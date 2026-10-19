# PQC-018 — Hoàn thiện phần concept còn thiếu từ bộ ảnh chung r35

- revision: 3 · 2026-10-18
- status: **IN_PROGRESS — 9 CONCEPTS REVIEWED; TWO SCREEN CORRECTIONS**; art/design-only
- owner: CODE; DESIGN review/canonical catalog
- authorization: user yêu cầu review017, đồng bộ ảnh và giao các ảnh còn lại cho CODE
- design_source: **`3c29fc3ad5cd2f7691e22dc7a119ed5de3d147f2`** (review PQD-003 r38 + task revision3)
- previous_design_pin: `68f2590b5883ca8aa746ffde0814d60a32dacb3c`
- received_art_pin: `0990fbcbf6045bd64244239e36ccbca8c8dc394b` (B + A correction `ab0ae35eafebf8602ef714d85004ad4b744898a4`)
- runtime_identity_pin: `a331ac110f19de63e9be6884d08db8c436054f50` (runtime trong e3 không đổi)
- runtime/app_tests/dependencies/CI/SDK/economy: **no**
- design_art/layout_checks/coordination: **yes**, chỉ allowlist §5
- runtime_ready: **false**, production approval: **not granted**

## 0. Revision3 — giữ9ảnh, chỉ sửa hai điểm còn thiếu

[Review r38](../../../design/coordination/reviews/PQD-003-r38.md) thay disposition r36.
Đã nhận correction A và toàn bộ B. **Không còn B pending delivery.** Cả9concept giữ
lại; không sinh lại PNG, không lặp intake16ảnh. Sáu screen studies được giữ ở mức
REVIEWED_WITH_LIMITS; A01/A03 còn lỗi sharedbar, B02 còn thiếu editor.

**Một substantive correction commit `[skip ci]`:**
1. **R38-A:** shared `.product-bar` không để badge ép title thành cột chữ. A01
   not_following/360/EN2× rộng32.75px; A03 first_visit/390/EN2× rộng10.20px, /360
   rộng0px. Cho wrap/stack, giữ title đọc được và pill trong bounds; không nhỏ chữ/
   clip/hide/truncate để pass. Check cả inner text và zero-width, không chỉ root overflow.
2. **R38-B:** B02 thêm editor read-only/mock **có nội dung đọc được**, khác preview
   và version tray. Hiện chỉ nhãnEditor +3ô trống, không editor. Code/block sequence
   là design fixture có provenance, không game API/lesson oracle/grader tự bịa;
   nếu Python thì literal giữ nguyênVI/EN. Không interpreter, không persist/publish.

Giữ cả9PNG/originals/hashes. R36 root-font/back-grid/source-copy fixes đã xác minh,
không làm lại. Chạy regression toànA240+B192 sau sharedCSS, thêm editor visible
content +computed fonts trong48case B02. Report đúng thực chạy, captures lỗi cũ và
editor mới. Sửa task stale67/67 thành actual final count cùng substantive correction.

Allowlist§5 không đổi: package018+own task. Không copy snapshot review DESIGN vào
CODE; đó là archive0990fbc, không bản sửa. Không chạm W08r37/PQD004, canonicalr35/r36,
app/CI/deps/backend/economy. Không ACK-only, không tựpopstash.011 correction vẫn riêng.
Gửi exactSHA để DESIGN review hai gates, không selfaccept hoặc tự port sang app.

Các bảng§1–§3 là brief gốc/ranh giới, **không giao lại việc đã làm**. Production
framing/geometry/layer/final-copy backlog không phải một đợt vẽ lại trong correction này.

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


## CODE progress — R38-A/B correction submission (not acceptance)

CODE preserved the exact pre-R38 source bytes and SHA-256 values from `0990fbcbf6045bd64244239e36ccbca8c8dc394b` in `docs/design/art-completion-r36/code/evidence/r38-originals/`; the archive includes all nine PNG hashes and unchanged-in-place status. All nine concept PNGs remain byte-for-byte unchanged.

- **R38-A:** `shared.css` now stacks/wraps the full-size product title and pill rather than allowing the pill to compress the title. It does not hide, clip, truncate, or shrink the title. The browser test checks rendered inner text fragments, nonzero dimensions, clipping/scroll dimensions, title font size, and pill bounds in each product-screen case, including A01 `not_following/360/EN/2×` and A03 `first_visit/390/EN/2×` and `/360/EN/2×`.
- **R38-B:** B02 now has a focusable, read-only editor sample that is visually separate from preview and version tray. The three VI/EN lines are fictional prose authored by CODE for this study, attributed in the product surface, manifest, and reviewer notes. They are not game API/code/canon, lesson answers, or graders. No interpreter, persistence, or publishing was added; primary CTA remains disabled.
- **Regression results:** Chromium 153, A **240/240** and B **192/192**; **432/432 total** configurations. A had **1,499** computed-font assertions and B **1,296** including **144** editor-font assertions across all **48 B02 combinations**. B02 content was visible in **48/48**. Product-title inner-text and pill-bound checks passed in **432** cases; zero horizontal overflow, header overlap, browser errors, or failed requests. All CTAs remained disabled; captures: A **19**, B **20**. Current machine-readable receipts: `code/evidence/r38a-browser-checks.json`, `code/evidence/r38-batch-b-browser-checks.json`, and `code/evidence/r38-static-checks.json`. These are static browser fixtures, not app/runtime or production validation.
- Final pre-R38 Batch B static receipt remains **79/79 PASS** in `code/evidence/batch-b-static-checks.json`; task text that said 67/67 was stale and is corrected here. The new R38 static/provenance receipt is **129/129 PASS** in `code/evidence/r38-static-checks.json`. Historical R36 and pre-R38 receipts remain intact.

Nine manifests, `reviewed-inputs.json`, the B02 README, package README/index, and evidence references now identify review pin `3c29fc3ad5cd2f7691e22dc7a119ed5de3d147f2` and the actual R38 receipts. One substantive `[skip ci]` correction commit will be sent to CODE for DESIGN review; **PQC-018 remains IN_PROGRESS and is not self-accepted**. No PNGs were regenerated. PQC-011 remains separate and CHANGES_REQUESTED.
