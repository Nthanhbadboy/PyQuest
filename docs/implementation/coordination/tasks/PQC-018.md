# PQC-018 — Hoàn thiện phần concept còn thiếu từ bộ ảnh chung r35

- revision: 2 · 2026-10-18
- status: **IN_PROGRESS — A correction and B concepts delivered; DESIGN re-review pending for both**; art/design-only
- owner: CODE; DESIGN review/canonical catalog
- authorization: user yêu cầu review017, đồng bộ ảnh và giao các ảnh còn lại cho CODE
- design_source: **`68f2590b5883ca8aa746ffde0814d60a32dacb3c`** (review PQD-003 r36 + task revision2)
- previous_design_pin: `cbb0f8bed808a888ae607bb31ba6343c182bf0b8`
- received_art_pin: `1053973da1ad11378f7263d7b13a4d61667133af` (Batch A; 017 giữ e3ec5f1)
- runtime_identity_pin: `a331ac110f19de63e9be6884d08db8c436054f50` (runtime trong e3 không đổi)
- runtime/app_tests/dependencies/CI/SDK/economy: **no**
- design_art/layout_checks/coordination: **yes**, chỉ allowlist §5
- runtime_ready: **false**, production approval: **not granted**

## 0. Revision2 — disposition và việc tiếp theo

[Review r36](../../../design/coordination/reviews/PQD-003-r36.md) là nguồn findings
mới nhất. Đã nhận Batch A5 từ exact1053973; giữ5PNG concept, **không sinh lại**.
54file imported nguyênbyte;16review records/path/hash đã kiểm. Intake16ảnh ở§1 đã
có record, không yêu cầu ACK-only hay làm lại toàn bộ; giữ lịch sử cbb, bổ sung pin
r36/finding mới khi correction. Source package lịch sử không phải bản đã accepted.

**Đã thực hiện theo hai commit substantive `[skip ci]` riêng:** Batch A correction commit `ab0ae35eafebf8602ef714d85004ad4b744898a4`; Batch B commit chứa bốn scene concept và fixture layouts. Cả hai batch vẫn chờ DESIGN review; không self-accept.
- **R36-A:** thực tăng typography1/1.3/2× (h1/h2/body/facts/code/output); sửa root-rem
  và header back48px không lấn heading. Independent240case:0overflow nhưng160scale
  failures và120header box overlaps. Assertion computed sizes, không chỉ selector.
- **R36-B:** source IDs/plumbing ra reviewer notes, copy cho trẻ VI/EN; Journal note
  phải đúng CTA-disabled, Catch Stars không “program”, VI manual_en title dịch đúng.
  Giữ gate/source Python literal/expected-output-vs-execution distinction.
- **R36-C:** composition scene-first bằng5ảnh sẵn có; tách review controls/notes khỏi
  product viewport, không năm hero+card giống nhau. Journal reading surface; Settings
  panel trong môi trường; Welcome scene+HUD; Catch Stars lane/jar không bị panel che;
  Bitsy board/code/output front-facing.2× cho đọc/scroll, không ép hết trênfirstfold.

Không thêm animation/layer/game loop/runtime để “làm sống” proof018. Đây là sửa
screen study theo brief gốc, không task Flutter mới. Giữ original bytes/hash trước
correction (archive dưới allowlist), update manifests/evidence thật. Có script test
reproducible trong `code/evidence/`; đủ240caseA, nooverflow/clip/overlap,48px,disabledCTA,
footer và computedfontchecks. Browser fails phải báo fail; chưa có engine thì UNVERIFIED.

BatchB giữ nguyên§2: friends/invites, Creator **có editor**, built-room từ **W03 tầng
trệt** (solidfloor/door/no cyan), **Miu cam** rest. Dùng grammar đã sửa cho B, đủstates.
Không sinh thêm ảnh ngoài9cảnh; không vẽ lại017 hay16ảnhcanonical. B không cần user
chọn lại; gửi substantive correctionSHA và BSHA để DESIGN review, không selfaccept.

