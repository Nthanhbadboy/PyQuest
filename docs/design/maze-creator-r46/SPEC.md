# r46 — Xưởng Mê Cung: hợp đồng thiết kế tương tác

2026-10-18 · DESIGN study, **không phải work order runtime**.
Pin CODE: `71b0fd3fd8fb07c73596ce089fa2e68f6fe87964`.
[8 source pins](source-manifest.json) · [trích đoạn có số dòng](SOURCE_EXCERPTS.md).

## 1. Từ source đến thiết kế — không đánh đồng

| Chủ đề | Source tại pin | r46 / chênh lệch có chủ ý |
|---|---|---|
| Bản đầu | `S..... / .##.#. / ...... / .#.##. / ...*.. / .....C`; limit10, loops=true; 6×6 | Giữ nguyên template, không dùng ảnh làm dữ liệu |
| Sáu bút | `# ~ * S C .` | Bụi cây, nước, ngọc, Robo, rương, tẩy/đất; trạng thái chọn có text và outline |
| Tên | TextField maxLength28; trim/fallback “Mê cung của tôi” khi lấy level | Giới hạn28grapheme bằng Intl.Segmenter, giữ input khi đang IME composition; normalize khi lưu mẫu. VI/EN không dịch tên do người dùng nhập |
| Kích thước | Chỉ4/5/6; giữ góc trên trái, thêm đất; S/C thiếu được đặt00/góc cuối | **Đề xuất:** xác nhận crop, ưu tiên vị trí trên nhưng không ghi đè endpoint còn lại; undo được |
| Đặt S/C | Source xóa mark cũ trước khi kiểm tra current==next; có thể ghi đè mark đối diện | **Đề xuất D46-P1:** same-cell là no-op; không bút nào ghi đè S/C; chuyển endpoint chỉ sang ô khác không chứa endpoint. Đây là bảo vệ thiết kế, không nói source đã sửa |
| Parser | `fromRows` fallback S=00, C=góc cuối; marker cuối cùng thắng nếu trùng | **Đề xuất:** dữ liệu thiếu/trùng marker hoặc sai cấu trúc hiển thị invalid, không dùng fallback để “chứng minh” |
| Limit | Clamp3–20, mặc định10 | Giữ; gọi là **mục tiêu lệnh**, không cap số lệnh được chạy; mục tiêu ảnh hưởng một sao riêng |
| Loops | Bật/tắt khối lặp; UI repeat2–9 | Giữ. Trong JS builder, lặp chỉ chứa hướng, không nested loop; body trống được bỏ khi đóng |
| Reachability | BFS qua `Tile.floor`, đến goal là true; tường/nước không qua | Giữ kết quả yes/no; không vẽ lời giải, không hứa lấy hết ngọc/đạt limit |
| Lưu | Private `_save`; không có nút Save riêng trong UI hiện tại; tự lưu trước test | **Đề xuất D46-P2:** nút Lưu rõ ràng, pending/error/retry, lưu rồi mới tiếp tục; kho RAM chỉ minh họa |
| Dirty navigation | New/load/back chưa có các guard của study; delete không hỏi như study | **Đề xuất D46-P3:** new/load/back hỏi giữ/lưu/bỏ; delete hỏi riêng, giữ bố cục đang mở thành draft nếu xóa bản đó |
| Verification | `_testRun` chỉ nhận won report mới set verified và save. Paint/resize/limit bỏ verified; rename/loops chỉ set dirty | **Đề xuất D46-P4:** mọi edit, kể cả tên/loops, tạo revision mới và bỏ dấu giải mẫu; undo không khôi phục bằng chứng cũ. Đây là chính sách thận trọng mới, không mô tả source hiện hành |
| Async | Source save/reload/navigation thật | **Đề xuất D46-P5:** kết quả gắn revision/token; phản hồi cũ không xóa dirty mới, lỗi không xóa bản nháp. Không tự tuyên bố repository hiện có API revision |
| Custom result | MazePlay emit `creatorTestRun`, pop custom report **trước** ordinary `levelCompleted`; Workshop có event first verify riêng | Study không emit event, không có ordinary progress, không nhận reward. Nút lưu kết quả mẫu chỉ ghi một object trong RAM |
| Economy | config.creator_mode=0; Workshop entry EnergyCostChip(0), không qua phí màn mới | Creator0, không tự thêm giá tile/ngọc/slot/undo/save/test |

