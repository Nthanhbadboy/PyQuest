#!/usr/bin/env python3
"""Offline r51 evidence/pin/dependency validation. --refresh writes the package manifest."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'docs/design/maze-python-r51'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def hashes(paths):
    return {str(p.relative_to(ROOT)): sha(p) for p in sorted(paths)}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--refresh', action='store_true')
    args = parser.parse_args()
    source = json.loads((BASE / 'source-manifest.json').read_text())
    for entry in source['files']:
        blob = subprocess.check_output(['git', 'show', source['code_pin'] + ':' + entry['path']], cwd=ROOT)
        assert hashlib.sha256(blob).hexdigest() == entry['sha256'], entry['path']
    dependencies = [
        'docs/design/maze-creator-r46/assets/workbench.png',
        'docs/design/maze-play-r50/assets/robo-token.png',
        'docs/design/maze-play-r50/assets/hedge-token.png',
        'docs/design/maze-play-r50/assets/garden-stage.png',
        'docs/design/maze-play-r50/assets/provenance.json',
        'docs/design/maze-play-r50/style.css',
        'docs/design/tutor-board-prototype/fonts/Nunito-Medium.ttf',
        'docs/design/tutor-board-prototype/fonts/Nunito-ExtraBold.ttf',
        'app/assets/fonts/JetBrainsMono-Medium.ttf',
        'app/assets/fonts/OFL-JetBrainsMono.txt',
        'app/assets/fonts/OFL-Nunito.txt',
        'docs/screenshots/27_workshop_code.jpg',
    ]
    for filename in ['model-checks.json', 'browser-checks.json']:
        receipt = json.loads((BASE / 'evidence' / filename).read_text())
        assert receipt['result'] == 'PASS'
        assert receipt['python_executed'] is False
        for path, digest in receipt['inputs'].items():
            assert sha(ROOT / path) == digest, 'Stale receipt: ' + path
    browser = json.loads((BASE / 'evidence/browser-checks.json').read_text())
    assert browser['matrix_cases'] == 252 and len(browser['flows']) == 19
    assert not browser['errors'] and not browser['external_requests']
    assert len(browser['captures']) == 12
    for path in browser['captures']:
        assert (BASE / 'evidence' / path).is_file(), path
    links = set()
    for p in [*BASE.glob('*.md'), BASE / 'index.html', BASE / 'style.css']:
        text = p.read_text()
        refs = re.findall(r'\]\(([^)]+)\)', text) if p.suffix == '.md' else re.findall(r'(?:href|src)=[\"\']([^\"\']+)[\"\']|url\([\"\']?([^\"\')]+)', text)
        for ref in refs:
            if isinstance(ref, tuple):
                ref = ref[0] or ref[1]
            if ref.startswith(('https:', 'http:', '#')):
                continue
            target = (p.parent / ref.split('#')[0]).resolve()
            expected_output = args.refresh and target in [BASE / 'manifest.json', BASE / 'evidence/static-checks.json']
            assert target.is_relative_to(ROOT) and (target.is_file() or expected_output), str(p) + ': ' + ref
            links.add(str(target.relative_to(ROOT)))
    tools = [ROOT / 'tools/design' / name for name in ['test_maze_python_r51.cjs', 'check_maze_python_r51.cjs', 'validate_maze_python_r51.py', 'serve_art_review.py']]
    artifacts = [p for p in BASE.rglob('*') if p.is_file() and p.name not in ['manifest.json', 'static-checks.json']]
    manifest = {'date': '2026-10-18', 'scope': 'HTML editor and authored response study; no Python/Flutter execution', 'artifacts': hashes(artifacts), 'dependencies': hashes([ROOT / p for p in dependencies]), 'tools': hashes(tools)}
    if args.refresh:
        (BASE / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    assert json.loads((BASE / 'manifest.json').read_text()) == manifest, 'Manifest drift: review before --refresh'
    receipt = {'result': 'PASS', 'source_pins': len(source['files']), 'local_link_targets': len(links), 'artifacts': len(artifacts), 'dependencies': len(dependencies), 'tools': len(tools), 'test_input_hashes_verified': True, 'python_executed': False, 'manifest_sha256': sha(BASE / 'manifest.json')}
    (BASE / 'evidence/static-checks.json').write_text(json.dumps(receipt, indent=2) + '\n')
    print(json.dumps(receipt, indent=2))

if __name__ == '__main__':
    main()