Allowlist§5 **không đổi**.011 sửa riêng theoorder011/r34,018 không mở app/CI/deps;
stash không tựpop. Không copy snapshot CODE1053973 từDESIGN đè localCODE đang sửa.

## 1. BẮT BUỘC xem hết bộ ảnh đã đồng bộ, không chỉ đọc tài liệu

Trước khi sinh ảnh đầu tiên:

1. Fetch DESIGN, ghi SHA thật. Đọc `docs/design/art-sync-r35/README.md`,
   `catalog.json`, `STYLE_SYNC.md`, review `docs/design/coordination/reviews/PQD-003-r35.md`.
2. Mở **cả16 ảnh active** liệt kê trong `catalog.json` ở kích thước đủ lớn. Gallery
   `docs/design/art-sync-r35/index.html` có từng ảnh và nút mở đủ kích thước. Không
   chỉ xem thumbnail/contact sheet, không nói “đã xem tất cả” khi chỉ kiểm hash.
3. Xem bố cục/trạng thái r34 và cả3layout r35 đã đồng bộ. Đặc biệt W14 **dùng correction
   r35**, không dùng concept frontal/cúp bake của017 làm neo nội thất.
4. W01 là neo chính camera/material/light. W13 giúp hiểu Nova/đồ học; W11 giúp hiểu
   Robo teal/brass. W02/W03/W07/W08 có lỗi geometry/detail đã ghi, không sao chép lỗi.
   Không “trung bình”16style để tự đổi mỹ thuật. Nhân vật khác nhau không bị recolor
   thành cùng một robot. Ghép cảnh nhà phải phân biệt mẫu nghiên cứu với cùng một nhà.
5. Giữ bốn tài liệu gốc và ART_DIRECTION_2_5D/WORLD_EXPANSION làm nguồn luật. Đọc module/
   character source thích hợp để tránh biến mini-game thật thành một trò khác.

Ghi `reviewed-inputs.json` **cùng commit công việc thực chất**, không ACK-only:
DESIGN SHA, đủ16id/path/SHA256, `viewed_fullsize` đúng thực tế, một nhận xét ngắn mỗi
ảnh, nguồn layout đã xem; chọn ref cụ thể và giải thích vì sao cho từng ảnh mới.
Nếu không có image viewer/tool, báo thiếu khả năng thật; không đánh dấu đã xem.

## 2. Phạm vi:9 ảnh độc lập, chia A5 rồi B4

Mỗi ảnh một file riêng, không ghép grid/contact sheet để thay deliverable. Mỗi đợt
commit `[skip ci]` và bàn giao riêng. Không cần đợi user chọn roadmap; nếu công cụ
chạm giới hạn, báo phần đã có/còn thiếu và tiếp tục khi được gọi, không retry vượt limit.
Không hứa chạy nền sau khi phiên kết thúc.

### Đợt A —5 cảnh ưu tiên, bàn giao trước

