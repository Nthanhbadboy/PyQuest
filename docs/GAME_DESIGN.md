# PyQuest — Game Design

> Tài liệu này xác định **luật chơi và thông số định lượng** của PyQuest:
> năng lượng, tiến trình hoạt động, phần thưởng, điều kiện mở khóa và cân bằng độ khó.
> Tài liệu **không** định nghĩa lại triết lý sản phẩm (xem `PRODUCT_VISION.md`)
> và **không** đi vào quyết định kỹ thuật (xem `TECHNICAL_ARCHITECTURE.md`).
>
> Thuật ngữ (**Home Map**, **Main Map**, **Main Quest**, **Mini-game Play Mode**,
> **Mini-game Creator Mode**, **Side Maps**, **Nhà Thành Tích**, **Adventure Recap**)
> dùng theo định nghĩa tại `PRODUCT_VISION.md`.

**Nguyên tắc quan trọng:** mọi con số trong tài liệu này là **giá trị khởi điểm**,
được đặt trong file cấu hình (không rải rác trong code) để có thể tinh chỉnh
sau khi thử nghiệm thực tế với trẻ. Cấu trúc luật chơi ổn định;
con số có thể đổi.

---

## 1. Triết lý thiết kế gameplay

Năm nguyên tắc chi phối mọi con số trong tài liệu này:

1. **Phiên chơi ngắn, không mệt.** Trẻ dưới 12 tuổi không nên ngồi quá lâu.
   Mỗi phiên lý tưởng 10–20 phút, có điểm dừng tự nhiên.

2. **Năng lượng điều tiết nhịp, không chặn việc học.**
   Hết năng lượng vẫn còn nội dung miễn phí để khám phá.

3. **Phần thưởng theo nỗ lực, không theo thời gian.**
   Thưởng cho tiến bộ và kỹ năng, không thưởng cho việc chơi lâu.

4. **Không phạt khi nghỉ.** Không streak, không mất huy hiệu vì vắng mặt.

5. **Thử thách tăng dần, luôn có đường quay lại.**
   Trẻ thất bại có thể thử lại ngay hoặc luyện ở mini-game liên quan.

---

## 2. Vòng lặp cốt lõi

```
Chọn nhiệm vụ → Học/Chơi → Nhận thưởng → Năng lượng giảm
      ↑                                          ↓
      └──── Quay lại ← Nghỉ/hồi năng lượng ←─────┘
```

**Thời lượng một vòng lặp:** 3–6 phút cho một hoạt động đơn lẻ.

**Thời lượng một phiên lý tưởng:** 4–6 hoạt động, tương đương 15–25 phút.

**Điểm dừng tự nhiên:** khi hết năng lượng hoặc hoàn thành một màn.

---

## 3. Hệ thống năng lượng

### 3.1. Giá trị khởi điểm

| Thông số | Giá trị | Ghi chú |
|---|---|---|
| Năng lượng tối đa — ban đầu | **20** | Mức mặc định khi tạo tài khoản (đầy bình) |
| Năng lượng tối đa — trần | **40** | Chỉ đạt được theo tiến trình bên dưới |
| Thời gian hồi 1 đơn vị | **10 phút** | Hồi đầy 20 đơn vị đầu tiên trong ~3h20 |
| Năng lượng nhận khi xem quảng cáo thưởng | **+5** | Tối đa 3 lần hợp lệ mỗi ngày |

**Tiến trình tăng năng lượng tối đa:** năng lượng tối đa ban đầu là 20, trần đề xuất là 40. Các mốc tăng thêm sẽ gắn với cột mốc gameplay/hoàn thành hoạt động được xác định khi cân bằng game; **không dựa trên XP hoặc cấp độ toàn cục**. Không cần thiết phải tăng năng lượng nếu điều đó không cải thiện trải nghiệm.

### 3.2. Mức tiêu hao theo hoạt động

