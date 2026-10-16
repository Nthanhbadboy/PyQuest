# P03 — Tutor có bảng để giảng

**Prototype HTML tương tác, theo kịch bản; không phải Flutter, AI hay voice đã chạy.**
Phản hồi người dùng: Tutor dẫn từ đầu và cần bảng để viết/vẽ/giảng trong bài học;
chat hai người không thể là giao diện học chính.

## Xem/bấm thử

```sh
python3 tools/design/serve_world.py --port 8001
```

Mở Live Preview tại `/tutor-board-prototype/` (server root là P04). Cần serve cả
`docs/design` vì dùng `shared-l10n`. Từ làng → **Cùng Robo mở bảng**:
- Chọn Chữ & lời chào hoặc Số & phép cộng.
- Dùng trước/sau, Xem từng bước, Tạm dừng, Xem lại từ đầu. Beat chỉ thay sau thao tác
  hoặc timer demo3.3s; không giả là đồng bộ giọng nói.
- Tutor highlight từ/dòng, viết kết quả, vẽ mũi tên và nhóm vật đếm3+4.
- Khoanh chỗ này bằng chuột/bút/ngón tay, hoàn tác/xóa **nét của bạn**. Nét lưu theo
  từng bước; sang bước khác sẽ ẩn, quay lại sẽ hiện, Tutor không xóa nét đó. Tối đa
  60 nét/bước,300 điểm/nét. Có ô ghi chú thay thế, không bắt buộc vẽ.
- Sửa một dòng code và chạy thử; `print(Robo)` nhận gợi ý, `print("Robo thông minh")`
  có kết quả, `print(3 + 4)` khác `print("3 + 4")`.
- Chậm lại dừng playback; Giải thích cách khác dùng ví dụ soạn sẵn, không gọi model.
- Lời giảng bằng chữ nằm trong details phụ, không chiếm vị trí bảng.

Chỉ một mèo ambient đi dạo; không đụng/chặn landmark, không là nhiệm vụ bắt buộc.
Robo dùng xuyên suốt như companion minh họa; **không đổi CastRegistry production**.
OS prefers-reduced-motion **OR** setting local tắt các animation ambient; đổi OS cũng
được theo dõi. Page hidden/navigation dừng scheduler, không tự resume ở background.

## Sandbox nhỏ, không phải Python

`tryPrint` chỉ nhận một lệnh print chứa chuỗi đơn giản (không escape/newline) hoặc
phép cộng hai số nguyên0..99. Không dùng eval, không chạy Python/network/file/mic.
Các cú pháp khác nói rõ chưa hỗ trợ, không gán thất bại bài học. Source bài1/bài3 đã
pin hash trong lessons.json; kế hoạch giảng được soạn riêng. Bài3 demo chỉ khám phá
example, không thay bài multiplication/choice hay chấm điểm nguồn.

Không lưu bài/code/nét vào DB/localStorage; **chỉ preference ngôn ngữ được lưu**.
Không gửi câu hỏi/code/nét vẽ đi đâu, không cộng điểm,
energy, XP hoặc hoàn thành lesson. Tải lại mất state. Note là ghi chú cục bộ, **chưa
có AI đọc hiểu nét vẽ hay trả lời theo ghi chú**. Voice chưa tích hợp, không có mic.
Đây là các giới hạn của mẫu, không phải rút bỏ yêu cầu AI tương tác trong sản phẩm.

## Kiểm tra

```sh
node --test tools/design/test_tutor_board.mjs
# Cần server8001 và dependencies tools/design/package.json:
NODE_PATH=/path/to/node_modules node tools/design/smoke_tutor_board.cjs
```

Sandbox này dùng:
`NODE_PATH=/home/user/.cache/art-review/node_modules LD_LIBRARY_PATH=/tmp/chromium-libs/lib`
cho Playwright Core/@sparticuz Chromium. BROWSER_EXECUTABLE_PATH và GALLERY_URL có thể
override. Với Chromium hệ thống hợp lệ không cần thư viện /tmp nêu trên.

- 11 unit tests: fixture/source hash, replay, highlight/output, count objects, allowlist
  ops/limits, không sửa plan, print subset và reject code không hỗ trợ.
- Browser smoke: journey, drawing/undo/retention theo beat/topic, code/note giữ nguyên,
  retry, text vs addition, pause/navigation cancel, OS reduced-motion, keyboard Enter,
  viewport1440×1100 /390×844 /360×640, không overflow ngang, primary controls≥48CSSpx,
  không JS/HTTP error. Evidence JPEG đầy trang và JSON đi kèm.
- Đã sửa CSS class collision giữa body calm và label toggle khiến layout bị flex
  ngang; smoke hiện kiểm đúng reduced-motion trên phone để bắt hồi quy này.
- Chưa có real-device stylus/touch/TalkBack, font scale2.0, audio/barge-in hay AI safety
  integration test. Không suy từ desktop pointer/HTML kiểm qua máy thật.

## Nguồn asset

- village.webp và robo.svg copy đúng byte từ P02; nguồn AI-generated scene và SVG
  authored đã ghi ở P02 manifest. Không phải art user-approved mới.
- cat.svg là hình vector mới viết bằng code cho exploration, không lấy stock asset.
- Nunito Medium/ExtraBold/OFL copy từ P02 (gốc app assets). License giữ nguyên byte,
  gồm whitespace trong văn bản upstream.
- manifest.json ghi bytes/hashes và scope. engine/app/style là code prototype mới.

## Bàn giao

Đọc `../TUTOR_TEACHING_BOARD.md`: UX, lớp board, safe TeachingPlan, sync cue với voice,
context revision, safety/fallback và acceptance. Task `../coordination/tasks/PQD-003.md`.
Không copy engine JS/subset evaluator vào Dart hoặc bỏ pipeline voice/transcript đã sửa.

## Ngôn ngữ

Cài đặt → Theo hệ thống / Tiếng Việt / English, đổi UI/Tutor script/board ngay, giữ
bài đang làm. BCP47 regional matching, English fallback, lựa chọn lưu qua reload.
Xem `../shared-l10n/README.md` và `../LANGUAGE_AND_LOCALIZATION.md`; production Flutter
chưa triển khai, literal code/output của bài nguồn không bị dịch.

## Copy bàn giao production (chưa wire runtime)

`authored-copy.v1.json` cung cấp title/say/caption/altText VI+EN cho8beat, stable IDs,
source mapping và waitForLearner. Đây là content contract, không phải production
TeachingPlan; HTML vẫn dùng lessons.json + shared-l10n, không được tuyên bố đã kiểm
TalkBack từ file copy mới. Chạy `node --test tools/design/test_board_copy.mjs` (4 tests).
Ba browser smokes hỗ trợ `EVIDENCE_DIR=/path/to/own-output` để không ghi đè ảnh của design.
