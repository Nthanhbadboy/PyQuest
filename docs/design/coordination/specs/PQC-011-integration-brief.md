# PQC-011 — lesson-board integration: brief chuẩn bị của Lead

Ngày2026-10-18. **DRAFT, chưa READY_FOR_CODE.** Owner/next actorDESIGN.
Source đọc tại a9bcdcf8e3203ee17b1a5de0b9ebff6a0e8dd32d;010/014/015/016 đãaccepted.
Lead tự chốt thiết kế tiếp theo, không hỏi user chọn roadmap và không giao Code một
allowlist mơ hồ. Đây là handoff cho lượtDESIGN kế tiếp, không phải quyền sửa runtime.

## Mục tiêu sản phẩm

Đưa bảng giảng đã nghiệm thu vào lesson thật, để Tutor không chỉ hiện khung chat.
Bước đầu nối hai example có authored plans đã kiểm; giữ rõ authored/caption-only,
không gọi đó là AI-generated board hoặc đồng bộ giọng nói. Không làm mất entryTutor
AI đang có. Hoàn thành lát cắt thật rồi mở tiếp011/012/013 theo contract, không biến
hai ví dụ thành tuyên bố bảng đã hỗ trợ toàn bộ lesson.

## Source facts đã đọc

- app/lib/modules/main_quest/lesson_screen.dart sở hữu index/step/input/run/feedback;
  _prepareStep reset per-step state; _next chuyển bước; dispose hiện chỉdisposecode.
- _openTutor gọi showTutorPanel với TutorContext từ lesson và CastRegistry.tutorForSkill
  theo actuallesson.skill. Chưa có BoardController hoặc BoardView ởLessonScreen.
- BoardController có lessonId/stepId final, contextRevision/turnId/sessionId guards;
  learner layer thuộccontroller; setLocale giữbeat/learner, dispose invalidate latework.
  Không có quyền tự ghi progress/score/energy/reward; integration phải giữ boundary đó.
- BoardView/BoardLabelsVIEN đãaccepted độc lập. BoardPrev/Next/Replay là beatcontrols,
  không được biến thành lessonNext/markSolved.
- app/test/board/fixtures/board_plans.v1.json và
  app/test/fixtures/tutor_board/authored-copy.v1.json là **fixtures**, chưa runtimeassets.
  Hai supportedsteps: mq1_01_s2 code print("Xin chào!"); mq1_03_s2 code
  print(3 + 4) newline print("3 + 4"). Không dịch code/output literals.
- board_test_support.dart compose copy/ops, registeredObjects giả lậphost và reference
  từ engine thật; helper dùng dart:io/flutter_test. **Không import testhelper vào app**
  hoặc tin registeredObjects/output tự khai trong payload là source of truth.

## Lead cần chốt trong lượt tiếp theo

1. Đọc tiếp lessonstepmodels/actualdataset/boardcodec+validator và các regressiontests;
   đối chiếu cảpack provenance/contentmap. Không dựa chỉ vào tóm tắt tênfile ở đây.
2. Chọn entry/layout cho bảng trên ExampleStep: mobile/keyboard/scroll, Tutoridentity,
   authored badge, beatcaption/Prev/Next/Replay, learnernote/ink hiện có. Giữ callable
   TutorAI route, không mở voice wiring hoặc ép thay chat provider.
3. Định nghĩa ownership perlesson/perstep, open/close/reopen/switchlocale/back/exit;
   board không nằm trong ephemeral chatsheet. Không reset editor/input hoặcgraderstate.
4. Production loader/asset strategy cho2plans+copy, validate trướcapply; registered
   IDs từ scaffold host, actualcode/reference từ engine/lesson trusted. Fallback an
   toàn cho step chưa cópack, malformed/staleplan; không tạo execution từ untrustedplan.
5. Author chính xác allowlist, lifecycle hooks và testmatrix: actualLessonScreen,
   preservation/reopen/locale, no-score/no-reward-onboardnavigation, stale disposal,
   safe fallback, baseline406ordinary+10render. Không kéo thêmdeps/CI/SDK.
6. Publish workorder011READY_FOR_CODE + spec trước khi chuyểnCODE. Nếu thiếuproof,
   Lead tiếp tục tự nghiên cứu; không vòngACK hoặc hỏi userchọn hộtask.

## Giới hạn đã quyết định

Không engine/grader/lessonanswers/schema/economy/social/voiceprovider changes trong
lát cắt đầu. Không đổi BoardValidator safeguards để nhậnplan không hợp lệ. Không
hứa vẽ tự do/AIplanning/voice sync đã làm nếu bản011chỉ gắn authoredboard hiện có.
Giữ tầm nhìn TutorAI có bảng và toànapp; scope nhỏ là trình tự triển khai, không hạ
mục tiêu thành demo hoặc thay người dùng bằng khách xemảnh.
