# Bàn giao cho AI triển khai — PyQuest 2.5D

Ngày: 2026-10-16. **Đây là kế hoạch/bàn giao, không phải bằng chứng app đã thay giao diện.**

**Cơ chế phối hợp đã chọn:** hai agent giữ hai nhánh riêng, chủ động fetch và đọc
bàn giao của nhau ở đầu/cuối lượt. Xem [quy ước design ↔ code](CROSS_BRANCH_COLLABORATION.md).
Không yêu cầu agent code đổi sang nhánh design; các chỉ dẫn không đổi nhánh bên
dưới áp dụng cho phiên design hiện tại.

## 1. Nhận đúng phiên bản trước khi làm

- Workspace chuẩn của đợt này: nhánh `arena/00838eb9-pyquest`.
- Source được nhập từ snapshot `c8b2029` của `arena/b813b575-pyquest`, rồi bổ sung
  bộ thiết kế tại `docs/design/village-kit/`.
- **Bộ asset mới không nằm trong snapshot `c8b2029`.** Chỉ clone nhánh nguồn cũ sẽ
  không nhận được các file thiết kế mới.
- Mốc nhập source đã tách thành commit `dafde39`. Asset/spec và tài liệu bàn giao
  được đóng gói ở commit design riêng sau đó. Bên nhận phải fetch remote thành công,
  xác nhận file tồn tại và pin SHA thực tế; không chỉ dựa vào lời thông báo đã commit.
- Lần nhận đầu: làm nhiệm vụ `docs/design/coordination/tasks/PQD-001.md` trước.
  Trạng thái task này quyết định được code ngay hay cần ACK/đợi duyệt.
- Nếu chuyển qua GitHub, kiểm tra `git status`, diff và file chưa tracked trước khi
  commit; không bỏ sót `source/`, `exports/`, manifest, script và source vừa nhập.
  Không đưa `.venv`, `node_modules`, build output hoặc secret vào commit.
- Trong phiên Arena hiện tại, không đổi nhánh. Nếu được yêu cầu xuất bản, chỉ push
  `git push origin arena/00838eb9-pyquest`; không push vào nhánh nguồn hay main.

### Đọc theo thứ tự

1. `README.md` và trạng thái triển khai trong bốn tài liệu sản phẩm/kỹ thuật.
2. `docs/design/BRANCH_IMPORT_AND_ASSET_AUDIT.md` — nguồn, khác biệt và giới hạn test.
3. `docs/PyQuest_Reffrence_Images/VILLAGE_2_5D_REDESIGN_BRIEF.md` — gate và ràng buộc.
4. `docs/design/village-kit/README.md`, `art-direction.json`, `manifest.json`.
5. Gallery, 21 reference gốc và screenshot baseline liên quan tới màn định sửa.
6. Source và test của module đó; không suy diễn trạng thái app từ mockup.

## 2. Ranh giới của bộ ảnh hiện có

**Có:** 6 minh họa địa điểm, PNG gốc 1024×1024, WebP 256/512, nền liền có bóng.
**Chưa có:** sprite alpha, NPC animation, terrain nối được, map nhiều lớp, art trong
màn chơi, bộ trạng thái UI, model 3D.

- Dùng ảnh mới làm card/thumbnail; không dùng như tile-map hoặc bản mê cung thật.
- Không nhúng chữ, điểm, giá, năng lượng, trạng thái khóa vào bitmap.
- Giữ ID hoạt động, progression, SQLite, điều kiện mở khóa và năng lượng.
- Không thêm global XP, nút Arena/Shop/Community giả hoặc chức năng chưa có backend.
- Chưa có xác nhận duyệt bộ ảnh cuối cùng; cần người dùng chốt trước khi ship.
- Gate Tutor của brief chưa được đóng bằng bằng chứng thiết bị trong phiên thiết kế.
  Không tự đánh dấu hoàn tất hay triển khai full village redesign để bỏ qua gate.

## 3. Gói triển khai đầu tiên — chỉ sáu thumbnail

Đây là lát cắt nhỏ để kiểm tra phong cách trong Flutter, **không phải viết lại map**.
Thực hiện sau khi được duyệt phạm vi và xác nhận các gate liên quan của brief.

