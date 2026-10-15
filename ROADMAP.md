# docs/ROADMAP.md

```markdown
# PyQuest — Roadmap

> Tài liệu này xác định **làm gì trước, làm gì sau, và kiểm tra bằng gì**.
> Mỗi giai đoạn có mục tiêu rõ ràng, phạm vi cụ thể và tiêu chí nghiệm thu.
> Tài liệu **không** định nghĩa lại luật chơi (xem `GAME_DESIGN.md`)
> và **không** định nghĩa lại quyết định kỹ thuật (xem `TECHNICAL_ARCHITECTURE.md`).

---

## 1. Nguyên tắc xuyên suốt roadmap

### 1.1. Lát cắt dọc trước, mở rộng sau

**Đừng xây cả thế giới PyQuest ngay lập tức.**
Làm một **lát cắt dọc hoàn chỉnh**:

```
Mở app → vào một trò chơi → chơi được → lưu kết quả → thoát ra mở lại vẫn còn kết quả.
```

Khi lát cắt đó chạy ổn, phần còn lại chủ yếu là **mở rộng theo module**.

### 1.2. Mỗi giai đoạn có tiêu chí nghiệm thu riêng

- Chỉ chuyển sang giai đoạn kế tiếp khi đạt tiêu chí nghiệm thu.
- Module đã ổn định **không bị sửa** chỉ vì thêm game mới.
- Nếu phải sửa module cũ để thêm nội dung mới → thiết kế interface đã sai, cần xem lại.

### 1.3. Thứ tự triển khai Nhà Thành Tích

- **Thiết kế nền tảng ngay từ đầu** — dữ liệu, sự kiện, interface.
- **Chỉ triển khai giao diện đầy đủ** sau khi có một mini-game mẫu chạy hoàn chỉnh.
- Lý do: cần kiểm tra cả vòng đời:
  chơi → ghi nhận tiến trình → trao thành tích → xem tổng kết → quay lại thế giới.

### 1.4. Kiểm thử theo giai đoạn, không tràn lan

- Không viết test cho từng hàm nhỏ.
- Kiểm tra theo rủi ro thực tế.
- Test cuối theo chuyến phiêu lưu hoàn chỉnh.
- Chi tiết xem mục 10.

---

## 2. Tổng quan các giai đoạn

| # | Giai đoạn | Mục tiêu chính | Thời lượng dự kiến |
|---|---|---|---|
| 1 | **Foundation** | Khung Flutter, điều hướng, lưu dữ liệu, giao diện cơ bản | Ngắn |
| 2 | **Home Map** | Thế giới chính, nhân vật, âm thanh | Trung bình |
| 3 | **Một mini-game hoàn chỉnh** | Gameplay, điểm số, lưu kỷ lục, Creator Mode | Trung bình |
| 4 | **Main Quest** | Bài học Python, bài tập, lưu tiến trình | Dài |
| 5 | **Python runtime** | Thực thi mã an toàn, giới hạn tài nguyên, xử lý lỗi | Trung bình |
| 6 | **Energy & Ads** | Hồi năng lượng và quảng cáo thưởng | Ngắn |
| 7 | **Side Maps & Pro** | Nội dung mở rộng và mua hàng | Trung bình |
| 8 | **Hoàn thiện** | Localization, accessibility, kiểm thử, build, phát hành | Dài |

**Lưu ý:** thời lượng chỉ là ước lượng tương đối — quan trọng là **thứ tự** và **tiêu chí nghiệm thu**, không phải deadline cứng.

---

## 3. Giai đoạn 1 — Foundation

### 3.1. Mục tiêu

Dựng khung ứng dụng Flutter chạy được, có điều hướng, lưu dữ liệu cơ bản,
và giao diện đủ để bắt đầu gắn module.

### 3.2. Phạm vi

- Khởi tạo project Flutter, cấu trúc thư mục theo `TECHNICAL_ARCHITECTURE.md`.
- Cấu hình build Android, chạy được trên thiết bị thật.
- Điều hướng cơ bản giữa các màn hình rỗng.
- Database SQLite với schema ban đầu (`settings`, `progress`).
- Repository pattern cho việc đọc/ghi dữ liệu.
- File cấu hình `game_config.json` với các thông số từ `GAME_DESIGN.md`.
- Màn hình khởi động + màn hình home tạm.

### 3.3. Không làm trong giai đoạn này

- Không làm Home Map đẹp.
- Không làm mini-game.
- Không tích hợp quảng cáo, thanh toán.
- Không làm Python runtime.

### 3.4. Tiêu chí nghiệm thu

- [ ] App build và chạy được trên Android thật.
- [ ] Điều hướng giữa 3–4 màn hình rỗng hoạt động trơn tru.
- [ ] Ghi một giá trị vào SQLite, thoát app, mở lại, đọc được giá trị cũ.
- [ ] `game_config.json` load được và đọc đúng thông số.
- [ ] Cấu trúc thư mục khớp với `TECHNICAL_ARCHITECTURE.md`.

---

## 4. Giai đoạn 2 — Home Map

### 4.1. Mục tiêu

Dựng thế giới chính có nhân vật, âm thanh, và cảm giác "đây là một trò chơi"
chứ không phải màn hình danh sách bài học.

### 4.2. Phạm vi

- Home Map có nền, địa điểm, các điểm đến (mini-game, Main Quest).
- Nhân vật dễ thương: robot tò mò, rồng con, mèo tìm lỗi code.
- Thoại ngắn, hài hước, liên quan nhiệm vụ tiếp theo.
- Nhạc nền du dương.
- Âm thanh tương tác phản hồi mỗi lần chạm.
- Bật/tắt âm thanh, nhạc nền trong settings.
- Khám phá không theo thứ tự: trẻ có thể chạm vào địa điểm bất kỳ.

### 4.3. Không làm trong giai đoạn này

- Không làm mini-game thật (chỉ placeholder khi chạm vào địa điểm).
- Không làm Main Quest bài học.

### 4.4. Tiêu chí nghiệm thu

- [ ] Home Map hiển thị đúng, không bị vỡ layout trên các kích thước màn hình phổ biến.
- [ ] Chạm vào địa điểm có phản hồi âm thanh + hiệu ứng.
- [ ] Nhân vật xuất hiện với thoại ngắn khi mở app.
- [ ] Tắt/bật âm thanh hoạt động và được lưu lại sau khi thoát app.
- [ ] Trẻ (hoặc người test) hiểu được "đây là nơi để khám phá".

---

## 5. Giai đoạn 3 — Một mini-game hoàn chỉnh

### 5.1. Mục tiêu

Đây là **giai đoạn quan trọng nhất** của PyQuest.
Một mini-game hoàn chỉnh, chạy ổn, lưu kết quả, có Creator Mode cơ bản.

**Mini-game đề xuất:** **Robot Maze** — vì nó liên kết trực tiếp với
tư duy thuật toán và dễ chuyển sang code Python.

### 5.2. Phạm vi

**Play Mode:**
- 10 màn, độ khó tăng dần theo `GAME_DESIGN.md`.
- Chọn lệnh lên/xuống/trái/phải để đưa robot đến kho báu.
- Điểm số, sao (1–3), hiệu ứng âm thanh.
- Lưu điểm cao, màn đã mở.

**Creator Mode:**
- Ghép khối lệnh bằng kéo thả (màn 1–3).
- Xem code Python sinh ra (màn 7–8).
- Viết dòng lệnh đơn giản (màn 9–10).

**Tích hợp nền tảng:**
- Phát sự kiện `level_completed` và `game_completed`.
- Ghi vào `progress_tracker`.
- Huy hiệu đơn giản: **First Line** (khi hoàn thành màn 1).
- Màn tổng kết sau mỗi màn, có nhân vật và lời thoại.

### 5.3. Không làm trong giai đoạn này

- Không làm 5 mini-game cùng lúc.
- Không làm Creator Mode đầy đủ — chỉ đủ để chứng minh luồng.
- Không làm Side Maps.

### 5.4. Tiêu chí nghiệm thu

**Đây là lát cắt dọc quan trọng nhất — phải đạt tất cả:**

- [ ] Mở app → vào Home Map → chạm vào Robot Maze → chơi được màn 1.
- [ ] Hoàn thành màn → thấy màn tổng kết với số liệu cụ thể.
- [ ] Điểm cao được lưu vào SQLite.
- [ ] Thoát app → mở lại → màn đã mở vẫn còn, điểm cao vẫn còn.
- [ ] Huy hiệu **First Line** xuất hiện sau khi hoàn thành màn 1.
- [ ] Creator Mode cho phép ghép khối và chạy thử ít nhất 1 màn.
- [ ] Không crash khi chơi liên tục 15 phút.
- [ ] Phát sự kiện `level_completed` và `game_completed` đúng chuẩn.

**Nếu tiêu chí này chưa đạt → chưa chuyển sang giai đoạn 4.**

---

## 6. Giai đoạn 4 — Main Quest

### 6.1. Mục tiêu

Tuyến học Python miễn phí, đủ để trẻ thực sự biết lập trình cơ bản.

### 6.2. Phạm vi

**Chặng 1 — Code Apprentice (12 bài):**
- In chữ, biến, số, chuỗi, phép toán, điều kiện.
- Điều khiển nhân vật bằng lệnh Python đầu tiên.

**Chặng 2 — Game Builder (15 bài):**
- Vòng lặp, hàm, danh sách, nhập liệu, tọa độ.
- Điểm số, mạng sống, điều kiện thắng thua.

**Chặng 3 — Game Creator (15 bài):**
- Kết hợp kiến thức để tự xây game hoàn chỉnh.
- Nhân vật, chướng ngại vật, va chạm, điểm thưởng, nhiều màn, xử lý lỗi.

**Chặng 4 — Game Master (8 bài + dự án cuối):**
- Dự án cuối tuyến miễn phí.
- Game chơi lại được, lưu thành tích.
- Nhận danh hiệu **Game Creator**.

**Hệ thống hỗ trợ:**
- XP, cấp độ theo `GAME_DESIGN.md`.
- Nhiệm vụ ngày (3/ngày).
- Màn tổng kết sau mỗi bài.
- Adventure Recap sau mỗi chặng.
- Nhà Thành Tích đầy đủ.

### 6.3. Không làm trong giai đoạn này

- Không làm Side Maps.
- Không làm Python runtime đầy đủ (dùng mô phỏng từ giai đoạn 5).

### 6.4. Tiêu chí nghiệm thu

- [ ] Chặng 1 hoàn chỉnh, trẻ (hoặc người test) hoàn thành được 12 bài.
- [ ] XP, cấp độ, mở khóa chặng hoạt động đúng `GAME_DESIGN.md`.
- [ ] Màn tổng kết hiển thị số liệu lấy từ tiến trình đã lưu.
- [ ] Adventure Recap hiển thị đúng số liệu sau chặng 1.
- [ ] Nhà Thành Tích hiển thị huy hiệu, tường chiến tích, bộ sưu tập.
- [ ] Nhiệm vụ ngày reset đúng 00:00 giờ địa phương.
- [ ] Huy hiệu bí mật không lộ điều kiện.
- [ ] Chặng 2 mở được khi đủ điều kiện.

---

## 7. Giai đoạn 5 — Python runtime

### 7.1. Mục tiêu

Thực thi mã Python an toàn, giới hạn tài nguyên, xử lý lỗi thân thiện.

### 7.2. Phạm vi

**Giai đoạn 5a — Mô phỏng:**
- Interpreter mô phỏng bằng Dart theo `TECHNICAL_ARCHITECTURE.md`.
- Hỗ trợ: `print()`, biến, số, chuỗi, `if/else`, `for`, `while`,
  danh sách, hàm đơn giản.
- Không hỗ trợ: import, file I/O, mạng, `eval`, `exec`, class phức tạp.
- Giới hạn tài nguyên: 3 giây, 100.000 bước, 32 MB, độ sâu đệ quy 50.

**Giai đoạn 5b — Đánh giá Python thật:**
- Thử nghiệm `chaquopy`, `python-for-android`, hoặc RustPython/WASM.
- So sánh với mô phỏng về: hiệu năng, độ ổn định, trải nghiệm trẻ.
- **Chỉ chuyển** nếu mô phỏng đã chứng minh giá trị sư phạm
  và Python thật mang lại lợi ích rõ ràng.

### 7.3. Xử lý lỗi

- Lỗi cú pháp: hiển thị thân thiện, gợi ý sửa.
- Lỗi runtime: dừng an toàn, không crash app.
- Vượt giới hạn: thông báo rõ, không hiển thị lỗi kỹ thuật thô.

### 7.4. Tiêu chí nghiệm thu

- [ ] Chạy được code Python cơ bản (in, biến, điều kiện, vòng lặp, hàm).
- [ ] Vòng lặp vô hạn dừng an toàn sau 3 giây, không crash.
- [ ] Đệ quy sâu dừng an toàn ở độ sâu 50.
- [ ] Lỗi cú pháp hiển thị thông báo thân thiện với trẻ.
- [ ] Output giới hạn ở 10 KB.
- [ ] Không truy cập được file hệ thống, mạng, module hệ thống.
- [ ] Creator Mode của ít nhất 1 mini-game dùng runtime này.

---

## 8. Giai đoạn 6 — Energy & Ads

### 8.1. Mục tiêu

Năng lượng hoạt động đúng luật, quảng cáo thưởng tự nguyện, an toàn cho trẻ.

### 8.2. Phạm vi

- Năng lượng hồi theo thời gian thực, kể cả khi tắt app.
- Hiển thị thời gian hồi đơn vị tiếp theo.
- Tiêu hao theo `GAME_DESIGN.md`.
- Quảng cáo thưởng AdMob rewarded.
- Giới hạn 3 lần/ngày, reset 00:00 giờ địa phương.
- Chỉ cộng thưởng sau khi SDK xác nhận hợp lệ.
- Xử lý quảng cáo thất bại: không trừ lượt, không trừ năng lượng.

### 8.3. Không làm trong giai đoạn này

- Không dùng interstitial, banner, native ads.
- Không tự động phát quảng cáo.
- Không hiển thị quảng cáo khi trẻ đang trong bài học.

### 8.4. Tiêu chí nghiệm thu

- [ ] Năng lượng hồi đúng tốc độ (10 phút/đơn vị).
- [ ] Tắt app 30 phút → mở lại → năng lượng đã hồi đúng.
- [ ] Hết năng lượng vẫn truy cập được nội dung miễn phí.
- [ ] Xem quảng cáo thưởng → cộng +5 năng lượng sau khi SDK xác nhận.
- [ ] Quảng cáo thất bại → không trừ lượt, không trừ năng lượng.
- [ ] Vượt 3 lần/ngày → nút ẩn hoặc vô hiệu hóa.
- [ ] Không có quảng cáo nào chen ngang bài học.
- [ ] Đã kiểm tra chính sách Google Play Families.

---

## 9. Giai đoạn 7 — Side Maps & Pro

### 9.1. Mục tiêu

Mở rộng thế giới và mô hình kinh doanh, nhưng không khóa Main Quest.

### 9.2. Phạm vi

**Side Maps (mua từng gói):**
- Pygame Island.
- AI Pet Trainer Isle.
- Bug Hunter Kingdom.
- Legendary Title Isles.

**Pro:**
- Bỏ quảng cáo thuộc phạm vi Pro.
- Quyền lợi bổ sung đã công bố rõ.
- Không khóa Main Quest.

**Hạ tầng:**
- Side Map Shop với thông tin rõ ràng.
- Parental gate trước màn hình mua hàng.
- Google Play Billing.
- Xác minh purchase token qua billing.
- Khôi phục giao dịch khi đổi thiết bị.

### 9.3. Tiêu chí nghiệm thu

- [ ] Trẻ xem được Side Map Shop với giá và nội dung rõ ràng.
- [ ] Parental gate hoạt động trước khi vào màn hình mua hàng.
- [ ] Mua Side Map → mở được nội dung.
- [ ] Thoát app → mở lại → quyền sở hữu vẫn còn.
- [ ] Đổi thiết bị → khôi phục được giao dịch.
- [ ] Mô phỏng purchase token giả → không mở nội dung.
- [ ] Pro ẩn toàn bộ quảng cáo trong phạm vi gói.
- [ ] Main Quest vẫn truy cập được khi không mua gì.

---

## 10. Giai đoạn 8 — Hoàn thiện

### 10.1. Mục tiêu

Đưa PyQuest từ "chạy được" sang "sẵn sàng phát hành".

### 10.2. Phạm vi

- **Localization:** ít nhất tiếng Việt và tiếng Anh.
- **Accessibility:** font size, contrast, hỗ trợ screen reader cơ bản.
- **Kiểm thử cuối theo chuyến phiêu lưu** (xem mục 11).
- **Tối ưu hiệu năng:** khởi động, load màn, FPS.
- **Tối ưu dung lượng:** nén asset, tải Side Maps theo gói.
- **Build release:** ký, cấu hình ProGuard/R8.
- **Chuẩn bị store listing:** mô tả, ảnh, video, phân loại độ tuổi.
- **Kiểm tra chính sách:** Google Play Families, quyền riêng tư trẻ em.

### 10.3. Tiêu chí nghiệm thu

- [ ] App khởi động < 3 giây trên thiết bị tầm trung.
- [ ] Mini-game chạy 60 FPS ổn định.
- [ ] Dung lượng app < 150 MB.
- [ ] Bật/tắt được âm thanh, nhạc nền, hoạt ảnh.
- [ ] Localization hoạt động, không có chuỗi hard-code.
- [ ] Tất cả kịch bản kiểm thử cuối (mục 11) đạt.
- [ ] Build release cài được trên thiết bị thật.
- [ ] Đã kiểm tra chính sách trước khi submit.

---

## 11. Kiểm thử cuối theo chuyến phiêu lưu

Đây là **mục tiêu kiểm chứng cuối** của PyQuest, không phải lý do
dựng framework test nặng nề. Thực hiện ở giai đoạn 8, nhưng có thể chạy thử sớm.

### 11.1. Sáu kịch bản đại diện

| # | Kịch bản | Mục tiêu kiểm chứng |
|---|---|---|
| 1 | **Người chơi mới** — mở app → khám phá bản đồ → chơi mini-game → học Python → nhận thành tích | Luồng onboarding hoàn chỉnh |
| 2 | **Người chơi quay lại** — hoàn thành một phần → đóng app → mở lại → tiếp tục đúng tiến trình | Lưu dữ liệu bền vững |
| 3 | **Người chơi hết năng lượng** — chuyển sang nội dung miễn phí → chờ hồi hoặc nhận thưởng quảng cáo hợp lệ | Năng lượng không chặn việc học |
| 4 | **Người chơi sáng tạo** — sửa quy tắc mini-game → chạy thử → gặp lỗi → sửa lỗi → hoàn thành trò chơi | Creator Mode + Python runtime |
| 5 | **Người chơi Pro** — mua hoặc khôi phục Pro → kiểm tra quyền lợi; mô phỏng lỗi giao dịch và trạng thái chưa xác minh | Thanh toán an toàn |
| 6 | **Người chơi gặp sự cố** — mất mạng, dữ liệu chưa lưu, runtime lỗi → app xử lý an toàn | Xử lý lỗi, không mất tiến trình |

### 11.2. Điểm kiểm tra bắt buộc

Bốn lỗi nghiêm trọng **phải** được kiểm tra ở mọi giai đoạn liên quan:

| Lỗi | Cách kiểm tra |
|---|---|
| **Mất dữ liệu** | Thoát app, mở lại, xác nhận trạng thái còn nguyên |
| **Cộng thưởng sai** | Kiểm tra luồng nhận XP, năng lượng, huy hiệu |
| **Vượt giới hạn Python** | Chạy code gây vòng lặp vô hạn, kiểm tra dừng an toàn |
| **Xác nhận Pro sai** | Mô phỏng purchase token giả, kiểm tra không mở nội dung |

---

## 12. Điều **không** làm trong roadmap này

Để giữ dự án tập trung, roadmap **chủ động không** bao gồm:

- Subscription định kỳ.
- Cloud sync ở giai đoạn đầu.
- Multiplayer.
- Social features (chat, bạn bè).
- Backend server phức tạp.
- Nhiều mini-game cùng lúc ở giai đoạn 3.
- iOS ở giai đoạn đầu.
- Analytics framework nặng.
- Framework test cồng kềnh.

Những mục này có thể được đánh giá lại sau khi PyQuest phát hành và có phản hồi thực tế.

---

## 13. Trạng thái hiện tại & việc cần làm ngay

### 13.1. Trạng thái

- Tài liệu sản phẩm: **đã tách xong** (`PRODUCT_VISION.md`, `GAME_DESIGN.md`).
- Tài liệu kỹ thuật: **đã chốt quyết định chính** (`TECHNICAL_ARCHITECTURE.md`).
- Mã nguồn: **chưa bắt đầu**.

### 13.2. Việc cần làm theo thứ tự ưu tiên

1. **Chốt phạm vi Python runtime** — đã chốt: mô phỏng giai đoạn đầu, đánh giá lại sau.
2. **Định lượng hóa Game Design** — đã có trong `GAME_DESIGN.md`.
3. **Xác định cấu trúc code & tiêu chí nghiệm thu** — đã có trong tài liệu này.
4. **Phân biệt Main Map và Main Quest** — đã chốt trong `PRODUCT_VISION.md`.
5. **Chốt ranh giới dữ liệu giữa các module** — đã có trong `TECHNICAL_ARCHITECTURE.md`.
6. **Tách tài liệu** — đã hoàn thành (README + 4 tài liệu trong `docs/`).
7. **Bắt đầu lát cắt dọc đầu tiên** — giai đoạn 1 → 3.

### 13.3. Bước tiếp theo cụ thể

Bắt đầu **giai đoạn 1 — Foundation**:

- Khởi tạo project Flutter.
- Dựng cấu trúc thư mục theo `TECHNICAL_ARCHITECTURE.md`.
- Cấu hình SQLite với schema ban đầu.
- Tạo `game_config.json`.
- Dựng 3–4 màn hình rỗng và điều hướng.
- Kiểm tra: ghi SQLite, thoát app, mở lại, đọc được.

Khi giai đoạn 1 đạt tiêu chí nghiệm thu → chuyển sang giai đoạn 2.

---

## 14. Nguyên tắc cuối cùng

> Trẻ mở PyQuest vì thích chơi, ở lại vì tò mò, rồi tự hỏi:
> **"Mình có thể tự làm một game như thế này không?"**
> Đó là lúc ứng dụng chuyển từ game giải trí thành công cụ dạy lập trình thực sự.

Roadmap này tồn tại để phục vụ khoảnh khắc đó —
không phải để hoàn thành checklist, không phải để đạt deadline,
mà để từng bước xây nên một thế giới mà trẻ thực sự muốn ở lại
và đủ công cụ để trẻ tự tạo ra thế giới của riêng mình.

---

## Tài liệu liên quan

- [`PRODUCT_VISION.md`](PRODUCT_VISION.md) — triết lý sản phẩm, thế giới, mô hình kinh doanh.
- [`GAME_DESIGN.md`](GAME_DESIGN.md) — luật chơi, năng lượng, XP, cân bằng độ khó.
- [`TECHNICAL_ARCHITECTURE.md`](TECHNICAL_ARCHITECTURE.md) — Python runtime, module, lưu dữ liệu.
```

