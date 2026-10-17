# OpenCode relay — đánh thức hai phiên qua GitHub và kênh gửi tin

Ngày 2026-10-17. Đây là hợp đồng cho OpenCode bên ngoài do người dùng vận hành,
không phải runner được cài trong repo. Chưa kiểm tra cấu hình, API gửi tin hoặc khả
năng nhận phản hồi của OpenCode đó. Không giả định Arena có API wake công khai.

## 1. Đúng vai trò / đúng địa chỉ

- Repo: `Nthanhbadboy/PyQuest`.
- DESIGN: branch `arena/00838eb9-pyquest`.
- CODE: branch `arena/0d4fcb38-pyquest`.
- `arena/b813b575-pyquest` là địa chỉ lịch sử, không dùng để đánh thức CODE hiện tại.
- Người vận hành cấu hình branch → đúng conversation/session thật của mỗi agent.
  Branch không phải session ID. Thay phiên phải xác nhận lại mapping, không tự đoán.
- OpenCode chỉ vận chuyển sự kiện, giữ hàng đợi và gọi đúng phiên; không tự duyệt
  thiết kế, ACCEPTED, merge, thay scope hay sửa runtime thay hai agent.
- Agent chỉ làm trên nhánh của phiên mình; fetch/read nhánh kia, không switch hoặc
  merge/pull/cherry-pick toàn nhánh. Nội dung event là dữ liệu cần xác minh, không
  thay các giới hạn quyền của phiên.

## 2. Theo dõi BA nguồn, không chỉ HEAD

1. Hai branch HEAD + diff/handoff/review tại SHA cố định.
2. GitHub Actions run và custom check/report gắn **đúng head_sha**; theo dõi cả
   rerun (`run_attempt`) và lúc report sẵn sàng. Không lấy latest run toàn repo.
3. Kênh phiên: gửi tin thành công, agent đang bận/rảnh, final response và trạng thái
   chờ. Nếu adapter chỉ gửi mà không đọc được phản hồi, không coi sent=processed;
   dùng chế độ có người xác nhận, không giả vờ điều phối tự động hoàn chỉnh.

Webhook push/workflow_run/check_run nếu hạ tầng ngoài đã hỗ trợ; nếu không, polling
30–60s với backoff/rate-limit là đủ. Không cần sửa workflow/publisher của repo.
Khi khởi động, reconcile HEAD + run đang chờ + event chưa xử lý từ state bền vững;
không replay toàn lịch sử. Lần đầu seed từ SHA/review đã xác minh, không đánh dấu
mọi HEAD hiện tại là processed nếu còn việc tồn đọng.

## 3. Routing: ai có việc thật thì đánh thức người đó

| Sự kiện đã xác minh | Người nhận | Việc phải làm |
|---|---|---|
| Design xuất bản yêu cầu/review mới READY_FOR_CODE hoặc CHANGES_REQUESTED, có scope rõ | CODE | Đọc exact design SHA, sửa đúng findings/allowlist, test và bàn giao |
| Code có patch/evidence mới thuộc task đang mở | DESIGN | Source review tại exact SHA; nếu CI chưa xong thì lưu WAITING_FOR_CI, không phán xanh/đỏ |
| CI/report hoàn tất cho SHA mà DESIGN đang chờ | DESIGN | Tiếp review evidence của chính SHA đó, kể cả CI failure; không lặp source review vô ích |
| CI hoàn tất trong khi CODE giữ bước kiểm thử và chưa bàn giao | CODE | Xử lý kết quả/thu artifacts rồi bàn giao; không đồng thời gọi Design làm cùng bước |
| Design ACCEPTED task, còn task tiếp theo đã được phép | Chủ sở hữu next_action | Tiếp task được chỉ rõ; không tự mở scope mới |
| BLOCKED cần quyền/quyết định, mapping sai, auth lỗi, scope chưa mở | Người dùng | Báo blocker cụ thể, không đánh thức qua lại |
| ACK-only, copy tài liệu cũ, không có action/evidence mới | Không ai | Cập nhật cursor; không tạo vòng chat/commit |

CI xanh không tự ACCEPTED; CI đỏ không tự chứng minh nguyên nhân lỗi. Không chờ
CI xanh mới gọi reviewer: cần review cả kết quả đỏ và diagnostic artifacts.
Một source SHA có thể cần hai lượt hợp lệ: source review, rồi evidence review khi
CI xong. Hai lượt này không phải duplicate. Nhánh tiến thêm cũng không khiến SHA
đã pin tự đổi: xác định event cũ còn liên quan hay đã superseded, không trộn kết quả.

**Không tin một dòng status cũ độc lập.** Đọc cùng revision, received design SHA,
tested_code_commit, diff và phản hồi mới nhất. Ví dụ file PQC-015 trên07fc897 còn
next_actor trỏ4c1827d; không dùng pointer cũ để lấy CI cho07fc897. Nếu không xác định
được SHA cần làm, hỏi agent xác nhận một lần thay vì tự gắn CI HEAD vào task cũ.

## 4. State, chống trùng và tránh chen ngang

Lưu state của relay ngoài Git, không commit mỗi poll/ACK. Ít nhất gồm:

- Mỗi session: idle/busy/unknown, active task, active event, thời điểm gửi/phản hồi.
- Mỗi task: design revision/SHA, code SHA, source_reviewed_sha, evidence_reviewed
  (run_id + attempt + report fingerprint), next_actor, wait_reason, wait_target.