### File cần xem

- `app/lib/app/activity_registry.dart`: danh sách sáu hoạt động.
- `app/lib/modules/main_map/activity_sheet.dart`: thumbnail 104×104, `BoxFit.cover`.
- `app/lib/modules/main_map/main_map_screen.dart`: map nền riêng và hitbox chuẩn hóa;
  không thay trong lát cắt thumbnail.
- Các file `*_module.dart` tương ứng: `ActivityDef.thumbnail`.

### Mapping cụ thể

| File mới trong `docs/design/village-kit/exports/` | Đường dẫn đích trong `app/assets/images/` |
|---|---|
| `python_academy_512.webp` | `thumb_tower.webp` |
| `robo_maze_512.webp` | `thumb_maze.webp` |
| `pip_volcano_512.webp` | `thumb_volcano.webp` |
| `star_observatory_512.webp` | `thumb_observatory.webp` |
| `bitsy_workshop_512.webp` | `thumb_workshop.webp` |
| `achievement_house_512.webp` | `thumb_house.webp` |

Nếu thay đúng tên đích, không cần sửa đường dẫn Dart hay thêm thư mục vào pubspec;
`assets/images/` đã được khai báo. Đọc source lại trước khi áp dụng vì có thể đã đổi.

### Quy trình

1. Lưu screenshot Flutter trước thay đổi và record commit/source đang test.
2. Kiểm tra hash các file nhận bàn giao bằng manifest.
3. Chỉ copy sáu WebP; không bundle PNG master, gallery hoặc baseline vào app.
4. Render/open đủ sáu ActivitySheet; xem trạng thái thường và khóa của Bug Hunter,
   tên dài, màn hình nhỏ, text scale lớn. Không ghi đè artwork map cũ.
5. Nếu thumbnail lệch màu với UI hiện tại, lập bản sửa UI riêng; không tiện tay
   thay toàn bộ theme, animation hoặc logic Tutor trong cùng thay đổi.
6. Cập nhật trạng thái triển khai riêng cho sáu thumbnail sau khi có evidence thật.

### Baseline và test không được vô tình ghi đè

`tools/design/export_village_kit.py` hiện copy thumbnail từ `app/assets/images/`
vào `baseline/`; `test_baselines_unchanged` hiện đối chiếu với app chưa thay art.

**Sau khi áp dụng art mới, không chạy exporter hiện tại một cách mù quáng:** nó sẽ
biến baseline cũ thành ảnh mới. Trước đó phải chỉnh exporter giữ baseline bất biến
(không ghi đè file có sẵn, xác minh hash đã lưu), và đổi test sang kiểm tra baseline
với hash cũ trong manifest thay vì yêu cầu app vẫn dùng ảnh cũ. Thêm kiểm tra riêng
rằng sáu ảnh runtime khớp export được chọn. Không chỉ xóa test đang fail.

### Kiểm thử tối thiểu

Chạy trong `app/` khi đã có Flutter SDK phù hợp source/CI:

```sh
flutter pub get
flutter analyze
flutter test --exclude-tags render
flutter test test/render/render_screens_test.dart --tags render
```

Source nhập về có dependency audio mới; cần review lockfile sau `pub get`, không
coi bộ test gallery Python/HTML là chứng nhận Flutter build thành công.

- Thêm/điều chỉnh widget test để mở đủ 6 sheet và xác minh asset được giải mã.
- Kiểm tra navigation, Bug Hunter unlock, progress vẫn lưu sau relaunch.
- Build/chạy Android theo workflow dự án; không đưa key bí mật vào tài liệu/evidence.
- Chụp ảnh trước/sau từ Flutter ở cùng kích thước và trạng thái dữ liệu; ghi rõ
  render test hay emulator/device. Không lấy ảnh gallery làm evidence app.
- Đo chênh lệch dung lượng APK và bộ nhớ khi mở sheet; ghi kết quả thật, không ước
  lượng thành số đo. Không thay `island_map.webp` hoặc hitbox trong gói này.

## 4. Các bộ cần thiết kế tiếp

