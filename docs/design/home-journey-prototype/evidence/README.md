# P06C — Bằng chứng kiểm tra

2026-10-16 · HTML design prototype; **không phải Flutter hoặc backend receipt**.

## Kết quả

- [model-tests.tap](model-tests.tap): **20/20 PASS**, gồm model, copy, nguồn asset,
  graph không cycle/orphan, recipe khớp model và đủ nguồn vật liệu không cần farm replay.
- [browser-check.json](browser-check.json): **PASS**, Chromium 153.0.8010.0.
- **324 cấu hình** = 126 fixture + 144 route (bao gồm project thiếu điều kiện) + 54 dialog.
  VI/EN × cỡ chữ 1/1.3/2 × 1440×1080, 390×844, 360×640.
- **15 audit axe**, không có violation tự động trong các tag đã chạy; `incomplete`
  được giữ trong receipt, không coi là chứng nhận WCAG.
- Kiểm đi thật qua UI: Maze thất bại rồi sửa; cả hai game thắng chưa nhận; chuyển màn
  giữ cả hai pending wins; nhận từng phần; preview/cancel; build pending/fail/retry;
  offline/reconnect không mất pending; ack một lần; badge giữ lại; replay không farm.
- Locale không đổi ledger/program/result; reload chỉ giữ ngôn ngữ. Storage lỗi/fallback
  system được kiểm trong context riêng. Tab/Shift+Tab/Space/Enter/Escape và focus return.
- Button/select/external links hiển thị ≥48×48 CSS px; không tràn ngang/cắt chữ trong
  các phần tử đo. Không lỗi JS/HTTP, external requests hoặc non-GET ở trang được quan sát.

## 12 ảnh chụp từ prototype

| Ảnh | Trạng thái |
|---|---|
| [01](01-main-desktop-vi.jpg) | Màn chính VI desktop, đảo mới và dự án theo đuổi |
| [02](02-room-plan-desktop-vi.jpg) | Phòng thiếu huy chương/vật liệu, từng nguồn có đường đi |
| [03](03-journey-book-desktop-vi.jpg) | Sổ hành trình nối hai hoạt động về một mục tiêu |
| [04](04-maze-desktop-vi.jpg) | Xếp bốn bước, chưa bấm chạy |
| [05](05-reward-before-claim-desktop-vi.jpg) | Thắng nhưng chưa nhận — không giả đã có vật liệu |
| [06](06-bridge-desktop-vi.jpg) | Ba ván ngang, chuẩn bị kiểm cây cầu |
| [07](07-build-pending-desktop-vi.jpg) | Chưa trừ vật liệu khi build pending |
| [08](08-opened-room-desktop-vi.jpg) | Phòng đã mở trong mẫu, mèo có lời đáp authored |
| [09](09-main-phone-390-vi.jpg) | Màn chính 390×844 VI |
| [10](10-room-plan-phone-390-vi.jpg) | Điều kiện và đường kiếm vật liệu trên phone |
| [11](11-ready-phone-360-en-text200.jpg) | Đủ điều kiện, 360×640 EN, cỡ chữ 200% |
| [12](12-build-failed-phone-360-en.jpg) | Build lỗi, 360×640 EN, giữ nguyên vật liệu |

Ảnh full-page có thể dài hơn viewport vì màn được cuộn. Kiểm tự động không thay
user research, thiết bị thật, TalkBack/VoiceOver, Safari/Firefox hay Flutter textScaler.
Không có kết quả performance AI, multiplayer, durable transactions, quyền sở hữu
server, thanh toán hoặc app economy được chứng minh trong gói này.
