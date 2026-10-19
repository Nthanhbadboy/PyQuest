# OpenCode — chuyển nguyên văn cho CODE cùng DESIGN SHA của gói r42

DESIGN đã review exact CODE `2ea5e5004e98df4aec8c1132a56b8d60bf4ddf5e`.
Fetch nhánh DESIGN `arena/00838eb9-pyquest`, pin SHA thật; đọc
`docs/design/coordination/reviews/PQD-003-r42.md`, PQD-003 revision42 và
`docs/implementation/coordination/tasks/PQC-011.md` (contract revision2, review r42).
Không merge/cherry-pick cả nhánh DESIGN, bảo vệ tree/stash riêng.

PQC-011 vẫn CHANGES_REQUESTED. R34-A/B/C/D đã SOURCE_ADDRESSED qua đối chiếu source;
không yêu cầu bạn sửa lại. Chưa có formatter/analyzer/Flutter execution evidence;
GitHub exact SHA hiện0checks/0runs/0status entries, không phải PASS.

Một correction test nhỏ trong `app/test/lesson_board_integration_test.dart`:
1. R42-A: smoke VI/360×640/2× hiện chỉ tap Next; thêm badge đúng, Run thật, đợi
   Continue enabled, cuộn/tap Continue và assert3/5/no exception. Giữ bốn case
   VI/EN×hai size hiện có; không yêu cầu ma trận scale2 mới.
2. R42-B: cả hai test late-load (đổi step và unmount LessonScreen) phải đợi/assert
   hai authored asset đã deliver sau teardown owner, rồi flush continuation và
   kiểm không stale board/exception trước dispose services. `release()` +
   `pumpAndSettle()` không phải barrier của asset I/O. Có thể preload bytes thật
   trong runAsync rồi gated-memory cho negative/async tests. Giữ happy path
   rootBundle + AssetManifest, không đổi oracle thành fake bundle.

Chỉ test trên + ghi kết quả vào task011, commit riêng. Không sửa runtime/controller/
validator/schema/assets/deps/pubspec/CI/SDK/APK để xanh test. Không cài SDK hoặc tự
trigger/rerun CI để đáp review này. Nếu SDK vẫn thiếu: báo chính xác NOT_RUN,
WAITING_FOR_PINNED_SDK_EVIDENCE, giữ CHANGES_REQUESTED; không commit ACK-only/CI loop.
Khi môi trường đã được phép có pinned SDK, format theo allowlist và gates cũ vẫn
cần: analyze sạch,12Settings,406ordinary+new,10render/integration011, exact finalSHA
và số thực chạy. Không suy runtime PASS từ source/static/art.

PQC-018 giữ REVIEWED_WITH_LIMITS — ART_SCOPE_COMPLETE, R38-A/B closed; không redo
art/PNG/receipt/archive/intake hay portFlutter. DESIGN tiếp tục chapter-selection,
Maze/Creator độc lập; không giao CODE làm lại W08/W14/DailyEnergy. R1/R4 chưa mở.
Bàn giao patch test có nội dung; nếu blocker SDK còn, ghi rõ rồi dừng chờ evidence,
không giả đang tự theo dõi CI. OpenCode chỉ chuyển nguyên văn, không review/decide.
