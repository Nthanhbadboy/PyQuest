# r52 · artwork và production boundary

## Một illustration mới, không một style mới

`assets/robo-celebration.png`: Robo mint-teal bên rương mở, bệ gỗ và vườn hàng rào,
ánh sáng ấm từ trên-trái, hình khối2,5D đồng bộ r50. Dùng portrait Robo và garden
stage r50 làm reference. Ảnh AI-generated qua Arena, không gán là vẽ tay.
[Provenance và hashes](assets/provenance.json).

Đã xem ảnh rồi sửa: bản tạo đầu có ba sao trang trí, dễ bị đọc thành ba sao luôn
đạt. Đã **xóa cả ba sao và dây treo bằng image edit**, giữ một final illustration.
Số sao/điểm/badge/status/text trong UI là DOM hoặc CSS riêng, không bake vào ảnh.
Final image1200×896; crop hero desktop/mobile có safe center cho Robo/rương.
Ảnh không biểu diễn route, số gem thu được hoặc proof của lượt chơi.

No-win dùng garden-stage +robo-token r50 thay celebration scene. Các emblem badge,
quest, energy, unlock, item là CSS visual studies với label thật, không phải
production achievement icon pack hoặc asset do CODE018 đang phụ trách.

## Reuse / licenses

- `../maze-play-r50/assets/{garden-stage,robo-token}.png`: nguồn r50;
  [asset plan](../maze-play-r50/ASSET_PLAN.md), [provenance](../maze-play-r50/assets/provenance.json).
- `../maze-play-r50/style.css`: palette/typography/dialog/chrome chung.
- NunitoMedium/ExtraBold từ `../tutor-board-prototype/fonts/`; OFL ở
  `app/assets/fonts/OFL-Nunito.txt`. Không remote fonts hoặc image requests.
- Baselines đã trực tiếp xem: `docs/screenshots/09_maze_result.jpg` và
  `docs/screenshots/28_workshop_verified.jpg`. Đây là ảnh Flutter lịch sử,
  không được thay bằng browser captures để tuyên bố after-runtime.

## Chưa production

Illustration opaque là scene panel, không sprite atlas/animation/camera rig.
Robo pose mới ở trong scene, **không** isolated transparent actor export. Chưa có
open/closed chest multi-pose pack, calibrated prop pivots, texture memory/device
profiling, badge glyph artwork hoặc after-runtime screenshots.

Nếu port: crop và text-safe zones phải kiểm ở layout thật; không lấy ảnh để quyết
định hitbox, data, star counts hoặc award eligibility. Không tự giao runtime order
chỉ vì r52 có thêm ảnh và HTML PASS.
