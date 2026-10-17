# PQC-018 · Art completion r36 — Batch A

**Status:** Five concepts retained unchanged; all five screen studies revised for DESIGN findings R36-A/B/C. Technical fixtures pass; the screen disposition remains **SCREEN_CHANGES_REQUESTED pending DESIGN re-review**. Batch B is pending, so PQC-018 remains IN_PROGRESS.

Each scene has a separate AI-generated 928×1152 opaque `concept.png`, original prompt, localized layout, manifest, and scene notes. The five original PNG bytes and SHA-256 hashes are unchanged. The corrected product view is distinct from reviewer language/scale/state controls and reviewer-only source notes. No CTA executes an app, game, save, grant, transaction, sign-in, network request, or AI inference.

## Open the studies

- [A01 · W04 Journey Journal](a01-w04-journal/layout.html) — front-facing journal spread; followed project, separate daily goal, multiple pending results, load failure.
- [A02 · Shared Settings](a02-shared-settings/layout.html) — settings board integrated into a timber/stone control alcove; system/fallback, manual VI/EN, save failure and retry.
- [A03 · Shared Welcome](a03-shared-welcome/layout.html) — open village landing and gate; first visit, returning, loading and retry.
- [A04 · W05 Catch Stars](a04-w05-catch-stars/layout.html) — clear falling-star lane and catcher; ready, paused and result fixture, no game loop.
- [A05 · W05 Bug Hunter](a05-w05-bug-hunter/layout.html) — Bitsy, front-facing code board and separate expected-output tray; source gate, ready puzzle and error fixture.

Each page has local VI/EN, 1×/1.3×/2×, and state controls in the **reviewer area outside the product viewport**. Product copy contains no source IDs/plumbing. A05 reviewer notes retain exact gate/source mapping, Python literals, and the expected-output-versus-execution distinction. Primary CTAs remain disabled.

## R36 correction evidence

- [R36-A/B/C browser report](evidence/r36a-browser-checks.json) and [reproducible Playwright script](evidence/r36a_browser_check.cjs).
- [Static/provenance report](evidence/r36a-static-checks.json) and [dependency-free checker](evidence/r36a_static_check.py).
- [Representative captures](evidence/) — 16 actual JPEG captures; they are not a manual review of all 240 configurations.
- [Original bytes/hash archive](evidence/r36a-originals/originals.json), baseline commit `1053973da1ad11378f7263d7b13a4d61667133af`.
- [16-image intake and review pins](reviewed-inputs.json); r35 catalog bytes remain pinned, with the r36 review pin recorded separately.

Chromium 153 executed 240 fixture cases: five scenes, all 20 declared states, two viewport sizes, VI/EN and 1×/1.3×/2×. Reported outcomes: **0 horizontal overflow**, **0 header/title overlaps**, **1,259 computed-font assertions**, 2,160 target-size checks, all CTAs disabled, all images decoded, no page errors or failed requests. The computed sizes were asserted, not inferred from CSS declarations. These are static-browser checks only; no Flutter, device, accessibility certification, production or runtime acceptance is claimed.

Serve from repository root so app fonts resolve:

```sh
python3 -m http.server 8000 --bind 0.0.0.0
```

Open `/docs/design/art-completion-r36/code/`. Browser test environment used outside-repository Playwright/Chromium; instructions and results are recorded in `evidence/BROWSER_CHECKS.md`.

## Scope and truth labels

Concept and screen study only. No alpha/layer separation, sprite/skeleton/tween, measured camera, pivots, footprints, occluders, runtime route, game loop, physics, account, cloud state, backend authority, real moderation, persistence, AI inference or purchase transaction is provided. No new gameplay, reward, unlock, account or settings behavior is asserted. DESIGN has not yet re-reviewed the correction. Batch B is not included.
