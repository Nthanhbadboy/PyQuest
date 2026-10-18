# PQC-011 — ACCEPTED, ghi nhận độc lập r53

2026-10-18 · reviewer DESIGN · source được nhận:
**`6dc8ca8feeed54cc0fa6a82109e3a59d24a16153`** trên CODE `arena/0d4fcb38-pyquest`.
Quyết định đã thông báo trong chat, nay được ghi vào repo; không phải một lần chạy mới.

- [Maintenance39115732723](https://github.com/Nthanhbadboy/PyQuest/actions/runs/39115732723)
- [Exact check117641471826](https://github.com/Nthanhbadboy/PyQuest/runs/117641471826)
- [RegularCI39115732724](https://github.com/Nthanhbadboy/PyQuest/actions/runs/39115732724)
- [Metadata/gate evidence đã query độc lập](evidence.json)

| Gate tại source được nhận | Kết quả |
|---|---|
| SDK | Flutter3.47.7 / Dart3.13.5 / frameworkabaf9c523780a608bd46686fd5e53740a07077f8 |
| Settings |12/12 |
| Tutor isolated / first→Tutor |1/1 và2/2 |
| Lesson integration |7/7 |
| Ordinary |422passed /0failed |
| Render |10/10 |
| Format/analyze/localization/lock/clean |PASS |
| APK |SKIPPED — không có APK mới |

## Source review

Diff30d0d90→6dc8ca8 chỉ integration test +taskdoc, không runtime. Bảy test giữ tên;
controller identity, code, selection, output, board beat/learner layer và locale
assertions được giữ. `f87c3bf→c075f22` chỉ formatter3insertions/4deletions; final6dc8
là verification trigger cùng normalized tree, không thay assertion để PASS.

CaseB vẫn bắt buộc pre-open caret visible nhưng ngoài padding, expected displacement
lấy **snapshot trước khi mở** và clamp scroll extents; measured−6.96 đúng geometric
correction. CaseA dùng unfocus/refocus bounded settle và yêu cầu caret trong padding
trước baseline; lần mở lại giữscroll trong0.5. Không hardcode126.04/6.96, không
jumpTo/caret suppression/hasFocus guard runtime. Đây là refinement đã được Lead
cho phép, không che test lỗi bằng bỏ boundary case hoặc nới tolerance.

Guard thử trước đó đã thất bại và được revert; không làm lại. Các báo cáo cũ đặt
scroll vào lúc mởsheet đã được sửa: biến động quan sát sau close tap, trong reverse
transition cùng khôi phục focus/caret reveal. Không dùng diễn giải timing cũ.

## Phạm vi đóng

Đóng011 authored lesson-board integration và regression/state contract đã giao.
Không chứng nhận AI planning, freehand/voice-sync, whole-app redesign, thiết bị/IME,
APK hoặc production. Source acceptance không chuyển tự động sang commit runtime mới.
CODE chỉ append/update disposition của taskdoc riêng, **không restore taskdoc DESIGN
đè lịch sử CODE**. Commit docs-only kế tiếp không được ghi là đã chạy tests nếu chưa.

Bước tiếp theo: [PQC-020 R1-A](../../../../implementation/coordination/tasks/PQC-020.md),
không mở lại011/018/019. Chưa merge branch hoặc build APK trong review này.
