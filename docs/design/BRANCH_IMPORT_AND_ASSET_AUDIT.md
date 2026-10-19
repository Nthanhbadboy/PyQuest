# Kiểm tra nhánh & bàn giao asset 2.5D

Ngày: **2026-10-16**. Nhánh làm việc vẫn là `arena/00838eb9-pyquest`.

## 1. Kết quả so sánh chính xác

| Mục | Kết quả |
|---|---|
| HEAD ban đầu | `5c8d215511c26d7b25772504f82b9299ed07dc00` |
| Nhánh yêu cầu | `arena/b813b575-pyquest` |
| Snapshot đã lấy | `c8b20296c7c6e0d9a5ff661dae2f10a816310944` |
| Chung tổ tiên | `59f38746deaad7b638134031229cc4f70408d582` |
| Commit riêng mỗi phía sau khi unshallow | 51 ở HEAD ban đầu / 26 ở nhánh nguồn |
| Diff hai snapshot trước khi nhập | 72 file, 4.860 dòng thêm / 1.001 dòng xóa (HEAD → nguồn) |

**Hai nhánh không giống nhau nhưng có chung lịch sử.** Checkout ban đầu là shallow
clone nên `git merge-base` không tìm được tổ tiên. Sau `git fetch --unshallow origin`,
merge-base có kết quả ở trên. Không dùng kết quả shallow để kết luận unrelated.

Đã fetch đúng remote ref và giải nén `git archive origin/arena/b813b575-pyquest`
vào working tree hiện tại, không clone lồng thêm repo, không đổi branch, không reset
lịch sử. **257/257 file trong snapshot nguồn khớp Git blob hash ngay sau khi nhập.**
Đây là nhập snapshot file, **không phải merge commit**. Ban đầu chỉ có trong working
tree; theo yêu cầu xuất bản tiếp theo, đã tách source import thành commit `dafde39`.
Bộ design/coordination nằm ở commit design riêng; bên nhận xác minh việc xuất bản
bằng fetch remote và pin SHA. Không mở PR trong bước bàn giao này.

Khác biệt chính được nhập: Tutor Gemini Live, transcript/speaker identity, audio
output/wire, test Tutor, dependency và Android manifest, CI, README và tài liệu
product/design mới. Đây là code có sẵn từ nhánh nguồn, không phải các tính năng
được viết mới trong đợt thiết kế asset này.

Các ngoại lệ có chủ ý:

- Giữ **38 ảnh `docs/screenshots/`** của nhánh hiện tại; nhánh nguồn không chứa bộ này.
- Giữ `ci/screenshot_blankness.py` của nhánh hiện tại, tránh mất công cụ baseline.
- Bỏ `app/README.md` mẫu Flutter đã bị xóa ở nhánh nguồn.
- Sau bước xác minh snapshot, thêm link bàn giao vào root README, ignore tooling
  cục bộ và bộ thiết kế/test mới. Vì vậy tree cuối **không được mô tả là giống hệt**
  nhánh nguồn.

## 2. Audit reference, evidence và source

