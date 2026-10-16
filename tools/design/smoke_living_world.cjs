const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium:pw}=require('playwright-core'),chromium=require('@sparticuz/chromium').default;
const out=path.resolve(__dirname,'../../docs/design/living-world-prototype/evidence');
(async()=>{const browser=await pw.launch({executablePath:process.env.BROWSER_EXECUTABLE_PATH||await chromium.executablePath(),args:chromium.args,headless:true});try{
 fs.mkdirSync(out,{recursive:true});const page=await browser.newPage({viewport:{width:1440,height:1100},deviceScaleFactor:1,locale:'vi-VN'});const errors=[];page.on('pageerror',e=>errors.push(String(e)));page.on('response',r=>{if(r.status()>=400)errors.push(`${r.status()} ${r.url()}`)});
 await page.goto(process.env.GALLERY_URL||'http://127.0.0.1:8001/',{waitUntil:'networkidle'});
 assert.equal(await page.locator('.villager').count(),2);
 const before=await page.locator('#npc-may').getAttribute('style');await page.waitForTimeout(220);assert.notEqual(await page.locator('#npc-may').getAttribute('style'),before);
 await page.waitForFunction(()=>document.querySelector('#npc-may').dataset.inside==='true',null,{timeout:16000});
 await page.locator('#pause-life').click();const frozen=await page.locator('#npc-may').getAttribute('style');await page.waitForTimeout(250);assert.equal(await page.locator('#npc-may').getAttribute('style'),frozen);
 const greeting=await page.locator('#greeting').innerText();await page.locator('#another-greeting').click();assert.notEqual(await page.locator('#greeting').innerText(),greeting);
 await page.locator('#hide-bubble').click();assert(await page.locator('#speech-body').isHidden());await page.locator('#tutor-avatar').click();assert(await page.locator('#speech-body').isVisible());
 await page.locator('[data-place=workshop]').click();assert.match(await page.locator('#card-copy').innerText(),/chưa được dựng/);await page.locator('[data-place=tower]').click();
 await page.screenshot({path:path.join(out,'01-living-village.jpg'),fullPage:true,type:'jpeg',quality:87});
 await page.locator('#harbor').click();await page.locator('[data-island=forest]').click();assert.equal(await page.locator('#sea-route polyline').count(),1);
 await page.screenshot({path:path.join(out,'02-archipelago.jpg'),fullPage:true,type:'jpeg',quality:87});
 await page.locator('#card-action').click();await page.waitForTimeout(400);assert(await page.locator('#cancel-voyage').isVisible());await page.locator('#cancel-voyage').click();assert.match(await page.locator('#voyage-status').innerText(),/Đã hủy/);assert.equal(await page.locator('#boat').evaluate(e=>e.style.left),'40%');
 await page.locator('[data-island=forest]').click();await page.locator('#card-action').click();await page.waitForFunction(()=>document.querySelector('#voyage-status').textContent.includes('Đã đến Làng Tán Lá'),null,{timeout:8000});assert.match(await page.locator('#card-state').innerText(),/chưa có game/);
 await page.locator('[data-island=stars]').click();await page.locator('#card-action').click();await page.waitForTimeout(150);await page.locator('[data-view=lesson]').click();
 const frame=page.frameLocator('#lesson-frame');await frame.locator('#classroom').waitFor();assert(await frame.locator('#village').isHidden());await frame.locator('#student-code').fill('print("Mình đi thuyền")');await frame.locator('#board-note').fill('Giữ lại ghi chú này');await frame.locator('#play').click();
 await page.locator('#back-to-world').click();assert.match(await page.locator('#voyage-status').innerText(),/Làng Tán Lá/);await page.waitForTimeout(3700);await page.locator('[data-view=lesson]').click();assert.equal(await frame.locator('#student-code').inputValue(),'print("Mình đi thuyền")');assert.equal(await frame.locator('#board-note').inputValue(),'Giữ lại ghi chú này');assert.equal(await frame.locator('#beat-number').innerText(),'Bước 1 / 4');
 await frame.locator('#run').click();assert.equal(await frame.locator('#student-output').innerText(),'Mình đi thuyền');await page.screenshot({path:path.join(out,'03-world-to-board.jpg'),fullPage:true,type:'jpeg',quality:87});
 await page.locator('[data-view=atlas]').click();await page.emulateMedia({reducedMotion:'reduce'});await page.locator('[data-island=stars]').click();await page.locator('#card-action').click();assert.match(await page.locator('#voyage-status').innerText(),/Đã đến Đảo Sao Mai/);assert(await page.locator('#cancel-voyage').isHidden());
 for(const viewport of [{width:390,height:844},{width:360,height:640}]){
  await page.setViewportSize(viewport);await page.locator('[data-view=village]').click();
  assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);
  const targets=await page.locator('.place-pin,#harbor,#card-action').evaluateAll(es=>es.map(e=>{const r=e.getBoundingClientRect();return [r.width,r.height]}));assert(targets.every(([w,h])=>w>=48&&h>=48));
  await page.screenshot({path:path.join(out,`04-village-${viewport.width}.jpg`),fullPage:true,type:'jpeg',quality:87});
  await page.locator('#open-atlas').click();await page.locator('[data-island=forest]').click();assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);
  await page.screenshot({path:path.join(out,`05-atlas-${viewport.width}.jpg`),fullPage:true,type:'jpeg',quality:87});
  await page.locator('[data-view=lesson]').click();assert.equal(await frame.locator('body').evaluate(()=>document.documentElement.scrollWidth>innerWidth),false,'Embedded mobile board must fit');await page.locator('#back-to-world').click();
 }
 await page.locator('[data-island=stars]').focus();await page.keyboard.press('Enter');assert.equal(await page.locator('#card-title').innerText(),'Đảo Sao Mai');assert.deepEqual(errors,[]);
 fs.writeFileSync(path.join(out,'browser-check.json'),JSON.stringify({status:'PASS',kind:'HTML scripted world, not Flutter/AI/multiplayer evidence',viewports:['1440x1100','390x844','360x640'],checks:['two NPCs move and one enters a house','ambient pause freezes position','context greeting variation and collapse','honest unfinished house state','atlas selection and sea route','voyage cancellation and arrival','navigation cancels voyage','embedded teaching board keeps code/note','hidden board playback paused','OS reduced motion makes voyage immediate','selected village targets >=48 CSS px','no horizontal page overflow','keyboard island selection','no JS or HTTP errors']},null,2)+'\n');console.log('PASS: living village, atlas voyages, embedded tutor and responsive layouts');
}finally{await browser.close();}})().catch(e=>{console.error(e);process.exit(1)});
