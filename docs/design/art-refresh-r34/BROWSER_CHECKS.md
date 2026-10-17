# Reproduce r34 design checks

These tools are **optional design tooling**, not Flutter/app/CI dependencies.
Server: `python tools/design/serve_art_review.py --port 8000` from repo root in a
separate process. Bind0.0.0.0; browser URLs/assets remain relative. No backend calls.

## Sandbox browser installation

The final run used Node22.22.3, playwright-core1.64.1 and Chromium153.0.8010.0 supplied
by @sparticuz/chromium153.0.0. This environment permits npm but lacks system NSS/NSPR.
Install only into disposable scratch:

```sh
npm install --prefix /home/user/.cache/pyquest-r34-browser --no-audit --no-fund \
  playwright-core@1.64.1 @sparticuz/chromium@153.0.0

node - <<'JS'
const fs = require('node:fs'), z = require('node:zlib');
const base = '/home/user/.cache/pyquest-r34-browser/';
fs.writeFileSync(base + 'al2023.tar', z.brotliDecompressSync(fs.readFileSync(
  base + 'node_modules/@sparticuz/chromium/bin/al2023.tar.br')));
JS
mkdir -p /home/user/.cache/pyquest-r34-browser/libs
tar xf /home/user/.cache/pyquest-r34-browser/al2023.tar \
  -C /home/user/.cache/pyquest-r34-browser/libs

NODE_PATH=/home/user/.cache/pyquest-r34-browser/node_modules \
LD_LIBRARY_PATH=/home/user/.cache/pyquest-r34-browser/libs/lib \
  node tools/design/check_art_r34.cjs
```

Do not commit node_modules, extracted Chromium, scratch package files or libraries.
No download from an unapproved binary host was used; artifacts came from npm.
The runner supports `ART_REVIEW_URL` for a different local review-server URL.

## What the runner checks

42states across10scenes ×2locales ×2phoneviewports ×3textscales yields504 cases
(the42states are across the10scenes, **not**42 per scene). Geometry and actual computed
text size are checked; scroll to panel end; CTA hit-test and min48px; no horizontal
overflow; privacy image removal. All42CTA transitions are clicked. Locale changes
keep chosen state. Host shell gets a360px smoke check. No pageerrors/HTTPerrors.

Screenshots:10normalphones,4exception states,1scrolled360×640 ENscale2,1galleryoverview.
The host screenshot viewport is1441px wide so centered phone edges fall on integer
CSS pixels. Earlier1440px capture rounded390CSSpx to391PNGpx; final evidence was
recaptured with correct390/360PNG dimensions, without rescaling the images.

## Limits and history

Initial scratch launch needed the module's default export, then failed for missing
libnspr4; bundled al2023 libraries resolved it. These attempts did not change app
or OS dependencies. First successful geometry matrix passed; final matrix rerun
also passed after fixing screenshot pixel alignment and one Vietnamese wording.

Receipt generation overwrites evidence intentionally; do not silently call a later
receipt the result of an earlier source. `manifest.json` hashes evidence at publication.
[checks.json](evidence/checks.json) is **HTML-only**. It is not a Flutter pass, Android
installation, OS keyboard, exhaustive accessibility, real device, gameplay, AI,
commerce or multiplayer test. Source/runtime011 has a separate failed CI review.

Static image/provenance validation:

```sh
# Use Pillow in an external environment (the repo's design tooling already uses it).
python tools/design/validate_art_r34.py
```
