const PQC018_COMMON = {
  fixture: { vi: 'MẪU THIẾT KẾ · KHÔNG CÓ DỮ LIỆU THẬT', en: 'DESIGN FIXTURE · NO LIVE DATA' },
  language: { vi: 'Ngôn ngữ xem', en: 'Preview language' },
  textSize: { vi: 'Cỡ chữ xem', en: 'Preview text size' },
  state: { vi: 'Trạng thái minh họa', en: 'Fixture state' },
  noRuntime: { vi: 'Bản xem tĩnh · Không kết nối app, tài khoản, mạng, lưu trữ hoặc giao dịch.', en: 'Static study · No app, account, network, persistence or transaction is connected.' },
  sources: { vi: 'Nguồn & phạm vi', en: 'Sources & scope' },
  back: { vi: 'Bộ ảnh PQC-018', en: 'PQC-018 art set' },
  code: { vi: 'Code nguồn · Chỉ đọc', en: 'Source code · Read only' },
  expected: { vi: 'expected_output từ dữ liệu · chưa thực thi', en: 'expected_output from data · not executed' },
  preferences: { vi: 'Tùy chọn mẫu', en: 'Preference fixtures' },
  sound: { vi: 'Âm thanh hiệu ứng', en: 'Sound effects' },
  music: { vi: 'Nhạc nền', en: 'Music' },
  calm: { vi: 'Chế độ êm dịu · ít chuyển động', en: 'Calm mode · less motion' },
  sampleOn: { vi: 'BẬT · MẪU', en: 'ON · FIXTURE' },
  sampleOff: { vi: 'TẮT · MẪU', en: 'OFF · FIXTURE' }
};

