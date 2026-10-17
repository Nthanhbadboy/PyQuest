# PyQuest — Product Vision

> **Trạng thái đối chiếu r47 · 2026-10-18:** xem [source / evidence / release policy](PROJECT_STATUS.md).
> Tầm nhìn, tiêu chí kế hoạch và source đã có không đồng nghĩa tính năng đã được nghiệm thu.

> **Đồng bộ mở rộng · 2026-10-18:** nhà → đất → đảo, nhiệm vụ liên kết,
> thăm nhà có hoạt động, thú thông minh, bạn bè/Arena đều thuộc thiết kế sản phẩm.
> [Thiết kế thế giới thống nhất](design/WORLD_EXPANSION_REDESIGN.md) nối các màn và
> phân biệt rõ luật đề xuất với source đã chạy. Không coi prototype là tính năng APK.

> Tài liệu này xác định **PyQuest là trò chơi gì**, dành cho ai, bán giấc mơ gì,
> và thế giới bên trong nó vận hành theo triết lý nào.
> Tài liệu **không** đi vào thông số cân bằng (xem `GAME_DESIGN.md`),
> cũng **không** đi vào quyết định kỹ thuật (xem `TECHNICAL_ARCHITECTURE.md`).

---

## 1. Định vị dự án

| Hạng mục | Nội dung |
|---|---|
| **Tên** | PyQuest |
| **Tagline** | Build Your Game. Rule Your World. |
| **Repository** | `PyQuest` (Private) |
| **Đối tượng** | Trẻ dưới 12 tuổi |
| **Nền tảng** | Mobile (Android trước, iOS sau) |
| **Thể loại** | Thế giới game nhiều nhánh hoạt động (phiêu lưu, khám phá, sưu tầm, giải đố, sáng tạo, thi đấu) + nhánh học lập trình Python |

**Định vị cốt lõi:**
PyQuest là **một thế giới game chung gồm nhiều nhánh hoạt động độc lập**. Trẻ chọn
kiểu trải nghiệm mình thích; mỗi nhánh có luật chơi, tiến trình và phần thưởng riêng.
PyQuest **không bán cảm giác "học thêm"**. Điểm mạnh riêng của PyQuest là nhánh
**tự tạo ra trò chơi của chính mình**; Python là công cụ cho nhánh đó — quan trọng,
nhưng **không bắt buộc cho mọi hoạt động**.

**Mục tiêu trải nghiệm:**
Trẻ mở PyQuest vì thích chơi → ở lại vì tò mò → tự hỏi
*"Mình có thể tự làm một game như thế này không?"*
Đó là lúc ứng dụng chuyển từ game giải trí thành công cụ dạy lập trình thực sự.

---

## Ngôn ngữ trải nghiệm

PyQuest phải **đa ngôn ngữ**, mặc định theo ngôn ngữ hệ thống. Người dùng có thể chọn
ngôn ngữ và lưu lựa chọn ở **Cài đặt**, hoặc trở về **Theo hệ thống**. Giao diện,
nội dung bài, lời Tutor và bảng giảng phải nhất quán; không chỉ dịch các nút bấm.
Không dịch âm thầm code/dữ liệu trẻ nhập hoặc đổi đáp án. VI/EN là gói ban đầu trong
mẫu thiết kế; thêm ngôn ngữ qua gói nội dung được review. Chi tiết và giới hạn triển
khai hiện tại: [Language contract](design/LANGUAGE_AND_LOCALIZATION.md).

## Thuật ngữ cốt lõi (dùng thống nhất toàn bộ tài liệu)

Các khái niệm dưới đây **không** được dùng thay thế cho nhau. Khi một tài liệu
khác dùng thuật ngữ này, nghĩa phải đúng như bảng sau.

| Thuật ngữ | Định nghĩa |
|---|---|
| **Home Map** | Khu vực khởi đầu chào đón trẻ: một thế giới có nhân vật, thoại, âm thanh — **không** phải màn hình danh sách bài học. Là điểm vào của mọi luồng chơi. |
| **Main Map** | **Bản đồ trung tâm (hub điều hướng) miễn phí để khám phá, chọn và mở các hoạt động** như Main Quest, mini-game và địa điểm khám phá. Main Map là điểm điều hướng — **không** phải một game lớn tự thân, không phải hệ thống XP/cấp độ, và không bị khóa sau paywall. Thế giới và gameplay nằm trong các hoạt động. |
| **Main Quest** | **Lộ trình học Python có cấu trúc, miễn phí** nằm trong Main Map (chặng 1–4). Main Quest là một **hoạt động học**; Main Map là **bản đồ/hub** chứa nó. Hai khái niệm **khác nhau**. |
| **Mini-game Play Mode** | Chế độ chơi mini-game ngay, **không** bắt buộc đọc bài hay viết code trước. |
| **Mini-game Creator Mode** | Chế độ xem/đổi luật chơi và dần học lập trình qua chính mini-game đó — **chỉ ở những game phù hợp**, không phải mọi game (xem mục 7.1). |
| **Side Maps** | Bản đồ mở rộng **trả phí tùy chọn**, bổ sung chiều sâu — **không** bán quyền truy cập kiến thức Python cơ bản. |
| **Nhà riêng / khu đất / đảo cá nhân** | Không gian sở hữu và sáng tạo có thể mở rộng, trang trí, nuôi thú và đón khách theo quyền. Là một nhánh hoạt động, không thay thế Main Map công cộng hoặc khóa Main Quest. |
| **Thú cưng thông minh** | Cư dân đồng hành có hành vi và hoạt động chơi, có lựa chọn mua theo nội dung/quyền lợi công bố rõ; có thể tận dụng AI on-device khi thiết bị hỗ trợ, không chỉ là avatar hoặc khung chat. |
| **Nhà Thành Tích** (Achievement House) | **Một địa điểm vật lý trong thế giới PyQuest** trưng bày huy hiệu, chiến tích, bộ sưu tập và game do trẻ tạo. |
| **Adventure Recap** | Bản tổng kết **dựa trên dữ liệu thật** về các hoạt động đã hoàn thành và kỹ năng mới học được (không viết cố định). |
| **Arena** | Trung tâm nhiều bộ môn thi đấu/thử thách của PyQuest: đối kháng trực tiếp, tích lũy sản phẩm/bộ sưu tập sáng tạo, giải đồng đội và các giải sáng tạo chuyên nghiệp. Không phải một trò chọn đáp án cú pháp. |
| **Creator Pro League** | Nhánh giải sáng tạo chuyên nghiệp của Arena: vẽ/lắp ghép/lập trình sản phẩm, chạy thử, nộp bài, chấm điểm và vinh danh. |
| **Tutor** | Nhân vật đồng hành trong thế giới PyQuest, có thể giải thích, gợi ý, cùng khám phá cách giải và ăn mừng tiến bộ. |
| **Danh hiệu** | Ghi nhận một thành tích/vai trò cụ thể; danh hiệu kỹ năng phải dựa trên bằng chứng năng lực, không phải mua hoặc nhận quà. |
| **Danh hiệu xã hội** | Danh hiệu tặng/quà tặng mang tính quan hệ xã hội; hiển thị riêng, không giả làm chứng nhận kỹ năng. |
| **Quà tặng** | Lớp sở hữu/giao lưu xã hội; không tự động cấp thành tích hay quyền thắng trong thi đấu. |

> **Lưu ý.** Trước đây tài liệu từng dùng "Main Map" để chỉ chính tuyến học.
> Cách hiểu đúng từ nay: **Main Map = bản đồ trung tâm (hub điều hướng) miễn phí**, **Main Quest = tuyến học trong đó**.

---

## 2. Triết lý thiết kế

Các nguyên tắc dưới đây chi phối **mọi quyết định** về sản phẩm, từ nội dung
đến mô hình kinh doanh, từ giao diện đến cách viết thoại.

### 2.1. Main Map là hub điều hướng; hoạt động cốt lõi miễn phí

Main Map chỉ là **hub khám phá và mở hoạt động**, không phải một game lớn tự thân.
Tuyến học Python cốt lõi và khả năng tạo game đơn giản **không bị khóa sau paywall**.
Trẻ không cần trả tiền để biết lập trình.

### 2.2. Side Maps bán chiều sâu, không bán lại kiến thức cơ bản

Bản đồ trả phí mở ra **chiều sâu, trải nghiệm mới, phần thưởng độc quyền** —
không bán lại kiến thức mà các hoạt động miễn phí đã dạy.

### 2.3. Năng lượng là tài nguyên gameplay thực sự

Năng lượng **không phải thanh trang trí**. Nó điều tiết nhịp chơi, có quy tắc rõ ràng,
hiển thị minh bạch, và **không tước đi quyền học** của trẻ.

### 2.4. Quảng cáo thưởng tự nguyện

Quảng cáo **không bắt buộc** để học kiến thức cơ bản. Trẻ chỉ xem khi muốn
nhận thêm năng lượng hoặc lượt chơi. Chỉ cộng thưởng sau khi SDK xác nhận hợp lệ.

### 2.5. Nghỉ ngơi là một phần của game

Khi hết năng lượng, PyQuest **không giả vờ** rằng quảng cáo đã phát.
Có hoạt ảnh nghỉ ngơi, gợi ý vận động mắt, và nội dung nhẹ để trẻ vẫn ở lại thế giới.

### 2.6. Không gây áp lực mua Pro

Không đánh lừa, không tạo áp lực với trẻ. Pro là **lựa chọn nâng cấp riêng**,
không phải điều kiện để tiếp tục cuộc phiêu lưu.

### 2.7. Tuân thủ chính sách trẻ em

Kiểm tra **Google Play Families** và mạng quảng cáo định dùng
**trước khi chốt cơ chế**, không phải sau khi đã triển khai.

### 2.8. Python phải thật hoặc mô phỏng có giới hạn rõ ràng

Không tô giao diện giống trình soạn code rồi tuyên bố
trẻ đã tạo game Python thật. Nếu là mô phỏng, phải nói rõ giới hạn.

### 2.9. Nhiều nhánh độc lập; cộng đồng phục vụ gameplay

PyQuest gồm nhiều nhánh hoạt động độc lập (phiêu lưu/khám phá, sưu tầm, giải đố,
sáng tạo, thi đấu và nhánh học lập trình Python). Trẻ tiến bộ theo nhánh mình
thích và **không** phải hoàn thành nhánh này để chơi nhánh khác, trừ khi kiến thức
đó thực sự cần cho hoạt động cụ thể. Mở khóa hoạt động gắn trực tiếp với chính
hoạt động đó; **không có XP/cấp độ toàn cục**.

Bạn bè và cộng đồng tồn tại để **làm gameplay vui hơn** (chơi cùng nhau, so tài,
khám phá, trao đổi kỷ niệm), **không** phải để PyQuest trở thành mạng xã hội.
Không xây bảng tin, hệ thống đăng bài chung hay cơ chế gây áp lực tương tác.

### 2.10. Luật chơi đơn giản; trải nghiệm là trọng tâm

Không đánh đồng game hay với logic phức tạp. Một game có thể chỉ cần điều khiển,
va chạm, thu thập, tính kết quả, nâng cấp, thất bại và chơi lại. Nếu vòng lặp đủ
vui, phản hồi tốt và tiến trình hấp dẫn thì logic đơn giản là ưu điểm, không phải
thiếu sót.

Ưu tiên cảm giác chơi: điều khiển mượt, hoạt ảnh có cá tính, hiệu ứng thu thập rõ
ràng, âm thanh phù hợp, thế giới đẹp và dễ đọc, phản hồi tức thì, nhịp phần thưởng
tốt. Đồ họa không cần siêu thực; phong cách đơn giản nhưng có chủ ý và chỉn chu
vẫn có thể tạo trải nghiệm mạnh.

Vòng lặp ngắn, mục tiêu nhìn thấy được: chơi → thu thập/hoàn thành mục tiêu → nhận
thưởng → nâng cấp hoặc mở khóa → thử thách xa hơn → thất bại/thử lại hoặc hồi sinh.
Tùy game, có thể có kỷ lục cá nhân, nhiệm vụ, khám phá, thi đấu và chơi cùng bạn bè.

Không bắt mọi lượt chơi phải dạy một bài học. Play Mode phải vui và dễ vào chơi
ngay. Creator Mode/Main Quest mở rộng từ trò chơi để người chơi khám phá cách thay
đổi luật và dùng Python sáng tạo khi phù hợp.

Không xây cả thế giới ngay từ đầu. Làm một game nhỏ hoàn chỉnh nhưng có chất lượng
trải nghiệm tốt; sau đó thêm game mới theo module.

### 2.11. Không biến XP thành hệ thống rườm rà

PyQuest không cần một hệ thống XP phức tạp cho mọi trò chơi chỉ vì các game khác
thường có cấp độ.

