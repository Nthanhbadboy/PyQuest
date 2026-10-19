"""Source/catalog/artifact/link integrity for r45, not a Flutter/maze-engine test."""
import hashlib
import json
import re
import struct
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
P = ROOT / 'docs/design/maze-trail-r45'
OUT = P / 'evidence/static-checks.json'


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


manifest = json.loads((P / 'manifest.json').read_text())
source = json.loads((P / 'source-manifest.json').read_text())
pin = manifest['code_pin']
assert pin == source['code_sha'] == '71b0fd3fd8fb07c73596ce089fa2e68f6fe87964'
assert len(source['sources']) == 7
for r in source['sources']:
    assert sha(git('show', pin + ':' + r['path'])) == r['sha256']
    assert git('rev-parse', pin + ':' + r['path']).decode().strip() == r['blob']
for r in manifest['references']:
    raw = (ROOT / r['path']).read_bytes()
    assert sha(raw) == r['sha256']
    assert raw == git('show', manifest['design_base'] + ':' + r['path'])
for r in manifest['artifacts'] + manifest['evidence']:
    f = P / r['path']
    assert sha(f.read_bytes()) == r['sha256'], r['path']
    assert f.stat().st_size == r['bytes']
raw = (P / manifest['art']['file']).read_bytes()
assert raw[:8] == b'\x89PNG\r\n\x1a\n'
assert struct.unpack('>II', raw[16:24]) == (848, 1264)
original = json.loads(git('show', pin + ':app/assets/data/robot_maze_levels.json'))
config = json.loads(git('show', pin + ':app/assets/config/game_config.json'))
catalog = json.loads(subprocess.check_output(['node', '-e', "console.log(JSON.stringify(require('./docs/design/maze-trail-r45/catalog.js')))"], cwd=ROOT))
assert catalog['gameId'] == original['game_id'] == 'robot_maze'
assert len(catalog['levels']) == len(original['levels']) == 10
cells = 0
for i, (a, b) in enumerate(zip(catalog['levels'], original['levels'])):
    assert a['id'] == b['id'] and a['number'] == i + 1
    assert a['title']['vi'] == b['title'] and a['story']['vi'] == b['story']
    assert a['rows'] == b['rows']
    assert a['commandLimit'] == b['command_limit'] and a['allowLoops'] == b['allow_loops']
    assert a['gems'] == sum(row.count('*') for row in b['rows'])
    assert 'solution' not in a and 'tip' not in a
    cells += sum(map(len, a['rows']))
assert cells == 246
costs = config['energy_costs']
assert catalog['costs'] == {'new': costs['mini_game_new_level'], 'replay': costs['mini_game_replay_completed'], 'creator': costs['creator_mode']}
assert catalog['maxInitial'] == config['energy']['max_initial']
browser = json.loads((P / 'evidence/browser-checks.json').read_text())
model = json.loads((P / 'evidence/model-checks.json').read_text())
assert browser['result'] == model['result'] == 'PASS'
assert browser['cases'] == len(browser['results']) == 360
assert browser['invalidCases'] == 0 and browser['failures'] == []
assert browser['errors'] == browser['externalRequests'] == []
assert browser['fontChecks'] == 5664 and browser['gridChecks'] == 246
assert len(browser['flows']) == 16 and model['checks'] == len(model['results']) == 18
assert len(browser['shots']) == 11
assert {r['path'].split('/')[-1] for r in manifest['evidence'] if r['path'].endswith(('.png', '.jpg'))} == set(browser['shots'])
for name in browser['shots']:
    raw = (P / 'evidence' / name).read_bytes()
    if name.endswith('.png'):
        width = int(re.search(r'-(360|390)-', name)[1])
        assert struct.unpack('>II', raw[16:24]) == (width, 640 if width == 360 else 844)
    else:
        assert raw[:2] == b'\xff\xd8'
for f in ['study.js', 'model.js']:
    assert not re.search(r'localStorage|sessionStorage|XMLHttpRequest|WebSocket|\bfetch\(|\beval\(|setInterval', (P / f).read_text())
links = 0
docs = [P / f for f in ['README.md', 'SPEC.md', 'ASSET_PLAN.md', 'index.html', 'style.css']]
docs += [ROOT / f for f in ['docs/design/VISUAL_DESIGN_STATUS.md', 'docs/design/coordination/tasks/PQD-007.md', 'docs/design/coordination/tasks/PQD-008.md']]
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
    'docs/design/coordination/tasks/PQD-007.md',
    'docs/design/coordination/tasks/PQD-008.md',
    'tools/design/serve_art_review.py',
    'tools/design/check_maze_r45.cjs',
    'tools/design/test_maze_r45.cjs',
    'tools/design/validate_maze_r45.py',
    'docs/design/art-refresh-r33/concepts/w02-home-expansion.jpg',
    'docs/design/art-refresh-r33/concepts/w08-archipelago.jpg',
}
changed = git('diff', '--name-only', manifest['design_base']).decode().splitlines()
changed += git('ls-files', '--others', '--exclude-standard').decode().splitlines()
assert all(f in allowed or f.startswith('docs/design/maze-trail-r45/') for f in changed), changed
receipt = {'result': 'PASS', 'scope': 'Design source/catalog/artifact/link/diff integrity ONLY; not Flutter or gameplay execution',
           'source_pins': 7, 'source_levels': 10, 'source_cells': cells, 'source_costs': 'MATCH',
           'references': len(manifest['references']), 'hashed_artifacts': len(manifest['artifacts']),
           'hashed_evidence': len(manifest['evidence']), 'captures': 11, 'local_links': links,
           'browser_cases': 360, 'font_checks': 5664, 'flows': 16, 'model_checks': 18,
           'runtime_changed': False, 'flutter_execution': 'NOT_RUN', 'ci_triggered': False}
OUT.write_text(json.dumps(receipt, indent=2) + '\n')
print(json.dumps(receipt, indent=2))
