# Art r56 — hai nhân vật mới, scene dùng lại đúng phạm vi

**Study assets, chưa phải runtime pack.** [Provenance](assets/provenance.json)
ghi dimensions/bytes/SHA256 của11art files và12reference files.

## Nhân vật

| Nhân vật | Tài sản | Identity và giới hạn |
|---|---|---|
| Thầy Py | `py-source.png` → `py-token.png` | Python xanh, bụng/hàm vàng, thân cuộn, kính tròn, mũ tốt nghiệp navy/tassel vàng; không biến thành người/robot |
| Bitsy | `bitsy-source.png` → `bitsy-token.png` | Mèo tím lavender, mắt xanh, mõm/bụng/chân cream, nơ xanh lá, kính lúp bên phải; giữ vai trò thám tử |
| Robo | reuse r50 token, không copy thêm | Mint robot, mặt navy, antenna/chest amber; oval shadow đã có trong study cũ |
| Pip | reuse r54 token, không copy thêm | Giữ cùng rồng/pose của Dragon study, không sinh một Pip khác |

Hai PNG đầu được tạo mới bằng Arena image generation, dùng source painter/cast và
ảnh tham chiếu nội bộ. Screenshot lesson cũ dùng để xác định identity Py, **không**
coi là capture Flutter có build provenance. Nguồn hình mới và derivative được giữ
riêng. Không tuyên bố bản quyền độc quyền, native alpha hoặc khả năng tái sinh seed.

Prompt summaries: Py chuyển nhận diện snake-blue/yellow/glasses/mortarboard từ
flat painter sang khối 2,5D cùng vật liệu Robo/Pip; Bitsy theo màu/lens/bow/tail từ
painter, không detective coat hoặc nhân hóa thành người. Mỗi ảnh chỉ một pose,
nền trắng; không ảnh UI/collage hoặc nhiều biến thể để người dùng phải chọn.

Cutout: flood-fill trắng nối rìa, minRGB232/chroma26, erode1px +blur0.35, crop và
thumbnail512. Đó là **study matte**, không kính trong suốt thật hay anatomy rig.
Py cần idle/think/point poses phù hợp thân rắn; Bitsy cần kiểm lại whiskers/stripe,
lens alpha và paw grip ở production. Chưa có blink/lip-sync/occlusion atlas.

## Scene exports

Bảy WebP quality87, tối đa720×1000, không upscale; không tạo lại scene bằng AI:

| Export | Nguồn đã có | Vai trò |
|---|---|---|
| arrival | r40 A03 welcome concept | Bến/cổng làng cho bước1/3, không route boat/travel |
| main_quest | r43 tower-garden | Giới thiệu Tháp Python và bước Py, không mở thêm lesson |
| robot_maze | r50 garden-stage | Không gian Maze, không dùng làm một level có collision |
| dragon_jump | r54 volcano-trail | Giới thiệu chạy cùng Pip, không chạy game ở sheet |
| catch_stars | r55 observatory-sky | Giới thiệu đài thiên văn, không mô phỏng atlas award |
| bug_hunter | r40 A05 workshop concept | Bàn điều tra của Bitsy; không thêm puzzle/content mới |
| achievement_house | r35 W14 correction | Căn phòng kỷ niệm; props bake không được hiểu là earned rewards |

R53 static village ở nền host là tái sử dụng trực tiếp. Host chỉ thử return/focus/
scroll của panel, không sửa hay thay Main Map CODE020. Export không nâng scene
opaque thành layered production world. Các nút/tags/status/name tách bằng DOM.

## Kích thước và cỡ chữ

Header scene180px, portrait115×140; Welcome scene300px, portrait152×175. Ở chữ≥1.5×,
content đứng trước scene; Welcome scene250px, **portrait không thu nhỏ**. Đây là
reorder đọc chữ lớn, không ẩn scene hoặc thu toàn phone. Nội dung có body scroll,
footer không đè hero/text. Tên/status không phối cảnh nghiêng theo hình gỗ.

## Trước khi đưa vào runtime

Chốt asset rights/provenance, crop và anchors; native character alpha/poses, decoder
memory và blend quality trên thiết bị. Không tính byteWebP thành60FPS/RAM đo thật.
Cần order riêng cho image/painter adapters, localization và Flutter semantics.
R56 không đổi `app/assets`, thumbnails nguồn, `CharacterId`, deps hoặc pubspec.
