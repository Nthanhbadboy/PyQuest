# PQC-018 Batch A · R36-A/B/C browser evidence

**Disposition:** Browser fixture checks PASS; DESIGN screen disposition remains **SCREEN_CHANGES_REQUESTED pending re-review**. This report does not self-accept the screen studies.

## Reproducible command

The checker is `r36a_browser_check.cjs`. It uses Playwright Core and Sparticuz Chromium installed outside the repository; it adds no app dependency. In the current sandbox:

```sh
LD_LIBRARY_PATH=/home/user/.cache/pyquest-r36-browser/libs/lib \
node docs/design/art-completion-r36/code/evidence/r36a_browser_check.cjs
```

The local static server is rooted at the repository, port 4180. Set `PQC018_BASE_URL` to another local review-server URL if needed; `PLAYWRIGHT_MODULE` and `CHROMIUM_MODULE` can point to the external browser modules.

## Matrix and measured results

- Chromium **153.0.8010.0**; five static HTML scenes, 20 declared states.
- 390×844 and 360×640 CSS viewports; VI and EN; 1×, 1.3×, and 2× scale.
- **240/240** combinations checked.
- Horizontal page overflow: **0**; header back-target/title overlap: **0**.
- **1,259** computed-font assertions over root, h1, h2, body, facts, code, and expected-output text. Scale was checked against computed pixel sizes at each scale.
- Interactive-target checks: **2,160**; all measured targets ≥48×48 CSS px.
- Main CTAs disabled: **240/240**.
- Reviewer controls/notes separated from product viewport: **240/240**.
- Scene images decoded; page errors: **0**; failed requests: **0**.
- Captures: **16** representative JPEGs; not every state/case was manually inspected.

Machine-readable result: [`r36a-browser-checks.json`](r36a-browser-checks.json). The previous [`browser-checks.json`](browser-checks.json) is the Batch A pre-correction baseline and must not be read as the R36 correction report.

## Targeted copy/source assertions

The fixture checker also checks the Journal load-error note (state selector outside product viewport; CTA disabled), Catch Stars paused copy (attempt, not “program”), VI copy for manual English setting, and A05 child-facing product copy with source IDs absent. A05 code assertions preserve the exact source Python literals and expected output; the label explicitly says that expected output is data and was not executed.

## Limits

Headless static-browser measurements only. No Flutter/app execution, Android/iOS device or safe-area/keyboard validation, child usability or accessibility certification, runtime gameplay, physics, network/backend, account, persistence, reward, transaction, AI or production acceptance. Representative screenshots do not establish visual review of all 240 cases. The corrected screens still require DESIGN review.
