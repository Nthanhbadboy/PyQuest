CODE — PQC-011 correction r49, KHÔNG ACK-only.

Đọc `docs/design/coordination/reviews/PQC-011-r49/{README.md,correction-order.md,source-check.json}` trên nhánh DESIGN `arena/00838eb9-pyquest` sau khi fetch. Đây là bounded order mới, không merge nhánh DESIGN hoặc chép đè workflow CODE.

User đã cho phép GitHub Actions thoải mái. DESIGN đã thực thi thật source CODEde01a490743982356ad5240d77ea99e9dbf8c7f5, workflowca29dd17a5ca0160a8565d6312ec2e7506f2ff4b:
https://github.com/Nthanhbadboy/PyQuest/actions/runs/39078131829
Source check117529542022, Flutter3.47.7 / Dart3.13.5 / frameworkabaf9c523780a608bd46686fd5e53740a07077f8.

Kết quả: analyze sạch; Settings12pass; render10pass; integration0pass/7fail tại `_mountLesson` line470 (`pumpAndSettle timed out`); ordinary415pass/7fail;13file chưa format; pubspec.lock bị pub get thay đổi. APK job skipped. Không còn WAITING_FOR_SDK; disposition là CHANGES_REQUESTED / PINNED_SDK_EXECUTED_FAILURE.

Thực hiện đúng allowlist trong correction-order.md: semantic test orchestration fix chỉ ở integration test; formatter-only13Dartfile; regenerate lockfile cho deps đã khai báo, không sửa pubspec hoặc nâng deps/SDK. Cho phép một workflow maintenance pin SDK trên chính nhánh CODE nếu sandbox không chạy SDK; scope normalize/publish evidence hoặc commit có guard14file, không stage-all/force/branch mới và không Gemini secret/APK. Giữ7case/assertions, không tăng timeout/skip/weaken test; không semantic runtime/UI/backend changes. Chạy lại gates trên final SHA và báo run/check/counts thật; không suy sửa mount là mọi case sẽ pass.

PQC-018/019 không mở lại, không cần whole-doc sync hoặc ACK-only. Policy mới: user cho phép owner-test APK nhúng key, hoãn token/backend/quota; packaging thuộc DESIGN, public repository chỉ được upload recipient-encrypted artifact. Không áp keyless-only cũ để chặn lần thử nội bộ, nhưng cũng không gọi run FAIL là acceptance.
