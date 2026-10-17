# PQC-017 — 2.5D concept scenes and phone-overlay studies

**Status:** generated concept scenes + design-only screen compositions; **awaiting DESIGN visual review**. This is not runtime art, an app screen, a usability pass, or production approval.

## Files

- [W13 Tutor Room](w13-tutor/README.md) — scene, interactive preview harness, state/copy map, prompt and provenance.
- [W14 Achievement House](w14-achievements/README.md) — scene, preview, badge-state fixture, source mapping and provenance.
- [W11 Practice Arena](w11-arena/README.md) — scene, preview, rules/unavailable states, source mapping and provenance.
- [`manifest.json`](manifest.json) — package and input pins, image dimensions/hashes, tool and rights notes.
- [`references/w01-village.jpg`](references/w01-village.jpg) — byte-for-byte copy of the W01 anchor from the pinned DESIGN commit, for the generation reference.

Each `layout.html` is a **static design study** with real HTML text overlays and selectors for 390×844 / 360×640, VI / EN, its required study states, and 1× / 2× text scale. The selectors only change the preview; controls inside the phone are disabled mock controls. Open the individual HTML file in a browser. Images are background scene concepts using proportional `cover` crop; they are not stretched, treated as a running app, or used as evidence of hit targets.

## Source and truthful-content map

- Design contract: commit `ae7289f376d70ab9f73b37346d25edaf727abc12` (`DESIGN-r33`), especially `ART_DIRECTION_2_5D.md`, `WORLD_EXPANSION_REDESIGN.md`, the four synchronized originals, r33 README/manifest and W01 village concept.
- Runtime/content identity reference only: commit `a331ac110f19de63e9be6884d08db8c436054f50`. The user's PQC-011 status remains **SUBMITTED_UNVERIFIED**; this package neither tests nor accepts it.
- W13 maps `mq1_01` / `mq1_01_s2`, `Lesson.skill = print()`, `CastRegistry.tutorForSkill` → Nova. The literal `print("Xin chào!")` and requested sample output `Xin chào!` are shown unchanged in both locales. The pinned lesson example has `expected_output: null`; therefore the overlay calls this **sample output / runtime not verified**, not an execution result. No voice, freehand, editable learner input, or working Run capability is claimed.
- W14 maps the real `first_line` definition from `achievement_catalog.dart` for selected-item detail. All earned/locked/secret shapes in the preview are explicitly labelled **sample fixtures**, not player progress. Secret conditions are not disclosed. The pinned catalog has no social-reward item registry; the social category is shown empty and labelled accordingly.
- W11 uses the source-backed Robo identity only as a practice-scene host. The pinned app has no Arena module/rule registry. The practice entry points and rules are design targets, not live routes; no opponent, score, rank, tournament, team, reward, or online presence is fabricated.

## Visual review notes and gaps

- W01 is the sole material/landmark anchor. W02 and W08 are not used as style authorization.
- W13 is a dimensional cutaway classroom with source-derived Nova, blank front-facing teaching surface, desk and clear path. The camera is an illustrative approximation, not measured orthographic geometry; the output/editor arrangement exists in HTML overlay, not in the generated pixels.
- W14 has dimensional cabinet, plinths, ledges, display niches and floor path, but its final generated interior still reads more frontal/perspective than W01's 3/4 orthographic anchor. A DESIGN camera/material review is required before selection as a family match.
- W11 has a coherent raised practice floor, tile field, separate Robo standing zone and exit arch. Camera/actor scale and obstacle-to-Maze correspondence remain illustrative and need DESIGN/gameplay review.
- Every image remains one flattened, opaque generated bitmap. No alpha, separated props, pivots, footprints, occlusion masks, animation or navigation/collision metadata are delivered.
- `layout.html` uses high-contrast intent and flexible/scrollable content; there is no measured contrast audit, screen-reader/focus test, hardware screenshot, touch test, or user study. At 2× the composition may scroll and the scene can be occluded by the content sheet; no text is intentionally clipped by a fixed-height overlay.
- Rights note: concepts were generated in Arena's built-in image tool from a project-owned W01 image; no third-party reference image was supplied. The generator did not expose a model/version identifier. Service terms and release rights have not been reviewed, and no exclusivity or third-party stock-license claim is made.

## Checks

Actual checks are recorded in [`manifest.json`](manifest.json) and each screen manifest. No Flutter/app/CI/APK work was performed, by scope. The HTML preview is a design artifact, not runtime implementation.
