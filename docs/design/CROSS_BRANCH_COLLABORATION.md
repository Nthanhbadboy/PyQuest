# Phối hợp design ↔ code qua hai nhánh

Ngày: 2026-10-16. Quy ước phối hợp, **chưa phải một dịch vụ agent tự chạy**.

## 1. Vai trò và nơi trao đổi

- Design: `arena/00838eb9-pyquest`, phụ trách asset/spec và visual review.
- Code: `arena/0d4fcb38-pyquest`, nhánh code hiện tại (cập nhật2026-10-17).
  `arena/b813b575-pyquest` là nhánh lịch sử; không dùng làm địa chỉ relay hiện tại.
- Mỗi agent chỉ commit/push lên nhánh được giao, không đổi nhánh hoặc ghi lên nhánh đối tác.
- Design xuất bản yêu cầu tại `docs/design/coordination/tasks/<task-id>.md`.
- Code xuất bản phản hồi tại `docs/implementation/coordination/tasks/<task-id>.md`
  trên nhánh code. Task design `PQD-001` đã có; file phản hồi code chỉ tồn tại khi
  agent code thực sự tạo và xuất bản, không được tự giả định đã có ACK.
- Mỗi bên đọc file đối tác qua remote ref, ghi phản hồi trong file thuộc mình.
  Không cần copy/merge cả nhật ký đối tác vào nhánh mình.

Hai nhánh riêng không cản trở việc phối hợp. Điều bắt buộc là nhiệm vụ có phiên bản,
commit nhận bàn giao cụ thể và evidence gắn với code được kiểm tra.

## 2. Chu kỳ chủ động của mỗi agent

**Ở đầu lượt, trước khi nhận task tiếp theo và sau khi hoàn thành một task:**

1. Kiểm tra nhánh, working tree, thay đổi chưa commit; không ghi đè công việc có sẵn.
2. Fetch đúng nhánh đối tác; đọc SHA mới, log/diff và file bàn giao liên quan.
3. So sánh với revision/commit đã xử lý, không chỉ thấy HEAD mới là làm lại mọi việc.
4. Nếu có task đủ điều kiện trong phạm vi đã được người dùng duyệt, nhận và làm tiếp.
   Nếu thiếu asset, evidence, quyền duyệt hoặc yêu cầu mâu thuẫn, ghi `BLOCKED` và
   câu hỏi cụ thể vào file phản hồi; không tự đoán hoặc đổi gameplay.
5. Khi hoàn thành, xuất bản kết quả nếu đã được phép commit/push; ghi rõ các commit
   artifact, test, evidence, lỗi và việc còn thiếu. Chỉ ghi `published` khi push thành công.
6. Kiểm tra nhánh đối tác thêm một lần. Không có việc mới thì báo `WAITING_FOR_PEER`
   cùng revision cuối đã xử lý và kết thúc lượt; không vòng lặp chờ vô hạn.

Không đánh dấu đã xử lý một revision chỉ vì đã fetch HEAD đó. Revision mới xuất hiện
trong lúc đang làm chỉ được ACK sau khi đọc và đánh giá ảnh hưởng.

### Đọc nhánh code từ phiên design hiện tại

```sh
git fetch origin refs/heads/arena/0d4fcb38-pyquest:refs/remotes/origin/arena/0d4fcb38-pyquest
git rev-parse origin/arena/0d4fcb38-pyquest
git log -5 --oneline origin/arena/0d4fcb38-pyquest
git ls-tree -r --name-only origin/arena/0d4fcb38-pyquest -- docs/implementation/coordination/
```

Dùng `git show <SHA>:<path>` để đọc file có thật; dùng `git diff <SHA-đã-xử-lý> <SHA-mới> -- <paths>`
để review thay đổi. SHA/path phải lấy từ Git và bàn giao thật, không dùng giá trị ví dụ
như một commit tồn tại. Agent code làm tương tự với remote ref của nhánh design,
trong giới hạn nhánh được phiên của agent đó cho phép.

## 3. Hợp đồng một nhiệm vụ

### Design ghi

- `task_id`: ID ổn định, ví dụ nhiệm vụ đầu có thể đặt `PQD-001`.
- `revision`: tăng khi spec/asset thay đổi có ảnh hưởng triển khai.
- `status`: `DRAFT`, `READY_FOR_INTAKE`, `READY_FOR_CODE`, `CHANGES_REQUESTED`,
  `ACCEPTED` hoặc `BLOCKED`. `READY_FOR_INTAKE` chỉ cho phép nhận bàn giao/kiểm tra
  gate, không có nghĩa được bỏ qua duyệt thiết kế để sửa app.
- Phạm vi được duyệt, gate còn thiếu, file được phép sửa và phần không được sửa.
  `test_change_authorized_by_this_revision` và `coordination_change_authorized_by_this_revision`
  chỉ mở scope được liệt kê tương ứng; không thay thế `runtime_change_authorized_by_this_revision`.
