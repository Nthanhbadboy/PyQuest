# PyQuest — Roadmap

> **Trạng thái hiện hành r53 · 2026-10-18:** xem [source / evidence / release policy](PROJECT_STATUS.md).
> Tầm nhìn, tiêu chí kế hoạch và source đã có không đồng nghĩa tính năng đã được nghiệm thu.
> PQC-011 đã ACCEPTED tại6dc8ca8. **R1-A/Main Map READY_FOR_CODE** theo
> [PQC-020](implementation/coordination/tasks/PQC-020.md); chỉ static scene +sáu route
> hiện có, không hoàn tất toànR1. Các mốc r44/r47 bên dưới giữ làm lịch sử.

> **Đồng bộ mở rộng · 2026-10-18:** nhà → đất → đảo, nhiệm vụ liên kết,
> thăm nhà có hoạt động, thú thông minh, bạn bè/Arena đều thuộc thiết kế sản phẩm.
> [Thiết kế thế giới thống nhất](design/WORLD_EXPANSION_REDESIGN.md) nối các màn và
> phân biệt rõ luật đề xuất với source đã chạy. Không coi prototype là tính năng APK.

> Tài liệu này xác định **làm gì trước, làm gì sau, và kiểm tra bằng gì**.
> Mỗi giai đoạn có mục tiêu rõ ràng, phạm vi cụ thể và tiêu chí nghiệm thu.
> Tài liệu **không** định nghĩa lại luật chơi (xem `GAME_DESIGN.md`)
> và **không** định nghĩa lại quyết định kỹ thuật (xem `TECHNICAL_ARCHITECTURE.md`).
>
> **Thứ tự phụ thuộc:** interpreter mô phỏng (giai đoạn 5) đứng **trước** Main Quest
> (giai đoạn 6) vì các màn Main Quest chạy code cần nó. Lát cắt dọc đầu tiên
> (giai đoạn 3) **không** cần interpreter.

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

### 1.5. Tầm nhìn sản phẩm không đồng nghĩa roadmap phiên bản đầu

- Có thể triển khai từng phần, nhưng phải ghi rõ phần nào được giữ cho giai đoạn sau thay vì làm biến mất khỏi tài liệu.
- "Chưa triển khai" không đồng nghĩa với "bị loại bỏ" hoặc "phụ thuộc vào nhánh khác".
- Các tính năng cộng đồng, Arena mở rộng, AI Tutor nâng cao và quà tặng được giữ trong tầm nhìn và triển khai theo giai đoạn khi sản phẩm sẵn sàng.

---

### 1.6. Cách đọc roadmap sau khi đồng bộ mở rộng

§2–13 giữ lịch sử và checklist của các giai đoạn nền. **Ưu tiên đang áp dụng nằm
ở §14 và §17**; không khởi tạo lại Foundation, không chờ mọi voice/model hoàn thiện
mới đưa UI mới vào APK. Thiết kế toàn hệ thống phải có trước, implementation vẫn
chia lát cắt có evidence. “Sau phát hành” trong kế hoạch cũ không phải lý do hoãn
nhà/đất/đảo vô hạn hoặc để bạn bè/thi đấu biến mất khỏi thiết kế.

Chỉ đóng từng dependency khi có chứng cứ; nghiên cứu/UI các lane độc lập có thể
song song. Chính sách/quyền/server bắt buộc cho tính năng shared/paid không biến
thành dependency giả cho UI làng hoặc nhánh nhà solo.

---

### 1.7. Gate hình ảnh2,5D trước khi giao UI

Cập nhật2026-10-18 theo user: đồng bộ tài liệu chưa đủ; mọi màn phải thuộc cùng bộ
2,5D theo [ART_DIRECTION_2_5D](design/ART_DIRECTION_2_5D.md). Dừng việc port nguyên
P02–P06C như final UI. DESIGN làm neo làng/nhà/hải đồ; CODE được giao phần art qua
PQC-017 design-only (Tutor/nội thất thành tích/Arena), không mở app/CI/deps.

R1 là ưu tiên UI. **R1-A đã READY_FOR_CODE tại r53** với composition phone/state/copy,
source geometry và static W01 export; xemPQC-020. Ngoại lệflattenedscene chỉ cho lát
cắt này, không miễn layer/actor/occlusion gates cho thế giới tương tác về sau.
Không chờ hoàn tất local AI/voice, nhưng cũng không bỏ art gate để nhanh có APK.
PQC-017/018 đã được review trong phạm vi art;018 ART_SCOPE_COMPLETE theo r40.
PQC-011 đã ACCEPTED tại6dc8ca8 theo reviewr53; xemPROJECT_STATUS.

---

## 2. Tổng quan các giai đoạn

