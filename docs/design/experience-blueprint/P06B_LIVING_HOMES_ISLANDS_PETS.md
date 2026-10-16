# P06B — Nhà có đời sống, đất có thể mở rộng, đảo có thể đón bạn

2026-10-16 · Bổ sung theo định hướng của chủ sản phẩm sau P06 `62627d5`.
**Thiết kế/tầm nhìn; chưa có prototype P06B, multiplayer hay local AI chạy thật.**

**Cập nhật bước nhỏ tiếp theo:** [P06C](P06C_LINKED_JOURNEYS.md) đã có màn chính,
hai mini-game và chuỗi huy chương/vật liệu → mở phòng. Đây chưa phải prototype
đi lại/sắp đồ/thăm nhà đồng bộ hoặc mua thú/AI local của P06B.

## 1. Điều cần sửa trong cách hiểu P06

P06 không thể chỉ là một trang hồ sơ đẹp có tác phẩm và thiệp. Người chơi cần **một
nơi thuộc về mình**, có thể thay đổi, mở rộng, nuôi thú và đón bạn đến cùng làm gì đó.

Bưu điện Mây hiện tại là **lớp giao lưu A**: lời mời, tác phẩm, kỷ niệm và quà tự làm.
Lớp **B — không gian sống và thăm nhà** là một trụ cột bổ sung, không phải wallpaper
cho profile. Bản prototype A không được trình bày như bằng chứng B đã hoàn thành.

> Ví dụ trải nghiệm đích: Mây vừa nối thêm một hiên gỗ ra khu vườn. Bo nhận lời mời,
> đến bến nhỏ rồi đi vào sân. Mèo của Mây chạy đến chào. Mây dẫn Bo lên gác xem mô
> hình mê cung, hai bạn thử một đường đi; sau đó cùng đặt một chiếc đèn ở khu vực
> Mây cho phép. Bo để lại thiệp trên bàn rồi ra về. Lần sau, Mây mở thêm bến thuyền
> và một đảo vườn — một nơi chơi mới, không chỉ thêm ô chứa đồ.

Đây là **kịch bản sản phẩm đề xuất**, không phải mô tả tính năng đã chạy.

## 2. Ba quy mô mở rộng, ba loại niềm vui

| Quy mô | Trẻ thay đổi điều gì? | Điều mở rộng thêm cho gameplay |
|---|---|---|
| **Nhà** | Sắp đồ, đổi phong cách; thêm hiên, phòng, gác, phòng trưng bày hoặc chỗ ở của thú | Một bàn sáng tạo, góc thử đồ chơi, nơi trưng bày có thể đi quanh; không chỉ số lượng slot |
| **Đất** | Mở mảnh đất liền kề; thêm vườn, hồ, đường đi, sân chơi, cầu và bến | Thú có nơi chơi, khách có tuyến khám phá, khu cùng xây được cấp quyền riêng |
| **Đảo** | Mở khu đảo mới và tuyến thuyền/cầu giữa các khu | Chủ đề, hoạt động và bộ sưu tập mới; có lý do dẫn bạn đi tham quan lần nữa |

Các bước minh họa: **căn nhà nhỏ → thêm hiên/phòng → mở sân/vườn → nối bến → đảo nhánh**.
Đây không phải hệ cấp độ XP toàn cục. Trẻ có thể thích chăm một căn nhà nhỏ hơn là
mở thật nhiều đất; nhà lớn không đồng nghĩa giỏi hơn hoặc đáng được kết bạn hơn.

### Tách nghĩa các địa điểm

- **Main Map:** hub công cộng để tìm hoạt động; vẫn miễn phí, không bị biến thành đất tư của người chơi.
- **Nhà riêng/khu đất cá nhân:** hoạt động sở hữu, trang trí và giao lưu, có owner/quyền khách rõ.
- **Nhà Thành Tích:** nơi trưng bày thành tích có nguồn; chủ nhà có thể đặt bản trưng bày được phép trong nhà riêng, không tự tạo ownership bằng cách đặt đồ.
- **Side Maps:** gói nội dung mở rộng đã có trong vision. Đảo riêng không tự động là một Side Map trả phí; hai loại cần ID, nội dung và entitlement riêng.

### Một lần mở rộng phải có ý nghĩa

