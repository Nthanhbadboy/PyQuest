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
callback khi dispose, chỉ dựa vào guard `mounted`. Trong app thật vô hại, nhưng nếu sau này
`_finish` ghi DB/sau animation thì sẽ có callback chạy sau khi màn chơi đã đóng. Đề xuất
nhỏ cho gói UI/game riêng: lưu `Timer` và `cancel()` trong `dispose()`.

## EV-ID-011 — PQD-002 §B: test route thật + ngân sách byte — `verified trên CI của e98f826`

File: `app/test/activity_sheet_thumbnails_test.dart` (443 dòng). Thêm/thay so với bản r3:

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
* `group('ImageCache khi mở lần lượt sáu sheet')`: `cache.clear()` → `precacheImage` sáu
  asset trong `runAsync` → in `entries/bytes/live` + assert `> 0` và `< 64 MiB`.
  Ghi rõ trong comment: đây là ImageCache của engine trên máy test, **không phải** RAM/GPU
  thiết bị thật.
* `group('vùng chạm của landmark …')`: dùng đúng công thức `_coverRect`/`toScreen` của
  `main_map_screen.dart:138` để tính `hitBox` ra px ở 360×640, assert mọi ô ≥ 48 px và
  nằm trong 0..1.

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

## EV-ID-012 — Số đo hình học cho feasibility (PQD-002 §A.2)

Tính bằng công thức của app (`kMapImageSize = 1152×2064`, `scale = max(w/imgW, h/imgH)`),
không phải ước lượng:

| Khung | Nền thật vẽ ra | 6 `hitBox` (rộng×cao, px) |
|---|---|---|
| 390×844 @3 | 471×844 (crop 21 % chiều rộng) | 118×191, 154×122, 113×124, 85×105, 108×93, 94×108 — **nhỏ nhất 85×105** |
| 360×640 @2 | 360×645 (crop 0,8 %) | 90×146, 117×93, 93×108, 85×80, 108×94, 94×108 — **nhỏ nhất 85×80** |
| 360×640 với nền **vuông** 1024² (prototype) | 640×645 | chỉ **56,25 %** chiều rộng còn thấy ⇒ mọi toạ độ chuẩn hoá cũ lệch |

Kết luận kỹ thuật (và là lý do PQC-002 không được "thay nền cho nhanh"): hitbox chỉ giữ
nguyên nghĩa nếu nền mới có **cùng tỷ lệ và cùng cách crop**; ảnh làng mới là vuông.
Cần design giao bảng toạ độ chuẩn hoá trên `village.webp` — tôi không tự đoán.

Không kiểm: `ChunkyButton small` = 44 px vẫn dưới sàn 48 px (giữ nguyên từ r3, chưa có
ruling); contrast của prototype **không** phải của app — các con số 11.19 / 5.53 / 6.27 /
6.53 là của `docs/design/first-play-prototype/evidence/contrast-check.json`, tự nó ghi
"selected opaque token pairs only", không áp dụng cho token hiện tại của PyQuest.

## EV-ID-013 — Before-set render cho sáu sheet (`render J`) — cách lấy ảnh

Harness: `app/test/render/render_screens_test.dart` → `render J: activity sheet before-set
(six + locked)`, cùng `start()/tap()/capture()/finish()` như các render khác,
`toImage(pixelRatio: 1.5)`, publish qua `ci/publish_previews.py` (resize rộng ≤480 →
hệ số 1.2308 ở khung 390). State: `j00_sheet_main_quest`, `j01_sheet_robot_maze`,
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
3. Bộ đếm `ImageCache`/bộ nhớ decode khi mở nhiều sheet (review §1 mục 512-vs-384 yêu cầu
   đo): cần Flutter SDK; lead không có số liệu, nên **không** kết luận 512 là rẻ.
4. Con số contrast và vùng chạm thật của `ChunkyButton` (`small` = 44 px < sàn 48 px theo
   charter): chỉ được sửa trong gói UI chung khi có quyết định design; chưa đo, chưa sửa.
5. Giọng nói Gemini Live trên thiết bị (PQC-004), `flutter pub get`/`pubspec.lock` (PQC-005):
   vẫn cần phiên có emulator/SDK.
6. Ảnh PNG master/WebP export **không** được render lại bằng art mới: không có art mới,
   không có pixel mới để so.
