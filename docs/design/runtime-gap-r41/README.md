# R41 — Xem lại runtime evidence, tiếp tục đúng phần còn thiếu

2026-10-18 · DESIGN · [Mở bảng đối chiếu](index.html) · [38 dòng coverage](coverage.json)

## Kết luận chính

**Có nhiều thiết kế mới, nhưng chưa có bộ ảnh runtime “sau redesign” của toàn app.**
Không được lấy gallery r35/r40 hoặc prototype W08/W14 làm bằng chứng các màn đó đã
thay trong Flutter. Cũng không đúng nếu nói app chưa có thay đổi nào: Settings và
bảng authored độc lập đã có implementation/evidence trong phạm vi riêng.

Tôi đã xem lại:
- **38 ảnh baseline** trong `docs/screenshots/`, qua bốn bảng ảnh; mở riêng đầy đủ
  `30_energy_sheet.jpg` và `31_daily_quests.jpg` để quyết định phần thiết kế tiếp.
- **Settings e02** của a9bcdcf: có System/VI/EN, active language và các controls đã
  dịch; vẫn là giao diện sheet hiện hữu, chưa phải scene A02 mới.
- **Board greeting EN2×** tại d18b3d4: code → connector → output của bảng độc lập;
  không phải ảnh tích hợp011.010 được nghiệm thu về sau tại3f26603 theo reviewr22.
- Canonical W01 full-size để làm neo cho cảnh bổ sung. Không tạo ảnh runtime mới.

**Provenance:**38ảnh được lưu trong Git tại5c8d215; không biết chắc SHA build/run đã
chụp chúng. Không dùng commit lưu ảnh làm tested source SHA. Bộ ảnh có38file, không
phải43file: số trong tên có khoảng trống. Các ảnh là nhiều trạng thái, không phải38
màn độc lập. Coverage gom thành **18 nhóm**.

## Đã redesign phần nào, còn thiếu phần nào?

| Nhóm | Thiết kế hiện có | Runtime / phần chưa xong |
|---|---|---|
| Settings, locale | A02 study;016 implementation riêng |016 đã nghiệm thu locale UX, không phải A02 đã lên app |
| Tutor / bài học |010 authored board, W13 art, prototype |010 standalone đạt;011 integration CHANGES_REQUESTED. Story/choice/fill/code/full lesson UI chưa được redesign toàn bộ |
| Làng, Welcome, ActivitySheet | W01, P02/P06C, A03/A05 | Chưa có after-runtime chứng minh hub mở rộng/scene mới được tích hợp |
| Nhà, đảo, pet, bạn bè | W02–W12 studies; W08r37 | Phần mở rộng không xuất hiện trong38baseline. Không được suy là đã lên app hoặc “không thuộc app” |
| Maze gameplay | P02 mô phỏng2màn, W05r34 | Chưa phủ toàn bộ runtime states. **Chọn màn05/41 thiếu thiết kế riêng** |
| Tháp Python/chọn bài12/42 | Có phòng Tutor, không có màn chương thay thế | **Thiếu thiết kế riêng cho chương/danh sách bài** |
| Dragon/Hái Sao | W05Dragon; A04r40 | Có scene/state studies; continuous gameplay renderer chưa được chứng minh đổi |
| Kết quả game/bài | P05/W06, một số state A04 | Chưa đủ per-game recap/source fields và after-runtime |
| Xưởng Mê Cung26–28 | B02r40 bố cục prose editor | **Chưa redesign grid/brush/code/verification thực của Maze Creator**; B02 không thay thế được phần đó |
| Nhà Thành Tích29/43 | W14r39 cabinet/detail | Có prototype, chưa runtime;3phòng còn lại ngoài slice |
| Nhiệm vụ hôm nay31 | **Bổ sung r41 này** | Trước đó Journal A01 không thay daily quests; vẫn chưa tích hợp Flutter |
| Năng lượng30 / nghỉ mắt | **Bổ sung r41 này** | Trước đó chỉ có năng lượng trong HUD và prototype chung, chưa có slice2,5D riêng |
| Splash01 | Chưa có redesign riêng | Backlog sau các luồng sử dụng chính |

