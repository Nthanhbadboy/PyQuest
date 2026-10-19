// Short learner-facing copy; engineering explanations stay in the review rail.
// All states are fixtures, explicitly marked by the shell, never real transactions.
const SCREEN_COPY = {
'w07-interior': {
 draft: ['Ghế gỗ đang được chọn. Bạn có thể thử chỗ đặt trước khi lưu.', 'Wooden chair selected. Try a position before saving.', 'Lưu bố trí', 'Save layout'],
 blocked: ['Ghế đang chắn cửa. Hãy chọn chỗ khác để luôn có đường ra nhé.', 'The chair is blocking the door. Choose another spot to keep a clear way out.', 'Chọn chỗ khác', 'Choose another spot'],
 unsaved: ['Bạn có thay đổi chưa lưu. Quay lại sắp xếp để giữ bản nháp này.', 'You have unsaved changes. Return to arranging to keep this draft.', 'Tiếp tục sắp xếp', 'Keep arranging'],
 saved: ['Chỗ ngồi mới đã sẵn sàng. Bạn có thể sắp xếp lại bất cứ lúc nào.', 'Your new seat is ready. You can rearrange it anytime.', 'Sắp xếp tiếp', 'Arrange again']
},
'w03-project': {
 missing: ['Còn thiếu một ít gỗ. Huy chương vẫn thuộc về bạn sau khi xây.', 'You need a little more wood. Your medal stays yours after building.', 'Tìm vật liệu', 'Find materials'],
 source: ['Nguồn vật liệu cho dự án này chưa sẵn sàng. Bạn vẫn có thể chơi các hoạt động khác.', 'Material sources for this project are not ready yet. You can still enjoy other activities.', 'Về dự án', 'Back to project'],
 ready: ['Sẽ dùng 3 gỗ và 2 vải. Giữ lại huy chương. Bạn muốn bắt đầu xây chứ?', 'This will use 3 wood and 2 cloth. Your medal is retained. Ready to build?', 'Xác nhận xây · mẫu', 'Confirm build · fixture'],
 pending: ['Đang kiểm tra lần xây trước. Bạn có thể quay lại sau mà không bắt đầu lần xây mới.', 'Checking your previous build. You can return later without starting another build.', 'Kiểm tra kết quả', 'Check result'],
 built: ['Bạn đã có một nơi mới để thử ý tưởng. Vào xem nhé!', 'You have a new place to try ideas. Come take a look!', 'Vào phòng', 'Enter room']
},
'w09-visit': {
 absent: ['Bạn đang xem khu vườn được chia sẻ. Chủ đang vắng, nên đây chưa phải buổi chơi cùng nhau.', 'You are viewing the shared garden. The host is away, so this is not a shared play session.', 'Xem quyền của mình', 'View my permissions'],
 permissions: ['Bạn được xem sân vườn. Phòng riêng và việc sắp xếp đồ không thuộc quyền của khách.', 'You can explore the garden. Private rooms and moving furniture are not included in guest access.', 'Tiếp tục tham quan', 'Continue the tour'],
 revoked: ['Lời mời ghé nhà không còn hiệu lực. Cùng trở về khu cộng đồng nhé.', 'This visit invitation is no longer valid. Let’s return to the community area.', 'Rời nhà', 'Leave the home'],
 offline: ['Chưa kiểm tra được quyền ghé nhà. Cảnh đang được ẩn để giữ riêng tư cho chủ.', 'Visit permission could not be checked. The scene is hidden to protect the host’s privacy.', 'Rời nhà', 'Leave the home']
},
'w10-pet': {
 play: ['Miu thích bóng len và góc leo nhỏ. Bạn không cần bật AI để chơi cùng Miu.', 'Miu likes the yarn ball and little ramp. You do not need AI to play together.', 'Cho Miu nghỉ', 'Let Miu rest'],
 rest: ['Bạn có thể nghỉ khi muốn. Miu vẫn được chăm sóc và không buồn vì bạn rời app.', 'Take a break whenever you like. Miu stays cared for when you leave the app.', 'Chọn trò chơi', 'Choose a game'],
 unsupported: ['Thiết bị chưa hỗ trợ trò chuyện AI trên máy. Miu vẫn đi lại, chơi và nghỉ bình thường.', 'This device does not support on-device AI chat yet. Miu can still move, play and rest.', 'Chơi cùng Miu', 'Play with Miu'],
 memory: ['Khi có ký ức game, bạn sẽ được xem và xóa. Bản thiết kế này không ghi âm hoặc lưu ký ức.', 'When game memories are available, you can view and delete them. This design records no audio or memories.', 'Về sân chơi', 'Back to the garden']
},
'w10b-pet-shop': {
 preview: ['Bạn nhỏ biết chơi và nghỉ. Khả năng AI và giá chưa được xác nhận, nên chưa thể mua.', 'This companion can play and rest. AI support and pricing are unconfirmed, so purchase is unavailable.', 'Thông tin cho phụ huynh', 'Parent information'],
 parent: ['Hãy cùng phụ huynh xem giá, quyền lợi và khả năng thiết bị trước khi quyết định.', 'Review price, benefits and device support with a parent before deciding.', 'Quay lại làm quen', 'Back to meet and greet'],
 pending: ['Đang kiểm tra lần mua trước. Đừng mua lại trong khi chờ xác nhận nhé.', 'Checking your previous purchase. Please do not purchase again while confirmation is pending.', 'Kiểm tra khôi phục', 'Check restore'],
 restore: ['Chưa khôi phục được quyền sở hữu. Bạn có thể kiểm tra lại sau, không cần mua lần nữa.', 'Ownership could not be restored yet. You can check again later without buying again.', 'Về xem trước', 'Back to preview']
},
'w12-creator': {
 draft: ['Ý tưởng này chỉ mình bạn thấy. Chạy thử trước, rồi lưu khi bạn muốn.', 'Only you can see this idea. Try it first, then save whenever you like.', 'Chạy thử · mẫu', 'Try it · fixture'],
 tested: ['Thử nghiệm giúp bạn tìm điều muốn sửa. Chưa có gì được chia sẻ với người khác.', 'Testing helps you find what to change. Nothing has been shared with anyone else.', 'Lưu phiên bản · mẫu', 'Save version · fixture'],
 saved: ['Bạn có thể chỉnh tiếp mà vẫn giữ phiên bản này. Muốn cho bạn bè xem không?', 'You can keep editing and retain this version. Would you like friends to see it?', 'Xem bước chia sẻ', 'Review sharing'],
 moderation: ['Tác phẩm đang chờ duyệt, chưa hiển thị công khai. Bạn vẫn có thể dùng bản riêng của mình.', 'Your creation is awaiting review and is not public yet. You can still use your private version.', 'Về bản nháp', 'Back to draft'],
 error: ['Chưa lưu được lần này. Bản nháp vẫn ở đây để bạn tiếp tục, đừng lo.', 'This save did not complete. Your draft is still here for you to keep working on.', 'Về bản nháp', 'Back to draft']
},
'w12b-friends-gifts': {
 draft: ['Chọn người nhận và món được phép tặng. Quà là lời chúc, không phải huy chương kỹ năng.', 'Choose a recipient and an eligible gift. A gift is a kind gesture, not a skill medal.', 'Xem lại món quà', 'Review gift'],
 confirm: ['Chưa chọn người nhận và món quà thật. Chưa có gì được gửi đi.', 'No real recipient or gift has been selected. Nothing has been sent.', 'Xem mẫu chờ phản hồi', 'Preview response wait'],
 pending: ['Người nhận có thể nhận hoặc từ chối. Không cần gửi lại khi đang chờ nhé.', 'The recipient can accept or decline. There is no need to resend while waiting.', 'Xem mẫu từ chối', 'Preview declined state'],
 declined: ['Người nhận đã chọn không nhận. Mọi lựa chọn đều được tôn trọng, không cần gửi lại.', 'Your friend chose not to accept. Their choice is respected; there is no need to resend.', 'Về góc quà', 'Back to gifts']
},
'w05-maze': {
 ready: ['Nhìn đường đi rồi chuẩn bị các lệnh cho robot. Hình này là sân minh họa, chưa phải màn chơi thật.', 'Look at the path and prepare the robot’s commands. This is an illustrated board, not a playable level.', 'Xem lúc tạm dừng', 'Preview pause'],
 paused: ['Lượt chơi và chương trình được giữ lại. Sẵn sàng thì quay lại nhé.', 'Your attempt and program are kept. Come back when you are ready.', 'Tiếp tục', 'Continue'],
 retry: ['Robot chưa đến đích. Thử xem lại từng lệnh rồi tìm một đường khác nhé.', 'The robot has not reached the goal. Review each command and try another route.', 'Sửa kế hoạch', 'Revise plan'],
 complete: ['Cùng xem lại lượt vừa chơi. Không cần bắt đầu ngay một lượt mới.', 'Let’s review that attempt. You do not need to start another one right away.', 'Xem kết quả', 'View results']
},
'w05-dragon': {
 ready: ['Nhìn khoảng cách giữa các bục và thử ý tưởng của bạn. Đây là hình minh họa, chưa chạy trò chơi.', 'Watch the gaps and try your idea. This is an illustration; the game is not running.', 'Xem lúc tạm dừng', 'Preview pause'],
 paused: ['Nghỉ một chút cũng được. Ý tưởng và lượt đang chơi vẫn được giữ lại.', 'It is okay to take a break. Your idea and current attempt are kept.', 'Tiếp tục', 'Continue'],
 retry: ['Chưa qua lần này cũng không sao. Bạn muốn thử một kế hoạch khác chứ?', 'It is okay not to make it this time. Would you like to try another plan?', 'Thử cách khác', 'Try another way'],
 complete: ['Cùng xem điều bạn đã thử. Bạn có thể nghỉ hoặc chọn hoạt động khác.', 'Let’s look at what you tried. You can rest or choose another activity.', 'Xem kết quả', 'View results']
},
'w06-result': {
 verified: ['Kết quả đã được ghi nhận. Bạn không cần nhận lại lần nữa.', 'Your result has been recorded. You do not need to claim it again.', 'Về góc sáng tạo', 'Go to creative corner'],
 pending: ['Đang kiểm tra kết quả. Bạn có thể quay lại sau mà không mất phần đang chờ.', 'Your result is being checked. You can come back later without losing what is pending.', 'Kiểm tra lại', 'Check again'],
 retry: ['Chưa hoàn thành lần này, nhưng bạn đã thử. Nghỉ một chút hay quay lại đều được.', 'Not completed this time, but you tried. You can take a break or try again.', 'Về Robot Maze', 'Back to Robot Maze'],
 error: ['Chưa đọc được kết quả, không có nghĩa là mất thưởng. Hãy kiểm tra lại sau nhé.', 'The result could not be read; that does not mean your reward is lost. Please check again later.', 'Kiểm tra lại', 'Check again']
}
};
for (const scene of window.SCENES) {
  for (const s of scene.states) {
    s.review = s.body;
    const copy = SCREEN_COPY[scene.id][s.id];
    s.body = pair(copy[0], copy[1]);
    s.action = pair(copy[2], copy[3]);
  }
}
