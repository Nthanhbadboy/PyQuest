# R1-A — Làng 2,5D: scene + sáu lối vào thật

2026-10-18 · DESIGN r53 · CODE base `6dc8ca8feeed54cc0fa6a82109e3a59d24a16153`.
Runtime authorization duy nhất: [PQC-020 revision1](../../implementation/coordination/tasks/PQC-020.md).
Đây là lát cắt đầu của R1, không hoàn tất R1/toàn app/nhà–đất–đảo.

## 1. Quyết định sản phẩm

Sau khi011 được nhận, ưu tiên đưa thay đổi nhìn thấy vào **MainMapScreen** thay vì
mở thêm vòng Tutor. Sáu module đã có vẫn là hoạt động thật. Chọn địa điểm → existing
ActivitySheet → existing activity → quay về làng; không thay gameplay/save/economy.

**Ngoại lệ art có giới hạn, do Lead chốt:** cho phép W01 flattened static scene
trong R1-A. Đây không phải đổi nhãn concept thành layered runtime pack: NPC, nhà,
đường và bóng vẫn bake trong ảnh; không có navigation mesh/occlusion/actor atlas.
Không dùng ảnh này để nhận R2/R3/R4 hoặc hứa một thế giới NPC tự hoạt động. Giữ
mục tiêu layer/actor/world interaction ở các gói kế tiếp, không lén loại khỏi app.

Chọn lại ảnh/làm lại018 không cần thiết: dùng đúng W01 user đã chọn. WebP quality88,
không upscale, 853×1844, 349864 bytes, decoded RGBA lý thuyết6291728 bytes. Con số
này không phải đo peak RAM/GPU. Hash nằm trong manifest. SourceJPEG giữ nguyên.

## 2. Bố cục và tọa độ

- Header ngoài scroll: PyQuest/đảo, Nhiệm vụ, Settings, EnergyPill hiện hữu. Tên và
  tooltip mới VI/EN; hit target tối thiểu48logicalpx. Không mất năng lượng/Settings
  ở chữ2×. Header được xuống dòng, không ép một hàng hay giảm cỡ chữ hệ thống.
- Toggle Cảnh làng/Địa điểm; một scroll owner cho nội dung. Map rộng bằng viewport,
  giữ aspect853/1844, **cuộn dọc**, không BoxFit.cover crop và không zoom/drag-only.
- Một đề xuất đặt trên khoảng trời trên cùng; không thêm một card làm mất chiều cao
  scene. Khi loading/không có status hợp lệ thì không có CTA đề xuất.
- Sáu marker là nút thật (không invisible gesture rectangles trải toàn cảnh), theo
  `manifest.layout.markers`. Width0.32×scene width, min-height48; text wrap tự nhiên.
  Bounds art chỉ là vùng minh họa để kiểm khớp landmark, **không phải collision/hitbox**.
- Label center theo normalized full asset: MainQuest(.48,.29), Maze(.23,.445),
  Dragon(.82,.33), Stars(.80,.515), Bitsy(.22,.64), Achievements(.80,.68).
- Nhãn VI/EN ở `model.mjs` là copy thiết kế; CODE đưa vào ARB `hub*` và dùng generated
  localization hiện có. Không parse text tiếng Việt hoặc dịch bằng substring.
- Text scale>=1.5 mặc định và chỉ dùng directory trong lát cắt này. Sáu nút đầy đủ,
  không ellipsis/FittedBox; cùng routes/locks/order. Header/energy vẫn truy cập được.
  Đó là lối accessible thay thế, không phải sáu thumbnail thay thế thiết kế làng.
- Ở scale1/1.3, người dùng có thể tự chọn directory. Tab order theo registry,
  không theo tọa độ hình; landmark offscreen phải cuộn tới khi nhận focus.
- Không render nút nhà, bến, Friends/Arena khi chưa có implementation tương ứng.
  Phần nhà/bến trong art chỉ là cảnh, không nhận tap/semantics button hoặc khóa trả phí.

## 3. Ownership, status và luồng thật

Nguồn `activityRegistry` giữ nguyên: main_quest, robot_maze, dragon_jump,
catch_stars, bug_hunter, achievement_house. Không đổi ActivityDef của sáu module
để khớp artwork mới; geometry mới thuộc MainMap presentation.

