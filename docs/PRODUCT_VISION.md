# PyQuest — Product Vision

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
| **Thể loại** | Game phiêu lưu + công cụ học lập trình |

**Định vị cốt lõi:**
PyQuest **không bán cảm giác "học thêm"**. PyQuest bán giấc mơ
**tự tạo ra trò chơi của chính mình**. Python chỉ là công cụ để trẻ làm được điều đó.

**Mục tiêu trải nghiệm:**
Trẻ mở PyQuest vì thích chơi → ở lại vì tò mò → tự hỏi
*"Mình có thể tự làm một game như thế này không?"*
Đó là lúc ứng dụng chuyển từ game giải trí thành công cụ dạy lập trình thực sự.

---

## Thuật ngữ cốt lõi (dùng thống nhất toàn bộ tài liệu)

Các khái niệm dưới đây **không** được dùng thay thế cho nhau. Khi một tài liệu
khác dùng thuật ngữ này, nghĩa phải đúng như bảng sau.

| Thuật ngữ | Định nghĩa |
|---|---|
| **Home Map** | Khu vực khởi đầu chào đón trẻ: một thế giới có nhân vật, thoại, âm thanh — **không** phải màn hình danh sách bài học. Là điểm vào của mọi luồng chơi. |
| **Main Map** | **Bản đồ trung tâm miễn phí để khám phá, chọn và mở các hoạt động** như Main Quest, mini-game và địa điểm khám phá. Main Map là điểm điều hướng, không phải hệ thống XP/cấp độ và không bị khóa sau paywall. |
| **Main Quest** | **Lộ trình học Python có cấu trúc, miễn phí** nằm trong Main Map (chặng 1–4). Main Quest là nội dung học; Main Map là thế giới chứa nó. Hai khái niệm **khác nhau**. |
| **Mini-game Play Mode** | Chế độ chơi mini-game ngay, **không** bắt buộc đọc bài hay viết code trước. |
| **Mini-game Creator Mode** | Chế độ xem/đổi luật chơi và dần học lập trình qua chính mini-game đó (xem mục 7.1). |
| **Side Maps** | Bản đồ mở rộng **trả phí tùy chọn**, bổ sung chiều sâu — **không** bán quyền truy cập kiến thức Python cơ bản. |
| **Nhà Thành Tích** (Achievement House) | **Một địa điểm vật lý trong thế giới PyQuest** trưng bày huy hiệu, chiến tích, bộ sưu tập và game do trẻ tạo. |
| **Adventure Recap** | Bản tổng kết **dựa trên dữ liệu thật** về các hoạt động đã hoàn thành và kỹ năng mới học được (không viết cố định). |

> **Lưu ý.** Trước đây tài liệu từng dùng "Main Map" để chỉ chính tuyến học.
> Cách hiểu đúng từ nay: **Main Map = thế giới miễn phí**, **Main Quest = tuyến học trong đó**.

---

## 2. Triết lý thiết kế

Tám nguyên tắc dưới đây chi phối **mọi quyết định** về sản phẩm, từ nội dung
đến mô hình kinh doanh, từ giao diện đến cách viết thoại.

### 2.1. Main Map miễn phí và đầy đủ cốt lõi

Tuyến học Python cốt lõi và khả năng tạo game đơn giản **không bị khóa sau paywall**.
Trẻ không cần trả tiền để biết lập trình.

### 2.2. Side Maps bán chiều sâu, không bán lại kiến thức cơ bản

Bản đồ trả phí mở ra **chiều sâu, trải nghiệm mới, phần thưởng độc quyền** —
không bán lại những gì Main Map đã dạy.

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

## 4. Cấu trúc thế giới game

### 4.1. Home Map — điểm khởi đầu sống động

Home Map **không phải** màn hình danh sách bài học.
Đây là một thế giới có địa điểm, nhân vật, câu chuyện.

**Đặc điểm:**
- Nhân vật dễ thương: robot tò mò, rồng con ham kho báu, mèo tìm lỗi code.
- Thoại ngắn, hài hước, liên quan nhiệm vụ tiếp theo.
- Nhạc nền du dương, âm thanh tương tác phản hồi mỗi lần chạm.
- Mini-game là **địa điểm trên bản đồ**, khám phá không theo thứ tự.

