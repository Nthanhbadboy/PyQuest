# P05 brief — Qua màn là mở ra một câu chuyện tiếp theo

**Trạng thái: brief + storyboard đã có [prototype HTML tương tác](../result-adventure-prototype/README.md).
Chưa có màn Flutter mới hoặc tích hợp backend.**
Không giao code bỏ 010/014/015. Đây là gói design có thể chuẩn bị độc lập ngay.

## 1. Mục tiêu và lát cắt đầu

Trẻ hiểu: **mình vừa làm được gì → vì sao được ghi nhận → nó nằm ở đâu → mình muốn
làm gì tiếp**. Không kết thúc màn bằng một panel số liệu chung chung hoặc một popup
thưởng che trò chơi. Không biến mọi lần thắng thành pháo hoa lớn giống hệt nhau.

Lát cắt: **Robot Maze → kết quả → huy hiệu mới nếu thật sự có → Nhà Thành Tích →
quay về chơi / xem ý tưởng thử thách với bạn**. Phần bạn bè chỉ là nhánh thiết kế P06;
không đặt lời mời có vẻ gửi được vào production khi dịch vụ chưa tồn tại.

Người học một mình phải kết thúc luồng trọn vẹn. Không bắt kết bạn, thi đấu hoặc làm
bài Python để nhận thành tích của mini-game đã thắng.

## 2. Bố cục và nhịp

Điện thoại: một khoảnh khắc nhân vật phản ứng → kết quả chính → lý do → phần thưởng
mới nếu có → lựa chọn tiếp. Nội dung cuộn, CTA không che con số/lỗi khi text scale 2.

| Tầng | Thiết kế |
|---|---|
| Phản ứng | Host đúng activity, một pose/câu ngắn. Một lần chuyển động nhỏ; không tự bật tiếng khi đã tắt sound. Calm dùng pose tĩnh |
| Kết quả | “Đã tới rương!”, số sao/kỷ lục có nguồn; phân biệt lần này với kỷ lục đã lưu |
| Giải thích | Tối đa3 mục tiêu đúng activity; mỗi sao có lý do, không ép học thuật ngữ mới |
| Ghi nhận | Chỉ hiển thị notices mới thật; nhiều phần thưởng gom vào một danh sách, không popup nối tiếp cưỡng bức |
| Việc tiếp | Một CTA chính, tối đa 2 lựa chọn phụ; cho chơi tiếp/chơi lại/về làng. Tốn năng lượng thì hiển thị cost thật trước thao tác |

Đề xuất animation để thử: host reaction 300–500ms, tổng ăn mừng khoảng 1–1.5s;
**không bắt đợi animation để bấm tiếp**, không delay save tới hết animation. Đây là
budget review, chưa phải timing production đã đo. Trophy lớn chỉ dành mốc lớn; badge
mới nhỏ hơn; improved score có nhấn nhẹ; replay không có award mới không mở quà rỗng.

## 3. Storyboard 8 khung — chuẩn bị cho prototype

| Khung | Người chơi thấy / làm | Data/state phải có | Không được suy diễn |
|---|---|---|---|
| S01 Chốt lượt | Robo tới rương, có thể dừng/đợi kết quả lưu | engine success + outcome thật; nếu pending hiển thị đang lưu | Animation chạm rương không tự phát thưởng lần nữa |
| S02 Kết quả | Sao và 3 mục tiêu của lượt; kỷ lục cũ so với mới nếu có | stars/score/bestScore/newBest/goals | Sao là theo luật của game, không do Tutor khen mà tăng |
| S03 Ghi nhận mới | Nếu `notices` có first_steps: huy hiệu “Bước Chân Đầu Tiên”; mở xem ý nghĩa | RewardNotice đúng ID, trạng thái đã lưu xác minh | firstCompletion của một màn không đồng nghĩa huy hiệu đầu đời; không luôn trao first_steps |
| S04 Xem huy hiệu | Tên, lý do đạt, nơi lưu, nút xem Nhà Thành Tích | catalog + record đã kiếm | Không gọi một badge là danh hiệu thi đấu, không thêm điểm tổng sắp chưa có luật |
| S05 Trưng bày | Nhà Thành Tích tập trung vào vật vừa đạt; các mục chưa đạt có điều kiện thật | earned/locked/secret + progress snapshot | Badge secret chưa đạt không lộ đáp án; không dựng badge bất khả thi |
| S06 Chọn việc tiếp | Tiếp tục Maze / thử hoạt động khác / nghỉ | hoạt động khả dụng, next level và cost thật | Không khóa next action bằng xem quảng cáo hoặc bắt chia sẻ |
| S07 Nhánh xã hội | Trong mẫu tương lai: xem trước thẻ thành tích được chia sẻ và ai có thể xem | quyền chia sẻ + moderation state; prototype ghi minh họa | Không tự công khai, không gửi khi người chơi chỉ mở xem trước |
| S08 Thử thách tiếp | Chọn kỷ lục cá nhân, khám phá game khác hoặc lời mời đủ điều kiện | cá nhân khác với trận thật; eligibility/backend khi có | Không fake đối thủ/rank/“bạn đang chờ” để ép chơi |

