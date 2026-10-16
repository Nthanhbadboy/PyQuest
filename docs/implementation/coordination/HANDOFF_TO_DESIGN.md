# Handoff → design (và người dùng): mọi đề xuất & câu hỏi đang mở

- từ: code agent · nhánh `arena/b813b575-pyquest` · tip khi viết: `c828ad4` (CI `38892233871` xanh:
  `analyze` No issues · `test +167` · `render +10`)
- theo dõi: **PQD-003 rev 3** @ `9172ecdb4c042c21ff9d5b8776676427690f9d07` (đã ACK, `unprocessed notes: 0`)
- gate hiện tại của design: `runtime=no · test=yes · coordination=yes` · `art_approval: pending-review`
- cách dùng: trả lời **từng mã số ngay dưới câu hỏi**; design ghi vào file phản hồi của họ hoặc commit
  thẳng vào `docs/design/coordination/`. Tôi không tự suy diễn khi chưa có trả lời (LEAD_RUNBOOK dòng 53).
- **Bản để design trả lời tại chỗ (có chỗ điền `TRA LỜI:`): `tasks/PQD-003.md` §L (L1–L10).**
- chi tiết đầy đủ: `tasks/PQD-003.md` (mục A–K), `tasks/PQD-002.md` (mục A.3, D), `EVIDENCE.md`
  (EV-ID-016…020). File này chỉ là **bảng hỏi-đáp gộp**, không thay thế các mục đó.

## A. Cần design quyết (không đụng quyền người dùng)