**Quy ước đọc tiêu chí:** 64 mục dưới §3–13 là yêu cầu kế hoạch/lịch sử,
không phải64 task chưa bắt đầu. Bỏ hình thức checkbox để tránh biến chúng thành
bảng tiến độ giả. Có source không tự đóng tiêu chí; xem §14 và PROJECT_STATUS
cho trạng thái và evidence. Giai đoạn4 vẫn partial vì chưa có rewarded-ad SDK.

| # | Giai đoạn | Mục tiêu chính | Thời lượng dự kiến |
|---|---|---|---|
| 1 | **Foundation** | Khung Flutter, điều hướng, lưu dữ liệu, giao diện cơ bản | Ngắn |
| 2 | **Home Map** | Thế giới chính, nhân vật, âm thanh | Trung bình |
| 3 | **Một mini-game hoàn chỉnh** | Gameplay, điểm số, lưu kỷ lục, Creator Mode — **lát cắt dọc đầu tiên** | Trung bình |
| 4 | **Energy & Rewarded Ads** | Năng lượng, hồi theo thời gian, quảng cáo thưởng | Ngắn |
| 5 | **Interpreter mô phỏng** | Thực thi tập con Python-like an toàn, giới hạn tài nguyên, xử lý lỗi | Trung bình |
| 6 | **Main Quest** | Bài học Python, bài tập, lưu tiến trình | Dài |
| 7 | **Side Maps & Pro** | Nội dung mở rộng và mua hàng | Trung bình |
| 8 | **Hoàn thiện** | Localization, accessibility, kiểm thử, build, phát hành | Dài |
| 9 | **Mở rộng theo readiness** | Nhà/đất/đảo, visit/pets, Arena, cộng đồng, quà tặng và nội dung mới; xem §17 | Dài |

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
- Database SQLite với schema ban đầu theo `TECHNICAL_ARCHITECTURE.md` mục 4.2 (`settings`, `progress`, `energy_state`, ...). **Không** tạo bảng XP/level toàn cục — bảng `player_state` cũ đã được bỏ.
- Repository pattern cho việc đọc/ghi dữ liệu.
- File cấu hình `game_config.json` với các thông số từ `GAME_DESIGN.md`.
- Màn hình khởi động + màn hình home tạm.

### 3.3. Không làm trong giai đoạn này

- Không làm Home Map đẹp.
- Không làm mini-game.
- Không tích hợp quảng cáo, thanh toán.
- Không làm Python runtime.

### 3.4. Tiêu chí nghiệm thu

- **Tiêu chí kế hoạch:** App build và chạy được trên Android thật.
- **Tiêu chí kế hoạch:** Điều hướng giữa 3–4 màn hình rỗng hoạt động trơn tru.
- **Tiêu chí kế hoạch:** Ghi một giá trị vào SQLite, thoát app, mở lại, đọc được giá trị cũ.
- **Tiêu chí kế hoạch:** `game_config.json` load được và đọc đúng thông số.
- **Tiêu chí kế hoạch:** Cấu trúc thư mục khớp với `TECHNICAL_ARCHITECTURE.md`.

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
- Thế giới có thể được trình bày như ngôi làng với các ngôi nhà/công trình/cổng là điểm vào module gameplay; không yêu cầu mọi công trình phải có ngay trong phiên bản đầu.

### 4.3. Không làm trong giai đoạn này

- Không làm mini-game thật (chỉ placeholder khi chạm vào địa điểm).
- Không làm Main Quest bài học.

### 4.4. Tiêu chí nghiệm thu

- **Tiêu chí kế hoạch:** Home Map hiển thị đúng, không bị vỡ layout trên các kích thước màn hình phổ biến.
- **Tiêu chí kế hoạch:** Chạm vào địa điểm có phản hồi âm thanh + hiệu ứng.
- **Tiêu chí kế hoạch:** Nhân vật xuất hiện với thoại ngắn khi mở app.
- **Tiêu chí kế hoạch:** Tắt/bật âm thanh hoạt động và được lưu lại sau khi thoát app.
- **Tiêu chí kế hoạch:** Trẻ (hoặc người test) hiểu được "đây là nơi để khám phá".

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

**Creator Mode (chỉ phần có cấu trúc — chưa cần interpreter giai đoạn 5):**
- Ghép khối lệnh bằng kéo thả (màn 1–3).
- Chỉnh tham số luật chơi qua điều khiển có cấu trúc và chạy thử màn bằng luật
  đó để chứng minh luồng.
- Các màn xem code sinh ra / viết code (màn 7–10) **hoãn** tới giai đoạn 5, khi
  interpreter mô phỏng đã có.

**Tích hợp nền tảng:**
- Phát sự kiện `level_completed` và `game_completed`.
- Ghi vào `progress_tracker`.
- Huy hiệu đơn giản: **First Line** (khi hoàn thành màn 1).
- Màn tổng kết sau mỗi màn, có nhân vật và lời thoại.

### 5.3. Không làm trong giai đoạn này

