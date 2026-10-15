Dưới đây là bản sắp xếp lại toàn bộ ý tưởng thành một cấu trúc mạch lạc, đầy đủ, có thể dùng làm tài liệu định hướng dự án / prompt / kiến trúc sản phẩm.

---

# PYQUEST — TÀI LIỆU TỔNG HỢP Ý TƯỞNG

## 1. Định vị dự án

**Tên dự án:** PyQuest  
**Tagline:** Build Your Game. Rule Your World.  
**Tên repository đề xuất:** `pyquest-game-lab`

**Định vị:**  
PyQuest là game lập trình cho trẻ dưới 12 tuổi. Sản phẩm không bán cảm giác “học thêm” mà bán giấc mơ **tự tạo trò chơi**. Python là công cụ để trẻ làm được điều đó.

**Mục tiêu trải nghiệm:**  
Trẻ mở PyQuest vì thích chơi → ở lại vì tò mò → rồi tự hỏi: *“Mình có thể tự làm một game như thế này không?”*  
Đó là lúc ứng dụng chuyển từ game giải trí thành công cụ dạy lập trình thực sự.

---

## 2. Nguyên tắc thiết kế xuyên suốt

1. **Main Map miễn phí và đầy đủ cốt lõi.**  
   Tuyến học Python chính không bị khóa sau paywall. Trẻ không cần mua gì để học kiến thức cơ bản.

2. **Side Maps bán chiều sâu, không bán kiến thức cơ bản.**  
   Bản trả phí mở thế giới mới, cơ chế nâng cao, bộ sưu tập độc quyền — không cắt phần cốt lõi khỏi bản miễn phí.

3. **Năng lượng điều tiết nhịp chơi, không phải thanh trang trí.**  
   Mỗi hoạt động tiêu hao năng lượng theo quy tắc rõ ràng. Hiển thị số lượt / năng lượng còn lại.

4. **Quảng cáo thưởng là tự nguyện.**  
   Trẻ có thể nghỉ, chờ hồi năng lượng hoặc xem quảng cáo thưởng nếu đủ điều kiện. Không biến quảng cáo thành điều kiện bắt buộc để học kiến thức cơ bản.

5. **Nghỉ ngơi là một phần của game.**  
   Có hoạt ảnh nhân vật nghỉ, chăm sóc thú cưng, gợi ý vận động mắt. Không giả vờ quảng cáo đã phát nếu chưa phát.

6. **Không gây áp lực mua Pro.**  
   Pro có thể bỏ quảng cáo và mở quyền lợi đã công bố, nhưng không dùng thông báo đánh lừa hoặc tạo áp lực với trẻ.

7. **Tuân thủ chính sách trẻ em.**  
   Phải kiểm tra Google Play Families và chính sách mạng quảng cáo trước khi chốt cơ chế. Quảng cáo gọi là “nghỉ mắt” không tự động đồng nghĩa phù hợp với trẻ nhỏ.

8. **Nếu chạy trong Flutter, phải có cơ chế Python thật hoặc mô phỏng giới hạn rõ ràng.**  
   Không thể chỉ tô giao diện giống trình soạn code rồi tuyên bố trẻ đã tạo ra game Python thật.

---

## 3. Mô hình kinh doanh: hai vòng kiếm tiền

### Vòng 1 — Quảng cáo thưởng để chơi tiếp
- Trẻ hết năng lượng → có thể nghỉ chờ hồi hoặc xem quảng cáo thưởng.
- Xem xong, SDK xác nhận hợp lệ → cộng thêm năng lượng / lượt chơi.
- Quảng cáo vừa tạo doanh thu, vừa tạo quãng nghỉ giữa các phiên chơi.

### Vòng 2 — Mua Side Maps để mở rộng thế giới
- Người dùng trả tiền để mở từng bản đồ phụ.
- Side Maps chứa nội dung chuyên biệt, thử thách nâng cao, phần thưởng sưu tập độc quyền.
- Mua bản đồ là mua nội dung và quyền sưu tập, không phải mua khả năng học Python cơ bản.

### Pro — lựa chọn nâng cấp riêng
- Có thể bỏ quảng cáo thuộc phạm vi gói Pro.
- Mở một số quyền lợi bổ sung đã công bố rõ.
- Không khóa Main Quest sau Pro.

---

## 4. Cấu trúc thế giới game