| # | Câu hỏi | Bằng chứng tôi đã đọc | Đề xuất của tôi | Nếu im lặng, tôi làm gì |
|---|---|---|---|---|
| **D1** | Bảng giảng: **v1 authored-only** (fixture đóng gói) hay **v2 plan-channel** (provider/relay trả plan có schema)? | `tutor_provider.dart:31` hardcode `'max_tokens': 700`; `TutorProvider.complete` chỉ trả `Future<String>`; `TutorReply` không có field plan. Ngân sách P03 (≤12 beats × ≤8 ops × caption ≤600 ký tự) **không vừa** 700 token. | **v1 authored-only** cho slice đầu: nghiệm thu được renderer + scheduler + validator mà không đụng provider, không có đường model-injection, không đổi quota. | Chờ. **Không** code board trong `app/lib`; **không** nhét JSON vào `TutorReply.text` (đi vòng validator, và `source` sẽ do model tự khai). |
| **D2** | Board nằm ở đâu trong cây widget: **shared state trên `PyQuestApp`** hay cùng route với `LessonScreen`? | `tutor_panel.dart:23-36` → `showPQSheet` → `showModalBottomSheet` (`shared/widgets/common.dart:309-311`): panel là **route, bị destroy khi đóng**; keyboard inset xử lý ở `:317-319`. | Shared state **ngoài** sheet. Điều kiện nghiệm thu 2 của chính thiết kế ("bảng không mất khi chat/keyboard mở") không đạt được nếu board sống trong sheet. | Ghi nhận là **rủi ro thiết kế chưa chốt**; `PQC-010` (renderer cho fixture) vẫn làm được độc lập vì nó không cần biết board đặt ở đâu. |
| **D3** | `waitForLearner`: trẻ không tương tác thì **giữ nguyên beat** hay tự nhảy beat cuối? | Demo P03 dùng timer 3,3 s; README của họ tự ghi "không giả là đồng bộ giọng nói". | **Giữ nguyên beat**, chỉ đi tiếp khi có thao tác hoặc người dùng bấm tiếp. Timer cố định không được thành quy tắc production. | Mặc định theo tài liệu của họ (giữ beat), không code gì thêm. |
| **D4** | `altText` của beat authored: design **viết tay từng beat**, hay generator rồi review? | §F của tôi có case "`altText` rỗng → loại beat"; prototype `engine.mjs` **không** có case này (tôi kiểm khi chạy `test_tutor_board.mjs` 11/11). | Viết tay. Board là phương tiện giảng, không phải trang trí; altText sinh bằng model rồi duyệt = thêm một vòng QA + một đường injection. | Nếu P03 không có altText cho 2 beat demo → **PQC-010 sẽ fail validation by design** (rule 6 §B), và đó là chủ ý, không phải bug. |
| **D5** | Prototype P03 có **2 hở** so với contract production: `engine.mjs` không có khái niệm `contextRevision`; learner-ink chưa có đường tấn công thật (prototype không nhận input từ model). | `tasks/PQD-003.md` §J.1/§J.2. | Xác nhận đây là **giới hạn demo**, không phải "đã xử lý"; 2 case phải có test riêng khi `PQC-013`/`PQC-014` mở. | Đã ghi thành yêu cầu test; không tự vá hộ sang production. |
| **D6** | Di sản `ui_lang`: giá trị cũ trong storage là **explicit** hay **unset**? | `settings_service.dart:42,44` lưu một khóa; `pq_l10n.dart:23-24` `fromCode(null) → vi` → **hai trạng thái cho ra cùng một kết quả**, không đọc ngược được. | Đề xuất coi là **explicit**. Lý do: âm thầm bật "theo hệ thống" cho người đã chọn Tiếng Việt là lỗi với trẻ; bỏ lỡ system default chỉ là chưa bật tính năng. | Không đổi resolver, không tạo migration. `PQC-014` đứng nguyên; mọi việc liên quan locale đứng nguyên. |
| **D7** | `PqLang` (enum 2 giá trị) có được thay bằng **chuỗi BCP-47** ngay ở `PQC-014`, hay giữ enum + map? | `PqStrings.of(lang) => lang == vi ? vi : en` (`pq_l10n.dart:35`); voice `language == 'vi' ? 'vi-VN' : 'en-US'` (`gemini_live_wire.dart:284`) — mọi chỗ "không vi" đều rơi vào `en-US`. | Đổi sang BCP-47 **ngay**, nếu không mỗi language pack mới lại phải sửa enum trong `app/lib` (runtime gate lại phải mở lần nữa). | Đề xuất giữ nguyên trên giấy; `PQC-014` chưa có quyền. |
| **D8** | `PQC-017` (lesson song ngữ): sửa **schema** `main_quest_ch1.json` (thêm `*_en`), hay design xuất bản `main_quest_ch1_en.json` tách? | Lesson keys hiện tại `challenge/id/number/py_line/skill/summary/steps/title`, step `code/id/text/type` — **không** có cặp ngôn ngữ → nội dung bài đang đơn ngữ thật sự. | File tách theo locale, loader chọn; `code`/`expectedOutput` **không** được dịch và bản dịch của `expectedOutput` phải là **lỗi build** (test chặn). | Không chạm `app/assets/**` (đang blocked). |
| **D9** | Board chiếm phần lớn viewport ở 360×640: xác nhận **Main Map vẫn là hub**, landmark không bị che, free play/Creator Mode vẫn tùy chọn. | `59f3874`/`d321e98` đã chốt README; `hitBox` sáu landmark đã có test `RenderBox` (≥48×48 sau crop) ở `activity_sheet_thumbnails_test.dart`. | Cần một con số: **footprint** (rect chuẩn hóa) của mỗi hotspot khi board mở ở 360×640 — tôi đã nói từ rev 2 rằng design còn nợ `footprint delivery`. | Không đổi layout/hit area. Test hiện tại tiếp tục chứng minh trạng thái **không có board**; khi có board, chính nó phải đỏ. |
| **D10** | Board có được **cue audio thật** ngay ở slice đầu, hay caption-only? | `live_audio_output.dart:12,25,27,29` = `open/write/stopStreaming/release`, **không có** callback "beat bắt đầu/kết thúc"; `tutor_transcript.dart:63,125` có `isFinal`/`interrupted`. | **Caption-only ở slice đầu**; cue sync thật để `PQC-012` khi đã có bằng chứng device voice (`PQC-004` còn blocked). | `PQC-010` nếu được mở sẽ chỉ render + validate, không giả đồng bộ bằng timer. |

## B. Cần người dùng authorize (design **không** tự mở được)

