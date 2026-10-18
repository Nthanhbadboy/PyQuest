# R1-B / r56 — Chào mừng và bảng giới thiệu địa điểm

**2026-10-18 · DESIGN_STUDY_DELIVERED · runtime NOT_AUTHORIZED.**
Nguồn CODE: `5c97577c32c27d36f33c09bf3af2fa01ad0111f5`, đang sửa PQC-020,
**chưa được nghiệm thu**. Đây là pin để đọc source, không phải bản runtime đạt chuẩn.
[21 source pins](source-manifest.json) · [trích dòng](SOURCE_NOTES.md).

## 1. Phạm vi và trải nghiệm

R1-A giữ Main Map, scene/status controller và sáu routes. R1-B theo SPEC r53 nối
ActivitySheet/Welcome/chọn bài. R56 xử lý **Welcome + ActivitySheet**, còn chọn bài
đã có r43: chỉ mô tả điểm giao tiếp, không dựng lại luồng lesson hoặc sửa Tutor.

Một lần mở app cần trả lời ba câu: đây là đâu; có thể làm gì mà không cần Python;
khi nào mới tiêu năng lượng. Một lần chạm địa điểm cần trả lời: hoạt động gì,
ai đồng hành, tiến độ nào đã biết, có khóa hay không, và nút tiếp theo thực sự đi đâu.

Các màn:
- Ba bước Robo / Py / Pip: khám phá tự chọn, học và thử Python, năng lượng/nghỉ ngơi.
- Sáu bảng địa điểm dùng tên và host đúng `ActivityDef`, không lấy tên viết tắt
  của marker r53 thay canonical name. Ví dụ **Núi Lửa Pip**, không bỏ Pip.
- Tiến độ riêng theo từng module; locked Bitsy và trường hợp thiếu prerequisite.
- Đang đọc/lỗi đọc, dữ liệu tiếng Việt cũ, năng lượng0 vẫn được vào địa điểm.
- Bản xem trước ranh giới route, không thực thi game/lesson/SQLite/events.
- Intro read/saving/unknown và đường khám phá tạm trong phiên, không giả đã lưu.

Không thêm route nhà riêng/bến/Friends/Arena, phí vào làng, tài khoản/cloud restore,
quà chào mừng, currency hay Tutor bắt buộc. Không mở rộng ngoại lệ flattened scene
của R1-A thành chấp thuận toàn bộ art runtime.

## 2. Hợp đồng nguồn cần giữ

### ActivitySheet và điều hướng

| Source fact | Hành vi phải giữ |
|---|---|
| `ActivityDef` | id/name/tagline/description/host/needsPython/hasCreatorMode; sáu module theo registry |
| `ActivityStatus` | `progressLabel`, nullable stars, locked/lockReason/unlockLessonId, recommended, detailLines |
| Sheet cancel | pop null; không `activityOpened`, không trừ năng lượng |
| Unlocked action | pop `open`; owner gọi `openActivity(context,module)` |
| Locked + prerequisite | pop `lesson:<id>`; owner mở MainQuestHome với `openLessonId` thật |
| Locked + không prerequisite | không nút mở/không đoán ID, vẫn đóng được sheet |
| `openActivity` | emit `activityOpened` với source `main_map` và activity_id của module được mở, rồi push home |
| Bitsy → bài cần học | activityOpened thuộc **main_quest**, không phải bug_hunter |
| MainQuestHome `openLessonId` | đánh dấu/scroll tới bài; **không tự gọi `_open(lesson)`**, không bỏ qua khóa bài |
| Phí | chỉ bắt đầu bài/màn/lượt mới gọi `spendEnergy`; sheet/home/list entry không trừ phí |

`activityOpened` thật có thể tạo notices/achievement effects. R56 không phát sự
kiện thật; log RAM không chứng minh idempotency của event/repository. Không suy
“không mất năng lượng” thành “entry không có tác động tiến độ” trong runtime.

### Trạng thái sáu địa điểm

