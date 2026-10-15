# PYQUEST — TÀI LIỆU TỔNG HỢP Ý TƯỞNG (BẢN TINH GỌN)

---

## 1. Định vị dự án

**Tên:** PyQuest  
**Tagline:** Build Your Game. Rule Your World.  
**Repository:** `PyQuest` (đang Private)

**Định vị:** Game lập trình cho trẻ dưới 12 tuổi. Không bán cảm giác "học thêm" mà bán giấc mơ **tự tạo trò chơi**. Python là công cụ để trẻ làm được điều đó.

**Mục tiêu trải nghiệm:**  
Trẻ mở PyQuest vì thích chơi → ở lại vì tò mò → tự hỏi *"Mình có thể tự làm một game như thế này không?"* — đó là lúc ứng dụng chuyển từ game giải trí thành công cụ dạy lập trình thực sự.

---

## 2. Nguyên tắc thiết kế xuyên suốt

1. **Main Map miễn phí và đầy đủ cốt lõi** — không khóa sau paywall.
2. **Side Maps bán chiều sâu**, không bán lại kiến thức cơ bản.
3. **Năng lượng là tài nguyên gameplay thực sự**, không phải thanh trang trí.
4. **Quảng cáo thưởng tự nguyện** — không bắt buộc để học kiến thức cơ bản.
5. **Nghỉ ngơi là một phần của game** — có hoạt ảnh, gợi ý vận động mắt, không giả vờ quảng cáo đã phát.
6. **Không gây áp lực mua Pro** — không đánh lừa, không tạo áp lực với trẻ.
7. **Tuân thủ chính sách trẻ em** — kiểm tra Google Play Families và mạng quảng cáo trước khi chốt cơ chế.
8. **Python phải thật hoặc mô phỏng giới hạn rõ ràng** — không tô giao diện giống trình soạn code rồi tuyên bố trẻ đã tạo game Python thật.

---

## 3. Mô hình kinh doanh — hai vòng kiếm tiền

### Vòng 1 — Quảng cáo thưởng để chơi tiếp
- Trẻ hết năng lượng → nghỉ chờ hồi hoặc xem quảng cáo thưởng.
- Chỉ cộng thưởng sau khi SDK xác nhận quảng cáo hoàn thành hợp lệ.

### Vòng 2 — Mua Side Maps để mở rộng thế giới
- Trả tiền để mở từng bản đồ phụ.
- Mua bản đồ = mua nội dung và quyền sưu tập, **không** mua khả năng học Python cơ bản.

### Pro — lựa chọn nâng cấp riêng
- Bỏ quảng cáo thuộc phạm vi gói Pro.
- Mở một số quyền lợi bổ sung đã công bố rõ.
- Không khóa Main Quest.

---

## 4. Cấu trúc thế giới game

### 4.1. Home Map
- Điểm khởi đầu sống động, không phải màn hình danh sách bài học.
- Nhân vật dễ thương: robot tò mò, rồng con ham kho báu, mèo tìm lỗi code.
- Thoại ngắn, hài hước, liên quan nhiệm vụ tiếp theo.
- Nhạc nền du dương, âm thanh tương tác phản hồi mỗi lần chạm.
- Mini-game là địa điểm trên bản đồ, khám phá không theo thứ tự.

### 4.2. Main Map — miễn phí
- Tuyến học Python cốt lõi: `print()` → biến → điều kiện → vòng lặp → danh sách → hàm → gỡ lỗi.
- Không cần mua để mở bài học chính; không cần xem quảng cáo để truy cập bản đồ.
- Có nhiệm vụ, XP, thú cưng cơ bản, thành tựu học tập.

### 4.3. Side Maps — mua từng gói
- **Pygame Island:** game 2D nâng cao, kiến trúc game, dự án mở rộng.
- **AI Pet Trainer Isle:** hành vi thú cưng, luật phản ứng, thử thách AI.
- **Bug Hunter Kingdom:** câu đố tìm lỗi.
- **Legendary Title Isles:** săn danh hiệu, huy hiệu, ngoại trang hiếm.

---

## 5. Vòng lặp gameplay & năng lượng

### Vòng lặp chính
1. **Chọn nhiệm vụ** — bản đồ, thú cưng, kho báu, nhiệm vụ ngày.
2. **Học và chơi** — bài học ngắn, đấu cú pháp, nhận XP, thu thập phần thưởng.
3. **Năng lượng giảm** — thông báo sắp hết, hiển thị số lượt còn lại.
4. **Nghỉ rồi chơi tiếp** — hồi theo thời gian, chờ nghỉ, hoặc xem quảng cáo thưởng nếu đủ điều kiện.
5. **Quay lại cuộc phiêu lưu** — mở nhiệm vụ mới, nâng cấp thú cưng, săn huy hiệu.

### Quy tắc năng lượng
- Mỗi hoạt động tiêu hao theo quy tắc rõ ràng; hiển thị số lượt/năng lượng còn lại.
- Hết năng lượng **không** đồng nghĩa hết quyền học.
- Trong lúc chờ hồi, trẻ vẫn có thể: xem lại bài cũ, đọc truyện Python, xem bộ sưu tập, luyện tập miễn phí.
- Quảng cáo phải có phần thưởng rõ ràng (thêm năng lượng hoặc lượt chơi).

---

## 6. Main Quest — lộ trình học miễn phí

Phải đủ nội dung để trẻ thực sự biết lập trình, kể cả tự làm game đơn giản.

| Chặng | Nội dung |
|---|---|
| **1. Code Apprentice** | In chữ, biến, số, chuỗi, phép toán, điều kiện. Điều khiển nhân vật bằng lệnh Python đầu tiên. |
| **2. Game Builder** | Vòng lặp, hàm, danh sách, nhập liệu, tọa độ, điểm số, mạng sống, điều kiện thắng thua. |
| **3. Game Creator** | Kết hợp kiến thức để tự xây game hoàn chỉnh: nhân vật, chướng ngại vật, va chạm, điểm thưởng, nhiều màn, xử lý lỗi. |
| **4. Game Master** | Dự án cuối tuyến miễn phí: game chơi lại được, lưu thành tích, nhận danh hiệu **Game Creator**. |

---

## 7. Mini-game dựng sẵn

Mỗi mini-game vừa giải trí vừa dạy tư duy lập trình, liên kết với một kiến thức Python để trẻ tự tạo game sau này.

