# Bằng chứng của nhánh code — PQD-001 / PQC-001…005

Quy tắc của file này: **một mục chỉ được ghi `verified` khi có lệnh đã chạy thật và kết
quả dán ở đó.** Mục nào chưa chạy thì ghi rõ `pending`/`not run` và ai phải chạy.
Không suy luận từ "CI xanh" ra "art được duyệt" hay "chạy tốt trên thiết bị".

Môi trường của lead (sandbox code): `python3` = Python 3.11.2, **không có** Flutter/Dart
SDK, không có Android SDK/emulator, Pillow chỉ có trong venv tạm `/tmp/pqvenv` (Pillow
12.3.0, cài từ pypi.org). Vì vậy: kiểm tra Python/hash → chạy local được; kiểm tra
Dart/Flutter → chạy qua CI `check` job trên đúng commit đã push.

Bản ghi code SHA gần nhất cho mọi mục bên dưới: `10fd7aa301a1210a074cde9afea3bf52e532312f`
(code tip) và design `560106e725e93c9385fd067d554693cf16e80a69` (revision 3).

---

## EV-ID-001 — Tài sản art + baseline: `verified` (intake, rev 1–2)

| Hạng mục | Cách kiểm | Kết quả |
|---|---|---|
| 6 master PNG 1024² | `sha256sum` + PIL size/format từng file | khớp manifest, 1024×1024, `PNG` |
| 12 WebP 256/512 | `sha256sum` so `manifest.json` | **24/24 khớp hash**, `alpha=false` cả 6 id |
| Dung lượng exports | cộng `variants[].bytes` | 112.938 B (6×512) + 43.092 B (6×256) = 156.030 B |
| Baseline runtime | `sha256sum app/assets/images/thumb_*.webp` so `baseline/*.webp` | 6/6 **khớp từng byte**, tổng 144.272 B |
| Mapping id→asset | đọc `docs/design/village-kit/manifest.json` + module dart | `python_academy→thumb_tower`, `robo_maze→thumb_maze`, `pip_volcano→thumb_volcano`, `star_observatory→thumb_observatory`, `bitsy_workshop→thumb_workshop`, `achievement_house→thumb_house` |
| Swap đã đề xuất (PQC-002) | 6×512 trừ 6×288 hiện tại | **−31.334 B** (nhẹ hơn, không phải phình asset) |

Không kiểm ở lượt này: cảm nhận chủ quan của người dùng với art ở 104 px (visual review
một phần ở EV-ID-007, nhưng **quyết định duyệt vẫn thuộc người dùng**).

## EV-ID-002 — PQC-001 (exporter không ghi đè baseline): `verified at design, do code branch chạy lại`

Design đã tự vá ở revision 3 → code branch **không** viết bản exporter song song.
Bằng chứng là chạy lại test của chính design:

```sh
# repo thật không bị đụng tới: chỉ trích xuất tree của design ra thư mục tạm
git archive 560106e725e93c9385fd067d554693cf16e80a69 | tar -x -C /tmp/rev3
/tmp/pqvenv/bin/python -m unittest discover -s /tmp/rev3/tools/design -p 'test_village_kit.py' -v
```

Kết quả dán nguyên văn: `Ran 11 tests in 1.780s` → `OK`, cùng 2 dòng
`Exported 6 masters → 12 WebP variants (156,030 bytes); app assets untouched.`

5 test hồi quy đúng phần lead từng báo lỗi exporter:

1. `test_corrupted_baseline_fails_without_writes`
2. `test_missing_baseline_fails_without_writes`
3. `test_changed_manifest_hash_cannot_bless_corrupted_baseline` (sửa hash không hợp thức hoá ảnh hỏng)
4. `test_duplicate_id_fails_without_writes`
5. `test_export_after_runtime_change_preserves_baseline_and_is_repeatable` (runtime đổi sang 512 trong
   fixture → export 2 lần: baseline giữ nguyên, kết quả lặp giống nhau, tool không sửa runtime)

Preflight chạy **trước mọi ghi file** và không đọc thumbnail runtime
(`tools/design/export_village_kit.py:26 validate_baselines`), không có `--refresh-baseline`.
`docs/design/village-kit/baseline-lock.json` pin 6 hash cũ + source commit `c8b2029` ✓.

## EV-ID-003 — Unit test cho coordinator `pq_lead.py`: `verified`

```sh
python3 tools/coordination/test_pq_lead.py     # stdlib unittest, mock git, state dir tạm
```

`Ran 26 tests … OK`. Phạm vi đã ép bằng test: `yes`/`no` nghiêm ngặt (`yesterday`, `true`,
thiếu field → đóng gate); hai chiều `GATE_CONFLICT`; ACK từ chối short SHA, SHA ngoài
lịch sử design, SHA không có task file và **không ghi state** khi từ chối; `ack` không tham
số = SHA vừa fetch; `watch` tính cycle có rc≠0, chặn `--interval < 5`, dừng theo `STOP`;
`status` in `STALE/UNVERIFIED` khi fetch lỗi; `brief` chặn work order thiếu dòng `- scope:`
(không mặc định = được phép); khoá single-writer + phá khoá cũ; `git` timeout → `LeadError`.

## EV-ID-004 — Hành vi thật của tool trên repo thật: `verified`

```sh
PQ_LEAD_STATE=/tmp/pq-lead-smoke python3 tools/coordination/pq_lead.py fetch   # rc=0
… status                                                                        # rc=0
… ack deadbeef                                                                  # rc=2
… ack c8b2029                                                                   # rc=2
```

* `fetch` tự phát hiện revision 3, ghi `inbox/20261016-075739-560106e.md`,
  in `NEW_DESIGN - -> 560106e … CHANGES_REQUESTED scopes={'runtime': 'no', 'test': 'yes', 'coordination': 'yes'}`.
* `status`: `code tip 10fd7aa…`, `code CI on tip: run #98 completed/success`,
  `design tip fetched 560106e…`, `- ACTION: the fetched design tip is newer than the processed revision`.
* `ack deadbeef` → stderr `rejecting ack: not a usable revision: 'deadbeef^{commit}'`.
* `ack c8b2029` (commit **của nhánh code**) → `rejecting ack: … is not in the fetched arena/00838eb9-pyquest history`.
  Sau cả hai lần, `state.json` **không** có `processed_scopes` → từ chối là không ghi gì ✓.
