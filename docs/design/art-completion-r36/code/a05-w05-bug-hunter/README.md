# a05-w05-bug-hunter · Bitsy's Workshop

**Batch A · concept + screen study only.**

- [Open localized layout](layout.html) · [Full-size art](concept.png) · [Exact generation prompt](prompt.txt)
- States: `locked, ready, wrong_error`. The page offers VI/EN and 1×/1.3×/2× text fixture controls; its primary CTA is disabled.
- Reference choice: see [`manifest.json`](manifest.json) for exact active paths and SHA-256; scene-specific rationale is included there and in [`../reviewed-inputs.json`](../reviewed-inputs.json).
- Sources: app/lib/modules/bug_hunter/bug_hunter_module.dart, app/lib/modules/bug_hunter/bug_models.dart, app/assets/data/bug_hunter_puzzles.json, app/lib/shared/characters/characters.dart, app/lib/shared/characters/cast.dart.
- Runtime/production readiness: **false**. No live data, gameplay, persistence, account, network, grant, purchase or inference is implemented.

The PNG is one opaque concept scene, not a layered/sprite pack. It must not be treated as calibrated geometry or proof of a shipped feature.
