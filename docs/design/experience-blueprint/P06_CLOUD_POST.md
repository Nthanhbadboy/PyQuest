# P06 — Bưu điện Mây: đem sáng tạo sang nhà bạn

2026-10-16 · **Thiết kế đã có prototype, chưa là social runtime.**

Gói chính: [friends-showcase-prototype/README](../friends-showcase-prototype/README.md).

**Cập nhật theo chủ sản phẩm:** gói hiện tại là **P06 A — lớp giao lưu**, không phải
toàn bộ P06. [P06B — không gian sống](P06B_LIVING_HOMES_ISLANDS_PETS.md) bổ sung mở rộng
nhà/đất/đảo, thăm nhà có hoạt động thật, mua thú thông minh và nghiên cứu AI local.
P06B mới là thiết kế; ảnh và test dưới đây không chứng minh các tính năng B đã chạy.

## Hành trình sâu của gói

**Ghé thăm → nhìn kỹ tác phẩm → khen một điều cụ thể → tự làm thiệp → chọn người nhận → hộp thư và quyền từ chối.**

Kèm luồng kết bạn có xác nhận, góc cá nhân private-first, xem như bạn, block/report,
không có bạn, offline, tương tác bị giới hạn, tác phẩm bị giữ và retry không gửi trùng.

Điểm nhấn sáng tạo là **xưởng thiệp thao tác được**, không phải một nút “tặng quà”
với ảnh minh họa: giấy, stamp, sáu vị trí, lời chúc, bỏ nhãn và hoàn tác.
Mỗi tác phẩm trở thành lý do ghé nhà bạn; không cần chat mở hoặc độ nổi tiếng.

## Đường nối các gói

| Từ / tới | Cầu nối được thiết kế | Điều chưa nối thật |
|---|---|---|
| P05 → P06 | Một dấu mốc có thể được chủ hồ sơ chọn trưng bày | Ownership/achievement sync, quyền upload/share |
| Creator → P06 | Tác phẩm có title/thumbnail/version được phép xem | Chưa chạy UGC; các tác phẩm ở P06 là hình cố định |
| P06 → P07 | Lời rủ chơi, sau này chuyển sang luật bộ môn/readiness | Không phòng, ghép trận, chấm điểm hoặc rank |
| P06 → solo | Một lối sang mẫu P05 khi chưa muốn giao lưu | Hai prototype không chuyển tiến trình |
| P06 → thế giới dài hạn | Nhà cây, bưu điện, xưởng và góc lưu kỷ niệm | Không NPC/pathfinding/world streaming mới |

## Bảo toàn tầm nhìn

§16.1–16.5 vẫn nguyên: bạn bè, đội nhóm, triển lãm, tặng quà mua sẵn, danh hiệu xã hội,
tranh/thiệp/quà tự làm, quà lập trình và an toàn trẻ em. Giai đoạn đầu tập trung một
vertical slice miễn phí, **không xóa những nhánh còn lại khỏi roadmap**.

- [Creative direction + wireflow + roadmap](../friends-showcase-prototype/DESIGN.md)
- [Hợp đồng hành vi và ghi chú port](../friends-showcase-prototype/IMPLEMENTATION_NOTES.md)
- [Kết quả kiểm chứng](../friends-showcase-prototype/evidence/README.md)

21 model/copy/provenance tests, 12 fixture, 414 layout configurations, 18 axe audits và
12 ảnh kiểm tra. Đây là bằng chứng **HTML prototype**, không chứng nhận Flutter,
quyền server, pháp lý hay an toàn hệ thống xã hội thật.

Không mở task runtime mới hoặc đổi phạm vi PQC-010/014/015. Bản code `5fb7fff` đã được
quan sát là cập nhật r7 một phần; P06 không audit/accept thay review độc lập.