| Mini-game | Cách chơi | Tư duy Python |
|---|---|---|
| **Robot Maze** | Chọn lệnh lên/xuống/trái/phải đưa robot đến kho báu | Thứ tự lệnh, thuật toán, hàm, vòng lặp |
| **Dragon Jump** | Điều khiển rồng nhảy qua chướng ngại vật, nhặt xu, tránh bẫy | Sự kiện, điều kiện, điểm số, trạng thái game |
| **Catch the Stars** | Di chuyển giỏ hứng sao, tránh vật cản | Biến, tọa độ, vòng lặp, bộ đếm |
| **Bug Hunter** | Tìm lệnh sai, sửa thứ tự khối lệnh | Cú pháp, logic, gỡ lỗi |
| **Pet Lab** | Cho thú cưng ăn/chơi/nghỉ, tạo quy tắc phản ứng | Điều kiện, trạng thái, hàm, thiết kế hành vi |

### Hai chế độ trong mỗi mini-game
- **Play Mode** — vào chơi ngay, không bắt buộc đọc bài hay viết code. Có điểm số, nhiệm vụ, âm thanh, hiệu ứng, thành tích.
- **Creator Mode** — xem game hoạt động, thay đổi quy tắc hoặc ghép khối lệnh, dần chuyển sang viết Python thật.

### Đưa vào Home Map
- Nhân vật rủ trẻ chơi: *"Robot của tớ bị lạc rồi, giúp tớ nhé!"*
- Chơi game nhận XP, huy hiệu, vật phẩm trang trí; phần thưởng học tập lớn hơn cho thử thách lập trình.
- Một số game tiêu hao năng lượng.

---

## 8. Side Maps trả phí & luồng mở khóa

Main Quest đủ kiến thức cơ bản và kỹ năng tạo game đơn giản. Side Maps bán chiều sâu, trải nghiệm mới, phần thưởng độc quyền.

### Luồng mở khóa
1. **Side Map Shop** — xem bản đồ, nội dung, phần thưởng, giá.
2. **Xác nhận mua hàng.**
3. **Xử lý bằng hệ thống thanh toán của nền tảng** khi tích hợp thực tế.
4. **Mở Side Map đã mua.**
5. **Lưu quyền sở hữu và khôi phục giao dịch khi cần.**

**Lưu ý:** quyền mua hàng không nên chỉ dựa vào file cục bộ có thể chỉnh sửa; cần xác minh qua cơ chế thanh toán nền tảng.

---

## 9. Bảng phân quyền Free / Mua gói / Pro

| Tính năng | Miễn phí | Mua gói / Pro |
|---|---|---|
| Main Map | Toàn bộ tuyến học cốt lõi | Không cần mua |
| Năng lượng | Hồi theo thời gian, xem quảng cáo thưởng nếu đủ điều kiện | Có thể có quyền lợi bổ sung công bố rõ |
| Bài học chính | Luôn truy cập được | Không khóa sau paywall |
| Side Maps | Xem trước nội dung và giá | Mở từng bản đồ đã mua |
| Danh hiệu, huy hiệu đặc biệt | Có phần thưởng miễn phí | Bộ sưu tập độc quyền từ nhiệm vụ trả phí |
| Bỏ quảng cáo | Có quảng cáo ở vị trí được phép | Pro bỏ quảng cáo thuộc phạm vi gói Pro |

---

## 10. Quy tắc quảng cáo & trẻ em

- Phân biệt rõ **quảng cáo thưởng tự nguyện** với **quảng cáo bắt buộc**.
- Tuân thủ chính sách quảng cáo dành cho trẻ em của nền tảng.
- Kiểm tra **Google Play Families** và mạng quảng cáo định dùng trước khi chốt cơ chế.
- Quảng cáo gọi là "nghỉ mắt" không tự động đồng nghĩa phù hợp với trẻ nhỏ.
- Không hiển thị quảng cáo sai lệch, gây nhầm lẫn hoặc tạo áp lực mua.
- Chỉ cộng thưởng sau khi SDK xác nhận hợp lệ.

---

## 11. Nhà Thành Tích — Hall of Achievements

Không chỉ là trang chứa huy hiệu, mà là một **căn nhà trong thế giới PyQuest**.

### Thành phần
- **Tủ huy hiệu:** mỗi huy hiệu đại diện một cột mốc.
- **Tường chiến tích:** số màn đã vượt, số game đã hoàn thành, số thế giới đã khám phá.
- **Bộ sưu tập nhân vật:** trang phục, phụ kiện, hiệu ứng cho nhân vật đồng hành.
- **Góc sáng tạo:** trưng bày game do trẻ tự xây.
- **Huy hiệu bí mật:** thưởng cho khám phá thú vị, cách giải khác nhau, phát hiện lỗi khó.

### Nguyên tắc
Phần thưởng phản ánh **nỗ lực và tiến bộ**, không thưởng cho việc chơi thật lâu hoặc xem thật nhiều quảng cáo.

---

## 12. Màn tổng kết & Adventure Recap

### 12.1. Màn tổng kết sau mỗi màn
Không phải màn hình "Level Complete" khô khan, mà là đoạn tổng kết ngắn, sinh động, có nội dung riêng.

**Ví dụ:**
> **Tuyệt vời! Bạn đã vượt mê cung!**  
> Robot Maze · Màn 5
>
> Bạn đã giúp Robo tìm đúng đường về nhà. Những lệnh bạn chọn chính là chìa khóa!
>
> | 12 | 8 | 1 |
> |---|---|---|
> | Màn đã vượt qua | Ngôi sao nhận được | Kỹ năng mới |
>
> **Kỹ năng vừa khám phá:** Bạn đã sử dụng thứ tự các lệnh để điều khiển robot. Đó chính là tư duy thuật toán!
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
> "Bạn đã đi từ những dòng lệnh đầu tiên đến việc tự điều khiển nhân vật trong trò chơi. Bạn không chỉ vượt màn — bạn đang học cách tạo ra thế giới của riêng mình."

**Lưu ý:** mọi con số phải lấy từ tiến trình đã lưu, không viết cố định.

---

## 13. Làm sinh động hơn Duolingo