Luồng đề xuất: **xem trước phần mới → xem điều kiện/chi phí cụ thể → xác nhận → nhận
kết quả có thẩm quyền → sắp xếp khu mới → chọn có mời bạn hay không**.

Giữ nguyên đồ cũ, có kiểm tra lối đi và vị trí hợp lệ, không khóa nhân vật/thú trong
phòng sau khi đặt đồ. Preview không tiêu tài nguyên. Lỗi hoặc xác nhận bị lặp không
trừ tiền hai lần. Chính sách tháo/dời/hoàn lại cần chốt trước khi triển khai.

**Chưa chốt** diện tích, số phòng, vật liệu, giá, loại tiền, điều kiện mở hoặc lịch phát
hành. Có thể phối hợp tiến trình hoạt động và mua nội dung/trang trí tùy chọn; không
mặc định mọi mở rộng đều trả tiền, không bán đường vào kiến thức cốt lõi.

## 3. Thăm nhà là một hoạt động chung

### Hai chế độ thật, không đánh tráo

1. **Tham quan khi chủ vắng:** đi trong phiên bản nhà đã được chủ chia sẻ; thử các đồ
   vật/tác phẩm cho phép. Ghi rõ chủ không hiện diện. Pet chạy hành vi được cấp phép,
   không giả giọng chủ hoặc hứa hẹn thay chủ. Thay đổi lưu lại phải có quyền và receipt.
2. **Ghé chơi cùng chủ:** lời mời được chấp nhận → vào cùng một phiên → thấy avatar,
   vị trí và hành động được đồng bộ → cùng hoạt động. Online/presence phải đến từ
   session thật, không từ timer hay NPC được dán nhãn người chơi.

Tham quan không bắt buộc chat mở/voice. Có thể cùng thử mê cung, ngồi bàn làm thiệp,
chơi ném bóng với thú hoặc sắp đồ trong một vùng được cấp quyền. Một vị khách cần có
**việc để làm**, không chỉ nút “thích nhà”.

### Quyền tối thiểu đề xuất

| Vai trò | Được làm | Không mặc định được làm |
|---|---|---|
| Khách tham quan | Đi trong khu mở, xem/thử đồ cho phép, tương tác thú qua hành động an toàn | Xem phòng riêng, lấy đồ, mua hàng, mở đất, sửa nhà hoặc đọc ký ức thú |
| Bạn được mời cùng chơi | Thêm quyền tham gia hoạt động cụ thể trong phiên | Toàn quyền edit chỉ vì đã là bạn |
| Người cùng trang trí | Đặt/dời vật cho phép trong **vùng và thời hạn được cấp** | Đụng tiền/kho đồ riêng, phá công trình hoặc sửa toàn đảo |
| Chủ nhà | Chọn khu mở, cấp/thu hồi quyền, đóng phiên, lưu bố cục hợp lệ | Tự cấp thưởng thi đấu, bỏ qua kiểm duyệt hoặc bảo vệ trẻ em |

Private room không được tải nội dung về máy khách rồi chỉ phủ màn tối. Nếu quyền bị
thu hồi khi đang thăm, dừng hành động và đưa khách về bến an toàn; không để mắc kẹt
hoặc tiếp tục sửa từ màn đang mở. Có đường rời nhà/chặn/báo cáo luôn dễ tìm.

### Những trạng thái cần thiết kế cùng happy path

- Chủ vắng / phiên đủ khách / lời mời hết hạn / khách từ chối.
- Đang vào nhà / mạng gián đoạn / reconnect đúng phiên hoặc rời an toàn.
- Chủ đổi bố cục trong lúc có khách; xung đột thao tác đặt cùng một vật.
- Đang preview mở đất nhưng chưa xác nhận, tài nguyên không đủ, giao dịch pending/lỗi.
- Khu bị đóng, tác phẩm bị giữ để kiểm tra, khách bị chặn giữa phiên.
- Mời người khác tới không tự chuyển nhà từ private sang public.

Không invent số khách, timeout, quota hay luật edit conflict trước khi có thiết kế
session/authority. Dùng server authoritative cho quyền, tài nguyên và trạng thái chia
sẻ; client prediction chỉ phục vụ cảm giác điều khiển, không quyết định ownership.

