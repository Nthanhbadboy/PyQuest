# PQC-007 — Review độc lập bảng feasibility P02

- tested_code_commit: `3b59f0b538f4bd94c49bf3076ae24f1c1dd8f428`
- tested_design_commit: `86513ca29910896ef21961d9489f00414dc5262f`
- reviewer: agent nhánh design `arena/00838eb9-pyquest`, đọc lại source độc lập với tác giả bảng code
- external_model_delegated: **no** — phiên này không có công cụ gọi model khác
- verdict: **CHANGES_REQUESTED cho bảng feasibility**; test/CI xanh được ghi nhận riêng
- runtime/art authorization: **không đổi**

Chỉ chọn nhập PQC-007, PQD-002 và EVIDENCE từ nhánh code để sửa tài liệu, không merge
nhánh hay nhập app/test/app/lib. Bản gốc vẫn đọc được bằng `git show <code_sha>:<path>`.
Các file `.dart` bên dưới đều tính dòng tại tested_code_commit, không tại tip tương lai.

## Tái hiện

```sh
python3 docs/implementation/coordination/reviews/PQC-007/audit.py > /tmp/pqc007.json
cmp /tmp/pqc007.json docs/implementation/coordination/reviews/PQC-007/facts.json
C=3b59f0b538f4bd94c49bf3076ae24f1c1dd8f428
# Xem bất kỳ dẫn chiếu bên dưới, thay path/range bằng ô tương ứng:
git show "$C:app/lib/modules/main_map/main_map_screen.dart" | nl -ba | sed -n '101,125p'
gh run view 38881345619 --json headSha,conclusion,status,url
gh api 'repos/Nthanhbadboy/PyQuest/commits/e98f826/check-runs?per_page=100'
```

`audit.py` chỉ đọc Git blobs đã pin, tự đọc WebP header (không tin kích thước manifest),
so hash/manifest, parse rect/anchor của sáu module, tính cover và scan toàn app/lib.
`facts.json` chứa output, số chưa làm tròn, source hashes và line anchors.
Đây là tính toán/header inspection, **không phải codec decode hay RAM thiết bị**.

Đã chạy thêm bộ coordinator từ archive nhánh code: **30/30 PASS**. Các test đó dùng
mock git, không chứng minh đã khởi động delegate/watch thực. `flutter`, `adb`, `emulator`
không có trên PATH; không có Flutter/emulator run local trong review này.

## Kiểm từng dòng A.1

Alias dưới đây chỉ để bảng dễ đọc, không phải đường dẫn thay thế:
- `map` = `app/lib/modules/main_map/main_map_screen.dart`
- `settings` = `app/lib/core/settings_service.dart`
- `play` = `app/lib/modules/robot_maze/maze_play_screen.dart`
- `models` = `app/lib/modules/robot_maze/maze_models.dart`
- `sheet` = `app/lib/modules/main_map/activity_sheet.dart`

| Dòng | Verdict | Dẫn chiếu đã kiểm / kết luận sửa |
|---|---|---|
| A.1.1 Intro | **SAI một phần** | `map:58–60,101–110,533` và `settings:33,38` đúng; hiện `_showIntro` ghi seen **sau khi dialog đóng**, không phải welcome CTA trực tiếp ghi. `setIntroSeen()` chỉ ghi `1`, không thể dùng nó để mở lại intro. “Chọn lại” cần action replay/navigation riêng, không reset persistence. `tutor_panel.dart:121` thuộc lời chào Tutor, không phải welcome; `shared/characters/dialogue.dart:40–56` chọn variant bằng seed, lời gọi này không truyền seed nên mặc định 0, **không tự xoay vòng**. |
| A.1.2 Map | **SAI** | `map:26,138–179,277–281` đúng công thức. Ảnh thật P02 **896×1200**, không 1024². Ở 360×640: P02 cover = **477.8667×640**, nhìn **75.3348% chiều rộng**. Một ảnh vuông giả định thì cover **640×640**, không 640×645. Rect, crop, số file và câu “không có tọa độ” đều cần sửa: HTML có sáu tọa độ điểm quy đổi ngay được sang 0..1, nhưng **chưa có rect production**. Các hitBox nằm trong **sáu** module, không ba file. Giữ kết luận không thay nền rồi giữ rect cũ; cùng ratio cũng chưa đủ nếu vị trí công trình khác. |
| A.1.3 Calm/energy | **ĐẠT phần source, CẦN BỔ SUNG** | `map:131` calm đúng; EnergyPill là **197**, không 196. Setting riêng có sẵn nhưng hub button vẫn là UI mới. Năng lượng HTML 20/20 không phải dữ liệu game; runtime phải dùng service thật. Nói rõ prototype chỉ lấy OS preference lúc load, người dùng có thể override; không đồng nhất với rule OS-OR-setting dự kiến. |
| A.1.4 Sheet/card | **SAI một phần** | `sheet:21–129` và `shared/widgets/common.dart:309–338` xác nhận 104², scroll, maxHeight 0.9, SafeArea và hai pop strings. Nhưng sheet không có field/UI chi phí năng lượng chuyên biệt; không nói đó là feature bị mất. P02 có màn `activity` dù không dùng widget Flutter `ActivitySheet`. Tái dùng model/action được; chuyển modal thành selected card **không** phải “tái dùng nguyên vẹn chỉ đổi nội dung”, cần container/flow mới và kiểm font lớn. |
| A.1.5 Maze | **SAI quan trọng** | `maze_board.dart:11,23,104` và `models:63,155,357,376` đúng vị trí; 155 là default **custom-level**, không default mọi level. `command_limit=4` của rm_01 là tiêu chí sao, **không phải input cap**: `play:135` cho block count <30; `models:357` chỉ xét sao. `play:287` xóa hintCells, **không phải nấc gợi ý**; hint thật ở 434–468, strong hint ba bước đầu phụ thuộc fail/config. Run CTA bị disable khi chạy (`play:882`), chưa có Stop 1-1. Active block được xóa ở 416 nên việc giữ lỗi đúng chip cần thiết kế/code thêm. |
| A.1.6 Result | **SAI một phần** | `play:519–565` là pipeline hoàn thành màn thật: emit levelCompleted, gom notices, score/best, 3 goals và **3 stats** (Số lệnh/Đá quý/Lần chạy). `map:254–270` là reward mở activity, không phải toàn bộ pipeline thắng. Không có symbol `recordLevelResult` trong app/lib; `app/test/services_test.dart:50` kiểm idempotency qua service/event API. Không yêu cầu chọn giữa “4 ô” và “1 dòng” dựa trên tiền đề sai; bảo toàn dữ liệu thật trước, layout sau. |