* `brief` theo từng scope (đọc từ dòng `- scope:` trong work order, đối chiếu scope design):

  | work order | scope | gate |
  |---|---|---|
  | PQC-001 | coordination | ALLOWED |
  | PQC-002 | runtime | **BLOCKED** (`runtime=no`) |
  | PQC-003 | test | ALLOWED |
  | PQC-004 | coordination (blocked_on: thiết bị) | ALLOWED về scope, vẫn chờ thiết bị |
  | PQC-005 | runtime (dependency) | **BLOCKED** |

## EV-ID-005 — Kiểm kê asset thumbnail đang chạy: `verified locally`

Đo bằng `/tmp/pqvenv/bin/python` (Pillow 12.3.0) trên `app/assets/images/`:

```
thumb_tower.webp       17656 B  (288, 288) WEBP
thumb_maze.webp        25976 B  (288, 288) WEBP
thumb_volcano.webp     19846 B  (288, 288) WEBP
thumb_observatory.webp 26676 B  (288, 288) WEBP
thumb_workshop.webp    26778 B  (288, 288) WEBP
thumb_house.webp       27340 B  (288, 288) WEBP
```

→ mọi file đang vuông, cạnh ≥256 px nên **test PQC-003 không cần đổi khi swap sang 512**
(khoảng trống giữa 256 và 512 là chủ ý để lát cắt art không kéo theo test khác).

## EV-ID-006 — PQC-003: `app/test/activity_sheet_thumbnails_test.dart` — `verified trên CI của commit c39a86f`

**Lệnh thật đã chạy (runner = `PyQuest CI` / check job, Flutter 3.47.7):**

| run | commit | kết quả |
|---|---|---|
| `38871660306` | `c39a86f` (commit chứa test) | `pub_get=0`, **`test=0`**, **`render=0`**, `analyze=1` với đúng 2 lint ở file mới |
| `38872131871` | `8e2111b` (chỉ sửa 2 lint) | **All steps passed** — `pub_get=0 analyze=0 test=0 render=0` |

Số liệu nguyên văn từ report: `flutter test --exclude-tags render` →
`00:26 +147: All tests passed!` (baseline trước đó là `+124` → **23 test của file mới đều chạy và pass**);
`flutter test --tags render test/render` → `00:08 +9: All tests passed!`.
Hai lỗi analyze đã sửa, không nới assertion:
`unnecessary_import` (bỏ `dart:typed_data` vì `services.dart` đã cung cấp) và
`unnecessary_non_null_assertion` (`DecorationImage.image` không null → bỏ `!` thứ hai).

**Không có Flutter SDK ở sandbox lead** → mọi khẳng định về Dart ở đây chỉ dựa trên CI của
đúng commit, không dựa trên "chạy local".

State mà test mô tả (tên để đối chiếu với render): `sheet_unlocked`, `sheet_locked_bug_hunter`.
Dữ liệu deterministic: status dựng trực tiếp, không mở `AppServices`/DB → không phụ thuộc
tiến trình máy chạy; `unlockLessonId: 'bug_3'` chỉ để ép nhánh CTA "đi tới bài học".

## EV-ID-007 — "Before" render thật, đọc từ CI của commit `10fd7aa`

CI: run `38868438592` (check `PyQuest check` → "All steps passed").
Toolchain in trong report: **Flutter 3.47.7 stable**, framework `abaf9c5237`,
engine hash `d8a2d6c768c334d53e16277f837970ffa1e2de81`, **Dart 3.13.5**, DevTools 2.60.0.

| Bước | Kết quả nguyên văn |
|---|---|
| `flutter analyze --no-fatal-infos` | `No issues found! (ran in 11.2s)` |
| `flutter test --exclude-tags render` | `00:18 +124: All tests passed!` |
| `flutter test --tags render test/render` | `00:17 +9: All tests passed!` |
| preview | 46 state, công bố dạng check run `preview\|<state>\|<chunk>\|<n>` |

Harness render: `start(tester)` đặt `physicalSize = 1170×2532 @3.0` (390×844 logical) và
`720×1280 @2.0` (360×640); `capture()` dùng `RenderRepaintBoundary.toImage(pixelRatio: 1.5)`;
`ci/publish_previews.py` đổi PNG → JPEG, resize về rộng ≤480 (hệ số 480/390 = 1.2308).
Ảnh state sheet "before" đã tải và xem thật: `a02_sheet_locked`, `b01_sheet_maze`.

Visual review (loại bằng chứng **khác** assert — review r3 §3.4):

* `b01_sheet_maze` — ô thumbnail nằm đúng slot 104×104 logical (≈128 px trong ảnh 480 rộng),
  bo góc 22 và viền ink 2.6 cắt nhẹ tàu lá và cờ ở góc phải-trên; bóng đổ cứng 4 px thấy rõ
  dưới khung. **Không có chữ nào bake trong bitmap** — mọi nhãn ("Mê Cung Robo",
  "Không cần biết Python", "Có Xưởng sáng tạo", "Tiến trình", sao 8) là widget Flutter.
* `a02_sheet_locked` (Bug Hunter / "Xưởng Bitsy") — state khoá render đúng như test giả định:
  panel khoá + icon lock + lý do, CTA `Đi tới bài học`, **không** có CTA `Vào …`; thumbnail
  vẫn cùng asset (khớp `thumb_workshop.webp`).
* Đo khách quan trên vùng lõi thumbnail của hai ảnh: stddev kênh
  `[43.9, 40.3, 31.7]` (maze) và `[63.0, 60.6, 59.1]` (locked) → không phải ô phẳng/placeholder.

## EV-ID-008 — Cách tái hiện test của PQC-003 (máy có SDK; đây cũng là cách lead xác nhận CI)

```sh
cd app
flutter pub get
flutter analyze --no-fatal-infos                       # phải ra "No issues found!"
flutter test test/activity_sheet_thumbnails_test.dart  # 23 test
```

Không cần thiết bị, không cần key; test không mở DB và không gọi mạng.
Nếu chạy trên máy có font khác, phần đo layout ở textScale 2.0 vẫn dùng font thật của app
(`loadAppFonts()`), nên số đo sát với bản build.
Đọc CI của một SHA cụ thể: `LEAD_RUNBOOK.md` §6 (dùng `gh api …/commits/<sha>/check-runs`,
không lấy "run gần nhất" của nhánh).

