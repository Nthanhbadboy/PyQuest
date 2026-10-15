import '../../shared/l10n/pq_l10n.dart';
import 'tutor_models.dart';

/// The tutor that works with no network and no model.
///
/// It is honestly rule-based: it picks from content that ships inside the app
/// (the lesson in front of the child plus a small Python knowledge table) and
/// the UI always labels it "Trợ giảng ngoại tuyến / Offline tutor". It never
/// pretends to be the AI, never invents a runtime result, and never claims to
/// have run the child's code.
class OfflineTutor {
  const OfflineTutor();

  /// A complete answer to [request].
  String answer(TutorRequest request) {
    final ctx = request.context;
    final q = request.question.toLowerCase();
    final lang = request.lang;

    bool asks(List<String> words) => words.any(q.contains);

    if (asks(['gợi ý', 'hint', 'đừng nói đáp án'])) {
      return hint(levelFor(ctx), ctx, lang);
    }
    if (asks(['lỗi', 'sai', 'error', 'không chạy', 'tìm lỗi', 'mistake'])) {
      return errorHelp(ctx, lang);
    }
    if (asks(['ví dụ', 'example'])) {
      return exampleAnswer(ctx, lang);
    }
    if (asks(['thử thách', 'challenge', 'khó hơn'])) {
      return challengeAnswer(ctx, lang);
    }
    if (asks(['từng dòng', 'line by line', 'giải thích code', 'đoạn code này'])) {
      return walkthrough(ctx, lang);
    }
    return explain(ctx, lang);
  }

  /// Where the learner is on the hint ladder: more attempts or a later step
  /// means a more concrete hint.
  TutorHintLevel levelFor(TutorContext ctx) {
    if (ctx.fails >= 5 || (ctx.isLateStep && ctx.fails >= 3)) return TutorHintLevel.full;
    if (ctx.fails >= 3) return TutorHintLevel.workedStart;
    if (ctx.fails >= 2) return TutorHintLevel.structure;
    if (ctx.fails >= 1) return TutorHintLevel.question;
    return TutorHintLevel.pointing;
  }

  /// One rung of the hint ladder. Never hands over the answer before the late
  /// steps of a lesson.
  String hint(TutorHintLevel level, TutorContext ctx, PqLang lang) {
    final topic = _topicFor(ctx);
    final where = _location(ctx, lang);
    final vi = <TutorHintLevel, String>{
      TutorHintLevel.pointing: 'Nhìn kỹ $where nhé. '
          'Đó là chỗ quyết định kết quả của bước này.',
      TutorHintLevel.question: 'Thử trả lời câu hỏi này trước: ${topic.question(valuesOf(ctx)).vi}',
      TutorHintLevel.structure: 'Khung làm bài chỉ có dạng ${topic.shape.vi}. '
          'Bạn thử tự điền phần còn lại nhé.',
      TutorHintLevel.workedStart: 'Mình làm mẫu phần đầu, phần sau để bạn:\n'
          '${topic.workedStart(ctx, PqLang.vi)}',
      TutorHintLevel.full: 'Bạn đã thử nhiều lần rồi nên mình nói rõ nhé — cách làm là: '
          '${topic.approach(ctx, PqLang.vi)}\n${_expected(ctx, PqLang.vi)}'
          'Sau khi chạy xong, thử đổi một giá trị để xem kết quả đổi thế nào.',
    };
    final en = <TutorHintLevel, String>{
      TutorHintLevel.pointing: 'Look closely at $where. '
          'That is what decides the result of this step.',
      TutorHintLevel.question: 'First answer this question: ${topic.question(valuesOf(ctx)).en}',
      TutorHintLevel.structure: 'The solution only has the shape ${topic.shape.en}. '
          'Fill in the rest yourself.',
      TutorHintLevel.workedStart: 'I will start it, you finish:\n'
          '${topic.workedStart(ctx, PqLang.en)}',
      TutorHintLevel.full: 'You have tried several times, so here is the full picture: '
          '${topic.approach(ctx, PqLang.en)}\n${_expected(ctx, PqLang.en)}'
          'When it runs, change one value and see how the result changes.',
    };
    return (lang == PqLang.vi ? vi : en)[level]!;
  }

