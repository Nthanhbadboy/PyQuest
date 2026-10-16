# Bảng việc của nhánh code — PQD-001 và các work order phái sinh

Cập nhật: 2026-10-16, lead @ code tip `3b59f0b` (+ lượt PQC-009). Design đã push
**PQD-002 revision 2** @ `d321e986b97c4e039d9a4f45d2ad3e26a172d5b6`: verdict cho bảng
feasibility rev-1 là `CHANGES_REQUESTED`, kèm `reviews/PQC-007/REVIEW.md` (phản biện từng
dòng) và `docs/design/first-play-prototype/IMPLEMENTATION_DECISIONS.md` (trả lời sáu câu
§A.3). Gate **không đổi**: **`runtime=no` · `test=yes` · `coordination=yes`**
(`art_approval: pending-prototype-review`) — quyết định thiết kế **không** mở gate runtime
và **không** thay người dùng duyệt art.
Bảng feasibility của rev-1 đã được sửa tận nơi trong `tasks/PQD-002.md` theo số của
`reviews/PQC-007/facts.json` (tôi chạy lại `audit.py`: output khớp 100 %).

Cột `scope` là **quyền sửa** (design cấp gì); cột `trạng thái` là **sẵn sàng làm**
(order có phụ thuộc/thiết bị nào chưa). `brief <id>` kiểm cột đầu, không kiểm cột sau.
Trạng thái: `READY` · `QUEUED` · `BLOCKED` · `IN_PROGRESS` · `READY_FOR_REVIEW` · `DONE`.

| id | Việc | scope | Gate đang giữ | Trạng thái | phụ thuộc |
|---|---|---|---|---|---|
| PQC-001 | Vô hiệu hoá exporter ghi đè baseline + tách test baseline | coordination | design đã tự vá ở rev 3; code branch chỉ xác minh | `DONE` (xác minh tại `560106e`, EV-ID-002: 11/11 test của design PASS) | — |
| PQC-002 | Thay 6 thumbnail bằng `exports/*_512.webp` | **runtime** | cần `READY_FOR_CODE` + `runtime=yes` **và** người dùng duyệt art ở 104 px | `BLOCKED` | PQC-001 ✅, PQC-003 (harness để có before/after) |
| PQC-003 | Test mở đủ 6 ActivitySheet + evidence trước/sau (chỉ `app/test`) | test | rev 3 cho làm ngay | `DONE` — CI run `38871660306` @ `c39a86f`: `test=0` với `+147` (23 test mới pass), `render=0` `+9`; lint đã sửa, bằng chứng ở EV-ID-006/-007/-008 | EV-ID-006/007/008 |
| PQC-004 | Đóng gate thiết bị cho Gemini Live trên Release APK | coordination (blocked_on: thiết bị) | cần phiên có emulator/thiết bị + nghe bằng tai | `BLOCKED` | `pyquest-release-apk` (run 93) |
| PQC-005 | Regenerate `app/pubspec.lock` cho nhóm dependency audio | runtime (dependency) | sandbox không có SDK; `pub get` của CI tự resolve 14 gói → cần quyết định có commit lock hay không | `BLOCKED` | — |
| PQC-007 | Đối chiếu feasibility P02 (bảng A.1–A.3) — phản biện độc lập từng `file:line` + số đo | coordination | design làm ở `arena/00838eb9-pyquest`; code **nhận corrections** và nhập `reviews/PQC-007/**` (audit tái hiện khớp, 9/9 ảnh khớp sha256) | `DONE` (verdict `CHANGES_REQUESTED` đã áp dụng; 4 over-claim bị rút — xem `tasks/PQD-002.md` §D, EV-ID-016) | — |
| PQC-008 | Semantics/focus cho 6 ô landmark **trên thiết bị** (TalkBack, Tab/Enter/Space, focus-return, duplicate node) — rev 2 đã **tách** phần route lesson sang PQC-009 | **runtime** | `runtime=no`; prompt mới cấm snippet API chưa kiểm chứng (`Semantics(actionLabel:)`, `SemanticsController`) | `BLOCKED` — chưa ai authorized; PQC-009 characterize mức code xong, **không** được tính là PQC-008 xong | design bật gate runtime đúng allowlist |
| PQC-009 | Route lesson thật + characterization geometry/cache/semantics/keyboard (test-only, `app/test/**`) | test | rev 2 mở: `ALLOWED for scope=test` | `DONE + delta rev 4 đã sửa` (keyboard per-Tab, content pack test; số CI của run mới ở EV-ID-021) — baseline CI **`38890785888` @ `e546f9b`**: `analyze` No issues found, `test` **`+167 All tests passed!`**, `render` `+10`; 8 test route/keyboard + 2 nhóm đo `RenderBox` + cache per-key + số cache đo qua render log; 6 vòng CI (4 đỏ vì đoán API / toast che chạm) ghi ở EV-ID-016/-017/-018; **rev 4 §V1** bắt 2 overclaim (keyboard chỉ assert sau 6 lần; 'đo RenderBox' thật ra là toán rect) → đã sửa + content pack test, EV-ID-021 | PQC-007 corrections ✅ |
| **PQD-003** | Tutor-first + bảng giảng tương tác (design **rev 4 @ `59f7023`**) | docs/contract | runtime=**no**, test=yes, coordination=yes, `art_approval: pending-review` | `RESPONDED` — `tasks/PQD-003.md`: §A source-map đọc trực tiếp; §B contract v1; §C **xung đột `max_tokens:700` vs ngân sách P03** (chọn authored-only hay plan-channel); §D `contextRevision`; §E work order `PQC-010..013` có allowlist; §F 14 negative case; §J `node --test test_tutor_board.mjs` **11/11** + hash fixture khớp tip. Không đổi `app/lib`/dep/iframe. **rev 4 @ `59f7023` đã audit + trả lời D1–D10/U1–U5/V1–V3/§L** → §M nhập quyết định (1..12 beats, 600 *code point*, atomic plan rejection, exact `sessionId+revision+turnId+locale` match, reduced-motion không nhảy beat, board ở `modules/tutor/board/**` ngoài sheet, fallback `en`, thứ tự 014→015→016), §F thành 20 dòng, và **sửa 2 overclaim của tôi** (per-Tab assertion; 'đo RenderBox' = toán rect) · EV-ID-021 | `PQC-010`/`014`/`015` vẫn **blocked** (runtime/dependency `no`); U1–U5 vẫn chờ người dùng |
| **PQC-014..017** | *Đề xuất (chưa được giao)*: `014` locale resolver+migration+persistence; `015` delegate + `flutter_localizations`/ARB (= **dependency**, cần duyệt); `016` ARB theo module + coverage gate port từng màn; `017` asset lesson song ngữ (không dịch `code`/`expectedOutput`) | runtime/asset/dep | tất cả **blocked** ở revision này (`runtime=no`) | `PROPOSED` — nghiệm thu đo được từng dòng ở `tasks/PQD-003.md` §K.3; mốc nền `48` điểm `PqLang.vi ?` / `6` file; **không** port màn nào trước `014` | design duyệt §K + user authorize dependency |
| PQC-006 | Đồng bộ 1 dòng audience trong `docs/PyQuest_Reffrence_Images/VILLAGE_2_5D_REDESIGN_BRIEF.md` theo `PRODUCT_VISION.md:17` (under-12) | coordination | design đã sửa ở rev 3 trên tài liệu của họ và cho phép nhập đúng câu đó | `DONE` — **một dòng**, byte-identical với bản design (đã `diff` với `560106e`); không đổi ảnh, không đổi định vị | — |