## EV-ID-009 — Dòng audience đã đồng bộ: `verified bằng diff`

`sed -n '7p' docs/PyQuest_Reffrence_Images/VILLAGE_2_5D_REDESIGN_BRIEF.md` khác bản cũ đúng
một dòng; `diff` với `git show 560106e:…` cùng dòng → **byte-identical** ✓ (thiết kế lại thành
"children under 12, consistent with `PRODUCT_VISION.md` §1", giữ câu "not a preschool playroom").
Không sửa ảnh, không sửa file khác trong thư mục reference của người dùng.

## EV-ID-010 — Flutter CI có lúc đỏ vì **chính harness render**; đã sửa trong scope `test`

Run `38873447429` @ `0968d1d` (commit **chỉ sửa docs**): `pub_get=0 analyze=0 test=0`
nhưng **`render=1`**, lỗi `A Timer is still pending even after the widget tree was disposed`
ở `render D: arcade games`. Chuỗi stack trỏ đúng nguồn: `_tick` của Catch Stars
(`app/lib/modules/catch_stars/catch_stars_module.dart:386`) hẹn
`Future.delayed(900ms)` cho cảnh "game over"; harness kết thúc ngay trong cửa sổ 900 ms đó
thì timer còn sống lúc teardown. Đây là **race của test**, phụ thuộc nhịp pump, nên ba run
trước đó (`c39a86f`, `8e2111b`, `f3f8210`) render vẫn `+9` xanh.

Cách xử lý: chỉ sửa `app/test/render/render_screens_test.dart::finish()` — gỡ cây widget
bằng `pumpWidget(SizedBox.shrink())` rồi pump thêm 1100 ms (> chu kỳ timer dài nhất) để
callback kịp chạy và tự thoát nhờ guard `if (!mounted) return`. Không đổi assertion, không
`ignore` lỗi, không đụng `app/lib/**`.

Xác nhận sau khi sửa: run `38873995396` @ `f73f852` → **All steps passed**
(`pub_get=0 analyze=0 test=0 render=0`, `No issues found! (11.3s)`, `+147`, render `+9`).

Ghi nhận cho design (không tự sửa, thuộc scope runtime): mini-game **không huỷ** delayed
callback khi dispose, chỉ dựa vào guard `mounted`. Chưa có đo lifecycle trên thiết bị để kết luận vô hại. Nếu sau này
`_finish` ghi DB/sau animation thì sẽ có callback chạy sau khi màn chơi đã đóng. Đề xuất
nhỏ cho gói UI/game riêng: lưu `Timer` và `cancel()` trong `dispose()`.

## EV-ID-011 — PQD-002 §B: test route thật + ngân sách byte — `verified trên CI của e98f826`

File: `app/test/activity_sheet_thumbnails_test.dart` (xem hash/line count tại review PQC-007). Thêm/thay so với bản r3:

* `group('route thật của sheet (showPQSheet) …')`: 7 ca. Mở sheet bằng **chính
  `showPQSheet`** của app ở `Size(360,640)@2` với `textScale 2.0` (đặt qua
  `platformDispatcher.textScaleFactorTestValue`, vì `MediaQuery` của route modal lấy từ
  *view* chứ không từ cây cha), `ensureVisible` rồi `tap` (giữ `warnIfMissed: true` — chạm
  không tới thì đỏ), và assert giá trị pop: `'open'` cho sáu activity, `'lesson:<id>'` cho
  Bug Hunter khoá.
* `unlockLessonId` **lấy từ data thật**: `BugHunterContent.load(rootBundle).unlockLessonId`
  (nguồn: `app/assets/data/bug_hunter_puzzles.json` → `packs[0].requires_lesson = mq1_03`),
  không còn `bug_3` tự đặt.
* Bỏ assertion `> 8 KiB` (review r4: proxy vô nghĩa). Thay bằng `test('ngân sách byte …')`:
  mỗi thumbnail ≤ 100.000 B, cả sáu ≤ 600.000 B, `> 0`; và test decode siết
  `256 ≤ cạnh ≤ 512` + vuông. Số thật của bộ hiện tại: 17.656 / 25.976 / 19.846 / 26.676 /
  26.778 / 27.340 B, tổng **144.272 B**, cạnh 288 → pass; bản 512 (tổng 112.938 B, cạnh 512)
  cũng pass ⇒ **test không chặn PQC-002**.
* `decodeAsset` dùng `try/finally` để `codec.dispose()` kể cả khi frame lỗi.
* Group có tên “ImageCache khi mở lần lượt sáu sheet”, nhưng code thực tế chỉ
  `cache.clear()` → `precacheImage` sáu asset trong `runAsync`; in `entries/bytes`
  (không có live), assert entries≥1 và bytes<64MiB. Chưa chứng minh cả sáu còn ở cache.
  Ghi rõ trong comment: đây là ImageCache của engine trên máy test, **không phải** RAM/GPU
  thiết bị thật.
* `group('vùng chạm của landmark …')`: dùng đúng công thức `_coverRect`/`toScreen` của
  `main_map_screen.dart:138` để tính `hitBox` ra px ở 360×640, assert mọi ô ≥ 48 px và
  right/bottom≤1.001 và kích thước dương; chưa assert left/top≥0 hoặc vùng sau clipping.

Kết quả CI thật (`PyQuest CI` run `38881345619` @ `e98f826`): `pub_get=0 analyze=0 test=0
render=0`, `No issues found! (ran in 11.0s)`, `flutter test` → **`+157: All tests passed!`**
(trước đó `+147`, tức 10 ca mới chạy và pass), render → **`+10: All tests passed!`**.

Không đổi workflow, không nới assert để được xanh. Lần chạy đầu của cùng thay đổi này
(`f8ff40c`) **đỏ** vì chính code mới: `analyze=1, test=1` — 3 lỗi compile (tham số named
không default, getter `ImageCache.currentLiveImages` không tồn tại) + 1 warning biến không
dùng; giữ nguyên trong lịch sử làm bằng chứng, sửa ở `e98f826`.

