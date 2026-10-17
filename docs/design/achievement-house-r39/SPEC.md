# W14 r39 — Tủ huy hiệu: thiết kế tương tác độc lập

Ngày: 2026-10-18 · owner DESIGN · task [PQD-005](../coordination/tasks/PQD-005.md).
**Design study, không phải màn Flutter đã triển khai, không production approval.**

## 1. Phạm vi và quan hệ với bản đồ mở rộng

W14 là nơi nhìn lại tiến bộ trong thế giới PyQuest, không phải shop hoặc bảng ép
luyện liên tục. Trọng tâm lần này là **phòng trưng bày → tủ → chi tiết → trở lại tủ**.
Khác r35 chỉ trình bày taxonomy, r39 có chọn huy hiệu, lọc, tìm, trạng thái đọc dữ
liệu và đường quay lại thật trong simulator.

Giữ nguyên W14/r35 làm nền 2,5D. Không vẽ lại ảnh đã đồng bộ, không đổi canonical,
không ghép nhân vật hoặc tự tạo vật phẩm xã hội. Nội dung achievement lấy từ source
có sẵn, không tự nghĩ thêm huy hiệu cho chương học chưa tồn tại.

Chỉ slice **badge cabinet**. Ba phần còn lại của `AchievementHouseScreen` — trophy
wall, collectible room, creation corner — chưa thiết kế lại ở đây. Điều kiện mở
phòng trong source giữ nguyên; không đưa điều kiện secret/night-play vào việc xây
nhà hoặc tiếp tục học. Danh hiệu/cạnh tranh/phần thưởng xã hội vẫn thuộc sản phẩm
mở rộng, nhưng **không có inventory xã hội giả** trong cabinet này.

Không sửa CODE's R38-A/B, PQC-018, PQC-011, prompt CODE, gallery r38 hoặc W08/r37.
Không phát hành work order runtime cho CODE trong delivery này.

## 2. Bố cục, hình ảnh và phân lớp

- Nền: ảnh opaque `../art-sync-r35/corrections/w14-achievements.jpg`, không đổi byte.
  Gỗ ấm, đá kem, ánh sáng mềm, thể tích isometric; giữ tủ bên trái, cửa bên phải và
  ba bục. Không gọi đây là geometry/runtime-ready scene.
- Lớp riêng trên ảnh: hotspot tủ và tối đa ba medal controls mẫu; background không
  chứa số đếm, text hay badge trạng thái mới. Tọa độ CSS normalized chỉ là bố cục
  thử nghiệm, **chưa phải anchor/camera calibration trong Flutter**.
- Medal: CSS đổ bóng + vành nổi, glyph hình học đơn giản. Đây là UI placeholder,
  **không phải bộ 15 icon artwork hoàn thiện**. Gold = earned; đá xanh xám = not-yet;
  dấu hỏi + nhãn = secret. Không phân biệt trạng thái chỉ bằng màu.
- Điện thoại: header → ownership count + sample label → room/cabinet navigation →
  scene hoặc nội dung → footer. Một scroller dọc. Không overlay sheet che cảnh khi
  đọc danh sách dài; chi tiết là một view riêng.
- Tủ hiển thị một cột thẻ, không ép bốn cột medal nhỏ. Bộ lọc hai cột, tên được xuống
  dòng. Header có cột back cố định và cột tiêu đề riêng; count không tranh chiều
  rộng với tiêu đề; ở2×, tiêu đề xuống hàng riêng lấy đủ chiều rộng. Không ellipsis, line clamp hay giảm cỡ chữ để lọt khung.
- Type: Nunito + Baloo2 từ font local hiện có. Cỡ chữ sản phẩm dùng rem; 1 / 1.3 /
  2× thực sự thay computed font size. Thanh điều khiển reviewer dùng px riêng,
  không nằm trong phone. Controls sản phẩm ≥48px; glyph không cần chứa đầy đủ tên
  vì accessible name và list alternative luôn có.

## 3. Nguồn nội dung và quyền xác nhận

Pin nguồn: `0990fbcbf6045bd64244239e36ccbca8c8dc394b` (CODE đã fetch khi review r38).

