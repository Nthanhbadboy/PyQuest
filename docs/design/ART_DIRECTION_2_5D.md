# PyQuest — Chuẩn hình ảnh 2,5D toàn sản phẩm

**Revision1 · 2026-10-18 · bắt buộc theo chỉ đạo user.** Đây là chuẩn thiết kế, không
phải xác nhận artwork đã được duyệt hay app đã đổi UI. Thay các diễn giải cũ cho
phép “trang thẻ phẳng + một hình 2,5D” được coi là hoàn tất redesign.

## 1. Phạm vi và thứ tự nguồn

Áp dụng **mọi màn**: onboarding, làng, nhà/sân/nội thất, dự án/túi/sổ, hải đồ, visit,
pet/shop, Tutor/lesson, mini-games, Creator, Arena, thành tích/kết quả, Settings.
Không chọn mỗi màn một phong cách tùy ảnh tham khảo. Product Vision giữ mục tiêu;
Game Design giữ luật; Technical Architecture giữ nguồn dữ liệu và constraints;
Roadmap giữ thứ tự. Tài liệu này chốt hình ảnh, WORLD_EXPANSION_REDESIGN chốt W01–W14.

21 ảnh nguồn là tham khảo, **không phải21 style được phép trộn**. Không nhập pixel-art,
nhân vật/logo thương mại, gacha hoặc biểu tượng gây hiểu nhầm chỉ vì có trong nguồn.
P02–P06C trước r33 giữ giá trị flow/prototype; không phải bộ final art cùng chuẩn.

## 2. Định nghĩa 2,5D phải nhìn thấy được

- Thế giới/đồ vật/nhân vật có thể tích, mặt trên/mặt bên phù hợp camera, bóng tiếp
  xúc với đất và vật liệu có khối; trước–giữa–sau và che khuất đọc được.
- Scene là nơi thao tác chính, không chỉ ảnh hero trên một trang web dài.
- Không coi drop-shadow của card, gradient của button hoặc ảnh isometric trong
  dashboard là bằng chứng cả màn đã đạt 2,5D.
- Cùng vật phải có silhouette, tỷ lệ, chất liệu, ánh sáng nhất quán từ ngoài nhà
  vào trong, từ làng sang atlas. Cùng họ mỹ thuật không bắt mọi khu cùng một màu.
- 2,5D là mục tiêu biểu đạt, **không bắt đổi engine sang realtime3D**, không tự mở deps.

**Lớp đọc/thao tác:** text, code, output, bảng số, control và semantics nằm front-facing
trên HUD/bảng trong scene; không nghiêng code theo phối cảnh hoặc làm chữ nổi khó đọc.
Màn Settings hay journal vẫn thuộc cùng bộ khung/vật liệu/character, không cần nhồi
một cảnh làng sau từng ô nhập. Đây là quy tắc khả dụng, không miễn yêu cầu mỹ thuật.

## 3. Khóa phong cách chung

| Thành phần | Chuẩn |
|---|---|
| Camera world/home | Hình chiếu trực giao3/4; target yaw45°/elevation30°. Concept AI chỉ xấp xỉ; geometry/anchor phải đo trước runtime |
| Nội thất | Cắt mái/tường phía camera; cửa, đồ và actor cùng trục với ngoại thất; không chuyển sang hình SVG phẳng sơ sài |
| Hải đồ | Cùng camera/vật liệu, giảm chi tiết theo tỷ lệ; nhiều đảo trong một biển liên tục, không các thumbnail rời |
| Mini-game | Giữ camera phục vụ luật: side-view cho nhảy, board rõ ô cho Maze; có chiều sâu lớp/khối/ánh sáng cùng họ, không pixel-art chen vào |
| Ánh sáng | Key ấm trên trái, bóng mềm dưới phải; ambient mát. Không mỗi asset tự có một hướng nắng |
| Vật liệu | Đá sáng cạnh bo, gỗ có thớ tiết chế, mái ngói teal/đất nung, cỏ có khối, biển xanh; tránh nhựa bóng toàn cảnh |
| Màu | Biển #35AFC0; cây #5B9B60; đá #E8D9B8; gỗ #986340; teal #286D73; amber #E7AD45; coral #CE7763; ink #183C46. Đây là palette art, không tự đảm bảo contrast chữ |
| Nhân vật | Dễ thương dưới12 nhưng không preschool; mắt/biểu cảm rõ, chân có điểm đặt đất, cùng tỷ lệ cửa/đồ. Dùng CastRegistry identity, không biến mọi Tutor thành Robo |
| Tỷ lệ scene | Cửa đủ cho actor đi qua, đồ có footprint. Không dùng nhân vật khổng lồ bên nhà đồ chơi nếu không chủ ý là UI portrait |
| UI | Khung gỗ/đá/giấy có độ dày tiết chế, 1CTA chính, text contrast kiểm riêng; không phủ beige/sage nhạt toàn màn |

