# Daily quests + Energy / eye break — r41 specification

Owner DESIGN ·2026-10-18 · [PQD-006](../coordination/tasks/PQD-006.md).
Bổ sung từ [audit38runtime screenshots](../runtime-gap-r41/README.md), không đổi
work order CODE011 hoặc mở implementation mới.

## 1. Trước và sau về thiết kế

Baseline31 là sheet ba card nhỏ, progress và nút claim cạnh nhau;30 là sheet chi
phí, thông tin hồi và nút nghỉ mắt. Cả hai có chức năng thật trong nguồn, **không
phải chức năng mới nghĩ ra**. Trước r41 chưa có study riêng của hai surface này;
Journal A01 là dự án dài hạn/kết quả chờ, không được dùng nó thay daily.

Bản mới đặt hai surface trong góc làng: quầy nhiệm vụ, bảng trống và ghế nghỉ.
Hình nền không chứa mục tiêu, số, tem đã nhận, giá, tên hoặc trạng thái. UI tách
riêng thành giấy ghi nhiệm vụ, sổ tem và phần năng lượng; blue/teal/pastel có chiều
sâu và contact shadow, không dùng ảnh phẳng làm phần thưởng. Bảng/cây/ghế nằm chung
mặt đất. Camera gần hơnW01, outline lá rõ hơn; **study mới, chưa canonical**.

Một scroller dọc trongphone; tabs chuyển daily/energy. Chi tiết nhiệm vụ là view
riêng; trở lại giữ scroll/focus. Tên/CTA wrap, text scale thật bằngrem. Header ở2×
đưa title xuống hàng đầy đủ. Không dùng transform để giả tăng chữ.

## 2. Nguồn pin

Exact CODE `4fe3b7d0a1bf5f6dface1b04cbc4e2d7ee9d451f`:

| File | Dữ liệu / ranh giới |
|---|---|
| `daily_quest_service.dart` |8definitions;1quest mỗi learn/practice/create; local-day selection; completed/rewarded; no streak/ad/purchase quests |
| `daily_quests_sheet.dart` | Current card/progress/claim/stamp book |
| `energy_service.dart` | Current/max/regen; map/completed lessons/achievements/Creator not locked by energy |
| `energy_widgets.dart` | Cost table, no-energy alternatives,20-second wellness break with no rewards |
| `game_config.dart` + `assets/config/game_config.json` | Initial max20, cap40, regen10minutes; costs from config |
| `state_repositories.dart` | Conditional markRewarded keyed local_day+quest_id; totalStamps counts all rewarded rows |

[Source manifest](source-manifest.json) lưu blob vàSHA256 của7file. Không import
runtime vào app DESIGN. [catalog.js](catalog.js) giữ exact VI titles/targets/category/
BugHunter flag và config costs; EN là DESIGN translation mới, không giả là app ARB.
Không thực thi hay dịch các event predicates Dart thành game simulation.

**Điểm chưa đồng nghĩa giữa lời và luật nguồn:** `arcade_star` ghi “Nhận sao…” nhưng
predicate nguồn kiểm arcade `levelCompleted` mà không tự kiểm `stars >=1` trong
closure ấy. r41 không sửa luật hoặc tự đánh dấu hoàn thành khi chơi; chỉ hiển thị
literal nguồn và fixture tiến độ. Cần đối chiếu event producer/contract khi có
implementation order, không coi dòng chữ là bằng chứng event semantics đã QA.

## 3. Daily quests, nhận tem và ngày mới

- Three sample quests:code_runs_3,arcade_star,robot_code, cùng ba thẻ trongbaseline31.
  Các trạng thái khác nhau dùng cùng ID để so sánh bố cục. **Không phải kết quả
  chạy `_pickFor(2026-10-18)`**.8definitions có pin không nghĩa cả8xuất hiện hôm nay.
- Ngày18/19 vàsổ2/3tem là dữ liệu mẫu có nhãn. Card đọc được progress0..target;
  completed≠rewarded. Mở xem không tự tăngprogress. Không bịa shop đổi tem/vật liệu.
- Nút “Thử nhận tem mẫu” chỉ tạo request trongmemory; số tem **không tăng lạc quan**.
  Pending chặn double-submit. Reviewer ngoài phone trả thành công/lỗi; đúng token
  và ngày mới được áp dụng. Thành công tăng đúng1tem mẫu, duplicate bị bỏ qua.
- Lỗi trong prototype là phản hồi mẫu **đã biết thất bại**, không phải mô hình hóa
  network timeout/ACK lost. Runtime thật phải re-read authority khi kết quả chưa
  rõ; không dựa vào mock này để chứng nhận giao dịch an toàn hoặc backend idempotency.