- Không làm 5 mini-game cùng lúc.
- Không làm Creator Mode đầy đủ — chỉ đủ để chứng minh luồng.
- Không làm các màn Creator Mode cần chạy code (xem code sinh ra / viết code,
  màn 7–10) — những màn này thuộc giai đoạn 5.
- Không làm Side Maps.
- **Chưa** áp dụng tiêu hao năng lượng ở lát cắt này; năng lượng được triển khai
  ở giai đoạn 4.

### 5.4. Tiêu chí nghiệm thu

**Đây là lát cắt dọc quan trọng nhất — phải đạt tất cả:**

- **Tiêu chí kế hoạch:** Mở app → vào Home Map → chạm vào Robot Maze → chơi được màn 1.
- **Tiêu chí kế hoạch:** Hoàn thành màn → thấy màn tổng kết với số liệu cụ thể.
- **Tiêu chí kế hoạch:** Điểm cao được lưu vào SQLite.
- **Tiêu chí kế hoạch:** Thoát app → mở lại → màn đã mở vẫn còn, điểm cao vẫn còn.
- **Tiêu chí kế hoạch:** Huy hiệu **First Line** xuất hiện sau khi hoàn thành màn 1.
- **Tiêu chí kế hoạch:** Creator Mode cho phép ghép khối/chỉnh luật có cấu trúc và chạy thử ít nhất
      1 màn (**không cần interpreter Python-like** ở giai đoạn này).
- **Tiêu chí kế hoạch:** Không crash khi chơi liên tục 15 phút.
- **Tiêu chí kế hoạch:** Phát sự kiện `level_completed` và `game_completed` đúng chuẩn.

**Nếu tiêu chí này chưa đạt → chưa chuyển sang giai đoạn 4.**

---

## 6. Giai đoạn 4 — Energy & Rewarded Ads

### 6.1. Mục tiêu

Năng lượng hoạt động đúng luật (`GAME_DESIGN.md` mục 3), quảng cáo thưởng tự
nguyện, an toàn cho trẻ.

### 6.2. Phạm vi

- Năng lượng: tối đa ban đầu **20**, tiến trình lên **40** theo `GAME_DESIGN.md` 3.1.
- Tiêu hao theo `GAME_DESIGN.md` 3.2: Play Mode 2, Creator Mode 0, bài/bài tập
  Main Quest 1, thử thách chặng 3 (lần đầu), ôn tập/đọc truyện/xem bộ sưu tập 0.
- Năng lượng hồi theo thời gian thực, kể cả khi tắt app; hiển thị thời gian hồi
  đơn vị tiếp theo.
- Quảng cáo thưởng AdMob rewarded.
- Giới hạn **3 lượt hợp lệ/ngày**, reset 00:00 giờ địa phương, **lưu trong database**.
- Chỉ cộng thưởng sau khi SDK xác nhận hợp lệ.
- Xử lý quảng cáo thất bại: không trừ lượt, không trừ năng lượng.

### 6.3. Không làm trong giai đoạn này

- Không dùng interstitial, banner, native ads.
- Không tự động phát quảng cáo.
- Không hiển thị quảng cáo khi trẻ đang trong bài học.

### 6.4. Tiêu chí nghiệm thu

- **Tiêu chí kế hoạch:** Năng lượng hồi đúng tốc độ (10 phút/đơn vị).
- **Tiêu chí kế hoạch:** Tắt app 30 phút → mở lại → năng lượng đã hồi đúng.
- **Tiêu chí kế hoạch:** Tiêu hao đúng luật cho từng hoạt động (`GAME_DESIGN.md` 3.2).
- **Tiêu chí kế hoạch:** Hết năng lượng vẫn truy cập được nội dung miễn phí (ôn tập, đọc truyện,
      xem bộ sưu tập, Creator Mode).
- **Tiêu chí kế hoạch:** Xem quảng cáo thưởng → cộng +5 năng lượng sau khi SDK xác nhận.
- **Tiêu chí kế hoạch:** Quảng cáo thất bại → không trừ lượt, không trừ năng lượng.
- **Tiêu chí kế hoạch:** Vượt 3 lượt/ngày → nút ẩn hoặc vô hiệu hóa; thoát/mở lại app **không** reset lượt trong ngày.
- **Tiêu chí kế hoạch:** Không có quảng cáo nào chen ngang bài học.
- **Tiêu chí kế hoạch:** Đã kiểm tra chính sách Google Play Families **trước khi bật quảng cáo thật**.

---

## 7. Giai đoạn 5 — Interpreter mô phỏng (tập con giới hạn)

### 7.1. Mục tiêu

Có một interpreter Dart chạy **an toàn** tập con Python-like, phục vụ các màn
Main Quest chạy code và Creator Mode mở code (xem `TECHNICAL_ARCHITECTURE.md` mục 2).

### 7.2. Phạm vi

- Interpreter mô phỏng tập con: `print()`, biến, số, chuỗi, `if/else`, `for`,
  `while`, danh sách, hàm đơn giản.