Font hiện có là nguồn để kiểm bố cục, không thêm font/dependency vào app trong gói art.
Màu và shadow của artwork không thay semantic states hoặc hit target >=48logicalpx.

## 4. Art brief gắn với các phần mở rộng

| Màn/nhóm | Hình ảnh bắt buộc phải thể hiện | Không được thay thế bằng |
|---|---|---|
| W01 làng | Scene công cộng liên tục, đủ điểm đến thật, đường về nhà và bến phân biệt, một gợi ý tiếp tục | Sáu ảnh công trình trên sáu card hoặc hàng nút Sắp ra mắt |
| W02/W03 nhà/dự án | Nhà và sân có lối đi; preview phần phòng mở thêm; badge giữ và cost dùng ở hai nhóm, không bake giá vào art | Một ảnh nhà gắn thanh XP hoặc nút mua để mở mọi thứ |
| W07 nội thất | Cắt mái, bàn hoạt động, vật đặt có khối; thấy được ích lợi của phòng và đường rời | Profile/kệ tranh, illustration không có điểm tương tác |
| W08 hải đồ | Public island, personal space và content pack phân loại bằng UI; bến nguồn/đích, route rõ | Ba đảo đổi màu không có vai trò; khóa tiền trên tất cả đảo |
| W09 visit | Cảnh nhà có khu khách được vào và hành động chung; chủ vắng/cùng phiên có nhãn | Đổi title profile thành “đến nhà” hoặc NPC giả người online |
| W10 pet/shop | Pet có thân/pose/đồ chơi, khu chơi thật; capability/purchase states trên panel | Chỉ avatar+chat, lời hứa model chạy mọi máy hoặc pet nài mua |
| W11 Arena | Sàn luyện tập/đấu, nơi đọc luật, khu đội/sản phẩm; loại trận và nguồn kết quả rõ | Dashboard leaderboard giả hoặc quiz Python đổi màu |
| W12 Creator/quà | Workbench và tác phẩm có trạng thái tạo/thử/lưu/chia sẻ; quyền/phiên bản rõ | Gallery ảnh không có hành động sáng tạo |
| W13 Tutor | Không gian học cùng Tutor, bảng/code/output dễ đọc, nhân vật có khối và cử chỉ hướng dẫn | Một ảnh avatar nhỏ trong trang web chứa editor và card |
| W14/result | Nhà Thành Tích có tủ/bục/đồ trưng bày trong không gian; earned khác locked; result gắn hoạt động | Chỉ ba card huy hiệu phẳng hoặc mọi người đều vô địch |
| Settings/journal | Cùng bộ khung có độ dày/vật liệu, đọc rõ khi dài/scale lớn; thông tin và lỗi thật | Form website khác style hoặc dùng perspective lên văn bản |

Số vật liệu/quyền/multiplayer/AI/commerce trong concept phải ghi minh họa, không
biến ảnh thành luật thật. Scene art không chứa text/giá/code quan trọng nếu dự kiến
làm asset production; chữ trong mockup chỉ là composition reference, phải tách sau.

## 5. Bàn giao theo ba mức, không gọi lẫn nhau

1. **Concept scene:** ảnh chọn hướng, có nguồn/prompt/references; chưa đủ pixel/
   alpha/occlusion/navigation hoặc trạng thái. Chọn ảnh không nghĩa duyệt runtime.
2. **Screen design:** composition trên360×640 và390×844, VI/EN, loading/error/locked/
   pending theo màn; controls không che scene, text/keyboard/scale2 vẫn đọc. Có
   trường dữ liệu và source mapping. Không dùng ảnh mờ/phóng to làm proof touch.