| ID/path dưới code/ | Cảnh cần làm | Source/không được giả | State overlay tối thiểu |
|---|---|---|---|
| A01 `w04-journal/` | Bàn/sổ hành trình có khối, trang đọc front-facing, dự án đang theo khác daily và kết quả chờ nhận | WORLD W04; không tạo grant/receipt/giá mới | có dự án, chưa theo dự án, nhiều kết quả chờ, lỗi tải |
| A02 `shared-settings/` | Góc bảng điều khiển gỗ/đá cùng nhà; vùng chữ sạch, không form web với một ảnh hero | `app/lib/app/settings_sheet.dart`, locale014–016 và Settings ARB hiện hữu; system+override VI/EN đã có | System+active/fallback, manual VI/EN, save failure/retry; không claim quyền thiết bị đã bật |
| A03 `shared-welcome/` | Bến/cổng làng mở, hướng vào thế giới cùng W01; dùng lại silhouette tháp, không thêm spires | Ngôn ngữ mặc định hệ thống; không ép học Tutor/mua hàng trước khi vào hub | first visit, returning/resume fixture, loading/retry; không giả cloud account |
| A04 `w05-catch-stars/` | Đài Thiên Văn/Hái Sao: vùng rơi sao, bình hứng/thiên thạch có khối, camera phục vụ kéo bắt | `catch_stars_module.dart`, `stars_game.dart`; source host Robo; không đổi tốc độ/collision/score, không biến thành quiz | ready, pause, result fixture; panel không che đường rơi; night lighting có lý do nhưng cùng vật liệu |
| A05 `w05-bug-hunter/` | Xưởng Bitsy: bàn debug/code có khối, nơi tìm lỗi và thử cách sửa, không chỉ gallery côn trùng | `bug_hunter_module.dart`, `bug_models.dart`, dataset & Bitsy painter; giữ actual unlock gate, không bịa đáp án/code | source-locked, ready, wrong fix/error study; code/output tách UI, literals đúng source cả VI/EN |

### Đợt B —4 cảnh sau A, cùng standard/canonical refs

| ID/path | Cảnh cần làm | Ranh giới | State overlay tối thiểu |
|---|---|---|---|
| B01 `w09-friends-invites/` | Khu cộng đồng/bàn lời mời có không gian thật; danh sách bạn/người nhận rõ, không bưu đình thay toàn UI | Danh tính hư cấu có nhãn fixture; không giả online, backend, moderation đã hoạt động | empty friend list, invite pending/expired, host away, blocked/report confirmation; private access không lộ |
| B02 `w12-creator-editor/` | Xưởng với editor front-facing, vùng thử và version tray rõ; nối W12 đã có, không lại một ảnh bàn làm việc không có editor | Code/preview/phiên bản read-only hoặc mock; không suy persisted/published khi chỉ vẽ | draft+unsaved, test error, saved-private, moderation pending; không grader/economy mới |
| B03 `w07-built-room/` | Phòng hoàn tất có thể dùng: sàn solid, cửa/nối phòng thật, workbench; lấy W03 ground-floor project làm ví dụ trước/sau | Không sao chép floating previewW02; W02 nghiên cứu nhà2tầng không phải cùng blueprint W03. Giữ wood/ivory/teal; không bake cost | completed/enter, use workbench, arrangement blocked; ảnh hoàn tất **không còn ghost cyan** |
| B04 `w10-pet-rest/` | **Cùng Miu mèo cam W10** nằm nghỉ ở góc pergola hiện có; đúng màu lông/tỷ lệ, không đổi sang mèo xám shop | Một pose/cảnh nghỉ mới; không montage poses, không claim animation hoặc AI | rest, device AI unsupported, model removed nhưng baseline còn; không pet buồn đòi mua |

Không mở thêm9màn Flutter. Các bảng trên là design brief, không quyền thay rules.
Các geometry/actor corrections còn lại của16ảnh hiện có ghi backlog trongSTYLE_SYNC,
DESIGN quản lý riêng; không tự ghi đè master để “sửa cho đồng bộ” ngoài scope9ảnh này.

## 3. Cách giao để không lặp lỗi017

Mỗi thư mục: `concept.png/jpg`, `layout.html` (+shared CSS/JS nếu cần), README,
manifest và prompt gốc. Mỗi ảnh cần source reference paths/hashes + DESIGN SHA thật;
source code chỉ map identity/rules. Nếu correction: giữ original bytes/hash **trước**
khi ghi bản mới; không lặp khoảng trống provenanceW14 cũ.

Phone390×844/360×640, VI/EN,1×/2×. Có thể tái dùng grammar của r35layouts hoặc r34,
nhưng không copy tên/title/state sai màn. Chữ2 phải wrap, flexchild min-width0;
header badge không white-space:nowrap gây scroll ngang. Một vertical scroll owner.
Nguồn code/output phải front-facing; không bake text/giá/quyền vào generated scene.
Empty state thật khác taxonomy mẫu; trophies/owned items không bake vào nềnempty.
Không để debug lesson IDs nổi trong UI trẻ. Controls là disabledmock hoặc chuyển
fixture có nhãn, không giả app; chọn rõ một cơ chế và ghi thật.

