#!/usr/bin/env python3
"""Collect and publish reproducible Flutter localization-generation evidence.

The checks API output carries a bounded JSON envelope containing the complete
source bytes and SHA-256 hashes for every generated Dart file. No test failure
or log truncation is used as a transport channel.
"""

from __future__ import annotations

import argparse
import base64
import datetime as dt
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import sys
from typing import Callable, Mapping, Sequence

SCHEMA_VERSION = 1
GENERATED_RELATIVE = PurePosixPath("app/lib/l10n/generated")
MAX_OUTPUT_BYTES = 60_000
MAX_LOG_CHARS = 2_000

Runner = Callable[..., subprocess.CompletedProcess[str]]


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _validate_relative_path(value: str) -> str:
    path = PurePosixPath(value)
    if path.is_absolute() or not path.parts or any(part in ("", ".", "..") for part in path.parts):
        raise ValueError(f"unsafe generated path: {value!r}")
    if "\\" in value or "\x00" in value:
        raise ValueError(f"unsafe generated path: {value!r}")
    return path.as_posix()


def snapshot_directory(root: Path) -> dict[str, bytes]:
    """Snapshot all regular files under root; reject symlinks and path escapes."""
    if not root.exists():
        return {}
    if root.is_symlink() or not root.is_dir():
        raise ValueError(f"generated output root is not a real directory: {root}")
    resolved_root = root.resolve(strict=True)
    result: dict[str, bytes] = {}
    for path in sorted(root.rglob("*")):
        relative = path.relative_to(root).as_posix()
        _validate_relative_path(relative)
        if path.is_symlink():
            raise ValueError(f"symlink in generated output: {relative}")
        resolved = path.resolve(strict=True)
        if resolved_root not in resolved.parents and resolved != resolved_root:
            raise ValueError(f"generated output escapes its directory: {relative}")
        if path.is_dir():
            continue
        if not path.is_file():
            raise ValueError(f"non-regular generated output: {relative}")
        result[relative] = path.read_bytes()
    return result


def prepare_output_directory(repo_root: Path) -> tuple[Path, dict[str, bytes], bool]:
    """Record then clear only the configured generated-output directory.

    Clearing before generation prevents committed stale files from masquerading
    as fresh generator output. The preexisting snapshot is retained as evidence
    and compared with HEAD, so untracked/stale files are never silently erased.
    """
    repository = repo_root.resolve(strict=True)
    output = repository / GENERATED_RELATIVE.as_posix()
    parent = output.parent.resolve(strict=False)
    if not parent.is_relative_to(repository):
        raise ValueError("generated output parent escapes the repository")
    if output.is_symlink():
        raise ValueError("generated output root must not be a symlink")
    existed = output.exists()
    prior = snapshot_directory(output)
    if existed:
        shutil.rmtree(output)
    return output, prior, existed


def snapshot_committed(repo_root: Path, runner: Runner = subprocess.run) -> dict[str, bytes]:
    """Read generated files from HEAD, not the mutable worktree or index."""
    prefix = GENERATED_RELATIVE.as_posix()
    listing = runner(
        ["git", "ls-tree", "-rz", "HEAD", "--", prefix],
        cwd=repo_root,
        capture_output=True,
        check=False,
    )
    if listing.returncode != 0:
        raise RuntimeError(f"git ls-tree failed: {listing.stderr.decode(errors='replace')[-MAX_LOG_CHARS:]}")
    result: dict[str, bytes] = {}
    for entry in listing.stdout.split(b"\0"):
        if not entry:
            continue
        metadata, raw_path = entry.split(b"\t", 1)
        mode, _kind, _object_id = metadata.decode("ascii").split()
        path = raw_path.decode("utf-8")
        if mode == "120000":
            raise ValueError(f"committed generated symlink is unsafe: {path}")
        if mode not in ("100644", "100755"):
            raise ValueError(f"unexpected committed generated file mode {mode}: {path}")
        relative = path.removeprefix(prefix + "/")
        _validate_relative_path(relative)
        if not path.startswith(prefix + "/"):
            raise ValueError(f"committed file outside generated output directory: {path}")
        shown = runner(
            ["git", "show", f"HEAD:{path}"],
            cwd=repo_root,
            capture_output=True,
            check=False,
        )
        if shown.returncode != 0:
            raise RuntimeError(f"git show failed for {path}: {shown.stderr.decode(errors='replace')[-MAX_LOG_CHARS:]}")
        result[relative] = shown.stdout
    return result


