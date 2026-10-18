# r52 · contract kết quả / biên nhận / thông báo

## 1. Source authority

Pin `bcf2bfc5088ca80f1a6f0fd1d2211032f5ce416a`, DESIGN base `adac29c`.
Full blob hashes và line ranges: [source-manifest](source-manifest.json),
[excerpts](SOURCE_EXCERPTS.md). Không suy các đề xuất dưới đây đã có trong Flutter.

| Source đã đọc | Ràng buộc thiết kế |
|---|---|
| MazeStars: reached +allGems +withinLimit; score40/30/30 từ config | Điểm là tổng tiêu chí, không phải số coin/phần thưởng. Không gems vẫn allGems khi won |
| ProgressRepository.saveLevelResult giữ max(stars), max(score) độc lập; plays+1 | Lượt kém hơn không hạ record. “Lần chạy” trong lượt không đồng nghĩa repository plays |
| newHighScore chỉ true nếu previous!=null và current.highScore>previous.highScore | Lần đầu hoàn thành là nhãn riêng; hòa điểm không gọi kỷ lục mới |
| levelCompleted → progress listener save record/unlock; EventOutcome bestScore/newHighScore | Record label dựa confirmed outcome, không tự đoán từ ba sao |
| LevelResultData.skill là chuỗi lời nhắc; levelCompleted không learnSkill | “Vừa luyện tập”, không dựng XP, mastery hoặc awarded skill |
| RewardNotice có kind/id/title/description;5kinds | UI phản ánh notices host đã trả, không suy badge từ số sao |
| Daily quest completed notice khác claimStamp | Xem/đóng notice không claim stamp |
| Result screen gom badges và others; custom dùng timed reward toasts | Inbox không tự hết hạn là đề xuất mới, không mô tả UI source sẵn có |
| Custom play trả _CustomRunReport, không levelCompleted của màn thường | Custom không thêm record/sao màn thường, không leaderboard/global record |
| Workshop _testRun: save trước play; report.won → verified save → customGameVerified lần đầu | Tới rương chưa đủ để nói bản đang sửa đã lưu và xác minh |

**Không có transaction toàn bộ chuỗi trong source.** ProgressRepository transaction
bảo vệ record, không tự bọc path store, loopUsed, levelCompleted, daily quest,
achievement và custom verification trong một durable receipt. Event listeners
chạy tuần tự. Nếu listener sau lỗi, listener trước có thể đã ghi. Source chưa có
receipt reconciliation API hoặc exactly-once run identity như đề xuất r52.

## 2. Record / result presentation

Hai lớp dữ liệu: attempt immutable và known receipt. Fixture trước khi đối soát
có thể biết previous record; UI vẫn hiện **kỷ lục trước lượt này**, không xóa nó,
nhưng không gọi record mới là đã lưu. Confirmed record hiển thị max độc lập.
Mọi record trong browser là mẫu RAM, không account state.

`first` và `rewards` dùng màn1 không gem,4lệnh,100điểm; `no-gems` là replay của
màn1. Các case thường khác chủ yếu dùng summary màn2 (6lệnh/1gem). `lower` dùng
9lệnh/0gem nên40điểm/1sao, giữ record100/3. `final` chỉ là layout cuối danh sách,
**không phải engine transcript hoặc solution của rm_10**. `rewards` là catalog
layout5kinds, không tuyên bố cả5loại phát sinh từ một lần thắng màn1. Các notice
ngoài `first_steps` dùng sample IDs rõ ràng, không là unlocked content mới.

Sao trong hero chỉ của lượt đó. Scene rương/đá quý là illustration, không replay
path hoặc số gem thu được; score stars chỉ DOM. No-win không dùng celebration
scene. Thẻ skill từ level1/2 hoặc authored custom hint; không đổi trạng thái học.

## 3. State / safe reconciliation proposal

`pending → checking(token, scope, revision) → saved | error | partial | stale`.

- pending: kết quả mẫu có, receipt chưa có; nút đi tiếp chưa authoritative.
- error: giữ attempt và previous, không dựng record mới hoặc notice.
- partial: record/proof đã được xác nhận, notices chưa biết. Không rollback record
  hoặc verified proof chỉ vì thông báo lỗi; cũng không dựng empty inbox như đã xong.
- saved: cả record/proof và notice receipt đã xác nhận trong mẫu; notice list rỗng
  là trạng thái hợp lệ. Navigation vẫn chỉ là điểm nối thiết kế, không runtime action.
- checking: một request; cancel tăng token; late/duplicate callback là no-op.
- stale: scope/revision đã khác; không áp response vào draft mới. Controller token
  tăng đơn điệu qua fixtures, kể cả sau nhiều lần đối soát.

**Đối soát là đọc/kiểm tra trạng thái, không emit lại completion.** Model tạo
record mẫu từ previous đúng một lần; complete sau partial giữ plays/record đã có.
Điều này kiểm UX invariant, không chứng minh backend đã idempotent. Runtime cần
run/creation identity bền vững, server/host authority, read-after-write/error
classification và tests riêng trước khi cho retry. Không triển khai endpoint mới.

Primary đợi đủ receipt trong study. Secondary/back vẫn cho rời qua sheet cảnh báo;
không ép người dùng chờ vô hạn vì notice. Không transfer trạng thái qua URL.

## 4. Custom proof

`runRevision` ghi bản tạo báo cáo, `revision` là bản đang mở. Edit tăng revision,
bỏ proof hiện hành; report vẫn thuộc bản cũ và được ghi rõ bản1, trong khi panel
trạng thái ghi bản2. Report thắng cũ không chứng minh bản2 giải được. Late callback
vẫn bị từ chối. Proof chỉ hợp lệ khi scope +revision khớp.

Repeat verification có copy riêng, không tự dựng badge “lần đầu” mới. Không có
claim/event counter trong browser. Không đánh đồng custom proof với account-wide
achievement hoặc normal level stars. `not-won` không có save/verify action.

Source hiện setState verified trước await _save; r52 đề xuất chỉ xác nhận UI khi
có receipt phù hợp. Việc thay save protocol/transactions/reward ordering cần order
CODE riêng; r52 không sửa các source đó.

## 5. Inbox / locale / keyboard

Danh sách giữ thứ tự fixture; dedup `(kind,id)` **trong một receipt mẫu**. Runtime
phải định nghĩa identity/occurrence từ host để không che hai grants hợp lệ cùng ID;
không dùng dedup UI làm reward ledger. “Đã xem” chỉ thêm seen key, không đổi score,
plays, năng lượng hay stamp. Để sau không đánh dấu tất cả đã đọc. Mở lại tiếp tục
notice đầu chưa đọc; xem tất cả không auto-mark. Không timer tự đóng/chặn đọc.

Locale VI/EN và scale100/130/200% giữ receipt/seen/open goals. Source VI copy được
dịch authored cho study, không chứng nhận whole-app l10n. Dialog native có focus
wrap/Escape/return. Buttons≥44px, chữ tăng thật, nội dung cuộn. Không confetti/audio
trong study; reduced-motion không cần tắt một timeline reward giả.

## 6. Runtime gate chưa mở

Cần tích hợp host result identity; transaction/reconciliation failure tests;
receipt persistence và disposal; actual max-record/newHighScore cases; unique
reward/stamp authority; custom edit-versus-save races; native navigation/energy;
Flutter/device/keyboard/screen-reader evidence; production actor/props pack.
R1/R4, CODE018/019 và PQC-011 correction không đổi quyền vì có r52.
