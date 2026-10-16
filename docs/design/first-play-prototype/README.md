# P02 — Chuyến phiêu lưu đầu tiên

**Mẫu thiết kế HTML có tương tác, không phải Flutter runtime.**
Mục tiêu: kiểm chứng một luồng sử dụng thay vì tiếp tục chỉ thay thumbnail hoặc viết
tài liệu điều phối. Trạng thái: design review, chưa phải user-tested/approved release.

## Xem và thử

Từ root repo:

```sh
python3 -m http.server 8000 --bind 0.0.0.0 --directory docs/design/first-play-prototype
```

Mở URL Live Preview hoặc server tương ứng. Trang không gọi CDN/API/AI, không yêu cầu
đăng nhập, không thu thông tin cá nhân, không lưu dữ liệu ra SQLite/localStorage.
Đóng/tải lại trang sẽ mất tiến trình mẫu; không coi đó là persistence của app thật.

Luồng: **Gặp Robo → Làng → Giới thiệu Robo Maze → Xếp lệnh → Chạy / sửa lỗi / gợi ý
→ Kết quả → Màn thứ hai hoặc quay về làng**.

- Hai level lấy từ `robot_maze_levels.json`: `rm_01`, `rm_02`, pin hash trong `levels.json`.
- Có collision, lệnh chưa đủ, xóa một lệnh/undo/reset, dừng chạy, hai nấc gợi ý và
  nhặt gem trên màn thứ hai. Thắng dựa vào đường đi mẫu, không phải nút giả chuyển màn.
- Kịch bản sidebar “đúng” và “đi vào tường” chạy chính mô phỏng này, dùng để review.
- Prototype cap 12 lệnh để UI không tăng vô hạn. Đây **không phải** quyết định đổi
  command_limit/điểm/sao/kinh tế của Flutter; các quy tắc đó vẫn ở source app.
- Thay screen/dừng/ẩn trang hủy lượt đang biểu diễn bằng run token. Không có một
  animation/timer vô hạn cho từng NPC. Reduced motion dùng nhịp ngắn, bỏ bobbing.
- Chọn được cả sáu landmark, nhưng chỉ Robo có luồng mô phỏng. Các nơi khác nói rõ
  “chưa mô phỏng trong mẫu này”, không giả làm tính năng đã code xong.
- Tutor là thoại/gợi ý được soạn sẵn, **không** có giọng nói hoặc AI đang trả lời.
- Năng lượng 20/20 là số minh họa có chú thích, không tiêu hao, không gọi ad/purchase.
- Sao trang trí ở màn kết quả không phải điểm sao theo công thức game; chỉ thống kê
  đường đi/gem thực sự đã chạy trong mẫu. Không cộng XP/xu/huy hiệu giả.

Quyết định sau feasibility: [IMPLEMENTATION_DECISIONS.md](IMPLEMENTATION_DECISIONS.md)
— chốt intro/result/card/motion/route; không thay đổi gate duyệt art/runtime.

## Thay đổi trải nghiệm so với baseline

| Màn | Ý đồ |
|---|---|
| Chào Robo | Hai lựa chọn có ý nghĩa, có thể bỏ qua. Không ép bật micro hoặc đăng nhập. |
| Làng | Cảnh 2.5D, nhãn của điểm đang chọn, một card hành động dưới cảnh. Hotspot bám hình, không đặt sáu bảng lớn che hết công trình. |
| Vào chơi | Mục tiêu và ba bước thao tác trước bảng thống kê. Một CTA rõ. |
| Robo Maze | Giữ lưới dễ hiểu, tạo khối bằng độ dày/bóng. Lệnh đang chạy sáng lên; lỗi gắn đúng bước, không che editor/CTA bằng banner lặp. |
| Kết quả | Khen điều người chơi vừa làm, thống kê lượt mẫu, có thể thử lại hoặc tiếp tục. |

Đây mới là một hướng thị giác: không mặc định mọi game phải dùng màu trầm, mọi scene
đều isometric hoặc mọi nhân vật đều giống Robo. Cần review cảm xúc/khả năng hiểu của
trẻ theo charter, rồi mới nhân rộng sang Python, arcade, workshop và các hệ thống mới.

