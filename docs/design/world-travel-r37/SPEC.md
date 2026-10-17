# W08 — Hải đồ, bến nguồn và hành trình đi đảo

**DESIGN r37 · 2026-10-18 · owner DESIGN · không phải work order CODE.**
User đã chuyển review r36 cho CODE và yêu cầu DESIGN làm phần không trùng việc.
Gói này độc lập với018 A corrections/B4 và011. Không đổi lịch hay allowlist của CODE.

## 1. Phạm vi và nguồn

**Thiết kế trải nghiệm W08**, không bổ sung engine travel hoặc nội dung đảo vào app.
Nguồn pin DESIGN `68f2590b5883ca8aa746ffde0814d60a32dacb3c`:
- [Product Vision](../../PRODUCT_VISION.md) §4.3–4.4: Main Map miễn phí; đảo cá nhân
  là không gian sở hữu, khác Side Map trả phí tùy chọn.
- [Game Design](../../GAME_DESIGN.md) §17.3: đi lại/travel không tiêu năng lượng mới;
  hoạt động tại đích vẫn có luật riêng. Không thưởng chỉ vì đi thuyền.
- [Architecture](../../TECHNICAL_ARCHITECTURE.md) §3/§11.3: source/destination,
  generation/cancel, load và access trước arrival; UI không sở hữu entitlement.
- [Roadmap](../../ROADMAP.md) R4: bến/đảo phải có việc làm, lỗi giữ nguồn, arrival một
  lần. Thiết kế này không tự mở triển khai R4 và không chặn công việc018.
- [WORLD_EXPANSION](../WORLD_EXPANSION_REDESIGN.md) W08; [art contract](../ART_DIRECTION_2_5D.md).

Đã đọc MainMapScreen tại runtime identity `a331ac110f19de63e9be6884d08db8c436054f50`,
blob `d9d35bacf663e22b986ae20273f1fc8aed27e7b9`. Đây không phải source authority của
travel mới. Không có nối router/world catalog/entitlement thật trong prototype.

### Tách việc rõ ràng

| DESIGN trong gói này | Không làm / không đụng |
|---|---|
| Hải đồ W08, chọn điểm đến, nguồn/đích, trạng thái đi/về | CODE018 Journal/Settings/Welcome/CatchStars/BugHunter |
| List thay thao tác trên bản đồ; đọc quyền/chuẩn bị nội dung | CODE018 Friends/Invites, Creator Editor, built-room, Miu rest |
| Một scene mới cho bản thử, hotspot/route/UI độc lập | Canonical16r35, package54file CODE1053973, reviewr36 |
| Spec lớp ảnh và chuyển động dự kiến | App, migration, backend, giao dịch, actor rig, runtime011 |

## 2. Bố cục và cách dùng

Cảnh biển liên tục là **bề mặt chọn điểm đến**, không phải một ảnh hero trang trí.
Ba nút48px gắn đảo, selected marker và tuyến bến–bến thay đổi theo lựa chọn. Danh
sách cung cấp cùng ba đích/loại khu cho người không muốn tìm hoặc pan/drag.

1. Header nói **Hải đồ** và **Đang ở…**, không có số XP, năng lượng hoặc ví bịa.
2. `Bản đồ / Danh sách` là hai cách chọn, không hai nguồn dữ liệu.
3. Nút1: public village; nút2: personal island; nút3: optional content pack.
   Cả tên lẫn loại có accessible name; không dùng màu để diễn đạt quyền.
4. Tờ thông tin bằng giấy/khung gỗ ở mép cảnh: một heading, message, hoạt động tại
   đích khi phù hợp; một primary action và đường hủy/chọn nơi khác.
Ngôn ngữ sản phẩm tiếp tục lấy từ LocaleController/System hoặc manual override014–016.
Selector VI/EN của reviewer không phải Settings mới và không lưu preference.

5. Xác nhận hiển thị **bến đi / bến đến**, không đánh đồng destination selection với
   đã đến. Không bắt trẻ xem animation để đủ điều kiện chơi.
6. Một scroll owner trong màn phone. Ở360×640 hoặc2× cho phép cuộn tới thông tin/CTA;
   không thu nhỏ chữ hoặc che lỗi bằng overflow clip. Map/list và state vẫn giữ.