- Không hỗ trợ: import, file I/O, mạng, `eval`, `exec`, class phức tạp.
- Kiểm soát thực thi: ngân sách bước, độ sâu gọi, kích thước output, ngắt an toàn
  (xem `TECHNICAL_ARCHITECTURE.md` mục 2.3). Không dựa vào timeout wall-clock đơn lẻ.
- Cổng `PythonRuntime` để có thể thay runtime sau này.

### 7.3. Không làm trong giai đoạn này

- Không nhúng Python thật.
- Không hứa một sandbox Python đa dụng.

### 7.4. Tiêu chí nghiệm thu

- **Tiêu chí kế hoạch:** Chạy được tập con Python-like (in, biến, điều kiện, vòng lặp, hàm đơn giản).
- **Tiêu chí kế hoạch:** Vòng lặp vô hạn dừng an toàn do **vượt ngân sách bước**, không crash.
- **Tiêu chí kế hoạch:** Đệ quy sâu dừng an toàn ở ngưỡng độ sâu đã đặt.
- **Tiêu chí kế hoạch:** Lỗi cú pháp hiển thị thông báo thân thiện với trẻ.
- **Tiêu chí kế hoạch:** Output bị chặn khi vượt giới hạn.
- **Tiêu chí kế hoạch:** Không truy cập được file hệ thống, mạng, module hệ thống.
- **Tiêu chí kế hoạch:** Creator Mode của mini-game mẫu chạy được trên interpreter này.

### 7.5. Đánh giá Python thật (sau này — chưa cam kết)

- Thử nghiệm `chaquopy`, `python-for-android`, hoặc RustPython/WASM.
- So sánh với mô phỏng về: hiệu năng, độ ổn định, trải nghiệm trẻ.
- **Chỉ chuyển** nếu mô phỏng đã chứng minh được giá trị sư phạm và Python thật mang
  lại lợi ích rõ ràng. Không đưa vào tiêu chí nghiệm thu giai đoạn này.

---

## 8. Giai đoạn 6 — Main Quest

### 8.1. Mục tiêu

Tuyến học Python miễn phí, đủ để trẻ thực sự biết lập trình cơ bản.

### 8.2. Phạm vi

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
- Mở hoạt động theo điều kiện đã công bố trong `GAME_DESIGN.md`; không triển khai XP/cấp độ toàn cục.
- Nhiệm vụ ngày (3/ngày).
- Màn tổng kết sau mỗi bài.
- Adventure Recap sau mỗi chặng.
- Nhà Thành Tích đầy đủ.

**Phụ thuộc:** chỉ bài/bài tập có chạy code mới dùng interpreter giai đoạn 5.
Bài lý thuyết, ghép khối và điều khiển có cấu trúc **không** cần interpreter.
Tiêu hao năng lượng dùng luật đã có từ giai đoạn 4.

### 8.3. Không làm trong giai đoạn này

- Không làm Side Maps.

### 8.4. Tiêu chí nghiệm thu

- **Tiêu chí kế hoạch:** Chặng 1 hoàn chỉnh, trẻ (hoặc người test) hoàn thành được 12 bài.
- **Tiêu chí kế hoạch:** Mở chặng theo tiến trình học/điều kiện thực sự cần; Main Map hiển thị và điều hướng tới hoạt động hợp lệ.
- **Tiêu chí kế hoạch:** Màn tổng kết hiển thị số liệu lấy từ tiến trình đã lưu.
- **Tiêu chí kế hoạch:** Adventure Recap hiển thị đúng số liệu sau chặng 1.
- **Tiêu chí kế hoạch:** Nhà Thành Tích hiển thị huy hiệu, tường chiến tích, bộ sưu tập.
- **Tiêu chí kế hoạch:** Nhiệm vụ ngày reset đúng 00:00 giờ địa phương.
- **Tiêu chí kế hoạch:** Huy hiệu bí mật không lộ điều kiện.
- **Tiêu chí kế hoạch:** Chặng 2 mở được khi đủ điều kiện.
- **Tiêu chí kế hoạch:** Không cộng trùng phần thưởng "một lần" sau khi thoát/mở lại app.

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

- **Tiêu chí kế hoạch:** Trẻ xem được Side Map Shop với giá và nội dung rõ ràng.
- **Tiêu chí kế hoạch:** Parental gate hoạt động trước khi vào màn hình mua hàng.
- **Tiêu chí kế hoạch:** Mua Side Map → mở được nội dung.
- **Tiêu chí kế hoạch:** Thoát app → mở lại → quyền sở hữu vẫn còn.
- **Tiêu chí kế hoạch:** Đổi thiết bị → khôi phục được giao dịch.
- **Tiêu chí kế hoạch:** Mô phỏng purchase token giả → không mở nội dung.
- **Tiêu chí kế hoạch:** Pro ẩn toàn bộ quảng cáo trong phạm vi gói.
- **Tiêu chí kế hoạch:** Main Quest vẫn truy cập được khi không mua gì.

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
- **AI Tutor mẫu đầu tiên:** cảnh mở đầu, một nhân vật mặc định hoàn chỉnh, gợi ý theo nấc, an toàn và kiểm soát chi phí (xem `PRODUCT_VISION.md` mục 14).

