# Relay r47 — gửi cùng commit DESIGN của gói này

CODE: nhận **PQC-019 — bounded docs / keyless APK sync** trên nhánh DESIGN
`arena/00838eb9-pyquest`. Pin đúng SHA DESIGN Lead gửi kèm, đọc task
`docs/implementation/coordination/tasks/PQC-019.md` và package
`docs/design/coordination/reviews/PQD-010-r47/`.

Patch `code-sync.patch` chuẩn bị riêng từ CODE
`71b0fd3fd8fb07c73596ce089fa2e68f6fe87964`,13file; không copy cả workflow từ DESIGN.
Đã check/apply và12localtests PASS trên snapshot tạm, **chưa áp dụng lên remote CODE**.

Thực hiện theo task019: bảo vệ dirty files, kiểm tra từng hunk nếu HEAD/files đổi,
apply-check rồi apply patch, chạy hai script policy local và diff-check, cập nhật
handoff, commit `[skip ci]` có nội dung thật và push đúng nhánh phiên CODE. Báo
final SHA/file list/counts thực tế. Không ACK-only, không SDK/runtime/app/deps,
không dispatch/rerun CI, không đọc/thay repo secrets hoặc xóa artifact.

Giữ **011 CHANGES_REQUESTED / WAITING_FOR_PINNED_SDK_EVIDENCE** và
**018 REVIEWED_WITH_LIMITS — ART_SCOPE_COMPLETE**. Task019 không mở lại hai task đó.
Keyless APK sẽ không xác thực direct Gemini Live; không thêm lại key để bật voice.
Không claim build/device/voice PASS hoặc đã thu hồi key/APK cũ.

OpenCode chỉ chuyển nguyên văn tin này và SHA DESIGN đi kèm; không tự apply,
review, quyết định hay theo dõi CI.
