# r47 — sửa tài liệu và đóng đường CI đưa Gemini key vào APK

**2026-10-18 · DESIGN_FIX_DELIVERED / CODE_SYNC_PENDING**

User yêu cầu “sửa” sau audit. Gói này sửa nhánh DESIGN và cung cấp patch riêng cho
CODE71b0; không ghi trực tiếp lên nhánh CODE, không merge runtime hai nhánh.

## Đã sửa

1. README + bốn tài liệu chính trỏ tới
   [PROJECT_STATUS](../../../../PROJECT_STATUS.md): source, evidence, kế hoạch và
   release policy tách riêng. Bỏ claim toàn app không bao giờ chứa API key.
2. Ads giữ ở kế hoạch; đủ Robot Maze / Dragon Jump / Catch the Stars / Bug Hunter;
   không bắt đầu lại Foundation. 64 tiêu chí kế hoạch được giữ nguyên nội dung,
   không dùng checkbox hoặc dấu tick tổng quát làm trạng thái nghiệm thu.
3. Interpreter: phân biệt counters/config với coverage đã được kiểm chứng;
   output10000 ký tự, collection10000 phần tử không phải trần bộ nhớ/sandbox pass.
4. Hai workflow, ba lệnh APK build đều truyền `--dart-define=GEMINI_API_KEY=`;
   bỏ env lấy Gemini repository secret. Không thêm opt-in bypass, không đổi gates.
   Release-mode chỉ là preview build mode, không phải quyền phát hành công khai.
5. Hướng dẫn voice không còn bảo dùng CI secret để bật voice. APK mới của đường
   workflow này không xác thực direct Gemini Live. Chưa triển khai token mediation,
   chưa sửa runtime; không lấy việc build keyless làm voice PASS.
6. Header/metadata018 và nhãn lịch sử trỏ về disposition r40;011 giữ blocker r44.
   CODE sync thuộc [PQC-019](../../../../implementation/coordination/tasks/PQC-019.md),
   không ACK-only, không mở lại task018 hoặc sửa authored board.

## CODE không bị overwrite bằng file DESIGN

[code-sync.patch](code-sync.patch) tạo từ **exact CODE
`71b0fd3fd8fb07c73596ce089fa2e68f6fe87964`**, chỉ13file.
[Manifest](patch-manifest.json) có SHA-256 trước/sau và patchhash. Đặc biệt giữ
workflow trigger, job condition, SDK pin, formatter/analyzer/integration/test gates
riêng trên CODE. Hai bản workflow của hai nhánh không giống nhau; không copy cả file.

Đã `git apply --check` rồi apply vào cây source tạm, chạy checks và so hash đầu ra.
**Không có nghĩa remote CODE đã nhận patch.** CODE cần nhận order019 và xuất bản
commit của mình; [relay](relay.md) là tin để OpenCode chuyển nguyên văn cùng SHA
DESIGN của gói này. Không sửa secret, không dispatch/rerun CI để đồng bộ tài liệu.

## Bằng chứng local

- [Receipt](receipt.json): `PASS_LOCAL_DOCS_AND_PACKAGING_POLICY_ONLY`.
- [DESIGN tests](design-tests.log):12/12 PASS.
- [CODE patch trial tests](code-patch-tests.log):12/12 PASS trên snapshot tạm.
- Mỗi lượt test có6 shell expansions chạy **fake Flutter**, với sentinel giả trong
  env, kiểm tra argv chỉ có Gemini define rỗng. Không cài/chạy Flutter hoặc đọc key.
- PyYAML6.0.3 trong cache parse4 bản workflow sau sửa (2 nhánh×2file); so cấu trúc
  trước/sau, ngoài thay đổi packaging đã cho phép thì giữ nguyên.
- Bảo toàn64 tiêu chí mỗi nhánh,13 filehash đầu ra, các link tài liệu mới và3link
  source pin của trạng thái. App và task011 không đổi.

Static checker bảo vệ các lệnh build literal hiện có, không là shell/YAML security
analyzer tổng quát hoặc chứng minh APK không chứa bất kỳ bí mật nào. Không build,
inspect hay cài APK; không có Flutter/Dart/device tests mới. Không đọc repo secret,
không kết luận đã lộ key. Workflow cũ/artifact cũ/key cũ **không được thu hồi hoặc
xoay tự động**; chủ tài khoản phải rà soát nếu đã phân phối bản có key.

## Chạy lại local

```sh
python tools/maintenance/test_release_policy.py
python tools/maintenance/check_release_policy.py
PYTHONPATH=/home/user/.cache/pyquest-r47/yaml \
  python tools/maintenance/validate_r47_delivery.py
git diff --check
```

Hai lệnh đầu chỉ dùng stdlib. Validator cuối cần PyYAML6.0.3 ngoài repo; cache ở
trên là môi trường kiểm tra lần này, không phải dependency mới của app/CI. Thiếu
parser thì validator dừng, không tự coi YAML đã PASS. Không có workflow CI mới
được gắn để chạy các script này và không có SDK được cài.

[Task DESIGN PQD-010](../../tasks/PQD-010.md) ghi phạm vi và trạng thái bàn giao.
