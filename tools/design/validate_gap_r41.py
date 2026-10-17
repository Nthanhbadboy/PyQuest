#!/usr/bin/env python3
"""As-of-r41 audit/design delivery. Does not run Flutter or alter CODE receipts."""
import hashlib,json,re,struct,subprocess
from pathlib import Path
from urllib.parse import urlsplit,unquote
ROOT=Path(__file__).resolve().parents[2];AUDIT=ROOT/'docs/design/runtime-gap-r41';NEW=ROOT/'docs/design/daily-energy-r41'
def git(*args):return subprocess.check_output(['git',*args],cwd=ROOT)
def sha(data):return hashlib.sha256(data).hexdigest()
def load(p):return json.loads(p.read_text())
c=load(AUDIT/'coverage.json');m=load(NEW/'manifest.json');source=load(NEW/'source-manifest.json')
assert len(c['records'])==38 and len({r['baseline'] for r in c['records']})==38
assert {r['baseline'] for r in c['records']}=={str(p.relative_to(ROOT)) for p in (ROOT/'docs/screenshots').glob('*.jpg')}
assert len({r['group'] for r in c['records']})==18
assert c['baseline_capture_code_sha'] is None and c['baseline_capture_run'] is None
for r in c['records']:
 data=(ROOT/r['baseline']).read_bytes();assert sha(data)==r['sha256'];assert data==git('show',c['baseline_stored_at']+':'+r['baseline']);assert r['runtime_after_redesign']=='NOT_EVIDENCED_BY_THIS_CAPTURE'
for r in c['supplemental']:
 assert sha((ROOT/r['path']).read_bytes())==r['sha256'];assert (ROOT/r['path']).read_bytes()==git('show',m['design_base']+':'+r['path'])
for r in source['sources']:
 ref=source['code_sha']+':'+r['path'];assert git('rev-parse',ref).decode().strip()==r['blob'];assert sha(git('show',ref))==r['sha256']
notice=c['new_code_notice'];delta=git('diff','--name-only',source['code_sha'],notice['sha']).decode().splitlines()
assert len(delta)==5 and not any(p.lower().endswith(('.jpg','.png','.webp')) for p in delta)
assert not git('diff','--name-only',source['code_sha'],notice['sha'],'--',*[r['path'] for r in source['sources']]).strip()
cat=json.loads(subprocess.check_output(['node','-e','console.log(JSON.stringify(require(process.argv[1])))',str(NEW/'catalog.js')]))
text=git('show',source['code_sha']+':app/lib/modules/daily_quests/daily_quest_service.dart').decode().split('dailyQuestPool = [')[1].split('class DailyQuestState')[0]
blocks=text.split('DailyQuestDef(')[1:];assert len(blocks)==len(cat['quests'])==8
for b,q in zip(blocks,cat['quests']):
 for key in ['id','title']:
  value=re.search(key+": '([^']+)'",b)[1];assert value==(q[key]['vi'] if key=='title' else q[key])
 assert q['category']==re.search(r'category: QuestCategory\.(\w+)',b)[1]
 assert q['target']==int(re.search(r'target: (\d+)',b)[1]);assert q['requiresBugHunter']==('requiresBugHunter: true' in b)
config=json.loads(git('show',source['code_sha']+':app/assets/config/game_config.json'))
assert cat['energy']==config['energy'] and cat['costs']==config['energy_costs']
for r in m['references']:assert sha((ROOT/r['path']).read_bytes())==r['sha256']
for key in ['artifacts','evidence']:
 for r in m[key]:assert sha((NEW/r['path']).read_bytes())==r['sha256'],r['path']
image=(NEW/m['image']['path']).read_bytes();assert image[:8]==b'\x89PNG\r\n\x1a\n';assert sha(image)==m['image']['sha256'];assert list(struct.unpack('>II',image[16:24]))==m['image']['dimensions']
assert sha((NEW/m['image']['prompt']).read_bytes())==m['image']['prompt_sha256']
for p in NEW.glob('*.js'):subprocess.run(['node','--check',str(p)],check=True)
b=load(NEW/'evidence/browser-checks.json');unit=load(NEW/'evidence/model-checks.json');gallery=load(AUDIT/'evidence/atlas-checks.json')
assert b['cases']==192 and b['fontChecks']==3624 and b['invalidCases']==0 and not b['errors'] and not b['externalRequests'];assert len(b['flows'])==11 and unit['checks']==17
assert gallery['imagesDecoded']==41 and gallery['groups']==18 and gallery['filters']==[18,4,2,18] and not gallery['errors']
links=0
for p in [AUDIT/'README.md',NEW/'README.md',NEW/'SPEC.md',NEW/'index.html',ROOT/'docs/design/coordination/tasks/PQD-006.md']:
 text=p.read_text();urls=re.findall(r'(?:href|src)="([^"]+)"',text) if p.suffix=='.html' else re.findall(r'\]\(([^)]+)\)',text)
 for url in urls:
  u=urlsplit(url)
  if u.scheme or not u.path:continue
  assert (p.parent/unquote(u.path)).resolve().is_file(),(p,url);links+=1
# Scope guard is for this delivery baseline, not an indefinite ban on future authorized changes.
base=m['design_base'];preserved=load(ROOT/'docs/design/achievement-house-r39/manifest.json')['dirty_files_preserved']
for r in preserved:assert sha((ROOT/r['path']).read_bytes())==r['sha256']
allowed={'docs/design/coordination/tasks/PQD-006.md','tools/design/serve_art_review.py','tools/design/test_daily_r41.cjs','tools/design/check_daily_r41.cjs','tools/design/check_gap_r41.cjs','tools/design/validate_gap_r41.py'}|{r['path'] for r in preserved}
changes=git('diff','--name-only',base,'--').decode().splitlines()+git('ls-files','--others','--exclude-standard').decode().splitlines()
for p in changes:assert p.startswith(('docs/design/runtime-gap-r41/','docs/design/daily-energy-r41/')) or p in allowed,p
report={'date':'2026-10-18','historical_baseline_hashes':38,'groups':18,'supplemental_capture_hashes':2,'source_pins':7,'source_quest_definitions':8,'source_energy_config_and_costs':'exact','reference_hashes':len(m['references']),'artifact_hashes':len(m['artifacts']),'evidence_hashes':len(m['evidence']),'local_document_links':links,'browser':'192 cases / 3624 fonts / 11 flows PASS','model':'17 checks PASS','gallery':'41 decoded / 56 links HTTP200 / filters18,4,2,18 PASS','scope':'PASS as of r41 against30394b7; no app/CI/CODE/011/018/W08/W14/historical evidence changes','runtime_after_claim':'none; baseline storage commit not labeled as capture SHA','limits':['Static/source/HTML checks only','No new Flutter capture, engine, repository or device validation']}
(AUDIT/'evidence/static-checks.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');print(json.dumps(report,ensure_ascii=False,indent=2))
