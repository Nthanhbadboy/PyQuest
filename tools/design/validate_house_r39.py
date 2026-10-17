#!/usr/bin/env python3
"""W14 r39 provenance/static delivery checks; not app or engine validation."""
import hashlib
import json
import re
import subprocess
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'docs/design/achievement-house-r39'
manifest = json.loads((OUT / 'manifest.json').read_text())
checks = []

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def verify(entries, base):
    for entry in entries:
        assert sha((base / entry['path']).read_bytes()) == entry['sha256'], entry['path']
    return len(entries)

refs = verify(manifest['references'], ROOT)
artifacts = verify(manifest['artifacts'], OUT)
evidence = verify(manifest['evidence'], OUT)
verify(manifest['dirty_files_preserved'], ROOT)
checks.append('Reference/artifact/evidence hashes; two pre-existing dirty JPEGs unchanged')
for item in manifest['sources']:
    ref = f"{item['commit']}:{item['path']}"
    assert git('rev-parse', ref).decode().strip() == item['blob']
    assert sha(git('show', ref)) == item['sha256']
checks.append('Three exact CODE source blobs and SHA256 pins')
source = json.loads((OUT / 'source-catalog.json').read_text())
text = git('show', f"{source['source_commit']}:{source['source_path']}").decode()
rows = []
for block in text.split('achievementCatalog = [', 1)[1].split('AchievementDef(')[1:]:
    row = {}
    for key in ['id', 'title', 'description', 'howTo']:
        match = re.search(r'\b' + key + r": '([^']*)'", block)
        row[key] = match.group(1) if match else None
    row['secret'] = 'secret: true' in block
    match = re.search(r'\bgoal: (\d+)', block)
    row['goal'] = int(match.group(1)) if match else None
    rows.append(row)
assert len(rows) == 15 and rows == source['entries']
checks.append('All 15 VI source literal records independently re-extracted')
assert manifest['image']['reuse_unchanged'] and not manifest['runtime_changed']
ref = manifest['image']['path']
assert git('show', manifest['base_design_pin'] + ':' + ref) == (ROOT / ref).read_bytes()
checks.append('Canonical W14 image exactly unchanged from DESIGN base')
html = (OUT / 'index.html').read_text()
ids = re.findall(r'\bid="([^"]+)"', html)
assert len(ids) == len(set(ids))
links = 0
for p in [OUT / 'README.md', OUT / 'SPEC.md', OUT / 'index.html', ROOT / 'docs/design/coordination/tasks/PQD-005.md']:
    text = p.read_text()
    urls = re.findall(r'(?:src|href)="([^"]+)"', text) if p.suffix == '.html' else re.findall(r'\]\(([^)]+)\)', text)
    for url in urls:
        u = urlsplit(url)
        if not u.path or u.scheme or u.netloc:
            continue
        target = (p.parent / unquote(u.path)).resolve()
        assert target.is_file() or target == OUT / 'evidence/static-checks.json', (p, url)
        links += 1
checks.append('Unique HTML IDs and local links resolve')
for p in OUT.glob('*.js'):
    subprocess.run(['node', '--check', str(p)], check=True)
for name in ['index.html', 'study.js', 'model.js', 'copy.js']:
    assert 'source-catalog.json' not in (OUT / name).read_text()
checks.append('Four JS files parse; source spoiler JSON not loaded by phone')
browser = json.loads((OUT / 'evidence/browser-checks.json').read_text())
model = json.loads((OUT / 'evidence/model-checks.json').read_text())
assert browser['cases'] == 168 and browser['fontComparisons'] == 2688
assert browser['invalidCases'] == 0 and browser['errors'] == [] and browser['externalRequests'] == []
assert len(browser['flows']) == 12 and model['checks'] == 20
checks.append('Final browser/model receipts match declared 168 / 2688 / 12 / 20')
# As-of-r39 delivery scope guard, not a perpetual ban on later authorized work.
base = manifest['base_design_pin']
changed = git('diff', '--name-only', base, '--').decode().splitlines()
changed += git('ls-files', '--others', '--exclude-standard').decode().splitlines()
preserved = {x['path'] for x in manifest['dirty_files_preserved']}
allowed = {'docs/design/coordination/tasks/PQD-005.md', 'tools/design/serve_art_review.py',
           'tools/design/test_house_r39.cjs', 'tools/design/check_house_r39.cjs', 'tools/design/validate_house_r39.py'}
for p in changed:
    assert p.startswith('docs/design/achievement-house-r39/') or p in allowed or p in preserved, p
server = 'tools/design/serve_art_review.py'
old = git('show', base + ':' + server).decode()
expected = old.replace("choices=('r36', 'w08', 'r38')", "choices=('r36', 'w08', 'r38', 'w14')").replace('    handler = partial', "    if args.landing == 'w14':\n        ArtHandler.landing = '/docs/design/achievement-house-r39/index.html'\n    handler = partial")
assert (ROOT / server).read_text() == expected
checks.append('Delivery allowlist: no app/CI/CODE package/task/prompt/W08/r38 changes; server only adds w14')
report = {'date': '2026-10-18', 'scope': 'As-of-r39 design delivery, against pinned base; not a future whole-repo invariant',
          'reference_hashes': refs, 'artifact_hashes': artifacts, 'evidence_hashes': evidence,
          'source_blobs': len(manifest['sources']), 'source_definitions': len(rows), 'local_links': links,
          'passed': checks}
(OUT / 'evidence/static-checks.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print(json.dumps(report, ensure_ascii=False, indent=2))
