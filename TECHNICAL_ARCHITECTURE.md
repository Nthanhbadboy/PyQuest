# docs/TECHNICAL_ARCHITECTURE.md

```markdown
# PyQuest — Technical Architecture

> Tài liệu này xác định **xây PyQuest bằng cách nào**:
> framework, cách chạy Python, cấu trúc module, lưu dữ liệu,
> quảng cáo, thanh toán và các quyết định kỹ thuật quan trọng.
> Tài liệu **không** định nghĩa lại luật chơi (xem `GAME_DESIGN.md`)
> và **không** định nghĩa lại triết lý sản phẩm (xem `PRODUCT_VISION.md`).

---

## 1. Tổng quan & quyết định chốt

| Hạng mục | Quyết định |
|---|---|
| **Framework** | Flutter (Dart) |
| **Nền tảng mục tiêu** | Android trước, iOS sau |
| **Python runtime** | **Mô phỏng có giới hạn rõ ràng** ở giai đoạn đầu; đánh giá Python thật ở giai đoạn sau |
| **Lưu dữ liệu** | SQLite cục bộ, tách bảng theo module logic |
| **Quảng cáo** | Google AdMob (rewarded ads), chỉ dùng khi đã xác minh chính sách Families |
| **Thanh toán** | Google Play Billing (Android), StoreKit (iOS sau) |
| **Kiến trúc** | Module hóa, giao tiếp qua interface rõ ràng |
| **Trạng thái dùng chung** | Một nguồn sự thật duy nhất cho tiến trình, năng lượng, thành tích |

**Nguyên tắc chốt:** làm một **lát cắt dọc hoàn chỉnh** trước khi mở rộng.
Mở app → chơi một mini-game → lưu kết quả → thoát ra mở lại vẫn còn kết quả.

---

## 2. Quyết định về Python runtime

Đây là quyết định kỹ thuật **quan trọng nhất** của PyQuest.
Có ba lựa chọn, mỗi lựa chọn có đánh đổi rõ ràng.

### 2.1. Ba lựa chọn

| Lựa chọn | Ưu điểm | Nhược điểm | Phù hợp giai đoạn |
|---|---|---|---|
| **A. Mô phỏng hoàn toàn** | An toàn tuyệt đối, không phụ thuộc nền tảng, dễ kiểm soát | Không phải Python thật, giới hạn kiến thức dạy được | Đầu |
| **B. Python thật nhúng (embedded)** | Trẻ chạy Python thật, kiến thức chuyển giao được | Phức tạp, nặng, khó kiểm soát tài nguyên, rủi ro bảo mật | Trung |
| **C. Lai — mô phỏng trước, Python thật sau** | Bắt đầu an toàn, mở rộng dần | Cần thiết kế abstraction tốt từ đầu | **Chọn** |

### 2.2. Quyết định: Chọn phương án C

**Giai đoạn 1–3 (Foundation → Main Quest):**
- Dùng **interpreter mô phỏng** viết bằng Dart.
- Hỗ trợ tập lệnh Python cơ bản: `print()`, biến, số, chuỗi,
  `if/else`, `for`, `while`, danh sách, hàm đơn giản.
- Không hỗ trợ: import module, file I/O, mạng, `eval`, `exec`,
  class phức tạp, decorator, generator.

**Giai đoạn 4 (Python runtime đầy đủ):**
- Đánh giá nhúng Python thật qua một trong các phương án:
  - `chaquopy` (Android native).
  - `python-for-android` với bridge.
  - RustPython biên dịch sang WASM.
- Chỉ chuyển khi mô phỏng đã chứng minh được giá trị sư phạm.

### 2.3. Giới hạn tài nguyên bắt buộc

Bất kể dùng mô phỏng hay Python thật, **phải** áp dụng:

| Giới hạn | Giá trị | Lý do |
|---|---|---|
| Thời gian chạy tối đa | **3 giây** | Tránh vòng lặp vô hạn |
| Số bước thực thi tối đa | **100.000** | Tránh treo máy |
| Bộ nhớ tối đa | **32 MB** | Tránh tràn bộ nhớ |
| Độ sâu đệ quy | **50** | Tránh tràn stack |
| Kích thước output | **10 KB** | Tránh spam log |
| Số lần in mỗi giây | **100** | Tránh spam console |

Khi vượt giới hạn: dừng thực thi an toàn, hiển thị thông báo thân thiện
cho trẻ (không hiển thị lỗi kỹ thuật thô).

### 2.4. Giao diện abstraction

Để có thể thay đổi runtime sau này, toàn bộ code gọi Python
phải đi qua interface duy nhất:

```dart
abstract class PythonRuntime {
  Future<ExecutionResult> execute(String code, {ExecutionContext? context});
  void interrupt();
  bool get isRunning;
}

