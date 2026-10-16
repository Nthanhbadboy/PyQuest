const path=require('node:path');
const fs=require('node:fs');
const assert=require('node:assert/strict');
const {chromium:pw}=require('playwright-core');
const chromium=require('@sparticuz/chromium').default;
const output=path.resolve(__dirname,'../../docs/design/first-play-prototype/evidence');
(async()=>{
 fs.mkdirSync(output,{recursive:true});
 const browser=await pw.launch({executablePath:process.env.BROWSER_EXECUTABLE_PATH||await chromium.executablePath(),args:chromium.args,headless:true});
 try{
  const page=await browser.newPage({viewport:{width:1440,height:1100},deviceScaleFactor:1});
  const errors=[];page.on('pageerror',e=>errors.push(String(e)));page.on('response',r=>{if(r.status()>=400)errors.push(`${r.status()} ${r.url()}`)});
  await page.goto(process.env.GALLERY_URL||'http://127.0.0.1:8000/',{waitUntil:'networkidle'});
  await page.locator('.intro h1').waitFor();
  await page.locator('#calm').check();
  await page.screenshot({path:path.join(output,'01-desktop-intro.jpg'),fullPage:true,type:'jpeg',quality:88});
  await page.locator('.flow [data-screen="hub"]').click();await page.waitForLoadState('networkidle');
  assert.equal(await page.locator('.map-hotspot').count(),6);
  const inside=await page.locator('.map-canvas').evaluate(el=>{const a=el.getBoundingClientRect(),b=el.parentElement.getBoundingClientRect();return a.width<=b.width+1&&a.height<=b.height+1});assert(inside,'Map must fit without shifted hotspots');
  await page.screenshot({path:path.join(output,'02-desktop-hub.jpg'),fullPage:true,type:'jpeg',quality:88});
  await page.locator('[data-place="0"]').click();await page.locator('#enter-place').click();
  assert.match(await page.locator('.coming').innerText(),/Chưa mô phỏng/);
  await page.locator('.coming [data-go="hub"]').click();await page.locator('[data-place="1"]').click();await page.locator('#enter-place').click();
  await page.locator('#start-maze').click();assert(await page.locator('#run').isDisabled());
  await page.locator('[data-command="U"]').click();await page.locator('#run').click();await page.locator('.maze-feedback.error').waitFor();
  assert.match(await page.locator('.maze-feedback').innerText(),/Lệnh 1 gặp tường/);
  await page.screenshot({path:path.join(output,'03-desktop-error.jpg'),fullPage:true,type:'jpeg',quality:88});
  await page.locator('[data-hint]').click();assert(await page.locator('dialog').evaluate(d=>d.open));
  await page.locator('#hint-next').click();assert.match(await page.locator('#hint-copy').innerText(),/bốn ô/);await page.keyboard.press('Escape');assert(!await page.locator('dialog').evaluate(d=>d.open));
  await page.locator('#clear').click();for(let i=0;i<4;i++)await page.locator('[data-command="R"]').click();
  await page.locator('#run').click();await page.locator('.result').waitFor();assert.match(await page.locator('.result-summary').innerText(),/4/);
  await page.screenshot({path:path.join(output,'04-desktop-result.jpg'),fullPage:true,type:'jpeg',quality:88});
  await page.locator('#next-level').click();for(const c of ['R','R','R','D','D','D'])await page.locator(`[data-command="${c}"]`).click();await page.locator('#run').click();await page.locator('.result').waitFor();assert.match(await page.locator('.result-summary').innerText(),/1\/1/);
  await page.locator('#next-level').click();assert.match(await page.locator('.selected-place .tag').innerText(),/2 MÀN/);
  await page.locator('#sample-win').click();await page.locator('#run').click();
  await page.waitForTimeout(850);assert.equal(await page.locator('.result').count(),0,'Stopped run must not finish later');
  assert.match(await page.locator('.maze-feedback').innerText(),/Đã dừng/);
  // Mobile journey and screen-size checks use the same state and controls as desktop.
  for(const viewport of [{width:390,height:844},{width:360,height:640}]){
   await page.setViewportSize(viewport);await page.reload({waitUntil:'networkidle'});
   await page.locator('.intro').waitFor();
   assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false,'Page overflows horizontally');
   await page.screenshot({path:path.join(output,`mobile-${viewport.width}-intro.jpg`),fullPage:true,type:'jpeg',quality:88});
   await page.locator('.intro .primary').click();await page.screenshot({path:path.join(output,`mobile-${viewport.width}-hub.jpg`),fullPage:true,type:'jpeg',quality:88});
   await page.locator('#enter-place').click();await page.locator('#start-maze').click();
   const sizes=await page.locator('.direction-pad button').evaluateAll(bs=>bs.map(b=>{const r=b.getBoundingClientRect();return [r.width,r.height]}));assert(sizes.every(([w,h])=>w>=48&&h>=48));
   assert.equal(await page.locator('#app').evaluate(e=>e.scrollWidth>e.clientWidth),false,'App overflows horizontally');
   const panels=await page.evaluate(()=>{const board=document.querySelector('.board').getBoundingClientRect(),goal=document.querySelector('.goal-strip').getBoundingClientRect(),hint=document.querySelector('.maze-feedback').getBoundingClientRect();return board.top>=goal.bottom&&board.bottom<=hint.top;});assert(panels,'Board must not overlap goal or feedback');
   await page.screenshot({path:path.join(output,`mobile-${viewport.width}-maze.jpg`),fullPage:true,type:'jpeg',quality:88});
  }
  assert.deepEqual(errors,[]);
  fs.writeFileSync(path.join(output,'browser-check.json'),JSON.stringify({status:'PASS',type:'HTML design prototype, NOT Flutter evidence',viewports:[{width:1440,height:1100},{width:390,height:844},{width:360,height:640}],checks:['six map destinations','honest unimplemented-route state','real fixture collision','two-step hint and Escape','both fixture wins','gem collection','session-only completed count','stop cancels pending result','board does not overlap adjacent panels','no horizontal overflow','direction controls at least 48px','no JS or HTTP errors']},null,2)+'\n');
  console.log('PASS: prototype flow, error/retry, hints, two wins, responsive layouts and loading.');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exit(1)});
