# r52 — Mê Cung: kết quả, kỷ lục và ghi nhận tác phẩm

**2026-10-18 · DESIGN_STUDY_DELIVERED · không phải APK hoặc runtime acceptance.**

![Kết quả r52](evidence/desktop-overview.jpg)

[Thử tương tác](index.html) · [Source/proposal contract](SPEC.md) ·
[Source excerpts](SOURCE_EXCERPTS.md) · [Artwork/provenance](ASSET_PLAN.md)

## Đã thiết kế

- Tách điểm/sao **lượt này** khỏi **kỷ lục đã ghi nhận**. Lần đầu hoàn thành khác
  với kỷ lục mới; hòa hoặc chơi kém hơn không xóa kết quả tốt hơn trước đó.
- Panel ba bước: tới rương → lưu đúng bản → đối soát thông báo. Có pending,
  đang chờ, lỗi lưu, lưu được nhưng thông báo chưa đủ và hủy chờ.
- Lời nhắc kỹ năng là điều vừa luyện tập, không tự dựng cấp độ/XP/mastery.
- Hộp thông báo badge/quest/energy/unlock/item: xem lần lượt, xem tất cả,
  để sau/mở lại. “Đã xem” chỉ đổi trạng thái đọc, không nhận thưởng hoặc tem.
- Kết quả custom maze: report thắng chưa bằng saved verification; phân biệt
  bản đã chạy với bản đang sửa, không áp callback cũ vào tác phẩm mới.
- Scene2,5D mới: Robo bên rương mở trong vườn, đồng bộ r50. Số sao/điểm/nhãn
  trạng thái là DOM thật, không bake vào minh họa.

## Cách xem

```sh
python tools/design/serve_art_review.py --port 8010 --landing r52
```

Preview **Mê Cung · Kết quả và ghi nhận thành tích**. Nút ☷ chọn19fixtures,
VI/EN, chữ100/130/200%; chọn phản hồi complete/partial/error, giữ và giao callback.

Thử `lower` để so40điểm lượt này với100điểm/3sao đã giữ; `partial` để đối soát mà
không tăng plays lần nữa; `rewards` để xem đủ5loại notice; `custom-pending` → giữ
phản hồi → đối soát → mô phỏng sửa bản → giao callback cũ để thấy proof bị từ chối.

**Nút “Đối soát biên nhận mẫu” chỉ giao fixture DESIGN trong RAM.** Không chạy
Python/game engine, database, event bus, save progress hoặc award service.
Navigation mở sheet báo điểm nối; link sang r45/r46 là trang độc lập, không chuyển
state hay trừ năng lượng. Reload mất RAM. Không có retry API/idempotency backend
được triển khai bởi r52; đó là đề xuất contract phải có order runtime riêng.

## Bằng chứng

- [Model](evidence/model-checks.json): **26checks +1.000record comparisons**.
- [Browser](evidence/browser-checks.json): **342cases**, **3.420font assertions**,
  **18flows**, **12captures**; Chromium153.0.8010.0, không page/request error,
  không external request. Matrix19fixtures ×3viewports ×2locales ×3scales.
- [Static](evidence/static-checks.json): source pins, file/dependency/tool hashes,
  local links và receipt-input hashes. [Manifest](manifest.json).
- Model là logic proposal JS, không Dart parity, SQLite transaction test hoặc
  chứng minh exactly-once. Browser không thay Flutter/device/screen-reader tests.
  Ảnh mobile/200% chỉ là một vị trí cuộn; test có thao tác cuộn tới nút để kiểm
  khả năng tiếp cận bằng pointer, chưa chứng nhận native accessibility.

Chạy lại từ repo root:

```sh
node tools/design/test_maze_result_r52.cjs
# Cần playwright-core1.64.1 + @sparticuz/chromium153.0.0 và system libs phù hợp:
node tools/design/check_maze_result_r52.cjs
python tools/design/validate_maze_result_r52.py
```

`ART_REVIEW_ORIGIN` cho test runner mặc định `http://127.0.0.1:8010`; browser UI
chỉ URL tương đối. Tool/cache không được commit như dependency của app.

## Phối hợp

[PQD-013](../coordination/tasks/PQD-013.md), DESIGN only. Source pin
`bcf2bfc5088ca80f1a6f0fd1d2211032f5ce416a`; đọc source không nghiệm thu CODE011.
Đã đối chiếu nhánh CODE cuối đợt: thêm `0d001f0de9186454eda7f3e71d409c68d4b10dbd`,
chỉ integration test và taskdoc; source pin liên quan r52 không đổi. Không query
hay chạy lại CI trong đợt này, chưa review correction để nhận011.
[Observation](partner-observation.json).

Không sửa app/CI/deps, không giao CODE thêm runtime work. Sau r52, Maze có thêm
study cho các surface còn thiếu nhưng chưa production port/transaction authority.
Hướng thiết kế tiếp: gameplay và kết quả Dragon Jump/Catch Stars, thay vì tiếp tục
coi toàn bộ app đã xong chỉ vì chuỗi study Maze đã nhiều hơn.