- **Lớp liên kết chung tối thiểu:** điểm/đóng góp theo luật, điều kiện mở khóa
  hoạt động, thành tích, danh hiệu, vật phẩm/quà tặng và hồ sơ người chơi.
- **Không tự động tạo thêm XP, level, điểm trận, điểm mùa, điểm tổng và nhiều
  loại tiền tệ** nếu chưa có mục đích sản phẩm cụ thể. Không tạo hai chỉ số cùng
  làm một việc chỉ vì tên gọi khác nhau.
- Mỗi game được phép có **điểm số hoặc tài nguyên nội bộ riêng** khi gameplay
  thực sự cần. Chúng không mặc nhiên phải trở thành XP toàn cục hay điểm xếp hạng
  chung.
- Kết quả game chỉ cần gửi sự kiện/kết quả có ý nghĩa sang lớp chung. Lớp chung
  kiểm tra điều kiện, trao điểm/danh hiệu/thành tích và mở khóa theo quy tắc rõ
  ràng; game không cần tự triển khai lại các hệ thống đó.
- **Quyết định hiện tại: không có XP/cấp độ toàn cục trong PyQuest.** Không triển
  khai công thức XP, bảng cấp, phần thưởng theo cấp hay rào cấp. Main Map chỉ điều
  hướng và mở hoạt động; điều kiện mở khóa phải gắn trực tiếp với hoạt động/kiến
  thức cần thiết.

### 2.12. Mô hình mô-đun và lớp dịch vụ chung

- Mỗi game là một module độc lập, có luật chơi, giao diện, tài nguyên, tiến trình
  nội bộ và điều kiện thắng/thua riêng.
- Module có thể báo các sự kiện chuẩn như bắt đầu, hoàn thành, thất bại, đạt kỷ
  lục, thu thập mốc quan trọng hoặc hoàn tất thử thách.
- Lớp dùng chung chịu trách nhiệm cập nhật hồ sơ, điểm đóng góp, thành tích, danh
  hiệu, mở khóa và phần thưởng xã hội theo luật cấu hình.
- Quà tặng thuộc lớp xã hội/sở hữu; quà được mua hoặc được bạn bè tặng không tự
  động chứng minh kỹ năng, không mua trực tiếp thành tích thi đấu.
- Thêm một game mới không được buộc viết lại các game hiện có hoặc nhân bản hệ
  thống thành tích. Chỉ thêm module và kết nối qua giao diện chung đã xác định.
- Thiết kế để triển khai từng phần: ban đầu có thể chỉ có một game, điểm/kỷ lục cơ
  bản và lưu kết quả; hệ thống bạn bè, giải đấu, sáng tạo cộng đồng và quà tặng
  được mở rộng khi cần nhưng vẫn thuộc tầm nhìn sản phẩm.

---

### 2.13. Mỹ thuật 2,5D là chuẩn toàn sản phẩm

Mọi màn PyQuest phải cùng một ngôn ngữ2,5D: cảnh, nhân vật, công trình, nội thất,
đồ vật và phản hồi có khối/chiều sâu/ánh sáng nhất quán. Không chỉ đặt một hình2,5D
vào trang thẻ phẳng rồi coi đã redesign. Áp dụng cả nhà–đất–đảo, visit/pet, Tutor,
mini-games, Arena, thành tích và hệ thống phụ. Text/code/control giữ front-facing
cho dễ đọc nhưng không tách khỏi bộ mỹ thuật chung.

Chuẩn bắt buộc: [ART_DIRECTION_2_5D](design/ART_DIRECTION_2_5D.md). Các ảnh tham khảo
nhiều phong cách không phải quyền trộn pixel-art/flat-vector vào thế giới. Thiết kế
đích không đồng nghĩa artwork/runtime đã có; dùng đủ gate concept → screen → asset.

---

## 3. Mô hình kinh doanh — hai vòng kiếm tiền

### 3.1. Vòng 1 — Quảng cáo thưởng để chơi tiếp

- Trẻ hết năng lượng → nghỉ chờ hồi **hoặc** xem quảng cáo thưởng.
- Chỉ cộng thưởng sau khi SDK xác nhận quảng cáo hoàn thành hợp lệ.
- Không có quảng cáo chen ngang giữa bài học.

### 3.2. Vòng 2 — Mua Side Maps để mở rộng thế giới

- Trả tiền để mở từng bản đồ phụ.
- Mua bản đồ = mua **nội dung và quyền sưu tập**,
  **không** mua khả năng học Python cơ bản.

### 3.3. Pro — lựa chọn nâng cấp riêng

- Bỏ quảng cáo thuộc phạm vi gói Pro.
- Mở một số quyền lợi bổ sung **đã công bố rõ**.
- **Không** khóa Main Quest. **Không** tạo áp lực với trẻ.

> **TBD — cần quyết định sản phẩm.** Quảng cáo thưởng là cách **tùy chọn** để
> nhận thêm năng lượng. Nếu Pro ẩn toàn bộ nút quảng cáo, người dùng Pro sẽ
> **không còn cách nhận +năng lượng qua quảng cáo**. Cần chốt một trong hai:
> (a) người dùng Pro vẫn được **tự nguyện** xem quảng cáo thưởng để lấy năng
> lượng, hoặc (b) Pro có **cách công bố rõ** khác để nhận phần năng lượng tương
> đương. Chưa chốt thì **không** được mặc định Pro mất nguồn năng lượng này.

---

### 3.4. Sở hữu, mở rộng không gian và mua thú cưng

- Nhà riêng, đất/đảo cá nhân và thú cưng là một nhánh sở hữu/sáng tạo dài hạn. Có chức năng mua thú cưng thông minh; quà, ngoại trang và nội dung mở rộng là lựa chọn bổ sung, không chỉ vật trang trí giả lập trong hồ sơ.
- Cách kiếm/mua phần mở rộng, giá, loại tiền và quyền lợi cụ thể cần được thiết kế riêng; chưa mặc định mọi phòng/mảnh đất/đảo đều trả phí. Không bán quyền vào Main Map, kiến thức Python cơ bản hoặc khả năng thắng trong thi đấu.
- Mua thú phải công bố nội dung và khả năng AI trên thiết bị trước giao dịch, có xác nhận/kiểm soát phù hợp với trẻ, receipt và chính sách khôi phục/hỗ trợ. Không dùng gacha, lời nài nỉ của thú hoặc nỗi sợ mất thú để thúc ép mua.

---

## 4. Cấu trúc thế giới game

### 4.1. Home Map — điểm khởi đầu sống động

Home Map **không phải** màn hình danh sách bài học.
Đây là một thế giới có địa điểm, nhân vật, câu chuyện.

**Đặc điểm:**
- Nhân vật dễ thương: robot tò mò, rồng con ham kho báu, mèo tìm lỗi code.
- Thoại ngắn, hài hước, liên quan nhiệm vụ tiếp theo.
- Nhạc nền du dương, âm thanh tương tác phản hồi mỗi lần chạm.
- Mini-game là **địa điểm trên bản đồ**, khám phá không theo thứ tự.

### 4.2. Main Map — hub điều hướng miễn phí

**Main Map là bản đồ trung tâm và điểm vào của các hoạt động PyQuest.** Người chơi nhìn thấy những địa điểm/game đang có, chọn hoạt động, xem điều kiện cần thiết và đi thẳng đến hoạt động đó. Bản đồ có thể được trình bày như một thế giới sống động, nhưng chức năng cốt lõi là **khám phá, điều hướng và mở hoạt động** — không phải tích XP hay tăng cấp.

**Main Map không phải một game lớn tự thân.** Thế giới và gameplay nằm trong các hoạt động mà nó dẫn tới; Main Map chỉ giúp tìm, chọn và mở chúng.

Main Map có thể dẫn tới:

- **Main Quest** — tuyến học Python có cấu trúc (xem mục 6).
- Các **mini-game** miễn phí (xem mục 7), có thể chơi ngay mà không bắt buộc học trước nếu game không cần kiến thức tiên quyết.
- Các **địa điểm/hoạt động khám phá** như nhiệm vụ, thú cưng cơ bản, Nhà Thành Tích và hoạt động cộng đồng khi được triển khai.

Main Quest đi từ `print()` đến gỡ lỗi:

```
print() → biến → điều kiện → vòng lặp → danh sách → hàm → gỡ lỗi
```

**Main Map là nơi chọn hoạt động; Main Quest là một hoạt động học có lộ trình nằm trong bản đồ.** Hai khái niệm khác nhau, không dùng thay thế cho nhau.

**Cam kết:**
- Không cần mua để mở Main Map hay Main Quest.
- Không cần xem quảng cáo để truy cập bản đồ.
- Toàn bộ kiến thức Python cơ bản và kỹ năng tạo game đơn giản nằm trong các hoạt động của Main Map (đặc biệt Main Quest) — không cần mua.

### 4.3. Side Maps — mua từng gói

| Side Map | Nội dung |
|---|---|
| **Pygame Island** | Game 2D nâng cao, kiến trúc game, dự án mở rộng. |
| **AI Pet Trainer Isle** | Hành vi thú cưng, luật phản ứng, thử thách AI. |
| **Bug Hunter Kingdom** | Câu đố tìm lỗi. |
| **Legendary Title Isles** | Săn danh hiệu, huy hiệu, ngoại trang hiếm. |

### 4.4. Thế giới làng PyQuest — mỗi ngôi nhà là một tính năng độc lập

Màn hình chính nên là một ngôi làng/thế giới có thể khám phá, không chỉ là menu chứa các nút chức năng. Các ngôi nhà, công trình và cổng ma thuật là điểm vào những hệ thống gameplay khác nhau.

Ví dụ:
- Thư viện Python/Tutor.
- Tòa nhà Main Quest.
- Đấu trường (Arena).
- Xưởng sáng tạo.
- Bảo tàng/Bộ sưu tập.
- Cổng tới Side Maps/Secret Isles.
- Nhà bạn bè/giao lưu (khi được triển khai).

Tutor là các nhân vật có tính cách, lĩnh vực và vai trò riêng. Họ có thể đi lại trong làng, tương tác với người chơi, xuất hiện tại sự kiện hoặc trao danh hiệu. Chạm vào nhân vật có thể mở trò chuyện (và voice chat nếu sản phẩm hỗ trợ); chạm vào ngôi nhà mở tính năng tương ứng.

Đây là tầm nhìn thế giới có thể mở rộng; không yêu cầu mọi nhân vật, hoạt ảnh hoặc công trình phải có ngay trong phiên bản đầu.

**Mỗi ngôi nhà là một module sản phẩm:**
- Mỗi nhà đại diện cho một khả năng/tính năng được thiết kế riêng, có vòng lặp chơi, giao diện, luật, tiến trình, phần thưởng và nội dung mở rộng của chính nó.
- Có thể bổ sung một ngôi nhà/tính năng mới mà không cần viết lại hoặc buộc mọi nhà hiện có phụ thuộc vào nó.
- Tính năng chưa triển khai vẫn thuộc tầm nhìn sản phẩm, không tự động bị coi là đã loại bỏ.
- Các nhà độc lập về gameplay nhưng dùng chung lớp dịch vụ nền cần thiết: hồ sơ người chơi, điểm, danh hiệu, bạn bè/quyền riêng tư và các quy tắc mở khóa kiến thức có liên quan.
- Không buộc người chơi phải đi qua mọi nhà. Người thích sáng tạo có thể tập trung sáng tạo; người thích thi đấu, khám phá, sưu tập hoặc giao lưu có thể theo đuổi nhánh mình yêu thích.

### 4.5. Nhà riêng, đất và đảo có thể lớn lên cùng người chơi

- Người chơi có không gian riêng để sắp xếp nội thất, trưng bày sản phẩm, nuôi thú và đón bạn. Có thể mở rộng nhà (hiên/phòng/gác), đất (vườn/hồ/sân/bến) và đảo (khu mới, cầu/thuyền, chủ đề và hoạt động mới).
- Các nhiệm vụ và dự án mở rộng phải liên kết thành hành trình rõ: xem điều kiện → đi đúng hoạt động để kiếm huy chương/vật liệu → nhận kết quả → quay về dự án → xác nhận mở. Ví dụ một phòng cần huy chương cụ thể và vật liệu có nguồn; không phải mọi nội dung mở chỉ bằng tiền hoặc một nút bấm.
- Huy chương dùng làm điều kiện thành tích được giữ lại, khác với vật liệu bị tiêu khi xây. Mỗi món còn thiếu cần chỉ nguồn kiếm và đường quay lại; nhiệm vụ/điều kiện không được tạo vòng khóa lẫn nhau. Giá trị, số lượng và luật thưởng phải được duyệt riêng, chống nhận/trừ lặp và không khóa kiến thức cốt lõi sau mở nhà.
- Mở rộng phải tạo thêm khả năng chơi và sáng tạo, không chỉ tăng ô chứa đồ hoặc thay hình nền. Không yêu cầu chạy theo nhà lớn nhất; một căn nhà nhỏ vẫn là trải nghiệm đầy đủ và có giá trị.
- Đây là một nhánh hoạt động độc lập; không biến Main Map miễn phí thành đất tư, không đồng nhất đảo cá nhân với Side Maps trả phí, không tạo XP/cấp độ toàn cục.
- Thăm nhà phải cho khách đi quanh, khám phá và tương tác với các đồ vật/tác phẩm/thú được phép; khi chủ và khách cùng hiện diện phải dựa trên phiên đồng bộ thật. Trang hồ sơ chỉ là một lối vào, không thay cho trải nghiệm thăm nhà.
- Phạm vi cho xem, cùng chơi và cùng sửa là các quyền khác nhau. Phòng riêng không tự mở vì đã kết bạn; chủ có thể thu hồi quyền và khách luôn có đường rời đi an toàn.