| Việc | Authority và quy tắc |
|---|---|
| Status | Gọi module.status(services), không hardcode fixture vào runtime |
| Loading | Chưa biết khóa/tiến độ ≠ unlocked; giữ tên địa điểm, không mở như default empty status |
| Error | Lỗi một địa điểm không phá năm địa điểm khác; Retry chỉ tải lại status, không emit activityOpened |
| Async | Generation token; response cũ/sau dispose không ghi đè state mới; không unhandled future |
| Recommendation | Chỉ ready + unlocked + recommended, đầu tiên theo registry; fallback Python nếu ready+unlocked |
| Fallback copy | “Ghé Tháp Python” / “Visit Python Tower”; không tự hứa next lesson/resume nếu không đọc dữ liệu lesson |
| Tap marker | Existing ActivitySheet với status thật; không emit visit chỉ vì xem sheet |
| Locked | Hiển thị sheet với lock thật; dùng unlockLessonId nguồn qua existing lesson:<id>; không mở thẳng game khóa |
| Enter | Giữ openActivity và event/navigation ownership; không tạo sự kiện/grant mới |
| Double tap | Chỉ một sheet/route đang mở; không emit trùng do tap nhanh |
| Cancel/back | Không ghi tiến độ/energy/reward; về marker và vị trí scroll trước mở (0.5px ở geometry không đổi) |
| Return from activity | Refresh status thật, bỏ kết quả refresh cũ; giữ scroll/mode, focus về nút mở nếu còn mounted |
| Locale | Dùng AppLocalizations/resolved locale hiện có; không lưu language preference mới |
| Calm | Không mở animation controller lặp chỉ để vẽ ảnh tĩnh; không pulse/floating label trong R1-A |

**Preservation phụ thuộc geometry:** offset±0.5 cho cùng viewport/mode/text scale.
Nếu font/orientation làm viewport đổi, clamp offset hợp lệ và bảo đảm selected place
còn reach được; không ép pixel invariant sai như bài học011. Locale không reset mode
hoặc route. Map/list có scroll position riêng trong memory; không thêm DB schema.

Một module.status có progressLabel/detailLines tiếng Việt không làm nó thành EN.
R1-A chỉ hiện tên + ready/locked/loading/retry từ localization mới, không parse hoặc
bịa tiến độ. ActivitySheet/game/Welcome hiện hữu được giữ nguyên: **chưa redesign hoặc
localize trọn app**. Điều này phải có trong handoff, không lấy ảnh hubEN làm claim
mọi route đãEN. Fixture12/20 trong study không được dùng làm giá trị production.

## 4. Prototype và bằng chứng

`index.html` mô phỏng callback/return/focus/scroll bằng dialog; không chạy Flutter,
không ghiSQLite, không phát event/reward, không xác minh lock production. Model
ReadGeneration là minh họa invariant, CODE cần Dart tests trên implementation thật.

Matrix:360×640/390×844 ×VI/EN ×1/1.3/2 ×fresh/returning/complete/loading/error.
Test browser kiểm font computed, bounds, min48, overlap giữa markers, toàn bộ sáu
route mẫu, locked→prerequisite, Enter/Escape và focus/scroll return. Không suy browser
PASS thành render/device acceptance. Runtime cần screenshot Flutter cùng matrix
đại diện, ảnh before tại6dc8ca8 và gates của020. Header safe-area/IME/semantics Flutter
không được chứng minh bởi HTML.

## 5. Phần không làm trong gói này

Không sửa Tutor/board/editor, MainQuest lesson flow, Settings semantics, existing CI, SDK/deps,
DB/progress/events, scoring/energy/awards, thumbnails sáu activity, AI/voice hoặc
key policy. Không bỏ tests011 để đưa map vào. Một focused workflow020 mới được phép theo allowlist, không đổiCI cũ. Không tự mởR4 hoặc xây skin cho toàn
bộ game trong patch này. R1-B sẽ tiếp ActivitySheet/Welcome và chọn bài theo art
đã chuẩn bị; scene layers/NPC cùng các lane nhà/đất/đảo vẫn cần work order riêng.