class ExecutionResult {
  final bool success;
  final String output;
  final String? errorMessage;
  final Duration executionTime;
}
```

**Quy tắc:** không module nào được gọi trực tiếp interpreter.
Chỉ được gọi qua `PythonRuntime`.

---

## 3. Kiến trúc module

### 3.1. Sơ đồ module

```
┌─────────────────────────────────────────────────────┐
│                   PyQuest App Core                   │
│      (Điều hướng, hồ sơ, ngôn ngữ, âm thanh)         │
└────────────┬────────────────────────────┬────────────┘
             │                            │
    ┌────────▼────────┐          ┌────────▼────────┐
    │   Main Quest    │          │   Mini-games    │
    │  (Bài học, XP)  │          │  (Robot Maze…)  │
    └────────┬────────┘          └────────┬────────┘
             │                            │
             └────────────┬───────────────┘
                          │
             ┌────────────▼────────────┐
             │   Shared State Layer    │
             │ (Progress, Energy, XP)  │
             └────────────┬────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
┌───────▼──────┐  ┌───────▼──────┐  ┌───────▼──────┐
│ Energy & Ads │  │ Achievement  │  │  Side Maps   │
│              │  │   System     │  │   & Pro      │
└──────────────┘  └──────────────┘  └──────────────┘
```

### 3.2. Quy tắc giao tiếp

- Các module **không** gọi trực tiếp lẫn nhau tùy tiện.
- Mọi giao tiếp đi qua **interface công khai** của module đích.
- Sự kiện (level completed, game completed, skill mastered)
  đi qua **event bus** đơn giản, không qua gọi hàm trực tiếp.

### 3.3. Interface mẫu

```dart
// Progress module interface
abstract class ProgressService {
  Future<PlayerProgress> getProgress();
  Future<void> recordLessonCompleted(String lessonId, int xp);
  Future<void> recordGameCompleted(String gameId, int stars, int score);
  Future<void> recordSkillMastered(String skillId);
}

// Energy module interface
abstract class EnergyService {
  Future<int> getCurrentEnergy();
  Future<int> getMaxEnergy();
  Future<DateTime?> getNextRegenTime();
  Future<bool> consume(int amount);
  Future<void> grant(int amount);
}

// Achievement module interface
abstract class AchievementService {
  Future<List<Achievement>> getAll();
  Future<List<Achievement>> getUnlocked();
  Future<void> processEvent(StandardEvent event);
}
```

---

## 4. Lưu dữ liệu

### 4.1. Quyết định: SQLite cục bộ

- **Giai đoạn đầu:** một file SQLite, bảng tách theo module logic.
- **Giai đoạn sau:** nếu cần, tách thành database vật lý riêng theo module.
- **Không** dùng file JSON rời rạc cho dữ liệu gameplay quan trọng
  (dễ hỏng, khó migrate, khó query).

### 4.2. Bảng theo module

| Module | Bảng | Dữ liệu sở hữu |
|---|---|---|
| Progress | `progress`, `skills` | Bài học đã hoàn thành, XP, kỹ năng đã nắm |
| Games | `game_results`, `unlocked_levels` | Điểm cao, màn đã mở, sao |
| Energy | `energy_state` | Năng lượng hiện tại, thời điểm hồi tiếp theo |
| Purchases | `purchases` | Quyền sở hữu bản đồ, trạng thái Pro |
| Settings | `settings` | Ngôn ngữ, âm thanh, nhạc nền |
| Achievements | `achievements` | Huy hiệu đã mở, thời điểm mở |

### 4.3. Schema mẫu

```sql
CREATE TABLE progress (
  id INTEGER PRIMARY KEY,
  lesson_id TEXT NOT NULL UNIQUE,
  completed_at INTEGER NOT NULL,
  xp_awarded INTEGER NOT NULL
);

CREATE TABLE game_results (
  id INTEGER PRIMARY KEY,
  game_id TEXT NOT NULL,
  level_id TEXT NOT NULL,
  stars INTEGER NOT NULL,
  high_score INTEGER NOT NULL,
  completed_at INTEGER NOT NULL,
  UNIQUE(game_id, level_id)
);

CREATE TABLE energy_state (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  current_energy INTEGER NOT NULL,
  max_energy INTEGER NOT NULL,
  last_regen_at INTEGER NOT NULL
);

