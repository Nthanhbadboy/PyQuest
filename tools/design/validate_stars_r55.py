"""Validate r55 source/art/catalog/receipts and bounded DESIGN scope, not Flutter."""
from pathlib import Path
import hashlib, json, re, subprocess
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]; P=ROOT/'docs/design/catch-stars-r55'
BASE='f26396d29358f2c98b91533e69255f78ac7768e5'; PIN='6dc8ca8feeed54cc0fa6a82109e3a59d24a16153'
def raw(path,sha=PIN):return subprocess.check_output(['git','show',sha+':'+path],cwd=ROOT)
def digest(data):return hashlib.sha256(data).hexdigest()
source=json.loads((P/'source-manifest.json').read_text());assert source['code_pin']==PIN
for item in source['files']:assert digest(raw(item['path']))==item['sha256'],item['path']
config=json.loads(raw('app/assets/config/game_config.json'));rules=json.loads((P/'rules.json').read_text())
assert rules['catch_stars']==config['catch_stars'];assert rules['catch_stars']['round_seconds']==45
assert rules['catch_stars']['star_scores']==[60,150,300];assert rules['catch_stars']['hearts']==3
assert rules['run_cost']==config['energy_costs']['arcade_run']==2
catalog=json.loads((P/'catalog.json').read_text())['constellations']
text=raw('app/lib/modules/catch_stars/stars_game.dart').decode()
pattern=r"Constellation\('([^']+)', '([^']+)', (\d+),\s*\[(.*?)\],\s*\[(.*?)\], '([^']+)'\)"
entries=re.findall(pattern,text,re.S);assert len(entries)==len(catalog)==8
for c,(id,name,n,pts,lines,story) in zip(catalog,entries):
    assert (c['id'],c['name']['vi'],c['threshold'],c['story']['vi'])==(id,name,int(n),story)
    assert c['points']==[[float(a),float(b)] for a,b in re.findall(r'Offset\(([^,]+), ([^)]+)\)',pts)]
    assert c['lines']==[[int(a),int(b)] for a,b in re.findall(r'\((\d+), (\d+)\)',lines)]
    assert c['name']['en'] and c['story']['en']
art=json.loads((P/'assets/provenance.json').read_text());assert art['runtime_ready'] is False
for item in art['files']:
    path=P/item['path'];assert digest(path.read_bytes())==item['sha256'];assert path.stat().st_size==item['bytes']
    with Image.open(path) as im:
        im.load();assert list(im.size)==item['size']
        if '-token' in path.name:assert im.mode=='RGBA' and im.getchannel('A').getextrema()==(0,255)
for item in art['references']:assert digest((ROOT/item['path']).read_bytes())==item['sha256']
model=json.loads((P/'evidence/model-checks.json').read_text());browser=json.loads((P/'evidence/browser-checks.json').read_text())
assert model['checks']==len(model['passed'])==32 and model['recordComparisons']==1000 and model['spawnSamples']==10000
assert browser['cases']==240 and browser['targets']==1236 and browser['fontChecks']==372 and browser['flows']==148 and not browser['errors']
for file in browser['captures']:
    with Image.open(ROOT/file) as im:im.load()
observation=json.loads((P/'partner-observation.json').read_text());assert len(observation['unchanged_source_files'])==8
for item in source['files']:assert digest(raw(item['path'],observation['code_tip_later']))==item['sha256']
links=0
for file in [P/'README.md',P/'SPEC.md',P/'ASSET_PLAN.md',P/'index.html',ROOT/'docs/design/coordination/tasks/PQD-016.md']:
    for ref in re.findall(r'\]\(([^)]+)\)',file.read_text())+re.findall(r'(?:href|src)="([^"#]+)"',file.read_text()):
        if ref.startswith(('http:','https:','#')):continue
        target=(file.parent/ref.split('#')[0]).resolve();assert target.exists() or target==P/'evidence/static-checks.json',(file,ref);links+=1
changed=subprocess.check_output(['git','diff','--name-only',BASE],cwd=ROOT,text=True).splitlines()+subprocess.check_output(['git','ls-files','--others','--exclude-standard'],cwd=ROOT,text=True).splitlines()
allowed={'docs/PROJECT_STATUS.md','docs/design/VISUAL_DESIGN_STATUS.md','docs/design/coordination/tasks/PQD-016.md','tools/design/serve_art_review.py','tools/design/build_stars_r55.py','tools/design/test_stars_r55.mjs','tools/design/check_stars_r55.cjs','tools/design/validate_stars_r55.py'}
assert all(f.startswith('docs/design/catch-stars-r55/') or f in allowed for f in changed),changed
report={'scope':'DESIGN-only integrity; no runtime acceptance','source_pins':len(source['files']),'source_unchanged_at_observed_CODE_tip':len(observation['unchanged_source_files']),'art_files':len(art['files']),'reference_hashes':len(art['references']),'catalog_entries':len(catalog),'captures':len(browser['captures']),'local_links':links,'runtime_or_CI_changes':0,'failures':0}
(P/'evidence/static-checks.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
