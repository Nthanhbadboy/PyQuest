# Review r40 — Hai correction R38-A/B đã đạt

**DESIGN review exact `4fe3b7d0a1bf5f6dface1b04cbc4e2d7ee9d451f`.**
Ngày2026-10-18 · [Kết luận chính thức](../coordination/reviews/PQD-003-r40.md) ·
[Preview9screen studies](index.html).

## Disposition

**PQC-018: REVIEWED_WITH_LIMITS — ART_SCOPE_COMPLETE.**
R38-A vàR38-B đã đóng sau kiểm chứng độc lập. Giữ9concept và9screen studies;
không yêu cầu thêm vòng sửa018. **Không phải nghiệm thu Flutter/runtime/production.**

| Kiểm độc lập | Kết quả |
|---|---:|
| Browser configurations A+B |240+192 =432đạt |
| Font assertions |3,204đạt |
| Title/pill text và bounds |432đạt |
| B02 editor content/provenance/read-only/layout |48đạt |
| Editor line font assertions |144đạt, trong3,204 |
| Title collapse, inner/page overflow, header overlap, browser/request errors |0 |

Gallery smoke:9ảnh decode,28links HTTP200,390/360khôngoverflow,0errors.
[Gallery receipt](evidence/atlas-checks.json).

[Browser receipt](evidence/independent-browser.json) ·
[Static receipt độc lập](evidence/independent-static.json) ·
[Handoff CODE nguyên văn](../coordination/reviews/PQC-018-r3/code-handoff.md).

## R38-A

Ba case từng collapse đã sửa thành title/pill hai hàng, không giảm cỡ chữ hoặc
cắt title. Đã mở cả ba ảnh này để kiểm tra trực quan:

![Journal360EN2×](evidence/a01-w04-journal-not_following-360-en-2x-bar.png)

![Welcome390EN2×](evidence/a03-shared-welcome-first_visit-390-en-2x-bar.png)

![Welcome360EN2×](evidence/a03-shared-welcome-first_visit-360-en-2x-bar.png)

## R38-B

Editor có nội dung văn xuôi mẫu read-only và attribution hiển thị, tách khỏi
preview và version tray. Đã xem [VI390](evidence/b02-w12-creator-editor-product-390-vi.jpg)
và [EN360/chữ2×](evidence/creator-product-360-en-2x.jpg). Ba dòng khớp manifest ở48cases;
keyboard typing không thay nội dung. CTA disabled, không network/persist/publish.

**Giới hạn:** prose mock không phải editor Python/mê cung đã chạy. Preview là khung
minh họa; error/private/moderation vẫn là fixtures, không bằng chứng thực thi/lưu.
Không chuyển giới hạn đó thành một correction mới trong018 đã hoàn tất.

## Source bảo toàn

[Snapshot](code-snapshot/index.html) chứa215file theo **nội dung exact Git4fe3b7d**.
147file không đổi dùng relative symlink đến snapshotr38 bất biến,68file mới lưu trực
tiếp; [inventory](snapshot-manifest.json) ghi rõ. Khi tách/gửi thư mục này phải mang
cả r38 hoặc dereference symlinks; không coi đây là ZIP tự chứa độc lập.

Đối chiếu36archive entries với Git0990fbc,24archivefiles cũ nguyên vẹn;
9PNG/9prompt không đổi,16canonical refs/15runtime source blobs/9manifests đạt.
Correction đúngallowlist, app/CI không đổi. CODE static129/129 được kiểm receipt,
**không chạy lại CODE checker và không ghi đè receipt gốc**.

Gallery [25ảnh r38](../art-review-r38/index.html) giữ lịch sử trướccorrection;
disposition mới ưu tiên reviewr40 này. [W08](../world-travel-r37/README.md) và
[W14](../achievement-house-r39/README.md) vẫn là các study DESIGN riêng.

## Tiếp theo

PQC-011 vẫn **CHANGES_REQUESTED theo revision2/r34**, không được nghiệm thu nhờ
artPASS. CODE tiếp tục order đó theoallowlist hiện có; không ACK-only, không mở
runtime018 hoặc tự sửa deps/SDK/CI. R1/R4 vẫn chưa mở.

## Tái chạy

```sh
# Server phục vụ cả các font và snapshot bất biến, không phục vụ app source:
python tools/design/serve_art_review.py --port 8003 --landing r40
ART_REVIEW_ORIGIN=http://127.0.0.1:8003 \
NODE_PATH=/home/user/.cache/pyquest-r34-browser/node_modules \
LD_LIBRARY_PATH=/home/user/.cache/pyquest-r34-browser/libs/lib \
node tools/design/review_art_r40.cjs
python tools/design/validate_art_r40.py
```

Không chạy scripts dưới `code-snapshot/evidence/`: đó là artifact CODE cần giữ nguyên.
Headless HTML tests không thay device/screen-reader/runtime tests. Không tuyên bố
đã xem thủ công432cases;5capture mục tiêu đã mở và13capture độc lập được lưu.
