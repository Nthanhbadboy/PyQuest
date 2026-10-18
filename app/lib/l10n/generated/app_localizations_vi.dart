// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'PyQuest';

  @override
  String foundationGreeting(String name) {
    return 'Xin chào $name!';
  }

  @override
  String get foundationFollowsDevice => 'Bản này theo ngôn ngữ của thiết bị.';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsLanguageTitle => 'Ngôn ngữ';

  @override
  String get settingsLanguageSystem => 'Theo hệ thống';

  @override
  String get settingsLanguageVi => 'Tiếng Việt';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String settingsLanguageEffective(String language) {
    return 'Đang dùng: $language';
  }

  @override
  String get settingsLanguageFallback =>
      'Ngôn ngữ của thiết bị chưa được hỗ trợ. PyQuest đang dùng English.';

  @override
  String get settingsLanguageScope =>
      'Cài đặt và giao diện hệ thống đổi ngôn ngữ ngay. Một số nội dung khác đang được bổ sung bản dịch.';

  @override
  String get settingsLanguageSaving => 'Đang lưu lựa chọn…';

  @override
  String get settingsLanguageSaveError =>
      'Chưa lưu được lựa chọn. Ngôn ngữ vẫn được dùng trong lần mở này; lần mở sau có thể trở về lựa chọn đã lưu trước đó.';

  @override
  String get settingsLanguageRetry => 'Thử lưu lại';

  @override
  String get settingsSound => 'Âm thanh hiệu ứng';

  @override
  String get settingsMusic => 'Nhạc nền';

  @override
  String get settingsCalm => 'Chế độ êm dịu (ít chuyển động)';

  @override
  String get settingsAboutPython => 'Về PyQuest Python';

  @override
  String get settingsResetProgress => 'Xoá toàn bộ tiến trình';

  @override
  String get settingsFooter =>
      'PyQuest 0.1 · Đảo Khởi Đầu. Tiến trình được lưu trên thiết bị này.';

  @override
  String get settingsParentTitle => 'Dành cho bố mẹ';

  @override
  String get settingsParentWarning =>
      'Thao tác này xoá tiến trình, huy hiệu, mê cung tự tạo và đặt lại cài đặt trên thiết bị này. Để tiếp tục, hãy nhập kết quả:';

  @override
  String settingsParentQuestion(int a, int b) {
    return '$a × $b = ?';
  }

  @override
  String get settingsParentAnswer => 'Kết quả';

  @override
  String get settingsCancel => 'Huỷ';

  @override
  String get settingsDelete => 'Xoá';

  @override
  String get settingsPythonTitle => 'PyQuest Python (mô phỏng)';

  @override
  String get settingsPythonIntro =>
      'Code của bạn chạy trên một phiên bản Python thu nhỏ được viết riêng cho PyQuest, ngay trên máy, không cần mạng. Nó giống Python thật ở những phần cơ bản nhưng KHÔNG phải Python đầy đủ.';

  @override
  String get settingsPythonSupportedTitle => 'Bạn có thể dùng';

  @override
  String get settingsPythonLimitsTitle => 'Giới hạn';

  @override
  String get settingsPythonSupportedValues =>
      'print(), biến, số nguyên, số thập phân, chuỗi chữ, True/False, None';

  @override
  String get settingsPythonSupportedOperators =>
      'Phép tính + - * / // % ** và so sánh == != < > <= >=, and/or/not';

  @override
  String get settingsPythonSupportedFlow =>
      'if / elif / else, while, for ... in range(...), break, continue';

  @override
  String get settingsPythonSupportedLists =>
      'Danh sách: [1, 2, 3], ds[0], ds.append(), len(), in';

  @override
  String get settingsPythonSupportedFunctions =>
      'Hàm: def, return, tham số mặc định';

  @override
  String settingsPythonSupportedFString(String example) {
    return 'f-string đơn giản, ví dụ: $example';
  }

  @override
  String get settingsPythonSupportedBuiltins =>
      'Lệnh có sẵn: len, range, str, int, float, bool, abs, round, min, max, sum, list, sorted, type';

  @override
  String get settingsPythonLimitFeatures =>
      'Không có import, file, mạng, input(), class, dictionary, tuple, cắt chuỗi [a:b], try/except, lambda.';

  @override
  String get settingsPythonLimitSteps =>
      'Tối đa 100.000 bước chạy — vòng lặp vô tận sẽ được dừng an toàn.';

  @override
  String get settingsPythonLimitDepthOutput =>
      'Hàm gọi lồng nhau tối đa 50 tầng; in ra tối đa 10.000 ký tự.';

  @override
  String get settingsPythonLimitIntegers =>
      'Số nguyên giới hạn khoảng ±9 tỉ tỉ (Python thật không giới hạn).';

  @override
  String get settingsPythonLimitOutputTiming =>
      'Kết quả hiện ra sau khi chương trình chạy xong, không hiện từng dòng theo thời gian thực.';

  @override
  String get settingsPythonLimitNames =>
      'Không cho đặt tên biến trùng print, len, range để tránh lỗi khó hiểu.';

  @override
  String get hubIslandName => 'Đảo Khởi Đầu';

  @override
  String get hubQuestsTooltip => 'Nhiệm vụ hôm nay';

  @override
  String get hubSettingsTooltip => 'Cài đặt';

  @override
  String get hubVillageTab => 'Cảnh làng';

  @override
  String get hubPlacesTab => 'Địa điểm';

  @override
  String get hubRecommendationTitle => 'Gợi ý cho bạn';

  @override
  String hubVisitRecommended(String place) {
    return 'Ghé $place';
  }

  @override
  String get hubExplore => 'Khám phá';

  @override
  String get hubLocked => 'Cần học trước';

  @override
  String get hubLoading => 'Đang tải trạng thái';

  @override
  String get hubRetry => 'Thử lại';

  @override
  String get hubStatusUnavailable => 'Chưa tải được trạng thái';

  @override
  String get hubSceneScrollHint => 'Cuộn để khám phá đủ sáu địa điểm.';

  @override
  String get hubDirectoryHint =>
      'Chọn một hoạt động. Tiến trình và khóa mở vẫn được giữ nguyên.';

  @override
  String get hubMainQuest => 'Tháp Python';

  @override
  String get hubRobotMaze => 'Mê Cung Robo';

  @override
  String get hubDragonJump => 'Núi Lửa';

  @override
  String get hubCatchStars => 'Đài Thiên Văn';

  @override
  String get hubBugHunter => 'Xưởng Bitsy';

  @override
  String get hubAchievements => 'Nhà Thành Tích';

  @override
  String get hubHomeSemantics => 'PyQuest, Đảo Khởi Đầu';
}
