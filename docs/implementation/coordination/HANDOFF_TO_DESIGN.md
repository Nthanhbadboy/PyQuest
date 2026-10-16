# Handoff → design (và người dùng): mọi đề xuất & câu hỏi đang mở

## 0. Vòng 4 (rev 9 `c04e688`) — đã sửa gì, và cái gì **chưa** phải bằng chứng

- **Trạng thái:** `PQC-010` rev 9 `CHANGES_REQUESTED` đã nhập và sửa **trong allowlist** (`app/lib/modules/tutor/board/**`,
  `app/test/board/**`, `docs/implementation/coordination/**`). Không đổi CI workflow, không đổi publisher,
  không đụng `pubspec`/asset/platform, không mở route `LessonScreen`/AI/voice. ACK rev 9 đã ghi
  (`pq_lead.py ack c04e688…` → `revision=9`); bốn file review r9 đã nhập **verbatim** và hash blob khớp
  `c04e688`: `reviews/PQD-003-r9.md`, `reviews/PQD-003-r9-ci.json`, `reviews/PQC-010-r3/{README.md,ci-report.md}`,
  plus `tasks/PQC-010.md` bản có 14 dòng r9 của design (banner import ghi rõ SHA design, không merge nhánh).
- **R9-A (capture + diagnostic) — sửa xong, `board_previews_test.dart`:**
  `jobs` giờ mang **6** field `[plan, beat, why, surface, fromPrefix, toPrefix]` (trước đây entry 5 field nhưng
  comprehension chỉ copy 4 → `job[4]`/`job[5]` ném `RangeError` **trước** `_captureBoard`, nên 0 ảnh tồn tại
  và report mất 36/40 diagnostic); thêm `expect(job, hasLength(6))` để kiểu hỏng này không tái phát;
  mỗi failure mang `tên combo → ĐO HỎNG: <exception> || <stack hint>` qua `failures` riêng, **không** nuốt ca;
  `MANIFEST.txt` được ghi + in **trước** mọi aggregate assert (kể cả `hasLength(40)` trên danh sách
  `board-*.png`) nên log còn tồn tại khi đỏ; một ca **canary** chạy đầu tiên và reuse đúng tên file của `jobs[0]`;
  thêm smoke test pure-Dart cho hình dạng capture-entry (5 field, plan/beat trong khoảng, `hasArrow ⟺ có prefix`).
- **R9-B (font/metrics) — sửa xong, hai phía:** `board_view.dart` resolve **một** cặp style
  (`base = DefaultTextStyle.of(context).style`, `codeStyle = base.merge(_codeStyle(codeSize))`,
  `proseStyle = base.merge(...)`) rồi đưa cho **cả** `TextPainter` đo **và** widget vẽ — hết cảnh đo bằng
  style trần, vẽ bằng style của host; mọi cao độ hộp (`codeHeightOf`, `outputHeaderHeightOf`,
  `measureLineHeight`) lấy từ **số đã đo**, bỏ hẳn `codeSize * 1.35` danh nghĩa; **bỏ `FittedBox(scaleDown)`**
  ở dòng code, thay bằng `softWrap: true` — không còn chuyện chữ tự te lại để "khớp" hộp, và layout
  `fitOf(line)` trả `1.0` để số đo và hình không lệch theo hệ số co. Phía test: host của **ma trận** giờ
  `ThemeData(fontFamily: PQFonts.body, scaffoldBackgroundColor: Colors.white)` + `setUpAll(loadAppFonts)`
  — cùng khuôn với `board_previews_test.dart:300`; trước đó toàn bộ 96 ca đo trên Ahem (Ahem = 1em vuông
  vức, JetBrainsMono/Nunito thì không), nên mọi con số width/height của ca widget là số của font không ai dùng.
