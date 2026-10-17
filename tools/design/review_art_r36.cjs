#!/usr/bin/env node
// Independent DESIGN check: measure actual computed fonts, not just scale-selector values.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium:pw}=require('playwright-core');const cm=require('@sparticuz/chromium');const chromium=cm.default||cm;
const root=path.resolve(__dirname,'../..'),pkg=path.join(root,'docs/design/art-completion-r36/code'),out=path.join(root,'docs/design/art-review-r36/evidence');
const origin=process.env.ART_REVIEW_ORIGIN||'http://127.0.0.1:8000';
(async()=>{fs.mkdirSync(out,{recursive:true});const browser=await pw.launch({executablePath:await chromium.executablePath(),args:chromium.args,headless:true});try{
const errors=[],cases=[],screenshots=[];const page=await browser.newPage();page.on('pageerror',e=>errors.push(String(e)));page.on('requestfailed',r=>errors.push(`${r.url()}: ${r.failure()?.errorText}`));page.on('response',r=>{if(r.status()>=400)errors.push(`${r.status()} ${r.url()}`)});
const ids=fs.readdirSync(pkg).filter(s=>/^a0[1-5]-/.test(s));
for(const id of ids){
for(const width of [390,360]){await page.setViewportSize({width,height:width===390?844:640});await page.goto(`${origin}/docs/design/art-completion-r36/code/${id}/layout.html`);await page.evaluate(()=>document.fonts.ready);await page.locator('[data-scene-image]').evaluate(i=>i.decode());
const states=await page.locator('[data-state-select] option').evaluateAll(os=>os.map(o=>o.value));
for(const lang of ['vi','en']){await page.click(`[data-lang="${lang}"]`);for(const state of states){await page.selectOption('[data-state-select]',state);await page.click('[data-scale="1"]');
const baseline=await page.evaluate(()=>Object.fromEntries(['[data-title]','[data-state-title]','[data-body]','[data-code-lines] code'].map(s=>[s,document.querySelector(s)?parseFloat(getComputedStyle(document.querySelector(s)).fontSize):null])));
for(const scale of [1,1.3,2]){await page.click(`[data-scale="${scale}"]`);const result=await page.evaluate(({baseline,scale})=>{
 window.scrollTo(0,document.documentElement.scrollHeight);
 const footerReachable=Math.abs(scrollY+innerHeight-document.documentElement.scrollHeight)<=2;
 const back=document.querySelector('.back-link').getBoundingClientRect(),title=document.querySelector('.headings').getBoundingClientRect();
 const headerOverlap=back.right>title.left+.5 && back.bottom>title.top && title.bottom>back.top;
 const fontChecks=Object.entries(baseline).filter(([,n])=>n!==null).map(([sel,base])=>({selector:sel,base,actual:parseFloat(getComputedStyle(document.querySelector(sel)).fontSize),expected:base*scale}));
 const badFonts=fontChecks.filter(f=>Math.abs(f.actual-f.expected)>.15);
 const overflow=[...document.querySelectorAll('h1,h2,p,li,code,.topbar,.state-card')].filter(e=>e.getBoundingClientRect().width>0&&e.scrollWidth>e.clientWidth+1).map(e=>e.tagName+':'+e.className);
 const controls=[...document.querySelectorAll('button,select,a')].filter(e=>e.getBoundingClientRect().width>0);const small=controls.filter(e=>{const b=e.getBoundingClientRect();return b.width<47.9||b.height<47.9}).map(e=>e.outerHTML.slice(0,130));
 return {footerReachable,headerOverlap,fontChecks,badFonts,overflow,pageOverflow:document.documentElement.scrollWidth>innerWidth+1,smallControls:small,disabledCTA:document.querySelector('[data-cta]').disabled};
},{baseline,scale});cases.push({id,width,lang,state,scale,...result});}
}
}
if(width===390){await page.click('[data-lang="vi"]');await page.click('[data-scale="1"]');await page.selectOption('[data-state-select]',states[0]);await page.evaluate(()=>window.scrollTo(0,0));const file=`${id}-390-vi-initial.png`;await page.screenshot({path:path.join(out,file)});screenshots.push(file);}
}
}
// Document the computed-size defect on a source-code state at 2x, scrolled to text.
await page.setViewportSize({width:360,height:640});await page.goto(`${origin}/docs/design/art-completion-r36/code/a05-w05-bug-hunter/layout.html`);await page.click('[data-lang="en"]');await page.selectOption('[data-state-select]','ready');await page.click('[data-scale="2"]');await page.locator('[data-code-panel]').scrollIntoViewIfNeeded();await page.screenshot({path:path.join(out,'bug-code-360-en-scale2.png')});screenshots.push('bug-code-360-en-scale2.png');
const report={date:'2026-10-18',reviewedSHA:'1053973da1ad11378f7263d7b13a4d61667133af',browser:browser.version(),cases:cases.length,overflowCases:cases.filter(c=>c.pageOverflow||c.overflow.length).length,smallControlCases:cases.filter(c=>c.smallControls.length).length,incorrectFontScaleCases:cases.filter(c=>c.badFonts.length).length,headerOverlapCases:cases.filter(c=>c.headerOverlap).length,allFootersReachable:cases.every(c=>c.footerReachable),allDisabledCTA:cases.every(c=>c.disabledCTA),errors,screenshots,results:cases,limits:['HTML only, not Flutter/device','Geometry checks are not an exhaustive accessibility audit','Source package left byte-identical']};
fs.writeFileSync(path.join(out,'independent-browser.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({...report,results:undefined},null,2));assert.equal(cases.length,240);assert.deepEqual(errors,[]);
// Return failure for actual layout defects; writing the report is not an acceptance pass.
if(report.incorrectFontScaleCases||report.overflowCases||report.smallControlCases||report.headerOverlapCases||!report.allFootersReachable||!report.allDisabledCTA)process.exitCode=2;
}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1});