Số đo `imageCache` mà test in ra nằm trong log đầy đủ của job `check`; report của check-run
bị cắt giữa (`... [trimmed] ...`) và endpoint `actions/jobs/<id>/logs` redirect sang blob
storage ngoài danh sách host sandbox được phép → **lead không trích được con số ở đây** và
không nêu số nào cả. Muốn số: mở run `38881345619` → job `check` → dòng `PQC-003 imageCache:`.

## EV-ID-012 — Số đo hình học: đã sửa bởi review độc lập PQC-007

Source code `3b59f0b`, P02 `86513ca`. Số cũ (P02 1024²; crop ngang21%; bốn
hitBox390; cover640×645 cho ảnh vuông) **sai**, không dùng làm đầu vào runtime.
Chạy `python3 docs/implementation/coordination/reviews/PQC-007/audit.py` từ root;
output đã pin ở `reviews/PQC-007/facts.json`, gồm source hash và file:line.

Công thức `_coverRect`: scale=max(w/imageW,h/imageH), destination căn giữa.
Đơn vị logical px, giả định map constraints đúng full viewport, không nhân DPR.

| Khung | Nền thật1152×2064 vẽ ra | Rect theo thứ tự main_quest, robot_maze, dragon_jump, catch_stars, bug_hunter, achievement_house |
|---|---|---|
|390×844|471.070×844; crop **17.2097% chiều rộng nguồn**|117.767×190.744;153.569×121.536;148.387×140.948;110.701×104.656;141.321×122.380;122.478×140.948|
|360×640|360×645; crop **0.7752% chiều cao nguồn**, không crop ngang|90×145.770;117.360×92.880;113.400×107.715;84.600×79.980;108×93.525;93.600×107.715|

P02 là **896×1200**,112,018B; full RGBA8 lý thuyết4,300,800B.
- Cover full390×844 →630.187×844, còn61.8864% ngang.
- Cover full360×640 →477.867×640, còn75.3348% ngang.
- Ví dụ ảnh vuông1024² →640×640 trong360×640, còn56.25% ngang; **không phải P02**.
- HTML P02 dùng contain trong map-region, không full-screen cover. Không suy ra vị trí
  thực trong prototype từ phép tính giả định cover này.
- Sáu point anchors đã có trong app.mjs (%/100). Chưa có production hit rect/polygon.
- Thumbnail swap PQC-002 **không thay nền map**. Đừng dùng lỗi ratio để chặn lẫn hai scope.
- Cùng ratio chưa đủ giữ hitbox: landmark mới còn phải cùng vị trí hình học.

`ChunkyButton small`: face44 + padding depth4 **bên trong** GestureDetector ⇒ height48
nếu constraints cho phép, chưa đo width/hit-test. Không dùng “44<48” làm bằng chứng
sai target. RoundIconButton44 là case riêng (width44); cần widget measurements.

Contrast11.19/5.53/6.27/6.53 thuộc bốn token pairs của HTML P02, không phải audit Flutter.

## EV-ID-013 — Before-set render cho sáu sheet (`render J`) — cách lấy ảnh

Harness: `app/test/render/render_screens_test.dart` → `render J: activity sheet before-set
(six + locked)`, cùng `start()/tap()/capture()/finish()` như các render khác,
`toImage(pixelRatio: 1.5)`, publish qua `ci/publish_previews.py` (resize rộng ≤480 →
hệ số final480/390=1.2308, final480/360=1.3333; không phải DPR). State: `j00_sheet_main_quest`, `j01_sheet_robot_maze`,
`j02_sheet_dragon_jump`, `j03_sheet_catch_stars`, `j04_sheet_bug_hunter`,
`j05_sheet_achievement_house` (seed `rich: true`), `j06_sheet_bug_hunter_locked`
(seed người mới, 3 lần `welcome_next`), `j07_small_sheet_robot_maze`,
`j08_small_sheet_bug_hunter_locked` (360×640 @2).

```sh
CID=$(gh api "repos/Nthanhbadboy/PyQuest/commits/<sha>/check-runs?per_page=100" \
      --jq '.check_runs[] | select(.name|startswith("preview|j")) | {name, id}')
# ghép chunk base64 theo <state> rồi decode — xem recipe đầy đủ ở LEAD_RUNBOOK.md §6
```

Đã có thật: `render J: activity sheet before-set (six + locked)` chạy trong run
`38880849377` @ `f8ff40c` (render phase = 0, dù test phase đỏ vì lỗi compile nói ở
EV-ID-011) và `previews.txt` của run đó liệt kê **đủ 9 file**:
`j00_sheet_main_quest`, `j01_sheet_robot_maze`, `j02_sheet_dragon_jump`,
`j03_sheet_catch_stars`, `j04_sheet_bug_hunter`, `j05_sheet_achievement_house`,
`j06_sheet_bug_hunter_locked`, `j07_small_sheet_robot_maze`,
`j08_small_sheet_bug_hunter_locked` (mỗi file 2 chunk base64), cộng `a02_sheet_locked`
và `b01_sheet_maze` của harness cũ. Run xanh cuối `38881345619` @ `e98f826` giữ `+10` render.

Chưa làm (để không nói quá): **chưa** so pixel cặp before/after, vì asset after chưa tồn tại
(PQC-002 chờ duyệt art). Bộ ảnh này là "before" đúng nghĩa: ảnh của app hiện tại.

## EV-ID-014 — `pq_lead.py` thôi cứng PQD-001, theo con trỏ task một chiều

Review r4 §C nêu tool "theo dõi PQD-001 cứng". Đã sửa tối thiểu, không thêm framework:

* `TASK_IDS = ('PQD-002','PQD-001')`, `pick_task_id(args, state)`: `--task` > `tracked_task`
  trong state > id mới nhất; đường dẫn design/ACK suy ra từ id được chọn.
* `fetch` chỉ đi theo con trỏ tới id **lớn hơn** và **có file task thật** tại SHA đó
  (`POINTER_RE` + `parse_task`) → `PQD-001 r4 → PQD-002` hoạt động, không ping-pong,
  không nhảy tới file ma.
* `status` in `tracked task id` và báo `MISSING (phải nộp ACK cho task đang theo dõi)` khi
  nhánh code chưa có ACK cho đúng task — đó là cách phát hiện "ACK để cho có".