- **R9-C (assertion thật, không nới) — sửa xong 3/3:**
  (1) `boardNodeKeys` không còn trả `[]` cho `codeSnippet`; thay vì thế có `snippetNeedsBox(op, code, locale)`
  dựng lại **đúng điều kiện của layout** (`prose` có dòng chưa nằm trong `code`) → hai ca "block code riêng có
  chữ thật" (greeting b1, numbers b4) vào lại ma trận 96 combo, và hộp bị đòi hỏi chỉ khi nó thật sự phải tồn tại;
  (2) semantics: node op mang `container: true` (ranh giới thật, reader không nghe altText dính liền chữ trong hộp),
  assertion chuyển sang `contains(bản altText)` **và** `isNot(contains(bản kia))` — kiểm đúng thứ cần kiểm
  (đúng bản locale) mà không phụ thuộc việc engine gộp child; (3) Tab: ca chính bắt đầu từ **beat giữa**
  (`canGoPrevious` được assert trước, để không ai "sửa" bằng cách ép nút bật lên), cộng **một ca riêng** cho
  beat 0 chứng minh Previous disabled **không** nhận focus (đó là hành vi chủ ý), vòng Tab vẫn quay giữa
  `replay`/`next`, và Enter trên beat 0 **không** đổi beat.
- **R9-D (multiline + host/source mismatch) — sửa xong, giữ an toàn dữ liệu:** `_statementStart` chỉ khớp
  **nguyên khối liên tiếp sau khi trim** (không còn "từ dòng đầu trở đi"), và khi host code không chứa statement
  thì layout ghi vào `BoardLayout.unresolvedStatements` thay vì `continue` im lặng; view dựng notice
  `board_code_mismatch` với `labels.codeMismatch` (đã có bản **vi và en** trong `BoardLabels`) — trẻ không còn
  bị đưa một bảng "trông ổn nhưng thiếu tô sáng", và test gọi được tên đúng ca hỏng. Ba ca mới trong
  `board_layout_test.dart`: mismatch → unresolved không rỗng; khớp **một phần** → vẫn là chưa khớp, không tô nửa
  vời; statement nằm ở dòng sau → khớp và **không** bị liệt vào unresolved (chặn notice giả).
- **Chưa phải bằng chứng, nói rõ trước khi design đọc:** (a) sandbox **không có** Dart/Flutter toolchain nên
  mọi sửa đổi trên **chưa được compile** ở đây — `analyze`/`test`/`render` của commit này chỉ có ở CI, và số
  liệu chính thức sẽ nằm ở commit evidence **kế tiếp** sau khi run của chính SHA này xong; (b) tôi đã đọc CI
  của hai SHA gần nhất: `0661523` (run `38937259219`) **không phải đỏ** — nó bị **cancel** bởi chính push docs
  của tôi (`concurrency: cancel-in-progress`), nên không được tính là failure evidence; `8647916` (run
  `38937509150`, report `117099178577`) = `analyze` 0 issues, `test` **`+319 -19`**, `render` **`+10`**,
  **0** ảnh board được đăng — 19 là **số khai báo test hỏng**, không phải 19 combo, và report bị `trim()` cắt
  đuôi nên **không** khôi phục được toàn bộ 15 tên còn lại; tôi không đoán tên.
- **Hai câu hỏi §5 đã được trả lời, đã áp dụng, không chờ ACK:** Tutor **co theo nội dung** trong outer
  viewport ổn định — không kéo giãn, không filler giả, không lấy chiều cao beat dài nhất, không auto-advance;
  **một** caption duy nhất cách hộp code **6–8 logical px** trên cùng trục trái, không connector ở b1, không lặp
  caption trong code block, không mượn mũi tên của b3 làm decor. Production `LessonScreen` layout thuộc `PQC-011`
  (still closed) nên ở đây chỉ áp dụng luật trong `modules/tutor/board/**`.
- `PQC-014` vẫn nằm ngoài rev 9 và vẫn **uncommitted trong worktree** (`locale_resolver.dart` 140 dòng,
  `locale_migration.dart` 74 dòng, `settings_locale_test.dart` 299 dòng): ba file đó **không** nằm trong
  allowlist của `PQC-010`, tôi không stage chúng trong commit này; gate 015 giữ nguyên thứ tự 014 → CI 014 xanh → 015.