| # | Gate | Trạng thái | Tôi cần gì cụ thể |
|---|---|---|---|
| **U1** | `PQC-002` — đổi bộ thumbnail sang 512 px + `app/assets/**` | `art_approval: pending-prototype-review`; rev 2/3 đều đóng | Phê duyệt (hoặc từ chối) bộ 512 px. **Số mới đo được, không phải ước đoán:** cache engine CI hiện `7 entries / 11.501.568 B`, khớp đúng `9.510.912` (nền 1152×2064 RGBA8) + 6×`331.776`; bộ 512 px sẽ là `6.291.456 B` (**+4.300.800 B ≈ +4,10 MiB** trong cache của engine trên máy CI) — **không** phải RAM/GPU thiết bị. |
| **U2** | `P02` hub direction (contain-in-map-region + 6 point anchors) | design đưa anchor trong `IMPLEMENTATION_DECISIONS §1` nhưng tự ghi là điểm HTML, không phải rect production | Chốt hướng + **footprint production** (dính với D9). |
| **U3** | `PQC-008` — runtime (semantics/focus trên thiết bị, TalkBack, Tab/Enter/Space) | `runtime=no` ba revision liên tiếp | Bật gate runtime **đúng allowlist** map+sheet. Tôi đã có baseline đỏ để họ làm đảo: Tab ×6 không đổi focus node (`EV-ID-018`). |
| **U4** | `PQC-004` — nghe voice trên thiết bị | cần máy + người nghe | Bằng chứng device (không thể thay bằng widget test/HTML). |
| **U5** | `PQC-005` / `PQC-015` — dependency (`pubspec.lock`, `flutter_localizations`, `intl`, ARB gen) | blocked | Authorize **một** lần cho nhóm dependency locale; không có nó thì "đa ngôn ngữ toàn app" không tới được `MaterialLocalizations` (toolbar chọn text, dismiss sheet, thông báo TalkBack). |

## C. Đề nghị design xác thực hộ (tôi không tự đóng phiếu của mình)

| # | Việc | Ghi chú |
|---|---|---|
| **V1** | Audit độc lập bàn giao PQC-009 ở `e546f9b`/`6e636b8` (8 test route/keyboard, 2 nhóm đo `RenderBox`, cache per-key, số `ImageCache`). | Rev 3 ghi rõ số của tôi là **counterpart-reported, chưa audit** — tôi đồng ý hoàn toàn và không dùng nó làm acceptance. Xin verdict thật (PASS/CHANGES) để đóng/mở `PQC-010`. |
| **V2** | Chạy lại `docs/design/first-play-prototype` và `tutor-board-prototype` trên **Flutter 3.47.7 / Dart 3.13.5** của repo? Không được: P03 là HTML. | Ý tôi: nếu `LANGUAGE_AND_LOCALIZATION.md`/`shared-l10n` có số "9 unit + 27 regression + 3 browser suites PASS", xin ghi rõ **môi trường chạy** (Node 22, headless chromium) vào evidence, để không ai đọc thành đã test trên Flutter/thiết bị. Phần này của **tôi cũng vậy**: `test_tutor_board.mjs 11/11` là Node trên máy sandbox. |
| **V3** | Xác nhận hai con số tôi rút ra từ **log CI**, không phải từ test: `+167` và `7 entries / 11.501.568 B`. | Nếu design muốn con số **ổn định như fixture**, tôi có thể chuyển sang assert trong render job — nhưng tôi **không** làm một mình vì nó biến job preview thành cửa chặn (đã ghi ở `EV-ID-018`). |

## D. Những gì tôi **không** hỏi ở đây (đã có trả lời, khỏi lặp)

- Retract 4 over-claim của PQC-007: đã nhập và sửa trong `tasks/PQD-002.md`; không cần bàn lại.
- `command_limit` vẫn là tiêu chí sao, không phải hard cap; `ChunkyButton.small` đo thật = **48** px cao;
  `RoundIconButton(size:44)` có `height-width = 44*0.09` và accessible name **chỉ khi** truyền `tooltip`
  → những cái này đã có test, không cần design xác nhận lại.
- Không xin thêm delegate ngoài mô hình cho việc đã được giao (rev 2 nói rõ).
- Không xin nới `test.txt`/workflow CI: kênh `render.txt` đã đủ, và work order cấm sửa CI để lách.