  /// Explains the last runtime error in child-friendly words, using the real
  /// error text the runtime produced (never a made-up one).
  String errorHelp(TutorContext ctx, PqLang lang) {
    final topic = _topicFor(ctx);
    final error = (ctx.lastError ?? '').trim();
    if (lang == PqLang.vi) {
      final head = error.isEmpty
          ? 'Bước này chưa chạy được nên mình chưa thấy thông báo lỗi.'
          : 'Thông báo lỗi thật khi chạy là:\n$error\n'
              '${_errorHintVi(error)}';
      return '$head\n\n'
          'Cách tìm lỗi theo thứ tự: đọc dòng bị báo lỗi, đếm dấu ngoặc và dấu hai chấm, '
          'rồi đọc tên biến xem có viết giống nhau ở mọi chỗ không. '
          'Chỗ thường sai nhất trong bài này: ${topic.commonMistake.vi}\n\n'
          'Sửa xong bạn chạy lại — kết quả chạy thật trong khung bên dưới là điều duy nhất chứng minh đúng.';
    }
    final head = error.isEmpty
        ? 'This step has not run yet, so there is no error message.'
        : 'The real error from the last run was:\n$error\n'
            '${_errorHintEn(error)}';
    return '$head\n\n'
        'Check in this order: read the reported line, count brackets and colons, '
        'then compare variable names everywhere they appear. '
        'The usual mistake in this lesson: ${topic.commonMistake.en}\n\n'
        'Run it again after fixing — the real run result below is the only proof.';
  }

  String explain(TutorContext ctx, PqLang lang) {
    final topic = _topicFor(ctx);
    if (lang == PqLang.vi) {
      return '${topic.idea.vi}\n\n'
          'Bước ${ctx.stepIndex}/${ctx.stepCount} đang hỏi: ${_task(ctx)}\n'
          '${_expected(ctx, PqLang.vi)}'
          'Thử trước đã: ${topic.experiment.vi}';
    }
    return '${topic.idea.en}\n\n'
        'Step ${ctx.stepIndex}/${ctx.stepCount} asks: ${_task(ctx)}\n'
        '${_expected(ctx, PqLang.en)}'
        'Try this first: ${topic.experiment.en}';
  }

  String exampleAnswer(TutorContext ctx, PqLang lang) {
    final topic = _topicFor(ctx);
    return lang == PqLang.vi
        ? 'Ví dụ nhỏ (đọc thôi, đừng chép nguyên vào bài):\n${topic.example.vi}\n\n'
            'Đọc xong bạn thử đoán xem máy in ra gì, rồi chạy thử để kiểm chứng.'
        : 'A small example (read it, do not paste it into your answer):\n${topic.example.en}\n\n'
            'Guess what it prints, then run it to check.';
  }

  String challengeAnswer(TutorContext ctx, PqLang lang) {
    final topic = _topicFor(ctx);
    return lang == PqLang.vi
        ? 'Thử thách thêm cho bước này: ${topic.challenge.vi}\n'
            'Cách này khó hơn một chút nhưng dùng đúng kiến thức của bài, bạn thử nhé.'
        : 'An extra challenge for this step: ${topic.challenge.en}\n'
            'It is a bit harder but uses exactly what this lesson taught.';
  }

