/// Language support for the cast and the AI tutor.
///
/// The rest of the island still speaks Vietnamese (its strings are written
/// inline across the UI), so this file deliberately covers only the two
/// systems that need both languages: character dialogue and the tutor. The
/// learner can switch language in Settings; every tutor request carries the
/// chosen language so answers come back in it.
library;

enum PqLang {
  vi('vi', 'Tiếng Việt'),
  en('en', 'English');

  const PqLang(this.code, this.label);

  /// BCP-47-ish code sent to the tutor provider.
  final String code;

  /// Shown in Settings.
  final String label;

  static PqLang fromCode(String? code) =>
      PqLang.values.firstWhere((l) => l.code == code, orElse: () => PqLang.vi);
}

/// Tutor + cast strings. Get an instance with [PqStrings.of].
class PqStrings {
  const PqStrings(this.lang);

  final PqLang lang;

  static const PqStrings vi = PqStrings(PqLang.vi);
  static const PqStrings en = PqStrings(PqLang.en);

  static PqStrings of(PqLang lang) => lang == PqLang.vi ? vi : en;

  bool get isVi => lang == PqLang.vi;

  // ---------------------------------------------------------------- tutor UI
  String get askTutor => isVi ? 'Hỏi trợ giảng' : 'Ask the tutor';
  String get tutorTitle => isVi ? 'Trợ giảng' : 'Tutor';
  String get thinking => isVi ? 'đang soạn câu trả lời…' : 'is writing…';
  String get retry => isVi ? 'Thử lại' : 'Try again';
  String get send => isVi ? 'Gửi' : 'Send';
  String get close => isVi ? 'Đóng' : 'Close';
  String get hintLadder => isVi ? 'Mức gợi ý' : 'Hint level';
  String get copyCode => isVi ? 'Sao chép code' : 'Copy code';
  String get copied => isVi ? 'Đã sao chép!' : 'Copied!';
  String get askPlaceholder =>
      isVi ? 'Hỏi bất cứ điều gì về bài này…' : 'Ask anything about this lesson…';

  // who is speaking in the tutor conversation (never inferred from the text)
  String get childLabel => isVi ? 'Bé' : 'You';
  String get interruptedTag => isVi ? 'bị ngắt lời' : 'interrupted';
  String get spokenTag => isVi ? 'qua giọng nói' : 'by voice';

  // labels that keep verified facts apart from generated explanations
  String get labelRanCode => isVi ? 'Kết quả chạy thật' : 'Real run result';
  String get labelAiWritten => isVi ? 'Do AI soạn' : 'AI-written';
  String get labelOffline => isVi ? 'Trợ giảng ngoại tuyến' : 'Offline tutor';
  String get labelStepHint => isVi ? 'Gợi ý của bài học' : 'Lesson hint';

  // quick actions
  String get actionExplain => isVi ? 'Giải thích' : 'Explain';
  String get actionHint => isVi ? 'Cho gợi ý' : 'Give me a hint';
  String get actionMistake => isVi ? 'Tìm lỗi giúp mình' : 'Find my mistake';
  String get actionExample => isVi ? 'Ví dụ nhỏ' : 'Show an example';
  String get actionChallenge => isVi ? 'Thử thách thêm' : 'Give me a challenge';
  String get actionWalkthrough => isVi ? 'Giải thích từng dòng' : 'Line by line';

  // states / errors
  String get errNoConfig => isVi
      ? 'Trợ giảng AI chưa được cấu hình trên bản này, nên mình dùng trợ giảng ngoại tuyến của đảo nhé!'
      : 'The AI tutor is not configured in this build, so I am using the island’s offline tutor.';
  String get errNetwork => isVi
      ? 'Mạng đang không ổn. Mình chưa gửi được câu hỏi — bạn thử lại nhé, hoặc hỏi trợ giảng ngoại tuyến.'
      : 'The network is not cooperating. I could not send your question — try again, or ask the offline tutor.';
  String get errTimeout => isVi
      ? 'Trợ giảng trả lời lâu quá nên mình tạm dừng chờ. Thử lại nhé!'
      : 'The tutor took too long, so I stopped waiting. Please try again!';
  String get errRateLimited => isVi
      ? 'Trợ giảng đang bận một chút. Chờ vài giây rồi thử lại nhé.'
      : 'The tutor is busy right now. Wait a few seconds and try again.';
  String get errServer => isVi
      ? 'Trợ giảng đang gặp sự cố. Bạn vẫn học tiếp bài được — thử lại sau nhé.'
      : 'The tutor hit a problem. You can keep learning — try again later.';
  String get errEmpty => isVi
      ? 'Trợ giảng gửi về câu trả lời rỗng. Thử hỏi lại theo cách khác nhé.'
      : 'The tutor sent an empty answer. Try asking in another way.';
  String get errBlocked => isVi
      ? 'Câu trả lời bị bộ lọc an toàn chặn lại. Mình thử cách khác nhé.'
      : 'The answer was stopped by a safety filter. Let us try another way.';
  String get errCancelled => isVi ? 'Bạn đã dừng câu hỏi này.' : 'You stopped this question.';

  // offline tutor notes
  String get offlineNotice => isVi
      ? 'Trợ giảng ngoại tuyến dùng chính nội dung bài học trên máy, không cần mạng.'
      : 'The offline tutor uses the lesson content on this device and needs no network.';
  String get offlineNoFakeAi => isVi
      ? 'Phần này do trợ giảng ngoại tuyến soạn, không phải AI.'
      : 'This part was written by the offline tutor, not by the AI.';
  String get aiNotice => isVi
      ? 'AI có thể sai. Hãy chạy code để kiểm chứng điều mình đọc được.'
      : 'AI can be wrong. Run the code to check what you read.';

  // quota
  String quotaLeft(int left, int total) => isVi
      ? 'Còn $left/$total câu hỏi AI hôm nay'
      : '$left/$total AI questions left today';
  String get quotaEmpty => isVi
      ? 'Hôm nay bạn đã dùng hết câu hỏi AI. Trợ giảng ngoại tuyến vẫn sẵn sàng, và bài học không bị giới hạn đâu!'
      : 'You used all AI questions today. The offline tutor is still here, and lessons are never limited!';
  String get quotaResetHint => isVi ? 'Hạn mức làm mới vào ngày mai.' : 'The limit refreshes tomorrow.';
  String get quotaNotForSale => isVi
      ? 'PyQuest không bán điểm hay bán lượt hỏi — không có quảng cáo chặn bài học.'
      : 'PyQuest does not sell points or questions — no ads interrupt lessons.';

  // learned-context notes
  String memoryRecurring(String topic, int times) => isVi
      ? 'Mình nhớ bạn từng gặp lỗi về $topic $times lần, nên lần này mình giải thích kỹ hơn nhé.'
      : 'I remember you ran into trouble with $topic $times before, so let us go slower here.';
  String milestoneCelebration(String name) => isVi
      ? '$name rất vui vì bạn đã tiến bộ!'
      : '$name is proud of your progress!';

  // safety / honesty in the panel footer
  String get childPrivacyNote => isVi
      ? 'Chỉ nội dung bài học và đoạn code bạn viết được gửi đi. Không gửi tên, tuổi hay thông tin cá nhân.'
      : 'Only the lesson and the code you wrote are sent. Your name, age and personal details are not.';
  String get aiMayInventCode => isVi
      ? 'Code trong câu trả lời chỉ là ví dụ để đọc — trợ giảng không tự chạy code của bạn.'
      : 'Code in an answer is only an example to read — the tutor never runs your code for you.';
}
