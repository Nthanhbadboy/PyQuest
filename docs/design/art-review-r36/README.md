# PyQuest r36 — năm concept mới, screen studies cần sửa

**DESIGN review CODE `1053973da1ad11378f7263d7b13a4d61667133af` · 2026-10-18.**

Mở **[gallery review 21 ảnh](index.html)** qua live preview: 16 ảnh canonical r35
và5concept mới. Không thay catalog lịch sử r35; không coi21ảnh là21màn app đã làm.

## Kết luận

- **Giữ cả5concept** Journal, Settings, Welcome, Catch Stars/Robo, Bug Hunter/Bitsy.
- **Yêu cầu sửa screen studies Batch A**: scale chữ thực, header360, copy/IDs và
  bố cục scene-first. Không yêu cầu sinh lại5PNG.
- **Batch B còn4cảnh**: Friends/Invites, Creator Editor, phòng hoàn tất từW03,
  Miu cam nghỉ. CODE sửa A rồi tiếp tục B, commit riêng.
- **PQC-011 không đổi: CHANGES_REQUESTED.** Không runtime, animation, layer export,
  backend, CI hoặc production approval.

### Bằng chứng độc lập

| Kiểm tra | Kết quả |
|---|---|
| Exact package / sources | 54file nguyênbyte;16catalog hashes;5manifests;15source blob pins |
| Chromium153 | 240case,20state,2phone,VI/EN,1×/1.3×/2× |
| Overflow ngang | 0/240 |
| Chữ tăng đúng scale | **160case không đạt**: rem còn neo root16px |
| Header360 | **120case heading box lấn hit-box nút back5px** |
| Controls / CTA / footer | >=48px; CTA disabled; footer cuộn tới được |
| Browser errors | 0 |

[Review đầy đủ và correction R36-A/B/C](../coordination/reviews/PQD-003-r36.md).
[Work order018 revision2](../../implementation/coordination/tasks/PQC-018.md).
[Receipt browser](evidence/independent-browser.json) ·
[Receipt provenance](evidence/independent-static.json) ·
[Gallery smoke check](evidence/atlas-checks.json) ·
[CODE package gốc, không phải bản đã sửa](../art-completion-r36/code/README.md).

Các report PASS lịch sử trong package CODE chỉ là phép kiểm CODE đã chạy;
**không phủ quyết findings DESIGN**. Chạy240tổ hợp selector không tự chứng minh chữ
đã tăng. Browser report không phải Flutter/device evidence.

## Chạy audit snapshot

```sh
python tools/design/validate_art_r36.py
# Server: python tools/design/serve_art_review.py --port 8000
NODE_PATH=/home/user/.cache/pyquest-r34-browser/node_modules \
LD_LIBRARY_PATH=/home/user/.cache/pyquest-r34-browser/libs/lib \
node tools/design/review_art_r36.cjs
```

Browser script trả **exit2** cho defects hiện hữu, lưu JSON/captures riêng ở thư mục
này. Không sửa CODE package, không cài thêm app dependencies. Static validator đọc
Git objects nên cần các source commits có trong repository.

Năm ảnh đã được DESIGN mở riêng full-size. Full-size review record16ảnh của CODE
đã khớp canonical paths/hashes; checker không chứng minh hành vi nhìn ảnh. Ghi chú
camera/material/geometry/layer còn lại trong review và STYLE_SYNC r35 vẫn áp dụng.

Gallery smoke test:21ảnh decode,31links200, filters5/21/16/5, phone390/360khôngoverflow,
controls>=48 và0browsererrors. Đã mở xem overview/mobile captures sau kiểm. Đây là
kiểm trang review, **không** nâng disposition screenA. Script: `tools/design/check_atlas_r36.cjs`
với cùng NODE_PATH/LD_LIBRARY_PATH ở trên.
