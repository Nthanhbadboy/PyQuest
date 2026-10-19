# Evidence — PQC-010 vòng2 / PQD-003 r8

- Tested code: `4a2a5826a3d9717190aa7147fe78287b472cac7d`.
- [Review](../PQD-003-r8.md) · [machine-readable receipt](../PQD-003-r8-ci.json).
- [Run38924022896](https://github.com/Nthanhbadboy/PyQuest/actions/runs/38924022896).
- [Raw custom report117057301755](ci-report.md): analyze sạch12.7s;
  ordinary316pass/6fail, render10pass; phases0/0/1/0. Không nghiệm thu.

## Ảnh lấy độc lập

`board-mq1_01_s2-b1-code-highlight-390x844-font1.0-vi.jpg` được decode nguyên byte
base64 từ check117056733450 của đúng SHA, không vẽ lại hoặc sửa nền. Đã mở trực tiếp:
font chữ thật nhưng nền đen/chữ tối, chưa đạt visual acceptance. File10776B, SHA256
`f16cfc1dcaf4185db3483b6e3d2fbcf35dbe0c49f34788d0eca934f3f37a61e4`.

Đây là **JPEG của publisher chuyển từ PNG**, không phải PNG lossless nguyên gốc.
Chỉ có1board image trong checks đã lấy, không có bộ40ảnh mà source test dự định chụp.
Ảnh app khác/10render pass không bù cho board evidence còn thiếu. Không dùng ảnh này
làm bằng chứng production lesson/device/AI/voice; đây là renderer trong test host.

## Giới hạn log và kiểm thử

Full log qua `gh run view --log-failed` lỗi EOF khi tải signed archive. Custom report
cắt phần giữa, danh sách cuối chỉ4failure names +2more; job annotations không có
hai tên còn thiếu. Giữ giới hạn này công khai, không suy tên từ source hoặc tự gán
nguyên nhân timeout/exception khi chưa có stack trace. Code agent cần trả log đủ.

Không có Flutter/Dart/device local; không chạy test Flutter ở nhánh design. Review
đối chiếu source, JSON fixtures, hashes, CI report và ảnh. Guard không thay đổi so
với bản đã kiểm37tests ởr7; không trình bày kết quả cũ như một lượt chạy mới.

Receipt report chỉ chuẩn hóa khoảng trắng cuối dòng; không phục dựng phần log bị cắt.