  String walkthrough(TutorContext ctx, PqLang lang) {
    if (!ctx.hasCode) {
      return lang == PqLang.vi
          ? 'Bạn chưa viết dòng code nào ở bước này. Viết thử vài dòng theo đề bài, '
              'rồi mình cùng xem từng dòng nhé.'
          : 'You have not written any code in this step yet. Write a few lines following the task, '
              'then we can go through them together.';
    }
    final lines = ctx.learnerCode!.split('\n').where((l) => l.trim().isNotEmpty).take(8).toList();
    final b = StringBuffer();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      b.writeln(lang == PqLang.vi
          ? '• Dòng ${i + 1}: `$line` — ${_linePurposeVi(line)}'
          : '• Line ${i + 1}: `$line` — ${_linePurposeEn(line)}');
    }
    b.write(lang == PqLang.vi
        ? '\nMình đọc theo code bạn viết, không tự sửa. Bạn sửa ở khung code rồi chạy lại nhé.'
        : '\nThis reads the code you wrote; it does not edit anything. Fix it in the editor and run again.');
    return b.toString();
  }

  // ---------------------------------------------------------------- helpers

  String _task(TutorContext ctx) =>
      ctx.stepPrompt.trim().isEmpty ? ctx.lessonTitle : ctx.stepPrompt.trim();

  String _expected(TutorContext ctx, PqLang lang) {
    final out = ctx.expectedOutput?.trim();
    if (out == null || out.isEmpty) return '';
    return lang == PqLang.vi
        ? 'Kết quả mong đợi của bài: `$out`.\n'
        : 'Expected output: `$out`.\n';
  }

  String _location(TutorContext ctx, PqLang lang) {
    final type = ctx.stepType;
    if (type == 'write') {
      return lang == PqLang.vi
          ? 'các dòng bạn đang viết trong khung code'
          : 'the lines you are writing in the code box';
    }
    if (type == 'order') {
      return lang == PqLang.vi ? 'thứ tự các dòng lệnh' : 'the order of the lines';
    }
    if (type == 'fill') {
      return lang == PqLang.vi ? 'những chỗ trống trong mẫu code' : 'the blanks in the code template';
    }
    if (type == 'choice') {
      return lang == PqLang.vi ? 'kết quả mà đoạn code sẽ in ra' : 'what the code will print';
    }
    return lang == PqLang.vi ? 'đề bài của bước này' : 'the task of this step';
  }

  List<String> valuesOf(TutorContext ctx) {
    final task = _task(ctx);
    final numbers = RegExp(r'\d+').allMatches(task).map((m) => m.group(0)!).toList();
    if (numbers.isNotEmpty) return numbers.take(3).toList();
    final quoted = RegExp('["\']([^"\']{1,12})["\']').allMatches(task).map((m) => m.group(1)!).toList();
    return quoted.take(2).toList();
  }

  String _errorHintVi(String error) {
    final e = error.toLowerCase();
    if (e.contains('syntax') || e.contains('cú pháp')) {
      return '→ Đây là lỗi cú pháp: máy chưa đọc được câu lệnh. Kiểm tra dấu ngoặc, dấu hai chấm cuối dòng if/for, và dấu nháy quanh chuỗi.';
    }
    if (e.contains('name') || e.contains('chưa được định nghĩa') || e.contains('không xác định')) {
      return '→ Máy gặp một tên mà nó chưa biết: có thể bạn viết sai chính tả tên biến, hoặc dùng biến trước khi gán giá trị.';
    }
    if (e.contains('type') || e.contains('kiểu')) {
      return '→ Có chỗ trộn số với chuỗi. Số thì không cần nháy, chữ thì phải có nháy.';
    }
    if (e.contains('indent') || e.contains('thụt')) {
      return '→ Lỗi thụt lề: các dòng bên trong if/for phải thụt vào cùng một khoảng.';
    }
    return '→ Đọc dòng bị báo lỗi trước, rồi sửa đúng dòng đó và chạy lại.';
  }

  String _errorHintEn(String error) {
    final e = error.toLowerCase();
    if (e.contains('syntax')) {
      return '→ That is a syntax error: the computer could not read the line. Check brackets, the colon at the end of if/for, and quotes around text.';
    }
    if (e.contains('name')) {
      return '→ The computer met a name it does not know: a variable is misspelled or used before it is given a value.';
    }
    if (e.contains('type')) {
      return '→ Numbers and text are mixed up. Numbers need no quotes, text does.';
    }
    if (e.contains('indent')) {
      return '→ Indentation error: the lines inside if/for must be indented by the same amount.';
    }
    return '→ Read the line that is reported, fix exactly that line, then run again.';
  }

  String _linePurposeVi(String line) {
    final l = line.trim();
    if (l.startsWith('print')) return 'in ra màn hình';
    if (l.contains('input')) return 'nhận dữ liệu vào (bài này mình tự cho giá trị)';
    if (l.startsWith('if')) return 'kiểm tra điều kiện';
    if (l.startsWith('elif')) return 'kiểm tra điều kiện tiếp theo';
    if (l.startsWith('else')) return 'trường hợp còn lại';
    if (l.startsWith('for') || l.startsWith('while')) return 'bắt đầu vòng lặp';
    if (l.startsWith('def')) return 'định nghĩa một hàm';
    if (l.startsWith('return')) return 'trả kết quả ra ngoài hàm';
    if (l.startsWith('#')) return 'ghi chú, máy không chạy dòng này';
    if (l.contains('=')) return 'gán giá trị cho biến';
    return 'một câu lệnh của chương trình';
  }

  String _linePurposeEn(String line) {
    final l = line.trim();
    if (l.startsWith('print')) return 'prints to the screen';
    if (l.contains('input')) return 'reads input (this lesson gives values directly)';
    if (l.startsWith('if')) return 'checks a condition';
    if (l.startsWith('elif')) return 'checks the next condition';
    if (l.startsWith('else')) return 'everything else';
    if (l.startsWith('for') || l.startsWith('while')) return 'starts a loop';
    if (l.startsWith('def')) return 'defines a function';
    if (l.startsWith('return')) return 'hands a value back out of the function';
    if (l.startsWith('#')) return 'a comment, the computer skips it';
    if (l.contains('=')) return 'stores a value in a variable';
    return 'a statement of the program';
  }

  _TutorTopic _topicFor(TutorContext ctx) {
    final haystack = '${ctx.skill} ${ctx.stepPrompt} ${ctx.lessonTitle}'.toLowerCase();
    bool has(List<String> words) => words.any(haystack.contains);
    if (has(['vòng lặp', 'loop', 'while', 'for '])) return _TutorTopic.loops;
    if (has(['hàm', 'def', 'function', 'return'])) return _TutorTopic.functions;
    if (has(['điều kiện', 'if', 'else', 'so sánh', 'condition'])) return _TutorTopic.conditions;
    if (has(['biến', 'variable'])) return _TutorTopic.variables;
    if (has(['chuỗi', 'string', 'ghép chữ', 'nối chữ'])) return _TutorTopic.strings;
    if (has(['số', 'phép tính', 'number', 'tính toán'])) return _TutorTopic.numbers;
    if (has(['lỗi', 'sửa', 'debug'])) return _TutorTopic.debugging;
    if (has(['in ra', 'print', 'thứ tự', 'lệnh'])) return _TutorTopic.printing;
    return _TutorTopic.general;
  }
}