S07/S08 xã hội là **storyboard định hướng**, không thuộc implementation của result
screen đầu. Trước khi có service, production kết thúc tốt tại S06 thay vì đầy nút khóa.

## 4. State matrix: không chỉ vẽ màn thắng đẹp

| ID | State | Nội dung / hành động | Hành vi cần giữ |
|---|---|---|---|
| R01 | Thắng, có award mới | Ăn mừng + notice; xem chi tiết hoặc tiếp | Notice từ outcome, không grant từ UI |
| R02 | Thắng, không award mới | Ghi nhận kết quả; không khung quà trống | Không tạo phần thưởng cho đủ layout |
| R03 | Cải thiện kỷ lục | Hiển thị lần này và best; câu khen cụ thể | Best không bị giảm khi replay kém hơn |
| R04 | Chưa tới mục tiêu | Một gợi ý theo lỗi có dữ liệu, giữ chương trình, thử lại | Không bêu xấu/giả thưởng chiến thắng, không xóa code |
| R05 | Replay đã nhận thưởng | “Huy hiệu đã ở trong bộ sưu tập”; vẫn ghi nhận luyện tập | Không nhận trùng, không lần nào cũng mở gói thưởng cũ |
| R06 | Pending save / write error | “Đang lưu” hoặc “Chưa lưu được”; retry xác minh/lưu đúng token | Không nói “đã lưu” trước ack; retry không emit completion tùy ý |
| R07 | Không còn màn kế / thiếu năng lượng | Về làng, replay nếu luật cho phép, nghỉ/hoạt động khả dụng | Không tạo XP gate hoặc tự nới energy cost |
| R08 | Background / mở lại / đóng nhanh | Không phát animation hàng loạt; khôi phục từ record đủ tin cậy | Reward không phụ thuộc view còn mounted; lỗi save phải rõ |
| R09 | Nhiều notice cùng lúc | Một danh sách có thứ tự: mốc lớn → badge → unlock/item | Không che/cướp focus liên tục; không gộp sai loại reward |
| R10 | Đổi VI/EN, calm, sound-off, text lớn | Nội dung tương đương, nút đủ lớn, mô tả có thể đọc | Không thay số/sao/đáp án, không replay event/award |
| R11 | Hồ sơ chưa có badge / secret chưa đạt | Mời thử hoạt động thật, placeholder khác earned | Không phô điều kiện secret; không bán badge kỹ năng |
| R12 | Chia sẻ chưa bật / offline / bị giới hạn | Bản cá nhân vẫn dùng được, giải thích trung tính | Không coi không có bạn là lỗi hoặc khóa chơi tiếp |

R06/R08 là **yêu cầu UX mới cần source-map khi port**. EventOutcome hiện không có
receipt/status persistence riêng; không giả rằng API đã trả tất cả trạng thái này.

## 5. Source mapping cho phần làm được trước

Đọc source ở snapshot design `5c69046` (không sửa app):