Thứ tự này là **đề xuất ưu tiên**, chưa phải backlog đã làm xong hay scope tự động
được duyệt. Giữ gameplay độc lập; không bắt mọi trò chơi dùng camera isometric.

| Ưu tiên / bộ | Cần thiết kế | Source áp dụng | Điều kiện nghiệm thu chính |
|---|---|---|---|
| P0 · Hệ UI chung + Tutor mẫu | Màu/chữ/khoảng cách; button default/pressed/disabled/loading; sheet, trạng thái đúng/sai/khóa/hết năng lượng; một cảnh Tutor có listen/think/talk/error/celebrate | `shared/theme/`, `shared/widgets/`, `modules/tutor/`, `shared/characters/` | Đọc rõ code/chat, tên người nói đúng, state bám phiên thật, thoát/bỏ qua được; không biến lỗi thành animation trang trí |
| P1 · Robo Maze vertical slice | Tile cỏ/đường/tường/nước; rương đóng/mở; gem; Robo hướng di chuyển, bước/va chạm/ăn mừng; block lệnh và run/reset state | `robot_maze/maze_board.dart`, `maze_play_screen.dart`, `maze_workshop_screen.dart` | Chơi + Creator Mode dùng chung tọa độ, ô chạm đúng, đường đi rõ; replay/reset không lỗi |
| P1 · Main Quest / editor | Bài học, câu chuyện, quiz/ghép/xếp/code; output, lỗi/gợi ý, hoàn thành; portrait các Tutor xuất hiện trong bài | `modules/main_quest/`, `shared/widgets/code_widgets.dart` | Không nền họa tiết sau code; thiết kế đủ trạng thái sai/đúng/loading/offline và bàn phím mở |
| P2 · Dragon Jump | Pip idle/run/jump/double-jump/hit; đá/bụi/cột/bọ bay; xu/gem; nền 3 lớp và mặt đất; Tổ Rồng/ngoại trang | `dragon_jump/dragon_game.dart`, `dragon_jump_module.dart` | **Giữ side-view và physics hiện có**, chỉ làm khối/ánh sáng 2.5D; chân/anchor và hitbox nhất quán, pickup dễ thấy |
| P2 · Catch Stars | Bình hứng, star/golden/comet/rainbow/meteor phân biệt bằng hình; catch/hurt/combo; nền trời; chòm sao | `catch_stars/stars_game.dart`, `catch_stars_module.dart` | **Giữ góc nhìn phục vụ kéo ngang**, không ép isometric; sao/thiên thạch phân biệt không chỉ bằng màu |
| P2 · Bug Hunter | Xưởng trong nhà, Bitsy, biểu tượng lỗi, hint ladder, lựa chọn sai/đúng, màn khóa và chuyển tới bài cần học | `modules/bug_hunter/` | Câu đố/code là trọng tâm, không che gợi ý; điều kiện mở khóa không đổi |
| P2 · Thành tích / năng lượng / nhiệm vụ | Huy hiệu earned/locked/secret, bộ sưu tập, reward toast, energy states, nhắc nghỉ, empty state | `achievements/`, `energy/`, `daily_quests/`, shared widgets | Không lộ huy hiệu bí mật sai thời điểm; dữ liệu thật; không thêm global XP hay quảng cáo chưa triển khai |
| P3 · Village runtime kit | Ground/path/river/bridge, sáu công trình alpha, props, bóng rời, NPC idle/walk; map nhiều lớp + pan; hit target overlay | `modules/main_map/`, map model mới nếu cần | Tutor gate đạt; scale/camera/footpoint thống nhất; occlusion đúng; chỉ tới module thật; motion dừng khi background |
| Sau đó · Arena / Shop / Social | Chỉ brief/concept trước khi có flow, trạng thái, backend/policy và scope được duyệt | Tính năng tương lai | Không dựng nút giả hoặc coi minh họa như tính năng đã hoàn thành |

### Quy tắc 2.5D theo loại màn

