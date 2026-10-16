# Evidence — PQC-010 vòng5 / PQD-003 r11

Ngày2026-10-17. [Review](../PQD-003-r11.md) · [receipt](../PQD-003-r11-ci.json).
SHA `582377567005105b574704dd299a4aec2aa12117`, code branch `arena/0d4fcb38-pyquest`.

Run38946140784/custom report117127799090: phases0/0/1/0; analyze sạch7.9s;
337pass/6fail ordinary,10renderpass. [Report](ci-report.md) chỉ bỏ trailing whitespace.
4failure names hiện trong report,2tên bị cắt; không có full log/local Flutter run.

40JPEG board đúng SHA đã được lấy, ghép chunks theo index. Bốn ảnh ở thư mục này
được mở trực tiếp và giữ nguyên byte; IDs/hashes trong receipt. Không tuyên bố đã
mở36ảnh còn lại. Đây là JPEG publisher, không phải lossless PNG gốc.

- b1 numbers VI/font1: nhóm3trái/4phải đã đúng.
- b2 numbers EN/font1: nhóm7 bị dịch sai sang mép phải.
- b3 numbers VI/360/font2: một output2dòng đúng, nhưng nhóm7 bị cắt bên phải.
- b3 greeting EN/360/font2: đã scroll để thấy code→connector→output/controls.

Không gọi ảnh trông tốt là pixel test PASS; verdict vẫn CHANGES_REQUESTED. Tách
source/visual findings với các assertion chưa có expected/actual trong log.