### 4.1. Home Map
- Là điểm khởi đầu sống động, không phải màn hình danh sách bài học.
- Có các nhân vật dễ thương:
  - Robot tò mò.
  - Rồng con ham kho báu.
  - Mèo chuyên tìm lỗi code.
- Nhân vật nói câu ngắn, hài hước, liên quan đến nhiệm vụ tiếp theo.
- Nhạc nền nhẹ nhàng, du dương, dẫn dắt trẻ khám phá.
- Âm thanh tương tác tạo phản hồi mỗi lần chạm.
- Các mini-game là địa điểm trên bản đồ, có thể khám phá không theo thứ tự bài học.

### 4.2. Main Map — miễn phí
- Luôn có thể tiếp tục học.
- Tuyến học Python cốt lõi: từ `print()` đến biến, điều kiện, vòng lặp, danh sách, hàm và gỡ lỗi.
- Không cần mua để mở nút bài học chính.
- Không yêu cầu xem quảng cáo mới được truy cập bản đồ.
- Có nhiệm vụ, XP, thú cưng cơ bản và thành tựu học tập.

### 4.3. Side Maps — mua từng gói
- **Pygame Island:** tạo trò chơi 2D, kiến trúc game, nhiều màn phức tạp, dự án mở rộng.
- **AI Pet Trainer Isle:** xây logic chăm sóc, huấn luyện thú cưng, luật phản ứng, thử thách AI.
- **Bug Hunter Kingdom:** giải câu đố tìm lỗi.
- **Legendary Title Isles:** nhiệm vụ săn danh hiệu, huy hiệu, ngoại trang hiếm.

---

## 5. Vòng lặp gameplay & năng lượng

### Vòng lặp chính
1. **Chọn nhiệm vụ**  
   Bản đồ phiêu lưu · Thú cưng · Kho báu · Nhiệm vụ ngày.

2. **Học và chơi**  
   Bài học ngắn · Đấu cú pháp · Nhận XP · Thu thập phần thưởng.

3. **Năng lượng giảm**  
   Thông báo sắp hết năng lượng, cho trẻ biết còn bao nhiêu lượt chơi.

4. **Nghỉ rồi chơi tiếp**  
   - Năng lượng hồi theo thời gian.
   - Hoặc chờ nghỉ.
   - Hoặc xem quảng cáo thưởng nếu đủ điều kiện.

5. **Quay lại cuộc phiêu lưu**  
   Mở nhiệm vụ mới, nâng cấp thú cưng, săn huy hiệu và tiếp tục học Python.

### Quy tắc năng lượng
- Năng lượng là tài nguyên gameplay thực sự.
- Mỗi hoạt động tiêu hao theo quy tắc rõ ràng.
- Hiển thị số lượt hoặc năng lượng còn lại.
- Hết năng lượng không đồng nghĩa hết quyền học.
- Trẻ có thể nghỉ, chờ hồi hoặc chọn quảng cáo thưởng nếu được phép.
- Không biến việc xem quảng cáo thành điều kiện bắt buộc để tiếp tục học kiến thức cơ bản.
- Quảng cáo phải có phần thưởng rõ ràng: ví dụ xem một quảng cáo được chấp thuận để nhận thêm năng lượng hoặc một lượt chơi.
- Chỉ cộng thưởng sau khi SDK xác nhận quảng cáo hoàn thành hợp lệ.
- Trong lúc chờ hồi năng lượng, trẻ vẫn có thể:
  - Xem lại bài cũ.
  - Đọc truyện Python.
  - Xem bộ sưu tập.
  - Luyện tập miễn phí không tiêu hao năng lượng.

---

## 6. Main Quest — lộ trình học miễn phí

Main Quest phải đủ nội dung để trẻ thực sự biết lập trình, kể cả tự làm game đơn giản.

### Chặng 1 — Code Apprentice
- In chữ, biến, số, chuỗi, phép toán và điều kiện.
- Điều khiển nhân vật bằng các lệnh Python đầu tiên.

### Chặng 2 — Game Builder
- Vòng lặp, hàm, danh sách, nhập liệu.
- Tọa độ, điểm số, mạng sống, điều kiện thắng thua.

### Chặng 3 — Game Creator
- Kết hợp kiến thức để tự xây game hoàn chỉnh:
  - Nhân vật.
  - Chướng ngại vật.
  - Va chạm.
  - Điểm thưởng.
  - Nhiều màn.
  - Xử lý lỗi.

### Chặng 4 — Game Master
- Dự án cuối tuyến miễn phí.
- Hoàn thiện một game có thể chơi lại.
- Lưu thành tích.
- Nhận danh hiệu **Game Creator**.