Unit test: `python3 tools/coordination/test_pq_lead.py` → **`Ran 30 tests … OK`**
(4 ca mới: `test_forward_pointer_is_followed_once`, `test_pointer_never_moves_backwards`,
`test_pointer_to_a_missing_file_is_ignored`, `test_explicit_task_flag_wins_over_state`;
fixture giờ chặn `PQ_LEAD_STATE` vào thư mục tạm nên không đọc state thật của máy).

## Chưa kiểm tra được — không được suy ra từ các mục trên

1. Render "after" của bộ 512 chưa tồn tại vì chưa có asset mới — xem mục 2.
2. Render "after" của bộ 512: phụ thuộc PQC-002, mà PQC-002 cần `runtime=yes` + người
   dùng duyệt art. Không tự thay asset để "có số liệu".
3. Bộ đếm `ImageCache` ở mức **precache per-key** đã có test và số đo đọc được từ
   `currentSize`/`currentSizeBytes` trong test (PQC-009); nhưng (a) số **live images** vẫn
   missing vì engine CI không có `currentLiveImages`, (b) log check-run bị cắt giữa nên không
   trích con số công bố được, (c) **bộ nhớ decode/GPU/RSS trên thiết bị** khi mở nhiều sheet
   vẫn chưa đo → **không** kết luận 512 px là rẻ hơn. W*H*4 không được dùng thay số đo.
4. Contrast mới có 4 cặp token trong prototype; **vùng chạm** của `ChunkyButton.small` đã
   đo bằng `RenderBox` trong test: mặt 44 + depth 4 padding **trong** hit area → 48 px cao
   (không còn là “44 px dưới sàn” như rev-1 từng nói); `RoundIconButton(size:44)` rộng 44 và
   depth cộng theo chiều dọc. Chưa có ruling thiết kế cho gói nút chung, chưa đo trên thiết bị,
   và chưa kiểm overlay/clipping/hit arbitration → **không** đổi widget trong PQD-002.
5. Giọng nói Gemini Live trên thiết bị (PQC-004), `flutter pub get`/`pubspec.lock` (PQC-005):
   vẫn cần phiên có emulator/SDK.
6. Ảnh PNG master/WebP export **không** được render lại bằng art mới: không có art mới,
   không có pixel mới để so.

## EV-ID-015 — PQC-007 đã tái kiểm độc lập ở nhánh design

Review `reviews/PQC-007/REVIEW.md`: đủ12 dòng A.1/A.2, source pin3b59f0b/design86513ca,
phép toán tái hiện, sửa cả kết luận hành vi/số đo. Không có external model delegate.
Coordinator30/30 PASS local Python, không có Flutter/ADB/emulator local.

GH run38881345619 head e98f826 success; check report chứa +157/+10 đã đọc độc lập.
Đã tải đủ9 JPEG before của e98f826, không chỉ dựa vào danh sách filenames từ run đỏ;
`reviews/PQC-007/ci-evidence.json` ghi check IDs/hash. Xem trực tiếp j01 và j08;
các ảnh còn lại chưa được nghiệm thu visual. Không có bộ after hay memory/device claim.

Trạng thái PQC-007 của design (`tasks/PQC-007.md`: `REVIEWED_CHANGES_REQUESTED`, yêu cầu
code lead **nhận patch** chứ không chỉ ghi ACK) đã được trả: patch docs được nhập thật
(`reviews/PQC-007/**`, `tasks/PQC-007/008/009.md`, `EVIDENCE.md` bản đã sửa), `tasks/PQD-002.md`
đã sửa số sai, board đã cập nhật — xem EV-ID-016.

## EV-ID-016 — PQC-009 (test-only) đã giao + nhập corrections PQC-007 có kiểm tra tính toàn vẹn

**Corrections được nhập, không chép tay.** Từ `d321e98` chỉ lấy các file docs/coordination
(không merge nhánh design): `EVIDENCE.md`, `tasks/PQC-007.md`, `tasks/PQC-008.md`,
`tasks/PQC-009.md`, `reviews/PQC-007/{REVIEW.md,audit.py,facts.json,ci-evidence.json}` +
9 ảnh `reviews/PQC-007/before/*.jpg`. Kiểm tra tính toàn vẹn sau import, chạy thật:

```sh
python3 docs/implementation/coordination/reviews/PQC-007/audit.py > /tmp/pqc007.json
cmp /tmp/pqc007.json docs/implementation/coordination/reviews/PQC-007/facts.json   # khớp
# 9/9 file trước khớp "sha256" + "bytes" ghi trong ci-evidence.json
```

`audit.py` đọc blob **đã pin** (`3b59f0b`) chứ không đọc working tree, nên việc nó tái hiện
trên nhánh này xác nhận số corrected, không phải xác nhận code của tôi. Bốn chỗ rev-1 tuyên
bố quá (1024²/56,25 %; `command_limit` hard cap; TalkBack không tới được; `ChunkyButton`
target 44) đã bị sửa ngay trong `tasks/PQD-002.md` và mục 3–4 ở trên.

**Test mới (chỉ `app/test/**`, gate `test=yes`):**

| File | Nội dung |
|---|---|
| `app/test/lesson_route_regression_test.dart` (mới) | 5 test: route map → sheet khóa → `sheet_go_lesson` → `MainQuestHomeScreen` (assert viền `PQColors.berry` trên card `mq1_03` = bằng chứng `openLessonId` tới screen), không `LessonScreen`, không đổi energy, không `lessonCompleted`; fixture `mq1_01`+`mq1_02` → tap card mới push `LessonScreen` và `energy.current` giảm đúng `config.cost('main_quest_lesson_first')` (=1); “Để sau” không phát `activityOpened`; characterization `Semantics(button:true)` của CTA vs sự vắng mặt khai báo ở `map_hit_*`; `_unlocked` không có đường vòng |
| `app/test/activity_sheet_thumbnails_test.dart` | nhóm cache đổi tên **+ đổi cách đo** sang `precache qua ImageProvider thật` (resolve/decode từng key, giữ `ImageStreamListener` khi đọc `currentSize`/`currentSizeBytes`, assert `entries >= 6`); `hitBox` test thêm `left/top >= 0` và phần còn nhìn thấy sau cover crop (`intersect`, ≥48x48); nhóm mới `kích thước chạm đo từ RenderBox thật` đo `ChunkyButton.small` (48 cao characterization) và `RoundIconButton(44)` ở textScale 1 và 2 |

