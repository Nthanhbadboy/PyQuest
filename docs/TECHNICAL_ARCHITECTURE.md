# PyQuest — Technical Architecture

> **Trạng thái đối chiếu r47 · 2026-10-18:** xem [source / evidence / release policy](PROJECT_STATUS.md).
> Tầm nhìn, tiêu chí kế hoạch và source đã có không đồng nghĩa tính năng đã được nghiệm thu.

> **Đồng bộ mở rộng · 2026-10-18:** nhà → đất → đảo, nhiệm vụ liên kết,
> thăm nhà có hoạt động, thú thông minh, bạn bè/Arena đều thuộc thiết kế sản phẩm.
> [Thiết kế thế giới thống nhất](design/WORLD_EXPANSION_REDESIGN.md) nối các màn và
> phân biệt rõ luật đề xuất với source đã chạy. Không coi prototype là tính năng APK.

> Tài liệu này xác định **xây PyQuest bằng cách nào**:
> framework, cách chạy Python, cấu trúc module, lưu dữ liệu,
> quảng cáo, thanh toán và các quyết định kỹ thuật quan trọng.
> Tài liệu **không** định nghĩa lại luật chơi (xem `GAME_DESIGN.md`)
> và **không** định nghĩa lại triết lý sản phẩm (xem `PRODUCT_VISION.md`).
>
> Thuật ngữ (**Home Map**, **Main Map**, **Main Quest**, **Mini-game Play Mode**,
> **Mini-game Creator Mode**, **Side Maps**, **Nhà Thành Tích**, **Adventure Recap**,
> **Arena**, **Creator Pro League**, **Tutor**) dùng theo định nghĩa tại `PRODUCT_VISION.md`.

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
| **Trạng thái dùng chung** | Một nguồn sự thật duy nhất cho tiến trình hoạt động, năng lượng, thành tích và quyền mở khóa |
| **XP/cấp độ toàn cục** | **Không dùng**; không có bảng XP/level hay công thức tăng cấp. Main Map chỉ điều hướng/mở hoạt động theo điều kiện trực tiếp |
| **Arena** | Các bộ môn là module độc lập; điểm/danh hiệu là lớp liên kết chung |
| **AI Tutor** | Production qua backend/service an toàn; owner-test có ngoại lệ r49, không commit secret |
| **Cộng đồng/quà tặng** | Module xã hội tách biệt, triển khai theo giai đoạn |

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

**Trước hết — dùng interpreter mô phỏng viết bằng Dart (tập con giới hạn).**
Interpreter này là **một phần của lõi sản phẩm**, không phải bước phụ:

- Nó cần có **trước hoặc cùng lúc** với các bài Main Quest chạy code và các màn
  Creator Mode có xem/chạy code.
- Hỗ trợ **tập con** Python-like: `print()`, biến, số, chuỗi, `if/else`, `for`,
  `while`, danh sách, hàm đơn giản.
- **Không** hỗ trợ: import module, file I/O, mạng, `eval`, `exec`, class phức tạp,
  decorator, generator.

**Lát cắt dọc đầu tiên KHÔNG cần interpreter.** Luồng
"mở app → chơi một mini-game → lưu kết quả → mở lại vẫn còn kết quả"
chỉ cần Play Mode + lưu dữ liệu, có thể hoàn thành trước khi interpreter tồn tại.

**Main Quest không phụ thuộc interpreter ở mọi màn.** Chỉ những màn có chạy code
(bài tập code, màn Creator Mode mở code) mới phụ thuộc. Các màn lý thuyết, ghép
khối, và điều khiển có cấu trúc **không** cần interpreter.

**Sau này — chỉ đánh giá Python thật nếu có lý do rõ ràng:**
- Đánh giá nhúng Python thật qua một trong các phương án:
  - `chaquopy` (Android native).
  - `python-for-android` với bridge.
  - RustPython biên dịch sang WASM.
- **Chỉ chuyển** khi mô phỏng đã chứng minh được giá trị sư phạm và Python thật
  mang lại lợi ích rõ ràng. Không cam kết trước.

> **Không** tuyên bố trẻ đang chạy "Python thật" khi implementation chỉ mô phỏng
> một tập con. Giao diện và tài liệu phải nói rõ giới hạn này.

### 2.3. Tập con được hỗ trợ & kiểm soát thực thi

Đây là **interpreter mô phỏng một tập con có giới hạn**, **không** phải một
sandbox Python đa dụng. Thiết kế an toàn phải dựa trên các biện pháp
**thực sự thi hành được** trong interpreter, không dựa vào một giá trị cấu hình
đơn lẻ.

#### 2.3.1. Cú pháp và phép toán được phép (tập con khởi điểm)

- **Cho phép:** literal số/chuỗi/bool; gán biến; biểu thức số học và so sánh;
  `print()`; `if/elif/else`; `for ... in range(...)`; `while`; list cơ bản và
  truy cập theo chỉ số; `def` với tham số và `return`; gọi hàm.
- **Không cho phép:** import; truy cập file; mạng; `eval`/`exec`; `class`;
  decorator; generator; `async`; và mọi truy cập tài nguyên hệ thống.

#### 2.3.2. Kiểm soát có thể thi hành

**Yêu cầu thiết kế, không phải chứng nhận sandbox.** Config/runtime source tại
CODE71b0 có `step_budget=100000`, `max_call_depth=50`, `max_output_chars=10000`
và `max_collection_length=10000`. Output là **ký tự**, không phải bảo đảm10KB.
Có bộ đếm/check trong source không chứng minh mọi operation, cấp phát hoặc thời
lượng CPU đều đã bị chặn. Cần evidence theo từng đường thực thi; đợt r47 không
chạy lại interpreter hay kiểm tra sandbox trên thiết bị. Rate-limit print, hủy
isolate và mục tiêu bộ nhớ bên dưới vẫn là yêu cầu cần kiểm chứng, không claim
đều đã triển khai. Xem [ma trận source/evidence](PROJECT_STATUS.md).

