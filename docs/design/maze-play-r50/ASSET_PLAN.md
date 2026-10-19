# r50 — Artwork và phần production còn thiếu

## Ba ảnh mới

1. `assets/garden-stage.png`: sân vườn trống nhìn ra biển, cùng họ W01/r45,
   không bake grid, nhân vật, rương, ngọc hoặc route. Là backdrop opaque một lớp,
   không phải geometry/game map hay scene có occlusion layers.
2. `assets/robo-portrait.png`: Robo mint-teal, màn mặt navy, antenna/chest amber,
   thân có khối và ánh sáng trên trái. Identity lấy từ Robo study trước và đối
   chiếu baseline06/07/09; không biến Robo thành Tutor cho mọi môn.
3. `assets/hedge-block.png`: prop bụi cây khối đơn, thay texture r46 quá nhiễu ở
   size nhỏ. Đã xem trong composition sau export, không chỉ xem ảnh gốc.

Các ảnh sinh bằng Arena image generation, dùng reference dự án. Không webstock,
không claim CC0/exclusivity/hand-painted human authorship. Prompt briefs, reference
paths, dimensions và hashes ở `assets/provenance.json`.

`robo-token.png` / `hedge-token.png` là **cutout dùng cho study**: flood-fill nền
trắng liên thông từ biên (minRGB>=232, chroma<=24), crop alpha bbox, resizeBICUBIC (Pillow).
Không giả đây là native alpha production, skeleton hoặc spritesheet animation.
Robo còn bóng/chân matte bake; cạnh cutout cần cleanup và shadow pass thật.

## Cùng họ mỹ thuật nhưng chưa là production art pack

- Board gỗ/đất, nước, gem và chest còn là CSS shapes/material studies. Chest có
  lid/front/shadow, nhưng chưa có asset closed/open chuẩn; gem chưa đủ facets.
- Board giữ lưới orthogonal đúng source; actor/wall có depth. Phối cảnh prop và
  background chỉ là composition, chưa có calibrated camera/pivot/occlusion.
- Robo mới thay legacySVG trong **r50 này**; không tự thay token trong r45/r46
  hoặc ảnh baseline. Chưa có idle/walk/turn/bonk/sink/win pose set.
- Marker/geometry/hit semantics không dựa pixel opaque của background. Board
  read-only trong gameplay; không gọi cell là brush target như Creator.
- Chữ, code, trạng thái sao, vị trí và năng lượng là DOMtext thật, không bake vào ảnh.

## Trước khi mở runtime skin order

1. Board frame9-slice; soil variants, hedge adjacency/endcap, water center/edge/
   corner; gem và chestclosed/open đồng camera. Dọn alpha, không kéo giãn crop
   từ một scene để giả xuất layered environment.
2. Roboactor sheet: chuẩn feet pivot/footprint, bounding box nhỏ hơn ô, facing4hướng,
   idle/move/fail/win; shadow riêng, kiểm actual48–64px và theme backgrounds.
3. Tách scene environment/background/foreground props/occluders; đo ánh sáng,
   camera và vùng safe khi board thay kích thước3×5 tới6×6.
4. Font/icon fallback, pixel contrast, screenreader, gesture, lifecycle và actual
   Flutter captures360/390 VI/EN200%. Không lấy browser PASS thay những gate này.
5. Python editor/diagnostics, score best-record, skill copy, reward-notice queue,
   custom-mode results và persistence transaction vẫn cần thiết kế/tích hợp riêng.

Phạm vi hoàn thành: block-mode gameplay + result interaction study. Không tuyên bố
mọi chế độ Maze, whole-app redesign hoặc production export đã hoàn tất.
