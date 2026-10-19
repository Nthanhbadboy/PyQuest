# Tutor-first — bảng giảng là trung tâm bài học

## Quyết định sản phẩm từ phản hồi người dùng

Tutor phải dẫn dắt từ đầu, không chỉ là nút trợ giúp hoặc một hộp chat hai người.
Trong bài học Tutor cần **phương tiện giảng giải**: viết, vẽ, nối ý, làm mẫu từng bước
và trao lượt thử lại cho người học. Đây là ưu tiên mới, không phải chỉnh màu transcript.

P02 còn thiếu điểm này. P03 tại `docs/design/tutor-board-prototype/` thử luồng:
**Tutor đón ở làng → mở bảng → chỉ/viết/vẽ từng ý → trẻ khoanh chỗ vướng → tự thử code**.
Đây là prototype HTML theo kịch bản, chưa phải AI hay Flutter implementation.

### Vai trò trong làng

- Tutor chính có chỗ đứng và lời mời rõ; tiếp tục đồng hành khi vào bài học, có thể bỏ
  qua lời chào và xem lại, không ép mic/login. Giữ identity/ngữ cảnh qua chuyển màn.
- Chọn **một mèo ambient đi dạo** ở slice đầu, chưa thêm đám đông người. Không gán mèo
  đó thành Tutor Bitsy hay ngầm đổi roster. Có thể thêm nhân vật nền khi đã có budget.
- NPC không chặn hit area, không kéo camera theo, không phát thoại chen bài, không
  tạo điều kiện phải đuổi/chạm mới được học. Tắt movement khi OS reduce-motion hoặc
  calmMode; pause khi app ẩn/route không hoạt động, không tính simulation nền vô hạn.
- Hình mèo SVG và đường chuyển động P03 là exploration, chưa phải sprite/pathfinding
  production. Không thay map/hitbox theo ảnh concept.

## Lesson workspace thay cho chat-first

| Vùng | Công việc |
|---|---|
|Bảng giảng (chính)|Viết chữ/code/công thức, tô đúng token/dòng, vẽ hình/nhóm vật, mũi tên quan hệ, so input-output. Không chỉ một canvas trống.|
|Tutor + lời giảng|Một ý ngắn gắn đúng điểm trên bảng; biểu cảm/động tác trỏ có nghĩa. Giữ caption khi không có âm thanh.|
|Lượt của trẻ|Sửa/chạy code, chọn/kéo vật hoặc trả lời; runtime bài học quyết định đúng-sai. Không chấm theo lời AI.|
|Đánh dấu chỗ vướng|Bút/marker riêng của trẻ + cách thay thế bằng ghi chú/chọn đoạn cho keyboard/screen reader. Tutor không được xóa nét của trẻ.|
|Điều khiển nhịp|Dừng, trước/sau, xem lại, “chậm lại”, “giải thích cách khác”; không ép xem autoplay mới được làm bài.|
|Hỏi lại/lịch sử|Transcript phụ mở khi cần; vẫn giữ source/role/error/interrupted thật. Không xóa history/voice fixes chỉ vì đổi bố cục.|

Desktop/tablet: board lớn bên trái, Tutor và phần tự thử bên phải. Điện thoại: bố cục
cuộn theo trục dọc, board/code không ép vào một viewport bằng chữ nhỏ; Tutor marker và
caption có ngay trên bảng, lời giải đầy đủ/công cụ thực hành ở dưới. Phải kiểm font lớn,
keyboard insets, focus và scroll-to-error khi port Flutter. P03 chưa chứng nhận tất cả.

## Hai minh họa đã có thật trong P03

Nguồn `app/assets/data/main_quest_ch1.json`, pin code `bb8cced8094d7204498bc002f4571b821f48e711`:

1. `mq1_01_s2`: `print("Xin chào!")`. Highlight print → highlight literal/dấu ngoặc →
   mũi tên nối kết quả không có dấu ngoặc → trẻ thử in `Robo thông minh` từ write step.