| Duolingo nhấn mạnh | PyQuest tạo trải nghiệm |
|---|---|
| Chuỗi ngày học | Thế giới thay đổi theo tiến trình, không phạt trẻ khi nghỉ |
| XP và cấp độ | XP kết hợp kỹ năng lập trình đã thực sự nắm được |
| Huy hiệu | Huy hiệu xuất hiện trong Nhà Thành Tích |
| Hoàn thành bài học | Nhân vật phản ứng, có hoạt ảnh và lời thoại riêng |
| Tiến trình theo khóa học | Bản đồ phiêu lưu, nhân vật, vùng đất có câu chuyện |
| Ôn tập kiến thức | Mini-game biến kỹ năng cũ thành thử thách mới |

**Lưu ý:** âm thanh, nhạc nền, hoạt ảnh nên bật/tắt được. Hiệu ứng chiến thắng nhẹ và nhanh.

---

## 14. Kiến trúc module & database

### 14.1. Kiến trúc module

```
PyQuest App Core          →  Điều hướng, hồ sơ, ngôn ngữ, âm thanh
Main Quest                →  Bài học Python và tiến trình
Mini-games                →  Robot Maze, Dragon Jump… (module riêng)
Energy & Ads              →  Năng lượng và quảng cáo thưởng
Side Maps & Pro           →  Bản đồ mở rộng và mua hàng
Achievement System        →  achievement_engine · progress_tracker · achievement_house
```

Các module giao tiếp qua **interface rõ ràng**, không gọi trực tiếp lẫn nhau tùy tiện.

### 14.2. Database tách theo module logic

| Module | Dữ liệu sở hữu |
|---|---|
| Progress | Bài học đã hoàn thành, XP, huy hiệu |
| Games | Điểm cao, màn đã mở khóa, thành tích |
| Energy | Năng lượng hiện tại và thời điểm hồi phục |
| Purchases | Trạng thái quyền sở hữu bản đồ và Pro |
| Settings | Ngôn ngữ, âm thanh, nhạc nền |

Ban đầu dùng file JSON riêng hoặc bảng SQLite riêng trong một database; khi cần mới chuyển sang database vật lý riêng.

### 14.3. Hệ thống thành tích — 3 module độc lập
- **`achievement_engine`** — xác định điều kiện mở khóa huy hiệu.
- **`progress_tracker`** — ghi nhận màn, game, kỹ năng, chặng học.
- **`achievement_house`** — giao diện căn nhà, bộ sưu tập, hoạt ảnh, tổng kết.

**Luồng:** game gửi sự kiện chuẩn hóa (`level_completed`, `game_completed`, `skill_mastered`) → hệ thống tiến trình lưu và tính thành tích → Nhà Thành Tích đọc dữ liệu hiển thị.

Nhờ vậy, thêm game mới không phải viết lại hệ thống huy hiệu.

---

## 15. Roadmap

1. **Foundation** — khung Flutter, điều hướng, lưu dữ liệu, giao diện cơ bản.
2. **Home Map** — thế giới chính, nhân vật, âm thanh.
3. **Một mini-game hoàn chỉnh** — gameplay, điểm số, lưu kỷ lục, Creator Mode.
4. **Main Quest** — bài học Python, bài tập, lưu tiến trình.
5. **Python runtime** — thực thi mã an toàn, giới hạn tài nguyên, xử lý lỗi.
6. **Energy & Ads** — hồi năng lượng và quảng cáo thưởng.
7. **Side Maps & Pro** — nội dung mở rộng và mua hàng.
8. **Hoàn thiện** — localization, accessibility, kiểm thử, build, phát hành.

**Nguyên tắc:** mỗi mục có tiêu chí nghiệm thu và test riêng; chỉ chuyển sang mục kế tiếp khi đạt yêu cầu. Module đã ổn định không bị sửa chỉ vì thêm game mới.

**Nguyên tắc chốt từ đầu:** đừng xây cả thế giới PyQuest ngay lập tức. Làm một **lát cắt dọc hoàn chỉnh**: mở app → vào một trò chơi → chơi được → lưu kết quả → thoát ra mở lại vẫn còn kết quả. Khi lát cắt đó chạy ổn, phần còn lại chủ yếu là mở rộng theo module.

**Thứ tự triển khai Nhà Thành Tích:** thiết kế nền tảng ngay từ đầu, nhưng chỉ triển khai giao diện đầy đủ **sau khi có một mini-game mẫu chạy hoàn chỉnh** — để kiểm tra cả vòng đời: chơi → ghi nhận tiến trình → trao thành tích → xem tổng kết → quay lại thế giới.

---

## 16. Đánh giá README & cấu trúc tài liệu

### 16.1. Phần đã tốt
Định vị sản phẩm, Main Quest miễn phí, Side Maps trả phí, vòng lặp năng lượng, Home Map, mini-game, nhận thức về quyền riêng tư trẻ em.

### 16.2. Phần cần sửa
- Tài liệu dài, lặp ý.
- Tên repo trong README (`pyquest-game-lab`) khác repo thực tế (`PyQuest`).
- Chưa phân biệt tính năng phiên bản đầu với kế hoạch tương lai.
- Chưa xác định cách chạy Python thật / giới hạn mô phỏng.
- Chưa có hướng dẫn chạy, kiểm thử, cấu trúc code.
- Chưa có quy tắc định lượng cho năng lượng, thời gian hồi, XP, điều kiện nhận thưởng.

### 16.3. Cấu trúc file đề xuất

| File | Vai trò |
|---|---|
| `README.md` | Giới thiệu, tính năng chính, trạng thái, cách chạy |
| `docs/PRODUCT_VISION.md` | Ý tưởng sản phẩm, Home Map, nhân vật, âm thanh, Main Quest, Side Maps, mô hình doanh thu |
| `docs/GAME_DESIGN.md` | Vòng lặp gameplay, năng lượng, XP, mini-game, phần thưởng, cân bằng độ khó |
| `docs/TECHNICAL_ARCHITECTURE.md` | Flutter, thực thi Python, lưu tiến độ, dịch vụ, quảng cáo, thanh toán |
| `docs/ROADMAP.md` | Giai đoạn triển khai, tiêu chí hoàn thành, kiểm thử |

**Nguyên tắc:** tài liệu sản phẩm xác định *xây trò chơi gì*; tài liệu kỹ thuật xác định *xây bằng cách nào*; roadmap xác định *làm gì trước và kiểm tra bằng gì*.