/// Pairs of Vietnamese/English fragments, kept together so the two languages
/// can never drift apart.
class _Bi {
  const _Bi(this.vi, this.en);
  final String vi;
  final String en;
}

class _TutorTopic {
  const _TutorTopic({
    required this.idea,
    required this.example,
    required this.experiment,
    required this.commonMistake,
    required this.challenge,
    required this.shape,
  });

  final _Bi idea;
  final _Bi example;
  final _Bi experiment;
  final _Bi commonMistake;
  final _Bi challenge;
  final _Bi shape;

  _Bi question(List<String> values) {
    final v = values;
    if (v.isEmpty) {
      return const _Bi(
        'Trong đề bài, chương trình cần in ra đúng nội dung gì?',
        'What exactly must the program print?',
      );
    }
    return _Bi(
      'Nếu thay ${v.first} bằng ${v.length > 1 ? v[1] : 'một giá trị khác'}, kết quả sẽ đổi thế nào?',
      'If ${v.first} became ${v.length > 1 ? v[1] : 'another value'}, what would change?',
    );
  }

  String workedStart(TutorContext ctx, PqLang lang) {
    if (ctx.hasCode) {
      final first = ctx.learnerCode!.split('\n').first.trim();
      if (first.isNotEmpty) return first;
    }
    return lang == PqLang.vi
        ? 'Dòng đầu tiên của bài thường là chỗ tạo ra giá trị cần dùng.'
        : 'The first line of the task usually creates the value you need.';
  }

  String approach(TutorContext ctx, PqLang lang) {
    final task = ctx.stepPrompt.trim().isEmpty ? ctx.lessonTitle : ctx.stepPrompt.trim();
    return '$task → ${lang == PqLang.vi ? idea.vi : idea.en}';
  }

  static const _TutorTopic printing = _TutorTopic(
    idea: _Bi(
      'Chương trình chạy từ trên xuống dưới, mỗi dòng xong rồi mới tới dòng sau. print() đưa nội dung ra màn hình theo đúng thứ tự đó.',
      'A program runs from top to bottom, one line at a time. print() puts text on the screen in that exact order.',
    ),
    example: _Bi(
      "print('Xin chào')\nprint('PyQuest')",
      "print('Hello')\nprint('PyQuest')",
    ),
    experiment: _Bi(
      'đổi thứ tự hai dòng print và đoán xem kết quả đổi thế nào.',
      'swap the two print lines and guess how the output changes.',
    ),
    commonMistake: _Bi('thiếu dấu nháy quanh phần chữ cần in.', 'missing quotes around the text to print.'),
    challenge: _Bi(
      'in ra ba dòng, trong đó dòng thứ hai là tên đảo của bạn.',
      'print three lines, where the second one is your island name reversed.',
    ),
    shape: _Bi('một dòng print cho mỗi nội dung cần in', 'one print line per piece of output'),
  );

