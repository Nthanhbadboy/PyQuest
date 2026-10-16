# Bảng việc của nhánh code — PQD-001 và các work order phái sinh

Cập nhật: 2026-10-16, lead @ code tip `10fd7aa`, design đã nhận **revision 3**
(`560106e725e93c9385fd067d554693cf16e80a69`, verdict `CHANGES_REQUESTED`).
Gate theo scope của revision 3: **`runtime=no` · `test=yes` · `coordination=yes`**
(`art_approval: pending`).

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
| PQC-007 | Đối chiếu feasibility P02 (bảng A.1–A.3 trong `tasks/PQD-002.md`) với design + người dùng; chốt 6 câu hỏi | coordination | design trả lời §A.3; người dùng chốt hướng hub | `READY` — delegate được ngay, không sửa code | PQD-002 rev 1 |
| PQC-008 | Semantics/focus cho 6 ô landmark + test route `lesson:<id>` tới đúng bài | **runtime** | `runtime=no`; cần design bật gate vì chạm `main_map_screen.dart:165` | `BLOCKED` | PQC-007, ruling của §A.3 câu 5 |
| PQC-006 | Đồng bộ 1 dòng audience trong `docs/PyQuest_Reffrence_Images/VILLAGE_2_5D_REDESIGN_BRIEF.md` theo `PRODUCT_VISION.md:17` (under-12) | coordination | design đã sửa ở rev 3 trên tài liệu của họ và cho phép nhập đúng câu đó | `DONE` — **một dòng**, byte-identical với bản design (đã `diff` với `560106e`); không đổi ảnh, không đổi định vị | — |

## Delegate được ngay (mỗi dòng = một phiên agent khác, tự chặn nếu gate đóng)

0. **PQC-007** (không cần SDK, không cần gate): đọc `tasks/PQD-002.md` §A, kiểm lại từng
   `file:line` mà bảng dẫn, phản biện chỗ nào lead đo sai; kết quả ghi thành mục mới trong
   `tasks/PQC-007.md` + câu hỏi còn mở cho design.
1. **Chạy lại `brief` + đọc EV-ID và tìm chỗ nói quá** — delegate đối chiếu từng mục trong
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
