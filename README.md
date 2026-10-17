# PyQuest

> **Trạng thái đối chiếu r47 · 2026-10-18:** xem [source / evidence / release policy](docs/PROJECT_STATUS.md).
> Tầm nhìn, tiêu chí kế hoạch và source đã có không đồng nghĩa tính năng đã được nghiệm thu.

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

**Giai đoạn:** Bản chơi được đầu tiên — **v0.1 "Đảo Khởi Đầu"** (chưa phát hành).
**Repository:** Private.
**Nền tảng:** Flutter 3.47 (CI dùng 3.47.7) · Android trước, kiến trúc giữ tương thích iOS.

Mã nguồn ứng dụng nằm trong [`app/`](app/). Mô tả những gì đã có ở mục
[Bản dựng hiện tại](#bản-dựng-hiện-tại--v01-đảo-khởi-đầu).

---

## Ngôn ngữ — yêu cầu toàn sản phẩm

Mặc định **theo hệ thống**, đổi và lưu trong **Cài đặt → Ngôn ngữ**. UI, Tutor và
bảng giảng dùng cùng lựa chọn; không dịch code/output hoặc xóa bài đang làm.
Mẫu làng/bảng đã thử được VI/EN, **chưa phải Flutter đã đa ngôn ngữ toàn app**.
Xem [contract và bàn giao](docs/design/LANGUAGE_AND_LOCALIZATION.md) và
[mẫu tương tác + checks](docs/design/shared-l10n/README.md).

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
   mở khóa gắn trực tiếp với hoạt động hoặc kiến thức thực sự cần.

> **Thuật ngữ quan trọng:** *Main Map* là **bản đồ trung tâm (hub điều hướng)
> miễn phí**; *Main Quest* là **tuyến học Python nằm trong đó**. Main Map không
> phải một game lớn — thế giới và gameplay nằm trong các hoạt động. Hai khái niệm
> khác nhau, không dùng thay thế.
> Định nghĩa đầy đủ ở [`docs/PRODUCT_VISION.md`](docs/PRODUCT_VISION.md).

---

## Bản dựng hiện tại — v0.1 "Đảo Khởi Đầu"

Một hòn đảo vẽ tay là **Main Map (hub)**: chạm vào từng địa điểm để mở hoạt động
riêng. Không có XP hay cấp độ toàn cục — mỗi hoạt động có luật chơi, điểm,
tài nguyên và tiến trình của riêng nó.

| Địa điểm | Hoạt động | Cần Python? | Có gì |
|---|---|---|---|
| **Tháp Python** | Main Quest | Có | Chặng 1 *Code Apprentice*: 12 bài, 64 bước (truyện, ví dụ chạy được, trắc nghiệm, ghép mảnh, xếp dòng, tự viết code, điều khiển Robo bằng code). Màn tổng kết bài, Adventure Recap, Sân tập code miễn phí. |
| **Mê Cung Robo** | Mini-game xếp lệnh | Không | 10 màn, 3 sao (tới rương · nhặt đủ đá quý · ít lệnh), khối Lặp lại, gợi ý theo số lần sai, xem code Python sinh ra. **Xưởng Mê Cung (Creator Mode):** tự vẽ mê cung, đặt luật, chứng minh giải được bằng khối lệnh hoặc code Python. |
| **Núi Lửa Pip** | Rồng Nhảy (arcade) | Không | Game loop riêng, vật lý nhảy 2 lần, chướng ngại, xu. Xu chỉ dùng trong **Tổ Rồng** (nâng cấp + mũ cho Pip). |
| **Đài Thiên Văn** | Hái Sao (arcade) | Không | Kéo bình hứng sao, combo, sao cầu vồng, né thiên thạch. Sao hái được thắp sáng **Bản đồ chòm sao** (sưu tầm). |
| **Xưởng Bitsy** | Săn Bọ Lỗi (debug) | Có | 12 câu đố, 20 con bọ; mở khi học xong Bài 3 (nút "Đi tới bài học"). |
| **Nhà Thành Tích** | Thành tích | — | 15 huy hiệu (3 bí mật), Tường chiến tích, Bộ sưu tập, Góc sáng tạo — mở dần theo hành trình. |

Hệ thống chung: năng lượng hồi theo thời gian (kể cả khi tắt app; không quảng cáo,
không mua bán), nhiệm vụ hằng ngày, nhắc nghỉ 30/45/60 phút và bài nghỉ mắt 20
giây, âm thanh/nhạc tự tạo, chế độ êm dịu, lưu toàn bộ tiến trình bằng SQLite.

**PyQuest Python (mô phỏng)** là một tập con Python viết bằng Dart, chạy ngay trên
máy: biến, số, chuỗi, f-string, list, if/elif/else, for/while, def/return.
Có giới hạn rõ ràng (100.000 bước, 50 tầng gọi hàm, 10.000 ký tự output; không
`import`, class, dict, tuple, `input()`...). Lỗi được giải thích bằng tiếng Việt
kèm thông báo mà Python thật sẽ in. Danh sách đầy đủ hiển thị trong app
(Cài đặt → *Về PyQuest Python*).

---

## Trợ giảng AI (AI Tutor)

Ba tầng, và app luôn nói rõ câu trả lời đến từ tầng nào:

1. **Trợ giảng ngoại tuyến** — luôn có, miễn phí, soạn từ chính nội dung bài học
   trên máy (`lib/modules/tutor/offline_tutor.dart`), gồm thang gợi ý 5 nấc.
2. **Trợ giảng AI qua relay** — `TutorSession` gọi endpoint OpenAI-compatible
   `/v1/chat/completions` (`lib/modules/tutor/tutor_provider.dart`), có hạn mức
   câu hỏi/ngày, lịch sử trong bài, và **tự động rơi về trợ giảng ngoại tuyến**
   khi mạng lỗi. Cấu hình qua `app/assets/config/ai_tutor_config.json` hoặc
   `--dart-define=AI_TUTOR_ENDPOINT=...`.
   **Luồng Tutor văn bản qua relay không nhúng provider key vào app.** Relay mẫu nằm ở
   [`tools/ai_relay/`](tools/ai_relay/) — chạy được bằng Python thuần, có test
   riêng (`python3 tools/ai_relay/test_relay.py`), chỉ giữ key ở phía server.
3. **Giọng nói Gemini Live (thử nghiệm)** — `lib/modules/tutor/gemini_live_*.dart`
   và `live_audio_output.dart`: trò chuyện rảnh tay trong màn học, 16 kHz PCM lên /
   24 kHz PCM xuống, half-duplex (micro chỉ mở khi trợ giảng im lặng), bắt
   chống vọng âm từ loa, và một transcript chung cho cả hai vai
   (`tutor_transcript.dart`) để câu nào cũng mang đúng tên người nói.
   Source còn đường thử nghiệm cục bộ qua `--dart-define=GEMINI_API_KEY=...`;
   giá trị này nằm trong APK, không phải bí mật được bảo vệ trên client.
   **Từ r47, hai workflow CI build APK với define rỗng, không đọc Gemini secret;
   direct Gemini Live không xác thực được trên các APK đó.** Phải có token ngắn hạn/
   server mediation trước khi cho phép phân phối voice. Bảng kiểm tra trên thiết bị:
   [`docs/experimental/GEMINI_LIVE_VOICE_TEST.md`](docs/experimental/GEMINI_LIVE_VOICE_TEST.md).

---

## Thiết kế & hình ảnh gốc

**Thế giới sống:** [P04 — làng, cư dân và hải đồ quần đảo](docs/design/living-world-prototype/README.md)
— đi thuyền mô phỏng và quay lại bảng Tutor, chưa phải vùng game Flutter mới.

**Mẫu Tutor + bảng giảng:** [P03 — viết, vẽ, chỉ từng bước và cho người chơi thử](docs/design/tutor-board-prototype/README.md)
— prototype có tương tác, chưa kết nối AI/voice hoặc tích hợp Flutter.

**Mẫu first-play mới:** [Robo → làng → thử thách → chơi/sửa lỗi → kết quả](docs/design/first-play-prototype/README.md)
— prototype HTML có tương tác, **chưa tích hợp Flutter**.

**Bộ thiết kế mới:** [Village Kit 01 — 6 landmark 2.5D](docs/design/village-kit/README.md)
(PNG gốc, WebP tối ưu, gallery so sánh và manifest; **chưa tích hợp runtime**).
[Báo cáo so sánh/nhập nhánh và kiểm tra](docs/design/BRANCH_IMPORT_AND_ASSET_AUDIT.md).
[Mục tiêu redesign toàn app & tiêu chí người dùng thật](docs/design/FULL_APP_REDESIGN_CHARTER.md).
[Bàn giao cho AI triển khai & các bộ asset cần làm tiếp](docs/design/AI_IMPLEMENTATION_HANDOFF.md).
[Prompt cho agent code](docs/design/coordination/CODE_AGENT_PROMPT.md) ·
[Task đầu PQD-001](docs/design/coordination/tasks/PQD-001.md) ·
[Quy ước phối hợp hai nhánh](docs/design/CROSS_BRANCH_COLLABORATION.md).

| Tài liệu | Vai trò |
|---|---|
| [`docs/PyQuest_Reffrence_Images/`](docs/PyQuest_Reffrence_Images/) | 21 ảnh tham khảo **gốc** của thế giới PyQuest — bằng chứng thiết kế, không phải asset runtime |
| [`docs/PyQuest_Reffrence_Images/PYQUEST_UI_DIRECTION_V2.svg`](docs/PyQuest_Reffrence_Images/PYQUEST_UI_DIRECTION_V2.svg) | Định hướng UI V2 (chưa triển khai vào source) |
| [`docs/PyQuest_Reffrence_Images/PYQUEST_VILLAGE_2_5D_CONCEPT.svg`](docs/PyQuest_Reffrence_Images/PYQUEST_VILLAGE_2_5D_CONCEPT.svg) | Bản concept ngôi làng 2.5D (ý tưởng, kèm brief) |
| [`docs/design/kai-lumi-character-reference.svg`](docs/design/kai-lumi-character-reference.svg) | Chuẩn tạo hình Kai & Lumi |

Giao diện hiện tại **đang chờ** được tinh chỉnh theo hướng V2: giữ chất thân thiện
với trẻ em nhưng chín hơn về phân cấp, khoảng cách, chữ và khả năng dùng.
Mockup **không** phải bằng chứng đã làm xong — xem quy trình ở
[`docs/ROADMAP.md`](docs/ROADMAP.md).

---

## Cấu trúc repository

```text
PyQuest/
├── README.md
├── docs/                      # 4 tài liệu gốc + ảnh tham khảo + design/experimental
├── .github/workflows/ci.yml   # analyze, test, render preview, build APK, emulator
├── ci/                        # Script CI (báo cáo, hành trình trên emulator)
├── tools/ai_relay/            # Relay AI mẫu (giữ key ngoài thiết bị) + test Python
└── app/                       # Ứng dụng Flutter
    ├── lib/
    │   ├── app/               # Khởi động, AppServices, registry các địa điểm
    │   ├── core/              # Sự kiện, cấu hình, âm thanh, cài đặt, phiên chơi
    │   ├── data/              # SQLite (migration) + repository
    │   ├── modules/           # Mỗi hoạt động một module độc lập
    │   ├── python_runtime/    # PyQuest Python (lexer, parser, interpreter)
    │   └── shared/            # Theme, nhân vật vẽ bằng code, widget dùng chung
    ├── assets/                # Font, âm thanh, cấu hình, nội dung (JSON)
    ├── test/                  # Unit, widget, render preview
    └── integration_test/      # Hành trình trên thiết bị thật/emulator
```

Thêm một trò chơi mới = tạo module trong `app/lib/modules/` + thêm một dòng vào
`lib/app/activity_registry.dart`; bản đồ, năng lượng, sự kiện, huy hiệu và lưu
trữ không cần sửa.

| Tài liệu | Vai trò |
|---|---|
| [`docs/PRODUCT_VISION.md`](docs/PRODUCT_VISION.md) | Ý tưởng sản phẩm, thế giới, nhân vật, mô hình kinh doanh, triết lý giáo dục |
| [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md) | Luật chơi, năng lượng, mở khóa hoạt động, huy hiệu, thành tích, cân bằng độ khó |
| [`docs/TECHNICAL_ARCHITECTURE.md`](docs/TECHNICAL_ARCHITECTURE.md) | Interpreter, module, AI Tutor, lưu dữ liệu, quảng cáo, thanh toán |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Giai đoạn triển khai, tiêu chí nghiệm thu và kiểm thử |

**Nguyên tắc tài liệu:** tài liệu sản phẩm xác định *xây trò chơi gì*;
tài liệu kỹ thuật xác định *xây bằng cách nào*; roadmap xác định
*làm gì trước và kiểm tra bằng gì*. Bốn tài liệu là nguồn định hướng sản phẩm;
mọi nhánh chuẩn hoá theo chúng, không tự sinh hướng thiết kế riêng. Trạng thái
source/kiểm chứng đọc tại [PROJECT_STATUS](docs/PROJECT_STATUS.md) và review/task
đã pin, không suy tiến độ triển khai từ yêu cầu trong tài liệu tầm nhìn.

---

## Roadmap tóm tắt — trạng thái source, không phải chứng nhận hoàn tất

| Phần | Trạng thái |
|---|---|
| Foundation / Home Map | Có source; không khởi tạo lại. UI thế giới mới chưa được port toàn bộ |
| Các hoạt động chơi / Creator Maze | Có source cho Robot Maze, Dragon Jump, Catch the Stars, Bug Hunter và Creator Maze |
| Energy & Rewarded Ads | Energy có; **rewarded ads chưa triển khai** |
| Interpreter mô phỏng | Có tập con Python và giới hạn; **không phải sandbox đã được chứng nhận** |
| Main Quest | Chặng1 có12 bài/64 bước; không có nghĩa mọi chặng/tiêu chí đã hoàn tất |
| Side Maps & Pro / cộng đồng đầy đủ | Kế hoạch sản phẩm, chưa có implementation đầy đủ |
| UI / localization / accessibility / voice / phát hành | Từng phần có evidence riêng; không có whole-app acceptance |

[Ma trận source/evidence và disposition task](docs/PROJECT_STATUS.md) là điểm đọc
trạng thái. [Roadmap](docs/ROADMAP.md) giữ thứ tự và tiêu chí kế hoạch; không dùng
số checklist hoặc biểu tượng hoàn thành thay SHA/test/device evidence.

**Nguyên tắc chốt từ đầu:** đừng xây cả thế giới PyQuest ngay lập tức. Làm một
**lát cắt dọc hoàn chỉnh**: mở app → vào một trò chơi → chơi được → lưu kết quả →
thoát ra mở lại vẫn còn kết quả. Lát cắt này **không** cần interpreter Python.

**Về runtime:** giai đoạn đầu dùng **interpreter mô phỏng một tập con giới hạn**
(Flutter/Dart), **không** chạy Python thật. Việc nhúng Python thật chỉ được đánh
giá sau, khi mô phỏng đã chứng minh giá trị sư phạm. Chi tiết ở
[`docs/TECHNICAL_ARCHITECTURE.md`](docs/TECHNICAL_ARCHITECTURE.md).

---

## Cách chạy

Yêu cầu: Flutter SDK stable (đã kiểm tra với 3.47.7), Android SDK hoặc thiết bị Android.

```bash
cd app
flutter pub get
flutter run                     # chạy trên thiết bị/emulator Android

flutter analyze                 # kiểm tra tĩnh
flutter test --exclude-tags render           # unit + widget test
flutter test --tags render test/render       # xuất ảnh preview vào app/build/previews/
# hành trình trên thiết bị (đúng lệnh CI dùng, xem ci/emulator_journey.sh)
flutter drive --no-pub --keep-app-running \
  --driver=test_driver/integration_test.dart --target=integration_test/journey_test.dart -d <device-id>
```

APK preview keyless (CI thông thường; owner-test có ngoại lệ r49 bên dưới):

```bash
cd app
flutter build apk --release --dart-define=GEMINI_API_KEY=
```

`--release` là build mode, **không phải quyền phát hành công khai**. Direct Gemini
Live sẽ không xác thực được khi define rỗng. **Theo quyết định người dùng r49,
workflow owner-test được nhúng key từ repository secret để chính họ thử voice**,
sau pinned-SDK checks; không public/store release. Xem [request và giới hạn](docs/OWNER_TEST_BUILDS.md)
và [voice checklist](docs/experimental/GEMINI_LIVE_VOICE_TEST.md). Token/backend/quota
hoãn cho lần thử nội bộ, không sửa Tutor ngoại tuyến/relay văn bản.

CI (GitHub Actions) chạy `analyze` + `test` + render preview cho mỗi lần push vào
`arena/**`; commit có `[apk]` build thêm Release APK (tải ở *Artifacts* của lần
chạy), commit có `[emulator]` chạy hành trình trên Android emulator. Kết quả mỗi
job được publish thành check run (*PyQuest check*, *PyQuest emulator*) qua
`ci/report.py` + `ci/step_outcomes.py`, nên đọc được ngay trên trang checks mà
không cần tải log.

Bảo mật: CI thông thường vẫn define key rỗng; owner-test là ngoại lệ được người
dùng cho phép. Key chỉ lấy từ repository secret trong step build, không commit
hoặc đưa vào log/chat. APK owner-test vẫn trích xuất được key, không chia sẻ
công khai. Key relay văn bản nằm phía server ở `RELAY_API_KEY`. Thay đổi workflow
không thu hồi APK hoặc xoay key cũ; build success không phải device/voice PASS.

---

## Đóng góp & giấy phép

Dự án đang ở giai đoạn phát triển nội bộ, chưa mở đóng góp công khai.
Giấy phép sẽ được công bố trước khi phát hành.

---

**PyQuest** — *Build Your Game. Rule Your World.*