## Kiểm từng dòng A.2

| Dòng | Verdict | Dẫn chiếu đã kiểm / kết luận sửa |
|---|---|---|
| Text scale | **ĐẠT có giới hạn** | Scan app/lib không có `textScaler`/`textScaleFactor`; không tìm thấy clamp trực tiếp. `app/test/activity_sheet_thumbnails_test.dart:296–382` có sáu unlocked + một locked, modal route thật và assert pop sau ensureVisible/tap ở 360×640@2, scale2. CI đúng commit xanh. Không suy ra mọi chữ/CTA đều đọc đủ (ChunkyButton có maxLines1/ellipsis) hoặc toàn app accessibility đạt. |
| Touch target | **SAI một phần** | Nhỏ nhất ở 360×640 là Catch Stars **84.6×79.98**; bảng 390 có bốn rect bị tính sai. `shared/widgets/chunky_button.dart:42–51,94–119`: small có face44 **+ padding depth4 trong GestureDetector =48 cao** dưới constraints bình thường; không kết luận target chỉ44. Cần đo rộng/cao hit-test thật. `RoundIconButton(size:44)` là trường hợp khác: rộng44, depth nằm theo chiều dọc. Rect toán chưa xét overlay, clipping/hit arbitration hoặc nhãn chồng. |
| Focus/semantics | **CẦN BỔ SUNG, bỏ khẳng định quá mức** | `map:164–168` thiếu explicit button role/label/keyboard focus. Nhưng GestureDetector không mặc nhiên loại semantics; còn `_MapLabel` GestureDetector chứa text (`map:347–400`) cũng mở sheet. Không đủ chứng cứ “TalkBack không tới được”. Phải kiểm cây semantics, accessible name, tap action, duplicate nodes, Tab/Enter/Space; HTML button không tự chứng nhận screen-reader/device usability. PQC-008 vẫn hợp lý nhưng prompt API phải được kiểm theo SDK, không dùng tên API đoán. |
| Reduced motion | **ĐẠT phần scan** | Không có `MediaQuery.disableAnimations`/`accessibilityFeatures` trong app/lib đã pin; có calmMode riêng. “1 dòng +1 dòng từng ticker” chưa phải effort estimate đã kiểm chứng. Mẫu lấy prefers-reduced-motion lúc tải, không subscribe thay đổi OS; chỉ là exploration. |
| Background | **CẦN BỔ SUNG** | Lifecycle overrides chỉ ở `core/audio_service.dart:111` và `core/session_service.dart:49`. `catch_stars_module.dart:331,358–386` có ticker, pause/route guard và delayed900ms không giữ handle. **Không đủ kết luận ticker tiếp tục chạy mọi lúc app ẩn**: Flutter scheduler/TickerMode/lifecycle cũng ảnh hưởng. Cần test pause/resume dt và pending callback; risk có thật, hiện tượng thiết bị chưa đo. |
| Cache | **SAI phần số/miêu tả test** | Không override maximumSizeBytes. P02 full RGBA8 lý thuyết = **4,300,800B ≈4.102MiB**, không 1024². Test ở `activity_sheet_thumbnails_test.dart:413–432` **precache sáu file**, không mở sáu sheet; chỉ assert entries≥1, bytes<64MiB; không in `live` và không assert bytes>0. Check report bị trim nên chưa lấy được số entries/bytes thực. Không coi assertion này chứng minh cả sáu còn ở cache hay footprint màn. |