---

## 17. Xử lý hình ảnh trong phiên chat

### Phân biệt hai loại ảnh
- **Ảnh AI tạo ra** — xuất hiện trong mục Images của ChatGPT.
- **Ảnh tham khảo** — lấy từ kết quả tìm kiếm, không mặc nhiên có giấy phép sử dụng thương mại.

### Tải ảnh AI tạo ra
1. Truy cập **ChatGPT Images** bằng tài khoản đang dùng.
2. Mở ảnh, nhấn **Save**, chọn thư mục đích.

### Tải ảnh tham khảo
1. Quay lại câu trả lời có ảnh trong cuộc trò chuyện.
2. Nhấp vào ảnh để mở lớn.
3. Nhấp chuột phải → **Save image as…**
4. Lưu vào `D:\PyQuest_Images\References`.

### Tạo thư mục quản lý (Windows PowerShell)
```powershell
New-Item -ItemType Directory -Force -Path `
  "D:\PyQuest_Images\AI_Generated", `
  "D:\PyQuest_Images\References"
```

Phân loại: `AI_Generated` (ảnh AI thật), `References` (ảnh tham khảo). Đặt tên theo nội dung: `achievement_house.png`, `robot_maze.png`, `dragon_jump.png`.

### Lưu ý
- Không thể tự động tải đủ toàn bộ ảnh lịch sử chat — lưu thủ công là phương án chắc chắn.
- Giữ riêng ảnh tham khảo với ảnh được phép dùng trong sản phẩm phát hành.

---

## 18. Tổng kết & việc cần làm tiếp theo

### Đã chốt
- **PyQuest** — biến trẻ từ người chơi thành người sáng tạo game.
- Main Map miễn phí, đầy đủ kiến thức Python cơ bản và kỹ năng tạo game đơn giản.
- Năng lượng điều tiết nhịp chơi; quảng cáo thưởng tự nguyện; Side Maps bán chiều sâu; Pro là nâng cấp riêng.
- Home Map có nhân vật dễ thương, thoại thú vị, nhạc du dương, âm thanh tương tác.
- Mini-game có Play Mode và Creator Mode.
- Nhà Thành Tích, màn tổng kết, Adventure Recap là phần thiết kế nền tảng.
- Kiến trúc module tách biệt; database tách theo module logic; roadmap chia giai đoạn có tiêu chí nghiệm thu.

### Nguyên tắc cuối cùng
> Trẻ mở PyQuest vì thích chơi, ở lại vì tò mò, rồi tự hỏi:  
> **"Mình có thể tự làm một game như thế này không?"**  
> Đó là lúc ứng dụng chuyển từ game giải trí thành công cụ dạy lập trình thực sự.

### Việc cần làm tiếp theo
1. Chỉnh README ngắn gọn, đúng tên repo `PyQuest`.
2. Tách tài liệu sản phẩm sang `docs/PRODUCT_VISION.md`.
3. Viết `docs/GAME_DESIGN.md` với quy tắc định lượng: năng lượng, thời gian hồi, XP, điều kiện nhận thưởng.
4. Viết `docs/TECHNICAL_ARCHITECTURE.md` với quyết định về Python runtime, Flutter, lưu tiến trình, quảng cáo, thanh toán.
5. Viết `docs/ROADMAP.md` với tiêu chí nghiệm thu từng giai đoạn.
6. Bắt đầu bằng **lát cắt dọc hoàn chỉnh**: mở app → chơi một mini-game → lưu kết quả → mở lại vẫn còn.
# PYQUEST — TÀI LIỆU TỔNG HỢP CUỐI CÙNG (CẬP NHẬT)

---

## PHẦN A — ĐÁNH GIÁ TRẠNG THÁI HIỆN TẠI

### A.1. Kết luận chung

Bản tinh gọn đã tốt hơn bản đầy đủ, nhưng **chưa nên dùng nguyên văn làm tài liệu giao cho AI lập trình**.

| Hạng mục | Trạng thái |
|---|---|
| Phần ý tưởng sản phẩm | **Đạt** — định hướng rõ, Main Quest miễn phí, mini-game hai chế độ, Nhà Thành Tích, tổng kết sau màn, Adventure Recap, cách chia module |
| Phần tài liệu triển khai | **Chưa đạt** — còn quyết định kỹ thuật quan trọng chưa chốt; README đang gánh quá nhiều loại tài liệu khác nhau |

### A.2. Sáu điểm cần sửa trước khi bắt đầu code

| Mức độ | Vấn đề | Hướng xử lý |
|---|---|---|
| **Cao** | Python chạy thật hay mô phỏng vẫn chưa quyết định | Chốt phạm vi Python hỗ trợ và cách thực thi an toàn |
| **Cao** | Năng lượng, XP, hồi phục chưa có con số | Đưa thông số sang Game Design; tránh để AI tự đặt luật |
| **Cao** | Chưa có cấu trúc code, cách chạy và test | Xác định Flutter/Dart, lưu dữ liệu, lệnh chạy và tiêu chí nghiệm thu |
| **Cao** | Main Map và Main Quest chưa được định nghĩa nhất quán | Phân biệt thế giới khám phá với tuyến học Python |
| **Vừa** | Có nói database riêng nhưng chưa xác định ranh giới dữ liệu | Quy định module nào sở hữu dữ liệu nào, cách giao tiếp và di trú |
| **Vừa** | README chứa cả đánh giá README và hướng dẫn tải ảnh trong chat | Chuyển phần ý tưởng sang tài liệu sản phẩm; bỏ nội dung đánh giá và hướng dẫn cá nhân khỏi tài liệu dự án |

### A.3. Nguyên tắc giữ lại các ý tưởng đã chốt

Nhà Thành Tích và Adventure Recap **phải được giữ lại trong thiết kế nền tảng**, gồm:
- Thống kê chính xác số màn và trò chơi đã hoàn thành.
- Ghi nhận kỹ năng Python thực sự đã học.
- Huy hiệu, bộ sưu tập và trò chơi do trẻ tự tạo.
- Màn tổng kết có nhân vật, lời thoại và lời khích lệ.
- Lưu dữ liệu bền vững để đóng app rồi mở lại vẫn còn thành tích.

