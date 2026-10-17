const PQC018_BATCH_B_COMMON = {
  reviewer: { vi: 'BẢN XEM CHO NGƯỜI DUYỆT', en: 'REVIEWER VIEW' },
  controls: { vi: 'Điều khiển bản xem', en: 'Preview controls' },
  language: { vi: 'Ngôn ngữ xem', en: 'Preview language' },
  textSize: { vi: 'Cỡ chữ xem', en: 'Preview text size' },
  state: { vi: 'Trạng thái minh họa', en: 'Fixture state' },
  back: { vi: 'Bộ ảnh PQC-018', en: 'PQC-018 art set' },
  notes: { vi: 'Ghi chú người duyệt · Không thuộc màn hình sản phẩm', en: 'Reviewer notes · Outside the product screen' },
  noteLabel: { vi: 'Lưu ý trạng thái', en: 'State note' },
  noRuntime: { vi: 'Bản xem tĩnh · Không kết nối app, tài khoản, mạng, lưu trữ hoặc giao dịch.', en: 'Static study · No app, account, network, persistence or transaction is connected.' },
  sources: { vi: 'Nguồn & phạm vi', en: 'Sources & scope' },
  friendsBar: { vi: 'Góc cộng đồng', en: 'Community nook' },
  creatorBar: { vi: 'Xưởng sáng tạo', en: 'Creator workshop' },
  creatorEditor: { vi: 'Trình chỉnh sửa', en: 'Editor' },
  creatorPreview: { vi: 'Vùng thử', en: 'Preview' },
  creatorTray: { vi: 'Khay phiên bản', en: 'Version tray' },
  creatorVersionA: { vi: 'Bản mẫu A', en: 'Sample version A' },
  creatorVersionB: { vi: 'Bản mẫu B', en: 'Sample version B' },
  roomBar: { vi: 'Phòng tầng trệt', en: 'Ground-floor room' },
  roomFloor: { vi: 'SÀN LIỀN MẠCH', en: 'SOLID FLOOR' },
  roomDoor: { vi: 'CỬA Ở TẦNG TRỆT', en: 'GROUND-LEVEL DOOR' },
  petBar: { vi: 'Góc nghỉ của Miu', en: 'Miu’s resting nook' },
  petStill: { vi: 'MỘT CẢNH TĨNH', en: 'ONE STILL SCENE' }
};