---

## 7. Mini-game dựng sẵn

Mỗi mini-game vừa giải trí, vừa dạy tư duy lập trình mà không gây cảm giác “đang học bài”. Mỗi game liên kết với một kiến thức Python để sau này trẻ có thể tự tạo game của mình.

### 7.1. Robot Maze — Dẫn đường cho robot
- Trẻ chọn lệnh lên, xuống, trái, phải để đưa robot đến kho báu.
- Màn sau dùng chuỗi lệnh để giải mê cung.
- **Tư duy:** thứ tự lệnh, thuật toán, hàm, vòng lặp.

### 7.2. Dragon Jump — Rồng con nhảy nhót
- Điều khiển rồng nhảy qua chướng ngại vật, nhặt xu, tránh bẫy.
- **Tư duy:** sự kiện, điều kiện, điểm số, trạng thái game.

### 7.3. Catch the Stars — Hứng sao
- Di chuyển chiếc giỏ để hứng sao và tránh vật cản.
- Có bảng điểm và thử thách thành tích.
- **Tư duy:** biến, tọa độ, vòng lặp, bộ đếm.

### 7.4. Bug Hunter — Thợ săn lỗi
- Tìm lệnh sai, sửa thứ tự khối lệnh, giúp nhân vật hoàn thành nhiệm vụ.
- Mỗi lỗi được giải thích bằng ngôn ngữ dễ hiểu.
- **Tư duy:** cú pháp, logic, gỡ lỗi.

### 7.5. Pet Lab — Phòng thí nghiệm thú cưng
- Cho thú cưng ăn, chơi, nghỉ ngơi.
- Thử tạo quy tắc phản ứng của riêng mình.
- **Tư duy:** điều kiện, trạng thái, hàm, thiết kế hành vi.

### Hai chế độ trong mỗi mini-game
- **Play Mode — Chơi giải trí:**  
  Vào game ngay, không bắt buộc đọc bài học hay viết code. Có điểm số, nhiệm vụ, âm thanh, hiệu ứng và thành tích cá nhân.

- **Creator Mode — Tìm hiểu cách tạo game:**  
  Trẻ xem game hoạt động ra sao, thay đổi quy tắc hoặc ghép khối lệnh. Sau đó dần chuyển sang viết Python thật để điều khiển nhân vật và xây dựng trò chơi.

### Cách đưa mini-game vào Home Map
- Nhân vật rủ trẻ chơi: *“Robot của tớ bị lạc rồi, giúp tớ nhé!”*
- Mỗi mini-game là một địa điểm trên bản đồ.
- Chơi game nhận XP, huy hiệu, vật phẩm trang trí.
- Phần thưởng học tập lớn hơn dành cho thử thách lập trình.
- Một số game tiêu hao năng lượng; hết năng lượng có thể nghỉ chờ hoặc xem quảng cáo thưởng nếu đủ điều kiện.

---

## 8. Side Maps trả phí — bán gì?

Main Quest đủ kiến thức Python cơ bản và đủ kỹ năng để tạo một game đơn giản hoàn chỉnh. Side Maps bán chiều sâu, trải nghiệm mới và phần thưởng độc quyền.

- **Pygame Island:** game nâng cao, kiến trúc game, nhiều màn phức tạp, dự án mở rộng.
- **AI Pet Trainer Isle:** xây hành vi thú cưng, luật phản ứng, thử thách AI.
- **Bug Hunter Kingdom:** câu đố tìm lỗi.
- **Legendary Title Isles:** săn danh hiệu, huy hiệu, ngoại trang hiếm, thử thách chuyên biệt.

### Luồng mở khóa Side Map
1. **Side Map Shop:** xem bản đồ, nội dung, phần thưởng và giá.
2. **Xác nhận mua hàng.**
3. **Xử lý bằng hệ thống thanh toán của nền tảng khi tích hợp thực tế.**
4. **Mở Side Map đã mua.**
5. **Lưu quyền sở hữu và khôi phục giao dịch khi cần.**

---

## 9. Bảng phân quyền Free / Mua gói / Pro

