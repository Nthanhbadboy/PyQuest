# PyQuest — trạng thái source, bằng chứng và phát hành

**2026-10-18 · r47 · không phải chứng nhận runtime mới.**

Tài liệu này phân biệt **có source**, **đã kiểm chứng tại một SHA**, **thiết kế** và
**kế hoạch**. Product Vision/Game Design/Technical Architecture/Roadmap giữ vai trò
riêng; không lấy checklist hoặc hình concept làm trạng thái triển khai.

## 1. Mốc đối chiếu

- CODE được đọc: `71b0fd3fd8fb07c73596ce089fa2e68f6fe87964` trên
  `arena/0d4fcb38-pyquest`. Chưa có bằng chứng thực thi pinned-SDK được nhận cho011
  tại SHA này. Không suy PASS từ việc source đã sửa.
- DESIGN trước đợt sửa tài liệu này: `c68bdcd73b400c4d449216023a54499b202bda1d`
  trên `arena/00838eb9-pyquest`; đã giao study r46, chưa port toàn bộ vào Flutter.
- Bằng chứng runtime lịch sử: source `a9bcdcf8e3203ee17b1a5de0b9ebff6a0e8dd32d`,
  run39051006962:406 ordinary +10 render;12 focused Settings là subset, không cộng
  lần nữa. Build APK run39052978443 không thay kiểm tra cài/chạy/voice trên thiết bị.
  Các kết quả này **không chuyển thành PASS cho CODE71b0 hoặc tip mới hơn**.

## 2. Ma trận tiến độ thay cho dấu tick tổng quát

| Phần | Source tại mốc đối chiếu | Bằng chứng / việc chưa đóng |
|---|---|---|
| Foundation, SQLite, điều hướng | Đã có; không khởi tạo lại | Có evidence lịch sử nói trên; không coi mọi tiêu chí Foundation đã nghiệm thu trên tip |
| Main Map | Đã có hub và registry6 module | UI thế giới2,5D mới chưa được port toàn bộ; concept không phải APK mới |
| Các hoạt động chơi | Robot Maze, Dragon Jump, Catch the Stars, Bug Hunter; Maze có Creator | Liệt kê4 hoạt động, trong đó Bug Hunter là debug; không còn tóm tắt thiếu bằng “ba mini-game” |
| Energy / rewarded ads | Energy hồi theo thời gian và lưu SQLite; **rewarded-ad SDK chưa có** | Ads/quota/reward callback/policy trẻ em là kế hoạch, không phải feature đã hoạt động |
| Interpreter mô phỏng | Có tập con Python viết bằng Dart và các bộ đếm/giới hạn | Không phải Python đầy đủ hoặc sandbox được chứng nhận; cần kiểm tra coverage, cấp phát và thời gian của từng operation |
| Main Quest | Chặng1 có12 bài/64 bước; Tutor ngoại tuyến và relay văn bản có source | Không nói toàn bộ các chặng hoặc board AI/freehand/voice-sync đã hoàn tất |
| Voice Gemini Live | Đường thử nghiệm direct API có trong source | Chưa có token ngắn hạn/server mediation production; CI mới không đưa key vào APK; không có device voice PASS mới |
| Side Maps, Pro, cộng đồng/Arena mở rộng | Thuộc kế hoạch sản phẩm, chưa đủ implementation | Không bán/claim quyền lợi chưa triển khai |
| Nhà–đất–đảo, visit/pet và skin mới | Đã có thiết kế và các study có giới hạn | Không dùng HTML/JS/art PASS thay runtime, quyền chia sẻ hay commerce thật |

64 tiêu chí lịch sử trong Roadmap là **tiêu chí kế hoạch**, không phải64 task chưa
bắt đầu, cũng không được đánh dấu hoàn tất hàng loạt vì thấy source. Khi nghiệm
thu một tiêu chí cần ghi rõ scope, SHA, log/test/device evidence và giới hạn.

## 3. Disposition phối hợp hiện hành

