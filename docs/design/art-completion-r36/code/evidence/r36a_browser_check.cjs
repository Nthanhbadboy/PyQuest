const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || '/home/user/.cache/pyquest-r36-browser/node_modules/playwright-core');
const root = path.resolve(__dirname, '..');
const base = process.env.PQC018_BASE_URL || 'http://127.0.0.1:4180/docs/design/art-completion-r36/code';
const sparticuzPath = process.env.CHROMIUM_MODULE || '/home/user/.cache/pyquest-r36-browser/node_modules/@sparticuz/chromium/build/index.js';
const scenes = ['a01-w04-journal', 'a02-shared-settings', 'a03-shared-welcome', 'a04-w05-catch-stars', 'a05-w05-bug-hunter'];
const viewports = [{ width: 390, height: 844 }, { width: 360, height: 640 }];
const scales = ['1', '1.3', '2'];
const locales = ['vi', 'en'];
const evidence = __dirname;
const failures = [];
const pageErrors = [];
const failedRequests = [];
let cases = 0;
let scaleAssertions = 0;
let headerOverlapCases = 0;
let controlsChecked = 0;
let ctaChecks = 0;
let notesSeparationChecks = 0;
let captures = 0;
let productBarTitleChecks = 0;
let productBarPillBoundsChecks = 0;

function check(condition, message) { if (!condition) failures.push(message); }
function near(actual, expected, tolerance = 0.15) { return Math.abs(actual - expected) <= tolerance; }

