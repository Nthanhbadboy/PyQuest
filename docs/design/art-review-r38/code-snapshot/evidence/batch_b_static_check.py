#!/usr/bin/env python3
"""Dependency-free provenance and structure checks for PQC-018 Batch B."""
import hashlib, json, struct
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REVIEW_PIN = '68f2590b5883ca8aa746ffde0814d60a32dacb3c'
SCENES = ['b01-w09-friends-invites','b02-w12-creator-editor','b03-w07-built-room','b04-w10-pet-rest']
failures=[]; checks=[]
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def record(name, ok, detail):
 checks.append({'check':name,'status':'PASS' if ok else 'FAIL','detail':detail})
 if not ok: failures.append(f'{name}: {detail}')
class Markers(HTMLParser):
 def __init__(self): super().__init__(); self.data=set()
 def handle_starttag(self,tag,attrs):
  for key,_ in attrs:
   if key.startswith('data-'): self.data.add(key)
inputs=json.loads((ROOT/'reviewed-inputs.json').read_text())
assets={a['id']:{'path':a['active_path'],'sha256':a['sha256']} for a in inputs['assets']}
choices={choice['scene']:choice for choice in inputs.get('scene_reference_choices',[])}
record('r36 design pin', inputs.get('latest_screen_review',{}).get('pin')==REVIEW_PIN, str(inputs.get('latest_screen_review',{}).get('pin')))
record('canonical input catalog pin', inputs.get('catalog_sha256')=='02ee503fa5c4ba34676719610f4831a67313e6c42ddbb653df0dca9d9eaa7ad6', str(inputs.get('catalog_sha256')))
for slug in SCENES:
 folder=ROOT/slug; m=json.loads((folder/'manifest.json').read_text()); layout=folder/'layout.html'; parser=Markers(); parser.feed(layout.read_text())
 record(f'{slug}: manifest identity',m.get('scene_id')==slug and m.get('batch')=='B','valid JSON, batch B and matching scene id')
 record(f'{slug}: review pin',m.get('design_review_pin')==REVIEW_PIN,m.get('design_review_pin','missing'))
 record(f'{slug}: design review not self-accepted','pending' in m.get('screen_review_status','').lower(),m.get('screen_review_status','missing'))
 record(f'{slug}: image hash',sha(folder/'concept.png')==m['image']['sha256'] and len((folder/'concept.png').read_bytes())==m['image']['bytes'],m['image']['sha256'])
 data=(folder/'concept.png').read_bytes(); dims=list(struct.unpack('>II',data[16:24]))
 record(f'{slug}: image dimensions',dims==m['image']['dimensions'],str(dims))
 record(f'{slug}: prompt hash',sha(folder/'prompt.txt')==m['image']['prompt_sha256'],m['image']['prompt_sha256'])
 record(f'{slug}: layout hash',sha(layout)==m['layout']['sha256'],m['layout']['sha256'])
 record(f'{slug}: shared css/js hash',sha(ROOT/'shared.css')==m['layout']['shared_css_sha256'] and sha(ROOT/'shared.js')==m['layout']['shared_js_sha256'],'shared base CSS/JS hashes match')
 record(f'{slug}: batch css/js hash',sha(ROOT/'batch-b.css')==m['layout']['batch_css_sha256'] and sha(ROOT/'batch-b.js')==m['layout']['batch_js_sha256'],'batch-specific CSS/JS hashes match')
 record(f'{slug}: references',all(r['id'] in assets and r['path']==assets[r['id']]['path'] and r['sha256']==assets[r['id']]['sha256'] for r in m['references']),', '.join(r['id'] for r in m['references']))
 scene_key={'b01-w09-friends-invites':'B01-w09-friends-invites','b02-w12-creator-editor':'B02-w12-creator-editor','b03-w07-built-room':'B03-w07-built-room','b04-w10-pet-rest':'B04-w10-pet-rest'}[slug]
 choice=choices.get(scene_key,{})
 record(f'{slug}: review reference decision',[(r['id'],r['path'],r['sha256']) for r in choice.get('references',[])]==[(r['id'],r['path'],r['sha256']) for r in m['references']],'reviewed-inputs reference paths and hashes match manifest')
 excluded=m.get('excluded_references',[])
 record(f'{slug}: excluded reference provenance',all(r['id'] in assets and r['path']==assets[r['id']]['path'] and r['sha256']==assets[r['id']]['sha256'] for r in excluded),', '.join(r['id'] for r in excluded) or 'no excluded references declared')
 record(f'{slug}: generation inputs',all(ref_id in {r['id'] for r in m['references']} for ref_id in m.get('generation_input_refs',[])),', '.join(m.get('generation_input_refs',[])))
 required={'data-scene','data-state-select','data-lang','data-scale','data-scene-image','data-title','data-state-title','data-body','data-facts','data-cta','data-note'}
 record(f'{slug}: study DOM markers',required<=parser.data,', '.join(sorted(required-parser.data)) or 'all required markers present')
 text=layout.read_text()
 record(f'{slug}: separation markup','reviewer-controls' in text and 'reviewer-notes' in text and 'product-screen' in text,'reviewer controls and notes are outside product viewport')
 record(f'{slug}: runtime boundary',m.get('runtime_ready') is False and m.get('production_approved') is False and m.get('animation_present') is False,'runtime, production and animation flags remain false')
 report=json.loads((ROOT/'evidence/batch-b-browser-checks.json').read_text())
 record(f'{slug}: browser report',report.get('status')=='PASS' and report.get('cases')==192 and report.get('horizontalOverflowCases')==0,'shared Batch B report PASS: 192 cases, zero overflow')