Các D46-P chỉ là quyết định thiết kế để review/port **sau một order được cấp riêng**.
Không giao agent CODE sửa chúng cùng PQC-011. Các rủi ro source trên là đọc tĩnh,
chưa reproduce bằng Flutter/device; không dùng chúng làm execution finding cho011.

## 2. Bàn sáng tạo là nơi thao tác

- Mái teal/gỗ ấm/kệ dụng cụ/cửa nhìn ra vườn nối vớiW01 và Maze trailr45.
  Scene mới không phải crop màn cũ. Board live là lớp chính diện, không nghiêng
  touch geometry theo hình bàn. Không claim đã calibrate isometric coordinate.
- Hai hàng bút ở cỡ thường, hai cột ở200%. Tên và label không bake vào ảnh.
- Board có đúng n²hit cells lấy từ rows. Mỗi edit thay data trước khi render.
  Không có solution overlay. Bụi cây dùng ảnh prop mới; tokenRobo legacy chỉ là
  ký hiệu nhỏ, chưa phải cast production repaint; xem [asset plan](ASSET_PLAN.md).
- Touch: chạm đặt, vuốt cuộn. Mouse: kéo tô. Không ép người dùng cuộn điện thoại
  qua vùng lưới và vô tình phá bản vẽ. Đây là thay đổi interaction so với pan-paint
  source. Có hướng dẫn mở rộng; không lấy JS scroll thay evidence touch swipe.
- Bàn phím: một tab stop vào lưới; arrows đổi cell; Enter/Space đặt. Mỗi cell có
  tên hàng/cột/nội dung. Phần đọc bằng chữ mô tả từng ô; không phụ thuộc màu.
- Undo từng thao tác cell/rule/name/resize, giữ tối đa60snapshot. Một stroke mouse
  có nhiều cell nên undo từng cell, **không** hứa undo một stroke nguyên khối.

## 3. Vòng đời bản nháp và kho mẫu

`new/pristine → edited/dirty → saving → saved`.
Lưu lỗi giữ nguyên dữ liệu và không xóa dirty của bản đang sửa. Một bản có thể lưu dù chưa có
đường tới rương: bản nháp không bắt buộc đã giải. Dữ liệu invalid cấu trúc thì
không cho save/test. Lưu thành công update cùngid, không nhân bản mỗi lần.

Kho chỉ giữ trong memory của trang, mất khi reload/navigation; không localStorage,
IndexedDB, SQLite, backend, account import hay sync. “Đã lưu vào kho mẫu” luôn
phân biệt “đã giải mẫu”. Record chưa có proof không đổi thành verified khi mở lại.

- New/load/back khi dirty: **Tiếp tục sửa / Lưu mẫu & tiếp tục / Bỏ & tiếp tục**.
  Cancel/Escape không thực hiện continuation. Lưu thất bại không đi tiếp.
- Bỏ thay đổi khôi phục saved snapshot hiện tại hoặc template mới; không chỉ
  che badge dirty. Về r45 có destination confirmation vì kho RAM sẽ mất.
- Delete: confirmation rõ; xóa active sample thì giữ layout trên bàn thành bản
  chưa lưu, id=null, proof=null; không “tác phẩm biến mất” ngay dưới tay.
- Unknown/loading/error/empty được tách. Retry không ngay lập tức giả vờ đã tải.
  Bộ điều khiển reviewer chọn success/error/deferred response; không phải backend.
- Native beforeunload khi dirty chỉ là hỗ trợ browser; không bảo đảm trình duyệt
  nào cũng cho hiện dialog hoặc lưu được khi đóng tab. Prototype không autosave.
- Khi save pending vẫn có thể sửa. Response khác revision bị bỏ ở phía mẫu và
  yêu cầu lưu lại. Chính sách backend/concurrency thật cần quyết định khi port.

## 4. Check ≠ thử giải ≠ lưu bằng chứng