| Hoạt động | Tiêu hao | Ghi chú |
|---|---|---|
| Chơi mini-game (**Mini-game Play Mode**) | **2** | Một màn, chỉ khi bắt đầu màn mới |
| Chơi mini-game (**Mini-game Creator Mode**) | **0** | Không tiêu hao — đây là học, không phải chơi |
| Bài học **Main Quest** | **1** | Một bài học lý thuyết |
| Bài tập **Main Quest** | **1** | Một bài tập code |
| Thử thách cuối chặng | **3** | Chỉ khi **bắt đầu lần đầu**, **không** tính khi thử lại |
| Nhiệm vụ ngày | **0** | **Không** tiêu hao năng lượng riêng — hoạt động gốc đã tiêu hao theo dòng tương ứng (xem mục 8) |
| Xem lại bài cũ | **0** | Luôn miễn phí |
| Đọc truyện Python | **0** | Luôn miễn phí |
| Xem bộ sưu tập | **0** | Luôn miễn phí |

### 3.3. Quy tắc hồi năng lượng

- Năng lượng hồi theo thời gian thực, kể cả khi tắt app.
- Hồi theo **từng đơn vị**, không theo phần trăm.
- Khi đầy, đồng hồ hồi dừng lại (không tích lũy tràn).
- Khi hết năng lượng: hiển thị thời gian hồi đơn vị tiếp theo,
  gợi ý nội dung miễn phí đang có.

### 3.4. Quy tắc quảng cáo thưởng

- Chỉ hiển thị nút "Nhận thêm năng lượng" khi năng lượng < tối đa.
- Tối đa **3 lần hợp lệ/ngày**, reset vào 00:00 giờ địa phương.
- Chỉ cộng **+5** năng lượng sau khi SDK xác nhận hợp lệ.
- Nếu quảng cáo thất bại hoặc bị hủy trước khi hoàn thành: **không** trừ lượt,
  **không** trừ năng lượng, hiển thị thông báo nhẹ.
- Lượt xem hợp lệ phải được **lưu lại (persist)** để lần mở app sau không thể
  nhận thêm quá 3 lần/ngày (xem `TECHNICAL_ARCHITECTURE.md`).

> **TBD — cần quyết định sản phẩm.** Quảng cáo thưởng là cách **tùy chọn** để thêm
> năng lượng. Nếu gói Pro ẩn toàn bộ nút quảng cáo, cần chốt người dùng Pro có
> được tự nguyện xem quảng cáo thưởng hay có cách công bố rõ khác để nhận phần
> năng lượng tương đương. Xem `PRODUCT_VISION.md` mục 3.3.

### 3.5. Điều **không** xảy ra khi hết năng lượng

- Không khóa Main Map.
- Không khóa bài học đã hoàn thành.
- Không khóa Nhà Thành Tích, bộ sưu tập, truyện.
- Không hiển thị popup gây áp lực mua Pro.

---

## 4. Mở hoạt động, điểm và thành tích — không có XP/cấp độ toàn cục

### 4.1. Vai trò của Main Map

**Main Map chỉ là bản đồ trung tâm để người chơi khám phá, chọn và mở các hoạt động.** Bản đồ không phải một thanh tiến trình và không yêu cầu tích XP để đi tiếp.

- Hoạt động không có kiến thức tiên quyết thì cho phép vào chơi ngay.
- Hoạt động cần kiến thức cụ thể chỉ yêu cầu hoàn thành bài/map Main Quest liên quan trực tiếp.
- Hoạt động có nội dung trả phí chỉ yêu cầu quyền sở hữu hợp lệ của gói tương ứng.
- Không khóa một hoạt động chỉ vì người chơi chưa đạt XP/cấp độ chung.
- Hiển thị rõ điều kiện mở khóa ngay tại hoạt động và cho phép đi tới nội dung tiên quyết liên quan.

### 4.2. Các khái niệm tiến trình được giữ lại

