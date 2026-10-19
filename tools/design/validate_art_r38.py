#!/usr/bin/env python3
"""Audit exact CODE package0990fbc, originals and canonical input hashes."""
from pathlib import Path
import hashlib,json,struct,subprocess
ROOT=Path(__file__).resolve().parents[2]
BASE=ROOT/'docs/design/art-review-r38'; PKG=BASE/'code-snapshot'
SHA='0990fbcbf6045bd64244239e36ccbca8c8dc394b'; A='ab0ae35eafebf8602ef714d85004ad4b744898a4'; OLD='1053973da1ad11378f7263d7b13a4d61667133af'
SRC='docs/design/art-completion-r36/code/'
def git(*args):return subprocess.check_output(['git',*args],cwd=ROOT)
def sha(data):return hashlib.sha256(data).hexdigest()
files=git('ls-tree','-r','--name-only',SHA,'--',SRC).decode().splitlines()
assert len(files)==145
for f in files:assert (PKG/f[len(SRC):]).read_bytes()==git('show',f'{SHA}:{f}'),f
inputs=json.loads((PKG/'reviewed-inputs.json').read_text());cat_path=inputs['catalog_path_at_pin']
cat_bytes=git('show',f"{inputs['design_pin']}:{cat_path}");assert sha(cat_bytes)==inputs['catalog_sha256']
cat=json.loads(cat_bytes);assets={a['id']:a for a in cat['assets']};cat_base=(ROOT/cat_path).parent
assert len(inputs['assets'])==16
for a in inputs['assets']:
 canonical=assets[a['id']];assert a['active_path']==canonical['path'];assert a['sha256']==canonical['sha256']==sha((cat_base/canonical['path']).read_bytes());assert a['viewed_fullsize'] and a['observation']
archive=json.loads((PKG/'evidence/r36a-originals/originals.json').read_text())
for item in archive['files']:
 source_path=item['path'] if item['path'].startswith('docs/') else SRC+item['path']
 original=git('show',f'{OLD}:{source_path}')
 current=PKG/item['path'] if item['archive_path']=='unchanged-in-place' else PKG/'evidence/r36a-originals'/Path(item['archive_path']).name
 assert current.read_bytes()==original and sha(original)==item['sha256'],item['path']
scene_count=source_count=state_count=0
for folder in sorted(PKG.glob('[ab]0*')):
 m=json.loads((folder/'manifest.json').read_text());scene_count+=1;state_count+=len(m['layout']['states'])
 data=(folder/'concept.png').read_bytes();assert sha(data)==m['image']['sha256'];assert len(data)==m['image']['bytes'];assert list(struct.unpack('>II',data[16:24]))==m['image']['dimensions']
 assert sha((folder/m['image']['prompt_path']).read_bytes())==m['image']['prompt_sha256']
 assert sha((folder/m['layout']['path']).read_bytes())==m['layout']['sha256']
 for key in ['shared_css','shared_js','batch_css','batch_js']:
  if key in m['layout']:assert sha((folder/m['layout'][key]).read_bytes())==m['layout'][key+'_sha256']
 for ref in m['references']+m.get('excluded_references',[]):
  c=assets[ref['id']];assert ref['path']==c['path'] and ref['sha256']==c['sha256']
 for pin in m.get('pinned_runtime_source_files',[]):
  assert git('rev-parse',f"{m['runtime_identity_pin']}:{pin['path']}").decode().strip()==pin['git_blob_sha'];source_count+=1
 assert not m['runtime_ready'] and not m['production_approved'] and not m['animation_present']
 if folder.name.startswith('a'):
  assert data==git('show',f'{OLD}:{SRC}{folder.name}/concept.png')
  for name in ['layout.html','manifest.json','README.md']:
   assert (folder/name).read_bytes()==git('show',f'{A}:{SRC}{folder.name}/{name}')
for name in ['shared.css','shared.js']:assert (PKG/name).read_bytes()==git('show',f'{A}:{SRC}{name}')
assert (scene_count,state_count,source_count)==(9,36,15)
changed=git('diff','--name-only',OLD,SHA).decode().splitlines()
assert all(p.startswith(SRC) or p=='docs/implementation/coordination/tasks/PQC-018.md' for p in changed)
assert not git('diff','--name-only',inputs['runtime_identity_pin'],SHA,'--','app','.github').strip()
inventory=json.loads((BASE/'catalog.json').read_text());assert inventory['count']==len(inventory['assets'])==25
for item in inventory['assets']:assert sha((BASE/item['path']).read_bytes())==item['sha256']
for pin,name in [(A,'code-handoff-A.md'),(SHA,'code-handoff-B.md')]:
 assert (ROOT/'docs/design/coordination/reviews/PQC-018-r2'/name).read_bytes()==git('show',f'{pin}:docs/implementation/coordination/tasks/PQC-018.md')
report={'review_inventory_images':25,'source_sha':SHA,'correction_sha':A,'exact_imports':len(files),'original_archive_entries_verified':len(archive['files']),'canonical_review_records':16,'manifests':9,'states':36,'runtime_source_blobs':15,'original_A_images_unchanged':5,'A_active_files_unchanged_by_B':True,'code_allowlist':'PASS','app_ci_diff_since_a331':False,'limits':['Hash checks do not prove visual review; DESIGN separately opened four new concepts','Metadata structure cannot prove an editor exists','No runtime or production approval']}
(BASE/'evidence').mkdir(exist_ok=True);(BASE/'evidence/independent-static.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
