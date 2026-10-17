# W11 — Practice Arena

**Artifact level:** concept scene + design-only HTML screen/state composition. **Review pending; not production-approved or runtime-ready.** `design_only: true` · `runtime_ready: false`.

**Pinned provenance:** DESIGN SHA `ae7289f376d70ab9f73b37346d25edaf727abc12`; source SHA `a331ac110f19de63e9be6884d08db8c436054f50` (PQC-011 remains `SUBMITTED_UNVERIFIED`). `concept.png` is PNG 1440×2912, SHA-256 `2b9932f9d6f69c9bb8bd9f3591099fc77d06e1338f41f0a75be0fc4a8bd15d72`. Prompt: [`prompt.txt`](prompt.txt), SHA-256 `c0d57a723aeb1f0c5293f4e0f05fc5cb874e5c48c301177f63b572c6d71fd992`. Reference: [`../references/w01-village.jpg`](../references/w01-village.jpg), SHA-256 `2b33ad2a3eb826e6068241dc801f94e1794139ebda9c44f55c4380169e5ebd99`, from the pinned DESIGN commit. Tool: Arena built-in image generator; model/version not exposed. Project-owned reference only; rights/terms remain unreviewed, with no CC0/exclusivity/stock-license claim. Source identity pin at a331: `app/lib/shared/characters/characters.dart` blob `d1659c3406b11c641b70fed158c6d03c97704831`, SHA-256 `09ce8c0e00a61133dac64c72704c7896f07c0002b65b96cf5bb343cd35bcfc6b`. Design rule pins at ae728: `docs/GAME_DESIGN.md` blob `2df52e69d31fe94b9bf5ccea32b84a62a2644d44`, SHA-256 `c44e8d361637e23bb3c82ca8d16c547628a54fe4b8288691afd125c8e797da61`; `docs/PRODUCT_VISION.md` blob `175fe891a64799d9c4629f44594cdeb2ea89ceda`, SHA-256 `553d0234810e57653abd016224f51171dac337ef93cf6f792b13541d306653c7`.

## Scene and truthful scope

`concept.png` is an independent raised 2.5D practice courtyard with a square Maze-like floor field, low blocks, an adjacent open actor area, a blank rules board and an exit arch. Robo is the only character, used as the source-backed fictional practice host; there is no depicted opponent or crowd. Scene props contain no scores, rewards, rank, team/tournament marks or online indicators.

The pinned a331 source has no Arena module or rule registry. `GAME_DESIGN.md` and `PRODUCT_VISION.md` describe Arena as a future/design domain and require training opponents to be clearly fictional, but they do not authorize inventing a playable route or score rule here. Therefore `Xem luật` / `Luyện tập` appear as disabled design-entry mock controls; Rules state explains that the Maze-specific controls/scoring are not sourced; Unavailable state says no Arena route, team, tournament, rank, result or reward exists in this source pin. No feature is represented as live.

## VI / EN states

| State | VI | EN | Truth boundary |
|---|---|---|---|
| Entry | Đấu trường luyện tập; Xem luật · mock; Luyện tập · mock | Practice Arena; View rules · mock; Practice · mock | Target composition only; both controls disabled. |
| Rules | Xem luật luyện tập; luật điều khiển/chấm điểm chưa có trong pinned source | Practice rules; concrete controls/scoring absent from pinned source | No score, win/loss condition or reward invented. |
| Unavailable | Nội dung luyện tập chưa khả dụng; no online opponent, rank, team or tournament | Practice content unavailable; no online opponent, rank, team or tournament | Honest unavailable state, not a “coming soon” menu. |

The preview supports both phone sizes, VI/EN and 1×/2×. Back and action controls are mock/disabled.

## Crop, safe areas and occlusion

Source scene: 1440×2912 (0.495:1). At 390×844, proportional `cover` crops roughly 48 source px from each side; at 360×640, the wider viewport crops about 22 displayed px at each vertical edge (about 88 source px at each edge). The scene has clear top/bottom water/sky margins to tolerate this crop, but the exact marker/board coverage needs visual review. The bottom sheet overlays the near edge of the floor; control targets are at least 48 CSS logical px. At 2× the overlay can scroll and obscure more floor without clipping copy. Device safe-area insets and occlusion were not measured.

## Review gaps

Camera, actor scale, tile geometry and the source Maze gameplay relationship are illustrative, not collision/navigation evidence. Arena runtime and rules remain absent in the pinned source. No alpha layers, pivots, occlusion masks, scoring or interaction payloads are delivered. Contrast and device review are unmeasured.
