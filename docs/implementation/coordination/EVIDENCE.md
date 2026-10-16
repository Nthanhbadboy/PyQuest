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
| (commit sửa lint, xem dưới) | `c39a86f` + 2 dòng fix | cập nhật ở EV-ID-008 |

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

## EV-ID-008 — Cách tái hiện test của PQC-003 (máy có SDK)

```sh
cd app
flutter pub get
flutter analyze --no-fatal-infos                       # phải ra "No issues found!"
flutter test test/activity_sheet_thumbnails_test.dart  # 23 test
```

Không cần thiết bị, không cần key; test không mở DB và không gọi mạng.
Nếu chạy trên máy có font khác, phần đo layout ở textScale 2.0 vẫn dùng font thật của app
(`loadAppFonts()`), nên số đo sát với bản build.

## Chưa kiểm tra được — không được suy ra từ các mục trên

1. Render "after" của PQC-003 chưa tồn tại vì chưa có asset mới — xem mục 2.
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
