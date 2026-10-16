# P06C — Thiết kế màn chính, màn phụ và nhiệm vụ liên kết

2026-10-16 · Bản thiết kế có thể bấm thử. Không phải work order Flutter/backend mới.
Yêu cầu chủ sản phẩm: thiết kế dần màn chính/màn phụ/mini-game; mở phòng cần huy chương,
vật liệu và nhiệm vụ có liên kết, không phải những chức năng rời nhau.

## 1. Hướng thiết kế

Màn chính nên trả lời ba câu: **mình đang xây điều gì, đã đi tới đâu, giờ có thể làm gì?**
Dự án nhà là lời gợi ý dài hạn, không lấn át Tutor/mini-game và không thay Main Map
miễn phí bằng khu đất tư có paywall.

- Hero đảo có ngôi nhà đang mở rộng, suối/cầu/xưởng/bến gợi các bước tiếp theo.
- Dải dự án cho thấy tiến độ 0/3 → 1/3 → 2/3 → 3/3; đây là ba chặng của một dự án,
  **không phải cấp độ hoặc XP toàn cục**. Kết quả chưa nhận chưa tăng chặng đã hoàn tất.
- Hai game có nội dung và vật liệu gắn dự án; sổ hành trình làm rõ quan hệ đó.
- Điều kiện thiếu không chỉ hiện khóa: có nguồn, số còn thiếu, nút đến đúng công việc,
  và từ kết quả có đường trở lại dự án đang theo.
- Đã xây thì không hiện lại yêu cầu trả vật liệu; vào được phòng mới, huy chương còn
  trong túi, nhật ký cho thấy đồ đã dùng. Màn chính chuyển minh họa sang góc phòng.

Ngôn ngữ hình ảnh kế thừa P06: kem, xanh rêu, gỗ, giấy, 2.5D. Ảnh raster chỉ trang trí;
mini-game và controls là HTML semantic, không giả nút trên một tấm tranh.

## 2. Hợp đồng nhiệm vụ liên kết

Đọc [journey-spec.json](journey-spec.json). Đây là schema thiết kế, chưa là registry app.

### Các quan hệ khác nhau phải được tách

1. **Điều kiện truy cập hoạt động:** Maze/Bridge mở ngay. Không cần phòng để kiếm đồ mở chính phòng đó.
2. **Thành tích:** thắng một mini-game mẫu, xác nhận phần thưởng → sở hữu `first_steps` một lần.
3. **Nguồn vật liệu:** mỗi công việc dự án có một bundle, nhận một lần cho dự án này.
4. **Điều kiện mở rộng:** `has(first_steps) AND wood >= 3 AND cloth >= 2`.
5. **Chi phí xây:** tiêu 3 gỗ/2 vải khi commit thành công; **không tiêu huy chương**.
6. **Lợi ích sau mở:** thêm nơi đến và entry sáng tạo; không chỉ thay con số trên profile.

```text
play.maze ── thắng + claim ── claim.maze ── 2 gỗ ────────┐
                                                       ├─ build.loft → enter.loft
play.bridge ─ thắng + claim ─ claim.bridge ─ 1 gỗ, 2 vải ─┘
                └──────── lần đầu claim win: first_steps (giữ lại)
```

Hai công việc không khóa lẫn nhau. Đã thắng nhưng chưa nhận được lưu riêng theo job,
không nằm duy nhất trong `currentResult`: chơi game khác hay thất bại ở lượt chơi lại
không xóa kết quả trước. Nhận từ kết quả thất bại hiện tại vẫn bị từ chối; người chơi
có thể trở lại kết quả thắng cũ trong sổ hành trình.

### Chống vòng khóa và ngõ cụt

Mỗi dự án tương lai cần khai báo nguồn nào có thể tiếp cận **trước** khi mở nó.
Không đặt nguyên liệu duy nhất trong phòng/đảo đang bị khóa bởi chính nguyên liệu đó.
Không âm thầm đòi có bạn, mua thú hoặc mua quà để hoàn thành nhánh học cốt lõi.
Nếu nhiều nguồn vật liệu, có thể cho chọn hoạt động yêu thích; phải duyệt cân bằng và
quota, không chỉ nhân bản phần thưởng hiện tại. Garden/dock/island chưa có recipe
trong mẫu này; không giả nút “tiếp tục” dẫn tới một nhiệm vụ không tồn tại.

## 3. Nguồn thật và phần đề xuất

| Thành phần | Nguồn / trạng thái |
|---|---|
| Maze `rm_01` | Geometry từ `app/assets/data/robot_maze_levels.json`; test đối chiếu trực tiếp |
| Kết quả di chuyển | Tái sử dụng `first-play-prototype/engine.mjs`, không thay Flutter engine |
| First Steps | Giữ nghĩa lần thắng mini-game đầu; art P05. Ownership ở đây chỉ thuộc ledger mẫu |
| Bridge ba ván | Mini-game mới **đề xuất**, không phải game Flutter đã tồn tại. Cả ba horizontal = nối lối |
| Gỗ, vải, cost/quest rewards | Toàn bộ là **đề xuất để review**; không có claim đã tồn tại trong economy registry |
| Phòng và nội thất | Nội thất preview/route mẫu; chưa đặt/dời đồ hoặc chạy world scene |
| Mèo Mơ | Lời đáp authored, không inference/voice, không tuyên bố pet di chuyển thực |
| Tutor và Bưu điện | Link sang prototype khác, tab mới, không carry progress hoặc actor identity |

`command_limit: 4` của nguồn Maze không bị đổi thành luật thất bại khi quá bốn bước.
UI giới hạn queue 16 lệnh cho demo; simulator vẫn quyết định kết quả bằng vị trí/chướng
ngại/rương. Mẫu này **không chấm sao/điểm, không đổi năng lượng và không cấp app event**.