### 10.3. Tiêu chí nghiệm thu

- **Tiêu chí kế hoạch:** App khởi động < 3 giây trên thiết bị tầm trung.
- **Tiêu chí kế hoạch:** Mini-game chạy 60 FPS ổn định.
- **Tiêu chí kế hoạch:** Dung lượng app < 150 MB.
- **Tiêu chí kế hoạch:** Bật/tắt được âm thanh, nhạc nền, hoạt ảnh.
- **Tiêu chí kế hoạch:** Localization hoạt động, không có chuỗi hard-code.
- **Tiêu chí kế hoạch:** Tất cả kịch bản kiểm thử cuối (mục 11) đạt.
- **Tiêu chí kế hoạch:** Build release cài được trên thiết bị thật.
- **Tiêu chí kế hoạch:** Đã kiểm tra chính sách trước khi submit.
- **Tiêu chí kế hoạch:** AI Tutor mẫu đầu tiên đạt tiêu chí nghiệm thu trong `PRODUCT_VISION.md` mục 14.6.

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
| 4 | **Người chơi sáng tạo** — sửa quy tắc mini-game → chạy thử → gặp lỗi → sửa lỗi → hoàn thành trò chơi | Creator Mode + interpreter giới hạn |
| 5 | **Người chơi Pro** — mua hoặc khôi phục Pro → kiểm tra quyền lợi; mô phỏng lỗi giao dịch và trạng thái chưa xác minh | Thanh toán an toàn |
| 6 | **Người chơi gặp sự cố** — mất mạng, dữ liệu chưa lưu, runtime lỗi → app xử lý an toàn | Xử lý lỗi, không mất tiến trình |

### 11.2. Điểm kiểm tra bắt buộc

Bốn lỗi nghiêm trọng **phải** được kiểm tra ở mọi giai đoạn liên quan:

| Lỗi | Cách kiểm tra |
|---|---|
| **Mất dữ liệu** | Thoát app, mở lại, xác nhận trạng thái còn nguyên |
| **Cộng thưởng sai** | Kiểm tra luồng điểm thưởng đã định nghĩa, năng lượng và huy hiệu |
| **Vượt giới hạn Python** | Chạy code gây vòng lặp vô hạn, kiểm tra dừng an toàn |
| **Xác nhận Pro sai** | Mô phỏng purchase token giả, kiểm tra không mở nội dung |

---

## 12. Điều **không** làm trong phiên bản đầu (nhưng thuộc tầm nhìn sản phẩm)

Để giữ dự án tập trung, roadmap **chủ động không** bao gồm trong phiên bản đầu:

- Subscription định kỳ.
- Cloud sync ở giai đoạn đầu.
- Multiplayer trực tuyến đầy đủ.
- Social features đầy đủ (chat, bạn bè) — **thuộc tầm nhìn sản phẩm**, triển khai theo giai đoạn khi sản phẩm sẵn sàng.
- Backend server phức tạp.
- Nhiều mini-game cùng lúc ở giai đoạn 3.
- iOS ở giai đoạn đầu.
- Analytics framework nặng.
- Framework test cồng kềnh.
- Arena mở rộng (giải theo mùa, thi đấu trực tuyến, đánh giá AI có kiểm soát) — **thuộc tầm nhìn sản phẩm**, triển khai sau khi các chế độ đơn người ổn định.
- Cộng đồng/quà tặng đầy đủ — **thuộc tầm nhìn sản phẩm**, triển khai theo giai đoạn.

Những mục này có thể được đánh giá lại sau khi PyQuest phát hành và có phản hồi thực tế. "Không làm trong phiên bản đầu" không đồng nghĩa với "bị loại bỏ khỏi tầm nhìn".

---

## 13. Giai đoạn 9 — Mở rộng tầm nhìn theo readiness

### 13.1. Mục tiêu

Mở rộng PyQuest theo tầm nhìn sản phẩm mà không làm mất các vòng lặp gameplay đã có.

### 13.2. Phạm vi

