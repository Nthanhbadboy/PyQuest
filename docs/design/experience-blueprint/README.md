# PyQuest — Bản đồ trải nghiệm và luồng thiết kế song song

Ngày: 2026-10-16. **Blueprint sản phẩm, không phải ảnh app hoặc tuyên bố đã triển khai.**
Mục tiêu: thiết kế đi trước đủ một luồng hoàn chỉnh để code không phải tự đoán UX;
không chờ board/locale xong mới nghĩ tới mini-game, bạn bè, thi đấu và vinh danh.

Sơ đồ tổng quan: [`experience-map.png`](experience-map.png).
Gói gần nhất: [**P06C — màn chính và nhiệm vụ liên kết**](P06C_LINKED_JOURNEYS.md):
7 màn, hai mini-game thao tác được, huy chương/vật liệu → mở Gác sáng tạo.
Gói [P06 A — Bưu điện Mây](P06_CLOUD_POST.md) giữ lớp bạn bè, kệ và thiệp.
**Bổ sung định hướng:** [P06B — nhà, đất, đảo và thú cưng thông minh](P06B_LIVING_HOMES_ISLANDS_PETS.md).
P06 A là lớp giao lưu; P06C thêm chuỗi mở phòng. Không gian đi lại/sắp đồ/thăm nhà
đồng bộ và AI local của P06B chưa triển khai; không đánh đồng ba phạm vi.
**Cập nhật:** [P06 đã có prototype tương tác](../friends-showcase-prototype/README.md),
12 fixture, art mới, VI/EN, 414 cấu hình kiểm bố cục và handoff; chưa tích hợp Flutter.
[P05 — kết quả và cuộc phiêu lưu tiếp theo](P05_RESULT_TO_NEXT_ADVENTURE.md) vẫn giữ nguyên.

## 1. Tầm nhìn chung: nhiều cách chơi, một thế giới

```text
Làng / trở lại phiên đang dở
  ├─ Chơi ngay: mini-game → kết quả → chơi tiếp / nghỉ / về làng
  ├─ Sáng tạo: tạo → thử → sửa → lưu tác phẩm → trưng bày
  ├─ Học: Tutor + bảng → tự thử → hiểu → vận dụng vào hoạt động phù hợp
  ├─ Kết nối: bạn bè → thăm tác phẩm → lời khen / mời chơi / hợp tác
  └─ So tài: luyện tập / thi đấu / giải sáng tạo / đội
                         ↓
          ghi nhận đúng kết quả, phần thưởng có nguồn
                         ↓
       Nhà Thành Tích / bộ sưu tập / hồ sơ được chia sẻ
                         ↓
      mục tiêu tiếp theo có ý nghĩa, không bắt buộc liên tục
```

Tutor là bạn đồng hành xuyên suốt, **không phải cổng bắt buộc trước mọi mini-game**.
Chơi một mình luôn có giá trị. Bạn bè/Arena tăng chiều sâu, không khóa kiến thức cốt
lõi sau kết bạn hoặc mua quà. Không có XP/cấp độ toàn cục; điểm từng hoạt động, tổng
sắp, danh hiệu kỹ năng và danh hiệu xã hội là các khái niệm khác nhau.

## 2. Hai luồng công việc không giẫm lên nhau

| Design làm trước | Code đang được phép làm | Chỗ hẹn gặp |
|---|---|---|
| Journey, state, bố cục, copy VI/EN, hình/animation brief, prototype review | PQC-010 board độc lập,014 resolver/migration,015 delegates/ARB foundation | Bàn giao gói có state và source mapping; review evidence ở điểm kết thúc mỗi gói |
| Kết quả/thưởng, Nhà Thành Tích, bạn bè/Arena, mini-game và hệ thống UI | Không yêu cầu code bỏ ba gói nền để làm ngay các gói này | Chỉ mở runtime work order mới sau khi đủ thiết kế và phạm vi triển khai được cấp |

Đã fetch code tới `ca2050a` khi soạn blueprint: phía code đang có các commit làm/sửa
PQC-010. **Không audit/accept CI của tip đó trong gói này.** Không đổi header quyền,
không thêm forward pointer làm coordinator chuyển khỏi PQD-003 revision 6.
Đây là **mốc lịch sử lúc soạn blueprint**; review sau đó đã lên r7. Gói P06 không đổi
coordinator hoặc quyền runtime hiện hành (xem handoff P06 và review r7).

## 3. Các gói thiết kế có thể làm ngay

Thứ tự dưới là **thứ tự thiết kế**, không là lời hứa phát hành toàn bộ một lúc.
Mỗi gói chỉ mở một luồng thử sâu trước, không làm hàng chục ảnh happy-path rời rạc.