| Kiểm soát | Cách thi hành | Giá trị |
|---|---|---|
| **Ngân sách bước (step budget)** | Đếm số "bước" ngay trong vòng lặp interpreter; dừng khi vượt ngưỡng. Đây là **ràng buộc cứng chính**. | 100.000 bước (**TBD** — cần hiệu chỉnh theo trải nghiệm thực tế) |
| **Độ sâu gọi/đệ quy** | Bộ đếm call-depth tường minh, tăng khi gọi hàm, giảm khi `return`. | 50 (**TBD**) |
| **Kích thước output** | Cộng dồn độ dài output; dừng/khóa khi vượt ngưỡng. | 10.000 ký tự trong source; cần kiểm chứng enforcement |
| **Kích thước collection** | Chặn khi list vượt độ dài tối đa. | 10.000 phần tử trong source; cần đo/kiểm chứng, không phải trần bộ nhớ |
| **Số lần in mỗi giây** | Đếm và gộp output trong cửa sổ thời gian. | 100/giây (**TBD**) |

#### 2.3.3. Ngắt/hủy thực thi — thiết kế đúng

- **Timeout wall-clock một mình KHÔNG dừng được code CPU-bound** chạy đồng bộ
  trong cùng isolate: một `while True` sẽ chặn luồng và không nhường quyền cho
  bộ hẹn giờ. Vì vậy **không** được mô tả "đặt 3 giây là tự dừng".
- Cách làm đúng (chọn một, thiết kế để có thể thay):
  - **Ưu tiên:** chặn bằng **ngân sách bước** (2.3.2). Phải kiểm tra coverage của
    bộ đếm và chặn các operation/cấp phát tốn kém; không suy ra “luôn dừng an toàn
    bất kể code làm gì” chỉ từ việc có một counter.
  - Nếu cần hủy giữa chừng theo yêu cầu người dùng: chạy interpreter trong một
    **isolate riêng** và **hủy isolate** khi người dùng bấm dừng.
- **Giới hạn bộ nhớ:** không thể thi hành "trần cứng" chỉ bằng một giá trị cấu
  hình trong tiến trình Dart. Cách khả thi: giới hạn collection + ngân sách bước
  + isolate riêng. Giá trị "32 MB" cũ chỉ là **mục tiêu tham khảo**, không phải
  ràng buộc được bảo đảm → đánh dấu **TBD** cho tới khi có cơ chế đo đáng tin.

#### 2.3.4. Thông báo khi vượt giới hạn

Khi vượt giới hạn: dừng thực thi an toàn và hiển thị thông báo **thân thiện với
trẻ** (ví dụ: "Chương trình chạy hơi lâu rồi! Mình thử làm ngắn lại nhé?"),
**không** hiển thị lỗi kỹ thuật thô.

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
    │ (Bài học, tiến trình) │          │  (Robot Maze…)  │
    └────────┬────────┘          └────────┬────────┘
             │                            │
             └────────────┬───────────────┘
                          │
             ┌────────────▼────────────┐
             │   Shared State Layer    │
             │ (Progress, Energy, Achievements)  │
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
  Future<void> recordLessonCompleted(String lessonId);
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

### 3.4. Mỗi game/nhánh là một module độc lập

- Mỗi game hoặc nhánh hoạt động sở hữu **luật chơi, điểm số, kỹ năng, tài nguyên
  và tiến trình riêng**. Lớp dùng chung không định nghĩa lại các phần này.
- Lớp dùng chung chỉ cung cấp những gì **nhiều nhánh cùng cần**: điều hướng, hồ sơ
  người chơi, thành tích liên quan, và — khi có mục đích rõ — điểm đóng góp/danh
  hiệu như lớp liên kết thành tích. Không dùng chung một công thức điểm hay tiến
  trình cho các game không liên quan.
- Thêm một game/nhánh mới chỉ cần **thêm module và nối qua interface/event**; không
  viết lại nền tảng và không nhân bản hệ thống thành tích.
- **Không** dựng backend, hệ thống mạng xã hội phức tạp hay hạ tầng đồng bộ
  realtime chỉ để phòng trước. Với game thiên về so điểm, gameplay có thể chạy cục
  bộ trên máy người chơi và chỉ đồng bộ phần kết quả cần thiết khi một game cụ thể
  thực sự cần.

### 3.5. Arena là các module độc lập trong cùng lớp gameplay

- Arena gồm nhiều bộ môn (đối kháng trực tiếp, tích lũy sản phẩm/bộ sưu tập sáng tạo, giải đồng đội, Creator Pro League). Mỗi bộ môn là một module gameplay độc lập với luật chơi, điều kiện thắng, cách chấm điểm và phần thưởng riêng.
- Lớp dùng chung chỉ cung cấp hồ sơ, điểm đóng góp, danh hiệu, mở khóa kiến thức và thành tích. Không ép các bộ môn dùng chung một công thức điểm.
- Điểm realtime/thanh tiến độ là dữ liệu runtime của trận; chỉ lưu kết quả có ý nghĩa (thắng/thua, điểm, thứ hạng, danh hiệu) vào lớp chung theo luật của bộ môn.
- Creator Pro League cần module mô phỏng để chạy sản phẩm; kết quả mô phỏng là nguồn sự thật cho các chỉ số khách quan. AI đánh giá chỉ hỗ trợ tiêu chí sáng tạo/chất lượng, không thay thế dữ liệu mô phỏng.
- Không giả mạo người thật trong bảng xếp hạng luyện tập; dữ liệu thi đấu thật và dữ liệu luyện tập phải được phân biệt ở tầng dữ liệu và giao diện.

### 3.6. Thế giới làng PyQuest — mỗi ngôi nhà là một module

- Màn hình chính là thế giới có thể khám phá; các ngôi nhà/công trình/cổng là điểm vào module gameplay.
- Ví dụ module: Thư viện Python/Tutor, tòa nhà Main Quest, Đấu trường, Xưởng sáng tạo, Bảo tàng/Bộ sưu tập, cổng Side Maps, Nhà bạn bè (khi triển khai).
- Mỗi module có vòng lặp chơi, giao diện, luật, tiến trình, phần thưởng và nội dung mở rộng riêng.
- Có thể thêm module mới mà không viết lại module cũ; chỉ kết nối qua interface/event.