| Tính năng | Miễn phí | Mua gói / Pro |
|---|---|---|
| Main Map | Toàn bộ tuyến học cốt lõi | Không cần mua |
| Năng lượng | Hồi theo thời gian, có thể xem quảng cáo thưởng nếu đủ điều kiện | Có thể có quyền lợi bổ sung được công bố rõ |
| Bài học chính | Luôn truy cập được | Không khóa sau paywall |
| Side Maps | Xem trước nội dung và giá | Mở từng bản đồ đã mua |
| Danh hiệu, huy hiệu đặc biệt | Có phần thưởng miễn phí | Có bộ sưu tập độc quyền từ nhiệm vụ trả phí |
| Bỏ quảng cáo | Có quảng cáo ở vị trí được phép | Pro bỏ các quảng cáo thuộc phạm vi gói Pro |

---

## 10. Quy tắc quảng cáo & trẻ em

- Phân biệt rõ **quảng cáo thưởng tự nguyện** với **quảng cáo bắt buộc**.
- Tuân thủ chính sách quảng cáo dành cho trẻ em của nền tảng.
- Kiểm tra chính sách hiện hành của **Google Play Families** và mạng quảng cáo định dùng trước khi chốt cơ chế.
- Việc một quảng cáo được gọi là “nghỉ mắt” không tự động khiến quảng cáo bắt buộc phù hợp với ứng dụng dành cho trẻ nhỏ.
- Không hiển thị quảng cáo sai lệch, gây nhầm lẫn hoặc tạo áp lực mua.
- Chỉ cộng thưởng sau khi có xác nhận hợp lệ từ SDK.

---

## 11. Yêu cầu kỹ thuật quan trọng

- Nếu game chạy bên trong ứng dụng Flutter, phải xây một cơ chế **thực thi hoặc mô phỏng Python** được giới hạn rõ ràng.
- Không thể chỉ tô giao diện giống trình soạn code rồi tuyên bố trẻ đã tạo ra game Python thật.
- Cần lưu quyền sở hữu Side Map, khôi phục giao dịch, đồng bộ tiến trình học và thành tích.
- Cần hệ thống năng lượng, quảng cáo thưởng, XP, huy hiệu, bộ sưu tập và nhiệm vụ ngày.

---

## 12. Chốt định hướng

**PyQuest — biến trẻ từ người chơi thành người sáng tạo game.**

- **Main Map:** miễn phí, đầy đủ kiến thức Python cơ bản và kỹ năng tạo game đơn giản.
- **Năng lượng:** điều tiết nhịp chơi, có nghỉ ngơi và hồi theo thời gian.
- **Quảng cáo thưởng:** tạo doanh thu, nhưng tự nguyện và có kiểm soát.
- **Side Maps:** bán chiều sâu, trải nghiệm mới và bộ sưu tập độc quyền.
- **Pro:** lựa chọn nâng cấp riêng, không khóa tuyến học chính.
- **Home Map:** nhân vật dễ thương, thoại thú vị, nhạc du dương, âm thanh tương tác.
- **Mini-game:** vừa chơi giải trí, vừa dẫn trẻ vào tư duy lập trình qua Play Mode và Creator Mode.
- **Nguyên tắc cuối:** trẻ mở vì thích chơi, ở lại vì tò mò, rồi tự hỏi mình có thể tự làm game như thế không.
Dưới đây là bản sắp xếp đầy đủ, tiếp nối tài liệu tổng hợp trước, bổ sung toàn bộ nội dung mới trong file: đánh giá README, kiến trúc module, roadmap, Nhà Thành Tích, màn tổng kết, Adventure Recap, và hướng dẫn xử lý ảnh.

---

# PYQUEST — TÀI LIỆU TỔNG HỢP Ý TƯỞNG (PHẦN 2)

## 13. Đánh giá README hiện tại trên repo

**Repo:** `https://github.com/Nthanhbadboy/PyQuest` (đang ở chế độ Private)

### 13.1. Phần đã tốt
- Định vị PyQuest: chơi game để học cách tự tạo game.
- Main Quest miễn phí, đủ kiến thức Python cơ bản và làm game đơn giản.
- Side Maps bán nội dung mở rộng và danh hiệu độc quyền.
- Vòng lặp năng lượng, quảng cáo thưởng và hồi năng lượng.
- Home Map có nhân vật, nhạc nền, mini-game và hai chế độ Play/Creator.
- Có nhận thức về quyền riêng tư và chính sách dành cho trẻ em.