Các module có thể triển khai và kiểm thử riêng, nhưng phải dùng chung **hợp đồng dữ liệu đã thống nhất**. Nếu không, sau này tiến trình, năng lượng và thành tích dễ bị lệch nhau.

---

## PHẦN B — NỘI DUNG SẢN PHẨM

### B.1. Định vị dự án

- **Tên:** PyQuest
- **Tagline:** Build Your Game. Rule Your World.
- **Repository:** `PyQuest` (đang Private)
- **Định vị:** Game lập trình cho trẻ dưới 12 tuổi — bán giấc mơ **tự tạo trò chơi**, Python là công cụ.
- **Mục tiêu trải nghiệm:** trẻ mở vì thích chơi → ở lại vì tò mò → tự hỏi *"Mình có thể tự làm một game như thế này không?"*

### B.2. Nguyên tắc thiết kế xuyên suốt

1. Main Map miễn phí và đầy đủ cốt lõi — không khóa sau paywall.
2. Side Maps bán chiều sâu, không bán lại kiến thức cơ bản.
3. Năng lượng là tài nguyên gameplay thực sự, không phải thanh trang trí.
4. Quảng cáo thưởng tự nguyện — không bắt buộc để học kiến thức cơ bản.
5. Nghỉ ngơi là một phần của game — có hoạt ảnh, gợi ý vận động mắt, không giả vờ quảng cáo đã phát.
6. Không gây áp lực mua Pro — không đánh lừa, không tạo áp lực với trẻ.
7. Tuân thủ chính sách trẻ em — kiểm tra Google Play Families và mạng quảng cáo trước khi chốt cơ chế.
8. Python phải thật hoặc mô phỏng giới hạn rõ ràng — không tô giao diện giống trình soạn code rồi tuyên bố trẻ đã tạo game Python thật.

### B.3. Mô hình kinh doanh — hai vòng kiếm tiền

**Vòng 1 — Quảng cáo thưởng để chơi tiếp:** hết năng lượng → nghỉ chờ hồi hoặc xem quảng cáo thưởng; chỉ cộng thưởng sau khi SDK xác nhận hợp lệ.

**Vòng 2 — Mua Side Maps để mở rộng thế giới:** mua nội dung và quyền sưu tập, **không** mua khả năng học Python cơ bản.

**Pro — lựa chọn nâng cấp riêng:** bỏ quảng cáo thuộc phạm vi gói Pro, mở quyền lợi bổ sung công bố rõ, không khóa Main Quest.

### B.4. Cấu trúc thế giới game

**Home Map**
- Điểm khởi đầu sống động, không phải màn hình danh sách bài học.
- Nhân vật dễ thương: robot tò mò, rồng con ham kho báu, mèo tìm lỗi code.
- Thoại ngắn, hài hước, liên quan nhiệm vụ tiếp theo.
- Nhạc nền du dương, âm thanh tương tác phản hồi mỗi lần chạm.
- Mini-game là địa điểm trên bản đồ, khám phá không theo thứ tự.

**Main Map — miễn phí**
- Tuyến học Python cốt lõi: `print()` → biến → điều kiện → vòng lặp → danh sách → hàm → gỡ lỗi.
- Không cần mua để mở bài học chính; không cần xem quảng cáo để truy cập bản đồ.
- Có nhiệm vụ, XP, thú cưng cơ bản, thành tựu học tập.

**Side Maps — mua từng gói**
- **Pygame Island:** game 2D nâng cao, kiến trúc game, dự án mở rộng.
- **AI Pet Trainer Isle:** hành vi thú cưng, luật phản ứng, thử thách AI.
- **Bug Hunter Kingdom:** câu đố tìm lỗi.
- **Legendary Title Isles:** săn danh hiệu, huy hiệu, ngoại trang hiếm.

### B.5. Vòng lặp gameplay & năng lượng

**Vòng lặp chính:**
1. Chọn nhiệm vụ — bản đồ, thú cưng, kho báu, nhiệm vụ ngày.
2. Học và chơi — bài học ngắn, đấu cú pháp, nhận XP, thu thập phần thưởng.
3. Năng lượng giảm — thông báo sắp hết, hiển thị số lượt còn lại.
4. Nghỉ rồi chơi tiếp — hồi theo thời gian, chờ nghỉ, hoặc xem quảng cáo thưởng nếu đủ điều kiện.
5. Quay lại cuộc phiêu lưu — mở nhiệm vụ mới, nâng cấp thú cưng, săn huy hiệu.

**Quy tắc năng lượng:**
- Mỗi hoạt động tiêu hao theo quy tắc rõ ràng; hiển thị số lượt/năng lượng còn lại.
- Hết năng lượng **không** đồng nghĩa hết quyền học.
- Trong lúc chờ hồi, trẻ vẫn có thể xem lại bài cũ, đọc truyện Python, xem bộ sưu tập, luyện tập miễn phí.
- Quảng cáo phải có phần thưởng rõ ràng (thêm năng lượng hoặc lượt chơi).

### B.6. Main Quest — lộ trình học miễn phí

| Chặng | Nội dung |
|---|---|
| **1. Code Apprentice** | In chữ, biến, số, chuỗi, phép toán, điều kiện. Điều khiển nhân vật bằng lệnh Python đầu tiên. |
| **2. Game Builder** | Vòng lặp, hàm, danh sách, nhập liệu, tọa độ, điểm số, mạng sống, điều kiện thắng thua. |
| **3. Game Creator** | Kết hợp kiến thức để tự xây game hoàn chỉnh: nhân vật, chướng ngại vật, va chạm, điểm thưởng, nhiều màn, xử lý lỗi. |
| **4. Game Master** | Dự án cuối tuyến miễn phí: game chơi lại được, lưu thành tích, nhận danh hiệu **Game Creator**. |

### B.7. Mini-game dựng sẵn

| Mini-game | Cách chơi | Tư duy Python |
|---|---|---|
| **Robot Maze** | Chọn lệnh lên/xuống/trái/phải đưa robot đến kho báu | Thứ tự lệnh, thuật toán, hàm, vòng lặp |
| **Dragon Jump** | Điều khiển rồng nhảy qua chướng ngại vật, nhặt xu, tránh bẫy | Sự kiện, điều kiện, điểm số, trạng thái game |
| **Catch the Stars** | Di chuyển giỏ hứng sao, tránh vật cản | Biến, tọa độ, vòng lặp, bộ đếm |
| **Bug Hunter** | Tìm lệnh sai, sửa thứ tự khối lệnh | Cú pháp, logic, gỡ lỗi |
| **Pet Lab** | Cho thú cưng ăn/chơi/nghỉ, tạo quy tắc phản ứng | Điều kiện, trạng thái, hàm, thiết kế hành vi |

