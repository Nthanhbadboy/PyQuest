"""Check the r54 study source/art receipts and finite DESIGN scope; not Flutter."""
from pathlib import Path
import hashlib,json,re,subprocess
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];P=ROOT/'docs/design/dragon-run-r54'
BASE='137bb208a80f3d64cc24fda2632a86d130316f9d';PIN='6dc8ca8feeed54cc0fa6a82109e3a59d24a16153'
source=json.loads((P/'source-manifest.json').read_text());assert source['code_pin']==PIN
for entry in source['files']:
    raw=subprocess.check_output(['git','show',PIN+':'+entry['path']],cwd=ROOT)
    assert hashlib.sha256(raw).hexdigest()==entry['sha256'],entry['path']
config=json.loads(subprocess.check_output(['git','show',PIN+':app/assets/config/game_config.json'],cwd=ROOT))
rules=json.loads((P/'rules.json').read_text());assert rules['dragon_jump']==config['dragon_jump'];assert rules['run_cost']==config['energy_costs']['arcade_run']==2
assert rules['dragon_jump']['star_scores']==[150,300,500]
art=json.loads((P/'assets/provenance.json').read_text());assert art['runtime_ready'] is False
for entry in art['files']:
    file=P/entry['path'];assert hashlib.sha256(file.read_bytes()).hexdigest()==entry['sha256'];assert file.stat().st_size==entry['bytes']
    with Image.open(file) as im:
        assert list(im.size)==entry['size'];im.load()
        if '-token' in file.name:
            assert im.mode=='RGBA' and im.getchannel('A').getextrema()==(0,255)
for entry in art['references']:
    assert hashlib.sha256((ROOT/entry['path']).read_bytes()).hexdigest()==entry['sha256']
model=json.loads((P/'evidence/model-checks.json').read_text());browser=json.loads((P/'evidence/browser-checks.json').read_text())
assert model['checks']==30 and model['recordComparisons']==1000 and model['failures']==0
assert browser['cases']==192 and browser['fontChecks']==300 and browser['flows']==99 and not browser['errors']
for image in browser['captures']:
    with Image.open(ROOT/image) as im:im.load()
links=0
for file in [P/'README.md',P/'SPEC.md',P/'ASSET_PLAN.md',P/'index.html']:
    for ref in re.findall(r'\]\(([^)]+)\)',file.read_text())+re.findall(r'(?:href|src)="([^"#]+)"',file.read_text()):
        if ref.startswith(('http:', 'https:', '#')):continue
        target=(file.parent/ref.split('#')[0]).resolve()
        assert target.exists() or target==P/'evidence/static-checks.json',(file,ref)
        links+=1
changed=subprocess.check_output(['git','diff','--name-only',BASE],cwd=ROOT,text=True).splitlines()+subprocess.check_output(['git','ls-files','--others','--exclude-standard'],cwd=ROOT,text=True).splitlines()
allowed={'docs/PROJECT_STATUS.md','docs/design/VISUAL_DESIGN_STATUS.md','docs/design/coordination/tasks/PQD-015.md','tools/design/serve_art_review.py','tools/design/build_dragon_r54.py','tools/design/check_dragon_r54.cjs','tools/design/test_dragon_r54.mjs','tools/design/validate_dragon_r54.py'}
assert all(x.startswith('docs/design/dragon-run-r54/') or x in allowed for x in changed),changed
result={'scope':'DESIGN-only source/art/receipt integrity; no runtime acceptance','source_pins':len(source['files']),'art_files':len(art['files']),'reference_hashes':len(art['references']),'captures':len(browser['captures']),'local_links':links,'runtime_or_CI_changes':0,'failures':0}
(P/'evidence/static-checks.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