| Khái niệm | Vai trò |
|---|---|
| **Điểm** | Chỉ dùng khi có mục đích cụ thể: điểm của một lượt chơi, điểm đóng góp, hoặc một loại điểm thưởng đã được định nghĩa. Không mặc định cộng mọi điểm thành một chỉ số tổng. |
| **Kỷ lục/điểm riêng của game** | Thuộc game đó, dùng cho nâng cấp, so kỷ lục hoặc luật chơi của game. Không tự động chuyển thành điểm toàn cục. |
| **Mở khóa hoạt động** | Dựa trên điều kiện thực sự cần: hoạt động trước đã hoàn thành, kiến thức tiên quyết, mốc thành tích cụ thể hoặc quyền sở hữu. |
| **Thành tích/huy hiệu** | Ghi nhận một việc đã làm hoặc cột mốc đã đạt; chỉ cấp một lần theo điều kiện rõ ràng. |
| **Danh hiệu** | Thể hiện một thành tựu hoặc vai trò cụ thể. Danh hiệu kỹ năng phải dựa trên bằng chứng năng lực, không phải mua hoặc nhận quà. |
| **Quà tặng/vật phẩm** | Thuộc sở hữu và giao lưu xã hội; không tự động cấp thành tích hay quyền thắng trong thi đấu. |
| **XP/cấp độ toàn cục** | **Không sử dụng trong thiết kế hiện tại.** Không tạo công thức XP, bảng cấp hay rào chắn cấp để điều hướng người chơi qua Main Map. Chỉ xem xét lại nếu sau này có nhu cầu sản phẩm cụ thể chứng minh được giá trị. |

### 4.3. Chống nhận thưởng trùng

- Thành tích một lần, phần thưởng mốc và quyền mở khóa phải được lưu bền vững.
- Dùng khóa định danh cho từng sự kiện/mốc để việc retry hoặc mở lại app không trao cùng một phần thưởng một lần nhiều lần.
- Nhiệm vụ ngày có thể lặp lại theo ngày địa phương nhưng không bắt buộc, không có hình phạt khi bỏ lỡ và không dùng streak gây áp lực.
- Chỉ ghi nhận phần thưởng sau khi xác minh điều kiện hoàn thành; thất bại không làm mất thành tích đã có.
- Quy tắc chống trùng chỉ bảo vệ phần thưởng/thành tích thực sự tồn tại; **không tạo XP chỉ để có thứ chống cộng trùng**.

---

## 5. Tiến trình Main Quest

### 5.1. Cấu trúc chặng

Mỗi chặng gồm nhiều **bài** (lesson), mỗi bài gồm:

```
1 bài lý thuyết ngắn (1–2 phút đọc)
   ↓
1–2 bài tập tương tác (2–4 phút)
   ↓
1 màn mini-game liên quan (2–3 phút)
   ↓
Màn tổng kết bài (30 giây)
```

### 5.2. Bảng chặng

| Chặng | Số bài | Năng lượng tối đa chặng | Thời gian ước tính |
|---|---|---|---|
| **1. Code Apprentice** | 12 bài | 20 | 45–60 phút |
| **2. Game Builder** | 15 bài | 25 | 60–90 phút |
| **3. Game Creator** | 15 bài | 30 | 90–120 phút |
| **4. Game Master** | 8 bài + dự án cuối | 40 | 120–180 phút |

**Tổng Main Quest:** ~50 bài, ~6–8 giờ chơi tích lũy.

### 5.3. Điều kiện mở khóa chặng tiếp theo

| Chặng | Điều kiện |
|---|---|
| Chặng 2 | Hoàn thành chặng 1. |
| Chặng 3 | Hoàn thành chặng 2. |
| Chặng 4 | Hoàn thành chặng 3 và có ít nhất 1 game tự tạo chạy được. |

Các mini-game/hoạt động khác trên Main Map không mặc định bị khóa theo chặng. Chỉ yêu cầu hoàn thành nội dung trước khi kiến thức đó thực sự cần cho hoạt động tương ứng.

---

## 6. Mini-game — thông số thiết kế

### 6.1. Cấu trúc chung mỗi mini-game

| Thành phần | Số lượng giai đoạn đầu |
|---|---|
| Số màn | 10 màn |
| Độ khó | Tăng dần theo màn |
| Màn mở khóa | Mở tuần tự, mỗi màn 1 lần chơi thành công |
| Điểm cao | Lưu theo màn |
| Ngôi sao mỗi màn | Tối đa 3 |

### 6.2. Điều kiện nhận sao

| Số sao | Điều kiện chung |
|---|---|
| ⭐ | Hoàn thành màn |
| ⭐⭐ | Hoàn thành không chết / không lỗi |
| ⭐⭐⭐ | Hoàn thành trong giới hạn (thời gian, số lệnh, hoặc điểm) |

