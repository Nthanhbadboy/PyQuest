#!/usr/bin/env python3
"""Validate/manifest the CURRENT r50 design package, never historical r47–49 receipts.
Does not run Flutter, access credentials, dispatch CI or inspect an APK.
"""
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
PACKAGE = ROOT / 'docs/design/maze-play-r50'

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def contrast(a,b):
    def lum(value):
        rgb=[int(value[i:i+2],16)/255 for i in (1,3,5)]
        c=[n/12.92 if n<=0.04045 else ((n+0.055)/1.055)**2.4 for n in rgb]
        return sum(x*y for x,y in zip(c,(.2126,.7152,.0722)))
    values=sorted((lum(a),lum(b)))
    return (values[1]+.05)/(values[0]+.05)

source=json.loads((PACKAGE/'source-manifest.json').read_text())
for pin in source['sources']:
    raw=subprocess.check_output(['git','show',source['code_sha']+':'+pin['path']],cwd=ROOT)
    assert hashlib.sha256(raw).hexdigest()==pin['sha256'],pin['path']
    assert subprocess.check_output(['git','rev-parse',source['code_sha']+':'+pin['path']],cwd=ROOT,text=True).strip()==pin['blob']
subprocess.run(['git','diff','--exit-code',source['design_base'],'--','app','.github','ci','tools/maintenance'],cwd=ROOT,check=True)
model=json.loads((PACKAGE/'evidence/model-checks.json').read_text())
browser=json.loads((PACKAGE/'evidence/browser-checks.json').read_text())
assert model['result']=='PASS' and model['checks']==28 and model['random_programs']==500
assert browser['result']=='PASS' and browser['cases']==324 and browser['invalidCases']==0
assert not browser['errors'] and not browser['externalRequests']
assert len(browser['flows'])==17 and len(browser['shots'])==13
assert browser['fontChecks']==3732
for image in browser['shots']:assert (PACKAGE/'evidence'/image).is_file(),image
links=0
for p in PACKAGE.glob('*.md'):
    for link in re.findall(r'\]\(([^)]+)\)',p.read_text()):
        if '://' in link or link.startswith('#'):continue
        target=(p.parent/link.split('#')[0]).resolve()
        if target==PACKAGE/'evidence/static-checks.json':continue
        assert target.exists(),(p,link)
        links+=1
for link in re.findall(r'(?:src|href)="([^"#]+)"',(PACKAGE/'index.html').read_text()):
    assert (PACKAGE/link).is_file(),link
for link in re.findall(r'url\(([^)]+)\)',(PACKAGE/'style.css').read_text()):
    assert (PACKAGE/link.strip('\'"')).is_file(),link
colors={label:round(contrast(a,b),2) for label,a,b in [
    ('ink-paper','#203e39','#fff9e9'),('muted-paper','#52665a','#fff9e9'),
    ('primary-light-end','#fff7df','#39786b'),('error-cue','#803c2c','#fae6d7')]}
assert min(colors.values())>=4.5,colors
for image in json.loads((PACKAGE/'assets/provenance.json').read_text())['originals']:
    assert digest(PACKAGE/'assets'/image['path'])==image['sha256']
    for ref in image['references']:assert digest(ROOT/ref['path'])==ref['sha256']
files=[p for p in sorted(PACKAGE.rglob('*')) if p.is_file() and p.relative_to(PACKAGE).as_posix() not in ['manifest.json','evidence/static-checks.json']]
manifest={'date':'2026-10-18','status':'DESIGN_STUDY_DELIVERED','runtime_authorized':False,
          'code_pin':source['code_sha'],'design_base':source['design_base'],
          'scope':'Block-mode gameplay and result interaction study, not complete Maze/Python/runtime art pack',
          'artifacts':[{'path':p.relative_to(PACKAGE).as_posix(),'bytes':p.stat().st_size,'sha256':digest(p)} for p in files],
          'external_dependencies':[{'path':p,'sha256':digest(ROOT/p)} for p in [
              'docs/design/maze-trail-r45/catalog.js','docs/design/tutor-board-prototype/fonts/Nunito-Medium.ttf',
              'docs/design/tutor-board-prototype/fonts/Nunito-ExtraBold.ttf']],
          'tools':[{'path':str(p.relative_to(ROOT)),'sha256':digest(p)} for p in [*sorted((ROOT/'tools/design').glob('*maze_play_r50*')),ROOT/'tools/design/serve_art_review.py']]}
(PACKAGE/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
report={'result':'PASS_STATIC_DESIGN_ONLY','source_pins':len(source['sources']),'local_links':links,
        'artifacts_hashed':len(files),'text_token_contrast':colors,'app_ci_maintenance_unchanged':True,
        'model_checks':model['checks'],'browser_cases':browser['cases'],'runtime_execution':False,
        'limitations':['Static contrast tokens, not every pixel/alpha composite','No Flutter/Python/device/voice/DB/energy authority acceptance','Existing CODE correction order untouched']}
(PACKAGE/'evidence/static-checks.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(report,ensure_ascii=False,indent=2))
