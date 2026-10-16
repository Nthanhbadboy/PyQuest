# P06 · Ghi chú bàn giao, không phải work order

2026-10-16 · Đọc cùng [DESIGN](DESIGN.md), [README](README.md), [manifest](manifest.json).
**Không tự cấp quyền triển khai Flutter/social/backend từ tài liệu này.**

## 1. Nguồn và phạm vi chính xác

| Nguồn | Điều được dùng | Điều không suy ra |
|---|---|---|
| `docs/PRODUCT_VISION.md` §16.1 | Bạn bè tùy chọn, hồ sơ/kệ theo quyền, phản hồi có kiểm soát | Đã có identity/API/quyền production |
| §16.2 | Đội nhóm, tác phẩm thành nội dung cho bạn chơi, triển lãm | P06 đã chạy UGC hoặc có matchmaking |
| §16.3 | Quà/danh hiệu xã hội khác thành tích; không ép đáp lễ | Giá, loại tiền, tỷ lệ/quota hoặc quyền mua được duyệt |
| §16.4 | Tranh/thiệp/quà tự tạo, album, quà lập trình về sau | Sáu ô sticker là toàn bộ Creator Mode cuối cùng |
| §16.5 | Privacy/consent/moderation/block/report/transaction safety | Một nút khiên hoặc checkbox chứng minh an toàn/pháp lý |
| `result-adventure-prototype` / P05 | Art mê cung, First Steps, một lối sang mẫu solo | Chuyển tiến trình, ownership hay kết quả giữa hai prototype |
| `shared-l10n/locale-core.mjs` | `normalizePreference`, `resolveLanguage`, `storageKey` | Dùng hàm dịch heuristics cho nội dung do người dùng tạo |

Base design khi bắt đầu: `a9ffa1c`. Nhánh code quan sát lúc đầu: `553e9ac`.
Đã fetch lại bằng refspec tường minh trước bàn giao: **`5fb7fff`**, sau commit nhận r7
`cdbc4a9`. Commit mới ghi **vòng 2 (1/2)** cho codec/owner/wait/locale data.
Đây là **ghi nhận có tiến triển**, không phải review hoặc acceptance mới của PQC-010.
Không thay review r7 bằng verdict PASS. Không sửa coordinator/header/work order.

## 2. Mô hình đang chạy — chỉ là simulation

`SocialSession` là mô hình thuần, mỗi phiên bắt đầu bằng một fixture. Dữ liệu hư cấu;
không import provider của Flutter hoặc schema social có thẩm quyền.

| Dữ liệu mẫu | Quy tắc hiện tại |
|---|---|
| `friends: Set<may/bo/la>` | Chỉ thêm qua accept incoming hoặc workbench resolve pending; block xóa friendship |
| `requests[id]` | incoming / pending / accepted / declined / canceled; không tự chuyển vì thời gian |
| `privateProfiles`, `heldWorks`, `mode` | Guards cho hình minh họa và hành động; không thay ACL server |
| `audience`, `displayed`, `previewAsFriend` | Riêng tư mặc định; viewer chỉ có món được chọn nếu audience friends |
| `reactions[workKey]` | Một semantic compliment hiện tại, thay thế chứ không cộng lượt |
| `draft` | paper, wish, sáu slots, revision; undo tối đa 30, revision tăng cả khi undo |
| `mail[]` | Gift snapshot hoặc sample play invitation; pending/delivered/failed/declined/canceled |
| `reports[]` | person + controlled reason + **local-only**, deduplicate cùng cặp trong phiên |

`window.__p06` cung cấp snapshot clone phục vụ kiểm tra, **không phải API sản phẩm**.
Không nhận UGC/JSON tùy ý, không thực thi script, không dùng hash để chứng minh ownership.

### Invariants cần giữ khi port

1. Chọn bạn hoặc đổi preview chưa phải gửi. Send phải kiểm lại quyền ngay khi thực hiện.
2. Gửi thiệp tạo snapshot, không giữ reference tới draft đang sửa. Edit sau gửi không đổi thư cũ.
3. Bấm gửi lặp cùng revision/recipient không tạo thêm thư trong phiên. Retry lỗi giữ cùng ID.
4. `gift-${recipient}-${revision}` chỉ là key mẫu. Production cần idempotency key, authenticated actor,
   recipient, payload hash/version, server receipt và atomicity — không copy ID này làm transaction system.
