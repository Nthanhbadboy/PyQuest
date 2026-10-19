# PQC-022 — bề mặt 2,5D r56 (Welcome + ActivitySheet) và r43 (Main Quest journey)

**2026-10-19 · CODE (`arena/4253d4f1-pyquest`) · chiến thuật Fast-Track Co-Dev
(`docs/design/coordination/specs/FAST_TRACK_CO_DEV.md`, bản nhập từ `8d79a59`).**

## 0. Nền đã nhập và bằng chứng đã TỰ kiểm (không copy từ tin nhắn)

Commit `0a44ba4` trên nhánh CODE nhập nội dung từ
`origin/arena/84456d39-pyquest` @ `8d79a59e7da91634ecdc111c6b2db663c7e86b46`
(`git checkout <ref> -- app .github/workflows docs/design/coordination/specs/FAST_TRACK_CO_DEV.md`,
không merge history). Trạng thái xanh của SHA đó do CODE đọc trực tiếp từ check-run:

| Receipt | Nguồn |
|---|---|
| `maintenance` → `00:50 +443: All tests passed!` (ordinary suite) | `.output.text` của check-run trên `8d79a59` |
| Settings `+12`, isolated `+1`, sequence `+2`, integration `+7` | cùng check-run (`### …log tail`) |
| `PQC-011 r49 exact gate counts \| success`, `PQC-020 focused gate evidence \| success`, `focused \| success`, `maintenance \| success`, `PyQuest check \| success`, `android \| skipped`, `apk \| skipped` | `commits/8d79a59/check-runs` |
| SDK `Flutter 3.47.7 • Dart 3.13.5 • framework abaf9c5237` | `flutter_version.txt` trong evidence |
| `Ordinary suite … required at least 422` ⇒ thêm test mới KHÔNG vỡ gate | `.github/workflows/pqc011-maintenance.yml:735-737` (`minimum=True`) |
| `Render suite` vẫn đúng 10 ⇒ không thêm case render | `test_count('pqc011-render.log', 10)` |

Kiểm "không mất đồ của R3": `git diff 561d0f6 8d79a59 -- app` chỉ 12 file; trong đó
`main_map_scene.dart` đổi 4 dòng (import `show listEquals` + bỏ một comment),
`main_map_scene_geometry.dart` / `main_map_scene_test.dart` (R3-GEOM) /
`render_screens_test.dart` **không đổi byte nào**; `lesson_route_regression_test.dart`
chỉ 4 lời gọi `hasFlag`→`flagsCollection` (+`dart:ui show Tristate`) nên oracle
semantics còn nguyên. `village_r53.webp` có `git diff --summary` = "mode change
100755 => 100644" và sha256 hai bên đều `d3130b407e08f146…8804c0e` ⇒ nội dung ảnh
pin không đổi.

Hai hệ quả đã ghi vào hồ sơ R3 (§9 của
`../PQC-020-r1/evidence/r3-village-geometry-root-scale.md`):
1. Overflow 2× mà R3 "khoan dung" KHÔNG đến từ `_IslandTitle`; nó đến từ
   `SplashScreen` và đã được sửa thật bằng `FittedBox`/`SingleChildScrollView`,
   nên root test bây giờ assert `takeException() == isNull` cho cả 12 config.
2. Đỏ `smoke 2×` cuối cùng của `561d0f6` là do pending-exception làm tap warning
   leo thành lỗi, không phải do rect; edit `ensureVisible`+`pumpFor` đang dở của
   CODE được **bỏ có chủ đích** vì bản `8d79a59` đã phủ hành vi đó.

## 1. Sửa gì (đúng allowlist file của FAST_TRACK_CO_DEV §3)

| File | Thay đổi |
|---|---|
| `app/lib/modules/main_map/activity_sheet.dart` | Panel r56: bar trên (tên địa điểm + `sheet_close`), dải scene 2,5D 180px (`Image.asset`, fade về parchment, seal tên canonical + trạng thái bằng chữ, portrait host 115×140 đè mép dưới), `.status-box`/`.metric` thay cho khối tiến trình cũ, `.footer` nằm NGOÀI vùng cuộn. Slot thumbnail 104×104 `DecorationImage(AssetImage(def.thumbnail))` giữ nguyên, CTA vẫn pop `open` / `lesson:<id>` / null. |
| `app/lib/modules/main_map/main_map_screen.dart` | `_WelcomeDialog` dựng lại theo `.panel.welcome`: bar + scene 300px (250px khi chữ ≥1.5×) + `.steps` 3 segment 5px + copy + footer `Lùi`/`Tiếp tục`; key mới `welcome_scene`, `welcome_guide`, `welcome_close`, `welcome_previous`; `welcome_next` giữ nguyên tên và vẫn pop ở trang cuối. Scene per-step: `arrival` (Robo/Pip, focus 53%/70%), `main_quest` (Py, 60%). |
| `app/lib/modules/main_quest/main_quest_module.dart` | `_TowerSceneHeader` (scene vườn tháp 180px + seal "Chặng n · x/12 bài" + `quest_quick_continue` góc trên phải + guide Py 115×140) và `_PedestalBand` ×3 ("Bệ 1–4 · n/4 bài", en dash, vàng = nhóm chứa bài kế, xanh + check = đủ 4, trung tính còn lại). Chạm bệ CHỈ đổi highlight dẫn bài (`_pedestalLead`), không mở lesson, không trừ phí. |
| `app/test/r1b_and_chapter_25d_test.dart` (mới) | 12 case: decode + ngân sách asset; sáu sheet (scene 180px, guide, slot 104×104 đúng một, thumbnail đã pin); sáu sheet ở 2× không layout exception + CTA ≥44px; oracle reorder đo `getTopLeft` tại 1×/1.3×/2×; portrait token cho main_quest/bug_hunter và painter cho host khác; CTA qua `showPQSheet` thật pop `open`/`lesson:mq1_03`; `sheet_close` pop null; welcome ở root thật (barrier không đóng, next/previous, token Py, scene 300px); welcome 2× (scene 250px, chữ trước scene, CTA trong khung nhìn); Main Quest 1×/2×; chạm bệ không trừ năng lượng; `openLessonId` highlight + `lesson_card_*`/`open_playground` còn nguyên. |
| `app/test/render/render_screens_test.dart` | `precacheMap` thêm 4 asset r56 để capture thấy artwork thật. **Không** đổi số case render (gate = đúng 10). |

