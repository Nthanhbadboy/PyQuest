# Ngôn ngữ chung cho mẫu P03/P04

Đáp ứng tương tác mẫu cho yêu cầu: **đa ngôn ngữ, mặc định theo hệ thống, đổi được
trong Cài đặt**. Phạm vi HTML review prototypes, không phải production Flutter.
Contract toàn sản phẩm: [`../LANGUAGE_AND_LOCALIZATION.md`](../LANGUAGE_AND_LOCALIZATION.md).

## Thử ngay

```sh
python3 tools/design/serve_world.py --port 8001
```

Mở root Live Preview → nút bánh răng **Cài đặt → Ngôn ngữ**. Hoặc vào
`/tutor-board-prototype/` để xem P03 độc lập. Phải serve cả `docs/design`, không
serve một thư mục prototype riêng vì cả hai dùng module/CSS chung này.

- Mặc định `system`: dùng `navigator.languages` theo thứ tự; vi-VN → vi, en-GB → en;
  không có ngôn ngữ hỗ trợ → English và báo fallback trong Settings.
- Chọn system/vi/en, áp dụng tức thì. Chỉ lưu preference vào localStorage key
  `pyquest.prototype.language.v1`, không tự lưu locale resolve từ hệ thống.
- Lắng nghe `languagechange` và `storage`; explicit choice không bị OS ghi đè.
  Missing/corrupt preference → system; lỗi lưu báo chỉ có hiệu lực trong phiên.
- Giao diện, labels/aria/title/placeholder, lời Tutor script và board explanations
  đổi cùng nhau. Native dialog có label, Escape và trả focus về nút mở.
- Không dịch code/pre/textarea, note/ink hay tên riêng. Output literal giữ nguyên;
  trạng thái “Chưa chạy” được dịch tường minh, không nhầm là output của code.
- Parent gửi thêm preference trên lifecycle bridge đã kiểm origin + source; iframe
  vẫn đồng bộ khi storage bị chặn. Đổi ngôn ngữ dừng playback, không reset beat/code/
  note/ink hay route. Reload vẫn mất bài/ink như trước; chỉ ngôn ngữ được lưu.

## Cấu trúc / giới hạn

- `locale-core.mjs`: resolver thuần và template interpolation.
- `en.mjs`: catalog prototype, dùng copy nguồn VI làm key. Đây là adapter tạm cho
  hai mẫu có sẵn, **không phải kiến trúc stable ARB IDs của Flutter**. Copy mới phải
  thêm/review bản dịch; unknown copy giữ nguyên, không gọi dịch online.
- `locale.mjs`: DOM text/attribute adapter, cache nguồn để đổi VI↔EN, Settings và events.
- `settings.css`: desktop/mobile, dùng Nunito đã có ở P03.
- `evidence/`: 5 JPEG từ browser (Settings EN desktop/390/360, bảng EN, Settings VI390)
  và JSON kết quả. Screenshot toàn trang có thể dài hơn viewport, backdrop của dialog
  chỉ phủ viewport thật, không phải viewport dài bằng ảnh.

Không AI/voice thật; không dịch toàn bộ dataset, không chạm runtime app, không kiểm
RTL/thiết bị thật. Literal tiếng Việt trong bài nguồn được giải thích bằng English
thay vì thay nội dung bài và grader. P02 là artifact lịch sử, chưa dùng adapter này.

## Checks

```sh
node --test tools/design/test_locale.mjs tools/design/test_living_world.mjs tools/design/test_tutor_board.mjs tools/design/test_first_play.mjs
NODE_PATH=/path/to/node_modules node tools/design/smoke_locale.cjs
NODE_PATH=/path/to/node_modules node tools/design/smoke_living_world.cjs
NODE_PATH=/path/to/node_modules node tools/design/smoke_tutor_board.cjs
```

Server8001 chạy trước. Dependencies pin ở `tools/design/package.json`. Sandbox dùng
`NODE_PATH=/home/user/.cache/art-review/node_modules LD_LIBRARY_PATH=/tmp/chromium-libs/lib`.
Suite locale bỏ flag Chromium `--single-process`: browser package này bị đóng khi
đóng rồi mở context kế tiếp trong single-process; không phải lỗi UI ứng dụng.

Kết quả: **36 Node tests PASS** (9 locale +27 hồi quy). Ba browser suites PASS.
Suite cũ đặt `locale:'vi-VN'` rõ ràng, giữ nguyên assertions; suite mới kiểm English
và system/default độc lập, không dùng preset storage để né mặc định hệ thống.

Browser locale: en-GB/vi-VN/unsupported ja-JP, no default storage write, manual/reload,
reset system, languagechange, manual ignores OS, corrupt preference, cross-tab,
parent/iframe, denied storage, code literal/output unchanged, giữ note/ink/beat,
route không reset, Escape/focus return, EN phone390×844/360×640 và desktop1440×1100.
Không coi kết quả này là acceptance Flutter/AI/TTS hay review bản dịch với trẻ thật.