### Scope guard từ rev 4 §D (áp dụng cho mọi delegate sau này)

Ưu tiên sản phẩm **không** được thu nhỏ thành "app học có Tutor": giữ bạn bè/thi đấu/thưởng-danh hiệu/
động viên qua màn/mini-game (Product Vision §7, 11–13, 15–16; Game Design §6–10, 12; Arena brief).
Không thay NPC bằng người chơi thật, không fake leaderboard/reward, không bắt free play qua lesson,
không mở backend social/online hay đổi economy/quota trong patch board/locale. `Main Map` vẫn là hub.

### Bước tiếp theo của tôi ở branch này (không cần ai cho phép thêm)

1. Chờ design chốt §C/§B/§F — đặc biệt **v1 authored-only** hay **v2 plan-channel**; `PQC-010` không
   khởi động được nếu chưa chốt. Trong lúc chờ: **không** code board trong `app/lib`.
1b. Rev 3 (locale): chờ chốt chính sách di sản `ui_lang` (§K.5 câu 6) — câu trả lời quyết định
   `PQC-014` có cần migration hay không. Không tự ý bật system default, vì nó đè lựa chọn cũ của trẻ.
2. Khi được gật authored-only: `app/test/board/**` (fixture JSON + validator + golden render) làm
   **cùng một lượt** với type — không tạo test cho type chưa tồn tại (bài học 6 vòng CI ở EV-ID-018).