- **Arena mở rộng:** giải theo mùa, bài thi sáng tạo phong phú, đánh giá AI có kiểm soát, chia sẻ tác phẩm và thi đấu trực tuyến khi sản phẩm sẵn sàng.
- **AI Tutor nâng cao:** thêm nhân vật Tutor (cún, mèo, rồng, búp bê), voice chat có kiểm soát, hội thoại theo ngữ cảnh trong toàn game.
- **Cộng đồng:** kết bạn, đội nhóm, quà tặng, danh hiệu xã hội, an toàn trẻ em.
- **Sáng tạo xã hội:** tranh, thiệp, quà do người chơi tự tạo.
- **Nhà/đất/đảo:** dự án có nguồn huy chương/vật liệu, preview/commit, phòng dùng được, sắp đồ và lối đi; không chỉ profile/wallpaper.
- **Visit thật:** snapshot chủ vắng hoặc cùng session, quyền xem/chơi/sửa, thu hồi/mất mạng, hoạt động chung và moderation.
- **Pet thông minh:** hành vi nền, khả năng thiết bị, mua/khôi phục quyền; nghiên cứu AI local riêng có benchmark/fallback.
- **Side Maps mới:** bộ môn, chủ đề, vật phẩm, danh hiệu và trải nghiệm nâng cao; không đồng nhất với đảo cá nhân.
- **Danh hiệu độc quyền:** Side Maps, Tutor, nhiều bảng xếp hạng và tổng sắp chung.

### 13.3. Tiêu chí nghiệm thu (cao cấp)

- **Tiêu chí kế hoạch:** Các tính năng mở rộng được thêm theo module, không viết lại nền tảng.
- **Tiêu chí kế hoạch:** Dữ liệu luyện tập và thi đấu thật được phân biệt rõ.
- **Tiêu chí kế hoạch:** Không có XP/cấp độ toàn cục được thêm vào.
- **Tiêu chí kế hoạch:** Cộng đồng/quà tặng tuân thủ an toàn trẻ em và quyền riêng tư.

---

## 14. Trạng thái hiện tại & việc cần làm ngay

### 14.1. Trạng thái có source khác với nghiệm thu

Nguồn cập nhật: [PROJECT_STATUS](PROJECT_STATUS.md), đối chiếu CODE
`71b0fd3fd8fb07c73596ce089fa2e68f6fe87964` và DESIGN trước r47
`c68bdcd73b400c4d449216023a54499b202bda1d`.

- Foundation/SQLite/điều hướng, Main Map, Main Quest chặng1 và interpreter mô phỏng
  đã có source; không bắt đầu lại dự án. Chưa đóng mọi tiêu chí của giai đoạn1–6.
- Registry có6 module: Main Quest, **Robot Maze, Dragon Jump, Catch the Stars,
  Bug Hunter**, Nhà Thành Tích. Bốn hoạt động chơi được liệt kê theo tên để không
  bỏ sót debug game Bug Hunter; Maze có Creator riêng.
- Giai đoạn4 **chỉ hoàn thành một phần**: energy có source, rewarded-ad SDK chưa
  có. Không coi quảng cáo/quota/SDK callbacks là dữ liệu đang được lưu/chạy.
- Evidence lịch sử a9b: run39051006962 có406 ordinary +10 render;12 focused Settings
  là subset. APK run39052978443 đã build, không thay device/voice/usability PASS.
  Những kết quả đó không phải execution evidence cho71b0 hoặc tip mới hơn.
- PQC-011: **CHANGES_REQUESTED / WAITING_FOR_PINNED_SDK_EVIDENCE**;
  R42-A/B **SOURCE_ADDRESSED / EXECUTION_UNVERIFIED** theo review r44.
- PQC-018: **REVIEWED_WITH_LIMITS — ART_SCOPE_COMPLETE** theo review r40;
  không runtime/production approval. Header cũ trên CODE phải đồng bộ, không mở lại task.
- DESIGN r45/r46 đã giao study chọn màn Maze và Creator; không phải Flutter port.
  Side Maps/Pro, cộng đồng/Arena đầy đủ và các lane runtime mở rộng vẫn chưa đóng.

### 14.2. Ưu tiên hiện tại

1. Giữ011 ở blocker evidence; không giao lại source correction đã được review,
   không cài SDK hoặc tự trigger/rerun CI để biến thiếu evidence thành PASS.
2. Đồng bộ tài liệu/trạng thái và chính sách APK keyless theo r47. Đây là việc
   bảo trì riêng, không mở runtime011 hoặc art018. Không overwrite workflow CODE
   bằng cả file DESIGN vì hai nhánh có các gate kiểm thử khác nhau.
3. DESIGN hoàn thiện các surface còn partial và bộ art2,5D production. R1/R4 chưa
   mở; CODE chỉ nhận runtime order có scope/allowlist/assets/tests riêng.
4. Nhà–đất–đảo, visit/pet, Arena/cộng đồng tiếp tục theo readiness, không tự cấp
   economy/quyền chia sẻ và không chờ voice production mới thiết kế UI độc lập.

### 14.3. Bước tiếp theo cụ thể

**Không khởi tạo lại Flutter/SQLite.** Đọc ma trận trong PROJECT_STATUS và task
review tương ứng trước khi chọn việc. Chỉ dùng source đã pin để map module/state;
không lấy checkbox, ảnh concept hoặc build APK làm bằng chứng đã nghiệm thu.
Các tiêu chí nền dưới §3–13 được giữ như kế hoạch tham chiếu, không phải bảng đếm
việc chưa bắt đầu. Không đánh dấu hoàn tất hàng loạt; từng acceptance cần SHA,
scope, log/test/device evidence và giới hạn của lần kiểm chứng.