## 4. Thú cưng thông minh là cư dân, không phải nút chat gắn con mèo

### Ba ý tưởng thú mẫu — tên và vai trò còn đề xuất

| Thú | Hành vi nhìn thấy | Nối với chơi/sáng tạo |
|---|---|---|
| **Mèo vườn** | Thích nằm nắng, chọn góc nghỉ, nhận ra trò chơi vừa được chọn | Chơi tìm đồ theo gợi ý, giúp trẻ thử quy tắc phản ứng |
| **Cáo đưa thư** | Mang một lá thư **đã được hệ thống xác nhận**, chạy ra bến chào khách | Dẫn tới bàn thiệp, chuyển thông báo được phép, không tự gửi dữ liệu |
| **Rái cá thợ xây** | Thử đường đi qua cầu, mang đạo cụ, phản ứng khi đường bị chắn | Chơi kiểm tra lối đi; trẻ có thể tự tạo hành vi khi muốn |

Mỗi thú có animation, sở thích trong game, góc riêng và các trò chơi nhỏ. Không cần
LLM để thở, đi, ngủ, chạy theo bóng hay né vật cản. Không biến pet thành đồng hồ
trừng phạt: nghỉ vài ngày không khiến thú chết, mất thiện cảm hoặc đòi mua đồ cứu.

Pet không nói mình là người thật/có nhu cầu được trẻ bảo vệ, không giữ bí mật với
người lớn, không đóng vai người bạn duy nhất. Lời nhắc mua không đi qua giọng nài nỉ
của thú; xem shop là hành động chủ động riêng của người chơi.

### Mua thú cưng phải được giữ trong sản phẩm

**Có chức năng mua thú cưng thông minh**, không đổi yêu cầu này thành chỉ xem thú
trang trí. Cửa hàng cần cho xem ngoại hình, tính cách, hoạt động, nội dung đi kèm,
khả năng AI trên máy và điều kiện sử dụng **trước khi xác nhận**.

- Giữ đường chơi thú cơ bản/phần nội dung miễn phí đã có trong vision.
- Thú mua được là lựa chọn sở hữu/nội dung bổ sung; không mua điểm/rank hoặc bảo đảm chiến thắng.
- Không gacha hoặc “sắp mất chú thú này” gây áp lực. Giá/tiền tệ/kiểm soát phụ huynh,
  xác nhận/khôi phục giao dịch/hoàn tiền và thay đổi entitlement phải chốt riêng.
- Thiết bị không hỗ trợ model không được nhận lời hứa AI đầy đủ rồi mới biết sau mua.
  Cần thể hiện chức năng nền còn dùng được và phần nào chưa hỗ trợ; có chính sách hỗ trợ phù hợp.
- Nếu model bị gỡ, thú vẫn thuộc người chơi theo entitlement hợp lệ và còn hành vi nền.
  Không buộc mua lại thú chỉ để khôi phục gói model.

## 5. Tận dụng AI local theo ba tầng

| Tầng | Vai trò | Lưu ý trung thực |
|---|---|---|
| **Hành vi nền** | State machine/behavior tree, pathfinding, animation, chơi theo luật | Chạy không cần mô hình sinh; không gọi thoại soạn sẵn là AI sinh |
| **Hiểu ý định/gợi ý cục bộ** | Ánh xạ hành động, chọn phản ứng theo tình huống; có thể dùng mô hình nhỏ khi đã benchmark | Heuristic/rule engine cũng là phương án; chưa khẳng định model cụ thể hoặc mọi máy chạy được |
| **Ngôn ngữ/tính cách on-device** | Lời phản ứng ngắn, gợi ý chơi, diễn đạt theo tính cách từ dữ liệu game được phép | Gói model tùy khả năng máy, có giới hạn nội dung/độ trễ/bộ nhớ, luôn có fallback |

Nguyên tắc: **AI đề xuất, engine kiểm tra và thực thi.** Model chỉ trả ý định theo
schema giới hạn, ví dụ `greet`, `follow`, `play_ball`, `rest`, `suggest_activity`.
Không dùng văn bản sinh làm code, URL, quyền mở cửa, quyền truy cập dữ liệu, giao dịch
mua thú/mở đất, hoặc kết quả thi đấu.