7. Toolbar ngôn ngữ, fixture, scale, trace và nút giả lập response nằm **ngoài** phone.
   Link phone riêng giữ nhãn “Bản thử tương tác” ở footer; URL không chứng minh app.

**Tên và nội dung minh họa:** Đảo Khởi Đầu / Vườn Nhỏ / Rừng Gió. Không cấp quyền
sở hữu đảo cho người dùng. Hai căn nhà trong ảnh đảo cá nhân là props minh họa,
không phải blueprint hoặc nội thất mới của CODE. Không bịa giá, MB, phần trăm tải,
medal requirement, recipe, lesson ID, số thưởng hoặc năng lượng.

## 3. Mười chín trạng thái

| State ID (chỉ trong reviewer tooling) | Nội dung / hành động trong màn | Điều không được suy ra |
|---|---|---|
| overview | Chọn đảo hoặc danh sách | Chưa chọn không phải lỗi |
| public_ready | Public/free, xác nhận nếu ở bến khác | Không bán lại core Python |
| private_ready | Đảo cá nhân và mục đích ghé; xem hành trình | Không đồng nhất với paid pack |
| content_preview | Gói tùy chọn, core vẫn miễn phí; CTA thông tin gói disabled vì chưa có catalog | Không có purchase/parental/price flow trong scope |
| eligibility_missing | Điểm đến chưa mở; chọn khu khác | Không tự thêm số huy chương hoặc mua để vượt điều kiện |
| permission_unknown | Chưa xác minh, không cho đi | Chưa rõ khác bị từ chối; không tự coi localbool là bằng chứng |
| permission_denied | Chưa có quyền, chọn khu công cộng | Reselect không tự cấp quyền lại |
| pack_missing | Quyền hợp lệ nhưng thiếu nội dung trên thiết bị | Lỗi/tải gói không làm mất ownership |
| downloading | Chuẩn bị nội dung, có hủy | Không đổi current place |
| download_error | Thử chuẩn bị lại hoặc chọn nơi khác | Không chuyển thành “chưa mua” |
| confirm | Nguồn/đích rõ, lên thuyền hoặc ở lại | Không debit năng lượng/vật liệu |
| loading | Chờ nội dung/quyền, CTA đi tiếp disabled, hủy được | Skip không được vượt load/access |
| load_error | Giữ bến nguồn; thử lại bằng yêu cầu mới hợp lệ | Không tự tới đích vì animation đã chạy |
| cancelled | Ở lại nguồn; thử lại hoặc chọn khác | Late response không đổi nơi ở |
| sailing | Load/access hợp lệ; bỏ qua cảnh chuyển tiếp hoặc hủy | Marker pulse không tự commit arrival |
| arrived | Cập bến một lần; đường quay về | Không thưởng/claim/badge vì travel |
| revoked | Thu hồi, về bến public an toàn; bỏ dữ liệu riêng | Không chỉ phủ banner lên payload riêng |
| offline | Dừng bắt đầu chuyến mới, giữ current place | Chọn lại đảo không tự khôi phục kết nối |
| return_confirm | Hành trình ngược, giữ đúng bến nguồn mới | Lỗi quay về không teleport khỏi đảo hiện tại |

`permission_unknown` trong bản thử là fixture đọc trạng thái, không có real recheck
adapter. `eligibility_missing` không có link dự án/recipe vì nguồn đó chưa chốt.
`arrived` dừng tại handoff của hải đồ; chưa mở màn chơi tại đảo hoặc sắp xếp nhà.
Các thiếu sót này phải được giải quyết trong order runtime/content riêng, không tự
đánh dấu W08 production complete bằng19state.

## 4. Mô phỏng tương tác, không phải authority

`model.js` là reducer **chỉ nằm trong docs/design**. Current place, access và số
arrival là fixtures trong bộ nhớ, reset khi reload. Không fetch API, không viết
localStorage/IndexedDB, không download content/store receipt hoặc tiêu vật liệu.

```text
select → preview → confirm → loading
                       ├─ cancel/error/offline → giữ nguồn, invalid generation
                       └─ content ready + access valid → sailing
                                                   ├─ cancel → giữ nguồn
                                                   └─ skip/arrive → commit một lần
arrived → return_confirm → cùng gate load/access cho đường về
revoked → hủy pending + bỏ private details + public safe dock
```