CREATE TABLE purchases (
  id INTEGER PRIMARY KEY,
  product_id TEXT NOT NULL UNIQUE,
  purchase_token TEXT NOT NULL,
  verified BOOLEAN NOT NULL DEFAULT 0,
  purchased_at INTEGER NOT NULL
);
```

### 4.4. Quy tắc sở hữu dữ liệu

- **Mỗi bảng chỉ thuộc một module.** Module khác **không** ghi trực tiếp.
- Module muốn đọc dữ liệu của module khác: gọi qua interface.
- **Một nguồn sự thật duy nhất** cho tiến trình, năng lượng, thành tích —
  tránh các module ghi đè lẫn nhau.

### 4.5. Migration

- Đặt `schema_version` trong bảng `settings`.
- Migration chạy khi app khởi động, trước khi load UI.
- Mỗi migration là một hàm Dart thuần, không phụ thuộc UI.
- Luôn có đường lùi: sao lưu database trước khi migrate.

---

## 5. Hệ thống thành tích

### 5.1. Ba module độc lập

| Module | Trách nhiệm |
|---|---|
| `achievement_engine` | Xác định điều kiện mở khóa huy hiệu |
| `progress_tracker` | Ghi nhận màn, game, kỹ năng, chặng học |
| `achievement_house` | Giao diện căn nhà, bộ sưu tập, hoạt ảnh, tổng kết |

### 5.2. Luồng sự kiện

```
Game / Lesson
    │
    ▼
Standard Event (level_completed, game_completed, skill_mastered)
    │
    ▼
progress_tracker → lưu vào SQLite
    │
    ▼
achievement_engine → kiểm tra điều kiện
    │
    ▼
achievement_house → đọc và hiển thị
```

### 5.3. Sự kiện chuẩn hóa

```dart
class StandardEvent {
  final String type; // 'level_completed', 'game_completed', 'skill_mastered'
  final String sourceId; // 'robot_maze', 'lesson_05'
  final Map<String, dynamic> data;
  final DateTime timestamp;
}
```

**Nguyên tắc:** thêm game mới không phải viết lại hệ thống huy hiệu —
chỉ cần phát sự kiện đúng chuẩn.

---

## 6. Quảng cáo

### 6.1. Nhà cung cấp: Google AdMob

- Chỉ dùng **rewarded ads** ở giai đoạn đầu.
- Không dùng interstitial, banner, native ads cho trẻ nhỏ.
- Đánh giá lại khi Google Play Families có chính sách mới.

### 6.2. Luồng quảng cáo thưởng

```
Trẻ bấm "Nhận thêm năng lượng"
    │
    ▼
Kiểm tra: còn lượt hôm nay? năng lượng < max?
    │
    ├─ Không → ẩn nút, hiển thị thông báo nhẹ
    │
    ▼
Hiển thị dialog xác nhận (rõ ràng, không gây áp lực)
    │
    ▼
Gọi SDK show()
    │
    ▼
Callback:
    ├─ onUserEarnedReward → cộng năng lượng, tăng lượt đã dùng
    ├─ onAdFailedToShow → không trừ lượt, thông báo nhẹ
    └─ onAdDismissed → nếu chưa earn, không cộng
```

### 6.3. Quy tắc an toàn

- **Không** tự động phát quảng cáo.
- **Không** phát quảng cáo khi trẻ đang trong bài học.
- **Không** hiển thị quảng cáo cho trẻ chưa được parental consent (nếu cần).
- **Chỉ** cộng thưởng sau khi SDK xác nhận hợp lệ.
- Ghi log lượt xem để giới hạn 3 lần/ngày.

### 6.4. Trạng thái Pro

- Người dùng Pro: ẩn toàn bộ nút quảng cáo.
- Không hiển thị quảng cáo dù ở bất kỳ màn nào.
- Trạng thái Pro lưu trong `purchases`, xác minh qua billing.

---

## 7. Thanh toán

### 7.1. Nhà cung cấp

- **Android:** Google Play Billing Library.
- **iOS (sau):** StoreKit 2.

### 7.2. Sản phẩm

| Loại | Ví dụ | Ghi chú |
|---|---|---|
| **In-app purchase (không tiêu hao)** | Side Maps, Pro | Mua một lần, dùng mãi |
| **Không** dùng subscription | — | Tránh áp lực định kỳ với trẻ |

### 7.3. Luồng mua hàng

```
Trẻ/parent bấm "Mua"
    │
    ▼
