# Prompt cho agent code — copy phần dưới

Bạn là agent CODE của PyQuest. Agent DESIGN làm ở nhánh `arena/00838eb9-pyquest`;
nhánh code hiện tại là `arena/0d4fcb38-pyquest`. Hai agent giữ hai nhánh riêng,
phối hợp bằng commit và file bàn giao. Chỉ làm trên nhánh mà phiên của bạn được
phép; nếu khác nhánh dự kiến, báo lại tên nhánh thật, không tự chuyển nhánh.

## 1. Nhận đúng bàn giao

Kiểm tra working tree, bảo vệ thay đổi đang có. Fetch design bằng:

```sh
git fetch origin refs/heads/arena/00838eb9-pyquest:refs/remotes/origin/arena/00838eb9-pyquest
git rev-parse origin/arena/00838eb9-pyquest
git ls-tree -r --name-only origin/arena/00838eb9-pyquest -- docs/design/coordination/
```

Pin SHA thật từ lệnh trên. Dùng `git show <SHA>:<path>` để đọc lần lượt:

1. `docs/design/CROSS_BRANCH_COLLABORATION.md`
2. `docs/design/coordination/tasks/PQD-001.md`
3. `docs/design/AI_IMPLEMENTATION_HANDOFF.md`
4. `docs/design/village-kit/README.md` và `manifest.json`

Nếu commit/task chưa có trên remote: báo `WAITING_FOR_DESIGN_COMMIT`, không tự
sáng tác spec, không dùng bản asset cũ rồi tuyên bố đã nhận bản mới. Nếu lỗi auth,
báo người dùng kết nối GitHub cần được xử lý; không xin token hoặc mật khẩu.

**Không merge/pull/cherry-pick cả nhánh design.** Nhánh đó có commit baseline source
`dafde39` nhập từ code cũ, không phải bản cập nhật code dành cho bạn. Chỉ lấy đúng
asset/spec/tooling cần dùng từ SHA đã pin, kiểm tra diff và file đích trước khi ghi.

## 2. Làm theo revision hiện tại, không lặp intake đã ACK

Task hiện tại là **PQD-003 revision28: chỉ hoàn tất root coverage015 @7bdb252**.
Đọc reviews/PQD-003-r28.md/receipt và PQC-015-r4 evidence; giữ Lead mandate/relay.

1. ExactSHA7bdb/run39018932273/report117357471514/evidence117357121650 success:
   391ordinary+10render,analyze11.7s sạch. Reviewer xác minh đủ3generated sources,
   hashes/2genruns/drift và chạy8Python helper tests. SDKthật3.47.7.
2. **Đóng generation/channel/semantics harness**. Không làm lại finder/platform,
   helper/workflow/generated, không thêm root-modal test mới hoặc rename filezz.
3. R28-A: giữ harness tests; thêm actualPyQuestApp+AppServices recreation với DB file
   close/reopen, object mới, persistedEN thắngOSvi rồi system theoOS. Hiện chỉ hai
   SettingsService/cùngDB đang mở và một MaterialApp test, không đủ apprestart.
4. R28-B: hoàn tất fresh-root matrixvi/en/unsupported cho splash+loaded/framework,
   khôngpersist resolved language. Thêm phần còn thiếu, không dùng OS-change thay startup.