Không chạm: `dragon_jump`, `catch_stars` (PQC-021 của Lead), `robot_maze`,
`achievements`, `bug_hunter` (PQC-023 của Lead), `.github/**` ngoài 2 file đã nhập,
`app/pubspec.yaml` (assets đã là glob `assets/images/`), `CharacterId`, thumbnails
đã pin, cap text-scale (vẫn đã bỏ), dependency.

## 2. Asset: số đo thật, provenance, byte

Bản copy vào app là **byte-identical** với ảnh study (sha256 khớp
`docs/design/arrival-entrance-r56/assets/provenance.json`, không re-encode,
không resize, không upscale):

| Asset app | Nguồn study | Kích thước | Bytes | sha256 (đầu/cuối) |
|---|---|---|---|---|
| `assets/images/arrival_r56.webp` | `arrival.webp` (r40 A03) | 720×894 | 108 042 | `0cd45386…d9f0a4ce` |
| `assets/images/main_quest_r56.webp` | `main_quest.webp` (r43 tower-garden) | 671×1000 | 112 096 | `ccb17b9a…8eb6b98c` |
| `assets/images/py_token_r56.png` | `py-token.png` | 438×512 | 174 312 | `f219bb09…c1e1f9b6` |
| `assets/images/bitsy_token_r56.png` | `bitsy-token.png` | 465×512 | 264 896 | `78aad5e5…3f5d9448` |

* CODE **không** chọn `tower-garden.png` (2 444 406 B) cho màn Main Quest mà dùng
  bản WebP 112 KB mà chính FAST_TRACK §3 cho phép ("hoặc … `main_quest.webp`").
* Tổng asset mới của PQC-022: **659 346 B** (4 file). `app/assets` hiện tại:
  53 file, 3 548 867 B; `app/assets/images` 16 file, 2 189 735 B
  (gồm 635 234 B của PQC-021 do import, không phải của gói này).
* RGBA giải mã lý thuyết nếu draw đủ: arrival 720·894·4 = 2 574 720 B,
  main_quest 671·1000·4 = 2 684 000 B, py 438·512·4 = 897 024 B,
  bitsy 465·512·4 = 952 320 B — **chỉ là con số lý thuyết, không phải RAM/GPU
  thiết bị**; không có `cacheWidth` cho bốn asset này; `FilterQuality.medium`
  như quy ước của hub; `gaplessPlayback: true` vì ảnh nằm trong panel có animation
  mặc định của sheet/dialog.
* Không có animation lặp/auto-advance/pulse cho phần mới (`animate: false` cho
  portrait painter trong scene), theo SPEC r56 §4 "Không có animation lặp".

## 3. Ánh xạ hợp đồng thiết kế → code (số đo kiểm được)

| Rule trong design | Code | Test đo |
|---|---|---|
| r56: header scene 180px, portrait 115×140 | `kSheetSceneHeight`, `kSheetGuideSize` | `getSize('sheet_scene').height == 180`, `getSize('sheet_guide') == Size(115,140)` |
| r56: welcome scene 300px → 250px khi ≥1.5×, portrait 152×175 không thu | `kWelcomeSceneHeight`/`kWelcomeSceneLargeHeight`, `kWelcomeGuideSize` | `getSize('welcome_scene').height` tại 1× và 2×, `welcome_guide` height ≥ 175 |
| r56: "font ≥1.5× đưa nội dung lên trước artwork" | `MediaQuery.textScalerOf(context).scale(16)/16 >= kR56LargeTextScale` (ngưỡng 1.5 của production, không phải số mới) | so `getTopLeft(scene).dy` với `getTopLeft(body).dy` ở 1.0/1.3/2.0 |
| r56: một scroll owner cho body, footer ngoài scroll | `Expanded(SingleChildScrollView)` + `_SheetActions` ngoài | `nextRect.bottom <= 640` ở 2× (CTA không cần cuộn vẫn thấy) |
| r56: tên dài wrap, không ellipsis/FittedBox | mọi Text mới không đặt `overflow`; không `FittedBox` trong ba file | — (chụp ảnh qua render job) |
| r56: không đưa chữ vào artwork | 4 asset là scene/portrait thuần; nhãn = widget | test đếm `find.text(module.def.name)`, không OCR |
| r43 §1: ba bệ là visual grouping, không khoá mới; "số + completed count" trên marker | `_PedestalBand` với `'Bệ ${lo+1}–${hi+1} · n/4 bài'` | `find.textContaining('Bệ 1–4')`, `quest_pedestal_0..2` |
| r43 §1: Quick continue ở góc trên cảnh, CTA cuối lặp cùng hành động, không thêm phí | `quest_quick_continue` gọi đúng `_open(quickTarget)`; `_open` vẫn tính review cost 0 | `energy.current` không đổi khi chạm bệ |
| r43 §1: `openLessonId` chỉ highlight, không tự `_open` | không đổi luồng đó; thêm highlight của bệ bằng OR | `find.byType(LessonScreen), findsNothing` |
| PQD-002 §B: đúng một slot `DecorationImage(AssetImage)` 104×104 | scene dùng `Image.asset` | `expect(thumbSlot, findsOneWidget)` (cả trong test cũ) |