Hiển thị thông tin sản phẩm rõ ràng (giá, nội dung, quyền lợi)
    │
    ▼
Gọi Billing flow
    │
    ▼
Nhận purchase token
    │
    ▼
Xác minh với server (hoặc Google Play nếu chưa có server)
    │
    ├─ Hợp lệ → lưu vào `purchases`, mở nội dung
    └─ Không hợp lệ → không mở, thông báo nhẹ
```

### 7.4. Quy tắc an toàn

- **Không** tin file cục bộ để xác nhận quyền sở hữu.
- Luôn xác minh qua billing token.
- Có cơ chế **khôi phục giao dịch** khi trẻ đổi thiết bị.
- Nếu chưa có server: dùng Google Play Billing query để xác minh.
- Ghi log giao dịch để debug.

### 7.5. Parental gate

- Trước khi vào màn hình mua hàng: yêu cầu **parental gate**
  (ví dụ: giải phép tính đơn giản).
- Không hiển thị giá bằng tiền thật cho trẻ mà không có gate.
- Không dùng ngôn ngữ gây áp lực ("chỉ còn hôm nay", "mua ngay").

---

## 8. Cấu trúc code Flutter

### 8.1. Cấu trúc thư mục

```
app/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── navigation/
│   │   ├── settings/
│   │   ├── audio/
│   │   └── localization/
│   ├── data/
│   │   ├── database/
│   │   ├── models/
│   │   └── repositories/
│   ├── modules/
│   │   ├── main_quest/
│   │   ├── mini_games/
│   │   │   ├── robot_maze/
│   │   │   ├── dragon_jump/
│   │   │   └── ...
│   │   ├── energy/
│   │   ├── ads/
│   │   ├── achievements/
│   │   ├── side_maps/
│   │   └── pro/
│   ├── python_runtime/
│   │   ├── python_runtime.dart
│   │   ├── simulated_interpreter.dart
│   │   └── resource_limits.dart
│   └── shared/
│       ├── widgets/
│       └── theme/
├── assets/
│   ├── images/
│   ├── audio/
│   └── config/
│       └── game_config.json
└── test/
    └── integration/
