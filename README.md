# PyQuest

**Build Your Game. Rule Your World.**

**Một thế giới game chung, gồm nhiều nhánh hoạt động độc lập** dành cho trẻ dưới
12 tuổi. Trẻ chọn kiểu trải nghiệm mình thích — phiêu lưu, khám phá, sưu tầm,
giải đố, sáng tạo, thi đấu hoặc chơi cùng bạn bè. **Lập trình Python là một nhánh
mạnh của PyQuest, không phải yêu cầu bắt buộc cho mọi trò chơi.**

> Trẻ mở PyQuest vì thích chơi, ở lại vì tò mò, rồi tự hỏi:
> *"Mình có thể tự làm một game như thế này không?"*
> Đó là lúc PyQuest mở thêm nhánh sáng tạo — nơi trẻ học cách tự tạo ra
> trò chơi của riêng mình.

---

## Trạng thái dự án

**Giai đoạn:** Đang xây dựng nền tảng — chưa phát hành.
**Repository:** Private.
**Nền tảng mục tiêu:** Flutter (Android trước, iOS sau).

Tiến độ hiện tại đang ở bước **chuẩn hóa tài liệu và chốt quyết định kỹ thuật**
trước khi bắt tay vào lát cắt dọc đầu tiên.

---

## PyQuest là gì?

- **Thế giới game chung** với bản đồ, nhân vật, thú cưng, kho báu và nhiệm vụ.
- **Nhiều nhánh hoạt động độc lập** — phiêu lưu/khám phá, sưu tầm, giải đố,
  sáng tạo, thi đấu; mỗi nhánh có luật chơi, tiến trình và phần thưởng riêng.
- **Một nhánh học lập trình Python** (Main Quest) từ `print()` đến tự xây game
  hoàn chỉnh — là điểm mạnh của PyQuest, nhưng không bắt buộc để chơi trò khác.
- **Sân chơi sáng tạo** — mỗi mini-game có Play Mode để chơi ngay; những game
  phù hợp có thêm Creator Mode để trẻ thay đổi luật chơi, dần chuyển sang viết code.

---

## Nguyên tắc thiết kế

1. **Main Map là hub điều hướng miễn phí, đầy đủ hoạt động cốt lõi** — không khóa sau paywall.
2. **Side Maps bán chiều sâu**, không bán lại kiến thức cơ bản.
3. **Năng lượng là tài nguyên gameplay thực sự**, không phải thanh trang trí.
4. **Quảng cáo thưởng tự nguyện** — không bắt buộc để học kiến thức cơ bản.
5. **Nghỉ ngơi là một phần của game** — có hoạt ảnh, gợi ý vận động mắt.
6. **Không gây áp lực mua Pro** — không đánh lừa, không tạo áp lực với trẻ.
7. **Tuân thủ chính sách trẻ em** — kiểm tra Google Play Families và
   mạng quảng cáo trước khi chốt cơ chế.
8. **Python phải thật hoặc mô phỏng giới hạn rõ ràng** — không tô giao diện
   giống trình soạn code rồi tuyên bố trẻ đã tạo game Python thật.
9. **Mỗi hoạt động độc lập, tiến trình riêng** — không có XP hay cấp độ toàn cục;
   mở khóa gắn trực tiếp với hoạt động hoặc kiến thức thực sự cần. Bạn bè và
   cộng đồng giúp chơi vui hơn, không phải điều kiện bắt buộc.

---

## Tính năng chính

- **Home Map** — thế giới khám phá với nhân vật dễ thương, thoại ngắn,
  nhạc nền du dương và phản hồi âm thanh mỗi lần chạm.
- **Main Map** — bản đồ trung tâm (hub) miễn phí để khám phá, chọn và mở hoạt
  động. Bản thân nó **không phải một game lớn**; thế giới và gameplay nằm trong
  các hoạt động mà nó dẫn tới.
