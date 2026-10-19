# PQC-020 R3 — bằng chứng: geometry village, root text scale, semantics render

**2026-10-19 · CODE evidence cho `DESIGN-PQC020-R3-DDF7DB5A` · KHÔNG phải ACCEPTED020.**

Spec R3 (import read-only từ DESIGN pin `0b96cdf20c5e2e9dbe8f2b17198cbdaed0420fca`):
[PQC-020-R3.md](../../../../design/coordination/specs/PQC-020-R3.md).
Review nền của DESIGN trên tip R2 (cũng import read-only, nguyên văn, CODE không sửa):
[PQC-020-ddf7db5a/README.md](../../../../design/coordination/reviews/PQC-020-ddf7db5a/README.md)
+ `evidence.json` + 8 captures trong `captures/`.

Mọi con số dưới đây hoặc (a) trích nguyên văn từ check-run của Actions, hoặc (b) là mô
hình số do CODE tính từ công thức trong source — nhãn `(mô hình)` chỉ rõ chỗ đó. Không
có số nào được "suy" từ ảnh hoặc từ một gate lẻ.

## 0. Provenance của bản import read-only (và một lỗi message cần nêu rõ)

11 file DESIGN-side được import nguyên văn từ pin `0b96cdf` (không merge branch, không
sửa nội dung): `docs/design/coordination/specs/PQC-020-R3.md`,
`docs/design/coordination/reviews/PQC-020-ddf7db5a/README.md`, `evidence.json` và 8
captures. SHA-256 prefix của bản trong repo **trùng khớp 12 ký tự đầu với blob ở pin**
cho cả 11 file (`dd62e520f07b` spec, `5f4c6258d647` README, `ee1fa68c4ea5` evidence.json,
`4bb7f2d98165` before-capture — đúng giá trị review §4 đã công bố, nên bản import cũng
khớp receipt của chính DESIGN).

Điều cần nói thẳng: các file này vào repo ở commit `f2f820b`, nhưng message của commit đó
chỉ nêu "ghép dart format" — vì `git checkout <pin> -- <paths>` đã tự stage chúng trước
đó. Nội dung không sai và không ngoài phạm vi (§D mục 9 cho phép import), nhưng provenance
nên nằm trong message; ghi lại ở đây để người đọc sau không phải đoán.

## 1. Chuỗi commit và vì sao mỗi bước đỏ

| SHA | Nội dung | Gate đọc được |
|---|---|---|
| `16027a2` | tests R3 trước khi sửa source | focused `39253245365`: bước **Dart formatter failure** → các bước sau `skipped` (không có verdict test) |
| `7177379c` | thêm `import activity.dart` + ghép format | CI `39253555316`: `analyze=1` — `Undefined class 'ActivityModule'` at `test/main_map_app_root_test.dart:141:24` |
| `7177379c` | (cùng SHA, sau fix import) | focused `39253555314` **58 passed, 1 failed (59 total)** — xem §2; CI `39253555316` analyze=0, `ordinary_tests=1`; maintenance `39253555268` ordinary **435 passed, 4 failed (439 total)** |
| `9bb5531` | production A + B | focused `39254852390` formatter failure (3 file); CI `39254852256` **analyze=1** (18 issues, 1 error mới) → Settings/Ordinary/Render `skipped`; maintenance `39254852268` ordinary `387/7 (394)` — 7 cái đều là `loading <file>` = lỗi BIÊN DỊCH |
| `503dd4d` | `import foundation` + format | focused `39256024275` **61 passed, 0 failed** ✓; CI `39256024243` analyze=0, Settings 12/0, ordinary **439/2 (441)**; maintenance `39256024348` render **10/0** ✓, isolated 1/0, sequence 2/0, integration 7/0, formatter/analyze/cleanliness PASS |
| `ff7fbde` | append 5 dòng workflow | focused `39256780941` formatter failure cho đúng 2 file vừa vào allowlist |
| `f2f820b` | format `pyquest_app` + root test | focused `39257044341` **62 passed, 2 failed (64)** — 2 failures là `main_map_app_root_test.dart`; trace ở §4 |
| tip sau đó | sửa root test (cuộn trước khi tap) + oracle exception có phạm vi + tài liệu này | bảng gate của tip được Lead/CODE đọc từ chính run trên tip; không suy từ `f2f820b` |