### 6.3. Đặc thù từng mini-game

| Mini-game | Số lệnh/màn | Điểm tối đa/màn | Ghi chú |
|---|---|---|---|
| **Robot Maze** | 3 → 15 lệnh | 100 | Số lệnh tối đa để nhận ⭐⭐⭐ |
| **Dragon Jump** | Không giới hạn | 500 | Điểm để nhận ⭐⭐⭐ |
| **Catch the Stars** | Không giới hạn | 300 | Số sao bắt được để nhận ⭐⭐⭐ |
| **Bug Hunter** | 1–3 lỗi/màn | 100 | Thời gian để nhận ⭐⭐⭐ |
| **Pet Lab** | 1–5 quy tắc | 100 | Độ phức tạp quy tắc để nhận ⭐⭐⭐ |

### 6.4. Creator Mode — tiến trình chuyển sang code thật

| Màn | Cách thao tác | Kiến thức Python tương ứng |
|---|---|---|
| 1–3 | Ghép khối lệnh bằng kéo thả | Khái niệm tuần tự |
| 4–6 | Kéo thả + chỉnh sửa tham số | Biến, hằng số |
| 7–8 | Ghép khối + xem code Python sinh ra | Cú pháp cơ bản |
| 9 | Viết dòng lệnh đơn giản | `print()`, gán biến |
| 10 | Viết hàm đơn giản | `def`, tham số |

**Hai cách đổi trò chơi — tách biệt rõ ràng:**

1. **Đổi luật qua điều khiển có cấu trúc sẵn có** (màn 1–8): trẻ chỉnh tham số,
   ghép khối, hoặc dùng mô hình lệnh do game cung cấp. Cách này **không** đòi hỏi
   interpreter và **không** chạy code tự do.
2. **Chạy code Python-like qua interpreter giới hạn** (màn 9–10, khi trẻ tự viết
   dòng lệnh/hàm): chỉ áp dụng với **tập con cú pháp đã công bố**, không phải
   Python đầy đủ. Việc **xem code sinh ra** ở màn 7–8 chỉ là hiển thị phần dịch ra
   từ khối, **không** chạy code tự do.

**Quan trọng:**
- Khi ở Creator Mode, hiển thị rõ đoạn code Python đang chạy.
- Nếu là mô phỏng, ghi chú rõ giới hạn (ví dụ: "phiên bản đơn giản hóa của Python").
- Không phải màn Creator Mode nào cũng cần interpreter; chỉ những màn có trẻ tự
  viết/chạy code mới phụ thuộc vào interpreter giới hạn.

> **Theo lộ trình:** mini-game mẫu ở giai đoạn 3 chỉ xây phần **có cấu trúc**
> (màn 1–3: ghép khối/chỉnh tham số, chạy thử bằng luật có cấu trúc). Các màn cần
> interpreter (màn 7–10) chỉ được làm sau giai đoạn 5 — xem `ROADMAP.md` mục 5.2.

---

## 7. Nhà Thành Tích — điều kiện mở khóa

### 7.1. Huy hiệu học tập

| Huy hiệu | Điều kiện | Ghi chú |
|---|---|---|
| **First Line** | Hoàn thành bài học đầu tiên | |
| **Loopy** | Hoàn thành 5 bài tập về vòng lặp | |
| **Condition Master** | Hoàn thành 10 bài tập về điều kiện | |
| **Function Wizard** | Hoàn thành 10 bài tập về hàm | |
| **Debugger** | Tìm được 20 lỗi trong Bug Hunter | |
| **Game Creator** | Hoàn thành dự án cuối chặng 4 | Danh hiệu chính |
| **Night Owl** | Hoàn thành một bài học sau 20:00 | Bí mật, không công bố |
| **Different Path** | Giải một màn Robot Maze bằng cách khác | Bí mật |
| **Perfectionist** | Đạt 3 sao tất cả màn của 1 mini-game | |

### 7.2. Điều kiện mở rộng Nhà Thành Tích

