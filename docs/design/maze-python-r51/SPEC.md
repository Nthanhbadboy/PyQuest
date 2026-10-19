# r51 · source và đề xuất thiết kế

## 1. Authority

Source pin: `de01a490743982356ad5240d77ea99e9dbf8c7f5`; DESIGN base `ce72fe7`.
Manifest lưu full SHA256 của từng file, excerpts dùng line number tại đúng pin.
Không suy nghiệm thu từ source; r51 không chạy gateway Dart.

| Contract có trong source | Cách thể hiện / ranh giới r51 |
|---|---|
| `startInCode && isCustom`; mode switch chỉ trong custom | R51 đặt trong Workshop; không cấp Python editor cho level thường |
| Màn thường dùng `CodeView(programToPython(...))` | R50 vẫn là block study; không đổi r50 để mở runtime mode |
| CodeEditor dùng controller/selection, auto-indent, helper keys | Native textarea có hành vi tương tự ở mức interaction, không phải port Flutter |
| `services.python.execute` nhận host right/left/up/down, at_chest, gems_left | Guide liệt kê đúng host names; không gọi execute trong browser |
| `ExecutionResult`: success/output/errorLine/errorKind/pythonError | Fixtures minh họa từng trạng thái; nội dung lỗi do DESIGN soạn, không phải engine transcripts thu được |
| Gateway hiện là limited Python-like `SimulatedPythonRuntime`, không CPython | UI nói rõ tập con; JS không xây parser thay thế |
| `codeOk = success || halted`, còn win dựa MazeSimulation | Output bình thường ≠tới rương; HostHalt mẫu thắng không hiện như syntax error |
| Command count là dòng không rỗng/không bắt đầu `#` | Hiện số dòng có lệnh, không gọi là số bước interpreter; Python refs không có source-line mapping nên không giả live trace |
| Workshop lưu trước test; verified chỉ sau report.won thực | Không lưu hay đánh dấu verified bằng fixture `won` |

Nguồn hiện tại đổi từ khối sang Python có thể ghi đè controller. **Giữ hai bản
nháp +xác nhận ghi đè +undo là đề xuất mới**, không phải guarantee sẵn có của app.
R51 giữ Python độc lập với bản khối mẫu tĩnh; không có editor khối thứ hai.

## 2. Editor proposal

- Code là chuỗi người dùng; locale chỉ đổi chrome/copy. Output/raw diagnostic giữ
  nguyên, không dịch code hoặc thay expected output theo ngôn ngữ giao diện.
- Insertion thay selected range, collapsed caret chèn đúng vị trí. `print()` đưa
  caret vào ngoặc; các helper khác đặt sau snippet. Undo/redo lưu code +selection.
- History40 snapshots; giới hạn study **5.000 UTF-16 code units và200 dòng**.
  Vượt giới hạn từ gõ/paste/snippet: từ chối edit, giữ bản cũ và báo; không âm thầm
  cắt code. Đây là giới hạn authoring proposal, không phải RuntimeLimits của Dart.
- Enter giữ số space đầu dòng, thêm4 khi prefix kết thúc `:`; đây là heuristic,
  không hiểu chuỗi/comment/parser. Tab chèn4space; selected-lines Tab/ShiftTab
  indent/outdent; selection kết thúc ở đầu dòng sau không kéo dòng đó vào.
- Esc đưa focus tới “Thêm lệnh” để thoát Tab-indent. Ctrl/Cmd+Z/Shift+Z và
  Ctrl/Cmd+Enter hỗ trợ; keydown có composition không bị heuristic xử lý.
- Font JetBrainsMono; code tự cuộn ngang/dọc, không wrap làm lệch số dòng.
  Gutter cuộn cùng textarea. Mode switch giữ code/caret/viewport; UI font scale
  giữ scroll theo số dòng. Chưa nhận chứng nhận native/mobile editing equivalence.

## 3. Request/result proposal

`begin → pending(token, code, revision, scope) → response` hoặc `cancelled/outdated`.
Chỉ một pending. Khi pending vẫn gõ được, khóa mode switch/replace. Request có
identity tăng dần; chỉnh code/undo tăng revision. Response chỉ được áp khi
pending token hiện hành, code revision và maze scope còn khớp. Cancel tăng token;
callback cũ không render/announce kết quả, không hồi sinh trạng thái đã hủy.

650ms chỉ là độ trễ minh họa. Reviewer hold/manual deliver để tái hiện race;
không đo hay cam kết latency engine. Response nhờ nút bấm được cuộn tới nếu
không đang nhập/chưa mở dialog; không giật focus khỏi textarea đang viết.

Chỉ exact-string lookup cho6 ví dụ trong model. Không dùng eval, Python/WASM,
network hoặc regex để giả lập chạy code. Mã không khớp trả `unavailable`, **không
phải lỗi chương trình**. Không update board position, không animation bước chạy.

`syntax/runtime/unsupported` có line1 authored; nút nhảy chọn đúng dòng, gutter
và aria-invalid chỉ có authority khi revision/scope khớp. Sửa code giữ thông tin
cũ như tham khảo nhưng bỏ current-line marker. `limit` line=null không suy line1.
Raw error có thể mở/đóng; output là text đã escape. Không biến stdout thành HTML.

## 4. Fixtures / visual reference

14 fixtures: draft, syntax, runtime, unsupported, limit, output, won, pending,
cancelled, outdated, edited, unavailable, blocks, long. Reviewer control không
phải navigation app thực. Không ghi preferences/localStorage.

Reference maze6×6, tọa độ dưới đây zero-based (x,y): start(0,0), chest(5,5),
gem(3,4), rows `S..... / .##.#. / ...... / .#.##. / ...*.. / .....C`.
Bản mẫu5right+5down tới rương và bỏ ngọc;4dòng có lệnh ≤mục tiêu mẫu10: minh họa
2/3tiêu chí, **không sinh star/proof/reward record**. Mê cung do DESIGN dựng để
đọc code, không phải lấy runtime screenshot thành layout chính xác.

## 5. UI / navigation / portability

Desktop: reference atelier trái, editor phải; mobile editor trước, scene dưới.
Nút Xem mê cung/Về editor cuộn/focus trong cùng trang. Dialog native có Escape,
focus wrap và trả focus; UI outgoing links mở cảnh báo mất draft RAM. Không có
state bridge hoặc hứa bảo toàn khi reload/browser Back/đóng tab.

Typography scale100/130/200% không co chữ để né overflow. 360×640,390×844,
844×390 test desktop Chromium; nội dung dài cuộn. Touch targets≥44px theo browser
harness, không đồng nghĩa chứng nhận vận động/thị giác/screen reader thiết bị.

## 6. Future runtime gate — chưa giao CODE

Cần order riêng cho editable controller state, token/scope request lifecycle,
engine adapter, actual error/output proof, interruption/disposal, IME/native
undo, host/progress authority, custom-result transaction, native accessibility,
large text/keyboard insets và device evidence. Không đổi interpreter, grader,
reward, events hoặc save protocol trong r51. R1/R4 không tự mở từ spec này.
