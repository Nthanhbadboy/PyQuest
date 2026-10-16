# Bảng việc của nhánh code — PQD-001 và các work order phái sinh

Cập nhật: 2026-10-16, lead @ code tip `24e59a2`, design đã xử lý `beb19a8` (revision 2).
Mỗi dòng là một work order delegate được; chi tiết nằm trong `tasks/<id>.md`.
Trạng thái dùng 6 giá trị: `READY` (gate mở, làm ngay) · `QUEUED` (hợp lệ, chờ người
bấm) · `BLOCKED` (thiếu gate/uy quyền, đã ghi câu hỏi) · `IN_PROGRESS` ·
`READY_FOR_REVIEW` · `DONE`.

| id | Việc | Gate đang giữ | Trạng thái | phụ thuộc |
|---|---|---|---|---|
| PQC-001 | Vô hiệu hoá việc exporter ghi đè baseline + tách test baseline (`tools/design`) | design phải tự vá, hoặc uỷ quyền cho code branch vì file thuộc nhánh design | `BLOCKED` | PQD-001 rev 2, câu hỏi #2 trong ACK |
| PQC-002 | Thay 6 thumbnail bằng `exports/*_512.webp` | design chuyển task sang `READY_FOR_CODE` **và** người dùng duyệt art ở 104 px | `BLOCKED` | PQC-001 (giữ bằng chứng trước), PQC-003 (harness evidence) |
| PQC-003 | Test mở đủ 6 ActivitySheet + khung evidence trước/sau (chỉ `app/test`) | không phụ thuộc design; cần người dùng đồng ý "làm ngay" | `QUEUED` | — |
| PQC-004 | Chạy bảng kiểm giọng nói Gemini Live trên Release APK, đóng gate thiết bị | cần phiên có emulator/thiết bị thật + nghe bằng tai | `BLOCKED` | Release APK `pyquest-release-apk` (run 93) |
| PQC-005 | Regenerate `app/pubspec.lock` cho nhóm dependency audio | cần máy có Flutter SDK (sandbox này không có, không tự cài) | `BLOCKED` | — |

## Việc đã xong ở lượt intake (không phải work order mở)

* Fetch + pin design `b9a7cc8` (rev 1) và `beb19a8` (rev 2); đọc protocol, handoff,
  charter, village-kit README/manifest, audit, brief.
* Kiểm chứng tài sản: **24/24 SHA-256 khớp**; 6 PNG 1024², 12 WebP 256/512,
  exports = 156.030 B, alpha=false; 6 baseline runtime trên nhánh code **khớp từng byte**
  với baseline đã lưu → mapping không drift.
* Kiểm chứng điều kiện: brief AC#1 (Tutor speaker label) đạt ở mức code+CI
  (run #92: analyze sạch, `+124` test, render `+9`); bằng chứng thiết bị cho giọng nói
  **chưa** (9 ô `[ ]`); art approval **chưa có**.
* Xuất bản ACK + delta: `124e89e`, `24e59a2` → CI run #97 "All steps passed".
* Không sửa runtime, không merge nhánh design, không xoá/thay file nào của working tree.

## Cách đọc số liệu ở lượt kế tiếp

```sh
python3 tools/coordination/pq_lead.py status
```

Dòng `gate verdict` là câu trả lời duy nhất cho câu hỏi "được code chưa".
`INTAKE_ONLY` hoặc `GATE_CONFLICT` → lead chỉ đọc/đánh giá/ghi câu hỏi.