| Thành phần | Mở khóa khi |
|---|---|
| Tủ huy hiệu | Ngay từ đầu |
| Tường chiến tích | Sau khi hoàn thành 5 màn |
| Bộ sưu tập nhân vật | Sau khi có thú cưng đầu tiên (cấp 3) |
| Góc sáng tạo | Sau khi tạo game đầu tiên chạy được |
| Huy hiệu bí mật | Bí mật — không công bố điều kiện |

### 7.3. Nguyên tắc thưởng huy hiệu

- Huy hiệu **không** bị mất khi trẻ nghỉ chơi.
- Huy hiệu **không** gắn với việc xem quảng cáo.
- Huy hiệu **không** dựa trên thời gian chơi.
- Huy hiệu bí mật **không** hiển thị điều kiện mở khóa,
  chỉ thông báo khi trẻ tình cờ đạt được.

---

## 8. Nhiệm vụ ngày

### 8.1. Số lượng và thời điểm

- **3 nhiệm vụ/ngày**, reset vào 00:00 giờ địa phương.
- Không bắt buộc hoàn thành. Không phạt khi bỏ lỡ.

### 8.2. Loại nhiệm vụ

| Loại | Ví dụ | Phần thưởng/ghi nhận | Năng lượng |
|---|---|---|---|
| Học tập | Hoàn thành 1 bài Main Quest | Ghi nhận tiến trình bài học | 0 |
| Luyện tập | Đạt 3 sao trong 1 màn bất kỳ | Kỷ lục/thành tích của màn | 0 |
| Sáng tạo | Sửa và chạy thử 1 quy tắc trong Creator Mode | Ghi nhận hoạt động sáng tạo | 0 |
| Khám phá | Chơi 1 mini-game chưa từng chơi | Ghi nhận khám phá | 0 |

**Lưu ý:** nhiệm vụ ngày **không** tiêu hao năng lượng riêng —
năng lượng đã tiêu hao theo hoạt động chính.

### 8.3. Điều **không** làm với nhiệm vụ ngày

- Không dùng streak để gây áp lực.
- Không có nhiệm vụ "xem quảng cáo".
- Không có nhiệm vụ "mua gì đó".

---

## 9. Màn tổng kết & Adventure Recap

### 9.1. Cấu trúc màn tổng kết sau mỗi màn

| Thành phần | Bắt buộc | Ghi chú |
|---|---|---|
| Tiêu đề thành tựu | Có | Ví dụ: "Tuyệt vời! Bạn đã vượt mê cung!" |
| Số liệu cụ thể | Có | Màn đã vượt, sao, kỷ lục hoặc thành tích phù hợp |
| Kỹ năng vừa khám phá | Có | Gắn với kiến thức Python |
| Lời thoại nhân vật | Có | Thay đổi theo nhân vật trong màn |
| Nút "Chơi tiếp" | Có | |
| Nút "Về bản đồ" | Có | |

### 9.2. Cấu trúc Adventure Recap

Xuất hiện khi hoàn thành một chặng.

| Thành phần | Nguồn dữ liệu |
|---|---|
| Số màn đã hoàn thành | `progress_tracker` |
| Số trò chơi đã chinh phục | `progress_tracker` |
| Số kỹ năng Python đã học | `progress_tracker` |
| Số huy hiệu đã mở khóa | `achievement_engine` |
| Lời nhắn của người hướng dẫn | Sinh theo chặng, không cố định |

**Quan trọng:** mọi con số **phải lấy từ tiến trình đã lưu**, không viết cố định.

---

## 10. Cân bằng độ khó

### 10.1. Đường cong độ khó chung

- **Màn 1–3:** hướng dẫn, gần như không thể thất bại.
- **Màn 4–6:** thử thách nhẹ, có gợi ý nếu thất bại 2 lần.
- **Màn 7–8:** thử thách trung bình, có gợi ý nếu thất bại 3 lần.
- **Màn 9:** thử thách cao, không gợi ý mặc định.
- **Màn 10:** thử thách đỉnh, có thể cần chơi lại vài lần.

### 10.2. Hệ thống gợi ý

