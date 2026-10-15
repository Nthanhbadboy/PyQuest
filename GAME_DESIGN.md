# docs/GAME_DESIGN.md

```markdown
# PyQuest — Game Design

> Tài liệu này xác định **luật chơi và thông số định lượng** của PyQuest:
> năng lượng, XP, tiến trình, phần thưởng, điều kiện mở khóa, cân bằng độ khó.
> Tài liệu **không** định nghĩa lại triết lý sản phẩm (xem `PRODUCT_VISION.md`)
> và **không** đi vào quyết định kỹ thuật (xem `TECHNICAL_ARCHITECTURE.md`).

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
| Năng lượng tối đa (ban đầu) | **20** | Có thể tăng qua tiến trình |
| Năng lượng tối đa (trần) | **40** | Đạt được ở Game Master |
| Thời gian hồi 1 đơn vị | **10 phút** | Hồi đầy 20 đơn vị trong ~3h20 |
| Năng lượng nhận khi xem quảng cáo thưởng | **+5** | Tối đa 3 lần/ngày |
| Năng lượng khởi đầu khi tạo tài khoản | **20** | Đầy bình |

### 3.2. Mức tiêu hao theo hoạt động

| Hoạt động | Tiêu hao | Ghi chú |
|---|---|---|
| Chơi mini-game (Play Mode) | **2** | Một màn |
| Chơi mini-game (Creator Mode) | **0** | Không tiêu hao — đây là học, không phải chơi |
| Bài học Main Quest | **1** | Một bài học lý thuyết |
| Bài tập Main Quest | **1** | Một bài tập code |
| Thử thách cuối chặng | **3** | Chỉ khi bắt đầu, không tính khi thử lại |
| Nhiệm vụ ngày | **2** | Mỗi nhiệm vụ |
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
- Tối đa **3 lần/ngày**, reset vào 00:00 giờ địa phương.
- Chỉ cộng **+5** năng lượng sau khi SDK xác nhận hợp lệ.
- Nếu quảng cáo thất bại: không trừ lượt, không trừ năng lượng, hiển thị thông báo nhẹ.

### 3.5. Điều **không** xảy ra khi hết năng lượng

- Không khóa Main Map.
- Không khóa bài học đã hoàn thành.
- Không khóa Nhà Thành Tích, bộ sưu tập, truyện.
- Không hiển thị popup gây áp lực mua Pro.

---

## 4. Hệ thống XP & cấp độ

### 4.1. Nguồn XP

| Hành động | XP nhận được | Ghi chú |
|---|---|---|
| Hoàn thành bài học Main Quest | **+10** | Lần đầu |
| Hoàn thành bài tập Main Quest | **+15** | Lần đầu |
| Hoàn thành một màn mini-game | **+20** | Lần đầu |
| Hoàn thành mini-game không lỗi | **+30** | Thưởng thêm |
| Thử thách cuối chặng | **+100** | Cột mốc lớn |
| Nhiệm vụ ngày | **+25** | Mỗi nhiệm vụ |
| Xem lại bài cũ | **+2** | Khuyến khích ôn tập |
| Tự tạo game chạy được | **+50** | Thưởng sáng tạo |
| Phát hiện lỗi trong Bug Hunter | **+15** | Mỗi lỗi tìm được |

### 4.2. Công thức cấp độ

XP cần để lên cấp `n` (tính từ cấp 1):

```
XP_cần(n) = 100 × n + 50 × (n − 1)
```

| Cấp | XP cần để lên cấp tiếp theo | Tổng XP tích lũy |
|---|---|---|
| 1 → 2 | 100 | 100 |
| 2 → 3 | 250 | 350 |
| 3 → 4 | 400 | 750 |
| 4 → 5 | 550 | 1.300 |
| 5 → 6 | 700 | 2.000 |
| 10 → 11 | 1.450 | 7.750 |

**Cấp tối đa giai đoạn đầu:** 20.

### 4.3. Quyền lợi theo cấp độ

| Cấp | Mở khóa |
|---|---|
| 1 | Bắt đầu Main Quest chặng 1 |
| 3 | Thú cưng đầu tiên |
| 5 | Trang phục cho nhân vật đồng hành |
| 8 | Năng lượng tối đa +5 (lên 25) |
| 10 | Mở chặng 2 — Game Builder |
| 12 | Khu vực sáng tạo trong Nhà Thành Tích |
| 15 | Năng lượng tối đa +10 (lên 30) |
| 18 | Mở chặng 3 — Game Creator |
| 20 | Danh hiệu **Game Master** tạm thời |

> Cấp độ **không** khóa bài học đã mở. Chỉ mở thêm nội dung mới.

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
| Chặng 2 | Hoàn thành chặng 1 + đạt cấp 10 |
| Chặng 3 | Hoàn thành chặng 2 + đạt cấp 18 |
| Chặng 4 | Hoàn thành chặng 3 + có ít nhất 1 game tự tạo chạy được |

> Cấp độ chỉ là **rào chắn mềm** để đảm bảo trẻ không nhảy quá nhanh.
> Nếu trẻ hoàn thành hết bài của chặng nhưng chưa đủ cấp,
> hiển thị gợi ý ôn tập hoặc chơi mini-game liên quan.

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

**Quan trọng:** khi ở Creator Mode, hiển thị rõ code Python đang chạy.
Nếu là mô phỏng, ghi chú rõ giới hạn (ví dụ: "phiên bản đơn giản hóa của Python").

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

| Loại | Ví dụ | XP | Năng lượng |
|---|---|---|---|
| Học tập | Hoàn thành 1 bài Main Quest | +25 | 0 |
| Luyện tập | Đạt 3 sao trong 1 màn bất kỳ | +25 | 0 |
| Sáng tạo | Sửa và chạy thử 1 quy tắc trong Creator Mode | +25 | 0 |
| Khám phá | Chơi 1 mini-game chưa từng chơi | +25 | 0 |

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
| Số liệu cụ thể | Có | Màn đã vượt, sao, XP |
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
- Không phạt XP khi thất bại.
- Không khóa màn tiếp theo vì thất bại.

---

## 11. Phần thưởng & vật phẩm

### 11.1. Loại phần thưởng

| Loại | Nguồn | Ghi chú |
|---|---|---|
| XP | Mọi hoạt động học tập | |
| Năng lượng | Quảng cáo thưởng, lên cấp | |
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
không hard-code. Ví dụ cấu trúc:

```json
{
  "energy": {
    "max_initial": 20,
    "max_cap": 40,
    "regen_minutes_per_unit": 10,
    "reward_ad_amount": 5,
    "reward_ad_daily_limit": 3
  },
  "xp": {
    "lesson_complete": 10,
    "exercise_complete": 15,
    "minigame_complete": 20,
    "minigame_no_error_bonus": 30,
    "chapter_challenge": 100,
    "daily_quest": 25,
    "review_lesson": 2,
    "custom_game_runs": 50,
    "bug_found": 15
  },
  "level": {
    "formula": "100 * n + 50 * (n - 1)",
    "max_level": 20
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
- [`TECHNICAL_ARCHITECTURE.md`](TECHNICAL_ARCHITECTURE.md) — Python runtime, module, lưu dữ liệu.
- [`ROADMAP.md`](ROADMAP.md) — giai đoạn triển khai và tiêu chí nghiệm thu.
```

---

Xong tài liệu **3/5: `docs/GAME_DESIGN.md`**.

Nhắn **"4"** để mình viết tiếp tài liệu thứ tư — dự kiến là `docs/TECHNICAL_ARCHITECTURE.md` (Flutter, Python runtime, lưu dữ liệu, module, quảng cáo, thanh toán).
