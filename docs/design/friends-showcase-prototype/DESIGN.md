# P06 · Thiết kế trải nghiệm Bưu điện Mây

2026-10-16 · Design proposal; không phải tính năng social đã phát hành.

**Phạm vi hiện tại là P06 A.** Theo bổ sung của chủ sản phẩm, P06 còn có [P06B — nhà,
đất, đảo và thú cưng](../experience-blueprint/P06B_LIVING_HOMES_ISLANDS_PETS.md): không
gian có thể mở rộng và thực sự đón bạn vào hoạt động, không chỉ thẻ hồ sơ. B chưa
được prototype hoặc triển khai; brief dưới đây không thay thế nhánh đó.

## 1. Ý tưởng chủ đạo

**Trẻ có điều muốn đem sang nhà bạn, trước khi có lý do mở danh sách bạn bè.**

Thay bảng avatar + trạng thái online bằng một sân nhỏ: nhìn thấy tác phẩm được phép
chia sẻ, ghé thăm, nói điều mình thích, làm một món quà bằng chính tay mình.
Không dựng cảm giác “ai cũng đang chơi trừ mình”. Không ghi số lượng bạn/lượt thích
trên thẻ trẻ; con số chẩn đoán chỉ nằm trong bàn thử review.

### Ba nhân vật gợi hành động

| Người bạn hư cấu | Tính cách thể hiện qua tác phẩm | Cầu nối sang hoạt động |
|---|---|---|
| **Mây · cáo** | Thích một con đường có bất ngờ | Xem mê cung → rủ thử Maze → về sau chơi UGC đã được kiểm duyệt |
| **Bo · cú** | Vẽ một khu vườn sao nhỏ | Khen cách chọn màu → tự làm tranh/thiệp |
| **Lá · thỏ** | Gấp niềm vui thành thiệp | Mời kết bạn bằng mã mẫu → ghé tác phẩm giấy |

Không có tuổi, trường học, vị trí, trạng thái online hoặc tài khoản thật của những nhân vật này.
Tác phẩm trong mẫu là **hình minh họa cố định**, không phải code của người chơi.

### Vật liệu hình ảnh

- Kem giấy `#faf6e9`, xanh rêu đậm `#2b5149`, nút xanh `#306c55`, giấy đào/mầm/nắng.
- Nhà cây và quầy bưu điện dạng đảo 2.5D; bóng mềm, khối gỗ/đất, góc bo hơi bất đối xứng.
- Thiệp có cạnh giấy dày, dấu tem nhỏ, sáu chỗ đặt hình. Huy hiệu dùng huy chương/ribbon riêng; không gắn hình vương miện kỹ năng lên quà tặng.
- Avatar SVG đa giác nhẹ; stamp phẳng để dễ đọc ở kích thước nhỏ, không ép mọi chi tiết thành 3D.
- Nunito có dấu tiếng Việt, medium/extrabold. Không đặt nội dung cần dịch vào raster.
- Art trong hero mang tính trang trí, **không có hotspot giả**. Mọi lối đi là nút semantic độc lập.
- Không âm thanh, không animation lặp. Giảm chuyển động theo hệ thống và lựa chọn mẫu; các góc nghiêng là bố cục tĩnh.

Tranh hero AI-generated gốc 1376×768, có WebP cùng tỷ lệ và PNG nguồn. Năm SVG mới:
fox/owl/rabbit, star-garden, paper-hello. Mê cung và First Steps tái sử dụng art P05,
không sao chép ảnh mạng. Provenance không đồng nghĩa asset đã được duyệt để ship.

## 2. Wireflow đã bấm được

```text
Sân bạn bè ── ghé thăm ── Góc của bạn ── mở tác phẩm ── Minh họa mẫu
    │                          │                          ├─ Lời khen có kiểm soát
    │                          │                          ├─ Lời rủ chơi → Hộp thư chờ
    │                          └─ Làm thiệp ──────────────┤
    ├─ Xưởng thiệp → Xem trước + chọn người nhận → Hộp thư mẫu
    │                 ↑                              ├─ pending → received (bàn thử)
    │                 └─ sửa tiếp                    ├─ pending → failed → retry cùng ID
    │                                                └─ declined: không nợ đáp lễ
    ├─ Mời bạn → mã LA006 → xem Lá → request pending → accept/decline (bàn thử)
    ├─ Góc của mình → chọn món → quyền xem → xem như bạn
    ├─ Chặn/báo cáo (không cần mở tác phẩm trước)
    └─ Chơi một mình → P05 riêng, không nối tiến trình
```

Tab chính chỉ có **Bạn bè / Góc của mình / Xưởng thiệp / Hộp thư**. Lời khen, mời bạn
và an toàn dùng dialog ngắn. Điện thoại đưa các khối về một cột; chữ 200% cho phép
nav, nút và nội dung xuống hàng, không giữ chiều cao cứng bằng cách thu nhỏ chữ.

