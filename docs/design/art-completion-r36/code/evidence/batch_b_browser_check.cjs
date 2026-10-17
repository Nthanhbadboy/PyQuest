const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || '/home/user/.cache/pyquest-r36-browser/node_modules/playwright-core');
const root = path.resolve(__dirname, '..');
const base = process.env.PQC018_BASE_URL || 'http://127.0.0.1:4180/docs/design/art-completion-r36/code';
const sparticuzPath = process.env.CHROMIUM_MODULE || '/home/user/.cache/pyquest-r36-browser/node_modules/@sparticuz/chromium/build/index.js';
const scenes = ['b01-w09-friends-invites', 'b02-w12-creator-editor', 'b03-w07-built-room', 'b04-w10-pet-rest'];
const viewports = [{ width: 390, height: 844 }, { width: 360, height: 640 }];
const scales = ['1', '1.3', '2'];
const locales = ['vi', 'en'];
const evidence = __dirname;
const failures = [];
const pageErrors = [];
const failedRequests = [];
let cases = 0;
let fontAssertions = 0;
let headerOverlapCases = 0;
let controlsChecked = 0;
let ctaChecks = 0;
let separationChecks = 0;
let footerReachableChecks = 0;
let imageChecks = 0;
let captures = 0;
let productBarTitleChecks = 0;
let productBarPillBoundsChecks = 0;
let editorVisibleContentChecks = 0;
let editorFontAssertions = 0;
function check(condition, message) { if (!condition) failures.push(message); }
function near(actual, expected, tolerance = 0.15) { return Math.abs(actual - expected) <= tolerance; }

