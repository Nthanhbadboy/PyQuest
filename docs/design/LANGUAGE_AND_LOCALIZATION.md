# PyQuest — Ngôn ngữ toàn app

Ngày: 2026-10-16. Yêu cầu người dùng: **đa ngôn ngữ; mặc định theo hệ thống;
có thể đổi trong Cài đặt**. Đây là yêu cầu sản phẩm xuyên suốt, không chỉ một toggle
cho hội thoại. Mẫu HTML P03/P04 là evidence thiết kế lịch sử.

**Cập nhật2026-10-17:**014service và015Flutter foundation đã ACCEPTED;015 tại556f92d/
run39021843114 (394ordinary+10render), không phải app đãdịchtoàndiện. Lead đã mở016
Settings system/VI/EN và localizedSettings surface theo PQD-003r29; spec/copy ở
coordination/specs/PQC-016-settings.md và PQC-016-copy.json. Các phần “chưatriểnkhai”
trong ghi chú lịch sử bên dưới không phủ nhận acceptance foundation hiện tại.

## 1. Hành vi thống nhất

- Lần mở đầu: **Theo hệ thống**. Không suy ngôn ngữ từ GPS/IP/quốc gia, không hỏi trẻ
  trước khi vào chơi và không mặc định tiếng Việt cho mọi thiết bị.
- Cài đặt → Ngôn ngữ: **Theo hệ thống / Tiếng Việt / English** trong gói đầu tiên.
  Tên ngôn ngữ dùng cách tự gọi của nó (autonym), không dùng quốc kỳ. Hiển thị thêm
  ngôn ngữ đang có hiệu lực; tùy chọn system khác với ngôn ngữ đã được resolve.
- Danh sách đầu tiên VI/EN là lựa chọn triển khai, không phải giới hạn sản phẩm mãi
  mãi hoặc tuyên bố người dùng đã chốt mọi ngôn ngữ. Chỉ liệt kê pack đã hoàn chỉnh,
  được review; thêm pack không thêm nhánh if/else rải khắp màn hình.
- Duyệt danh sách ngôn ngữ OS theo ưu tiên, chuẩn hóa BCP47, chọn ngôn ngữ hỗ trợ đầu
  tiên. `vi-VN` → vi; `en-GB` → en; `[fr-FR,vi-VN,en-US]` → vi. Không có ngôn ngữ phù
  hợp → **English**, có thông báo fallback trong Settings. Không giả hỗ trợ ja/zh/ko.
- Chọn thủ công áp dụng ngay, lưu qua lần mở lại; thay đổi OS không ghi đè lựa chọn
  này. Chọn lại **Theo hệ thống** khôi phục theo dõi OS. OS đổi khi app đang mở hoặc
  app resume thì cập nhật nếu đang system; không ghi effective locale thành override.
- Pref hỏng/không tồn tại → system. Lỗi lưu: vẫn dùng lựa chọn trong phiên, báo không
  lưu được; không tuyên bố đã lưu thành công. Chỉ lưu preference, không cần gửi vị trí.
- Đổi ngôn ngữ không reset màn đang mở, tuyến đi, beat, code, ghi chú, nét vẽ,
  progress/energy/rewards. Không bắt reload ứng dụng để áp dụng.

## 2. Phạm vi: không chỉ dịch nút

| Lớp | Yêu cầu |
|---|---|
| Toàn bộ UI | Onboarding, map, lựa chọn Tutor, Settings, bài học, mọi hoạt động, achievement, recap, paywall/parental flows, loading/empty/error/retry, accessibility labels, thông báo và xác nhận. Inventory cả màn hiện có lẫn chưa redesign. |
| Thế giới | Tên địa điểm, mô tả, lời mời và NPC bubbles; giữ ID nội bộ, identity roster và tên riêng theo quy ước nội dung. Không đổi luật mở khóa theo ngôn ngữ. |
| Bài học | Tiêu đề, hướng dẫn, hints, giải thích đáp án, board captions/diagrams/transcript; pack theo lesson ID/step ID ổn định, không copy một dataset rồi tự sửa đáp án. |
| AI Tutor | Effective locale đi cùng turn context + board plan. Cùng giọng điệu thân thiện, ngắn, đúng lứa tuổi ở cả hai ngôn ngữ; không chỉ dịch lời chào rồi trả lời dài bằng ngôn ngữ khác. |
| Voice | TTS chọn voice hỗ trợ đúng ngôn ngữ. Không có voice phù hợp → giữ chữ/bảng, báo voice chưa có bằng ngôn ngữ UI, không đọc tiếng Việt bằng voice English và gọi là hỗ trợ. |
| A11y/format | Semantics, số đếm/plurals, ngày giờ, đơn vị theo locale; bàn phím/focus, dấu tiếng Việt, text scaling. Không bake chữ UI vào tranh. |

**Không dịch âm thầm** code Python, identifiers, syntax, chuỗi literal của chương
trình, expected outputs hoặc dữ liệu người học tự nhập. Raw error/trace có thể giữ
nguyên; phần giải thích lỗi cho trẻ phải được bản địa hóa. Không để AI quyết định
lại validator/đáp án chỉ vì người học đổi ngôn ngữ.