| Module | Facts được source tính |
|---|---|
| Main Quest | Số lesson hoàn thành thuộc chapter hiện có; lesson chưa hoàn thành đầu tiên; chapter number/title |
| Maze | Completed level count; total stars; tổng levels×3; số custom levels nếu có |
| Dragon | Record hoặc phân biệt chưa chơi/chưa có sao; coins và runs |
| Catch Stars | Record; `atlas_total`; số chòm có threshold≤total, không dựa vào score |
| Bitsy | Khóa theo `packs.first.requiresLesson`; lesson number/title thật; nếu mở thì puzzles/stars/bugs |
| Achievement House | Unlocked/catalog badges; unseen count nếu>0; số secret badges trong catalog, không tiết lộ tên secret chưa đạt |

Content pin có12lesson,10maze levels,12puzzles/20bugs,15badges/3secret và8constellations.
Đó là tổng từ source; số đã hoàn thành trong UI là **fixture**, không phải tài khoản.
`mq1_03` hiện là prerequisite đọc từ JSON, không được hardcode vào UI. Model test
thay prerequisite thànhmq1_06 để kiểm tra điều hướng còn theo dữ liệu.

### Welcome nguồn

Ba host Robo/Py/Pip và ba chủ đề được giữ. Source có nút next, bước cuối pop;
`_showIntro` await dialog rồi gọi `setIntroSeen()`. Dialog barrier không dismiss
bằng tap; đoạn source này không có PopScope chặn system Back. Không có thực nghiệm
Android Back trong r56, không suy UI mới là hành vi hiện hữu.

`SettingsService._set` đổi `_values` và notify **trước** await repository.put.
Vì vậy “đã thấy trong RAM” không đồng nghĩa durable write. Không có receipt/reconcile
contract như các proposal bên dưới trong source được pin.

## 3. Đề xuất mới, tách khỏi source

**D56-P1 — Localization và status presentation.** ActivityDef/status hiện có các
chuỗi tiếng Việt; không parse chuỗi như `3/10 màn` để sinh English. `catalog.json`
trích canonical VI; EN là bản dịch thiết kế. Lesson EN tái sử dụng r43 sau khi so
ID/title VI. UI proposal dùng facts có kiểu để format metrics theo locale:
`phase, locked, unlockLessonId, stars, record, nextLessonId, metrics[]`.
Đây là shape JS của study, **không phải field đã có trong ActivityStatus**.

Trước runtime phải có bounded order quyết định cách đưa locale/facts vào presenter
hoặc module.status. Không tự thay interface/core/schema dưới nhiệm vụ020. Trong
thời gian còn legacy strings: giữ nguyên và gắn nhãn “Source information · Vietnamese”;
không gọi toàn bộ sheet đã EN, không bịa con số để lấp chỗ trống. Default theo system
locale VI/EN, reviewer override không ghi preference. App đã có Settings override,
r56 không tạo một hệ locale riêng trong runtime.

**D56-P2 — Welcome completion.** Có nút previous để đọc lại. Không tick seen khi
mở intro hoặc đọc bước1/2. Final Continue vào saving; chỉ ACK trong study mới đặt
seen. Unknown cho read-back hoặc “khám phá trong phiên này”; lựa chọn sau không
được quảng cáo là đã lưu. Read-error cũng có đường session-only. Late callback
sau khi rời/retry/đổi fixture bị loại bằng token theo session.

Đây là UX proposal và state machine RAM. Không backend, không durable exactly-once,
không giải pháp sửa cơ chế optimistic settings hiện tại. Muốn triển khai phải chốt
write failure/relaunch semantics riêng, không lén sửa Settings của020. Không tự
cam kết restore tài khoản hoặc đồng bộ nhiều thiết bị.

**D56-P3 — Nội dung Welcome.** Copy rút gọn, nói rõ mở địa điểm miễn phí, hồi1energy/
10phút theo config, Python không bắt buộc cho mọi game; nhắc Tutor có bảng để cùng
viết/vẽ trong lesson. Không ép vào lesson đầu tiên. Không lặp lời hứa “không mua bán”
vô thời hạn từ source cũ để phủ định roadmap shop/house/visit; không thêm commerce
ở đây. Nút xem lại lời chào trên host chỉ là lối thử trong study, chưa có runtime order.

