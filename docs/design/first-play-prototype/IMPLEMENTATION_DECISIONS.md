# P02 — Quyết định của design sau phản biện PQC-007

- design decision revision: 1
- based_on_code: `3b59f0b538f4bd94c49bf3076ae24f1c1dd8f428`
- prototype_reference: `86513ca29910896ef21961d9489f00414dc5262f`
- purpose: trả lời feasibility, tránh code tự đoán; **không phải duyệt art/runtime**
- acceptance owner: design chốt UX; người dùng duyệt art; code xác minh feasibility/tests

## 1. Cảnh làng, tọa độ, safe area

**Chọn hướng scene và UI overlay tách lớp**, không lấy JPEG/WebP concept làm map
production một bước. P02 vẫn là ảnh nền liền để review bố cục, không phải bộ layer có
thể ship. Không thay `island_map.webp`, `kMapImageSize`, hitBox/labelAnchor ở lượt này.

- Reference đúng **896×1200**, aspect **56:75**. Những con số1024²/640×645 trong
  feasibility cũ đã bị bác bỏ; xem review PQC-007 và facts.json.
- Prototype/future composition review dùng **contain** trong map-region, không crop
  công trình bằng cover toàn điện thoại. Header, card và nav nằm ngoài region;
  dành safe area hệ thống riêng, không cộng inset vào tọa độ landmark.
- Quy ước tọa độ: gốc trái-trên của **ảnh**, x sang phải/y xuống dưới, miền0..1.
  `screenPoint = imageRect.topLeft + normalizedPoint * imageRect.size`.
  Với contain: scale=min(regionW/896,regionH/1200); imageRect căn giữa region.
- Khi stage production: mỗi landmark cần art footprint/label anchor riêng và control
  hit target tối thiểu48 logical px. Không dùng một normalized rect cố định để bảo
  đảm48px trên mọi màn. Rect/polygon footprint production **chưa được bàn giao**.
- Không ép sáu control chen vào region quá thấp: có thể cuộn trang (không đặt card
  đè map), và phải có lựa chọn địa điểm dạng danh sách dùng chung state/action cho
  font lớn, keyboard/screen reader hoặc khung hẹp. Kích thước cuối phải test, không
  coi những đề xuất này là viewport evidence đã chạy.

Các **point anchors đã có** trong app.mjs của prototype (không phải production hitBox):

| Prototype landmark | Module thật | x | y |
|---|---|---|---|
|python_academy|main_quest|0.50|0.30|
|robo_maze|robot_maze|0.28|0.44|
|pip_volcano|dragon_jump|0.80|0.34|
|star_observatory|catch_stars|0.82|0.53|
|bitsy_workshop|bug_hunter|0.23|0.68|
|achievement_house|achievement_house|0.78|0.74|

Art P02 được duyệt hướng cũng **chưa đủ** cho full-map swap: vẫn cần layered deliverable,
footprints, safe area/crop tests và task runtime riêng. Thumbnail512 là scope khác,
không sửa map geometry.

## 2. IntroSeen và đường vào chơi

**Cả ba lựa chọn** — Bỏ qua, Khám phá đảo, Thử cùng Robo — đều kết thúc intro và đánh
dấu `introSeen=true` qua một completion handler trước khi điều hướng đích. Giữ API
persistence hiện có, không thêm flag thứ hai chỉ cho CTA trực tiếp; chỉ ghi một lần
mỗi completion, tránh hai navigation cùng chạy khi double-tap.

- Bỏ qua/khám phá → hub. Thử cùng Robo → introduction/home Robo Maze, **không** tự
  tính đã thắng, tự bắt đầu lượt mất energy hay ép bỏ màn hướng dẫn.
- App restart bình thường không lặp welcome đã hoàn tất. Lỗi lưu/khởi động lại trước
  khi ghi xong phải được test; không dùng prototype session state làm persistence.
- “Gặp lại Robo” mở welcome/guide theo yêu cầu, **không** gọi setIntroSeen để reset,
  không xóa tiến trình. Setter hiện chỉ ghi1, không phải replay controller.
- Không đổi Tutor identity, voice/microphone permission hay nhân vật trong lesson.

## 3. Result: bảo toàn dữ liệu thật, đổi thứ tự nhìn

**Giữ pipeline sự kiện/reward và notices**, không bỏ toast vì prototype chưa mô phỏng.
Không phát lại cùng levelCompleted để tạo thêm phần thưởng hoặc hiển thị notices hai lần.

Thứ tự mục tiêu cho UI mới:
1. Một câu khen hành động vừa làm + số sao thật từ `MazeStars`.
2. Nhóm “Lượt này”: **Số lệnh, Đá quý, Lần chạy** (ba stats hiện có), score/best/newBest
   nếu có, và kết quả ba goals. Có thể dùng list/wrap thay grid cứng; không lược bỏ
   dữ liệu để bắt chước một dòng HTML, không bịa thêm “ô thống kê thứ tư”.
3. Skill/giải thích học được + notices theo kết quả service; không dùng sao trang trí.
4. CTA next/replay/back/map giữ đúng ResultAction, nextCost và điều kiện thật. Cost
   phải đọc đủ trước xác nhận; font2.0 cho phép cuộn, không đẩy CTA ra ngoài hit area.

Đây là content/layout contract, chưa có mockup Flutter đủ mọi state hoặc approval ship.

## 4. Selected card, progress và energy

- Mục tiêu P02: tap landmark **chọn địa điểm**; card dưới map hiển thị tên, một dòng
  progressLabel + stars khi có dữ liệu, hoặc lockReason + CTA đi bài cần học khi khóa.
  Không gắn sáu bảng thống kê che sáu công trình. Detail dài ở activity intro/detail.