## 4. Những gì bằng chứng NÀY không nói

* Không có Android device/emulator, không TalkBack, không APK, không fps/RAM đo
  thật; "không layout exception" chỉ đúng trong `WidgetTester` với linear scaler.
* Capture render cho 4 asset mới sẽ đổi ảnh ở các config sheet/welcome/MainQuest —
  đó là kênh bằng chứng, ảnh do Lead mở trên finalSHA; CODE không tự nghiệm thu.
* Không đổi: semantics của modal (dialog/barrier vẫn `showDialog` +
  `barrierDismissible: false` như hiện hữu), `setIntroSeen()` (vẫn đặt sau khi
  dialog đóng bất kể cách đóng — sửa write-semantics là đơn riêng theo D56-P2),
  copy tiếng Việt của Welcome/sheet (D56-P1 cần localization contract trước).
* Bitsy/Py dùng token study dạng PNG có nền đã cutout theo ASSET_PLAN
  ("study matte, không phải native alpha thật"); nếu DESIGN yêu cầu alpha/atlas
  production thì asset phải thay, không phải code.

## 5. Gate

Đọc từ check-run của **chính SHA bàn giao** (không suy từ SHA trước):

| Workflow | Trên `863d20a` (run đang có bằng chứng) | Ghi chú |
|---|---|---|
| `PQC-020 R1-A focused verification` | **success** (run `39266717225`) | formatter `Formatted 13 files (0 changed)` + 6 file focused xanh |
| `PQC-011 r49 maintenance verification` | failure (run `39266717154`) | ordinary `+457 -3` (460, cần ≥422 **và zero fail**), render `9/10` (cần đúng 10), Settings `12` ✓, isolated `1` ✓, sequence `2` ✓, integration `7` ✓ — 3 đỏ đều ở `r1b_and_chapter_25d_test.dart`, đã phân tích ở §6 |
| `PyQuest check` (CI) | failure (`39266717140`) | `PyQuest localization generation evidence` = success, `flutter analyze` còn warning `_ChapterHeader` (đã sửa ở mục 6), `android` = skipped |

Bảng này **cố ý** ghi theo SHA đã chạy. SHA bàn giao cuối sẽ được điền vào dòng
dưới sau chu kỳ CI của commit này — không copy kết quả của SHA khác làm bằng chứng
cho SHA bàn giao:

| SHA bàn giao | Kết quả |
|---|---|
| `354a33837539c24136d831ec0a16cdde14b95311` | focused **success** (`39268386183`); maintenance failure (`39268386125`): ordinary `443/1` (file test của tôi không compile), render `9/10`, Settings/isolated/sequence/integration xanh; CI failure (`39268386136`) vì `flutter analyze` 1 error. Đã sửa ở commit kế. |
| `238bebb…` / `014c078…` | focused **success** (`39269333289` / `39270079751`); ordinary `459/2` rồi `460/1`; render `9/10`; `014c078` còn lại 1 đỏ `openLessonId vẫn highlight + các key cũ còn nguyên` + CI 13 issues (toàn bộ là `info` `curly_braces` có sẵn của repo, không phải file của tôi). |
| `9940e6bbc367e875903600cc1e4f75ffc23a999b` | focused **success** (`39271407446`); maintenance failure (`39271407419`) = `analyze, ordinary suite, render suite`; ordinary `443/1 (444)` với `Failing tests:` là `loading r1b_and_chapter_25d_test.dart` — `return_of_invalid_type_from_closure` ở `tester.runAsync(() async {…})` (suy ra `T = Object` từ nhánh `catch`, đóng băng cả file). Đã sửa ở commit kế. |
| `aec4a2f1878600e316f62c6065ff856f3ecd62c6` | focused **success** (`39271913533`); maintenance + CI failure; `Failing gate outcomes` = `ordinary suite, render suite` (analyze rớt khỏi danh sách ⇒ file của tôi sạch, `14 issues found` đều là `info` của repo); ordinary `462/1 (463)`, đỏ duy nhất `các key hợp đồng cũ còn trên màn Main Quest (lesson_card_*, open_playground)`; render vẫn `9/10`. Hai ca bản sao harness (`capture()` với `toImage(pixelRatio: 1.5)`, và cả nhóm `Render A replica`) **xanh** ⇒ giả thuyết CTA thô của case A bị bác. |
| `f647db7f1ee4da5322c26e577589073a56b252e6` | focused **success** (`39272542843`); maintenance failure (`39272542888`) + CI failure (`39272542978`); ordinary `464/1 (465)` với ĐÚNG MỘT đỏ `key hợp đồng cũ lesson_card_mq1_01 còn trên Main Quest 2.0x` — hai ca em song sinh (cuộn tới `open_playground`, đi qua `mq1_01/04/08/12`) xanh ⇒ key tồn tại, cuộn được, không exception. In `PQC022-*` không bao giờ tới được log đã publish ⇒ phải tách ca, không đoạp đặt. |
| `ddf53be31e5d433df057901e4b25b4ccdafcb639` | focused **success** (`39273391579`); maintenance + CI failure; ordinary `465` với 2 đỏ: `cảnh vườn tháp + ba bệ + quick continue ở 1× và 2×` và `key hợp đồng cũ lesson_card_mq1_01 … 2.0x` ⇒ chỉ đảo thứ tự là **chưa đủ**; xem mục 6 dưới. |
| `498ecf802d466d76662170984fb8434b45917fd5` | focused **skipped**, maintenance **skipped**, CI failure — KHÔNG phải đỏ thật: `PQC-020 focused` và `PQC-011 maintenance` có `if:` bắt buộc commit có marker `[pqc020-check]` / `[pqc011-verify]`, và message của commit này thiếu nên hai workflow bỏ chạy. Đây cũng là lý do chu kỳ "bỏ artwork" không có số ordinary. |
| `56ace8145c07aea36323b96ded849c37060cb0f7` (sync) | **XANH cả ba cổng trên nhánh CODE**: `PQC-020 focused gate evidence` success, `PQC-011 r49 exact gate counts` success với `### Failing gate outcomes / None`, ordinary `00:56 +470: All tests passed!`, `PyQuest check` success. Cây khớp `029f801` trên `arena/84456d39-pyquest` (nhánh hợp nhất của Lead) + 18 file docs/tools mà chỉ nhánh này giữ. |

