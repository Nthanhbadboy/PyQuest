# APK thử nội bộ — thay đổi chính sách r49

**2026-10-18 · user-authorized · chưa phải kết quả thực thi.**

Người dùng cho phép nhúng Gemini key trong APK để chính họ thử, hoãn token ngắn
hạn/backend/giới hạn token; đồng thời xác nhận GitHub Actions có thể dùng thoải mái.
Quyết định này thay thế giới hạn keyless-only của r47/r48 cho **đường thử nội bộ**,
không phủ nhận review lịch sử và không cho phép public/store release.

## Request và phạm vi

- Workflow: `.github/workflows/build-debug-apk.yml`, chỉ nhánh DESIGN
  `arena/00838eb9-pyquest`; manual dispatch hoặc push có `[preview-apk]`.
- Source CODE pin: `de01a490743982356ad5240d77ea99e9dbf8c7f5`. Không merge app của
  CODE vào DESIGN, không đẩy commit sang nhánh CODE, không thay runtime/dependencies.
- SDK: Flutter **3.47.7**, framework
  `abaf9c523780a608bd46686fd5e53740a07077f8`, Dart **3.13.5** trên Actions runner.
- Harness thuộc workflow SHA, checkout riêng với app source SHA. Evidence ghi
  cả hai, không dùng HEAD của DESIGN làm source pin của APK.
- Mỗi request mới phải ghi lại source SHA tin cậy; fallback push được pin literal
  trong workflow. Không package tip di động hoặc tự lấy code mới mà không review.

## Hai gate riêng

1. `verify-source`: SDK pin, pub get, formatter không sửa file trong scope011,
   localization helper/evidence, analyze, Settings12, actual LessonScreen
   integration, ordinary suite và render suite. Chạy các phase độc lập để lỗi
   format không che các lỗi test; bất kỳ phase fail đều làm job fail.
   Counts thật ghi `test-counts.json`, không cộng Settings/integration subset vào
   ordinary. Ordinary giữ tối thiểu406, integration tối thiểu7, render tối thiểu10.
2. `build-android` chỉ chạy sau khi `verify-source` thành công. Build release-mode
   mặc định (không phải public release), tùy chọn debug. `internal_voice=true`
   yêu cầu repository secret `GEMINI_API_KEY` không rỗng; thiếu secret thì **fail**,
   không lặng lẽ giao bản keyless rồi gọi là bản voice. `false` tạo define rỗng.

Key chỉ cấp cho step build; file define tạm quyền0600 ngoài source được xóa khi
step kết thúc. Không ghi key vào repository/log/receipt/chat. APK **có thể bị
trích xuất key**; secret tại Actions không bảo vệ key bên trong APK. Chỉ chủ tài
khoản tải/cài thử, không chia sẻ công khai. Artifact owner-test giữ3ngày, evidence
không chứa secret giữ14ngày; thời hạn retention không thu hồi bản đã tải xuống.

`.github/workflows/ci.yml` thông thường vẫn keyless và không bị thay gate. r49
không sửa các workflow bên CODE. Khi đồng bộ sau này phải giữ cấu trúc/gate CODE,
không chép đè workflow DESIGN. Không đòi CODE ACK-only cho quyết định chính sách.

## Evidence và nghiệm thu

- Local: policy regression và fake-SDK harness tests chỉ chứng minh orchestration,
  **không** chứng minh Flutter/analyzer/tests thật hoặc APK đã build.
- Actions: phải ghi run ID/URL, job/check IDs, source/workflow SHAs, logs/counts và
  kết luận thật. Formatter fail cần CODE sửa đúng scope và chạy lại source SHA mới.
- APK: artifact ID, filename, SHA256, `build-info.txt`; build thành công **không**
  chứng minh cài/chạy, micro/loa, Gemini authentication hay voice trên thiết bị.
- Người dùng thử theo [voice checklist](experimental/GEMINI_LIVE_VOICE_TEST.md).
  Token mediation/quota chưa triển khai, không dùng nó để chặn lần thử nội bộ này.
- Các receipt/patch r47/r48 giữ nguyên để kiểm toán; không rerun validator cũ để
  ghi đè evidence lịch sử. PQC-019/018 không mở lại; PQC-011 chưa được tự nhận PASS.

## Kết quả thực thi

Chưa có kết quả tại lúc tạo request r49. Run/source/artifact phải được bổ sung từ
GitHub Actions thật, không suy ra từ cấu hình hoặc bộ kiểm tra giả lập.