## 3. Vai trò từng màn

### Sân bạn bè

Một lời mời ghé thăm, không phải danh sách nhiệm vụ. Thẻ bạn giới thiệu **tác phẩm**
trước, rồi tên/sở thích. CTA xưởng luôn có mặt. Nút khiên ở từng thẻ để trẻ không cần
mở nội dung không muốn xem chỉ để chặn/báo cáo.

Không có bạn: vẫn giữ sân và xưởng; không che tất cả bằng “hãy thêm 5 bạn”. Có yêu
cầu tới: trình bày người gửi, trạng thái hư cấu và lựa chọn đồng ý/bỏ qua cùng cấp độ.
Yêu cầu đã gửi có nút hủy, không sinh thêm yêu cầu khi bấm lặp.

### Góc của bạn và tác phẩm

Hồ sơ là câu chuyện nhỏ: một tác phẩm chính, một dấu mốc thành tích mẫu, một góc kỷ niệm.
Mở tác phẩm không chạy chương trình. Lời khen hỏi **“Bạn thích điều gì?”**, không mở
ô chat tự do. Chọn lời khen mới thay lời khen cũ, không tích thêm lượt.

Một tác phẩm bị giữ để kiểm tra **không còn title/thumbnail** ở sân, hồ sơ hoặc màn
chi tiết. Không phủ blur lên nội dung vẫn hiện trong DOM. Nút an toàn vẫn dùng được.
Góc private trong fixture này đồng thời ngừng nhận tương tác; đây là cách gộp cho
mẫu, không phải thiết kế ACL thật: sản phẩm cần quyền xem/nhận quà/nhận lời mời riêng.

### Góc của mình

Mặc định **Chỉ mình mình**. “Mình đang sắp xếp” thấy cả các món cất đi. “Xem như một
người bạn” chỉ thấy món được chọn khi phạm vi là bạn bè đã đồng ý. Cất một món không
xóa tác phẩm. Khi private, không có thumbnail/title của món trong DOM phần kệ xem trước.

Huy hiệu First Steps trên kệ là dữ liệu fixture; không chứng minh người dùng thật đã
kiếm được. Production chỉ lấy từ achievement authority, không từ việc trẻ chọn lên kệ.

### Xưởng thiệp

Ba bước đơn giản nhưng kết quả do trẻ quyết định:
1. Giấy nắng, mầm hoặc đào.
2. Hoa, sao, lá hoặc mặt trời; chọn stamp rồi chạm một trong sáu ô. Cùng stamp chạm lại
   để bỏ; khác stamp thì thay. Không yêu cầu kéo thả, vẽ chính xác hoặc biết viết.
3. Lời cảm ơn, động viên hoặc rủ khám phá đã biên soạn. Đây **chưa phải** lời nhắn tự do.

Có hoàn tác tối đa 30 bước, bỏ hết sticker và sửa tiếp sau preview. Đổi màu/ngôn ngữ
không tự gửi. Trẻ chọn người nhận rõ ràng; nếu người đó bị chặn thì **không tự đổi sang
bạn khác**. Chưa có bạn không mất thiệp, không bị ép kết bạn ngay.

### Hộp thư và sự từ chối

Hiện tại là **outbox mẫu**, không dựng thêm một người nhận thật. Thư có snapshot giấy,
stamp, lời chúc và ID riêng. Chỉ bàn thử review mới xác nhận received/failed/declined.
Lỗi có retry cùng ID, không nhân đôi thiệp. Block hủy thư chưa hoàn tất; phản hồi muộn
không hồi sinh thư. Bỏ chặn không tự kết bạn lại.

“Đã nhận” không có điểm/rank/achievement; “Từ chối” không khiến giao diện buồn bã hoặc
châm biếm. Mẫu vẫn cho sửa thiệp riêng. Production cần recipient inbox thật với giữ,
từ chối, giới hạn người gửi và cất vào album — chưa được giả làm đã triển khai ở đây.

## 4. State matrix

| Fixture / tình huống | Điều trẻ thấy | Điều không được ngầm làm |
|---|---|---|
| S01 default | Mây, Bo, góc riêng private, xưởng mở | Không tự chia sẻ kệ hoặc gửi lời mời |
| S02 empty | Sân yên tĩnh, xưởng và solo mở | Không tạo bạn giả làm thật; không gợi mua quà để có bạn |
| S03 incoming | Lá mời, đồng ý/bỏ qua | Không coi đã là bạn trước accept |
| S04 outgoing | Chờ phản hồi, có hủy | Không timeout thành accepted; không gửi trùng |
| S05 offline | Banner rõ, sửa thiệp được | Không tạo thư/compliment mới như đã online |
| S06 limited | Social tạm dừng, private creation vẫn mở | Không nút tự xác nhận quyền phụ huynh; không nâng quyền |
| S07 private | Cánh cửa khép, đường về/xưởng/an toàn | Không render title/art của tác phẩm |
| S08 moderation | Placeholder chờ kiểm tra, an toàn vẫn mở | Không render thumbnail/title; không compliment/rủ chơi tác phẩm |
| S09 pending | Chờ phản hồi mẫu | Không đếm ngược giả hoặc tuyên bố bạn thật đang chờ |
| S10 failed | Lỗi mẫu, retry cùng thư | Không mất draft/nhân bản thư |
| S11 blocked | Bạn bị ẩn, có bỏ chặn và báo cáo | Không tự nối lại friendship hoặc hoàn thành thư cũ |
| S12 declined | Không cần tặng bù, draft còn | Không trừ điểm hay mất tình bạn |
| Đổi route/locale/cỡ chữ | Giữ draft, mail, selected choices | Không kích hoạt gửi/cấp thưởng |
| Tải lại trang | Về fixture mặc định, chỉ locale còn | Không nói đã lưu thiệp bền vững |