### 3.7. AI Tutor là dịch vụ có ngữ cảnh, không phải chatbot tách rời

- Tutor được gọi từ các màn học/chơi với ngữ cảnh tối thiểu: mục tiêu nhiệm vụ, câu hỏi hiện tại, câu trả lời của trẻ, số lần thử, gợi ý đã đưa, khái niệm đang học.
- Không gửi toàn bộ lịch sử hoặc dữ liệu không cần thiết.
- Hệ thống bài học/mô phỏng là nguồn sự thật về đáp án; AI giải thích/gợi ý nhưng không ghi đè đáp án, quy tắc chấm hoặc kết quả trận.
- Gợi ý theo từng nấc: hướng chú ý → gợi ý một bước → minh họa/giải thích. Không mặc định bật mí đáp án ngay ở lần sai đầu tiên.
- Phản hồi phải phù hợp lứa tuổi/ngôn ngữ; có giới hạn an toàn và cơ chế thoát dễ thấy.

---

### 3.8. Các domain mở rộng và ranh giới ownership

**Thiết kế đích, chưa phải các service đã tồn tại trong source a9b.** Không dựng
backend trước nhu cầu cụ thể, nhưng visit thật/quyền chia sẻ không thể giả bằng
SQLite local. Không tạo module mới cho từng căn nhà hoặc instance pet.

| Domain đề xuất | Sở hữu / trách nhiệm | Không được quyết định |
|---|---|---|
| World catalog/session | Region kind, portal graph, availability, bounds, navigation/occlusion, nguồn/đích travel, return context | Grade, reward, ownership hoặc rank |
| Housing | Space/room/parcel, bố cục phiên bản, object instance, footprint/lối ra, draft/commit | Tự cấp đồ, quyền Side Map hay quyền khách |
| Projects/inventory | Recipe version, grants, vật liệu, build commands/receipts; phối hợp debit+grant atomic | UI tự grant từ text “thắng”; tiêu badge như tiền |
| Visit/social | Invite/session, vai trò/quyền vùng, revocation, presence, moderation | Friend=true đồng nghĩa edit toàn nhà; private payload gửi rồi che UI |
| Pet behavior | State machine, safe actions, pathfinding; adapter capability/model tùy chọn | Mua hàng, cấp quyền, ghi điểm/đáp án từ model text |
| Entitlements | Quyền nội dung/đồ/pet/mua đã xác minh và restore/revoke | Boolean local tự chứng minh giao dịch trả phí |
| Arena/Creator | Artifact versions, submission/result authority, title/rank contribution | Cảnh nhà đẹp hoặc pet đắt tự cấp thành tích |

Data IDs phải tách `regionId`, `spaceId`, `ownerId`, `activityId`, `projectId`,
`recipeVersion`, `objectInstanceId`, `petId`, `sessionId`, `commandId`. Locale chỉ
chọn copy, không đổi IDs hoặc business keys. Personal island khác paid content pack.
Đây là vocabulary/schema contract đề xuất, chưa là lệnh tạo migration/API.

`ActivityRegistry` hiện có vẫn là nơi mở các hoạt động thật. UI world gọi adapter
availability/router; không hardcode một lớp grading/economy mới vào màn làng.
Travel mang nguồn/đích + cancel/generation token; chỉ commit arrival sau load và
quyền hợp lệ. Lỗi giữ nguồn, resume không tự grant phần thưởng hoặc replay travel.

---

## 4. Lưu dữ liệu

### 4.1. Quyết định: một database SQLite cục bộ

- **Một file SQLite duy nhất**, các bảng tách theo module logic.
- **Không** tạo database vật lý riêng cho từng module. Chỉ tách khi có lý do cụ
  thể được ghi rõ trong tài liệu (ví dụ: yêu cầu hiệu năng đo được); mặc định là
  **một database**.
- **Không** dùng file JSON rời rạc cho dữ liệu gameplay quan trọng
  (dễ hỏng, khó migrate, khó query). `game_config.json` chỉ chứa **cấu hình
  tĩnh**, không phải trạng thái gameplay.

### 4.2. Bảng theo module

| Module | Bảng | Dữ liệu sở hữu |
|---|---|---|
| Progress | `progress`, `skills` | Bài học đã hoàn thành, kỹ năng đã nắm |
| Reward claims | `reward_claims` | Khóa chống nhận trùng cho phần thưởng mốc và các thành tích được trao một lần |
| Games | `game_results`, `unlocked_levels` | Điểm cao, màn đã mở, sao |
| Energy | `energy_state` | Năng lượng hiện tại, năng lượng tối đa, thời điểm hồi tiếp theo |
| Rewarded ads | `rewarded_ad_claims` | Số lượt quảng cáo hợp lệ trong ngày, theo ngày địa phương |
| Daily quests | `daily_quests` | Nhiệm vụ ngày, trạng thái hoàn thành, ngày áp dụng |
| Achievements | `achievements` | Huy hiệu đã mở, thời điểm mở |
| Purchases | `purchases` | Bản ghi mua hàng + trạng thái **xác minh** (không phải bằng chứng quyền sở hữu cuối cùng) |
| Settings | `settings` | Ngôn ngữ, âm thanh, nhạc nền, `schema_version` |
| Arena (khi triển khai) | `arena_results`, `arena_titles`, `leaderboard_contributions` | Kết quả trận/thử thách, danh hiệu, điểm đóng góp theo luật bộ môn |
| Social (khi triển khai) | `friends`, `teams`, `gifts`, `social_titles` | Quan hệ bạn bè, đội, quà tặng, danh hiệu xã hội |
| AI Tutor (khi triển khai) | `tutor_preferences`, `tutor_context_cache` (nếu cần) | Nhân vật Tutor đang dùng, cài đặt; không lưu dữ liệu nhạy cảm |

### 4.3. Schema mẫu