---

### 4.6. Một hệ thống thế giới, không bốn ứng dụng rời nhau

Làng công cộng → hoạt động → kết quả → dự án nhà → đất/bến/đảo tạo đường khám phá
liên kết. Đây là **lựa chọn dài hạn**, không thay mọi nhánh thành bài học hay buộc
mọi trẻ xây nhà. Kết quả có thể quay lại hoạt động, trưng bày hoặc dự án đang theo.
Tutor đi cùng ngữ cảnh; bạn bè/Arena là trụ cột chơi lâu dài, không chỉ phụ kiện chat.

- Màn đầu ưu tiên cảnh có điểm đến và một việc đang dở; không biến thành danh sách
  card dài hoặc một nhà riêng chặn Main Map. Có đường vào mini-game ngay.
- Hành trình mở rộng có nhiều quy mô: phòng mở thêm bàn sáng tạo; sân/vườn mở thêm
  chơi với thú; bến/đảo mở thêm nội dung và đường khám phá. Không chỉ đổi wallpaper.
- Dự án được lưu lâu dài, không reset theo nhiệm vụ ngày. Huy chương là bằng chứng
  giữ lại; vật liệu là tài nguyên có thể tiêu; không dùng điểm xếp hạng làm tiền xây.
- Nhà riêng, Nhà Thành Tích, đảo cá nhân và Side Map có identity/quyền khác nhau.
  Cụm “mỗi nhà là một module” ở §4.4 chỉ nói công trình chức năng công cộng, không
  có nghĩa mỗi phòng do trẻ xây cần một module game riêng.
- Giữ miễn phí phần cốt lõi, không cần kết bạn/mua thú để kiếm nguyên liệu bắt buộc;
  không mở vòng khóa: phòng cần gỗ nhưng chỉ phòng đó mới có gỗ.
- Xem **Game Design §17** cho luật, **Technical Architecture §3.8/4.8/9.4** cho
  ownership/authority và **Roadmap §17** cho thứ tự triển khai. Thiết kế màn W01–W14
  nằm trong [WORLD_EXPANSION_REDESIGN](design/WORLD_EXPANSION_REDESIGN.md).

---

## 5. Vòng lặp gameplay & năng lượng

### 5.1. Vòng lặp chính

1. **Chọn nhiệm vụ** — bản đồ, thú cưng, kho báu, nhiệm vụ ngày.
2. **Học và chơi** — bài học ngắn, đấu cú pháp, thu thập phần thưởng và ghi nhận thành tích khi đạt điều kiện.
3. **Năng lượng giảm** — thông báo sắp hết, hiển thị số lượt còn lại.
4. **Nghỉ rồi chơi tiếp** — hồi theo thời gian, chờ nghỉ,
   hoặc xem quảng cáo thưởng nếu đủ điều kiện.
5. **Quay lại cuộc phiêu lưu** — mở nhiệm vụ mới, nâng cấp thú cưng, săn huy hiệu.

### 5.2. Quy tắc năng lượng

- Mỗi hoạt động tiêu hao theo quy tắc rõ ràng; hiển thị số lượt/năng lượng còn lại.
- Hết năng lượng **không** đồng nghĩa hết quyền học.
- Trong lúc chờ hồi, trẻ vẫn có thể:
  - Xem lại bài cũ.
  - Đọc truyện Python.
  - Xem bộ sưu tập.
  - Luyện tập miễn phí.
- Quảng cáo phải có phần thưởng rõ ràng (thêm năng lượng hoặc lượt chơi).

> Thông số định lượng cụ thể (mức tiêu hao, tốc độ hồi, giới hạn ngày)
> được quy định tại `GAME_DESIGN.md`.

### 5.3. Năng lượng, quảng cáo theo từng hạng mục và quyền lợi nhỏ khi mua Side Map

#### Năng lượng là cơ chế giữ nhịp chơi và nhắc trẻ nghỉ

- PyQuest dùng hệ thống năng lượng để điều tiết thời lượng chơi; mục tiêu là giúp trẻ có nhịp học, chơi và nghỉ hợp lý, không khuyến khích chơi liên tục không giới hạn.
- Các hoạt động tiêu hao năng lượng theo mức được thiết kế phù hợp với độ dài và cường độ của hoạt động. Không mặc định mọi hành động đều tốn cùng một lượng.
- Năng lượng hồi lại theo thời gian. Khi năng lượng thấp hoặc hết, giao diện giải thích rõ và gợi ý nghỉ/ngừng chơi, quay lại sau; không dùng thông báo gây áp lực hoặc khiến trẻ sợ mất thành tích.
- Không để năng lượng làm mất tiến độ đang diễn ra: trẻ phải có thể kết thúc/lưu trạng thái ở điểm dừng hợp lý. Không cắt ngang một màn Main Quest hoặc làm mất tác phẩm chỉ vì hết năng lượng giữa chừng.
- Quảng cáo không được dùng để vô hiệu hóa hoàn toàn mục tiêu nghỉ ngơi. Nếu có lượt chơi thêm qua quảng cáo thì vẫn phải tuân thủ giới hạn và thiết kế nhịp nghỉ chung.

#### Quảng cáo có quy tắc và hạn mức riêng ở từng hạng mục

- Các hạng mục của PyQuest có thể tích hợp quảng cáo theo chính sách sản phẩm, nhưng mỗi hạng mục phải có hạn mức riêng, dễ hiểu: lượt miễn phí, số lượt có thể nhận thêm qua quảng cáo, khoảng thời gian áp dụng và thời điểm làm mới hạn mức.
- Quy tắc này áp dụng theo từng hạng mục, chẳng hạn Main Quest, Arena/thi đấu, sáng tạo, sưu tập, Side Maps và mini-game. Không mặc định tất cả phải có cùng số lượt hoặc cùng cách hiển thị quảng cáo; phải xác định hạn mức phù hợp với vai trò của từng hạng mục.
- Muốn chơi thêm sau khi dùng hết lượt miễn phí, người chơi có thể tự nguyện xem quảng cáo nếu hạng mục đó còn lượt thưởng quảng cáo; nếu hết hạn mức thì dừng và chờ lượt/năng lượng hồi lại hoặc quay sang hoạt động phù hợp khác.
- Quảng cáo phải xuất hiện ở điểm dừng tự nhiên, không ép xem giữa màn chơi, không chặn việc học kiến thức cốt lõi của Main Quest và không bắt trẻ xem quảng cáo để bảo vệ tiến độ đã đạt được.
- Năng lượng và lượt quảng cáo là hai giới hạn có liên quan nhưng không đồng nhất: xem quảng cáo không mặc nhiên xóa bỏ mọi giới hạn năng lượng hoặc cấp quyền chơi vô hạn. Luật kết hợp giữa chúng phải được công bố rõ.
- Không biến quảng cáo thành cách mua điểm, danh hiệu, thứ hạng hoặc bỏ qua điều kiện kiến thức. Điểm kiếm từ hoạt động có giới hạn phải được tính vào bảng xếp hạng theo quy tắc chống cày lặp.

#### Mua Side Map chỉ cộng thêm một ít quyền chơi

- Khi người chơi mua/mở khóa một Side Map bằng tiền, có thể tặng kèm một lượng nhỏ năng lượng bổ sung hoặc một ít lượt chơi thêm như quyền lợi phụ.
- Phần cộng thêm phải có giới hạn rõ ràng, nhỏ và cân bằng; không được tạo năng lượng vô hạn, cho phép xem quảng cáo không giới hạn, hoặc biến người mua thành người có lợi thế xếp hạng không tương xứng.
- Quyền lợi phụ này không thay thế điều kiện kiến thức của hoạt động, không tự động trao danh hiệu thành tích và không mua trực tiếp điểm/thứ hạng.
- Mua map mở ra thế giới/nội dung mới là giá trị chính. Năng lượng hoặc lượt chơi cộng thêm chỉ là phần thưởng phụ, không được biến thành lý do duy nhất để mua.
- Cần tách bạch quyền lợi đi kèm giao dịch với năng lượng hồi tự nhiên, lượt miễn phí theo kỳ và lượt thưởng quảng cáo; hiển thị trước giao dịch để phụ huynh/trẻ hiểu rõ điều gì được nhận và giới hạn của nó.

#### Nguyên tắc an toàn với trẻ em

- Không dùng thông báo khẩn cấp giả, chuỗi ép xem quảng cáo, đồng hồ đếm ngược gây áp lực hoặc cơ chế khiến trẻ cảm thấy phải tiếp tục chơi để không mất thứ đã đạt được.
- Trước khi phát hành, phải rà soát cách triển khai quảng cáo, nội dung quảng cáo, sự đồng ý của phụ huynh, tần suất, mua hàng trong ứng dụng và quy định theo thị trường/nền tảng. Không giả định mọi định dạng quảng cáo thưởng đều phù hợp với mọi nhóm tuổi hoặc được phép ở mọi nơi.

---

## 6. Main Quest — lộ trình học miễn phí

Main Quest phải đủ nội dung để trẻ **thực sự biết lập trình**,
kể cả tự làm game đơn giản.

| Chặng | Tên | Nội dung |
|---|---|---|
| **1** | **Code Apprentice** | In chữ, biến, số, chuỗi, phép toán, điều kiện. Điều khiển nhân vật bằng lệnh Python đầu tiên. |
| **2** | **Game Builder** | Vòng lặp, hàm, danh sách, nhập liệu, tọa độ, điểm số, mạng sống, điều kiện thắng thua. |
| **3** | **Game Creator** | Kết hợp kiến thức để tự xây game hoàn chỉnh: nhân vật, chướng ngại vật, va chạm, điểm thưởng, nhiều màn, xử lý lỗi. |
| **4** | **Game Master** | Dự án cuối tuyến miễn phí: game chơi lại được, lưu thành tích, nhận danh hiệu **Game Creator**. |

---

## 7. Mini-game dựng sẵn

Mỗi mini-game trước hết phải **vui và dễ vào chơi ngay**.
Một số mini-game liên kết với một kiến thức Python để trẻ tự tạo game sau này;
**không** bắt mọi mini-game trở thành bài học lập trình.

| Mini-game | Cách chơi | Tư duy Python |
|---|---|---|
| **Robot Maze** | Chọn lệnh lên/xuống/trái/phải đưa robot đến kho báu | Thứ tự lệnh, thuật toán, hàm, vòng lặp |
| **Dragon Jump** | Điều khiển rồng nhảy qua chướng ngại vật, nhặt xu, tránh bẫy | Sự kiện, điều kiện, điểm số, trạng thái game |
| **Catch the Stars** | Di chuyển giỏ hứng sao, tránh vật cản | Biến, tọa độ, vòng lặp, bộ đếm |
| **Bug Hunter** | Tìm lệnh sai, sửa thứ tự khối lệnh | Cú pháp, logic, gỡ lỗi |
| **Pet Lab** | Cho thú cưng ăn/chơi/nghỉ, tạo quy tắc phản ứng | Điều kiện, trạng thái, hàm, thiết kế hành vi |

### 7.1. Play Mode cho mọi game; Creator Mode khi phù hợp

**Play Mode** có ở **mọi** mini-game. **Creator Mode** chỉ có ở **những game phù
hợp** với sáng tạo/lập trình; mỗi game tự quyết định có chế độ này hay không. Game
thuần giải trí, giải đố hoặc suy luận không bắt buộc phải có Creator Mode.

**Mini-game Play Mode** — vào chơi ngay, **không** bắt buộc đọc bài hay viết code.
Có điểm số, nhiệm vụ, âm thanh, hiệu ứng, thành tích.

**Mini-game Creator Mode** — trẻ xem trò chơi hoạt động và thay đổi nó theo hai
cách, tách biệt rõ ràng:

1. **Đổi luật chơi qua điều khiển có cấu trúc sẵn có** của game (ví dụ: chỉnh
   tham số tốc độ, số xu, số màn, điều kiện thắng). Cách này **không** yêu cầu
   chạy code.
