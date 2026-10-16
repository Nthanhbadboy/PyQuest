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

Task hiện tại là **PQD-003 revision18: review5bf44fa, authorization r6 giữ nguyên**.
Đọc task003, `reviews/PQD-003-r18.md`, receipt r18 và SDK evidence trong PQC-010-r12.
Code ở `arena/0d4fcb38-pyquest`; không switch/push sang nhánh phiên khác.

**Làm ngay, không ACK-only:**
1. Run38964109149/report117188237347: analyze sạch10.8s,349pass/3fail,10renderpass.
   Chỉ D1-sem/D2-sem/D3-sem đỏ; visible/checkpoints và D3-visible ink roundtrip qua.
2. SDK abaf9c5237 mặc định testWidgets semanticsEnabled:true: bỏ manual handle KHÔNG
   tắt semantics. Đã đối chiếu source verifier chạy trước package:test teardown.
   Ba -sem tests vẫn có extra ensureSemantics + addTearDown(handle.dispose), quá muộn.
3. Bỏ cặp manual handle ở ba test, dùng framework-managed handle (explicit
   semanticsEnabled:true nếu muốn rõ). Hoặc dispose handle riêng trong try/finally
   trước callback return, không double dispose. Giữ getSemantics, expected VI/EN,
   negative stale-locale assertions và hành trình; không false/skip/property-only.
4. Không sửa runtime/renderer/scroll theo đoán. Source lifecycle finding không phải
   full CI trace; chạy lại exact SHA, lấy actual first failure nếu vẫn đỏ. Giữ ink
   roundtrip đã qua và groupX/scale/output/Tab/capture đã đóng. Không thêm test split.
5. Trả exact SHA/run/report. Scope010/014/015 giữ nguyên;014 độc lập,015 sau014 xanh,
   dependency chỉ015. Không LessonScreen/AI/voice/art/social/economy/P06/CI/publisher.

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
- Không có thay đổi cần làm: `WAITING_FOR_PEER`.

Lưu revision/SHA đã xử lý, không tạo ACK commit lặp vô ích. Không cần người dùng
chuyển từng lời giữa hai bên. Tuy nhiên khi phiên kết thúc, bạn không tự thức dậy
vì commit mới: ghi trạng thái chờ rồi dừng, lần được gọi tiếp theo fetch trước.
Không chạy vòng lặp chờ vô hạn hoặc khẳng định đã cài cơ chế tự động khi chưa có runner.

Bắt đầu bằng fetch, đọc `PQD-003` revision hiện tại, nhận bàn giao và thực hiện task đúng scope. Nếu bị chặn bởi
quyền commit/push hoặc môi trường, ghi rõ điều gì đã làm và điều gì còn phải đợi.