```sql
CREATE TABLE progress (
  id INTEGER PRIMARY KEY,
  lesson_id TEXT NOT NULL UNIQUE,
  completed_at INTEGER NOT NULL
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

-- Chống cộng trùng phần thưởng quảng cáo theo ngày địa phương.
CREATE TABLE rewarded_ad_claims (
  local_day TEXT NOT NULL,          -- ví dụ '2026-10-15'
  claims_used INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (local_day)
);

-- Nhiệm vụ ngày: khóa theo (ngày, nhiệm vụ) để không cộng lại.
CREATE TABLE daily_quests (
  local_day TEXT NOT NULL,
  quest_id TEXT NOT NULL,
  completed INTEGER NOT NULL DEFAULT 0,
  rewarded INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (local_day, quest_id)
);

-- Phần thưởng "một lần" dùng chung: mỗi phần thưởng chỉ có một khóa duy nhất.
-- Ví dụ: 'exercise:05a', 'custom_game:12', 'chapter:01', 'bug:robot_maze:07'.
CREATE TABLE reward_claims (
  reward_key TEXT PRIMARY KEY,
  awarded_at INTEGER NOT NULL
);

CREATE TABLE achievements (
  achievement_id TEXT PRIMARY KEY,
  unlocked_at INTEGER NOT NULL
);
```

> Ghi chú: `UNIQUE(lesson_id)`, `UNIQUE(game_id, level_id)`, `reward_key`,
> khóa chính của `rewarded_ad_claims`, `daily_quests`, `achievements` là cơ chế
> **chống cộng trùng** — xem mục 4.6.

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

### 4.6. Chống cộng trùng & khôi phục sau khi mở lại app

Mục tiêu: các sự kiện hoàn thành lặp lại hoặc việc **thoát/mở lại app** không
được cộng phần thưởng "một lần" hai lần (xem quy tắc ở `GAME_DESIGN.md` mục 4.3).

**Cơ chế:**

- **Ghi "lần đầu" bằng INSERT có ràng buộc duy nhất.** Ví dụ: hoàn thành bài học
  → `INSERT INTO progress(lesson_id, ...)`. Nếu `lesson_id` đã tồn tại, lệnh
  thất bại và không ghi nhận hoàn thành. Tương tự với màn mini-game qua `game_results`.
- **Các phần thưởng một lần khác (bài tập, game tự tạo, thử thách chặng, lỗi)
  dùng chung bảng `reward_claims`** với `reward_key` duy nhất (`exercise:…`,
  `custom_game:…`, `chapter:…`, `bug:…`). Chỉ trao phần thưởng mốc khi insert khóa mới thành công; khóa đã tồn tại thì bỏ qua.
- **Quảng cáo thưởng:** tăng `claims_used` trong `rewarded_ad_claims` **chỉ sau**
  callback xác nhận hợp lệ. Đọc lại số lượt trước khi cho phép xem.
- **Nhiệm vụ ngày:** kiểm tra khóa `(local_day, quest_id)` trong `daily_quests`
  trước khi cộng; dùng ngày **địa phương** để reset.
- **Tính idempotent:** xử lý cùng một sự kiện nhiều lần (do retry, resume,
  hoặc mở lại app) cho kết quả như xử lý một lần.

### 4.7. Bản ghi cục bộ vs quyền sở hữu đã xác minh

- Bảng `purchases` là **bản ghi cục bộ + dấu xác minh**, **không** phải bằng
  chứng cuối cùng về quyền sở hữu.
- Một boolean cục bộ hoặc file cục bộ có thể chỉnh sửa **không** đủ để xác nhận
  đã mua. Quyền sở hữu phải được **truy vấn/xác minh lại** qua hệ thống thanh
  toán nền tảng (xem mục 7).
- **Không cần backend ở giai đoạn Foundation.** Có thể dùng truy vấn Google Play
  Billing ngay trên thiết bị; chỉ cân nhắc server khi yêu cầu thực tế đòi hỏi
  xác minh tập trung (xem mục 12).

---

### 4.8. Dữ liệu không gian, dự án và authority mở rộng

Giữ một SQLite cho phần local. Các nhóm sau là **dự kiến theo domain**, không thêm
bảng chỉ vì có mockup. Migration cụ thể chỉ mở trong work order triển khai.

| Dữ liệu | Local solo | Shared / trả phí / thi đấu |
|---|---|---|
| Layout/draft của chủ | Repository housing, revision, validation footprint | Published revision + quyền chỉnh do dịch vụ xác minh; client không overwrite snapshot cũ |
| Vật liệu/project/build receipt | Transaction local bền vững, dedup và recovery | Service ledger là authority; cache/outbox không tự coi là đã commit |
| Badge/tiến trình đã có | Đọc từ owner hiện hành, không duplicate bảng trong housing | Không suy ra entitlement từ đồ trưng bày |
| Visit presence/quyền | Không giả online; cached shared snapshot chỉ khi policy còn cho phép | Session server authoritative, revoke/expiry, payload tối thiểu theo quyền |
| Pet và model | Config/memory game hữu hạn; capabilities/model files riêng | Ownership trả phí từ receipt; shared actions do một session authority validate |
| UGC/Arena | Draft/artifact local và trạng thái gửi | Moderation/result authority, private/approved/held, không tính rank từ fake leaderboard |

**Command xử lý mở rộng:** load receipt theo key bền vững → kiểm principal/owner,
project+recipe version, state và requirements → atomic debit vật liệu + grant space
+ ghi receipt → phát domain event sau commit. Retry cùng key trả cùng kết quả;
request body khác cùng key bị từ chối. Hai lệnh khác nhau xây cùng mục tiêu phải có
ràng buộc uniqueness/revision, không chỉ khóa nút UI. Module giữ ownership bảng,
phối hợp qua transaction coordinator/unit-of-work, không cho UI tự ghi nhiều bảng.

App đóng giữa pending: reopen tra receipt/đồng bộ lại, không đoán thành công/thất bại
bằng animation. Server đã commit nhưng response mất không được debit lần hai.
Cancel trước gửi không thay dữ liệu; sau gửi là **chưa biết kết quả**, không tự rollback
server. Recipe đổi/balance đổi phải kiểm ở commit, không tin preview cũ. Không dùng
last-write-wins cho tài nguyên/ownership; merge layout phải có policy xung đột.