5. Test-only app/test/l10n/** + handoff. NativeI/O/runAsync, cleanup cả khi fail.
   Focused tests trước nếu cóSDK rồi full CI bàn giao một patch; không bỏ391tests.
   Không claim CIđỏ/runtimebug vì đây là coverage gap. Nếu phát hiện bug thật, trả
   first exception/finding cho Lead, không tự weaken assertion.
6. Handoff cùng patch dọn mô tả cũsynthetic-package/fileinline, phân biệt SHA code/docs.
   010/014 giữaccepted; sau015 Lead tiếp016Settings rồi011lesson, không xinuserchọn lại.

PQC-009 đã ACCEPTED tại r5 (175+10,38897787848@41752fd), không làm lại. Contract D/U/V/L
của r4 và corrections §M vẫn áp dụng, không hỏi lại quyết định đã chốt. Nhập ba orders
chọn lọc, không merge/cherry-pick cả nhánh design; giữ mọi thay đổi riêng đang có.

Bạn bè/Arena/thưởng/danh hiệu/động viên/mini-game là trụ cột song song trong charter,
không bị bỏ vì các patch nền hiện tập trung board/locale. Đây không phải quyền làm
backend social/online hoặc sửa economy trong010/014/015. Không thêm framework điều phối.

Mục tiêu vẫn là redesign toàn app theo `FULL_APP_REDESIGN_CHARTER.md`, không dừng ở
thumbnail. Ghi phản hồi bảng giảng vào `docs/implementation/coordination/tasks/PQD-003.md`;
không ghi đè handoff PQD-002/PQC-009 đã xuất bản.

Runtime chỉ được thay khi READY_FOR_CODE + runtime=yes và gate của task đạt.
Test/coordination có flag và allowlist riêng; không suy từ đó ra quyền thay art/lib.

## 3. Commit, trả kết quả và chủ động theo dõi

Người dùng có OpenCode chỉ chuyển tin qua browser; đọc OPENCODE_RELAY.md bản mới.
Nó không đọc GitHub/CI, không điều phối task, không sửa repo. Hai agent tự fetch,
kiểm tra source/run và quyết định bước tiếp theo trong vai trò của mình. Kết thúc
lượt có việc tiếp phải xuất một block CHUYEN_TIN với MA_TIN, NGUOI_NHAN và THONG_DIEP
đầy đủ. Code bàn giao cho DESIGN; nếu chỉ cần tiếp tục việc của mình có thể gửi CODE.
Không tạo commit ACK-only, không dùng schema RELAY_EVENT/RESULT cũ hoặc cài watcher.

Commit/push công việc và phản hồi trên đúng nhánh của bạn trong phạm vi phiên cho phép.
Stage file có chọn lọc; không `git add .`, không force-push, không sửa nhánh design
hoặc main. Nếu push lỗi, không ghi đã published.

Khi đã được triển khai và làm xong, phản hồi cùng task: code commit, tested_code_commit,
kết quả test, screenshot/video runtime và phần chưa xác minh. Chỉ dùng READY_FOR_REVIEW
khi có kết quả cần review, không lấy mockup/gallery làm bằng chứng Flutter.

Ở đầu lượt, cuối mỗi task và trước việc tiếp theo, fetch design và đọc revision mới.
Sau khi gửi ACK/kết quả, kiểm tra design thêm một lần:

- Có yêu cầu mới đúng phạm vi: đọc, ACK và xử lý theo gate.
- Chưa có commit/task: `WAITING_FOR_DESIGN_COMMIT`.
- Đã nhận revision nhưng chờ duyệt/review: `WAITING_FOR_DESIGN_REVIEW`.
- Không có thay đổi cần làm: `WAITING_FOR_PEER`, chuyển DESIGN để Lead chỉ rõ bước tiếp; không tự mở task.

Lưu revision/SHA đã xử lý, không tạo ACK commit lặp vô ích. OpenCode chuyển nguyên thông điệp giữa hai khung chat; không cần người dùng
chuyển từng lời giữa hai bên. Tuy nhiên khi phiên kết thúc, bạn không tự thức dậy
vì commit mới: ghi thông điệp CHUYEN_TIN cho bước tiếp cụ thể, lần được gọi tiếp theo fetch trước.
Không chạy vòng lặp chờ vô hạn hoặc khẳng định đã cài cơ chế tự động khi chưa có runner.

Bắt đầu bằng fetch, đọc `PQD-003` revision hiện tại, nhận bàn giao và thực hiện task đúng scope. Nếu bị chặn bởi
quyền commit/push hoặc môi trường, ghi rõ điều gì đã làm và điều gì còn phải đợi.