| Ý nghĩa hiển thị | Nguồn có thật | Giới hạn |
|---|---|---|
| Sao/mục tiêu/điểm Maze | `maze_play_screen.dart::_onWin`, `MazeStars.evaluate`, config game | command_limit là tiêu chí sao, không input hard cap |
| Result presentation | `shared/widgets/result_screen.dart::LevelResultData` có success/stars/score/bestScore/newBest/goals/stats/skill/host/notices/primaryCost | Chưa có schema social/match rank hoặc receipt lưu thưởng |
| Notice để chúc mừng | `core/events.dart::EventOutcome`, `RewardNotice`, `RewardKind` | kinds hiện là badge/quest/energy/unlock/item, **chưa có title/socialTitle** |
| Điều kiện badge | `modules/achievements/achievement_catalog.dart` | First Steps ID `first_steps` và First Line ID `first_line` khác nhau; không dịch ID |
| Chống nhận trùng | `data/repositories/progress_repository.dart`, reward_claims | Cần kiểm pipeline/call sites khi port; UI không tự insert/emit lại |

Đường dữ liệu thiết kế: **game/engine → event & persistence → outcome → presentation**.
Ở đây mô tả ownership, không đề xuất constructor/endpoint mới phải implement ngay.
Custom Maze test run đi qua `creator_test_run` và trả report riêng; không gán luồng
progression của màn thường cho lượt thử tác phẩm.

Code mapping trước khi port cần xác nhận trên tested SHA khi đó, không copy snapshot
thiết kế như source mới nhất. Không đổi save semantics hoặc rule kinh tế trong mockup.

## 6. Bộ câu VI/EN đầu tiên (copy đề xuất, có điều kiện)

| Semantic ID | Điều kiện | VI | EN |
|---|---|---|---|
| result.maze.success | engine xác nhận đã tới rương | Bạn đã đưa Robo tới rương! | You guided Robo to the chest! |
| result.personalBest | newHighScore=true | Một kỷ lục mới của bạn! | A new personal best! |
| result.badge.new | notice badge mới | Một dấu mốc mới trong hành trình của bạn. | A new milestone on your adventure. |
| result.retry | chưa đạt, chưa có chẩn đoán lỗi cụ thể | Mình thử một cách khác nhé? | Shall we try another way? |
| result.save.pending | chờ lưu được xác minh | Đang lưu kết quả… | Saving your result… |
| result.save.failed | ghi chưa thành công | Chưa lưu được kết quả. Thử lại nhé. | Your result could not be saved. Please try again. |
| result.replay.noNewAward | badge đã nhận, không có notice mới | Huy hiệu đã nằm trong bộ sưu tập của bạn. | This badge is already in your collection. |
| result.action.collection | có nơi xem record | Xem bộ sưu tập | View collection |
| result.action.home | đường ra luôn có | Về làng | Back to the village |
| result.action.rest | lựa chọn nghỉ | Nghỉ một chút | Take a break |

Không khen trẻ vì online lâu, hơn bạn kém hơn, hay được Tutor “yêu quý hơn” nhờ mua.
Lời khen có thể đổi cách nói, nhưng chỉ ghi nhận điều dữ liệu chứng minh. Microcopy có
tham số phải là message hoàn chỉnh, không nối mảnh câu theo trật tự tiếng Việt.

## 7. Checklist thiết kế và tình trạng bàn giao

- Dựng P05 tương tác bằng fixture rõ nhãn: 8 storyboard frames, tối thiểu R01–R10 có
  state switch; minh họa awards không ghi vào app DB và không fake multiplayer.
- Vẽ/so sánh bố cục phone trước; đưa victory pose, badge silhouette và motion variants
  vào art review riêng, không mặc định cả bộ 512 đã được duyệt.
- Test trình duyệt VI/EN, 360/390,font lớn, keyboard/reduced-motion và no duplicate
  mock notice. Kết quả đó chỉ chứng minh prototype, không chứng minh app persistence.
- Bàn giao screenshot/state matrix/data ownership để agent code port khi có work
  order mới; giữ PQC-010/014/015 không bị ngắt ngang bởi gói design này.

**Đã dựng:** prototype HTML, huy hiệu SVG và cảnh ăn mừng SVG; 8 khung, 14 fixture
thuộc 12 nhóm state, VI/EN/calm/text-scale, evidence trình duyệt. Xem README P05 để
phân biệt mô phỏng và source thật.

**Chưa hoàn thành:** art approval/export production, âm thanh, Flutter result/hall,
friend services hay điểm xếp hạng. Không báo hiệu quả retention khi chưa có thử
nghiệm người dùng phù hợp và consent.