2. **Chạy code Python-like được hỗ trợ** thông qua interpreter giới hạn (xem
   `TECHNICAL_ARCHITECTURE.md`). Cách này chỉ khả dụng ở các màn Creator Mode
   đã mở code, và chỉ hỗ trợ tập con cú pháp đã công bố.

Creator Mode tiến dần từ ghép khối → chỉnh tham số → xem code sinh ra → viết
dòng lệnh đơn giản. Không phải màn Creator Mode nào cũng cần interpreter.

### 7.2. Đưa vào Home Map

- Nhân vật rủ trẻ chơi: *"Robot của tớ bị lạc rồi, giúp tớ nhé!"*
- Chơi game để vui; khi đạt điều kiện cụ thể có thể nhận điểm thưởng, huy hiệu hoặc vật phẩm trang trí.
- Phần thưởng học tập lớn hơn cho thử thách lập trình.
- Một số game tiêu hao năng lượng.

### 7.3. Mini-game giải trí — điểm có giới hạn lượt và quảng cáo có giới hạn

- Mini-game giải trí là hoạt động ngắn để thư giãn giữa các chặng học; vẫn có thể thưởng điểm và thành tích phù hợp.
- Mỗi mini-game có số lượt chơi miễn phí trong một khoảng thời gian xác định. Khi hết lượt miễn phí, người chơi có thể dừng lại hoặc tự nguyện xem quảng cáo để nhận thêm lượt.
- Số lượt xem quảng cáo để nhận lượt chơi thêm cũng phải có giới hạn rõ ràng; hết giới hạn thì không tiếp tục cấp lượt qua quảng cáo trong kỳ đó.
- Quảng cáo vừa là nguồn doanh thu vừa tạo khoảng nghỉ ngắn, không được lặp liên tục, chặn Main Quest, buộc trẻ xem để tiếp tục học hoặc gây áp lực phải xem.
- Không dùng quảng cáo để bán điểm, danh hiệu, thứ hạng hoặc thay thế kỹ năng. Điểm từ mini-game phải có mức trần/hạn mức phù hợp để không thể cày lặp rồi thống trị bảng tổng sắp.

---

## 8. Side Maps trả phí & luồng mở khóa

Main Quest đủ kiến thức cơ bản và kỹ năng tạo game đơn giản.
Side Maps bán chiều sâu, trải nghiệm mới, phần thưởng độc quyền.

### 8.1. Luồng mở khóa

1. **Side Map Shop** — xem bản đồ, nội dung, phần thưởng, giá.
2. **Xác nhận mua hàng.**
3. **Xử lý bằng hệ thống thanh toán của nền tảng** khi tích hợp thực tế.
4. **Mở Side Map đã mua.**
5. **Lưu quyền sở hữu và khôi phục giao dịch khi cần.**

**Lưu ý:** quyền mua hàng **không nên** chỉ dựa vào file cục bộ có thể chỉnh sửa;
cần xác minh qua cơ chế thanh toán nền tảng.

---

## 9. Bảng phân quyền Free / Mua gói / Pro

| Tính năng | Miễn phí | Mua gói / Pro |
|---|---|---|
| Main Map (hub điều hướng miễn phí, gồm Main Quest) | Toàn bộ hoạt động và tuyến học cốt lõi | Không cần mua |
| Năng lượng | Hồi theo thời gian, xem quảng cáo thưởng nếu đủ điều kiện | Có thể có quyền lợi bổ sung công bố rõ |
| Main Quest (bài học chính) | Luôn truy cập được | Không khóa sau paywall |
| Side Maps | Xem trước nội dung và giá | Mở từng bản đồ đã mua |
| Danh hiệu, huy hiệu đặc biệt | Có phần thưởng miễn phí | Bộ sưu tập độc quyền từ nhiệm vụ trả phí |
| Bỏ quảng cáo | Có quảng cáo ở vị trí được phép | Pro bỏ quảng cáo thuộc phạm vi gói Pro |

---

## 10. Quy tắc quảng cáo & trẻ em

- Phân biệt rõ **quảng cáo thưởng tự nguyện** với **quảng cáo bắt buộc**.
- Tuân thủ chính sách quảng cáo dành cho trẻ em của nền tảng.
- Kiểm tra **Google Play Families** và mạng quảng cáo định dùng
  **trước khi chốt cơ chế**.
- Quảng cáo gọi là "nghỉ mắt" **không tự động** đồng nghĩa phù hợp với trẻ nhỏ.
- Không hiển thị quảng cáo sai lệch, gây nhầm lẫn hoặc tạo áp lực mua.
- Chỉ cộng thưởng sau khi SDK xác nhận hợp lệ.

---

## 11. Nhà Thành Tích — Hall of Achievements

Không chỉ là trang chứa huy hiệu, mà là một **căn nhà trong thế giới PyQuest**.

### 11.1. Thành phần

- **Tủ huy hiệu:** mỗi huy hiệu đại diện một cột mốc.
- **Tường chiến tích:** số màn đã vượt, số game đã hoàn thành,
  số thế giới đã khám phá.
- **Bộ sưu tập nhân vật:** trang phục, phụ kiện, hiệu ứng cho nhân vật đồng hành.
- **Góc sáng tạo:** trưng bày game do trẻ tự xây.
- **Huy hiệu bí mật:** thưởng cho khám phá thú vị, cách giải khác nhau,
  phát hiện lỗi khó.

### 11.2. Nguyên tắc

Phần thưởng phản ánh **nỗ lực và tiến bộ**,
**không** thưởng cho việc chơi thật lâu hoặc xem thật nhiều quảng cáo.

---

## 12. Màn tổng kết & Adventure Recap

### 12.1. Màn tổng kết sau mỗi màn

Không phải màn hình "Level Complete" khô khan,
mà là đoạn tổng kết ngắn, sinh động, có nội dung riêng.

**Ví dụ:**

> **Tuyệt vời! Bạn đã vượt mê cung!**
> Robot Maze · Màn 5
>
> Bạn đã giúp Robo tìm đúng đường về nhà.
> Những lệnh bạn chọn chính là chìa khóa!
>
> | 12 | 8 | 1 |
> |---|---|---|
> | Màn đã vượt qua | Ngôi sao nhận được | Kỹ năng mới |
>
> **Kỹ năng vừa khám phá:** Bạn đã sử dụng thứ tự các lệnh
> để điều khiển robot. Đó chính là tư duy thuật toán!
>
> **Robo:** "Tuyệt! Thêm một nhà thám hiểm lập trình tài ba!"

### 12.2. Ba nguyên tắc cho màn tổng kết

1. **Ghi nhận thành tựu cụ thể** — trẻ vừa học gì, vượt bao nhiêu thử thách.
2. **Khích lệ không gây áp lực** — có lời động viên và gợi ý thử lại nếu chưa thắng.
3. **Thay đổi theo hành trình** — nhân vật, lời thoại, hiệu ứng, phần thưởng đa dạng.

### 12.3. Adventure Recap — tổng kết chặng lớn

Khi trẻ hoàn thành một chặng, PyQuest tạo báo cáo tổng kết cuộc phiêu lưu.

**Ví dụ:**

> **Cuộc phiêu lưu của bạn**
>
> | 25 | 5 | 8 | 3 |
> |---|---|---|---|
> | Màn đã hoàn thành | Trò chơi đã chinh phục | Kỹ năng Python đã học | Huy hiệu đã mở khóa |
>
> **Lời nhắn của người hướng dẫn:**
> "Bạn đã đi từ những dòng lệnh đầu tiên đến việc tự điều khiển
> nhân vật trong trò chơi. Bạn không chỉ vượt màn —
> bạn đang học cách tạo ra thế giới của riêng mình."

**Lưu ý:** mọi con số phải lấy từ **tiến trình đã lưu**, không viết cố định.

---

## 13. Arena — trung tâm nhiều bộ môn

Arena không phải chỉ là một trò chọn đáp án cú pháp. Đây là trung tâm gồm nhiều
loại thử thách và giải đấu; mỗi bộ môn có cách chơi, điều kiện thắng và cách tính
điểm phù hợp.

### 13.1. Đấu trường luyện tập

- Người chơi vượt thử thách với đối thủ do hệ thống điều khiển.
- Đối thủ có tên nhân vật, ngoại hình và vai trò trong thế giới PyQuest.
- Mục đích là luyện tập, vượt cấp, hoàn thành điều kiện hoặc giành quyền tham gia giải.
- Giao diện hướng tới người chơi không dùng nhãn kỹ thuật gây hiểu nhầm; trình bày nhân vật như một đối thủ trong game.
- **Cấm dùng từ "bot"** trong toàn bộ nội dung sản phẩm và giao diện người chơi. Chế độ luyện tập gọi là "Đối thủ", đặt tên nhân vật phù hợp thế giới PyQuest.
- Không giả mạo đối thủ do hệ thống điều khiển thành người thật. Tên nhân vật và bối cảnh có thể mang tính hư cấu trong chế độ luyện tập, nhưng không được tuyên bố đó là người thật hoặc thành tích toàn cầu thật.

### 13.2. Đấu trường thi đấu

- Dùng cho các cuộc thi có thứ hạng, điểm, giải theo mùa/tuần và danh hiệu.
- Khi là cuộc thi giữa người thật, phải hiển thị đúng trạng thái và danh tính/tên hiển thị của người thật; không giả mạo người chơi hoặc tuyên bố đang thi đấu toàn cầu nếu dữ liệu không chứng minh điều đó.
- Màn hình trận có thể hiển thị tên nhân vật/thí sinh, điểm realtime, thanh tiến độ, vị trí và trạng thái hơn-thua.
- Không cần đưa giải thích về công nghệ điều khiển đối thủ lên giao diện thi đấu.

### 13.3. Điểm và thanh tiến độ realtime

Mục đích chính của điểm/thanh tiến độ trực tiếp là giúp trẻ thấy diễn biến: mình đang dẫn, bị vượt hay sắp hoàn thành mục tiêu. Không biến việc này thành một bài toán phải chứng minh công bằng tuyệt đối.

- Mê cung/đua tốc độ: tiến độ dựa trên quãng đường, mục tiêu, vật phẩm hoặc checkpoint thực sự hoàn thành.
- Đấu thú/robot: có thể dùng máu, năng lượng, điểm kỹ năng hoặc mục tiêu đạt được.
- Thử thách theo lượt: điểm thay đổi sau hành động hoặc câu trả lời có kết quả.
- Giải sáng tạo được chấm: có thể hiển thị điểm tạm tính/tiến độ đánh giá; kết quả cuối cùng chỉ chốt sau khi mô phỏng và chấm xong.
- Không bắt mọi bộ môn dùng chung một công thức. Mỗi giải có luật chấm riêng, đủ rõ để người chơi hiểu cách thắng/thua.
- Không cần ép tất cả người chơi hoặc sản phẩm giống hệt nhau. Sự khác biệt trong sáng tạo là một phần của gameplay.

### 13.4. Creator Pro League — giải sáng tạo chuyên nghiệp

Đây là một nhánh quan trọng của Arena, không được rút gọn thành bài trắc nghiệm Python.

**Vòng lặp gameplay:**
1. **Vẽ và sáng tạo:** trẻ tự vẽ hoặc tùy chỉnh hình dáng, màu sắc, khuôn mặt, phụ kiện và ngoại hình.
2. **Lắp ghép:** kết hợp các bộ phận/module để tạo robot, con vật, phương tiện hoặc sinh vật của riêng mình.
3. **Lập trình:** dùng khối lệnh trực quan hoặc đoạn code phù hợp cấp độ để điều khiển sản phẩm.
4. **Chạy thử:** sản phẩm chạy trong mô phỏng; trẻ nhìn thấy code biến thành hành động thực tế.
5. **Sửa và nâng cấp:** thay đổi thiết kế, logic hoặc chiến thuật rồi thử lại.
6. **Nộp bài/thi đấu:** đưa sản phẩm vào thử thách theo chủ đề và luật cụ thể.
7. **Chấm điểm và vinh danh:** hệ thống đánh giá kết quả, xếp hạng, trao danh hiệu và cộng điểm vào bảng xếp hạng tuần/mùa.

**Ví dụ bộ môn:**
- **Maze Championship:** thiết kế nhân vật/robot và lập trình tìm đường, tránh bẫy, lấy vật phẩm, về đích.
- **Creator Pro League:** vẽ/lắp ghép robot hoặc sinh vật, lập trình hành vi để hoàn thành đề bài.
- **AI Pet Battle:** tạo thú cưng và lập trình quy tắc hành vi/chiến thuật để tham gia đấu trường.
- Có thể mở rộng thêm các bộ môn sáng tạo khác khi gameplay đã hỗ trợ.

