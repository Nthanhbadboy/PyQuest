# P05 — Design handoff, chưa phải runtime work order

## Đọc trước

PQC-010/014/015 vẫn là luồng code hiện hành. Gói này **không đổi quyền** và không yêu
cầu dừng công việc đó để port P05. Không sửa PQD-003, prompt hay forward pointer.
Chỉ dùng để review hướng thiết kế và chuẩn bị một implementation slice sau khi được
phép. Không cherry-pick JavaScript model vào domain hoặc dùng nó như spec storage.

## Ý định trải nghiệm

Trẻ nhận ra điều mình làm được, hiểu lý do, biết tìm thành tích và có lựa chọn tiếp.
Tutor không chiếm sân khấu khi mini-game vừa kết thúc; dùng Robo vì đây là Maze.
Không cộng XP toàn cục, không khóa học sau kết bạn, không fake ranking/đối thủ.

S01 chốt lượt → S02 kết quả → S03 ghi nhận → S04 badge → S05 Nhà Thành Tích → S06
chọn việc tiếp. S07 chia sẻ và S08 nhánh thử thách chỉ là định hướng P06/P07; tuyến
cá nhân vẫn hoàn chỉnh nếu không có dịch vụ online.

## Mapping: dữ liệu thật và phần đề xuất

| Vùng P05 | Nguồn app để kiểm lại ở tested SHA lúc port | Trách nhiệm / giới hạn |
|---|---|---|
| Result/goal/stats/host | `LevelResultData`, `_onWin`, `MazeStars.evaluate`, game config | Giữ engine làm chủ luật. Cột “lượt này” khác “best đã lưu”; lần đầu không giả previous-best |
| 3 sao của rm_01 | `rows` không có gem, allGems=true nếu thắng, command_limit=4 | Đánh giá đúng source; không giảm còn2 sao vì không có gem, không hard-cap input4 |
| New badge | `EventOutcome.notices`, `RewardNotice.kind/id` | Không suy new-award chỉ từ firstCompletion của màn; không re-emit completion khi mở panel |
| Collection | earned records + `achievementCatalog` | Lock khác earned; title/description/condition secret chưa đạt không lộ; catalog không khả dụng không tự thêm |
| Daily quest notice | `daily_quest_service.dart` / three_stars | Chỉ thông báo hoàn thành. Claim/rewarded là flow khác, không tự nhận tem/energy từ hiệu ứng |
| Next activity | next level record/config, new/replay cost | Prototype2/0 là đọc source, không quota mới. Kiểm eligibility lần nữa khi vào game |
| Save state | Persistence contract cần review | `EventOutcome` hiện **chưa có** status/receipt API riêng. Pending/error/restore UI ở đây là yêu cầu UX, không API đã tồn tại |
| Social preview | Chưa có trong EventOutcome | Không port nút gửi cho đến khi có identity/permissions/consent/moderation/backend phù hợp |

Snapshot nguồn `090b87d` và hash trong manifest để đối chiếu, không tuyên bố đó là
code tip mới nhất. Khi port phải đọc lại source thực tế, không chỉ lấy tên field từ
prototype. Maze custom test run vẫn riêng với `creator_test_run`, không ép normal
level progression vào Creator Mode.

## Slice đề xuất sau này (chưa được cấp quyền)

1. **Presentation-only result:** host, sao, stats/goals, grouped notices, CTA/cost và
   back route; nối nguồn kết quả sẵn có, không đổi grading/energy/claim rules.
2. **Badge detail → collection:** dựa trên earned snapshot thật, private-first;
   secret/empty/locked đúng catalog; không tự publish profile.
3. **Save/interruption contract:** chỉ implement khi đã xác định nơi nhận ack/error,
   idempotency key và ownership lifecycle. Tách khỏi việc đổi màu/layout để review.
4. **Next choice:** route tới activity khả dụng, dùng cost từ config. Bản preview màn2
   của HTML không được copy thành nút chết trong production.
5. **P06/P07 sau:** social/Arena cần thiết kế & quyền backend riêng, không ké scope này.

Mỗi slice cần allowlist/tests/evidence riêng khi mở. Tài liệu này không xác nhận
allowlist của result/hall đã được cấp và không sửa pubspec, DB hay route production.

## Anatomy & responsive behavior

- Desktop: hero/host ở trái, recap/notice/action ở phải, tương phản dịu và bóng nổi.
- Phone: hero gọn hơn; award và CTA trước recap chi tiết. Với pending/error, trạng thái
  lưu xuất hiện trước CTA. Văn bản cuộn bình thường, không fixed bottom che nội dung.
- Target button tối thiểu48 CSSpx trong mẫu; khi port kiểm48 logicalpx của Flutter,
  cả semantics/focus và text scale2. Không suy đơn vị CSS thành bằng chứng thiết bị.
- Huy hiệu không là hộp quà cưỡng bức mở; replay không tạo một “quà rỗng”.
- Cỡ chữ lớn đổi hàng/cột, không thu nhỏ font để giữ bố cục. Mẫu dùng1/1.3/2.
- Motion hiện650ms, 1 lần/lượt đã lưu; không bắt chờ, OS hoặc local calm đều tắt.
  Page hidden hủy chuyển động; đổi locale không phát lại. Chưa voice/haptics.

## Checklist kiểm production, không dùng kết quả HTML thay thế

- Kết quả lấy từ engine; null best khác0; failure không “được3 sao”; best không giảm.
- Same event/receipt được retry, mở lại, background/unmount không nhận thưởng hai lần.
- Lỗi lưu hiện trung thực; nút retry không bắn completion event mới tùy ý; test nơi
  save đang dở khi đóng app và khi routing. In-memory Set ở mẫu **không chứng minh**
  durability hay transaction của app.
- Không ghép quest với badge, không hiển thị claim currency chưa được xác nhận.
- Chơi lại giữ input/code đúng lifecycle; không reset khi đổi locale hoặc mở Settings.
- Record đầu đời khác firstCompletion của một màn; kiểm existing-earned + new score.
- Localization dùng semantic IDs/ARB với tham số nguyên message, không tree-walker
  hay nối câu. Nội dung code/answer/IDs không đổi theo language.
- Keyboard/TalkBack/large-text/reduced-motion/device memory phải có evidence riêng.
- Review art trước export; pin kích thước/crop/contrast/decoded footprint nếu import.

## Art và source files

`arrival-island.svg`: khối minh họa2.5D760×470, background trong suốt, các hedge/rương
không dùng hit-test. Robo là layer img tách, để animation không animate toàn cảnh.
`first-steps.svg`: medal240×260, gradient vàng/xanh, ribbon đất nung, silhouette dấu
chân. Đây là hình mới review được, chưa duyệt để thay asset trong app.

Các reuse/font licenses nằm trong manifest. Không có stock mới hoặc generated raster
mới ở P05; SVG authored bằng code. Screenshot không chứng minh bố cục Flutter hiện có.

## Điểm cần review tiếp

- Nhịp phone: người chơi nhìn ra lý do nhận sao trước khi đi tiếp hay cần gợi mở thêm?
- Có cần mở mini sheet xem badge thay màn riêng? Hiện chọn màn riêng cho focus/đọc rõ.
- Collection mẫu mới có3 ô đại diện, chưa chốt IA/categorization toàn catalog.
- Nội dung khen cần test với trẻ và consent phù hợp; chưa có bằng chứng retention.
- Night Owl không đưa vào mẫu mới; giữ OPEN-01 của blueprint, không âm thầm đổi luật.
