// Design fixtures only. No runtime, user account, transaction or model calls.
// Every user-facing screen string is an explicit VI/EN pair.
const pair = (vi, en) => ({vi, en});
const state = (id, name, title, body, action, next, rows = []) => ({id, name, title, body, action, next, rows});
const row = (a, b) => ({label: a, value: b});
window.SCENES = [
  {
    id: 'w07-interior', group: pair('Nhà & xây dựng', 'Home & building'), title: pair('Góc sáng tạo', 'Creative corner'),
    subtitle: pair('Nhà mình · Sắp xếp', 'My home · Arrange'),
    alt: pair('Phòng cắt mái với bàn làm việc, ghế có dấu chọn và lối cửa bên phải.', 'Cutaway room with a workbench, selected chair and a doorway on the right.'),
    source: 'W02/W07 · housing layout / occupancy — proposed, not shipped',
    note: pair('Ghế và dấu chọn đang dính trong JPEG. Cửa nhìn xuống mái nhà khác; cần sửa nối sàn/ngưỡng cửa trước asset production. Chưa có footprint hay occluder đo được.', 'Chair and selection mark are baked into the JPEG. The doorway looks toward a lower roof; floor/threshold connection needs correction before production. No measured footprint or occluder.'),
    brief: 'Cutaway coastal cottage, workbench, movable chair, cyan footprint, clear exit, ivory/walnut/teal, warm upper-left light; no UI text.',
    states: [
      state('draft', pair('Bản nháp', 'Draft'), pair('Một chỗ để làm điều mình thích', 'A place to make things'), pair('Ghế gỗ đang được chọn. Xem trước không thay đổi nhà đã lưu.', 'Wooden chair selected. Previewing does not change your saved home.'), pair('Xem bước lưu', 'Preview saving'), 'saved', [row(pair('Vật đang chọn', 'Selected object'), pair('Ghế gỗ', 'Wooden chair')), row(pair('Lối ra', 'Exit path'), pair('Cần kiểm footprint thật', 'Needs actual footprint check'))]),
      state('blocked', pair('Chắn cửa', 'Blocked doorway'), pair('Để trống lối ra nhé', 'Keep the doorway clear'), pair('Mẫu trạng thái: vị trí đặt chắn lối. Chưa lưu hoặc tiêu vật liệu. Ảnh không phải kết quả kiểm va chạm.', 'State fixture: placement blocks the exit. Nothing saved or spent. The image is not collision evidence.'), pair('Chọn chỗ khác', 'Choose another spot'), 'draft'),
      state('unsaved', pair('Rời khi chưa lưu', 'Unsaved changes'), pair('Giữ bản nháp hay bỏ thay đổi?', 'Keep your draft or discard changes?'), pair('Quay lại sắp xếp sẽ giữ bản nháp. Bỏ thay đổi chỉ tác động bản nháp, không xóa đồ đã sở hữu.', 'Returning to arrange keeps the draft. Discarding affects only the draft, not owned furniture.'), pair('Giữ bản nháp', 'Keep draft'), 'draft'),
      state('saved', pair('Lưu thành công', 'Saved'), pair('Bố trí đã lưu · mẫu', 'Layout saved · fixture'), pair('Trong app thật chỉ hiện sau receipt thành công. Vẫn còn ghế trong quyền sở hữu; có thể di chuyển lại.', 'In the app, show only after a successful receipt. You still own the chair and can move it again.'), pair('Tiếp tục sắp xếp', 'Arrange again'), 'draft')
    ]
  },
  {
    id: 'w03-project', group: pair('Nhà & xây dựng', 'Home & building'), title: pair('Mở góc sáng tạo', 'Expand your creative corner'), subtitle: pair('Dự án · Xem trước', 'Project · Preview'),
    alt: pair('Nhà nhỏ với khung phòng xanh trong, huy chương và vật liệu đặt tách nhau.', 'Small cottage with a translucent room outline, separate medal and material displays.'),
    source: 'W03 · recipe + inventory + durable build receipt — proposed; numbers from P06C fixture only',
    note: pair('Hình biểu đạt điều kiện khác chi phí, không định nghĩa recipe. Nền trong preview còn là cỏ và nối cửa chưa rõ; phải sửa geometry trước dựng phòng thật.', 'Art separates eligibility from costs, not a recipe definition. The preview still has a grassy floor and unclear connecting doorway; geometry must be corrected before building a real room.'),
    brief: 'One-room cottage extension preview, solid ground, permanent medal separate from wood/cloth cost props, no baked price or quantity.',
    states: [
      state('missing', pair('Thiếu vật liệu', 'Missing materials'), pair('Thêm một phòng để thử tác phẩm', 'A new room to try your creations'), pair('Ví dụ thiết kế P06C, không phải giá trong APK. Theo dự án không tiêu vật liệu.', 'P06C design example, not an APK price. Following a project spends nothing.'), pair('Xem nguồn vật liệu', 'View material sources'), 'source', [row(pair('Điều kiện · giữ lại', 'Requirement · retained'), pair('First Steps · đã có (mẫu)', 'First Steps · earned (fixture)')), row(pair('Chi phí · dùng khi xây', 'Cost · spent on build'), pair('Gỗ 2/3 · Vải 2/2 (mẫu)', 'Wood 2/3 · Cloth 2/2 (fixture)'))]),
      state('source', pair('Nguồn kiếm', 'Material source'), pair('Phải có đường kiếm khả dụng', 'There must be an available source'), pair('Nguồn thưởng và recipe chưa chốt runtime. Không gán thắng Maze thành +gỗ, không khóa vòng tròn hoặc ép mua.', 'Reward sources and recipes are not finalized. Do not turn a Maze win into wood, create circular locks or require a purchase.'), pair('Về dự án', 'Back to project'), 'missing'),
      state('ready', pair('Đủ · xác nhận', 'Ready · confirmation'), pair('Xem kỹ phần sẽ dùng', 'Review what will be spent'), pair('Mẫu: dùng 3 gỗ và 2 vải, giữ huy chương. Chỉ trừ một lần khi xây thành công; đây không phải giao dịch thật.', 'Fixture: spend 3 wood and 2 cloth, retain the medal. Deduct once on successful construction; this is not a real transaction.'), pair('Xem trạng thái xử lý', 'Preview processing'), 'pending'),
      state('pending', pair('Chưa rõ kết quả', 'Unconfirmed result'), pair('Đang kiểm tra lần xây này', 'Checking this build'), pair('Không gửi lệnh xây mới. App phải kiểm lại cùng mã receipt; tài nguyên không được trừ lần hai.', 'Do not submit another build command. Recheck the same receipt; never deduct resources twice.'), pair('Xem mẫu đã xây', 'View completed fixture'), 'built'),
      state('built', pair('Đã xây', 'Built'), pair('Phòng mới đã sẵn sàng · mẫu', 'Your new room is ready · fixture'), pair('Hình vẫn là preview cũ, chưa có artwork trạng thái hoàn tất. App thật phải đổi cảnh và cho vào phòng dùng được.', 'The art is still a preview; completed-state art is missing. The app must update the scene and allow entry to a useful room.'), pair('Xem phòng mới', 'View the new room'), '@w07-interior')
    ]
  },
  {
    id: 'w09-visit', group: pair('Bạn bè & thú', 'Friends & pets'), title: pair('Ghé khu vườn', 'Visit the garden'), subtitle: pair('Khách · Khu được chia sẻ', 'Guest · Shared area'),
    alt: pair('Khách đứng ở cổng sân với bàn trồng cây và cửa phòng riêng đóng kín.', 'A visitor at a garden gate, a planting bench and a closed private-room door.'),
    source: 'W09 · host permissions + snapshot/session authority — proposed, no live backend',
    note: pair('Chỉ có một khách, không có chủ để tránh giả presence. Cần tách actor/props và không gửi phòng riêng xuống client khách. Invite/reconnect/moderation chưa đủ state.', 'One visitor, no host to imply presence. Separate actor/props and never send private rooms to unauthorized guest clients. Invite/reconnect/moderation states remain incomplete.'),
    brief: 'Shared coastal courtyard, guest gate and planting table, one visitor only, closed opaque private door, no online indicators.',
    states: [
      state('absent', pair('Chủ vắng', 'Host away'), pair('Chủ đang vắng · bản tham quan', 'Host away · tour snapshot'), pair('Xem khu đã được chia sẻ. Không phải cùng phiên; không thay đổi đồ hoặc cây của chủ.', 'Explore the shared area. This is not a live session; do not change the host’s objects or plants.'), pair('Xem quyền của khách', 'View guest permissions'), 'permissions'),
      state('permissions', pair('Quyền khách', 'Guest permissions'), pair('Chỉ trong khu đã được mời', 'Only within your invited area'), pair('Mẫu: được xem sân; không vào phòng riêng, không di chuyển đồ, không gửi quà tự động.', 'Fixture: view the garden only; no private-room access, moving objects or automatic gifts.'), pair('Trở lại tham quan', 'Return to tour'), 'absent'),
      state('revoked', pair('Thu hồi quyền', 'Access revoked'), pair('Quyền ghé nhà đã thay đổi', 'Visit permission has changed'), pair('Dừng tương tác và ẩn snapshot ngay. Rời nhà an toàn; không tiếp tục cho xem nội dung riêng qua ảnh cũ.', 'Stop interactions and hide the snapshot immediately. Leave safely; cached imagery must not reveal private content.'), pair('Về khu cộng đồng', 'Return to community'), '@w12b-friends-gifts'),
      state('offline', pair('Mất kết nối', 'Disconnected'), pair('Chưa xác minh lại quyền', 'Permission not reverified'), pair('Ẩn cảnh khi không xác minh được quyền. Không coi cache là bằng chứng vẫn được ghé hoặc chủ đang online.', 'Hide the scene when permission cannot be verified. Cache is not proof of continuing access or online presence.'), pair('Rời khu vườn', 'Leave the garden'), '@w12b-friends-gifts')
    ]
  },
  {
    id: 'w10-pet', group: pair('Bạn bè & thú', 'Friends & pets'), title: pair('Sân chơi của Miu', 'Miu’s play garden'), subtitle: pair('Thú của mình · Hoạt động nền', 'My pet · Baseline activities'),
    alt: pair('Mèo cam chơi bóng trong sân với bậc leo và góc nghỉ.', 'An orange cat playing with a ball, beside a ramp and resting nook.'),
    source: 'W10 · baseline pet state + optional device/model manager — proposed',
    note: pair('Pose chơi đang bake vào ảnh; trạng thái nghỉ chưa có art riêng. Mèo shop khác style mắt/giải phẫu, cần character sheet chung. Không có inference hoặc animation.', 'Playing pose is baked in; no separate resting art. Shop kitten differs in eyes/anatomy and needs a shared character sheet. No inference or animation.'),
    brief: 'Orange tabby playing with coral ball, grounded garden, ramp and shaded resting cushion, healthy baseline pet, no AI or purchase pressure.',
    states: [
      state('play', pair('Chơi nền', 'Baseline play'), pair('Chơi một chút nhé?', 'A little playtime?'), pair('Chơi, đi lại và nghỉ không cần mô hình AI. Hình chỉ minh họa pose, không phải animation đang chạy.', 'Play, movement and rest do not require an AI model. This is a pose illustration, not running animation.'), pair('Xem góc nghỉ', 'View resting state'), 'rest'),
      state('rest', pair('Nghỉ', 'Rest'), pair('Miu vẫn ổn khi bạn nghỉ', 'Miu is fine when you take a break'), pair('Không phạt pet vì bạn rời app. Cần pose nghỉ riêng; ảnh hiện tại vẫn là pose chơi.', 'No pet penalty for leaving the app. A separate rest pose is needed; the image still shows playing.'), pair('Chọn trò chơi', 'Choose a game'), 'play'),
      state('unsupported', pair('AI chưa hỗ trợ', 'AI unsupported'), pair('Chưa hỗ trợ hội thoại trên máy', 'On-device conversation unavailable'), pair('Vẫn chơi bình thường. Không âm thầm gửi cloud; câu trả lời kịch bản không được gọi là suy luận AI.', 'Baseline play remains available. No silent cloud fallback; scripted responses must not be called AI inference.'), pair('Về sân chơi', 'Back to play'), 'play'),
      state('memory', pair('Ký ức & riêng tư', 'Memory & privacy'), pair('Bạn kiểm soát ký ức game', 'You control game memory'), pair('Mẫu thiết kế: cần danh sách xem/xóa rõ ràng khi hệ thống thật tồn tại. Gallery không thu âm, lưu ký ức hay tải model.', 'Design fixture: provide inspect/delete controls when a real system exists. This gallery records no audio or memories and downloads no model.'), pair('Về sân chơi', 'Back to play'), 'play')
    ]
  },
  {
    id: 'w10b-pet-shop', group: pair('Bạn bè & thú', 'Friends & pets'), title: pair('Làm quen bạn mới', 'Meet a new companion'), subtitle: pair('Xem trước · Không giao dịch', 'Preview · No transaction'),
    alt: pair('Mèo xám trên thảm trong căn phòng chơi không có lồng.', 'A grey kitten on a rug in an open, cage-free playroom.'),
    source: 'W10b · catalog / device capability / parental consent / entitlement — proposed',
    note: pair('Không bake giá hoặc sale; trạng thái mua cần authority thật. Phụ huynh, restore/refund/pending chưa có tích hợp. Art mèo cần đồng bộ với W10.', 'No baked price or sale labels; purchases require real authority. Parent consent, restore/refund/pending are not integrated. Kitten art needs alignment with W10.'),
    brief: 'Humane companion showroom, grey kitten, play arch and woven bed, no cages or sale pressure; blank lower floor for separate capability UI.',
    states: [
      state('preview', pair('Xem khả năng', 'Capabilities'), pair('Biết rõ trước khi quyết định', 'Know what you are choosing'), pair('Hành vi nền: chơi và nghỉ. AI local: chưa xác nhận thiết bị. Giá/quyền lợi: chưa có dữ liệu, không bật mua.', 'Baseline: play and rest. Local AI: device support unverified. Price/benefits: unavailable, so purchase stays disabled.'), pair('Xem bước phụ huynh', 'Preview parent step'), 'parent'),
      state('parent', pair('Phụ huynh', 'Parent confirmation'), pair('Cần phụ huynh và dữ liệu thật', 'Parent approval and real data required'), pair('Không phải parental gate đang hoạt động. Chỉ cho xác nhận mua khi có giá, quyền lợi, capability và người lớn đã đồng ý.', 'This is not a working parental gate. Confirm only with price, benefits, capabilities and adult approval.'), pair('Quay lại xem', 'Back to preview'), 'preview'),
      state('pending', pair('Đang xác minh', 'Verification pending'), pair('Chưa xác nhận quyền sở hữu', 'Ownership not yet confirmed'), pair('Không mua lại khi đang chờ. Kiểm receipt cũ; hủy thao tác chờ không được giả là đã hoàn tiền.', 'Do not repurchase while waiting. Check the existing receipt; canceling a wait is not a refund.'), pair('Xem mẫu khôi phục', 'Preview restore state'), 'restore'),
      state('restore', pair('Khôi phục/lỗi', 'Restore/error'), pair('Chưa khôi phục được quyền', 'Could not restore access'), pair('Giữ biên nhận và cho kiểm tra lại qua nguồn thanh toán. Không cấp pet chỉ vì ảnh đã xuất hiện.', 'Retain the receipt and recheck the payment authority. Seeing an image does not grant ownership.'), pair('Về xem trước', 'Back to preview'), 'preview')
    ]
  },
  {
    id: 'w12-creator', group: pair('Sáng tạo & chia sẻ', 'Create & share'), title: pair('Xưởng của mình', 'My workshop'), subtitle: pair('Creator · Bản nháp riêng tư', 'Creator · Private draft'),
    alt: pair('Bàn làm việc có mô hình đường bi, khay thử và sổ phiên bản.', 'Workbench with a marble-run model, a testing tray and a version folio.'),
    source: 'W12 · creator draft/version/test result + sharing permissions — mixed existing module/proposed expansion',
    note: pair('Cơ cấu đường bi là prop khái niệm, chưa được test vật lý. Không thay code game hay đáp án theo hình; UI editor/timeline riêng còn thiếu.', 'Marble mechanism is a concept prop, not physics-tested. Do not change game code or answers to match art; dedicated editor/timeline UI remains missing.'),
    brief: 'Useful workshop with central marble-run workbench, distinct test tray, stored older prototype and folio; not achievement museum.',
    states: [
      state('draft', pair('Đang tạo', 'Creating'), pair('Thử ý tưởng của bạn', 'Try your idea'), pair('Bản nháp riêng tư. Chạy thử không tự lưu, xuất bản hay cấp huy chương.', 'Private draft. Testing does not automatically save, publish or award a medal.'), pair('Xem trạng thái chạy thử', 'Preview test state'), 'tested'),
      state('tested', pair('Chạy thử', 'Testing'), pair('Một bước thử, không phải xuất bản', 'A test, not a publication'), pair('Kết quả chạy phải đến từ engine. Gallery này không thực thi cơ cấu hoặc code; chỉ minh họa luồng.', 'Results must come from the engine. This gallery runs no mechanism or code; it illustrates the flow.'), pair('Xem bước lưu phiên bản', 'Preview version saving'), 'saved'),
      state('saved', pair('Đã lưu riêng', 'Saved privately'), pair('Phiên bản riêng · mẫu', 'Private version · fixture'), pair('Giữ phiên bản đã lưu khi chỉnh tiếp. Chia sẻ là bước riêng, cần quyền và kiểm duyệt tương ứng.', 'Keep the saved version while editing further. Sharing is separate and requires appropriate permission and moderation.'), pair('Xem bước chia sẻ', 'Preview sharing'), 'moderation'),
      state('moderation', pair('Chờ duyệt', 'Awaiting moderation'), pair('Chưa hiển thị công khai', 'Not public yet'), pair('Pending không phải published. Tác phẩm riêng vẫn dùng được; chưa hiện cho khách khi chưa được phép.', 'Pending does not mean published. Your private work remains usable; guests cannot see it without authorization.'), pair('Trở lại bản nháp', 'Back to draft'), 'draft'),
      state('error', pair('Lưu lỗi', 'Save failed'), pair('Giữ nguyên ý tưởng của bạn', 'Keep your idea safe'), pair('Không xóa bản nháp. Khi lưu lại, kiểm phiên bản và receipt để tránh tạo bản sao ngoài ý muốn.', 'Do not discard the draft. On retry, check the version and receipt to avoid unwanted duplicates.'), pair('Về bản nháp', 'Back to draft'), 'draft')
    ]
  },
  {
    id: 'w12b-friends-gifts', group: pair('Sáng tạo & chia sẻ', 'Create & share'), title: pair('Góc gửi quà', 'Gift corner'), subtitle: pair('Cộng đồng · Không giả online', 'Community · No simulated presence'),
    alt: pair('Bàn gói quà dưới mái teal, có gói quà và hai ngăn thư.', 'Gift-wrapping bench under a teal canopy with a parcel and mail cubbies.'),
    source: 'W12/W09 · allowed gift catalog + recipient consent + durable send receipt — proposed',
    note: pair('Một gói quà không thay friend list/invite UI. Cần làm tiếp danh sách bạn, chặn/báo cáo và chọn người nhận. Không suy online từ ảnh.', 'One parcel does not replace friend-list/invite UI. Friend list, block/report and recipient selection remain. No presence inferred from imagery.'),
    brief: 'Coastal community packing pavilion, one parcel, blank tag, separate incoming/outgoing cubbies; no fake online crowd or badges.',
    states: [
      state('draft', pair('Chuẩn bị', 'Prepare'), pair('Một món quà, một lựa chọn rõ ràng', 'A gift, with a clear choice'), pair('Chọn đúng người và món được phép tặng. Không gửi thật từ gallery; quà không cấp huy chương kỹ năng.', 'Choose the right person and an eligible gift. Nothing is sent from this gallery; gifts do not grant skill medals.'), pair('Xem bước xác nhận', 'Preview confirmation'), 'confirm'),
      state('confirm', pair('Xác nhận', 'Confirmation'), pair('Xem lại trước khi gửi', 'Review before sending'), pair('Mẫu giao diện chưa có người nhận hoặc món quà thật, nên không có nút giao dịch hoạt động.', 'This fixture has no real recipient or item, so no transaction action is enabled.'), pair('Xem mẫu chờ nhận', 'Preview pending state'), 'pending'),
      state('pending', pair('Chờ phản hồi', 'Awaiting response'), pair('Chờ người nhận quyết định', 'Let the recipient decide'), pair('Không gửi thêm bản sao khi mạng chậm. Nhận hoặc từ chối phải theo cùng giao dịch, không tự cấp vật phẩm.', 'Do not send duplicates on slow networks. Accept/decline must use the same transaction; never grant items locally.'), pair('Xem mẫu từ chối', 'Preview declined state'), 'declined'),
      state('declined', pair('Từ chối', 'Declined'), pair('Tôn trọng lựa chọn của bạn', 'Respect your friend’s choice'), pair('Không gây áp lực gửi lại hoặc phạt người nhận. Chính sách trả vật phẩm phải theo authority, không do ảnh quyết định.', 'Do not pressure a resend or penalize the recipient. Return policy belongs to the authority, not the artwork.'), pair('Về góc quà', 'Back to gift corner'), 'draft')
    ]
  },
  {
    id: 'w05-maze', group: pair('Chơi & kết quả', 'Play & results'), title: pair('Robot Maze', 'Robot Maze'), subtitle: pair('Luyện đường đi · Không đổi luật', 'Path practice · Rules unchanged'),
    alt: pair('Sân ô đá với robot và cờ đích, vật cản teal.', 'A stone-tiled board with a robot, goal flag and teal obstacles.'),
    source: 'W05 · Maze engine / level data owns tiles, collisions and outcome; picture is not a playable level',
    note: pair('Lưới AI không khớp dữ liệu màn và có bảng trống bake phía dưới. Phải dựng tile/actor/obstacle theo engine, không lấy pixel ảnh làm collision. Robot khác W06, cần đồng bộ.', 'AI grid does not match level data and has a baked blank board below. Rebuild tiles/actors/obstacles from engine data, not image pixels. Robot differs from W06 and needs alignment.'),
    brief: 'Readable raised stone maze, robot start and coral goal, teal obstacles, coastal garden, no baked answers; illustrative level only.',
    states: [
      state('ready', pair('Chuẩn bị', 'Ready'), pair('Lập kế hoạch trước khi chạy', 'Plan before running'), pair('Scene minh họa, không phải level có thể chơi. Ô, hướng robot và lệnh thật phải đọc từ dữ liệu Maze.', 'Illustrative scene, not a playable level. Tiles, robot direction and real commands come from Maze data.'), pair('Xem trạng thái tạm dừng', 'Preview paused state'), 'paused'),
      state('paused', pair('Tạm dừng', 'Paused'), pair('Bạn có thể nghỉ một chút', 'You can take a break'), pair('Giữ chương trình và lượt đang dở. Không chạy timer nền hoặc tiêu lượt mới chỉ vì mở lại màn.', 'Keep the program and current attempt. Do not run a background timer or spend another attempt just for reopening.'), pair('Về chuẩn bị', 'Back to ready'), 'ready'),
      state('retry', pair('Chưa tới đích', 'Not at the goal'), pair('Xem lại một bước thôi', 'Review just one step'), pair('Lỗi cần chỉ đúng lệnh do engine báo. Không tự vẽ đường đúng hoặc đổi vật cản để làm ảnh trông thắng.', 'Show the command reported by the engine. Do not invent a solution path or move obstacles to depict a win.'), pair('Sửa kế hoạch', 'Revise the plan'), 'ready'),
      state('complete', pair('Kết thúc lượt', 'Attempt ended'), pair('Đọc kết quả đã xác minh', 'Read the verified result'), pair('Không cấp vật liệu dự án từ artwork. Màn kết quả chỉ đọc dữ kiện do hoạt động trả về.', 'Artwork grants no project materials. Results only display data returned by the activity.'), pair('Xem màn kết quả', 'View results'), '@w06-result')
    ]
  },
  {
    id: 'w05-dragon', group: pair('Chơi & kết quả', 'Play & results'), title: pair('Dragon Jump', 'Dragon Jump'), subtitle: pair('Góc nhìn ngang · Có chiều sâu', 'Side view · Layered depth'),
    alt: pair('Rồng nhỏ ở bục đá, các bục nhảy trên khe dung nham và biển phía xa.', 'Small dragon on a stone platform, jump ledges over lava gaps and a distant sea.'),
    source: 'W05 · Dragon engine / platform geometry / attempt result; artwork not a collision map',
    note: pair('Bục đá và rồng bake cùng ảnh, không có animation. Side-view là có chủ đích; tỷ lệ bước nhảy phải do engine quyết định. Phong cách rồng mềm hơn cảnh khác, cần calibrate.', 'Platforms and dragon are baked together, with no animation. Side view is intentional; jump distance belongs to the engine. Dragon rendering is softer than other scenes and needs calibration.'),
    brief: 'Side-view friendly coral dragon, thick basalt jump platforms, warm amber lava, layered turquoise horizon; same material family, no pixel art.',
    states: [
      state('ready', pair('Chuẩn bị', 'Ready'), pair('Nhìn khoảng cách, thử từng bước', 'Watch the gap, try one step'), pair('Giữ camera ngang để đọc luật. Không dùng khoảng cách trong tranh làm thông số màn hoặc đáp án.', 'Keep a side camera for readable rules. Do not use distances in the painting as level parameters or answers.'), pair('Xem trạng thái tạm dừng', 'Preview paused state'), 'paused'),
      state('paused', pair('Tạm dừng', 'Paused'), pair('Dừng lại mà không mất bản nháp', 'Pause without losing your draft'), pair('Giữ code/lượt; giảm chuyển động không được khóa điều khiển. Gallery không mô phỏng game physics.', 'Keep code/attempt; reduced motion must not disable controls. This gallery does not simulate game physics.'), pair('Về chuẩn bị', 'Back to ready'), 'ready'),
      state('retry', pair('Thử lại', 'Try again'), pair('Chưa qua lần này, vẫn có cách thử', 'Not this time; there’s another try'), pair('Lời động viên không giả điểm hoặc thưởng. Chỉ trừ lượt/năng lượng theo luật hiện có, không theo hiệu ứng.', 'Encouragement invents no score or reward. Attempts/energy follow existing rules, not visual effects.'), pair('Thử kế hoạch khác', 'Try another plan'), 'ready'),
      state('complete', pair('Kết quả', 'Result'), pair('Kết thúc lượt · mẫu', 'Attempt ended · fixture'), pair('Dùng kết quả do game trả về; không tự gán thắng chỉ vì rồng đang đứng an toàn trong concept.', 'Use the game’s result; a safe-looking dragon in a concept is not proof of a win.'), pair('Xem màn kết quả', 'View results'), '@w06-result')
    ]
  },
  {
    id: 'w06-result', group: pair('Chơi & kết quả', 'Play & results'), title: pair('Sau một lượt chơi', 'After a play session'), subtitle: pair('Kết quả · Dữ kiện trước hiệu ứng', 'Results · Facts before effects'),
    alt: pair('Góc nghỉ cạnh sân luyện tập với robot, ghế và bục trống.', 'A practice-garden rest corner with a robot, bench and empty plinth.'),
    source: 'W06 · activity outcome + existing event reward notices; new grant/claim authority not implemented',
    note: pair('Bục trống dùng được cho thắng/thử lại, không ép mọi người nhận cúp. Robot chưa cùng character sheet với Maze. Không có receipt/grant thật.', 'Empty plinth supports success/retry without giving everyone a trophy. Robot is not yet on the same character sheet as Maze. No real receipt/grant.'),
    brief: 'Calm rest terrace with robot and empty plinth, no trophy, coins, stars or victory baked in; support honest result overlays.',
    states: [
      state('verified', pair('Đã ghi nhận', 'Recorded'), pair('Bạn đã thử và học thêm một chút', 'You tried and learned something'), pair('Mẫu: hoạt động đã ghi nhận kết quả tự động. Không đặt thêm nút Nhận lần hai hoặc tự sinh vật liệu.', 'Fixture: the activity recorded its result automatically. Do not add a second claim or invent materials.'), pair('Về góc sáng tạo', 'Go to creative corner'), '@w07-interior'),
      state('pending', pair('Chờ xác nhận', 'Awaiting confirmation'), pair('Kết quả chưa được xác nhận', 'Result not confirmed yet'), pair('Giữ cùng receipt, kiểm lại thay vì tạo lượt nhận mới. Có thể rời màn mà không xóa phần thưởng đang chờ.', 'Retain the same receipt and recheck instead of creating another claim. Leaving must not delete a pending reward.'), pair('Xem mẫu đã ghi nhận', 'Preview recorded state'), 'verified'),
      state('retry', pair('Chưa hoàn thành', 'Not completed'), pair('Nghỉ một chút hoặc thử lại', 'Take a break or try again'), pair('Không hiển thị cúp/điểm thưởng không có thật. Thất bại lượt này không xóa kết quả chờ nhận của lượt trước.', 'No invented trophies or points. This attempt’s failure does not erase a previous pending result.'), pair('Về Robot Maze', 'Back to Robot Maze'), '@w05-maze'),
      state('error', pair('Kiểm tra lỗi', 'Check failed'), pair('Chưa đọc được kết quả', 'Could not read the result'), pair('Không gọi là mất thưởng. Giữ mã giao dịch cũ để retry; gallery chỉ mô tả UI, không cấp hay thu hồi tài nguyên.', 'Do not call this a lost reward. Keep the transaction ID for retry; this gallery describes UI and grants or revokes nothing.'), pair('Xem trạng thái chờ', 'View pending state'), 'pending')
    ]
  }
];