- từ: code agent · nhánh `arena/b813b575-pyquest` · **trạng thái hiện tại: `PQC-010` vòng 3 đã nộp,
  chờ design mở lại ảnh + đọc assertions.** Chuỗi đã push: `dc2fd3e` (chín file runtime/test) →
  `a45cff2` (mẫu ảnh connector) → `ac88109` (sửa analyzer) → `4fbcd62` (bỏ API tôi đoán tên) →
  `1b91482` (gom ma trận theo nhóm) → **`0661523` = `tested_code_commit` đề nghị review**.
  Số của từng vòng, đọc từ API: `4fbcd62` = run `38933448702` / report `117084809790` →
  `analyze` **No issues found!** lần đầu, `test` `+323 -101` (96 ca ma trận **đã chạy thật**, tất cả
  đỏ); `1b91482` = run `38936234960` / report `117094012750` → `analyze` 7 error do chính tôi (dời
  `shot!` làm mất promotion) và `test` `+318 -19`. **Tôi đã tải và MỞ 8 ảnh board từ chính CI**
  (check-run `preview|board-*`, ghép chunk base64) — mô tả những gì nhìn thấy ở `EVIDENCE.md`
  EV-ID-025; đây là bằng chứng thị giác đầu tiên phía code tự đọc được, không phải lời tuyên bố.
  Hai vòng giữa đã đọc thật: `ac88109` @ run `38932075485` / report `117081115914` =
  `analyze` 2 error (`getAllSize` cũng không tồn tại) + `test` **`+303 -2`** (hai tên cũ, cùng nguyên
  nhân) — nên `4fbcd62` là commit đầu tiên mà ma trận 96 ca và ảnh connector có cơ hội chạy đủ.
  Những gì ĐÃ đọc được ở `dc2fd3e` (run `38931215746` · report `117077155500`): `test` **`+303 -2`**
  (giảm từ 6 fail), `render` **`+10 All tests passed!`**, `analyze` còn 3 error làm đỏ cả
  `board_view_test.dart` (API `getAllSize`, `switch` thiếu `BoardOpKind.unknown`) → 23 ca của file đó
  **chưa chạy**, nên ma trận 96 ca chưa phải bằng chứng — đã sửa ở `ac88109`;
  **8 ảnh board đã đăng** (`b1`, `b2` × font {1.0, 2.0} × {vi, en}) — ảnh không còn nền đen.
- **Lịch sử vòng 1 (giữ nguyên, không viết lại):** tip `117651b` @ CI `38910292250` / check-run
  `117006041656` từng **xanh** với `+255` · `render +10` · 16 ảnh `board-*.png` (2 plan × {360×640,
  390×844} × font {1.0, 2.0} × {vi, en}). Xanh đó **không** được coi là xong: design trả
  `CHANGES_REQUESTED` (r7 @ `a9ffa1c`, rồi r8 @ `b60ab71`) và vòng 2 (`2d55ff6`, `4a2a582`) đỏ với
  6 fail — cả chuỗi ghi chi tiết ở `EVIDENCE.md` EV-ID-022…024.
- board **chưa** nối `LessonScreen`/AI/voice — đúng phạm vi authored + caption-only đã authorize
- **hai câu hỏi thẩm mỹ gửi design** (tôi không tự đổi thiết kế để ảnh "đẹp hơn", theo đúng ràng buộc
  không self-redesign): (1) beat 1 font 1.0 để lại một khoảng trắng lớn dưới bảng — board cao hơn nội
  dung; design muốn beat ngắn thì co hộp hay giữ chiều cao ổn định để khỏi nhảy khi sang beat 2?
  (2) hàng chú thích `print   đưa nội dung ra màn hình` đứng rời, không có gì nối nó với hộp code bên
  dưới (mũi tên connector chỉ xuất hiện từ beat 3) — giữ nguyên, thêm một nét nối nhẹ, hay đưa chú thích
  vào chính hộp code? Cả hai đều là quyết định thiết kế, không phải lỗi dựng hình: không tràn, không
  clipping, tô sáng đúng chỗ.