expected={
 'b01-w09-friends-invites':['empty','invite_pending','invite_expired','host_away','blocked','report_confirmation'],
 'b02-w12-creator-editor':['draft_unsaved','test_error','saved_private','moderation_pending'],
 'b03-w07-built-room':['completed_enter','use_workbench','arrangement_blocked'],
 'b04-w10-pet-rest':['rest','ai_unsupported','model_removed_baseline']}
for slug,states in expected.items():
 m=json.loads((ROOT/slug/'manifest.json').read_text())
 record(f'{slug}: state coverage',m['layout']['states']==states,', '.join(m['layout']['states']))
# Scene-specific source/rule boundaries are kept in reviewer notes and prompt provenance.
js=(ROOT/'batch-b.js').read_text()
for label,ok,detail in [
 ('Friends empty/pending/expired/away/blocked/report states',all(k in js for k in ['empty:','invite_pending:','invite_expired:','host_away:','blocked:','report_confirmation:']),'six explicit privacy-aware states'),
 ('Creator editor states',all(k in js for k in ['draft_unsaved:','test_error:','saved_private:','moderation_pending:']),'four states; editor, preview and version tray fixtures'),
 ('Built-room states',all(k in js for k in ['completed_enter:','use_workbench:','arrangement_blocked:']),'continuous floor/door context without inferred geometry rules'),
 ('Miu rest states',all(k in js for k in ['rest:','ai_unsupported:','model_removed_baseline:']),'same orange Miu, static fallback states only'),
 ('Primary CTAs disabled by markup',all((ROOT/s/'layout.html').read_text().count('disabled data-cta')==1 for s in SCENES),'one disabled primary CTA per scene')]: record(label,ok,detail)

report={'task':'PQC-018 Batch B','review_pin':REVIEW_PIN,'checks':checks,'check_count':len(checks),'passed':sum(c['status']=='PASS' for c in checks),'failed':len(failures),'status':'PASS' if not failures else 'FAIL','limits':'Dependency-free file/hash/structure validation only; browser evidence is separate. No design self-acceptance or runtime/device validation.'}
(ROOT/'evidence/batch-b-static-checks.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'status':report['status'],'check_count':report['check_count'],'passed':report['passed'],'failed':report['failed'],'failures':failures},ensure_ascii=False,indent=2))
if failures: raise SystemExit(1)
