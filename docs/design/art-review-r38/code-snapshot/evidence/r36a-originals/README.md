# PQC-018 · Art completion r36 — Batch A

**Status:** Batch A (5/9) concept + responsive screen-study assets. The remaining Batch B scenes are intentionally not included in this handoff.

All scene art is AI-generated concept imagery. Each scene has its own full-size `concept.png`, `layout.html`, `prompt.txt`, `manifest.json`, and short review notes. The interface panels are front-facing, localized VI/EN fixture overlays; no displayed CTA executes a game, saves a setting, grants a reward, transacts, signs in, or contacts a server.

## Open the studies

- [A01 · W04 Journey Journal](a01-w04-journal/layout.html) — followed project, separate daily goal, multiple pending results, load failure.
- [A02 · Shared Settings](a02-shared-settings/layout.html) — system/active/fallback, manual VI/EN, save failure and retry.
- [A03 · Shared Welcome](a03-shared-welcome/layout.html) — first visit, returning, loading and retry.
- [A04 · W05 Catch Stars](a04-w05-catch-stars/layout.html) — ready, paused and result fixture; no game simulation.
- [A05 · W05 Bug Hunter](a05-w05-bug-hunter/layout.html) — source lesson gate, ready puzzle and error/wrong-fix fixture.

Each page has local VI/EN, 1×/1.3×/2× text controls and a local state selector. These selectors only change the displayed study fixture. The main CTA is disabled. All important UI text is separate from the generated scene image.

## Review inputs and provenance

- [Mandatory 16-image review and scene-reference decisions](reviewed-inputs.json).
- DESIGN source pin: `cbb0f8bed808a888ae607bb31ba6343c182bf0b8`.
- W01 is the primary visual anchor. Active W02/W08 are the published corrected copies; W14 is the r35 3/4 daylight/empty correction. Known W02/W03/W07 geometry caveats are not reused.
- Runtime identity/source pin: `a331ac110f19de63e9be6884d08db8c436054f50`. Module rules and character identity remain owned by app source; this handoff changes no runtime files.
- Every scene manifest records image SHA-256, dimensions, source paths, reference IDs/hashes, exact prompt provenance, state IDs and `runtime_ready: false` / `production_approved: false`.

## Local preview / checks

Serve from repository root so the studies can load the existing app font files at `app/assets/fonts/`:

```sh
python3 -m http.server 8000 --bind 0.0.0.0
```

Open `/docs/design/art-completion-r36/code/`. This is static design material, not a Flutter app. Batch A browser status is recorded in `evidence/` and the handoff task; browser/device proof is not implied unless the evidence explicitly says it was executed.

## Scope and truth labels

Concept and screen study only. No alpha/layer separation, measured camera, pivots, footprints, occluders, runtime route, game loop, physics, account, cloud state, backend authority, real moderation, actual persistence, AI inference or purchase transaction is provided. All sample data remains visibly fixture-labeled. Do not port to app/runtime or infer product rules from the pictures.
