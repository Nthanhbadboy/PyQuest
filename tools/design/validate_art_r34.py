#!/usr/bin/env python3
"""Validate r34 art provenance/evidence; never substitutes for runtime tests."""
from pathlib import Path
from PIL import Image
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'docs/design/art-refresh-r34'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    assert len(manifest['assets']) == 10
    assert not manifest['runtime_ready'] and not manifest['runtime_changed']
    checked = []
    for item in manifest['assets'] + manifest['evidence']:
        path = BASE / item['path']
        with Image.open(path) as image:
            image.load()
            assert list(image.size) == item['dimensions'], path
        assert path.stat().st_size == item['bytes'], path
        assert digest(path) == item['sha256'], path
        if 'reference' in item:
            assert digest(ROOT / item['reference']) == item['reference_sha256']
            assert item['reviewed_fullsize'] and not item['production_approved']
            assert not item['runtime_ready']
        if '390x844' in path.name:
            assert item['dimensions'] == [390, 844]
        if '360x640' in path.name:
            assert item['dimensions'] == [360, 640]
        checked.append(str(path.relative_to(ROOT)))
    receipt = json.loads((BASE / 'evidence/checks.json').read_text())
    assert receipt['matrixCases'] == receipt['passed'] == 504
    assert receipt['states'] == receipt['ctaTransitions'] == 42
    assert not receipt['errors'] and not receipt['failures']
    assert set(receipt['screenshots']) == {Path(e['path']).name for e in manifest['evidence']}
    ci = json.loads((ROOT / 'docs/design/coordination/reviews/PQC-011-r3/ci-check.json').read_text())
    assert ci['head_sha'] == manifest['reviewed_code_sha']
    assert ci['id'] == 117462432865 and ci['conclusion'] == 'failure'
    links = []
    docs = list(BASE.glob('*.md')) + [
        ROOT / 'docs/design/coordination/reviews/PQD-003-r34.md',
        ROOT / 'docs/implementation/coordination/tasks/PQC-011.md',
        ROOT / 'docs/design/ART_DIRECTION_2_5D.md',
        ROOT / 'docs/design/coordination/tasks/PQD-003.md',
    ]
    for document in docs:
        for link in re.findall(r'!?\[[^\]]*\]\(([^)\s]+)\)', document.read_text()):
            if '://' in link or link.startswith('#'):
                continue
            target = (document.parent / link.split('#')[0]).resolve()
            assert target.exists(), (document, link)
            links.append({'from': str(document.relative_to(ROOT)), 'to': link})
    for source in ['scenes.js', 'screen-copy.js', 'gallery.js']:
        subprocess.run(['node', '--check', str(BASE / source)], check=True)
    subprocess.run(['git', 'diff', '--check'], cwd=ROOT, check=True)
    report = {
        'date': '2026-10-18', 'timezone': 'Asia/Saigon',
        'kind': 'Design-only static image/provenance/link checks',
        'assets_and_screenshots_verified': len(checked),
        'local_markdown_links_verified': len(links),
        'source_ci_failure_verified': ci['id'],
        'javascript_syntax': '3 files passed', 'git_diff_check': 'passed',
        'runtime_tests_run': False, 'checked_files': checked,
        'known_preexisting_r33_image_drift': manifest['preexisting_workspace_drift_excluded'],
    }
    (BASE / 'evidence/static-checks.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({k: v for k, v in report.items() if k != 'checked_files'}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
