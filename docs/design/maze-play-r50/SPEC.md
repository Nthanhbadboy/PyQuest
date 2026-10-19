# r50 — Gameplay bằng khối lệnh và kết quả Maze

**2026-10-18 · DESIGN_STUDY_DELIVERED · runtime NOT_AUTHORIZED**

Pin CODE `de01a490743982356ad5240d77ea99e9dbf8c7f5`; base DESIGN
`b911a1cd5bbc789d75e5aee4191680c7b43eba6b`. Scope này độc lập correction PQC-011.
Không sửa app, workflow, SDK, dependency, reward/event hoặc bản APK.

## 1. Đối chiếu và bố cục

Đã đọc MazeLevel/MazeSimulation/MazeStars, builder/run/result/next-cost trong
MazePlayScreen, entry/unlock trong module, config và shared result. Source pins
và trích đoạn ở `source-manifest.json` / `SOURCE_EXCERPTS.md`. Đã mở xem baseline
06/07/09; chúng là ảnh runtime lịch sử, không phải after-redesign và không có
execution SHA mới được suy từ tên file.

- Thay flat green field + cây vector bằng sân vườn, board gỗ/đất có bề dày,
  bụi cây có mặt trên/mặt bên và Robo2,5D. Bảng giữ orthogonal để hướng đi không
  bị đổi nghĩa. Camera của backdrop không được coi là camera engine đã calibrate.
- Desktop: board bên trái, bàn lệnh bên phải; không phải nhiều màn ghép thành ảnh.
- Phone: một scroll owner cho board/bàn lệnh; dock hành động luôn ngoài scroll.
  CTA ban đầu “Xếp lệnh cho Robo” đưa tới controls; Chạy đưa lại board. Trong lúc
  chạy, caption hiện bước đã thử, block hiện tại/hướng và lượt lặp nếu có.
  Không ép board + cả chương trình luôn vừa360×640, nhất là chữ200%.
- Text/code/HUD luôn nhìn chính diện; không bake câu chữ vào art. Mobile chuyển
  chip năng lượng vào scene, 200% bỏ breadcrumb lặp lại để dành chỗ cho tiêu đề,
  không thu nhỏ font. Tap targets >=48px; board là ảnh ngữ nghĩa, không phải editor.

## 2. Luật đọc từ source

| Luật | Áp dụng trong study |
|---|---|
|10level,246ô | Dùng catalog r45, kiểm lại từng row/title/story/limit/allowLoops với JSON CODEde01 |
|Hướng | U/D/L/R là hướng tuyệt đối trên bảng, không phải xoay trái/phải theo Robo |
|Tường/mép | Kết thúc lượt thử; không đi vào ô bị chặn |
|Nước | Đi vào ô nước rồi kết thúc lượt thử |
|Đủ lệnh mà chưa tới rương | `notThere`, không tự nối đường tới đích |
|Rương | Dừng chạy khi tới; các lệnh dư trong chương trình vẫn tính commandCount |
|Lặp |2–9lần, tối đa6mũi tên trong body ở UI; commandCount=1+body.length |
|Giới hạn thực thi | Tối đa200move; đây là analogue JS, không chứng minh engine parity |
|Sao | Tới rương:1; đủ ngọc:+1; không vượt mục tiêu lệnh:+1; hai sao thêm độc lập |
|Màn0ngọc | Tới rương tự đạt tiêu chí ngọc; không tạo fixture rm01=1sao bất khả thi |
|Điểm |40/30/30 từ config, hiển thị “điểm mẫu”, không phát thưởng |
|Unlock | Record ngay trước đủ để mở màn kế;1sao vẫn mở, không khóa bằng tổng sao |
|Chi phí | Màn mới2, replay đã qua0, Creator0; không trừ thêm mỗi lần sửa/chạy lại trong màn |

Robo trên board chỉ xuất hiện ở một ô hiện tại; spawn chỉ là ký hiệu trên nền,
không có robot ghost. Dấu vết chỉ hiện sau khi đã thử; không hiển thị solution
trước lượt chơi. Catalog không mang `solution` từ nguồn. Fixture review có plan
mẫu định trước, không tự điền vào chương trình của người chơi bình thường.

## 3. Đề xuất UI/state, KHÔNG nói source đã có

- **D50-P1 — quan sát từng bước:** pause/resume/single-step/stop; active block và
  inner arrow theo StepRef analogue. Timer token làm callback cũ vô hiệu sau Stop,
  đổi fixture/level. Nhịp480ms, reduced-motion220ms là nhịp review, không đổi config
  source380ms. Không animate vị trí giả theo screenshot; frames tính từ lệnh JS.