Kỹ thuật đáng ghi lại cho đời sau (đều là lỗi thật đã trả giá):
`MainMapScreen._ambient` là `AnimationController..repeat()` (`main_map_screen.dart:38`) nên
**không** được dùng `pumpAndSettle()` trên map — bơm số khung cố định; teardown phải
`s.dispose()` + gỡ cây như `finish()` của harness render, nếu không `Future.delayed(900ms)`
của toast reward (`main_map_screen.dart:268-271`) nổ “Timer is still pending”; `Key('x')` là
`ValueKey<String>('x')` nên `find.byKey` khớp được key của app.

**Chưa có / không tuyên bố:** số `entries/bytes` cụ thể không trích được từ log CI (báo cáo
check-run bị cắt giữa, `actions/jobs/.../logs` redirect ra blob ngoài allowlist sandbox — xem
EV-ID-011); chưa chạy `flutter analyze`/`flutter test` local (không có SDK ở đây) nên mọi kết
luận xanh/đỏ chỉ lấy từ run CI trên đúng commit; `git show` là cách đọc nhánh design, không
merge; PQC-008 vẫn `BLOCKED` (runtime=no) và **không** được coi là xong vì PQC-009 đã characterize;
PQC-002 + art P02 vẫn chờ người dùng duyệt.

Kết quả CI của cùng lượt này (3 run, gồm 2 run đỏ và lý do từng cái) ở **EV-ID-017**.

## EV-ID-017 — PQC-009 trên CI: 3 vòng, số liệu thật đọc ở commit cuối

**Chuỗi CI (mỗi vòng là bằng chứng thật, không tường thuật suy đoán):**

| Run | Commit | Kết quả | Đọc từ báo cáo check-run |
|---|---|---|---|
| `38886724385` | `a572aa9` | **đỏ** | `flutter analyze`: 8 issues — 4 `error • Undefined class 'SemanticsProperties'` + 1 `warning • unnecessary_non_null_assertion` + 3 info; `test` = `+124 -2` (hai file **không load được**, không phải test logic fail); `render` `+10` |
| `38887445456` | `bb8cced` | **đỏ** | `analyze` = **No issues found!**; `test` = `+163 -1` (một test fail: `đã xong mq1_01+mq1_02: ...`); `render` `+10` |
| `38888232576` | `0d609f7` | **xanh** | `analyze` **No issues found! (ran in 10.6s)** · `test` **`+166: All tests passed!`** · `render` **`+10`** (10/10, vẫn đủ `j00…j08`) |

`+157 → +166` khớp đúng 9 test mới (7 của `lesson_route_regression_test.dart`, 2 của nhóm
đo `RenderBox`), nên không có test nào bị mất/đổi thành skip. Flutter `3.47.7` / Dart `3.13.5`.

**Hai bài học kỹ thuật đáng giữ (đều do CI dạy, không có SDK để thử local):**
1. `SemanticsProperties` **không** được export từ `material.dart` của SDK này → không được
   nêu tên type trong test; helper đọc `Semantics.properties` qua `dynamic` (`Semantics` thì
   có thật). Trước đó tôi đoán tên API theo trí nhớ và cháy analyze.
2. `openActivity` chèn toast reward vào **root overlay** sau 900 ms, mỗi toast sống 2.8 s
   (`main_map_screen.dart:268-271`, `reward_toast.dart:20-27`). Một test assert "chạm vào
   card khóa thì không có gì xảy ra" mà không canh cửa sổ này chỉ chứng minh... không có gì
   chạm tới nơi. Fix: `pumpFor(5s)` trước khi đo `hitTestable()`/tap, và tách test gộp thành
   ba test để **tên test** chỉ ra chỗ gãy (báo cáo check-run cắt giữa log, không đọc được
   message).

**Số đo characterization đã đứng trên CI:** `ChunkyButton.small` cao **48** (mặt 44 + depth 4
bên trong hit area) ở cả textScale 1 và 2, rộng ≥44; `RoundIconButton(size:44)` rộng đúng 44
và `height - width = 44*0.09`; sáu `hitBox` normalized nằm trong 0..1 **và** phần còn nhìn thấy
sau cover crop ≥48×48 ở 360×640. Cache: per-key resolve+decode qua `AssetImage`, `entries ≥ 6`
khi còn listener — **không** có số `live` (SDK không có `currentLiveImages`) và **không** trích
được `entries/bytes` công bố, vì `test.txt` trong báo cáo bị cắt giữa (giới hạn đã ghi ở
EV-ID-011; `actions/jobs/<id>/logs` redirect ra blob storage ngoài allowlist sandbox).

**Route đã chứng minh (test 1–3 + 2 fixture, theo decisions §6):** map → `map_hit_bug_hunter`
→ sheet khóa → `sheet_go_lesson` → `MainQuestHomeScreen` với card `mq1_03` được highlight
(bằng chứng `openLessonId` tới screen, không phải chuỗi pop), **không** `LessonScreen`,
**không** đổi `energy.current`, **không** phát `lessonCompleted`; fixture xong
`mq1_01`+`mq1_02` → card hết khóa, tap card mới push `LessonScreen` và energy giảm đúng cost
tính theo rule của `_open`; “Để sau” không phát `activityOpened`.

Không có số `entries/bytes` nào được công bố ở EV-ID-016/-017: kênh render log đã làm việc đó ở **EV-ID-018**.

**Không đổi gate:** `brief PQC-009` = ALLOWED(test), `brief PQC-008` vẫn BLOCKED(runtime=no);
PQC-002/art P02 vẫn chờ người dùng. Diff của cả ba commit chỉ nằm trong `app/test/**` và
`docs/implementation/coordination/**`; `audit.py` của design tái hiện khớp `facts.json` trên
nhánh này và 9/9 ảnh import khớp sha256+bytes.

## EV-ID-018 — PQC-009 phần còn hở: baseline keyboard + **số cache đo được**, sau 4 vòng CI

`0d609f7` xanh nhưng PQC-009 vẫn còn hai mục chưa làm: ý 4 (keyboard/Tab order) và ý 3
(số `entries/bytes` không trích được vì `test.txt` bị cắt giữa). cả hai đã đóng, và chuỗi
run sau là bằng chứng thật, kể cả bốn run đỏ:

