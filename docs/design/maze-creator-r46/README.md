# r46 — Xưởng Mê Cung, editor tương tác

**2026-10-18 · DESIGN_STUDY_DELIVERED · runtime NOT_AUTHORIZED**

![Xưởng Mê Cung r46](evidence/desktop-overview.jpg)

[Mở bản tương tác](index.html) · [Hợp đồng source/proposal](SPEC.md) ·
[Artwork & production gaps](ASSET_PLAN.md) · [8source pins](source-manifest.json) ·
[Trích source](SOURCE_EXCERPTS.md) · [Manifest](manifest.json)

Đây là **editor thực sự thao tác được trong HTML/JS**, không phảiB02prose editor
hay phác đồ read-only của r45. Một xưởng mới cùng họW01/r45, sáu bút, data grid
thật, vòng đời bản nháp và bàn thử khối lệnh. Không phải Flutter đã reskin.

## Thử nhanh

1. Chọn **Nước** rồi chạm một ô đất; chọn **Robo** để chuyển điểm bắt đầu.
   Không thể xóa nhầm/đè Robo hoặc rương. Chạm lại cùng endpoint là no-op.
2. **Kích thước** →4×4→xác nhận; **Hoàn tác** quay về bố cục trước.
3. **Lưu bản mẫu** → **Kho mẫu** để mở/xóa; sửa rồi **Tạo bản mới** để thấy
   guardgiữ/lưu/bỏ. Kho chỉ trongRAM, tải lại sẽ mất.
4. **Kiểm tra đường** chỉ kiểm tra lối tới rương. **Thử bằng khối lệnh** lưu
   sample trước rồi mở bàn thử. Với template gốc, ghép một khối lặp5lầnPhải,
   tiếp một khối lặp5lầnXuống; chạyJS đến rương, bỏ qua ngọc. Mẫu đạt2/3tiêu chí,
   không phải perfect và không nhận sao tiến độ. Không tự điền solution vào UI.
5. **Phác thảo Python** cho sửa chữ, không có Python runtime. Nút chạyJS không
   được dùng để giả thực thi Python.

Desktop có reviewer controlsVI/EN,100/130/200%,20fixtures, responseok/fail/deferred.
Chúng không thuộc productUI. Mobile chỉ hiện mànstudy; locale/scale vẫn kiểm được
qua APItest hoặc reviewerdesktop. Sản phẩm thật giữ systemlocale +Settingsoverride
đã có, không đổi sang reviewercontrol này.

## Những gì đã kiểm

| Evidence | Kết quả |
|---|---|
| [Model checks](evidence/model-checks.json) | **36PASS** +4.000edit/resize kiểm invariant |
| [Browser checks](evidence/browser-checks.json) | **240PASS** =20fixtures×2widths360/390×2localesVI/EN×3scales |
| Font proportional assertions | **4.908**, không shrink chữ để tránh overflow |
| Interaction flows | **23PASS**, gồm touch tap/swipe, mouse drag, keyboard, guards, async/error/retry, repeat run, result-save, reload |
| Touch2× corner placements | **16** real hits; cả hai locale vàwidth; thêm resize/save thực |
| Captures | **14** —13phonePNG +desktopJPEG |
| [Static receipt](evidence/static-receipt.json) | Source pins/excerpts, artifact hashes, local links, scope và contrast token tĩnh; không runtime execution |

**Giới hạn:** browserChromium153headless, không physicaldevice/screenreader/Flutter.
JSsimulation khác engineDart; khôngPython,DB,accountprogress,energyspend,rewards,
events hay serververification. “Đã giải · mẫu” là thắng bằng chuỗi lệnh của study,
không được dùng để accept011 hoặc xác minh tác phẩm của người dùng thật.

## Source và proposal được tách riêng

PinCODE`71b0fd3fd8fb07c73596ce089fa2e68f6fe87964`, baseDESIGN
`30a562f56faf85bbf7b3c7811b24eb56c007f7bc`. Template/size/limit/loops/BFS/custom
result/economy dựa source; markerprotection, explicitSave, dirtynavigation,
revisionproof và undo là đề xuất có đánh dấu trongSPEC. Không claim source đã có
hoặc đã sửa những guard đó. Không phát orderCODE cùnggói này.

[TaskPQD-009](../coordination/tasks/PQD-009.md) ·
[Tình trạng toànapp](../VISUAL_DESIGN_STATUS.md) ·
[PQC-011 waitr44](../coordination/reviews/PQD-003-r44.md).
018giữART_SCOPE_COMPLETE; R1/R4chưa mở. Toànapp còn các surfacepartial, production
artpack và runtimeport. Backgroundopaque và symbolicCSS/legacyRobo chưa thành
productiontiles/actor; chi tiết trongASSET_PLAN.

## Chạy lại

Từ rootrepo, dùng môi trườngbrowser hiện có; không càiSDKFlutter hoặc triggerCI:

```sh
python tools/design/serve_art_review.py --port 8007 --landing r46
node tools/design/test_creator_r46.cjs
NODE_PATH=/home/user/.cache/pyquest-r34-browser/node_modules \
LD_LIBRARY_PATH=/home/user/.cache/pyquest-r34-browser/libs/lib \
node tools/design/check_creator_r46.cjs
python tools/design/validate_creator_r46.py
```

Server đầu tiên là long-lived; trênArena dùng process tool. Testbrowser nhận
`ART_REVIEW_ORIGIN` nếuportkhác; code phía người xem chỉ dùng relativeURLs.
CachePlaywright/Chromium có thể không tồn tại ở môi trườngkhác; thiếucache không
được coi testsđãpass. Các receipthash ghim lầnchạy đã giao, rerun khácbrowser có
thể đổi metadata và cần regenerate manifest nếu muốn xuất bản lại evidence.

## Captures tiêu biểu

- [Board đã sửa](evidence/dirty-390-vi-1x-board.png)
- [Guard chưa lưu](evidence/unsaved-390-vi-1x-modal.png)
- [Đổi khung EN200%](evidence/resize-360-en-2x-modal.png)
- [Lỗi lưu EN200%](evidence/save_error-360-en-2x-rules.png)
- [Bàn thử](evidence/test-390-vi-1x-modal.png)
- [Kết quả thắng mẫu](evidence/test_won-390-vi-1x-result.png)
- [Lưới EN200%](evidence/new-360-en-2x-board.png)
- [Python sketch EN200%](evidence/code-360-en-2x-modal.png)