  static const _TutorTopic variables = _TutorTopic(
    idea: _Bi(
      'Biến giống một chiếc hộp có dán nhãn: bạn cất một giá trị vào đó và gọi lại bằng tên hộp. Khi bạn cất giá trị mới, giá trị cũ không còn nữa.',
      'A variable is a labelled box: you put a value in and call it back by name. Put a new value in and the old one is gone.',
    ),
    example: _Bi(
      'diem = 5\nprint(diem)\ndiem = diem + 1\nprint(diem)',
      'score = 5\nprint(score)\nscore = score + 1\nprint(score)',
    ),
    experiment: _Bi(
      'đổi số ban đầu rồi đoán xem lần in thứ hai ra số mấy.',
      'change the starting number and guess the second print.',
    ),
    commonMistake: _Bi(
      'viết tên biến khác nhau ở hai chỗ (ví dụ diem và Diem).',
      'writing the variable name differently in two places (score vs Score).',
    ),
    challenge: _Bi(
      'dùng ba biến và in ra tổng của chúng.',
      'use three variables and print their total.',
    ),
    shape: _Bi('tên biến = giá trị', 'name = value'),
  );

  static const _TutorTopic conditions = _TutorTopic(
    idea: _Bi(
      'if chỉ chạy phần bên trong khi điều kiện đúng. Dấu hai chấm kết thúc dòng if, và các dòng bên trong phải thụt lề.',
      'if runs the lines inside it only when the condition is true. A colon ends the if line and the inside lines must be indented.',
    ),
    example: _Bi(
      'tuoi = 9\nif tuoi >= 8:\n    print("Lớn rồi")\nelse:\n    print("Còn nhỏ")',
      'age = 9\nif age >= 8:\n    print("Big")\nelse:\n    print("Small")',
    ),
    experiment: _Bi(
      'đổi giá trị so sánh để rơi vào nhánh else.',
      'change the value so the else branch runs.',
    ),
    commonMistake: _Bi('thiếu dấu hai chấm hoặc thụt lề sai.', 'a missing colon or wrong indentation.'),
    challenge: _Bi(
      'thêm nhánh elif cho trường hợp ở giữa.',
      'add an elif branch for the middle case.',
    ),
    shape: _Bi('if <so sánh>:', 'if <condition>:'),
  );

  static const _TutorTopic loops = _TutorTopic(
    idea: _Bi(
      'Vòng lặp làm lại cùng một việc nhiều lần. Máy chỉ dừng khi điều kiện sai, nên bên trong vòng lặp phải có một dòng làm giá trị thay đổi.',
      'A loop repeats the same job. The computer stops only when the condition turns false, so something inside must change the value.',
    ),
    example: _Bi(
      'so = 1\nwhile so <= 3:\n    print(so)\n    so = so + 1',
      'n = 1\nwhile n <= 3:\n    print(n)\n    n = n + 1',
    ),
    experiment: _Bi(
      'đổi số cuối cùng và đếm xem vòng lặp chạy bao nhiêu lần.',
      'change the final number and count how many rounds run.',
    ),
    commonMistake: _Bi(
      'quên tăng giá trị nên vòng lặp chạy mãi tới khi chạm giới hạn của PyQuest.',
      'forgetting to increase the value, so the loop runs until it hits the PyQuest limit.',
    ),
    challenge: _Bi(
      'in ra bảng cửu chương của một số bằng một vòng lặp for.',
      'print a multiplication table with one for loop.',
    ),
    shape: _Bi('while <điều kiện>:', 'while <condition>:'),
  );

  static const _TutorTopic functions = _TutorTopic(
    idea: _Bi(
      'Hàm là một khối lệnh được đặt tên, viết một lần và gọi lại nhiều lần. return trả kết quả ra ngoài, còn print chỉ hiện lên màn hình.',
      'A function is a named block you write once and call many times. return hands a value back out; print only shows it.',
    ),
    example: _Bi(
      'def gap_doi(x):\n    return x * 2\n\nprint(gap_doi(4))',
      'def double(x):\n    return x * 2\n\nprint(double(4))',
    ),
    experiment: _Bi(
      'gọi hàm hai lần với hai giá trị khác nhau.',
      'call the function twice with different values.',
    ),
    commonMistake: _Bi(
      'quên gọi hàm (thiếu dấu ngoặc) nên chỉ nhận được tên hàm.',
      'forgetting the brackets, so you get the function name instead of its result.',
    ),
    challenge: _Bi(
      'viết hàm nhận hai số và trả về số lớn hơn.',
      'write a function that takes two numbers and returns the larger one.',
    ),
    shape: _Bi('def <tên>(<tham số>):', 'def <name>(<parameters>):'),
  );

