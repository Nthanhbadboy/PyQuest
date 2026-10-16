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
python3 tools/coordination/pq_lead.py status     # hợp đồng hiện tại: design rev, ba scope, gate, CI, ACK
python3 tools/coordination/pq_lead.py status --offline   # đọc cache, nhưng in rõ STALE/UNVERIFIED
python3 tools/coordination/pq_lead.py fetch      # fetch + so + ghi inbox nếu design có commit mới
python3 tools/coordination/pq_lead.py ack <SHA>  # đánh dấu đã xử lý revision (chống ACK lặp)
python3 tools/coordination/pq_lead.py brief PQC-002      # work order + cổng gate cho scope của nó
python3 tools/coordination/pq_lead.py brief BOARD        # chỉ mục work order
python3 tools/coordination/pq_lead.py watch --interval 120 --max-minutes 45 --max-failures 5
echo > ~/.pq-lead/STOP                            # xin dừng vòng watch ở cycle kế (nó tự xoá file)
```

Mã thoát: `0` ok · `1` bị chặn gate (`brief` của scope chưa được phép) ·
`2` lỗi git/fetch/state/ACK bị từ chối · `3` `state.lock` đang có writer khác giữ
(chờ bằng `--wait <giây>`). `watch` trả `2` khi hết `--max-failures`;
`git` bị giới hạn 120 s/call (timeout → `LeadError`, không treo vô hạn).

State nằm ở `~/.pq-lead` (ngoài repo, có chủ đích): `state.json`, `lead.log`, `state.lock`,
`inbox/<thời-gian>-<sha>.md`, `STOP`. Tool **không** commit, không push, không sửa working tree.
Ghi state luôn đi qua `state_lock()`; khi có lỗi git, `last_error` được lưu để `status`
in ra thay vì giả vờ vừa kiểm tra.

## 3. Quy tắc gate (không đàm phán)

0. Ba scope **độc lập**, chỉ mở khi chuỗi đúng `yes` (không phải `yesterday`, `no`,
   hay thiếu field): `runtime_*` → `app/lib/**`, `app/assets/**`, Android, dependency;
   `test_*` → `app/test/**` (kể cả harness render); `coordination_*` → docs/board/evidence.
   Cho phép `test` hoặc `coordination` **không** hàm ý được sửa app. Work order phải có
   dòng `- scope: <tên scope>`; thiếu dòng đó `brief` chặn (mặc định an toàn), không suy ra.
1. Chỉ sửa `app/**` khi verdict của tool là `READY_FOR_CODE` **và** file task design
   ghi `runtime_change_authorized_by_this_revision: yes`. Khác đi một trong hai →
   intake/ACK, không code.
2. `GATE_CONFLICT` (task bảo READY_FOR_CODE nhưng không cho sửa runtime, hoặc ngược
   lại) → dừng, ghi câu hỏi vào file phản hồi, không tự suy diễn ý design.
2b. `status` chỉ được tin khi dòng `checked at` mang nhãn `[verified]`. Nhãn
   `STALE/UNVERIFIED` nghĩa là fetch lỗi: giữ dữ liệu cũ để đọc, nhưng **không** lấy
   gate cũ mở việc mới.
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

* delegate chỉ nhận **một** work order; bước bắt buộc là
  `python3 tools/coordination/pq_lead.py brief <ID>` và dán nguyên văn dòng `gate:` vào
  bàn giao. Gate chưa mở thì trả về `BLOCKED` kèm lý do, không "làm tạm", không tự thêm
  file ngoài danh sách `Allowed paths` của order.
* bàn giao lại gồm: commit code, `tested_code_commit`, lệnh test đã chạy + kết quả
  thật, file đã sửa, thứ chưa kiểm chứng, và đường dẫn evidence.
* mỗi work order kết thúc bằng commit trên **nhánh code**; không push nhánh design,
  không mở PR, không force-push.
* khi delegate hết việc trong phạm vi, lead fetch design một lần nữa rồi ghi
  `WAITING_FOR_PEER` / `WAITING_FOR_DESIGN_REVIEW` cùng SHA đã xử lý — không vòng lặp
  chờ vô hạn trong một phiên.
* `brief` in quyền theo scope; `status: BLOCKED/QUEUED` trong chính work order là **độ
  sẵn sàng** (thiếu thiết bị, thiếu duyệt art). Hai thứ khác nhau: được phép sửa ≠ nên làm.
* không chạy `watch` và `ack`/`fetch` đồng thời trên cùng state dir mà không `--wait`;
  đứa nhận `rc=3` phải thử lại hoặc dừng, không xoá `state.lock` khi lock còn mới.

## 6. Cách đọc kết quả CI cho đúng commit (môi trường lead không có Flutter SDK)

```sh
SHA=$(git rev-parse HEAD)                       # SHA vừa push, không dùng 'latest'
gh run list --branch arena/b813b575-pyquest --limit 3
gh api "repos/Nthanhbadboy/PyQuest/commits/$SHA/check-runs" \
  --jq '.check_runs[] | select(.name=="PyQuest check") | .id'
gh api repos/Nthanhbadboy/PyQuest/check-runs/<id> \
  --jq '.output | {title, summary, text}'        # flutter --version + analyze/test/render log
```

Ảnh render "before/after" không nằm trong artifact mà được publish thành check run
`preview|<state>|<chunk>|<n>` (base64 JPEG, xem `ci/publish_previews.py`). Ghép chunk rồi
giải mã để xem thật và đo bằng số (Pillow trong venv tạm), như EV-ID-007. Quy tắc: số liệu
CI chỉ gán cho **đúng SHA** đã fetch; run của commit khác là bằng chứng của commit khác.

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
