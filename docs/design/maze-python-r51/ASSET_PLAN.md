# r51 · tái sử dụng artwork, không mở style mới

Không generate ảnh mới trong đợt này. Artwork dùng từ các study đã giao:

| Asset | Nguồn / usage |
|---|---|
| `../maze-creator-r46/assets/workbench.png` | Scene2,5D xưởng gỗ; background opaque cho reference board, không phải collision map |
| `../maze-play-r50/assets/robo-token.png` | Cutout Robo232×380 từ generated portrait r50; token đứng/guide/diagnostic, không sprite animation |
| `../maze-play-r50/assets/hedge-token.png` | Cutout hàng rào256×205 từ generated block r50; tường trên lưới reference |
| `../maze-play-r50/style.css` | Shared palette, framing, CSSchest/gem, dialog/chrome; không fork màu sang style khác |
| `../tutor-board-prototype/fonts/Nunito-{Medium,ExtraBold}.ttf` | UI VI/EN theo stylesheet r50 |
| `../../../app/assets/fonts/JetBrainsMono-Medium.ttf` | Code monospace có dấu; URL từ thư mục r51 về root bằng3parent, đã tải qua preview |

Provenance gốc: [r46 assets](../maze-creator-r46/ASSET_PLAN.md),
[r50 assets](../maze-play-r50/ASSET_PLAN.md),
[r50 provenance](../maze-play-r50/assets/provenance.json).
Các ảnh là AI-generated study art; nguồn/derivative có trong hồ sơ gốc, không
đổi credit thành vẽ tay. R51 không tái export/crop hay nhân bản các file lớn.
Dependency hashes trong manifest phát hiện drift của asset/CSS/font dùng chung.
Font licenses có trong `app/assets/fonts/OFL-Nunito.txt` và `OFL-JetBrainsMono.txt`.

Baseline đã nhìn: `docs/screenshots/27_workshop_code.jpg`, không after-runtime.
Captures mới là browser render của editor study, không được thay ảnh Flutter cũ
để tuyên bố app đã đổi hình. Scene tham chiếu cố ý tĩnh, không phản ứng như engine
đã chạy các fixture output/won.

## Các phần production còn thiếu

Robo nhiều hướng/pose, rig/animation/timing; wall adjacency/corner/terrain atlas;
transparent chest/gem production assets thay CSS; camera/scale/calibration giữa
board và scene; profiling bộ nhớ/texture/semantics của Flutter. Cutout r50 vẫn
có matte/shadow study, không coi là alpha pack production đã duyệt.

R51 không bàn giao artwork độc lập mới cho CODE018/019, không đổi allowlist,
không tạo thêm task ACK. Dùng asset cũ để phát triển screen interaction trước.