---

Xong tài liệu **5/5: `docs/ROADMAP.md`**.

## Tổng kết bộ tài liệu PyQuest

Bạn đã có đủ bộ tài liệu để bắt đầu:

| # | File | Vai trò |
|---|---|---|
| 1 | `README.md` | Giới thiệu dự án, trạng thái, cách chạy |
| 2 | `docs/PRODUCT_VISION.md` | Triết lý sản phẩm, thế giới, nhân vật, mô hình kinh doanh |
| 3 | `docs/GAME_DESIGN.md` | Luật chơi, năng lượng, XP, huy hiệu, cân bằng độ khó |
| 4 | `docs/TECHNICAL_ARCHITECTURE.md` | Flutter, Python runtime, module, lưu dữ liệu, quảng cáo, thanh toán |
| 5 | `docs/ROADMAP.md` | Giai đoạn triển khai, tiêu chí nghiệm thu, kiểm thử |

**Nguyên tắc đã được duy trì xuyên suốt cả 5 tài liệu:**
- Tài liệu sản phẩm xác định *xây trò chơi gì*.
- Tài liệu kỹ thuật xác định *xây bằng cách nào*.
- Roadmap xác định *làm gì trước và kiểm tra bằng gì*.
- Không có nội dung đánh giá README hay hướng dẫn cá nhân trong tài liệu dự án.
- Mọi con số gameplay đặt trong `game_config.json`, không hard-code.
- Không test tràn lan, tập trung điểm rủi ro cao, test cuối theo chuyến phiêu lưu.

**Bước tiếp theo:** bắt đầu **giai đoạn 1 — Foundation**, cụ thể là khởi tạo project Flutter và dựng cấu trúc thư mục theo `TECHNICAL_ARCHITECTURE.md`. Khi đạt tiêu chí nghiệm thu giai đoạn 1, chuyển sang giai đoạn 2 (Home Map), rồi giai đoạn 3 (lát cắt dọc quan trọng nhất).
