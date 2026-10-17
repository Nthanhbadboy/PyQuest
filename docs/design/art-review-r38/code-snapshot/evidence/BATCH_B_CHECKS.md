# PQC-018 Batch B · checks and evidence

**Status:** Static checks and browser fixture tests pass. Batch B is submitted for DESIGN review; no screen/concept is self-accepted.

## Reproduce

```sh
python3 docs/design/art-completion-r36/code/evidence/batch_b_static_check.py
LD_LIBRARY_PATH=/home/user/.cache/pyquest-r36-browser/libs/lib \
node docs/design/art-completion-r36/code/evidence/batch_b_browser_check.cjs
```

The browser check uses Playwright/Chromium installed outside the repository and a static server rooted at the repository on port 4180. Override `PQC018_BASE_URL`, `PLAYWRIGHT_MODULE` or `CHROMIUM_MODULE` if using a different local test environment. No app dependencies were added.

## Actual results

- Dependency-free static/reference/layout/image/prompt/manifest checks: **79/79 PASS** (`batch-b-static-checks.json`).
- Headless Chromium **153.0.8010.0**, four scenes and **16 declared state configurations**.
- 390×844 and 360×640 CSS viewports; Vietnamese/English; 1×, 1.3×, 2×; **192/192** combinations.
- Computed-font assertions: **960**; header/back-title overlaps: **0**; horizontal overflow: **0**.
- Interactive targets: **1,728** checks, all ≥48×48 CSS px; primary CTAs disabled: **192/192**.
- Reviewer controls/notes outside product viewport: **192/192**; footer reached by scrolling to document end: **192/192**.
- Four images decoded; page errors: **0**; failed requests: **0**.
- **20** actual JPEG captures: each declared state at 390×844 VI 1× plus one 360×640 EN 2× capture per scene. Captures are representative evidence, not manual review of all browser combinations.

Machine-readable result: [`batch-b-browser-checks.json`](batch-b-browser-checks.json). The reproducible scripts are [`batch_b_browser_check.cjs`](batch_b_browser_check.cjs) and [`batch_b_static_check.py`](batch_b_static_check.py).

## Visual / source scope

All four new concept images were opened individually at full size. B03 visibly has a continuous floor and connected ground-level doorway without the cyan construction ghost. B04 depicts the same orange Miu at rest under the W10 pergola, not the gray W10b shop kitten. B01 and B02 include the requested environmental spaces; the state lists/editor/preview/tray are front-facing HTML overlays rather than text baked into the image. Exact canonical reference paths/hashes, generation inputs, prompt hashes and notes are in `reviewed-inputs.json` and each scene manifest.

## Limits

This is a static design preview only. No Flutter/app/device, accessibility certification, online service, invite delivery, moderation backend, creator persistence/publishing, room runtime geometry/cost/collision, pet AI/model call, gameplay, animation or production acceptance was tested or implemented. Static concept art does not prove that a feature exists.