0. Mọi câu hỏi/đề xuất đang mở đã gom về **một file**: `HANDOFF_TO_DESIGN.md` (D1–D10 / U1–U5 / V1–V3),
   cross-link từ `tasks/PQD-003.md`. Trạng thái: `WAITING_FOR_DESIGN_REVIEW` cho D1–D10+V1,
   `WAITING_FOR_USER` cho U1–U5.

3. Publish số frame/cache của board qua **kênh render log** (`render.txt` không bị cắt giữa), không
   qua `test.txt`, và không sửa workflow để lách giới hạn log.

## Delegate được ngay (mỗi dòng = một phiên agent khác, tự chặn nếu gate đóng)

0. ~~**PQC-007**~~ **đã DONE** (design phản biện, code nhận corrections). Việc test-only
   kế tiếp là **PQC-009** — đã DONE trên CI `38888232576`; delegate mới **không** cần thiết cho phần đã
   được giao (rev 2 ghi rõ: một phiên code đang chạy có thể nhận PQC-009 trực tiếp).
1. **Đọc `IMPLEMENTATION_DECISIONS.md` @ `d321e98` rồi rà `EVIDENCE.md` tìm chỗ nói quá** —
   delegate đối chiếu từng mục trong
   `EVIDENCE.md` với lệnh thật (recipe CI ở `LEAD_RUNBOOK.md` §6); mục nào không tái hiện
   được thì hạ xuống `not run`, nếu CI đỏ thì sửa test chứ không sửa gate.
2. **Rà soát bằng chứng** — đối chiếu từng EV-ID trong `EVIDENCE.md` với lệnh thật;
   mục nào không tái hiện được thì hạ xuống `not run`.
3. **Prompt đã sẵn sàng cho phiên có phần cứng/SDK**: `tasks/PQC-004.md` (emulator + nghe
   bằng tai) và `tasks/PQC-005.md` (máy có Flutter SDK, chỉ báo cáo diff nếu `runtime=no`).
   `tasks/PQC-002.md` cũng đã có prompt " armed ": phiên đó chạy `brief PQC-002` trước, gate
   chưa mở là trả `BLOCKED` ngay — nên khi người dùng gật, việc nhảy được vào queue mà không
   cần viết lại mô tả.
4. **Việc KHÔNG giao**: bất kỳ sửa nào trong `app/lib/**`, `app/assets/**`, Android,
   dependency, gameplay, hay workflow CI (`runtime=no`). Delegate nào nhận order mà
   `brief` in ra `DO NOT START` phải trả `BLOCKED`, không tự nới.

## Việc đã xong ở các lượt intake (không phải work order mở)

* Fetch + pin design `b9a7cc8` (rev 1), `beb19a8` (rev 2), `560106e` (rev 3); đọc protocol,
  handoff, charter, village-kit README/manifest, audit, brief, `PQD-001-r3.md`.
* Kiểm chứng tài sản: **24/24 SHA-256 khớp**; 6 PNG 1024²; 12 WebP 256/512; exports
  156.030 B; 6 baseline runtime **khớp từng byte** với baseline đã lưu (EV-ID-001, -005).
* Chạy lại test của design tại rev 3 → 11/11 PASS, gồm 5 test hồi quy baseline (EV-ID-002).
* Sửa 4 lỗi coordinator mà review r3 §4 nêu + 1 lỗi fail-open tự phát hiện
  (`brief` mặc định scope khi work order thiếu `- scope:`); 26 unit test stdlib (EV-ID-003),
  hành vi thật trên repo (EV-ID-004).
* Bằng chứng "before" lấy từ CI run `38868438592`: analyze sạch 11.2s, test `+124`,
  render `+9`, 46 state preview; đã tải `a02_sheet_locked` + `b01_sheet_maze` về xem
  và đo stddev vùng thumbnail (EV-ID-007).
* Xuất bản ACK/delta: `124e89e`, `24e59a2`, `10fd7aa` (CI #97, #98 success).
* Không sửa runtime, không merge nhánh design, không xoá/thay file nào của working tree.

## Cách đọc số liệu ở lượt kế tiếp

```sh
python3 tools/coordination/pq_lead.py fetch && python3 tools/coordination/pq_lead.py status
python3 tools/coordination/pq_lead.py brief PQC-003   # hoặc brief BOARD để xem chỉ mục
```

`status` in ba dòng scope + `gate verdict` — đó là câu trả lời cho "được sửa gì, ở đâu".
`STALE/UNVERIFIED` trong dòng `checked at` → **không** dùng gate đó để mở việc.
Sau khi xử lý xong một revision: `ack <sha-đọc-rồi>`; tool từ chối short SHA và SHA
không thuộc lịch sử design, và không ghi state khi từ chối.
