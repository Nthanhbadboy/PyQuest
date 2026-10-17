#!/usr/bin/env node
// Optional DESIGN-only browser checks. No app/CI dependency changes.
// NODE_PATH points to an external installation of playwright-core + @sparticuz/chromium.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const { chromium: playwright } = require('playwright-core');
const chromiumModule = require('@sparticuz/chromium');
const chromium = chromiumModule.default || chromiumModule;
const root = path.resolve(__dirname, '../..');
const output = path.join(root, 'docs/design/art-refresh-r34/evidence');
const base = process.env.ART_REVIEW_URL || 'http://127.0.0.1:8000/';
(async () => {
 fs.mkdirSync(output, {recursive:true});
 const browser = await playwright.launch({executablePath: await chromium.executablePath(), args: chromium.args, headless:true});
 const errors = [], failures = [], matrix = [], screenshots = [];
 try {
  const page = await browser.newPage({viewport:{width:1441,height:1160}, reducedMotion:'reduce'});
  page.on('pageerror', e => errors.push(String(e)));
  page.on('response', r => {if(r.status()>=400) errors.push(`${r.status()} ${r.url()}`);});
  await page.goto(base); await page.evaluate(() => document.fonts.ready);
  const catalog = await page.evaluate(() => SCENES.map(s => ({id:s.id,states:s.states.map(t=>t.id)})));
  assert.equal(catalog.length,10);
  const copyErrors = await page.evaluate(() => {
   const missing=[]; const pairCheck=(v,p)=>{if(!v?.vi || !v?.en) missing.push(p);};
   for(const s of SCENES){for(const k of ['group','title','subtitle','alt','note'])pairCheck(s[k],`${s.id}.${k}`);
    for(const st of s.states){for(const k of ['name','title','body','action','review'])pairCheck(st[k],`${s.id}.${st.id}.${k}`);
     for(const r of st.rows){pairCheck(r.label,'row label');pairCheck(r.value,'row value');}
     if(st.next.startsWith('@')?!SCENES.some(x=>x.id===st.next.slice(1)):!s.states.some(x=>x.id===st.next))missing.push(`bad transition ${s.id}/${st.id}`);
    }
   }return missing;
  });
  assert.deepEqual(copyErrors,[]);
  for(const width of [390,360]) for(const lang of ['vi','en']) for(const scale of ['1','1.3','2']) {
   await page.selectOption('#size',String(width)); await page.click(lang==='vi'?'#langVi':'#langEn'); await page.selectOption('#scale',scale);
   for(const s of catalog) {
    await page.evaluate(id=>gallery.selectScene(id),s.id);
    for(const state of s.states) {
     await page.evaluate(id=>gallery.selectState(id),state);
     const result=await page.evaluate(()=>{
      const phone=document.getElementById('phone'),scroll=document.getElementById('phoneScroll');
      const panel=document.querySelector('.context-panel'),action=document.getElementById('primaryAction');
      const b=action.getBoundingClientRect(),p=phone.getBoundingClientRect();
      scroll.scrollTop=scroll.scrollHeight;
      const body=document.getElementById('stateBody');
      const end=panel.getBoundingClientRect().bottom,limit=scroll.getBoundingClientRect().bottom;
      const center=document.elementFromPoint(b.x+b.width/2,b.y+b.height/2);
      const horizontal=[phone,scroll,panel,body,action,...panel.querySelectorAll('h3,dt,dd,p')].filter(el=>el.scrollWidth>el.clientWidth+1).map(el=>el.id||el.tagName);
      return {width:p.width,height:p.height,actionHeight:b.height,actionVisible:action.contains(center),horizontal,canReachEnd:end<=limit+1,
       bodyFont:parseFloat(getComputedStyle(body).fontSize),state:phone.dataset.state,
       privacyHidden:phone.dataset.screen!=='w09-visit'||!['revoked','offline'].includes(phone.dataset.state)||document.querySelectorAll('#scene img').length===0};
     });
     const entry={screen:s.id,state,lang,width,scale:Number(scale)};
     const ok=result.width===width && result.height===(width===390?844:640) && result.actionHeight>=48 && result.actionVisible && !result.horizontal.length && result.canReachEnd && result.bodyFont>=14*Number(scale)-.1 && result.privacyHidden;
     matrix.push({...entry,pass:ok});if(!ok) failures.push({...entry,result});
    }
   }
  }
  // Exercise actual CTA handlers for every scenario, not only test API selection.
  await page.selectOption('#size','390');await page.selectOption('#scale','1');await page.click('#langVi');
  let transitions=0;
  for(const s of catalog) for(const state of s.states){
   await page.evaluate(({id,state})=>{gallery.selectScene(id);gallery.selectState(state);},{id:s.id,state});
   const expected=await page.evaluate(()=>SCENES.find(x=>x.id===gallery.current).states.find(x=>x.id===gallery.state).next);
   await page.click('#primaryAction');
   const actual=await page.evaluate(()=>({scene:gallery.current,state:gallery.state}));
   if(expected.startsWith('@'))assert.equal(actual.scene,expected.slice(1));else assert.equal(actual.state,expected);
   transitions++;
  }
  // Locale changes preserve active state; short content is allowed to clamp scroll.
  await page.evaluate(()=>{gallery.selectScene('w03-project');gallery.selectState('pending');});
  await page.click('#langEn');assert.equal(await page.getAttribute('#phone','data-state'),'pending');
  await page.click('#langVi');assert.equal(await page.getAttribute('#phone','data-state'),'pending');
  for(const s of catalog){
   await page.evaluate(id=>gallery.selectScene(id),s.id);
   await page.locator('#scene img').evaluate(img=>img.decode());
   const file=`${s.id}-390x844-vi.png`;await page.locator('#phone').screenshot({path:path.join(output,file)});screenshots.push(file);
  }
  for(const [id,state] of [['w09-visit','revoked'],['w03-project','pending'],['w10-pet','unsupported'],['w12-creator','error']]){
   await page.evaluate(({id,state})=>{gallery.selectScene(id);gallery.selectState(state);},{id,state});
   const file=`${id}-${state}-390x844-vi.png`;await page.locator('#phone').screenshot({path:path.join(output,file)});screenshots.push(file);
  }
  await page.selectOption('#size','360');await page.selectOption('#scale','2');await page.click('#langEn');
  await page.evaluate(()=>{gallery.selectScene('w03-project');document.getElementById('phoneScroll').scrollTop=9999;});
  const small='w03-project-360x640-en-text2-scrolled.png';await page.locator('#phone').screenshot({path:path.join(output,small)});screenshots.push(small);
  // Responsive host-shell smoke; phone composition tests above use exact viewport sizes.
  await page.setViewportSize({width:360,height:900});
  const hostOverflow=await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth+1);
  if(hostOverflow)failures.push({host:'360px',error:'horizontal overflow'});
  await page.setViewportSize({width:1441,height:1160});await page.selectOption('#size','390');await page.selectOption('#scale','1');await page.click('#langVi');
  await page.evaluate(()=>gallery.selectScene('w10-pet'));
  await page.screenshot({path:path.join(output,'gallery-overview.png'),fullPage:true});screenshots.push('gallery-overview.png');
  const report={date:'2026-10-18',timezone:'Asia/Saigon',kind:'HTML design study checks, NOT Flutter/device/accessibility acceptance',browser:browser.version(),scenes:catalog.length,states:catalog.reduce((n,s)=>n+s.states.length,0),matrixCases:matrix.length,passed:matrix.filter(m=>m.pass).length,ctaTransitions:transitions,locales:['vi','en'],phoneViewports:['390x844','360x640'],textScales:[1,1.3,2],checks:['local font load','paired phone copy','valid transition targets','no phone horizontal overflow','primary CTA >=48px and hit-testable','scroll end reachable','text scaling not capped','revoked/offline visit removes scene image','CTA transition per state','locale preserves active state','360px host shell smoke'],errors,failures,screenshots,limits:['No Flutter run','No OS keyboard or device test','No real housing/AI/social/commerce/gameplay','No exhaustive screenreader or contrast audit','Art remains opaque and some state-specific art is missing']};
  fs.writeFileSync(path.join(output,'checks.json'),JSON.stringify(report,null,2)+'\n');
  console.log(JSON.stringify(report,null,2));
  assert.deepEqual(errors,[]);assert.deepEqual(failures,[]);
 } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
