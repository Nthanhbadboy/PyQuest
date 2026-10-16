import '../../shared/characters/characters.dart';
import '../../shared/l10n/pq_l10n.dart';

/// Where an answer came from. The UI must always be able to tell the learner
/// whether a sentence was written by the AI or by the offline tutor.
enum TutorSource {
  /// Written by the configured AI provider.
  ai,

  /// Written on the device from the lesson content (rule based).
  offline,

  /// No endpoint configured in this build, so the offline tutor answered.
  offlineNoEndpoint,

  /// The AI call failed (network, timeout, server…) so the offline tutor answered.
  offlineAfterError,

  /// Today's AI questions are used up — offline tutor answered instead.
  offlineQuota,

  /// The learner stopped the request.
  cancelled;

  bool get isAi => this == TutorSource.ai;

  /// True when the text was produced on the device, not by a model.
  bool get isOffline => !isAi;

  String label(PqStrings s) => switch (this) {
        TutorSource.ai => s.labelAiWritten,
        TutorSource.offline => s.labelOffline,
        TutorSource.offlineNoEndpoint => s.labelOffline,
        TutorSource.offlineAfterError => s.labelOffline,
        TutorSource.offlineQuota => s.labelOffline,
        TutorSource.cancelled => s.labelOffline,
      };
}

/// Why a provider call did not produce an answer. Kept separate from the UI
/// strings so the session can decide whether to retry or fall back.
enum TutorFailKind {
  notConfigured,
  network,
  timeout,
  rateLimited,
  server,
  empty,
  blocked,
  badResponse;

  String message(PqStrings s) => switch (this) {
        TutorFailKind.notConfigured => s.errNoConfig,
        TutorFailKind.network => s.errNetwork,
        TutorFailKind.timeout => s.errTimeout,
        TutorFailKind.rateLimited => s.errRateLimited,
        TutorFailKind.server => s.errServer,
        TutorFailKind.empty => s.errEmpty,
        TutorFailKind.blocked => s.errBlocked,
        TutorFailKind.badResponse => s.errServer,
      };

  /// Worth one more try? Rate limits and safety blocks are not.
  bool get isRetryable =>
      this == TutorFailKind.network || this == TutorFailKind.timeout || this == TutorFailKind.server;
}

/// Buttons offered above the chat input. Each one is also an instruction the
/// tutor receives, so the answer matches the button the child pressed.
enum TutorQuickAction {
  explain,
  hint,
  mistake,
  example,
  challenge,
  walkthrough;

  String label(PqStrings s) => switch (this) {
        TutorQuickAction.explain => s.actionExplain,
        TutorQuickAction.hint => s.actionHint,
        TutorQuickAction.mistake => s.actionMistake,
        TutorQuickAction.example => s.actionExample,
        TutorQuickAction.challenge => s.actionChallenge,
        TutorQuickAction.walkthrough => s.actionWalkthrough,
      };

  /// The question actually sent. Written as a child's request, not as a
  /// system instruction, so the model answers rather than acknowledges it.
  String question(PqLang lang) {
    final vi = <TutorQuickAction, String>{
      TutorQuickAction.explain: 'Giải thích giúp mình bước này đang làm gì nhé.',
      TutorQuickAction.hint: 'Cho mình một gợi ý nhỏ, đừng nói đáp án nhé.',
      TutorQuickAction.mistake: 'Đoạn code của mình chưa chạy được. Bạn tìm giúp mình chỗ sai nhé.',
      TutorQuickAction.example: 'Cho mình một ví dụ nhỏ khác để dễ hiểu hơn nhé.',
      TutorQuickAction.challenge: 'Cho mình một thử thách thêm cho bước này nhé.',
      TutorQuickAction.walkthrough: 'Giải thích từng dòng của đoạn code này giúp mình nhé.',
    };
    final en = <TutorQuickAction, String>{
      TutorQuickAction.explain: 'Please explain what this step is doing.',
      TutorQuickAction.hint: 'Give me a small hint, please do not tell me the answer.',
      TutorQuickAction.mistake: 'My code does not work yet. Help me find what is wrong.',
      TutorQuickAction.example: 'Show me another small example so it is easier to understand.',
      TutorQuickAction.challenge: 'Give me an extra challenge for this step.',
      TutorQuickAction.walkthrough: 'Explain this code line by line for me.',
    };
    return (lang == PqLang.vi ? vi : en)[this]!;
  }
}

