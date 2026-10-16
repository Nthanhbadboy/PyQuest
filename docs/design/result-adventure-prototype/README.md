# P05 — Một dấu mốc mới, một cuộc phiêu lưu tiếp theo

**2026-10-16 · Prototype HTML/JavaScript để review thiết kế. Không phải Flutter,
không có thưởng/tiến trình thật, backend, AI hoặc multiplayer.**

[Brief và source mapping](../experience-blueprint/P05_RESULT_TO_NEXT_ADVENTURE.md) ·
[Handoff thiết kế](IMPLEMENTATION_NOTES.md) · [Manifest](manifest.json) ·
[Ảnh kết quả desktop](evidence/01-result-desktop-vi.jpg) ·
[Ảnh điện thoại](evidence/06-result-phone-390-vi.jpg)

## Bấm thử

```sh
python3 tools/design/serve_results.py --port 8002
```

Mở Live Preview cổng **8002**, hoặc `/result-adventure-prototype/` trên một HTTP
server có root `docs/design`. Chỉ serve thư mục design, không expose toàn repository.
Không cần Flutter/backend. Mọi URL asset/module tương đối, không gọi localhost từ
trình duyệt của người dùng và không có request tới bên thứ ba.

### Luồng gợi ý

1. **Kết quả:** Robo tới rương; xem 3 sao, lý do, điểm lượt này và kỷ lục đã lưu mẫu.
2. **Xem huy hiệu:** Bước Chân Đầu Tiên, lý do đạt và nơi lưu.
3. **Xem bộ sưu tập:** Nhà Thành Tích riêng tư; earned/locked khác nhau, bí mật không
   lộ tên hay điều kiện. Mẫu chỉ trưng bày một phần catalog, không phải toàn bộ.
4. **Chọn cuộc phiêu lưu tiếp:** xem trước màn 2, luyện lại màn 1 hoặc nghỉ.
5. **Luyện lại:** sửa mũi tên; JavaScript mô phỏng `rm_01`, chưa chạy Python. Không
   giới hạn nhập ở 4 lệnh — đó là tiêu chí sao. Kết quả trả ngay, chưa có playback
   từng bước. Chơi lại không trao lại huy hiệu, kết quả kém hơn không làm giảm best.
6. **Xem trước thẻ trưng bày:** private, chưa kết nối/offline/bị giới hạn; không gửi,
   không có người nhận, tên thật, danh bạ, đối thủ hoặc bạn online giả.
7. **Nghỉ:** không phạt mất huy hiệu vì nghỉ. Riêng prototype mất dữ liệu khi reload;
   đây không phải đề xuất storage cho sản phẩm.

Nút Cài đặt ở góc trên có ngôn ngữ hệ thống/VI/EN, chữ 100%/130%/200% và giảm chuyển
động. Hệ thống không hỗ trợ dùng English. Mẫu không phát audio; không có nút bật âm
thanh giả. Chỉ language preference dùng key chung của prototype trong localStorage;
code/lượt chơi/huy hiệu không ghi storage. Lỗi lưu preference được nói rõ.

## Bàn thử thiết kế

Nút **Thử các tình huống** ở cuối trang mở 14 fixture, tương ứng 12 nhóm state
trong brief (R06 và R07 tách hai biến thể). Chọn fixture **đặt lại phiên mẫu**.
Nút S01–S08 chuyển khung mà không phát game event hay ghi thưởng.

| Fixture | Cách kiểm / điều không được giả |
|---|---|
| R01 | Thắng, đúng 1 notice first_steps, 1 huy hiệu |
| R02 | Thắng khi badge đã sở hữu, không tạo quà cho đủ layout |
| R03 | Best trước đó 70 → lượt mới 100, không nhận badge lại |
| R04 | Hai lệnh R R chưa tới rương; thử lại giữ code mũi tên, thêm R R để thắng |
| R05 | Sáu lệnh R L R R R R, 2 sao / 70 điểm; best vẫn 100 |
| R06a/b | Pending/error: chưa có badge hay saved best; bấm giả lập lưu hoặc nút lưu lại mẫu. Không timer tự báo đã lưu |
| R07a/b | Thiếu energy / hết tuyến: không vào next; vẫn có lựa chọn luyện lại và nghỉ |
| R08 | Mở lại kết quả: không ăn mừng/trao thưởng cũ lần nữa |
| R09 | first_steps + quest three_stars; khác loại notice, chỉ 1 badge; không tự claim tem/năng lượng |
| R10 | Dùng Cài đặt để đổi ngôn ngữ, calm, text size mà giữ lượt/program |
| R11 | Collection trống, khuyến khích thử hoạt động thật; secret không lộ đáp án |
| R12 | Thẻ xã hội chỉ xem trước; chọn offline/restricted không làm mất bộ sưu tập riêng |

