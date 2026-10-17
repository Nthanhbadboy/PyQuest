# PQC-018 r38 — giữ9concept, còn hai sửa màn hình

**DESIGN review · 2026-10-18.**
A correction `ab0ae35eafebf8602ef714d85004ad4b744898a4`;
BatchB `0990fbcbf6045bd64244239e36ccbca8c8dc394b`.

Mở [gallery review25ảnh](index.html) hoặc [nine-scene CODE snapshot](code-snapshot/index.html).
W08 của DESIGN vẫn có [preview riêng](../world-travel-r37/index.html).

## Quyết định

- **Giữ cả9PNG**, không yêu cầu sinh lại. B đã bàn giao đủ4concept.
- **6screen studies giữ ở mức reviewed-with-limits:** Settings, CatchStars,
  BugHunter, Friends/Invites, BuiltRoom, MiuRest.
- **3screen studies còn hai findings:** Journal/Welcome dùng chung productbar bị
  ép title ởEN2× (**R38-A**); Creator chưa có editor surface (**R38-B**).
- **PQC-018 IN_PROGRESS**, không production approval.011 vẫnCHANGES_REQUESTED.

### Bằng chứng độc lập

| Phép kiểm | Kết quả |
|---|---|
| Provenance |145file nguyênbyte,28archive entries,16canonical records,15source blobs |
| A PNG |5/5 không đổi từ1053973; active A không bị commit B sửa |
| Browser |432cases =A240+B192,2phone,VI/EN,1/1.3/2× |
| Cỡ chữ thực |2,196assertions đạt |
| Page overflow / back-header overlap |0/432 |
| CTA / reviewer separation / footer |432/432 mỗi nhóm; controls>=48 |
| Product title collapse |**3cases**, gồm1internal overflow; pagewidth vẫn pass |
| Creator editor |**Chưa có**, không chỉ là chưa nối runtime |

[Ảnh lỗi WelcomeEN2×](evidence/welcome-bar-390-en-2x.png) cho thấy tiêu đề bị ép
thành cột chữ. B02 chỉ có labelEditor, preview3ôtrống vàversiontray; cần vùng
editor đọc được, không chỉ tên vùng.

[Review đầy đủ và gate correction](../coordination/reviews/PQD-003-r38.md) ·
[Work order018 revision3](../../implementation/coordination/tasks/PQC-018.md) ·
[Browser receipt](evidence/independent-browser.json) ·
[Static receipt](evidence/independent-static.json).

## Cách lưu và tái kiểm

`code-snapshot/` là **145file exact0990fbc**, không sửa receipt/manifests gốc.
Package1053973, catalog/evidence r35/r36 và W08r37 không bị ghi đè. CODE sửa trong
allowlist của chính CODE, không copy archive này trở lại working tree đang sửa.

```sh
python tools/design/validate_art_r38.py
# Server nếu chưa chạy: python tools/design/serve_art_review.py --port 8000 --landing r38
NODE_PATH=/home/user/.cache/pyquest-r34-browser/node_modules \
LD_LIBRARY_PATH=/home/user/.cache/pyquest-r34-browser/libs/lib \
node tools/design/review_art_r38.cjs
```

Browser checker hiện trả **exit2** cho findings đã ghi, không phải setup fail.
Không chạy scriptCODE trực tiếp trong snapshot vì chúng ghi lại receipt gốc.
Review gallery check riêng không phải screen acceptance.

Gói này không thực thi Flutter, gameplay, lưu/nhận thưởng, backend, AI hay commerce.
Cảnh/actor chưa có layer/rig/animation hoặc geometry đo được. Sáu studies được giữ
không có nghĩa là sáu màn app hoàn tất. Không giao thêm ảnh hoặc mở runtime để sửa
hai findings. Một correction commit018 là đủ scope tiếp theo.

Gallery đã kiểm riêng:25ảnh decode,41links HTTP200, bộ lọc9/25/16/9, phone390/360
không tràn ngang và0browsererrors. Đã mở overview/mobile captures. Tái kiểm bằng
`tools/design/check_atlas_r38.cjs` với cùng browser environment; đây không phải
acceptance của9screen studies.