**Chấm điểm:**
Không cần giả định có công bằng tuyệt đối giữa các tác phẩm khác nhau. Cần có luật và tiêu chí đủ rõ để người chơi biết mình được đánh giá dựa trên điều gì.

Có thể kết hợp:
- **Chỉ số khách quan từ mô phỏng:** hoàn thành nhiệm vụ hay không, thời gian, đường đi, số lỗi va chạm, vật phẩm thu thập, tài nguyên sử dụng, độ ổn định và các số liệu phù hợp với từng đề.
- **Đánh giá theo tiêu chí:** độ sáng tạo, thiết kế, cách giải quyết vấn đề, chất lượng logic/code và mức đáp ứng đề bài.
- AI có thể hỗ trợ đánh giá các tiêu chí sáng tạo/chất lượng; không nên thay thế những dữ kiện có thể đo trực tiếp bằng kết quả mô phỏng.
- Trọng số phụ thuộc bộ môn và có thể khác giữa các giải. Công bố tiêu chí và trọng số đủ để người chơi hiểu cách tính.
- Điểm realtime có thể là điểm tạm tính; điểm chính thức được chốt khi đánh giá hoàn tất.
- Không âm thầm thay đổi điểm để ép một kết quả thắng/thua cụ thể.

### 13.5. Ba nhánh hoạt động trong Arena

Arena cần có ít nhất ba nhánh rõ ràng, không gộp mọi thứ thành một kiểu thi đấu:

#### A. Đối kháng trực tiếp

- Người chơi điều khiển sản phẩm/nhân vật của mình thi trực tiếp với một đối thủ trong cùng trận hoặc cùng thử thách.
- Ví dụ: đua mê cung, đua vượt chướng ngại, đấu thú hoặc đấu robot chiến thuật.
- Điểm, thanh tiến độ, vị trí, máu/năng lượng hoặc mục tiêu hoàn thành cập nhật trong lúc chơi để người chơi nhìn thấy diễn biến hơn-thua.
- Kết quả trận quyết định thắng/thua, điểm giải, thứ hạng và phần thưởng tương ứng.
- Tùy khả năng sản phẩm, đối thủ có thể là nhân vật do hệ thống điều khiển trong chế độ luyện tập hoặc người chơi thật trong giải trực tuyến. Phải thể hiện trung thực loại trận; không giả mạo người thật.

#### B. Tích lũy sản phẩm / bộ sưu tập sáng tạo

- Người chơi tạo nhiều sản phẩm theo thời gian: nhân vật, thú cưng, robot, phương tiện, bản thiết kế, chương trình điều khiển hoặc tác phẩm khác.
- Có thể vẽ, tùy chỉnh và lắp ghép bộ phận; lập trình sản phẩm; lưu phiên bản; thử nghiệm; nâng cấp; đặt tên; xem lịch sử và trưng bày bộ sưu tập.
- Sản phẩm không chỉ là skin hoặc đồ trang trí: khi phù hợp, chúng có logic/hành vi do code điều khiển và có thể được dùng trong các thử thách.
- Có mục tiêu tích lũy như hoàn thành bộ sưu tập, mở khóa bộ phận, hoàn thành chủ đề hoặc sở hữu các tác phẩm có đặc tính khác nhau. Không cần cấp sáng tạo/XP toàn cục.
- Có thể tổ chức thử thách đánh giá từng tác phẩm hoặc cả bộ sưu tập. Điểm/danh hiệu gắn với tiêu chí của thử thách, không mặc định số lượng nhiều là chất lượng cao.
- Nhánh này vẫn có giá trị với trẻ không muốn đối kháng trực tiếp; không bắt buộc mọi tác phẩm phải tham gia thi đấu.

#### C. Giải đồng đội

- Cho phép người chơi tham gia đội, cùng thực hiện mục tiêu và tích lũy thành tích tập thể.
- Các vai trò có thể bổ trợ nhau, ví dụ: người thiết kế, người lắp ghép, người viết logic/code, người thử nghiệm và người tối ưu chiến thuật. Không nhất thiết phải khóa vai trò cứng; cách chia việc tùy định dạng giải.
- Định dạng giải có thể gồm cùng nhau giải mê cung, phối hợp nhiều sản phẩm, xây dựng một tác phẩm chung, vượt chuỗi nhiệm vụ hoặc cộng điểm từ các thành viên trong một khoảng thời gian.
- Điểm đội có thể dựa trên kết quả nhiệm vụ, tiến độ chung, chất lượng sản phẩm hoặc tổng thành tích thành viên theo luật cụ thể. Nêu rõ thành tích cá nhân và thành tích đội để người chơi thấy đóng góp của mình.
- Hỗ trợ danh hiệu cá nhân lẫn danh hiệu tập thể: thành viên đội vô địch, đội sáng tạo xuất sắc, đội hoàn thành thử thách, danh hiệu theo mùa.
- Giải đồng đội có thể triển khai sau các chế độ đơn người, nhưng phải được giữ trong tầm nhìn sản phẩm; không được loại bỏ chỉ vì chưa thuộc phiên bản đầu.

### 13.6. Danh hiệu, điểm tuần và thành tích lâu dài

Arena phải tạo ra động lực theo nhiều cấp:
- Điểm của trận/thử thách.
- Thứ hạng trong từng bộ môn.
- Điểm đóng góp vào bảng xếp hạng tuần.
- Giải theo mùa và danh hiệu lưu trong hồ sơ.
- Danh hiệu hiếm gắn với thành tích thực sự hoặc thử thách đặc biệt.

Ví dụ tên danh hiệu (tên có thể được bản địa hóa): Maze Master, Master Creator, AI Beast Tamer, Weekly Champion, Legendary Inventor.

Không nhất thiết mọi danh hiệu dùng cùng điều kiện. Có thể trao danh hiệu vì tốc độ, sáng tạo, chiến thuật, hoàn thành bộ sưu tập hoặc thành tích theo mùa. Cần tránh để một loại điểm duy nhất khiến các bộ môn khác mất ý nghĩa.

#### 13.6.1. Danh hiệu độc quyền, quan hệ với Tutor và nhiều bảng xếp hạng

PyQuest cần có hệ thống vinh danh nhiều tầng. Không ép mọi thành tích vào một bảng duy nhất, nhưng các thành tích đủ điều kiện vẫn có thể đóng góp vào điểm tổng sắp chung.

**Danh hiệu độc quyền của Side Maps:**
- Một Side Map/Secret Isle có thể sở hữu bộ danh hiệu độc quyền gắn với thế giới, cốt truyện, kỹ năng và thử thách riêng của nơi đó.
- Mở khóa hoặc mua quyền truy cập map chỉ mở cơ hội tham gia; không tự động trao danh hiệu vốn đại diện cho thành tích. Người chơi phải đạt mốc, hoàn thành thử thách hoặc thỏa điều kiện được công bố.
- Danh hiệu độc quyền phải giữ được ý nghĩa riêng của map và được lưu trong hồ sơ/bộ sưu tập danh hiệu. Có thể ghi nhận rõ danh hiệu đến từ thế giới nào.
- Không được biến việc mua ngọc hoặc mua map thành cách mua thẳng thứ hạng thi đấu, điểm thành tích hay danh hiệu vốn phải kiếm bằng kỹ năng. Nếu có vật phẩm trả phí, phải phân biệt rõ vật phẩm sở hữu với thành tích đạt được.

**Danh hiệu riêng do Tutor trao tặng:**
- Các Tutor là nhân vật trong thế giới, có thể xây dựng quan hệ với người chơi thông qua học tập, trò chuyện, giúp đỡ nhân vật, hoàn thành nhiệm vụ hoặc tiến bộ ở lĩnh vực họ hướng dẫn.
- Tutor có thể trao danh hiệu riêng khi người chơi đạt mốc quan hệ hoặc hoàn thành một nhiệm vụ/cột mốc đặc biệt. Danh hiệu có thể mang tên và câu chuyện riêng của Tutor, làm cho phần thưởng có cảm xúc và có tính sưu tầm.
- Không nhất thiết mọi Tutor đều dùng chung điều kiện. Điều kiện nên gắn với tính cách, lĩnh vực và câu chuyện của nhân vật; người chơi cần hiểu cách nhận danh hiệu.
- Quan hệ tốt với Tutor phải được xây dựng bằng tương tác và thành tích trong game, không phải mua hàng hoặc trả tiền để được nhân vật yêu quý.

**Nhiều bảng xếp hạng, một hồ sơ thành tích:**
- **Bảng tuần:** thành tích trong tuần hiện tại, làm mới theo lịch được công bố.
- **Bảng tháng:** thành tích trong tháng, có phần thưởng/danh hiệu tháng nếu áp dụng.
- **Bảng thi đấu:** kết quả theo trận, bộ môn, giải hoặc mùa thi đấu.
- **Bảng hoạt động:** các nhóm hoạt động như khám phá, hoàn thành nhiệm vụ, sáng tạo, sưu tầm hoặc đóng góp đồng đội.
- **Bảng chuyên môn:** xếp hạng riêng theo từng bộ môn để người giỏi sáng tạo không bị đánh giá chỉ bằng thành tích đua tốc độ, và ngược lại.
- **Bảng đội:** thành tích tập thể, đóng góp đội và danh hiệu đội theo giải/mùa.
- **Tổng sắp chung:** quy đổi điểm đóng góp từ các nhánh theo quy tắc đã công bố, tạo một góc nhìn tổng thể nhưng không thay thế các bảng chuyên biệt.

**Quy tắc quy đổi điểm:**
- Mỗi loại hoạt động có thể có điểm gốc, hệ số hoặc giới hạn đóng góp riêng; công thức cần được công bố đủ rõ và tránh để một hoạt động lặp vô hạn thống trị mọi bảng.
- Danh hiệu có thể đóng góp điểm tổng sắp khi có quy tắc rõ ràng, nhưng sở hữu danh hiệu không tự động đồng nghĩa với điểm vô hạn hoặc vị trí cố định.
- Điểm tuần/tháng phải tách kỳ và quy tắc reset khỏi điểm thành tích lâu dài trong hồ sơ. Danh hiệu vĩnh viễn đã kiếm được không bị xóa chỉ vì kỳ xếp hạng kết thúc.
- Bảng xếp hạng người thật chỉ hiển thị dữ liệu thi đấu thật. Bảng luyện tập với nhân vật hư cấu phải được trình bày đúng bản chất, không giả làm bảng xếp hạng người thật.
- Vì PyQuest hướng tới trẻ em, cần tránh thiết kế bảng xếp hạng gây áp lực quá mức; có thể cung cấp bảng bạn bè/đội hoặc mục tiêu cá nhân bên cạnh bảng cạnh tranh rộng hơn.

### 13.7. Kết nối với vòng lặp học tập và thế giới PyQuest

- Main Quest vẫn là tuyến học cốt lõi miễn phí.
- Mini-game không chỉ để giải trí hoặc nhận thưởng; phải cho trẻ áp dụng kiến thức đã học.
- Khối lệnh trực quan phù hợp với người mới; có thể mở dần sang Python thật khi phù hợp.
- Không yêu cầu xây dựng trình chạy Python đầy đủ ngay từ phiên bản đầu để giữ ý tưởng sáng tạo. Có thể bắt đầu bằng tập lệnh/khối lệnh giới hạn và mô phỏng an toàn, nhưng không được vì vậy mà xóa bỏ tầm nhìn mở rộng.
- Side Maps / Secret Isles có thể mở rộng nội dung, bộ môn, chủ đề, vật phẩm, danh hiệu và trải nghiệm nâng cao theo mô hình thương mại đã mô tả trong tài liệu sản phẩm.
- Thành tích từ Arena liên kết với hồ sơ, bộ sưu tập danh hiệu và bảng xếp hạng tuần/mùa.

#### 13.7.1. Các nhánh độc lập; dependency chung được giới hạn rõ ràng

Đây là nguyên tắc kiến trúc sản phẩm bắt buộc:

