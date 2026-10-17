# PQC-015 — ngoại lệ evidence CI hẹp do Lead mở ở r27

Căn cứ: LEAD_MANDATE_2026-10-17 và report117319893254@07fc897. Bốn probe chunk fail
nhưng report chỉ có chunk0, không thể khôi phục payload đầy đủ; native job log không
truy cập được từ sandbox reviewer. Không tiếp tục vận chuyển file bằng test cố ý fail.
Đây là thay đổi scope **mới có chủ đích**, thay giới hạn “không CI/publisher” của
r24–r26 chỉ cho phần sau; không tuyên bố các patch trước đã được phép sửa CI.

## Allowlist bổ sung (ngoài015 hiện có)

- `.github/workflows/ci.yml`: chỉ job `check`, gọi collection/generation verification
  và publish evidence. Không sửa triggers, permissions, bootstrap, apk/emulator,
  SDK version, dependencies hay bỏ analyze/ordinary/render tests.
- `ci/l10n_evidence.py`: helper stdlib Python cho collection/verification/publication
  evidence015 (có thể tách collect/publish subcommands trong cùng file).
- `ci/test_l10n_evidence.py`: unit tests helper với fixtures temp nhỏ; không thêm deps.
- Evidence JSON tạm trong CI không commit; bản source output đã decode phải vào
  `app/lib/l10n/generated/**` trên nhánh CODE, kèm receipt dưới implementation docs.

Không cần sửa `ci/report.py`, `ci/publish_previews.py` hoặc xây hệ thống CI mới.
Dùng check riêng `PyQuest l10n evidence` qua API checks hiện có, head_sha bằng SHA
runner thực. Token chỉ từ GitHub Actions environment như publish hiện có, không
ghi token vào file/check/chat. Không thêm quyền hoặc yêu cầu user cấp secret.

## Hành vi cần đạt

1. Sau pub get, chạy `flutter gen-l10n` với SDK đang pin; ghi command, SDK revision,
   exit status. Chạy lần2 và so sánh **tập tên file + bytes/hash**, kể cả file mới
   chưa tracked hoặc output stale dư. Không dùng riêng `git diff --quiet` làm
   bằng chứng vì nó bỏ qua untracked files.
2. Đối chiếu output đầy đủ với bộ generated Dart commit tại tested SHA. Bản hiện
   tại chưa có output đúng, vì vậy lượt thu artifacts đầu có thể báo drift đỏ thật;
   không đổi status cho xanh. Sau nhập output phải rerun trên SHA mới và không drift.
3. Publish đủ base/_en/_vi source trong envelope JSON hoặc gzip/base64 có tổng hash,
   danh sách filenames/per-file sha256, tested SHA, run ID/attempt và kết quả hai
   lần generate. Reviewer có thể decode **toàn bộ** từ api.github.com, không cần
   tải blob ngoài allowlist. Chỉ đọc đúng generated Dart dưới đường dẫn015; chặn
   traversal/symlink ra ngoài, không quét workspace hoặc thu env/credential files.
4. Check evidence có ngân sách rõ (dưới giới hạn API64000 ký tự cho output.text).
   Với bộ015 nhỏ, một envelope đủ; nếu vượt giới hạn, fail rõ thay vì cắt payload
   hoặc phát hàng loạt test đỏ. Lỗi publish phải trả nonzero, không giả đã bàn giao.
5. Kết quả gen/repro/committed-drift phải đi vào status/exit của job check, không chỉ
   in thông báo rồi workflow vẫn xanh. Không bỏ các status/test cũ; không diễn giải
   check evidence xanh là toàn bộ app ACCEPTED.
6. Giữ thông tin failure thật nếu còn widget test đỏ: có thể publish một mục nhỏ
   trong check evidence chứa first exception/context của các test015 từ test.txt,
   giới hạn kích thước và ghi rõ nếu không tìm thấy. Không bịa cause từ elapsed time.
7. Khi đường evidence thật hoạt động và có output đầy đủ, bỏ generation_probe_test
   cố ý fail; thay bằng verification thật ở CI/test phù hợp. Không chỉ xóa probe
   rồi bàn giao generated files vẫn sai. Có thể cùng patch đưa evidence channel mới
   và bỏ probe, nhưng acceptance phải có artifact thực + gen rerun trên SHA bàn giao.

## Kiểm thử helper / bàn giao

Unit tests tối thiểu: round-trip envelope/hash; thêm file untracked cũng bị phát hiện;
byte/name drift; thiếu file/lệnh gen lỗi không bị báo pass; payload quá lớn; path
unsafe; publication failure được truyền thành nonzero. Mock gh/subprocess trong
unit tests, không tạo check thật khi chạy tests local.

Code tự chạy Python tests, diff-check, CI đúng SHA. Trả riêng hashes/output generation,
repo drift/repro, ordinary/render/analyze và lỗi còn lại. Reviewer không cần đoán
artifact từ một số pass hoặc một test name. Không thêm diagnostic-only commit nối
tiếp khi các sửa semantics/createTemp đã biết vẫn chưa xử lý.