## 6. Hồ sơ đỏ-xanh theo từng chu kỳ CI (không nới ngưỡng)

Mọi con số dưới đây lấy từ `check-run` của chính SHA được nêu, đọc bằng
`gh api repos/Nthanhbadboy/PyQuest/commits/<sha>/check-runs?page=1..4` và
`.output.text`; không có suy luận từ source.

### `6b74744` — ba đỏ, ba nguyên nhân khác nhau

| Gate | Kết quả | Nguyên nhân thật | Cách sửa (ở `f97c8df`) |
|---|---|---|---|
| `pqc020` formatter | FAIL — `Formatted 13 files (1 changed)`, `Changed lib/modules/main_map/main_map_screen.dart` | Tôi viết tay một `Align(...)` khác output `dart format` | Giải nhất: lấy đúng snapshot `PQC-020 formatted source snapshot` (check-run `118103352926` + `118103359203`, giải mã base64 → tar) và copy **byte-for-byte**; 15/16 file còn lại đã khớp sẵn |
| ordinary / focused / Settings / Render | FAIL — ordinary `+354 -10`, focused `+8 -6`, Settings 0 passed, Render 0 passed | `activity_sheet.dart:234:13: Error: The argument type 'String?' can't be assigned to the parameter type 'String'` (CFE). Field **public của class private không được flow-promote**, nên `token == null ? … Image.asset(token …)` chỉ hỏng ở CFE chứ analyzer không báo — vì vậy `flutter analyze` vẫn xanh mà 7 file test không compile | Đọc field ra local `final String? asset = token;` rồi rẻ nhánh trên local. Không dùng `!`, không `// ignore`, không cast |
| `flutter analyze` | FAIL — 19 issues, 4 thuộc file tôi | `unnecessary_non_null_assertion` ×2 (`w.image!`, `decoration.image!.image!` — hai chỗ đó **non-nullable**), `unused_element_parameter` (`super.key` cho widget private không ai truyền key), `unnecessary_brace_in_string_interps` (`'${constVar} B'`) | Xoá noise thật, không thêm `// ignore` |

### `f97c8df` — còn hai đỏ, đều là hợp đồng thật của repo

| Gate | Kết quả | Nguyên nhân thật | Cách sửa (ở `863d20a`) |
|---|---|---|---|
| formatter | **PASS** — `Formatted 13 files (0 changed)` | (đã hội tụ theo snapshot) | giữ nguyên |
| `flutter analyze` | FAIL — `warning • The declaration '_ChapterHeader' isn't referenced • lib/modules/main_quest/main_quest_module.dart:427:7 • unused_element` (warning duy nhất; 13 dòng còn lại là info `curly_braces` có trước) | Tôi thay panel chặng bằng dải cảnh 2,5D và bỏ luôn widget cũ | Dựng **cả hai**: scene band rồi tới `_ChapterHeader(content:, done:)` (đúng ý r43 §1 "không nhét 12 bài + mọi thông báo lên 640px", nhưng không xoá nội dung chữ) |
| ordinary + focused | FAIL — `Found 3 widgets with text "Núi Lửa Pip" / "Mê Cung Robo" descending from widgets with type "ActivitySheet" … Which: is too many` (2 file: `main_map_scene_route_test.dart`, oracle semantics R3 trong `lesson_route_regression_test.dart`) | Hợp đồng repo: **đúng một** `Text(def.name)` bên trong `ActivitySheet`. Bản 2,5D của tôi lặp tên ở `_SheetBar` (14.5) và `_SceneSeal` (15.5) ngoài `PQText.h2` ở body | Đọc study trước khi sửa: `docs/design/arrival-entrance-r56/app.mjs` dựng `.scene-seal = t('host') + ' · ' + hosts[lang][a.host]` (caption **nhân vật**, 11px), tên địa điểm nằm ở `panel-copy h2`, còn tên nhân vật đã do `SpeechBubble` render (`common.dart:116`, ngoài nhánh `showPortrait`) → seal thành chip trạng thái `Đang khóa`/`Đã mở`, bar thành nhãn tĩnh `Giới thiệu địa điểm`. Test mới của tôi chốt hợp đồng bằng `findsOneWidget` (trước: `findsWidgets`) |

### `863d20a` — focused **XANH**, ordinary còn 3 đỏ ở đúng màn tôi mới sửa