2. `mq1_03_s2`: `print(3 + 4)` / `print("3 + 4")`. Vẽ nhóm3 và nhóm4 → gộp7 vật →
   phân biệt phép tính với chữ → trẻ thử đổi dấu ngoặc. Phần thử này là exploration
   của ví dụ, **không** thay bài write/phép nhân/chấm điểm gốc của mq1_03.

Hai kế hoạch bảng là authored fixtures, không phải AI tự sinh. Demo dùng Robo làm
companion minh họa nhất quán; production phải dùng identity đã chọn/CastRegistry theo
spec, không hardcode mọi bài thành Robo hoặc silently đổi Thầy Py/Nova/Ada.

## Kiến trúc cần có: AI đề xuất, renderer thực hiện có kiểm soát

Đã đọc source tại code bb8cced; app/lib không đổi từ review trước:
- `modules/main_quest/lesson_screen.dart::_tutorContext` đã gom context bài học.
- `modules/tutor/tutor_models.dart::TutorReply` hiện có text/source/character/hint và
  metadata lỗi/quota/latency, **chưa có teaching plan/board operations**.
- `modules/tutor/tutor_panel.dart` mở bottom sheet và transcript; không có shared board.
- Các bài đã có example/editor/mô phỏng cục bộ, không cần thay engine chấm để có bảng.

Pipeline đích:
`lesson context + câu hỏi/selection → tutor service → validated TeachingPlan → board renderer`
`                                             ↘ lời giảng/voice có cueId ↗`

### Hợp đồng tối thiểu (proposal, không phải API đã tồn tại)

TeachingPlan có schemaVersion, planId, lessonId, stepId, **contextRevision**, turnId,
characterId, source và danh sách beats có cueId/stable objectIds. Mỗi beat chứa lời
ngắn/altText, các thao tác board được cho phép, và optional waitForLearner.

- Allowlist primitives: text, codeSnippet, highlightToken/line, simpleShape,
  connector, bounded tokenGroup, output, clearTutorLayer. Renderer bố trí trong các
  slot semantic, không yêu cầu AI đoán pixel màn điện thoại.
- P03 chỉ thực hiện subset: code/focus/caption/output/tokens/arrow, ≤12beats,
  ≤8ops/beat, text≤600 ký tự, tokens≤12. Các giới hạn này là prototype budget,
  production cần schema/limit tests riêng; không gọi đây là schema production đã chốt.
- Không render HTML/JS/SVG tùy ý, không tải URL ảnh tự do theo model, không `eval` mã
  từ model; chuỗi là text đã escape. Code mẫu chỉ chạy qua sandbox hiện có khi trẻ
  chủ động chạy, không cho bảng gọi I/O/mic/file/quota/reward trực tiếp.
- Board layers tách **lesson scaffold / Tutor / learner ink**. Nét/gõ của trẻ thuộc
  quyền của trẻ; model chỉ được sửa layer Tutor. Khi đổi frame, lưu annotation theo
  context/beat và có cách quay lại; không để một phản hồi muộn xóa việc đang làm.
- Validate syntax/schema, known lesson/step/object references, size/counts, safety và
  tính nhất quán với kết quả deterministic trước khi phát. Metadata/source không
  được lấy từ câu tự nhận của model. Nếu plan sai, bỏ plan + dùng giải thích/local
  fixture có nhãn thật, không render nửa bảng hỏng hoặc bịa “AI đã chạy code”.
- Responses gắn contextRevision/turnId: đổi bài, sửa code hoặc cancel làm phản hồi cũ
  hết hiệu lực. Barge-in dừng audio **và** board scheduler ở cùng cue; không bắt đầu
  thao tác mới của câu đã bị ngắt. Replay bảng không ghi lại reward/quota.

### Voice không phải hiệu ứng giả

Caption phải dùng được độc lập. Nếu có voice thật, phát board beat theo cue bắt đầu/
kết thúc thực của speech output, không giả đồng bộ bằng timer cố định. P03 autoplay
3.3s chỉ để review visual sequence và được ghi rõ không có âm thanh. Audio lỗi/ngắt
thì bảng giữ trạng thái hợp lệ, có thể đi tiếp thủ công. Không bắt bật micro để học.
Không nới gate device voice từ widget tests/HTML; PQC-004 vẫn cần nghe trên thiết bị.

