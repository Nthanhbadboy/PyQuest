# W13 — Tutor Room

**Artifact level:** concept scene + design-only HTML screen/state composition. **Review pending; not production-approved or runtime-ready.** `design_only: true` · `runtime_ready: false`.

**Pinned provenance:** DESIGN SHA `ae7289f376d70ab9f73b37346d25edaf727abc12`; source SHA `a331ac110f19de63e9be6884d08db8c436054f50` (PQC-011 remains `SUBMITTED_UNVERIFIED`). `concept.png` is PNG 704×1472, SHA-256 `611acdf2acd18110c30984f797da6a091bcac57adc99a119c28a06adcdd75d84`. Prompt: [`prompt.txt`](prompt.txt), SHA-256 `54ac2110d45dd8998f9dfd875a419a54fc29807fa0b1a07414d9bfd636f419f8`. Reference: [`../references/w01-village.jpg`](../references/w01-village.jpg), SHA-256 `2b33ad2a3eb826e6068241dc801f94e1794139ebda9c44f55c4380169e5ebd99`, copied from `docs/design/art-refresh-r33/concepts/w01-village.jpg` at the DESIGN SHA. Tool: Arena built-in image generator; model/version not exposed. Project-owned reference only; no CC0/exclusivity/stock-license claim, and generator terms/release rights remain unreviewed. Source file pins: `app/assets/data/main_quest_ch1.json` blob `70e155fbb7228d2b27ea4eb08ff13ddd2d2d931a`, SHA-256 `bead251d9f290db0b8fa4475f7413976324b00e7b0f498c633a25a5e6392f8b8`; `app/lib/shared/characters/cast.dart` blob `a9258bbea435464ea987a38a7584659c1d5d4b8b`, SHA-256 `b8115b14be89858802199ff8b824e4ce72c92c7ffd2948a7abbd7bdd87e53c0c`; `characters.dart` blob `d1659c3406b11c641b70fed158c6d03c97704831`, SHA-256 `09ce8c0e00a61133dac64c72704c7896f07c0002b65b96cf5bb343cd35bcfc6b`; `cast_painters.dart` blob `8d262521c39f14666f53aca35db01655d49ce790`, SHA-256 `9764e6433498d45080a98eefc7ebeb635f0b37971fbad2b752c0a90785448898` (all at source SHA above).

## Scene and composition

`concept.png` is a separate vertical cutaway classroom: pale stone, walnut framing, teal water/sky, front-facing blank teaching board, small slate/table, open path and a human-scale Nova pointing at the board. The character visual cues (brown ponytail, goggles on forehead, teal outfit, tool belt) are sourced from `CharacterId.nova` / `NovaPainter` in the pinned source, not a replacement mascot. The generated board is blank; all code and output text is real overlay HTML.

The preview is [`layout.html`](layout.html). Select both viewport sizes, VI/EN, primary/error state and 1×/2× text. It shows:

- Primary: authored `mq1_01_s2` code `print("Xin chào!")` and requested display output `Xin chào!`.
- A visible **sample output / runtime not verified** label. In source a331, this `example` step has no `expected_output`; the output is a design brief requirement, not proof that the source ran it.
- Nova's authored identity; no fake listening/speaking/voice indicator.
- Read-only authored sample, not a claim that learner freehand or editable input works. Mock actions are disabled.
- Code-error overlay as a design study, not a verified interpreter error message.

## VI / EN copy and states

All display strings are in `layout.html`. The code and output literals are not localized.

| State | VI | EN | Truth boundary |
|---|---|---|---|
| Primary | Phòng học cùng Tutor; Bài 1 · mq1_01_s2; Xin chào, Python!; Code mẫu · chỉ đọc trong concept; Kết quả mẫu · chưa xác minh runtime; Chạy ví dụ · mock | Tutor classroom; Lesson 1 · mq1_01_s2; Hello, Python!; Authored code · read-only concept; Sample output · runtime not verified; Run sample · mock | No result is claimed from live execution. |
| Error | Trạng thái lỗi · minh họa thiết kế; Chưa có kết quả; Kiểm tra dấu ngoặc kép và dấu ngoặc đóng. | Error state · design study; No output yet; Check the quotation mark and closing parenthesis. | Copy/invalid line are illustrative, not a real runtime message. |
| Character | Nova · Bạn đồng hành tò mò, thích sáng chế. | Nova · curious inventor companion. | Identity/role from pinned CastRegistry; no voice state. |

## Crop, safe areas and occlusion

Source scene: 704×1472 (0.478:1). `cover` preserves proportions. At 390×844, the near-matching ratio crops only a slim amount at the sides; at 360×640, the wider viewport crops roughly 28 source-display px from the top and bottom. Header and panel are overlay layers, never baked into the scene. The UI reserves 18px top and 14px bottom padding plus a 48px back target; the lower panel intentionally covers the front table/floor, not the board/Nova focal area. At 2×, content can scroll and cover more scene rather than clipping text. Exact safe-area insets and device occlusion were not measured.

## Review gaps

Illustrative camera only; compare interior axis, Nova silhouette and material/light against W01 before approving. No board-to-runtime anchor, foreground mask, alpha, animation, source-layer export or app navigation is supplied. Contrast and hardware behavior are unmeasured. See the package manifest for prompt/reference hashes, tool provenance, source pins and image hash.
