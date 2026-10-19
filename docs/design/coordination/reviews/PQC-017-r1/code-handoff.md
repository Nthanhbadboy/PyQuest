# PQC-017 — CODE hỗ trợ concept 2.5D, không sửa app

- revision: 1 · user authorization: 2026-10-18
- status: **DESIGN_REVIEW_PENDING** (concept/layout package delivered; not accepted or production-approved)
- owner: CODE for bounded art/design support; DESIGN owns visual review
- design source: `ae7289f376d70ab9f73b37346d25edaf727abc12` on `arena/00838eb9-pyquest`
- source context: `a331ac110f19de63e9be6884d08db8c436054f50`; PQC-011 remains **SUBMITTED_UNVERIFIED**
- runtime/app/dependencies/CI/economy changes: **none**
- `design_only: true`; `runtime_ready: false`; production approval: **not granted**

## Delivered under `docs/design/art-refresh-r33/code/`

- `w13-tutor/concept.png`, `layout.html`, `README.md`, `manifest.json`, `prompt.txt`
- `w14-achievements/concept.png`, `layout.html`, `README.md`, `manifest.json`, `prompt-original.txt`, `prompt-restyle.txt`
- `w11-arena/concept.png`, `layout.html`, `README.md`, `manifest.json`, `prompt.txt`
- package `README.md`, `manifest.json`, `index.html`, and byte-for-byte W01 reference copy under `references/`

Three independent generated scene images were selected; they are not a contact sheet. HTML layouts place real, bilingual UI copy over the scene image and offer selectors for 390×844 / 360×640, VI / EN, study states and 1× / 2× text. In-phone controls are disabled design mocks; these files are not an app.

### Source-correct content

- W13: source-pinned `mq1_01` / `mq1_01_s2`, `Lesson.skill=print()`, `CastRegistry.tutorForSkill` → Nova, with visual cues from `NovaPainter`. The code literal remains `print("Xin chào!")` and the requested display output remains `Xin chào!` in both locales. The source example's `expected_output` is null, so the overlay is labelled **sample output · runtime not verified**. It does not claim voice, freehand or editable learner input.
- W14: selected detail uses the actual a331 `first_line` title/description/how-to. All earned/locked/secret statuses are labelled visual fixtures, not player progress; no secret condition is disclosed. The social-reward category is empty because no social item registry exists in that pinned catalog.
- W11: source-backed Robo is a fictional practice-scene host only. Pinned source has no Arena module or rule registry. “Xem luật” / “Luyện tập” are disabled design targets; no opponent, score, rank, reward, team, tournament or live route is claimed.

## Review gaps / not delivered

- W14 remains more frontal/perspective than W01's 3/4 orthographic anchor after one restyle pass; DESIGN camera/material review and likely correction are required.
- W13/W11 cameras, actor scale and gameplay alignment remain illustrative, not calibrated to runtime geometry.
- Images are flattened opaque concepts, not layered runtime art. Alpha, pivots, footprints, masks, animation, navigation/collision, app routing and scoring are not delivered.
- Contrast, focus/screen-reader behavior, device safe areas, touch targets on hardware, screenshots and usability were not measured. The HTML study uses 48px minimum targets and scrollable content as design intent only.
- W14 selected-original bytes were overwritten by its one restyle pass before its hash was recorded; the manifest explicitly leaves that hash unclaimed.
- Generator model/version and release terms were not exposed/reviewed. No CC0/exclusivity/stock-license claim; rights review is still required.

## Checks actually run

- Read the pinned work order, ART_DIRECTION, WORLD_EXPANSION, r33 README/manifest and all four synchronized originals with `git show` at the DESIGN SHA.
- Read W01 reference at full resolution; pinned W01 SHA256 recorded.
- Read relevant CastRegistry, Nova painter, lesson JSON, achievement catalog/house module at a331 SHA; pinned blob and file hashes recorded.
- Image dimension/format/byte/SHA256 checks using a Python standard-library image-header parser.
- JSON parsing, HTML/source-copy checks and JavaScript syntax checks: see package manifest for exact results.
- Browser-render, Flutter, app tests, CI, APK, device and contrast tests: **not run** (outside scope or unavailable).

Do not mark PQC-017 accepted until DESIGN completes image review. This package does not change PQC-011's **SUBMITTED_UNVERIFIED** state.