const PQC018_BATCH_B_SCENES = {
  'b01-w09-friends-invites': {
    title: { vi: 'Bạn bè & lời mời', en: 'Friends & invitations' },
    subtitle: { vi: 'Một góc cộng đồng với danh sách rõ ràng và riêng tư', en: 'A community nook with a clear, privacy-aware list' },
    alt: { vi: 'Góc cộng đồng ngoài trời có giàn gỗ, bàn giấy trống, ghế và cổng vườn mở.', en: 'An outdoor community nook with a timber pergola, blank paper, seating and an open garden gate.' },
    reviewerNotes: {
      vi: 'Tham chiếu W09 + W12b + W01. Danh tính “Bạn mẫu” là hư cấu. Tất cả trạng thái là minh họa; không có online presence, lời mời gửi thật, backend, moderation hoặc chia sẻ không gian riêng.',
      en: 'References W09 + W12b + W01. “Sample friend” is fictional. All states are illustrative; there is no online presence, real invitation delivery, backend, moderation or private-space sharing.'
    },
    states: {
      empty: {
        label: { vi: 'Danh sách trống', en: 'Empty friend list' }, tag: { vi: 'CHƯA CÓ BẠN NÀO', en: 'NO FRIENDS YET' },
        title: { vi: 'Danh sách bạn bè đang trống', en: 'Your friend list is empty' },
        body: { vi: 'Không có người nhận nào trong mẫu này. Bạn có thể xem lại quyền riêng tư trước khi chọn người.', en: 'There is no recipient in this fixture. Review privacy before choosing someone.' },
        facts: [{ vi: 'Bạn bè · Chưa có', en: 'Friends · None yet' }, { vi: 'Khu vực riêng · Không hiển thị', en: 'Private areas · Not shown' }],
        cta: { vi: 'Tìm bạn · Mẫu', en: 'Find friends · fixture' },
        note: { vi: 'Không tìm kiếm hoặc gửi lời mời thật.', en: 'No real search or invitation is performed.' }
      },
      invite_pending: {
        label: { vi: 'Lời mời đang chờ', en: 'Invite pending' }, tag: { vi: 'ĐANG CHỜ', en: 'PENDING' },
        title: { vi: 'Lời mời chưa được trả lời', en: 'The invitation has not been answered' },
        body: { vi: 'Mẫu người nhận xuất hiện trong danh sách, nhưng trạng thái chờ không xác nhận rằng lời mời đã tới nơi.', en: 'A sample recipient appears in the list; pending does not confirm that an invitation was delivered.' },
        friendRow: { vi: 'Bạn mẫu · Lời mời đang chờ', en: 'Sample friend · Invitation pending' },
        facts: [{ vi: 'Trạng thái · Chưa xác nhận', en: 'Status · Not confirmed' }, { vi: 'Thông tin riêng · Ẩn', en: 'Private information · Hidden' }],
        cta: { vi: 'Gửi lại · Mẫu', en: 'Resend · fixture' },
        note: { vi: 'Nút gửi lại là mẫu tắt; không phát sinh lời mời.', en: 'The resend button is a disabled fixture; no invitation is sent.' }
      },
      invite_expired: {
        label: { vi: 'Lời mời hết hạn', en: 'Invite expired' }, tag: { vi: 'ĐÃ HẾT HẠN', en: 'EXPIRED' },
        title: { vi: 'Lời mời mẫu đã hết hạn', en: 'The sample invitation has expired' },
        body: { vi: 'Giữ rõ trạng thái đã hết hạn để không nhầm với lời mời đang chờ hoặc bạn đã xác nhận.', en: 'Keep the expired state distinct from a pending invitation or a confirmed friend.' },
        friendRow: { vi: 'Bạn mẫu · Lời mời hết hạn', en: 'Sample friend · Invitation expired' },
        facts: [{ vi: 'Danh sách bạn · Chưa xác nhận', en: 'Friend list · Not confirmed' }, { vi: 'Khu vực riêng · Không hiển thị', en: 'Private areas · Not shown' }],
        cta: { vi: 'Xem lựa chọn · Mẫu', en: 'Review options · fixture' },
        note: { vi: 'Không tự gửi lại hoặc làm mới lời mời.', en: 'No invitation is resent or renewed automatically.' }
      },
      host_away: {
        label: { vi: 'Chủ nhà vắng mặt', en: 'Host away' }, tag: { vi: 'CHỦ NHÀ VẮNG', en: 'HOST AWAY' },
        title: { vi: 'Chủ nhà hiện không có mặt', en: 'The host is not available' },
        body: { vi: 'Mẫu chỉ giữ lời nhắn trung tính. Không suy ra chủ nhà đang trực tuyến hoặc mở quyền xem phòng riêng.', en: 'This fixture keeps the message neutral. It does not imply the host is online or grant access to a private room.' },
        friendRow: { vi: 'Bạn mẫu · Chưa có mặt', en: 'Sample friend · Not available' },
        facts: [{ vi: 'Khu vực công khai · Giữ nguyên', en: 'Public area · Unchanged' }, { vi: 'Phòng riêng · Không truy cập', en: 'Private room · No access' }],
        cta: { vi: 'Quay lại · Mẫu', en: 'Return · fixture' },
        note: { vi: 'Không có presence, kết nối hoặc phiên ghé thăm thật.', en: 'No presence, connection or real visit session exists.' }
      },
      blocked: {
        label: { vi: 'Đã chặn · Mẫu', en: 'Blocked · fixture' }, tag: { vi: 'ĐÃ CHẶN', en: 'BLOCKED' },
        title: { vi: 'Giữ an toàn và quyền riêng tư', en: 'Keep safety and privacy first' },
        body: { vi: 'Trạng thái minh họa đã chặn người mẫu. Không tiết lộ hồ sơ, lời mời hoặc nội dung phòng riêng.', en: 'The illustrative state blocks a sample person. It reveals no profile, invitation or private-room content.' },
        friendRow: { vi: 'Người dùng mẫu · Thông tin ẩn', en: 'Sample person · Details hidden' },
        facts: [{ vi: 'Thông tin cá nhân · Ẩn', en: 'Personal details · Hidden' }, { vi: 'Truy cập riêng · Không cấp', en: 'Private access · Not granted' }],
        cta: { vi: 'Đã chặn · Mẫu', en: 'Blocked · fixture' },
        note: { vi: 'Không có chặn hoặc kiểm duyệt backend thật.', en: 'No real block action or backend moderation is connected.' }
      },
      report_confirmation: {
        label: { vi: 'Xác nhận báo cáo', en: 'Report confirmation' }, tag: { vi: 'CHƯA GỬI', en: 'NOT SENT' },
        title: { vi: 'Xem lại trước khi báo cáo', en: 'Review before reporting' },
        body: { vi: 'Bản xem chỉ minh họa bước xác nhận. Không thu thập lý do, gửi báo cáo hoặc hiển thị thông tin riêng.', en: 'This study only illustrates a confirmation step. It collects no reason, sends no report and reveals no private information.' },
        facts: [{ vi: 'Báo cáo · Chưa gửi', en: 'Report · Not sent' }, { vi: 'Thông tin người khác · Ẩn', en: 'Other person’s information · Hidden' }],
        cta: { vi: 'Xác nhận · Tắt trong mẫu', en: 'Confirm · Disabled in fixture' },
        note: { vi: 'Không có moderation, hậu quả tài khoản hoặc backend được mô phỏng.', en: 'No moderation, account consequence or backend is simulated.' }
      }
    }
  },
  'b02-w12-creator-editor': {
    title: { vi: 'Xưởng sáng tạo', en: 'Creator workshop' },
    subtitle: { vi: 'Trình chỉnh sửa, vùng thử và khay phiên bản', en: 'An editor, preview area and version tray' },
    alt: { vi: 'Xưởng sáng tạo bằng gỗ có bảng chỉnh sửa trống, khung thử riêng và khay thẻ trống.', en: 'A timber creator workshop with a blank editor board, separate preview frame and blank card tray.' },
    reviewerNotes: {
      vi: 'Tham chiếu W12/W12b và W13. Editor/vùng thử/khay phiên bản là mock đọc-only. Trạng thái lưu riêng và moderation là fixtures; không tuyên bố đã lưu, công bố, chạy test, chấm điểm hay nhận thưởng.',
      en: 'References W12/W12b and W13. The editor, preview and version tray are read-only mocks. Private-save and moderation states are fixtures; nothing is persisted, published, tested, graded or rewarded.'
    },
    states: {
      draft_unsaved: {
        label: { vi: 'Bản nháp chưa lưu', en: 'Draft · unsaved' }, tag: { vi: 'BẢN NHÁP', en: 'DRAFT' },
        title: { vi: 'Bản nháp còn thay đổi', en: 'The draft has unsaved changes' },
        body: { vi: 'Bảng chỉnh sửa và vùng thử chỉ là minh họa tĩnh. Thay đổi chưa được lưu và có thể mất khi rời màn hình thật.', en: 'The editor and preview are static illustrations. Changes are not saved and could be lost when leaving a real screen.' },
        facts: [{ vi: 'Trạng thái · Bản nháp mẫu', en: 'Status · Sample draft' }, { vi: 'Lưu trữ · Chưa xác minh', en: 'Persistence · Not verified' }],
        cta: { vi: 'Lưu bản nháp · Tắt', en: 'Save draft · disabled' },
        note: { vi: 'Không có dữ liệu chỉnh sửa hoặc lưu trữ thật.', en: 'No real edit data or storage is connected.' }
      },
      test_error: {
        label: { vi: 'Lỗi khi thử', en: 'Test error' }, tag: { vi: 'LỖI MẪU', en: 'ERROR FIXTURE' },
        title: { vi: 'Vùng thử báo lỗi minh họa', en: 'The preview shows an illustrative error' },
        body: { vi: 'Giữ editor và nội dung mẫu để có thể xem lại. Không có lần chạy hoặc kết quả bài kiểm tra thật.', en: 'Keep the editor and sample content available for review. No run or real test result exists.' },
        facts: [{ vi: 'Vùng thử · Chưa chạy', en: 'Preview · Not run' }, { vi: 'Bản nháp · Không đổi', en: 'Draft · Unchanged' }],
        cta: { vi: 'Thử lại · Tắt', en: 'Retry · disabled' },
        note: { vi: 'Không bịa grader, điểm hoặc lỗi engine cụ thể.', en: 'No grader, score or specific engine error is fabricated.' }
      },
      saved_private: {
        label: { vi: 'Bản riêng tư · Mẫu', en: 'Saved privately · fixture' }, tag: { vi: 'RIÊNG TƯ', en: 'PRIVATE' },
        title: { vi: 'Bản mẫu chỉ dành riêng', en: 'A sample kept private' },
        body: { vi: 'Nhãn này minh họa trạng thái riêng tư; không chứng minh nội dung đã lưu trên thiết bị hoặc máy chủ.', en: 'This label illustrates a private state; it does not prove that anything was saved on a device or server.' },
        facts: [{ vi: 'Chia sẻ · Chưa công khai', en: 'Sharing · Not public' }, { vi: 'Lưu · Không xác minh', en: 'Saved · Not verified' }],
        cta: { vi: 'Mở bản riêng · Tắt', en: 'Open private copy · disabled' },
        note: { vi: 'Không tạo nội dung, phiên bản hoặc quyền truy cập thật.', en: 'No real creation, version or access permission is created.' }
      },
      moderation_pending: {
        label: { vi: 'Chờ kiểm duyệt · Mẫu', en: 'Moderation pending · fixture' }, tag: { vi: 'ĐANG CHỜ', en: 'PENDING' },
        title: { vi: 'Chưa có quyết định kiểm duyệt', en: 'No moderation decision yet' },
        body: { vi: 'Trạng thái chờ được giữ trung tính. Không khẳng định nội dung đã gửi, được duyệt hoặc xuất bản.', en: 'The pending state stays neutral. It does not claim content was submitted, approved or published.' },
        facts: [{ vi: 'Trạng thái · Chưa xác minh', en: 'Status · Not verified' }, { vi: 'Công khai · Không', en: 'Public · No' }],
        cta: { vi: 'Xem trạng thái · Tắt', en: 'View status · disabled' },
        note: { vi: 'Không có hệ thống moderation hoặc backend trong concept này.', en: 'No moderation system or backend is part of this concept.' }
      }
    }
  },
  'b03-w07-built-room': {
    title: { vi: 'Phòng tầng trệt hoàn tất', en: 'Completed ground-floor room' },
    subtitle: { vi: 'Sàn liền, cửa thật và bàn làm việc', en: 'Solid floor, real doorway and workbench' },
    alt: { vi: 'Phòng một tầng hoàn tất với sàn đá liền mạch, cửa mở có ngưỡng và bàn làm việc.', en: 'A completed one-storey room with a continuous stone floor, an open threshold doorway and workbench.' },
    reviewerNotes: {
      vi: 'W03 là ngữ cảnh dự án tầng trệt; W02 là nghiên cứu nhà hai tầng riêng và không phải cùng blueprint. Concept mới loại bỏ cyan ghost, có sàn và cửa ở tầng trệt. Không suy geometry, footprint, recipe, collision hoặc cost runtime từ tranh.',
      en: 'W03 provides the ground-floor project context; W02 is a separate two-storey study, not the same blueprint. The new concept removes the cyan ghost and depicts a floor and ground-level door. Do not infer runtime geometry, footprint, recipe, collision or cost from the image.'
    },
    states: {
      completed_enter: {
        label: { vi: 'Hoàn tất · Vào phòng', en: 'Completed · enter room' }, tag: { vi: 'PHÒNG MẪU', en: 'ROOM FIXTURE' },
        title: { vi: 'Một căn phòng đã hoàn tất', en: 'A completed room' },
        body: { vi: 'Hình minh họa có sàn liền mạch và cửa thật ở tầng trệt. Đây là concept, không xác nhận phòng đã được xây trong game.', en: 'The illustration shows a continuous floor and a real ground-level doorway. It is a concept, not proof that a room was built in the game.' },
        facts: [{ vi: 'Sàn · Liền dưới bàn làm việc', en: 'Floor · Continuous beneath the workbench' }, { vi: 'Cửa · Mở ra lối vườn trong tranh', en: 'Door · Opens to the garden in the picture' }],
        cta: { vi: 'Vào phòng · Mẫu tắt', en: 'Enter room · disabled fixture' },
        note: { vi: 'Không còn cyan ghost trong ảnh hoàn tất; không có điều hướng thật.', en: 'The finished image has no cyan ghost; no real navigation occurs.' }
      },
      use_workbench: {
        label: { vi: 'Dùng bàn làm việc', en: 'Use workbench' }, tag: { vi: 'BÀN LÀM VIỆC', en: 'WORKBENCH' },
        title: { vi: 'Bàn làm việc có chỗ trong phòng', en: 'The workbench has room in the scene' },
        body: { vi: 'Bàn được đặt trên sàn nhìn thấy rõ. Trạng thái này chỉ minh họa vị trí; không mô phỏng tương tác hoặc công cụ.', en: 'The bench sits on the visible floor. This state only illustrates placement; it does not simulate an interaction or tool.' },
        facts: [{ vi: 'Vị trí · Trên sàn tầng trệt', en: 'Placement · On the ground floor' }, { vi: 'Tương tác · Chưa chạy', en: 'Interaction · Not run' }],
        cta: { vi: 'Dùng bàn · Tắt trong mẫu', en: 'Use bench · disabled in fixture' },
        note: { vi: 'Không có tác động lên tiến độ hoặc dữ liệu người chơi.', en: 'No player data or progress is changed.' }
      },
      arrangement_blocked: {
        label: { vi: 'Sắp xếp bị chặn', en: 'Arrangement blocked' }, tag: { vi: 'CẦN XEM LẠI', en: 'REVIEW PLACEMENT' },
        title: { vi: 'Vị trí này cần được xem lại', en: 'This placement needs review' },
        body: { vi: 'Giữ thông báo trung tính khi một cách sắp xếp không dùng được. Hình không định nghĩa luật va chạm hoặc điều kiện xây dựng.', en: 'Keep the message neutral when an arrangement is unavailable. The image defines no collision or building rule.' },
        facts: [{ vi: 'Vị trí · Mẫu chưa dùng được', en: 'Placement · Unavailable fixture' }, { vi: 'Quy tắc · Chưa được xác định bởi concept', en: 'Rule · Not defined by the concept' }],
        cta: { vi: 'Chọn vị trí khác · Mẫu tắt', en: 'Choose another spot · disabled fixture' },
        note: { vi: 'Không tiêu tài nguyên hoặc áp dụng thay đổi thật.', en: 'No resources are spent and no real change is applied.' }
      }
    }
  },
  'b04-w10-pet-rest': {
    title: { vi: 'Miu nghỉ ngơi', en: 'Miu at rest' },
    subtitle: { vi: 'Cùng Miu mèo cam trong khu vườn W10', en: 'The same orange Miu in the W10 garden' },
    alt: { vi: 'Miu mèo mướp cam nằm cuộn nghỉ trên nệm dưới giàn pergola gỗ trong khu vườn.', en: 'Miu the orange tabby is curled up resting on a cushion beneath the timber garden pergola.' },
    reviewerNotes: {
      vi: 'Dùng cùng identity Miu cam trong W10; không dùng mèo xám W10b. Ảnh là một pose tĩnh. Unsupported AI và removed-baseline chỉ là state fixtures, không có suy luận, animation, mua hàng hoặc dữ liệu thú cưng thật.',
      en: 'Preserves the orange Miu identity from W10; does not substitute the gray W10b kitten. The picture is one still pose. Unsupported-AI and removed-baseline states are fixtures only; there is no inference, animation, purchase or live pet data.'
    },
    states: {
      rest: {
        label: { vi: 'Đang nghỉ', en: 'Resting' }, tag: { vi: 'MỘT POSE TĨNH', en: 'ONE STILL POSE' },
        title: { vi: 'Miu đang nghỉ dưới giàn pergola', en: 'Miu is resting beneath the pergola' },
        body: { vi: 'Miu nằm cuộn trên nệm trong khu vườn quen thuộc. Không có lời nhắc mua hàng hay hoạt ảnh trong concept.', en: 'Miu is curled up on a cushion in the familiar garden. The concept has no purchase prompt or animation.' },
        facts: [{ vi: 'Nhân vật · Miu mèo cam', en: 'Character · Orange Miu' }, { vi: 'Cảnh · Tĩnh, không chuyển động', en: 'Scene · Still, no motion' }],
        cta: { vi: 'Xem góc nghỉ · Mẫu tắt', en: 'View resting nook · disabled fixture' },
        note: { vi: 'Không có hành vi, chăm sóc hoặc trạng thái runtime được mô phỏng.', en: 'No behavior, care mechanic or runtime state is simulated.' }
      },
      ai_unsupported: {
        label: { vi: 'AI không hỗ trợ · Mẫu', en: 'AI unsupported · fixture' }, tag: { vi: 'KHÔNG HỖ TRỢ', en: 'UNSUPPORTED' },
        title: { vi: 'Không có suy luận AI trên thiết bị này', en: 'No AI inference on this device' },
        body: { vi: 'Trạng thái minh họa nói rõ khi thiết bị không hỗ trợ. Hình nghỉ cơ bản vẫn được giữ; không có kết quả AI giả.', en: 'The illustrative state is explicit when a device is unsupported. The resting baseline remains; no AI result is fabricated.' },
        facts: [{ vi: 'AI · Không chạy', en: 'AI · Not run' }, { vi: 'Ảnh nền · Vẫn hiển thị', en: 'Baseline image · Still shown' }],
        cta: { vi: 'Đã hiểu · Mẫu tắt', en: 'Understood · disabled fixture' },
        note: { vi: 'Không kết nối thiết bị hoặc mô hình AI.', en: 'No device or AI model is connected.' }
      },
      model_removed_baseline: {
        label: { vi: 'Mô hình đã gỡ · Nền còn', en: 'Model removed · baseline remains' }, tag: { vi: 'NỀN ĐƯỢC GIỮ', en: 'BASELINE KEPT' },
        title: { vi: 'Ảnh nền vẫn còn khi mô hình bị gỡ', en: 'The baseline remains after a model is removed' },
        body: { vi: 'Fixture giữ nguyên hình nghỉ cơ bản của Miu nếu một mô hình tùy chọn không còn. Không có nội dung do AI tạo để thay thế.', en: 'This fixture keeps Miu’s resting baseline if an optional model is unavailable. No AI-generated content replaces it.' },
        facts: [{ vi: 'Hình nền · Giữ nguyên', en: 'Baseline image · Preserved' }, { vi: 'Mô hình · Không được gọi', en: 'Model · Not invoked' }],
        cta: { vi: 'Tiếp tục với ảnh nền · Mẫu tắt', en: 'Continue with baseline · disabled fixture' },
        note: { vi: 'Không xóa ảnh, gọi mô hình hoặc thay đổi dữ liệu thú cưng.', en: 'No image is deleted, model is called or pet data changed.' }
      }
    }
  }
};