### Kiến trúc hướng tới, chưa triển khai

- Một runtime/model có thể dùng chung, personality/config nhỏ theo từng thú; không nạp một LLM riêng cho mỗi con.
- Animation và di chuyển không đợi model. Inference theo sự kiện có scheduler, timeout/cancel; không gọi LLM mỗi frame.
- Pet ở nhà có khách dùng một nguồn quyết định session hợp lệ, broadcast hành động đã validate; không để mỗi máy tự suy ra trạng thái shared world khác nhau.
- Model không có quyền truy cập dữ liệu của khách. Tên nhà, thiệp và tác phẩm của khách là dữ liệu không đáng tin, không phải chỉ thị hệ thống.
- Ký ức đề xuất chỉ là dữ liệu game có giới hạn: trò chơi ưa thích, chỗ nghỉ, cấu hình tính cách do người chơi chọn. Không xây hồ sơ đời tư, không lưu mọi hội thoại mặc định; có xem/xóa/reset.
- Local AI không đồng nghĩa toàn app offline: ghé thăm chung/receipt/quyền vẫn cần dịch vụ đồng bộ. Không gửi prompt lên cloud âm thầm khi local lỗi.
- Tải model là bước riêng, nói rõ dung lượng khi biết; xác minh nguồn/license/integrity, hỗ trợ hủy/xóa và quản lý cập nhật.
- VI/EN phải có bộ kiểm riêng; không mặc định model giỏi tiếng Anh sẽ dùng tốt với trẻ nói tiếng Việt. Không âm thầm dịch tên riêng hay chương trình của trẻ.
- Pet tham gia Arena cần luật thực thi tái lập/giới hạn công bằng; không lấy model đắt hơn hoặc máy mạnh hơn làm lợi thế mua được.

### Gate nghiên cứu bắt buộc trước lời hứa kỹ thuật

Benchmark máy Android mục tiêu: RAM/peak memory, dung lượng tải/cài, cold start,
first response và latency phân vị, nhiệt/pin trong phiên chơi, gián đoạn background,
chất lượng/an toàn VI/EN, chế độ offline và fallback. Phải kiểm **cùng render game**,
không chỉ chạy prompt trên desktop trống. Chưa chọn model, runtime, con số hiệu năng
hoặc cam kết “AI local chạy mọi máy” trong gói này.

## 6. Hành trình mẫu tiếp theo nên làm

Đề xuất **P06B**, không đổi task runtime đang được phép:

1. Một căn nhà 2.5D có sân, phòng và pet: trẻ tự đi vào/chạm đồ; có điều khiển thay thế không cần kéo.
2. Xem trước một hiên hoặc ô đất mới; hủy không mất gì, xác nhận mẫu có state rõ.
3. Sắp một vật, kiểm tra không chắn cửa; pet đi tới/chơi với vật theo hành vi nền.
4. Hai vai chủ/khách trong **simulation được ghi nhãn** để chốt quyền và hoạt động cùng chơi.
5. Sơ đồ chuyển sân → bến → đảo; map mới là nhánh nội dung, không chỉ nền khác màu.
6. Màn xem/mua thú theo entitlement mẫu và bảng khả năng thiết bị; chưa tạo thanh toán hoặc inference thật.

Sau khi thiết kế được duyệt, **multiplayer thăm nhà thật** và **local inference thật**
phải có work order, benchmark và evidence độc lập. Đổi tên NPC thành “bạn online”
hoặc phát thoại scripted không đáp ứng yêu cầu của chủ sản phẩm.

## 7. Quyết định đã ghi nhận và phần còn mở

**Đã ghi nhận:** nhà/đất/đảo có thể mở rộng; thăm nhà là tương tác thực chất; mua thú
cưng thông minh là một nhánh sản phẩm; local AI là hướng cần nghiên cứu; bản P06 A
chưa đủ để coi đã thiết kế hết trải nghiệm này.

**Còn mở:** điều kiện/giá/tiền tệ mở rộng và mua thú; số khách, co-edit scope và hosting;
đời máy thấp nhất; model/runtime/license; chính sách memory; quyền trẻ/phụ huynh theo
thị trường; mức AI có trong từng sản phẩm. Không chốt ngầm các điểm này bằng một mockup.
