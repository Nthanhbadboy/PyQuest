# PQC-018 · Art completion r36 — nine concept studies

**Status:** All nine concept images are present. Batch A screens were corrected for R36-A/B/C and pass the static browser checks; DESIGN review is pending. Batch B concepts and state studies are delivered in a separate batch commit and await DESIGN review. PQC-018 remains **IN_PROGRESS**; nothing here is self-accepted.

All concepts are separate, opaque AI-generated images with stored prompts. The A01–A05 original PNGs remain byte-for-byte unchanged. Each screen uses localized HTML fixtures; reviewer controls and technical notes are outside the product viewport. No CTA executes app/runtime behavior.

## Batch A · correction submitted for DESIGN review

- [A01 · W04 Journey Journal](a01-w04-journal/layout.html) — paper spread; following project, separate daily goal, pending results, load error.
- [A02 · Shared Settings](a02-shared-settings/layout.html) — integrated timber/stone preference board; system/fallback, manual VI/EN, save error, retry.
- [A03 · Shared Welcome](a03-shared-welcome/layout.html) — open village landing; first visit, returning, loading, retry.
- [A04 · W05 Catch Stars](a04-w05-catch-stars/layout.html) — clear star lane/catcher; ready, paused, result.
- [A05 · W05 Bug Hunter](a05-w05-bug-hunter/layout.html) — Bitsy, front-facing code board and expected-output tray; source gate, ready, wrong/error.

Batch A correction commit: `ab0ae35eafebf8602ef714d85004ad4b744898a4`. Exact original files/hashes are archived in [`evidence/r36a-originals/`](evidence/r36a-originals/). Results and scope limits: [`evidence/r36a-browser-checks.json`](evidence/r36a-browser-checks.json), [`evidence/r36a-static-checks.json`](evidence/r36a-static-checks.json), and [`evidence/BROWSER_CHECKS.md`](evidence/BROWSER_CHECKS.md).

## Batch B · concept studies submitted for DESIGN review

- [B01 · Friends & Invites](b01-w09-friends-invites/layout.html) — community nook plus friend/recipient list; empty, pending, expired, host away, blocked, report confirmation.
- [B02 · Creator Editor](b02-w12-creator-editor/layout.html) — visible editor, separate preview and version tray; unsaved draft, test error, saved-private, moderation pending.
- [B03 · Completed W03 ground-floor room](b03-w07-built-room/layout.html) — solid floor, real ground-level door, workbench, no cyan ghost; completed/enter, workbench, blocked arrangement.
- [B04 · Miu resting](b04-w10-pet-rest/layout.html) — the same orange Miu under the W10 pergola; rest, unsupported AI, model removed with baseline retained.

Batch B manifests record exact active reference paths/hashes, actual image dimensions/bytes, prompt hashes, and which pinned images were passed to generation. [Full-size review notes and input provenance](reviewed-inputs.json). Evidence: [`evidence/batch-b-browser-checks.json`](evidence/batch-b-browser-checks.json) and [`evidence/batch-b-static-checks.json`](evidence/batch-b-static-checks.json).

Batch B Chromium 153: **192/192** combinations (four scenes, 16 state configurations, two phone sizes, VI/EN, 1×/1.3×/2×); 960 computed-font assertions, 1,728 target-size checks, zero horizontal overflow or header overlap, all CTAs disabled, reviewer/product separation and footer reachability in all 192 cases, zero page errors/request failures, all four images decoded. Twenty captures include each declared state and 360×640 EN 2× scene examples. Details and reproducible commands: [`evidence/BATCH_B_CHECKS.md`](evidence/BATCH_B_CHECKS.md). DESIGN review is pending.

## Shared truth labels and limits

Browser evidence is for static design fixtures, not Flutter/app/device, accessibility certification, production approval, or runtime validation. No real friends/online/backend/moderation, persistence, published creator content, game loop, room geometry/collision/cost, reward, AI inference, or animation is implemented. Static images do not define calibrated geometry, layers, sprites, or interaction rules. Batch A R36-A/B/C correction and Batch B both remain pending DESIGN review.

Serve from repository root for the app font files:

```sh
python3 -m http.server 8000 --bind 0.0.0.0
```

Open `/docs/design/art-completion-r36/code/`. Test scripts and outside-repository browser setup are documented under `evidence/`.