| Run | Commit | Kết quả | Lý do |
|---|---|---|---|
| `38889441962` | `37b3a23` | đỏ | `sendKeyDownEvent(logicalKey: ...)` — SDK này không có named `logicalKey` (4 error) |
| `38889939855` | `f08eec7` | đỏ | `.usbHidUsage` không tồn tại trên `LogicalKeyboardKey` (2 error) |
| `38890358736` | `9b7e979` | đỏ | `.usbHidUsage` trả `int`, mà tham số là `LogicalKeyboardKey` (2 error) |
| `38890785888` | `e546f9b` | **xanh** | `analyze` **No issues found! (8.6s)** · `test` **`+167 All tests passed!`** · `render` **`+10`** |

`+166 → +167` = đúng một test mới (keyboard), không test nào bị bỏ/skip. Ba run đỏ **không**
phải hành vi app: là chữ ký API trong test của tôi → bài học “không đoán API” giờ nằm trong
comment của chính test đó.

**1) Baseline keyboard (mức widget, không phải kết luận thiết bị).** Test
`characterization keyboard: Tab không đặt focus vào landmark nào (hành vi hiện có)` bơm
6 lần Tab bằng `sendKeyDownEvent(LogicalKeyboardKey.tab)` và **kiểm chứng** từng lần bằng
`HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.tab)` — nếu sự kiện không
được ghi nhận là Tab thì test đỏ tại đó, không cho phép kết luận từ tổ hợp phím vô nghĩa.
Kết quả trên CI: focus node **không đổi** sau 6 lần Tab và `sheet_go_lesson` **không** bật.
Đây là baseline để PQC-008 phải làm *đảo ngược* (Tab tới được sáu địa điểm, Enter/Space mở
đúng hành vi tap, focus trả về launcher) — và nó **không** đóng PQC-008, không nói tới
TalkBack/Android.

**2) Số cache thật, lấy từ kênh render log (không cắt giữa).** `render J` là chỗ duy nhất mở
lần lượt sáu sheet qua route của app, nên phép đo `imageCache` được đặt ở đó, in một dòng:

```
PQC-009 imageCache khi mở lần lượt sáu sheet (cache của engine trên máy CI, KHÔNG phải
RAM/GPU thiết bị): j00=7entries/11501568B -> j01=7entries/11501568B -> ... -> j05=7entries/11501568B
```

Đọc đúng những gì nó nói (đã kiểm qua **ba run (kể cả hai run đỏ vì lỗi analyzer, render job vẫn chạy) — số giống hệt nhau**):
- **7 entries / 11.501.568 B ≈ 10,97 MiB** cho cả nền đảo + sáu thumbnail, và **không đổi**
  khi mở lần lượt sáu sheet → sáu ảnh này đã nằm sẵn trong cache từ `precacheMap`, mở sheet
  không nạp thêm. Phép đo này *không* chứng minh hành vi thải cache theo thời gian.
- Khớp số học **chính xác đến từng byte**: nền `1152*2064*4 = 9.510.912 B` + sáu thumbnail
  `288*288*4 = 331.776 B` × 6 = `1.990.656 B` → `9.510.912 + 1.990.656 = 11.501.568 B`,
  tức đúng bằng số đo. Kết luận hẹp mà chắc: bộ đếm `currentSizeBytes` của engine CI này
  tính theo RGBA8 của ảnh **đã giải mã**, không theo byte file asset.
- Vì vậy bộ 512 px của PQC-002: 6 * `512*512*4 = 1.048.576 B` = `6.291.456 B ≈ 6,00 MiB`,
  tức **+4.300.800 B ≈ +4,10 MiB** so với bộ hiện tại trên máy CI — *trùng* với con số
  review PQC-007 cảnh báo (1.990.656 → 6.291.456), nhưng ở đây là số **đo** trên kênh cache
  thật chứ không phải tích W*H*4 tự tuyên bố. **Không** được dùng làm RAM/GPU thiết bị,
  và **không** đủ để nói 512 px là rẻ hay đắt trên máy thật; quyết định PQC-002 vẫn thuộc
  người dùng + gate runtime.
- Giới hạn còn nguyên: `currentLiveImages` không tồn tại ở engine CI → số “live” vẫn
  **missing**; không sửa workflow/CI config để lách giới hạn log (work order cấm).

## EV-ID-019 — PQD-003 rev 2: source-map bảng giảng, contract v1, và **đã chạy** mẫu P03

Design push `4b87fef` = **PQD-003 revision 2** (53 files / 1394 insertions, `CHANGES_REQUESTED`,
gate `runtime=no / test=yes / coordination=yes`, `art_approval: pending-review`). Phản hồi ở
`tasks/PQD-003.md`, làm đúng 5 việc được giao, **không** sửa `app/lib`, không thêm dependency,
không port iframe/waypoint, không mở lại PQD-001/002.

**§A source map — đọc trực tiếp, mỗi dòng là một file:line đã mở:**
`lesson_screen.dart:59-99` `_tutorContext()` (14 trường, không tên/tuổi/id trẻ); `:103-113`
`_openTutor()` → `showTutorPanel()` → `showPQSheet<void>` (`tutor_panel.dart:23-36`) →
`showModalBottomSheet`
(`shared/widgets/common.dart:309-311`, keyboard inset `:317-319`); `CastRegistry.tutorForSkill`
quyết định identity theo skill của **bài** (nên "không hardcode Robo" đã đúng ở production);
`TutorContext`/`TutorReply` **không** có `planId/turnId/contextRevision/beats`;
`TutorProvider.complete` trả **`Future<String>`** và `TutorChatRequest.toJson` hardcode
`'max_tokens': 700` (`tutor_provider.dart:31`); `tutor_prompt.dart:60` là chỗ **duy nhất** code của
trẻ được làm mới; `tutor_session.dart:47,116,163` chỉ có cờ `_busy`, **không có request id**;
`tutor_transcript.dart:63,125` đã có `isFinal`/`interrupted` thật; `LiveAudioOutput` **không** có
`cancel()` — surface thật là `stopStreaming()`/`release()` (`live_audio_output.dart:122,133`),
teardown mic/socket ở `gemini_live_voice.dart:592-616`.

