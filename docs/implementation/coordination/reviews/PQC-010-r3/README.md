# Evidence — PQC-010 vòng3 / PQD-003 r9

Ngày2026-10-17. [Review](../PQD-003-r9.md) · [receipt/hash/check IDs](../PQD-003-r9-ci.json).

## CI hiện tại

Tested SHA `8647916223bc5168a81ca9ea30cf3e6b28be6e09`, app tree giống0661523.
[Run38937509150](https://github.com/Nthanhbadboy/PyQuest/actions/runs/38937509150),
custom report117099178577: phases0/0/1/0, analyze sạch10.7s,319pass/19fail ordinary,
10renderpass, APK skipped. [Report text](ci-report.md) chỉ bỏ trailing whitespace.
**Không có published board preview ở SHA này.** Không gọi ảnh lịch sử bên dưới là
bộ ảnh của run hiện tại. Review source tìm thấy jobs length4 nhưng đọc indices4/5
trước try/capture; không phải ảnh nền đen tái xuất hiện.

## 8 JPEG lịch sử, không phục dựng/sửa ảnh

`historical-dc2fd3e/` lấy từ check runs của dc2fd3e, run38931215746/report117077155500.
Đã ghép chunk base64 theo index, kiểm đủ chunk trước decode. Đây là JPEG publisher,
không phải PNG lossless. Receipt ghi source SHA/check IDs/SHA256/bytes từng ảnh.

Mở trực tiếp hai ảnh:
- [b1 VI/font1](historical-dc2fd3e/board-mq1_01_s2-b1-code-highlight-390x844-font1.0-vi.jpg): nền trắng, code/chữ đọc được; phần dưới là viewport trống.
- [b2 EN/font2](historical-dc2fd3e/board-mq1_01_s2-b2-quote-tokens-390x844-font2.0-en.jpg): chữ wrap nhiều dòng, highlight print/quotes, controls xuống dòng.

Sáu ảnh còn lại đã lấy/hash, không tuyên bố đã mở từng ảnh. Tất cả chỉ greeting b1/b2
ở390×844, không có evidence output/connector/numbers/shape/khổ360. `app/lib` không
đổi từ dc2fd3e tới8647916, nhưng test harness đổi; không dùng ảnh lịch sử để chấp
nhận harness mới hay đóng toàn bộ visual requirements.

## Giới hạn

Custom report nêu4/19failure names,15tên còn lại bị cắt. Full signed log download
qua gh lỗi EOF; report annotations rỗng. Không có local Flutter/Dart, không chạy
repro Flutter/device, không đo TalkBack. Review dùng source/hash/CI và ảnh đã chỉ rõ.
Các assertions sai/coverage holes từ source không được gán là tên failure bị thiếu.