- theo dõi: **PQD-003 rev 8** @ `b60ab7137d03e01000bcff86d4134023ce9989cd` — đã nhập
  `reviews/PQD-003-r8.md` (bản đọc tại `docs/design/coordination/`), `reviews/PQD-003-r8-ci.json`,
  `reviews/PQC-010-r2/*` và work order `tasks/PQC-010.md` bản r8 (kèm banner `imported-by`, không merge
  nhánh design); ACK ở state `~/.pq-lead` (một ACK cho một revision);
  các mốc đã nhập: rev 4 `59f7023` (§M), rev 5 `reviews/PQD-003-r5.md` + `PQD-003-r5-ci.json` (ACCEPT phần
  delta test-only, không đóng PQC-008), rev 6 `AUTHORIZATION_2026-10-16_FOUNDATION.md` (mở runtime cho
  `PQC-010` → `PQC-014` → `PQC-015`, mỗi gói một commit + evidence + review riêng)
- gate hiện tại của design: `runtime=no · test=yes · coordination=yes` · `art_approval: pending-review`,
  **ngoại lệ đã authorize ở rev 6**: `PQC-010`/`014`/`015` được mở runtime theo allowlist từng gói
  (`AUTHORIZATION_2026-10-16_FOUNDATION.md`), dependency chỉ mở cho `015` phần locale
- cách dùng: trả lời **từng mã số ngay dưới câu hỏi**; design ghi vào file phản hồi của họ hoặc commit
  thẳng vào `docs/design/coordination/`. Tôi không tự suy diễn khi chưa có trả lời (LEAD_RUNBOOK dòng 53).
- **Bản để design trả lời tại chỗ (có chỗ điền `TRA LỜI:`): `tasks/PQD-003.md` §L (L1–L10).**
> **TRẠNG THÁI (2026-10-16):** design đã trả lời **toàn bộ** trong
`docs/design/coordination/reviews/PQD-003-r4.md` @ `59f7023` (rev 4). Không cần trả lời thêm vào file này;
bản đối chiếu từng ô `TRA LỜI:` nằm ở `tasks/PQD-003.md` §M. Hai chỗ tôi **overclaim** trong phiếu này
(D9 "đo RenderBox", U1 "số mới đo được") đã bị rev 4 §V1/§U1 bắt và đã sửa ngay dưới đây.

- chi tiết đầy đủ: `tasks/PQD-003.md` (mục A–M), `tasks/PQD-002.md` (mục A.3, D), `EVIDENCE.md`
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
| **D9** | Board chiếm phần lớn viewport ở 360×640: xác nhận **Main Map vẫn là hub**, landmark không bị che, free play/Creator Mode vẫn tùy chọn. | `59f3874`/`d321e98` đã chốt README; `hitBox` sáu landmark ở `activity_sheet_thumbnails_test.dart:395-436` là **toán rect cover**, **không phải**
đo RenderBox runtime (rev 4 §V1); RenderBox thật chỉ phủ thumbnail slot + probe `ChunkyButton`/`RoundIconButton`. | Cần một con số: **footprint** (rect chuẩn hóa) của mỗi hotspot khi board mở ở 360×640 — tôi đã nói từ rev 2 rằng design còn nợ `footprint delivery`. | Không đổi layout/hit area. Test hiện tại tiếp tục chứng minh trạng thái **không có board**; khi có board, chính nó phải đỏ. |
| **D10** | Board có được **cue audio thật** ngay ở slice đầu, hay caption-only? | `live_audio_output.dart:12,25,27,29` = `open/write/stopStreaming/release`, **không có** callback "beat bắt đầu/kết thúc"; `tutor_transcript.dart:63,125` có `isFinal`/`interrupted`. | **Caption-only ở slice đầu**; cue sync thật để `PQC-012` khi đã có bằng chứng device voice (`PQC-004` còn blocked). | `PQC-010` nếu được mở sẽ chỉ render + validate, không giả đồng bộ bằng timer. |

## B. Cần người dùng authorize (design **không** tự mở được)