- **Mỗi nhánh là một hoạt động độc lập.** Đối kháng trực tiếp, tích lũy/bộ sưu tập sản phẩm, giải sáng tạo chuyên nghiệp và giải đồng đội có tiến trình, luật chơi, điều kiện tham gia, cách chấm điểm và phần thưởng riêng. Người chơi không phải hoàn thành một nhánh để được chơi nhánh khác, trừ điều kiện kiến thức/mở khóa đã quy định.
- **Dependency về kiến thức đi từ Main Quest đến các nhánh hoạt động.** Người chơi phải vượt qua một số map Main Quest tương ứng để học đủ kiến thức trước khi mở khóa hoặc đủ điều kiện tham gia từng bộ môn. Mỗi bộ môn chỉ yêu cầu các map/kiến thức thật sự cần cho gameplay của nó; không khóa tất cả hoạt động sau khi hoàn thành toàn bộ Main Quest.
- **Điểm tổng sắp và danh hiệu là lớp liên kết chung.** Thành tích của từng nhánh được quy đổi theo quy tắc của nhánh đó thành điểm đóng góp và/hoặc danh hiệu; hệ thống tổng hợp chúng vào hồ sơ và bảng tổng sắp tuần/mùa. Đây là cầu nối chung giữa các nhánh, không phải lý do để buộc tiến trình chơi của chúng phụ thuộc lẫn nhau.
- Không yêu cầu người chơi phải sở hữu sản phẩm mới được đấu đối kháng nếu chế độ đó có phương án tham gia riêng; không bắt người thích sưu tầm phải thi đấu; không bắt thành viên muốn thi đồng đội phải hoàn thành Creator Pro League trước, trừ khi giải cụ thể yêu cầu kiến thức hoặc sản phẩm tương ứng.
- Giữ dữ liệu, tiến trình, luật và vòng lặp của từng nhánh tách biệt ở mức thiết kế. Chỉ chia sẻ những dịch vụ nền thật sự cần thiết như hồ sơ, mở khóa kiến thức, điểm tổng sắp và danh hiệu; tránh tạo dependency chéo không cần thiết.
- Khi thiết kế roadmap, có thể triển khai các nhánh ở thời điểm khác nhau nhưng phải giữ chúng trong tầm nhìn sản phẩm. "Chưa triển khai" không đồng nghĩa với "phụ thuộc vào nhánh khác" hoặc "bị loại bỏ".

#### 13.7.2. Ba quy tắc sản phẩm cốt lõi: điểm, mở khóa kiến thức và lượt mini-game

**Dependency 1 — Mọi thành tích quy về điểm tổng sắp:**
- Các nhánh vẫn độc lập về gameplay, nhưng thành tích của chúng có thể quy đổi theo quy tắc tương ứng thành điểm đóng góp cho hệ thống tổng sắp chung.
- Bảng tuần, tháng, thi đấu, hoạt động, chuyên môn và đồng đội là các bảng/góc xếp hạng khác nhau; không phải các hệ thống điểm hoàn toàn tách rời. Cần quy định rõ loại điểm và kỳ tính của từng bảng.
- Danh hiệu vẫn giữ ý nghĩa sưu tầm và thể hiện thành tích; những danh hiệu được quy định có điểm thưởng có thể đóng góp vào tổng sắp. Không mặc định mọi danh hiệu đều cho điểm như nhau.
- Không để một nhánh có thể cày lặp vô hạn rồi chiếm toàn bộ bảng tổng sắp. Điểm, hệ số và giới hạn đóng góp cần phù hợp với từng loại hoạt động.

**Dependency 2 — Main Quest mở khóa hoạt động theo kiến thức đã học:**
- Mỗi hoạt động xác định trước những kiến thức cần thiết, sau đó ánh xạ đến các map Main Quest dạy và kiểm tra các kiến thức đó.
- Người chơi phải hoàn thành đủ những map tương ứng mới được mở khóa hoạt động. Khi chưa đủ điều kiện, giao diện phải nói rõ còn thiếu map nào hoặc cần học năng lực gì, đồng thời cho phép đi thẳng đến map liên quan.
- Không bắt người chơi hoàn thành toàn bộ Main Quest để mở mọi thứ. Điều kiện chỉ cần bao phủ kiến thức thực sự cần cho hoạt động cụ thể.
- Ngọc, mua Side Map hoặc quảng cáo không thay thế điều kiện kiến thức của hoạt động yêu cầu kỹ năng đó.

**Mini-game giải trí — điểm có giới hạn lượt và quảng cáo có giới hạn:**
- Đã mô tả ở mục 7.3.

### 13.8. Hướng triển khai theo giai đoạn (không phải lý do loại bỏ tầm nhìn)

- **Giai đoạn đầu:** module lắp ghép có sẵn, tùy chỉnh ngoại hình, khối lệnh giới hạn, mô phỏng đơn giản, điểm và kết quả xác định được.
- **Giai đoạn tiếp theo:** thêm bộ phận/khả năng, điều kiện/vòng lặp phức tạp hơn, nhiều đề thi, lưu tác phẩm và nâng cấp.
- **Giai đoạn nâng cao:** giải theo mùa, bài thi sáng tạo phong phú, đánh giá AI có kiểm soát, chia sẻ tác phẩm và thi đấu trực tuyến khi sản phẩm sẵn sàng.

Đây là cách chia phạm vi triển khai, không phải quyết định bỏ các tính năng khỏi tầm nhìn sản phẩm.

---

## 14. AI Tutor — dẫn đường, bảng giảng và nhân vật đồng hành

### 14.1. Mục tiêu trải nghiệm

- **Tutor-first, không chat-first:** Tutor dẫn dắt từ đầu hành trình. Khi vào bài học, giao diện chính là bảng giảng tương tác để Tutor viết code/chữ, vẽ minh họa, tô sáng và giải thích từng bước; người chơi có thể đánh dấu chỗ vướng rồi tự thử. Khung chat/lịch sử là phần phụ, không thay thế phương tiện giảng giải.

- AI Tutor là một trong những trải nghiệm đầu tiên người chơi thực sự gặp, không phải một nút chat phụ được thêm vào sau. Cảnh mở đầu phải sống động, giàu biểu cảm và có chất lượng hình ảnh như game thương mại; tránh phong cách sách giáo khoa, màn hình biểu mẫu khô cứng hoặc nhân vật chỉ đứng cạnh một bong bóng thoại tĩnh.
- Cảnh mở đầu giới thiệu Tutor qua một khoảnh khắc tương tác ngắn trong thế giới PyQuest: nhân vật xuất hiện, chào người chơi, phản ứng bằng biểu cảm/hoạt ảnh và mời người chơi cùng bắt đầu hành trình. Phải có tương tác thật (chạm, chọn hoặc trả lời), không chỉ là đoạn phim dài không thể bỏ qua.
- Mục tiêu là tạo cảm giác có một người bạn đồng hành thông minh, vui vẻ và đáng tin, đồng thời cho trẻ hiểu ngay Tutor có thể giúp việc gì: giải thích, gợi ý khi bí, cùng khám phá cách giải và ăn mừng tiến bộ.
- Thiết kế cảnh mở đầu trước khi mở rộng hàng loạt sang các màn khác. Dựng một mẫu hoàn chỉnh gồm hình ảnh, chuyển động, lời thoại, lựa chọn phản hồi, trạng thái chuyển tiếp và cách mở lại Tutor; chỉ nhân rộng khi mẫu đã được duyệt.

### 14.2. Nhịp hội thoại đầu tiên

1. Tutor xuất hiện trong một cảnh thuộc thế giới PyQuest, có hoạt ảnh vào cảnh, ánh mắt/biểu cảm và phản ứng với thao tác của trẻ.
2. Tutor chào bằng tiếng Việt tự nhiên, câu ngắn, thân thiện, không dùng giọng giáo điều hoặc kiểu đọc bài giảng. Lời chào có thể được đọc thành tiếng nếu âm thanh được bật.
3. Trẻ được chọn cách tương tác đơn giản, chẳng hạn chọn một câu trả lời gợi ý hoặc nhập/nói câu ngắn; không buộc trẻ nhập thông tin cá nhân để tiếp tục.
4. Tutor minh họa một khả năng hữu ích bằng một tương tác ngắn: đưa ra câu đố nhỏ, cho trẻ thử, phản hồi theo câu trả lời và gợi ý một bước nếu trẻ gặp khó.
5. Tutor giải thích rằng trẻ có thể gọi mình từ các màn học/chơi để xin gợi ý, hiểu lỗi hoặc tìm cách giải khác. Sau đó dẫn trẻ vào game chính một cách tự nhiên.
6. Cảnh có nút bỏ qua và có thể xem lại; không kéo dài phần giới thiệu, không khóa trẻ trong hội thoại bắt buộc hoặc lặp lại mỗi lần mở ứng dụng.

### 14.3. Nhân vật Tutor có thể chọn và sưu tầm

- Tutor có một bộ nhân vật được thiết kế nghệ thuật đồng bộ nhưng mỗi nhân vật có hình dáng, cá tính, biểu cảm, chuyển động và âm sắc riêng. Các hướng nhân vật có thể gồm **cún, mèo, rồng, búp bê** và các nhân vật nguyên bản khác phù hợp thế giới PyQuest.
- Có một nhân vật mặc định miễn phí, đủ đẹp và có đầy đủ khả năng Tutor. Trẻ có thể đổi nhân vật trong khu vực tùy chỉnh; nhân vật đang dùng phải xuất hiện nhất quán ở cảnh mở đầu, trong màn chơi, khi đưa gợi ý và khi chúc mừng.
- Có thể bán nhân vật bổ sung dưới dạng nội dung tùy chọn. Giao dịch chỉ thay đổi ngoại hình, hoạt ảnh, biểu cảm, phụ kiện hoặc gói giọng đọc đã mô tả rõ; **không khóa chất lượng giải thích, độ thông minh, số gợi ý cần thiết hoặc quyền được trợ giúp cốt lõi sau paywall**.
- Mỗi nhân vật trả phí phải được thiết kế cẩn thận trước khi đưa vào cửa hàng: silhouette dễ nhận ra ở kích thước nhỏ, biểu cảm đọc được, hoạt ảnh idle/talk/listen/think/celebrate/error-support, cách hiển thị trong các tỉ lệ màn hình khác nhau và khả năng tiếp cận. Không chỉ đổi màu hoặc thay một icon rồi coi là nhân vật mới.
- Có thể cho trẻ xem trước nhân vật và hoạt ảnh thực tế trước khi mua. Giá, nội dung nhận được và việc mua một lần hay có điều kiện khác phải hiển thị rõ; không dùng đồng hồ đếm ngược, khan hiếm giả hoặc lời thoại khiến trẻ cảm thấy Tutor sẽ buồn nếu không được mua.
- Mua nhân vật không mua được tình cảm của Tutor, quan hệ đặc biệt, danh hiệu kỹ năng hoặc lợi thế thi đấu. Mối quan hệ trong game phát triển qua tương tác và tiến bộ, không phụ thuộc tiền trả.
- Việc chọn nhân vật là tùy chọn; không bắt trẻ phải mua hoặc chọn một nhân vật mới để bắt đầu học. Cần tính tới xác nhận mua hàng/phụ huynh và quy định mua hàng trong ứng dụng dành cho trẻ em theo nền tảng/thị trường.

### 14.4. Tutor đồng hành theo ngữ cảnh trong toàn game

- Tutor không phải một chatbot tách rời khỏi gameplay. Khi được gọi từ một màn cụ thể, hệ thống cần cung cấp ngữ cảnh tối thiểu có liên quan như mục tiêu nhiệm vụ, câu hỏi hiện tại, câu trả lời của trẻ, số lần thử, gợi ý đã đưa và khái niệm đang học; không gửi toàn bộ lịch sử hoặc dữ liệu không cần thiết.
- Tutor phải hỗ trợ **gợi ý theo từng nấc**: trước hết hướng trẻ chú ý tới dữ kiện; tiếp theo gợi ý một bước; sau đó minh họa hoặc giải thích cách làm nếu trẻ vẫn cần. Không mặc định bật mí đáp án ngay ở lần sai đầu tiên.
- Khi trẻ trả lời đúng, Tutor giải thích ngắn vì sao cách làm hiệu quả. Khi trẻ sai, phản hồi không chê bai, không làm trẻ xấu hổ và đưa ra bước tiếp theo cụ thể. Có thể thay đổi cách giải thích hoặc ví dụ nếu trẻ chưa hiểu.
- Với bài có đáp án chuẩn hoặc kết quả mô phỏng xác định được, hệ thống bài học/mô phỏng là nguồn sự thật về đáp án. AI có thể giải thích và gợi ý nhưng không được tự ý thay đổi đáp án, quy tắc chấm hoặc kết quả trận.
- Phản hồi cần phù hợp lứa tuổi và ngôn ngữ đã chọn; tránh nội dung đáng sợ, tình dục, bạo lực không phù hợp, thao túng cảm xúc, yêu cầu giữ bí mật với người lớn, xin thông tin cá nhân hoặc khuyến khích lệ thuộc vào Tutor.
- Hội thoại tự do bằng văn bản/giọng nói, nếu được hỗ trợ, phải có giới hạn an toàn và cơ chế thoát dễ thấy. Không mặc định triển khai voice chat mở không kiểm soát chỉ vì có nhân vật biết nói.

### 14.5. Kiến trúc AI, chi phí và quyền riêng tư

