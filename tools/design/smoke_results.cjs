const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {chromium:pw}=require('playwright-core'),chromium=require('@sparticuz/chromium').default;
const out=process.env.EVIDENCE_DIR?path.resolve(process.env.EVIDENCE_DIR):path.resolve(__dirname,'../../docs/design/result-adventure-prototype/evidence');
const url=process.env.GALLERY_URL||'http://127.0.0.1:8002/';
(async()=>{
 fs.mkdirSync(out,{recursive:true});fs.rmSync(path.join(out,'browser-check.json'),{force:true});
 const browser=await pw.launch({executablePath:process.env.BROWSER_EXECUTABLE_PATH||await chromium.executablePath(),args:chromium.args.filter(x=>x!=='--single-process'),headless:true});
 try{
 let page=await browser.newPage({viewport:{width:1440,height:1100},locale:'vi-VN'});const errors=[], external=[];
 page.on('pageerror',e=>errors.push(String(e)));page.on('response',r=>{if(r.status()>=400)errors.push(`${r.status()} ${r.url()}`)});
 page.on('request',r=>{if(new URL(r.url()).origin!==new URL(url).origin)external.push(r.url())});
 const snap=()=>page.evaluate(()=>window.__p05);
 const shot=async name=>{const reopen=await page.locator('#review-panel').isVisible();if(reopen)await page.locator('#review-open').click();await page.evaluate(()=>{scrollTo(0,0);return document.fonts.ready;});await page.screenshot({path:path.join(out,name+'.jpg'),fullPage:true,type:'jpeg',quality:86,animations:'disabled'});if(reopen)await page.locator('#review-open').click();};
 async function review(){if(await page.locator('#review-panel').isHidden())await page.locator('#review-open').click();}
 async function scenario(id){await review();await page.locator('#scenario').selectOption(id);}
 async function go(view){await review();await page.locator(`#frames [data-view="${view}"]`).click();}
 async function settings(lang,scale){await page.locator('#settings-open').click();if(lang)await page.locator('#language').selectOption(lang);if(scale)await page.locator('#text-scale').selectOption(scale);await page.locator('#settings-close').click();}
 async function noOverflow(context){const r=await page.evaluate(()=>({viewport:innerWidth,scroll:document.documentElement.scrollWidth,clipped:[...document.querySelectorAll('button,select,h1,h2,h3,p')].filter(e=>e.getClientRects().length&&e.scrollWidth>e.clientWidth+3).map(e=>[e.tagName,e.textContent.slice(0,80),e.scrollWidth,e.clientWidth])}));assert(r.scroll<=r.viewport,JSON.stringify({context,...r}));assert.deepEqual(r.clipped,[],`Clipped content: ${context}`);}
 await page.goto(url,{waitUntil:'networkidle'});assert.equal((await snap()).language,'vi');assert.equal((await snap()).writes,1);assert.equal(await page.locator('[data-notice=first_steps]').count(),1);
 await shot('01-result-desktop-vi');
 await page.locator('#content [data-view=badge]').click();assert.equal(await page.locator('h1').innerText(),'Bước Chân Đầu Tiên');await shot('02-badge-desktop-vi');
 await page.locator('#content [data-view=hall]').click();assert.equal(await page.locator('[data-earned=true]').count(),1);assert(!/Lối Đi Khác|Cú Đêm|20:00|different_path/.test(await page.locator('#content').innerText()));await shot('03-hall-desktop-vi');
 await page.locator('#content [data-view=share]').click();assert(await page.locator('.share-controls button[disabled]').isVisible());for(const state of ['offline','restricted','unconnected']){await page.locator('#social-state').selectOption(state);assert.equal((await snap()).owned.length,1);}
 await page.locator('#main-nav [data-view=next]').click();await shot('04-next-desktop-vi');await page.locator('#content [data-view=rest]').click();assert.match(await page.locator('h1').innerText(),/giữ chỗ/);assert.equal((await snap()).owned.length,1);
 await scenario('r06');assert.equal((await snap()).writes,0);assert.equal(await page.locator('[data-notice]').count(),0);await page.locator('#mock-error').click();assert.equal((await snap()).status,'error');await shot('05-save-error-desktop-vi');await page.locator('[data-action=ack]').click();assert.equal((await snap()).writes,1);assert.equal((await snap()).owned.length,1);await page.locator('#restore').click();assert.equal((await snap()).writes,1);assert.equal((await snap()).visibleNotices.length,0);
 await scenario('r04');await page.locator('#content [data-view=play]').click();assert.equal((await snap()).program.length,2);await page.locator('[data-command=R]').click();await page.locator('[data-command=R]').click();await page.locator('[data-action=run]').click();assert.equal((await snap()).score,100);assert.equal((await snap()).owned.length,1);assert.equal((await snap()).writes,1);
 await page.locator('#content [data-view=play]').click();await page.locator('[data-action=run]').click();assert.equal((await snap()).owned.length,1);assert.equal((await snap()).writes,2);assert.equal((await snap()).visibleNotices.length,0);
 for(const id of ['r01','r02','r03','r04','r05','r06','r06error','r07','r07end','r08','r09','r10','r11','r12']){await scenario(id);await noOverflow(id);}
 await scenario('r09');assert.equal(await page.locator('[data-notice]').count(),2);assert.equal((await snap()).owned.length,1);
 for(const id of ['r07','r07end']){await scenario(id);await go('next');assert(await page.locator('#content [data-view=challenge]').isDisabled());assert(await page.locator('#content [data-view=play]').isEnabled());}
 // Locale/text/motion changes preserve the current run and program, never issue another mock write.
 await scenario('r04');await page.locator('#content [data-view=play]').click();await page.locator('[data-command=R]').click();const before=await snap();await settings('en','2');const after=await snap();assert.deepEqual(after.program,before.program);assert.equal(after.writes,before.writes);assert.equal(after.view,'play');assert.equal(after.language,'en');await noOverflow('EN play at 200% desktop');
 await page.locator('#settings-open').click();await page.keyboard.press('Escape');assert.equal(await page.evaluate(()=>document.activeElement.id),'settings-open');
 await settings('vi','1');await page.emulateMedia({reducedMotion:'reduce'});await scenario('r01');assert.equal((await snap()).celebrations,0);assert.equal(await page.evaluate(()=>document.getAnimations().length),0);await page.emulateMedia({reducedMotion:'no-preference'});assert.equal((await snap()).celebrations,0);
 await page.locator('#settings-open').click();await page.locator('#calm').check();await page.locator('#settings-close').click();await scenario('r01');assert.equal((await snap()).celebrations,0);
 await page.setViewportSize({width:390,height:844});await settings('vi','1');await go('result');await page.locator('#review-open').click();await shot('06-result-phone-390-vi');
 await page.locator('#content [data-view=badge]').click();await shot('07-badge-phone-390-vi');await page.locator('#content [data-view=hall]').click();await shot('08-hall-phone-390-vi');
 await page.setViewportSize({width:360,height:640});await settings('en','2');await go('result');await page.locator('#review-open').click();await shot('09-result-phone-360-en-text200');
 await settings('en','1');await scenario('r06error');await page.locator('#review-open').click();await shot('10-save-error-phone-360-en');
 // Keyboard traversal actually moves focus; Enter and Space activate native buttons.
 await settings('vi','1');await scenario('r01');await page.locator('#review-open').click();await page.locator('#main-nav [data-view=result]').focus();const nav=[];for(let i=0;i<3;i++){nav.push(await page.evaluate(()=>document.activeElement.dataset.view||document.activeElement.id));await page.keyboard.press('Tab');}
 assert.deepEqual(nav,['result','hall','next']);assert.equal(await page.evaluate(()=>document.activeElement.id),'settings-open');await page.keyboard.press('Enter');assert(await page.locator('#settings').isVisible());await page.keyboard.press('Escape');
 await page.locator('#content [data-view=badge]').focus();await page.keyboard.press('Space');assert.equal((await snap()).view,'badge');await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));assert.equal(await page.evaluate(()=>document.activeElement.tagName),'H1');
 // System default/fallback and write failure in isolated contexts.
 const fallback=await browser.newPage({locale:'fr-FR'});await fallback.goto(url);assert.equal(await fallback.evaluate(()=>window.__p05.language),'en');await fallback.evaluate(()=>{Object.defineProperty(navigator,'languages',{value:['vi-VN'],configurable:true});dispatchEvent(new Event('languagechange'));});assert.equal(await fallback.evaluate(()=>window.__p05.language),'vi');await fallback.close();
 const blocked=await browser.newPage({locale:'vi-VN'});await blocked.addInitScript(()=>{Storage.prototype.setItem=()=>{throw new Error('Blocked for test')}});await blocked.goto(url);await blocked.locator('#settings-open').click();await blocked.locator('#language').selectOption('en');assert.match(await blocked.locator('#preference-status').innerText(),/could not be saved/);assert.equal(await blocked.evaluate(()=>window.__p05.writes),1);await blocked.close();
 // Check the 8 storyboard frames in 2 languages x 3 text sizes x 3 viewports.
 let layoutChecks=0;
 for(const viewport of [{width:1440,height:1100},{width:390,height:844},{width:360,height:640}]){
  await page.setViewportSize(viewport);
  for(const lang of ['vi','en'])for(const scale of ['1','1.3','2']){
   await settings(lang,scale);await scenario('r01');
   for(const view of ['finish','result','reward','badge','hall','next','share','challenge']){
    await go(view);await noOverflow(`${viewport.width}/${lang}/${scale}/${view}`);layoutChecks++;
    // Check controls in every frame, not just the final frame in each viewport/locale/scale.
    const targets=await page.locator('button:visible,select:visible').evaluateAll(es=>es.map(e=>{const r=e.getBoundingClientRect();return {tag:e.tagName,label:e.textContent.slice(0,60),w:r.width,h:r.height}}));
    assert(targets.every(t=>t.h>=48&&(t.tag!=='BUTTON'||t.w>=48)),JSON.stringify({view,targets:targets.filter(t=>t.h<48||(t.tag==='BUTTON'&&t.w<48))}));
   }
  }
 }
 assert.deepEqual(errors,[]);assert.deepEqual(external,[]);
 fs.writeFileSync(path.join(out,'browser-check.json'),JSON.stringify({status:'PASS',date:'2026-10-16',browser:await browser.version(),scope:'HTML / JavaScript design prototype only; no Flutter, device, real persistence, AI or online social evidence',layoutChecks,scenarios:14,viewports:['1440x1100','390x844','360x640'],languages:['vi','en'],textScales:[1,1.3,2],checks:['full result/badge/collection/next/rest journey','first_steps and quest notices keep separate kinds','pending/error/ack/reopen without duplicate mock writes','retry retains program; deterministic rm_01 replay','no repeat badge; saved best never falls (also unit-tested)','no secret title/condition exposed','insufficient energy and end-route states','locale and text changes preserve run/program','device and local reduced motion','144 frame/language/scale/viewport layouts without page or text clipping','visible buttons and selects >=48 CSS px height','real Tab/Enter/Space and modal Escape focus restoration','system locale/fallback/change and preference write error','no external requests or JS/HTTP errors'],limitations:['not a real-device or TalkBack test','no actual audio to test; sound is absent','CSS text scaling is not Flutter textScaleFactor','model ledger is in-memory only; reload resets it','frame layout checks do not assert every state at every scale']},null,2)+'\n');
 console.log(`PASS: P05 journeys, 14 scenarios, ${layoutChecks} layouts, keyboard, locale and motion`);
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exit(1)});