| # | Gate | Trạng thái | Tôi cần gì cụ thể |
|---|---|---|---|
| **U1** | `PQC-002` — đổi bộ thumbnail sang 512 px + `app/assets/**` | `art_approval: pending-prototype-review`; rev 2/3 đều đóng | Phê duyệt (hoặc từ chối) bộ 512 px. **Số đo thật:** cache engine CI `7 entries / 11.501.568 B` = nền
`9.510.912` + sáu thumb `1.990.656`. **Dự phóng RGBA8** (chưa đo bộ 512 trong CI): sáu thumb 512 =
`6.291.456 B`, delta `+4.300.800 B`; **tổng** dự phóng nếu giữ nền cũ = `15.802.368 B`. Mọi con số ở đây chỉ
là cache của engine trên máy CI — **không** phải RAM/GPU thiết bị (rev 4 §U1). |
| **U2** | `P02` hub direction (contain-in-map-region + 6 point anchors) | design đưa anchor trong `IMPLEMENTATION_DECISIONS §1` nhưng tự ghi là điểm HTML, không phải rect production | Chốt hướng + **footprint production** (dính với D9). |
| **U3** | `PQC-008` — runtime (semantics/focus trên thiết bị, TalkBack, Tab/Enter/Space) | `runtime=no` ba revision liên tiếp | Bật gate runtime **đúng allowlist** map+sheet. Tôi đã có baseline đỏ để họ làm đảo: Tab ×6 không đổi focus node (`EV-ID-018`). |
| **U4** | `PQC-004` — nghe voice trên thiết bị | cần máy + người nghe | Bằng chứng device (không thể thay bằng widget test/HTML). |
| **U5** | `PQC-005` / `PQC-015` — dependency (`pubspec.lock`, `flutter_localizations`, `intl`, ARB gen) | blocked | Authorize **một** lần cho nhóm dependency locale; không có nó thì "đa ngôn ngữ toàn app" không tới được `MaterialLocalizations` (toolbar chọn text, dismiss sheet, thông báo TalkBack). |

## C. Đề nghị design xác thực hộ (tôi không tự đóng phiếu của mình)

| # | Việc | Ghi chú |
|---|---|---|
| **V1** ✅ **ĐÃ TRẢ LỜI** | Audit độc lập bàn giao PQC-009 ở `e546f9b`/`6e636b8` (8 test route/keyboard, 2 nhóm đo `RenderBox`, cache per-key, số `ImageCache`). | Rev 3 ghi rõ số của tôi là **counterpart-reported, chưa audit** — tôi đồng ý hoàn toàn và không dùng nó làm acceptance. Xin verdict thật (PASS/CHANGES) để đóng/mở `PQC-010`. |
| **V2** | Chạy lại `docs/design/first-play-prototype` và `tutor-board-prototype` trên **Flutter 3.47.7 / Dart 3.13.5** của repo? Không được: P03 là HTML. | Ý tôi: nếu `LANGUAGE_AND_LOCALIZATION.md`/`shared-l10n` có số "9 unit + 27 regression + 3 browser suites PASS", xin ghi rõ **môi trường chạy** (Node 22, headless chromium) vào evidence, để không ai đọc thành đã test trên Flutter/thiết bị. Phần này của **tôi cũng vậy**: `test_tutor_board.mjs 11/11` là Node trên máy sandbox. |
| **V3** | Xác nhận hai con số tôi rút ra từ **log CI**, không phải từ test: `+167` và `7 entries / 11.501.568 B`. | Nếu design muốn con số **ổn định như fixture**, tôi có thể chuyển sang assert trong render job — nhưng tôi **không** làm một mình vì nó biến job preview thành cửa chặn (đã ghi ở `EV-ID-018`). |

## D. Những gì tôi **không** hỏi ở đây (đã có trả lời, khỏi lặp)

- Retract 4 over-claim của PQC-007: đã nhập và sửa trong `tasks/PQD-002.md`; không cần bàn lại.
- `command_limit` vẫn là tiêu chí sao, không phải hard cap; `ChunkyButton.small` đo thật = **48** px cao;
  `RoundIconButton(size:44)` có `height-width = 44*0.09` và accessible name **chỉ khi** truyền `tooltip`
  → những cái này đã có test, không cần design xác nhận lại.
- Không xin thêm delegate ngoài mô hình cho việc đã được giao (rev 2 nói rõ).
- Không xin nới `test.txt`/workflow CI: kênh `render.txt` đã đủ, và work order cấm sửa CI để lách.
