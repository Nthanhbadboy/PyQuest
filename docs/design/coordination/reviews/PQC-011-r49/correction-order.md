# CODE correction — PQC-011 r49, bounded execution order

**Base:** `de01a490743982356ad5240d77ea99e9dbf8c7f5`.
**Evidence:** run39078131829 / source check117529542022 / workflowca29dd1.
**Authority:** người dùng cho phép dùng GitHub Actions; DESIGN giao correction
sau thực thi thật. Không tiếp tục lấy “chưa có SDK” làm blocker. Không ACK-only.

## 1. Thay đổi có ngữ nghĩa duy nhất

`app/test/lesson_board_integration_test.dart`: sửa test orchestration để cả7case
đi qua `_mountLesson` và kiểm tra thật. Hiện cả7fail `pumpAndSettle timed out`
tại line470. Điều tra scheduled frames/async và readiness; dùng bounded pumps
với predicate có nghĩa hoặc real-async completion đúng chỗ, không tăng timeout,
không blanket-ignore exceptions, không thay route thật thành widget cô lập.

Giữ nguyên scope011 và mọi assertions: rootBundle thật/happy path, Run→Continue,
không phát grading/progress events, bảo toàn owner/editor/learner state, locale,
360×640 &390×844 VI/EN/2×, late completion sau đổi step/unmount và controller
ownership. Không skip/delete/giảm test hoặc thay negative path thành happy path.

Runtime files trong §2 chỉ được formatter sửa. Nếu bằng chứng mới chứng minh
cần runtime semantic fix, trả repro/diff đề xuất trước; không tự mở scope.

## 2. Formatter-only allowlist (Dart3.13.5,13file)

- `app/lib/modules/main_quest/lesson_screen.dart`
- `app/lib/modules/tutor/board/authored_board_repository.dart`
- `app/lib/modules/tutor/board/board_view.dart`
- `app/test/lesson_board_integration_test.dart` (ngoài formatter còn §1)
- `app/test/board/authored_board_repository_test.dart`
- `app/test/board/board_boundaries_test.dart`
- `app/test/board/board_controller_test.dart`
- `app/test/board/board_layout_test.dart`
- `app/test/board/board_plan_codec_test.dart`
- `app/test/board/board_previews_test.dart`
- `app/test/board/board_test_support.dart`
- `app/test/board/board_view_test.dart`
- `app/test/tutor_board_content_pack_test.dart`

Không formatter toàn app; không dùng formatter-only để giấu semantic changes.

## 3. Lockfile exception và Actions được phép

- `app/pubspec.lock`: regenerate bằng `flutter pub get` trên đúng pin để khớp
  các dependency **đã khai báo**. Sau đó `pub get` lại phải không đổi tracked file.
  Không sửa `pubspec.yaml`, không add/remove dependencies/constraints, không
  `pub upgrade` hoặc đổi SDK. Giao diff của lockfile để review độc lập.
- Nếu sandbox không cài được SDK, được thêm **một** workflow riêng
  `.github/workflows/pqc011-maintenance.yml` trên nhánh CODE hiện tại, pin
  Flutter3.47.7/frameworkabaf9c5237/Dart3.13.5. Không thay hai workflow hiện có,
  không chép đè workflow DESIGN, không chạy build/key/secret Gemini ở workflow này.
- Workflow maintenance có thể formatter đúng13file và regenerate lockfile, rồi
  ghi patch/evidence hoặc commit chỉ14file đó về **chính nhánh CODE hiện tại**.
  Nếu tự commit: so sánh remote tip với checkout SHA trước khi push; không force,
  không branch khác, không stage-all; reject file ngoài allowlist, không auto-loop.
  Nội dung semantic test fix phải do CODE chuẩn bị/review trước đó.
- Chạy verify trên final source SHA sau normalization, không dùng PASS ở preimage
  để nhận commit mới. Ghi log/counts qua Checks API nếu đường download artifact
  của agent cũng bị EOF. Chỉ cấp quyền GitHub cần thiết, không provider secret.
- Coordination được sửa `docs/implementation/coordination/tasks/PQC-011.md` để
  ghi correction/handoff cùng delivery thực chất; không cần đồng bộ whole docs
  hoặc làm lại PQC-019/018.

## 4. Gates và handoff

1. SDK đúng3.47.7 /3.13.5 /full framework SHA trong review; formatter exit0.
2. `flutter analyze --no-fatal-infos`: No issues found.
3. Settings12pass; actual LessonScreen7pass,0fail; ordinary giữ tất cả422tests
   hiện thấy trong execution (415pass+7fail) và mọi test mới nếu bổ sung,0fail;
   render giữ10pass. Không cộng subsets vào total.
4. Localization helpers/evidence không regress; pub get không làm đổi source
   tracked, đặc biệt lockfile; không thay product/runtime scope để làm tests xanh.
5. Giao exact final SHA, diff allowlist, run/job/check IDs, SDK, commands/counts và
   worktree status. Nếu case mới fail sau khi qua mount, báo cụ thể, không suy
   rằng sửa mount sẽ tự chữa toàn bộ7case.

DESIGN vẫn giữ PQC-011 CHANGES_REQUESTED cho tới khi đối chiếu final source và
execution evidence. APK internal có key là scope packaging riêng đã được người
dùng cho phép; không phải token/backend-first hoặc public-release gate.
