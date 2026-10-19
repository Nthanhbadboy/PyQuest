# P04 — Một thế giới để lớn lên cùng

> **Cập nhật2026-10-18:** P04 là prototype lịch sử. Thiết kế hiện hành nối đầy đủ
> nhà–đất–đảo/visit/pet tại [WORLD_EXPANSION_REDESIGN](WORLD_EXPANSION_REDESIGN.md).
> Không dùng “Tutor ưu tiên” ở gói cũ để hoãn UI làng sau voice/local AI.

## Chốt hướng sáng tạo

Người dùng trao quyền chủ động sáng tạo cho design: Tutor có lời chào/bong bóng thoại
thay đổi, trẻ nhỏ đi chơi và ra vào nhà, nhiều làng/đảo và chuyến thuyền mở rộng thế
 giới. Mình chọn **quần đảo của những điều tò mò**, không dashboard khóa học có cảnh nền.
Đây là quyền phát triển ý tưởng, không tự động duyệt mọi asset/runtime của prototype.

Ba lớp trải nghiệm liên kết:
1. **Nhà để trở về:** Đảo Khởi Đầu, quảng trường, mèo phơi nắng, những người quen.
2. **Người đồng hành:** Tutor nhớ ngữ cảnh đang xem/làm, chỉ một điều thú vị, có thể
   thu gọn; đi vào bài thì mở bảng viết/vẽ của P03, không trở thành chatbot riêng.
3. **Chân trời để khám phá:** bến thuyền/hải đồ, mỗi làng có kiến trúc và hoạt động riêng.

## Quần đảo đầu tiên (concept, không phải ba vùng game đã ship)

| Nơi | Không khí / vai trò | Ý tưởng phát triển |
|---|---|---|
|Đảo Khởi Đầu|Đá sáng, mái xanh, vườn và quảng trường. An toàn, quen thuộc.|Main Map vẫn là hub; các hoạt động sẵn có và bảng Tutor, không ép Main Quest trước free-play.|
|Làng Tán Lá|Nhà gỗ trên cây lớn, cầu treo, cờ nhỏ, màu lá/đất ấm.|Creator, chế tạo và chia sẻ ý tưởng được kiểm soát; không phải chỉ đổi màu nhà của đảo đầu.|
|Đảo Sao Mai|Đá tím xanh, mái vòm, kính thiên văn, vườn hình trăng.|Quan sát quy luật, giải đố, kể chuyện bằng dữ liệu; chưa có bộ bài/luật chơi trong mẫu.|

Hải đồ là minh họa tổng quan, cận cảnh làng là diorama2.5D. Hai mức nhìn có thể khác
mức chi tiết, nhưng cùng palette, ánh sáng êm và silhouette rõ. Mỗi chuyến đi nên có
một khoảnh khắc nhìn thấy mình đang đi đâu, không phải một loading screen dài bắt buộc.
Không khóa các vùng chỉ bằng XP/chi tiền; content/prerequisite cần task sản phẩm riêng.
Tab về làng và truy cập Tutor là điều hướng nhanh, không bắt trẻ đi thuyền mỗi lần.

## Tutor sống động nhưng không phiền

- Lời chào có nhiều biến thể theo context: lần gặp, trở về, xem hải đồ, tới một nơi,
  chọn hoạt động. Không lặp ngay câu vừa nói; ưu tiên câu ngắn có hành động tùy chọn.
- P04 chọn điểm bắt đầu ngẫu nhiên trong kho câu **soạn sẵn**, rồi lần lượt theo
  context trong phiên. Không có AI generation, nhận dạng giọng nói hoặc profile nhớ trẻ.
- Không xoay thoại liên tục theo timer. Khi có AI/voice production: có khoảng nghỉ,
  chỉ một lời chủ động khi context đổi; không chen lúc nhập code, trẻ đang đọc/chạy
  bài hoặc Tutor đang nói. Tắt tiếng/thu gọn là lựa chọn thật, không phạt bỏ qua.
- Dữ kiện lời nói phải lấy từ trạng thái thật. Không nói “bạn đã giỏi hơn hôm qua” nếu
  chưa có bằng chứng. Câu về NPC trong mẫu được nhận diện là hư cấu, không giả multiplayer.
- Cùng identity/context đi qua thế giới và lesson; code/nét vẽ phải còn khi trở lại.
  Hỏi tự do/AI/voice vẫn theo safety và data policy của `TUTOR_TEACHING_BOARD.md`.

## Cư dân và nhịp sinh hoạt

