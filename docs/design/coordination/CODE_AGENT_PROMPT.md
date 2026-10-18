# Prompt cho agent code — copy phần dưới

Bạn là agent CODE của PyQuest. Agent DESIGN làm ở nhánh `arena/00838eb9-pyquest`;
nhánh code hiện tại là `arena/4253d4f1-pyquest`. Hai agent giữ hai nhánh riêng,
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
2. `docs/design/coordination/tasks/PQD-003.md` (revision hiện hành; không lặp lịch sử)
3. `docs/implementation/coordination/tasks/PQC-020.md`
4. `docs/design/coordination/specs/PQC-020-R2.md` và
   `docs/design/coordination/reviews/PQC-020-bed783cf/README.md`
5. `docs/design/r1-village-r53/README.md`, `SPEC.md` và `manifest.json`

Task020 trên DESIGN là baseline revision1; đọc append mới trên chính CODE, không
restore taskdoc DESIGN đè lịch sử CODE. R2 là bổ sung authority hiện hành.

Nếu commit/task chưa có trên remote: báo `WAITING_FOR_DESIGN_COMMIT`, không tự
sáng tác spec, không dùng bản asset cũ rồi tuyên bố đã nhận bản mới. Nếu lỗi auth,
báo người dùng kết nối GitHub cần được xử lý; không xin token hoặc mật khẩu.

**Không merge/pull/cherry-pick cả nhánh design.** Nhánh đó có commit baseline source
`dafde39` nhập từ code cũ, không phải bản cập nhật code dành cho bạn. Chỉ lấy đúng
asset/spec/tooling cần dùng từ SHA đã pin, kiểm tra diff và file đích trước khi ghi.

## 2. Work order hiện hành — r53 / PQC-020 revision2

PQC-011 **ACCEPTED** tại `6dc8ca8feeed54cc0fa6a82109e3a59d24a16153`.
Đọc `reviews/PQC-011-r53/README.md` vàevidence. Cập nhật task011 của CODE bằngrecord
acceptance, không restore taskDESIGN cũ đè lịch sử. Không lặp diagnostics/guard.

Tiếp tục **PQC-020 / R1-A Main Map**, baseline revision1 + ngoại lệ revision2 theo:
- `docs/implementation/coordination/tasks/PQC-020.md` — baseline authority/gates;
- `docs/design/coordination/specs/PQC-020-R2.md` — allowlist bổ sung hiện hành;
- `docs/design/r1-village-r53/{README.md,SPEC.md,manifest.json,source-manifest.json}`;
- Mở exportW01 vàcaptures390VI/360EN2×, không chỉ đọc tên ảnh.

Runtime chỉ mainmap/geometry/status/copy trongallowlist; sáu module/routes/locks
vàgameplay/save giữ nguyên. W01 được phép dùng **flattened static**, không phải
layered world, khôngtựvẽlại018 hoặc mởR4/NPC/nhà. Một focused020workflow được phép;
SDK/deps/keypolicy giữ nguyên. R2 chỉ cho routing verify trên exact branch mới
trong hai workflow hiện có, cùng formatter/focused-list cho hai test được sửa;
không normalize/diagnose/dispatch trên nhánh mới, không sửa regular ci.yml.
Final verify cùng SHA **sau các sửa thật**, không `[skip ci]`.
011/018/019 không mở lại. Không có ACK-only khi source task đã published.

Review bed783cf: locale injection đúng scope, ordinary433/2; focused/maintenance
NOT_RUN do routing nhánh cũ. Đổi expected hub label sang `Núi Lửa`; thay keyboard/
semantics characterization cũ bằng assertions R1-A thực, không skip/delete cases.
Rerun focused/normal/maintenance trên finalSHA mới; ordinary ít nhất435/0, render10.
Root clamp1.2 vẫn là gap riêng: chưa cho sửa app root hoặc claim app2×/ACCEPTED020.
Không push/fast-forward nhánh CODE cũ. Đọc order đầy đủ trước khi sửa.

DESIGN đã giao studies Dragon/Catch/R1-B; tiếp Bug Hunter gameplay/results độc lập.
CODE không làm trùng study này.

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
