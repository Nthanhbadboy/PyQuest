# Dragon Jump r54 — một lần chạm, một cú bay

**2026-10-18 · DESIGN_STUDY_DELIVERED · chưa cấp quyền sửa runtime.**

![Gameplay study với cảnh 2,5D mới — không phải Flutter](evidence/desktop-overview.jpg)

[Mở bản tương tác](index.html) · [Hợp đồng màn hình](SPEC.md) ·
[Nguồn và giới hạn](SOURCE_NOTES.md) · [Artwork / production gaps](ASSET_PLAN.md)

## Phần thiết kế vừa hoàn thành

- Cảnh đường chạy ven núi lửa **liên tục**, phù hợp luật hiện có; không dùng các
  hố dung nham trong concept cũ để ngầm tạo luật chơi mới.
- Pip, đá và bọ bay có khối, tách khỏi nền; bụi cây cùng họ artwork Maze r50.
- Có thể chơi analogue JS: nhảy/vỗ cánh, nhặt xu, va chạm, bảo vệ ngắn, tạm dừng,
  kết thúc lượt và chơi lại. Nút Nhảy không bị cuộn ra khỏi màn hình.
- Chữ lớn không thu nhỏ: HUD và nút tăng font thật; camera giữ Pip trong vùng nhìn.
  Pause dành chỗ cho Resume/Finish thay vì giữ một nút Nhảy đã vô hiệu hóa.
- Kết quả tách **lượt này / kỷ lục / xu trong ví / ghi nhận**. Có zero-star,
  first/better/tie/lower, pending/unknown và đối chiếu; không cộng gem hai lần.
- Thiếu hoặc chưa đọc được năng lượng không cho bắt đầu lượt mới. Resume không
  mất thêm năng lượng; replay vẫn cần2, đúng loại lượt arcade.

**Đây là HTML/JS với dữ liệu RAM, không phải game Flutter đã được thay giao diện.**
Không ghi tài khoản, SQLite, trao thưởng hoặc mua đồ thật. Source không có đầy đủ
receipt/reconciliation như đề xuất; không được dùng demo dedup để claim atomic save.

## Luật được pin từ CODE

Source `6dc8ca8feeed54cc0fa6a82109e3a59d24a16153`,10file được hash độc lập.
Điểm = floor(distance/50)+3×coins; gem đã góp5 vào tổngcoins. Mốc sao150/300/500.
Mặc định3tim/2nhảy; heart→4tim, wings→3nhảy. Mỗi lượt mới2năng lượng. Chỉ lượt có
sao mới ghi level record; zero-star vẫn giữ xu sau khi ghi nhận.

Đặc biệt: nút kết thúc trong pause của source **chốt lượt và xu**, không vứt bỏ lượt.
R54 thể hiện rõ điều này. Source facts và đề xuất mới được tách trongSPEC.

## Bằng chứng thực chạy

| Kiểm tra | Kết quả | Phạm vi |
|---|---:|---|
| JS model |30checks +1.000record comparisons | Analogue, không Dart engine parity |
| Chromium153 |192configurations |16states ×2sizes ×2languages ×3textscales |
| Font |300assertions | Computed size của phần tử đang hiển thị |
| Target / bounds |684checks | Controls>=48, không page/inner horizontal overflow |
| Interaction |99flows | Entry/jump/pause/finish/receipt/replay/energy/keyboard, RAF và visibility event |
| Captures |16 | Browser, không APK |
| Source/art/static |[Receipt](evidence/static-checks.json) | Hash, nguồn, links, scope; không Flutter |

[Model receipt](evidence/model-checks.json) · [Browser receipt](evidence/browser-checks.json).
Đã mở kiểm trực quan các ảnh gốc, desktop, gameplay/pause360EN2× và kết quả.
Không nói đã nhìn thủ công cả192case. Kiểm browser phát hiện và đã sửa handler
Back vẫn còn sau ready→running; lần đầu nhảy nay đổi đúng sang Pause.

## Giới hạn và phối hợp

- Một pose Pip, không phải animation atlas. Cột đá stacked và coin/gem Canvas còn
  là studies; camera/persistence đề xuất chưa được kiểm trên thiết bị.
- RNG JS khác Dart; không dùng bộ số này thay regression của game nguồn.
- Study loadout chỉ đọc8món/giá nguồn. Chưa làm luồng mua/equip/cửa hàng đầy đủ.
- CODE vẫn nhận **PQC-020/R1-A**, không giao thêm Dragon runtime hoặc mở lại011.
  [Partner observation](partner-observation.json) ghi tip đã kiểm, không phải watcher.
- DESIGN kế tiếp: Catch Stars gameplay/results, rồi R1-B. Whole-app redesign chưa xong.

## Chạy lại

```sh
# Pillow dùng cho export và static image verification:
python tools/design/build_dragon_r54.py
node tools/design/test_dragon_r54.mjs
python tools/design/serve_art_review.py --port 8012 --landing r54
# Terminal khác, Playwright1.64.1 và @sparticuz/chromium153.0.0 trong NODE_PATH;
# Linux cần libnspr/nss trong LD_LIBRARY_PATH nếu host chưa có.
ART_REVIEW_ORIGIN=http://127.0.0.1:8012 node tools/design/check_dragon_r54.cjs
python tools/design/validate_dragon_r54.py
```

Live study mặc định ở Home. Dùng controls bên ngoài điện thoại hoặc URL
`?state=running&lang=en&scale=2&freeze=1` để review một frame. Freeze/response controls
là dụng cụ thiết kế, không nút sản phẩm; thiếu frame rate/DB/device evidence vẫn
phải ghi chưa kiểm thay vì lấy screenshot làm chứng nhận.
