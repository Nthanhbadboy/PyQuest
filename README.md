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
