# Robo Maze level selection — contract r45

2026-10-18 · DESIGN only. Bổ sung thiết kế cho baseline05/41, không thay runtime.

## 1. Cảnh và tổ chức thông tin

Khu vườn lấy hướng từ W01: đường đá liên tục, năm bệ chọn màn và Xưởng ở góc dưới.
Hai trang1–5/6–10 là cách chia viewport của **cùng catalog**, không phải đảo, region,
entitlement hay cổng khóa mới. Scene nền không đại diện cho geometry của level thật.
Số và trạng thái là lớp UI trước cảnh. Vàng chỉ current; xanh kèm số sao chỉ completed;
trung tính kèm “Chưa mở” cho locked. Không dùng màu làm tín hiệu duy nhất.

Header giữ progress/stars/energy; Continue dẫn tới firstOpen. Đã qua đủ10màn thì
CTA chuyển sang replay, kể cả tổng sao dưới30. Sổ màn cho xem đủ10tiêu đề, không
ellipsis. Màn khóa vẫn cho xem thông tin và lý do, nhưng không có Enter CTA.
Browse/page/journal/rules không tốn năng lượng. Inspect locked là đề xuất UX mới,
không phải quyền bỏ qua prerequisite hiện có.

## 2. Source mapping

Pin `71b0fd3fd8fb07c73596ce089fa2e68f6fe87964`; blob/SHA256 ở source-manifest.

| Source | Dùng cho |
|---|---|
| robot_maze_levels.json | rm01–rm10; order/title/storyVI/rows/command_limit/allow_loops; không copy solution/tip |
| robot_maze_module.dart | firstOpen; index0 mở hoặc records chứa previousID; entry/replay cost; Workshop miễn phí |
| maze_models.dart | Row symbols và dimensions; Repeat command count=1+body length; MazeStars rules |
| maze_play_screen.dart | Mục tiêu sao trong result; command target là bonus, không phải điều kiện unlock |
| game_config.json | New2/replay0/creator0; initial capacity20 |
| energy_widgets.dart | Cost0 không gọi spend; positive cost cần energy authority chấp nhận |
| progress_repository.dart | LevelRecords/best stars và completed IDs; study không đọc/ghi DB |

Loading/error/unknown, route book, inspect locked và invalid deep-link là **design
proposal**. Không nói Flutter hiện tại đã có các surface này. Khi port phải dùng
ngôn ngữ theo system và Settings manual override hiện có; reviewer VI/EN ở đây
không phải language picker mới trong product, không thay Settings016.

## 3. Mở màn, replay và sao

- Unlock theo ID màn ngay trước; không theo tổng sao, completed count hay trang map.
- New2; completed replay0. Energy0 chặn màn mới, không chặn replay/Workshop.
  Unknown energy không thành0. Unknown progress không thành0/10 hoặc0sao.
- Workshop0, không cần hoàn thành level/Main Quest. Route preview chưa phải editor.
- Đến rương mới có sao. Hai điều kiện thêm độc lập: đủ ngọc và trong mục tiêu lệnh.
  Màn không có ngọc đạt gem condition khi tới rương. Sao không phải currency tiêu đi.
- Command target là bonus objective. Với Repeat, số lệnh tính cả khối Lặp và body,
  không phải tổng bước sau expand. Study không chạy chương trình để tính sao.
- Sample records phải hợp lý với topology: rm01 không có ngọc; rm02 buộc đi qua ngọc,
  nên không dựng completed1star cho hai màn đó. Fixture one_star_unlock dùng rm03,
  nơi có đường tránh ngọc, để minh họa completed1star vẫn mở rm04.
- All_partial là10completed/20stars; perfect là10/30. Không gọi partial là “minimum”
  hoặc khẳng định đã tìm mọi mức sao có thể đạt bằng execution.
- Entry/replay/Workshop chỉ mở destination preview. Không debit/refund, award,
  event emit, save hoặc optimistic update. Records và energy không đổi.

## 4. Detail và phác đồ

Tiêu đề/story và allowLoops theo source. Read-only diagram giữ246ô của10màn.
SVG nhỏ chỉ là icon start/chest/gem; không dùng SVG phẳng để thay artwork2,5D chính.
Wall xanh, water xanh lam, floor đá có độ dày nhẹ; legend và text rows đọc được
không phụ thuộc màu. Tiles không phải controls hoặc gameplay. Không có solution
route; không đưa `solution` hay `tip` vào catalog JS.

Details hiện ba objectives, số ngọc và command target. Locked CTA chỉ chuyển tới
detail của màn trước. InvalidID có not-found riêng và lựa chọn mở journal rõ ràng;
không tự thay thành level1. Valid-but-locked deep-link giữ đúng ID và trang.

## 5. 15fixtures

new; returning(2completed/4stars); loop_ready(5completed); replay(energy0);
perfect(10/30); locked(màn8); energy_empty; energy_unknown; loading; load_error;
deep_link(màn9); unknown_link; all_partial(10/20); detail(màn3); one_star_unlock
(rm01=2,rm02=2,rm03=1; màn4mở).

Các completed lists là sample prefix. Unit test riêng dùng record không liền nhau
để kiểm previousID thay vì count. Capacity20 là sample profile chưa Main Quest bonus,
không áp đặt capacity20 cho mọi người chơi. EN là bản dịch thiết kế, chưa app localization.

## 6. Layout và accessibility

360×640/390×844, VI/EN, rem1/1.3/2. Chữ thật, không phóng ảnh thay text scaling.
Marker nở ở2×. Nút Workshop chuyển từ anchor trong cảnh sang full-width dock dưới
cảnh ở2×; không thu nhỏ font hoặc để che marker. Map canvas có aspect ratio riêng
nên reflow dock không dịch anchors. Một scroll owner cho main screen; native modal
có scroll riêng và background inert. Close/Escape trả focus đúng opener.

Matrix360cases gồm cả hai trang. Tap thật40marker ở2× (10×2size×2locale), Workshop,
keyboard và free fallback đều đạt. Chưa có manual screen-reader/contrast audit toàn
bộ palette; font/geometry tests không phải chứng nhận WCAG.

## 7. Boundary và phần tiếp

Không có work order runtime mới. PQC011r44 vẫn chờ SDK evidence; không nghiệm thu
qua artwork. Không đổi accepted tasks, receipts018 hoặc W01 canonical. Port cần
binding dữ liệu, async authority, real navigation/energy và Flutter after-captures.

Maze Creator là nhiệm vụ DESIGN tiếp theo: grid/brush/spawn/goal/validation/test/save.
Phác đồ read-only của r45 không được coi là editor đã hoạt động.