- **D50-P2 — chỉnh kế hoạch:** chọn block → đưa trước/sau/bỏ; mở lại repeat, đổi số
  lần, thêm/bỏ mũi tên cuối; undo40snapshot, clear có confirmation. Error trở về
  editor vẫn giữ plan và chỉ rõ block gây lỗi cho tới lần sửa kế tiếp.
- **D50-P3 — giới hạn builder nhất quán:** study cap30commandCount tổng thể.
  Source `_addMove` có cap30 nhưng `_addLoop` không enforce cùng global cap;
  không nói invariant chặt hơn này đã có trong Flutter.
- **D50-P4 — xác nhận kết quả:** pending/error/retry/saved tách khỏi won. Sổ mẫu
  chỉ cập nhật khi ack đúng token; callback lặp không nhân thưởng, best star không
  giảm. Next bị chặn trước ack. Source hiện emit/store trong `_onWin`, không có
  đủ pending/retry UI hoặc transaction/idempotency bảo đảm như mô hình đề xuất.
  Khi port phải thiết kế authority/atomicity thật, không tin receipt client.
- **D50-P5 — next/exit guards:** thiếu năng lượng khác chưa đọc được; không tự
  refill hoặc gán success cho retry dữ liệu. Cả hai cho replay miễn phí. Rời
  page báo mất draft/confirmation trong mẫu. Source có thể pop khi spendEnergy
  không thành công; r50 không sửa hành vi đó trong app.

Kết quả1/2/3sao đều có lời khích lệ, không giả mọi lượt là perfect. Last-level
result không tạo level11, đảo mới, vật liệu nhà hoặc achievement tự bịa. Lối tới
Creator chỉ là đường dẫn study đã có, không phải reward/unlock mới.

## 4. Ngữ nghĩa bản mẫu

- Dữ liệu ở RAM; không localStorage/sessionStorage, tài khoản, DB, events,
  energy service, analytics hay APIAI. Nhãn mẫu hiển thị cả trên phone.
- Entry mặc định là returning player ở màn3, sample records rm01=3/rm02=2,
  năng lượng còn4 sau admission giả định. Không trừ lại entry cost trong r50.
- Next trong cùng study thật sự đổi source board và giảm **sample** energy2
  nếu màn đó chưa qua; replay next-record0. Không thay tiến độ người dùng.
- Back trỏ r45; kết quả cuối có link r46. **Không có state bridge qua các trang**;
  r45 vẫn giữ destination-preview của receipt lịch sử, không bị sửa lén để giả
  toàn flow đã tích hợp. Reload reset hoàn toàn sample records/draft.
- Python ở đây chỉ là bản dịch đọc từ blocks, không editable/executable. Đây
  **không thay thế Code mode trong app**, không chứng minh Dart Python interpreter.
  Full Python editor/diagnostics còn là gap thiết kế riêng, cũng như custom save.
- Gợi ý đã soạn, không AI tutor/chat/voice. Không thêm backend/token/quota gate.

## 5. Interaction và accessibility

VI/EN +100/130/200% là bàn kiểm thiết kế, không phải thay Settings. Sản phẩm thật
vẫn dùng system locale và override thủ công đã có. Native dialog có tên, focus
wrap, Escape và trả focus opener/fallback. Kết quả/pause dùng text và live region,
không chỉ màu; help giải thích hướng tuyệt đối và cách đếm lệnh. Board có mô tả
vị trí và bản đọc từng ô mở rộng. Không claim screenreader/device audit.

Nút điều khiển không bị shrink ở200%. Nội dung dài cuộn trong screen hoặc dialog;
program có scroll owner riêng. Font assertions bỏ icon glyph/decorative art;
text label được đo tỉ lệ thật. Các capture tắt smooth scroll **chỉ trong test**
để lấy đúng vị trí focus, không dùng ảnh đang giữa animation làm bằng chứng.

## 6. Acceptance của study, không của app

28model checks +500random programs so với scalar JS analogue;324browser cases
(19state +8secondary dialog)×2viewport×2locale×3scale,3.732font assertions,
17interaction flows và13captures. BrowserChromium153; kiểm errors/requests,
overflow, target size/collision, single Robo, logic và các guard qua click/tap.
Không có Flutter/Dart execution, DB migration, reward authority hay physicaldevice
voice/accessibility acceptance. PQC-011 giữ disposition theo review r49.