**Phát hiện chặn thiết kế (§C):** ngân sách P03 (≤12 beats × ≤8 ops × caption ≤600 ký tự) **không vừa**
`max_tokens: 700` của transport hiện tại → phải chọn trước: **v1 authored-only** (fixture đóng gói,
không đụng provider/quota — khuyến nghị) hay **v2 plan-channel riêng** (chạm provider/relay/config →
cần authorize riêng). Không có lựa chọn thứ ba "để AI viết vào `TutorReply.text`": text answer hiện tại
**không** điều khiển được canvas, và nhét JSON vào `text` sẽ đi vòng qua mọi lớp validate.

**§D** định nghĩa `contextRevision` + bảng chỗ bump thật; **§E** 4 work order nhỏ có allowlist
(`PQC-010..013`) — `PQC-010` vẫn **blocked** vì chạm `app/lib` (runtime=no); **§F** ma trận 14 negative
case kèm nơi chặn; **§G** nói rõ việc không làm và vì sao; **§H** 5 câu hỏi cho design/người dùng.

**§J đã chạy mẫu, không chỉ đọc:** `node --test tools/design/test_tutor_board.mjs` trên extract của
`4b87fef` → **11/11 pass**; run đầu fail 1/11 là do tôi extract thiếu `main_quest_ch1.json` (ghi nguyên
trạng). `source_sha256` của fixture P03 = `bead251d9f290db0…`, **khớp** cả tip tôi / `4b87fef` / `bb8cced`
→ authored plans không lệch dataset. Browser smoke **không** chạy vì nó ghi ảnh vào
`docs/design/tutor-board-prototype/evidence/` (vùng bằng chứng của design) + cần chromium; thay bằng
serve prototype cho người dùng bấm thật. Hai hở của prototype (không `contextRevision`; learner-ink
chưa có đường tấn công thật) nêu thành câu hỏi, **không** tự sửa hộ.

Không đổi gate nào của PQC-002/P02/PQC-004/PQC-005/PQC-008. Một ACK duy nhất cho `4b87fef`.

## EV-ID-020 — PQD-003 rev 3 (`9172ecd`): hiện trạng đa ngôn ngữ đo trên nguồn, không phải tuyên bố

Design rev 3 thêm yêu cầu của người dùng: **đa ngôn ngữ, mặc định theo hệ thống, đổi trong Settings**.
Phản hồi ở `tasks/PQD-003.md` §K. Toàn bộ dưới đây là grep/read trực tiếp trên `app/lib` tại tip tôi
(`6e636b8`), không suy từ tài liệu:

- `pq_l10n.dart:1-7` doc của chính file tự khai phạm vi: *"The rest of the island still speaks Vietnamese
  (its strings are written inline across the UI)"* → cast + tutor **không** phải bằng chứng toàn app.
- `PqLang.fromCode(null)` → `orElse: () => PqLang.vi` (`:23-24`) và `settings_service.dart:42,44` lưu đúng
  một khóa `ui_lang` → **`unset` và `explicit vi` không phân biệt được sau khi đọc**. Resolver 3 mức
  (explicit > system > fallback) không biểu diễn được trên schema này, nên bật "theo hệ thống" sau này sẽ
  **âm thầm đè** lựa chọn của người chơi cũ — bug migration, không bug UI. Đề xuất chính sách ở §K.5 câu 6.
- `pyquest_app.dart:57,66`: hai `MaterialApp` **không** `locale:`, **không** `localizationsDelegates:` →
  chuỗi của framework (toolbar chọn text, dismiss của sheet, thông báo semantics) luôn theo
  `MaterialLocalizations` mặc định. `pubspec.yaml`: `flutter_localizations`/`intl`/`generate:` = **0 kết quả**
  → thêm delegate là **dependency + build config**, cùng loại gate đang blocked (`PQC-005`).
- `platformDispatcher`/`systemLocale`/`Window.locale`: **0 kết quả trong `app/lib`** → app chưa bao giờ hỏi
  hệ thống; "mặc định theo hệ thống" chưa tồn tại ở mức nào. `settings_sheet.dart:78` đã có picker
  (`setLang`) nhưng chỉ đủ cho cast/tutor, và `auto` **không** encode được bằng enum 2 giá trị.
- Voice đi cùng nguồn: `gemini_live_voice.dart:287` → `GeminiLiveWire.languageCode(language)` với
  `language == 'vi' ? 'vi-VN' : 'en-US'` (`gemini_live_wire.dart:284`, nhét vào setup config `:46,55`)
  → resolve **một lần upstream**, nếu mỗi call-site tự suy thì UI/voice/board nói khác ngôn ngữ trong
  cùng một lượt.
- `main_quest_ch1.json`: lesson keys `challenge/id/number/py_line/skill/summary/steps/title`, step keys
  `code/id/text/type` → **không** có cặp `*_vi/*_en`: nội dung bài đang đơn ngữ, nên "toàn app" cần đổi
  **schema asset** (gate asset+runtime). `code`/`expectedOutput` phải **không** bị dịch; đề xuất: bản dịch
  của `expectedOutput` là **lỗi build** (chặn bằng test, `PQC-017`).
- Số nền cho coverage gate (đo bằng `grep -rn`, **không** phải test): **48** điểm `PqLang.vi ?` inline trên
  **6** file `app/lib`. Không có ý nghĩa "đã xong"; chỉ là mốc để gate `PQC-016` giảm dần theo file.

**Work order đề xuất:** `PQC-014` resolver+migration+persistence (test 3 case `unset`/`vi`/`en` + migration
trên dữ liệu cũ) → `PQC-016` ARB theo module + coverage gate port từng màn → `PQC-017` asset lesson song
ngữ; `PQC-015` delegate/pubspec ngay khi dependency được duyệt. **Không port màn nào trước `PQC-014`** —
đó chính là cách biến `default vi` thành explicit override. Board `PQC-010` không chờ chuỗi này; contract
board nhận thêm `locale` + quy tắc invalidate (đổi locale bump `contextRevision`, giữ code/note/ink/beat,
không dịch literal/engine output, không đổi grader) — §K.2.

Không audit hộ số liệu của design (`9 locale unit + 27 regression + 3 browser suites PASS` ở
`shared-l10n/evidence` là counterpart-reported, tôi chưa chạy); không tạo fixture `app/test/l10n/**` cho
type chưa tồn tại (§K.4). Gate PQC-002/P02/PQC-004/PQC-005/PQC-008 giữ nguyên. Một ACK cho `9172ecd`.