### 13.2. Phần cần sửa
- Tài liệu dài, lặp lại ý tưởng ở nhiều mục.
- Tên repository trong README là `pyquest-game-lab`, trong khi repo thực tế đã là `PyQuest`.
- Chưa phân biệt rõ tính năng nào thuộc phiên bản đầu tiên, tính năng nào là kế hoạch tương lai.
- Chưa xác định cách chạy Python thật hoặc giới hạn của cơ chế mô phỏng.
- Chưa có hướng dẫn chạy dự án, kiểm thử và cấu trúc code thực tế.
- Một số quyết định quan trọng như cách tính năng lượng, thời gian hồi, XP và điều kiện nhận thưởng vẫn chưa có quy tắc định lượng.

### 13.3. Cấu trúc file đề xuất

| File | Vai trò |
|---|---|
| `README.md` | Giới thiệu PyQuest, tính năng chính, trạng thái dự án và cách chạy |
| `docs/PRODUCT_VISION.md` | Toàn bộ ý tưởng sản phẩm, Home Map, nhân vật, âm thanh, Main Quest, Side Maps và mô hình doanh thu |
| `docs/GAME_DESIGN.md` | Vòng lặp gameplay, năng lượng, XP, mini-game, phần thưởng và cân bằng độ khó |
| `docs/TECHNICAL_ARCHITECTURE.md` | Flutter, thực thi Python, lưu tiến độ, dịch vụ, quảng cáo và thanh toán |
| `docs/ROADMAP.md` | Các giai đoạn triển khai, tiêu chí hoàn thành và kiểm thử |

### 13.4. Nguyên tắc tài liệu
- Tài liệu sản phẩm xác định **ta đang xây trò chơi gì**.
- Tài liệu kỹ thuật xác định **xây bằng cách nào**.
- Roadmap xác định **làm gì trước và kiểm tra bằng gì**.
- Không để AI đọc một tài liệu dài rồi tự quyết định toàn bộ kiến trúc.

**Bước tiếp theo hợp lý:** chỉnh README ngắn gọn, giữ nguyên các ý tưởng sản phẩm trong tài liệu riêng, rồi mới bắt đầu code.

---

## 14. So sánh độ phức tạp với Simple Calendar

| Tiêu chí | Simple Calendar | PyQuest |
|---|---|---|
| Nghiệp vụ | Lịch, Task, Customer, Stops, thời gian, giá tiền… | Bài học, trò chơi, tiến trình học |
| Quan hệ dữ liệu | Nhiều thực thể liên kết, sửa một chỗ ảnh hưởng chỗ khác | Có thể tách dữ liệu từng trò chơi và từng bản đồ |
| Giao diện | Nhiều màn hình dùng chung trạng thái | Mỗi màn chơi có thể đóng gói độc lập |
| Kiểm thử | Dễ phát sinh lỗi dây chuyền | Có thể nghiệm thu từng trò chơi |
| Độ khó lớn nhất | Nghiệp vụ và trạng thái phức tạp | Chạy Python an toàn, nội dung giáo dục, quảng cáo và thanh toán |

**Kết luận:** PyQuest dễ kiểm soát hơn nếu thiết kế kiến trúc ngay từ đầu. Gameplay và nội dung có thể chia nhỏ, hoàn thành và kiểm thử từng phần. Nhưng quảng cáo, thanh toán và lưu tiến trình vẫn cần thiết kế cẩn thận.

---

## 15. Kiến trúc theo module

```
PyQuest App Core
├── Điều hướng
├── Hồ sơ cục bộ
├── Ngôn ngữ
└── Âm thanh

Main Quest
└── Bài học Python và tiến trình (module riêng)

Mini-games
└── Robot Maze, Dragon Jump… (module riêng)

Energy & Ads
└── Năng lượng và quảng cáo thưởng (module riêng)

Side Maps & Pro
└── Bản đồ mở rộng và mua hàng (module riêng)
```

Các module giao tiếp qua những **interface rõ ràng**, thay vì gọi trực tiếp lẫn nhau tùy tiện.

---

## 16. Database — tách theo module logic

Không nhất thiết phải tạo nhiều file database SQLite ngay từ đầu. Đề xuất tách theo module logic:

| Module | Dữ liệu sở hữu |
|---|---|
| **Progress** | Bài học đã hoàn thành, XP, huy hiệu |
| **Games** | Điểm cao, màn đã mở khóa, thành tích |
| **Energy** | Năng lượng hiện tại và thời điểm hồi phục |
| **Purchases** | Trạng thái quyền sở hữu bản đồ và Pro |
| **Settings** | Ngôn ngữ, âm thanh, nhạc nền |

Mỗi module sở hữu dữ liệu và API của mình. Ban đầu có thể dùng các file JSON riêng hoặc các bảng SQLite riêng trong một database; khi cần mới chuyển sang database vật lý riêng.

