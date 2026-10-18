"""r56 DESIGN-only integrity: source, catalog, art, receipts, links and scope."""
from pathlib import Path
import hashlib, json, re, subprocess
from PIL import Image
ROOT=Path(__file__).resolve().parents[2];P=ROOT/'docs/design/arrival-entrance-r56'
BASE='58d08d5ab160de59b678a012830a58020f5b5130';PIN='5c97577c32c27d36f33c09bf3af2fa01ad0111f5'
def raw(path,sha=PIN):return subprocess.check_output(['git','show',sha+':'+path],cwd=ROOT)
def digest(data):return hashlib.sha256(data).hexdigest()
source=json.loads((P/'source-manifest.json').read_text());assert source['code_pin']==PIN;assert len(source['files'])==21
for item in source['files']:assert digest(raw(item['path']))==item['sha256'],item['path']
c=json.loads((P/'catalog.json').read_text());assert c['source_pin']==PIN
modules=['main_quest/main_quest','robot_maze/robot_maze','dragon_jump/dragon_jump','catch_stars/catch_stars','bug_hunter/bug_hunter','achievements/achievement_house']
registry=raw('app/lib/app/activity_registry.dart').decode().split('activityRegistry = [')[1].split('];')[0]
assert re.findall(r'(\w+Module)\(\)',registry)==['MainQuestModule','RobotMazeModule','DragonJumpModule','CatchStarsModule','BugHunterModule','AchievementHouseModule']
assert [x['id'] for x in c['activities']]==['main_quest','robot_maze','dragon_jump','catch_stars','bug_hunter','achievement_house']
for a,m in zip(c['activities'],modules):
    block=raw('app/lib/modules/'+m+'_module.dart').decode().split('final ActivityDef def = const ActivityDef(')[1].split('\n  );')[0]
    for key in ['name','tagline','description']:assert a[key]['vi']==re.search(key+r": '([^']*)'",block).group(1);assert a[key]['en']
    assert a['host']==re.search(r'host: CharacterId\.(\w+)',block).group(1)
    assert a['needsPython']==('needsPython: true' in block);assert a['hasCreatorMode']==('hasCreatorMode: true' in block)
    assert a['source_thumbnail']==re.search(r"thumbnail: '([^']*)'",block).group(1)
    assert (P/a['study_scene']).exists()
quest=json.loads(raw('app/assets/data/main_quest_ch1.json'));maze=json.loads(raw('app/assets/data/robot_maze_levels.json'));bugs=json.loads(raw('app/assets/data/bug_hunter_puzzles.json'));config=json.loads(raw('app/assets/config/game_config.json'))
assert c['chapter']==quest['chapter'];assert c['unlockLessonId']==bugs['packs'][0]['requires_lesson']
assert c['totals']['lessons']==len(quest['lessons']);assert c['totals']['maze']==len(maze['levels']);assert c['totals']['puzzles']==len(bugs['puzzles']);assert c['totals']['bugs']==sum(len(p['bugs']) for p in bugs['puzzles'])
for a,b in zip(c['lessons'],quest['lessons']):assert (a['id'],a['number'],a['title']['vi'])==(b['id'],b['number'],b['title'])
assert c['config']['energy']==config['energy'];assert c['config']['costs']==config['energy_costs']
ach=raw('app/lib/modules/achievements/achievement_catalog.dart').decode().split('final List<AchievementDef> achievementCatalog = [')[1]
assert c['totals']['badges']==len(re.findall(r'AchievementDef\(',ach));assert c['totals']['secretBadges']==ach.count('secret: true')
expected=[{'id':id,'threshold':int(n)} for id,n in re.findall(r"Constellation\('([^']+)', '[^']+', (\d+)",raw('app/lib/modules/catch_stars/stars_game.dart').decode())];assert c['constellations']==expected
welcome=re.findall(r"CharacterId\.(\w+),\s*'([^']+)',\s*'([^']+)',",raw('app/lib/modules/main_map/main_map_screen.dart').decode().split('static const _pages = [')[1].split('];')[0]);assert c['welcome_source']==[{'host':h,'title':t,'body':b} for h,t,b in welcome]
art=json.loads((P/'assets/provenance.json').read_text());assert art['runtime_ready'] is False
for entry in art['files']:
    path=P/entry['path'];assert digest(path.read_bytes())==entry['sha256'];assert path.stat().st_size==entry['bytes']
    with Image.open(path) as im:
        im.load();assert list(im.size)==entry['size']
        if '-token' in path.name:assert im.mode=='RGBA' and im.getchannel('A').getextrema()==(0,255)
for entry in art['references']:assert digest((ROOT/entry['path']).read_bytes())==entry['sha256']
obs=json.loads((P/'partner-observation.json').read_text());assert len(obs['unchanged_pinned_files'])==21
for entry in source['files']:assert digest(raw(entry['path'],obs['observed_code_tip']))==entry['sha256']
model=json.loads((P/'evidence/model-checks.json').read_text());browser=json.loads((P/'evidence/browser-checks.json').read_text())
assert model['checks']==len(model['passed'])==36 and model['zeroChargeCombinations']==18 and model['failures']==0
assert browser['cases']==252 and browser['targets']==768 and browser['fontChecks']==468 and browser['flows']==278 and not browser['errors']
assert len(browser['captures'])==22
for image in browser['captures']:
    with Image.open(ROOT/image) as im:im.load()
links=0
for file in [P/'README.md',P/'SPEC.md',P/'ASSET_PLAN.md',P/'index.html',ROOT/'docs/design/coordination/tasks/PQD-017.md']:
    for ref in re.findall(r'\]\(([^)]+)\)',file.read_text())+re.findall(r'(?:href|src)="([^"#]+)"',file.read_text()):
        if ref.startswith(('http:','https:','#')):continue
        target=(file.parent/ref.split('#')[0]).resolve();assert target.exists() or target==P/'evidence/static-checks.json',(file,ref);links+=1
changed=subprocess.check_output(['git','diff','--name-only',BASE],cwd=ROOT,text=True).splitlines()+subprocess.check_output(['git','ls-files','--others','--exclude-standard'],cwd=ROOT,text=True).splitlines()
allowed={'docs/PROJECT_STATUS.md','docs/design/VISUAL_DESIGN_STATUS.md','docs/design/coordination/tasks/PQD-017.md','tools/design/serve_art_review.py','tools/design/build_arrival_r56.py','tools/design/test_arrival_r56.mjs','tools/design/check_arrival_r56.cjs','tools/design/validate_arrival_r56.py'}
assert all(x.startswith('docs/design/arrival-entrance-r56/') or x in allowed for x in changed),changed
report={'scope':'DESIGN-only integrity; not Flutter or runtime acceptance','source_pins':len(source['files']),'unchanged_at_observed_CODE_tip':len(obs['unchanged_pinned_files']),'catalog_activities':len(c['activities']),'welcome_pages':len(c['welcome_source']),'art_files':len(art['files']),'reference_hashes':len(art['references']),'captures':len(browser['captures']),'local_links':links,'runtime_or_CI_changes':0,'failures':0,'study_inputs':{name:digest((P/name).read_bytes()) for name in ['index.html','style.css','app.mjs','model.mjs','copy.mjs','catalog.json']}}
(P/'evidence/static-checks.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