| Gate | Kết quả | Nguyên nhân thật | Cách sửa (commit này) |
|---|---|---|---|
| `PQC-020 R1-A focused verification` | **success** (formatter `0 changed` + focused tests xanh) | 6 file map/sheet/route đã chấp nhận 2,5D: sheet Welcome mới, `_SheetSceneHeader`, seal đổi nội dung | giữ |
| `pqc011` ordinary | `+457 -3` (460) — 3 ca trong `r1b_and_chapter_25d_test.dart`, nhóm `Main Quest journey r43` | Cả ba là **lỗi test của tôi**, không phải lỗi màn chơi: (1) `ListView` main quest là lazy + `findsOneWidget` mặc định bỏ offstage → `'Bệ 9–12'`, `open_playground`, `lesson_card_mq1_03` bị báo thiếu dù widget có thật; (2) `getSize` trên widget offstage → `RenderBox was not laid out`; (3) `tapAndSettle` = `ensureVisible` + **một** `pump()` → tap đo rect lúc cuộn còn animation (đúng cái bẫy đã làm đỏ smoke 2× ở PQC-020 R3) → `warnIfMissed` dựng thành failure; (4) tôi so viền deep-link với `0xFFFF2E63` trong khi `_LessonCard:502` vẽ `PQColors.berry = 0xFFEC5C93` (`0xFFFF2E63` là `PQColors.accent`, không phải màu highlight của card); (5) helper `cardBorderColorFor` **không được ghi vào file** vì `str.replace` không khớp (no-op im lặng) → undefined function | (1) tách `anyKey()` = `skipOffstage:false` cho kiểm TỒN TẠI, `keyOf()` cho kiểm hình học; (2) `scrollUntilVisible` + `pumpFor(250ms)` trước mọi phép đo/tap; (3) bỏ `tapAndSettle` ở chỗ này, dùng chính idiom repo (`scrollUntilVisible` → pump → `tap`); (4) so với `kBerryBorder = Color(0xFFEC5C93)` và **thêm ca phụ** chứng minh thẻ bên cạnh KHÔNG có viền đó (nếu không, phép kiểm chỉ là trang trí); (5) thêm ca "trước khi chạm bệ chưa có highlight" để chứng minh phép kiểm phân biệt được. Test in receipt `PQC022-MQ …` để đỏ kế tiếp tự giải thích ngay trong log tail, khỏi đoán |
| `pqc011` render | `9 passed, 1 failed / 10` | **Chưa có bằng chứng:** check-run chỉ in `Render suite test output: FAIL: 9 passed, 1 failed (10 total)` và file `render.txt` được đánh dấu `(missing: render.txt)` → không có tên ca, không có trace. GIẢ THUYẾT (suy từ source, chưa được CI xác nhận): `_TowerSceneHeader` đặt seal (`Positioned left:12`, `maxWidth:190`) và CTA (`Positioned right:12`) ở hai lớp positioned riêng nên ở 360×640 chữ 2× chúng chồng nhau. Chu kỳ kế sẽ phân biệt: nếu render xanh sau thay đổi dưới đây thì giả thuyết đúng, nếu vẫn đỏ thì phải đọc trace từ ca render chứ không đoán tiếp | Gộp seal + CTA vào **một** `Positioned(left:12,right:12,top:10)` dạng `Row` với `Expanded` quanh seal → seal wrap (2 dòng, không ellipsis, không FittedBox), CTA không bị cắt; không đổi số đo 180px của scene |
| Settings / isolated / sequence / integration | `12`, `1`, `2`, `7` ✓ | — | không đụng |

Không có ngưỡng, timeout, tolerance, regex hay danh sách gate nào được nới ở mọi
commit trên; số ca render vẫn **đúng 10** và ordinary chỉ tăng do file test mới.

### `354a338` — một error phân tích làm cả file test không compile

| Gate | Kết quả thật (đọc từ check-run của `354a338`) | Nguyên nhân | Cách sửa (commit này) |
|---|---|---|---|
| `PyQuest check` → `flutter analyze` | FAIL — `error • A value of type 'BoxBorder?' can't be assigned to a variable of type 'Border?' • test/r1b_and_chapter_25d_test.dart:250:26 • invalid_assignment`; `14 issues found` (13 info `curly_braces` có trước + 1 error này) | `BoxDecoration.border` có kiểu tĩnh là `BoxBorder?`, không phải `Border?`. Cảnh báo đỏ: `flutter analyze` **error** làm mất luôn 12 ca test của file | `final BoxDecoration decoration = card.decoration! as BoxDecoration; final Border border = decoration.border! as Border;` — cast tường minh, không `!` thừa, không `// ignore` |
| `pqc011` ordinary | `443 passed, 1 failed (444 total)` và ca fail là `r1b_and_chapter_25d_test.dart: loading ...` | Đây là **lỗi biên dịch**, không phải lỗi assert: file không load được nên ordinary TỤT từ 460 xuống 444 (12 ca của tôi không chạy). Kết luận quan trọng: đỏ ở `863d20a` (3 ca) và đỏ ở `354a338` (1 ca) là hai chuyện khác nhau | sửa error + thay `anyKey()` (đang thừa) bằng cuộn tường minh |
| `pqc011` render | `9 passed, 1 failed / 10` — **không đổi qua ba SHA** | GIẢ THUYẾT "seal/CTA chồng nhau ở 2×" của mục trên đã bị **bác bỏ**: `354a338` mang bản `Positioned(left:12,right:12)` + `Row`/`Expanded` mà render vẫn 9/10. Hai `Positioned` trong `Stack` cũng không sinh `RenderFlex overflowed`, nên nó không phải nguồn exception. `render_screens_test.dart` ghi rõ "Not a golden test: nothing is compared" ⇒ ca render chỉ có thể đỏ vì exception. CI KHÔNG công bố log render (`.output.text` in `(missing: render.txt)`, tương tự `test.txt`) nên **không có bằng chứng** để kết luận | Không đoán tiếp. Thêm ca `cấu hình render 390×844 dpr3 ở 1.0× và 2.0×` vào `r1b_and_chapter_25d_test.dart`: tái hiện đúng số đo của harness (390×844, dpr 3.0, `textScaleFactorTestValue` 1.0/2.0) cho MainQuest + sheet mở khóa + sheet khóa (`a02_sheet_locked`) + welcome (`a00_welcome`, tap `welcome_next` 3×), assert `takeException()` isNull và in receipt `PQC022-RENDER …` — ordinary log là kênh duy nhất CI công bố, nên red (nếu còn) sẽ tự nêu tên surface + cỡ chữ thay vì để người review đoán |