const PQC018_SCENES = {
  'a01-w04-journal': {
    title: { vi: 'Sổ hành trình', en: 'Journey Journal' },
    subtitle: { vi: 'Dự án · Nhật ký · Kết quả', en: 'Projects · Notes · Results' },
    alt: { vi: 'Sổ hành trình mở trên bàn gỗ tròn trong góc đọc nhìn ra làng PyQuest.', en: 'An open journey journal on a round wooden table in a reading nook overlooking PyQuest village.' },
    states: {
      following: {
        label: { vi: 'Đang theo dự án', en: 'Following a project' },
        tag: { vi: 'DỰ ÁN ĐANG THEO', en: 'FOLLOWED PROJECT' },
        title: { vi: 'Một dự án dài, một mục tiêu riêng mỗi ngày', en: 'One long project, a separate daily goal' },
        body: { vi: 'Dự án đang theo vẫn giữ chỗ riêng trong hành trình. Nhiệm vụ ngày là việc khác; đổi dự án không xóa tiến độ.', en: 'The followed project keeps its own place in the journey. A daily goal is separate; changing projects does not erase progress.' },
        facts: [
          { vi: 'Dự án · Phòng sáng tạo (mẫu)', en: 'Project · Creative room (fixture)' },
          { vi: 'Hôm nay · mục tiêu riêng, không gộp vào dự án', en: 'Today · a separate goal, not merged into the project' }
        ],
        cta: { vi: 'Mở dự án · Mẫu', en: 'Open project · fixture' },
        note: { vi: 'Dữ liệu minh họa; không có tiến trình hoặc phần thưởng thật.', en: 'Illustrative data; no live progress or reward is connected.' }
      },
      not_following: {
        label: { vi: 'Chưa theo dự án', en: 'No followed project' },
        tag: { vi: 'CHỌN KHI SẴN SÀNG', en: 'CHOOSE WHEN READY' },
        title: { vi: 'Bạn có thể chọn một việc để theo', en: 'Choose a project when you are ready' },
        body: { vi: 'Chưa có dự án được chọn. Mục tiêu hằng ngày vẫn là một phần riêng và không bắt buộc phải bắt đầu dự án.', en: 'No project is selected. A daily goal stays separate, and starting a project is optional.' },
        facts: [
          { vi: 'Dự án đang theo · Chưa chọn (mẫu)', en: 'Followed project · None selected (fixture)' },
          { vi: 'Mục tiêu hằng ngày · Hiển thị riêng', en: 'Daily goal · Shown separately' }
        ],
        cta: { vi: 'Xem dự án · Mẫu', en: 'Browse projects · fixture' },
        note: { vi: 'Không có yêu cầu mua hàng hoặc điều kiện mới trong hình minh họa.', en: 'This illustration adds no purchase requirement or new eligibility rule.' }
      },
      pending_results: {
        label: { vi: 'Nhiều kết quả chờ', en: 'Several results pending' },
        tag: { vi: 'CẦN KIỂM TRA', en: 'NEEDS REVIEW' },
        title: { vi: 'Các kết quả vẫn ở riêng từng dòng', en: 'Keep each result in its own entry' },
        body: { vi: 'Mẫu nhiều kết quả đang chờ. Kiểm tra từng receipt của cùng một kết quả; không ghi đè hoặc tạo bản nhận mới.', en: 'Fixture with several pending results. Recheck the same receipt for each result; do not overwrite it or create a new claim.' },
        facts: [
          { vi: 'Kết quả minh họa A · Chờ xác minh', en: 'Sample result A · Awaiting verification' },
          { vi: 'Kết quả minh họa B · Chờ xác minh', en: 'Sample result B · Awaiting verification' },
          { vi: 'Kết quả minh họa C · Chờ xác minh', en: 'Sample result C · Awaiting verification' }
        ],
        cta: { vi: 'Xem trạng thái · Mẫu', en: 'View status · fixture' },
        note: { vi: 'Không hiển thị số lượng vật liệu, grant hay receipt thật.', en: 'No material quantity, grant, or real receipt is displayed.' }
      },
      load_error: {
        label: { vi: 'Lỗi tải', en: 'Load error' },
        tag: { vi: 'CHƯA TẢI ĐƯỢC', en: 'COULD NOT LOAD' },
        title: { vi: 'Sổ hành trình chưa sẵn sàng', en: 'The journal is not ready yet' },
        body: { vi: 'Giữ nguyên dự án và kết quả đang chờ. Thử tải lại cùng trạng thái; không tạo nhiệm vụ mới.', en: 'Keep the followed project and pending results intact. Retry the same state; do not create a new task.' },
        facts: [
          { vi: 'Tiến độ · Chưa xác minh', en: 'Progress · Not verified' },
          { vi: 'Kết quả chờ · Không bị xóa bởi lỗi tải', en: 'Pending results · Not erased by a load failure' }
        ],
        cta: { vi: 'Thử tải lại · Mẫu', en: 'Retry loading · fixture' },
        note: { vi: 'Nút chỉ đổi trạng thái trong bản xem thiết kế.', en: 'The button only previews a state in this design study.' }
      }
    }
  },
  'a02-shared-settings': {
    title: { vi: 'Cài đặt', en: 'Settings' },
    subtitle: { vi: 'Ngôn ngữ · Âm thanh · Hiển thị', en: 'Language · Sound · Display' },
    alt: { vi: 'Góc điều khiển bằng gỗ và đá, có bảng trống nhìn ra quảng trường PyQuest.', en: 'A timber-and-stone control alcove with a blank panel overlooking PyQuest square.' },
    states: {
      system_active: {
        label: { vi: 'Theo hệ thống', en: 'System language' }, tag: { vi: 'TỰ ĐỘNG', en: 'AUTOMATIC' },
        title: { vi: 'Dùng ngôn ngữ của thiết bị', en: 'Use the device language' },
        body: { vi: 'Ngôn ngữ hệ thống đang được dùng. Ngôn ngữ hiển thị hiệu lực là Tiếng Việt (mẫu).', en: 'The system preference is selected. The effective language is English (fixture).' },
        facts: [{ vi: 'Hiệu lực · Tiếng Việt', en: 'Effective · English' }, { vi: 'Phạm vi · Ứng dụng PyQuest', en: 'Scope · PyQuest app' }],
        cta: { vi: 'Đang dùng · Mẫu', en: 'Currently selected · fixture' },
        note: { vi: 'Không đọc hoặc thay đổi quyền/ngôn ngữ hệ điều hành trong bản này.', en: 'This study does not read or change operating-system permissions or language.' }
      },
      system_fallback: {
        label: { vi: 'Dự phòng hệ thống', en: 'System fallback' }, tag: { vi: 'DỰ PHÒNG', en: 'FALLBACK' },
        title: { vi: 'Dùng Tiếng Anh khi chưa có bản dịch', en: 'Use English when a translation is unavailable' },
        body: { vi: 'Tùy chọn hệ thống vẫn được giữ. Bản xem trước dùng Tiếng Anh làm ngôn ngữ dự phòng.', en: 'The system preference remains selected. This fixture uses English as the fallback language.' },
        facts: [{ vi: 'Tùy chọn · Hệ thống', en: 'Preference · System' }, { vi: 'Hiệu lực · Tiếng Anh dự phòng (mẫu)', en: 'Effective · English fallback (fixture)' }],
        cta: { vi: 'Xem dự phòng · Mẫu', en: 'Preview fallback · fixture' },
        note: { vi: 'Đây là trạng thái minh họa, không phải kiểm tra locale thiết bị.', en: 'This is an illustrative state, not a device-locale check.' }
      },
      manual_vi: {
        label: { vi: 'Tiếng Việt', en: 'Vietnamese' }, tag: { vi: 'CHỌN THỦ CÔNG', en: 'MANUAL OVERRIDE' },
        title: { vi: 'Ưu tiên Tiếng Việt', en: 'Prefer Vietnamese' },
        body: { vi: 'Lựa chọn thủ công được ưu tiên hơn ngôn ngữ hệ thống trong ứng dụng.', en: 'The manual choice takes precedence over the system language in the app.' },
        facts: [{ vi: 'Lựa chọn · Tiếng Việt', en: 'Selection · Vietnamese' }, { vi: 'Phạm vi · Ứng dụng PyQuest', en: 'Scope · PyQuest app' }],
        cta: { vi: 'Chọn Tiếng Việt · Mẫu', en: 'Select Vietnamese · fixture' },
        note: { vi: 'Không thay đổi cài đặt hệ thống của thiết bị.', en: 'The device’s system setting is not changed.' }
      },
      manual_en: {
        label: { vi: 'English', en: 'English' }, tag: { vi: 'CHỌN THỦ CÔNG', en: 'MANUAL OVERRIDE' },
        title: { vi: 'Prefer English', en: 'Prefer English' },
        body: { vi: 'Lựa chọn thủ công được ưu tiên hơn ngôn ngữ hệ thống trong ứng dụng.', en: 'The manual choice takes precedence over the system language in the app.' },
        facts: [{ vi: 'Lựa chọn · English', en: 'Selection · English' }, { vi: 'Phạm vi · Ứng dụng PyQuest', en: 'Scope · PyQuest app' }],
        cta: { vi: 'Chọn English · Mẫu', en: 'Select English · fixture' },
        note: { vi: 'Không thay đổi cài đặt hệ thống của thiết bị.', en: 'The device’s system setting is not changed.' }
      },
      save_error: {
        label: { vi: 'Lưu thất bại', en: 'Save failed' }, tag: { vi: 'LỖI LƯU', en: 'SAVE ERROR' },
        title: { vi: 'Lựa chọn mới vẫn dùng trong phiên', en: 'Your new choice still applies for now' },
        body: { vi: 'Ngôn ngữ mới có hiệu lực trong phiên nhưng chưa ghi được. Báo lỗi và cho thử lại cùng lựa chọn; lần mở sau có thể trở về lựa chọn đã lưu trước đó.', en: 'The new language applies for this session but could not be saved. Show the error and retry the same choice; next time, the previously saved preference may return.' },
        facts: [{ vi: 'Hiệu lực trong phiên · Có', en: 'Effective this session · Yes' }, { vi: 'Đã lưu · Chưa', en: 'Persisted · No' }],
        cta: { vi: 'Thử lại · Mẫu', en: 'Retry · fixture' },
        note: { vi: 'Không có ghi dữ liệu thật trong bản xem này.', en: 'No real preference is written in this preview.' }
      },
      retry: {
        label: { vi: 'Đang thử lại', en: 'Retrying' }, tag: { vi: 'ĐANG CHỜ', en: 'WAITING' },
        title: { vi: 'Đang kiểm tra cùng lựa chọn', en: 'Checking the same preference' },
        body: { vi: 'Mẫu chờ thử lại không tạo một yêu cầu cài đặt khác hoặc khẳng định thành công.', en: 'The retry fixture does not create another settings request or claim success.' },
        facts: [{ vi: 'Yêu cầu · Giữ nguyên', en: 'Request · Unchanged' }, { vi: 'Kết quả · Chưa xác nhận', en: 'Result · Not confirmed' }],
        cta: { vi: 'Chờ kết quả · Mẫu', en: 'Waiting · fixture' },
        note: { vi: 'Chỉ là trạng thái giao diện minh họa.', en: 'Interface state only; illustrative.' }
      }
    }
  },
  'a03-shared-welcome': {
    title: { vi: 'Chào mừng đến PyQuest', en: 'Welcome to PyQuest' },
    subtitle: { vi: 'Bến làng · Lối vào mở', en: 'Village landing · Open way in' },
    alt: { vi: 'Bến gỗ nối qua cổng làng mở, con đường đi tới tháp mái xanh.', en: 'A timber dock and open village gate lead along a path toward a teal-roof tower.' },
    states: {
      first_visit: {
        label: { vi: 'Lần đầu ghé', en: 'First visit' }, tag: { vi: 'BẠN ĐANG Ở BẾN', en: 'YOU ARE AT THE LANDING' },
        title: { vi: 'Một thế giới mới để khám phá', en: 'A new world to explore' },
        body: { vi: 'Cổng đang mở và con đường dẫn vào làng. Bạn có thể bắt đầu ở quảng trường; không cần mua hàng hay mở bài học trước.', en: 'The gate is open and the path leads into the village square. You can begin exploring without a purchase or a required lesson first.' },
        facts: [{ vi: 'Điểm đến · Quảng trường làng (mẫu)', en: 'Destination · Village square (fixture)' }, { vi: 'Tài khoản đám mây · Không được mô phỏng', en: 'Cloud account · Not simulated' }],
        cta: { vi: 'Vào làng · Mẫu', en: 'Enter village · fixture' },
        note: { vi: 'Bản xem không tạo tài khoản hoặc đồng bộ đám mây.', en: 'This study creates no account or cloud sync.' }
      },
      returning: {
        label: { vi: 'Quay lại', en: 'Returning' }, tag: { vi: 'CHÀO MỪNG TRỞ LẠI', en: 'WELCOME BACK' },
        title: { vi: 'Tiếp tục từ nơi bạn dừng lại', en: 'Continue where you left off' },
        body: { vi: 'Mẫu quay lại giữ nguyên một lối vào làng. Không tự chọn dự án, đổi ngôn ngữ hoặc mở Tutor thay bạn.', en: 'The returning fixture keeps the village entrance available. It does not choose a project, change language, or open Tutor for you.' },
        facts: [{ vi: 'Điểm đến · Quảng trường làng (mẫu)', en: 'Destination · Village square (fixture)' }, { vi: 'Trạng thái lưu · Chưa kết nối', en: 'Saved state · Not connected' }],
        cta: { vi: 'Tiếp tục · Mẫu', en: 'Continue · fixture' },
        note: { vi: 'Không có cloud account hoặc restore thật.', en: 'No cloud account or actual restore is connected.' }
      },
      loading: {
        label: { vi: 'Đang tải', en: 'Loading' }, tag: { vi: 'ĐANG CHUẨN BỊ', en: 'GETTING READY' },
        title: { vi: 'Đang mở cánh cổng', en: 'Opening the gate' },
        body: { vi: 'Giữ nguyên điểm đến đã chọn. Đây là trạng thái tải minh họa, không có mạng hoặc dữ liệu tài khoản phía sau.', en: 'Keep the selected destination. This is a loading illustration with no network or account data behind it.' },
        facts: [{ vi: 'Lối vào · Quảng trường làng', en: 'Entry · Village square' }, { vi: 'Dữ liệu · Mẫu tĩnh', en: 'Data · Static fixture' }],
        cta: { vi: 'Đang tải · Mẫu', en: 'Loading · fixture' },
        note: { vi: 'Không tự chuyển màn trong bản xem.', en: 'This preview does not navigate automatically.' }
      },
      retry: {
        label: { vi: 'Thử lại', en: 'Retry' }, tag: { vi: 'CHƯA KẾT NỐI', en: 'NOT CONNECTED' },
        title: { vi: 'Chưa mở được làng', en: 'The village did not open' },
        body: { vi: 'Giữ lối vào và cho phép thử lại. Không tạo phiên đăng nhập hoặc báo rằng tiến trình đã được đồng bộ.', en: 'Keep the entrance available and offer a retry. Do not create a login session or report that progress has synced.' },
        facts: [{ vi: 'Điểm đến · Giữ nguyên', en: 'Destination · Preserved' }, { vi: 'Phiên · Chưa xác minh', en: 'Session · Not verified' }],
        cta: { vi: 'Thử lại · Mẫu', en: 'Retry · fixture' },
        note: { vi: 'Lỗi/khôi phục chỉ được mô phỏng bằng trạng thái tĩnh.', en: 'Failure/recovery is shown as a static fixture only.' }
      }
    }
  },
  'a04-w05-catch-stars': {
    title: { vi: 'Đài Thiên Văn', en: 'Star Observatory' },
    subtitle: { vi: 'Hái Sao · Robo', en: 'Catch Stars · Robo' },
    alt: { vi: 'Đài quan sát ban đêm với Robo teal/brass và bình hứng dưới đường rơi sao, sao chổi, sao cầu vồng và thiên thạch.', en: 'A night observatory with teal-and-brass Robo and a catcher below falling stars, a comet, rainbow star and meteor.' },
    states: {
      ready: {
        label: { vi: 'Sẵn sàng', en: 'Ready' }, tag: { vi: 'MẪU TRÒ CHƠI', en: 'GAME STUDY' },
        title: { vi: 'Kéo bình để hứng sao', en: 'Move the jar to catch stars' },
        body: { vi: 'Sao rơi qua vùng chơi; bình là vật cần điều khiển. Né thiên thạch. Bố cục này không định nghĩa tốc độ, điểm, va chạm hoặc đáp án.', en: 'Stars fall through the play lane; the jar is the controlled catcher. Avoid meteors. This composition does not define speed, score, collision or answers.' },
        facts: [{ vi: 'Nhân vật dẫn · Robo theo CastRegistry', en: 'Host · Robo identity follows CastRegistry' }, { vi: 'Lệnh · Hứng sao / né thiên thạch', en: 'Action · Catch stars / avoid meteors' }],
        cta: { vi: 'Điều khiển · Tắt trong mẫu', en: 'Controls · Disabled in fixture' },
        note: { vi: 'Không có game loop, điểm số, energy hoặc receipt trong layout này.', en: 'No game loop, score, energy or receipt runs in this layout.' }
      },
      paused: {
        label: { vi: 'Tạm dừng', en: 'Paused' }, tag: { vi: 'LƯỢT ĐANG DỞ', en: 'ATTEMPT PAUSED' },
        title: { vi: 'Bạn có thể nghỉ một chút', en: 'You can take a short break' },
        body: { vi: 'Giữ lượt và chương trình đang dở khi tạm dừng. Scene đứng yên; không chạy timer nền hoặc trừ lượt mới.', en: 'Keep the current attempt and program while paused. The scene stays still; no background timer or new attempt is consumed.' },
        facts: [{ vi: 'Lượt hiện tại · Giữ nguyên (mẫu)', en: 'Current attempt · Preserved (fixture)' }, { vi: 'Hiệu ứng chuyển động · Đã dừng trong mẫu', en: 'Motion effects · Stopped in fixture' }],
        cta: { vi: 'Tiếp tục · Mẫu', en: 'Resume · fixture' },
        note: { vi: 'Không mô phỏng trạng thái runtime hoặc pause thực.', en: 'No runtime attempt or real pause is simulated.' }
      },
      result: {
        label: { vi: 'Kết quả mẫu', en: 'Result fixture' }, tag: { vi: 'CHƯA THỰC THI', en: 'NOT EXECUTED' },
        title: { vi: 'Đọc dữ kiện trước hiệu ứng', en: 'Facts before effects' },
        body: { vi: 'Bảng kết quả phải lấy dữ liệu từ lượt chơi thật. Ảnh này không cho biết thắng, điểm, sao hay phần thưởng.', en: 'A result panel must use data from the real attempt. This image does not establish a win, score, stars or reward.' },
        facts: [{ vi: 'Trạng thái · Mẫu chưa xác minh', en: 'Status · Unverified fixture' }, { vi: 'Phần thưởng · Không được tạo bởi artwork', en: 'Reward · Not created by artwork' }],
        cta: { vi: 'Về hoạt động · Mẫu', en: 'Back to activity · fixture' },
        note: { vi: 'Không cấp hoặc xác nhận phần thưởng.', en: 'No reward is granted or verified.' }
      }
    }
  },
  'a05-w05-bug-hunter': {
    title: { vi: 'Xưởng Bitsy', en: 'Bitsy’s Workshop' },
    subtitle: { vi: 'Săn bọ lỗi · Code có nguồn', en: 'Bug Hunter · Source-backed code' },
    alt: { vi: 'Bitsy mèo tím lavender đeo nơ xanh và kính lúp bên bàn sửa lỗi có bảng code trống.', en: 'Lavender Bitsy with a green bow and magnifier at a debugging bench with a blank code board.' },
    code: ['print("Xin chào!")', 'print("Tớ là Bitsy)'],
    expectedOutput: 'Xin chào!\nTớ là Bitsy',
    states: {
      locked: {
        label: { vi: 'Chưa mở', en: 'Locked' }, tag: { vi: 'CẦN BÀI TRƯỚC', en: 'LESSON GATE' },
        title: { vi: 'Học print() và số trước nhé', en: 'Learn print() and numbers first' },
        body: { vi: 'Nguồn gốc mở gói đầu là bài mq1_03 theo puzzle data. Đây là trạng thái mẫu; không mở khóa bằng ảnh hoặc nút này.', en: 'The first pack’s source gate is lesson mq1_03 in the puzzle data. This is a fixture; an image or button does not unlock it.' },
        facts: [{ vi: 'Điều kiện · Trạng thái bài học', en: 'Gate · Lesson completion state' }, { vi: 'Nguồn · bug_hunter_puzzles.json', en: 'Source · bug_hunter_puzzles.json' }],
        cta: { vi: 'Xem điều kiện · Mẫu', en: 'View requirement · fixture' },
        note: { vi: 'Không chèn đáp án hoặc mở game thật.', en: 'No answer is inserted and no game is launched.' }
      },
      ready: {
        label: { vi: 'Đã mở · Mẫu', en: 'Ready · fixture' }, tag: { vi: 'BÀI TẬP CÓ NGUỒN', en: 'SOURCE-BACKED PUZZLE' },
        title: { vi: 'Tìm dòng có bọ lỗi', en: 'Find the line with a bug' },
        body: { vi: 'Code dưới đây là literal từ câu đố bh_01 trong source. Kết quả là expected_output của dữ liệu; bản xem không thực thi code.', en: 'The code below is literal from source puzzle bh_01. The result is its expected_output; this preview does not execute code.' },
        facts: [{ vi: 'Gói · Chữ và số', en: 'Pack · Text and numbers' }, { vi: 'Mở khóa · Bài mq1_03', en: 'Unlock · Lesson mq1_03' }],
        cta: { vi: 'Chạy thử · Tắt trong mẫu', en: 'Run sample · Disabled in fixture' },
        note: { vi: 'Không cung cấp lựa chọn sửa, lời giải hoặc kết quả chạy thật.', en: 'No fix options, solution or live execution result is provided.' }
      },
      wrong_error: {
        label: { vi: 'Lỗi / sửa sai', en: 'Error / wrong fix' }, tag: { vi: 'MẪU LỖI', en: 'ERROR FIXTURE' },
        title: { vi: 'Giữ lại manh mối, không bịa đáp án', en: 'Keep the clue; do not invent an answer' },
        body: { vi: 'Dòng 2 được đánh dấu theo puzzle source. Lỗi cụ thể và lựa chọn sửa phải đến từ engine/dataset; chưa có lần chạy trong bản xem này.', en: 'Line 2 is marked from the puzzle source. The exact error and available fixes belong to the engine/dataset; nothing was run in this preview.' },
        facts: [{ vi: 'Puzzle · bh_01 (mẫu)', en: 'Puzzle · bh_01 (fixture)' }, { vi: 'Thực thi · Chưa chạy', en: 'Execution · Not run' }],
        cta: { vi: 'Xem manh mối · Mẫu', en: 'View clue · fixture' },
        note: { vi: 'Không hiển thị SyntaxError giả hoặc lời giải tự sinh.', en: 'No fabricated SyntaxError or generated solution is shown.' }
      }
    }
  }
};

