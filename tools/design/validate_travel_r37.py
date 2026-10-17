#!/usr/bin/env python3
"""Validate W08 study provenance and receipts, without accepting app/runtime work."""
from pathlib import Path
import hashlib
import json
import re
import struct
import subprocess
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
ROOT = Path(__file__).resolve().parents[2]
BASE = ROOT / 'docs/design/world-travel-r37'
m = json.loads((BASE / 'manifest.json').read_text())
def sha(data): return hashlib.sha256(data).hexdigest()
def git(*args): return subprocess.check_output(['git', *args], cwd=ROOT)
for item in m['artifacts']:
    assert sha((BASE / item['path']).read_bytes()) == item['sha256'], item['path']
for item in m['references'] + m['contracts']:
    assert sha((ROOT / item['path']).read_bytes()) == item['sha256'], item['path']
    assert sha(git('show', f"{m['design_pin']}:{item['path']}")) == item['sha256']
pin = m['runtime_read_only_reference']
assert git('rev-parse', f"{pin['commit']}:{pin['path']}").decode().strip() == pin['blob']
image = (BASE / m['image']['path']).read_bytes()
assert list(struct.unpack('>II', image[16:24])) == m['image']['dimensions'] == [928, 1152]
assert image[25] == m['image']['png_color_type']
assert not m['runtime_changed'] and not m['runtime_ready'] and not m['production_approved']
class Links(HTMLParser):
    def __init__(self): super().__init__(); self.links = []
    def handle_starttag(self, tag, attrs):
        self.links += [v for k, v in attrs if k in ('href', 'src') and v]
parser = Links(); parser.feed((BASE / 'index.html').read_text())
links = list(parser.links)
links += re.findall(r'url\([\'\"]?([^\)\'\"]+)', (BASE / 'style.css').read_text())
for name in ('README.md', 'SPEC.md'):
    links += re.findall(r'\]\(([^)]+)\)', (BASE / name).read_text())
for link in links:
    url = urlsplit(link)
    if url.scheme or url.netloc: continue
    if url.path: assert (BASE / unquote(url.path)).exists(), link
for name in ('model.js', 'copy.js', 'study.js'):
    subprocess.run(['node', '--check', str(BASE / name)], check=True)
anchors = json.loads((BASE / 'anchors.json').read_text())
js = (BASE / 'study.js').read_text()
for route in anchors['routes'].values(): assert route in js
browser = json.loads((BASE / 'evidence/browser-checks.json').read_text())
model = json.loads((BASE / 'evidence/model-checks.json').read_text())
assert browser['cases'] == len(browser['results']) == 456 and browser['invalidCases'] == 0
assert not browser['errors'] and not browser['externalRequests'] and len(browser['flows']) == 12
assert model['tests'] == 16 and all(r['status'] == 'PASS' for r in model['results'])
# Scope guard: this independent study must not overwrite CODE's accepted input/work areas.
protected = ['app', '.github', 'docs/design/art-completion-r36/code', 'docs/design/art-sync-r35',
             'docs/design/art-review-r36', 'docs/implementation/coordination/tasks/PQC-018.md']
assert not git('diff', '--name-only', m['design_pin'], '--', *protected).strip()
report = {'artifacts_hashed': len(m['artifacts']), 'reference_and_contract_pins': len(m['references']) + len(m['contracts']),
          'runtime_source_blob': 'MATCH', 'local_links_checked': len(links), 'js_syntax_files': 3,
          'browser_cases': 456, 'browser_flows': 12, 'model_checks': 16, 'protected_scope_changed': False,
          'runtime_or_production_approval': False}
(BASE / 'evidence/static-checks.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