function batchBText(value, lang) {
  if (typeof value === 'string') return value;
  return value?.[lang] ?? '';
}

function initBatchBScene() {
  const root = document.querySelector('[data-scene]');
  if (!root) return;
  const scene = PQC018_BATCH_B_SCENES[root.dataset.scene];
  if (!scene) return;
  let lang = 'vi';
  let scale = '1';
  let stateId = root.dataset.initialState || Object.keys(scene.states)[0];
  const stateSelect = root.querySelector('[data-state-select]');
  Object.entries(scene.states).forEach(([id, item]) => {
    const option = document.createElement('option');
    option.value = id;
    option.textContent = batchBText(item.label, lang);
    stateSelect.append(option);
  });
  const render = () => {
    const item = scene.states[stateId];
    document.documentElement.lang = lang;
    document.documentElement.style.setProperty('--text-scale', scale);
    root.querySelectorAll('[data-common]').forEach(node => { node.textContent = batchBText(PQC018_BATCH_B_COMMON[node.dataset.common], lang); });
    root.querySelectorAll('[data-common-aria]').forEach(node => { node.setAttribute('aria-label', batchBText(PQC018_BATCH_B_COMMON[node.dataset.commonAria], lang)); });
    root.querySelector('[data-title]').textContent = batchBText(scene.title, lang);
    root.querySelector('[data-subtitle]').textContent = batchBText(scene.subtitle, lang);
    root.querySelector('[data-scene-image]').alt = batchBText(scene.alt, lang);
    [...stateSelect.options].forEach(option => { option.textContent = batchBText(scene.states[option.value].label, lang); });
    stateSelect.value = stateId;
    root.querySelector('[data-tag]').textContent = batchBText(item.tag, lang);
    root.querySelector('[data-state-title]').textContent = batchBText(item.title, lang);
    root.querySelector('[data-body]').textContent = batchBText(item.body, lang);
    root.querySelector('[data-note]').textContent = batchBText(item.note, lang);
    root.querySelector('[data-cta]').textContent = batchBText(item.cta, lang);
    const facts = root.querySelector('[data-facts]');
    facts.replaceChildren();
    item.facts.forEach(fact => { const li = document.createElement('li'); li.textContent = batchBText(fact, lang); facts.append(li); });
    const extra = root.querySelector('[data-reviewer-note-extra]');
    if (extra) extra.textContent = batchBText(scene.reviewerNotes, lang);
    const roster = root.querySelector('[data-friend-roster]');
    if (roster) {
      const friend = batchBText(item.friendRow, lang);
      roster.hidden = !friend;
      roster.querySelector('[data-friend-row]').textContent = friend;
    }
    root.querySelectorAll('[data-lang]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.lang === lang)));
    root.querySelectorAll('[data-scale]').forEach(button => button.setAttribute('aria-pressed', String(button.dataset.scale === scale)));
  };
  stateSelect.addEventListener('change', event => { stateId = event.target.value; render(); });
  root.querySelectorAll('[data-lang]').forEach(button => button.addEventListener('click', () => { lang = button.dataset.lang; render(); }));
  root.querySelectorAll('[data-scale]').forEach(button => button.addEventListener('click', () => { scale = button.dataset.scale; render(); }));
  render();
}

document.addEventListener('DOMContentLoaded', initBatchBScene);