- Asset paths + manifest/hash; mapping màn/state; tiêu chí nghiệm thu.
- Review: trỏ đúng revision, code commit và evidence đã xem; phân biệt nhận xét
  mỹ thuật với lỗi chức năng. Không kết luận animation đúng từ một ảnh tĩnh.

### Code ghi

- Cùng `task_id`, `design_revision` và **design SHA đã fetch thực tế**.
- `status`: `ACKNOWLEDGED`, `IN_PROGRESS`, `READY_FOR_REVIEW` hoặc `BLOCKED`.
- Asset đã lấy, đường dẫn runtime, code commit cần review.
- Test thực chạy, test chưa chạy, screenshot/video paths và môi trường.
- `tested_code_commit`: commit chứa code được build/test, có thể khác commit bổ sung
  báo cáo/evidence. Không cần nhúng SHA của chính commit đang được tạo vào nó.
- Các câu hỏi hoặc lý do chưa thể đáp ứng yêu cầu.

Đừng dùng riêng câu “lấy bản mới nhất”. Người nhận pin SHA mà mình đã đọc và giữ nó
trong ACK. Nếu spec đổi khi đang code, công bố ảnh hưởng, hoàn thành revision đã nhận
hoặc thỏa thuận chuyển revision; không âm thầm trộn hai bộ asset.

## 4. Đồng bộ chọn lọc, không kéo cả nhánh qua lại

- **Fetch để đọc, không mặc định `git pull` nhánh đối tác vào nhánh hiện tại.**
- Agent code chỉ nhập asset/spec thuộc task đã nhận từ design SHA đã pin.
- Agent design chỉ đọc code/evidence để review, không tự nhập toàn bộ source mỗi vòng.
- Không cherry-pick mù commit chứa cả source cũ và artwork. Chọn đúng đường dẫn,
  kiểm tra working tree trước khi restore/copy, không xóa thay đổi đang có.
- Không force-push, reset dữ liệu hay tự merge vào main. File không thuộc task phải
  được giải thích và duyệt riêng nếu cần sửa.
- Không copy ngược file coordination của đối tác rồi commit lại, tránh ping-pong
  commit đánh thức hai agent dù nhiệm vụ không thay đổi.
- Evidence lớn dùng artifact hoặc nơi lưu phù hợp repo; file bàn giao phải chỉ rõ
  commit/run, cách truy cập và hạn sử dụng. Không dùng link hết hạn làm bằng chứng duy nhất.

## 5. Điều kiện bắt đầu đối với trạng thái hiện tại

- Mốc source import được tách thành commit `dafde39`; asset/spec/coordination được
  đóng gói ở commit design riêng để agent code không kéo ngược source cũ.
- Khi nhận prompt, fetch remote, kiểm tra `docs/design/coordination/tasks/PQD-001.md`
  và pin SHA thực tế. Nếu chưa fetch được commit/file, báo `WAITING_FOR_DESIGN_COMMIT`;
  không suy ra rằng một bản local đã được push.
- Task đầu đã nhận ACK. Revision 3 giao test-only và sửa coordinator; **chờ
  `READY_FOR_CODE` + runtime=yes trước khi sửa runtime**. Test có flag và allowlist
  riêng không đồng nghĩa được đổi app/lib hoặc assets.
- Agent code phải được cung cấp quy ước này và xác nhận tham gia. Viết tài liệu một
  phía không đồng nghĩa phía kia đã đọc, ACK hoặc bắt đầu chạy.
- Sáu thumbnail là lát cắt đầu đề xuất. Việc duyệt art, gate Tutor và bảo vệ baseline
  vẫn theo `AI_IMPLEMENTATION_HANDOFF.md`; cơ chế phối hợp không tự bỏ các gate đó.

## 6. Relay browser và vai trò Lead — cập nhật2026-10-17

Người dùng đã chốt: Design là Lead quyết định thiết kế, giao việc, review và tiếp tục
quản lý phát triển app; user theo dõi và can thiệp riêng, không phải chọn task mỗi
vòng. Xem [Lead mandate](coordination/LEAD_MANDATE_2026-10-17.md).

OpenCode bên ngoài **chỉ chờ turn hoàn tất rồi chuyển nguyên thông điệp cuối lượt
qua khung chat browser**. Không đọc/điều phối GitHub/CI thay agent, không sửa repo,
không chọn task hoặc review. Hai agent tự kiểm tra source/CI và chủ động ghi bước
kế tiếp theo [OPENCODE_RELAY.md](coordination/OPENCODE_RELAY.md).

Commit không tự gọi được chat; cuối lượt phải có block CHUYEN_TIN nếu còn action.
Lead nghiệm thu xong thì giao task mới hoặc chuyển về DESIGN để tiếp tục thiết kế,
không dừng vì chưa có commit kế tiếp. Không tự mở scope bên CODE: Lead publish
work order rõ trước. Không tuyên bố browser relay đã chạy/đã gửi nếu chưa xác minh.
Bản hướng dẫn watcher GitHub tại e4c2895 đã được thay bằng cơ chế browser relay này.