R07end là fixture ép `next = null` để review edge state, **rm_01 thật vẫn có màn kế**.
R09 giả định quest three_stars đang active và chưa hoàn thành; không thay quest pool.
Dữ liệu cân bằng mẫu là 8 hoặc 0; chi phí 2/0 đối chiếu config, không vận hành ví tiền.
Màn 2 chỉ là preview, không bấm vào một game giả chạy. Màn 1 mới có mô phỏng lệnh.

## Chọn hình thức lần này

- Tông kem, xanh rừng, vàng ấm; khối nổi nhẹ thay vì mọi panel phát sáng.
- Hòn đảo 2.5D và huy hiệu dấu chân là SVG viết mới; Robo, làng, thumbnail Maze và
  Nunito dùng lại nguồn design đã có. Manifest ghi hash/provenance và license font.
- Hòn đảo chỉ để ăn mừng, **không phải mê cung rm_01 hay hitbox gameplay**. Board
  luyện lại dùng đúng 5×3 ô của rm_01, không suy luật từ tranh minh họa.
- Một cử động Robo tối đa 650 ms mỗi lượt mới đã ack, không chặn CTA. Calm/OS reduced
  motion tắt cử động; đổi locale/reopen không phát lại; page hidden hủy animation.
- Điện thoại đặt ghi nhận và đường tiếp trước recap; pending/error vẫn hiện save
  status và retry trước CTA. Không có footer cố định đè nội dung chữ lớn.
- Đây là art/UI để review, chưa phải asset pack được duyệt để swap production.

## Kiểm tra đã chạy

```sh
node --test tools/design/test_results.mjs
# Dependencies design đã pin trong tools/design/package.json; không sửa pubspec.
NODE_PATH=/path/to/node_modules node tools/design/smoke_results.cjs
```

Browser tool nhận `GALLERY_URL`, `BROWSER_EXECUTABLE_PATH`, `EVIDENCE_DIR`. Trong môi
trường hiện tại, dùng Playwright Core 1.64.1 / @sparticuz Chromium 153.0.0 và ba lib
NSPR/NSS thiếu được lấy từ **al2023.tar.br của chính package Chromium** vào cache;
`LD_LIBRARY_PATH=/home/user/.cache/p05-review/libs/lib`. Không commit binary/browser.

- **14 unit tests PASS:** fixture/config mapping, failure/retry, pending/error, receipt
  idempotence, no duplicate mock award, best monotonic, calm/reopen, kind distinction,
  navigation không write, snapshot isolation, copy VI/EN và hash provenance.
- **40 test design cũ +14 P05 =54 PASS**, không skip; [báo cáo unit](evidence/unit-check.json).
- **Browser PASS**, Chromium153.0.8010.0: journey, 14 fixtures; **144 tổ hợp** = 8 khung
  × 2 ngôn ngữ × 3 cỡ chữ × 3 viewport (1440×1100,390×844,360×640), không overflow
  ngang/clipping văn bản theo assertions. Không đồng nghĩa test mọi state×mọi size.
- Visible button/select cao ≥48 CSS px; buttons rộng ≥48. Kiểm Tab thực sự di chuyển,
  Enter/Space activation, Escape đóng modal và trả focus. Language/size không reset
  program; OS/manual calm; system locale fallback/change; preference write error.
- Không JS/HTTP errors, không network ngoài origin trong luồng kiểm.
- 10 JPEG và [báo cáo browser](evidence/browser-check.json). Đã xem ảnh desktop,
  điện thoại và English200%; có cuộn dọc, không ép chữ lớn vào panel cố định.

Lần kiểm ban đầu bắt được chữ nút reviewer tràn ở English200% và đã sửa thành một
cột trên phone. Đã sửa close-event trễ của Settings để không giành focus từ heading
của trang vừa mở bằng bàn phím. Screenshot Chromium headless sau cả ma trận resize từng timeout;
script chụp ảnh trước rồi chạy ma trận layout, không bỏ assertion hay gán kết quả giả.

**Chưa kiểm:** thiết bị thật/touch/TalkBack, Flutter semantics/textScaleFactor,
production persistence/relaunch/duplicate event, âm thanh, real AI, moderation,
backend hay thử nghiệm với trẻ em. CSS text scale không phải bằng chứng Flutter.

## Quan hệ với agent code

Lượt P05 đã đọc remote-tracking ref `ca2050a`, không audit/accept code ở đây.
**Đính chính khi review r7:** fetch chỉ ghi FETCH_HEAD chưa bảo đảm tracking ref tiến;
câu trước đây “không có commit mới hơn” bị rút lại. Review r7 đã fetch refspec tường
minh và đối chiếu remote/API tới `553e9ac`, xem `../coordination/reviews/PQD-003-r7.md`. Không đổi PQD-003 r6, PQC-010/014/015, runtime gates,
app/assets/dependencies. P05 là gói review design riêng; hướng port ở handoff là
**đề xuất**, không tự mở runtime work order mới.