  static const _TutorTopic strings = _TutorTopic(
    idea: _Bi(
      'Chuỗi là đoạn chữ đặt trong dấu nháy. Dấu + nối hai chuỗi lại, nhưng không nối được chuỗi với số.',
      'A string is text inside quotes. + joins two strings, but it cannot join a string with a number.',
    ),
    example: _Bi(
      'ten = "Nova"\nprint("Chào " + ten + "!")',
      'name = "Nova"\nprint("Hi " + name + "!")',
    ),
    experiment: _Bi(
      'thử nối một số vào chuỗi để xem máy báo gì.',
      'try joining a number to a string and read what the computer says.',
    ),
    commonMistake: _Bi('quên dấu cách trong chuỗi.', 'forgetting the space inside the string.'),
    challenge: _Bi(
      'in ra một câu chào có tên và số tuổi giả của nhân vật.',
      'print a greeting with a name and a pretend age.',
    ),
    shape: _Bi('"chữ " + "chữ"', '"text " + "text"'),
  );

  static const _TutorTopic numbers = _TutorTopic(
    idea: _Bi(
      'Máy tính làm đúng thứ tự phép tính như ở lớp: nhân chia trước, cộng trừ sau; dấu ngoặc đổi thứ tự.',
      'The computer follows the usual order of operations: multiply and divide before add and subtract; brackets change it.',
    ),
    example: _Bi('print(2 + 3 * 4)\nprint((2 + 3) * 4)', 'print(2 + 3 * 4)\nprint((2 + 3) * 4)'),
    experiment: _Bi(
      'đoán hai kết quả trên trước khi chạy.',
      'guess both results before running.',
    ),
    commonMistake: _Bi('quên dấu ngoặc nên kết quả lệch.', 'missing brackets, so the result is off.'),
    challenge: _Bi(
      'tính tiền mua 3 món với giá khác nhau bằng một dòng.',
      'compute the price of three items in a single line.',
    ),
    shape: _Bi('print(<phép tính>)', 'print(<expression>)'),
  );

  static const _TutorTopic debugging = _TutorTopic(
    idea: _Bi(
      'Sửa lỗi gồm ba bước: đọc thông báo lỗi theo đúng dòng, đoán nguyên nhân, sửa đúng một chỗ rồi chạy lại.',
      'Debugging is three steps: read the message and its line, guess the cause, fix one thing and run again.',
    ),
    example: _Bi(
      'print("PyQuest)   ← thiếu dấu nháy đóng',
      'print("PyQuest)   ← missing closing quote',
    ),
    experiment: _Bi(
      'sửa đúng một chỗ mỗi lần để biết chỗ nào gây lỗi.',
      'fix one thing at a time so you know which one caused it.',
    ),
    commonMistake: _Bi('sửa nhiều chỗ cùng lúc rồi không biết chỗ nào đúng.', 'changing many places at once.'),
    challenge: _Bi(
      'cố tình tạo một lỗi rồi tự sửa mà không xem gợi ý.',
      'create an error on purpose and fix it without a hint.',
    ),
    shape: _Bi('đọc lỗi → đoán → sửa một chỗ → chạy lại', 'read → guess → fix one → run again'),
  );

  static const _TutorTopic general = _TutorTopic(
    idea: _Bi(
      'Bài học đi từng bước nhỏ: hiểu đề, viết code, chạy thử, rồi xem kết quả chạy thật để kiểm chứng.',
      'A lesson goes in small steps: read the task, write code, run it, then check the real run result.',
    ),
    example: _Bi('print("Thử một dòng trước đã")', 'print("Try one line first")'),
    experiment: _Bi(
      'chạy thử một dòng đơn giản trước khi viết cả bài.',
      'run one simple line before writing the whole answer.',
    ),
    commonMistake: _Bi('viết cả đoạn dài rồi mới chạy.', 'writing a long block before running anything.'),
    challenge: _Bi(
      'tự nghĩ một câu hỏi mới về đoạn code này.',
      'invent a new question about this code.',
    ),
    shape: _Bi('một bước nhỏ mỗi lần', 'one small step at a time'),
  );
}
