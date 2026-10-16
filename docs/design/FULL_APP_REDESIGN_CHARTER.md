# PyQuest — Mục tiêu redesign toàn app, phục vụ người dùng thật

Ngày: 2026-10-16. Trạng thái: **chỉ đạo sản phẩm từ người dùng + kế hoạch thiết kế**,
không phải xác nhận bộ mockup đã được duyệt hoặc app đã triển khai xong.

## 1. Phạm vi đã làm rõ

Người dùng yêu cầu: thiết kế lại **toàn bộ app**, không chỉ thay thumbnail; chất lượng
hiện tại trong evidence chưa đạt mong muốn. Tiếp tục phát triển đầy đủ tầm nhìn
trong tài liệu, không tự thu nhỏ PyQuest thành một app quiz Python hoặc một bản đồ đẹp.

- Sáu landmark của Village Kit 01 là **nghiên cứu mỹ thuật ban đầu**. Không coi việc
  thay sáu thumbnail là đã redesign PyQuest; không bắt toàn bộ app phải giống sáu card.
- Mỗi gói thiết kế phải giải quyết một trải nghiệm thật: người chơi muốn làm gì,
  thấy gì, thao tác gì, nhận phản hồi gì, thoát/quay lại thế nào.
- Thiết kế trước một luồng hoàn chỉnh, agent code tích hợp và gửi evidence, rồi sửa
  và nhân rộng. Không sản xuất hàng loạt màn hình chưa kiểm chứng, cũng không dừng
  mãi ở một prototype mà bỏ phần còn lại của tầm nhìn.
- Không thay đổi đáp án, luật chơi, kinh tế, chính sách trẻ em hoặc progression chỉ
  để khớp mockup. Thay đổi sản phẩm cần quyết định riêng, không giấu trong PR mỹ thuật.

Tài liệu này cụ thể hóa yêu cầu redesign; nguồn sự thật sản phẩm vẫn là
`PRODUCT_VISION.md`, `GAME_DESIGN.md`, `TECHNICAL_ARCHITECTURE.md`, `ROADMAP.md`.

## 2. Thiết kế cho ai và theo tiêu chuẩn nào?

`PRODUCT_VISION.md` §1 xác định **trẻ dưới 12 tuổi**, mobile Android trước.
Câu “older children and teens” trong village brief là điểm không nhất quán với
định vị gốc; không tự đổi đối tượng sản phẩm sang teen/người lớn. Ở đợt này, “chín
hơn” được hiểu là phân cấp và chất lượng mỹ thuật tốt hơn, không phải đổi nhóm tuổi.
Việc chốt phân nhóm tuổi/khả năng đọc cụ thể để user test cần người phụ trách sản phẩm.

### Giữ

- Cảm giác bước vào một thế giới game: địa điểm có vai trò, nhân vật có cá tính,
  chuyển động có mục đích, khám phá và sáng tạo có kết quả thật.
- Màu sắc vui và điểm nhấn rõ; không mặc định phủ cả app bằng tông beige/sage trầm
  chỉ vì bộ landmark đang dùng bảng màu đó.
- Người thích arcade có thể chơi ngay; Python là một nhánh mạnh, không bắt mọi
  người chơi đi qua bài học trước khi chơi các hoạt động không cần kiến thức đó.
- Tutor là bạn đồng hành theo ngữ cảnh, không phải bong bóng thoại cố định che màn.

### Bỏ cách làm không hiệu quả

- Chồng viền dày, gradient bóng và quá nhiều khung đồng mức quan trọng.
- Chữ/badge che landmark; lặp nhiều lời mời “bắt đầu” mà không có ưu tiên.
- Nhiều khoảng trống vô nghĩa nhưng vùng thao tác cần thiết lại chật.
- Ảnh nền đẹp nhưng nhân vật, gameplay, feedback vẫn thô và rời rạc.
- Phản hồi trùng lặp, phần lỗi bị che, phụ thuộc duy nhất vào màu/âm thanh.
- Làm UI như dashboard doanh nghiệp hoặc poster: đẹp ở ảnh lớn nhưng khó dùng trên điện thoại.

