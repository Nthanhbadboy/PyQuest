# Evidence — PQC-010 vòng4 / PQD-003 r10

Ngày2026-10-17. [Review](../PQD-003-r10.md) · [receipt](../PQD-003-r10-ci.json).
Code branch hiện tại: `arena/0d4fcb38-pyquest`, SHA
`2bb2c697820e8689e44e4471c50c9a5b79dd3dd4`.

[Run38943424997](https://github.com/Nthanhbadboy/PyQuest/actions/runs/38943424997),
custom report117118848668: phases0/0/1/0, analyze sạch9.6s,336pass/7fail ordinary,
render chung10pass. [Report](ci-report.md) chỉ chuẩn hóa trailing whitespace.
Report có4failure names;3tên bị cắt. Code agent báo full download EOF; review không
có full log và không tự gán tên cho phần thiếu. Không chạy Flutter/Dart/device local.

## 40ảnh đúng SHA,8ảnh đã mở và lưu

Đã lấy40JPEG qua64check chunks, ghép theo index và kiểm đủ chunks. Receipt ghi
check IDs/hash/bytes/source SHA của cả40. Tám ảnh có `path` là ảnh đã mở trực tiếp
và lưu ở thư mục này;32ảnh khác đã lấy/hash nhưng không tuyên bố đã mở từng ảnh.
Đây là JPEG của publisher, không phải PNG lossless gốc, không sửa/repaint ảnh.

Ảnh cho thấy nền trắng/chữ thật/mũi tên đã tiến bộ. Các ảnh font2/360 đang ở đầu
scroll và chưa thấy đủ target output/wait/connector. Ảnh numbers font1 cho thấy
hai nhóm3/4 xếp dọc dù copy nói trái/phải, và hai ô output cùng tên ởb3/b4. Chi tiết
và yêu cầu sửa trong review; không đánh đồng viewport crop với runtime overflow.
40ảnh publish được không chứng minh pixel assertions đã pass: test capture còn đỏ.