- Trong runtime hiện tại chưa đổi flow: ActivitySheet vẫn mở như cũ cho tới task port
  được duyệt. PQC-008 accessibility không được âm thầm đổi tap thành selection.
- EnergyPill ở hub là tổng thật từ service. **Không ghi giá lượt chơi giả vào card**:
  mở một activity home không đồng nghĩa bắt đầu một level. Cost thật đặt tại CTA có
  hành động tiêu năng lượng (start/replay/next), lấy từ config/progression hiện có.
- Không làm mất locked state, lesson CTA, progress/sao và Creator Mode tùy chọn.
  Không biến Creator thành đường bắt buộc cho trẻ mới vào app.

## 5. Semantics và focus

**Đồng ý yêu cầu accessibility**, nhưng đây không phải runtime authorization.
PQC-008 khi được mở phải giữ hành vi hiện tại (mở sheet), không đổi hitBox/art/layout.

- Một hành động landmark có accessible name đúng tên nơi, button role, tap action;
  khóa vẫn có thể mở giải thích/bài cần học, không vô hiệu hóa nhầm toàn vùng.
- Tab đi tới sáu địa điểm theo thứ tự registry; Enter/Space thực hiện cùng hành động
  với tap, focus indicator nhìn thấy; đóng sheet trả focus về nơi đã mở.
- Tránh hai node thông báo trùng cho hình/nhãn của cùng địa điểm; expose selected chỉ
  khi có state chọn thật. Không tự thêm selected state giả vào map cũ.
- Test cây semantics, tên/action/keyboard ở Flutter **không thay** test TalkBack trên
  Android. Baseline GestureDetector chưa đủ bằng chứng cho kết luận hoàn toàn unreachable.
- Prompt API như `Semantics(actionLabel:...)` hay `assertWidgetSatisfies` không phải code
  mẫu đã được xác nhận: dùng API có thật trong SDK CI và để analyzer/test kiểm chứng.

## 6. Lesson route thật

**Giữ Bug Hunter → Main Quest lesson `mq1_03`** như data hiện tại. Lấy unlockLessonId
qua loader/service; fixture có thể assert mq1_03 để phát hiện đổi dataset không chủ ý,
nhưng không hardcode production bỏ qua `requires_lesson` của data.

Test-only được làm ngay: từ map mở locked sheet, chạm CTA, chứng minh MainQuestHome
nhận đúng openLessonId và card mq1_03 được nhắm tới, không chỉ chuỗi pop.
**Không auto-start bài học**: source hiện chỉ scroll/highlight card, còn prerequisite.
- Người mới: card mq1_03 vẫn khóa; không bypass hai bài trước, không trừ energy.
- Người đã xong mq1_01/mq1_02 nhưng chưa mq1_03: Bug Hunter vẫn khóa; sau khi route
  tới Tháp Python, tap thêm card đã mở mới vào lesson player đúng mq1_03 và áp dụng
  spendEnergy thật. Không đổi quy tắc chỉ vì CTA gọi “đi tới bài học”.
Không pump thẳng destination để né routing. Nếu test tìm ra lỗi runtime, báo blocker
riêng; không tự sửa. Đổi sang auto-start sẽ là proposal riêng, không thuộc quyết định này.

## 7. Motion/lifecycle/maze — những câu còn thiếu trong feasibility cũ

- Target production: reduced motion khi **OS yêu cầu OR calmMode=true**. Setting trong
  app chỉ giảm thêm, không được vô hiệu hóa yêu cầu của OS. Không tuyên bố HTML hiện
  tại đã thực hiện đầy đủ rule này; phải bổ sung tests riêng khi port.
- Tắt motion trang trí không đổi luật/thời gian tính điểm. Khi background/route ra
  ngoài: game không được âm thầm tiến lượt hoặc cộng reward. Quy tắc pause/resume/reset
  cụ thể theo từng game; kiểm dt jump và cancel pending completion, không suy đoán từ
  việc có Ticker. Không kéo voice lifecycle vào patch UI này.
- `command_limit` vẫn là mục tiêu sao, không hard input cap. Không thay30 của block
  editor, không copy12 của mẫu. Hiển thị vượt mục tiêu như gợi ý tối ưu, không cấm thử.
- Stop và exact-command error là yêu cầu UX mới cần implementation task; không “map
  1-1”. Stop phải hủy completion cũ/không phát reward, giữ chương trình để sửa, đưa
  board về đầu lượt như mẫu. Quy tắc energy khi chạy lại giữ service hiện tại.
- Hint thật tiếp tục dựa content/config; không chép hint giải hết đường của prototype
  thành gợi ý mặc định mọi màn. Lưu fail-step/active chip cần đảm bảo loop/Python mode
  vẫn được chỉ đúng chỗ, không chỉ case bốn mũi tên.

## Bảng quyền vẫn còn hiệu lực

| Việc | Quyết định |
|---|---|
|Đọc/correct feasibility; test route/cache/geometry hiện có|Có, theo PQD-002 r2/PQC-009|
|Sửa runtime semantics (PQC-008)|Chưa; chờ scope runtime riêng|
|Swap6 thumbnails (PQC-002)|Chờ người dùng duyệt bộ512 cụ thể + gate runtime có allowlist|
|Art P02|Chờ duyệt hướng, không tự suy từ “Yes” agent-watch|
|PQC-004|Cần phiên có Android/âm thanh để kiểm thực; không thể thay bằng mocks|
|PQC-005|Cần SDK/network và quyền sửa lockfile; không sửa tay lock hay tự nâng constraints|