### An toàn và dữ liệu trẻ em

Context chỉ gồm bài/mục tiêu/attempt cần thiết, không toàn bộ profile/transcript.
Selection/ghi chú/ảnh nét vẽ không tự upload; nêu rõ cái gì được gửi trước khi bật AI.
Không xin PII, không nội dung ngoài độ tuổi, không pressure gắn bó/mua Tutor để được
học tốt hơn. Rate limit/quota/lỗi mạng chuyển sang trợ giúp có nhãn offline, không bỏ
bảng trống. AI không được ghi đè đáp án/chấm/reward/prerequisite hoặc làm hộ bài mặc định.
Không nhúng provider secret vào client hay sample plans.

## Nghiệm thu implementation sau này

1. Với hai fixture nguồn, trẻ thấy Tutor viết/đánh dấu/minh họa gắn lời giảng, không
   phải chỉ thêm một ảnh tĩnh vào chat. Có thể dừng, xem lại, hỏi một chỗ cụ thể.
2. Giữ code, selection, focus/scroll và annotation khi mở/đóng Tutor, thử sai, đổi
   chế độ bảng/chat; response sai revision không được đè lượt hiện tại.
3. Negative cases: plan sai schema/oversize/object id, HTML/URL injection, output sai
   với engine, yêu cầu clear learner layer, response muộn, offline/quota/timeout,
   background, barge-in, hai request trả ngược thứ tự.
4. 360×640/390×844/tablet, font1/1.3/2, keyboard mở; primary targets≥48 logical px;
   altText/traversal và phương án không vẽ. Kiểm Android TalkBack bằng thiết bị riêng.
5. Không thay luật/lesson answers/prerequisites/energy; tests hiện có không bị nới.
6. Làng có ambient life nhưng bảng/Tutor là ưu tiên; đo frame/cache thực, không tuyên
   bố nhẹ vì SVG/WebP ít byte. Main Map vẫn là hub, free play/Creator tùy chọn giữ nguyên.

## Handoff và giới hạn quyền

P03 thay trọng tâm thiết kế bài học, không hủy task regression PQC-009 đang chạy.
Task design PQD-003 giao code đọc/source-map, contract/fixture tests theo phạm vi riêng.
Chưa mở thay runtime/voice/art/dependency toàn app; production cần implementation task
có allowlist sau khi review prototype và hợp đồng. Không đánh dấu “AI giảng trên bảng
đã xong” từ screenshot hoặc timer demo.

## Yêu cầu xuyên suốt: ngôn ngữ

PyQuest phải đa ngôn ngữ, mặc định theo hệ thống và cho đổi/lưu trong Cài đặt.
Áp dụng cho UI, lời Tutor, bài học và bảng giảng; không dịch code, dữ liệu trẻ nhập
hoặc expected output. Đổi locale không mất bài/nét/tiến trình và không phát lại
voice/reply locale cũ. Xem [LANGUAGE_AND_LOCALIZATION.md](LANGUAGE_AND_LOCALIZATION.md)
cho fallback, VI/EN ban đầu, kiến trúc mở rộng và nghiệm thu toàn app. P03/P04 đã có
mẫu tương tác; đây chưa phải bằng chứng Flutter/AI/voice đã đa ngôn ngữ.

## Chốt contract sau phản hồi code — PQD-003 r4

Xem `coordination/reviews/PQD-003-r4.md` cho các quyết định chuẩn mới nhất. V1 authored/
caption-only, lesson-session state ngoài chat sheet, không đặt board trên Main Map.
Content VI/EN của8beat ở `tutor-board-prototype/authored-copy.v1.json`; chưa wire vào
HTML/Flutter semantics. Invalid plan reject nguyên khối; chỉ accept đúng session/
revision/turn, không lấy revision lớn hơn làm điều kiện đủ. Giảm chuyển động không
bỏ beat; chờ learner không timeout nhảy cuối. Đổi locale dừng audio và đổi caption/
altText tại beat đang chọn, giữ code/ink/note. Những điều này còn cần runtime tests.