### 14.4. Quyết định còn mở (TBD)

Các điểm sau **chưa chốt** và **không** được tự ý đặt số liệu:

| Điểm mở | Câu hỏi cần quyết định | Nguồn |
|---|---|---|
| Nhóm quảng cáo thưởng cho Pro | Người dùng Pro vẫn được tự nguyện xem quảng cáo thưởng, hay có cách công bố rõ khác để nhận năng lượng? | `PRODUCT_VISION.md` 3.3, `TECHNICAL_ARCHITECTURE.md` 6.4 |
| Giá trị kiểm soát interpreter | Ngân sách bước, trần collection, mục tiêu bộ nhớ cụ thể | `TECHNICAL_ARCHITECTURE.md` 2.3 |
| Nhà cung cấp/model AI Tutor | Chất lượng tiếng Việt, độ trễ, chi phí, phương án lỗi | `TECHNICAL_ARCHITECTURE.md` 9.1 |
| Cơ chế kiểm duyệt nội dung do người chơi tạo | Báo cáo/kiểm duyệt phù hợp trẻ em | `PRODUCT_VISION.md` 16.5 |
| Recipe và vật liệu | Nguồn reachable, supply đủ, quota/giá, backfill người đã chơi; không lấy số fixture làm production | `GAME_DESIGN.md`17 |
| Visit thật | Capacity, quyền từng vùng, reconnect/thu hồi/co-edit conflicts | `TECHNICAL_ARCHITECTURE.md`3.8/4.8 |
| Pet local AI / mua thú | Model/license/benchmark VIEN, capability trước mua, memory/restore/refund | `TECHNICAL_ARCHITECTURE.md`9.4; `PRODUCT_VISION.md`16.7 |

---

## 15. Nguyên tắc cuối cùng

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
- [`GAME_DESIGN.md`](GAME_DESIGN.md) — luật chơi, năng lượng, mở khóa hoạt động và cân bằng độ khó.
- [`TECHNICAL_ARCHITECTURE.md`](TECHNICAL_ARCHITECTURE.md) — interpreter, module, lưu dữ liệu.
- [`../README.md`](../README.md) — điểm vào dự án.
- [`ARENA_CREATOR_COMPETITION_BRIEF.md`](ARENA_CREATOR_COMPETITION_BRIEF.md) — nguồn bổ sung về Arena, Creator League và trải nghiệm thi đấu.

---

**Bước tiếp theo:** theo §14/§17, không theo thứ tự voice → token → UI của bản
roadmap cũ. Voice production vẫn cần token an toàn và evidence thiết bị, nhưng là
lane riêng; không chặn việc thiết kế/đưa UI thế giới và chơi solo vào app.

---

## 16. Trạng thái triển khai và áp dụng UI Direction V2

### 16.1. Đã có trong source

- Main Map bản đồ đảo, Main Quest, mini-game, achievements, energy, daily quests.
- Trợ giảng ba tầng (ngoại tuyến / relay AI / Gemini Live voice) với transcript
  một mô hình tin nhắn có vai: trẻ và trợ giảng luôn hiện đúng tên, một lượt một
  bong bóng, trạng thái "đang nói / đang nghe / bị ngắt lời" lấy từ phiên thật.
- Kiểm thử hiện có trong CI (analyze + unit/widget + render preview); build Release
  APK đã thành công qua GitHub Actions.

### 16.2. Chưa có hoặc cần xác minh

- Arena, Creator Pro League, giải đồng đội.
- Side Maps và Pro đầy đủ.
- Cộng đồng, quà tặng và danh hiệu xã hội đầy đủ.
- Quảng cáo thưởng (rewarded ads) chưa có trong source.
- UI thế giới mới chưa được áp dụng vào APK a9b; bản thiết kế mở rộng đã nối lại các gói V2/P03–P06C, xem §17.
- **Bằng chứng trên thiết bị cho giọng nói**: bản sửa lỗi âm thanh và vai người nói
  có test source (giao thức Live, vòng đời loa PCM, mô hình transcript, danh
  tính trong panel) và evidence lịch sử, nhưng **chưa** có phiên Gemini Live thật được xác
  nhận bằng tai trên máy. Tiêu chí đóng: làm theo bảng kiểm trong
  `docs/experimental/GEMINI_LIVE_VOICE_TEST.md` trên owner-test APK được phép có
  key theo [r49](OWNER_TEST_BUILDS.md), hoặc đường token production tương lai; ghi
  exact SHA. Token/backend/quota hoãn cho lần thử này. Build success không phải voice PASS.

### 16.3. Hạng mục áp dụng UI Direction V2