| Số lần thất bại liên tiếp | Hành động |
|---|---|
| 1 | Không can thiệp |
| 2 | Hiển thị gợi ý nhẹ (highlight, không nói đáp án) |
| 3 | Hiển thị gợi ý rõ hơn |
| 4+ | Đề xuất chơi lại màn trước hoặc luyện mini-game liên quan |

### 10.3. Không bao giờ

- Không hiển thị đáp án trực tiếp.
- Không tự động hoàn thành màn cho trẻ.
- Không trừ điểm/thành tích đã có khi thất bại.
- Không khóa màn tiếp theo vì thất bại.

---

## 11. Phần thưởng & vật phẩm

### 11.1. Loại phần thưởng

| Loại | Nguồn | Ghi chú |
|---|---|---|

| Năng lượng | Hồi theo thời gian, quảng cáo thưởng hợp lệ hoặc mốc gameplay được công bố | |
| Huy hiệu | Cột mốc, khám phá | |
| Trang phục nhân vật | Cột mốc, sự kiện | |
| Phụ kiện thú cưng | Nhiệm vụ, mini-game | |
| Danh hiệu | Chặng lớn | |
| Vật phẩm trang trí Nhà Thành Tích | Nhiệm vụ đặc biệt | |

### 11.2. Quy tắc phân phối

- Phần thưởng **không** ngẫu nhiên gây nghiện (không loot box).
- Phần thưởng **không** gắn với quảng cáo ngoài năng lượng.
- Phần thưởng **không** mất khi trẻ nghỉ chơi.
- Phần thưởng trả phí **đã công bố rõ** trước khi mua.

---

## 12. Phiên chơi & nhịp nghỉ

### 12.1. Cảnh báo phiên dài

| Thời gian chơi liên tục | Hành động |
|---|---|
| 30 phút | Hiển thị gợi ý nghỉ mắt nhẹ |
| 45 phút | Hiển thị gợi ý nghỉ mắt rõ hơn |
| 60 phút | Đề xuất nghỉ với hoạt ảnh |

**Không** chặn cứng. Chỉ gợi ý.

### 12.2. Hoạt ảnh nghỉ ngơi

- Nhân vật ngồi nghỉ, uống nước, nhìn ra xa.
- Gợi ý vận động mắt: "Nhìn ra xa 20 giây nhé!"
- Nhạc nền chuyển sang bản nhẹ hơn.
- Không giả vờ quảng cáo đã phát.

---

## 13. Bảng cấu hình đề xuất

Toàn bộ thông số trên nên được đặt trong file cấu hình JSON,
không hard-code. Ví dụ cấu trúc (không có XP/cấp độ toàn cục):

```json
{
  "energy": {
    "max_initial": 20,
    "max_cap": 40,
    "regen_minutes_per_unit": 10,
    "reward_ad_amount": 5,
    "reward_ad_daily_limit": 3
  },
  "session": {
    "reminder_minutes_1": 30,
    "reminder_minutes_2": 45,
    "reminder_minutes_3": 60
  }
}
```

---

## 14. Điều cần kiểm tra khi thử nghiệm thực tế

Các con số trên là **điểm khởi đầu**. Cần tinh chỉnh dựa trên:

1. **Thời gian phiên thực tế** — trẻ có chơi đến khi hết năng lượng không?
2. **Tỷ lệ hoàn thành chặng 1** — có quá khó hay quá dễ không?
3. **Tần suất xem quảng cáo thưởng** — có bị lạm dụng không?
4. **Điểm dừng tự nhiên** — trẻ có dừng đúng lúc không?
5. **Phản ứng với màn tổng kết** — có đọc không, có hứng thú không?

Kết quả thử nghiệm sẽ quyết định điều chỉnh cụ thể.

---

## Tài liệu liên quan

- [`PRODUCT_VISION.md`](PRODUCT_VISION.md) — triết lý sản phẩm, thế giới, mô hình kinh doanh.
- [`TECHNICAL_ARCHITECTURE.md`](TECHNICAL_ARCHITECTURE.md) — interpreter, module, lưu dữ liệu.
- [`ROADMAP.md`](ROADMAP.md) — giai đoạn triển khai và tiêu chí nghiệm thu.
- [`../README.md`](../README.md) — điểm vào dự án.