**Hai chế độ:**
- **Play Mode** — vào chơi ngay, không bắt buộc đọc bài hay viết code. Có điểm số, nhiệm vụ, âm thanh, hiệu ứng, thành tích.
- **Creator Mode** — xem game hoạt động, thay đổi quy tắc hoặc ghép khối lệnh, dần chuyển sang viết Python thật.

**Đưa vào Home Map:** nhân vật rủ trẻ chơi; chơi game nhận XP, huy hiệu, vật phẩm trang trí; phần thưởng học tập lớn hơn cho thử thách lập trình; một số game tiêu hao năng lượng.

### B.8. Side Maps trả phí & luồng mở khóa

1. Side Map Shop — xem bản đồ, nội dung, phần thưởng, giá.
2. Xác nhận mua hàng.
3. Xử lý bằng hệ thống thanh toán của nền tảng khi tích hợp thực tế.
4. Mở Side Map đã mua.
5. Lưu quyền sở hữu và khôi phục giao dịch khi cần.

**Lưu ý:** quyền mua hàng không nên chỉ dựa vào file cục bộ có thể chỉnh sửa; cần xác minh qua cơ chế thanh toán nền tảng.

### B.9. Bảng phân quyền Free / Mua gói / Pro

| Tính năng | Miễn phí | Mua gói / Pro |
|---|---|---|
| Main Map | Toàn bộ tuyến học cốt lõi | Không cần mua |
| Năng lượng | Hồi theo thời gian, xem quảng cáo thưởng nếu đủ điều kiện | Có thể có quyền lợi bổ sung công bố rõ |
| Bài học chính | Luôn truy cập được | Không khóa sau paywall |
| Side Maps | Xem trước nội dung và giá | Mở từng bản đồ đã mua |
| Danh hiệu, huy hiệu đặc biệt | Có phần thưởng miễn phí | Bộ sưu tập độc quyền từ nhiệm vụ trả phí |
| Bỏ quảng cáo | Có quảng cáo ở vị trí được phép | Pro bỏ quảng cáo thuộc phạm vi gói Pro |

### B.10. Quy tắc quảng cáo & trẻ em

- Phân biệt rõ quảng cáo thưởng tự nguyện với quảng cáo bắt buộc.
- Tuân thủ chính sách quảng cáo dành cho trẻ em của nền tảng.
- Kiểm tra Google Play Families và mạng quảng cáo định dùng trước khi chốt cơ chế.
- Quảng cáo gọi là "nghỉ mắt" không tự động đồng nghĩa phù hợp với trẻ nhỏ.
- Không hiển thị quảng cáo sai lệch, gây nhầm lẫn hoặc tạo áp lực mua.
- Chỉ cộng thưởng sau khi SDK xác nhận hợp lệ.

### B.11. Nhà Thành Tích — Hall of Achievements

Không chỉ là trang chứa huy hiệu, mà là một **căn nhà trong thế giới PyQuest**.

**Thành phần:**
- Tủ huy hiệu: mỗi huy hiệu đại diện một cột mốc.
- Tường chiến tích: số màn đã vượt, số game đã hoàn thành, số thế giới đã khám phá.
- Bộ sưu tập nhân vật: trang phục, phụ kiện, hiệu ứng cho nhân vật đồng hành.
- Góc sáng tạo: trưng bày game do trẻ tự xây.
- Huy hiệu bí mật: thưởng cho khám phá thú vị, cách giải khác nhau, phát hiện lỗi khó.

**Nguyên tắc:** phần thưởng phản ánh nỗ lực và tiến bộ, không thưởng cho việc chơi thật lâu hoặc xem thật nhiều quảng cáo.

### B.12. Màn tổng kết & Adventure Recap

**Màn tổng kết sau mỗi màn** — không phải màn hình "Level Complete" khô khan.

Ví dụ:
> **Tuyệt vời! Bạn đã vượt mê cung!**  
> Robot Maze · Màn 5
>
> | 12 | 8 | 1 |
> |---|---|---|
> | Màn đã vượt qua | Ngôi sao nhận được | Kỹ năng mới |
>
> **Kỹ năng vừa khám phá:** Bạn đã sử dụng thứ tự các lệnh để điều khiển robot. Đó chính là tư duy thuật toán!
>
> **Robo:** "Tuyệt! Thêm một nhà thám hiểm lập trình tài ba!"

**Ba nguyên tắc cho màn tổng kết:**
1. Ghi nhận thành tựu cụ thể.
2. Khích lệ không gây áp lực.
3. Thay đổi theo hành trình.

**Adventure Recap — tổng kết chặng lớn:**
> | 25 | 5 | 8 | 3 |
> |---|---|---|---|
> | Màn đã hoàn thành | Trò chơi đã chinh phục | Kỹ năng Python đã học | Huy hiệu đã mở khóa |
>
> **Lời nhắn:** "Bạn đã đi từ những dòng lệnh đầu tiên đến việc tự điều khiển nhân vật trong trò chơi. Bạn không chỉ vượt màn — bạn đang học cách tạo ra thế giới của riêng mình."

Mọi con số phải lấy từ tiến trình đã lưu, không viết cố định.

### B.13. Làm sinh động hơn Duolingo

| Duolingo nhấn mạnh | PyQuest tạo trải nghiệm |
|---|---|
| Chuỗi ngày học | Thế giới thay đổi theo tiến trình, không phạt trẻ khi nghỉ |
| XP và cấp độ | XP kết hợp kỹ năng lập trình đã thực sự nắm được |
| Huy hiệu | Huy hiệu xuất hiện trong Nhà Thành Tích |
| Hoàn thành bài học | Nhân vật phản ứng, có hoạt ảnh và lời thoại riêng |
| Tiến trình theo khóa học | Bản đồ phiêu lưu, nhân vật, vùng đất có câu chuyện |
| Ôn tập kiến thức | Mini-game biến kỹ năng cũ thành thử thách mới |