- Request có generation token; response cũ sau hủy/lỗi không có hiệu lực.
- Fake automatic response chờ1100ms chỉ cho thao tác review tiện hơn, **không là
  thời gian tải/SLA**, không network measurement. Tắt checkbox để kiểm hủy/lỗi.
- Tải xong chỉ chuyển sang sailing; vẫn chưa đổi nơi ở. Không click tiếp thì
  không tự arrival. Không replay khi resume; background clears fake timer.
- Access denial được giữ khi chọn lại; không mở bằng nút chọn lại hoặc đổi locale.
- Locale/scale/map-vs-list không sửa request/current/rights. Dữ liệu mô phỏng chỉ
  thay khi đổi fixture hoặc có event được nêu. Không debug IDs trong phone.
- Các kiểm generation/idempotence dưới đây chứng minh **simulator**, không chứng
  minh server hoặc transaction của app. Không dùng logic này như authority thật.

## 5. Art, anchors và chuyển động

Một PNG mới sinh từ W01 + bản published W08 r35, đã mở full-size. **Không ghi đè**
nguồn canonical. Mục đích: giảm chi tiết nước ảnh thật, giữ ba đảo/bến đọc được,
loại route/boat/NPC/text bake để UI tự quyết tuyến và quyền.

**Đạt mức study:** khối đảo/công trình/đá/gỗ, ánh trên-trái, landmark tower và dome,
biển liên tục; route/markers/labels tách khỏi ảnh và đổi được trong HTML.
**Còn khác neo:** viền vẽ rõ hơn W01, mái tháp giản lược ngói, chi tiết/kiến trúc đảo
nhà thay đổi, camera chưa đo. Không promote thành neo mới hay final production art.

`anchors.json` ghi coordinate frame928×1152, marker center theo phần trăm và dock
SVG100×124.138. Đây là **UI placement đo bằng mắt**, không camera calibration,
navmesh, physics/collision hay footprint. Tuyến qua nước đã chỉnh tránh cắt vào
cụm cây trên đảo riêng; vẫn phải kiểm geometry thật khi sản xuất.

| Lớp tương lai | Hiện có | Trước production còn cần |
|---|---|---|
| Ocean / terrain | Cùng một opaquePNG | Tách nền, bờ, bounds và scale vật liệu |
| Landmarks / docks | Bake cùng đảo | Props, footprint, pivots, portal anchors có nguồn |
| Boat / wake | **Không có sprite** | Vẽ/export riêng, hướng quay, wake, occlusion đúng camera |
| Route / markers / HUD | HTML/SVG semantic overlays | Adapter availability/router, gesture/hit tests trong Flutter |
| Camera / navigation | Chỉ coordinate frame của ảnh | Đo world units, anchors, streaming, collision, safe return |

Chuyển động hiện có chỉ loading indicator và pulse marker hai nhịp; không gọi đây
là tàu chạy hoặc game animation. Calm/OS reduced motion bỏ chuyển động; trạng thái
vẫn có chữ. Đề xuất tương lai: chuyển cảnh ngắn, skip luôn có sau load/access, hủy
trước arrival; thời gian/art budget phải đo riêng. Không thêm engine/dependencies.

## 6. Evidence và gate

- [456 browser cases](evidence/browser-checks.json):19state ×2phone ×2locale ×3scale
  ×2view(map/list). Computed font sizes phải tăng thật; không overflow, control>=48,
  header không overlap, footer reach được và không internal IDs trong phone.
-12 browser flow checks: hotspot/list, cancel+late response, arrival, failed return,
  locale/scale giữ context, calm/OS reduced motion, fake load không auto-arrive.
- [16 reducer checks](evidence/model-checks.json): không economy, không duplicate
  departure/arrival, guards, revoke, offline/reconnect, source immutability.
- Screenshot review là đại diện, không tuyên bố nhìn thủ công456cases. Không chạy
  Flutter/device/network/store tests, không benchmark FPS hoặc memory trên máy thật.

Bước production chỉ được mở bằng work order riêng khi world catalog, availability,
asset layers, navigation và authority đã có. **Không giao cho CODE triển khai W08
trong lúc đang làm018.** W08 không thay brief/canonical reference của Batch B.