## Toán đã sửa — EV-ID-012

Đơn vị logical px, full viewport làm `constraints.biggest` để tính giả định; không nhân DPR.
Actual map container/safe area/overlay trong app cần kiểm widget riêng.

| Viewport | Cover nền cũ | Phần bị crop | main_quest | robot_maze | dragon_jump | catch_stars | bug_hunter | achievement_house |
|---|---|---|---|---|---|---|---|---|
| 390×844 | 471.070×844 | **17.2097% chiều rộng nguồn** |117.767×190.744|153.569×121.536|148.387×140.948|110.701×104.656|141.321×122.380|122.478×140.948|
| 360×640 | 360×645 | **0.7752% chiều cao nguồn**, không crop ngang |90×145.770|117.360×92.880|113.400×107.715|84.600×79.980|108×93.525|93.600×107.715|

Ảnh P02 896×1200 nếu dùng **cover toàn viewport** (không phải layout contain của HTML):
- 390×844 → 630.187×844, nhìn 61.8864% chiều rộng.
- 360×640 → 477.867×640, nhìn 75.3348% chiều rộng.
- 56.25% chỉ đúng cho ví dụ vuông giả định 1024² vào 360×640, **không mô tả P02**.
- Thumbnails: **144,272 →112,938 B**, giảm31,334 B đúng. Nhưng full-resolution RGBA8
  lý thuyết **1,990,656 →6,291,456 B**; nén nhỏ hơn không đồng nghĩa decode ít RAM hơn.
  Không dùng các tích W×H×4 này làm số ImageCache/GPU/RSS đo thực.

## Route lesson: tên openLessonId không có nghĩa tự mở lesson player

Kiểm thêm `app/lib/modules/main_quest/main_quest_module.dart:51–56,87–111,146–159,270`:
`MainQuestHomeScreen(openLessonId: ...)` **cuộn/tô nổi card**, không tự push LessonScreen.
`_unlocked` giữ prerequisite; chỉ khi tap card đã mở mới `_open`/spendEnergy/push.

Vì vậy route regression phải có hai fixture: (a) người mới → home đúng target mq1_03,
card còn khóa, không tự vào bài/trừ energy; (b) đã xong hai bài trước nhưng chưa mq1_03 →
vẫn Bug Hunter khóa, route tới target rồi **tap thêm card** mới vào đúng lesson player.
Không biến câu “route lesson thật” thành yêu cầu bỏ qua khóa/auto-start ngoài scope.

## CI và ảnh: có kiểm độc lập, không chỉ chép báo cáo

Run `38881345619` head **e98f826ab385c34495c95552237375276ad8b57a** success, check
`PyQuest check` có cả 4 phase exit0; đoạn cuối report chứa **+157 tests/+10 render**.
Đã lấy đủ 18 chunk qua GitHub check-runs và decode thành **9 JPEG before** trong `before/`;
`ci-evidence.json` ghi SHA256, check IDs và source commit. Đây không phải ảnh after.

Đã xem trực tiếp j01 (maze390: CTA vào chơi + để sau hiện), j08 (locked360: CTA bài học
hiện; nút Để sau ở dưới fold). Chỉ hai ảnh này được ghi nhận visual review; các ảnh
còn lại không vì được tải mà tự coi là đã nghiệm thu.

Lưu ý: test-render ở text scale mặc định, **không** là ảnh chứng minh scale2.
Khung390 raw capture585px (ratio1.5), publish480px: scale final480/390=1.23077.
Khung360 raw540px, publish480px: scale final480/360=1.33333. Không đồng nhất DPR với
capture ratio. Seed rich/new-player là hai fixture profile, không cùng nội dung state.

## Việc tiếp theo, không đòi thêm ACK vô ích

1. Nhánh code nhận corrections docs này, cập nhật board/PQC-008 và không lặp lại số sai.
2. Design trả sáu câu A.3 bằng quyết định cụ thể ở PQD-002 revision2; quyết định thiết kế
   **không** mở runtime gate hoặc duyệt hình thay người dùng.
3. Tách regression route lesson hiện có + characterization semantics/hit target/cache
   thành test-only. Chạy test trên CI được, không cần emulator cho phần này.
4. PQC-004 cần thiết bị/âm thanh thật. PQC-005 cần SDK/network **và** gate dependency;
   không ghi rằng chỉ có SDK là tự được sửa lockfile.
