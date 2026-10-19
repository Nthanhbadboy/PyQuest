# Lead mandate — tiếp tục thiết kế và phát triển toàn app

Ngày2026-10-17. Ghi nhận chỉ đạo người dùng trong chat, không phải agent tự cấp quyền.

Người dùng xác định Design vừa thiết kế, review, vừa quản lý phát triển app theo
thiết kế; OpenCode chỉ chuyển thông điệp qua browser khi một turn đã xong, không
sửa/không can thiệp. Chỉ đạo tiếp theo:

> Bạn là người quyết; user chỉ theo dõi, khi cần sẽ can thiệp riêng. Những gì đã nói
> thì cứ làm tiếp; xong app mới dùng, lúc đấy mới cần user quyết định.

## Cách áp dụng

- Lead chủ động quyết định roadmap, chia/giao task, tiêu chí nghiệm thu, sửa đổi
  thiết kế và mở các gói triển khai cụ thể theo tầm nhìn đã giao. Không hỏi lại
  người dùng từng bước hoặc dừng sau010/014/015 như thể toàn app đã xong.
- Quyền điều phối mới thay cơ chế xin quyền riêng cho mỗi work order trong các
  ghi chú cũ. Không biến thành quyền CODE tự mở mọi package: Lead publish từng
  order/revision + allowlist + dependency + acceptance; CODE làm đúng gói được giao.
- Gói đang triển khai là015,010/014 đã ACCEPTED theo phạm vi riêng. R27 mở ngoại lệ
  CI/evidence hẹp để giải quyết vấn đề có bằng chứng, không mở blanket dependency,
  SDK/toolchain upgrade hay đổi gameplay trong cùng patch.
- Sau015, ưu tiên016 Settings system/VI/EN để người dùng điều khiển locale rõ ràng;
  tiếp011 tích hợp bảng authored vào lesson để thành trải nghiệm học thật. Lead
  chuẩn bị spec/đọc source và chốt allowlist trước khi CODE bắt đầu. Đây là thứ tự
  do Lead chọn, không yêu cầu người dùng chọn lại, chưa phải CODE có quyền làm ngay.
- Tiếp tục các lát cắt sản phẩm trong FULL_APP_REDESIGN_CHARTER, LANGUAGE_AND_LOCALIZATION,
  TUTOR_TEACHING_BOARD và LIVING_WORLD_DIRECTION: Tutor AI từ đầu, màn chính/phụ,
  làng có sức sống, mini-games, quests nối nhau, medals/materials, nhà→đất→đảo,
  bạn bè/thăm nhà/thi đấu/thưởng/danh hiệu/pets thông minh. Không bỏ các trụ cột đó
  vì các vòng gần đây chỉ sửa foundation.

## Chất lượng và giới hạn thật

Lead không được dùng mục tiêu “xong app” để giả acceptance, bỏ tests hoặc đổi tầm
nhìn thành demo/postcard. Mỗi gói có evidence thật; hoàn tất module không đồng nghĩa
đã kiểm thiết bị, full process, backend/social/voice hay app production.

Không tự có thêm credentials, quyền tài khoản hay dịch vụ trả phí. Thiếu điều kiện
ngoài khả năng phiên phải ghi thật và làm tiếp phần khả thi. Quyết định phát triển
thông thường do Lead xử lý; không biến mọi lỗi kỹ thuật thành câu hỏi cho người dùng.
Người dùng luôn có thể ngắt/chỉnh hướng. OpenCode không được diễn giải lại scope.

Cuối mỗi lượt có next action thì xuất một block CHUYEN_TIN theo OPENCODE_RELAY.md;
nghiệm thu xong mà còn kế hoạch thì Lead tiếp tục hoặc tự chuyển tin về DESIGN.