| Task | Disposition có thẩm quyền | Nguồn |
|---|---|---|
| PQC-010 /014 /015 /016 | Đã nhận trong phạm vi riêng; không có nghĩa whole-app complete | Snapshot/evidence lịch sử ở §1 |
| PQC-011 | **CHANGES_REQUESTED / WAITING_FOR_PINNED_SDK_EVIDENCE**; R42-A/B **SOURCE_ADDRESSED / EXECUTION_UNVERIFIED** | [Review r44 tại DESIGN8f754a1](https://github.com/Nthanhbadboy/PyQuest/blob/8f754a16c829264747b6517c7f7bacb3c8769283/docs/design/coordination/reviews/PQD-003-r44.md) |
| PQC-018 | **REVIEWED_WITH_LIMITS — ART_SCOPE_COMPLETE**; không runtime/production approval | [Task revision4 tại DESIGN30394b7](https://github.com/Nthanhbadboy/PyQuest/blob/30394b7bb23ad1fcf371c8dee644fd6caaf3793d/docs/implementation/coordination/tasks/PQC-018.md) |
| DESIGN r45 /r46 | Maze selection và Creator interaction study đã giao | [Visual status tại DESIGNc68bdcd](https://github.com/Nthanhbadboy/PyQuest/blob/c68bdcd73b400c4d449216023a54499b202bda1d/docs/design/VISUAL_DESIGN_STATUS.md) |
| Runtime R1 /R4 | Chưa mở | Cần order/asset/allowlist/gates riêng; không suy quyền từ art study |

**Độ lệch nhánh đã phát hiện:** CODE71b0 còn câu ads đã có, chỉ dẫn bắt đầu
Foundation và header018 `IN_PROGRESS`; DESIGN đã sửa các mục đó từ trước r47.
Bản cập nhật r47 và patch đồng bộ phải được CODE áp dụng trên nhánh của CODE;
không coi việc DESIGN push hoặc đối tác fetch là đã đồng bộ working tree.
PQC-011 và acceptance lịch sử không bị sửa/đóng lại trong việc đồng bộ này.

## 4. APK và bí mật: chính sách từ r47

- Hai workflow `.github/workflows/ci.yml` và `build-debug-apk.yml` **không đọc
  repository secret `GEMINI_API_KEY` để build**, và truyền define rỗng rõ ràng cho
  mọi lệnh build APK. Không thêm tùy chọn opt-in đưa key dài hạn vào CI artifact.
- Hệ quả: APK tạo bởi cấu hình workflow mới **không có Gemini key từ đường build
  đó**; direct Gemini Live voice không xác thực được. Đây là thay đổi có chủ ý,
  không phải lỗi cần khắc phục bằng cách thêm lại secret. Tutor ngoại tuyến/relay
  văn bản không bị sửa; hành vi trên APK vẫn phải được kiểm chứng khi có build.
- `--release` chỉ là build mode, **không phải cho phép phát hành công khai**.
  Signing, quyền phân phối, token/backend, an toàn trẻ em và kiểm tra thiết bị vẫn
  là các gate riêng. Keyless không đồng nghĩa đã đạt mọi yêu cầu bảo mật.
- Source vẫn cho phép đường thử nghiệm cục bộ qua dart-define; sửa workflow không
  vô hiệu hóa mọi cách tự build có key. Đường đó không được upload/phân phối như
  artifact tiêu chuẩn. Xem [hướng dẫn voice](experimental/GEMINI_LIVE_VOICE_TEST.md).
- Workflow cũ có thể đã đóng gói key nếu secret tồn tại. Sửa hôm nay **không xóa
  key khỏi APK cũ, không thu hồi artifact và không tự xoay key**. Chưa đọc secret,
  chưa phân tích APK cũ, chưa kết luận lộ key. Chủ tài khoản cần rà soát phạm vi
  phân phối, thu hồi/xoay key nếu đã đưa vào bản chia sẻ; không gửi key qua chat.

## 5. Giới hạn của đợt sửa

Chỉ sửa tài liệu, cấu hình đóng gói và kiểm tra local của chính sách đó. Không sửa
app/runtime/dependencies, không cài SDK, không dispatch/rerun CI, không tạo APK
hoặc tuyên bố đạt Flutter/Python/device tests. CODE sync là task riêng, không phải
ACK-only và không mở lại source corrections của011 hay art scope018.
