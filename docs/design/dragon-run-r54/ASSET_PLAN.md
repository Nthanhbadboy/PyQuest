# Artwork r54 và phần production còn thiếu

## Bốn ảnh mới, một phong cách chung

| File gốc | Vai trò / brief đã dùng |
|---|---|
| `assets/volcano-trail.png` | Cảnh side-view ven biển/núi lửa, đá bo cạnh, ánh sáng ấm trên trái; đường chạy liên tục, không nhân vật, coin hoặc hố dung nham |
| `assets/pip-source.png` | Pip coral-orange, bụng kem, sừng kem, cánh/gai teal; một pose chạy về phải trên nền trắng |
| `assets/basalt-source.png` | Một khối basalt thấp, mặt trên sáng, chân phẳng, đọc rõ khi thu xuống48×44 |
| `assets/beetle-source.png` | Một bọ bay về trái, vỏ teal, cánh kem, silhouette46×32; không làm quái vật đáng sợ |

Các ảnh được sinh riêng bằng Arena image generation, không collage/spritesheet giả.
Background dùng reference W01 + DragonW05; Pip/rock dùng DragonW05; beetle dùng W01.
Quyền: AI-generated dùng reference của dự án, không claim stock/CC0/exclusivity hoặc
vẽ tay bởi người. Hash/dimensions/bytes và references trong [provenance](assets/provenance.json).
W01/r34/r50 không bị sửa. Phiên này không thay asset runtime của CODE.

## Export cho study

- `volcano-trail.webp`: quality88, giữ kích thước gốc. Artwork còn opaque một lớp.
- `pip-token.png`, `basalt-token.png`, `beetle-token.png`: flood-fill nền trắng liên
  thông từ biên, minRGB232/chroma26; erode1px + blur0.35, alpha crop và thumbnail512.
  Đây là **matte xử lý sau**, không phải native alpha hay animation frame set.
- Bụi cây reuse `../maze-play-r50/assets/hedge-token.png`, pin SHA256 riêng.
- Cột đá dùng hai rock stacked để đọc thử chiều cao; **chưa có pillar production**.
- Coin/gem là Canvas material/icon studies; vị trí từ analogue, không bake vào cảnh.
- Shadow của Pip là ellipse riêng cho study. Pose gốc chưa có feet pivot/physics
  silhouette chuẩn; body collision vẫn lấy numeric bounds nguồn, không theo alpha.

## Đã kiểm trực quan

Mở cả bốn ảnh gốc và baseline21, rồi desktop gameplay, gameplay360EN2×,
pause360EN2×, resultfirst390VI và resultactions360EN2×. Đã bỏ letterbox làm nhỏ Pip,
đưa camera vào vùng game thật và đưa Resume/Finish lên trước copy dài ở pause.
Không tuyên bố đã review thủ công mọi192case hoặc đã render Flutter.

## Gate trước khi port skin

1. Pip: idle/run/jump/flap/hit/end poses, cùng tỉ lệ và feet pivot; ba nâng cấp,
   năm cosmetics và silhouette collision không bị art che mất. Cutout hiện có chỉ
   là một pose dịch chuyển, không có animation authored.
2. Terrain tileable/parallax layers, foreground/occlusion riêng; ground anchor,
   background height/camera movement kiểm thật trên viewport nhỏ và text2×.
3. Pillar riêng, bush variants, beetle wing cycle; alpha/shadow/color calibration
   tại kích thước game, không chỉ xem hình512px. Coin/gem facets và contrast.
4. Stable asset budget/atlas/decode cache và measured frame/GPU/RAM trên thiết bị;
   dung lượng ảnh không chứng minh60fps hoặc memory safety.
5. Input/semantics/calm/lifecycle/locale, collision parity với Dart và receipt
   authority cho save. Có work order riêng trước khi sửa renderer/app/DB.

**Không nhận production pack hoặc runtime qua tài liệu này.** Ngoại lệ staticW01
của PQC-020 chỉ dành R1-A, không tự mở Dragon skin hoặc thế giới layered ở đây.