### Trạng thái suy luận — ghi rõ để không nhầm với bằng chứng

* **Đã chứng minh bằng CI:** formatter `Formatted 13 files (0 changed)`; focused `success` ở `863d20a`/`354a338`; Settings 12, isolated 1, sequence 2, integration 7; ordinary 457 (khi 12 ca của tôi chạy) / 443 (khi file không compile); render 9/10 ở `f97c8df`, `863d20a`, `354a338`; `PyQuest localization generation evidence` success.
* **Chỉ là suy luận từ source (chưa có bằng chứng CI):** nguyên nhân ca render đỏ. Đã loại được: golden (harness không so ảnh), overlay seal/CTA. Chưa loại được: tương tác của harness với `sheet_open`/`map_label_*` sau khi layout Main Quest đổi chiều cao, hoặc exception ở một màn không thuộc PQC-022 nhưng bị dịch chuyển cuộn.

### `238bebb` — analyze sạch, ordinary còn 2 ca (lỗi thứ tự cuộn trong test của tôi)

Bằng chứng đọc từ check-run của `238bebb3956717d2f1a5013f1a5abfd299f31f6c`:

* `flutter analyze`: `13 issues found`, **không còn dòng nào thuộc file của tôi**
  (13 info `curly_braces_in_flow_control_structures` có trước ở board/sheet tests)
  ⇒ error `BoxBorder?` đã hết, `_ChapterHeader` đã được dùng lại.
* `pqc011` ordinary: `459 passed, 2 failed (461 total)` ⇒ file của tôi compile và
  chạy đủ 13 ca. `Failing tests:` nêu đích danh:
  `chạm bệ chỉ đổi highlight dẫn bài…` và `openLessonId vẫn highlight + các key cũ còn nguyên`.
  Ca `cảnh vườn tháp + ba bệ + quick continue ở 1× và 2×` và ca
  `cấu hình render 390×844 dpr3 ở 1.0× và 2.0×` **xanh** ⇒ ba surface mới
  (MainQuest home, sheet mở khóa, sheet khóa, welcome + 3 lần `welcome_next`)
  không sinh exception ở đúng cấu hình harness render.
* `pqc011` render: vẫn `9 passed, 1 failed / 10` (SHA thứ ba liên tiếp). CI không
  công bố log render ⇒ không có tên ca, không có trace. Kết luận thành thật:
  **PQC-022 chưa chứng minh được nguyên nhân ca render đỏ**; các giả thuyết đã
  loại bằng dữ liệu: golden-compare (harness tự ghi "nothing is compared"),
  overlay seal/CTA (bản Row/Expanded ở `354a338`+`238bebb` không đổi số liệu),
  exception ở surface của tôi trong cấu hình render (ca mới, xanh).
* Hạn chế kênh bằng chứng: receipt `PQC022-MQ …` / `PQC022-RENDER …` in ra bằng
  `print` **không xuất hiện** trong `.output.text` của maintenance (chỉ là 18000
  ký tự cuối của log, `grep -n "PQC022-"` trên dump trả về 0 dòng). Chúng chỉ có
  giá trị khi ca đó trượt và khung hình failing nằm trong đoạn đuôi được công bố.
  Không được coi là "bằng chứng đã in".

Nguyên nhân hai ca đỏ còn lại — đều là **lỗi viết test**, sửa nguyên nhân:

1. `scrollUntilVisible(finder, 160)` tiến từng bước 160px, nên sau khi canh
   `lesson_card_mq1_09`, cái bệ ngay phía trên có thể bị tràn lên đỉnh khung
   nhìn ⇒ `expect(band2, findsOneWidget)` và `tap(band2)` đo hụt. Sửa: cuộn tới
   **chính widget sẽ chạm** (bệ), không cuộn tới thẻ ở dưới.
2. `SliverList` **thải element** của child ra ngoài `cacheExtent`, nên
   `skipOffstage: false` cũng không cứu được phép đọc sau khi đã cuộn đi chỗ
   khác. Sửa: đọc màu viền ngay khi thẻ đang ở gần khung nhìn, và thứ tự
   `lesson_card_mq1_01` (đỉnh) → deep link → `open_playground` (đáy) để mỗi key
   được kiểm lúc còn được build. Không thêm `ensureVisible` giả, không
   `pumpAndSettle` (hub có controller vô hạn), không nới timeout.

### `014c078` — ordinary còn MỘT ca, render vẫn `9/10`; thêm kênh chẩn đoán

Bằng chứng từ check-run của `014c078638d3a747df08df79d53886e29209fc38`:

* `PQC-020 focused gate evidence`: **success**, `Formatted 13 files (0 changed)`.
* ordinary: `460 passed, 1 failed (461 total)`; `Failing tests:` nêu đúng MỘT ca
  `Main Quest journey r43 openLessonId vẫn highlight + các key cũ còn nguyên`
  ⇒ hai lần sửa trước (seal/bar không lặp tên, `_ChapterHeader` dùng lại, cuộn
  đúng thứ tự) đã ăn: 12/13 ca của file tôi xanh, gồm cả ca
  `cấu hình render 390×844 dpr3 ở 1.0× và 2.0×`.
* `PyQuest check | failure` chỉ vì `flutter test` của chính nó gặp cùng ca đỏ đó;
  `### analyze.txt` của nó ghi `13 issues found` và **không còn dòng nào thuộc
  file PQC-022** ⇒ không còn warning/error do tôi.