Không đưa phần đã có concept vào “chưa làm gì”, và không đưa phần có concept vào
“đã hoàn tất”. Chấp nhận018 ởr40 là hoàn tất **art work order đó**, không phải toàn
bộ các chức năng mà tên màn gợi tới đã được thiết kế/triển khai hết.

## Đã làm tiếp ngay trong lượt này

[**Nhiệm vụ hôm nay + Năng lượng/nghỉ mắt r41**](../daily-energy-r41/README.md):
- Một cảnh quầy nhiệm vụ và ghế nghỉ2,5D mới, lấy W01 làm neo, không đổi canonical.
- Daily tách khỏi dự án dài hạn:3nhóm học/luyện/sáng tạo, progress, pending/error/
  đã nhận mẫu, ngày mới, sổ tem.8định nghĩa nguồn được pin; không tạo reward mới.
- Energy rõ phần miễn phí, bảng chi phí nguồn, full/empty/loading/error; không ads/
  mua năng lượng. Nghỉ mắt20giây, dừng được, không tạo bonus.
- VI/EN, chữ1/1.3/2×; **192browser cases,3.624font checks,11flows,17model checks đạt**.
- Đây là HTML simulator có nhãn mẫu; không ghi dữ liệu app, không sửa engine/011.

![Bản thiết kế mới, không phải screenshot Flutter](../daily-energy-r41/evidence/desktop-overview.jpg)

## Cập nhật CODE cuối lượt

Đã fetch thấy **2ea5e5004e98df4aec8c1132a56b8d60bf4ddf5e**, correction011 mới.
Commit chỉ đổi5file source/test/task, không thêm ảnh runtime. **Chưa review/accept
commit này trongr41**; trạng thái011 củaDESIGN chưa đổi.7nguồn daily/energy pin4fe3b7d
vẫn nguyên byte ở2ea5e5. Review011 là lượt riêng, không dùng auditảnh để bỏ qua tests.

## Thứ tự tiếp tục đã chọn

1. **Review riêng correction011 mới**, theo orderr40; không giao thêm task CODE từ audit này.
2. **DESIGN kế tiếp: màn chọn chương/bài Main Quest (12/42)**. Đây là khoảng trống
   độc lập với inline board011: cấu trúc chương, bài đã học/đang học/khóa, đường ôn
   miễn phí và return. Không sửa board/editor/grader hoặc giả điều kiện mở bài mới.
3. Chọn màn Maze05/41, rồi Maze Creator grid/brush/test/verified thật về mặt thiết kế.
4. Khi có order tích hợp: cần **after-runtime cùng nguồn/viewport/state**; đối chiếu
   trước/sau bằng Flutter captures mới. Không dùng36/38/40HTML receipts thay bước ấy.

Không tự mở R1/runtime qua audit này. Bốn tài liệu sản phẩm/charter đã mở rộng vẫn
là phạm vi toàn app; đây là thứ tự bù thiết kế, không thu sản phẩm về Tutor-only.

## Bằng chứng và giới hạn

- [Sheet1](evidence/baseline-sheet-1.jpg) · [Sheet2](evidence/baseline-sheet-2.jpg) ·
  [Sheet3](evidence/baseline-sheet-3.jpg) · [Sheet4](evidence/baseline-sheet-4.jpg).
- [Nguồn mới](../daily-energy-r41/source-manifest.json), [spec](../daily-energy-r41/SPEC.md).
- [Board010 acceptance](../coordination/reviews/PQD-003-r22.md),
  [Settings016 acceptance](../coordination/reviews/PQD-003-r30.md),
  [011 findings](../coordination/reviews/PQD-003-r34.md),
  [018 art scope complete](../coordination/reviews/PQD-003-r40.md).
- Không chạy Flutter/device/CI mới trongr41; không tuyên bố xem full-size cả38ảnh
  hoặc toàn bộ capture CI cũ. Chỉ những ảnh đánh dấu full-size trongcoverage mới
  có claim đó. Ảnh baseline, reviews cũ, W08/W14 và package CODE giữ nguyên byte.

Kiểm audit gallery:41ảnh decode,56linksHTTP200,filters18/4/2/18,390/360khôngtrànngang.
[Gallery receipt](evidence/atlas-checks.json) · [Static/source/scope receipt](evidence/static-checks.json).