def compare_snapshots(first: Mapping[str, bytes], second: Mapping[str, bytes]) -> dict[str, list[str]]:
    first_names, second_names = set(first), set(second)
    common = first_names & second_names
    return {
        "missing_on_second": sorted(first_names - second_names),
        "extra_on_second": sorted(second_names - first_names),
        "changed": sorted(name for name in common if first[name] != second[name]),
    }


def compare_committed(generated: Mapping[str, bytes], committed: Mapping[str, bytes]) -> dict[str, list[str]]:
    generated_names, committed_names = set(generated), set(committed)
    common = generated_names & committed_names
    return {
        "missing_from_generated": sorted(committed_names - generated_names),
        "uncommitted_generated": sorted(generated_names - committed_names),
        "changed": sorted(name for name in common if generated[name] != committed[name]),
    }


def encode_hashes(files: Mapping[str, bytes]) -> list[dict[str, object]]:
    return [
        {
            "path": f"{GENERATED_RELATIVE.as_posix()}/{_validate_relative_path(name)}",
            "size_bytes": len(files[name]),
            "sha256": sha256(files[name]),
        }
        for name in sorted(files)
    ]


def encode_files(files: Mapping[str, bytes]) -> list[dict[str, object]]:
    encoded: list[dict[str, object]] = []
    for name in sorted(files):
        relative = _validate_relative_path(name)
        data = files[name]
        encoded.append({
            "path": f"{GENERATED_RELATIVE.as_posix()}/{relative}",
            "size_bytes": len(data),
            "sha256": sha256(data),
            "content_base64": base64.b64encode(data).decode("ascii"),
        })
    return encoded


def _validate_evidence_path(path: object) -> str:
    prefix = GENERATED_RELATIVE.as_posix() + "/"
    if not isinstance(path, str) or not path.startswith(prefix):
        raise ValueError(f"unsafe generated evidence path: {path!r}")
    relative = _validate_relative_path(path.removeprefix(prefix))
    canonical = f"{prefix}{relative}"
    if path != canonical:
        raise ValueError(f"noncanonical generated evidence path: {path!r}")
    return canonical


def verify_envelope(envelope: Mapping[str, object]) -> bool:
    files = envelope.get("generated_files")
    if not isinstance(files, list):
        raise ValueError("generated_files must be a list")
    seen: set[str] = set()
    for item in files:
        if not isinstance(item, dict):
            raise ValueError("generated file entry must be an object")
        path = _validate_evidence_path(item.get("path"))
        if path in seen:
            raise ValueError(f"duplicate generated evidence path: {path!r}")
        seen.add(path)
        encoded = item.get("content_base64")
        if not isinstance(encoded, str):
            raise ValueError(f"missing base64 source for {path}")
        data = base64.b64decode(encoded, validate=True)
        if item.get("size_bytes") != len(data) or item.get("sha256") != sha256(data):
            raise ValueError(f"source size/hash mismatch for {path}")

    for field in ("generation_outputs", "committed_file_hashes", "preexisting_output_hashes"):
        records = envelope.get(field, [])
        if not isinstance(records, list):
            raise ValueError(f"{field} must be a list")
        generations = [records] if field in ("committed_file_hashes", "preexisting_output_hashes") else records
        for snapshot in generations:
            if not isinstance(snapshot, list):
                raise ValueError(f"{field} entries must be lists of file hashes")
            paths: set[str] = set()
            for record in snapshot:
                if not isinstance(record, dict):
                    raise ValueError(f"{field} file hash must be an object")
                path = _validate_evidence_path(record.get("path"))
                if path in paths:
                    raise ValueError(f"duplicate path in {field}: {path}")
                paths.add(path)
                digest = record.get("sha256")
                size = record.get("size_bytes")
                if (not isinstance(digest, str) or len(digest) != 64
                        or any(char not in "0123456789abcdef" for char in digest)
                        or not isinstance(size, int) or size < 0):
                    raise ValueError(f"invalid size/hash in {field} for {path}")
    return True