/// The hint ladder: a hint gets more concrete each time the learner is stuck,
/// but never hands over the whole solution before the late steps.
enum TutorHintLevel {
  /// Point at the exact place to look.
  pointing,

  /// Ask a guiding question.
  question,

  /// Show the shape of the code without the values.
  structure,

  /// Work the first line, leave the rest.
  workedStart,

  /// Late in the lesson: the full explanation is allowed.
  full;

  String labelVi() => switch (this) {
        TutorHintLevel.pointing => 'Chỉ chỗ cần xem',
        TutorHintLevel.question => 'Câu hỏi gợi mở',
        TutorHintLevel.structure => 'Khung code',
        TutorHintLevel.workedStart => 'Làm mẫu một phần',
        TutorHintLevel.full => 'Giải thích đầy đủ',
      };

  String labelEn() => switch (this) {
        TutorHintLevel.pointing => 'Where to look',
        TutorHintLevel.question => 'A guiding question',
        TutorHintLevel.structure => 'The code shape',
        TutorHintLevel.workedStart => 'First line worked',
        TutorHintLevel.full => 'Full explanation',
      };

  String label(PqLang lang) => lang == PqLang.vi ? labelVi() : labelEn();
}

/// Everything the tutor is allowed to know about the current exercise. Built
/// by the Main Quest (so this module never depends on lesson internals) and
/// containing no learner identity: no name, age, id or device data.
class TutorContext {
  const TutorContext({
    required this.lessonId,
    required this.lessonTitle,
    required this.skill,
    this.summary = '',
    this.stepIndex = 1,
    this.stepCount = 1,
    this.stepType = '',
    this.stepPrompt = '',
    this.expectedOutput,
    this.lessonHint,
    this.learnerCode,
    this.lastError,
    this.fails = 0,
  });

  final String lessonId;
  final String lessonTitle;
  final String skill;
  final String summary;

  /// 1-based position of the current step.
  final int stepIndex;
  final int stepCount;
  final String stepType;
  final String stepPrompt;
  final String? expectedOutput;
  final String? lessonHint;

  /// What the child has written so far (may be empty).
  final String? learnerCode;

  /// The last error message from the Python runtime, if the code failed.
  final String? lastError;

  /// How many times this step failed, used to climb the hint ladder.
  final int fails;

  bool get hasCode => (learnerCode ?? '').trim().isNotEmpty;
  bool get isLateStep => stepIndex >= 5;
  bool get isLastStep => stepIndex >= stepCount;

  /// Human-readable context block for the model, truncated by the caller.
  String describe(PqLang lang) {
    final b = StringBuffer();
    void add(String label, String? value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) b.writeln('$label: $v');
    }

    add(lang == PqLang.vi ? 'Bài' : 'Lesson', '$lessonTitle ($lessonId)');
    add(lang == PqLang.vi ? 'Kỹ năng' : 'Skill', skill);
    add(lang == PqLang.vi ? 'Tóm tắt bài' : 'Lesson summary', summary);
    add(lang == PqLang.vi ? 'Bước' : 'Step', '$stepIndex/$stepCount (${stepType.isEmpty ? 'exercise' : stepType})');
    add(lang == PqLang.vi ? 'Đề bài' : 'Task', stepPrompt);
    add(lang == PqLang.vi ? 'Kết quả mong đợi' : 'Expected output', expectedOutput);
    add(lang == PqLang.vi ? 'Gợi ý có sẵn trong bài' : 'Hint already in the lesson', lessonHint);
    add(lang == PqLang.vi ? 'Code bé đã viết' : 'Code written so far', learnerCode);
    add(lang == PqLang.vi ? 'Lỗi gần nhất khi chạy' : 'Last runtime error', lastError);
    if (fails > 0) add(lang == PqLang.vi ? 'Số lần thử lại' : 'Failed attempts on this step', '$fails');
    return b.toString().trim();
  }

  TutorContext copyWith({
    String? learnerCode,
    String? lastError,
    int? fails,
    int? stepIndex,
    String? stepPrompt,
    String? stepType,
    String? expectedOutput,
    String? lessonHint,
  }) =>
      TutorContext(
        lessonId: lessonId,
        lessonTitle: lessonTitle,
        skill: skill,
        summary: summary,
        stepIndex: stepIndex ?? this.stepIndex,
        stepCount: stepCount,
        stepType: stepType ?? this.stepType,
        stepPrompt: stepPrompt ?? this.stepPrompt,
        expectedOutput: expectedOutput ?? this.expectedOutput,
        lessonHint: lessonHint ?? this.lessonHint,
        learnerCode: learnerCode ?? this.learnerCode,
        lastError: lastError ?? this.lastError,
        fails: fails ?? this.fails,
      );

  @override
  String toString() => 'TutorContext($lessonId step $stepIndex/$stepCount)';
}

