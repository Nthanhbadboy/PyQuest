#!/usr/bin/env python3
"""Independent exact-commit/provenance review. Never execute archived CODE checkers."""
from pathlib import Path
import hashlib,json,struct,subprocess
ROOT=Path(__file__).resolve().parents[2];BASE=ROOT/'docs/design/art-review-r40';PKG=BASE/'code-snapshot'
SHA='4fe3b7d0a1bf5f6dface1b04cbc4e2d7ee9d451f';OLD='0990fbcbf6045bd64244239e36ccbca8c8dc394b';SRC='docs/design/art-completion-r36/code/'
def git(*args):return subprocess.check_output(['git',*args],cwd=ROOT)
def digest(data):return hashlib.sha256(data).hexdigest()
def load(path):return json.loads(path.read_text())
manifest=load(BASE/'snapshot-manifest.json');files=git('ls-tree','-r','--name-only',SHA,'--',SRC).decode().splitlines()
assert [SRC+i['path'] for i in manifest['files']]==files
for i in manifest['files']:
 p=PKG/i['path'];data=git('show',f"{SHA}:{SRC}{i['path']}")
 assert p.read_bytes()==data and digest(data)==i['sha256'] and len(data)==i['bytes'],i['path']
 if i['storage']=='symlink-to-immutable-r38':assert p.is_symlink() and p.resolve().is_relative_to(ROOT/'docs/design/art-review-r38/code-snapshot')
 else:assert not p.is_symlink()
archive=load(PKG/'evidence/r38-originals/originals.json');assert archive['baseline_commit']==OLD;assert len(archive['files'])==36
for i in archive['files']:
 source=i['path'] if i['path'].startswith('docs/') else SRC+i['path'];original=git('show',f'{OLD}:{source}')
 p=PKG/i['path'] if i['archive_path']=='unchanged-in-place' else PKG/'evidence/r38-originals'/i['archive_path']
 assert original==p.read_bytes() and digest(original)==i['sha256'] and len(original)==i['bytes'],i['path']
# Every pre-existing archived original remains exactly intact in this correction.
old_archive_files=[p for p in git('ls-tree','-r','--name-only',OLD,'--',SRC+'evidence/r36a-originals').decode().splitlines()]
for p in old_archive_files:assert git('show',f'{OLD}:{p}')==git('show',f'{SHA}:{p}')
inputs=load(PKG/'reviewed-inputs.json');cat_bytes=git('show',f"{inputs['design_pin']}:{inputs['catalog_path_at_pin']}")
assert digest(cat_bytes)==inputs['catalog_sha256'];cat=json.loads(cat_bytes);assets={a['id']:a for a in cat['assets']};cat_base=(ROOT/inputs['catalog_path_at_pin']).parent
assert len(inputs['assets'])==16
for a in inputs['assets']:
 c=assets[a['id']];assert a['active_path']==c['path'] and a['sha256']==c['sha256']==digest((cat_base/c['path']).read_bytes())
 assert a['viewed_fullsize'] and a['observation']
scenes=sources=states=0
for folder in sorted(PKG.glob('[ab]0*')):
 m=load(folder/'manifest.json');scenes+=1;states+=len(m['layout']['states']);data=(folder/'concept.png').read_bytes()
 assert digest(data)==m['image']['sha256'] and len(data)==m['image']['bytes'];assert list(struct.unpack('>II',data[16:24]))==m['image']['dimensions']
 assert data==git('show',f'{OLD}:{SRC}{folder.name}/concept.png')
 assert digest((folder/m['image']['prompt_path']).read_bytes())==m['image']['prompt_sha256']
 assert (folder/'prompt.txt').read_bytes()==git('show',f'{OLD}:{SRC}{folder.name}/prompt.txt')
 assert digest((folder/m['layout']['path']).read_bytes())==m['layout']['sha256']
 for key in ['shared_css','shared_js','batch_css','batch_js']:
  if key in m['layout']:assert digest((folder/m['layout'][key]).read_bytes())==m['layout'][key+'_sha256']
 for ref in m['references']+m.get('excluded_references',[]):
  c=assets[ref['id']];assert ref['path']==c['path'] and ref['sha256']==c['sha256']
 for pin in m.get('pinned_runtime_source_files',[]):
  assert git('rev-parse',f"{m['runtime_identity_pin']}:{pin['path']}").decode().strip()==pin['git_blob_sha'];sources+=1
 assert not m['runtime_ready'] and not m['production_approved'] and not m['animation_present']
 if folder.name!='b02-w12-creator-editor':assert (folder/'layout.html').read_bytes()==git('show',f'{OLD}:{SRC}{folder.name}/layout.html')
assert (scenes,states,sources)==(9,36,15)
assert (PKG/'shared.js').read_bytes()==git('show',f'{OLD}:{SRC}shared.js')
assert not git('diff','--name-only',inputs['runtime_identity_pin'],SHA,'--','app','.github').strip()
changed=git('diff','--name-only',OLD,SHA).decode().splitlines();assert all(p.startswith(SRC) or p=='docs/implementation/coordination/tasks/PQC-018.md' for p in changed)
assert git('rev-parse',SHA+'^').decode().strip()==OLD
handoff=ROOT/'docs/design/coordination/reviews/PQC-018-r3/code-handoff.md';assert handoff.read_bytes()==git('show',f'{SHA}:docs/implementation/coordination/tasks/PQC-018.md')
assert '79/79' in handoff.read_text()
code_report=load(PKG/'evidence/r38-static-checks.json');assert code_report['check_count']==code_report['passed']==129 and code_report['failed']==0
assert len(code_report['checks'])==129 and all(c['status']=='PASS' for c in code_report['checks'])
prose=load(PKG/'b02-w12-creator-editor/manifest.json')['editor_sample_provenance'];assert prose['origin'] and prose['not_game_api_or_canon'] and prose['not_lesson_answer_or_grader']
for k in ['executable','interpreter','persistence','publishing']:assert prose[k] is False
b=load(BASE/'evidence/independent-browser.json');assert b['cases']==432 and b['invalidCases']==0 and b['errors']==[] and b['externalRequests']==[]
assert b['editorContentChecks']==48 and b['editorFontAssertions']==144 and b['fontAssertions']==3204
report={'date':'2026-10-18','source_sha':SHA,'exact_content_imports':len(files),'unchanged_content_symlinks':sum(i['storage']=='symlink-to-immutable-r38' for i in manifest['files']),'new_archive_entries_verified_against_git':36,'old_archive_files_unchanged':len(old_archive_files),'canonical_review_records':16,'manifests':9,'states':36,'runtime_source_blobs':15,'all_nine_PNGs_and_prompts_unchanged':True,'other_eight_layouts_and_shared_js_unchanged':True,'code_correction_allowlist':'PASS','single_substantive_commit':True,'app_ci_diff_since_a331':False,'code_static_receipt':'129/129 preserved, inspected, not re-executed','independent_browser':'432 PASS; editor48; font3204 including editor144','limits':['This is an independent provenance check, not a re-run of CODE static129 script','Hashes do not certify visual review; targeted product captures separately viewed','No app/device/engine/production acceptance']}
(BASE/'evidence/independent-static.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