## 2. Finding A — regression BẮT được lỗi tại base (trước khi sửa source)

Nguyên văn từ `PQC-020 focused gate evidence` check-run `118063474177` (run
`39253555314`, sha `7177379c`, source chưa sửa):

```text
00:03 +5: …/app/test/main_map_scene_test.dart: village: sáu RenderBox nút thật nằm đúng
projection, không chồng nhau, cuộn được tới từng cái
The following TestFailure was thrown running a test:
Expected: a numeric value within <0.5> of <172.79999999999998>
  Actual: <175.10399999999998>
   Which:  differs by <2.304000000000002>
main_quest tâm X phải khớp projection ở Size(360.0, 640.0)/vi/1.0x
  file:///…/app/test/main_map_scene_test.dart line 216
```

Ba điểm cần nhấn mạnh:

- Lộ ở **1.0×**, không phải chỉ 2×: `Align` sai ở mọi scale, chỉ khác độ lớn.
- Cùng SHA đó, ordinary suite maintenance = `435 passed, 4 failed (439 total)`; 439 =
  435 baseline đã nghiệm thu + 4 case mới (3 root scale + 1 R3-GEOM). **4 failed = đúng
  4 case mới**, không có case cũ nào đỏ → không regression phụ, và không nới ngưỡng.
- Số lệch ở 390 cho `dragon_jump` trong capture CI round trước là −36.7 px; (mô hình)
  cùng công thức cho `|Δx| = |2·(1−anchor.x)·(parentW−childW)/2 − …|` khớp 33.6 px ở
  360 và 36.7 px ở 390 mà CODE tính lại từ source (marker width = 0.32·scene width).

## 3. Finding A — hợp đồng chung, không còn “model test xanh / hộp thật đè nhau”

`_positionedMarker` cũ: `Align(alignment: Alignment(2x−1, 2y−1))` với `x = anchor.x·sceneW
/ sceneW`. `Align` đặt tâm child tại `childSize/2 + anchor·(parentSize − childSize)` ⇒
chỉ trùng `anchor·parentSize` khi child == parent. Va chạm là quan hệ **giữa hai hộp**,
nên không thể giải trong từng child: sáu `Align` được thay bằng **một**
`CustomMultiChildLayout` (`_VillageMarkerLayout`, `main_map_scene.dart`) gọi
`villageMarkerPlacements` (`main_map_scene_geometry.dart`) — production và test cùng một
hàm, đó là “one shared production/test contract”.

Quy tắc (doc comment đi kèm source): canh hộp **nội dung thật** lên projection → kẹp vào
scene → quét từ trên xuống, chỉ đẩy theo trục Y và chỉ với cặp thực sự chung dải ngang →
nếu tràn đáy thì quét ngược từ đáy → mọi khoảng đã lệch được trả về là
`declaredOffset`. Không đổi x sau bước 1 ⇒ không đổi `anchor` và không chuyển marker sang
nhà khác. Không `ellipsis`/shrink font/clip/`scaleDown`; `softWrap` vẫn bật; chiều rộng
nhãn giữ đúng `0.32·scene.width` và `minimumSize` 48 như trước ⇒ target ≥ 48 không giảm.
Artwork/ids/aspect ratio 853×1844 không đụng.

(mô hình) Cùng thuật toán CODE viết tay bằng Python để quét trước khi code:

| scene width | chiều cao nội dung | offset phải khai báo | còn đè nhau? | tràn scene? |
|---|---|---|---|---|
| 328 (=360−32) | 48/58/76/100 (≈1×–1.3×) | không có | không | không |
| 328 | 120 (≈2×) | robot_maze +14.1, achievement_house +7.0 | không | không |
| 328 | 160 (2× + wrap) | robot_maze +54.1, catch_stars +32.8, bug_hunter +79.8, achievement_house +79.8 | không | không |
| 328 | 200 | main_quest −4.6, robot_maze +89.5, dragon_jump −32.9, catch_stars +39.9, bug_hunter +155.3, achievement_house +126.9 | không | không |
| 358 (=390−32) | 48/58/76/100 | không có | không | không |
| 358 | 120 | robot_maze +4.0 | không | không |
| 358 | 160–200 | 4 nhãn, lớn nhất +137.1 | không | không |
| 328/358 | ≥260 (3×+, giả định) | có | **CÒN** đè 2 cặp | không |