- Trước khi chọn nhà cung cấp/model, xác định yêu cầu chất lượng tiếng Việt, độ trễ, khả năng gợi ý theo từng bước, chi phí mỗi phiên và phương án khi dịch vụ lỗi. Có thể đánh giá các nhà cung cấp như Gemini hoặc lựa chọn khác, nhưng không khóa kiến trúc vào một nhà cung cấp trước khi có thử nghiệm và quyết định được ghi nhận.
- Với phát hành công khai/production, khóa API phải nằm ở backend/service an toàn, không nhúng vào client. Không commit secret vào repository. [Owner-test r49](OWNER_TEST_BUILDS.md) có ngoại lệ được người dùng cho phép: nhúng key vào APK thử nội bộ, hoãn token/backend/quota cho lần thử này.
- Dùng giới hạn token/thời lượng, rate limit, quota và theo dõi chi phí; không để một tài khoản có thể tạo chi phí không giới hạn. Cần thiết kế thông báo lỗi và phương án trợ giúp không dùng AI khi mạng yếu, quota hết hoặc nhà cung cấp không khả dụng.
- Chỉ gửi dữ liệu tối thiểu cần thiết cho nhiệm vụ. Không yêu cầu tên thật, địa chỉ, trường học, số điện thoại, ảnh, vị trí hoặc thông tin nhạy cảm để dùng Tutor. Quy định lưu trữ, thời hạn xóa, quyền phụ huynh và sự đồng ý cần được xác định trước phát hành.
- Xác định rõ phần nào chạy cục bộ, phần nào gửi đến dịch vụ bên ngoài; thông báo dễ hiểu cho phụ huynh về việc dùng AI/giọng nói và dữ liệu được xử lý. Không tuyên bố hội thoại hoàn toàn riêng tư hoặc không được lưu nếu kiến trúc nhà cung cấp chưa chứng minh điều đó.
- Kiểm thử bằng bộ tình huống dành riêng cho trẻ: câu trả lời sai liên tiếp, câu hỏi ngoài chủ đề, nội dung không an toàn, yêu cầu tiết lộ dữ liệu, prompt injection, câu trả lời AI sai, ngắt mạng, timeout, hết quota và chuyển sang trợ giúp không AI.

### 14.6. Tiêu chí nghiệm thu cho mẫu đầu tiên

- Cảnh mở đầu có hình ảnh và chuyển động đủ chất lượng để đại diện cho phong cách PyQuest mới; không phải chỉ là màn chat với ảnh đại diện.
- Người chơi có thể tương tác, nhận phản hồi phù hợp và vào game; có thể bỏ qua hoặc xem lại.
- Ít nhất một nhân vật mặc định hoàn chỉnh; hệ thống thiết kế cho phép thêm cún/mèo/rồng/búp bê mà không phải viết lại luồng hội thoại.
- Mua nhân vật chỉ thay đổi phần mỹ thuật/đã công bố; Tutor miễn phí vẫn có đủ năng lực hỗ trợ học tập cốt lõi.
- Tutor sử dụng đúng ngữ cảnh bài hiện tại, đưa gợi ý theo nấc và không tự ghi đè đáp án chuẩn.
- Có giới hạn an toàn, xử lý lỗi dịch vụ, kiểm soát chi phí và quy tắc dữ liệu trước khi đưa AI thật tới người dùng.
- Thiết kế hình ảnh và hội thoại phải được duyệt bằng một mẫu chơi thực tế trước khi mở rộng toàn game. Đây là thứ tự triển khai ưu tiên, không phải lý do loại bỏ tầm nhìn Tutor đồng hành dài hạn.

### 14.7. Bảng giảng chung của Tutor và người học

- Tutor có công cụ có cấu trúc để viết/vẽ/đánh dấu/nối ý, liên hệ code với kết quả và
  đổi ví dụ khi trẻ chưa hiểu; không chỉ gửi một đoạn văn hoặc ảnh minh họa tĩnh.
- Bảng chia lớp nội dung bài, nét của Tutor và nét/ghi chú của người học. Tutor không
  được xóa hoặc ghi đè việc trẻ đang làm; giữ state qua mở/đóng trợ giúp và retry.
- Có dừng, xem lại, đi từng bước và cách thao tác không cần vẽ/không cần bật mic.
  Voice nếu bật phải gắn đúng bước trình bày; barge-in/background hủy cue cũ an toàn.
- AI đề xuất kế hoạch bảng qua schema/allowlist được kiểm tra; không render mã/URL
  tùy ý, không tự chạy code hay quyết định điểm. Engine bài học là nguồn đáp án.
- Làng có mèo và vài NPC trẻ hư cấu đi chơi, ghé vào/ra nhà để tạo sự sống nhưng không
  cạnh tranh với Tutor, không chặn tương tác, tôn trọng reduced motion và lifecycle.
  Tutor có lời chào/gợi ý biến thể theo context, không lặp một câu hoặc nói liên tục.
  Hướng mở rộng là nhiều làng/đảo với bến thuyền và hải đồ, mỗi nơi có bản sắc riêng;
  không giả NPC là người chơi online hoặc chặn Tutor sau một chuyến đi bắt buộc.
- Thiết kế và mẫu tương tác: `docs/design/TUTOR_TEACHING_BOARD.md`, P03. Prototype
  scripted không đồng nghĩa đã tích hợp AI/voice hoặc qua kiểm nghiệm trẻ em.

---

## 15. Vòng lặp dài hạn — dễ bắt đầu, luôn có điều tiếp theo để khám phá

PyQuest học hỏi nguyên tắc sản phẩm từ các ứng dụng học tập có sức bền dài hạn: bắt đầu đơn giản, tạo mục tiêu ngắn dễ hiểu và mở ra con đường tiến bộ dài. Không sao chép máy móc cơ chế của sản phẩm khác; thiết kế vòng lặp phù hợp với game thế giới mở và trẻ em.

- **Mục tiêu ngắn:** mỗi lần vào game có một việc rõ ràng để làm: hoàn thành một màn, sửa một lỗi, thêm một bộ phận, đạt một kỷ lục hoặc hoàn thành một nhiệm vụ nhỏ.
- **Tiến trình dài:** bộ sưu tập, bản đồ, danh hiệu, tác phẩm sáng tạo và quan hệ với Tutor tạo lý do quay lại theo tuần/tháng/mùa.
- **Nội dung mới:** mini-game mới, Side Maps, thử thách theo mùa, bộ phận mới và đề thi mới mở rộng dần.
- **Tôn trọng thời gian nghỉ:** không streak ép buộc, không phạt khi vắng mặt, không thông báo gây áp lực.
- **Nhiều cách tiến bộ:** trẻ có thể theo đuổi học tập, sáng tạo, thi đấu, sưu tầm hoặc giao lưu; không bắt một con đường duy nhất.

---

## 16. Cộng đồng, bạn bè và quà tặng

### 16.1. Kết bạn và khám phá thành tích

- Người chơi có thể gửi/nhận lời mời kết bạn, xem hồ sơ được chia sẻ, danh hiệu, tác phẩm trưng bày và bộ sưu tập mà chủ hồ sơ cho phép người khác xem.
- Có thể thăm không gian/trang trưng bày của bạn bè, xem sản phẩm sáng tạo, để lại phản hồi được kiểm soát như lời khen hoặc biểu tượng cảm xúc.
- Kết bạn là tùy chọn. Không được bắt buộc phải có bạn hoặc tham gia cộng đồng để hoàn thành Main Quest hay tiếp cận kiến thức cốt lõi.
- Quyền riêng tư cần cho phép người chơi/phụ huynh kiểm soát ai có thể tìm, kết bạn, xem tác phẩm, gửi quà hoặc tương tác.

### 16.2. Đội nhóm và hoạt động xã hội

- Người chơi có thể lập/tham gia đội để cùng giải mê cung, xây dựng sản phẩm, hoàn thành nhiệm vụ, dự thi và tích lũy thành tích chung.
- Hiển thị đóng góp cá nhân và kết quả đội theo luật rõ ràng; có thể có danh hiệu cá nhân lẫn danh hiệu tập thể.
- Tạo lý do tương tác thực chất: thử thách sản phẩm của bạn, giải mê cung do bạn tạo, cùng hoàn thành dự án, tham gia sự kiện cuối tuần hoặc xem triển lãm cộng đồng.
- Tác phẩm do người chơi tạo có thể trở thành nội dung cho người chơi khác khám phá, trong phạm vi quyền riêng tư, kiểm duyệt và an toàn cho trẻ em.

### 16.3. Quà tặng mua được và danh hiệu xã hội

- Người chơi có thể tự nguyện mua quà trong cửa hàng bằng loại tiền tệ được quy định rồi gửi tặng bạn: hoa, hộp quà, thú cưng mini, pháo hoa, phụ kiện, vật phẩm trang trí hoặc quà theo dịp.
- Có thể tặng danh hiệu xã hội độc đáo, khung hồ sơ, hiệu ứng, thiệp hoặc vật phẩm kỷ niệm. Ví dụ chủ đề: bạn đồng hành, ngôi sao của làng, người truyền cảm hứng, bạn sáng tạo tuyệt vời. Tên và cách thể hiện chỉ là ví dụ, cần được thiết kế sau.
- Quà theo dịp có thể gắn với sinh nhật, ngày kết bạn, chiến thắng, hoàn thành dự án chung hoặc sự kiện theo mùa. Không dùng thông báo giả hoặc đồng hồ đếm ngược gây áp lực mua.
- Quà/danh hiệu xã hội phải phân biệt trực quan với danh hiệu chứng minh kỹ năng hoặc thành tích thi đấu. Mua quà không mua được thứ hạng, điểm thi đấu hay chứng nhận kỹ năng.
- Người nhận có thể xem quà và lời nhắn, lưu vật phẩm nếu phù hợp, hoặc từ chối/giới hạn quà theo thiết lập. Cần có biện pháp chống spam, quấy rối, giao dịch gian lận và gây áp lực tặng quà.
- Không biến quà tặng thành nghĩa vụ: không phạt khi không tặng/không đáp lễ, không bắt mua quà để hoàn thành nhiệm vụ hoặc được công nhận là bạn bè.

### 16.4. Người chơi tự tạo tranh, thiệp và quà

- Xưởng sáng tạo có thể cung cấp công cụ vẽ tranh, thiết kế thiệp, chọn màu/nền, dùng nhãn dán, viết lời chúc và tạo vật phẩm đơn giản để tặng người khác.
- Có thể mở rộng sang nhân vật, biểu tượng, huy hiệu, phụ kiện hoặc món quà tương tác do người chơi tự thiết kế; tùy khả năng sản phẩm, tác phẩm có thể được lưu vào bộ sưu tập của người nhận.
- Có thể có album kỷ niệm, lịch sử quà đã trao, thiệp sinh nhật, lời chúc chiến thắng, cảm ơn, động viên hoặc tác phẩm kỷ niệm của đội.
- Tác phẩm tự làm có thể miễn phí; quà mua sẵn là lựa chọn bổ sung, không thay thế ý nghĩa của món quà cá nhân.
- Về sau, người chơi có thể học cách làm thiệp chuyển động, thêm hiệu ứng, tạo nhân vật biết vẫy tay hoặc lập trình món quà tương tác. Đây là cơ hội nối sáng tạo xã hội với kiến thức lập trình, không bắt mọi hoạt động tặng quà trở thành bài học hay bài kiểm tra.

### 16.5. An toàn cộng đồng cho trẻ em

- Thiết kế theo độ tuổi và rà soát các yêu cầu pháp lý/nền tảng trước khi phát hành: quyền riêng tư, sự đồng ý của phụ huynh khi cần, giới hạn tin nhắn, kiểm soát nội dung do người dùng tạo, chặn/báo cáo, chống giả mạo và bảo vệ giao dịch.
- Không mặc định cho phép giao dịch điểm, danh hiệu thành tích hoặc tài khoản giữa người chơi. Mọi loại trao đổi phải có danh sách vật phẩm được phép, quy tắc rõ và biện pháp chống lừa đảo.
- Nội dung do người chơi tạo và lời nhắn phải có cơ chế báo cáo/kiểm duyệt phù hợp. Cần tránh để thông tin cá nhân hoặc nội dung không phù hợp xuất hiện công khai.
- Mọi mua hàng/quà tặng trả phí phải hiển thị rõ giá, vật phẩm nhận được và xác nhận trước giao dịch; cân nhắc kiểm soát của phụ huynh phù hợp với nhóm tuổi và thị trường.
- Những cơ chế cộng đồng này là tầm nhìn sản phẩm cần bảo toàn; thứ tự triển khai có thể chia giai đoạn, không được lặng lẽ xóa khỏi tầm nhìn chỉ vì phiên bản đầu chưa có.

---

### 16.6. Đến nhà nhau là tương tác thực chất

