# PyQuest — trạng thái source, bằng chứng và phát hành

**2026-10-18 · source review r49 +design r51 · không phải chứng nhận runtime mới.**

Tài liệu này phân biệt **có source**, **đã kiểm chứng tại một SHA**, **thiết kế** và
**kế hoạch**. Product Vision/Game Design/Technical Architecture/Roadmap giữ vai trò
riêng; không lấy checklist hoặc hình concept làm trạng thái triển khai.

**Quyết định mới r49:** người dùng cho phép Actions và APK thử nội bộ có Gemini key.
[Request/gates](OWNER_TEST_BUILDS.md) pin CODEde01a49.
[Run39078131829/review r49](design/coordination/reviews/PQC-011-r49/README.md): SDK
đúng pin; analyze,12Settings,10render đạt;7integration fail,415ordinary pass/7fail,
13file format fail và lockfile drift. APK chưa build; không còn thiếu SDK. Token/backend/giới hạn token hoãn cho lần thử này.

**Design mới r51:** [Xưởng Python/editor/diagnostics](design/maze-python-r51/README.md)
đã có study tương tác; chỉ custom mazes, authored response lookup, không chạy Python.
Không portFlutter hoặc thay disposition011 bằng browser PASS.

**Quan sát CODE sau r51:** tip `bcf2bfc5088ca80f1a6f0fd1d2211032f5ce416a` đã có
correction commits; Actions39080793621/39080793623 tại tip có kết luận failure.
Chỉ metadata/source-file hash observation, chưa review logs/correction để nghiệm thu.
[Snapshot phạm vi quan sát](design/maze-python-r51/partner-observation.json).

**Design trước r50:** [Maze block-play/kết quả](design/maze-play-r50/README.md) đã
có study tương tác và browser evidence; chưa portFlutter, không thay disposition011.

## 1. Mốc đối chiếu

- CODE docs/packaging mới nhất đã review: `de01a490743982356ad5240d77ea99e9dbf8c7f5`;
  [PQC-019 r48](design/coordination/reviews/PQD-010-r48/README.md) đã nhận trong
  phạm vi tài liệu/keyless policy. App và task011 không đổi so với71b0; không có
  execution evidence SDK mới tại review r48. r49 đã chạy và **FAIL** như trên;
  các mốc bên dưới là pin lịch sử, không PASS của tip.

- CODE được đọc: `71b0fd3fd8fb07c73596ce089fa2e68f6fe87964` trên
  `arena/0d4fcb38-pyquest`. r49 đã thực thi trên de01a49 với cùng app source,
  nhưng chưa nghiệm thu011 vì failures. Không suy PASS từ source review.
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
| Voice Gemini Live | Đường thử nghiệm direct API có trong source | Chưa có token ngắn hạn/server mediation production; r49 cho phép key trong APK owner-test, CI thường vẫn keyless; chưa có device voice PASS mới |
| Side Maps, Pro, cộng đồng/Arena mở rộng | Thuộc kế hoạch sản phẩm, chưa đủ implementation | Không bán/claim quyền lợi chưa triển khai |
| Nhà–đất–đảo, visit/pet và skin mới | Đã có thiết kế và các study có giới hạn | Không dùng HTML/JS/art PASS thay runtime, quyền chia sẻ hay commerce thật |

64 tiêu chí lịch sử trong Roadmap là **tiêu chí kế hoạch**, không phải64 task chưa
bắt đầu, cũng không được đánh dấu hoàn tất hàng loạt vì thấy source. Khi nghiệm
thu một tiêu chí cần ghi rõ scope, SHA, log/test/device evidence và giới hạn.

## 3. Disposition phối hợp hiện hành