/// One question, ready to be sent (or answered offline).
class TutorRequest {
  const TutorRequest({
    required this.question,
    required this.context,
    required this.lang,
    this.character = CharacterId.nova,
    this.quickAction,
  });

  final String question;
  final TutorContext context;
  final PqLang lang;

  /// Which cast member answers — sets the tone of the reply.
  final CharacterId character;
  final TutorQuickAction? quickAction;

  TutorRequest copyWith({String? question, TutorContext? context, PqLang? lang, CharacterId? character}) =>
      TutorRequest(
        question: question ?? this.question,
        context: context ?? this.context,
        lang: lang ?? this.lang,
        character: character ?? this.character,
        quickAction: quickAction,
      );
}

/// The tutor's answer plus the facts about how it was produced.
class TutorReply {
  const TutorReply({
    required this.text,
    required this.source,
    required this.character,
    this.hintLevel,
    this.failKind,
    this.latency = Duration.zero,
    this.usedQuota = false,
    this.attempts = 0,
  });

  final String text;
  final TutorSource source;
  final CharacterId character;

  /// Set when the answer is a hint from the ladder.
  final TutorHintLevel? hintLevel;

  /// Set when the AI call failed and the offline tutor stepped in.
  final TutorFailKind? failKind;

  /// Wall-clock time the provider call took (0 for offline answers).
  final Duration latency;

  /// True when this answer consumed one of today's AI questions.
  final bool usedQuota;
  final int attempts;

  bool get isAi => source.isAi;

  @override
  String toString() => 'TutorReply(${source.name}, ${text.length} chars)';
}

/// A stored conversation line, so the panel can reopen with yesterday's
/// answers and the tutor can avoid repeating itself.
class TutorTurn {
  const TutorTurn({
    required this.question,
    required this.answer,
    required this.source,
    required this.lessonId,
    required this.at,
    this.character = CharacterId.nova,
    this.hintLevel,
  });

  final String question;
  final String answer;
  final TutorSource source;
  final String lessonId;
  final DateTime at;
  final CharacterId character;
  final TutorHintLevel? hintLevel;

  Map<String, Object?> toJson() => {
        'q': question,
        'a': answer,
        'src': source.name,
        'lesson': lessonId,
        'at': at.millisecondsSinceEpoch,
        'ch': character.name,
        if (hintLevel != null) 'hint': hintLevel!.name,
      };

  static TutorTurn? fromJson(Map<String, dynamic> j) {
    final q = j['q'] as String?;
    final a = j['a'] as String?;
    if (q == null || a == null) return null;
    return TutorTurn(
      question: q,
      answer: a,
      source: TutorSource.values.firstWhere(
        (s) => s.name == j['src'],
        orElse: () => TutorSource.offline,
      ),
      lessonId: j['lesson'] as String? ?? '',
      at: DateTime.fromMillisecondsSinceEpoch((j['at'] as num?)?.toInt() ?? 0),
      character: CharacterId.values.firstWhere(
        (c) => c.name == j['ch'],
        orElse: () => CharacterId.nova,
      ),
      hintLevel: j['hint'] == null
          ? null
          : TutorHintLevel.values.firstWhere(
              (h) => h.name == j['hint'],
              orElse: () => TutorHintLevel.pointing,
            ),
    );
  }
}