Offline không phải một boolean cho mọi thứ: hoạt động solo và dữ liệu local đã được
phép vẫn dùng được; quyền shared/paid/rank cần authoritative receipt hoặc chính sách
cache đã duyệt. Khi chuyển local solo sang account không tự biến ledger local thành
quyền mua/thi đấu đã xác minh. Phải có migration/reconciliation rõ, không xóa save.

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

### 5.4. Arena và thành tích

- Arena phát sự kiện chuẩn khi hoàn thành trận/thử thách: `arena_match_completed`, `arena_challenge_completed`, `title_unlocked`.
- `achievement_engine` kiểm tra điều kiện danh hiệu theo luật bộ môn.
- Điểm đóng góp vào tổng sắp được tính theo quy tắc đã công bố; không để một nhánh cày lặp vô hạn thống trị bảng.
- Bảng xếp hạng người thật và bảng luyện tập phải được phân biệt ở tầng dữ liệu.

---

## 6. Quảng cáo

### 6.1. Nhà cung cấp: Google AdMob

- Chỉ dùng **rewarded ads** ở giai đoạn đầu.
- Không dùng interstitial, banner, native ads cho trẻ nhỏ.
- **Chưa xác nhận** cấu hình ad network này đáp ứng chính sách hướng tới trẻ em.
  Phải kiểm tra **Google Play Families** và chính sách của mạng quảng cáo **trước
  khi bật quảng cáo thật**; không mặc định là đã tuân thủ.
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
- Quảng cáo phải xuất hiện ở điểm dừng tự nhiên, không ép xem giữa màn chơi, không chặn việc học kiến thức cốt lõi của Main Quest.
- Mỗi hạng mục có hạn mức riêng: lượt miễn phí, số lượt có thể nhận thêm qua quảng cáo, khoảng thời gian áp dụng và thời điểm làm mới hạn mức.

### 6.4. Trạng thái Pro & nguồn năng lượng qua quảng cáo

**Nguyên tắc giữ nguyên:**
- Quảng cáo thưởng là **tùy chọn**; Main Quest và nội dung học cốt lõi luôn truy
  cập được **không cần** xem quảng cáo.
- Chỉ cộng thưởng sau **xác nhận hợp lệ** từ SDK.
- Quảng cáo **thất bại** không trừ năng lượng và không tiêu mất lượt.
- Pro **không** khóa Main Quest.
- Trạng thái Pro lưu trong `purchases`, **xác minh qua billing** (không tin cờ cục bộ).

> **TBD — cần quyết định sản phẩm.** "Pro bỏ quảng cáo" và "quảng cáo thưởng là
> cách tùy chọn để thêm năng lượng" đang **xung đột** nếu Pro ẩn hết nút quảng
> cáo: người dùng Pro sẽ mất nguồn năng lượng đó. Cần chốt một trong hai:
> (a) Pro vẫn được **tự nguyện** xem quảng cáo thưởng, hoặc (b) Pro có **cách
> công bố rõ khác** để nhận phần năng lượng tương đương.
> Không tự đặt chính sách monetization mới trước khi quyết định. Xem
> `PRODUCT_VISION.md` mục 3.3.

**Phạm vi (đã chốt):** nếu Pro bỏ quảng cáo, chỉ bỏ **quảng cáo** — không đụng
tới quyền học, không khóa nội dung cốt lõi.

---

## 7. Thanh toán

### 7.1. Nhà cung cấp

- **Android:** Google Play Billing Library.
- **iOS (sau):** StoreKit 2.

### 7.2. Sản phẩm

| Loại | Ví dụ | Ghi chú |
|---|---|---|
| **In-app purchase (không tiêu hao)** | Side Maps, Pro, nhân vật Tutor, quà tặng | Mua một lần, dùng mãi |
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
- Parental gate trước màn hình mua hàng.
- Không hiển thị giá bằng tiền thật cho trẻ mà không có gate.
- Không dùng ngôn ngữ gây áp lực ("chỉ còn hôm nay", "mua ngay").
- Mua nhân vật Tutor chỉ thay đổi phần mỹ thuật/đã công bố; không khóa chất lượng giải thích, độ thông minh, số gợi ý cần thiết hoặc quyền được trợ giúp cốt lõi sau paywall.
- Mua quà/danh hiệu xã hội không mua được thứ hạng, điểm thi đấu hay chứng nhận kỹ năng.

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
│   │   ├── arena/
│   │   │   ├── direct_duel/
│   │   │   ├── creator_pro_league/
│   │   │   └── team_tournament/
│   │   ├── tutor/
│   │   ├── social/
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
- **Không** commit secret vào repository. Với production/public release, không nhúng provider key vào client; [owner-test r49](OWNER_TEST_BUILDS.md) được người dùng cho phép nhúng key để thử nội bộ, hoãn token/backend/quota.
- **Không** tạo bảng XP/level toàn cục.

---

## 9. AI Tutor — kiến trúc và an toàn

### 9.1. Nguyên tắc

- Trước khi chọn nhà cung cấp/model, xác định yêu cầu chất lượng tiếng Việt, độ trễ, khả năng gợi ý theo từng bước, chi phí mỗi phiên và phương án khi dịch vụ lỗi. Có thể đánh giá các nhà cung cấp như Gemini hoặc lựa chọn khác, nhưng không khóa kiến trúc vào một nhà cung cấp trước khi có thử nghiệm và quyết định được ghi nhận.
- Khóa API và thông tin bí mật phải nằm ở backend/service an toàn.
- Dùng giới hạn token/thời lượng, rate limit, quota và theo dõi chi phí; không để một tài khoản có thể tạo chi phí không giới hạn.
- Chỉ gửi dữ liệu tối thiểu cần thiết cho nhiệm vụ. Không yêu cầu tên thật, địa chỉ, trường học, số điện thoại, ảnh, vị trí hoặc thông tin nhạy cảm để dùng Tutor.
- Xác định rõ phần nào chạy cục bộ, phần nào gửi đến dịch vụ bên ngoài; thông báo dễ hiểu cho phụ huynh về việc dùng AI/giọng nói và dữ liệu được xử lý.
- Không tuyên bố hội thoại hoàn toàn riêng tư hoặc không được lưu nếu kiến trúc nhà cung cấp chưa chứng minh điều đó.

