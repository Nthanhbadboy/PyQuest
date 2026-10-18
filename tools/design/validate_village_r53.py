"""Static provenance and scope checks for the r53 DESIGN handoff, not Flutter tests."""
from pathlib import Path
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
P = ROOT / 'docs/design/r1-village-r53'
manifest = json.loads((P / 'manifest.json').read_text())
source = json.loads((P / 'source-manifest.json').read_text())
asset = manifest['asset']
assert hashlib.sha256((P / asset['path']).read_bytes()).hexdigest() == asset['sha256']
assert (P / asset['path']).stat().st_size == asset['bytes']
assert hashlib.sha256((ROOT / asset['source']).read_bytes()).hexdigest() == asset['source_sha256']
assert manifest['code_pin'] == source['code_pin'] == '6dc8ca8feeed54cc0fa6a82109e3a59d24a16153'
for entry in source['files']:
    raw = subprocess.check_output(['git', 'show', source['code_pin'] + ':' + entry['path']], cwd=ROOT)
    assert hashlib.sha256(raw).hexdigest() == entry['sha256'], entry['path']
review = json.loads((ROOT / 'docs/design/coordination/reviews/PQC-011-r53/evidence.json').read_text())
assert review['head_sha'] == source['code_pin'] and review['conclusion'] == 'success'
assert review['regular_ci']['headSha'] == source['code_pin'] and review['regular_ci']['conclusion'] == 'success'
model = json.loads((P / 'evidence/model-checks.json').read_text())
browser = json.loads((P / 'evidence/browser-checks.json').read_text())
assert model['checks'] == 15 and model['failures'] == 0
assert browser['cases'] == 60 and browser['fontChecks'] == 360 and browser['flows'] == 108 and not browser['errors']
for name in browser['captures']:
    assert (ROOT / name).is_file(), name
links = 0
for file in [P / 'README.md', P / 'SPEC.md', P / 'index.html',
             ROOT / 'docs/implementation/coordination/tasks/PQC-020.md',
             ROOT / 'docs/design/coordination/reviews/PQC-011-r53/README.md']:
    text = file.read_text()
    refs = re.findall(r'\]\(([^)]+)\)', text) + re.findall(r'(?:href|src)="([^"#]+)"', text)
    for ref in refs:
        if ref.startswith(('http:', 'https:', '#')):
            continue
        target = (file.parent / ref.split('#')[0]).resolve()
        assert target.exists() or target == (P / 'evidence/static-checks.json'), (file, ref)
        links += 1
changed = subprocess.check_output(['git', 'diff', '--name-only', 'b116bb86e12101c498bd33d984d927f0b188689d'], cwd=ROOT, text=True).splitlines()
changed += subprocess.check_output(['git', 'ls-files', '--others', '--exclude-standard'], cwd=ROOT, text=True).splitlines()
assert not any(p.startswith(('app/', '.github/', 'ci/')) for p in changed), changed
result = {'scope': 'DESIGN integrity, not runtime acceptance', 'source_pins': len(source['files']),
          'asset_hashes': 2, 'local_links': links, 'capture_files': len(browser['captures']),
          'acceptance_sha': source['code_pin'], 'tracked_runtime_or_ci_changes': 0, 'failures': 0}
(P / 'evidence/static-checks.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