- **Main Quest** — tuyến học Python có cấu trúc, miễn phí, là **một hoạt động
  nằm trong Main Map**.
- **Mini-game** — Robot Maze, Dragon Jump, Catch the Stars, Bug Hunter, Pet Lab;
  mỗi game có **Play Mode**; **một số game phù hợp** có thêm **Creator Mode**.
- **Nhà Thành Tích** (Achievement House) — căn nhà trong thế giới PyQuest trưng
  bày huy hiệu, chiến tích, bộ sưu tập và game do trẻ tự tạo.
- **Màn tổng kết & Adventure Recap** — ghi nhận thành tựu cụ thể, khích lệ
  không gây áp lực, thay đổi theo hành trình.
- **Side Maps** — bản đồ mở rộng mua từng gói: Pygame Island,
  AI Pet Trainer Isle, Bug Hunter Kingdom, Legendary Title Isles.
- **Năng lượng & quảng cáo thưởng** — điều tiết nhịp chơi, không chặn việc học.

> **Thuật ngữ quan trọng:** *Main Map* là **bản đồ trung tâm (hub điều hướng)
> miễn phí**; *Main Quest* là **tuyến học Python nằm trong đó**. Main Map không
> phải một game lớn — thế giới và gameplay nằm trong các hoạt động. Hai khái niệm
> khác nhau, không dùng thay thế.
> Định nghĩa đầy đủ ở [`docs/PRODUCT_VISION.md`](docs/PRODUCT_VISION.md).

---

## Cấu trúc repository

```text
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
| [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) | Luật chơi, năng lượng, mở khóa hoạt động, huy hiệu, thành tích, cân bằng độ khó |
| [`docs/TECHNICAL_ARCHITECTURE.md`](docs/TECHNICAL_ARCHITECTURE.md) | Interpreter, module, lưu dữ liệu, quảng cáo, thanh toán |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Giai đoạn triển khai, tiêu chí nghiệm thu và kiểm thử |

**Nguyên tắc tài liệu:** tài liệu sản phẩm xác định *xây trò chơi gì*;
tài liệu kỹ thuật xác định *xây bằng cách nào*; roadmap xác định
*làm gì trước và kiểm tra bằng gì*.

---

## Roadmap tóm tắt

1. **Foundation** — khung Flutter, điều hướng, lưu dữ liệu, giao diện cơ bản.
2. **Home Map** — thế giới chính, nhân vật, âm thanh.
3. **Một mini-game hoàn chỉnh** — gameplay, điểm số, lưu kỷ lục, Creator Mode.
4. **Energy & Rewarded Ads** — năng lượng, hồi theo thời gian, quảng cáo thưởng.
5. **Interpreter mô phỏng** — thực thi tập con Python-like an toàn, giới hạn tài nguyên.
6. **Main Quest** — bài học Python, bài tập, lưu tiến trình.
7. **Side Maps & Pro** — nội dung mở rộng và mua hàng.
8. **Hoàn thiện** — localization, accessibility, kiểm thử, build, phát hành.

Chi tiết xem tại [`docs/ROADMAP.md`](docs/ROADMAP.md).

**Nguyên tắc chốt từ đầu:** đừng xây cả thế giới PyQuest ngay lập tức.
Làm một **lát cắt dọc hoàn chỉnh**:
mở app → vào một trò chơi → chơi được → lưu kết quả → thoát ra mở lại vẫn còn kết quả.
Lát cắt này **không** cần interpreter Python; interpreter được xây ở giai đoạn 5.

**Về runtime:** giai đoạn đầu dùng **interpreter mô phỏng một tập con giới hạn**
(Flutter/Dart), **không** chạy Python thật. Việc nhúng Python thật chỉ được đánh
giá sau, khi mô phỏng đã chứng minh giá trị sư phạm. Chi tiết ở
[`docs/TECHNICAL_ARCHITECTURE.md`](docs/TECHNICAL_ARCHITECTURE.md).

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
