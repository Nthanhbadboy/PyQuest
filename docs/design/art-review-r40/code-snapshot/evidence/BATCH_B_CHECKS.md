# PQC-018 Batch B · checks and evidence

**Status:** R38-A/B correction regression passes; submitted for DESIGN review, not self-accepted.

## Reproduce R38

```sh
python3 docs/design/art-completion-r36/code/evidence/r38_static_check.py
LD_LIBRARY_PATH=/home/user/.cache/pyquest-r36-browser/libs/lib \
PQC018_BASE_URL=http://127.0.0.1:4180/docs/design/art-completion-r36/code \
node docs/design/art-completion-r36/code/evidence/batch_b_browser_check.cjs
```

Serve the repository root on port 4180 for browser runs. Override `PQC018_BASE_URL`, `PLAYWRIGHT_MODULE` or `CHROMIUM_MODULE` for another local setup. No app dependencies were added.

## R38 actual results

- Browser regression: Chromium **153.0.8010.0**, B **192/192** across four scenes, 16 state configurations, two viewport widths, VI/EN and 1×/1.3×/2×.
- Computed-font assertions: **1,296**, including **144 B02 editor-font assertions across all 48 B02 combinations**. B02 visible authored sample-content checks: **48/48**.
- Shared product-bar title inner-text/zero-width and pill-bound checks: **192/192** each; zero horizontal overflow and header overlap.
- Interactive targets: **1,728** checks ≥48×48 CSS px; disabled primary CTA: **192/192**; reviewer/product separation: **192/192**; footer reachability: **192/192**.
- Four images decoded; page errors: **0**; failed requests: **0**; representative JPEG captures: **20**.
- Combined A+B R38 regression: **432/432** cases; the R38 static/provenance receipt is **129/129 PASS** in [`r38-static-checks.json`](r38-static-checks.json), the B browser receipt is [`r38-batch-b-browser-checks.json`](r38-batch-b-browser-checks.json), and A is [`r38a-browser-checks.json`](r38a-browser-checks.json).

## Historical pre-R38 receipt

The final pre-R38 Batch B dependency-free static/reference/layout/image/prompt/manifest check was **79/79 PASS** in [`batch-b-static-checks.json`](batch-b-static-checks.json). An earlier task sentence saying 67/67 was stale. The pre-R38 B browser receipt is preserved at [`batch-b-browser-checks.json`](batch-b-browser-checks.json); it is not overwritten by the R38 regression.

## Visual / source scope

All four concept images remain unchanged. B02 now displays a distinct read-only editor surface, separate from the preview and version tray. Its three VI/EN sample lines are fictional prose authored by CODE for this study; provenance explicitly excludes game APIs/code/canon, lesson answers and graders. There is no interpreter, persistence or publishing. The primary CTA remains disabled. Full-size concept observations and reference hashes remain in `reviewed-inputs.json` and each scene manifest.

## Limits

Static design preview only; no Flutter/app/device, accessibility certification, online service, invite delivery, moderation backend, creator persistence/publishing, room runtime geometry/cost/collision, pet AI/model call, gameplay, animation or production acceptance was tested or implemented.