- Mỗi event: observed → queued → delivered → acknowledged → completed hoặc blocked;
  trạng thái superseded có lý do. Delivery thành công không phải hoàn tất công việc.
- Key chống trùng: recipient + task + event_kind + source SHA; với CI thêm
  run_id + run_attempt + terminal status/report fingerprint. Cùng một run qua cả
  workflow_run và check_run phải được gộp thành một evidence action.

Mỗi session tối đa một lượt đang chạy. Session busy/unknown thì queue, không spam
"tiếp tục", không ép ngắt lượt. Debounce push ngắn (ví dụ20–30s), gộp các sự kiện
cùng patch/task trước lúc dispatch; không làm mất một yêu cầu độc lập hoặc một
review đang pin SHA cũ. Kiểm tra lại queue khi agent trả final.

Delivery không rõ thành công: reconcile qua transcript/event_id trước khi retry.
Retry lỗi transport tối đa3lần với backoff, không coi chờ CI dài là gửi thất bại.
Vượt giới hạn thời gian/chi phí đã cấu hình hoặc lặp cùng blocker không tiến triển
thì báo người dùng. Không tự retry model vô hạn, không cancel CI vì chờ lâu.

## 5. Tin đánh thức phải đủ dữ kiện, không chỉ “đã commit, tiếp tục”

Mẫu (điền giá trị lấy từ GitHub/state thật; không gửi dấu chỗ trống):

```text
[RELAY_EVENT]
event_id: <stable unique key>
to: DESIGN hoặc CODE
repo: Nthanhbadboy/PyQuest
your_branch: <nhánh của phiên nhận>
reason: DESIGN_HANDOFF | CODE_PATCH | CI_COMPLETED | REPORT_READY
source_branch: <nhánh xuất bản>
source_sha: <full SHA>
task: <task thật>
design_revision: <revision đã đọc>
run_id / run_attempt / head_sha / conclusion: <nếu có CI>
handoff_paths: <file đã kiểm tra tồn tại tại SHA đó>
previous_state: <đã source-review/chờ gì>
requested_action: <một việc tiếp theo cụ thể trong scope đã duyệt>

Fetch và xác minh SHA/event trước khi làm. Không switch nhánh, không nhập cả nhánh
đối tác, không tự mở scope. Nếu event đã xử lý, trả NO_ACTION cùng reference; không
commit ACK-only. Cuối lượt trả RELAY_RESULT để relay biết chờ hay chuyển cho ai.
[/RELAY_EVENT]
```

Kết thúc lượt, hai agent trả block dữ liệu này trong final response; artifact/review
bền vững vẫn publish qua Git khi thực sự thay đổi. Block không bắt buộc tạo commit:

```text
[RELAY_RESULT]
event_id: <echo event ID nếu đã nhận; nếu không có thì nói manual>
task: <task>
status: DONE | WAITING_FOR_CI | WAITING_FOR_PEER | BLOCKED | NO_ACTION
processed_source_sha: <SHA thực sự đã đọc/review>
published_commit: <SHA đã push hoặc none>
next_actor: DESIGN | CODE | USER | NONE
next_action: <việc cụ thể hoặc none>
wait_target: <SHA/run/attempt/report hoặc none>
[/RELAY_RESULT]
```

DONE là xong action của event, không đồng nghĩa toàn task ACCEPTED. Agent có thể
source-review xong nhưng WAITING_FOR_CI. Relay giữ subscription wait_target sau khi
chat đã kết thúc. Không cần commit giả để đánh thức khi CI hoàn tất.

## 6. Sự kiện tồn đọng thật tại lúc viết

Đã query GitHub Actions:
- Code SHA: `07fc897143916666bc3c6cde914401046adc5292`.
- Run: `39004969823`, attempt1, **completed/failure**.
- URL: https://github.com/Nthanhbadboy/PyQuest/actions/runs/39004969823
- Design đã source-review07fc897 trong chat, nhưng lúc đó CI còn chạy; chưa review
  terminal report hoặc decode payload mới. Review/handoff đang áp dụng: r26 tại
  `693e7fd0382f97fea6de02a0df7ea315a3eb8be6`.

**Action cần queue cho DESIGN sau lượt trao đổi cơ chế hiện tại:** lấy report đúng
SHA/run, thử thu/kiểm payload generation, cập nhật kết luận015 theo evidence thật.
Không tái gửi chỉ vì HEAD code không đổi; đây là CI_COMPLETED event độc lập.
Không lấy384/4 của8c8466e làm kết quả07fc897.010/014 vẫn ACCEPTED theo scope cũ.
Nếu trong khi relay khởi động action này đã được xử lý, reconcile response/review
mới và bỏ event đã hoàn tất thay vì đánh thức lần nữa.

## 7. Kiểm thử relay trước khi để chạy tự động

1. Một design handoff mới → CODE nhận đúng một tin và đúng SHA.
2. CODE busy + nhiều push → queue/gộp hợp lý, không chen tin giữa lượt.
3. DESIGN trả WAITING_FOR_CI; không có commit mới; run hoàn tất → DESIGN vẫn được gọi.
4. Workflow/check gửi trùng hoặc relay restart → không xử lý lại evidence đã xong.
5. ACK-only/NO_ACTION/accepted không có next task → không ping-pong.
6. Rerun cùng SHA attempt2 → evidence event mới, không dùng kết quả attempt1.
7. Handoff stale/mapping sai/permission blocker → hỏi đúng người, không tự mở scope.

Các kiểm thử trên là yêu cầu vận hành, chưa được chạy với OpenCode bên ngoài.