5. Play demo giới hạn một record theo người nhận trong một fixture. Đây không phải luật mời lại/cooldown của sản phẩm.
6. Block bỏ friendship, hủy request và pending/failed mail của người đó; late resolve không khôi phục thư.
7. Unblock không tự accept lại. Report vẫn được phép mở sau block, và không báo “đã gửi moderator” khi chỉ lưu cục bộ.
8. Người nhận không hợp lệ **không được thay ngầm bằng người đầu tiên trong dropdown**. Chọn người mới phải là ý định mới rõ ràng.
9. Hide/private/moderation phải lọc tại mọi surface: thẻ sân, profile, detail, owner-as-friend; không chỉ che bằng CSS.
10. Locale/navigation/font/motion không được gọi send, grant reward hoặc dựng lại session. Load fixture/reload mới reset theo nhãn rõ.
11. Không có `score`, `rank`, `currency`, `purchase`, `reward grant` trong model social này. Badge hiển thị là fixture.

**Giới hạn:** visibility trong DOM không xóa asset đã cache và không bảo vệ dữ liệu
trong source JavaScript. Tất cả tên/tác phẩm đều giả lập. Không dùng bằng chứng này
để nói người lạ không thể truy cập dữ liệu thật.

## 3. Đề xuất dữ liệu production — chưa là API

Các tên dưới là **khái niệm đề xuất**, không phải DTO đã tồn tại trong app:

- `ProfileSummary`: opaque actor ID, nickname đã kiểm duyệt, avatar cho phép, relationship state,
  quyền của viewer và revision. Không đưa email, trường, vị trí, ngày sinh vào card bạn.
- `SharedWork`: owner ID, work ID/version, visibility, moderation state, safe thumbnail/ref,
  loại tác phẩm và cách mở được phép. Không trả private body/title/thumbnail rồi mong client tự che.
- `RelationshipRequest`: requester/recipient, request ID, lifecycle, revoke reason và server clock nếu có expiry.
- `GiftDraft`: versioned composition, locale-independent stamp IDs, template message ID + version;
  nếu thêm free text phải có content locale và moderation riêng, không “tự dịch” dữ liệu người dùng.
- `GiftTransaction`: durable ID, sender/recipient, immutable asset/version, delivery/acceptance state,
  receipt, cancellation/reversal; paid/free item kinds tách rõ. Không receipt thì không ghi “đã nhận”.
- `SafetyReport`: safe evidence references, reason, receipt/queue state, access policy; không tự chụp/gửi dữ liệu nhạy cảm ngoài ý định người báo cáo.
- `PlayInvitation`: activity/variant, permissions, version, expired/canceled/accepted; chỉ join service có quyền mới cấp room/match/session ID.

ACL phải **tách riêng** ai được tìm, mời kết bạn, xem profile, xem từng work, gửi quà,
gửi play invite và sửa đội. `privateProfiles` trong mẫu gộp nhìn/nhận cho dễ thử,
**không là kiến trúc backend được duyệt**. Chặn hai chiều, quyền phụ huynh, quota,
rate limit, abuse review và quyền thu hồi cần được thiết kế/kiểm trên server.

### Loading, thu hồi quyền và đồng bộ

- Unknown/loading không dùng hồ sơ gần nhất của tài khoản khác làm placeholder. Clear viewer-scoped cache khi đổi account.
- Offline thật: draft cục bộ cần trạng thái lưu riêng; không giả online success. Mẫu hiện chỉ có fixture offline, không Service Worker.
- Revoke/quarantine khi đang mở modal: revalidate khi confirm và khi nhận acknowledgement; thu hồi title/thumbnail/action thích hợp.
- App background/restart: phục hồi từ receipt/draft version được xác nhận, không gửi lại do mount/rebuild/locale callback.
- Received khác accepted/kept. Prototype chỉ mô phỏng outcome cho outbox; sản phẩm cần inbox phía nhận với giữ/từ chối/giới hạn người gửi.
- UGC playable cần sandbox tài nguyên, validation, moderation và version pinning trước khi đi vào engine; ảnh P06 không chứng minh khả năng chạy code an toàn.

## 4. A11y và localization

- Native button/select/dialog; hit target đo tối thiểu 48×48 CSS px. Không tương tác bằng hover/drag riêng.
- Dialog có heading/name, Tab/Shift+Tab wrap, Escape, return focus về nguồn mở khi còn tồn tại.
  Sau đổi route, focus heading chính; sau edit thiệp, giữ focus control/slot vừa dùng.