def encode_envelope(envelope: Mapping[str, object], max_bytes: int = MAX_OUTPUT_BYTES) -> str:
    verify_envelope(envelope)
    serialized = json.dumps(envelope, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    if len(serialized.encode("utf-8")) > max_bytes:
        raise ValueError(f"evidence envelope exceeds {max_bytes} byte output limit")
    return serialized


def decode_envelope(serialized: str) -> dict[str, object]:
    value = json.loads(serialized)
    if not isinstance(value, dict):
        raise ValueError("evidence envelope must be a JSON object")
    verify_envelope(value)
    return value


def _result_record(command: Sequence[str], result: subprocess.CompletedProcess[str] | None,
                   exception: Exception | None = None) -> dict[str, object]:
    if exception is not None:
        return {"command": list(command), "exit_code": None, "error": str(exception)[:MAX_LOG_CHARS]}
    assert result is not None
    return {
        "command": list(command),
        "exit_code": result.returncode,
        "stdout": (result.stdout or "")[-MAX_LOG_CHARS:],
        "stderr": (result.stderr or "")[-MAX_LOG_CHARS:],
    }


def collect_evidence(
    repo_root: Path,
    app_dir: Path,
    metadata: Mapping[str, str],
    runner: Runner = subprocess.run,
) -> dict[str, object]:
    errors: list[str] = []
    generation_runs: list[dict[str, object]] = []
    flutter_result: subprocess.CompletedProcess[str] | None = None
    try:
        flutter_result = runner(["flutter", "--version"], cwd=app_dir, capture_output=True,
                                text=True, check=False)
        if flutter_result.returncode != 0:
            errors.append(f"flutter --version exited {flutter_result.returncode}")
    except Exception as error:  # evidence must still be emitted when Flutter is unavailable
        errors.append(f"flutter --version failed: {error}")

    try:
        committed = snapshot_committed(repo_root, runner)
    except Exception as error:
        committed = {}
        errors.append(f"cannot read committed generated output: {error}")

    output_root = repo_root / GENERATED_RELATIVE.as_posix()
    preexisting: dict[str, bytes] = {}
    preexisting_drift: dict[str, list[str]] = {
        "missing_from_generated": [], "uncommitted_generated": [], "changed": [],
    }
    can_generate = True
    try:
        output_root, preexisting, had_preexisting_directory = prepare_output_directory(repo_root)
        if had_preexisting_directory:
            preexisting_drift = compare_committed(preexisting, committed)
            if any(preexisting_drift.values()):
                errors.append("pre-generation output differed from committed generated Dart output")
    except Exception as error:
        can_generate = False
        errors.append(f"cannot safely prepare generated output directory: {error}")

    snapshots: list[dict[str, bytes]] = []
    command = ["flutter", "gen-l10n"]
    for index in (1, 2):
        try:
            if not can_generate:
                raise RuntimeError("refusing generation because the output directory is unsafe")
            result = runner(command, cwd=app_dir, capture_output=True, text=True, check=False)
            generation_runs.append(_result_record(command, result))
            if result.returncode != 0:
                errors.append(f"generation run {index} exited {result.returncode}")
        except Exception as error:
            generation_runs.append(_result_record(command, None, error))
            errors.append(f"generation run {index} failed: {error}")
        try:
            snapshots.append(snapshot_directory(output_root) if can_generate else {})
        except Exception as error:
            snapshots.append({})
            errors.append(f"generation run {index} output snapshot failed: {error}")

    first = snapshots[0] if snapshots else {}
    second = snapshots[1] if len(snapshots) > 1 else {}
    reproducibility = compare_snapshots(first, second)
    committed_drift = compare_committed(second, committed)
    if not first or not second:
        errors.append("one or both generation runs produced no generated files")
    if any(reproducibility.values()):
        errors.append("generation outputs are not byte-for-byte reproducible")
    if any(committed_drift.values()):
        errors.append("generated output differs from the committed Dart output")

    flutter_text = ""
    if flutter_result is not None:
        flutter_text = ((flutter_result.stdout or "") + (flutter_result.stderr or ""))[-MAX_LOG_CHARS:]
    envelope: dict[str, object] = {
        "schema_version": SCHEMA_VERSION,
        "tested_sha": metadata.get("sha", ""),
        "run_id": metadata.get("run_id", ""),
        "run_attempt": metadata.get("run_attempt", ""),
        "flutter_version": flutter_text,
        "generation_runs": generation_runs,
        "preexisting_output_hashes": encode_hashes(preexisting),
        "preexisting_drift": preexisting_drift,
        "reproducibility": reproducibility,
        "generation_outputs": [encode_hashes(first), encode_hashes(second)],
        "committed_file_hashes": encode_hashes(committed),
        "committed_drift": committed_drift,
        "generated_files": encode_files(second),
        "errors": errors,
        "passed": not errors,
    }
    try:
        encode_envelope(envelope)
    except ValueError as error:
        errors.append(str(error))
        envelope["passed"] = False
        # Keep a complete bounded failure record without pretending the source was delivered.
        envelope["generated_files"] = []
        envelope["errors"] = errors
    return envelope


def publish_check(envelope: Mapping[str, object], repository: str, sha: str,
                  runner: Runner = subprocess.run) -> None:
    serialized = encode_envelope(envelope)
    passed = envelope.get("passed") is True
    summary = (
        f"Localization generation evidence: {'PASS' if passed else 'FAIL'}; "
        f"tested SHA `{sha}`; run `{envelope.get('run_id', '')}` attempt "
        f"`{envelope.get('run_attempt', '')}`."
    )
    payload = {
        "name": "PyQuest localization generation evidence",
        "head_sha": sha,
        "status": "completed",
        "conclusion": "success" if passed else "failure",
        "completed_at": dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"),
        "output": {
            "title": "Flutter localization generation evidence",
            "summary": summary,
            "text": serialized,
        },
    }
    result = runner(
        ["gh", "api", f"repos/{repository}/check-runs", "--method", "POST", "--input", "-"],
        input=json.dumps(payload, ensure_ascii=False),
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(f"checks API publish failed ({result.returncode}): {(result.stderr or '')[-MAX_LOG_CHARS:]}")


def _write_json(path: Path, envelope: Mapping[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(envelope, ensure_ascii=False, sort_keys=True, indent=2) + "\n", encoding="utf-8")


def command_collect(args: argparse.Namespace) -> int:
    metadata = {"sha": args.sha, "run_id": args.run_id, "run_attempt": args.run_attempt}
    envelope = collect_evidence(args.repo_root.resolve(), args.app_dir.resolve(), metadata)
    _write_json(args.output, envelope)
    print(f"collected localization evidence: {'PASS' if envelope['passed'] else 'FAIL'} -> {args.output}")
    for error in envelope["errors"]:
        print(f"ERROR: {error}", file=sys.stderr)
    return 0 if envelope["passed"] else 1


def command_publish(args: argparse.Namespace) -> int:
    try:
        envelope = json.loads(args.evidence.read_text(encoding="utf-8"))
        if not isinstance(envelope, dict):
            raise ValueError("evidence file is not a JSON object")
        verify_envelope(envelope)
        if envelope.get("tested_sha") != args.sha:
            errors = envelope.get("errors")
            if not isinstance(errors, list):
                errors = []
            errors.append("evidence tested SHA does not match the publish target SHA")
            envelope["errors"] = errors
            envelope["passed"] = False
    except Exception as error:
        envelope = {
            "schema_version": SCHEMA_VERSION,
            "tested_sha": args.sha,
            "run_id": args.run_id,
            "run_attempt": args.run_attempt,
            "flutter_version": "",
            "generation_runs": [],
            "preexisting_output_hashes": [],
            "preexisting_drift": {},
            "reproducibility": {},
            "generation_outputs": [],
            "committed_file_hashes": [],
            "committed_drift": {},
            "generated_files": [],
            "errors": [f"evidence collection unavailable or invalid: {error}"],
            "passed": False,
        }
    try:
        publish_check(envelope, args.repository, args.sha)
    except Exception as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print(f"published localization evidence check for {args.sha}: {'PASS' if envelope.get('passed') else 'FAIL'}")
    return 0 if envelope.get("passed") is True else 1


def make_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    collect = commands.add_parser("collect", help="run generation twice and capture evidence")
    collect.add_argument("--repo-root", type=Path, required=True)
    collect.add_argument("--app-dir", type=Path, required=True)
    collect.add_argument("--output", type=Path, required=True)
    collect.add_argument("--sha", default=os.environ.get("GITHUB_SHA", ""))
    collect.add_argument("--run-id", default=os.environ.get("GITHUB_RUN_ID", ""))
    collect.add_argument("--run-attempt", default=os.environ.get("GITHUB_RUN_ATTEMPT", ""))
    collect.set_defaults(function=command_collect)
    publish = commands.add_parser("publish", help="publish the evidence envelope as a check run")
    publish.add_argument("--evidence", type=Path, required=True)
    publish.add_argument("--repository", default=os.environ.get("GITHUB_REPOSITORY", ""))
    publish.add_argument("--sha", default=os.environ.get("GITHUB_SHA", ""))
    publish.add_argument("--run-id", default=os.environ.get("GITHUB_RUN_ID", ""))
    publish.add_argument("--run-attempt", default=os.environ.get("GITHUB_RUN_ATTEMPT", ""))
    publish.set_defaults(function=command_publish)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    args = make_parser().parse_args(argv)
    if args.command == "publish" and (not args.sha or not args.repository):
        print("ERROR: publish requires repository and exact tested SHA", file=sys.stderr)
        return 1
    return args.function(args)


if __name__ == "__main__":
    raise SystemExit(main())
