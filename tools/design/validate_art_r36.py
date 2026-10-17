#!/usr/bin/env python3
"""Validate immutable CODE Batch A provenance against exact Git objects."""
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
CODE = '1053973da1ad11378f7263d7b13a4d61667133af'
DESIGN = 'cbb0f8bed808a888ae607bb31ba6343c182bf0b8'
PKG = 'docs/design/art-completion-r36/code'

def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)

def sha(data):
    return hashlib.sha256(data).hexdigest()

files = git('ls-tree', '-r', '--name-only', CODE, '--', PKG).decode().splitlines()
assert len(files) == 54
for name in files:
    assert (ROOT / name).read_bytes() == git('show', f'{CODE}:{name}'), name
review = json.loads((ROOT / PKG / 'reviewed-inputs.json').read_text())
cat_bytes = git('show', f"{DESIGN}:{review['catalog_path_at_pin']}")
assert sha(cat_bytes) == review['catalog_sha256']
cat = json.loads(cat_bytes)
base = (ROOT / review['catalog_path_at_pin']).parent
by_id = {a['id']: a for a in cat['assets']}
assert len(review['assets']) == len(by_id) == 16
for item in review['assets']:
    a = by_id[item['id']]
    assert item['sha256'] == a['sha256'] == sha((base / a['path']).read_bytes())
    assert item['active_path'] == a['path'] and item['viewed_fullsize']
    assert item['observation']
source_blobs = 0
states = 0
for folder in sorted((ROOT / PKG).glob('a0*')):
    m = json.loads((folder / 'manifest.json').read_text())
    for key in ('image', 'layout'):
        item = m[key]
        assert sha((folder / item['path']).read_bytes()) == item['sha256'], (folder, key)
    assert sha((folder / m['image']['prompt_path']).read_bytes()) == m['image']['prompt_sha256']
    for shared in ('shared_css', 'shared_js'):
        assert sha((folder / m['layout'][shared]).read_bytes()) == m['layout'][shared + '_sha256']
    for ref in m['references']:
        a = by_id[ref['id']]
        assert ref['path'] == a['path'] and ref['sha256'] == a['sha256']
    for pin in m['pinned_runtime_source_files']:
        actual = git('rev-parse', f"{m['runtime_identity_pin']}:{pin['path']}").decode().strip()
        assert actual == pin['git_blob_sha'], pin
        source_blobs += 1
    assert not m['runtime_ready'] and not m['production_approved'] and not m['animation_present']
    states += len(m['layout']['states'])
assert source_blobs == 15 and states == 20
runtime_changed = git('diff', '--name-only', review['runtime_identity_pin'], CODE, '--', 'app', '.github').decode().splitlines()
assert not runtime_changed
inventory = json.loads((ROOT / 'docs/design/art-review-r36/catalog.json').read_text())
assert inventory['count'] == len(inventory['assets']) == 21
assert not inventory['production_approved'] and not inventory['runtime_ready']
assert (ROOT / review['catalog_path_at_pin']).read_bytes() == cat_bytes
for entry in inventory['assets']:
    assert sha((ROOT / 'docs/design/art-review-r36' / entry['path']).read_bytes()) == entry['sha256']
assert (ROOT / 'docs/design/coordination/reviews/PQC-018-r1/code-handoff.md').read_bytes() == git('show', f'{CODE}:docs/implementation/coordination/tasks/PQC-018.md')
report = {'review_inventory_assets': 21, 'r35_catalog_unchanged': True, 'reviewed_sha': CODE, 'design_pin': DESIGN, 'exact_imports': len(files),
          'catalog_assets_and_review_records': len(by_id), 'scene_manifests': 5,
          'source_blob_checks': source_blobs, 'states': states, 'app_ci_changes_since_runtime_pin': runtime_changed,
          'limits': ['Recorded full-size viewing is a CODE declaration; provenance checking alone cannot prove human viewing.',
                     'DESIGN separately opened all five new concept images.', 'Static provenance PASS is not layout or runtime acceptance.']}
out = ROOT / 'docs/design/art-review-r36/evidence/independent-static.json'
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n')
print(json.dumps(report, indent=2, ensure_ascii=False))