3. **Runtime art pack:** terrain/prop/actor/shadow/occluder tách lớp; export alpha
   đúng, dimensions/pivot/footprint/hit bounds/atlas metadata + provenance; route
   và quyền thực sự nối source. Cần work order runtime riêng, không tự copy vào app.

Ảnh AI nếu còn lỗi cửa/cầu/bóng/tay hoặc khác camera phải sửa rồi review; không bỏ
qua vì “chỉ là concept”. Không tự gọi ảnh sinh có layer, model3D hay sprite animation.
Không vẽ lại vài polygon/SVG phẳng để thay nhiệm vụ làm artwork2,5D chất lượng.
SVG vẫn dùng được cho sơ đồ/callout/icon, không phải lối né quality gate cảnh/nhân vật.

## 6. Chia việc r33

- **DESIGN:** ba concept neo phong cách: W01 làng; W02/W03 nhà–sân/dự án mở rộng;
  W08 hải đồ. Chốt palette/camera/material, nối docs và review cả hai phần.
- **CODE qua PQC-017 (design-only):** W13 phòng học/Tutor; W14 Nhà Thành Tích;
  W11 Arena luyện tập. Mỗi màn là một ảnh riêng có bố cục phone và state overlay
  theo work order. Không làm app/CI/dependency hoặc tự nhận011 accepted.
- **Đợt sau:** visit/pet/shop, nội thất edit, Creator/quà, arcade/result và shared
  panels còn lại. Chưa vẽ đủ thì đánh dấu missing, không dùng ba concept đại diện
  để tuyên bố toàn app đã đồng bộ hình ảnh.

### Cập nhật r34 · 2026-10-18

[art-refresh-r34](art-refresh-r34/README.md) bổ sung10concept DESIGN cho nội thất,
dự án, visit, pet/shop, Creator/quà, Maze/Dragon và result; có42state HTML và kiểm
phone VI/EN. Đây là concept/screen study, chưa production pack; geometry cửa/nền,
character consistency và scene states còn gap ghi trong manifest. Không thay W01
làm neo style bằng cách lấy trung bình mọi sai khác của các ảnh mới.
Journal/Settings/Welcome chưa có ảnh mới vì tool limit10ảnh/lượt. CatchStars/
BugHunter, friends list và editor sâu vẫn thiếu.017 củaCODE chưa được nhận trong
reviewr34. Các checklist dưới đây vẫn chưa đạt toàn bộ; R1 không tự mở.

### Cập nhật r35 · 2026-10-18 — nguồn ảnh chung

[art-sync-r35](art-sync-r35/README.md) nhập3conceptCODE017 vào13conceptDESIGN, thành
catalog16ảnhactive. W14dùngcorrection3/4/empty mới; original giữnguyên. W13/W11giữ
concept, cả3layoutđã sửaoverflow2×, W13ẩndebugID, W14thêmemptythật. Đây không phải
productionapproval cho16ảnh: geometry/character/materialgaps vẫn trongSTYLE_SYNC.
W01vẫnneo chính. **CODE phải xem đủ16ảnh +layouts** trước018, khôngchỉthumbnail.
018giao9ảnh cònthiếu theoA5+B4; không tựmởruntime hoặc ghiđèmaster.

## 7. Quality gate trước R1 UI

- [ ] Ba concept DESIGN và ba concept CODE cùng họ2,5D; không mang nhân vật/logo lạ.
- [ ] Có màn làng, nhà và nội thất để so camera/tỷ lệ/ánh sáng, không chỉ ngoại thất.
- [ ] Concept đã xem ở kích thước lớn; screen composition đã xem trên phone hai size.
- [ ] Luật/state/data đúng bốn tài liệu; không ảnh đẹp đổi đáp án/economy/quyền.
- [ ] Bản nào còn thiếu visit/pet/arcade phải ghi rõ; không claim toàn app hoàn tất.
- [ ] Asset được nhận ở đúng mức1/2/3; R1 có allowlist/source/navigation/evidence riêng.

Đây là checklist chưa được đánh dấu pass chỉ bằng việc publish tài liệu này.
