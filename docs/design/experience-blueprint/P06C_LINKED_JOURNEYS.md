# P06C — Màn chính và hành trình mở rộng có điều kiện

2026-10-16 · Gói triển khai thiết kế tiếp theo theo yêu cầu chủ sản phẩm.
**Prototype tương tác đã có, không cấp scope runtime mới.**

Gói chính: [home-journey-prototype](../home-journey-prototype/README.md).

## Luồng đầu tiên đã khép vòng

**Màn chính → kế hoạch Gác sáng tạo → tìm huy chương/gỗ/vải → hai mini-game → nhận
vật liệu → trở lại nhà → preview/xác nhận → pending/thành công/lỗi → phòng mới.**

- Maze `rm_01` dùng geometry đã có, simulator design hiện có; không đổi luật Flutter.
- Bridge ba ván là mini-game đề xuất mới, có thao tác và kết quả thực trong mẫu.
- Huy chương First Steps được giữ; 3 gỗ + 2 vải bị dùng khi xây thành công.
- 2 gỗ từ Maze; 1 gỗ + 2 vải từ Bridge. Tất cả số vật liệu là định mức đề xuất.
- Không bắt thứ tự hai game; không cần phòng để vào game kiếm đồ mở phòng đó.
- Hai kết quả thắng chưa nhận không ghi đè nhau; thất bại ở lượt mới không xóa win cũ.
- Túi và nhật ký phân biệt vật liệu được nhận, vật liệu đã tiêu và huy chương sở hữu.

## Nguyên tắc dùng cho các nhiệm vụ sau

1. Mỗi điều kiện có nguồn đạt được, trạng thái hiện tại và đường tới hoạt động đó.
2. Kết quả hoạt động dẫn trở lại dự án đang theo; không bắt trẻ nhớ đường qua nhiều menu.
3. Badge/permission là điều kiện; material/currency là chi phí. Không tự tiêu badge.
4. Dependency graph không cycle, không đặt nguồn duy nhất sau chính cửa đang khóa.
5. Pending, lỗi, retry, cancel, app resume và duplicate receipt phải được thiết kế cùng happy path.
6. Các dự án mở rộng không khóa Tutor/Main Quest/Python cơ bản hoặc buộc kết bạn/mua thú.
7. Recipes tương lai cần cấu hình và review riêng. Không suy ra giá hay lượng tài nguyên app từ prototype.

## Bước tiếp theo được chia nhỏ

| Nhánh | Bước thiết kế tiếp | Chưa được coi đã làm |
|---|---|---|
| Nhà/sân | Đặt đồ, kiểm lối đi, mở vùng đất với preview và điều kiện rõ | Editable world, pathfinding |
| Mini-game | Thêm chiều sâu Bridge; tiếp P08 các game có bản sắc | Physics hoặc gameplay Flutter mới |
| Vườn/bến/đảo | Mỗi khu mở thêm hoạt động và nguồn vật liệu có thể tiếp cận | Recipe/giá/điều kiện được duyệt, scene streaming |
| Thăm nhà/thú | Nối quyền visit, hoạt động chung và shop/AI capability | Multiplayer, payment, local inference |

P06 A vẫn là lớp bạn bè/thiệp. P06B giữ tầm nhìn không gian sống; P06C mới thực hiện
một nhánh **tiến trình mở phòng**, chưa thay thế các phần đi lại/sắp đồ/thăm nhà thật.

**Bằng chứng riêng của C:** 20 unit tests, 7 fixture, 324 layout checks, 15 axe audits,
12 ảnh. Không cộng số này vào bằng chứng AI/local multiplayer hoặc Flutter.