| Task | Disposition có thẩm quyền | Nguồn |
|---|---|---|
| PQC-010 /014 /015 /016 | Đã nhận trong phạm vi riêng; không có nghĩa whole-app complete | Snapshot/evidence lịch sử ở §1 |
| PQC-011 | **CHANGES_REQUESTED / PINNED_SDK_EXECUTED_FAILURE**; corrections R49-A/B/C, không thiếu SDK | [Actual Actions evidence + order r49](design/coordination/reviews/PQC-011-r49/README.md) |
| PQC-018 | **REVIEWED_WITH_LIMITS — ART_SCOPE_COMPLETE**; không runtime/production approval | [Task revision4 tại DESIGN30394b7](https://github.com/Nthanhbadboy/PyQuest/blob/30394b7bb23ad1fcf371c8dee644fd6caaf3793d/docs/implementation/coordination/tasks/PQC-018.md) |
| DESIGN r45 /r46 | Maze selection và Creator interaction study đã giao | [Visual status tại DESIGNc68bdcd](https://github.com/Nthanhbadboy/PyQuest/blob/c68bdcd73b400c4d449216023a54499b202bda1d/docs/design/VISUAL_DESIGN_STATUS.md) |
| DESIGN r51 /PQD-012 | Custom Python editor/diagnostics study đã giao; không runtime execution/order | [r51 spec/evidence](design/maze-python-r51/README.md) |
| DESIGN r50 /PQD-011 | Block-play Maze và result study đã giao; không runtime order | [r50 spec/evidence](design/maze-play-r50/README.md) |
| PQC-019 | **ACCEPTED_WITH_LIMITS — DOCS_AND_KEYLESS_POLICY_SCOPE_COMPLETE** tại CODEde01a49 | [Review độc lập r48](design/coordination/reviews/PQD-010-r48/README.md) |
| Runtime R1 /R4 | Chưa mở | Cần order/asset/allowlist/gates riêng; không suy quyền từ art study |

**Độ lệch nhánh đã được sửa trong phạm vi r47:** CODE71b0 từng còn câu ads đã có,
chỉ dẫn bắt đầu Foundation và header018 `IN_PROGRESS`. CODEde01a49 đã áp dụng patch
13file và DESIGN đã review độc lập tại r48, không chỉ fetch/ACK. Gói r47/receipt và
PROJECT_STATUS trong patch là snapshot lúc giao; disposition mới nằm tại review
r48 và đầu task019, không bắt đối tác tạo commit ACK-only để chép lại từng review.
PQC-011 và acceptance lịch sử không bị sửa/đóng lại trong việc đồng bộ này.

## 4. APK và bí mật: chính sách hiện hành r49

- Theo quyết định mới của người dùng, workflow owner-test được lấy Gemini key
  từ repository secret để build APK nội bộ sau pinned-SDK checks. Xem
  [phạm vi/gates/retention](OWNER_TEST_BUILDS.md). CI thông thường vẫn keyless.
- Không đưa giá trị key vào source/log/chat. Key trong APK vẫn trích xuất được;
  APK chỉ dành chủ tài khoản thử, không public/store release. Repo public nên
  artifact vận chuyển được mã hóa cho private key ngoài Git, không upload APK dạng thường.
- Token ngắn hạn/backend/quota hoãn cho lần thử nội bộ; production vẫn cần gate
  riêng. Build success không phải chứng nhận cài/chạy hay voice trên thiết bị.
- r47/r48 keyless-only là chính sách lịch sử, được thay thế trong scope owner-test;
  không sửa receipt cũ, không tự thu hồi APK hoặc xoay key đã tồn tại.

## 5. Giới hạn lịch sử r47/r48 (không phải cấm Actions ở r49)

Chỉ sửa tài liệu, cấu hình đóng gói và kiểm tra local của chính sách đó. Không sửa
app/runtime/dependencies, không cài SDK, không dispatch/rerun CI, không tạo APK
hoặc tuyên bố đạt Flutter/Python/device tests. CODE sync là task riêng, không phải
ACK-only và không mở lại source corrections của011 hay art scope018.
