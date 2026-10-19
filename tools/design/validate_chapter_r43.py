"""r43 pins/catalog/artifact/link verification; not a Flutter validator."""
import hashlib
import json
import re
import struct
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
P = ROOT / 'docs/design/chapter-journey-r43'
OUT = P / 'evidence/static-checks.json'


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


manifest = json.loads((P / 'manifest.json').read_text())
source = json.loads((P / 'source-manifest.json').read_text())
pin = manifest['code_pin']
assert pin == source['code_sha'] == '2ea5e5004e98df4aec8c1132a56b8d60bf4ddf5e'
assert len(source['sources']) == 7
for row in source['sources']:
    raw = git('show', pin + ':' + row['path'])
    assert digest(raw) == row['sha256'], row['path']
    assert git('rev-parse', pin + ':' + row['path']).decode().strip() == row['blob']
later = source['observed_later_code_tip']['sha']
assert later == '71b0fd3fd8fb07c73596ce089fa2e68f6fe87964'
assert set(git('diff', '--name-only', pin, later).decode().splitlines()) == {
    'app/test/lesson_board_integration_test.dart',
    'docs/implementation/coordination/tasks/PQC-011.md',
}
for row in source['sources']:
    assert git('show', later + ':' + row['path']) == git('show', pin + ':' + row['path'])
for row in manifest['references']:
    raw = (ROOT / row['path']).read_bytes()
    assert digest(raw) == row['sha256'], row['path']
    assert raw == git('show', manifest['design_base'] + ':' + row['path'])
for row in manifest['artifacts'] + manifest['evidence']:
    f = P / row['path']
    assert digest(f.read_bytes()) == row['sha256'], row['path']
    assert f.stat().st_size == row['bytes'], row['path']
art = (P / manifest['art']['file']).read_bytes()
assert art[:8] == b'\x89PNG\r\n\x1a\n'
assert struct.unpack('>II', art[16:24]) == (848, 1264)
original = json.loads(git('show', pin + ':app/assets/data/main_quest_ch1.json'))
config = json.loads(git('show', pin + ':app/assets/config/game_config.json'))
catalog = json.loads(subprocess.check_output(['node', '-e', "console.log(JSON.stringify(require('./docs/design/chapter-journey-r43/catalog.js')))"], cwd=ROOT))
assert catalog['chapter'] == original['chapter']
assert catalog['nextChapter'] == original['next_chapter']
assert catalog['costs'] == config['energy_costs']
assert catalog['energyConfig'] == config['energy']
assert len(catalog['lessons']) == len(original['lessons']) == 12
for a, b in zip(catalog['lessons'], original['lessons']):
    for k in ['id', 'number', 'challenge']:
        assert a[k] == b[k]
    assert a['title']['vi'] == b['title'] and a['skill']['vi'] == b['skill']
    assert a['steps'] == len(b['steps'])
assert [l['tutor'] for l in catalog['lessons']] == ['Nova', 'Nova', 'Pixel', 'Bit', 'Bit', 'Nova', 'Pixel', 'Pixel', 'Pixel', 'Pixel', 'Ada', 'Ada']
browser = json.loads((P / 'evidence/browser-checks.json').read_text())
model = json.loads((P / 'evidence/model-checks.json').read_text())
assert browser['result'] == model['result'] == 'PASS'
assert browser['cases'] == len(browser['results']) == 168
assert browser['invalidCases'] == 0 and browser['failures'] == []
assert browser['errors'] == browser['externalRequests'] == []
assert len(browser['flows']) == 15 and browser['fontChecks'] == 2340
assert model['checks'] == len(model['results']) == 17
assert len(browser['shots']) == 13
for name in browser['shots']:
    raw = (P / 'evidence' / name).read_bytes()
    if name.endswith('.png'):
        width = int(re.search(r'-(360|390)-', name)[1])
        assert struct.unpack('>II', raw[16:24]) == (width, 640 if width == 360 else 844)
    else:
        assert raw[:2] == b'\xff\xd8'
for file in ['study.js', 'model.js']:
    assert not re.search(r'localStorage|sessionStorage|XMLHttpRequest|WebSocket|\bfetch\(|\beval\(|setInterval', (P / file).read_text())
links = 0
docs = [P / f for f in ['README.md', 'SPEC.md', 'ASSET_PLAN.md', 'index.html', 'style.css']]
docs += [ROOT / f for f in ['docs/design/VISUAL_DESIGN_STATUS.md', 'docs/design/coordination/tasks/PQD-007.md', 'docs/design/coordination/tasks/PQD-006.md']]
for doc in docs:
    text = doc.read_text()
    targets = re.findall(r'\]\(([^)]+)\)', text)
    if doc.suffix == '.html':
        targets += re.findall(r'(?:src|href)="([^"]+)"', text)
    if doc.suffix == '.css':
        targets += re.findall(r'url\([\'"]?([^\)\'\"]+)', text)
    for target in targets:
        if target.startswith('#') or '://' in target:
            continue
        f = (doc.parent / target.split('?')[0].split('#')[0]).resolve()
        assert f.exists() or f == OUT, (doc, target)
        links += 1
allowed = {
    'docs/design/VISUAL_DESIGN_STATUS.md',
    'docs/design/coordination/tasks/PQD-006.md',
    'docs/design/coordination/tasks/PQD-007.md',
    'tools/design/serve_art_review.py',
    'tools/design/check_chapter_r43.cjs',
    'tools/design/test_chapter_r43.cjs',
    'tools/design/validate_chapter_r43.py',
    'docs/design/art-refresh-r33/concepts/w02-home-expansion.jpg',
    'docs/design/art-refresh-r33/concepts/w08-archipelago.jpg',
}
changed = git('diff', '--name-only', manifest['design_base']).decode().splitlines()
changed += git('ls-files', '--others', '--exclude-standard').decode().splitlines()
assert all(f in allowed or f.startswith('docs/design/chapter-journey-r43/') for f in changed), changed
receipt = {
    'result': 'PASS',
    'scope': 'Design source pins, catalog, artifacts, receipts, links and diff allowlist ONLY; not Flutter execution',
    'source_pins': 7, 'source_lessons': 12, 'source_costs_and_energy_config': 'MATCH',
    'references': len(manifest['references']),
    'hashed_artifacts': len(manifest['artifacts']),
    'hashed_evidence': len(manifest['evidence']),
    'captures': len(browser['shots']), 'local_links': links,
    'browser_cases': 168, 'font_checks': 2340, 'flows': 15, 'model_checks': 17,
    'runtime_changed': False, 'flutter_execution': 'NOT_RUN', 'ci_triggered': False,
}
OUT.write_text(json.dumps(receipt, indent=2) + '\n')
print(json.dumps(receipt, indent=2))