Mẫu hiện dùng source exercise có literal `Xin chào!` và mục tiêu `Robo thông minh`.
English giải thích literal đó, không thay bằng `Hello!` rồi khiến grader sai. Muốn
có bộ ví dụ theo ngôn ngữ phải soạn/review cùng expected outputs và kiểm parity;
không đổi dataset/chấm điểm trong một patch dịch giao diện. Ghi chú/tin nhắn cũ của
trẻ được giữ nguyên; không dịch lại lịch sử hoặc tự viết lại nội dung của trẻ.

## 3. Contract production cho agent code

1. Một `LanguagePreference` và `effectiveLocale` tập trung; locale là đầu vào cấu
   hình của app/MaterialApp, `supportedLocales` và delegates, không mỗi widget tự
   đọc SharedPreferences. Dùng stable message IDs + Flutter ARB/ICU/gen_l10n (hoặc
   giải pháp tương đương có kiểm coverage), không port DOM text matching từ mẫu.
2. Lưu mode system/explicit riêng với giá trị đã resolve. Migration phải phân biệt
   **raw key cũ `ui_lang` thật sự có giá trị hợp lệ** và getter cũ mặc định vi. Giữ
   lựa chọn vi/en đã lưu; key cũ không tồn tại không được biến thành explicit vi.
   Invalid legacy value → system. Đề xuất key/version và test migration trước port.
3. Inventory strings/lesson content/semantics; catalog có message hoàn chỉnh và
   typed placeholders, không nối mảnh câu theo thứ tự tiếng Việt. CI phát hiện key
   thiếu/placeholder mismatch. Fallback English là lưới an toàn, không lý do ship
   một pack thiếu nửa màn hình. Nội dung bài offline có pack đi kèm.
4. Mỗi turn Tutor/TeachingPlan mang locale + contextRevision. Locale đổi: dừng
   playback/voice cũ, cancel hoặc loại bỏ reply/board/audio stale, giữ learner layer
   và bài đang làm; câu trả lời mới dùng locale mới. Không reset beat như mở bài mới.
   Board allowlist/safety không nới vì dịch; locale/prompt không cho model chấm bài.
5. TTS/STT capability khác UI capability. Kiểm voice per language và offline/network
   errors; không đổi mic permissions, provider/key/roster để lách thiếu voice. Chữ và
   board luôn dùng được, kể cả khi voice chưa hỗ trợ.
6. Theme/fonts/layout phải đủ glyph và co giãn. Mẫu chỉ chứng minh LTR VI/EN. Thêm
   script mới/RTL cần fonts, bidi/code LTR isolation và kiểm layout riêng; không
   quảng cáo hỗ trợ RTL hay mọi ngôn ngữ khi chưa có pack và tests.

**Baseline kiểm tra:** `app/lib/core/settings_service.dart` đọc `ui_lang`;
`app/lib/shared/l10n/pq_l10n.dart` hiện hỗ trợ một phần cast/Tutor và mặc định vi.
Phần UI khác vẫn nhiều copy Việt viết cứng. Không coi hai file đó là bằng chứng app
đã đa ngôn ngữ toàn diện. Code agent phải kiểm lại source ở SHA của nhánh mình.

## 4. Nghiệm thu production (chưa đạt bằng chứng Flutter)

- Resolver: vi/en, regional tags, ưu tiên nhiều locale, unsupported, empty/invalid,
  system change và explicit override, migration/key hỏng/storage error.
- UI: lần cài sạch theo OS; Settings đổi ngay, lưu qua relaunch, trở lại system;
  tất cả màn/semantics/error states bằng VI và EN, không còn hardcode bất ngờ.
- State: đổi ngôn ngữ trong lesson/board/travel/chat không mất input/ink/beat/route;
  engine output/validator/progress không đổi. Không phát reply/voice locale cũ.
- Content: coverage/placeholder/ICU, bản dịch có review đúng lứa tuổi, source lesson
  IDs/parity, offline copy, Tutor prompt locale và board caption locale.
- Device evidence: Android thật/emulator ở VI/EN, OS-change/resume, text scale 2.0,
  TalkBack/focus, phone nhỏ và TTS hỗ trợ/không hỗ trợ. Browser screenshot không thay thế.

## 5. Đã làm ở nhánh design / ranh giới bàn giao

`shared-l10n/README.md` ghi implementation, cách chạy và bằng chứng thật. P03/P04 có
Settings, VI/EN cho giao diện/lời Tutor soạn sẵn/bảng, đồng bộ parent–iframe và
preference-only persistence. Test browser/Node không gọi AI/voice, không chứng minh
app Flutter hay mọi lesson của sản phẩm đã có bản dịch.

PQD-003 revision 3 nhận yêu cầu này vào board contract ngay từ đầu. Code agent lập
allowlist/migration/test plan cho foundation locale trước khi mở runtime work order;
không đợi redesign mọi màn xong mới nghĩ tới localization, không trộn rewrite toàn
app với NPC engine. Giữ PQC-009 delivery; PQC-008 và các gate khác không tự mở.

## Làm rõ sau source review263033a

Getter `lang` mất phân biệt unset/explicit, nhưng raw storage không mất: SettingsService
vẫn có `raw(key)` và load map từ repository. Migration đọc raw, không hỏi người dùng
chọn một chính sách làm mất system default. Xem quyết định D6–D8 trong
`coordination/reviews/PQD-003-r4.md`: English fallback, supported BCP47 tags + adapter
cho enum cũ, delegates/generation trước port ARB UI, lesson translation overlay không
copy grader. Caption/altText authored đổi ngay ở beat hiện tại khi đổi ngôn ngữ.