### 4.2. Main Map — thế giới miễn phí cốt lõi

**Main Map là bản đồ trung tâm và điểm vào của các hoạt động PyQuest.** Người chơi nhìn thấy những địa điểm/game đang có, chọn hoạt động, xem điều kiện cần thiết và đi thẳng đến hoạt động đó. Bản đồ có thể được trình bày như một thế giới sống động, nhưng chức năng cốt lõi là **khám phá, điều hướng và mở hoạt động** — không phải tích XP hay tăng cấp.

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
- Toàn bộ kiến thức Python cơ bản và kỹ năng tạo game đơn giản nằm trong Main Map.

### 4.3. Side Maps — mua từng gói

| Side Map | Nội dung |
|---|---|
| **Pygame Island** | Game 2D nâng cao, kiến trúc game, dự án mở rộng. |
| **AI Pet Trainer Isle** | Hành vi thú cưng, luật phản ứng, thử thách AI. |
| **Bug Hunter Kingdom** | Câu đố tìm lỗi. |
| **Legendary Title Isles** | Săn danh hiệu, huy hiệu, ngoại trang hiếm. |

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

Mỗi mini-game vừa giải trí vừa dạy tư duy lập trình,
liên kết với một kiến thức Python để trẻ tự tạo game sau này.

| Mini-game | Cách chơi | Tư duy Python |
|---|---|---|
| **Robot Maze** | Chọn lệnh lên/xuống/trái/phải đưa robot đến kho báu | Thứ tự lệnh, thuật toán, hàm, vòng lặp |
| **Dragon Jump** | Điều khiển rồng nhảy qua chướng ngại vật, nhặt xu, tránh bẫy | Sự kiện, điều kiện, điểm số, trạng thái game |
| **Catch the Stars** | Di chuyển giỏ hứng sao, tránh vật cản | Biến, tọa độ, vòng lặp, bộ đếm |
| **Bug Hunter** | Tìm lệnh sai, sửa thứ tự khối lệnh | Cú pháp, logic, gỡ lỗi |
| **Pet Lab** | Cho thú cưng ăn/chơi/nghỉ, tạo quy tắc phản ứng | Điều kiện, trạng thái, hàm, thiết kế hành vi |

### 7.1. Hai chế độ trong mỗi mini-game

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
| Main Map (thế giới miễn phí, gồm Main Quest) | Toàn bộ thế giới và tuyến học cốt lõi | Không cần mua |
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

## 13. Làm sinh động hơn Duolingo

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

## 14. Điều PyQuest **không** làm

Để giữ định vị nhất quán, PyQuest chủ động **không**:

- Khóa bài học Python cơ bản sau paywall.
- Bắt trẻ xem quảng cáo để truy cập Main Map.
- Dùng streak và hình phạt để thúc trẻ quay lại mỗi ngày.
- Thưởng cho việc chơi lâu hoặc xem nhiều quảng cáo.
- Tuyên bố trẻ "đã tạo game Python thật" khi thực tế chỉ ghép khối.
- Gây áp lực mua Pro bằng thông báo khẩn cấp hoặc giới hạn giả tạo.

---

## 15. Tóm tắt một câu

**PyQuest biến trẻ từ người chơi thành người sáng tạo game**,
bằng cách cho trẻ một thế giới đủ vui để ở lại,
một lộ trình đủ nhẹ để bắt đầu,
và một công cụ đủ thật để trẻ tin mình có thể tự làm nên trò chơi của riêng mình.

---

## Tài liệu liên quan

- [`GAME_DESIGN.md`](GAME_DESIGN.md) — luật chơi, năng lượng, mở khóa hoạt động và phần thưởng.
- [`TECHNICAL_ARCHITECTURE.md`](TECHNICAL_ARCHITECTURE.md) — runtime Python, module, lưu dữ liệu.
- [`ROADMAP.md`](ROADMAP.md) — giai đoạn triển khai và tiêu chí nghiệm thu.
- [`../README.md`](../README.md) — điểm vào dự án.
