# PyQuest — Village Kit 01 · 2.5D landmarks

**2026-10-16 · Design review, chưa tích hợp vào Flutter.**

Bộ minh họa đợt đầu cho **6 địa điểm hiện có**, không phải thiết kế lại toàn bộ app.
Mở [gallery](index.html) qua HTTP để so sánh mới/cũ, xem ở 104 px, phóng to và tải từng file.
Xem nhanh [bảng tổng hợp](evidence/asset-review.jpg).

## Có gì trong bộ này?

- `source/`: 6 PNG gốc, 1024×1024, do AI tạo mới cho dự án; đây là **raster master**, không phải vector chỉnh lớp hay model 3D.
- `exports/`: 12 WebP RGB (mỗi ảnh có bản 256 và 512 px), tổng **156.030 bytes (~152 KiB)**.
- `baseline/`: bản sao bất biến của 6 thumbnail trước thay thiết kế. `baseline-lock.json` pin hash và source commit `c8b2029`; exporter không lấy lại từ runtime.
- `art-direction.json`: hướng mỹ thuật, mô tả chủ thể/prompt recipe, mapping module và activity ID. Recipe ghi lại ý đồ tạo ảnh, không phải bản log nguyên văn đầy đủ của mỗi tool call.
- `manifest.json`: kích thước, dung lượng, SHA-256, provenance, file nguồn và trạng thái.
- `evidence/asset-review.jpg`: bảng bàn giao artwork; **không phải screenshot app đang chạy**.
- `index.html`: gallery responsive độc lập, không gọi API ngoài, không sửa dữ liệu app.

| Ảnh | Module / Activity ID | Vị trí thumbnail trong app |
|---|---|---|
| `python_academy` | `main_quest` | `assets/images/thumb_tower.webp` |
| `robo_maze` | `robot_maze` | `assets/images/thumb_maze.webp` |
| `pip_volcano` | `dragon_jump` | `assets/images/thumb_volcano.webp` |
| `star_observatory` | `catch_stars` | `assets/images/thumb_observatory.webp` |
| `bitsy_workshop` | `bug_hunter` | `assets/images/thumb_workshop.webp` |
| `achievement_house` | module `achievements`, ID `achievement_house` | `assets/images/thumb_house.webp` |

### Giới hạn quan trọng

**Các ảnh có nền ivory và bóng ghép sẵn, không có alpha.** Dùng cho card/thumbnail,
không thả trực tiếp lên mặt đất của map. Góc isometric là tạo hình thị giác do AI
ước lượng, chưa phải camera/đơn vị hình học được hiệu chuẩn giữa mọi tile.

Bóng một số ảnh kéo tới mép canvas; phù hợp khung card, chưa đủ cho atlas sprite.
Mê cung là biểu tượng minh họa, **không được dùng làm mê cung gameplay** hoặc suy ra
đường đi/hitbox từ ảnh. Bộ này chưa có NPC, idle/walk animation, terrain ghép nối,
map lớn, avatar, UI icon hay runtime 3D. Không tuyên bố đây là toàn bộ asset của app.

## Căn cứ thiết kế

Nguồn nằm trong repository; đủ cho đợt landmark này nên không tải stock trên mạng:

- `docs/PyQuest_Reffrence_Images/`: đã xem contact sheet của 21 ảnh gốc. Các ảnh bắt đầu
  bằng `DiyPois…`, `HQlxf…`, `TVJkPw…`, `uJri7…` cho cấu trúc thế giới, landmark và
  đường nối; `2R8S…`, `5fwn…`, `nlBv…` cho chủ đề robot/giải đố; `S0vq…` cho thành tích.
- `VILLAGE_2_5D_REDESIGN_BRIEF.md`: góc 3/4, lớp chiều sâu, màu thống nhất, chữ rời,
  không tạo điểm đến giả. `PYQUEST_UI_DIRECTION_V2.svg` và concept là định hướng,
  không phải ảnh bằng chứng runtime.
- `docs/screenshots/`: đã xem contact sheet của 38 ảnh baseline hiện có; map nhiều
  chi tiết, thumbnail nhỏ, viền UI đậm. Giảm chi tiết và màu chói trong bộ mới,
  giữ silhouette từng hoạt động ở kích thước nhỏ.
- `PRODUCT_VISION.md` §4, §14, §21; `GAME_DESIGN.md` §4, §16;
  trạng thái asset trong `TECHNICAL_ARCHITECTURE.md`; gate triển khai trong
  `ROADMAP.md` §16. Không thêm XP toàn cục, paywall, Arena hoặc thị trường chưa có.