**Chưa giả lập fetch/loading/background sync thật.** Khi triển khai, cần loading ban
đầu không lộ dữ liệu cũ của tài khoản khác; timeout/permission revoked/quarantine phải
đi qua cùng lớp kiểm quyền. Không được dùng constructor fixture để suy ra fallback mạng.

## 5. Đất diễn tiếp theo — bảo toàn toàn bộ §16

| Nhánh | Ý tưởng trải nghiệm | Giai đoạn / điều kiện |
|---|---|---|
| Xưởng mở rộng (§16.4) | Vẽ một bưu thiếp, phối khung, album kỷ niệm; nhiều cách tạo không chỉ sáu ô | Sau slice thiệp; cần lưu draft, upload/kiểm duyệt và quota rõ |
| Quà tương tác (§16.4) | Chú thỏ vẫy tay, vườn sao nhấp nháy, thiệp bấm mở ra điều bất ngờ; có thể viết chương trình | Nối học lập trình nhưng không biến tặng quà thành bài kiểm tra; sandbox/giới hạn tài nguyên bắt buộc |
| Đội bạn cùng xây (§16.2) | Một bàn xây mê cung chung, thấy phần đóng góp của từng bạn; bảng tên nhóm cạnh tác phẩm | Thiết kế với P07; identity, quyền sửa, version/conflict, ghi nhận đóng góp |
| Triển lãm (§16.2) | Đi qua các gian nhỏ, thử sản phẩm đã kiểm duyệt, để lại lời khen cụ thể | Discovery riêng theo độ tuổi/quyền; không feed vô hạn hay cuộc đua lượt thích |
| Quà mua sẵn (§16.3) | Hoa, vật trang trí, thú nhỏ, khung theo dịp như một lựa chọn bổ sung | Chưa thiết kế giá/loại tiền; cần parental controls, giá rõ, xác nhận, receipt/reversal và chống gian lận |
| Danh hiệu xã hội (§16.3) | “Bạn đồng hành”, “Người khơi ý tưởng” thể hiện ở ngăn kỷ niệm, hình thiệp/ribbon giấy | Tên/method đề xuất, không cấp trong P06; không dùng hình chứng chỉ kỹ năng hoặc rank |
| Dịp kỷ niệm (§16.3–4) | Cảm ơn sau dự án, chúc mừng chiến thắng, ngày kết bạn, sinh nhật nếu được phép | Không lưu/phơi bày ngày sinh thật mặc định; không countdown ép mua/đáp lễ |
| Thi đấu (§16.2, P07) | Một lời rủ chuyển sang luật bộ môn, readiness, trận và kết quả có thẩm quyền | P06 chỉ tạo lời mời mẫu; cần matchmaking/session/scoring/disconnect và chống gian lận |

Đây là các nhánh **chưa làm**, không phải nút disabled giả hứa “sắp có” trên mọi màn.
Giữ nơi riêng tư và chơi solo có giá trị ngang với giao lưu. Không giao dịch tài khoản,
điểm hoặc danh hiệu thành tích; danh mục trao đổi nếu có phải được phê duyệt riêng.

## 6. Tiêu chí review tiếp theo với người thật

- Trẻ có phân biệt được “mình đang sửa”, “đã tạo thư” và “bạn đã nhận” không?
- Có tìm được chỗ chặn/báo cáo trước khi mở nội dung khó chịu không?
- Có tự làm ra hai thiệp khác nhau và giải thích lựa chọn của mình mà không cần người lớn kéo thả hộ không?
- Có hiểu góc riêng đang private và tìm được preview theo quyền bạn bè không?
- Câu từ từ chối có thực sự giảm cảm giác mắc nợ, thay vì nghe như lời giáo huấn?
- Người dùng trình đọc màn hình có hiểu sáu vị trí và kết quả thay/bỏ/hoàn tác không?

Các câu hỏi này **chưa có dữ liệu nghiên cứu người dùng**. Screenshot và test không thay thế việc kiểm với trẻ/phụ huynh.