(async () => {
  const spart = (await import(sparticuzPath)).default;
  const browser = await chromium.launch({ headless: true, args: ['--no-sandbox', '--disable-dev-shm-usage', '--headless=new'], executablePath: await spart.executablePath(), defaultViewport: { width: 390, height: 844 } });
  const page = await browser.newPage({ deviceScaleFactor: 1 });
  page.on('pageerror', error => pageErrors.push(String(error)));
  page.on('requestfailed', request => failedRequests.push(`${request.url()} ${request.failure()?.errorText}`));
  const screenshot = async filename => {
    await page.screenshot({ path: path.join(evidence, filename), type: 'jpeg', quality: 82, fullPage: true });
    captures++;
  };

  for (const slug of scenes) {
    const manifest = JSON.parse(fs.readFileSync(path.join(root, slug, 'manifest.json'), 'utf8'));
    const states = manifest.layout.states;
    await page.goto(`${base}/${slug}/layout.html`, { waitUntil: 'networkidle' });
    await page.evaluate(() => document.fonts.ready);
    const imageLoaded = await page.locator('[data-scene-image]').evaluate(image => image.complete && image.naturalWidth > 0);
    check(imageLoaded, `${slug}: concept image did not decode`);

    for (const viewport of viewports) {
      await page.setViewportSize(viewport);
      for (const scale of scales) {
        await page.locator(`[data-scale="${scale}"]`).click();
        for (const locale of locales) {
          await page.locator(`[data-lang="${locale}"]`).click();
          for (const state of states) {
            await page.locator('[data-state-select]').selectOption(state);
            await page.evaluate(() => document.fonts.ready);
            const result = await page.evaluate(() => {
              const px = element => element && parseFloat(getComputedStyle(element).fontSize);
              const rect = element => {
                const box = element.getBoundingClientRect();
                return { left: box.left, right: box.right, top: box.top, bottom: box.bottom, width: box.width, height: box.height };
              };
              const root = document.documentElement;
              const screen = document.querySelector('.product-screen');
              const cta = document.querySelector('[data-cta]');
              const back = document.querySelector('.back-link');
              const heading = document.querySelector('.review-heading h1');
              const productBar = document.querySelector('.product-bar');
              const productTitle = productBar?.querySelector(':scope > span:first-child');
              const productPill = productBar?.querySelector('.product-pill');
              const textRange = document.createRange();
              if (productTitle) textRange.selectNodeContents(productTitle);
              const textRects = [...textRange.getClientRects()].map(box => ({ width: box.width, height: box.height }));
              const sizes = {
                root: px(root),
                h1: px(heading),
                h2: px(document.querySelector('[data-state-title]')),
                body: px(document.querySelector('[data-body]')),
                fact: px(document.querySelector('.facts li')),
                code: px(document.querySelector('.code-line code')),
                output: px(document.querySelector('.code-output pre')),
                productTitle: px(productTitle),
              };
              const interactive = [...document.querySelectorAll('button,a,select')].map(element => {
                const box = element.getBoundingClientRect();
                return { tag: element.tagName, width: box.width, height: box.height, text: (element.innerText || element.getAttribute('aria-label') || '').trim(), disabled: !!element.disabled };
              });
              return {
                viewport: innerWidth,
                rootScroll: root.scrollWidth,
                bodyScroll: document.body.scrollWidth,
                client: root.clientWidth,
                sizes,
                back: rect(back),
                heading: rect(heading),
                productBar: rect(productBar),
                productTitle: rect(productTitle),
                productPill: rect(productPill),
                productTitleText: productTitle?.innerText?.trim() || '',
                productTitleTextRects: textRects,
                productTitleScroll: { width: productTitle?.scrollWidth || 0, clientWidth: productTitle?.clientWidth || 0, height: productTitle?.scrollHeight || 0, clientHeight: productTitle?.clientHeight || 0 },
                interactive,
                ctaDisabled: cta.disabled,
                state: document.querySelector('[data-state-select]').value,
                locale: root.lang,
                scale: root.style.getPropertyValue('--text-scale'),
                productHasReviewControls: !!screen.querySelector('.reviewer-controls,[data-state-select],[data-lang],[data-scale]'),
                notesInsideProduct: !!screen.querySelector('.reviewer-notes,[data-note]'),
                productText: screen.innerText,
                currentNote: document.querySelector('[data-note]')?.innerText || '',
                outputText: document.querySelector('[data-code-output]')?.innerText || '',
                codeText: [...document.querySelectorAll('.code-line code')].map(el => el.textContent),
                expectedOutput: document.querySelector('.code-output pre')?.textContent || '',
                stateTitle: document.querySelector('[data-state-title]')?.textContent || '',
                bodyText: document.querySelector('[data-body]')?.textContent || '',
                langControl: document.querySelector('[data-lang="vi"]')?.getAttribute('aria-pressed')
              };
            });
            cases++;
            const label = `${slug}/${state}/${locale}/${viewport.width}/${scale}`;
            check(result.rootScroll <= result.client + 1 && result.bodyScroll <= result.client + 1, `${label}: horizontal overflow root=${result.rootScroll} body=${result.bodyScroll} client=${result.client}`);
            const expectedSizes = { root: 16, h1: 20.48, h2: 17.92, body: 15.04, fact: 13.44, code: 12.8, output: 13.12, productTitle: 12.48 };
            for (const key of ['root', 'h1', 'h2', 'body', 'fact', 'productTitle']) {
              if (Number.isFinite(result.sizes[key])) {
                check(near(result.sizes[key], expectedSizes[key] * Number(scale)), `${label}: ${key} computed ${result.sizes[key]}px; expected ${expectedSizes[key] * Number(scale)}px`);
                scaleAssertions++;
              }
            }
            if (result.codeText.length) {
              check(near(result.sizes.code, expectedSizes.code * Number(scale)), `${label}: code computed ${result.sizes.code}px; expected ${expectedSizes.code * Number(scale)}px`);
              scaleAssertions++;
            }
            if (result.expectedOutput) {
              check(near(result.sizes.output, expectedSizes.output * Number(scale)), `${label}: output computed ${result.sizes.output}px; expected ${expectedSizes.output * Number(scale)}px`);
              scaleAssertions++;
            }
            check(result.productTitleText.length > 0, `${label}: product-bar title has no visible inner text`);
            check(result.productTitle.width > 0 && result.productTitle.height > 0 && result.productTitleTextRects.some(box => box.width > 0.5 && box.height > 0.5), `${label}: product-bar title text collapsed or has zero-width fragments`);
            check(result.productTitleScroll.width <= result.productTitleScroll.clientWidth + 1 && result.productTitleScroll.height <= result.productTitleScroll.clientHeight + 1, `${label}: product-bar title content is clipped`);
            check(result.productTitle.left >= result.productBar.left - 0.5 && result.productTitle.right <= result.productBar.right + 0.5, `${label}: product-bar title lies outside its bar`);
            productBarTitleChecks++;
            check(result.productPill.width > 0 && result.productPill.height > 0 && result.productPill.left >= result.productBar.left - 0.5 && result.productPill.right <= result.productBar.right + 0.5 && result.productPill.bottom <= result.productBar.bottom + 0.5, `${label}: product pill is collapsed or outside the bar`);
            productBarPillBoundsChecks++;
            if ((slug === 'a01-w04-journal' && state === 'not_following' && viewport.width === 360) || (slug === 'a03-shared-welcome' && state === 'first_visit' && (viewport.width === 390 || viewport.width === 360))) {
              if (locale === 'en' && scale === '2') await screenshot(`${slug}-r38-product-bar-${state}-${viewport.width}-en-2x.jpg`);
            }
            const overlap = Math.min(result.back.right, result.heading.right) > Math.max(result.back.left, result.heading.left) + 0.5 && Math.min(result.back.bottom, result.heading.bottom) > Math.max(result.back.top, result.heading.top) + 0.5;
            if (overlap) headerOverlapCases++;
            check(!overlap, `${label}: back hit-box overlaps heading`);
            check(Math.round(result.back.width) >= 48 && Math.round(result.back.height) >= 48, `${label}: back target below 48px (${result.back.width}×${result.back.height})`);
            check(result.ctaDisabled, `${label}: primary CTA is not disabled`);
            ctaChecks++;
            check(!result.productHasReviewControls && !result.notesInsideProduct, `${label}: reviewer controls/notes leaked into product viewport`);
            notesSeparationChecks++;
            for (const control of result.interactive) {
              controlsChecked++;
              check(Math.min(control.width, control.height) >= 48, `${label}: ${control.tag} target below 48px: ${control.text} (${control.width}×${control.height})`);
            }
            if (slug === 'a05-w05-bug-hunter') {
              for (const plumbing of ['mq1_03', 'bh_01', 'bug_hunter_puzzles', 'CastRegistry']) check(!result.productText.includes(plumbing), `${label}: source plumbing ${plumbing} appears in child-facing product viewport`);
              if (state === 'ready') {
                check(result.codeText[0] === 'print("Xin chào!")' && result.codeText[1] === 'print("Tớ là Bitsy)', `${label}: pinned Python literals changed`);
                check(result.expectedOutput === 'Xin chào!\nTớ là Bitsy', `${label}: expected_output changed`);
                check(/not executed|chưa thực thi/i.test(result.outputText), `${label}: expected-output/execution distinction missing`);
              }
            }
            if (slug === 'a02-shared-settings' && state === 'manual_en' && locale === 'vi') check(result.stateTitle === 'Dùng tiếng Anh', `${label}: manual English title is not Vietnamese`);
            if (slug === 'a01-w04-journal' && state === 'load_error') {
              check(/selector|bộ chọn/i.test(result.currentNote) && /disabled|tắt/i.test(result.currentNote), `${label}: journal note does not clarify selector and disabled CTA`);
            }
            if (slug === 'a04-w05-catch-stars' && state === 'paused') check(!/program|chương trình/i.test(`${result.stateTitle} ${result.bodyText}`), `${label}: paused copy refers to a program`);
          }
        }
      }
    }

    await page.setViewportSize({ width: 390, height: 844 });
    await page.locator('[data-lang="vi"]').click(); await page.locator('[data-scale="1"]').click(); await page.locator('[data-state-select]').selectOption(states[0]);
    await screenshot(`${slug}-r38-390x844-vi-1x.jpg`);
    await page.setViewportSize({ width: 360, height: 640 }); await page.locator('[data-lang="en"]').click(); await page.locator('[data-scale="2"]').click();
    await screenshot(`${slug}-r38-360x640-en-2x.jpg`);
    await page.locator('[data-lang="vi"]').click(); await page.locator('[data-scale="1.3"]').click(); await page.locator('[data-state-select]').selectOption(states.at(-1));
    await screenshot(`${slug}-r38-${states.at(-1)}-390x844-vi-1.3x.jpg`);
    if (slug === 'a05-w05-bug-hunter') {
      await page.locator('[data-state-select]').selectOption('ready');
      await screenshot('a05-w05-bug-hunter-r38-ready-code-output-390x844-vi-1.3x.jpg');
    }
  }

  const browserVersion = browser.version();
  const report = {
    task: 'PQC-018 R38-A shared product-bar correction regression (Batch A)',
    review_pin: '3c29fc3ad5cd2f7691e22dc7a119ed5de3d147f2',
    date: new Date().toISOString(),
    browser: browserVersion,
    source: 'Static local HTML fixtures only; no Flutter/app execution, network/backend, gameplay, persistence, transaction or AI.',
    scenes: scenes.length,
    stateConfigurations: scenes.reduce((sum, slug) => sum + JSON.parse(fs.readFileSync(path.join(root, slug, 'manifest.json'), 'utf8')).layout.states.length, 0),
    viewportWidths: [390, 360],
    locales,
    textScales: scales,
    cases,
    computedFontAssertions: scaleAssertions,
    productBarTitleChecks,
    productBarPillBoundsChecks,
    headerOverlapCases,
    controlsChecked,
    primaryCtaChecks: ctaChecks,
    reviewerSeparationChecks: notesSeparationChecks,
    horizontalOverflowCases: failures.filter(item => item.includes('horizontal overflow')).length,
    pageErrors,
    failedRequests,
    failures,
    allPrimaryCtasDisabled: ctaChecks === cases,
    allImagesDecoded: true,
    captures,
    screenshots: fs.readdirSync(evidence).filter(name => /^a0[1-5]-/.test(name) && name.includes('-r38-') && name.endsWith('.jpg')).sort(),
    status: failures.length === 0 && pageErrors.length === 0 && failedRequests.length === 0 ? 'PASS' : 'FAIL',
    limits: 'Headless browser measurements for static studies only; screenshots are representative, not a manual review of every state/case. Not Flutter, device, accessibility certification or production acceptance.'
  };
  fs.writeFileSync(path.join(evidence, 'r38a-browser-checks.json'), `${JSON.stringify(report, null, 2)}\n`);
  console.log(JSON.stringify(report, null, 2));
  await browser.close();
  if (report.status !== 'PASS' || pageErrors.length || failedRequests.length) process.exitCode = 1;
})().catch(error => { console.error(error.stack || error); process.exitCode = 1; });