Âm thanh, nhạc nền, hoạt ảnh nên bật/tắt được. Hiệu ứng chiến thắng nhẹ và nhanh.

---

## PHẦN C — KIẾN TRÚC & TRIỂN KHAI

### C.1. Kiến trúc module

```
PyQuest App Core          →  Điều hướng, hồ sơ, ngôn ngữ, âm thanh
Main Quest                →  Bài học Python và tiến trình
Mini-games                →  Robot Maze, Dragon Jump… (module riêng)
Energy & Ads              →  Năng lượng và quảng cáo thưởng
Side Maps & Pro           →  Bản đồ mở rộng và mua hàng
Achievement System        →  achievement_engine · progress_tracker · achievement_house
```

Các module giao tiếp qua **interface rõ ràng**, không gọi trực tiếp lẫn nhau tùy tiện.

### C.2. Database tách theo module logic

| Module | Dữ liệu sở hữu |
|---|---|
| Progress | Bài học đã hoàn thành, XP, huy hiệu |
| Games | Điểm cao, màn đã mở khóa, thành tích |
| Energy | Năng lượng hiện tại và thời điểm hồi phục |
| Purchases | Trạng thái quyền sở hữu bản đồ và Pro |
| Settings | Ngôn ngữ, âm thanh, nhạc nền |

Ban đầu dùng file JSON riêng hoặc bảng SQLite riêng trong một database; khi cần mới chuyển sang database vật lý riêng.

### C.3. Hệ thống thành tích — 3 module độc lập

- **`achievement_engine`** — xác định điều kiện mở khóa huy hiệu.
- **`progress_tracker`** — ghi nhận màn, game, kỹ năng, chặng học.
- **`achievement_house`** — giao diện căn nhà, bộ sưu tập, hoạt ảnh, tổng kết.

**Luồng:** game gửi sự kiện chuẩn hóa (`level_completed`, `game_completed`, `skill_mastered`) → hệ thống tiến trình lưu và tính thành tích → Nhà Thành Tích đọc dữ liệu hiển thị.

### C.4. Roadmap

1. **Foundation** — khung Flutter, điều hướng, lưu dữ liệu, giao diện cơ bản.
2. **Home Map** — thế giới chính, nhân vật, âm thanh.
3. **Một mini-game hoàn chỉnh** — gameplay, điểm số, lưu kỷ lục, Creator Mode.
4. **Main Quest** — bài học Python, bài tập, lưu tiến trình.
5. **Python runtime** — thực thi mã an toàn, giới hạn tài nguyên, xử lý lỗi.
6. **Energy & Ads** — hồi năng lượng và quảng cáo thưởng.
7. **Side Maps & Pro** — nội dung mở rộng và mua hàng.
8. **Hoàn thiện** — localization, accessibility, kiểm thử, build, phát hành.

**Nguyên tắc:** mỗi mục có tiêu chí nghiệm thu và test riêng; chỉ chuyển sang mục kế tiếp khi đạt yêu cầu.

**Nguyên tắc chốt từ đầu:** đừng xây cả thế giới PyQuest ngay lập tức. Làm một **lát cắt dọc hoàn chỉnh**: mở app → vào một trò chơi → chơi được → lưu kết quả → thoát ra mở lại vẫn còn kết quả.

**Thứ tự triển khai Nhà Thành Tích:** thiết kế nền tảng ngay từ đầu, nhưng chỉ triển khai giao diện đầy đủ sau khi có một mini-game mẫu chạy hoàn chỉnh.

### C.5. Cấu trúc GitHub khuyên dùng

```
PyQuest/
├── README.md
├── docs/
│   ├── PRODUCT_VISION.md
│   ├── GAME_DESIGN.md
│   ├── TECHNICAL_ARCHITECTURE.md
│   └── ROADMAP.md
└── app/                 # Khi bắt đầu triển khai
```

| File | Vai trò |
|---|---|
| `README.md` | Giới thiệu dự án, trạng thái và cách chạy |
| `PRODUCT_VISION.md` | Toàn bộ ý tưởng thế giới, nhân vật, mô hình kinh doanh, triết lý giáo dục |
| `GAME_DESIGN.md` | Luật chơi, năng lượng, XP, huy hiệu, thành tích, cân bằng độ khó |
| `TECHNICAL_ARCHITECTURE.md` | Python runtime, các module, lưu dữ liệu, quảng cáo, thanh toán |
| `ROADMAP.md` | Từng giai đoạn, tiêu chí nghiệm thu và test |

**Nguyên tắc tài liệu:** tài liệu sản phẩm xác định *xây trò chơi gì*; tài liệu kỹ thuật xác định *xây bằng cách nào*; roadmap xác định *làm gì trước và kiểm tra bằng gì*.

### C.6. Nguyên tắc phát triển & kiểm thử

Với PyQuest, phần lớn module độc lập, chủ yếu ghi và đọc trạng thái. Không cần biến việc phát triển thành một dự án chạy hàng đống test sau mỗi thay đổi. Ưu tiên kiến trúc đơn giản, luồng chơi thật và kiểm tra tổng thể ở cuối.

#### C.6.1. Không test tràn lan

- Không viết unit test cho từng hàm nhỏ, getter/setter hay thao tác lưu trạng thái đơn giản.
- Không cố định từng pixel, khoảng cách, màu sắc hoặc animation bằng test.
- Không dựng mock phức tạp chỉ để kiểm tra các module vốn độc lập.
- Không chạy toàn bộ test sau mỗi lần sửa giao diện hoặc nội dung.

#### C.6.2. Kiểm tra theo rủi ro thực tế

| Hạng mục | Cách kiểm tra |
|---|---|
| Module độc lập, ghi/đọc trạng thái | Kiểm tra trực tiếp khi cần |
| Giao diện, bản đồ, nhân vật, animation | Chạy app và quan sát thực tế |
| Tiến trình học, phần thưởng, năng lượng | Kiểm tra một số luồng đại diện |
| Lưu dữ liệu | Thoát app, mở lại, xác nhận trạng thái còn nguyên |
| Python runtime | Kiểm tra các trường hợp chạy code, lỗi và giới hạn tài nguyên |
| Quảng cáo, mua Pro | Kiểm tra tích hợp thực tế và các trường hợp thất bại |
| Toàn bộ trò chơi | Kiểm tra cuối theo các chuyến phiêu lưu hoàn chỉnh |

