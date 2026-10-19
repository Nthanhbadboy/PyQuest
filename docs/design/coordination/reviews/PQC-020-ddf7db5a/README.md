# Review ddf7db5a — CI đã đạt; ảnh thật còn lỗi geometry và gap app-root

**2026-10-19 · PQC-020 CHANGES_REQUIRED / NOT_ACCEPTED.**
Nhận handoff CODE tại `ddf7db5aab54603f9e9d4caca2eb15abce6c64f4`, tip nhánh
`arena/4253d4f1-pyquest`. Quyết định tiếp: [PQC-020 R3](../../specs/PQC-020-R3.md).

## 1. CI xác minh độc lập trên tip, không suy từ 6e45eb88

Đọc REST Actions và toàn bộ195check-runs (phân trang), kiểm head_sha từng receipt.

| Gate | Run / check | Kết quả |
|---|---|---|
| Focused020 | [39248746968](https://github.com/Nthanhbadboy/PyQuest/actions/runs/39248746968) / [118047499829](https://github.com/Nthanhbadboy/PyQuest/runs/118047499829) | 5gate PASS;58/0 |
| NormalCI | [39248747036](https://github.com/Nthanhbadboy/PyQuest/actions/runs/39248747036) / [118048853111](https://github.com/Nthanhbadboy/PyQuest/runs/118048853111) | 9phase exit0;12Settings,435ordinary,10render |
| Maintenance verify | [39248747052](https://github.com/Nthanhbadboy/PyQuest/actions/runs/39248747052) / [118048036656](https://github.com/Nthanhbadboy/PyQuest/runs/118048036656) | 12/1/2/7;435/0;10/0; hỗ trợ đềuPASS |

Flutter3.47.7 / Dart3.13.5 / frameworkabaf9c523780a608bd46686fd5e53740a07077f8.
Analyze/formatter/localization/pub-get+lock/clean đều đạt. Tipdiff từ6e45eb88 chỉ
taskdoc, nhưng **đã thực sự rerun cả ba gate trênddf7**. Không còn gate NOT_RUN
như reviewbed783cf. Android build skipped; không APK/device acceptance.

## 2. Source/routing review

- Delta từbed783cf không có `app/lib` change. Journey lexical sequence giống base
  sau đúng một nhãn `Núi Lửa Pip`→`Núi Lửa`, bỏ comment/whitespace/trailing commas
  khi so sánh; không bỏ mọi comma. Đây là so sánh lexical, không Dart AST proof.
- Lesson-route vẫn8cases;6case ngoài keyboard/semantics giữ nguyên lexical tokens.
  Keyboard đặt focus một lần rồi Tab/Shift+Tab thật, Enter/Space mở đúng Maze sheet,
  Back trả focus, energy/event assertions giữ nguyên. Nhận phần sửa này.
- Hai workflow giữ clause cũ khi bỏ whitespace. DESIGN chạy1.536 tổ hợp mỗi workflow
  (256marker subsets×2events×3refs), tổng3.072 comparisons đúng condition yêu cầu.
  Maintenance từ `env:` trở xuống byte-identical với base: không đổi phase/steps/
  SDK/threshold/permissions. Focused chỉ thêm paths theo R2. Đây là kiểm evaluator
  tĩnh cho biểu thức đang dùng, không thay run thật; cả ba run thật cũng đã xanh.
- Nhánh CODE cũ vẫn01db21a6. Không yêu cầu push nó hoặc tạo branch khác.

## 3. Đã lấy và mở ảnh Flutter thật — không chỉ đếm neutral checks

Decode đủ chunks, kiểm sourceSHA/check IDs, lưu hash ở [evidence.json](evidence.json).
Đây là JPEG preview do CI xuất từ capture, không phải PNG gốc hoặc ảnh HTML.

| Ảnh đã xem | Điều quan sát / giới hạn |
|---|---|
| [VI3901×](captures/r1a_map_390_vi_1x.jpg) | Núi Lửa che phần phải/dưới nhãn Tháp Python |
| [EN3601×](captures/r1a_map_360_en_1x.jpg) | Volcano cũng chồng Python Tower |
| [VI3902×](captures/r1a_map_390_vi_2x.jpg) | Directory chữ lớn; dùng route override, chưa chứng minh root2× |
| [EN3602×](captures/r1a_map_360_en_2x.jpg) | Directory; cần scroll xem đủ6, không thể suy chỉ từ ảnh đầu |
| [Locked sheet](captures/r1a_locked_activity_sheet.jpg) | CTA prerequisite và cancel hiện rõ ở cấu hình này |
| [Prerequisite route](captures/r1a_locked_prerequisite_route.jpg) | Bài3 được highlight, vẫn locked; không tự mở LessonScreen |
| [Sau route return](captures/r1a_map_after_route_return.jpg) | Thấy đủ6markers/art; lỗi Tháp Python/Núi Lửa vẫn còn |

### Finding A — geometry model và render không khớp (production bug)

`_positionedMarker` tính anchor tuyệt đối rồi đổi sang `Alignment(2*x-1,2*y-1)`.
Nhưng Align đặt child theo khoảng trống: `childSize/2 + anchor*(parentSize-childSize)`.
Geometry helper/test dùng `anchor*parentSize`. Với width390, marker width124,8,
tâmx của dragon thực theo Align là279,864, không phải319,8 như helper giả định.
Đây là công thức source, không phải số đo pixel được bịa từ JPEG. Ảnh xác nhận
hậu quả chồng nhãn. Pure test “no overlap” xanh không chứng minh actual RenderBoxes.

### Finding B — app root2× vẫn chưa đạt (production policy + evidence gap)

Root vẫn `withClampedTextScaling(maxScaleFactor:1.2)`. Render helper
`pushMapAtTextScale` push MainMap thứ hai, override MediaQuery bên trong Navigator.
Vì vậy ảnh2× hợp lệ như isolated surface, **không hợp lệ làm bằng chứng app root**.
Test12configs đã tồn tại trong `main_map_scene_test.dart` và suite xanh; không gọi
nó NOT_RUN, nhưng harness `mainMapHost` cũng không phải `PyQuestApp` production.
R3 cho phép bỏ root cap và thêm matrix thật, không chỉ đổi tên ảnh.

### Finding C — semantics oracle chưa đúng tầng (test evidence gap)

Case mới trong lesson-route đọc `Semantics.properties` bằng helper `semanticsProps`,
lọc `button && label.contains(name)` rồi assert có một `ExcludeSemantics` ở đâu đó
bên dưới. Không chứng minh rendered tree có đúng role/action/không duplicate; sự
có mặt của ExcludeSemantics không kiểm ancestry của node bị loại. Không kết luận
production semantics hỏng: `main_map_scene_test.dart` **đã có** rendered name/tap
test với `ensureSemantics/getSemantics`. R3 yêu cầu dùng cách đo đó để hoàn thiện
role/uniqueness của regression mới, giữ coverage CTA và không đếm wrappers.

## 4. Một số gap evidence đã có thể đóng ngay

- DESIGN lấy lại4chunks `a01_map_new_player` từ Checks API tại **6dc8ca8**, decode
  và so **byte-identical** với before image CODE đã lưu. [Ảnh before](captures/before-6dc8ca8-a01-map-new-player.jpg)
  có SHA256 `4bb7f2d981655abbbd09f02e7cfd87c30ddfd6dfe86d8bdb197a3ed70cbcbfe3`.
  Receipt ghi check IDs. Before390VI/new-player/1× dùng được; không cần rerun baseline.
  Không suy before2× hoặc cùng scroll offset cho mọi ảnh.
- Đọc VP8 header asset:853×1844;349864bytes;SHA256d3130b407e08f146ae633b50fad9f1e05aa466dd5dc049cdc75c1b36f8804c0e.
  RGBA lý thuyết6,00026MiB, **không phải RAM/GPU thiết bị**. Render precache dùng
  nền mới +sáu thumbnails, không còn island_map trong helper đó. Cần tổng hợp
  inventory/budget, không đòi CODE đo lại hash như chưa có dữ liệu.

## 5. Verdict và bước kế tiếp

**Nhận:** CI same-tip, routing verify-only, locale/label fix, keyboard regression,
ordinary coverage435 và render10; baseline image provenance/asset byte facts.
**Chưa nhận toàn020:** lỗi nhãn chồng, root2×, rendered semantics regression và
bộ evidence cuối sau sửa. R3 mở đúng app-root policy/layout/test files cần thiết,
không gameplay, SDK/deps, CI policy mới, APK hay R1-B.

DESIGN chỉ review source/API/ảnh và publish tài liệu; không chạy Flutter locally,
không dispatch/rerun hoặc sửa CODE. Root text policy ảnh hưởng nhiều route nhưng
nghiệm thu020 chỉ chứng minh lát cắt đã test, không tự chứng nhận toàn app/thiết bị.