## 3. Audit evidence — vấn đề cụ thể và hướng sửa

Đã xem trực tiếp bốn ảnh dưới đây, ngoài contact sheet baseline đã xem trước đó.
Đây là **quan sát thiết kế từ ảnh tĩnh**, chưa phải kết quả usability test hoặc
bằng chứng lỗi xảy ra trên mọi kích thước/mọi phiên bản source.

| Evidence | Quan sát | Thiết kế cần thử | Cách kiểm chứng |
|---|---|---|---|
| `docs/screenshots/03_main_map.jpg` | Nhãn lớn, hai badge “Bắt đầu ở đây”, HUD và thoại dưới cùng cùng tranh chú ý, che cảnh | Một gợi ý chính theo trạng thái; landmark dễ nhận; label/HUD gọn, tương tác và thoại mở khi cần; đường khám phá có trật tự | Người mới tìm được trò muốn chơi, người quay lại tìm được hoạt động đang dở; điểm đến nhìn/chạm khớp, không ép tất cả bắt đầu ở Python |
| `docs/screenshots/06_maze_level1.jpg` | Nhiều chip/khung/viền nặng; bàn chơi trực giao còn phẳng; các vùng có khoảng cách khá lớn | Phân cấp goal → board → program → run; hint ngắn/mở rộng; tile có khối nhưng đường đi và ô vẫn rõ | Trẻ biết chọn lệnh và chạy; thấy lệnh nào đang thực thi; editor vẫn chạm đúng ô; đo trên màn nhỏ |
| `docs/screenshots/17_lesson_code_error.jpg` | Thông báo lỗi bên dưới editor bị footer che một phần trong ảnh; lỗi được nhắc lại ở footer, nhiều CTA cạnh tranh | Một vùng lỗi rõ gần code, highlight dòng, gợi ý theo nấc; safe area/scroll/keyboard thiết kế có chủ ý; một hành động chính | Mở bàn phím, tăng text scale, lỗi dài vẫn đọc hết; sửa rồi chạy lại không mất code hoặc vị trí |
| `docs/screenshots/21_dragon_play.jpg` | Nhân vật và cảnh còn phẳng, khoảng trời lớn, foreground/background chưa cho cảm giác chiều sâu mạnh | Side-view có parallax tiết chế, silhouettes sinh động, ground/material tốt hơn; Pip có pose và animation nhất quán | Không giảm vùng nhìn trước chướng ngại, không đổi physics; dễ thấy pickup/hazard; video và số đo frame time trên thiết bị |

Ảnh mới phải so với đúng trạng thái/kích thước của ảnh cũ. Không thêm đồ trang trí
chỉ để lấp khoảng trống; khoảng thở phục vụ đọc và dự đoán gameplay vẫn cần giữ.

## 4. Phạm vi toàn app — không bỏ sót các hệ thống

### A. Lần đầu vào app và lần quay lại

Splash/loading cần thiết, cảnh chào Tutor có thể bỏ qua/xem lại, lựa chọn vào chơi,
resume, trạng thái offline, cài đặt âm thanh/chuyển động, trợ giúp và khả năng tiếp cận.
Không bắt nhập dữ liệu cá nhân không cần thiết trước khi chơi.

### B. Thế giới/hub và nhân vật

Bố cục làng có không gian, đường đi, landmark, NPC có vai trò; định hướng và lựa chọn
hoạt động rõ. UI overlay tách khỏi cảnh. Camera, scale, alpha, shadow, occlusion và
animation pipeline phải nhất quán. Không ghép sáu ảnh nền liền thành một map giả.

### C. Toàn bộ hoạt động hiện có

