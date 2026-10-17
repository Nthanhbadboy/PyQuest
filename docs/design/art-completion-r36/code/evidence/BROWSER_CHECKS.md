# PQC-018 Batch A browser review

**Final run: PASS in headless Chromium 153.0.8010.0** against the local static review server, 2026-10-18 Asia/Saigon. This exercised the five Batch A HTML studies only; it did not run Flutter, the app, any game loop, networking, account, storage, transaction, reward, or AI system.

## Matrix and outcome

- 5 scenes; all 20 declared state fixtures.
- 390×844 and 360×640 CSS viewports.
- Vietnamese and English.
- 1×, 1.3×, and 2× text scale.
- **240 state/locale/viewport/scale cases** checked.
- Horizontal overflow: **0/240**; maximum measured overflow: 0 CSS px.
- Visible controls checked for at least 48×48 CSS px; primary CTAs remained disabled in every case.
- All five scene images decoded; no page errors or failed requests.
- **21** JPEG captures are in this directory: each page at both phone sizes and EN 2×, plus the selected pending/error/result/source-code states.

The first target-size pass found the small inline source link below 48 px. It was changed to a 48 px touch target and the complete matrix was rerun; the final run above is the clean rerun.

## Important limits

These are screenshots/browser results for static design fixtures, not device/safe-area/keyboard, Flutter, accessibility audit, child usability, contrast certification, runtime gameplay, physics, persistence, or production approval. State and language selectors only switch local fixture copy. The app/runtimes were not changed.

Exact machine-readable results: [`browser-checks.json`](browser-checks.json). Static/source checks: [`static-checks.json`](static-checks.json).
