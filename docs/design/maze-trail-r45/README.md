# r45 — Vườn Mê Cung / chọn màn Robo

**2026-10-18 · DESIGN_STUDY_DELIVERED · runtime NOT_AUTHORIZED.**

![Màn chọn level trong khu vườn 2,5D](evidence/desktop-overview.jpg)

[Bản tương tác](index.html) · [Cảnh nguyên bản](assets/hedge-trail.png) ·
[Spec](SPEC.md) · [Asset plan](ASSET_PLAN.md) ·
[Tình trạng hình ảnh toàn app](../VISUAL_DESIGN_STATUS.md)

## Phần mới

Một khu vườn mê cung 2,5D cùng họ W01: hàng rào cây có khối, đường đá liên tục,
cầu gỗ qua suối, năm bệ chọn màn và Xưởng ở góc dưới. Hai trang1–5/6–10 dùng cùng
cảnh như **sổ lộ trình**, không phải hai đảo, gói trả phí hoặc geometry gameplay.
Chạm trực tiếp các bệ để xem từng màn; trạng thái/number/star đều là HTMLtext thật.

- Đúng **10màn** từ source, hai nhóm arrow/repeat theo `allow_loops`.
- Sổ đủ10màn, tiếp tục màn kế, completed/replay, locked reason và lối tới màn trước.
- Phác đồ riêng cho mỗi màn: **246ô nguồn** giữ đúng wall/water/start/chest/gem/floor;
  có bản mô tả ô bằng chữ. Không có solution/tip từ JSON trong catalog design.
- Phân biệt thiếu năng lượng và chưa biết năng lượng; free replay/workshop;
  loading/error, link màn khóa, link không tồn tại, hoàn thành và perfect.
- Nút ra gameplay/Workshop/village chỉ mở **destination preview**, không chạy app.

## Luật giữ theo source

PinCODE `71b0fd3fd8fb07c73596ce089fa2e68f6fe87964`, [7sourcepins](source-manifest.json).
Newlevel2, completedreplay0, Creator0. Unlock theo record của **ID ngay trước**,
không theo tổngsao. Hai điều kiện sao thêm là độc lập sau khi tới rương: đủngọc,
và trong mục tiêu lệnh. Mục tiêu lệnh không phải điều kiện khóa màn kế.

Fixture returning có rm01=2sao,rm02=2sao, nên màn3mở với tổng4sao. Màn1không có
ngọc nên khi tới rương luôn đạt điều kiện ngọc; không dựng mẫu rm01=1sao bất khả thi.
Fixture one_star_unlock dùng rm03=1sao (ngọc có thể bỏ qua) để mở màn4.
rm02 buộc đi qua ngọc nên không dùng mẫu1sao ở màn này. Fixture all_partial có10màn
đã qua với20sao; perfect là30sao, không gọi hai trạng
thái đó giống nhau. Đây chỉ là sample records, không đọc hoặc ghi dữ liệu người chơi.

Tiêu đề/storyVI, rows, commandLimit/allowLoops lấy nguyên source. EN là bản dịch
thiết kế, không chứng minh app đã localized. Loading/error/inspectlocked/deeplink
là đề xuất UI và trạng thái kiểm, không khẳng định Flutter hiện đã có các surface đó.

## Kiểm tra thực chạy — chỉ HTML/JS

| Kiểm tra | Kết quả |
|---|---:|
| JS model | **18checks PASS** |
| Chromium153 | **360/360cases PASS** |
| Font scaling | **5.664assertions PASS** |
| Diagrams | **10màn /246ô khớp source** |
| Interaction | **16flows PASS** |
| Captures | **11ảnh:10phonePNG +1desktopJPG** |

Matrix:15fixtures ×2viewport(360×640/390×844) ×VI/EN ×1/1.3/2×font ×2trang map.
Không horizontal/pageverticaloverflow ngoài scroll owner, target<48px, overlap/outside
scene controls, page error hoặc external request trong matrix. Tap thật cả10marker
và Xưởng ở2× trênhai size/cảVIEN; kiểm keyboard/focus/Escape, free replay và deeplink.

[Browser receipt](evidence/browser-checks.json) · [Model receipt](evidence/model-checks.json) ·
[Source/static receipt](evidence/static-checks.json).

Đã mở xem full-size scene, hai baseline05/41, desktop, loop_ready, EN2×map và
EN2×energyfallback; đọc thêm detail/locked/unknown-linkcaptures. Không claim xem thủ
công cả360cases. Đã sửa overlap/outside nútWorkshop ở360font2× bằng flow dock dưới
scene, không giảm cỡchữ. Checker cũng sửa selector journal để chỉ tap dialog đang mở.

## Một số trạng thái

- [Quay lại · màn3](evidence/returning-390-vi-1x.png)
- [Trang khối Lặp](evidence/loop_ready-390-vi-1x.png)
- [Phác đồ màn3](evidence/detail-390-vi-1x.png)
- [Màn khóa / prerequisite](evidence/locked-390-vi-1x.png)
- [Hết năng lượng EN2×](evidence/energy_empty-360-en-2x.png)
- [Link không tồn tại](evidence/unknown_link-390-vi-1x.png)
- [Map EN2× +Workshop dock](evidence/perfect-360-en-2x.png)

## Chạy lại

```sh
python tools/design/serve_art_review.py --port 8006 --landing r45
node tools/design/test_maze_r45.cjs
# Cần playwright-core và Chromium tương thích trong môi trường design:
node tools/design/check_maze_r45.cjs
python tools/design/validate_maze_r45.py
```

`?phone=1` ẩn bàn kiểm ngoài phone. Dữ liệu chỉ trong memory, khônglocalStorage,
backend/AI/SDK/deps/CI. Retry chờ dữ liệu thay vì tự fake success; dùng reviewer để
chọn snapshot có dữ liệu. Locale/textscale không reset record/energy/selectedlevel.

## Giới hạn và việc tiếp

Art opaque848×1264, chưa alpha layers/actor rig/navigation/camera calibration;
không phải asset gameplaygrid. Phác đồ là diagramread-only, **không phải Maze editor**.
Không portFlutter, chạy engine, thử mua/trừenergy/awardstars/persist/custom save.
Không đánh đồng HTMLchecks với nghiệm thu011; r44/WAITING_FOR_PINNED_SDK_EVIDENCE giữ nguyên.
018art scope vẫn complete. HaiJPEGdirtyr33khôngstage; r41audit và r43package giữ nguyên.

**Tiếp theo: Maze Creator grid/brush/spawn/goal/validation/test/save states thật trong
thiết kế**, không dùng B02prose mock để gọi Creator hoàn tất. Những nhóm partial và
productionexport còn lại ghi trong bảng tình trạng toàn app.