- Nhà/đất/đảo cá nhân là không gian chơi có vị trí, đồ vật và hoạt động; không chỉ hồ sơ có ảnh, lượt thích hoặc nút gửi quà.
- Có thể thiết kế tham quan khi chủ vắng và ghé chơi cùng chủ. Chế độ chủ vắng phải nói rõ không có chủ online; chế độ cùng chơi cần hiện diện và hành động đồng bộ thật, không giả người thật bằng NPC/timer.
- Những hoạt động chung có thể gồm thử mê cung tự tạo, làm thiệp, chơi với thú, khám phá một khu mới hoặc cùng trang trí vùng được cấp quyền. Không bắt buộc chat mở hay voice để tương tác có ý nghĩa.
- Quyền khách/chủ/cùng sửa, phiên vào-ra, mất mạng, xung đột chỉnh sửa, chặn giữa phiên và kiểm duyệt mọi nội dung chia sẻ phải đi cùng thiết kế thăm nhà. Lời mời tới chơi không tự biến toàn bộ nhà thành công khai.

### 16.7. Thú cưng thông minh và cơ hội dùng AI local

- Thú cưng có thể được mua, có tính cách, hành vi, hoạt động và vai trò trong nhà/đảo: chơi, khám phá, chào khách, phản ứng với đồ vật hoặc tham gia sản phẩm người chơi tạo. Giữ nhánh thú cơ bản và nội dung cốt lõi miễn phí; không giảm thú thông minh thành món trang trí hoặc chỉ một chatbot.
- Nghiên cứu AI chạy trên thiết bị để hiểu ý định, chọn phản ứng hoặc diễn đạt lời ngắn phù hợp tính cách; không mặc định mọi máy chạy được model sinh. Hành vi nền, di chuyển và hoạt ảnh vẫn hoạt động khi model chưa có, đang lỗi hoặc không được hỗ trợ.
- AI chỉ đề xuất trong hành động cho phép; engine/dịch vụ có thẩm quyền quyết định quyền vào nhà, thay đổi thế giới, giao dịch và kết quả thi đấu. Thú không tự mua đồ, mở đất, cấp quyền cho khách hoặc đọc dữ liệu riêng của khách.
- Ký ức chỉ dùng dữ liệu game cần thiết, có giới hạn và có thể xem/xóa/reset; không mặc định thu thập đời tư/hội thoại trẻ. Không gửi dữ liệu lên cloud âm thầm khi local lỗi; on-device AI không đồng nghĩa multiplayer và mọi dịch vụ đều offline.
- Không khiến thú chết/mất tình cảm vì trẻ nghỉ chơi, không dùng thú gây áp lực mua hay tạo quan hệ lệ thuộc. Khả năng ngôn ngữ, độ trễ, RAM, pin/nhiệt, license và an toàn phải được kiểm trên thiết bị mục tiêu trước khi hứa với người dùng.

Thiết kế chi tiết bổ sung: [P06B — nhà, đất, đảo và thú cưng](design/experience-blueprint/P06B_LIVING_HOMES_ISLANDS_PETS.md).
Đây là tầm nhìn sản phẩm được giữ lại, **chưa chứng minh đã triển khai multiplayer, mua thú hoặc local AI**.

---

## 17. Nguyên tắc tổng hợp không được làm mất khi cập nhật tài liệu

1. **Mỗi nhà là một tính năng độc lập; điểm và danh hiệu là cầu nối thành tích chung.**
2. **Người chơi có thể chơi theo sở thích và tiến bộ một mình; cộng đồng mở thêm lựa chọn chứ không phải điều kiện bắt buộc.**
3. **Điểm, danh hiệu thành tích, danh hiệu xã hội và quà tặng là những khái niệm khác nhau, dù có thể cùng xuất hiện trong hồ sơ.**
4. **Tặng quà là tự nguyện; tự vẽ tranh/thiệp và tự tạo quà phải được giữ như một phần của tầm nhìn sáng tạo.**
5. **Vòng lặp dài hạn phải kết hợp mục tiêu ngắn, tiến trình lâu dài, nội dung mới và sự tôn trọng thời gian nghỉ.**
6. **Tầm nhìn sản phẩm không đồng nghĩa roadmap phiên bản đầu.** Có thể triển khai từng phần, nhưng phải ghi rõ phần nào được giữ cho giai đoạn sau thay vì làm biến mất khỏi tài liệu.
7. **Nhà/đất/đảo có thể mở rộng, thăm nhà có hoạt động thật và thú cưng thông minh (có lựa chọn mua, nghiên cứu AI local) là những nhánh phải bảo toàn.** Không thay bằng trang hồ sơ, hình nền hoặc thoại scripted rồi coi đã hoàn thành.
8. Khi rà soát hoặc viết lại tài liệu PyQuest, phải đối chiếu cả các mục mới 9–12 của brief, không chỉ Arena/Creator League. Không tự ý loại bỏ các tính năng xã hội, sáng tạo, quà tặng hoặc vòng lặp dài hạn vì lý do thu gọn phạm vi kỹ thuật.

---

## 18. Làm sinh động hơn Duolingo

| Duolingo nhấn mạnh | PyQuest tạo trải nghiệm |
|---|---|
| Chuỗi ngày học | Thế giới thay đổi theo tiến trình, không phạt trẻ khi nghỉ |
| Mở khóa hoạt động | Điều kiện rõ ràng theo hoạt động/kiến thức cần thiết; không dùng XP/cấp độ toàn cục |
| Huy hiệu | Huy hiệu xuất hiện trong Nhà Thành Tích |
| Hoàn thành bài học | Nhân vật phản ứng, có hoạt ảnh và lời thoại riêng |
| Tiến trình theo khóa học | Bản đồ phiêu lưu, nhân vật, vùng đất có câu chuyện |
| Ôn tập kiến thức | Mini-game biến kỹ năng cũ thành thử thách mới |

**Lưu ý:** âm thanh, nhạc nền, hoạt ảnh nên bật/tắt được.
Hiệu ứng chiến thắng nhẹ và nhanh.

---

## 19. Điều PyQuest **không** làm

Để giữ định vị nhất quán, PyQuest chủ động **không**:

- Khóa bài học Python cơ bản sau paywall.
- Bắt trẻ xem quảng cáo để truy cập Main Map.
- Dùng streak và hình phạt để thúc trẻ quay lại mỗi ngày.
- Thưởng cho việc chơi lâu hoặc xem nhiều quảng cáo.
- Tuyên bố trẻ "đã tạo game Python thật" khi thực tế chỉ ghép khối.
- Gây áp lực mua Pro bằng thông báo khẩn cấp hoặc giới hạn giả tạo.
- Yêu cầu XP/cấp độ toàn cục để mở những hoạt động không liên quan.
- Bắt mọi trò chơi phải là bài học Python.
- Trở thành mạng xã hội (bảng tin, đăng bài, cơ chế gây áp lực tương tác).
- Dùng từ "bot" trong nội dung sản phẩm/giao diện người chơi.
- Giả mạo đối thủ do hệ thống điều khiển thành người thật.

---

## 20. Tóm tắt một câu

**PyQuest là một thế giới game nhiều nhánh, nơi trẻ chơi theo sở thích và
dần trở thành người sáng tạo**, bằng cách cho trẻ một thế giới đủ vui để ở lại,
nhiều nhánh để chọn,
một lộ trình đủ nhẹ để bắt đầu,
và một nhánh sáng tạo đủ thật để trẻ tin mình có thể tự làm nên trò chơi của riêng mình.

---

## Tài liệu liên quan

- [`GAME_DESIGN.md`](GAME_DESIGN.md) — luật chơi, năng lượng, mở khóa hoạt động và phần thưởng.
- [`TECHNICAL_ARCHITECTURE.md`](TECHNICAL_ARCHITECTURE.md) — runtime Python, module, lưu dữ liệu.
- [`ROADMAP.md`](ROADMAP.md) — giai đoạn triển khai và tiêu chí nghiệm thu.
- [`../README.md`](../README.md) — điểm vào dự án.
- [`ARENA_CREATOR_COMPETITION_BRIEF.md`](ARENA_CREATOR_COMPETITION_BRIEF.md) — nguồn bổ sung về Arena, Creator League và trải nghiệm thi đấu.

---

## 21. Trạng thái triển khai hiện tại và định hướng UI Direction V2

### 21.1. Snapshot source và giới hạn bằng chứng — a9bcdcf

Các mục dưới mô tả snapshot `a9bcdcf`, không tự cập nhật theo tip của nhánh CODE.
Có trong source:
- Main Map dạng bản đồ đảo với các địa điểm hoạt động: Main Quest, Robot Maze, Dragon Jump, Catch the Stars, Bug Hunter và Nhà Thành Tích.
- Main Quest là hoạt động học Python có lộ trình, mở khóa theo tiến trình (chặng 1 *Code Apprentice*: 12 bài, 64 bước).
- Energy hồi theo thời gian, daily quests, achievements (15 huy hiệu, 3 bí mật), màn tổng kết và Adventure Recap theo dữ liệu đã lưu.
- AI Tutor đủ ba tầng và luôn nói rõ câu trả lời đến từ tầng nào: trợ giảng ngoại tuyến soạn từ nội dung bài học, trợ giảng AI qua relay `/v1/chat/completions` (hạn mức câu hỏi/ngày, lịch sử trong bài, tự fallback khi lỗi), và giọng nói Gemini Live trong màn học.
- Transcript trợ giảng dùng một mô hình tin nhắn chung: mỗi dòng mang **vai** của người nói (trẻ hay nhân vật nào trả lời), câu gõ và câu nói được xử lý như nhau, một lượt chỉ một bong bóng, và trạng thái "đang nói / đang nghe / bị ngắt lời" lấy từ chính phiên giọng nói.

Chưa triển khai hoặc chưa có bằng chứng trong source hiện tại:
- Arena nhiều bộ môn, Creator Pro League, giải đồng đội.
- Side Maps trả phí, Pro đầy đủ, cộng đồng/quà tặng đầy đủ.
- Quảng cáo thưởng: năng lượng đã có, rewarded ads chưa có trong source.
- Giọng nói còn đường thử nghiệm có key nằm trong APK; r49 cho phép GitHub Actions build owner-test có key theo quyết định người dùng, CI thường vẫn keyless. Token/backend/quota hoãn cho lần thử nội bộ; chưa có production mediation hoặc device voice PASS mới. Xem [request r49](OWNER_TEST_BUILDS.md).

**Mốc nghiệm thu riêng:**010 board độc lập,014 locale service,015 root localization,
016 Settings đã được nhận trong phạm vi riêng. Run39051006962:406ordinary+10render;
APK sourcea9b đã build ở39052978443. Build thành công không thay device/user test.
011 mới được giao để nối hai authored examples vào lesson; không có cơ sở ghi bảng
AI/voice hoặc freehand đã triển khai toàn bài học. Nhà/đất/đảo, vật liệu/dự án xây,
visit thật, mua thú/local AI và UI thế giới mới chưa có trong APK này.


### 21.2. UI Direction V2

`docs/PyQuest_Reffrence_Images/PYQUEST_UI_DIRECTION_V2.svg` là tài liệu định hướng thiết kế, **không phải** giao diện đang chạy. 21 ảnh gốc trong `docs/PyQuest_Reffrence_Images/` và `docs/design/kai-lumi-character-reference.svg` đã có trong checkout làm nguồn nghiên cứu; không thay chuẩn2,5D r33 hoặc gate duyệt art.

Nguyên tắc áp dụng:
- **Ảnh gốc là nguồn tham khảo, không phải21 phong cách cùng được duyệt.** Theo chỉ đạo r33, ART_DIRECTION_2_5D là chuẩn mới xuyên mọi màn; chọn độ sâu, chất liệu và khả năng đọc phù hợp từ nguồn, không trộn pixel/flat/nhân vật thương mại. V2 là lịch sử nghiên cứu; hình mới phải thuộc cùng họ2,5D, chín hơn về phân cấp nhưng vẫn dành cho trẻ dưới12.
- UI V2 chưa được triển khai vào source; không mô tả mockup V2 như tính năng đã hoàn thành.
- Các asset ảnh tham khảo là tài liệu thiết kế, không phải asset runtime của app.
- Khi áp dụng V2 vào source, phải đánh giá từng màn hình hiện có, thiết kế chi tiết, triển khai, kiểm thử và xác nhận runtime.

### 21.3. Hướng thiết kế sau khi đồng bộ mở rộng

V2 và P03–P06C là nguồn nghiên cứu, không phải các app riêng cần ghép nguyên iframe.
[Thiết kế thống nhất](design/WORLD_EXPANSION_REDESIGN.md) thay cách xem làng như sáu
thumbnail: world hub, nhà/sân, dự án, sổ hành trình, hải đồ, visit/pets/Arena dùng cùng
điều hướng và ngôn ngữ hình ảnh. Không chờ AI/voice hoàn thiện mới đưa UI làng vào
app. Những gate bảo mật voice vẫn bắt buộc trước khi phát hành voice production.