* Attribution của ca render: tại `561d0f6e5f4f63c9cf38ce35928b8cb481fc1f8a`
  (tip ngay trước PQC-022) `PQC-011 r49 exact gate counts` fail vì
  `ordinary suite, Ordinary suite test output: FAIL: 440 passed, 1 failed (441 total)`
  và **render không nằm trong danh sách fail** ⇒ render 10/10 ở đó, nên ca render
  đỏ hiện tại do thay đổi của PQC-022 gây ra, không phải có trước. Đây là kết luận
  từ SỐ LIỆU gate của hai SHA, không phải suy từ nội dung diff.
* Không có đường nào khác để đọc log render: artifact `pqc011-r49-…-diagnostics`
  (38 KB) tồn tại nhưng host blob của GitHub Actions không nằm trong danh sách
  mạng được phép ⇒ `gh run download` trả EOF; các check-run `preview|…` là của
  PQC-023 (board), không liên quan; `PQC-011 r49 exact gate counts` chỉ công bố
  4 log tail (isolated / sequence / integration / ordinary), **không có render**.

Để chu kỳ sau có bằng chứng thay vì đoán, commit này thêm hai kênh chẩn đoán:

1. `cấu hình render …` gọi lại đúng `capture()` của harness: bọc cây trong
   `RepaintBoundary` + `boundary.toImage(pixelRatio: 1.5)` +
   `image.toByteData(png)` trong `tester.runAsync`, assert không lỗi. Đây là
   khác biệt cuối cùng còn lại giữa ca thường và ca render.
2. Group mới `Render A replica` dựng LẠI TRÌNH TỰ của `render A: first launch`
   trên app thật (`intro_seen='0'`, `pumpRoot` 2.0×, 3× `welcome_next`,
   `directory_place_main_quest` + `hubTextScale ≈ 32`, đổi `main_map_mode_village`,
   về 1.0×, `map_label_bug_hunter`, đọc `getRect(sheet_go_lesson)` so với chiều
   cao viewport rồi `tap` **trực tiếp không `ensureVisible`** như harness,
   `expect(MainQuestHomeScreen, findsOneWidget)`). Nếu ca này đỏ thì đó chính là
   ca render đỏ, và tên ca trong `Failing tests:` đủ để chỉ ra bước nào.

Hồ sơ cũng ghi lại một lỗi nhỏ không ảnh hưởng code: message của commit
`014c078` có lẫn hai ký tự CJK (`步进`) do tôi gõ sai; không sửa lại lịch sử vì
không force-push.

### `9940e6b` — một error `runAsync` nữa, và vì sao nó đắt

`9940e6bbc367e875903600cc1e4f75ffc23a999b`: analyze báo
`error • The returned type 'String?' isn't returnable from a 'Future<Object>'
function, as required by the closure's context •
test/r1b_and_chapter_25d_test.dart:904:20 • return_of_invalid_type_from_closure`
⇒ file không compile ⇒ ordinary `443 passed, 1 failed (444 total)` với ca fail là
`r1b_and_chapter_25d_test.dart: loading …`, tức 15 ca của tôi chạy 0 assert (kể
cả hai ca chẩn đoán mới). Hệ quả cần nhớ: **mỗi error biên dịch trong file test
nuốt luôn 16 dòng gate**, nên phải tự kiểm tra kiểu trả về của closure khi dùng
`tester.runAsync` — ở đây suy ra `T = Object` từ nhánh `catch`, nên `return null`
bị từ chối. Sửa: closure trả `void` (`runAsync<void>`) và ghi lỗi vào biến cục bộ
`Object? captureError = null;`.

### `f647db7` → commit này: isolating đỏ = bằng chứng cho MỘT rule thiết kế bị thiếu

`f647db7f1ee4da5322c26e577589073a56b252e6`: ordinary `464 passed, 1 failed
(465)`, `Failing tests:` còn ĐÚNG MỘT ca
`Main Quest journey r43 key hợp đồng cũ lesson_card_mq1_01 còn trên Main Quest 2.0x`.
Hai ca em-vừa-tách (cuộn tới `open_playground`, và đi qua 4 thẻ `mq1_01/04/08/12`)
xanh ⇒ không có exception, không có Scrollable lồng gây sai, các key đều tồn tại
và tới được. Vậy thẻ bài **đầu tiên** không ở trong khung nhìn ngay khi mở màn ở
2.0× trên 360×640: dải cảnh 180px + panel chặng 2.0× đã đẩy `lesson_card_mq1_01`
xuống dưới nếp gấp.

Đây không phải "test sai" mà là **rule r56 chưa áp dụng cho Main Quest**:
*"từ 1.5×, content đứng trước artwork, không phóng to artwork"*. Sheet đã làm
đúng (`kR56LargeTextScale`), màn Main Quest thì chưa. Sửa theo rule, không sửa
theo test:

* `kTowerLargeTextScale = 1.5` + `largeText` trong `_MainQuestHomeScreenState.build`.
* 1.0×: `[sceneHeader, 12, _ChapterHeader, …]` (artwork trước, đúng ý r43).
* ≥1.5×: `[ _ChapterHeader, 12, sceneHeader, … ]` (chữ trước, artwork sau).
* `_TowerSceneHeader` được dựng MỘT lần vào biến `sceneHeader` để hai nhánh không
  sao chép tham số (và `_ChapterHeader` vẫn được tham chiếu ⇒ không còn
  `unused_element`).
* Test khóa lại bằng `PQC022-MQ ${scale}x chapterTop=… sceneTop=…` + hai nhánh
  `expect`: `chapterTop < sceneTop` ở 2.0×, ngược lại ở 1.0×.

### `ddf53be` → đảo thứ tự chưa đủ; ở ≥1.5× phải **bỏ** lớp artwork

