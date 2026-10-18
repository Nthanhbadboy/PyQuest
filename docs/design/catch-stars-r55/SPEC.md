# Catch Stars r55 — hợp đồng màn chơi, kết quả và bản đồ sao

**2026-10-18 · DESIGN STUDY / runtime NOT_AUTHORIZED.**
Nguồn luật pin `6dc8ca8feeed54cc0fa6a82109e3a59d24a16153`.
[Source notes](SOURCE_NOTES.md) có trích dòng; [manifest](source-manifest.json) có SHA256.
CODE tip quan sát sau đó `e440239fa334c8dae0538ed4460139d1f9416ad0` không đổi tám
file nguồn của study. Không merge CODE, không coi source hay HTML là nghiệm thu Flutter.

## 1. Ý đồ hình ảnh và hai tiến trình khác nhau

Giữ thế giới vật liệu r33/r40/r50/r54: mái đài thiên văn xanh ngọc, đồng ấm, kính
xanh, bầu trời chàm và Robo mint. Bình/ngôi sao/thiên thạch là object riêng, không
kéo cả concept r40. Không có vạch làn hẹp; bình đi toàn chiều ngang theo clamp nguồn.
Robo là bạn đồng hành, không thêm pet AI/NPC/upgrade/chợ sao trong lát cắt này.

- **Điểm lượt** → 0–3 sao kết quả theo 60 / 150 / 300.
- **Số vật bắt được** → mỗi vật không phải thiên thạch cộng **1** vào `atlas_total`.
  Không lấy score, multiplier hoặc số sao kết quả thay cho caught.
- Chòm sao là tám mẫu nhân vật nguồn, không thêm currency, unlock đồ đạc hoặc quest.
  Truyện hư cấu được ghi rõ, không gọi là kiến thức/bản đồ thiên văn thực.

## 2. Luật nguồn được mang sang mô hình JS

| Mục | Luật nguồn |
|---|---|
| Vào/chơi lại | `arcade_run=2`, trừ trước entry; ready-back không hoàn |
| Lượt | 45 giây, 3 tim; timer chỉ bắt đầu khi di chuyển |
| Không gian | width400; basketX/targetX200; clamp45…355; basketY=.84×heightUnits |
| Điều khiển nguồn | tap→moveTo, drag delta→nudge; basket easing `min(1,14dt)` |
| Bước thời gian | clampdt0…0.25, chia nhỏ tối đa1/60; pause không update |
| Bắt | strict `abs(y−basketY)<26 && abs(x−basketX)<52` |
| Rơi | `y+=vy*dt*(1+.35p)`; `x+=sin(time*2+sway)*sway*dt*20`; p=time/45 clamped |
| Spawn | đầu .6s; tiếp `(.85−.45p)*(.7+random*.6)`; x40…360, y−30 |
| Loại | meteor<.14+.12p, comet<.22+.12p, golden<.28+.12p, rainbow<.30+.12p, còn lại star |
| Vận tốc | star150…220; golden120…160; comet330…410; rainbow140; meteor190…280 |
| Combo | tăng trước khi tính; `min(3,1+floor(combo/5))`; cầu vồng nhân đôi |
| Điểm gốc | star1, golden5, comet3, rainbow2; mỗi vật chỉ counted1 |
| Cầu vồng | đặt6s **trước khi tính điểm cho chính nó**, tối đa×6 |
| Thiên thạch | trừ1tim, combo0, hurt1; **không invulnerability**, không xóa rainbow |
| Hụt | y>height+30; nonmeteor chỉ resetcombo nếucombo>0; không trừtim; meteor hụt không reset |
| Kết thúc | sau cả vòng lặp fallers, nếu time≥45 hoặc hearts≤0; nhiều meteor cùng bước có thể trừ nhiều tim |
| Pause-finish | đặt time=45, tiếp tục bước cập nhật bình thường; có thể bắt/va chạm cuối, không discard |

Ví dụ bắt thường: 4 sao=4đ; sao thứ5 thêm2đ; thứ10 thêm3đ. Rainbow ởcombo1
thêm4đ; ởcombo5 thêm8đ; từcombo10 thêm12đ. Eight golden catches=60đ/8caught;
15golden=160đ;25golden=310đ. Không mang luật jump/coins/gems/invulnerability từ Dragon.

Nguồn `_finish` tuần tự: đọc before → addInt atlas_total → update best_caught nếu
lớn hơn → phát `itemCollected` cho **từng** threshold crossed (`const:<id>`) → nếu
stars>0, `levelCompleted(run,score,stars,caught)` và best/first outcome. Zero-star
vẫn cộngatlas/mởchòm, nhưng không tạo runrecord. Fallback max(current,old) trong
source không được gắn nhãn “đã ghi”; UI này chỉ gọi previous/acknowledged record
là “Kỷ lục đã ghi”. Không có transaction bao toàn bộ chuỗi trên.

## 3. Đề xuất thiết kế — KHÔNG phải hành vi runtime đã tồn tại

**D55-P1 Camera.** Study cố định world400×600, vẽ vị trí y theo `y/600*stageHeight`,
x theo `x/400*stageWidth`. Sprite vẫn theo width/400, không co lại khi font tăng.
Bình92×62 là proxy mỹ thuật; source painter rim92/body82×50. Cloud/Robo/fallers
là lớp riêng. Robo gần clamp phải được dịch vào khung nhìn, không đẩy collider.
Nền giữ tỷ lệ, fit theo chiều cao, neo phải; dải pixel rìa trái mở rộng sky/water.
Không kéo giãn mặt trăng, không ép một dải dọc thành làn chơi.