**Lưu ý quan trọng:** quyền mua hàng không nên chỉ dựa vào một file cục bộ có thể chỉnh sửa; cần xác minh giao dịch qua cơ chế thanh toán của nền tảng.

---

## 17. Roadmap — chia việc theo nguyên tắc "xong mục nào, khóa mục đó"

1. **Foundation:** khung Flutter, điều hướng, lưu dữ liệu và giao diện cơ bản.
2. **Home Map:** thế giới chính, nhân vật, âm thanh.
3. **Một mini-game hoàn chỉnh:** gameplay, điểm số, lưu kỷ lục và Creator Mode.
4. **Main Quest:** bài học Python, bài tập và lưu tiến trình.
5. **Python runtime:** thực thi mã an toàn, giới hạn tài nguyên và xử lý lỗi.
6. **Energy & Ads:** hồi năng lượng và quảng cáo thưởng.
7. **Side Maps & Pro:** nội dung mở rộng và mua hàng.
8. **Hoàn thiện:** localization, accessibility, kiểm thử, build và phát hành.

Mỗi mục có tiêu chí nghiệm thu, test riêng và chỉ chuyển sang mục kế tiếp khi đạt yêu cầu. Những module đã ổn định không bị sửa chỉ vì thêm một trò chơi mới, trừ khi có thay đổi hợp đồng giao tiếp được kiểm soát.

### Nguyên tắc chốt từ đầu
**Đừng xây cả thế giới PyQuest ngay lập tức.**  
Hãy làm một **lát cắt dọc hoàn chỉnh**: mở app → vào một trò chơi → chơi được → lưu kết quả → thoát ra mở lại vẫn còn kết quả.  
Khi lát cắt đó chạy ổn, phần còn lại chủ yếu là mở rộng theo module, thay vì liên tục chữa lỗi kiến trúc.

---

## 18. Nhà Thành Tích — Hall of Achievements

Đây không chỉ là trang chứa huy hiệu. Nó là một **căn nhà trong thế giới PyQuest**, nơi mỗi thành tựu của trẻ được lưu lại và trưng bày.

### 18.1. Thành phần
- **Tủ huy hiệu:** mỗi huy hiệu đại diện cho một cột mốc, từ hoàn thành bài Python đầu tiên đến tự tạo trò chơi.
- **Tường chiến tích:** thống kê số màn đã vượt qua, số trò chơi đã hoàn thành và số thế giới đã khám phá.
- **Bộ sưu tập nhân vật:** mở khóa trang phục, phụ kiện và hiệu ứng cho nhân vật đồng hành.
- **Góc sáng tạo:** trưng bày các trò chơi do trẻ tự xây dựng.
- **Huy hiệu bí mật:** thưởng cho những khám phá thú vị, cách giải khác nhau hoặc phát hiện lỗi khó.

### 18.2. Nguyên tắc thưởng
Phần thưởng phải phản ánh **nỗ lực và sự tiến bộ**, chứ không chỉ thưởng cho việc chơi thật lâu hoặc xem thật nhiều quảng cáo.

---

## 19. Màn tổng kết sau mỗi màn chơi

Mỗi màn kết thúc bằng một đoạn tổng kết ngắn, sinh động và có nội dung riêng, không phải màn hình hiện mỗi dòng "Level Complete".

### 19.1. Ví dụ minh họa

> **Tuyệt vời! Bạn đã vượt mê cung!**  
> Robot Maze · Màn 5
>
> Bạn đã giúp Robo tìm đúng đường về nhà. Những lệnh bạn chọn chính là chìa khóa!
>
> | 12 | 8 | 1 |
> |---|---|---|
> | Màn đã vượt qua | Ngôi sao nhận được | Kỹ năng mới |
>
> **Kỹ năng vừa khám phá:**  
> Bạn đã sử dụng thứ tự các lệnh để điều khiển robot. Đó chính là tư duy thuật toán!
>
> **Robo:** "Tuyệt! Thêm một nhà thám hiểm lập trình tài ba!"

*Đây là minh họa cho trải nghiệm, chưa phải màn hình đã được triển khai.*

### 19.2. Ba nguyên tắc cho màn tổng kết
1. **Ghi nhận thành tựu cụ thể:** trẻ vừa học được gì, đã vượt qua bao nhiêu thử thách.
2. **Khích lệ không gây áp lực:** không làm trẻ thấy mình kém cỏi nếu chưa thắng; có lời động viên và gợi ý thử lại.
3. **Thay đổi theo hành trình:** nhân vật, lời thoại, hiệu ứng và phần thưởng phải đa dạng, tránh lặp lại một mẫu ở mọi màn.

