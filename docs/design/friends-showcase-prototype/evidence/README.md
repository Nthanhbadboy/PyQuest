# P06 · Bằng chứng kiểm tra

2026-10-16 · **HTML/CSS/JavaScript prototype, không phải screenshot Flutter.**

Receipt/ảnh này thuộc **P06 A đã bàn giao ở `62627d5`**. Bổ sung Product Vision và
brief P06B sau đó chỉ là thiết kế; không tái dùng 414 layout hay 18 axe audits để
tuyên bố mở nhà/đất/đảo, thăm nhà realtime, mua thú hoặc local AI đã được kiểm.
Manifest giữ hash Product Vision cũ trong `source_history` và hash văn bản mới
trong `sources`; cập nhật nguồn không đồng nghĩa đổi prototype đã chụp.

## Kết quả có thể chạy lại

- [model-tests.tap](model-tests.tap): **21/21 PASS**, Node test runner.
- [browser-check.json](browser-check.json): **PASS**, Chromium 153.0.8010.0.
- **216** layout fixture: 12 tình huống × 2 ngôn ngữ × 3 cỡ chữ × 3 viewport.
- **126** layout route: 7 màn × cùng 18 tổ hợp.
- **72** layout dialog: invite/compliment/play-invite/safety × cùng 18 tổ hợp.
- Tổng **414** cấu hình không phát hiện page/text overflow theo phép đo; button/select
  hiển thị tối thiểu 48×48 CSS px. Nội dung cố ý sr-only không thuộc phép đo clipping.
- **18** audit axe cho các route/dialog trọng tâm VI desktop và EN phone: không có
  violation trong tag WCAG 2 A/AA và 2.1 A/AA. Receipt giữ các mục `incomplete` để review,
  đặc biệt contrast trên gradient/ảnh; không tuyên bố chứng nhận WCAG.
- Đã chạy chuỗi hành động thật bằng Playwright: kết bạn chưa accept, invalid code,
  đổi code vô hiệu preview, chặn/hủy thư, không tự thay người nhận, report sau block,
  private/moderation filtering, thiệp/chọn người nhận/gửi lặp/retry, locale/reload/motion.
- Bàn phím thật qua Tab/Shift+Tab/Enter/Space/Escape; kiểm focus sau edit/route/dialog
  và khi system locale thay trong lúc nhập mã. Không gọi trực tiếp click handler thay chứng cứ bàn phím.
- Không lỗi JavaScript/HTTP; không request ngoài origin hoặc non-GET trong trang chính được quan sát.

## Ảnh được chụp từ app đang chạy

| Ảnh | Nội dung |
|---|---|
| [01](01-garden-desktop-vi.jpg) | Sân bạn bè và bưu điện 2.5D, VI desktop |
| [02](02-visit-desktop-vi.jpg) | Góc Mây: tác phẩm, huy hiệu mẫu, kỷ niệm tách biệt |
| [03](03-work-compliment-desktop-vi.jpg) | Chi tiết tác phẩm và lời khen đã chọn |
| [04](04-card-studio-desktop-vi.jpg) | Thiệp giấy đào, thêm mặt trời, chọn lời rủ khám phá |
| [05](05-gift-review-desktop-vi.jpg) | Preview tặng Bo trước khi tạo thư |
| [06](06-mail-failed-desktop-vi.jpg) | Hộp thư có play invite và thiệp lỗi, retry rõ |
| [07](07-my-shared-shelf-desktop-vi.jpg) | Xem như bạn sau khi chủ kệ cho phép chia sẻ |
| [08](08-garden-phone-390-vi.jpg) | Sân bạn bè, 390×844 VI |
| [09](09-studio-phone-390-vi.jpg) | Xưởng thiệp một cột, 390×844 VI |
| [10](10-declined-phone-360-en-text200.jpg) | Từ chối thư, 360×640 EN, chữ 200% |
| [11](11-private-phone-360-en.jpg) | Góc private không lộ tác phẩm, 360×640 EN |
| [12](12-incoming-phone-360-en.jpg) | Lời mời tới có accept/decline, 360×640 EN |

Ảnh full-page cố ý dài hơn chiều cao viewport; cuộn là hành vi mong muốn, không ép
mọi nội dung vào một màn bằng chữ nhỏ. Screenshot không chỉ chọn happy path.

## Giới hạn không được bỏ khỏi handoff

Không kiểm thiết bị thật, Safari/Firefox, TalkBack/VoiceOver hoặc trẻ em/phụ huynh.
Không kiểm browser zoom như Flutter textScaler. Không có real network outage,
backend ACL, real moderator, identity/consent, inbox của tài khoản thứ hai, durable
transaction, paid gift, UGC execution, multiplayer hoặc gameplay mới.

Kiểm DOM ẩn title/thumbnail chỉ chứng minh UI filtering của dữ liệu mẫu, không chứng
minh quyền truy cập server hoặc xóa dữ liệu từng cache. Đã xác nhận nguồn asset/copy
bằng hash trong model tests; hash không thay art approval, licensing review hay security audit.

Lệnh và dependency: [README](../README.md#đã-kiểm-tra). Dependency kiểm nằm trong cache,
không nằm trong app Flutter hoặc package runtime.