Đọc bảng: 1×/1.3× **không cần offset nào** ⇒ assertion “tâm thật == projection, 0.5 px”
vẫn bắt buộc và có nghĩa ở đó; 2× lệch có khai báo, không còn đè; chỉ ở chiều cao phi
thực tế (≥260 px cho một nhãn 105×?) thuật toán bó tay vì hình học hết chỗ — lúc đó test
báo cáo đè, layout không giấu bằng cách thu nhỏ chữ.

Bằng chứng render (không phải mô hình): focused `39256024275` tại `503dd4d` =
**61 passed, 0 failed (61 total)** với case R3-GEOM đo `tester.getRect`/`tester.getSize`
của sáu `map_label_*` ở 360×640 + 390×844, VI/EN, 1/1.3/2× (2× có chuyển mode thật bằng
`main_map_mode_village` vì 2× mặc định là directory), so hộp thật với ô mà
`villageMarkerPlacements` đã quyết (0.5 px), buộc `declaredOffset.dx == 0`, buộc tâm ==
projection khi offset được khai báo là 0, đủ 48 px, không đè nhau, nằm trong scene,
`ensureVisible` + `hitTestable` từng cái, và `takeException` phải null. Hai test model
mới trong `main_map_scene_geometry_test.dart` kiểm chính hợp đồng (bảng trên ở tầng
unit); bốn test model cũ vẫn đó, đổi tên thành `model:` theo §A.

## 4. Finding B — root thật nhận system scale; hai bug lộ ra khi bỏ bypass

Production: `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.2)` đã bị **xóa** khỏi
`app/lib/app/pyquest_app.dart` (thành comment block tại `:153`), không clamp mới, không
cờ theo màn hình, không sửa theme/boot/locale-binding/routes. `grep -n
"withClampedTextScaling\|maxScaleFactor"` trên file: 0 kết quả ngoài comment.

Test `main_map_app_root_test.dart` dựng `PyQuestApp` thật, đặt scale bằng
`tester.platformDispatcher.textScaleFactorTestValue` + `addTearDown(clearTextScaleFactorTestValue)`
(không bọc MediaQuery, không route MainMap thứ hai). Receipt CI nguyên văn từ
`f2f820b` (check-run `118074…` text, run `39257044341`):

```text
R3-ROOT 360x640/vi/1.0x hubScaler=16.0 sheetScaler=16.0 mode=village
R3-ROOT 360x640/vi/1.3x hubScaler=20.8 sheetScaler=20.8 mode=village
```

⇒ **bằng chứng CI** cho điều kiện “1→16, 1.3→20.8 tại hub VÀ sheet, đúng mức hệ thống,
không còn cap 1.2” (1.2× sẽ cho 19.2). 2× bị chặn bởi hai lỗi dưới đây, không phải bởi
cap.

**(a) Lỗi của chính test — đã sửa.** `smoke 2×` fail vì
`Found 0 widgets with key [<'sheet_go_lesson'>]`; trace kế trước đó:

```text
Warning: A call to tap() with finder "Found 1 widget with key [<'directory_place_bug_hunter'>]: [
  _DirectoryPlaceButton-[<'directory_place_bug_hunter'>],
]" derived an Offset (Offset(195.0, 984.8)) that would not hit test on the specified widget.
Indeed, Offset(195.0, 984.8) is outside the bounds of the root of the render tree, Size(390.0, 844.0).
```

Ở 2× directory, hàngBug Hunternằm dưới gập màn (984.8 > 844) ⇒ tap trượt ⇒ sheet không mở.
Sửa: `ensureVisible` rồi mới tap (và cùng cách cho `firstPlace`, `mazeRow`). Đây là điều
kiện “controls phải CUỘN tới được rồi chạm”, không phải nới assertion.

**(b) NEW-FINDING ngoài allowlist — báo cáo, không sửa.** `root matrix` đỏ ở
`layout exception ở 360x640/vi/2.0x` với

```text
Expected: null
  Actual: FlutterError:<A RenderFlex overflowed by 135 pixels on the right.>
```

và ở config 390 cùng pha, log giữ nguyên dump render object:

```text
A RenderFlex overflowed by 105 pixels on the right.
The overflowing RenderFlex has an orientation of Axis.horizontal.
… constraints: BoxConstraints(0.0<=w<=390.0, 0.0<=h<=Infinity)
… size: Size(390.0, 128.0)  direction: horizontal  mainAxisSize: min
```

