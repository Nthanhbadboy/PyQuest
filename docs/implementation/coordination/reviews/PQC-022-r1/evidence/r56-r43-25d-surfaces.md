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
| (điền sau chu kỳ CI của commit kế tiếp) | |

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
