# PyQuest Village — 2.5D Redesign Brief

Status: design direction / future implementation scope. Visual concept committed at [PYQUEST_VILLAGE_2_5D_CONCEPT.svg](./PYQUEST_VILLAGE_2_5D_CONCEPT.svg). This is a design mockup, not implemented app UI. Do not begin this UI overhaul before the AI Tutor greeting/speaker-label bug is fixed and verified.

## Product intent

The current village feels cramped and visually flat. Redesign it as a larger, explorable-feeling **2.5D learning world** for children under 12, consistent with `PRODUCT_VISION.md` §1—not a preschool playroom. Visual maturity means stronger hierarchy, craftsmanship and usability; it does not change the product audience to teens or adults. The village should reward exploration and make the learning journey feel alive, while the actual lessons, Python editor, Arena and AI Tutor remain readable and task-focused.

## Visual direction

- Use a fixed 3/4 isometric camera and layered depth: foreground, walkable ground, buildings/props, characters, background hills/sky.
- Choose one coherent art style and palette. Prefer polished low-poly/isometric forms with soft directional shadows, subtle gradients and restrained outlines; avoid mixing pixel-art sprites with smooth vector UI.
- Use depth, scale, occlusion and shadows to imply 2.5D. If runtime 3D is too expensive for the Flutter app, render approved 3D models from a fixed camera to optimized transparent PNG sprite frames.
- The village map should feel broader than one screen: allow controlled pan/scroll and reveal additional districts gradually. Avoid shrinking everything to fit one static canvas.
- Keep labels, buttons and progress UI as clean overlays, separate from scenery. Maintain strong contrast and comfortable tap targets on phones.
- Avoid over-saturated candy colors, oversized babyish faces, random decorative clutter, and UI that competes with learning.

## Village layout and expansion

Build a connected map with clear landmarks and readable paths. Candidate districts (final names may change after source audit):

1. **Village Square** — spawn point, welcome board, daily goal and a few moving residents.
2. **Python Academy** — lesson entrance, learning streak and next lesson; must link to the real lesson flow.
3. **Code Workshop** — coding challenges, build/repair interactions and earned cosmetic unlocks.
4. **Arena Gate** — entry to Arena modes and Creator Pro League; show availability and status truthfully.
5. **Market / Customization** — outfit, avatar and decoration previews; do not imply paid ownership unless the purchase flow exists.
6. **Forest Trail** — optional exploration route, collectible learning hints and environmental props.
7. **Community Plaza** — safe, moderated community/gift features only where already supported by product policy and backend.

Use locked/coming-soon areas only when the product has an actual progression or planned-state model. Do not create fake buttons or dead-end buildings.

## Animated character requirements

- Add a small, purposeful cast of moving NPCs rather than a crowd of identical static decorations.
- At minimum, aim for idle and walk loops; add talk/work/special emotes only where they communicate a role.
- Example roles: learner/player avatar, guide/mentor, academy teacher, workshop engineer, market keeper, explorer, and a few background villagers/animals.
- NPCs may follow short bounded paths, pause at landmarks, turn/face the destination, and occasionally play an idle animation. Keep motion slow and calm; avoid every character moving at once.
- Tap a relevant NPC/building to open a short, useful interaction or navigate to an existing feature. Avoid dialogue spam and interactions that block navigation.
- Ensure character feet align with the ground plane; use consistent scale, shadows, draw order and occlusion so a character can pass behind a building or foreground prop where appropriate.
- Respect reduced-motion/accessibility settings if available. Pause nonessential animations when the village is off-screen or backgrounded.
- Use deterministic animation state and bounded timers; do not create an uncontrolled animation loop per NPC.

## Asset pipeline

Preferred first research source: https://www.autosprite.io/free-sprite-sheets (site states CC0, commercial use allowed, no attribution and no sign-up; individual assets differ in animation states and camera angle). Candidates documented in `CRAFTPIX_ASSET_RESEARCH.md` are research leads, not approved final art.

For a convincing isometric 2.5D village, prioritize either:
- a coherent set of **isometric/3/4-view sprite sheets with idle + walk**, or
- low-poly 3D characters and environment props rendered from one fixed isometric camera to sprites.

Do not use side-view combat sprites as village residents merely because they are animated. Inspect actual PNGs and frame sequences first. Keep a source/license manifest, record download URL and license, optimize PNG dimensions and file size, and include only assets actually used by the app. No-login download availability does not itself prove compatibility with the chosen art direction.

## Implementation constraints

- First inspect the existing village source, navigation, state, assets and tests; identify the exact files that must change and why.
- Preserve current product flows and existing persistence. Village redesign must not alter lesson progression, purchase entitlement, Arena state, or AI Tutor behavior.
- Do not start the full redesign until the AI Tutor greeting/speaker-label issue is fixed and regression-tested.
- Use a data-driven map model for districts, paths, props and NPCs where that fits the current architecture; avoid a giant hard-coded widget.
- Keep rendering performant on low-memory Android devices: atlas/sprite-sheet reuse, bounded animation frame rates, culling off-screen NPCs, and asset-size budgets.
- Support different phone aspect ratios and safe areas. Avoid text baked into art; keep labels localizable.
- Add tests for map navigation, tap targets, unlock states and animation lifecycle where the architecture allows.

## Acceptance criteria

- [ ] AI Tutor greeting and speaker labels are fixed and regression-tested before village redesign starts.
- [ ] The village is visibly larger and has multiple connected districts, not just a reskinned single panel.
- [ ] The camera/layout reads as 2.5D/isometric through consistent perspective, depth layers and shadows.
- [ ] Multiple NPCs visibly animate; at least idle and walking behavior are demonstrated with approved assets.
- [ ] Characters move only on valid paths and remain correctly layered against scenery.
- [ ] Important destinations navigate to real app flows; no fake or dead-end controls.
- [ ] UI labels remain legible and tappable on small Android screens.
- [ ] Animation and asset memory use are bounded; no runaway timers or background animation churn.
- [ ] Every shipped asset has a recorded source and verified license.
- [ ] A before/after screenshot set and test summary are attached to the implementation report.

## Suggested order of work

1. Fix and verify AI Tutor bug; add a regression test.
2. Audit current village implementation and capture baseline screenshots.
3. Select one consistent 2.5D style and inspect candidate assets before coding.
4. Prototype one small area with one animated NPC and verify performance on a low-end device.
5. Expand the map/districts, wire only real destinations, then add remaining NPCs and ambient motion.
6. Run regression tests for Tutor, lessons, Arena, purchases and navigation; compare APK size and frame performance.