| Nguồn chỉ đọc | Vai trò |
|---|---|
| `app/lib/modules/achievements/achievement_catalog.dart` | 15 định nghĩa, literal VI, secret flags, numeric goals |
| `app/lib/modules/achievements/achievement_house_module.dart` | Bốn phòng, current badge/secret presentation, load/seen behavior |
| `app/lib/modules/achievements/achievement_engine.dart` | Cấp achievement theo event; đây mới là source runtime, prototype không chạy engine |
| `WORLD_EXPANSION_REDESIGN.md`, `GAME_DESIGN.md` | Nhà thành tích trong thế giới mở rộng; quan hệ skill/social |

[Manifest](manifest.json) pin blob + SHA256; [source-catalog.json](source-catalog.json)
trích 15 literal definitions để review, **có spoiler**, không được phone tải.
[Catalog UI](catalog.js) chứa 12 public definitions, 3 khóa opaque `mystery_1..3`,
và đúng một earned-secret fixture. VI tên/mô tả/howTo giữ nguyên source. EN là
bản dịch DESIGN mới, không giả nhận là literal app ARB hoặc bản dịch đã duyệt.

Không sao chép hay thực thi closures `check` / `progress` Dart. Việc mô tả một điều
kiện không xác nhận nội dung đó đã được QA chơi thành công ở runtime.

### Các trường hợp cần lưu ý

1. `first_line`: “Dòng Code Đầu Tiên”; “Viết dòng Python đầu tiên cùng Py.”;
   “Hoàn thành Bài 1 của Main Quest.” Không đổi thành một nhiệm vụ tự nghĩ.
2. `maze_explorer`: goal10 từ nguồn; **4/10 là fixture**. Chỉ badge này trình bày
   numeric progress để kiểm state. Unknown progress không hiển thị0/10.
3. `perfectionist`: 3 sao toàn bộ10RobotMaze **hoặc** toàn bộ12BugHunter. Giữ nguyên
   copy OR; không hiển thị thanh10 bước khiến người dùng hiểu đây là đường duy nhất.
4. `different_path` earned fixture chỉ được reveal cho `mystery_2`, không dùng
   definition ấy cho hai secret khác. Không có earned date giả.
5. Source có secret về học sau20giờ địa phương. **Không quảng bá chơi muộn**, không
   chèn đếm ngược, streak pressure hoặc yêu cầu secret để mở nhà/học tiếp.
6. Engine tự ghi nhận achievement; prototype không có CTA “claim”. Runtime hiện có
   `markAllSeen()` khi load: r39 **không gọi và không thay đổi** behavior này; đọc
   bản thử không đánh dấu achievement trong app đã xem.

### Chính sách giữ bí mật — đề xuất hiển thị, không sửa engine

Runtime source đang có hint dạng câu đố cho locked-secret. r39 đề xuất thận trọng:
locked-secret chỉ có tên generic và mô tả bất ngờ; không title thật/howTo/goal.
Tìm kiếm chỉ trên title được phép nhìn thấy, không trên condition/sourceID. Secret
đã đạt mới reveal definition được cung cấp.

Đây là **DOM/search redaction**, không tuyên bố bảo mật server-side: earned fixture
nằm trong JavaScript, JSON nguồn review có đủ secret, người mở DevTools/file vẫn
xem được. Runtime thật phải quyết định payload/visibility contract riêng. Không
coi file tĩnh là nơi giấu bí mật có tính bảo mật.

## 4. State, tương tác, điều hướng

| Fixture | Kết quả mong muốn |
|---|---|
| room_populated | Hai earned sample `first_steps`, `first_line`; hai medal trên bục |
| cabinet_all |15cards; earned count2/15, tách result count |
| earned_filter |2sample đã đạt |
| locked_filter |10badge thường chưa đạt; không gộp secret |
| secret_filter |3secret, generic khi chưa đạt |
| earned_detail |Đã ghi nhận; không claim, không bịa ngày |
| locked_detail |Maze Explorer + howTo nguồn + sample4/10 |
| secret_locked |Generic; không hint/condition/progress |
| secret_earned |Thêm earned `mystery_2`; tên/mô tả đúng nguồn, tổng3 |
| empty_room |Thật sự0earned; không medal trên bục, vẫn xem catalog được |
| loading |Không badge list/medal, count “— / 15”, không giả empty |
| load_error |Thông báo lỗi đọc, không xóa mẫu; retry riêng |
| progress_unknown |Thiếu progress khác0; ẩn progress bar |
| search_empty |Không kết quả; vẫn giữ ownership2/15 |

