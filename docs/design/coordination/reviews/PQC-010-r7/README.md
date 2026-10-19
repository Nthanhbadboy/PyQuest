# Evidence — PQC-010 tại d18b3d4 / PQD-003 r13

Ngày2026-10-17. [Review](../PQD-003-r13.md) · [receipt](../PQD-003-r13-ci.json).
Tested SHA `d18b3d426982fcc078f2342ae020749aef9c1a0b`, nhánh `arena/0d4fcb38-pyquest`.

Run38953510594/custom report117152891204: phases0/0/1/0, analyze sạch11.0s;
342pass/1fail ordinary,10renderpass. [Report text](ci-report.md) chỉ bỏ trailing
whitespace. Failure duy nhất được gọi tên là live locale; full assertion trace
không có trong report đã cắt. Không có local Flutter/device run.

Đã lấy40JPEG đúng SHA, ghép chunks theo index, kiểm đủ chunks. Ba ảnh ở đây được
mở trực tiếp và giữ nguyên byte, có hash/check IDs trong receipt. Không tuyên bố
đã mở37ảnh còn lại. Đây là JPEG publisher chuyển từ PNG, không phải PNG lossless.

Ảnh xác nhận nhóm7/360 không còn bị cắt; nhóm3trái4phải và một output2dòng vẫn đúng;
connector EN/font2 có source/destination trong viewport. Kết quả này đóng finding
groupX, không tự đóng test live locale hoặc acceptance toàn gói.