### 9.2. Kiểm thử AI Tutor

Kiểm thử bằng bộ tình huống dành riêng cho trẻ: câu trả lời sai liên tiếp, câu hỏi ngoài chủ đề, nội dung không an toàn, yêu cầu tiết lộ dữ liệu, prompt injection, câu trả lời AI sai, ngắt mạng, timeout, hết quota và chuyển sang trợ giúp không AI.

### 9.3. Tiêu chí nghiệm thu mẫu đầu tiên

- Cảnh mở đầu có hình ảnh và chuyển động đủ chất lượng để đại diện cho phong cách PyQuest mới; không phải chỉ là màn chat với ảnh đại diện.
- Người chơi có thể tương tác, nhận phản hồi phù hợp và vào game; có thể bỏ qua hoặc xem lại.
- Ít nhất một nhân vật mặc định hoàn chỉnh; hệ thống thiết kế cho phép thêm cún/mèo/rồng/búp bê mà không phải viết lại luồng hội thoại.
- Mua nhân vật chỉ thay đổi phần mỹ thuật/đã công bố; Tutor miễn phí vẫn có đủ năng lực hỗ trợ học tập cốt lõi.
- Tutor sử dụng đúng ngữ cảnh bài hiện tại, đưa gợi ý theo nấc và không tự ghi đè đáp án chuẩn.
- Có giới hạn an toàn, xử lý lỗi dịch vụ, kiểm soát chi phí và quy tắc dữ liệu trước khi đưa AI thật tới người dùng.

---

### 9.4. Pet thông minh và local AI: tách capability khỏi ownership

Hành vi nền (di chuyển, chơi, nghỉ, phản hồi đồ vật) chạy deterministic/state machine,
không chờ LLM mỗi frame. Intent classifier/rules và model ngôn ngữ là adapter tùy
chọn; một runtime có thể dùng chung, không nạp một model cho mỗi pet. Engine validate
safe action schema trước khi thực thi; text không thành code/URL/quyền/giao dịch.

Capability states: unsupported, absent, downloading, ready, failed/disabled. Các
trạng thái không đồng nghĩa mất pet. Trước giao dịch phải công bố khả năng trên máy,
phần cần model/tải thêm và fallback. Tải có cancel/integrity/license/version checks;
xóa model không xóa ownership. Không gửi lên cloud âm thầm khi local lỗi.

Scheduler theo sự kiện có timeout/cancel, pause/background và giới hạn công việc.
Shared pet chỉ có một nguồn quyết định theo session; các client không tự sinh
hành vi rồi ghi đè nhau. Không truyền dữ liệu private của khách vào model; tên nhà,
thiệp/UGC là dữ liệu không tin cậy, không phải system instructions. Memory chỉ là
sở thích game hữu hạn, xem/xóa/reset được; không lưu mọi hội thoại mặc định.

Trước chọn model/runtime phải benchmark Android mục tiêu **cùng scene game đang
render**: peak RAM, download/install, cold start, latency phân vị, pin/nhiệt,
background/cancel, an toàn và chất lượng VI/EN. Chưa chốt model, dung lượng hay hứa
AI sinh trên mọi máy. Fallback không bị ghi nhãn giả là AI. Tutor core và UI world
không phụ thuộc benchmark này; key/token production của voice vẫn là gate riêng.

---

## 10. Kiểm thử

### 10.1. Nguyên tắc

Với PyQuest, phần lớn module độc lập, chủ yếu ghi và đọc trạng thái.
**Không** biến việc phát triển thành dự án chạy hàng đống test.
Ưu tiên kiến trúc đơn giản, luồng chơi thật, kiểm tra tổng thể ở cuối.

### 10.2. Không test tràn lan

- Không viết unit test cho từng hàm nhỏ, getter/setter, thao tác lưu đơn giản.
- Không cố định từng pixel, khoảng cách, màu sắc, animation bằng test.
- Không dựng mock phức tạp cho module vốn độc lập.
- Không chạy toàn bộ test sau mỗi lần sửa giao diện.

### 10.3. Điểm kiểm tra bắt buộc

Không cần nhiều test, nhưng **phải** có điểm kiểm tra đủ sức phát hiện lỗi nghiêm trọng:

| Lỗi cần phát hiện | Cách kiểm tra |
|---|---|
| **Mất dữ liệu** | Thoát app, mở lại, xác nhận trạng thái còn nguyên |
| **Cộng thưởng sai** | Kiểm tra luồng nhận điểm thưởng đã định nghĩa, năng lượng và huy hiệu |
| **Vượt giới hạn Python** | Chạy code gây vòng lặp vô hạn, kiểm tra dừng an toàn |
| **Xác nhận Pro sai** | Mô phỏng purchase token giả, kiểm tra không mở nội dung |

### 10.4. Test cuối theo chuyến phiêu lưu

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

## 11. Hiệu năng & tài nguyên

### 11.1. Mục tiêu

| Chỉ số | Mục tiêu |
|---|---|
| Thời gian khởi động app | < 3 giây (thiết bị tầm trung) |
| Thời gian load màn mini-game | < 1 giây |
| FPS mini-game | 60 FPS ổn định |
| Dung lượng app | < 150 MB (không tính asset tải thêm) |
| Bộ nhớ khi chạy | < 200 MB |

### 11.2. Chiến lược asset

- Ảnh: dùng định dạng nén tốt (WebP).
- Âm thanh: OGG cho nhạc nền, WAV ngắn cho hiệu ứng.
- Asset lớn (Side Maps): tải theo gói khi mua, không nhúng hết vào app.
- Nhân vật Tutor trả phí: xem trước hoạt ảnh thực tế trước khi mua; cần thiết kế silhouette/hoạt ảnh phù hợp nhiều tỉ lệ màn hình.

---

### 11.3. Scene pipeline cho làng, nhà và đảo

