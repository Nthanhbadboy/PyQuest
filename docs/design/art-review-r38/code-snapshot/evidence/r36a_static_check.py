#!/usr/bin/env python3
"""Reproducible, dependency-free provenance and structural checks for R36-A/B/C."""
from __future__ import annotations
import hashlib
import json
import struct
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REVIEW_PIN = "68f2590b5883ca8aa746ffde0814d60a32dacb3c"
SCENES = [
    "a01-w04-journal", "a02-shared-settings", "a03-shared-welcome",
    "a04-w05-catch-stars", "a05-w05-bug-hunter",
]
failures: list[str] = []
checks: list[dict] = []


def record(name: str, ok: bool, detail: str) -> None:
    checks.append({"check": name, "status": "PASS" if ok else "FAIL", "detail": detail})
    if not ok:
        failures.append(name + ": " + detail)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class Structure(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.tags: dict[str, int] = {}
        self.ids: set[str] = set()
        self.data_markers: set[str] = set()
    def handle_starttag(self, tag, attrs):
        self.tags[tag] = self.tags.get(tag, 0) + 1
        attrs = dict(attrs)
        if "id" in attrs: self.ids.add(attrs["id"])
        for key in attrs:
            if key.startswith("data-"): self.data_markers.add(key)


def check_scene(slug: str) -> dict:
    folder = ROOT / slug
    manifest_path = folder / "manifest.json"
    manifest = json.loads(manifest_path.read_text())
    html_path = folder / "layout.html"
    parser = Structure()
    parser.feed(html_path.read_text())
    layout_sha = sha(html_path)
    css_sha = sha(ROOT / "shared.css")
    js_sha = sha(ROOT / "shared.js")
    record(f"{slug}: JSON manifest", manifest.get("scene_id") == slug, "valid JSON and matching scene_id")
    record(f"{slug}: design review pin", manifest.get("design_review_pin") == REVIEW_PIN, manifest.get("design_review_pin", "missing"))
    record(f"{slug}: screen disposition", "CHANGES_REQUESTED" in manifest.get("screen_review_status", ""), manifest.get("screen_review_status", "missing"))
    record(f"{slug}: layout hash", manifest.get("layout", {}).get("sha256") == layout_sha, layout_sha)
    record(f"{slug}: shared hashes", manifest.get("layout", {}).get("shared_css_sha256") == css_sha and manifest.get("layout", {}).get("shared_js_sha256") == js_sha, f"css={css_sha}; js={js_sha}")
    record(f"{slug}: runtime boundary", manifest.get("runtime_ready") is False and manifest.get("production_approved") is False and manifest.get("animation_present") is False, "runtime_ready/production_approved/animation_present remain false")
    image_path = folder / "concept.png"
    image = manifest.get("image", {})
    image_data = image_path.read_bytes()
    width, height = struct.unpack(">II", image_data[16:24])
    record(f"{slug}: original concept image", sha(image_path) == image.get("sha256") and len(image_data) == image.get("bytes") and (width, height) == tuple(image.get("dimensions", [])), f"{width}x{height}, {len(image_data)} bytes, sha256={sha(image_path)}")
    record(f"{slug}: prompt hash", sha(folder / image.get("prompt_path", "prompt.txt")) == image.get("prompt_sha256"), image.get("prompt_sha256", "missing"))
    required = {"data-scene", "data-state-select", "data-lang", "data-scale", "data-scene-image", "data-state-title", "data-body", "data-facts", "data-cta", "data-note"}
    record(f"{slug}: fixture DOM markers", required <= parser.data_markers, ", ".join(sorted(required - parser.data_markers)) or "all required markers present")
    record(f"{slug}: reviewer/product separation markup", "product-screen" in html_path.read_text() and "reviewer-controls" in html_path.read_text() and "reviewer-notes" in html_path.read_text(), "review controls/notes outside product viewport in source layout")
    return {"scene_id": slug, "layout_sha256": layout_sha, "image_sha256": sha(image_path), "image_dimensions": [width, height], "states": manifest["layout"]["states"]}


for required_file in [ROOT / "shared.css", ROOT / "shared.js", ROOT / "reviewed-inputs.json"]:
    record(f"present: {required_file.name}", required_file.is_file(), str(required_file))

archive_path = ROOT / "evidence" / "r36a-originals" / "originals.json"
archive = json.loads(archive_path.read_text())
record("archive baseline pin", archive.get("baseline_commit") == "1053973da1ad11378f7263d7b13a4d61667133af", archive.get("baseline_commit", "missing"))
for item in archive["files"]:
    current = ROOT / item["path"]
    if item["archive_path"] == "unchanged-in-place":
        actual = sha(current)
    else:
        actual = sha(ROOT / "evidence" / "r36a-originals" / Path(item["archive_path"]).name)
    record(f"original preserved: {item['path']}", actual == item["sha256"], f"expected={item['sha256']} actual={actual}")

scenes = [check_scene(slug) for slug in SCENES]
reviewed = json.loads((ROOT / "reviewed-inputs.json").read_text())
record("16-image intake record retained", len(reviewed.get("assets", [])) == 16 and reviewed.get("fullsize_review", {}).get("assets_reviewed") == 16, f"assets={len(reviewed.get('assets', []))}; base source pin={reviewed.get('design_pin')}")
record("r36 review pin recorded", reviewed.get("latest_screen_review", {}).get("pin") == REVIEW_PIN, str(reviewed.get("latest_screen_review", {})))

# Content truth gates that must not regress during layout restyling.
js = (ROOT / "shared.js").read_text()
record("manual English translated in Vietnamese", "title: { vi: 'Dùng tiếng Anh', en: 'Use English' }" in js, "manual_en VI/EN labels checked in shared fixture data")
record("Catch Stars no program copy", "Giữ lượt chơi minh họa" in js and "Giữ lượt và chương trình" not in js, "paused copy is attempt/play, not a program")
record("Journal selector/CTA note", "Bộ chọn trạng thái nằm ngoài màn hình sản phẩm" in js and "CTA luôn tắt" in js, "selector remains reviewer control; primary CTA disabled")
record("Bug Hunter source mapping stays in reviewer notes", "puzzle bh_01" in js and "mq1_03" in js and "CastRegistry" in js, "exact identifiers remain available outside product copy")
record("Bug Hunter Python literals retained", 'print(\"Xin chào!\")' in js and 'print(\"Tớ là Bitsy)' in js, "both source literals preserved character-for-character")
record("expected output remains unexecuted data", "Xin chào!\\nTớ là Bitsy" in js and "Expected output from data · not executed" in js, "data output remains distinct from execution")

report = {
    "task": "PQC-018 Batch A R36-A/B/C correction",
    "review_pin": REVIEW_PIN,
    "baseline_commit": archive["baseline_commit"],
    "check_count": len(checks),
    "passed": sum(check["status"] == "PASS" for check in checks),
    "failed": len(failures),
    "status": "PASS" if not failures else "FAIL",
    "scenes": scenes,
    "checks": checks,
    "limits": "Static provenance/structure checks only. Browser measurements are reported separately; this does not self-accept DESIGN screen disposition or prove runtime/device behavior."
}
(ROOT / "evidence" / "r36a-static-checks.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
(ROOT / "evidence" / "static-checks.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n")
print(json.dumps({"status": report["status"], "check_count": report["check_count"], "passed": report["passed"], "failed": report["failed"], "failures": failures}, ensure_ascii=False, indent=2))
if failures:
    raise SystemExit(1)
