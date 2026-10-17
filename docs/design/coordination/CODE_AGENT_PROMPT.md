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

Task hiện tại là **PQD-003 revision27: hoàn tất015 sau review07fc897/source6dd62c8**.
Đọc task003, reviews/PQD-003-r27.md, receipt r27 và PQC-015-r3/evidence-channel.md.
Đọc LEAD_MANDATE_2026-10-17: người dùng giao Lead quyết định/tiếp tục phát triển app;
không xin user chọn task mỗi vòng. CODE vẫn làm đúng order/allowlist Lead đã publish.

**Gộp sửa015 còn lại, không ACK-only/diagnostic split:**
1. Run07:39004969823/report117319893254,384pass/7fail,10render,analyze sạch8.4s.
   Ba app integration đỏ +4probe fail, chỉ chunk0 được thu; không có payload đầy đủ.
   Source6dd đã runAsync5DBcloses nhưng createTemp/DBreads/semantics/cleanup còn lại.
   Kiểm CI6dd39006531482 đúng SHA, không dùng số07 cho6dd.
2. Bỏ extra ensureSemantics+addTearDown, dùng framework-managed semanticsEnabled:true
   hoặc finally trước callback return; giữ CloseButton VI/EN/getSemantics assertions.
3. Sửa createTemp fakeasync; audit DBreads, cleanup kể cả assertion fail. Pump/assert
   trong widget zone, native I/O đúng boundary. Giữ resume/reload/Navigator/input coverage.
4. Lead mở ngoại lệ CI015 hẹp: job check trong ci.yml + ci/l10n_evidence.py + tests.
   Làm theo evidence-channel.md để publish đủ SDKgenerated output/hashes, gen lần2 và
   committed drift. Không sửa ci/report.py/previews/SDK/deps/APK/emulator; không
   pipeline overhaul. Bỏ intentional-fail probe khi đường evidence thật hoạt động.
5. Không giấu failures/skip tests. Commit generated files thật sau thu; rerun trên
   SHA có output để chứng minh không drift/untracked. Trả exactSHA/run/report.
6.010/014 giữ nghiệm thu. Sau015, Lead chuẩn bị016 rồi011; CODE chưa tự làm hai gói
   này hoặc đổi runtime ngoài015. Phạm vi không đồng nghĩa app đã hoàn thiện.

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