Browser nếu có: kiểm từng state ×2viewport ×2locale ×2scale, overflow ngang, cuộn tới
footer, chữ thực tăng, controls >=48px; lưu captures và actual report. Có thể dùng
`tools/design/review_art_r35.cjs` làm tham khảo logic, không chạy rồi báo nó đã kiểm
các file018 mới khi chưa chỉnh target. Tooling install chỉ scratch, không appdeps.
Nếu không có browser: static checks + ghi BROWSER_UNVERIFIED, không tự ghi PASS.
Không cần Flutter/CI/APK cho art. Không benchmark runtime hoặc network trong task.

## 4. Acceptance/gate

- Đủ ảnh/bố cục/state/source của mỗi đợt; xem fullsize, không vài SVG phẳng thay cảnh.
- Có `reviewed-inputs.json` đủ16ảnh thật, đã xem correctionW14 và biết W01 là neo.
- Camera/material/door/actor source nhất quán; không ép Dragon side-view thànhiso.
- Không bakedtext/giá/claim; không bịa online/AI/refund/earned state.
- Hash trước/sau correction, manifests/runtime_ready:false; biết concept≠production.
- Source/HTMLchecks báo thực chạy; không claim browserpass nếu không có engine.
- Dừng báo blocker cụ thể nếu thiếu nguồn/tool; không sửa runtime để “khớp tranh”.

## 5. Allowlist chính xác

Chỉ ghi:
- `docs/design/art-completion-r36/code/**` (9nhóm trên, shared design CSS/JS,
  manifests/prompts/readme/reviewed-inputs/evidence vừa đủ; không caches/modelweights)
- `docs/implementation/coordination/tasks/PQC-018.md` (status/handoff)

