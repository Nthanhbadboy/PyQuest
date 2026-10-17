/* VI/EN UI copy. Destination names and availability are explicitly design fixtures. */
window.W08_COPY={
 vi:{
  title:'Hải đồ',eyebrow:'MỘT THẾ GIỚI ĐỂ KHÁM PHÁ',at:'Đang ở',from:'Từ bến',to:'Đến bến',map:'Bản đồ',list:'Danh sách',back:'Về bến nguồn',legend:'Chạm một điểm trên biển',free:'Đi thuyền không tốn năng lượng',fixture:'Bản thử tương tác · điểm đến minh họa',selected:'Điểm đến đã chọn',here:'Bạn đang ở đây',preview:'Xem hành trình',depart:'Lên thuyền',cancel:'Ở lại bến nguồn',retry:'Thử lại',return:'Quay về làng',choose:'Chọn nơi khác',skip:'Bỏ qua chuyển cảnh',download:'Chuẩn bị nội dung',disabled:'Chưa thể đi',wait:'Đang chuẩn bị…',packageDisabled:'Thông tin gói chưa có',sourceSafe:'Bạn vẫn ở bến nguồn.',noReward:'Không nhận thưởng chỉ vì đi thuyền.',arrival:'Bến đã cập',route:'Tuyến đi minh họa',
  places:{village:{name:'Đảo Khởi Đầu',kind:'Công cộng · miễn phí',short:'Làng',activity:'Trở về quảng trường và các hoạt động Python cơ bản.'},home:{name:'Vườn Nhỏ',kind:'Đảo cá nhân',short:'Đảo riêng',activity:'Một nơi để chăm vườn và sắp xếp không gian của mình.'},forest:{name:'Rừng Gió',kind:'Gói nội dung tùy chọn',short:'Gói khám phá',activity:'Một chủ đề khám phá riêng. Không thay quyền học Python cơ bản miễn phí.'}},
  states:{
   overview:['Ra khơi từ đây','Chọn một đảo để xem nơi đến và những việc có thể làm.'],
   public_ready:['Một nơi dành cho mọi người','Quảng trường và Python cơ bản luôn thuộc khu công cộng miễn phí.'],
   private_ready:['Ghé Vườn Nhỏ nhé?','Đảo cá nhân khác với gói nội dung mua thêm. Bạn có thể đi khi quyền vào khu này hợp lệ.'],
   content_preview:['Một chuyến khám phá tùy chọn','Xem nội dung và quyền truy cập trước khi đi. Không cần mua gói để trở về làng hay học Python cơ bản.'],
   eligibility_missing:['Điểm đến chưa mở','Bạn chưa thể đi đến đây. Có thể quay lại sau hoặc chọn một khu công cộng.'],
   permission_unknown:['Cần kiểm tra quyền vào đảo','Chưa xác minh được quyền truy cập. Hãy ở bến nguồn trong lúc kiểm tra.'],
   permission_denied:['Chưa thể vào khu này','Quyền vào khu này chưa hợp lệ. Bạn vẫn có thể chọn một nơi công cộng.'],
   pack_missing:['Chuẩn bị nội dung trước nhé','Bạn có quyền vào gói này, nhưng nội dung chưa có trên thiết bị.'],
   downloading:['Đang chuẩn bị nội dung','Bạn vẫn ở bến nguồn. Có thể dừng mà không bắt đầu chuyến đi.'],
   download_error:['Chưa chuẩn bị xong','Không tải được nội dung. Quyền truy cập không bị đổi thành chưa mua vì lỗi tải.'],
   confirm:['Sẵn sàng lên thuyền?','Kiểm tra bến đi và bến đến. Chuyến đi không tiêu năng lượng hay vật liệu.'],
   loading:['Đang chuẩn bị chuyến đi','Chỉ rời bến khi nội dung đã sẵn sàng và quyền vào đảo còn hợp lệ.'],
   load_error:['Chưa thể rời bến','Chuyến đi chưa hoàn tất. Bạn vẫn ở bến nguồn và có thể thử lại.'],
   cancelled:['Mình ở lại bến nhé','Chuyến đi đã dừng. Không tiêu năng lượng và không đổi nơi đang ở.'],
   sailing:['Bến đến đã sẵn sàng','Bạn có thể bỏ qua cảnh chuyển tiếp. Việc kiểm tra nội dung và quyền đã hoàn tất.'],
   arrived:['Đã cập bến','Chuyến đi hoàn tất. Bạn luôn có đường quay về làng.'],
   revoked:['Đã trở về bến an toàn','Quyền vào khu riêng đã thay đổi. Nội dung riêng không còn được hiển thị.'],
   offline:['Chưa có kết nối','Không bắt đầu chuyến đi mới lúc này. Nơi đang ở vẫn được giữ nguyên.'],
   return_confirm:['Quay về Đảo Khởi Đầu','Đường về làng luôn rõ ràng. Chuyến quay về cũng cần chuẩn bị xong trước khi đổi bến.']
  },
  harness:{title:'Hải đồ & hành trình đi đảo',desc:'DESIGN làm riêng W08. Không sửa PQC-018, không nối app, không giao thêm việc cho Code.',controls:'Bàn điều khiển review',language:'Ngôn ngữ xem',scale:'Cỡ chữ thật',state:'Trạng thái minh họa',auto:'Tự trả kết quả tải mẫu',calm:'Giảm chuyển động',ok:'Tải xong + quyền hợp lệ',fail:'Trả lỗi tải',revoke:'Thu hồi quyền mẫu',stale:'Gửi phản hồi cũ',reconnect:'Khôi phục kết nối mẫu',note:'Các nút trong điện thoại chỉ chuyển dữ liệu mẫu trong bộ nhớ. Không mạng, tải gói, mua hàng, lưu dữ liệu hoặc đi đảo thật.',steps:'Thử: chọn đảo2 → xem hành trình → lên thuyền → bỏ qua chuyển cảnh. Tắt tự trả kết quả để thử hủy và phản hồi đến muộn.',receipt:'Dấu vết mô phỏng',full:'Mở màn phone riêng',gallery:'Bộ ảnh chung21',spec:'Đọc thiết kế & giới hạn',newArt:'Cảnh W08 mới · UI/tuyến đi tách ảnh',newArtNote:'Đảo và công trình vẫn là một PNG opaque; chưa có boat sprite, lớp che, navigation hay animation game.',idle:'Không có yêu cầu đang chờ',lateIgnored:'Phản hồi cũ đã bị bỏ qua',simulation:'MẪU TƯƠNG TÁC · KHÔNG PHẢI APP'}
 },
 en:{
  title:'World chart',eyebrow:'A WORLD TO EXPLORE',at:'You are at',from:'From',to:'To',map:'Map',list:'List',back:'Back to departure dock',legend:'Choose a place across the sea',free:'Boat travel uses no energy',fixture:'Interactive study · illustrative destinations',selected:'Selected destination',here:'You are here',preview:'Plan this journey',depart:'Set sail',cancel:'Stay at departure dock',retry:'Try again',return:'Return to the village',choose:'Choose another place',skip:'Skip the transition',download:'Prepare content',disabled:'Travel unavailable',wait:'Preparing…',packageDisabled:'Pack information unavailable',sourceSafe:'You are still at the departure dock.',noReward:'Travelling does not grant rewards.',arrival:'Arrival dock',route:'Illustrative route',
  places:{village:{name:'Starter Island',kind:'Public · free',short:'Village',activity:'Return to the plaza and the core Python activities.'},home:{name:'Little Garden',kind:'Personal island',short:'Personal island',activity:'A place to tend your garden and arrange your own space.'},forest:{name:'Windwood',kind:'Optional content pack',short:'Content pack',activity:'A separate exploration theme. It does not replace free access to core Python.'}},
  states:{
   overview:['Set out from here','Choose an island to see where it leads and what you can do there.'],
   public_ready:['A place for everyone','The plaza and core Python remain part of the free public world.'],
   private_ready:['Visit Little Garden?','A personal island is not a paid content pack. Travel requires valid access to this space.'],
   content_preview:['An optional adventure','Review its content and access before travelling. No pack is needed to return to the village or learn core Python.'],
   eligibility_missing:['This destination is not open yet','You cannot travel here yet. Come back later or choose a public place.'],
   permission_unknown:['Check access first','Access has not been verified. Stay at the departure dock while it is checked.'],
   permission_denied:['This space is not available','Access to this space is not valid. You can still choose a public destination.'],
   pack_missing:['Prepare the content first','Access to this pack is valid, but its content is not on this device yet.'],
   downloading:['Preparing content','You remain at the departure dock. You can stop without starting a journey.'],
   download_error:['Content is not ready','The download failed. A download error does not remove your access to the pack.'],
   confirm:['Ready to set sail?','Check the departure and arrival docks. This journey uses no energy or materials.'],
   loading:['Preparing your journey','Only leave once the content is ready and access is still valid.'],
   load_error:['Still at the departure dock','The journey has not completed. You remain at the source and can try again.'],
   cancelled:['Stay at the dock for now','The journey stopped. No energy was used and your location has not changed.'],
   sailing:['The destination is ready','You can skip the transition. Content and access checks have already completed.'],
   arrived:['You have arrived','Your journey is complete. There is always a clear way back to the village.'],
   revoked:['Back at a safe dock','Access to the private space has changed. Private content is no longer displayed.'],
   offline:['No connection yet','Do not start a new journey right now. Your current location is preserved.'],
   return_confirm:['Return to Starter Island','Keep the way home clear. The return journey must also be ready before changing docks.']
  },
  harness:{title:'World chart & island travel',desc:'A separate DESIGN study for W08. No PQC-018 edits, app integration or new CODE assignment.',controls:'Review controls',language:'Preview language',scale:'Actual text scale',state:'Illustrative state',auto:'Simulate a successful load automatically',calm:'Reduce motion',ok:'Load ready + valid access',fail:'Simulate load failure',revoke:'Revoke sample access',stale:'Send an old response',reconnect:'Restore sample connection',note:'Phone controls only change in-memory fixtures. No network, pack download, purchase, persistence or real travel is performed.',steps:'Try: island2 → plan journey → set sail → skip transition. Turn off automatic responses to try cancellation and late replies.',receipt:'Simulation trace',full:'Open standalone phone',gallery:'Shared21-image gallery',spec:'Design & limitations',newArt:'New W08 scene · separate UI and route',newArtNote:'Islands and buildings remain one opaque PNG. No boat sprite, occluder layers, navigation or game animation exists.',idle:'No pending request',lateIgnored:'Old response ignored',simulation:'INTERACTIVE STUDY · NOT THE APP'}
 }
};
