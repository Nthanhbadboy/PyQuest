# Scoped runtime guard — PQD-003 r6

`scoped-runtime-r6.patch` là delta nhỏ cho **tool hiện có** trên code4315d39:
- `tools/coordination/pq_lead.py`
- `tools/coordination/test_pq_lead.py`

Không thêm runner, auto-delegation hoặc polling. Design giữ patch thay vì copy cả
hai file code sang nhánh design. Mã gốc được lấy bằng git show4315d39; patch đã được
áp vào bản extract và chạy **37 tests PASS (30 cũ +7 scoped-runtime)** bằng Python3.
Kết quả/provenance ở `scoped-runtime-r6-check.json`.

## Vì sao phải nhận trước khi bật runtime

do_brief cũ chỉ xét runtime=yes và READY_FOR_CODE của **task design**, nên có thể
in ALLOWED cho008 vốn BLOCKED. R6 chỉ mở010/014/015. Guard mới còn kiểm:
- ID trong `authorized_runtime_work_orders` (match chính xác, không wildcard).
- Order header đúng work_order, status READY_FOR_CODE, source_task đúng task design.
- dependency_change_required có giá trị yes/no rõ; yes cần cờ dependency và whitelist
  riêng. R6 chỉ có015 được dependency, không tự mở005 cũ.

Nó không tự chứng minh diff giữ file allowlist hay prerequisite014 đã xanh; code
agent/reviewer vẫn kiểm những điều đó trước từng gói, và phải fetch mới trước brief.

## Cách nhận trên nhánh code của phiên

1. Pin SHA design r6 bằng fetch; bảo vệ thay đổi đang có. Lấy đúng patch và ba orders,
   không merge/cherry-pick cả nhánh design. So với code4315d39 nếu tool đã thay đổi.
2. Từ repo root, dùng đường dẫn patch đã lấy:

```sh
git apply --check /path/to/scoped-runtime-r6.patch
git apply /path/to/scoped-runtime-r6.patch
python3 tools/coordination/test_pq_lead.py
python3 tools/coordination/pq_lead.py --task PQD-003 fetch
python3 tools/coordination/pq_lead.py --task PQD-003 brief PQC-010
python3 tools/coordination/pq_lead.py --task PQD-003 brief PQC-014
python3 tools/coordination/pq_lead.py --task PQD-003 brief PQC-015
python3 tools/coordination/pq_lead.py --task PQD-003 brief PQC-008
python3 tools/coordination/pq_lead.py --task PQD-003 brief PQC-005
```

Hai lệnh cuối phải trả BLOCKED/nonzero (nếu005 order chưa được nhập thì missing cũng
không phải quyền ALLOWED). Không sửa flag old order để làm tất cả brief xanh.
Patch conflict → đọc delta và port cùng logic/tests; không force overwrite tool mới.
Commit coordination fix cùng gói010 hoặc riêng commit nhỏ, **không dừng ở ACK-only**.

Ghi nhớ: tests dùng fake Git cho lỗi network/locks chỉ chứng minh guard/tool, không
chứng minh một model đã được đánh thức hay bắt đầu code. Phiên code thực hiện việc.