Background/terrain, landmark, prop, actor, foreground occluder và HUD tách lớp.
Scene definition chứa camera bounds, foot pivots, footprints, walkable paths,
portal anchors và semantic targets; ảnh nền không phải navigation mesh. Bản đồ
zoom/pan có danh sách điểm đến thay thế, text không bake vào art.

Culling/pooling/atlas và một scheduler giới hạn actor; pause offscreen/background,
không replay hàng phút animation khi resume. Travel skip/cancel được; không timer
riêng vô hạn cho từng NPC. Model/assets có tải/hủy/retry/fallback và manifest nguồn.
Flutter assets directory không recursive với JSON con: đăng ký chính xác hoặc đặt
file trực tiếp dưới thư mục đã khai báo, kiểm bằng AssetManifest/rootBundle thật.

Các số §11.1 là mục tiêu base app, không bằng chứng đã đo và không tự cấp thêm RAM
cho inference. Pet model cần profile ngân sách thiết bị riêng được review; scene
phải vẫn hoạt động khi thiếu model. Chưa có quyền thay engine/render stack/deps chỉ
vì tài liệu này đề xuất chia lớp.

---

### 11.4. Art pipeline2,5D bắt buộc, không bắt đổi engine

Theo [ART_DIRECTION_2_5D](design/ART_DIRECTION_2_5D.md), mọi màn dùng chung camera
family/material/light/actor scale. Có thể dùng pre-rendered2D layers để biểu đạt2,5D;
không tự thêm engine3D/package. HUD/text/semantics tách scene transform.

Phân biệt concept image, screen composition và production art pack. Trước runtime
phải có layer/alpha/dimensions/pivot/footprint/occluder/hit-target/source-license;
ảnh isometric opaque không tự có geometry hoặc animation. Asset resolution/crop
không được làm lệch collider/touch target. Font/scale/calm/keyboard dùng UI thật,
không chứng minh bằng chữ bake vào ảnh. VI/EN strings/code/giá không bake vào asset.

Kiểm camera/shadow/contact point và độ rõ trên phone trước khi import; quality
review concept không thay device performance hoặc runtime integration tests.

---

## 12. Bảo mật & quyền riêng tư

### 12.1. Dữ liệu trẻ em

- **Không** thu thập dữ liệu cá nhân ngoài mức cần thiết.
- **Không** yêu cầu đăng ký tài khoản ở giai đoạn đầu.
- **Không** gửi dữ liệu lên server nếu chưa có parental consent.
- Tuân thủ **COPPA** (Mỹ) và **GDPR-K** (EU) nếu phát hành ở các thị trường đó.

### 12.2. Lưu trữ cục bộ

- Toàn bộ tiến trình lưu cục bộ ở giai đoạn đầu.
- Nếu thêm cloud sync sau: mã hóa khi truyền, xin consent rõ ràng.

### 12.3. Interpreter

- Interpreter mô phỏng **không** có quyền truy cập file hệ thống hay mạng.
- Không cho phép import module hệ thống.
- Kiểm soát thực thi như mục 2.3.
- Nếu sau này nhúng Python thật: chạy trong sandbox, áp dụng lại các kiểm soát và
  đánh giá rủi ro bảo mật trước khi phát hành.

### 12.4. Cộng đồng và an toàn

- Nội dung do người chơi tạo và lời nhắn phải có cơ chế báo cáo/kiểm duyệt phù hợp.
- Không mặc định cho phép giao dịch điểm, danh hiệu thành tích hoặc tài khoản giữa người chơi.
- Mọi mua hàng/quà tặng trả phí phải hiển thị rõ giá, vật phẩm nhận được và xác nhận trước giao dịch.
- Thiết kế theo độ tuổi và rà soát các yêu cầu pháp lý/nền tảng trước khi phát hành.

---

## 13. Quyết định còn để mở

Các quyết định sau **chưa chốt**, cần đánh giá thêm:

| Quyết định | Khi nào chốt |
|---|---|
| Python thật hay mô phỏng sau này | Sau khi mô phỏng chứng minh giá trị sư phạm |
| Hạ tầng backend cụ thể | Chọn theo nhu cầu: relay AI an toàn, visit session/quyền thật, shared ledger/rank/purchase; không giả các chức năng đó bằng local state |
| Có dùng Firebase không | Khi cần analytics, crash reporting, remote config |
| Có hỗ trợ iOS ngay không | Sau khi Android ổn định |
| Localization | VI/EN + system/manual đã chốt;014–016 chỉ nghiệm thu foundation/Settings. Lesson/world copy packs và voice locale còn cần gate riêng |
| Người dùng Pro có được xem quảng cáo thưởng không | Quyết định sản phẩm (xem 6.4) |
| Giá trị cụ thể của ngân sách bước, trần collection, mục tiêu bộ nhớ | Sau khi đo thực tế interpreter (xem 2.3) |
| Hệ thống bạn bè/cộng đồng và đồng bộ thi đấu | Chỉ khi một game cụ thể cần; không dựng trước (xem 3.4) |
| Nhà cung cấp/model AI Tutor | Sau thử nghiệm chất lượng tiếng Việt, độ trễ, chi phí |
| Cơ chế kiểm duyệt nội dung do người chơi tạo | Trước khi bật tính năng cộng đồng |
| Recipe, supply/material ledger và migration người chơi cũ | Trước slice xây nhà, không copy fixture P06C vào economy |
| Visit capacity/reconnect/co-edit conflict/revocation | Trước visit thật; quyền/authority phải chốt trước UI “cùng chơi” |
| Model/runtime/license, capability/pet memory policy | Sau benchmark VI/EN và máy mục tiêu, trước lời hứa mua AI |
| Giá/tiền tệ/entitlement mở rộng và pet | Trước commerce slice, parental/refund/restore cần policy riêng |

---

## 14. Tóm tắt quyết định chốt