## Nguồn và quyền sử dụng

- `art/village.jpg`: ảnh mới sinh bằng công cụ image generation của Arena, dùng hai
  PNG landmark nguyên bản `python_academy`/`bitsy_workshop` làm tham chiếu phong cách.
  Không đưa stock/reference bên thứ ba vào tool. `village.webp`: bản tối ưu 112.018 B.
  Đây là một cảnh nền liền, **không phải** map ghép tile, model 3D hay terrain có hitbox.
- `art/robo.svg`: SVG tạo mới bằng code cho mẫu, không phải sprite walk-cycle; dùng
  gradient và shadow để tạo khối. Chưa thay `CharacterView` của app.
- Sáu `art/*_512.webp` là bản sao đúng byte của Village Kit 01, chỉ phục vụ preview.
- `fonts/`: Nunito từ app hiện có, đi cùng giấy phép OFL.
- `levels.json`: fixture từ hai màn source, không chứa solution; mô phỏng riêng cho
  thiết kế. Source và hash ghi trong file; không tuyên bố đã port đủ game Dart.
- `manifest.json`: provenance, kích thước/dung lượng/hash, nguồn tham chiếu và giới hạn.

Không gắn nhãn CC0 cho ảnh AI. Kiểm tra điều khoản công cụ và chính sách dự án trước
phát hành. Font phải tiếp tục giữ license nếu đưa vào gói khác.

## Kiểm thử và evidence

```sh
node --test tools/design/test_first_play.mjs
# Server phải đang mở đúng prototype. Install dependency test một lần:
cd tools/design && npm install
# Nếu cần: BROWSER_EXECUTABLE_PATH=/path/to/chromium
node smoke_first_play.cjs
```

Browser test dùng Playwright Core + Chromium, yêu cầu thư viện NSS/NSPR. `GALLERY_URL`
có thể trỏ tới server khác. Mặc định port 8000. `test_first_play.mjs` chỉ dùng Node stdlib.

- 8 unit test: fixture khớp repo, thắng rm_01/rm_02, collision, biên, chưa tới đích,
  nhặt gem, lượt chạy độc lập và lệnh không hợp lệ.
- Browser: luồng chọn làng/vào chơi, lỗi, gợi ý + Escape, hai màn thắng, gem, trạng
  thái địa điểm chưa mô phỏng, viewport 1440×1100 / 390×844 / 360×640, không tràn ngang,
  board không che goal/feedback, nút điều hướng >=48 CSS px, không lỗi JS/HTTP.
- Ở mobile, toolbar review chiếm khoảng 47 px của viewport; không nhầm kích thước
  viewport trình duyệt với usable app area hay ảnh Flutter cùng tên kích thước.
- `evidence/` là screenshot **HTML design prototype**, không phải before/after Flutter.
  `browser-check.json` ghi phạm vi test. Chưa có user test trẻ em, perf trên Android,
  talk/listen animation, pan map, runtime cache budget, persistence hay AI thật.

Đã phát hiện lỗi board đè goal/feedback ở màn 360×640 khi làm prototype; sửa flex
sizing để không shrink board qua panel khác và thêm kiểm tra chống overlap.
Các màn ngắn có thể cuộn trong viewport app; khi triển khai Flutter cần kiểm tra
reachability CTA với textScale/keyboard, không chỉ “không có exception”.

## Bàn giao cho agent code

1. Không copy nguyên HTML/engine vào app, không thay map/hitbox bằng ảnh concept này.
2. Đối chiếu từng state với source Flutter, báo điểm chưa thể tái hiện/cần asset layer.
3. Lấy đây làm mẫu trao đổi design, không tự coi là người dùng đã duyệt art cuối.
4. Chỉ triển khai phần có task `READY_FOR_CODE` và runtime=yes. Task hiện tại chỉ
   cho phép test/evidence/feasibility; không bỏ gate Tutor, progression, safety.
5. Nếu layout chưa ổn trên máy nhỏ hoặc thiếu state, trả screenshot và câu hỏi cụ
   thể. Không tự thay phong cách để “code cho xong”.
