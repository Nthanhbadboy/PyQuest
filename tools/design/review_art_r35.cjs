#!/usr/bin/env node
// DESIGN-only read-only review of original PQC-017 and synchronized derivatives.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium:pw}=require('playwright-core');const mod=require('@sparticuz/chromium');const chromium=mod.default||mod;
const root=path.resolve(__dirname,'../..'),base=process.env.ART_REVIEW_ORIGIN||'http://127.0.0.1:8000';
const out=path.join(root,'docs/design/art-sync-r35/evidence');fs.mkdirSync(out,{recursive:true});
const mode=process.argv[2]||'original';assert(['original','synced'].includes(mode));
(async()=>{const browser=await pw.launch({executablePath:await chromium.executablePath(),args:chromium.args,headless:true});
try{const page=await browser.newPage({viewport:{width:1440,height:1100}});const errors=[];page.on('pageerror',e=>errors.push(String(e)));page.on('response',r=>{if(r.status()>=400)errors.push(`${r.status()} ${r.url()}`)});
const cases=[],captures=[];
for(const screen of ['w13-tutor','w14-achievements','w11-arena']){
const url=mode==='original'?`/docs/design/art-refresh-r33/code/${screen}/layout.html`:`/docs/design/art-sync-r35/layouts/${screen}.html`;
await page.goto(base+url);await page.evaluate(()=>document.fonts.ready);
const states=await page.locator('#state option').evaluateAll(os=>os.map(o=>o.value));
for(const size of ['390x844','360x640'])for(const locale of ['vi','en'])for(const scale of ['1','2'])for(const state of states){
await page.selectOption('#size',size);await page.selectOption('#locale',locale);await page.selectOption('#scale',scale);await page.selectOption('#state',state);
const result=await page.evaluate(()=>{const p=document.getElementById('phone');p.scrollLeft=0;p.scrollTop=0;const b=p.getBoundingClientRect();
const overflow=[p,...p.querySelectorAll('.top,.panel,.row,.tabs,.fixture-grid,.specimen,.actions,.code,.top-title,.flag')].filter(e=>e.getBoundingClientRect().width>0&&e.scrollWidth>e.clientWidth+1).map(e=>e.className||e.id);
const controls=[...p.querySelectorAll('button')];return{width:b.width,height:b.height,scrollWidth:p.scrollWidth,clientWidth:p.clientWidth,overflow,disabledMocks:controls.every(e=>e.disabled),code:[...p.querySelectorAll('pre')].map(e=>e.textContent),debugIDVisible:!![...p.querySelectorAll('*')].find(e=>e.children.length===0&&e.getBoundingClientRect().width>0&&e.textContent.includes('mq1_01_s2'))};});
cases.push({screen,size,locale,scale,state,...result});
if((size==='390x844'&&locale==='vi'&&scale==='1'&&state===states[0])||(size==='360x640'&&locale==='en'&&scale==='2'&&state===states[0])){const file=`${mode}-${screen}-${size}-${locale}-text${scale}.png`;await page.locator('#phone').screenshot({path:path.join(out,file)});captures.push(file);}
}
}
const report={date:'2026-10-18',mode,source_code_sha:'e3ec5f1b6887eea5fa168efd265531425a531719',browser:browser.version(),cases:cases.length,horizontalOverflowCases:cases.filter(c=>c.overflow.length).length,debugIDVisibleCases:cases.filter(c=>c.debugIDVisible).length,errors,captures,results:cases,limits:['HTML only, no Flutter/device tests','No gameplay, live AI, social or economy','No exhaustive contrast/screenreader audit']};
fs.writeFileSync(path.join(out,`${mode}-layouts.json`),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify({mode,cases:report.cases,horizontalOverflowCases:report.horizontalOverflowCases,debugIDVisibleCases:report.debugIDVisibleCases,errors,captures},null,2));
assert.deepEqual(errors,[]);if(mode==='synced'){assert.equal(report.horizontalOverflowCases,0);assert.equal(report.debugIDVisibleCases,0);assert(cases.every(c=>c.disabledMocks));}
}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1});