| Gói | Đầu ra cụ thể | Làm trước mà không chờ code | Phần phải đợi trước khi ship |
|---|---|---|---|
| **P05 — Qua màn → được ghi nhận → chọn việc tiếp** | Storyboard, màn thắng/chưa đạt/kỷ lục/chơi lại; luồng thưởng và Nhà Thành Tích; copy theo tình huống | Thiết kế ngay trên dữ liệu kết quả hiện có; ưu tiên đầu tiên | Port Flutter và chứng minh kết quả/lưu thưởng thực, không cộng trùng |
| **P06 — Giao lưu & không gian sống** | A: bạn bè, kệ, thiệp, block/report. B: mở nhà/đất/đảo, thăm nhà có hoạt động chung, mua thú thông minh | A/C đã có prototype; C nối hai game → badge/vật liệu → phòng; B giữ design brief và gate AI local | Identity/consent, world/session authority, lưu trữ/transactions, moderation; benchmark AI on-device và entitlement thú |
| **P07 — Arena & Creator League** | Chọn bộ môn → xem luật → đăng ký → chờ → thi → kết quả → bảng hạng; đối kháng/sưu tập/đội có vai trò riêng | Mẫu thi đấu đầu dùng Maze để dễ liên hệ gameplay; nguyên tắc UI chung cho các bộ môn | Matchmaking/session/result authority, chống gian lận, disconnect/reconnect, scoring rules được duyệt |
| **P08 — Mini-game có bản sắc** | HUD/gameplay/result mẫu cho Maze, Dragon Jump, Catch Stars, Bug Hunter; Creator Mode riêng khi phù hợp | Visual grammar, onboarding chơi ngay, feedback va chạm/nhặt đồ, pause/retry | Physics/hit testing/frame budget và kiểm máy thật; không sửa luật để khớp tranh |
| **D-UI — Bộ giao diện game dùng chung** | Buttons/chips, sao, reward cards, bảng xếp hạng, modal, loading/empty/error, focus; animation timing và calm variants | Làm cùng P05 rồi kiểm lại ở P06/P07, không chờ Flutter widget library | Tích hợp component + font scale/keyboard/device evidence |
| **D-ART — Art & motion 2.5D** | Camera/scale/palette, tách background/landmark/NPC/FX, badge/title silhouettes, sprite/pose brief | Mẫu nhỏ có trạng thái và kích thước đích; không cần engine mới để chọn hướng | Duyệt art riêng, atlas/export/occlusion/nav footprint/performance; không swap asset đang blocked |
| **D-COPY — Nội dung & đa ngôn ngữ** | Copy VI/EN cho mọi state mới, Tutor khen/gợi ý theo kết quả, empty/error/a11y; thuật ngữ và slot tham số | Soạn pack theo semantic ID, giữ code/output/đáp án bất biến | Review nội dung với người đọc phù hợp độ tuổi và nối vào registry/ARB |
| **D-WORLD — Đảo, nhà & nội dung dài hạn** | Bản đồ chức năng, chuyện của từng nơi, vai trò vật phẩm/danh hiệu, ý tưởng sự kiện | World bible + sơ đồ tuyến chơi gắn hoạt động thật | Content/gameplay khả dụng, navigation, streaming/memory, season operations |

**Cập nhật sau blueprint:** P05 và **P06 Bưu điện Mây** đã có prototype HTML tương tác,
art, state matrix và evidence để review; chưa phải màn Flutter/asset được duyệt cho production.
P07/P08 tiếp tục ở backlog. Nhánh chia sẻ của P05 và tương tác xã hội ở P06 đều là
simulation, không phải social backend. P06 giữ đầy đủ các nhánh đội nhóm/triển lãm/quà mua sẵn/
quà tự làm và lập trình trong roadmap §16, không thu hẹp tầm nhìn thành danh sách bạn.
P02/P03/P04 vẫn là các prototype đã bàn giao trước.

## 4. Chuẩn bàn giao của mỗi gói

Một gói được gọi **design-ready** khi có đủ:
1. Đường vào, hành động chính, thành công/thất bại và đường thoát. Nêu ai muốn làm gì.
2. State matrix: loading, empty, pending, error, retry, offline, disabled/permission,
   interrupted/background, quay lại; chỉ chọn state thực sự có ý nghĩa cho luồng.
3. Phone 360×640/390×844, nội dung cuộn khi cần; VI/EN, font 1/1.3/2, giảm chuyển động,
   tên/role/focus order và cách thao tác không cần vẽ/kéo/nghe.
4. Source mapping: trường thật nào có sẵn; trường nào **đề xuất**, chưa phải API.
   UI không tạo kết quả trận, claim thưởng hoặc bằng chứng “đã lưu” thay backend.
5. Assets có provenance/kích thước/layer/pivot/license; bảng crop/hit-target nếu là map.
6. Prototype hoặc storyboard có các state trên, kịch bản kiểm chứng và phần chưa kiểm.
7. Implementation slice đề xuất có allowlist; **design-ready không tự cấp runtime**.