1. Đánh giá các màn hình hiện có so với UI V2.
2. Thiết kế chi tiết cho các màn hình cần thay đổi.
3. Triển khai theo module, không viết lại nền tảng.
4. Kiểm thử và xác nhận runtime.
5. Cập nhật tài liệu sau khi có bằng chứng triển khai.

Không đánh dấu hoàn thành chỉ vì tài liệu hoặc mockup tồn tại. Ảnh tham khảo gốc
(21 ảnh trong `docs/PyQuest_Reffrence_Images/`) đã có trong checkout làm nguồn
tham khảo; không phải mọi style trong ảnh đều được duyệt. Chuẩn bắt buộc r33 là
ART_DIRECTION_2_5D. Mockup V2/concept SVG không phải bằng chứng đã triển khai.


## 17. Lộ trình redesign đồng bộ nhà–đất–đảo

**Đây là kế hoạch, không phải blanket runtime authorization.** Mỗi hàng cần order
có source pin/allowlist/test; không đánh dấu đã làm vì có bảng này. R0 là tài liệu
đã hoàn thành trong r32; các hàng còn lại chưa nghiệm thu. User không cần chọn lại
các bước phát triển thông thường; Lead chịu trách nhiệm chia scope và review.

| Lane | Đầu ra nhìn thấy/chơi được | Dependency thật | Evidence để đóng |
|---|---|---|---|
| R0 Đồng bộ | Bốn tài liệu + thiết kế W01–W14 và audit thiếu/mâu thuẫn | Đọc PV/P06B/P06C/source, không cần backend | Cross-doc coverage, link/gate check; **không phải runtime pass** |
| R1 UI thế giới hiện hữu | Làng2.5D dễ đọc, một gợi ý tiếp tục, chọn địa điểm → activity → kết quả → về; giữ sáu module thật | Art/copy/state và scene/navigation contract riêng; nối011 theo gate, không cần voice mới | APK mới, trước/sau360×640/390×844, VIEN, touch/focus/scroll/locale, save và routes không đổi; frame/memory trên máy ghi rõ nếu chưa đo |
| R2 Nhà + dự án solo | Nhà ban đầu, một dự án mở phòng có nguồn grant, nhận → preview → xây → vào dùng được; Sổ/túi | Inventory/recipe/ledger/migration được duyệt; không cần social backend | Hai thứ tự job, pending đa kết quả, retry/restart không cộng/trừ lặp, badge còn, người chơi cũ không mất save |
| R3 Bố trí + pet nền | Sắp/cất đồ, lối đi hợp lệ, pet đi/chơi/phản hồi, nội thất dùng được | Layout/behavior/nav ownership; không cần model sinh | Thao tác không drag, cancel/save/relaunch, không kẹt cửa, pause/calm, pet không phạt khi nghỉ |
| R4 Đất / bến / đảo | Mở khu có hoạt động mới, hải đồ phân loại, đi/về/cancel; không chỉ thêm nền | Content và recipe mỗi khu, scene bounds/streaming/authority | Reachability/supply, lỗi travel giữ bến nguồn, arrival một lần, trạng thái cũ còn; không đồng nhất đảo tư với paid map |
| R5 Ghé nhà thật | Chủ vắng có nhãn hoặc hai người cùng phiên, một hoạt động chung, quyền vùng/thu hồi | Identity/consent/moderation, session authority, shared layout/version | Hai thiết bị/client độc lập, presence thật, disconnect/rejoin/revoke/private data không leak; không lấy simulation hai vai làm bằng chứng |
| R6 Arena / đội / giao lưu | Từ luyện tập rõ nhãn tới một bộ môn thật, tác phẩm/version, title/rank, quà/thiệp có quyền | Scoring/result authority, anti-abuse, moderation/consent; không cần hoàn tất mọi đảo | Kết quả chính thức/dedup/disconnect, đóng góp cá nhân/đội, ownership quà không thành skill title, safe solo exit |
| R7 Pet AI / commerce | Capability rõ trước mua, inference tùy máy, fallback, restore và entitlement thật | Model/runtime/license benchmark VIEN; store/parental/receipt policy | Đo cùng scene, cancel/background, prompt safety, không silent cloud fallback; gỡ model không mất pet; purchase fail/restore/revoke đúng |

R5/R6 có thể nghiên cứu song song; triển khai từng lát cắt riêng khi dependency đạt.
R7 không chặn R1–R4. R6 không cần chờ mua thú hay sở hữu đảo lớn. Side Maps/Pro/quà
trả phí vẫn giữ roadmap, nhưng không lén bán quyền học hoặc mua chiến thắng.

Mỗi APK phải ghi source SHA, phần UI thật sự đổi và phần chưa có. Review visual
không chỉ đếm test: phải dùng được vòng đã giao. Tài liệu/hình/prototype chưa nối
Flutter không phải bằng chứng đã giao trải nghiệm mới cho người cài app.