(mô hình, có khớp số) Row nằm trong **shell của hub**, `Row(mainAxisSize: min)` chứa
`_IslandTitle` (Container 44 + SizedBox 10 + Column hai dòng `PQText.h3`/`small`) cộng
hai `RoundIconButton(size: 48)`; nội dung ≈ 495 px nên `495 − 360 = 135` và
`495 − 390 = 105` — đúng hai con số CI. File chứa nó là
`app/lib/modules/main_map/main_map_screen.dart`, **không** nằm trong allowlist R3 (§D:
“Không sửa … ngoài list, báo finding cụ thể trước”) ⇒ CODE không tự sửa header, cũng
không khôi phục cap để che lỗi (§B). Hệ quả: **không tuyên bố toàn app đạt 2×**.

Oracle mới `expectOnlyDocumentedRootOverflow` thay cho `expect(takeException, isNull)`:
1×/1.3× vẫn bắt buộc null tuyệt đối; ở >1.5 chỉ ĐÚNG một lỗi horizontal right-overflow
được tha, in receipt `R3-ROOT-EXC <cfg/stage> <dòng đầu của dump>`; bất kỳ exception nào
khác làm đỏ với nguyên văn dump trong `reason`. Mỗi giai đoạn (hub, village/mode, sheet
mở, sheet đóng, final) được kiểm riêng để không dồn “Multiple exceptions”. Hình học
scene KHÔNG dựa vào lệnh tha này — nó do case R3-GEOM (`main_map_scene_test.dart`) giữ
nghiêm ở cùng 12 config, trong cùng gate.

## 5. Finding C — oracle semantics đọc cây render

`lesson_route_regression_test.dart`: case semantics sau khi đóng modal gọi
`tester.ensureSemantics()` (dispose handle), cuộn từng `map_label_*` vào viewport, rồi
`tester.getSemantics(place)` + `getSemanticsData()` để assert button role, nhãn
“`<tên>, <status>`” theo locale, `SemanticsAction.tap`, `enabled`; và đếm
**button node con trong cùng subtree** (`innerButtons == 0`) để chứng minh sau
merge/exclusion không còn node lặp — thay cho việc đếm widget `Semantics` trong cây
widget (nguyên nhân fail thật của round trước: một `_PlaceButton` mang hai `Semantics`
trước `ExcludeSemantics`, nên đếm wrapper không bao giờ là oracle). Receipt `R3-SEM` in
số hiệu node đã đọc. Đủ 8 cases, keyboard sequence R2 giữ nguyên, không assertion lesson/
prerequisite/energy nào bị bỏ. Bốn info `deprecated_member_use` cho `hasFlag` là pattern
sẵn có của repo; không thêm `// ignore`, không đoán API `flagsCollection`.

## 6. §D mục 8 — diff workflow, đúng 5 dòng append

`.github/workflows/pqc020-focused.yml`: `lib/app/pyquest_app.dart` vào `dart format`,
`test/main_map_app_root_test.dart` vào cùng list + vào `source_files` của snapshot + vào
danh sách `flutter test` (đặt CUỐI, để trace của nó nằm trong `log[-18000:]` mà bước
evidence giữ lại khi đỏ). Không đổi routing/SDK/steps/timeouts/publisher/gates;
`pqc011-maintenance.yml` và `ci.yml` không bị chạm.

## 7. Ngân sách asset / asset-loading (§E mục 4)