1. **Kiểm tra đường**: cấu trúc hợp lệ + BFS từS tớiC qua đất. Không lưu, không
   promote proof, không tính rằng ngọc nào cũng reachable. Nếu fail, mở lối hoặc
   chuyển marker; không có nút “force verified”.
2. **Thử bằng khối lệnh**: check→save sample thành công→mở snapshot cố định.
   Nếu save error thì giữ editor, không khởi chạy trên draft chưa lưu.
3. GhépU/D/L/R, mởrepeat2–9, thêm hướng vào body rồi đóng. Không dùng chương trình
   giải tự điền cho editor bình thường; fixturetest_won là tình huống review riêng.
4. **Chạy mẫu JS**: kết quả thực sự tính từ snapshot + program. Outcomeswin/wall/
   water/edge/notThere/tooLong/invalid. Max200moves; nước vào path trước fail,
   tường/edge không; đến rương dừng di chuyển. MộtRobo ở vị trí hiện tại, không để
   ghostRobo ở spawn. Path sau run là dấu vết thử, không hint trước run.
5. Số lệnh đếm toàn bộ chương trình; repeat=1+body length, không expanded moves.
   Sao mẫu khiwin:1 + allGems + withinLimit. Vượt target vẫn có thểwin; zero-gem
   win được allGems, giống tiêu chí source. Không có sao tiến độ được phát.
6. Win chưa làm kho verified. **Lưu kết quả giải mẫu** kiểm tra id/revision/dirty,
   rồi lưu proof sample. Fail cho retry ngay ở result sheet; bản lưu cũ chưa có
   proof không bị giả vờ verified. Dirty proof tạm mang nhãn chưa lưu kết quả.
7. Sửa bất kỳ nội dung/luật/tên nào bỏ proof. Response thuộc bản trước không dùng
   để xác minh bản hiện tại. Fixtures cũng chạy hàm JS để tạo kết quả win, không
   lấy BFS=true để gán verified.

Đây là JS analogue để review interaction, **không port engine** và không chứng
minh parityDart. App thật vẫn cần MazeSimulation/Python/runtime/repository/events
và suite authorized. Model nhận result object trong cùng study, không là security
boundary hay authority có thể tin từ client trong sản phẩm.

## 5. Python surface

Cho nhập chữ nháp và quay về builder; ghi rõ không thực thi, không lưu cùng maze.
Không gắn nút “Run Python” giả, không chuyển chữ thành won bằng parser tự chế.
Source hiện có Code mode thật; đây chỉ là layout/entry study, **không thay thế** nó.
Code draft chỉ giữ trong lượt sheet, mở test mới reset. Textarea/copy/scroll là
controls thật nhưng syntax highlighting, diagnostics, selection toolbar và runtime
keyboard handling chưa được redesign trọn vẹn trongr46.

## 6. Accessibility / locale / evidence

- VI/EN studycontrols không thay settings product: app vẫn system locale mặc định
  và override thủ công đã tồn tại. Không mô tả picker hiện tại là thiếu.
- Scale100/130/200% áp dụng text thật, không chụp một ảnh rồi zoom/shrink.
  Board shape và decorativeicon giữ kích thước vì không phải chữ đọc.
- Targetinteractive>=48px. Checkbox24px có label click area cao>=48px. Board test
  là ảnh ngữ nghĩa không editable, không được tính như touch target.
- Modal có close, focus trap và Escape trả focus opener. Long content cuộn trong
  screen/sheet, không tràn page; ở200% không cố nhét cả xưởng vào một viewport.
- [Browser evidence](evidence/browser-checks.json):20fixtures×2widths×2locales×3scales,
  font proportional assertions, hit bounds và real flows. Không đồng nghĩa đã
  test screen reader, physical device, contrast mọi pixel art hay Flutter.

## 7. Không nằm trong r46

Public publish/share, import/export, remix ownership, multiplayer/collaboration,
server verification, economy/reward/achievement binding, unlimited saves, runtime
schema migration, production tile atlas, anim/rig, new deps, app implementation.
PQC-011 giữ `CHANGES_REQUESTED / WAITING_FOR_PINNED_SDK_EVIDENCE`;018 giữ
`ART_SCOPE_COMPLETE`; R1/R4 không mở. Toàn app vẫn chưa hoàn tất thiết kế/port.