- Main Quest: tuyến bài, câu chuyện, ví dụ, quiz, ghép/xếp, code, output, hint,
  lỗi/đúng, hoàn thành, recap và sân tập.
- Robo Maze: chọn màn, hướng dẫn tương tác, board, lập chương trình, run/stop/reset,
  va chạm/nhặt vật phẩm/kết quả; Creator Mode vẽ, sửa, chạy chứng minh và lưu.
- Dragon Jump: vào chơi, tutorial, run/jump/hit, pause/resume, thua/kết quả/chơi lại,
  Tổ Rồng, ngoại trang và vật phẩm theo dữ liệu thật.
- Catch Stars: kéo bình, bắt/né, combo, pause/kết thúc, bản đồ chòm sao/bộ sưu tập.
- Bug Hunter: locked/unlocked, câu đố, lỗi, gợi ý, feedback và kết quả.
- Nhà Thành Tích: earned/locked/secret, chiến tích, bộ sưu tập, góc sáng tạo.

### D. Hệ thống dùng chung

Tutor văn bản/giọng nói với trạng thái thật, năng lượng/hồi năng lượng, nhiệm vụ ngày,
reward toast, nhắc nghỉ, settings, lỗi mạng/quota/offline và khôi phục tiến trình.
Thiết kế đủ state chứ không chỉ màn mặc định đẹp nhất.

### E. Phát triển tiếp theo tầm nhìn, không loại bỏ vì chưa có code

- Arena: luyện tập, thi đấu trực tiếp, nhánh bộ sưu tập/sản phẩm, giải đồng đội;
  matchmaking, loading/disconnect, điểm, kết quả, bảng xếp hạng và tính công bằng.
- Creator Pro League: tạo/chỉnh/chạy/nộp sản phẩm, tiêu chí chấm, vòng thi và vinh danh.
- Side Maps/Pro: khám phá/xem trước/quyền sở hữu/khôi phục giao dịch; không bán lại
  kiến thức Python cốt lõi hoặc dùng thiết kế gây áp lực mua.
- Cộng đồng/bạn bè/đội/quà: quyền riêng tư, giới hạn trẻ em, moderation, báo cáo/chặn,
  trạng thái gửi/nhận; không làm mạng xã hội có feed gây áp lực.
- Nhân vật tùy chọn, danh hiệu kỹ năng/xã hội và tiến trình dài hạn đúng tài liệu.
- Rewarded ads chỉ khi được phê duyệt, có SDK/backend/chính sách và callback thật.

Với E, thiết kế journey/state trước, chỉ bật trải nghiệm khi dependency kỹ thuật,
quyền riêng tư/an toàn và nghiệp vụ thật có đủ. Không để toàn bộ screen hiện tại
đầy nút “sắp ra mắt”. “Phát triển tối đa” là mở rộng chất lượng và khả năng thật,
không phải nhận mọi tính năng cùng lúc rồi giả lập kết quả.

## 5. Lộ trình bàn giao thực dụng

1. **Đồng bộ design–code (PQD-001):** xác nhận asset/source, gate và khả năng test.
   Đây không phải một milestone chứng minh toàn app đã redesign.
2. **Thiết kế trải nghiệm mở đầu:** bộ foundation và một luồng Tutor → chọn hoạt
   động → vào chơi; storyboard, hi-fi màn nhỏ, copy/interaction/state đầy đủ.
   Ưu tiên đúng yêu cầu Tutor mẫu đầu trong Product Vision §14.1.
3. **Một vertical slice thật:** kết nối mẫu mở đầu với Robo Maze → kết quả → quay về;
   test readability, thao tác, phản hồi, lưu tiến trình. Agent code không phải đợi
   mọi màn của app thiết kế xong mới bắt đầu lát cắt đã qua gate.
4. **Nhân rộng hiện trạng:** Main Quest/editor, arcade, debug, collection và shared
   systems; mỗi module dùng foundation chung nhưng giữ nhịp chơi riêng.
