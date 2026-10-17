#!/usr/bin/env python3
"""R38 provenance and structural regression checks for all nine PQC-018 studies."""
from __future__ import annotations
import hashlib, json, struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PIN = '3c29fc3ad5cd2f7691e22dc7a119ed5de3d147f2'
A = ['a01-w04-journal','a02-shared-settings','a03-shared-welcome','a04-w05-catch-stars','a05-w05-bug-hunter']
B = ['b01-w09-friends-invites','b02-w12-creator-editor','b03-w07-built-room','b04-w10-pet-rest']
FAIL=[]; CHECKS=[]
def sha(path: Path) -> str: return hashlib.sha256(path.read_bytes()).hexdigest()
def record(name, ok, detail):
    CHECKS.append({'check':name,'status':'PASS' if ok else 'FAIL','detail':str(detail)})
    if not ok: FAIL.append(f'{name}: {detail}')
def read_json(path): return json.loads(path.read_text())

archive_dir=ROOT/'evidence/r38-originals'
archive=read_json(archive_dir/'originals.json')
record('pre-R38 archive baseline',archive.get('baseline_commit')=='0990fbcbf6045bd64244239e36ccbca8c8dc394b',archive.get('baseline_commit'))
record('pre-R38 archive records',len(archive.get('files',[]))==36,len(archive.get('files',[])))
archive_by_path={item['path']:item for item in archive.get('files',[])}
for item in archive.get('files',[]):
    current=ROOT/item['path']
    saved=current if item['archive_path']=='unchanged-in-place' else archive_dir/item['archive_path']
    actual=sha(saved) if saved.is_file() else 'MISSING'
    record(f"original bytes/hash archived: {item['path']}",actual==item['sha256'],actual)

css=ROOT/'shared.css'; js=ROOT/'shared.js'; bcss=ROOT/'batch-b.css'; bjs=ROOT/'batch-b.js'
shared=css.read_text(); batch_css=bcss.read_text(); batch_js=bjs.read_text()
record('R38-A product bar wraps', 'flex-wrap: wrap' in shared and 'flex: 1 1 100%' in shared and 'overflow-wrap: anywhere' in shared,'title occupies a full row; wrapping remains enabled')
record('R38-A title retains full scale and no clipping', 'font-size: .78rem' in shared and 'text-overflow' not in shared and 'text-indent' not in shared,'shared title keeps baseline font; no hide/clip/truncate rule')
record('R38-A pill stays bounded', '.product-pill' in shared and 'max-width: 100%' in shared and 'white-space: normal' in shared,'pill can wrap and cannot exceed available bar width')
record('R38-B distinct editor styles',all(x in batch_css for x in ['.creator-editor {','.creator-preview {','.version-tray {','.creator-editor-surface {']),'editor, preview and version tray have independent visual rules')
record('R38-B no live editor or runtime', 'contenteditable' not in (ROOT/'b02-w12-creator-editor/layout.html').read_text() and 'interpreter' in batch_js.lower() and 'publishing' in batch_js.lower(),'read-only mock; no editor execution or publishing behavior')

reports={
 'A':read_json(ROOT/'evidence/r38a-browser-checks.json'),
 'B':read_json(ROOT/'evidence/r38-batch-b-browser-checks.json')
}
for batch,report,expected_cases,expected_fonts,expected_titles,expected_caps in [
 ('A',reports['A'],240,1499,240,19),('B',reports['B'],192,1296,192,20)]:
    record(f'{batch}: R38 browser receipt pin/status',report.get('review_pin')==PIN and report.get('status')=='PASS',f"pin={report.get('review_pin')} status={report.get('status')}")
    record(f'{batch}: full configuration coverage',report.get('cases')==expected_cases,report.get('cases'))
    record(f'{batch}: computed font assertions',report.get('computedFontAssertions')==expected_fonts,report.get('computedFontAssertions'))
    record(f'{batch}: title inner-text/bounds checks',report.get('productBarTitleChecks')==expected_titles and report.get('productBarPillBoundsChecks')==expected_titles,f"title={report.get('productBarTitleChecks')}, pill={report.get('productBarPillBoundsChecks')}")
    record(f'{batch}: no overflow/header overlap/errors',report.get('horizontalOverflowCases')==0 and report.get('headerOverlapCases')==0 and not report.get('pageErrors') and not report.get('failedRequests'), 'zero overflow/overlap, page errors and failed requests')
    record(f'{batch}: disabled CTAs and captures',report.get('allPrimaryCtasDisabled') is True and report.get('captures')==expected_caps,f"disabled={report.get('allPrimaryCtasDisabled')} captures={report.get('captures')}")
    record(f'{batch}: screenshot files',all((ROOT/'evidence'/name).is_file() for name in report.get('screenshots',[])) and len(report.get('screenshots',[]))==expected_caps,len(report.get('screenshots',[])))