---

## 20. Adventure Recap — Bức tranh tổng kết toàn bộ hành trình

Ngoài tổng kết sau mỗi màn, khi trẻ hoàn thành một chặng lớn, PyQuest tạo một **Adventure Recap** — bản tổng kết cuộc phiêu lưu.

### 20.1. Ví dụ báo cáo tổng kết một chặng

> **Cuộc phiêu lưu của bạn**
>
> | 25 | 5 | 8 | 3 |
> |---|---|---|---|
> | Màn đã hoàn thành | Trò chơi đã chinh phục | Kỹ năng Python đã học | Huy hiệu đã mở khóa |
>
> **Lời nhắn của người hướng dẫn:**  
> "Bạn đã đi từ những dòng lệnh đầu tiên đến việc tự điều khiển nhân vật trong trò chơi. Bạn không chỉ vượt màn — bạn đang học cách tạo ra thế giới của riêng mình."

*Số liệu trên chỉ là ví dụ minh họa. Trong ứng dụng thật, mọi con số phải lấy từ tiến trình đã lưu, không được viết cố định.*

---

## 21. Làm sinh động hơn Duolingo bằng cách nào?

| Duolingo thường nhấn mạnh | PyQuest nên tạo trải nghiệm |
|---|---|
| Chuỗi ngày học | Thế giới thay đổi theo tiến trình, không phạt trẻ khi nghỉ |
| XP và cấp độ | XP kết hợp kỹ năng lập trình đã thực sự nắm được |
| Huy hiệu | Huy hiệu xuất hiện trong Nhà Thành Tích |
| Hoàn thành bài học | Nhân vật phản ứng, có hoạt ảnh và lời thoại riêng |
| Tiến trình theo khóa học | Bản đồ phiêu lưu, nhân vật và các vùng đất có câu chuyện |
| Ôn tập kiến thức | Mini-game biến kỹ năng cũ thành thử thách mới |

**Lưu ý:** Âm thanh, nhạc nền và hoạt ảnh nên có thể bật/tắt. Hiệu ứng chiến thắng cần nhẹ và nhanh, không làm trẻ phải xem màn hình chờ dài sau mỗi bài.

---

## 22. Tách module cho hệ thống thành tích

Để tính năng này không làm dự án rối lên, tách thành **ba module độc lập**:

1. **`achievement_engine`:** xác định điều kiện mở khóa huy hiệu và thành tích.
2. **`progress_tracker`:** ghi nhận màn đã hoàn thành, trò chơi, kỹ năng và chặng học.
3. **`achievement_house`:** giao diện căn nhà, bộ sưu tập, hoạt ảnh và tổng kết.

### Luồng hoạt động
- Các trò chơi chỉ gửi **sự kiện chuẩn hóa**, chẳng hạn `level_completed`, `game_completed` hoặc `skill_mastered`.
- Hệ thống tiến trình lưu sự kiện và tính thành tích.
- Nhà Thành Tích chỉ đọc dữ liệu để hiển thị.

Nhờ vậy, thêm trò chơi mới không phải viết lại toàn bộ hệ thống huy hiệu.

### Thứ tự triển khai
Đưa Nhà Thành Tích và màn tổng kết vào **thiết kế nền tảng ngay từ đầu**, nhưng chỉ triển khai giao diện đầy đủ **sau khi đã có một mini-game mẫu chạy hoàn chỉnh**. Như thế ta kiểm tra được cả vòng đời:

> chơi → ghi nhận tiến trình → trao thành tích → xem tổng kết → quay lại thế giới phiêu lưu.

---

## 23. Xử lý hình ảnh trong phiên chat

### 23.1. Phân biệt hai loại ảnh
- **Ảnh AI tạo ra:** xuất hiện trong mục Images của ChatGPT.
- **Ảnh tham khảo:** lấy từ kết quả tìm kiếm, không mặc nhiên có giấy phép sử dụng thương mại.

### 23.2. Cách tải ảnh AI tạo ra
1. Truy cập **ChatGPT Images** bằng tài khoản đang dùng.
2. Mở ảnh cần lấy, nhấn **Save**.
3. Chọn thư mục đích trên máy tính nếu trình duyệt hỏi.

