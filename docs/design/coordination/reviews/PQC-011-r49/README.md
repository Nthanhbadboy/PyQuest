# PQC-011 r49 — pinned SDK executed, corrections required

**2026-10-18 · CHANGES_REQUESTED / PINNED_SDK_EXECUTED_FAILURE**

Không còn blocker “SDK chưa có”. Đây là kết quả thực thi thật, không phải review
source hoặc fake-Flutter tests. Không có APK mới; build job bị gate chặn.

## Identity và evidence

- Source CODE: `de01a490743982356ad5240d77ea99e9dbf8c7f5` (app không đổi so với71b0).
- Workflow/harness DESIGN: `ca29dd17a5ca0160a8565d6312ec2e7506f2ff4b`.
- [Actions run39078131829](https://github.com/Nthanhbadboy/PyQuest/actions/runs/39078131829): **failure**.
- Verification job117529428071; build job117529872654 **skipped**, không chạy step build.
- [Source check117529542022](https://github.com/Nthanhbadboy/PyQuest/runs/117529542022): **failure**,
  gắn trực tiếp với CODEde01a49, không nhầm SHA workflow là SHA app.
- `source-check.json`: snapshot GitHub Checks API (summary, diagnostic excerpts).
  `run.json`, `jobs.json`, `artifacts.json`: metadata API độc lập; `receipt.json`:
  kết quả review và hashes. Full logs ở verification artifact; đường tải Azure từ
  workspace trả EOF, không được giả là đã tải/đọc toàn bộ artifact.

## Kết quả thực tế

| Gate | Kết quả |
|---|---|
| SDK | Flutter3.47.7 / Dart3.13.5 / frameworkabaf9c523780a608bd46686fd5e53740a07077f8 đúng pin |
| pub get | exit0, nhưng làm đổi lockfile (xem gate drift) |
| Formatter | **FAIL**,13file cần format; dùng `--output=none`, không sửa source |
| Localization evidence helpers | **8 pass** |
| Localization generation evidence | **PASS** |
| Analyze | **PASS**,No issues found |
| Focused Settings | **12 pass,0 fail** |
| Actual LessonScreen integration | **0 pass,7 fail** |
| Ordinary suite | **415 pass,7 fail**,không phải suite PASS |
| Render suite | **10 pass,0 fail** |
| Source drift | **FAIL**; log cho thấy ít nhất `app/pubspec.lock` bị cập nhật |
| APK | **NOT_BUILT**,job skipped |

Settings/integration là subset của ordinary, không cộng lại. Trong
`test-counts.json` của runner, `passed=null` cho suite fail vì extractor chỉ đếm
“All tests passed!”. Counts415/7 và0/7 ở bảng trên lấy từ terminal summaries thật
trong diagnostic excerpts, không suy `null` thành0 hay PASS.

### R49-A — test helper không settle

Cả7case dừng tại `pumpAndSettle timed out`; stack trỏ
`_mountLesson`, `app/test/lesson_board_integration_test.dart:470`.
Không được kết luận từ đó rằng app/device runtime hỏng; test chưa tới các
assertions nghiệp vụ. CODE phải tìm nguồn frame/async chưa ổn định, dùng ready
predicate + bounded pump/real-async khi cần, không tăng timeout để che lỗi.
Giữ đủ assertions trước đây, nhất là Run→Continue VI/360×640/2× và delivery
completion sau step change/unmount. Không dùng fake bundle cho happy path.

### R49-B — formatting

13Dartfile được liệt kê trong `source-check.json` và correction order. Đây là
formatter check thật trên Dart3.13.5; không được gọi source “đã format” trước
khi formatter exit0 ở SHA cuối.

### R49-C — lockfile drift

`pub get` trên source pin thêm package records cho các dependency đã có trong
pubspec (ví dụ flutter_sound/record/web_socket_channel) và sắp xếp lại entries.
Gate này là kiểm tra reproducibility bổ sung r49, không phải bằng chứng phải
thêm dependency/product feature mới. Cho phép regenerate **lockfile** bằng
SDK pin; không sửa pubspec/constraints, không `pub upgrade`, không nâng SDK.
Nếu drift khác ngoài scope đã cho phép thì báo diff để triage, không tự stage.

## Correction order và giới hạn

Xem [correction-order.md](correction-order.md) và [relay.md](relay.md).
Không cần ACK-only. CODE thực hiện source correction trên nhánh của CODE rồi
trả final SHA + bằng chứng pinned-SDK. DESIGN kiểm tra độc lập và build owner-test
sau gate; không tự mở rộng sang runtime/UI/voice/backend/token limits.

PQC-018 art và PQC-019 review lịch sử không bị mở lại. Quyền dùng Actions và nhúng
key cho lần thử nội bộ vẫn có hiệu lực. Repository public nên đường APK mới dùng
recipient-encrypted artifact, không upload APK có key dạng thường. Private
recipient key chỉ ở workspace ngoài Git; chưa có APK thật để giải mã hay test.

## Chronology và local checks (không thay SDK evidence)

1. `1dbc4f3` / run39077780697 bắt đầu execution. Khi xác nhận repo public, REST
   cancel trả403; push concurrency guard đã hủy run. API xác nhận build không chạy.
2. `e6471b0` / run39077867619 chạy checks, failure; build public bị chặn.
3. `ca29dd1` / run39078131829 bổ sung encrypted transport và Checks API publication;
   kết quả ở trên đọc được trực tiếp, không phải suy từ run2.
4. Local15policy +5fake-SDK harness tests PASS; YAML/shell syntax và5publisher
   outcomes PASS; failure-count extractor được cải tiến sau run, chưa rerun SDK; AES-256-GCM/RSA-OAEP roundtrip với payload tổng hợp PASS. Không
   dùng chúng để tuyên bố APK/SDK/device PASS.
