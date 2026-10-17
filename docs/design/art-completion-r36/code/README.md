# PQC-018 · Nine art/design studies

**Status:** Nine concepts retained; R38-A/B screen corrections implemented in CODE and submitted for DESIGN re-review. PQC-018 remains **IN_PROGRESS** and is not self-accepted. All nine PNGs are unchanged.

These are localized static HTML fixtures only. Reviewer controls and notes sit outside each product viewport, all primary CTAs remain disabled, and nothing connects to app/runtime behavior.

## Scenes

- [A01 · W04 Journey Journal](a01-w04-journal/layout.html) — project follow, separate daily goal, pending results, load error.
- [A02 · Shared Settings](a02-shared-settings/layout.html) — integrated preference board; system/fallback, manual VI/EN, save error, retry.
- [A03 · Shared Welcome](a03-shared-welcome/layout.html) — open village landing; first visit, returning, loading, retry.
- [A04 · W05 Catch Stars](a04-w05-catch-stars/layout.html) — clear star lane/catcher; ready, paused, result.
- [A05 · W05 Bug Hunter](a05-w05-bug-hunter/layout.html) — Bitsy, front-facing code board and expected-output tray; source gate, ready, wrong/error.
- [B01 · Friends & Invites](b01-w09-friends-invites/layout.html) — community nook and recipient list; empty, pending, expired, host away, blocked, report confirmation.
- [B02 · Creator Editor](b02-w12-creator-editor/layout.html) — readable, read-only editor sample distinct from preview and version tray; unsaved, test-error, private, moderation fixtures.
- [B03 · Completed W03 ground-floor room](b03-w07-built-room/layout.html) — solid floor, real ground-level door, workbench, no cyan ghost.
- [B04 · Miu resting](b04-w10-pet-rest/layout.html) — same orange Miu under the W10 pergola; one still pose.

## R38 correction evidence

- DESIGN review pin: `3c29fc3ad5cd2f7691e22dc7a119ed5de3d147f2`.
- **R38-A:** Shared product bar wraps/stack titles and pill at full title font size. No hiding, clipping, truncation, or font shrinking. Browser assertions check rendered inner text and nonzero text fragments, clipping dimensions, title scale, and pill bounds, including all three reported A01/A03 2× cases.
- **R38-B:** B02 editor is a focusable read-only mock distinct from the illustrative preview and version tray. Its three fictional VI/EN prose lines were authored by CODE for this study and are explicitly attributed; they are not game APIs/code/canon, lesson answers, or graders. No interpreter, persistence or publishing was added; primary CTA stays disabled.
- Chromium 153 regression: **A 240/240 + B 192/192 = 432/432**; **1,499 A** and **1,296 B** computed-font assertions, including **144 B02 editor-font assertions across all 48 B02 combinations**. B02 visible-content checks **48/48**. Product title inner-text and pill-bound checks **432/432**; zero overflow, header overlaps, page errors or failed requests. All primary CTAs disabled. Captures: **19 A + 20 B**.
- Current machine-readable results: [`r38a-browser-checks.json`](evidence/r38a-browser-checks.json), [`r38-batch-b-browser-checks.json`](evidence/r38-batch-b-browser-checks.json), and R38 static/provenance **129/129 PASS** in [`r38-static-checks.json`](evidence/r38-static-checks.json). Exact pre-R38 sources/hashes and all nine original PNG hashes are archived in [`evidence/r38-originals/`](evidence/r38-originals/).
- Historical receipts remain intact: A R36 evidence in [`r36a-browser-checks.json`](evidence/r36a-browser-checks.json); final pre-R38 B static count **79/79 PASS** in [`batch-b-static-checks.json`](evidence/batch-b-static-checks.json) (the earlier task sentence claiming 67/67 was stale); pre-R38 B browser receipt in [`batch-b-browser-checks.json`](evidence/batch-b-browser-checks.json).

The A correction and B concept batches were delivered separately as `ab0ae35eafebf8602ef714d85004ad4b744898a4` and `0990fbcbf6045bd64244239e36ccbca8c8dc394b`. R38-A/B are one additional substantive correction awaiting DESIGN review; no self-acceptance or production approval is claimed.

## Limits and preview

No Flutter/app/device, accessibility certification, backend, persistence, gameplay, economy, moderation, AI inference, animation, geometry or production behavior is tested or implemented. Concept art and static fixtures are not runtime proof.

Serve from the repository root to load the app fonts:

```sh
python3 -m http.server 8000 --bind 0.0.0.0
```

Open `/docs/design/art-completion-r36/code/`. Browser scripts and test setup are in [`evidence/BATCH_B_CHECKS.md`](evidence/BATCH_B_CHECKS.md).