- Hotspot và list cùng mở chi tiết; list là đường không phụ thuộc tọa độ cảnh.
- Tìm title có trim/case-fold theo locale; filter all / earned / not-yet-normal /
  secret. Không dùng search để reveal tên secret đang khóa.
- Detail-back / header-back / Escape về tủ; giữ query, filter, scroll, focus về card
  trước đó nếu card vẫn tồn tại. Từ medal trong phòng, quay lại cũng về tủ để có
  danh sách đầy đủ. Room tab về cảnh. Tại room gốc, back disabled vì navigation về
  village nằm ngoài prototype; không giả route app đã nối.
- Error → retry → loading. Response chỉ do reviewer chủ động trả mẫu; không gọi
  network, không timer ngầm. Trong phone riêng, retry sẽ chờ cho tới khi reviewer
  trả qua harness hoặc dùng back để hủy mẫu pending. Không nói đã tải từ backend.
- Response khớp token mới được áp dụng trong phiên model; stale/duplicate bị bỏ qua.
  Back khi loading hủy token, trở về error/retry. Chuyển fixture là **reset simulator**,
  không phải một request runtime hoặc một restore persistent session.
- Locale/scale đổi giữa chừng giữ state, query, ownership và pending request. Browser
  language VI → VI, ngôn ngữ khác → EN; query/manual reviewer override ưu tiên.
  Không ghi settings. Sản phẩm thật giữ yêu cầu **system default + Settings override**
  hiện có; selector reviewer không thay thế Settings hoặc xây localization mới.
- Không game animation. Calm toggle và `prefers-reduced-motion` giữ trạng thái tĩnh.
  Không tuyên bố character rig, âm thanh, celebration hoặc spatial movement đã có.

## 5. Accessibility và bằng chứng

Native buttons/input/select, visible keyboard focus, semantic headings/labels,
aria-pressed cho filters/tabs, accessible labels cho scene medals, status/live
announcement cho thay đổi kết quả. Nền có alt riêng; ký hiệu medal aria-hidden vì
button/card đã có tên. Chi tiết cũ được xóa text khỏi DOM khi đóng hoặc lỗi tải.

Kiểm định HTML:14fixtures×2phones(390×844,360×640)×2locales×3scales = **168cases**;
2,688computed-font comparisons, targets/overflow/header width/footer reachability,
secret leakage và ownership-vs-result checks.12browser interaction flows và20model
checks. [Browser evidence](evidence/browser-checks.json), [model](evidence/model-checks.json).

Đã mở screenshot đại diện để rà thủ công; phát hiện glyph bracket thiếu font và
filter EN2× tách từ xấu, sửa sang ASCII `<>` và filter2cột, rồi chạy lại toàn bộ.
Không đồng nhất automation168cases với đã nhìn bằng mắt168ảnh.

**Chưa kiểm**: screen-reader trên thiết bị thật, Flutter text scale/semantics,
contrast certification toàn màn, renderer frame time, save/load database, event
engine, navigation app, reward authority. Không dùng receipt này để ACCEPT runtime.

## 6. Công việc còn lại trước khi triển khai

- Chốt display-policy secret với hợp đồng runtime; không tự sửa rule khi dựng UI.
- Vẽ/export bộ badge asset riêng và validate metadata, icon meaning, nền sáng/tối.
- Calibrate room camera/medal anchors, safe area, scene cropping; tách layer nếu cần
  tương tác actor/animation. Bản nền opaque hiện tại chưa đủ cho các việc ấy.
- Chuẩn bị order Flutter giới hạn: đọc repository data, trạng thái tải/failed thật,
  semantics/device checks, bảo toàn engine/seen behavior theo quyết định sản phẩm.
- Trophy wall/collectibles/creation corner và social-reward inventory cần các slice
  tiếp theo; không dùng “15định nghĩa” để tuyên bố toàn bộ Nhà Thành Tích hoàn chỉnh.