Bridge là bài nhập môn ngắn để chứng minh vòng chơi → vật liệu → mở rộng. Không coi
ba tấm ván là toàn bộ chiều sâu game: các màn sau có thể thêm góc quay, vật cản và
nhiều cách nối, nhưng cần level design và luật riêng trước khi thêm thưởng.

## 4. Transaction/state invariants

- Win → eligible/pending reward. Chỉ explicit claim mới thay túi/badge trong simulation.
- Dedup phần thưởng theo project-job, không theo số lần render hoặc số lượt replay.
- Preview và cancel không đổi tài nguyên. `beginBuild` chuyển pending nhưng chưa debit.
- Pending/failed không giả phòng đã mở. Retry kiểm lại điều kiện; ack kiểm lại cả connection
  và requirements, rồi debit vật liệu + grant room trong cùng bước model.
- Ack lặp hoặc request sau built không xây/trừ thêm. Không có đánh đổi huy chương.
- Offline vẫn cho thử game, giữ kết quả chờ; không claim/build như đã online. Checkbox
  kết nối chỉ là bàn thử, không mô phỏng đủ networking/reconnect production.
- Locale/font/route không reset ledger. Load fixture/reload mới reset theo nhãn rõ.

Production cần ledger/receipt bền vững, authoritative result và transaction atomic
trên account/project/version. `project-reward-maze` và `study-room-v1` chỉ là ID trong
phiên; **không copy chúng làm hệ thống idempotency/authorization đa người chơi**.

Phải xử lý app restart giữa pending, server đã commit nhưng response thất lạc, quyền
bị thu hồi, version recipe thay đổi, đồng bộ hai thiết bị và balance thay giữa preview
và ack. Hiện chỉ có negative tests cho revalidation mô hình cục bộ, chưa chứng minh
những trường hợp server này đã giải quyết.

## 5. Khả dụng, ngôn ngữ và accessibility

- Cả hai mini-game dùng button, không bắt phản xạ nhanh/drag/voice; cầu có nhãn vị trí và orientation.
- Maze có mô tả bản đồ cho assistive tech; từng lệnh có tên hướng, queue tối đa rõ.
- Focus về heading khi đổi màn, giữ control khi sửa lệnh/xoay ván; dialog có tên,
  Escape, Tab wrap, restore focus. Status không dựa vào màu đơn độc.
- VI/EN authored; default theo danh sách system có thứ tự, unsupported → English.
  Giữ raw `system`, chỉ lưu locale; storage lỗi nói rõ không lưu được.
- Tên Mơ, IDs, direction tokens, vật liệu/ledger không đổi khi đổi locale.
- Responsive reflow thay vì thu nhỏ chữ; targets button/select/external link ≥48 CSS px.
  Giảm chuyển động theo hệ thống hoặc lựa chọn; không âm thanh.
- Chưa kiểm screen reader trên thiết bị. 15 audit axe không thay chứng nhận WCAG;
  các contrast incomplete còn cần manual review, nhất là gradient/ảnh.

## 6. Những gói nối tiếp — triển khai thiết kế dần, không mở scope code ngầm

| Đợt thiết kế | Nội dung | Quan hệ với hành trình hiện tại |
|---|---|---|
| **P06C hiện tại** | Màn chính, dự án phòng, sổ hành trình, túi, hai game, kết quả, phòng mở | Một vertical slice đủ khép vòng |
| **Bố trí nhà/sân** | Đặt/dời đồ, lối đi không bị chắn, preview mở đất, phòng riêng/khu cho khách | Dùng entitlement phòng/đất, thêm recipe được duyệt; không khóa nguồn nguyên liệu sau chính dự án |
| **Vườn → bến → đảo** | Các hoạt động mới, bản đồ phân khu và sơ đồ điều kiện rõ | Mỗi khu phải mở thêm cách chơi; số liệu/nguồn vật liệu còn TBD |
| **Mini-game có bản sắc (P08)** | Bridge sâu hơn, Dragon Jump/Catch Stars/Bug Hunter HUD & feedback | Từng game có skill, outcome và reward contract riêng; không cùng một minigame đổi màu |
| **Thăm nhà/đội (P06B/P07)** | Presence, hoạt động chung, vùng edit có quyền, disconnect/thu hồi | Không buộc có bạn mới mở phòng/học; cần session authority trước khi gọi là tương tác thật |
| **Thú và shop** | Tính cách, hoạt động, xem mua/entitlement, research AI local | Benchmark/parental controls/giao dịch riêng; không giả local AI bằng câu thoại này |

Thiết kế các nhánh có thể làm song song nhưng không hứa tự chạy khi phiên agent dừng.
Không chuyển task coordinator hoặc triển khai Flutter/social/economy từ file này.

## 7. Bàn giao cho code

Đọc P06C như **reference đã có tương tác**, giữ work order hiện hành. Chưa được thêm
resource provider, sửa game_config/reward registry, nối scene vào app hoặc tải AI model.
Khi mở slice được cấp phép riêng: đề xuất domain IDs/schema, authority, allowlist/test,
nguồn cấu hình recipe và migration. Port visual phải kèm test hai thứ tự hoàn thành,
pending reward không mất, cancel/failed không debit, ack/retry không trùng, badge còn,
locale không grant và các điều kiện reachable không cycle.

Nhánh code đã được quan sát tại `6936796` khi bắt đầu gói; đây không phải acceptance
mới của PQC-010. Ảnh/tests HTML không thay review Flutter hoặc server.

Đã fetch lại trước bàn giao tới `4a2a582` (r7 C2); chỉ ghi nhận commit mới, chưa audit/accept runtime trong gói C.