**D56-P4 — Async ownership.** Map/controller vẫn sở hữu status; panel nhận snapshot
và callback retry, không tự mở thêm repository reads song song. Loading/error giữ
identity của địa điểm nhưng không giả ready/unlocked. Demo callback dùng token+ID;
retry/close/route/fixture mới loại response cũ. Không fake retry thành success bằng
setTimeout: phải dùng công cụ mô phỏng hoặc test callback rõ ràng.

## 4. Bố cục 2,5D và tương tác

- Khung bảng gỗ, giấy sáng, nút có độ dày; chữ hoàn toàn front-facing. Không đưa
  text/cost/status vào artwork. Scene crop chỉ làm không gian giới thiệu, không là
  nút bản đồ hoặc geometry proof. Py/Bitsy mới, Robo/Pip giữ các study r50/r54.
- Normal text: scene/host ở đầu bảng, title/tags/status rồi lời host. Một scroll
  owner cho body; footer action luôn ngoài scroll, không phủ lên body.
- Font≥1.5×: panel mở rộng full phone, **đưa nội dung lên trước artwork**; không
  co font hoặc thu nhỏ avatar để ép mọi thứ vào một màn. Artwork vẫn cuộn tới được.
- Font1/1.3/2× dùng computed size thật. Tên dài wrap, không ellipsis/FittedBox.
  Buttons≥48px; action text wrap tự nhiên. Close luôn rõ, không cần swipe để thoát.
- Header dùng nhãn ngắn “Study · RAM” ở phone, reviewer controls tách ra ngoài.
- Welcome không có nhấn nền để kết thúc; Escape lùi bước khi ready và page>0.
  Không claim giống system Back của Flutter. Continue và đường session-only khi
  read/save lỗi luôn reachable; không bắt buộc mua hoặc kết nối tài khoản.
- Panel sheet: close/Escape không mở route; Enter kích hoạt button native.
  Tab đi qua nút và vùng body có thể cuộn bằng bàn phím; vòng focus nằm trong
  phone panel. Nội dung nền inert. Focus về đúng nút địa điểm sau cancel/return.
- Cùng geometry: khôi phục scroll±0.5px. Khi locale/scale đổi geometry: clamp và
  bảo đảm nút nhận focus nhìn thấy, không ép pixel invariance sai.
- Study dùng **phone-local role=dialog, aria-modal=false**, vì workbench ngoài
  phone vẫn tương tác. Đây không phải kiểm chứng Flutter semantics/modal barrier
  hoặc screen reader; runtime phải dùng semantics/focus scope phù hợp thật.
- Không có animation lặp, auto-advance, pulse hoặc camera chuyển động. Không cần
  giả nút calm-mode; không đo haptics, audio hay FPS.

## 5. Ranh giới thiết kế và kiểm chứng

R56 route preview nói rõ chỉ là boundary: activity home hoặc MainQuest lesson list
với highlighted ID. Không nhúng game cũ để giả màn Flutter đã được sửa. r43 là
tham chiếu màn chọn bài, không phải kết quả điều hướng runtime của r56.

[Model receipt](evidence/model-checks.json):36checks+18zero-charge combinations.
[Browser receipt](evidence/browser-checks.json):21fixtures×2viewports×2locales×3scales,
fonts/targets/overflow/footers, welcome states, sáu open/cancel/route-return flows,
legacy status, zero energy và callback stale. [Static](evidence/static-checks.json)
kiểm nguồn/catalog/art/links/scope. Không Dart/SQLite/device/voice/award acceptance.

**CODE020 giữ nguyên scope và đang sửa checks.** R56 không cấp runtime R1-B order,
không sửa task020/CI/SDK/deps, không thêm lại diagnostics011. R1-B runtime cần:
status localization contract, intro write semantics, image/painter pack, các test
Flutter và before/after cùngSHA; review R1-A riêng trước khi quyết định bước triển khai.