## 5. Thiết kế xã hội & thi đấu trước khi có backend: phân biệt rõ ba mức

- **Có thể chốt ngay:** bố cục/profile sections, tên hành động, lời khen có kiểm soát,
  private/public indicators, cách xem luật/mục tiêu, cách phân biệt cá nhân/đội và loại
  trận, màn pending/không có dữ liệu. Mẫu dùng dữ liệu minh họa ghi nhãn rõ.
- **Đề xuất để review:** cơ chế lời mời (ví dụ mã mời giới hạn), phạm vi hiển thị hồ sơ,
  thời hạn/quota tặng quà, luật hòa và giải thưởng. Chưa tự chốt con số kinh tế.
- **Không được giả làm thật:** người online, thành viên đội, đối thủ người thật,
  matchmaking, rank/giải thưởng, consent/moderation hoặc giao dịch đã thành công.

Với trẻ em: không tìm bạn bằng danh bạ/vị trí thật theo mặc định, không ép chat tự do,
không bắt mua quà/đáp lễ. Cần review quyền riêng tư/phụ huynh và pháp lý theo thị trường
trước phát hành; wireframe có nút chặn không chứng minh hệ thống đã an toàn.

## 6. Vòng quay lại lành mạnh

Mục tiêu là trẻ **muốn quay lại vì vui, tiến bộ và có bạn**, không kéo dài phiên bằng
áp lực. Cho lựa chọn chơi tiếp, đổi hoạt động hoặc nghỉ; thành tích đã kiếm không mất
khi vắng mặt. Không giả countdown/đối thủ/“bạn đang đợi”, không cấp thưởng ngẫu nhiên
kiểu loot box, không rank shaming. Nhắc nghỉ đi cùng nhịp hoàn thành tự nhiên.

Thiết kế kiểm khả năng hiểu bằng nhiệm vụ: biết vì sao nhận sao/huy hiệu; biết xem
thành tích; phân biệt luyện tập với người thật; biết giới hạn chia sẻ và quay về chơi
một mình. Chưa user-test thì không báo đã tăng retention hoặc đã được trẻ xác nhận.

## 7. Sổ quyết định còn mở — không âm thầm thay luật

| ID | Vấn đề | Hướng xử lý của design |
|---|---|---|
| OPEN-01 | Game Design §8 liệt kê Night Owl sau 20:00, nhưng cũng nói huy hiệu không theo thời gian chơi; nhóm dưới 12 tuổi | Chưa dùng badge đêm làm động lực trong mẫu mới. Đưa ra review sản phẩm/an toàn riêng, không xóa/sửa luật nguồn trong gói này |
| OPEN-02 | Tổng sắp có nhiều nhánh, trọng số/cap chưa đủ cho một mùa thi thật | Thiết kế slot “Cách tính điểm”/“Kỳ xếp hạng”; không tự đặt hệ số hoặc quà như luật đã chốt |
| OPEN-03 | Bạn bè/đội/UGC cần quyết định consent, discoverability, moderation, loại tin nhắn | Làm đủ state và phương án private-first; chốt policy trước runtime/backend |
| OPEN-04 | Cảnh P04 chỉ có vài landmark minh họa, không đủ toàn module trong blueprint | Không đặt mọi tính năng thành nút “sắp ra mắt”; IA sản phẩm đầy đủ tách khỏi nav đang chạy |

## Nguồn

- `docs/PRODUCT_VISION.md` §7,11–16: Play/Creator, Nhà Thành Tích, recap, Arena, Tutor,
  vòng lặp dài hạn, bạn bè/quà/đội. `docs/ARENA_CREATOR_COMPETITION_BRIEF.md` mở rộng Arena.
- `docs/GAME_DESIGN.md` §4,6–12: sao, danh hiệu, tổng sắp, nhiệm vụ, thưởng và luật.
- `docs/TECHNICAL_ARCHITECTURE.md` §3.5,4,5.4: activity modules, persistence và nguồn kết quả.
- `../FULL_APP_REDESIGN_CHARTER.md`: phạm vi toàn app; `../LANGUAGE_AND_LOCALIZATION.md`:
  system/manual language; `../coordination/tasks/PQD-003.md`: quyền code hiện hành.

## Tái tạo sơ đồ và phạm vi kiểm tra

Dùng môi trường Python riêng cho design (không đổi dependencies của app):

```sh
python -m pip install -r tools/design/requirements.txt
python tools/design/render_experience_blueprint.py
```

Sơ đồ dùng Nunito đã có trong `docs/design/tutor-board-prototype/fonts/` (OFL).
Đã kiểm render PNG 1680×1280, xem bố cục, tính lặp lại của output và đường dẫn tài liệu.
Đã đối chiếu các trường result/reward với source snapshot ghi trong brief P05.
Đây **không phải** kiểm thử Flutter, backend, thiết bị hoặc thử nghiệm với trẻ em.