- **Làng:** phù hợp isometric nhiều lớp; cần alpha, nền và bóng tách riêng.
- **Robo Maze:** source hiện là lưới trực giao. Lần đầu có thể giữ lưới, thêm độ dày
  và bóng cho tile. Nếu đổi sang isometric thật phải thiết kế phép chiếu + phép
  chiếu ngược cho chạm, selection, Creator Mode và test; không chỉ nghiêng hình.
- **Dragon Jump / Catch Stars:** làm vật thể có thể tích và nền chiều sâu nhưng giữ
  camera phù hợp cách chơi. “2.5D” không đồng nghĩa mọi game đều nhìn chéo.
- **Lesson / code / chat:** giao diện phẳng dễ đọc; chỉ nhân vật/illustration có khối.

## 5. Hợp đồng kỹ thuật cho asset mới

Trước khi tạo hàng loạt, mỗi bộ phải có một mẫu thử trong app và các thông tin sau:

- ID ổn định, màn/state dùng, file đích, source/provenance và điều kiện quyền sử dụng.
- Camera/perspective; tỉ lệ tương đối so với nhân vật/tile; hướng ánh sáng.
- Kích thước source và runtime; alpha **thật** nếu cần ghép nền, không nền caro giả.
- Sprite: frame rect, canvas chung, pivot/footpoint, hướng nhìn, duration/fps,
  loop/non-loop và fallback khi reduced-motion. Không tự bịa animation từ 1 ảnh tĩnh.
- Hitbox/collision do game định nghĩa độc lập artwork; vẽ debug overlay để kiểm tra.
- Tách layer cho phần phải occlude/đổi màu/đổi ngoại trang. Không bake UI text vào ảnh.
- Budget texture/decode/atlas và số NPC đồng thời phải được đo trên thiết bị mục tiêu;
  không bật animation controller/timer không giới hạn cho từng NPC.
- UI: đủ state normal/pressed/disabled/loading/error/empty/locked theo chức năng;
  ưu tiên Flutter vector/layout cho button/panel thay vì ảnh nền phóng méo.
- Evidence: ảnh runtime, video nếu cần chứng minh animation, test và trạng thái chưa
  kiểm chứng. Luôn phân biệt asset preview, render test và bằng chứng thiết bị.

Với animation cần nhất quán nhiều frame/hướng, ưu tiên một nhân vật được rig hoặc
model 3D được render cùng camera. AI image generation phù hợp concept/illustration;
không coi các ảnh sinh độc lập là một walk cycle đã dùng được.

## 6. Prompt giao việc cho AI triển khai (copy nguyên khối)

> Bạn tiếp quản PyQuest. Trước tiên đọc `docs/design/AI_IMPLEMENTATION_HANDOFF.md`,
> `docs/design/BRANCH_IMPORT_AND_ASSET_AUDIT.md` và `docs/design/village-kit/README.md`.
> Kiểm tra working tree và xác nhận có đủ 6 PNG master + 12 WebP + manifest mới;
> không chỉ lấy nhánh nguồn cũ `arena/b813b575-pyquest`. Không xóa thay đổi đang có.
>
> Đề xuất lát cắt triển khai đầu tiên chỉ gồm sáu thumbnail trong ActivitySheet.
> Xác nhận thiết kế đã được duyệt và trạng thái gate Tutor trước khi sửa UI. Dùng
> mapping file trong handoff, giữ map nền, hitbox, gameplay, SQLite, progression,
> unlock và Tutor logic. Không thêm tính năng tương lai hay global XP.
>
> Trước khi copy asset, bảo vệ baseline và sửa exporter/test theo mục 3 để không
> ghi đè ảnh cũ. Chỉ bundle WebP thật sự dùng. Chạy Flutter pub get/analyze/test,
> render đủ sáu sheet, kiểm tra điện thoại nhỏ, text scale và Bug Hunter bị khóa;
> chụp bằng chứng Flutter trước/sau. Nếu thiếu SDK/thiết bị, ghi rõ chưa kiểm chứng.
>
> Kết thúc bằng danh sách file thay đổi, kết quả test, ảnh evidence thật và việc
> còn thiếu. Không tự mở rộng sang map/NPC hoặc sửa cả trò chơi trong cùng lượt.
> Sau khi lát cắt được duyệt mới nhận gói tiếp theo trong mục 4.