- Retry cótokenmới. Locale/scale/tab giữ request. Chuyển fixture tạo phiêntestmới
  với tokenunique; stale response không cập nhật fixture khác.
- Reviewer next-day chỉ minh họa một lần18→19: bỏ pending của ngày cũ, reset các
  thẻ sample, giữ tổngtem. Không mô phỏng day picker, clock skew, timezone switch
  hoặc claim lịch sử. **Không hứa tem chưa nhận được carry qua ngày mới**; cũng
  không tạo cảnh báo gây sợ mất thành tích. Dự án dài hạn không bị daily reset.
- Nếu mởphone riêng, claimpending chờ reviewer harness; không có backend hoặc
  autosuccess. Không giả route vào Main Quest/game. Detail ghi rõ chưa nối hoạt động.

## 4. Năng lượng và nghỉ mắt

- Partial11/20,next06:45 là snapshot mẫu;0/20 và20/20 là hai state riêng.
 20 là sample initial max, **không phải max vĩnh viễn**: nguồn cómilestones vàcap40.
- Config costs: new mini-game2; arcade run2; first Main Quest lesson1; first chapter
  challenge3; review0; creator0; completed mini-game replay0. Không đổi economy.
- Empty không khóa map, review bài đã học, achievements, Maze Creator, code playground.
  Copy ưu tiên lựa chọn miễn phí, không ads/purchase/refill pressure.
- Load/error hiển thịunknown, không coi là0. Chi phí là read-only catalog, không
  CTA bắt đầu/spend. Bản thử không tự hồi năng lượng hoặc tạo activity session.
- Eye break20giây là timerlocal, códừng sớm. Tab khác/dừng nghỉ không tiếp tục tick;
  hidden document dừng tick; pagehideclear timer. Không âm thanh/AI/đo mắt thật.
- Không tem hay energy bonus khi hết timer. Nguồn córegen riêng vẫn có thể tăng
  energy theo thời gian thật; **không được suy “energy không bao giờ tăng lúc nghỉ”**.
- Calm/reduced-motion: không animation cảnh/vòng chạy; chỉ số giây thay đổi, không
  liveannounce từnggiây. Prototypekhôngđo thiết bị, khôngmedicalclaim.

## 5. State matrix

16fixtures:
`daily_ready`, `daily_progress`, `daily_claimable`, `daily_claim_pending`,
`daily_claim_error`, `daily_claimed`, `daily_loading`, `daily_error`, `daily_new_day`,
`energy_partial`, `energy_empty`, `energy_full`, `energy_loading`, `energy_error`,
`break_active`, `break_done`.

Manual controls ở ngoàiphone:fixture,language,textsize,response success/failure,
next sample day,one tick,automatic seconds. Default locale theo browserVI hoặcEN
fallback; manualoverride trongphiên/query. Không ghiSettings mới; product thật giữ
system default+Settings override hiện có.

Nativecontrols≥48px, headings/progress labels, visiblefocus, detailEscape/back,
statusannouncement không đọc liên tục timer. Hai locale×hai viewport390×844/360×640
×ba scales1/1.3/2××16fixtures =192cases. Costtable được mở trong toàn bộ matrix để
không bỏ sót text ởdetails đóng. Test cả page horizontal/vertical overflow, footer,
innerbounds, truecomputedfonts, unknowncounts vàreviewer separation.

Đã chạy:192/192cases,3,624fontchecks,11flows,17modelchecks. Rà captures đại diện,
sửa riêng live-region absolute gâydocument scroll thừa và dùngprogress track rõ.
Đã chạy lại toàn bộ sau sửa. Không tuyên bốscreen-reader/device/Flutter/contrast
certification hoặc service/repository/engine tests từ kết quảHTML.

## 6. Mỹ thuật và phần chưa có

`assets/garden-kiosk.png` là một ảnh AI-generated mới trong larger prototype,
reference W01; prompt vàhash được lưu. Không alpha/layers/rig/geometry/anchor runtime,
không animation nhân vật. Không thay canonical. Không claimCC0/exclusiveownership.
Nềnkhôngthaythếinteraction; card/status/text ởDOM riêng.

Trước implementation cần authority/day-boundary/loading/error hợp đồng rõ, locale
ARB thật, layoutadaptive khi thànhsheet/fullscreen, navigation thật, screenreader,
Flutter/devicecaptures before/after vàartcalibration. Không dùng ảnh này như bằng
chứng hai mànđãlênapp. R41 không tự cấp quyền đổiengine/reward/CI/deps hoặc011.