```

### 8.2. Quy tắc code

- **Không** hard-code giá trị gameplay — đặt trong `game_config.json`.
- **Không** gọi database trực tiếp từ UI — qua repository.
- **Không** gọi module khác trực tiếp — qua interface.
- **Không** tạo tầng trung gian chỉ để trông "chuẩn kiến trúc".

---

## 9. Kiểm thử

### 9.1. Nguyên tắc

Với PyQuest, phần lớn module độc lập, chủ yếu ghi và đọc trạng thái.
**Không** biến việc phát triển thành dự án chạy hàng đống test.
Ưu tiên kiến trúc đơn giản, luồng chơi thật, kiểm tra tổng thể ở cuối.

### 9.2. Không test tràn lan

- Không viết unit test cho từng hàm nhỏ, getter/setter, thao tác lưu đơn giản.
- Không cố định từng pixel, khoảng cách, màu sắc, animation bằng test.
- Không dựng mock phức tạp cho module vốn độc lập.
- Không chạy toàn bộ test sau mỗi lần sửa giao diện.

### 9.3. Điểm kiểm tra bắt buộc

Không cần nhiều test, nhưng **phải** có điểm kiểm tra đủ sức phát hiện lỗi nghiêm trọng:

| Lỗi cần phát hiện | Cách kiểm tra |
|---|---|
| **Mất dữ liệu** | Thoát app, mở lại, xác nhận trạng thái còn nguyên |
| **Cộng thưởng sai** | Kiểm tra luồng nhận XP, năng lượng, huy hiệu |
| **Vượt giới hạn Python** | Chạy code gây vòng lặp vô hạn, kiểm tra dừng an toàn |
| **Xác nhận Pro sai** | Mô phỏng purchase token giả, kiểm tra không mở nội dung |

### 9.4. Test cuối theo chuyến phiêu lưu

Thay vì hàng trăm test nhỏ, xây dựng kịch bản đại diện:

1. **Người chơi mới:** mở app → khám phá bản đồ → chơi mini-game
   → học Python → nhận thành tích.
2. **Người chơi quay lại:** hoàn thành một phần → đóng app → mở lại
   → tiếp tục đúng tiến trình.
3. **Người chơi hết năng lượng:** chuyển sang nội dung miễn phí khác
   → chờ hồi hoặc nhận thưởng quảng cáo hợp lệ.
4. **Người chơi sáng tạo:** sửa quy tắc mini-game → chạy thử → gặp lỗi
   → sửa lỗi → hoàn thành trò chơi.
5. **Người chơi Pro:** mua hoặc khôi phục quyền Pro → kiểm tra quyền lợi;
   mô phỏng lỗi giao dịch và trạng thái chưa xác minh.
6. **Người chơi gặp sự cố:** mất mạng, dữ liệu chưa lưu, runtime lỗi
   → app xử lý an toàn, không mất tiến trình ngoài dự kiến.

Các kịch bản này là **mục tiêu kiểm chứng cuối**, không phải lý do
dựng ngay framework test nặng nề.

---

## 10. Hiệu năng & tài nguyên

### 10.1. Mục tiêu

| Chỉ số | Mục tiêu |
|---|---|
| Thời gian khởi động app | < 3 giây (thiết bị tầm trung) |
| Thời gian load màn mini-game | < 1 giây |
| FPS mini-game | 60 FPS ổn định |
| Dung lượng app | < 150 MB (không tính asset tải thêm) |
| Bộ nhớ khi chạy | < 200 MB |

### 10.2. Chiến lược asset

- Ảnh: dùng định dạng nén tốt (WebP).
- Âm thanh: OGG cho nhạc nền, WAV ngắn cho hiệu ứng.
- Asset lớn (Side Maps): tải theo gói khi mua, không nhúng hết vào app.

---

## 11. Bảo mật & quyền riêng tư

### 11.1. Dữ liệu trẻ em

- **Không** thu thập dữ liệu cá nhân ngoài mức cần thiết.
- **Không** yêu cầu đăng ký tài khoản ở giai đoạn đầu.
- **Không** gửi dữ liệu lên server nếu chưa có parental consent.
- Tuân thủ **COPPA** (Mỹ) và **GDPR-K** (EU) nếu phát hành ở các thị trường đó.

### 11.2. Lưu trữ cục bộ

- Toàn bộ tiến trình lưu cục bộ ở giai đoạn đầu.
- Nếu thêm cloud sync sau: mã hóa khi truyền, xin consent rõ ràng.

### 11.3. Python runtime

- Chạy trong sandbox, không truy cập file hệ thống.
- Không cho phép import module hệ thống.
- Giới hạn tài nguyên như mục 2.3.

---

## 12. Quyết định còn để mở

Các quyết định sau **chưa chốt**, cần đánh giá thêm:

| Quyết định | Khi nào chốt |
|---|---|
| Python thật hay mô phỏng ở giai đoạn 4 | Sau khi mô phỏng chứng minh giá trị sư phạm |
| Có cần server backend không | Khi cần cloud sync hoặc xác minh purchase tập trung |
| Có dùng Firebase không | Khi cần analytics, crash reporting, remote config |
| Có hỗ trợ iOS ngay không | Sau khi Android ổn định |
| Localization sang ngôn ngữ nào | Trước giai đoạn hoàn thiện |

---

## 13. Tóm tắt quyết định chốt

| Hạng mục | Chốt |
|---|---|
| Framework | Flutter |
| Python runtime giai đoạn đầu | Mô phỏng có giới hạn rõ |
| Python runtime giai đoạn sau | Đánh giá lại, không cam kết trước |
| Lưu dữ liệu | SQLite, tách bảng theo module |
| Quảng cáo | AdMob rewarded, tối đa 3/ngày |
| Thanh toán | Google Play Billing |
| Kiến trúc | Module hóa, interface rõ ràng |
| Kiểm thử | Không tràn lan, tập trung điểm rủi ro cao |
| Lát cắt dọc đầu tiên | Mở app → chơi mini-game → lưu → mở lại vẫn còn |

---

## Tài liệu liên quan

- [`PRODUCT_VISION.md`](PRODUCT_VISION.md) — triết lý sản phẩm, thế giới, mô hình kinh doanh.
- [`GAME_DESIGN.md`](GAME_DESIGN.md) — luật chơi, năng lượng, XP, cân bằng độ khó.
- [`ROADMAP.md`](ROADMAP.md) — giai đoạn triển khai và tiêu chí nghiệm thu.
```

---

Xong tài liệu **4/5: `docs/TECHNICAL_ARCHITECTURE.md`**.

Nhắn **"5"** để mình viết tài liệu cuối cùng — dự kiến là `docs/ROADMAP.md` (giai đoạn triển khai, tiêu chí nghiệm thu, thứ tự làm, kiểm thử theo giai đoạn).
