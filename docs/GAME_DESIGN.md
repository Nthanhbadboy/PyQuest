# PyQuest — Game Design

> Tài liệu này xác định **luật chơi và thông số định lượng** của PyQuest:
> năng lượng, XP, tiến trình, phần thưởng, điều kiện mở khóa, cân bằng độ khó.
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

**Tiến trình tăng năng lượng tối đa** (khớp với bảng quyền lợi cấp độ, mục 4.3):

| Mức tối đa | Mở khóa khi | Ghi chú |
|---|---|---|
| **20** | Mặc định khi bắt đầu | |
| **25** | Đạt cấp 8 | +5 |
| **30** | Đạt cấp 15 | +5 |
| **40** | Hoàn thành chặng 4 (Game Master), tương ứng cấp 20 | +10 |

> **Quy tắc:** năng lượng tối đa chỉ tăng theo bảng trên. Trần **40** gắn với
> hoàn thành chặng cuối, **không** tự mở chỉ vì đạt một cấp trung gian.

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

## 4. Hệ thống XP & cấp độ

### 4.1. Nguồn XP

Cột **Loại** quyết định phần thưởng có được cộng lặp lại hay không.
Chi tiết chống cộng trùng ở mục 4.4.

| Hành động | XP | Loại | Ghi chú |
|---|---|---|---|
| Hoàn thành bài học Main Quest | **+10** | Một lần / bài | Chỉ lần đầu hoàn thành bài đó |
| Hoàn thành bài tập Main Quest | **+15** | Một lần / bài tập | Chỉ lần đầu hoàn thành bài tập đó |
| Hoàn thành một màn mini-game | **+20** | Một lần / màn | Theo `game_id` + `level_id` |
| Thưởng mini-game không lỗi | **+30** | Một lần / màn | Chỉ cộng cùng lúc với lần hoàn thành đầu tiên, nếu đạt điều kiện |
| Thử thách cuối chặng | **+100** | Một lần / chặng | Chỉ lần đầu hoàn thành thử thách chặng |
| Nhiệm vụ ngày | **+25** | Lặp lại, giới hạn | Tối đa 1 lần / nhiệm vụ / ngày |
| Xem lại bài cũ | **+2** | Lặp lại (giới hạn **TBD**) | Giới hạn **chưa chốt** — xem 4.4; khóa dự kiến `review:<lesson_id>:<local_day>` |
| Game tự tạo chạy được (lần đầu) | **+50** | Một lần / game tự tạo | Thưởng sáng tạo, không cộng lại mỗi lần chạy |
| Phát hiện lỗi trong Bug Hunter | **+15** | Một lần / lỗi | Mỗi lỗi (định danh duy nhất) chỉ cộng một lần |

### 4.2. Công thức cấp độ

XP cần để đi **từ cấp `n` lên cấp `n + 1`**:

```
XP_lên_cấp_tiếp(n) = 100 × n + 50 × (n − 1) = 150 × n − 50
```

Tổng XP tích lũy cần để **đạt tới cấp `L`** (bắt đầu ở cấp 1 với 0 XP) là tổng
các mốc trên:

```
XP_tổng(L) = Σ (n = 1 … L − 1) XP_lên_cấp_tiếp(n)
           = (L − 1) × (75 × L − 50)
```

| Mốc | XP cần để lên cấp tiếp theo | Tổng XP tích lũy để đạt cấp |
|---|---|---|
| 1 → 2 | 100 | Đạt cấp 2 = 100 |
| 2 → 3 | 250 | Đạt cấp 3 = 350 |
| 3 → 4 | 400 | Đạt cấp 4 = 750 |
| 4 → 5 | 550 | Đạt cấp 5 = 1.300 |
| 5 → 6 | 700 | Đạt cấp 6 = 2.000 |
| 9 → 10 | 1.300 | Đạt cấp 10 = 6.300 |
| 10 → 11 | 1.450 | Đạt cấp 11 = 7.750 |
| 17 → 18 | 2.500 | Đạt cấp 18 = 22.100 |

> **Tránh nhầm mốc:** **7.750 XP** là để **đạt cấp 11**, không phải cấp 10.
> Đạt cấp 10 cần **6.300 XP**; đạt cấp 18 cần **22.100 XP**.

**Cấp tối đa giai đoạn đầu:** 20.

### 4.3. Quyền lợi theo cấp độ

| Cấp | Mở khóa |
|---|---|
| 1 | Bắt đầu Main Quest chặng 1 |
| 3 | Thú cưng đầu tiên |
| 5 | Trang phục cho nhân vật đồng hành |
| 8 | Năng lượng tối đa +5 (lên 25) |
| 10 | Mở chặng 2 — Game Builder (**cần xem lại — xem 4.4**) |
| 12 | Khu vực sáng tạo trong Nhà Thành Tích |
| 15 | Năng lượng tối đa +5 (lên 30) |
| 18 | Mở chặng 3 — Game Creator (**cần xem lại — xem 4.4**) |
| 20 | Danh hiệu **Game Master**; hoàn thành chặng 4 mở năng lượng tối đa 40 |

> Cấp độ **không** khóa bài học đã mở. Chỉ mở thêm nội dung mới.

### 4.4. Quy tắc một lần / lặp lại & chống cộng trùng

**Nguyên tắc chung:** mọi phần thưởng "Một lần" phải được cộng **đúng một lần
cho mỗi đối tượng** (bài học, bài tập, màn, lỗi, game tự tạo, thử thách chặng),
**bất kể** trẻ hoàn thành lại bao nhiêu lần, thoát app giữa chừng, hay mở lại app.