*Lưu ý:* Thư viện Images không đảm bảo chứa toàn bộ ảnh đã xuất hiện trong cuộc trò chuyện.

### 23.3. Cách tải ảnh tham khảo
1. Quay lại câu trả lời có ảnh trong cuộc trò chuyện.
2. Nhấp vào ảnh để mở lớn nếu giao diện hỗ trợ.
3. Nhấp chuột phải, chọn **Save image as…**
4. Lưu vào thư mục `D:\PyQuest_Images\References`.
5. Lặp lại với từng ảnh.

Nếu trình duyệt không hiện tùy chọn lưu, thử mở ảnh trong tab mới. Nếu vẫn không được, dùng đường dẫn nguồn của ảnh để tải từ trang gốc.

### 23.4. Tạo thư mục quản lý ảnh

Trên Windows, mở PowerShell và chạy:

```powershell
New-Item -ItemType Directory -Force -Path `
  "D:\PyQuest_Images\AI_Generated", `
  "D:\PyQuest_Images\References"
```

Sau đó phân loại:
- **AI_Generated:** ảnh AI thực sự được tạo trong ChatGPT.
- **References:** ảnh tham khảo từ kết quả tìm kiếm.

Đặt tên file theo nội dung, ví dụ: `achievement_house.png`, `robot_maze.png`, `dragon_jump.png`.

### 23.5. Lưu ý quan trọng
- Chưa xác minh được danh sách file gốc và số lượng ảnh trong toàn bộ phiên chat.
- Không thể cung cấp lệnh PowerShell bảo đảm tự động tải đủ tất cả ảnh lịch sử.
- Việc lưu thủ công là phương án chắc chắn hơn khi chưa có danh sách URL hoặc file ảnh nguồn.
- **Giữ riêng ảnh tham khảo với ảnh được phép sử dụng trong sản phẩm phát hành.** Ảnh tìm kiếm trên mạng không mặc nhiên có giấy phép sử dụng thương mại.

---

## 24. Tổng kết định hướng mở rộng

### Đã chốt
- **PyQuest** — biến trẻ từ người chơi thành người sáng tạo game.
- **Main Map miễn phí**, đầy đủ kiến thức Python cơ bản và kỹ năng tạo game đơn giản.
- **Năng lượng** điều tiết nhịp chơi, có nghỉ ngơi và hồi theo thời gian.
- **Quảng cáo thưởng** tự nguyện, có kiểm soát.
- **Side Maps** bán chiều sâu, trải nghiệm mới và bộ sưu tập độc quyền.
- **Pro** là lựa chọn nâng cấp riêng, không khóa tuyến học chính.
- **Home Map** có nhân vật dễ thương, thoại thú vị, nhạc du dương, âm thanh tương tác.
- **Mini-game** có Play Mode và Creator Mode.
- **Nhà Thành Tích** và **màn tổng kết** là phần thiết kế nền tảng, triển khai giao diện sau khi có mini-game mẫu.
- **Adventure Recap** tổng kết hành trình theo chặng.
- **Kiến trúc module** tách biệt: Core, Main Quest, Mini-games, Energy & Ads, Side Maps & Pro, Achievement.
- **Database** tách theo module logic: Progress, Games, Energy, Purchases, Settings.
- **Roadmap** chia theo giai đoạn, mỗi mục có tiêu chí nghiệm thu riêng.

### Nguyên tắc cuối cùng
> Trẻ mở PyQuest vì thích chơi, ở lại vì tò mò, rồi tự hỏi:  
> **"Mình có thể tự làm một game như thế này không?"**  
> Đó là lúc ứng dụng chuyển từ game giải trí thành công cụ dạy lập trình thực sự.

### Việc cần làm tiếp theo
1. Chỉnh README ngắn gọn, đúng tên repo `PyQuest`.
2. Tách tài liệu sản phẩm sang `docs/PRODUCT_VISION.md`.
3. Viết `docs/GAME_DESIGN.md` với quy tắc định lượng: năng lượng, thời gian hồi, XP, điều kiện nhận thưởng.
4. Viết `docs/TECHNICAL_ARCHITECTURE.md` với quyết định về Python runtime, Flutter, lưu tiến trình, quảng cáo và thanh toán.
5. Viết `docs/ROADMAP.md` với tiêu chí nghiệm thu từng giai đoạn.
6. Bắt đầu bằng **lát cắt dọc hoàn chỉnh**: mở app → chơi một mini-game → lưu kết quả → mở lại vẫn còn.