Chọn **hai NPC trẻ hư cấu Mây/Bo + một mèo ambient** cho slice đầu. Không nhân bản
hàng chục actor chỉ để trông đông. Mỗi bạn có vòng: ở quảng trường → đi dạo → ghé cửa
nhà → ở trong nhà một lúc → quay ra. Không có tiến trình/thưởng gắn với việc đuổi NPC.

P04 dùng waypoint0..1 trong ảnh và SVG đơn giản; không navmesh, không pathfinding
production, chưa có layer occlusion thực. Đã chỉnh chân route theo đường/hiên nhà,
không lấy tâm mái nhà làm điểm tới. Sprite/walk-cycle/depth masks cần art handoff riêng.

Khi port:
- Walkable paths và portal ở **cửa**, foot pivot và depth theo chân; bóng và foreground
  masks riêng. Actor không xuyên mái/đi trên mặt nước. Không sinh vị trí ngẫu nhiên
  trong hitbox UI. Nền minh họa hiện tại không phải dữ liệu navigation.
- Một world clock/scheduler có giới hạn actor. Không một timer vô hạn cho mỗi NPC;
  paused/background/offscreen không chạy simulation bù hàng phút khi resume.
- Ambient không nhận pointer, không chặn landmark/card; không tự bật semantics
  announcements mỗi bước. Nếu cho nói chuyện NPC sau này, thêm interaction target rõ.
- OS reduced-motion OR calm setting dừng ambient. Trong P04 có pause sinh hoạt riêng,
  không tắt chức năng mở bảng/học. Thuyền có thể chuyển bến tức thì khi reduced motion.

## Mở rộng world mà không làm mất phần học

Prototype đi từ làng tới atlas/đảo concept rồi mở lại P03 bằng cùng iframe instance
(same-origin). Đây chỉ là cách tái dùng HTML review, **không phải kiến trúc Flutter**.
Route khỏi lesson gửi pause, nên scheduler không giảng tiếp sau một iframe bị ẩn;
return giữ code, note và ink. postMessage kiểm origin + source và chỉ nhận pause/resume.

Production cần WorldDefinition (map/region IDs, landmarks, portals, docks, camera bounds,
asset references, spawn paths, status/content availability) và WorldSession (location,
Tutor context, route/cancel token). Không hardcode một màn làng vào từng lesson.
Travel phải có cancel/skip và một điểm commit arrival, không ghi reward hay tiến trình
học vì tới một island. Load lỗi thì ở lại bến nguồn, không để trẻ mắc kẹt giữa hai map.

Ưu tiên P04 thời điểm soạn là board. Thứ tự hiện hành theo ROADMAP §17: hoàn tất
011 trong scope, đưa UI world vào app theo R1; không mở thêm voice/model trước đó.
World phục vụ nhiều nhánh chơi/sở hữu/giao lưu, không chỉ làm nền cho bài học.

## Thẩm mỹ và nguồn bên ngoài

Được chủ động chọn/gia công yếu tố đẹp, nhưng không ghép bừa asset khác camera, tỷ lệ,
đường nét hoặc không rõ quyền. Dùng nguồn có license/provenance, lưu source URL/license
và bản biến đổi nếu nhập asset bên ngoài; không giả asset tìm được là tự làm/CC0.
Lượt P04 dùng cảnh quần đảo AI-generated mới, tham chiếu chính village P02; kids/boat
là SVG authored, không tải stock hay sao chép hình game thương mại. Metadata trong manifest.
Tương lai ưu tiên một bộ walk-cycle/expression nhất quán hơn việc thêm nhiều ảnh rời.

## Bằng chứng và giới hạn

Mẫu: `living-world-prototype/README.md`; cảnh mới1264×848, WebP127,302B. Tests xác nhận
biến thể lời thoại, đường đi, NPC vào/ra nhà, cancel/arrival, motion, chuyển sang bảng,
retention và phone layouts. Không suy từ đó ra AI/voice, device performance, TalkBack,
font2.0, nội thất hay game hai đảo mới đã hoàn thiện. Art mới vẫn là exploration.

## Yêu cầu xuyên suốt: ngôn ngữ

PyQuest phải đa ngôn ngữ, mặc định theo hệ thống và cho đổi/lưu trong Cài đặt.
Áp dụng cho UI, lời Tutor, bài học và bảng giảng; không dịch code, dữ liệu trẻ nhập
hoặc expected output. Đổi locale không mất bài/nét/tiến trình và không phát lại
voice/reply locale cũ. Xem [LANGUAGE_AND_LOCALIZATION.md](LANGUAGE_AND_LOCALIZATION.md)
cho fallback, VI/EN ban đầu, kiến trúc mở rộng và nghiệm thu toàn app. P03/P04 đã có
mẫu tương tác; đây chưa phải bằng chứng Flutter/AI/voice đã đa ngôn ngữ.