Mỗi phần thưởng "một lần" có một **khóa định danh duy nhất** được lưu bền vững
(xem `TECHNICAL_ARCHITECTURE.md` mục 4.3 và 4.6):

| Phần thưởng | Khóa chống cộng trùng (ví dụ) |
|---|---|
| Hoàn thành bài học (+10) | `lesson:<lesson_id>` |
| Hoàn thành bài tập (+15) | `exercise:<exercise_id>` |
| Hoàn thành màn mini-game (+20) | `game:<game_id>:<level_id>` |
| Thưởng không lỗi (+30) | cùng khóa màn `game:<game_id>:<level_id>` |
| Thử thách cuối chặng (+100) | `chapter:<chapter_id>` |
| Game tự tạo chạy được (+50) | `custom_game:<custom_game_id>` |
| Phát hiện lỗi (+15) | `bug:<game_id>:<bug_id>` |

| Nhóm | Quy tắc |
|---|---|
| **Một lần** | Cộng khi **lần đầu** đối tượng được xác nhận hoàn thành. Khóa được ghi vào database; lần hoàn thành sau **không** cộng lại. |
| **Thưởng không lỗi (+30)** | Gắn với lần hoàn thành đầu tiên của màn. Không cộng lại khi chơi lại. |
| **Nhiệm vụ ngày (+25)** | Lặp lại nhưng tối đa **1 lần / nhiệm vụ / ngày**; đếm theo ngày địa phương. |
| **Ôn tập (+2)** | Lặp lại; **giới hạn chưa chốt (TBD)** — xem ghi chú dưới. Khóa dự kiến `review:<lesson_id>:<local_day>`, **tách biệt** với nhiệm vụ ngày. |
| **Thử thách cuối chặng (+100)** | Một lần / chặng. Thử lại không cộng thêm. |
| **Phát hiện lỗi (+15)** | Mỗi lỗi định danh duy nhất một lần. |

**Chống cộng trùng khi retry / mở lại app:** khóa "đã nhận thưởng một lần" và các
lượt trong ngày (nhiệm vụ ngày, quảng cáo thưởng) phải được lưu bền vững trong
SQLite và kiểm tra **trước** khi cộng. Cơ chế bảng cụ thể ở
`TECHNICAL_ARCHITECTURE.md` mục 4.3 và 4.6.

**XP ôn tập dùng khóa riêng, không dùng chung với nhiệm vụ ngày.** Việc ôn lại một
bài và "nhiệm vụ ngày" là hai nguồn thưởng khác nhau, có khóa khác nhau
(`review:<lesson_id>:<local_day>` so với `daily_quests(local_day, quest_id)`).
Trộn hai khóa này sẽ khiến việc ôn bài bị tính như hoàn thành nhiệm vụ ngày, hoặc
bị chặn oan.

> **TBD — cần quyết định sản phẩm.**
>
> **1. Rào chắn cấp độ mở chặng (chưa chốt).** Hai ngưỡng hiện tại đang quá cao so
> với lượng XP mà nội dung cung cấp:
> - Chặng 2 cần **cấp 10**, tức **6.300 XP** tích lũy (theo bảng 4.2).
> - Chặng 3 cần **cấp 18**, tức **22.100 XP** tích lũy (theo bảng 4.2).
> - Trong khi chặng 1 (12 bài) chỉ cung cấp khoảng vài trăm XP, và toàn bộ Main
>   Quest (~50 bài + mini-game) khó đạt tới các mốc trên.
>
> Cần chốt **một** hướng: (a) giữ công thức cấp độ và **hạ** ngưỡng cấp mở chặng,
> hoặc (b) giữ ngưỡng cấp và **tăng mạnh** XP/khối lượng nội dung, hoặc (c) bỏ
> rào cấp độ và mở chặng thuần theo tiến trình bài học. Không tự đặt con số mới
> trước khi quyết định.
>
> **2. Giới hạn XP ôn tập (+2) (chưa chốt).** Hiện **chưa** có cơ chế giới hạn hoàn
> chỉnh: chưa chốt số lần tối đa cho một bài, và bảng ở
> `TECHNICAL_ARCHITECTURE.md` mới chỉ **dự kiến** khóa
> `review:<lesson_id>:<local_day>`. Đề xuất mặc định "mỗi bài 1 lần XP ôn tập/ngày"
> nhưng **cần xác nhận** trước khi coi là đã chốt.

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

| Chặng | Điều kiện | Trạng thái |
|---|---|---|
| Chặng 2 | Hoàn thành chặng 1 + đạt cấp 10 | Ngưỡng cấp **TBD** (xem 4.4) |
| Chặng 3 | Hoàn thành chặng 2 + đạt cấp 18 | Ngưỡng cấp **TBD** (xem 4.4) |
| Chặng 4 | Hoàn thành chặng 3 + có ít nhất 1 game tự tạo chạy được | Chốt |

> Cấp độ chỉ là **rào chắn mềm** để đảm bảo trẻ không nhảy quá nhanh.
> Nếu trẻ hoàn thành hết bài của chặng nhưng chưa đủ cấp,
> hiển thị gợi ý ôn tập hoặc chơi mini-game liên quan.
> **Lưu ý:** điều kiện "hoàn thành chặng trước" luôn đúng; chỉ các **ngưỡng cấp
> độ** đang chờ quyết định ở mục 4.4.

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
- [`TECHNICAL_ARCHITECTURE.md`](TECHNICAL_ARCHITECTURE.md) — interpreter, module, lưu dữ liệu.
- [`ROADMAP.md`](ROADMAP.md) — giai đoạn triển khai và tiêu chí nghiệm thu.
- [`../README.md`](../README.md) — điểm vào dự án.