| Hạng | Giá trị | Nguồn |
|---|---|---|
| `app/assets/images/village_r53.webp` | 349,864 bytes | `stat` trong repo; khớp DESIGN review §4 |
| Kích thước giải mã | 853 × 1844 (VP8) | DESIGN review §4; CODE không cần đo lại hash |
| SHA-256 asset | `d3130b407e08f146ae633b50fad9f1e05aa466dd5dc049cdc75c1b36f8804c0e` | DESIGN review §4 (import read-only) |
| RGBA lý thuyết | 6,291,728 B = 6.00026 MiB | 853·1844·4 — **không phải RAM/GPU thiết bị** |
| Asset mới / đổi bytes | không | `git diff` không có file assets; §D “Không sửa asset bytes” |
| Ảnh hub nạp | đúng MỘT `Image.asset('assets/images/village_r53.webp')` (`main_map_scene.dart:113-120`, `gaplessPlayback: true`) | source |
| Preload nền cũ + mới | không có: `precacheMap` (`test/render/render_screens_test.dart:124-136`) chỉ village_r53 + sáu thumbnail, không còn `island_map` | source; khớp ghi chú review §4 |
| Tổng `app/assets` | 45 file, 2,255,274 B; fonts 9 file 796,912 B | `find`/`stat` — nền repo, không đổi |
| Render object quanh nhãn | trước: 6×(`Align`+`SizedBox`) = 12; sau: 1 `RenderCustomMultiChildLayout` + 6 `MultiChildLayoutParentData` | cấu trúc source (không phải đo máy) |
| **Frame time / RAM trên thiết bị** | **NOT_MEASURED** | không có device/emulator round này; không hứa 60fps từ bytes hay widget test |

## 8. Còn thiếu / không claim

- Baseline provenance: ảnh `before-6dc8ca8-a01-map-new-player.jpg` (SHA-256
  `4bb7f2d981655abbbd09f02e7cfd87c30ddfd6dfe86d8bdb197a3ed70cbcbfe3`) là
  **390×844 · VI · new-player · 1×**, đã được DESIGN đối chiếu byte-identical với Checks
  API; không phải ảnh “before 2×”, và CODE không chạy lại baseline (§E mục 3).
- Chưa đóng: overflow header ở `main_map_screen.dart` tại 2× thật (§4b), frame time/RAM
  thiết bị (NOT_MEASURED), TalkBack/thiết bị, APK, toàn bộ claim 2× ngoài lát cắt hub +
  sheet + hai route smoke, R1-B/Bug Hunter.
- CI xanh ≠ ACCEPTED020; Lead mở ảnh và review trên finalSHA.


## 9. Đính chính attribution của mục 4b (2026-10-19, lượt PQC-022)

Mục 4b ghi: "2× thật để lại MỘT `RenderFlex overflowed ... on the right` ở header
hub, nguồn suy ra là `_IslandTitle` (`main_map_screen.dart:330`)". **Sai nguồn.**

Bằng chứng mới:
- `FlutterError.toString()` của layout overflow không chứa `file:line`, nên 4b chỉ là
  mô hình số học (495−360=135, 495−390=105). Con số vẫn khớp, nhưng phép gán cho
  `_IslandTitle` không có cơ sở trực tiếp — đúng như mục 6 đã cảnh báo.
- Khi Lead/Co-Dev bọc `PyQuestLogo` và hàng `CharacterView` của **SplashScreen**
  bằng `FittedBox(fit: BoxFit.scaleDown)` + `SingleChildScrollView`
  (`app/lib/app/pyquest_app.dart`, commit `af09802` trên `arena/84456d39-pyquest`),
  toàn bộ 12 config của matrix ở ROOT THẬT chuyển sang sạch:
  `app/test/main_map_app_root_test.dart` hiện assert `expect(tester.takeException(),
  isNull)` cho MỌI config (kể 2×) và maintenance in `00:50 +443: All tests passed!`
  trên `8d79a59e7da91634ecdc111c6b2db663c7e86b46`. `main_map_screen.dart` không đổi
  một byte giữa hai SHA ⇒ nếu header còn tràn thì `isNull` đã đỏ.
- Hệ quả cho test: oracle `expectOnlyDocumentedRootOverflow` (cho-phép-đúng-một-lỗi)
  của lượt này **không còn cần** và đã được thay bằng assert strict `isNull` khi import
  `8d79a59`; không phải nới tolerance mà là hết điều kiện để nới. Receipt in
  (`R3-ROOT ...`, `R3-ROOT scale-change ...`, `R3-GEOM`, `R3-SEM`) giữ nguyên.
- Cũng chính pending-exception đó là nguyên nhân thật của đỏ `smoke 2×` ở `561d0f6`
  (tap CTA sinh `warnIfMissed` → "Multiple exceptions" → route không mở), không phải
  do rect như suy đoán trong §4c; bản `8d79a59` thêm `ensureVisible` trước các tap và
  đỏ biến mất.

Không thay đổi các kết luận khác của §4: 1×→16.0 và 1.3×→20.8 ở hub + sheet,
scale-change khi sheet đang mở, và ràng buộc không khôi phục cap 1.2.