Được đọc tất cả refs cần thiết từ SHA DESIGN pin. Không merge/cherry-pick cả nhánh
DESIGN; không ghi r33/code package gốc, r34, r35canonical, ART_DIRECTION, app/**,
pubspec/lock/deps/SDK, CI/CircleCI/APK, giá/recipe/engine/backend/LLM.
Giữ nhánh phiên CODE đang được phép, bảo vệ stash/thay đổi có sẵn, không tự popstash.
Không ACK-only commit. Push nhánh CODE của phiên; trả DESIGN exactSHA + ảnh + checks.

## 6. Thông tin mới thay bản chưa chuyển

PQC-017 đã review/nhập chung qua r35, không yêu cầu vẽ lại cả ba. W14 correction và
layout fixes doDESIGN giao; dùng bản canonical r35. Không port vào runtime.

**PQC-011 vẫn CHANGES_REQUESTED theo reviewr34**; user chưa chuyển bản tinr34 nên
handoff017 ghiSUBMITTED_UNVERIFIED là lịch sử, không phủ quyết review mới. Khi sửa011,
dùng allowlist011 và commit runtime riêng;018 không mở app changes. CI117462432865
exacta331 đã fail analyze8issues, suites skipped; không tự accept vì có artwork.


## CODE progress — Batch A correction (not acceptance)

CODE fetched/pinned DESIGN `68f2590b5883ca8aa746ffde0814d60a32dacb3c`, read the r36 review, this revision2 task, and art-review README. The sixteen-image intake record remains linked to its exact r35 catalog; no intake ACK-only work was added.

The five concept PNGs are byte-for-byte unchanged from CODE `1053973da1ad11378f7263d7b13a4d61667133af`. CODE retained their original SHA-256 values, archived the pre-correction layouts/shared files/manifests/notes/evidence, and revised the five responsive screen studies for R36-A/B/C. The screen disposition remains **SCREEN_CHANGES_REQUESTED pending DESIGN re-review**. Batch B has now been delivered in its own substantive commit, also pending DESIGN review.

R36-A: root-rem scaling now changes computed root and descendant text sizes; the back control occupies a real 48px grid track. Browser assertions test actual computed pixels and title/back bounding boxes. R36-B: reviewer-only source IDs and plumbing are outside product view; Journal load-error CTA note, Catch Stars paused wording, and VI manual-English title are corrected. A05 source gate, exact Python literals, and expected-output/not-executed distinction remain visible in reviewer evidence. R36-C: the five product viewports have distinct scene-specific compositions; reviewer controls and notes are outside each product viewport.

Correction evidence: final dependency-free static/provenance count is **90/90** in `code/evidence/r36a-static-checks.json`. Chromium 153 run: 240/240 fixture combinations, 1,259 computed-font assertions, 0 horizontal overflow, 0 header overlaps, 2,160 target-size checks >=48×48 CSS px, 240 disabled CTA checks, 240 reviewer/product separation checks, no page errors or failed requests; 16 representative captures. Evidence and the reproducible browser script are under `code/evidence/`. This is static design-fixture evidence only, not Flutter/device/app/runtime or production validation.

Batch A correction substantive commit `[skip ci]`: `ab0ae35eafebf8602ef714d85004ad4b744898a4`. DESIGN re-review is requested, not self-accepted.

## CODE progress — Batch B (not acceptance)

Four separate concept images and matching localized state studies were delivered in a second substantive `[skip ci]` commit, separate from the Batch A correction:

- B01 `b01-w09-friends-invites/concept.png` — 928×1152, 2,721,961 bytes, SHA-256 `769336b24efdbc7561427030fa636e8301a3eee15431d1882554ec069f6b0ece`; empty list, invite pending/expired, host away, blocked, report confirmation.
- B02 `b02-w12-creator-editor/concept.png` — 928×1152, 2,370,490 bytes, SHA-256 `d37ff8e6e729400df919a0e7b94abb7800f2754ed481facea53eecc78955442e`; editor, preview and version tray; unsaved draft, test error, saved-private, moderation pending.
- B03 `b03-w07-built-room/concept.png` — 928×1152, 2,108,457 bytes, SHA-256 `88f1e9c4ec20c070a35a00f0430b61837ce13a49f8fd2f3b430ef8ee4df3b63d`; W03 ground-floor context, solid floor, connected ground-level door and workbench; no cyan ghost.
- B04 `b04-w10-pet-rest/concept.png` — 848×1264, 2,684,317 bytes, SHA-256 `f0a7e8896ef8ba6298e79d4579f7c463bb7b57e109dcbcf24aa4e0e6c8a62317`; same orange Miu under the W10 pergola, one still pose, plus unsupported-AI and model-removed/baseline fixtures. W10b gray shop cat explicitly excluded.

Each image was opened and inspected full-size. Exact generation prompt hashes, design pin `68f2590b5883ca8aa746ffde0814d60a32dacb3c`, canonical reference paths/hashes, generation input IDs and limitations are in the four manifests and `code/reviewed-inputs.json`. No regeneration of the five A PNGs occurred.

Batch B checks: static/provenance **67/67 PASS**; Chromium 153 **192/192** cases over 16 states ×2 phone sizes ×VI/EN ×1×/1.3×/2×; 960 computed-font assertions, 1,728 controls >=48×48, 0 overflow/header overlaps, 192 disabled CTA checks, 192 reviewer/product separation checks, 192 footer reachability checks, zero page errors/request failures, all four images decoded, 20 captures. Machine-readable evidence and scripts are under `code/evidence/`. Headless static HTML only; no Flutter/device/app/runtime/backend, AI, moderation, economy, or production acceptance.

Both Batch A correction and Batch B are **awaiting DESIGN review**. PQC-018 remains **IN_PROGRESS**. PQC-011 remains CHANGES_REQUESTED under r34 and untouched; stash remains preserved.
