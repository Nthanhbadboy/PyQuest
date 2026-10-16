import '../../shared/characters/cast.dart';
import '../../shared/l10n/pq_l10n.dart';
import 'tutor_config.dart';
import 'tutor_models.dart';
import 'tutor_provider.dart';

/// Builds the messages sent to the provider.
///
/// Two promises this file keeps:
/// * **Privacy** — only lesson content, the code the child wrote and the
///   question leave the device. Learner identity is never part of a prompt,
///   and anything that looks like an email address or a phone number inside
///   the child's own question is redacted before sending.
/// * **Honesty** — the model is told that it cannot run code, that it must
///   not pretend to, and that a full solution is only allowed from step
///   [TutorConfig.minStepForDirectAnswer] onwards.
abstract final class TutorPrompt {
  static const String _redacted = '[đã ẩn]';

  static List<TutorMessage> build(TutorRequest request, TutorConfig config) {
    return [
      TutorMessage('system', _system(request, config)),
      TutorMessage('user', _user(request, config)),
    ];
  }

  static String _system(TutorRequest request, TutorConfig config) {
    final persona = CastRegistry.of(request.character).promptPersona;
    final language = request.lang == PqLang.vi ? 'Vietnamese' : 'English';
    final lateStep = request.context.stepIndex >= config.minStepForDirectAnswer;
    final solutionRule = lateStep
        ? 'The child is on a late step of this lesson (step ${request.context.stepIndex}), '
            'so you may explain the complete solution once, in short numbered steps.'
        : 'The child is on step ${request.context.stepIndex} of the lesson. '
            'Do NOT give the complete solution: give one partial step, one small example, '
            'or one guiding question, and let the child finish the rest.';
    return '''
You are a coding tutor inside PyQuest, a Python adventure game for children under 12.
$persona

Reply ONLY in $language. Use short sentences and words a nine-year-old can read. Aim for 90 words or fewer, never more than 140 words.
$solutionRule

Hard rules:
1. You cannot run code and you never claim to have run, tested or checked anything. Real results only come from the game's own Python runner, which the child sees separately.
2. Never invent an error message or an output. If you did not see one, say you did not see one.
3. Teach in this order: the idea in one sentence, then how it applies to the task in front of the child, then one thing for the child to try.
4. Code goes in a single ```python block of at most 6 lines, using only basic Python 3: print, variables, arithmetic, if/elif/else, for, while, def, return. Never import anything, never open files, never use the internet.
5. Never ask for or repeat personal details: no names, ages, schools, addresses, phone numbers, photos or passwords. If the child mentions any, do not repeat it and move back to the lesson.
6. Stay on Python and this lesson. If the child asks about something else, answer in one friendly sentence and bring the question back to the code.
7. Never mention that you are a language model, and never apologise repeatedly. No emoji.
8. If you are not sure, say what you are unsure about and suggest running the code in the game to find out.
'''
        .trim();
  }

  static String _user(TutorRequest request, TutorConfig config) {
    final ctx = request.context;
    final trimmedCode = _truncate(ctx.learnerCode ?? '', _codeBudget(config));
    final scoped = trimmedCode == (ctx.learnerCode ?? '') ? ctx : ctx.copyWith(learnerCode: trimmedCode);
    var block = scoped.describe(request.lang);
    if (block.length > config.maxLessonContextChars) {
      block = '${block.substring(0, config.maxLessonContextChars)}\n…(${request.lang == PqLang.vi ? 'phần còn lại đã bỏ bớt' : 'rest omitted'})';
    }
    final question = sanitiseQuestion(request.question, config.maxQuestionChars);
    final header = request.lang == PqLang.vi
        ? 'Thông tin bài học hiện tại của bé (đây là toàn bộ những gì bé gửi kèm):'
        : 'The child’s current lesson (this is everything sent along):';
    final ask = request.lang == PqLang.vi
        ? 'Câu hỏi của bé:'
        : 'The child asks:';
    return '$header\n$block\n\n$ask\n$question';
  }

  static int _codeBudget(TutorConfig config) {
    final budget = (config.maxLessonContextChars * 0.4).floor();
    return budget < 400 ? 400 : budget;
  }

  static String _truncate(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}\n#…(${s.length - max} ký tự đã bỏ bớt)';

  /// Removes obvious personal data from free text typed by a child, and caps
  /// the length so one message cannot grow without bound.
  static String sanitiseQuestion(String raw, int maxChars) {
    var s = raw.trim();
    s = s.replaceAll(RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'), _redacted);
    s = s.replaceAll(RegExp(r'(?:\+?\d[\d\s.\-]{7,}\d)'), _redacted);
    if (s.length > maxChars) s = '${s.substring(0, maxChars)}…';
    return s;
  }
}