#### C.6.3. Test cuối theo chuyến phiêu lưu

Thay vì hàng trăm test nhỏ, xây dựng một số kịch bản đại diện:

1. **Người chơi mới:** mở app → khám phá bản đồ → chơi mini-game → học Python → nhận thành tích.
2. **Người chơi quay lại:** hoàn thành một phần → đóng app → mở lại → tiếp tục đúng tiến trình.
3. **Người chơi hết năng lượng:** chuyển sang nội dung miễn phí khác → chờ hồi năng lượng hoặc nhận thưởng quảng cáo hợp lệ.
4. **Người chơi sáng tạo:** sửa quy tắc mini-game → chạy thử → gặp lỗi → sửa lỗi → hoàn thành trò chơi.
5. **Người chơi Pro:** mua hoặc khôi phục quyền Pro → kiểm tra quyền lợi; mô phỏng lỗi giao dịch và trạng thái chưa xác minh.
6. **Người chơi gặp sự cố:** mất mạng, dữ liệu chưa lưu hoặc runtime lỗi → app xử lý an toàn, không mất tiến trình ngoài dự kiến.

Các kịch bản này là **mục tiêu kiểm chứng cuối**, không phải lý do để dựng ngay một bộ framework test nặng nề.

#### C.6.4. Giữ code gọn, tránh kiến trúc quá mức

- Module độc lập khi thực sự cần; không tạo tầng trung gian chỉ để trông có vẻ chuẩn kiến trúc.
- Dùng chung một nguồn trạng thái cho tiến trình, năng lượng và thành tích; tránh các module ghi đè dữ liệu của nhau.
- Chỉ thêm kiểm tra tự động khi nó ngăn được lỗi đáng kể hoặc giúp tái hiện lỗi khó.
- Các giá trị gameplay có thể điều chỉnh qua cấu hình, không rải số liệu khắp code.
- Chỉ tối ưu những vấn đề thực tế ảnh hưởng đến trải nghiệm, không theo đuổi sự hoàn hảo ở từng pixel.

#### C.6.5. Điểm kiểm tra bắt buộc

Không cần nhiều test, nhưng vẫn phải có một số điểm kiểm tra đủ sức phát hiện lỗi nghiêm trọng — đặc biệt là:
- **Mất dữ liệu.**
- **Cộng thưởng sai.**
- **Vượt giới hạn khi chạy Python.**
- **Quyền mua Pro bị xác nhận sai.**

#### C.6.6. Định hướng chung

Xây dựng nhanh từng phần độc lập → kiểm tra thủ công trong quá trình phát triển → kiểm chứng toàn bộ bằng vài chuyến phiêu lưu thực tế ở cuối. **Không biến test thành một sản phẩm thứ hai.**

---

## PHẦN D — XỬ LÝ HÌNH ẢNH TRONG PHIÊN CHAT

*(Phần này chỉ giữ để tham khảo cá nhân — **không đưa vào tài liệu dự án** theo khuyến nghị ở mục A.2)*

### Phân biệt hai loại ảnh
- **Ảnh AI tạo ra** — xuất hiện trong mục Images của ChatGPT.
- **Ảnh tham khảo** — lấy từ kết quả tìm kiếm, không mặc nhiên có giấy phép sử dụng thương mại.

### Tải ảnh AI tạo ra
1. Truy cập **ChatGPT Images** bằng tài khoản đang dùng.
2. Mở ảnh, nhấn **Save**, chọn thư mục đích.

### Tải ảnh tham khảo
1. Quay lại câu trả lời có ảnh trong cuộc trò chuyện.
2. Nhấp vào ảnh để mở lớn.
3. Nhấp chuột phải → **Save image as…**
4. Lưu vào `D:\PyQuest_Images\References`.

### Tạo thư mục quản lý (Windows PowerShell)
```powershell
New-Item -ItemType Directory -Force -Path `
  "D:\PyQuest_Images\AI_Generated", `
  "D:\PyQuest_Images\References"
```

### Lưu ý
- Không thể tự động tải đủ toàn bộ ảnh lịch sử chat — lưu thủ công là phương án chắc chắn.
- Giữ riêng ảnh tham khảo với ảnh được phép dùng trong sản phẩm phát hành.

---

## PHẦN E — KẾT LUẬN & VIỆC CẦN LÀM TIẾP THEO

### E.1. Nguyên tắc cuối cùng

> Trẻ mở PyQuest vì thích chơi, ở lại vì tò mò, rồi tự hỏi:  
> **"Mình có thể tự làm một game như thế này không?"**  
> Đó là lúc ứng dụng chuyển từ game giải trí thành công cụ dạy lập trình thực sự.

### E.2. Chốt trạng thái hiện tại

Nội dung hiện tại **đã đủ tốt để làm bản tổng hợp ý tưởng sản phẩm**, nhưng **chưa phải bản đặc tả triển khai cuối cùng**.

**Khuyến nghị:** tách tài liệu trước → chốt các quyết định kỹ thuật sau → rồi mới bắt đầu xây lát cắt dọc đầu tiên. Làm vậy sẽ tận dụng được lợi thế PyQuest dễ chia thành các phần độc lập.

### E.3. Việc cần làm tiếp theo (theo thứ tự ưu tiên)

1. **Chốt phạm vi Python runtime** — chạy thật hay mô phỏng, giới hạn tài nguyên, cách thực thi an toàn.
2. **Định lượng hóa Game Design** — năng lượng, thời gian hồi, XP, điều kiện nhận thưởng, cân bằng độ khó.
3. **Xác định cấu trúc code & tiêu chí nghiệm thu** — Flutter/Dart, lưu dữ liệu, lệnh chạy, test.
4. **Phân biệt Main Map và Main Quest** — thế giới khám phá vs tuyến học Python.
5. **Chốt ranh giới dữ liệu giữa các module** — module nào sở hữu dữ liệu nào, cách giao tiếp, di trú.
6. **Tách tài liệu** — chỉnh README ngắn gọn, chuyển ý tưởng sang `PRODUCT_VISION.md`, bỏ nội dung đánh giá và hướng dẫn cá nhân khỏi tài liệu dự án.
7. **Bắt đầu lát cắt dọc đầu tiên** — mở app → chơi một mini-game → lưu kết quả → mở lại vẫn còn.
