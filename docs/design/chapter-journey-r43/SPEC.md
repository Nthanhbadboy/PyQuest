# Main Quest entry — visual/interaction contract r43

2026-10-18 · DESIGN only. Bổ sung thiết kế cho baseline12/42; không chạm LessonScreen011.

## 1. Đọc màn hình

**Cảnh liên tục, không phải twelve-card dashboard.** Tháp dùng cùng hình dáng/vật
liệu W01 nhưng cận cảnh trong vườn, không thay canonical asset. Bệ1–4 tại phía phải
trên; bệ5–8 phía trái giữa; bệ9–12 phía phải dưới; bàn thực hành phía trước. Vàng là
nhóm chứa bài tiếp theo; xanh nhạt +check khi đủ4bài; trung tính cho nhóm còn lại.
Không dùng màu làm tín hiệu duy nhất: số và completed count nằm trên marker.

Header tách back/title, nhãn dữ liệu mẫu, progress/energy và switch chặng.
Quick continue nằm góc trên cảnh để không bắt trẻ tìm CTA cuối trang. CTA cuối cảnh
lặp cùng hành động, không thêm phí. Không cố nhét cả12bài và mọi thông báo lên640px.

Ba bệ là **visual grouping**, không lesson grading, skill tiers hoặc chapter locks mới.
Mở bệ giữ bài đang chọn nếu thuộc nhóm; nếu khác nhóm chọn bài đầu nhóm. Nút Continue
lấy first unlocked +not completed, all-complete thì chọn bài1để ôn. Deep-link fixture
bài9khóa hiển thị đúng bài9và lý do, không tự bypass hay nhảy vào bài.

## 2. Source mapping (exact2ea5e50)

| Source | Contract giữ lại |
|---|---|
| `main_quest_ch1.json` | 1chapter,12lesson IDs/order/title VI/skill/step count/challenge; next chapter metadata chưa có nội dung |
| `main_quest_module.dart` | i0 mở; i>0 cần lesson trước completed; firstOpen; completed review, challenge và new cost; playground; recap khi đủ12 |
| `quest_models.dart` | Load một JSON chapter; không runtime catalog nhiều chặng |
| `game_config.json` | New1; review0; challenge3; cap20, +5 khi milestonechapter, maximum40 |
| `energy_widgets.dart` | cost<=0 không cần spend; positive cost phải được energy authority chấp nhận |
| `progress_repository.dart` | completedLessons là nguồn completed IDs; study không mở/ghi DB |
| `cast.dart` | Tutor theo skill: Nova/Pixel/Bit/Ada cho12bài; không dùng plan text làm identity |

[source-manifest.json](source-manifest.json) có blob +SHA256 của từng file.
CatalogJS không chứa exercise đáp án hay output oracle. Lesson/board/content validation
không đổi. UI host vẫn là khu Tháp Python; không vẽ nhân vật mới trái CastRegistry.

Loading/error/unknown, grouping journal và cách trình bày chapter availability là
**đề xuất UI của design**; source hiện tại chưa có toàn bộ các surface này. Pins
chứng minh catalog/rule nguồn, không chứng minh runtime đã thực thi state model mới.

## 3. Gate và quyền

- Browse map/chapter/group/detail không tốn năng lượng; bài khóa vẫn inspect để đọc lý do.
- Bài chưa mở không có Enter CTA. Link bài trước chỉ chọn trong journal.
- Bài hoàn thành giá0, mở được ngay cả khi energy0hoặcunknown.
- Bài mới giá1; challenge cuối giá3. Unknown energy tách rõ zero; không hiện CTA entry
  trả phí khi chưa đọc được năng lượng. Đưa lối review/playground miễn phí, không upsell.
- Unknown progress không hiện0/12 hay tất cảđãkhóa. Scene vẫn có nhưng lesson nodes
  không interactive; playground độc lập. Retry giữ unknown và không tự tạo success.
- All-complete vẫn không mở Game Builder: chỉ mô tả nội dung tương lai. Không bịa chapter2
  catalog, ngày phát hành, giá hoặc phí unlock. Đây là cách làm rõ source metadata,
  không một work order để đổi logic Flutter.
- Study gate chỉ định **được xem trước destination**, không mô phỏng transaction energy.
  Entry preview không trừ/hoàn năng lượng, emit event, chấm điểm, hoàn thành bài,
  phát stamp/reward hoặc lưu lựa chọn. Không timer, backend hoặc localStorage.

## 4. 14 fixture / state surfaces

| Fixture | Hiện trên screen |
|---|---|
| new | 0/12; bài1ready;16/20 |
| returning | 1/12; bài2next;11/20 |
| midway | 6/12; bệđầucomplete; bài7next;9/20 |
| challenge | 11/12; bài12ready, cost3;3/20 |
| chapter_done | 12/12; free review +recap;0/25 mẫu |
| locked | Bài4chưa mở, cần bài3 |
| energy_empty | Bài2open nhưng0/20; free alternatives |
| review_free | Bài1completed,0/20; vẫn review được |
| loading | progress/energy/cap chưa biết, không số0 giả |
| load_error | Unknown +retry; không biến thành empty progress |
| energy_unknown | Progress có, energyunknown; không entry positive-cost |
| deep_link | Trỏ bài9chưa mở, không bypass |
| next_chapter | Chapter2 metadata-only kể cả12/12 |
| departure | Route preview rõ giới hạn; không runtime navigation |

Snapshot completion lists là prefix minh họa. Model test riêng xác nhận unlock theo
**ID bài ngay trước**, không theo tổng sốdone hoặc vị trí visual group. Capacity25
ở completed fixture là mẫu theo configuration, không chứng minh milestone đã chạy.

## 5. Layout / accessibility

360×640,390×844 ×VI/EN ×font1/1.3/2. Tất cả chữ product dùngrem; không scale toànảnh
để giả lớn chữ. Large header reflow xuống hàng; không truncate tên bài. Marker range
dùng en dash ngắn hơn, không thu nhỏ font. Nhãn desk dịch sang trái ở2× để không
chồng bệ cuối; đây là **UI anchor proposal**, không đổi footprint hoặc camera world.

Text front-facing, không nghiêng theo perspective. Targets>=48px. Main page có một
scroll owner; khi journal mở, native modal giữ focus và scroll riêng, background inert.
Tab/Enter/Escape dùng được; close trả focus đúng opener mà không tự kéo page. Nội dung
2× có thể dài hơn viewport, CTA phải cuộn tới/tap thật được, không ép toàn bộ hiện cùng lúc.
Reduced-motion không animation; không autoplay, nhấp nháy hoặc âm thanh.

Chương trình kiểm layout/targets/fonts và15interactionflows; chưa manual screen-reader
hoặc contrast audit toàn bộ palette. Đã sửa contrast lỗi cụ thể của nút Chapters qua
visual review. Không coi font/geometry PASS là mọi accessibility requirement đã đạt.

## 6. Integration boundary / handoff

Không work order CODE mới. Chưa copy asset vàoapp, chưa đổi navigation, shader hoặc
asset manifest. Muốn port cần order riêng, đóng contract loading/energy authority,
semantics thực trênFlutter, capture before/after, measured anchors và exported layers.
Main Quest lesson screen đã có order011riêng; r43không thay board, code editor, TutorPanel,
grader, localizedSettings hoặc accepted regression baseline của các task trước.