function text(value, lang) {
  if (typeof value === 'string') return value;
  return value?.[lang] ?? '';
}

function initScene() {
  const root = document.querySelector('[data-scene]');
  if (!root) return;
  const scene = PQC018_SCENES[root.dataset.scene];
  if (!scene) return;
  let lang = 'vi';
  let scale = '1';
  let stateId = root.dataset.initialState || Object.keys(scene.states)[0];
  const title = root.querySelector('[data-title]');
  const subtitle = root.querySelector('[data-subtitle]');
  const tag = root.querySelector('[data-tag]');
  const stateTitle = root.querySelector('[data-state-title]');
  const body = root.querySelector('[data-body]');
  const facts = root.querySelector('[data-facts]');
  const note = root.querySelector('[data-note]');
  const cta = root.querySelector('[data-cta]');
  const image = root.querySelector('[data-scene-image]');
  const stateSelect = root.querySelector('[data-state-select]');
  const state = () => scene.states[stateId];

  Object.entries(scene.states).forEach(([id, entry]) => {
    const option = document.createElement('option');
    option.value = id;
    option.textContent = text(entry.label, lang);
    stateSelect.append(option);
  });

  const render = () => {
    document.documentElement.lang = lang;
    document.documentElement.style.setProperty('--text-scale', scale);
    root.querySelectorAll('[data-common]').forEach(node => {
      node.textContent = text(PQC018_COMMON[node.dataset.common], lang);
    });
    root.querySelectorAll('[data-common-aria]').forEach(node => {
      node.setAttribute('aria-label', text(PQC018_COMMON[node.dataset.commonAria], lang));
    });
    title.textContent = text(scene.title, lang);
    subtitle.textContent = text(scene.subtitle, lang);
    image.alt = text(scene.alt, lang);
    stateSelect.value = stateId;
    [...stateSelect.options].forEach(option => {
      option.textContent = text(scene.states[option.value].label, lang);
    });
    const current = state();
    tag.textContent = text(current.tag, lang);
    stateTitle.textContent = text(current.title, lang);
    body.textContent = text(current.body, lang);
    note.textContent = text(current.note, lang);
    cta.textContent = text(current.cta, lang);
    facts.replaceChildren();
    current.facts.forEach(fact => {
      const li = document.createElement('li');
      li.textContent = text(fact, lang);
      facts.append(li);
    });
    root.querySelectorAll('[data-lang]').forEach(button => {
      button.setAttribute('aria-pressed', String(button.dataset.lang === lang));
    });
    root.querySelectorAll('[data-scale]').forEach(button => {
      button.setAttribute('aria-pressed', String(button.dataset.scale === scale));
    });
    const codePanel = root.querySelector('[data-code-panel]');
    if (codePanel) {
      codePanel.hidden = !scene.code || !['ready', 'wrong_error'].includes(stateId);
      const codeLines = codePanel.querySelector('[data-code-lines]');
      codeLines.replaceChildren();
      if (!codePanel.hidden) {
        scene.code.forEach((line, index) => {
          const row = document.createElement('div');
          row.className = `code-line${stateId === 'wrong_error' && index === 1 ? ' is-error' : ''}`;
          const number = document.createElement('span');
          number.className = 'line-number';
          number.textContent = String(index + 1);
          const code = document.createElement('code');
          code.textContent = line;
          row.append(number, code);
          codeLines.append(row);
        });
      }
      const output = codePanel.querySelector('[data-code-output]');
      output.hidden = stateId !== 'ready';
      if (scene.expectedOutput && stateId === 'ready') output.querySelector('pre').textContent = scene.expectedOutput;
    }
  };

  stateSelect.addEventListener('change', event => { stateId = event.target.value; render(); });
  root.querySelectorAll('[data-lang]').forEach(button => button.addEventListener('click', () => { lang = button.dataset.lang; render(); }));
  root.querySelectorAll('[data-scale]').forEach(button => button.addEventListener('click', () => { scale = button.dataset.scale; render(); }));
  render();
}

document.addEventListener('DOMContentLoaded', initScene);