| Hạng mục | Chốt |
|---|---|
| Framework | Flutter |
| Python runtime giai đoạn đầu | Mô phỏng có giới hạn rõ |
| Python runtime giai đoạn sau | Đánh giá lại, không cam kết trước |
| Lưu dữ liệu | SQLite, tách bảng theo module |
| Quảng cáo | AdMob rewarded, tối đa 3/ngày |
| Thanh toán | Google Play Billing |
| Kiến trúc | Module hóa, interface rõ ràng |
| Mở rộng nhánh mới | Thêm module + interface/event; không sửa nền tảng (xem 3.4) |
| Kiểm thử | Không tràn lan, tập trung điểm rủi ro cao |
| Lát cắt dọc đầu tiên | Mở app → chơi mini-game → lưu → mở lại vẫn còn |
| AI Tutor | Dịch vụ qua backend/service an toàn, ngữ cảnh tối thiểu |
| XP/cấp độ toàn cục | Không dùng |

---

## Tài liệu liên quan

- [`PRODUCT_VISION.md`](PRODUCT_VISION.md) — triết lý sản phẩm, thế giới, mô hình kinh doanh.
- [`GAME_DESIGN.md`](GAME_DESIGN.md) — luật chơi, năng lượng, mở khóa hoạt động và cân bằng độ khó.
- [`ROADMAP.md`](ROADMAP.md) — giai đoạn triển khai và tiêu chí nghiệm thu.
- [`../README.md`](../README.md) — điểm vào dự án.
- [`ARENA_CREATOR_COMPETITION_BRIEF.md`](ARENA_CREATOR_COMPETITION_BRIEF.md) — nguồn bổ sung về Arena, Creator League và trải nghiệm thi đấu.

---

## 15. Trạng thái triển khai hiện tại và UI Direction V2

### 15.1. Snapshot source a9bcdcf — không phải danh sách domain tương lai đã triển khai

- `activity_registry` và `MainMapScreen` cho bản đồ đảo và các địa điểm hoạt động.
- Main Quest, mini-game, achievements, energy, daily quests và progress tracker.
- Trợ giảng (`lib/modules/tutor/`) tách theo trách nhiệm, mỗi tầng một file để test được độc lập:
  `tutor_session.dart` (chọn AI/ngoại tuyến, hạn mức, lịch sử), `tutor_provider.dart`
  (gọi relay OpenAI-compatible), `offline_tutor.dart` (soạn từ nội dung bài + thang
  gợi ý), `tutor_transcript.dart` (mô hình tin nhắn có vai: trẻ / trợ giảng, partial
  hay đã chốt, bị ngắt lời), `tutor_panel.dart` (UI dùng chung cho câu gõ và câu nói).
- Giọng nói Gemini Live (`gemini_live_wire.dart` giao thức, `live_audio_output.dart`
  vòng đời loa PCM + `PcmTurnPump`, `gemini_live_voice.dart` bắt lượt và micro
  half-duplex). Ba tầng này không gọi `TutorSession`: phiên voice nói chuyện trực
  tiếp với Live, còn câu hỏi gõ đi qua relay.
- Relay mẫu `tools/ai_relay/relay.py` giữ key phía server (allowlist model, giới
  hạn body/token, rate limit, không log nội dung) và có test chạy bằng Python thuần.
- SQLite cục bộ với các bảng theo module; không có bảng XP/level toàn cục.

### 15.2. Asset và tài liệu thiết kế

- Ảnh tham khảo và SVG V2 là tài liệu thiết kế, không phải asset runtime của app.
- 21 ảnh gốc trong `docs/PyQuest_Reffrence_Images/`, `PYQUEST_UI_DIRECTION_V2.svg`,
  `PYQUEST_VILLAGE_2_5D_CONCEPT.svg` và `docs/design/kai-lumi-character-reference.svg`
  đã có trong checkout làm nguồn tham khảo. Chuẩn hiện hành là ART_DIRECTION_2_5D;
  không dùng sự pha trộn trong ảnh gốc để hợp thức hóa nhiều style trong một app.
- Không đưa API key, token hoặc thông tin bí mật vào tài liệu, log hay commit.
  Đường chuẩn cho trợ giảng văn bản là **relay giữ key ở server**
  (`tools/ai_relay/relay.py`, `RELAY_API_KEY`), app chỉ cấu hình endpoint
  (`AI_TUTOR_ENDPOINT` hoặc `assets/config/ai_tutor_config.json`).
- Source Gemini Live còn đường thử nghiệm cục bộ bằng dart-define; key nằm trong
  APK và có thể bị trích xuất. `GeminiLiveWire.redactSecrets` chỉ giảm lộ trong
  log, không bảo vệ key trong client. Cần token ngắn hạn/server mediation trước
  khi cho phép phân phối voice công khai; owner-test r49 được miễn gate này theo
  quyết định người dùng. Việc sửa tài liệu không triển khai cơ chế token.
- **r49: người dùng cho phép nhúng Gemini key từ repository secret vào APK
  owner-test**, sau pinned-SDK checks trên exact source SHA. CI thông thường vẫn
  keyless. Token/backend/quota hoãn cho lần thử nội bộ; không public/store release.
- Xem [request/gates/evidence](OWNER_TEST_BUILDS.md). Key trong APK trích xuất được;
  không ghi key vào source/log/chat. Build success không thay device/voice tests.
  Các receipt r47/r48 giữ nguyên là lịch sử; artifact/key cũ không tự thu hồi/xoay.

### 15.3. UI Direction V2

UI V2 chưa được triển khai vào source. Việc áp dụng phải đi qua đánh giá màn hình hiện có, thiết kế chi tiết, triển khai, kiểm thử và xác nhận runtime.


### 15.4. Trạng thái đồng bộ mở rộng2026-10-18

World/housing/inventory/projects/visit/pet domains ở §3.8/4.8/9.4 là kiến trúc đích,
chưa có nghĩa migration/backend/model đã được viết.010/014/015/016 accepted riêng;
011 được giao r31 cho hai authored examples, không mở domain mở rộng hoặc deps.
APK a9b build run39052978443; CI source run39051006962 có406ordinary+10render.
UI/housing sẽ có order riêng theo Roadmap §17 và
[thiết kế W01–W14](design/WORLD_EXPANSION_REDESIGN.md). Không cần chờ voice/local AI
production mới triển khai UI làng; không vì vậy bỏ gate bảo mật khi phát hành voice.
