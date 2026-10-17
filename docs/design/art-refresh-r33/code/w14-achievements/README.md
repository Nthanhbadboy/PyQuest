# W14 — Achievement House interior

**Artifact level:** concept scene + design-only HTML screen/state composition. **Review pending; not production-approved or runtime-ready.** `design_only: true` · `runtime_ready: false`.

**Pinned provenance:** DESIGN SHA `ae7289f376d70ab9f73b37346d25edaf727abc12`; source SHA `a331ac110f19de63e9be6884d08db8c436054f50` (PQC-011 remains `SUBMITTED_UNVERIFIED`). `concept.png` is PNG 843×1264, final SHA-256 `fac243137dc25acd74f9688c876b8286e53d1c7b12acf6c1085e91c1236265f8`. Prompts: [`prompt-original.txt`](prompt-original.txt), SHA-256 `ca328ae40a1b71d5c8630c3887608ec819337cd407ec5c6564463c45852a155f`; [`prompt-restyle.txt`](prompt-restyle.txt), SHA-256 `3fa12a034ad5ab525b42224d09f64625cbe55dba52252c7a02bc4fb5c73b9b46`. Reference: [`../references/w01-village.jpg`](../references/w01-village.jpg), SHA-256 `2b33ad2a3eb826e6068241dc801f94e1794139ebda9c44f55c4380169e5ebd99`; restyle also used the selected generated image, whose pre-edit hash was not captured. Tool: Arena built-in image generator; model/version not exposed. No third-party reference; rights/terms remain unreviewed, with no CC0/exclusivity/stock-license claim. Source file pins at a331: `app/lib/modules/achievements/achievement_catalog.dart` blob `e6cf2f772f70aae7862b17c293a44a38569b8f0e`, SHA-256 `07d52e12d2552ddff0fb7786146184df421c8ad2267e57fbb1cb7c9ef6c67200`; `achievement_house_module.dart` blob `145c9c4d2435e586c96a03277e01991d14ad4523`, SHA-256 `49060c2d988d40047dbf7768fe5846071d8702053d4337c2589ef431cc0301b0`.

## Scene and source mapping

`concept.png` is a standalone dimensional interior with a deep walnut medal cabinet, empty recesses, freestanding stone plinths, a display ledge/niche and a walkable central floor. The generated generic discs/trophies are room fixtures only; no names, counts, badge conditions, player status or rewards are baked into the art.

The preview in [`layout.html`](layout.html) uses actual `first_line` definition text for one selected skill-badge detail: title `Dòng Code Đầu Tiên`, description `Viết dòng Python đầu tiên cùng Py.`, and how-to `Hoàn thành Bài 1 của Main Quest.` These strings map to `achievement_catalog.dart` at a331. English copy is a design translation. The detail explicitly says it is a fixture and does not claim anyone earned it.

An empty view displays a labelled state taxonomy for earned / locked / secret as sample fixtures, using shape plus text instead of color alone. Secret status has no revealed condition. Social reward is a category label with no item: no social-reward registry exists in the pinned a331 catalog. No XP/progress is invented. Mock detail/back controls are disabled.

## VI / EN study states

| State | Content | Boundary |
|---|---|---|
| Empty / fixture | “Trưng bày mẫu”, “Fixture · không có dữ liệu người chơi”, sample labels for Đã mở / Đang khóa / Bí mật, skill vs social categories | All status shapes are explicitly samples, never player data. |
| Detail | “Dòng Code Đầu Tiên” / “First Line”, source-mapped description and how-to, “Fixture · chưa gắn tiến trình” | Definition detail only; not a claim the badge is unlocked. |
| Secret | Generic “Bí mật · mẫu” and a question-mark fixture | No secret condition or specific hidden badge is disclosed. |
| Social | Empty category and “Không có registry xã hội tại a331” | No fabricated social item. |

Locale toggle translates all copy. Source-specific strings and translations are in the HTML. At 2×, the page may scroll; no fixed-height text clipping is intended.

## Crop, safe areas and occlusion

Source scene: 843×1264 (0.667:1), wider than a phone. The proportional `cover` crop at 390×844 trims approximately 129 source px from each horizontal edge; at 360×640 it trims approximately 66 source px per side. The left cabinet and right-hand plinths may be partially cropped, so the image must be reviewed in both exact viewports before selection. The content sheet intentionally overlays foreground floor/plinth bases; upper cabinet and display alcove remain the scene focus. Header/panel are independent HTML; no scene is stretched. Safe inset and device-specific occlusion were not measured.

## Art-family review gap

The image is detailed and dimensional, but after one restyle pass it still reads more frontal/perspective than W01's target 3/4 orthographic camera. Material direction is closer but not fully calibrated. Treat this as a reviewable exploration, not a pass; DESIGN should request a camera/material correction if a strict same-family match is required. No alpha layers, pivots, occlusion masks, hit bounds, animation or runtime geometry are supplied.
