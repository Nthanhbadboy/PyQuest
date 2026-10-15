# README.md

```markdown
# PyQuest

**Build Your Game. Rule Your World.**

Game lập trình dành cho trẻ dưới 12 tuổi — nơi trẻ không chỉ chơi game
mà còn học cách **tự tạo ra trò chơi của riêng mình** bằng Python.

> Trẻ mở PyQuest vì thích chơi, ở lại vì tò mò, rồi tự hỏi:
> *"Mình có thể tự làm một game như thế này không?"*
> Đó là lúc ứng dụng chuyển từ game giải trí thành công cụ dạy lập trình thực sự.

---

## Trạng thái dự án

**Giai đoạn:** Đang xây dựng nền tảng — chưa phát hành.
**Repository:** Private.
**Nền tảng mục tiêu:** Flutter (Android trước, iOS sau).

Tiến độ hiện tại đang ở bước **chuẩn hóa tài liệu và chốt quyết định kỹ thuật**
trước khi bắt tay vào lát cắt dọc đầu tiên.

---

## PyQuest là gì?

- **Game phiêu lưu** có bản đồ, nhân vật, thú cưng, kho báu và nhiệm vụ.
- **Công cụ học Python** với lộ trình từ `print()` đến tự xây game hoàn chỉnh.
- **Sân chơi sáng tạo** — mỗi mini-game có Play Mode để chơi ngay và
  Creator Mode để trẻ thay đổi luật chơi, dần chuyển sang viết Python thật.

---

## Nguyên tắc thiết kế

1. **Main Map miễn phí và đầy đủ cốt lõi** — không khóa sau paywall.
2. **Side Maps bán chiều sâu**, không bán lại kiến thức cơ bản.
3. **Năng lượng là tài nguyên gameplay thực sự**, không phải thanh trang trí.
4. **Quảng cáo thưởng tự nguyện** — không bắt buộc để học kiến thức cơ bản.
5. **Nghỉ ngơi là một phần của game** — có hoạt ảnh, gợi ý vận động mắt.
6. **Không gây áp lực mua Pro** — không đánh lừa, không tạo áp lực với trẻ.
7. **Tuân thủ chính sách trẻ em** — kiểm tra Google Play Families và
   mạng quảng cáo trước khi chốt cơ chế.
8. **Python phải thật hoặc mô phỏng giới hạn rõ ràng** — không tô giao diện
   giống trình soạn code rồi tuyên bố trẻ đã tạo game Python thật.

---

## Tính năng chính

- **Home Map** — thế giới khám phá với nhân vật dễ thương, thoại ngắn,
  nhạc nền du dương và phản hồi âm thanh mỗi lần chạm.
- **Main Quest** — tuyến học Python miễn phí, đủ để trẻ tự làm game đơn giản.
- **Mini-game** — Robot Maze, Dragon Jump, Catch the Stars, Bug Hunter, Pet Lab;
  mỗi game có Play Mode và Creator Mode.
- **Nhà Thành Tích** — căn nhà trong thế giới PyQuest trưng bày huy hiệu,
  chiến tích, bộ sưu tập và game do trẻ tự tạo.
- **Màn tổng kết & Adventure Recap** — ghi nhận thành tựu cụ thể, khích lệ
  không gây áp lực, thay đổi theo hành trình.
- **Side Maps** — bản đồ mở rộng mua từng gói: Pygame Island,
  AI Pet Trainer Isle, Bug Hunter Kingdom, Legendary Title Isles.
- **Năng lượng & quảng cáo thưởng** — điều tiết nhịp chơi, không chặn việc học.

---

## Cấu trúc repository

```
PyQuest/
├── README.md
├── docs/
│   ├── PRODUCT_VISION.md
│   ├── GAME_DESIGN.md
│   ├── TECHNICAL_ARCHITECTURE.md
│   └── ROADMAP.md
└── app/                 # Mã nguồn Flutter (sẽ bổ sung khi bắt đầu code)
```

| Tài liệu | Vai trò |
|---|---|
| [`docs/PRODUCT_VISION.md`](docs/PRODUCT_VISION.md) | Ý tưởng sản phẩm, thế giới, nhân vật, mô hình kinh doanh, triết lý giáo dục |
| [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) | Luật chơi, năng lượng, XP, huy hiệu, thành tích, cân bằng độ khó |
| [`docs/TECHNICAL_ARCHITECTURE.md`](docs/TECHNICAL_ARCHITECTURE.md) | Python runtime, module, lưu dữ liệu, quảng cáo, thanh toán |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Giai đoạn triển khai, tiêu chí nghiệm thu và kiểm thử |

**Nguyên tắc tài liệu:** tài liệu sản phẩm xác định *xây trò chơi gì*;
tài liệu kỹ thuật xác định *xây bằng cách nào*; roadmap xác định
*làm gì trước và kiểm tra bằng gì*.

---

## Roadmap tóm tắt

1. **Foundation** — khung Flutter, điều hướng, lưu dữ liệu, giao diện cơ bản.
2. **Home Map** — thế giới chính, nhân vật, âm thanh.
3. **Một mini-game hoàn chỉnh** — gameplay, điểm số, lưu kỷ lục, Creator Mode.
4. **Main Quest** — bài học Python, bài tập, lưu tiến trình.
5. **Python runtime** — thực thi mã an toàn, giới hạn tài nguyên, xử lý lỗi.
6. **Energy & Ads** — hồi năng lượng và quảng cáo thưởng.
7. **Side Maps & Pro** — nội dung mở rộng và mua hàng.
8. **Hoàn thiện** — localization, accessibility, kiểm thử, build, phát hành.

Chi tiết xem tại [`docs/ROADMAP.md`](docs/ROADMAP.md).

**Nguyên tắc chốt từ đầu:** đừng xây cả thế giới PyQuest ngay lập tức.
Làm một **lát cắt dọc hoàn chỉnh**:
mở app → vào một trò chơi → chơi được → lưu kết quả → thoát ra mở lại vẫn còn kết quả.

---

## Cách chạy

> Sẽ cập nhật khi mã nguồn Flutter được khởi tạo ở giai đoạn Foundation.

Dự kiến:

```bash
# Yêu cầu: Flutter SDK (stable), Dart
flutter pub get
flutter run
```

---

## Đóng góp & giấy phép

Dự án đang ở giai đoạn phát triển nội bộ, chưa mở đóng góp công khai.
Giấy phép sẽ được công bố trước khi phát hành.

---

**PyQuest** — *Build Your Game. Rule Your World.*
```

---

Xong tài liệu **1/4: `README.md`**.

Khi bạn sẵn sàng, nhắn **"2"** để mình viết tiếp tài liệu thứ hai — dự kiến là `docs/PRODUCT_VISION.md`.
