const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium:pw}=require('playwright-core');const chromium=require('@sparticuz/chromium').default;
const output=path.resolve(__dirname,'../../docs/design/tutor-board-prototype/evidence');
(async()=>{
 const browser=await pw.launch({executablePath:process.env.BROWSER_EXECUTABLE_PATH||await chromium.executablePath(),args:chromium.args,headless:true});
 try{
  fs.mkdirSync(output,{recursive:true});
  const page=await browser.newPage({viewport:{width:1440,height:1100},deviceScaleFactor:1});const errors=[];
  page.on('pageerror',e=>errors.push(String(e)));page.on('response',r=>{if(r.status()>=400)errors.push(`${r.status()} ${r.url()}`);});
  await page.goto(process.env.GALLERY_URL||'http://127.0.0.1:8000/',{waitUntil:'networkidle'});
  await page.locator('#calm').check();await page.screenshot({path:path.join(output,'01-village.jpg'),fullPage:true,type:'jpeg',quality:86});
  await page.locator('#begin').click();assert(await page.locator('#classroom').isVisible());
  assert.equal(await page.locator('.code-block mark').innerText(),'print');
  await page.locator('#next').click();await page.locator('#next').click();assert.equal(await page.locator('.board-output pre').innerText(),'Xin chào!');
  await page.locator('#pen').click();let r=await page.locator('#student-ink').boundingBox();
  await page.mouse.move(r.x+r.width*.35,r.y+r.height*.28);await page.mouse.down();await page.mouse.move(r.x+r.width*.65,r.y+r.height*.38,{steps:12});await page.mouse.up();assert.equal(await page.locator('#student-ink polyline').count(),1);
  await page.locator('#next').click();assert.equal(await page.locator('#student-ink polyline').count(),0);await page.locator('#previous').click();assert.equal(await page.locator('#student-ink polyline').count(),1,'Ink retained per beat');
  await page.locator('#pen').click();await page.locator('#board-note').fill('Vì sao dấu ngoặc kép biến mất?');
  await page.locator('#student-code').fill('print(Robo)');await page.locator('#run').click();assert.match(await page.locator('#student-feedback').innerText(),/ngoặc kép/);
  await page.locator('#student-code').fill('print("Robo thông minh")');await page.locator('#run').click();assert.equal(await page.locator('#student-output').innerText(),'Robo thông minh');
  await page.screenshot({path:path.join(output,'02-print-board.jpg'),fullPage:true,type:'jpeg',quality:86});
  await page.locator('[data-topic=numbers]').click();await page.locator('#next').click();await page.locator('#next').click();assert.equal(await page.locator('.token').count(),7);assert.equal(await page.locator('.board-output pre').innerText(),'7\n3 + 4');
  await page.locator('#student-code').fill('print("3 + 4")');await page.locator('#run').click();assert.equal(await page.locator('#student-output').innerText(),'3 + 4');
  await page.locator('#another').click();assert(await page.locator('#help-answer').isVisible());await page.screenshot({path:path.join(output,'03-number-board.jpg'),fullPage:true,type:'jpeg',quality:86});
  await page.locator('[data-topic=print]').click();assert.equal(await page.locator('#student-ink polyline').count(),1);assert.equal(await page.locator('#board-note').inputValue(),'Vì sao dấu ngoặc kép biến mất?');assert.equal(await page.locator('#student-code').inputValue(),'print("Robo thông minh")');
  await page.locator('#undo-ink').click();assert.equal(await page.locator('#student-ink polyline').count(),0);
  await page.locator('#replay').click();await page.locator('#play').click();await page.locator('#slower').click();await page.waitForTimeout(3500);assert.equal(await page.locator('#beat-number').innerText(),'Bước 1 / 4','Pause cancels scheduled teaching');
  await page.locator('#play').click();await page.locator('#village-nav').click();await page.waitForTimeout(3500);await page.locator('#lesson-nav').click();assert.equal(await page.locator('#beat-number').innerText(),'Bước 1 / 4','Leaving cancels scheduled teaching');
  await page.emulateMedia({reducedMotion:'reduce'});await page.locator('#calm').uncheck();assert(await page.locator('body').evaluate(b=>b.classList.contains('calm')),'OS reduced motion cannot be disabled');
  for(const viewport of [{width:390,height:844},{width:360,height:640}]){
   await page.setViewportSize(viewport);await page.locator('[data-topic=numbers]').click();await page.locator('#replay').click();await page.locator('#next').click();await page.locator('#next').click();
   const widthInfo=await page.evaluate(()=>({scroll:document.documentElement.scrollWidth,width:innerWidth,wide:[...document.querySelectorAll('body *')].filter(e=>e.getBoundingClientRect().right>innerWidth+1).map(e=>[e.tagName,e.id,e.className,e.getBoundingClientRect().right])}));assert(widthInfo.scroll<=widthInfo.width,'No horizontal page overflow: '+JSON.stringify(widthInfo));
   assert.equal(await page.locator('#board-content').evaluate(e=>e.scrollWidth>e.clientWidth+1),false,'Board content fits');
   const sizes=await page.locator('#previous,#play,#next,#pen,#run').evaluateAll(bs=>bs.map(b=>{const r=b.getBoundingClientRect();return [r.width,r.height]}));assert(sizes.every(([w,h])=>w>=48&&h>=48),JSON.stringify(sizes));
   await page.locator('#student-code').fill('print(3 + 4)');await page.locator('#run').click();assert.equal(await page.locator('#student-output').innerText(),'7');
   await page.screenshot({path:path.join(output,`04-mobile-${viewport.width}.jpg`),fullPage:true,type:'jpeg',quality:86});
  }
  // Real DOM focus can reach and invoke transport without pointer interactions.
  await page.locator('#replay').click();await page.locator('#next').focus();await page.keyboard.press('Enter');assert.equal(await page.locator('#beat-number').innerText(),'Bước 2 / 4');
  assert.deepEqual(errors,[]);fs.writeFileSync(path.join(output,'browser-check.json'),JSON.stringify({status:'PASS',kind:'HTML scripted prototype, not Flutter/AI/voice/device evidence',viewports:['1440x1100','390x844','360x640'],checks:['village to teaching board','text highlight and output arrow','per-beat drawing retained across navigation','student note and code survive topic switching','wrong input explained then valid input evaluated','seven object diagram','string versus addition output','pause and route change cancel playback','OS reduced motion honored','no horizontal overflow','selected primary targets >=48 CSS px','keyboard transport activation','no page/HTTP errors']},null,2)+'\n');console.log('PASS: tutor board journey, drawing, practice, playback cancellation and responsive checks');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exit(1)});