(async () => {
  const spart = (await import(sparticuzPath)).default;
  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox', '--disable-dev-shm-usage', '--headless=new'], executablePath: await spart.executablePath(), defaultViewport: { width: 390, height: 844 } });
  const page = await browser.newPage({ deviceScaleFactor: 1 });
  page.on('pageerror', error => pageErrors.push(String(error)));
  page.on('requestfailed', request => failedRequests.push(`${request.url()} ${request.failure()?.errorText}`));
  const screenshot = async filename => { await page.screenshot({ path: path.join(evidence, filename), type: 'jpeg', quality: 82, fullPage: true }); captures++; };

  for (const slug of scenes) {
    const manifest = JSON.parse(fs.readFileSync(path.join(root, slug, 'manifest.json'), 'utf8'));
    const states = manifest.layout.states;
    await page.goto(`${base}/${slug}/layout.html`, { waitUntil: 'networkidle' });
    await page.evaluate(() => document.fonts.ready);
    const imageLoaded = await page.locator('[data-scene-image]').evaluate(image => image.complete && image.naturalWidth > 0);
    imageChecks++;
    check(imageLoaded, `${slug}: concept image did not decode`);

    for (const viewport of viewports) {
      await page.setViewportSize(viewport);
      for (const scale of scales) {
        await page.locator(`[data-scale="${scale}"]`).click();
        for (const locale of locales) {
          await page.locator(`[data-lang="${locale}"]`).click();
          for (const state of states) {
            await page.locator('[data-state-select]').selectOption(state);
            const data = await page.evaluate(() => {
              const px = el => el && parseFloat(getComputedStyle(el).fontSize);
              const rect = el => { const r = el.getBoundingClientRect(); return { left:r.left,right:r.right,top:r.top,bottom:r.bottom,width:r.width,height:r.height }; };
              const root = document.documentElement;
              const screen = document.querySelector('.product-screen');
              const productBar = screen.querySelector('.product-bar');
              const productTitle = productBar.querySelector(':scope > span:first-child');
              const productPill = productBar.querySelector('.product-pill');
              const titleRange = document.createRange(); titleRange.selectNodeContents(productTitle);
              const editor = document.querySelector('.creator-editor');
              const editorSurface = editor?.querySelector('.creator-editor-surface');
              const editorLines = [...(editor?.querySelectorAll('.creator-editor-line') || [])];
              const editorTextRects = editorLines.map(line => { const range = document.createRange(); range.selectNodeContents(line.querySelector(':scope > span:last-child')); return [...range.getClientRects()].map(r => ({width:r.width,height:r.height})); });
              const preview = document.querySelector('.creator-preview');
              const tray = document.querySelector('.version-tray');
              return {
                client: root.clientWidth, rootScroll: root.scrollWidth, bodyScroll: document.body.scrollWidth,
                scale: root.style.getPropertyValue('--text-scale'), lang: root.lang,
                sizes: {root:px(root), h1:px(document.querySelector('.review-heading h1')), h2:px(document.querySelector('[data-state-title]')), body:px(document.querySelector('[data-body]')), fact:px(document.querySelector('.facts li')), productTitle:px(productTitle)},
                productBar:rect(productBar), productTitle:rect(productTitle), productPill:rect(productPill),
                productTitleText:productTitle.innerText.trim(), productTitleTextRects:[...titleRange.getClientRects()].map(r=>({width:r.width,height:r.height})),
                productTitleScroll:{width:productTitle.scrollWidth,clientWidth:productTitle.clientWidth,height:productTitle.scrollHeight,clientHeight:productTitle.clientHeight},
                editor:editor ? {role:editorSurface.getAttribute('role'),readOnly:editorSurface.getAttribute('aria-readonly'),contentEditable:editorSurface.getAttribute('contenteditable'),lines:editorLines.map(line=>line.querySelector(':scope > span:last-child').innerText.trim()),textRects:editorTextRects,surface:rect(editorSurface),box:rect(editor),preview:rect(preview),tray:rect(tray),lineFont:px(editorLines[0]?.querySelector(':scope > span:last-child')),headingFont:px(editor.querySelector('.creator-editor-heading strong')),sourceFont:px(editor.querySelector('.creator-editor-provenance')),surfaceBackground:getComputedStyle(editorSurface).backgroundColor,previewBackground:getComputedStyle(preview).backgroundImage,trayBackground:getComputedStyle(tray).backgroundColor}:null,
                back:rect(document.querySelector('.back-link')), heading:rect(document.querySelector('.review-heading h1')),
                controls:[...document.querySelectorAll('button,a,select')].map(el=>{const r=el.getBoundingClientRect();return{tag:el.tagName,width:r.width,height:r.height,text:(el.innerText||el.getAttribute('aria-label')||'').trim()};}),
                disabled:document.querySelector('[data-cta]').disabled,
                separation:!screen.querySelector('.reviewer-controls,[data-state-select],[data-lang],[data-scale],[data-note],.reviewer-notes'),
                product:screen.innerText,
                friendVisible:document.querySelector('[data-friend-roster]') ? !document.querySelector('[data-friend-roster]').hidden : null,
                friendText:document.querySelector('[data-friend-row]')?.innerText || '',
                title:document.querySelector('[data-state-title]').innerText,
                bodyText:document.querySelector('[data-body]').innerText,
                state:document.querySelector('[data-state-select]').value
              };
            });
            cases++;
            const tag = `${slug}/${state}/${locale}/${viewport.width}/${scale}`;
            check(data.rootScroll <= data.client + 1 && data.bodyScroll <= data.client + 1, `${tag}: horizontal overflow root=${data.rootScroll} body=${data.bodyScroll} client=${data.client}`);
            check(data.productTitleText.length > 0 && data.productTitle.width > 0 && data.productTitle.height > 0 && data.productTitleTextRects.some(box=>box.width>.5&&box.height>.5), `${tag}: product-bar title inner text collapsed or has zero-width fragments`);
            check(data.productTitleScroll.width <= data.productTitleScroll.clientWidth + 1 && data.productTitleScroll.height <= data.productTitleScroll.clientHeight + 1, `${tag}: product-bar title content is clipped`);
            check(data.productTitle.left >= data.productBar.left - .5 && data.productTitle.right <= data.productBar.right + .5, `${tag}: product-bar title outside bar`); productBarTitleChecks++;
            check(data.productPill.width > 0 && data.productPill.height > 0 && data.productPill.left >= data.productBar.left - .5 && data.productPill.right <= data.productBar.right + .5 && data.productPill.bottom <= data.productBar.bottom + .5, `${tag}: product pill collapsed or outside bar`); productBarPillBoundsChecks++;
            for (const [key, basePx] of Object.entries({root:16,h1:20.48,h2:17.92,body:15.04,fact:13.44,productTitle:12.48})) {
              if (Number.isFinite(data.sizes[key])) { check(near(data.sizes[key], basePx * Number(scale)), `${tag}: ${key} computed ${data.sizes[key]}px; expected ${basePx * Number(scale)}px`); fontAssertions++; }
            }
            const overlap = Math.min(data.back.right,data.heading.right)>Math.max(data.back.left,data.heading.left)+.5 && Math.min(data.back.bottom,data.heading.bottom)>Math.max(data.back.top,data.heading.top)+.5;
            if (overlap) headerOverlapCases++;
            check(!overlap && data.back.width >= 48 && data.back.height >= 48, `${tag}: back target/title overlap or undersized`);
            check(data.controls.every(control => Math.min(control.width,control.height) >= 48), `${tag}: at least one interactive target below 48×48`);
            controlsChecked += data.controls.length;
            check(data.disabled, `${tag}: primary CTA active`); ctaChecks++;
            check(data.separation, `${tag}: reviewer controls or notes inside product viewport`); separationChecks++;
            const footerReachable = await page.evaluate(() => { window.scrollTo(0, document.body.scrollHeight); const rect = document.querySelector('.page-foot').getBoundingClientRect(); return rect.bottom <= innerHeight + 1; });
            check(footerReachable, `${tag}: footer not reachable by scrolling to document end`); footerReachableChecks++;
            if (slug === 'b01-w09-friends-invites') {
              check(!/w09|w12b|backend|online presence|moderation/i.test(data.product), `${tag}: source plumbing or service claims in child-facing viewport`);
              if (state === 'empty' || state === 'report_confirmation') check(!data.friendVisible, `${tag}: sample friend row incorrectly shown`);
              if (['invite_pending','invite_expired','host_away','blocked'].includes(state)) check(data.friendVisible && /sample|mẫu|hidden|ẩn|pending|chờ|expired|hết hạn|away|vắng|blocked|chặn/i.test(data.friendText), `${tag}: recipient/status row missing or unclear`);
              if (state === 'blocked' || state === 'report_confirmation') check(/hidden|ẩn|private|riêng/i.test(data.product), `${tag}: private information not explicitly hidden`);
            }
            if (slug === 'b02-w12-creator-editor') {
              const expectedLines = locale === 'vi'
                ? ['Khu vườn nhỏ nằm cạnh ao.', 'Một hạt giống chờ dưới lớp đất.', 'Đèn giấy khẽ sáng lúc hoàng hôn.']
                : ['A small garden sits beside a pond.', 'One seed waits beneath the soil.', 'A paper lantern glows at dusk.'];
              check(data.editor && data.editor.role === 'textbox' && data.editor.readOnly === 'true' && data.editor.contentEditable !== 'true', `${tag}: editor is not an explicitly read-only static surface`);
              check(data.editor?.lines.length === 3 && expectedLines.every((line,index)=>data.editor.lines[index]===line), `${tag}: localized authored sample prose is missing or changed`);
              check(data.editor?.textRects.length === 3 && data.editor.textRects.every(rects=>rects.some(rect=>rect.width>.5&&rect.height>.5)), `${tag}: editor sample line has no visible text fragment`);
              check(data.product.includes(locale === 'vi' ? 'Văn xuôi hư cấu viết riêng cho study' : 'Fictional prose authored for this study'), `${tag}: sample provenance is not visible`);
              check(data.editor.box.bottom <= data.editor.preview.top && data.editor.preview.bottom <= data.editor.tray.top, `${tag}: editor, preview and version tray overlap or are not separate surfaces`);
              check(data.editor.surfaceBackground !== data.editor.trayBackground && data.editor.previewBackground !== 'none', `${tag}: editor, preview and version tray are not visually distinguished`);
              editorVisibleContentChecks++;
              for (const [key,basePx] of Object.entries({lineFont:12.48,headingFont:14.08,sourceFont:11.52})) {
                check(near(data.editor[key],basePx*Number(scale)), `${tag}: editor ${key} computed ${data.editor[key]}px; expected ${basePx*Number(scale)}px`); editorFontAssertions++;
              }
              if (state === 'saved_private') check(/not verified|không chứng minh|not verified|chưa xác minh|fixture|mẫu/i.test(data.product), `${tag}: private state lacks fixture/non-persistence qualifier`);
              if (state === 'moderation_pending') check(/not|không/i.test(data.bodyText), `${tag}: pending copy lacks a non-claim`);
            }
            if (slug === 'b03-w07-built-room') check(/sàn|floor/i.test(data.product) && /cửa|door/i.test(data.product), `${tag}: floor/door composition cues missing`);
            if (slug === 'b04-w10-pet-rest') check(/Miu/.test(data.product) || /Miu/.test(data.title), `${tag}: Miu identity label missing`);
          }
        }
      }
    }

    await page.setViewportSize({width:390,height:844});
    await page.locator('[data-lang="vi"]').click(); await page.locator('[data-scale="1"]').click();
    for (const state of states) {
      await page.locator('[data-state-select]').selectOption(state);
      await screenshot(`${slug}-r38-${state}-390x844-vi-1x.jpg`);
    }
    await page.setViewportSize({width:360,height:640}); await page.locator('[data-lang="en"]').click(); await page.locator('[data-scale="2"]').click();
    await screenshot(`${slug}-r38-360x640-en-2x.jpg`);
  }

  const report = {
    task:'PQC-018 R38-A/B correction regression (Batch B)', review_pin:'3c29fc3ad5cd2f7691e22dc7a119ed5de3d147f2', date:new Date().toISOString(), browser:browser.version(),
    source:'Static local HTML fixtures only; no Flutter/app execution, network/backend, gameplay, persistence, transaction or AI.',
    scenes:scenes.length, stateConfigurations:scenes.reduce((sum,slug)=>sum+JSON.parse(fs.readFileSync(path.join(root,slug,'manifest.json'),'utf8')).layout.states.length,0),
    viewportWidths:[390,360], locales, textScales:scales, cases, computedFontAssertions:fontAssertions+editorFontAssertions, generalComputedFontAssertions:fontAssertions,
    productBarTitleChecks, productBarPillBoundsChecks, b02EditorVisibleContentChecks:editorVisibleContentChecks, b02EditorComputedFontAssertions:editorFontAssertions, headerOverlapCases,
    controlsChecked, ctaChecks, reviewerSeparationChecks:separationChecks, footerReachableChecks, imageChecks,
    horizontalOverflowCases:failures.filter(item=>item.includes('horizontal overflow')).length,
    pageErrors, failedRequests, failures, allPrimaryCtasDisabled:ctaChecks===cases, allImagesDecoded:imageChecks===scenes.length,
    captures, screenshots:fs.readdirSync(evidence).filter(name=>name.endsWith('.jpg') && /^b0[1-4]-[^/]+-r38-/.test(name)).sort(),
    status:failures.length===0 && pageErrors.length===0 && failedRequests.length===0?'PASS':'FAIL',
    limits:'Headless static-fixture checks and representative captures only; no manual visual review of every state/configuration, no Flutter/device/accessibility/production acceptance.'
  };
  fs.writeFileSync(path.join(evidence,'r38-batch-b-browser-checks.json'),`${JSON.stringify(report,null,2)}\n`);
  console.log(JSON.stringify(report,null,2)); await browser.close();
  if(report.status!=='PASS'||pageErrors.length||failedRequests.length) process.exitCode=1;
})().catch(error=>{console.error(error.stack||error);process.exitCode=1;});
