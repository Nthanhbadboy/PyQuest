# Ủy quyền ba gói nền — 2026-10-16

## Quyết định của người dùng

Sau khi design đã nghiệm thu delta4315d39 và publish verdict907617a, người dùng trả
lời câu hỏi **“Bạn cho phép agent code bắt đầu phạm vi nào?”** bằng lựa chọn:

> **Mở cả 3 gói nền (đề xuất)** — Cho sửa runtime theo từng gói: bảng giảng độc lập,
> resolver/migration ngôn ngữ, và Flutter localization/dependencies tối thiểu.
> Review riêng từng gói; không mở các task art, voice, gameplay hay backend khác.

Đây là quyết định trực tiếp mới. Không phải suy từ “commit rồi”, click xem preview,
CI xanh, quyền sáng tạo art hay một ACK của agent.

## Phạm vi có hiệu lực — PQD-003 revision6

| Gói | Runtime | Dependency | Thứ tự / giới hạn |
|---|---|---|---|
| PQC-010 | yes | no | Board model/validator/renderer độc lập, authored/caption-only; chưa wire LessonScreen/AI/voice. |
| PQC-014 | yes | no | Preference/resolver/raw migration/persistence; không dịch toàn UI. |
| PQC-015 | yes | yes, chỉ locale | Sau014 CI xanh: Flutter delegates/ARB generation/app root; chưa port toàn app. |

Các file/path được sửa và nghiệm thu nằm trong ba work order dưới
`docs/implementation/coordination/tasks/`. Ngoài allowlist vẫn chưa được cấp quyền.
Thực hiện010 →014 →015, commit/evidence riêng; gửi review từng gói, không cần chờ
một vòng hỏi lại quyền đã cấp để chuyển gói tiếp theo nếu prerequisite đã xanh.

**Không mở:**002/art512 và map footprint mới,004/device voice,005/dependency blanket,
008/map accessibility runtime,011/lesson integration,012/voice cue,013/AI plan,
016/full UI port,017/lesson assets, backend social, economy/grader/progression,
platform/CI workflow hoặc mọi package upgrade ngoài closure tối thiểu cho015.

“Không mở” là ranh giới lượt này, không bỏ mục tiêu Tutor AI, đa ngôn ngữ toàn app,
bạn bè/Arena/mini-game/thưởng. Design tiếp tục thiết kế các luồng đó song song.

## Scope guard — không mở nhầm task cũ

Đã đọc `tools/coordination/pq_lead.py` tại code4315d39: do_brief runtime chỉ kiểm
cờ global/runtime+READY_FOR_CODE, **chưa kiểm work-order ID hoặc BLOCKED của order**.
Vì vậy không được dùng tool cũ với header r6 để suy rằng008/005 được phép.

Giao patch `patches/scoped-runtime-r6.patch`, chỉ sửa tool/test đã có trên code
branch. Whitelist010/014/015 và dependency015 nằm trong header PQD-003 r6; brief
mới yêu cầu ID chính xác, source_task đúng, order READY_FOR_CODE, explicit dependency
requirement. Missing/malformed/wildcard list đều đóng. Không xây runner/delegation
framework mới và không tuyên bố tool tự gọi được agent.

Agent code nhập patch ở scope coordination trước, chạy tests và brief cho cả gói
được phép lẫn bị chặn rồi mới sửa app. Gate là hướng dẫn kiểm soát công việc, không
là sandbox enforce mọi file diff: vẫn phải tự kiểm allowlist và reviewer kiểm diff.
Fetch revision mới trước mỗi gói; không dùng cached/offline verdict làm quyền mới.
