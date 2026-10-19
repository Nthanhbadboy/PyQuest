# PQC-011 r5 — evidence cho review r44

[Review / disposition](../PQD-003-r44.md) · [Relay](relay.md)

**R42-A/B source addressed, execution unverified.** PQC-011 CHANGES_REQUESTED;
blocker WAITING_FOR_PINNED_SDK_EVIDENCE. Không có correction source mới được giao.

- CODE pin: `71b0fd3fd8fb07c73596ce089fa2e68f6fe87964`.
- Parent: `2ea5e5004e98df4aec8c1132a56b8d60bf4ddf5e`.
- Hai file trong `source/` là snapshot nguyên byte từ Git, không import vào app:
  integration test và task011. Trạng thái trong task snapshot là báo cáo củaCODE,
  không tự thành DESIGN acceptance.
- [Manifest](manifest.json): blob/hash/timestamp/SDK availability và preservation checks.
- `correction.patch.json`: nguyên diff trong trường `patch`; JSON wrapper giữ
  context whitespace mà không thêm trailing whitespace vào docs.
- [Check runs](check-runs.json) và [workflow runs](workflow-runs.json): zero tại
  thời điểm đọc, không phải test PASS. Không suy mọi kiểm tra bên ngoài GitHub vắng mặt.
- [SDK binding excerpts](sdk-binding-excerpts.txt): đọc source pinnedFlutter về
  pump/runAsync và fake/real async interplay. Không cài/chạy SDK.

Chạy kiểm archive từ repo root:
`python docs/design/coordination/reviews/PQC-011-r5/verify_source.py`.
[Receipt](static-checks.json) chỉ là pin/byte/patch/metadata/link integrity, không
formatter/analyzer/Fluttertests. Không chạy importedCODEtests hoặc triggerCI.

Giữ nguyên bốn case layout scale mặc định, repository happy path rootBundle /
AssetManifest, runtime/deps/CI và các art studies. Không dùng r43HTMLPASS để accept011.
