# Runbook của lead nhánh code

Ngày: 2026-10-16. Áp dụng cho `arena/b813b575-pyquest`. Đây là cơ chế làm việc,
**không phải dịch vụ tự chạy**: phần "tự động" ở đây chỉ là *phát hiện và ghi lại*,
phần *suy nghĩ và sửa code* luôn thuộc về một phiên agent thật được gọi.

## 1. Ba tầng, ai làm gì

| Tầng | Việc | Ai chạy |
|---|---|---|
| Quan sát | fetch nhánh design, so revision, đọc gate, ghi note vào inbox | `tools/coordination/pq_lead.py` (chạy nền được) |
| Quyết định | revision mới có đổi phạm vi/không; có qua gate chưa; giao việc nào | **lead** (một phiên agent) dựa trên `status` + file task hai bên |
| Thực thi | sửa code/test theo đúng một work order | **delegate** — phiên agent khác nhận `brief` của work order |

Lead không tự làm mọi thứ khi có thể giao: mỗi work order trong `TASK_BOARD.md` đủ
self-contained để một phiên chưa biết gì về cuộc hội thoại vẫn làm đúng, và tự chặn
mình nếu gate chưa mở.

## 2. Lệnh

```sh
python3 tools/coordination/pq_lead.py status     # hợp đồng hiện tại: design rev, gate, CI, ACK
python3 tools/coordination/pq_lead.py fetch      # fetch + so + ghi inbox nếu design có commit mới
python3 tools/coordination/pq_lead.py ack <SHA>  # đánh dấu đã xử lý revision (chống ACK lặp)
python3 tools/coordination/pq_lead.py brief PQC-002   # in work order để giao delegate
python3 tools/coordination/pq_lead.py watch --interval 120 --max-minutes 480  # vòng chờ
```

State nằm ở `~/.pq-lead` (ngoài repo, có chủ đích): `state.json`, `lead.log`,
`inbox/<thời-gian>-<sha>.md`. Tool **không** commit, không push, không sửa working tree.

## 3. Quy tắc gate (không đàm phán)

1. Chỉ sửa `app/**` khi verdict của tool là `READY_FOR_CODE` **và** file task design
   ghi `runtime_change_authorized_by_this_revision: yes`. Khác đi một trong hai →
   intake/ACK, không code.
2. `GATE_CONFLICT` (task bảo READY_FOR_CODE nhưng không cho sửa runtime, hoặc ngược
   lại) → dừng, ghi câu hỏi vào file phản hồi, không tự suy diễn ý design.
3. Một work order = một revision design được pin. Design ra revision mới giữa chừng
   thì công bố ảnh hưởng, hoàn tất cái đang nhận hoặc chốt chuyển revision; không
   trộn hai bộ asset.
4. Không merge/pull/cherry-pick nguyên nhánh design (lịch sử khác, và tree của họ có
   thêm screenshot/tooling không thuộc task). Chỉ lấy đúng file task cần, kiểm tra
   diff trước khi ghi.
5. Không copy file coordination của nhau rồi commit lại; không push một ACK y hệt cho
   cùng một revision; bằng chứng luôn gắn SHA thật.
6. Không secret ở bất kỳ đâu: không in `GEMINI_API_KEY`, không bỏ key vào app release,
   evidence, tài liệu hay log.

## 4. Giao việc cho model khác (delegate)

* delegate chỉ nhận **một** work order; trước khi sửa phải chạy `pq_lead.py status`
  và tự xác nhận gate; nếu gate chưa mở thì trả về `BLOCKED` kèm lý do, không "làm tạm".
* bàn giao lại gồm: commit code, `tested_code_commit`, lệnh test đã chạy + kết quả
  thật, file đã sửa, thứ chưa kiểm chứng, và đường dẫn evidence.
* mỗi work order kết thúc bằng commit trên **nhánh code**; không push nhánh design,
  không mở PR, không force-push.
* khi delegate hết việc trong phạm vi, lead fetch design một lần nữa rồi ghi
  `WAITING_FOR_PEER` / `WAITING_FOR_DESIGN_REVIEW` cùng SHA đã xử lý — không vòng lặp
  chờ vô hạn trong một phiên.

## 5. Giới hạn thật của phần "luôn thức"

* `watch` chỉ có ích **chừng nào sandbox còn sống**; tiến trình này không tự gọi model,
  không tự commit, và chết khi phiên/sandbox kết thúc. Đây là điểm cứng của môi trường,
  không phải thứ có thể khắc phục bằng cách viết thêm tài liệu.
* Muốn chu kỳ thật sự không cần người: cần một runner bên ngoài có (a) quyền gọi
  agent/session mới, (b) credential chỉ đọc-ghi đúng hai nhánh, (c) timeout, giới hạn
  số vòng, khoá chống xử lý trùng revision, và (d) điểm dừng gửi cho người khi gate cần
  duyệt. Chưa có runner đó thì mọi mô tả "tự động hoàn toàn" đều là nói quá.
* Việc của con người trong loop này hiện chỉ là: chuyển lời/duyệt gate, hoặc gọi
  phiên kế tiếp — phiên đó fetch trước, đọc inbox, rồi mới làm.