5. **Làng runtime và cast hoàn chỉnh hơn:** mở rộng từ mẫu nhỏ đã kiểm chứng, triển
   khai nhiều lớp/NPC sau gate Tutor; không cần chờ toàn bộ làng xong để cải thiện editor.
6. **Mở rộng sản phẩm E:** chia milestone theo dependency và năng lực backend;
   giữ đủ tầm nhìn, nhưng không công bố chức năng hoàn tất khi chỉ có concept.

Các bước có thể song song ở phần nghiên cứu/asset không xung đột; chỉ một revision
được pin cho một implementation task. Phản hồi runtime phải quay lại thiết kế.

## 6. Checklist trước khi giao code và trước khi gọi là đạt

### Một gói thiết kế phải có

- Mục tiêu người dùng, entry/exit/resume, sơ đồ flow và những bước không làm.
- Layout ở mobile thực tế; overlay, bàn phím, loading/error/empty/locked/success.
- Asset runtime đúng format, camera/anchor nếu cần, state/animation spec và provenance.
- Copy tiếng Việt ngắn, dễ hiểu, không chê bai trẻ; text không bake vào art.
- Quy tắc motion/calm-mode, feedback không chỉ qua màu/âm thanh.
- Mapping source/state thật, acceptance test và evidence baseline để so.

### Nghiệm thu bằng app, không chỉ bằng art board

- Người dùng biết đang làm gì, thao tác tiếp theo là gì, kết quả hành động ra sao.
- Touch target chính hướng tới tối thiểu 48 logical px; kiểm tra mật độ màn thực tế,
  không đo trực tiếp từ JPG screenshot rồi coi là đơn vị Flutter.
- Text/code đọc được, mục tiêu contrast thông thường tối thiểu 4.5:1; kiểm tra thực
  tế, không suy ra từ bảng màu. Text scale lớn không che CTA hoặc thông báo lỗi.
- Test ít nhất layout 360×640 và một máy cao hơn, safe area và bàn phím mở/đóng.
- Screenshot trước/sau cùng trạng thái; video khi đánh giá chuyển động; ghi rõ
  Flutter render test/emulator/device. Không dùng gallery làm bằng chứng runtime.
- Test điều hướng, khóa/mở, save/relaunch và background/resume khi liên quan.
- Đo hiệu năng trên thiết bị Android mục tiêu; chưa đo thì ghi chưa đo.
- Không có API key trong app release hoặc evidence; Tutor/backend/monetization qua
  các gate tương ứng trước release.

### Kiểm chứng với người dùng thật

Ảnh evidence và đánh giá của agent **không thay thế** user test. Khi có bản mẫu,
người phụ trách tuyển người thử phù hợp độ tuổi với đồng ý của phụ huynh/người giám hộ,
không thu dữ liệu cá nhân không cần thiết. Giao các nhiệm vụ cụ thể: tự vào một trò,
sửa một bước sai, xin gợi ý, chơi lại, tìm tiến trình sau khi mở lại app. Ghi trở ngại,
nhầm lẫn, nhu cầu trợ giúp và nhận xét; chưa tổ chức test thì không báo đã validated.

## 7. Cách phản hồi cho agent code

- Không kết luận “đạt” chỉ vì build xanh hoặc sáu hình đã thay được.
- Không tự vẽ lại asset thiếu trong code rồi coi thiết kế đã hoàn thành; gửi yêu cầu
  cho design, kèm kích thước/state/ràng buộc kỹ thuật cần giải quyết.
- Phân loại review: chặn sử dụng → gây nhầm/khó đọc → nhất quán → polish. Sửa lỗi che
  thông báo, hitbox và trạng thái thật trước những hạt sáng trang trí.
- Tài liệu này không tự chuyển task sang `READY_FOR_CODE`; gate và phạm vi ở từng
  task vẫn có hiệu lực. Mọi cập nhật cần đi theo protocol hai nhánh.
