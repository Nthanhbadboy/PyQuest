#!/usr/bin/env python3
"""Unit tests for the bounded localization evidence channel."""

from __future__ import annotations

import base64
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

import l10n_evidence as evidence


def completed(command, returncode=0, stdout="", stderr="", **kwargs):
    return subprocess.CompletedProcess(command, returncode, stdout, stderr)


class EvidenceChannelTests(unittest.TestCase):
    def test_round_trip_preserves_sources_and_hashes(self):
        files = {
            "app_localizations.dart": b"class AppLocalizations {}\n",
            "app_localizations_vi.dart": "Xin chào\n".encode(),
        }
        envelope = {
            "schema_version": evidence.SCHEMA_VERSION,
            "tested_sha": "a" * 40,
            "run_id": "123",
            "run_attempt": "2",
            "generated_files": evidence.encode_files(files),
            "errors": [],
            "passed": True,
        }
        serialized = evidence.encode_envelope(envelope)
        restored = evidence.decode_envelope(serialized)
        self.assertEqual(restored["generated_files"], evidence.encode_files(files))
        for item in restored["generated_files"]:
            source = base64.b64decode(item["content_base64"], validate=True)
            self.assertEqual(item["sha256"], evidence.sha256(source))

    def test_detects_untracked_name_and_byte_drift(self):
        first = {"base.dart": b"same", "stale.dart": b"old"}
        second = {"base.dart": b"changed", "new.dart": b"added"}
        twice = evidence.compare_snapshots(first, second)
        self.assertEqual(twice["missing_on_second"], ["stale.dart"])
        self.assertEqual(twice["extra_on_second"], ["new.dart"])
        self.assertEqual(twice["changed"], ["base.dart"])

        committed = {"base.dart": b"committed", "expected.dart": b"expected"}
        generated = {"base.dart": b"different", "untracked.dart": b"new"}
        drift = evidence.compare_committed(generated, committed)
        self.assertEqual(drift["missing_from_generated"], ["expected.dart"])
        self.assertEqual(drift["uncommitted_generated"], ["untracked.dart"])
        self.assertEqual(drift["changed"], ["base.dart"])

    def test_preexisting_untracked_output_is_recorded_before_safe_cleanup(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            app = root / "app"
            generated = root / evidence.GENERATED_RELATIVE.as_posix()
            app.mkdir()
            generated.mkdir(parents=True)
            committed = {"app_localizations.dart": b"committed\n"}
            (generated / "app_localizations.dart").write_bytes(committed["app_localizations.dart"])
            (generated / "orphan.dart").write_bytes(b"stale untracked\n")

            def runner(command, **kwargs):
                if command[:2] == ["flutter", "--version"]:
                    return completed(command, stdout="Flutter 3.47.7\n")
                if command[:2] == ["flutter", "gen-l10n"]:
                    generated.mkdir(parents=True, exist_ok=True)
                    for name, content in committed.items():
                        (generated / name).write_bytes(content)
                    return completed(command)
                if command[:3] == ["git", "ls-tree", "-rz"]:
                    path = f"{evidence.GENERATED_RELATIVE.as_posix()}/app_localizations.dart"
                    return completed(command, stdout=f"100644 blob deadbeef\t{path}".encode() + b"\0")
                if command[:2] == ["git", "show"]:
                    return completed(command, stdout=committed["app_localizations.dart"])
                self.fail(f"unexpected command: {command}")

            result = evidence.collect_evidence(root, app, {"sha": "e" * 40}, runner=runner)
            self.assertFalse(result["passed"])
            self.assertIn("orphan.dart", result["preexisting_drift"]["uncommitted_generated"])
            self.assertTrue(any("pre-generation output differed" in error for error in result["errors"]))
            self.assertEqual(len(result["generated_files"]), 1)

    def test_failed_generators_are_not_reported_as_success(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            app = root / "app"
            app.mkdir()

            def runner(command, **kwargs):
                if command[:2] == ["flutter", "--version"]:
                    return completed(command, stdout="Flutter 3.47.7\n")
                if command[:2] == ["flutter", "gen-l10n"]:
                    return completed(command, returncode=1, stderr="generator failed")
                if command[:3] == ["git", "ls-tree", "-rz"]:
                    return completed(command, stdout=b"")
                self.fail(f"unexpected command: {command}")

            result = evidence.collect_evidence(root, app, {"sha": "b" * 40}, runner=runner)
            self.assertFalse(result["passed"])
            self.assertEqual([run["exit_code"] for run in result["generation_runs"]], [1, 1])
            self.assertTrue(any("generation run" in message for message in result["errors"]))
            self.assertTrue(any("no generated files" in message for message in result["errors"]))

    def test_collect_captures_every_file_and_compares_twice_to_head(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            app = root / "app"
            generated = root / evidence.GENERATED_RELATIVE.as_posix()
            app.mkdir()
            files = {
                "app_localizations.dart": b"base\n",
                "app_localizations_en.dart": b"english\n",
                "app_localizations_vi.dart": b"vietnamese\n",
            }
            run_count = 0

            def runner(command, **kwargs):
                nonlocal run_count
                if command[:2] == ["flutter", "--version"]:
                    return completed(command, stdout="Flutter 3.47.7\n")
                if command[:2] == ["flutter", "gen-l10n"]:
                    run_count += 1
                    generated.mkdir(parents=True, exist_ok=True)
                    for name, content in files.items():
                        (generated / name).write_bytes(content)
                    return completed(command, stdout="generated\n")
                if command[:3] == ["git", "ls-tree", "-rz"]:
                    entries = []
                    for name in sorted(files):
                        entries.append(
                            f"100644 blob deadbeef\t{evidence.GENERATED_RELATIVE.as_posix()}/{name}".encode()
                            + b"\0"
                        )
                    return completed(command, stdout=b"".join(entries))
                if command[:2] == ["git", "show"]:
                    path = command[2].removeprefix("HEAD:").split("/")[-1]
                    return completed(command, stdout=files[path])
                self.fail(f"unexpected command: {command}")

            result = evidence.collect_evidence(
                root,
                app,
                {"sha": "c" * 40, "run_id": "9", "run_attempt": "1"},
                runner=runner,
            )
            self.assertTrue(result["passed"], result["errors"])
            self.assertEqual(run_count, 2)
            self.assertEqual(len(result["generated_files"]), 3)
            self.assertEqual(result["tested_sha"], "c" * 40)
            for item in result["generated_files"]:
                source = base64.b64decode(item["content_base64"], validate=True)
                self.assertEqual(item["sha256"], evidence.sha256(source))

    def test_rejects_oversize_envelope_instead_of_truncating(self):
        envelope = {
            "generated_files": evidence.encode_files({"large.dart": b"x" * 200}),
        }
        with self.assertRaisesRegex(ValueError, "exceeds"):
            evidence.encode_envelope(envelope, max_bytes=128)

    def test_rejects_unsafe_paths_and_symlinks(self):
        with self.assertRaisesRegex(ValueError, "unsafe generated path"):
            evidence.encode_files({"../escape.dart": b"no"})
        malicious = {
            "generated_files": [{
                "path": "app/lib/l10n/generated/../escape.dart",
                "size_bytes": 0,
                "sha256": evidence.sha256(b""),
                "content_base64": "",
            }],
        }
        with self.assertRaisesRegex(ValueError, "unsafe"):
            evidence.verify_envelope(malicious)

        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary) / "generated"
            root.mkdir()
            outside = Path(temporary) / "outside.dart"
            outside.write_text("unsafe", encoding="utf-8")
            (root / "escape.dart").symlink_to(outside)
            with self.assertRaisesRegex(ValueError, "symlink"):
                evidence.snapshot_directory(root)

    def test_publish_failure_propagates(self):
        envelope = {
            "generated_files": evidence.encode_files({"app_localizations.dart": b"source"}),
            "passed": True,
            "run_id": "5",
            "run_attempt": "1",
        }

        def failed_runner(command, **kwargs):
            self.assertEqual(command[:2], ["gh", "api"])
            posted = json.loads(kwargs["input"])
            self.assertEqual(posted["head_sha"], "d" * 40)
            self.assertLess(len(posted["output"]["text"].encode()), evidence.MAX_OUTPUT_BYTES)
            return completed(command, returncode=1, stderr="checks API unavailable")

        with self.assertRaisesRegex(RuntimeError, "publish failed"):
            evidence.publish_check(envelope, "owner/repo", "d" * 40, runner=failed_runner)


if __name__ == "__main__":
    unittest.main(verbosity=2)