b_report=reports['B']
record('B02: all 48 editor content checks',b_report.get('b02EditorVisibleContentChecks')==48,b_report.get('b02EditorVisibleContentChecks'))
record('B02: computed fonts across 48 cases',b_report.get('b02EditorComputedFontAssertions')==144,b_report.get('b02EditorComputedFontAssertions'))
record('B02: three localized sample literals',all(s in batch_js for s in ['Khu vườn nhỏ nằm cạnh ao.','Một hạt giống chờ dưới lớp đất.','Đèn giấy khẽ sáng lúc hoàng hôn.','A small garden sits beside a pond.','One seed waits beneath the soil.','A paper lantern glows at dusk.']),'VI and EN prose literals appear in the static fixture')

for slug in A+B:
    folder=ROOT/slug; manifest=read_json(folder/'manifest.json'); layout=folder/'layout.html'; image=folder/'concept.png'
    batch='A' if slug in A else 'B'; report=reports[batch]
    record(f'{slug}: manifest/review pin',manifest.get('scene_id')==slug and manifest.get('design_review_pin')==PIN,manifest.get('design_review_pin'))
    record(f'{slug}: layout and shared hashes',manifest.get('layout',{}).get('sha256')==sha(layout) and manifest.get('layout',{}).get('shared_css_sha256')==sha(css) and manifest.get('layout',{}).get('shared_js_sha256')==sha(js),'live layout/CSS/JS hashes match')
    if batch=='B': record(f'{slug}: batch asset hashes',manifest['layout'].get('batch_css_sha256')==sha(bcss) and manifest['layout'].get('batch_js_sha256')==sha(bjs),'batch-b.css/js hashes match')
    record(f'{slug}: image original preserved',sha(image)==manifest['image']['sha256'] and len(image.read_bytes())==manifest['image']['bytes'],manifest['image']['sha256'])
    dims=list(struct.unpack('>II',image.read_bytes()[16:24]))
    record(f'{slug}: image dimensions unchanged',dims==manifest['image']['dimensions'],dims)
    original=archive_by_path.get(f'{slug}/concept.png',{})
    record(f'{slug}: image matches pre-R38 archive',sha(image)==original.get('sha256'),original.get('sha256'))
    checks=manifest.get('checks',{})
    expected_browser='../evidence/r38a-browser-checks.json' if batch=='A' else '../evidence/r38-batch-b-browser-checks.json'
    record(f'{slug}: manifest links current evidence',checks.get('browser_report')==expected_browser and checks.get('static_report')=='../evidence/r38-static-checks.json' and checks.get('browser_cases')==report['cases'] and checks.get('computed_font_assertions')==report['computedFontAssertions'],checks.get('browser_report'))
    record(f'{slug}: no production acceptance',manifest.get('runtime_ready') is False and manifest.get('production_approved') is False and checks.get('all_primary_ctas_disabled') is True,'static-only fixture and CTA remains disabled')

b02=read_json(ROOT/'b02-w12-creator-editor/manifest.json')
provenance=b02.get('editor_sample_provenance',{})
record('B02: explicit sample provenance',bool(provenance.get('origin')) and provenance.get('not_game_api_or_canon') is True and provenance.get('not_lesson_answer_or_grader') is True,provenance.get('origin'))
record('B02: no interpreter/persistence/publishing',provenance.get('executable') is False and provenance.get('interpreter') is False and provenance.get('persistence') is False and provenance.get('publishing') is False,provenance)

report={'task':'PQC-018 R38-A/B correction static provenance and structure','review_pin':PIN,'baseline_commit':archive.get('baseline_commit'),'check_count':len(CHECKS),'passed':sum(c['status']=='PASS' for c in CHECKS),'failed':len(FAIL),'status':'PASS' if not FAIL else 'FAIL','browser_receipts':{'A':{'cases':reports['A'].get('cases'),'computed_font_assertions':reports['A'].get('computedFontAssertions'),'captures':reports['A'].get('captures')},'B':{'cases':reports['B'].get('cases'),'computed_font_assertions':reports['B'].get('computedFontAssertions'),'editor_visible_content_checks':b_report.get('b02EditorVisibleContentChecks'),'editor_computed_font_assertions':b_report.get('b02EditorComputedFontAssertions'),'captures':reports['B'].get('captures')}},'checks':CHECKS,'limits':'Static hashes/provenance/structure plus linked headless HTML receipts only; no DESIGN self-acceptance, Flutter/device/accessibility certification or production validation.'}
(ROOT/'evidence/r38-static-checks.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'status':report['status'],'check_count':report['check_count'],'passed':report['passed'],'failed':report['failed'],'failures':FAIL},ensure_ascii=False,indent=2))
if FAIL: raise SystemExit(1)
