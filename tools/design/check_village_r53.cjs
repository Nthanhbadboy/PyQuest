const {chromium}=require('playwright');
const chromiumModule=require('@sparticuz/chromium');
const chromiumBin=chromiumModule.default||chromiumModule;
const fs=require('fs');const assert=require('assert/strict');
(async()=>{
 const origin=process.env.ART_REVIEW_ORIGIN||'http://127.0.0.1:8011';
 const browser=await chromium.launch({executablePath:await chromiumBin.executablePath(),args:chromiumBin.args.filter(a=>a!=='--single-process'),headless:true});
 const errors=[];let cases=0,targets=0,flows=0,fontChecks=0;const captures=[];
 for(const [w,h] of [[360,640],[390,844]])for(const lang of ['vi','en'])for(const scale of [1,1.3,2])for(const state of ['fresh','returning','complete','loading','error']){
  const page=await browser.newPage({viewport:{width:w,height:h},deviceScaleFactor:1});page.on('pageerror',e=>errors.push(String(e)));
  page.on('requestfailed',r=>errors.push(r.url()+': '+r.failure()?.errorText));
  await page.goto(`${origin}/docs/design/r1-village-r53/index.html?lang=${lang}&scale=${scale}&state=${state}`);
  await page.waitForFunction(()=>window.studyReady);await page.evaluate(()=>document.fonts.ready);
  const geometry=await page.evaluate(()=>{
   const scroll=document.querySelector('#hub-scroll'),device=document.querySelector('.device');
   const rect=e=>{const r=e.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height}};
   const buttons=[...document.querySelectorAll('.device button')].filter(b=>b.getClientRects().length);
   return {pageWidth:document.documentElement.scrollWidth,innerWidth,scrollWidth:scroll.scrollWidth,clientWidth:scroll.clientWidth,scrollHeight:scroll.clientHeight,
    targets:buttons.map(b=>({id:b.id,...rect(b),overflow:b.scrollWidth>b.clientWidth+1,font:parseFloat(getComputedStyle(b.querySelector('.name')||b).fontSize)})),
    markers:[...document.querySelectorAll('.marker')].map(rect),mode:device.classList.contains('large')?'large':'normal',
    suggestion:document.querySelector('#suggestion')?.textContent||null};
  });
  assert.ok(geometry.pageWidth<=w+1&&geometry.scrollWidth<=geometry.clientWidth+1,`horizontal overflow ${w}/${lang}/${scale}/${state}`);
  assert.ok(geometry.scrollHeight>=140,`no usable scroll viewport ${geometry.scrollHeight}`);
  assert.equal(geometry.mode,scale>=1.5?'large':'normal');assert.equal(await page.locator('[data-id]').count(),6);
  for(const t of geometry.targets){assert.ok(t.w>=48-0.1&&t.h>=48-0.1,`small target ${t.id} ${t.w}x${t.h}`);assert.ok(t.x>=-.5&&t.x+t.w<=w+.5,`clipped ${t.id}`);assert.equal(t.overflow,false,`text overflow ${t.id}`);targets++;
   if(t.id.startsWith('place-')){const base=scale>=1.5?16:13;assert.ok(Math.abs(t.font-base*scale)<.1,`font ${t.id}`);fontChecks++;}}
  for(let i=0;i<geometry.markers.length;i++)for(let j=i+1;j<geometry.markers.length;j++){const a=geometry.markers[i],b=geometry.markers[j];assert.ok(a.x+a.w<=b.x+.1||b.x+b.w<=a.x+.1||a.y+a.h<=b.y+.1||b.y+b.h<=a.y+.1,`marker overlap ${w}/${lang}/${scale}`)}
  if(state==='loading'){assert.equal(geometry.suggestion,null);assert.equal(await page.locator('[data-id]:disabled').count(),6);flows++;}
  if(state==='fresh'){
   for(const id of ['main_quest','robot_maze','dragon_jump','catch_stars','bug_hunter','achievement_house']){
    const b=page.locator(`[data-id="${id}"]`);await b.scrollIntoViewIfNeeded();const before=await page.locator('#hub-scroll').evaluate(e=>e.scrollTop);
    await b.click();assert.equal(await page.locator('#sheet').evaluate(e=>e.open),true);
    await page.locator('#route-action').click();await page.evaluate(()=>new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r))));assert.equal(await page.evaluate(()=>window.lastRoute),id==='bug_hunter'?'lesson:mq1_03':`activity:${id}`);
    assert.equal(await page.evaluate(()=>document.activeElement.id),`place-${id}`);
    const after=await page.locator('#hub-scroll').evaluate(e=>e.scrollTop);assert.ok(Math.abs(before-after)<=.5,`scroll moved ${id}: ${before}->${after}`);flows++;
   }
   const b=page.locator('[data-id="main_quest"]');await b.scrollIntoViewIfNeeded();await b.focus();await page.keyboard.press('Enter');assert.equal(await page.locator('#sheet').evaluate(e=>e.open),true);await page.keyboard.press('Escape');await page.evaluate(()=>new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r))));assert.equal(await page.evaluate(()=>document.activeElement.id),'place-main_quest');flows++;
  }
  if(state==='error'){const b=page.locator('[data-id="robot_maze"]');await b.click();assert.equal(await page.locator('#sheet').evaluate(e=>e.open),false);await page.locator('[data-id="robot_maze"]').click();assert.equal(await page.locator('#sheet').evaluate(e=>e.open),true);await page.keyboard.press('Escape');flows++;}
  if((state==='fresh'&&(scale===1||scale===2))||(state==='error'&&w===360&&lang==='en'&&scale===1.3)){
   await page.reload();await page.waitForFunction(()=>window.studyReady);await page.evaluate(()=>document.fonts.ready);await page.evaluate(()=>document.activeElement?.blur());await page.locator('#hub-scroll').evaluate(e=>e.scrollTop=0);await page.waitForTimeout(80);const path=`docs/design/r1-village-r53/evidence/${state}-${w}-${lang}-${scale}x.png`;await page.screenshot({path});captures.push(path);
   if(state==='fresh'&&((w===390&&lang==='vi'&&scale===1)||(w===360&&lang==='en'&&scale===2))){
    await page.locator('#hub-scroll').evaluate(e=>e.scrollTop=e.scrollHeight);await page.waitForTimeout(80);
    const bottom=`docs/design/r1-village-r53/evidence/fresh-${w}-${lang}-${scale}x-bottom.png`;await page.screenshot({path:bottom});captures.push(bottom);
   }
  }
  cases++;await page.close();
 }
 const page=await browser.newPage({viewport:{width:1240,height:980}});await page.goto(origin);await page.waitForFunction(()=>window.studyReady);await page.evaluate(()=>document.fonts.ready);await page.screenshot({path:'docs/design/r1-village-r53/evidence/desktop-overview.jpg',type:'jpeg',quality:88});captures.push('docs/design/r1-village-r53/evidence/desktop-overview.jpg');
 assert.equal(errors.length,0,errors.join('\n'));
 const result={scope:'Chromium HTML study, not Flutter/device/SQLite',browser:browser.version(),cases,targets,fontChecks,flows,captures,errors};fs.writeFileSync('docs/design/r1-village-r53/evidence/browser-checks.json',JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result,null,2));await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