Nguồn Flutter dùng `heightUnits=screenHeight/(screenWidth/400)` **thay đổi theo
viewport**. Chọn600 ở đây là đề xuất riêng để tăng chữ không đổi thời gian rơi và
world state trong cùng lượt. Khoảng va chạm dọc hiển thị bị nén theo stage; chưa
chứng minh gameplay feel/fairness tương đương source. Trước runtime phải chọn hợp
đồng camera, test source baseline và viewport/text matrix, không copy600 vào
engine rồi nhận “preserve physics”. HTML checks không thay thế việc đó.

**D55-P2 Input/a11y.** Thêm hai nút48px+ (thực tế dock≥56px), nudge±48 logical mỗi
lần; ArrowLeft/Right, native key repeat, Escape pause/back; pointer capture cho
kéo. Không thêm jump. UI không bắt người chơi dùng drag; chưa chứng minh timed
game fully accessible cho người không nhìn thấy. Stage group có tên hướng dẫn,
canvas imagery aria-hidden, HUD text DOM, live message ngắn; không đọc mỗi frame.

**D55-P3 Lifecycle.** Khi document hidden, pause, không tựresume khi visible.
Giảm hiệu ứng loại glow/border impact; **không dừng vật rơi** trong lượt đang chơi.
Browser visibility test là event mô phỏng, không Android lifecycle/voice/device proof.

**D55-P4 Receipt authority.** Pending/unknown giữ tổng và record đã xác nhận; mở
chòm dự kiến không kể truyện/khẳng định nhận thưởng. Không cho vào lượt mới khi
chưa rõ receipt, kể cả đã vềhome/atlas. Read-back chuyểnunknown→pending, KHÔNG
cộng lại. Nút “Mô phỏng” ở design tools mới phát RAM acknowledgement. Một attempt
ID duy nhất trong session chặn late/double ACK của study. **Không durable idempotency,
không retry protocol/transaction/SQLite exactly-once.** Production cần contract
repository/event reconciliation trước khi dùng UI này. R55 không mở quyền sửa core.

**D55-P5 Localization.** Default navigator locale VI nếuvi, còn lạiEN; override
qua controls. Đây không thay Settings hiện có của app (system default/manual
VI/EN đã tồn tại). VI catalog trích nguyên văn; EN là bản dịch thiết kế mới.
Chữ thực1/1.3/2×, không transform scale, ellipsis hoặc scaleDown để giảđạt.

## 4. Hợp đồng màn và focus

- **Home:** arthero, hướng dẫn, nút entry/cost và atlas, energy/total/next threshold;
  5loại có tên/đặc điểm, combo/miss giải thích. Cuộn nội dung dài, không ép thành1màn.
- **Ready:** thông báo bắt đầu bằng movement và đã tốn2energy/no refund. Nội dung
  dài ở200% cuộn trong panel có keyboard focus; panel không nhận drag gameplay.
  Nút trái/phải cố định ngoài panel và field. Chạm vùngsky ngoài panel vẫn bắt đầu.
- **Playing:** HUD score/time/hearts ở ngoài field; combo/rainbow ởdải riêng.
  Hit/miss dùng dải này +livemessage, không đặt banner lên bình/làn rơi. Golden
  khác size, comet cóđuôi/cầu sáng, rainbow có3vòng, meteor làđá/đuôi coral;
  không phân loại chỉ bằng màu.
- **Pause:** replace field bằng panel cuộn, hai hành động đặt trước lời giải thích;
  resume không tốnthêmenergy; finish vẫn ghi nhận lượt. Focus vàoResume.
- **Results:** điểm/caught/bestcombo/record/receipt/tổng nguồn riêng; mốc60/150/300;
  0star vẫn có thể unlockPip từ72→80. Pending headline không gọi “Kỷ lục mới”.
  Nội dung kết quả cuộn và controls tới được bằngTab. Focusheading khi chuyểnmàn.
- **Atlas:** 8 cards, locked/lit, threshold, selected detail và đúng normalized
  points/edges nguồn. Locked không lộ story trongDOM. Click card đưa focus đến
  detail, không mất selection. Đủ1200 thìalllit, không bịa chòm thứ9.
- **Energy:** thiếu/unknown làmodal; khôngcharge/clock; Escape trởfocusbutton.
  Unknown đọc lại là mô phỏng, không giả API thật. Không nạp tiền/ads/debt.
- **Design tools:** desktop và nút☷ trênphone; đổi language/scale không tạo attempt,
  resettime haycharge. Mởtools tronglượt chủđộngpause. Fixture thay toàn bộ RAM có
  chủý; reload mất dữliệu. Controls không phải menu production đượcduyệt.

## 5. Evidence và cổng runtime còn thiếu

[Model](evidence/model-checks.json), [browser](evidence/browser-checks.json),
[static](evidence/static-checks.json). 20fixtures×2viewports×2languages×3scales.
32modelchecks +1.000record comparisons +10.000spawn samples. Không so RNG Dart
vớiLCG JS: FX nguồn cũng tiêu thụrandom, FX study giảnlược nên chuỗispawn khác.
Không audio/haptics/productionanimation,900msenddelay,store/network/backend/API,
realawards/screenreader/deviceperf testing. Browser target/font/flow assertions
không phải WCAG certification hay toàn bộ screenshot đãreview thủcông.

Runtime Catch **NOT_AUTHORIZED**. CODE giữPQC-020/R1-A. Trước orderCatch riêng cần:
production asset/animation/collider anchors; camera fairness; authority/failure
contract; Flutter tests/localization/assets with pinned SDK; sameSHA captures và
regressions. Không mở new economy/quests/friends/house từ một atlas study.