Đã xem contact sheet của **21 reference gốc** và **38 screenshot baseline**; đọc
brief 2.5D, nghiên cứu nguồn CraftPix/AutoSprite, chuẩn nhân vật, các phần định hướng
và trạng thái liên quan trong bốn tài liệu sản phẩm/kỹ thuật, README, cùng source
map, activity registry, ActivitySheet và module. Chi tiết lựa chọn thị giác ở
[Village Kit README](village-kit/README.md#căn-cứ-thiết-kế).

Không tải stock trên mạng: reference trong repo đã đủ cho đợt này. Không tuyên bố
đã kiểm tra lại license website ở thời điểm hiện tại; không dùng mô tả license trong
research doc như một giấy phép cho asset đã tải. Không tải CraftPix hay AutoSprite.

Nguồn app hiện tại dùng map nền `island_map.webp` với hitbox chuẩn hóa, không có
terrain renderer isometric. Thumbnail trong sheet là 104×104. Vì vậy bộ mới nhắm
vào **minh họa card/thumbnail**, không thay map một cách mù quáng.

## 3. Thành phẩm

[Gallery](village-kit/index.html) · [Bảng artwork](village-kit/evidence/asset-review.jpg)
· [Manifest](village-kit/manifest.json) · [Hướng dẫn](village-kit/README.md)

- 6 PNG master 1024×1024: Tháp Python, Mê Cung Robo, Núi Lửa Pip, Đài Thiên Văn,
  Xưởng Bitsy, Nhà Thành Tích.
- 12 WebP tối ưu (256/512), tổng 156.030 bytes (~152 KiB); không tăng bundle app vì
  chưa thêm vào `pubspec.yaml` hay thay `app/assets/images/`.
- Gallery responsive: so sánh mới/cũ, xem 104 px, mở chi tiết, tải file thật.
- Manifest có SHA-256, provenance AI-generated, đường dẫn nguồn, activity ID,
  kích thước và trạng thái. Không gán CC0 hoặc tính độc quyền cho artwork AI.
- Script export, integrity tests và browser smoke test có trong `tools/design/`.

**Chưa có:** alpha sprite, model 3D, NPC idle/walk, map lớn, full UI overhaul hay APK
mới. Hình ảnh là raster nền liền, camera mang tính minh họa, không có footpoint hay
collision thật. Một số bóng chạm cạnh ảnh, không thích hợp ghép atlas không xử lý.
Gate xác minh Tutor trên thiết bị trong brief vẫn chưa đóng.

## 4. Kiểm tra đã chạy

| Kiểm tra | Kết quả / phạm vi |
|---|---|
| Snapshot file import | 257 blob khớp nguồn trước các bổ sung thiết kế |
| `python3 tools/ai_relay/test_relay.py` | **17/17 PASS**, server giả lập; không gọi nhà cung cấp thật |
| `python tools/design/test_village_kit.py` với Pillow 12.3.0 | **5/5 PASS**: ID module/activity, hash, kích thước, định dạng, budget, baseline không đổi, không ship vào app |
| `tools/design/smoke_gallery.cjs` | **PASS** trên Chromium headless: 6 card, ảnh tải được, đổi baseline, preview 104 px, dialog, tải WebP, Escape, nút đóng, mobile không tràn ngang, không JS/HTTP lỗi |
| Browser viewport | Desktop 1440×1100, mobile 390×844 |
| `git diff --check` | PASS |
| Flutter analyze / unit-widget / APK / thiết bị | **Chưa chạy**: môi trường không có Flutter/Dart SDK; không chứng nhận source nhập về đã build được |

Bằng chứng mới là screenshot **gallery HTML**, không phải screenshot Flutter:
[desktop](village-kit/evidence/gallery-desktop.png) ·
[mobile](village-kit/evidence/gallery-mobile.png).
Bộ `docs/screenshots/` là baseline đã có sẵn, không được gán thành bằng chứng của
lần import hay redesign này.

Source nhập có thêm `flutter_sound`, `record`, `web_socket_channel`, nhưng lockfile
được giữ đúng snapshot nguồn; cần `flutter pub get` và chạy CI trước khi đánh giá
khả năng build. Gemini Live thật cần kiểm tra trên thiết bị theo checklist riêng.

## 5. Bước tiếp theo

1. Duyệt 6 minh họa ở 104 px, điều chỉnh nếu muốn nhiều màu/ít chi tiết hơn.
2. Xác minh Tutor, giải dependency và chạy regression trên Flutter/Android.
3. Áp dụng thumbnail theo mapping đã ghi; chụp ảnh Flutter trước/sau thật.
4. Thiết kế terrain/NPC riêng với alpha, camera, anchor, idle/walk và lifecycle;
   chỉ sau đó triển khai bản đồ làng 2.5D nhiều lớp.