- Sáu ô có tên vị trí và stamp hiện tại. Stamp palette có tên và `aria-pressed`; readonly card có mô tả giấy/hình, không chỉ hình trang trí câm.
- Không dùng màu đơn độc phân biệt pending/failed/declined; có chữ và lựa chọn tương ứng.
- VI/EN authored trong `copy.mjs`. Missing key/parameter phải lỗi, không im lặng để UI nửa ngôn ngữ.
- Ngôn ngữ mặc định theo **danh sách system có thứ tự**, lấy supported candidate đầu; không hỗ trợ thì English.
- Raw preference `system` không bị thay bằng ngôn ngữ resolved. Storage lỗi vẫn đổi trong phiên và nói không lưu được.
- Nicks Mây/Bo/Lá, code LA006, IDs, payload composition và state không dịch. Wish/compliment là template authored, được render theo locale.
- LocalStorage chỉ `pyquest.prototype.language.v1`, dùng chung các mẫu; không ghi gift/report/contact vào storage.
- Font scale 1/1.3/2 ở prototype là CSS, **không tương đương chứng cứ Flutter textScaler**. Cần kiểm text scale và screen reader trên thiết bị thật sau port.
- Reduced motion theo hệ thống OR lựa chọn tại chỗ; không âm thanh. Không thêm voice dependency vào scope này.

Axe không có violation trong 18 audit đã chạy nhưng còn `color-contrast` incomplete
trên gradient/ảnh. Đã sửa các lỗi contrast được phát hiện và kiểm ảnh thủ công;
**chưa tuyên bố đạt toàn bộ WCAG hoặc trải nghiệm assistive technology**.

## 5. Slice triển khai đề xuất (đều chưa được cấp quyền ở P06)

| Slice đề xuất | Đầu ra | Gate trước khi làm / trước ship |
|---|---|---|
| A. Flutter local preview | Shell 7 màn + model fixture, localization, accessibility, card composition | Work order allowlist riêng; không route vào app live, không network/economy |
| B. Private creation | Draft durable, own shelf, export/upload đã kiểm soát | Storage/version/recovery/quotas; quyền sở hữu và xử lý nội dung |
| C. Friend/visibility | Invitation lifecycle, accepted friends, viewer ACLs | Identity/consent/server rules, abuse/rate limits, privacy review |
| D. Gifts & safety | Inbox/outbox, immutable snapshots, accepted/declined, block/report | Transaction authority, moderation/receipt, parental controls nếu cần; thực sự gửi báo cáo |
| E. Playable visits & teams | Mở UGC được phép, invite sang activity, đóng góp đội | Sandbox + game session authority + P07; không để social UI tự chấm thắng |
| F. Shop & rich gifts | Quà mua sẵn, album, quà lập trình | Economy/receipts/refund/legal/platform review và chỉ thị phạm vi mới |

Tên thư mục có thể đề xuất cho A: `app/lib/design_preview/friends_showcase/` và test tương ứng.
Đây **không phải allowlist đang hiệu lực**. Cần work order được cấp trước khi tạo file app.
Không thêm package backend, sửa rule economy, di chuyển app shell hoặc đổi gameplay dựa vào P06.

## 6. Prompt bàn giao cho agent code

> Đọc gói `docs/design/friends-showcase-prototype/` và blueprint P06 trên commit thiết kế mới.
> Đây là **design reference**, chưa phải lệnh triển khai social runtime. Tiếp tục đúng
> phạm vi PQC-010/014/015 đang có hiệu lực; không chuyển task/coordinator vì thấy P06.
> Chạy mẫu và đọc DESIGN/IMPLEMENTATION_NOTES để góp ý câu hỏi về schema/ownership/port.
> Giữ private-first, friend acceptance, card snapshot, retry/idempotency, block/report,
> locale/a11y, quà khác kỹ năng. Không copy JS fixture guards thành authorization server.
> Khi muốn nhận slice Flutter local preview, trả lời đề xuất allowlist và test riêng để
> được cấp phạm vi; không tự nối auth, social API, payments, matchmaking hoặc UGC execution.
> Commit/evidence trả về trên nhánh code hiện có, không tạo nhánh phối hợp thứ ba.

## 7. Acceptance cho lần port tương lai

Giữ được 12 fixture, 7 route, bốn dialog và đường solo; chứng minh bằng widget/state tests
và ảnh thiết bị. Thêm negative tests cho revoked permission, blocked stale confirmation,
draft recovery, wrong account cache, duplicate server receipt, reports thực sự queued/sent,
recipient refusal và moderation on every surface. Các test 21/414 của HTML là reference,
**không thay CI Flutter, end-to-end hai tài khoản hoặc kiểm an toàn production**.
