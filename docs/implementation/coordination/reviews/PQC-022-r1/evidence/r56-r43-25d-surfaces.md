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

| Workflow | Trạng thái | Số liệu |
|---|---|---|
| `PQC-020 R1-A focused verification` | (điền sau khi CI chạy trên SHA này) | |
| `PQC-011 r49 maintenance verification` | | ordinary / render / Settings / isolated / sequence / integration |
| `PyQuest CI` | | analyze / formatter / l10n / pub get |
