# Prompt cho agent code — copy phần dưới

Bạn là agent CODE của PyQuest. Agent DESIGN / Co-Dev làm ở nhánh `arena/84456d39-pyquest`
(kế thừa từ `arena/00838eb9-pyquest`); nhánh code hiện tại là `arena/4253d4f1-pyquest`.
Hai agent giữ hai nhánh riêng, cùng code Flutter song song theo cụm module tách biệt,
phối hợp bằng commit và file bàn giao. Chỉ làm trên nhánh mà phiên của bạn được
phép; nếu khác nhánh dự kiến, báo lại tên nhánh thật, không tự chuyển nhánh.

## 1. Nhận đúng bàn giao

Kiểm tra working tree, bảo vệ thay đổi đang có. Fetch nhánh Lead/Co-Dev bằng:

```sh
git fetch origin refs/heads/arena/84456d39-pyquest:refs/remotes/origin/arena/84456d39-pyquest
git rev-parse origin/arena/84456d39-pyquest
git ls-tree -r --name-only origin/arena/84456d39-pyquest -- docs/design/coordination/
```

Pin SHA thật từ lệnh trên. Dùng `git show <SHA>:<path>` để đọc lần lượt:

1. `docs/design/CROSS_BRANCH_COLLABORATION.md`
2. `docs/design/coordination/tasks/PQD-003.md` (revision hiện hành; không lặp lịch sử)
3. `docs/implementation/coordination/tasks/PQC-020.md`
4. `docs/design/coordination/specs/PQC-020-R3.md` và
   `docs/design/coordination/reviews/PQC-020-ddf7db5a/README.md`
5. `docs/design/r1-village-r53/README.md`, `SPEC.md` và `manifest.json`

Task020 trên DESIGN là baseline revision1; đọc append mới trên chính CODE, không
restore taskdoc DESIGN đè lịch sử CODE. R3 là bổ sung authority hiện hành (R2 giữ phần không bị thay thế).

Nếu commit/task chưa có trên remote: báo `WAITING_FOR_DESIGN_COMMIT`, không tự
sáng tác spec, không dùng bản asset cũ rồi tuyên bố đã nhận bản mới. Nếu lỗi auth,
báo người dùng kết nối GitHub cần được xử lý; không xin token hoặc mật khẩu.

**Không merge/pull/cherry-pick cả nhánh design.** Nhánh đó có commit baseline source
`dafde39` nhập từ code cũ, không phải bản cập nhật code dành cho bạn. Chỉ lấy đúng
asset/spec/tooling cần dùng từ SHA đã pin, kiểm tra diff và file đích trước khi ghi.

## 2. Work order hiện hành — r53 / PQC-020 revision3

PQC-011 **ACCEPTED** tại `6dc8ca8feeed54cc0fa6a82109e3a59d24a16153`.
Không mở lại diagnostics/normalize. R2 trênddf7db5a đã có ba gate xanh cùng tip:
focused58/0, normal435/0+render10/0, maintenance12/1/2/7+435/0+10/0/supportPASS.
Review độc lập xác nhận routing/label/keyboard, nhưng **020 NOT_ACCEPTED**.

Tiếp tục R1-A theo baseline task020 + **PQC-020-R3.md** (đọc đầy đủ):
- Sửa Align/anchor mismatch làm nhãn Núi Lửa đè Tháp Python trong ảnh CI; đo
  actual button rectangles/centers, không chỉ helper geometry.
- Cho phép bỏ blanket cap1.2 ở app root, giữ scaler hệ thống; root12case matrix và
  captures phải qua PyQuestApp thật, không route override MediaQuery.
- Thay widget-properties oracle semantics bằng rendered semantics role/name/action/
  uniqueness; giữ keyboard và các case route/energy/save.
- Hoàn thiện captures/evidence/budget. Before6dc8ca8 và asset hash đã được DESIGN
  kiểm độc lập trong reviewddf7; không cần rerun baseline.

R3 liệt kê exact runtime/test/CI paths. Focused workflow chỉ thêm formatter/snapshot
paths và focused root test; giữ routing R2. Maintenance/normalCI/SDK/deps không sửa.
Chỉ push arena/4253d4f1-pyquest; không fast-forward/push nhánh CODE cũ. Final gates
trên cùng SHA mới: ordinary435+N/0, focused58+N phù hợp, render10/0 và hỗ trợPASS.
Không nhận toàn app/device2× chỉ từ hub matrix, không APK hoặc tự ACCEPTED020.

R1-A dùng W01 **flattened static**, không gọi layered/animated world; giữ6module,
route/status/energy/save. Không mở R1-B hoặc gameplay. DESIGN tiếp Bug Hunter
study độc lập; CODE không làm trùng study hoặc port artwork khác.

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
