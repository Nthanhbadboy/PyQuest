const {chromium}=require('playwright');const moduleBin=require('@sparticuz/chromium');const bin=moduleBin.default||moduleBin;
const fs=require('fs'),assert=require('assert/strict');
(async()=>{
 const origin=process.env.ART_REVIEW_ORIGIN||'http://127.0.0.1:8012',base=origin+'/docs/design/dragon-run-r54/index.html';
 const browser=await chromium.launch({executablePath:await bin.executablePath(),args:bin.args.filter(x=>x!=='--single-process'),headless:true});
 const states=['home','ready','running','jump','hit','paused','upgraded','zero_star','first','best','tie','lower','saving','save_error','energy_empty','energy_unknown'];
 const errors=[];let cases=0,targets=0,fontChecks=0,flows=0;const captures=[];
 async function load(page,w,lang,scale,state){await page.goto(`${base}?lang=${lang}&scale=${scale}&state=${state}&freeze=1`);await page.waitForFunction(()=>window.studyReady);await page.evaluate(()=>document.fonts.ready);}
 async function capture(page,name){const path=`docs/design/dragon-run-r54/evidence/${name}.png`;await page.screenshot({path});captures.push(path);}
 for(const [w,h]of [[360,640],[390,844]])for(const lang of ['vi','en'])for(const scale of [1,1.3,2])for(const state of states){
  const page=await browser.newPage({viewport:{width:w,height:h},deviceScaleFactor:1});page.on('pageerror',e=>errors.push(String(e)));page.on('response',r=>{if(r.status()>=400)errors.push(r.url()+': '+r.status())});
  page.on('request',r=>{if(!r.url().startsWith(origin))errors.push('external '+r.url())});
  await load(page,w,lang,scale,state);
  const m=await page.evaluate(()=>{
   const rect=e=>{const r=e.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height}};
   const blocks=[...document.querySelectorAll('.phone .scroll,.phone .home-copy,.phone .result-body,.phone .pause-panel,.phone .hud,.phone .top')];
   const b=[...document.querySelectorAll('.phone button,.phone [role=button]')].filter(e=>e.getClientRects().length);
   const fonts=[...document.querySelectorAll('.home-copy,.result-body,.hud strong')].filter(e=>e.getClientRects().length).map(e=>({kind:e.className||'hud',size:parseFloat(getComputedStyle(e).fontSize)}));
   return {width:document.documentElement.scrollWidth,blocks:blocks.map(e=>({name:e.className,bad:e.scrollWidth>e.clientWidth+1})),buttons:b.map(e=>({id:e.id||e.className,...rect(e),overflow:e.scrollWidth>e.clientWidth+1})),fonts,stage:document.querySelector('.stage')?rect(document.querySelector('.stage')):null};
  });
  const key=`${w}/${lang}/${scale}/${state}`;assert.ok(m.width<=w+1,'page overflow '+key);
  for(const block of m.blocks)assert.equal(block.bad,false,`inner overflow ${block.name} ${key}`);
  for(const b of m.buttons){assert.ok(b.w>=47.9&&b.h>=47.9,`small ${b.id} ${key} ${b.w}x${b.h}`);assert.ok(b.x>=-.5&&b.x+b.w<=w+.5,`x bounds ${b.id} ${key}`);assert.equal(b.overflow,false,`button overflow ${b.id} ${key}`);targets++;}
  for(const f of m.fonts){const expected=(f.kind==='home-copy'?14:f.kind==='result-body'?13:22)*scale;assert.ok(Math.abs(f.size-expected)<.1,`font ${key}`);fontChecks++;}
  if(m.stage){assert.ok(m.stage.h>=190,`unusable scene ${key} ${m.stage.h}`);assert.ok(Math.abs(m.stage.w-w)<1,'gameplay keeps full viewport width');}
  if(w===390&&lang==='vi'&&scale===1&&['home','running','jump','hit','first','zero_star','saving','upgraded'].includes(state))await capture(page,`${state}-${w}-${lang}-${scale}x`);
  if(w===360&&lang==='en'&&scale===2&&['home','running','paused','best','save_error'].includes(state)){await capture(page,`${state}-${w}-${lang}-${scale}x`);if(['best','save_error'].includes(state)){await page.locator('.scroll').evaluate(e=>e.scrollTop=e.scrollHeight);await capture(page,`${state}-${w}-${lang}-${scale}x-bottom`);}}
  if(state==='home'){
   await page.locator('#start').click();assert.equal(await page.evaluate(()=>dragonStudy.state.energy),10);assert.equal(await page.evaluate(()=>dragonStudy.state.route),'play');flows++;
   await page.locator('#jump').click();await page.evaluate(()=>dragonStudy.step(.1));assert.equal(await page.evaluate(()=>dragonStudy.state.game.jumps),1);await page.keyboard.press('Space');assert.equal(await page.evaluate(()=>dragonStudy.state.game.jumps),2);await page.keyboard.press('Space');assert.equal(await page.evaluate(()=>dragonStudy.state.game.jumps),2);flows++;
   await page.locator('#top-action').click();const before=await page.evaluate(()=>dragonStudy.state.game.distance);await page.evaluate(()=>dragonStudy.step(.25));assert.equal(await page.evaluate(()=>dragonStudy.state.game.distance),before);await page.locator('#resume').click();assert.equal(await page.evaluate(()=>dragonStudy.state.energy),10);flows++;
   await page.locator('#top-action').click();await page.locator('#finish').click();assert.equal(await page.evaluate(()=>dragonStudy.state.receipt),'pending');await page.locator('#home').click();assert.equal(await page.locator('#start').isDisabled(),true);await page.locator('#view-receipt').click();await page.evaluate(()=>dragonStudy.acknowledge('confirmed'));await page.locator('#replay').click();assert.equal(await page.evaluate(()=>dragonStudy.state.energy),8);flows++;
  }
  if(state==='save_error'){
   await page.locator('#reconcile').click();assert.equal(await page.evaluate(()=>dragonStudy.state.receipt),'pending');assert.equal(await page.evaluate(()=>dragonStudy.state.wallet),80);await page.evaluate(()=>dragonStudy.acknowledge('confirmed'));assert.equal(await page.evaluate(()=>dragonStudy.state.wallet),91);await page.evaluate(()=>dragonStudy.acknowledge('confirmed'));assert.equal(await page.evaluate(()=>dragonStudy.state.wallet),91);flows++;
  }
  if(state==='energy_empty'||state==='energy_unknown'){
   await page.locator('#start').click();assert.equal(await page.locator('#dialog').evaluate(e=>e.open),true);assert.equal(await page.evaluate(()=>dragonStudy.state.route),'home');await page.keyboard.press('Escape');await page.waitForTimeout(30);assert.equal(await page.evaluate(()=>document.activeElement.id),'start');flows++;
  }
  if(state==='ready'){
   await page.locator('.stage').focus();await page.keyboard.press('Enter');assert.equal(await page.evaluate(()=>dragonStudy.state.game.phase),'running');await page.keyboard.press('Escape');assert.equal(await page.evaluate(()=>dragonStudy.state.game.paused),true);flows++;
  }
  cases++;await page.close();
 }
 const page=await browser.newPage({viewport:{width:1260,height:990}});page.on('pageerror',e=>errors.push(String(e)));
 await page.goto(`${base}?state=running&freeze=1`);await page.waitForFunction(()=>window.studyReady);await page.evaluate(()=>document.fonts.ready);await page.screenshot({path:'docs/design/dragon-run-r54/evidence/desktop-overview.jpg',type:'jpeg',quality:88});captures.push('docs/design/dragon-run-r54/evidence/desktop-overview.jpg');
 // Actual RAF analogue advances when unfrozen, then stops when paused. Not a device perf benchmark.
 await page.locator('#freeze').uncheck();const d=await page.evaluate(()=>dragonStudy.state.game.distance);await page.waitForTimeout(120);assert.ok(await page.evaluate(()=>dragonStudy.state.game.distance)>d);await page.locator('#top-action').click();const paused=await page.evaluate(()=>dragonStudy.state.game.distance);await page.waitForTimeout(120);assert.equal(await page.evaluate(()=>dragonStudy.state.game.distance),paused);flows++;
 await page.evaluate(()=>{dragonStudy.setFixture('running');Object.defineProperty(document,'hidden',{value:true,configurable:true});document.dispatchEvent(new Event('visibilitychange'));});
 assert.equal(await page.evaluate(()=>dragonStudy.state.game.paused),true);await page.evaluate(()=>{delete document.hidden;document.dispatchEvent(new Event('visibilitychange'));});assert.equal(await page.evaluate(()=>dragonStudy.state.game.paused),true);flows++;
 // A late simulated save reply must not attach to a replacement fixture/attempt object.
 await page.evaluate(()=>dragonStudy.setFixture('running'));await page.locator('#top-action').click();await page.locator('#finish').click();await page.evaluate(()=>dragonStudy.setFixture('saving'));await page.waitForTimeout(1100);assert.equal(await page.evaluate(()=>dragonStudy.state.receipt),'pending');assert.equal(await page.evaluate(()=>dragonStudy.state.wallet),80);flows++;
 assert.equal(errors.length,0,errors.join('\n'));
 const receipt={scope:'HTML/JS design study; not Dart, SQLite, device or engine parity',browser:browser.version(),cases,targets,fontChecks,flows,captures,errors};fs.writeFileSync('docs/design/dragon-run-r54/evidence/browser-checks.json',JSON.stringify(receipt,null,2)+'\n');console.log(JSON.stringify(receipt,null,2));await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