- Source: `MainMapScreen` hiện dùng một nền `island_map.webp` (1152×2064) và hitbox
  chuẩn hóa; `ActivitySheet` dùng thumbnail **104×104**, `BoxFit.cover`.
  Sáu module đang được đăng ký trong `activity_registry.dart`.

Chất liệu mới: đá limestone, mái teal, cây sage, điểm sáng amber; khối low-poly
mềm, nhìn rõ mặt trên và hai mặt bên, ánh sáng trên-trái. Giữ cảm giác phiêu lưu
thân thiện nhưng không dùng mặt nhân vật quá trẻ con hoặc viền đen dày.

## Nguồn gốc / quyền sử dụng

Ảnh tạo bằng công cụ image generation của Arena cho tác vụ này. Chỉ dùng PNG
`python_academy` mới tạo làm tham chiếu phong cách cho năm ảnh tiếp theo; **không
đưa ảnh stock CraftPix, ảnh nhân vật thương hiệu hay 21 reference gốc vào tool**.
Các reference chỉ được đọc để rút nguyên tắc bố cục/chủ đề, không cắt lại làm asset.

Không gắn nhãn CC0 và không khẳng định tính độc quyền pháp lý của ảnh AI.
Trước phát hành, kiểm tra điều khoản công cụ tạo ảnh và chính sách quyền sử dụng
của dự án. Không tải hoặc phân phối lại archive CraftPix/AutoSprite trong đợt này.

## Tái xuất, kiểm tra, xem gallery

Từ thư mục gốc repo:

```sh
python3 -m venv .venv
.venv/bin/pip install -r tools/design/requirements.txt
.venv/bin/python tools/design/export_village_kit.py
.venv/bin/python tools/design/test_village_kit.py
python3 -m http.server 8000 --bind 0.0.0.0 --directory docs/design/village-kit
```

Mở URL server/preview được môi trường cung cấp. Gallery cần HTTP để đọc JSON;
không mở bằng `file://`. Không có dependency JS/CDN, link tải trỏ file thật.
Export dùng Pillow và Nunito đã có trong app, giữ nguyên các file `app/assets/`.
Trước khi ghi, exporter xác minh toàn bộ baseline theo lock; thiếu/hỏng thì dừng,
không tự lấy art mới từ app làm ảnh cũ. Khôi phục baseline từ Git nếu hỏng.
Bộ test có regression chạy export khi runtime đã đổi và kiểm tra xuất lặp không đổi kết quả.

Smoke test trình duyệt (server gallery phải đang chạy):

```sh
cd tools/design
npm install
npm test
```

Test dùng Playwright Core + Chromium, cần các thư viện hệ thống như NSS/NSPR.
Có thể đặt `BROWSER_EXECUTABLE_PATH` tới Chromium đã cài và `GALLERY_URL` tới URL
HTTP cần kiểm tra. Test ghi screenshot vào `evidence/gallery-desktop.png` và
`evidence/gallery-mobile.png`; đây là **evidence gallery HTML**, không phải Flutter.

## Bước đưa vào app (chưa thực hiện)

1. Duyệt silhouette và màu ở chế độ **104 px**; hiện có thể so sánh trực tiếp với
   thumbnail cũ. Đây là preview HTML, chưa phải Flutter golden test.
2. Xác minh gate Tutor theo `docs/experimental/GEMINI_LIVE_VOICE_TEST.md` trước
   redesign làng; đợt này không tự đánh dấu gate đã đạt.
3. Với thumbnail: copy bản 512 px vào đúng đường dẫn trong bảng trên sau khi duyệt;
   không sửa progress, unlock, điều hướng hoặc hitbox. Giữ label/tên địa điểm ngoài ảnh.
4. Với map/NPC: cần pipeline riêng xuất alpha, chuẩn hóa camera, scale/anchor, shadow
   layer, collision/occlusion và idle/walk. Không dùng sáu ảnh card như tile-map.
5. Chạy `flutter pub get`, analyze, unit/widget/render tests, đo APK và kiểm tra thật
   trên Android. Source vừa nhập có thêm dependency audio; không giả định lockfile
   đã được giải lại hoặc app đã build thành công trong môi trường này.

Xem [báo cáo đồng bộ nhánh và kiểm tra](../BRANCH_IMPORT_AND_ASSET_AUDIT.md).

**Giao cho AI khác:** đọc [hướng dẫn triển khai, prompt bàn giao và danh sách thiết kế tiếp](../AI_IMPLEMENTATION_HANDOFF.md).
Bản vá PQD-001 revision 3 giữ baseline độc lập runtime. Khi lấy tool, lấy cả
`baseline-lock.json`; không tự cập nhật hash baseline để làm test xanh.