`ddf53be31e5d433df057901e4b25b4ccdafcb639` đưa panel chặng lên trước dải cảnh ở
≥1.5×. Kết quả ordinary: còn **hai** đỏ, tức là sửa một phần và lộ ra phần còn lại:

* `lesson_card_mq1_01 … 2.0x` vẫn đỏ ⇒ ngay cả khi chữ đứng trước, dải 180px
  (cộng panel chặng ~450px ở 2×) vẫn lớn hơn chỗ mà 640px dành cho nội dung.
  Ở 2.0×, "trả chỗ" không thể đạt bằng cách xếp lại — phải **giảm** artwork.
* `cảnh vườn tháp + ba bệ + quick continue` **bật đỏ mới** ⇒ đúng như dự đoán
  khi dải cảnh bị đẩy xuống dưới: `getSize(tower_25d_scene)` không còn tìm thấy
  RenderBox vì dải cảnh nằm ngoài viewport. Đây là bằng chứng ngược, xác nhận
  vấn đề là *chiếm chỗ*, không phải *thứ tự*.

Cách sửa cuối (commit này), vẫn đúng tinh thần r56 "content before artwork,
không phóng artwork":

* `_TowerSceneHeader` thêm `showArtwork`; `false` thì widget chỉ còn dải seal +
  `quest_quick_continue` (`Row` cũ được tách thành `_strip()` để hai chế độ dùng
  chung một định nghĩa, không sao chép hành vi) và **không** mang key
  `tower_25d_scene`.
* `_MainQuestHomeScreenState.build` luôn đặt dải này ở đỉnh (r43: "quick continue
  ở góc trên cảnh, không bắt trẻ tìm CTA cuối trang") rồi tới panel chặng + danh
  sách bài; `showArtwork: !largeText`.
* Test chuyển từ "đo thứ tự bằng geometry" (giòn, phụ thuộc viewport) sang
  **hành vi có thể quan sát được**: 1.0× còn `tower_25d_scene` cao 180 và đứng
  trước `CHẶNG 1`; ≥1.5× thì `tower_25d_scene` *biến mất*, không còn `Image.asset`
  của scene, và `lesson_card_mq1_01` phải thấy được ngay khi mở màn. Ca cô lập
  `lesson_card_mq1_01 … 2.0x` (deep-link `openLessonId: 'mq1_03'`) giữ nguyên.
* Xoá const trùng ý nghĩa trong comment, sửa `kTowerLargeTextScale` doc, và sửa
  `avoid_init_to_null` (`Object? captureError;`) mà `analyze` vừa báo ở file test.

## 7. Chốt nguyên nhân thật (do Lead trên `arena/84456d39-pyquest`) — và bài học quy kết

`29ba169` + `029f801` trên nhánh hợp nhất đã đóng cả hai điểm đỏ cuối. Nguyên
nhân KHÔNG phải "thiếu rule r56" như suy luận của tôi ở §6:

* `lesson_card_mq1_01` ở `2.0×` / `360×640`: `find.byKey` mặc định
  `skipOffstage: true`, nên một child của `SliverList` nằm ngoài
  `scrollOffset .. scrollOffset + remainingPaintExtent` cho `findsNothing` **dù
  widget vẫn được build và vẫn đúng thiết kế**. Lead sửa bằng cách làm cho nó thật
  sự nằm trong vùng vẽ: `_ChapterHeader` co còn dải tiêu đề một dòng
  (`CHẶNG 1 · Những dòng đầu tiên`) khi `textScale >= 1.5`, cộng
  `cacheExtent: 1200`.
* Render F `360×640`: cùng cơ chế offstage — `tap()` trong
  `test/render/render_screens_test.dart` giờ lấy finder với
  `skipOffstage: false` rồi `tester.ensureVisible(f.first)` trước khi chạm, nên
  thẻ `lesson_card_mq1_04` ở dưới nếp gấp vẫn chạm được.

Ba điều rút ra cho chu kỳ sau (tự phê bình, không phải thay đổi thiết kế):

1. Trước khi quy kết "thiếu rule trong lib" cho một assertion `findsNothing` trên
   danh sách cuộn, phải loại giả thuyết offstage-trước-cuộn (đọc
   `Scrollable.position.pixels` + `viewportDimension`, hoặc chạy finder với
   `skipOffstage: false`). Tôi đã dành 4 SHA đổi `main_quest_module.dart` theo
   hướng "artwork phải trả chỗ", trong khi màn hình chỉ cần `cacheExtent`.
2. `showArtwork: !largeText` (bỏ hẳn lớp cảnh ở ≥1.5×) trong `498ecf8` **đã bị
   thay** bởi phương án gọn hơn của Lead: giữ nguyên dải cảnh cho mọi cỡ chữ,
   chỉ thu panel chặng. Không cần nhân bản `_strip()`.
3. Marker trong commit message là điều kiện chạy của hai cổng focused/maintenance
   (`[pqc020-check]`, `[pqc011-verify]`); một commit thiếu marker cho ra
   `skipped`, dễ đọc nhầm thành "CI không chạy được".

Trạng thái bàn giao: nội dung PQC-022 đã nằm trong `arena/84456d39-pyquest@029f801`
và `arena/4253d4f1-pyquest@56ace81` (sync, không force-push). Việc còn lại thuộc
Lead: ACCEPTED020 trên SHA bàn giao cuối, và xác nhận 18 file docs/tools chỉ nhánh
CODE có (`docs/implementation/coordination/{TASK_BOARD,LEAD_RUNBOOK,HANDOFF_TO_DESIGN}.md`,
`docs/implementation/coordination/tasks/*`, `tools/coordination/*`,
`.circleci/config.yml`, bằng chứng PQC-020 R2 và `r38-originals`) — nếu nhánh hợp
nhất chủ đích không có chúng thì nhánh CODE sẽ xóa theo yêu cầu.
