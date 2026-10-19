# PyQuest — Hải đồ & hành trình đi đảo / r37

**DESIGN làm riêng W08 theo yêu cầu user, không trùng phần CODE đang làm.**

Mở **[bản thử tương tác](index.html)** trong Live Preview. Có bản
[phone riêng](index.html?phone=1) và [phone EN2×](index.html?phone=1&lang=en&scale=2).

## Đã thiết kế

- **Một cảnh hải đồ 2,5D mới**, dựa trên W01 và W08 published; không sửa ảnh canonical.
  Ba đảo trong một vùng biển, không route/text/boat bake vào ảnh.
- **Bản đồ chọn được + danh sách tương đương**. Public/free, personal island và
  optional content pack có nhãn riêng; không biến mọi đảo thành paid map.
- **19 trạng thái**, từ chọn đích/điều kiện/quyền tới tải, hủy, lỗi, cập bến, thu hồi
  và quay về. Bến nguồn/đích tách rõ; đi thuyền không tiêu năng lượng hay nhận thưởng.
- Copy VI/EN, chữ1×/1.3×/2× tăng thật, controls48px, calm và OS reduced motion.
- [Spec bố cục/state/authority/layer plan](SPEC.md), [anchors minh họa](anchors.json),
  [manifest nguồn/hash](manifest.json), [prompt sinh ảnh](assets/prompt.txt).

## Thử nhanh

1. Chạm **đảo2** hoặc chọn **Danh sách → Vườn Nhỏ**.
2. **Xem hành trình → Lên thuyền**.
3. Mẫu tự trả kết quả tải sau1100ms; chọn **Bỏ qua chuyển cảnh** để mô phỏng cập bến.
4. **Quay về làng** để kiểm hành trình ngược.

Trong bàn review bên phải, tắt “Tự trả kết quả tải mẫu” để thử **hủy**, **trả lỗi tải**,
**gửi phản hồi cũ** hoặc **thu hồi quyền mẫu**. Chọn fixture để xem các trạng thái
chưa có adapter thật như quyền chưa xác minh/thiếu điều kiện. Toolbar này không
phải một phần giao diện cho trẻ.

## Kiểm chứng

| Phạm vi | Kết quả |
|---|---|
| Browser Chromium153 | **456/456 cases**:19states ×2phone ×VI/EN ×3scale ×map/list |
| Geometry/typography | 0tràn ngang, chữ tăng đúng tỷ lệ, controls>=48px, header không overlap, footer tới được |
| Browser interaction | **12 flows** đạt; không page/request errors, không external requests |
| Reducer mô phỏng | **16 checks** đạt: cancel/late response, single arrival, nguồn khi lỗi, quyền/offline, không economy |

[Browser receipt](evidence/browser-checks.json) · [Reducer receipt](evidence/model-checks.json).

```sh
node tools/design/test_travel_r37.cjs
python tools/design/validate_travel_r37.py
# Preview riêng: python tools/design/serve_art_review.py --port 8001 --landing w08
# Checker cũng có thể dùng server review8000, cùng serving scope; hoặc đặt
# ART_REVIEW_ORIGIN=http://127.0.0.1:8001 trước lệnh node.
NODE_PATH=/home/user/.cache/pyquest-r34-browser/node_modules \
LD_LIBRARY_PATH=/home/user/.cache/pyquest-r34-browser/libs/lib \
node tools/design/check_travel_r37.cjs
```

## Ranh giới — không gọi lẫn thiết kế và app

Đây là HTML và dữ liệu mẫu **chỉ trong bộ nhớ**. Không tải gói thật, mua hàng, lưu dữ
liệu, mở app route hoặc cấp quyền. Fake load1100ms không là benchmark. Đến đảo chỉ
đổi trạng thái trong bản thử, chưa có màn hoạt động tại đảo.

Ảnh mới vẫn opaque; UI/route tách được **không có nghĩa terrain/nhà/boat đã tách
layer**. Chưa có boat sprite/rig/game animation, navigation hoặc geometry calibrated.
Viền vẽ và mái tháp còn khác W01; giữ mức composition study, không neo canonical mới.
Không Flutter/device/backend/commerce acceptance.

**Không đổi PQC-018, PQC-011, CODE package hoặc catalog r35/r36.** Code tiếp tục đúng
correction A rồi Batch B như tin đã nhận; không cần đổi việc vì gói W08 này.
[21 ảnh đang review](../art-review-r36/index.html) vẫn truy cập riêng.
