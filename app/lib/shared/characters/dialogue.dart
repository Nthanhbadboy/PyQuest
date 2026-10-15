import '../l10n/pq_l10n.dart';
import 'cast.dart';
import 'characters.dart';

/// Moments a character can speak in. Kept deliberately close to gameplay
/// events so the UI never has to invent copy inline.
enum DialogueMoment {
  /// First contact in a lesson or panel.
  greet,

  /// The learner just solved something.
  correct,

  /// The learner got it wrong — never shaming.
  wrong,

  /// The character is working on an answer.
  thinking,

  /// A milestone (lesson finished, chapter finished).
  celebrate,

  /// The learner seems lost: milder, curiosity-first tone.
  confused,

  /// A hint is offered.
  hint,

  /// An extra challenge is offered.
  challenge,

  /// The daily AI question allowance is used up.
  quotaEmpty,
}

/// Per-character voice for every moment, in both languages. Data only: the UI
/// and the tutor pick a line with [CastDialogue.line], which rotates through
/// the variants deterministically so a child does not read the same sentence
/// every time (and never a random line that contradicts the situation).
abstract final class CastDialogue {
  static String line(
    CharacterId id,
    DialogueMoment moment,
    PqLang lang, {
    int seed = 0,
  }) {
    final table = lang == PqLang.vi ? _vi : _en;
    final list = table[id]?[moment];
    if (list != null && list.isNotEmpty) {
      return list[seed.abs() % list.length];
    }
    final fallback = _fallback[lang == PqLang.vi ? 0 : 1][moment];
    if (fallback != null && fallback.isNotEmpty) {
      return fallback[seed.abs() % fallback.length];
    }
    return '';
  }

  /// All variants, for tests and for the roster screen.
  static List<String> variants(CharacterId id, DialogueMoment moment, PqLang lang) {
    final table = lang == PqLang.vi ? _vi : _en;
    return List.unmodifiable(table[id]?[moment] ?? const <String>[]);
  }

  /// A short line about the character's field, used on roster cards.
  static String topicLine(CastMember member, PqLang lang) {
    final topics = member.topics.take(2).map((t) => lang == PqLang.vi ? t.vi : t.en).toList();
    return topics.join(lang == PqLang.vi ? ' và ' : ' and ');
  }

  static const Map<String, Map<DialogueMoment, List<String>>> _fallback = {
    'vi': {
      DialogueMoment.greet: ['Mình ở đây cùng bạn nhé!'],
      DialogueMoment.correct: ['Chính xác!'],
      DialogueMoment.wrong: ['Chưa đúng rồi — thử lại cùng mình nhé.'],
      DialogueMoment.thinking: ['Mình đang nghĩ…'],
      DialogueMoment.celebrate: ['Bạn tiến bộ thật rồi!'],
      DialogueMoment.confused: ['Không sao đâu, mình đi chậm lại nhé.'],
      DialogueMoment.hint: ['Gợi ý nhỏ cho bạn nè…'],
      DialogueMoment.challenge: ['Sẵn sàng cho thử thách chứ?'],
      DialogueMoment.quotaEmpty: ['Hôm nay hết lượt hỏi AI rồi, nhưng mình vẫn học tiếp với bạn được!'],
    },
    'en': {
      DialogueMoment.greet: ['I am right here with you!'],
      DialogueMoment.correct: ['Exactly right!'],
      DialogueMoment.wrong: ['Not quite yet — let us try again together.'],
      DialogueMoment.thinking: ['I am thinking…'],
      DialogueMoment.celebrate: ['You really are improving!'],
      DialogueMoment.confused: ['That is all right, let us slow down.'],
      DialogueMoment.hint: ['Here is a small hint…'],
      DialogueMoment.challenge: ['Are you ready for a challenge?'],
      DialogueMoment.quotaEmpty: ['Today’s AI questions are used up, but we can keep learning together!'],
    },
  };

  static const Map<CharacterId, Map<DialogueMoment, List<String>>> _vi = {
    CharacterId.nova: {
      DialogueMoment.greet: [
        'Chào bạn! Mình là Nova. Cùng mở bài này ra và thử một lệnh nhỏ nhé?',
        'Bạn tới rồi! Mình vừa nghĩ ra một cách thử code rất vui, làm luôn không?',
      ],
      DialogueMoment.correct: [
        'Tuyệt! Bạn vừa làm đúng điều mình nghĩ tới luôn đó!',
        'Chuẩn luôn! Ghi lại vào nhật ký sáng chế nào!',
      ],
      DialogueMoment.wrong: ['Chưa đúng cũng không sao — thử đổi một chỗ rồi xem máy in ra gì nhé.'],
      DialogueMoment.thinking: ['Để mình ghép các mảnh lại xem sao…'],
      DialogueMoment.celebrate: ['Bạn làm được rồi! Mình phải ghi lại phát minh này!'],
      DialogueMoment.confused: ['Hơi rối rồi hả? Mình bắt đầu từ chỗ bạn chắc chắn nhất nhé.'],
      DialogueMoment.hint: ['Mình gợi ý một chút thôi, phần còn lại để bạn khám phá nhé!'],
      DialogueMoment.challenge: ['Thử thêm một biến thể của bài này xem bạn làm được tới đâu!'],
      DialogueMoment.quotaEmpty: ['Hết lượt hỏi AI hôm nay rồi. Mình vẫn ở đây giúp bạn theo cách khác!'],
    },
    CharacterId.ada: {
      DialogueMoment.greet: [
        'Chào cháu. Hãy đọc đoạn code trước, rồi cô trò mình bàn từng bước một.',
        'Cô đã xem bài này rồi. Có một chỗ rất đáng để hiểu cho thật kỹ — bắt đầu nhé.',
      ],
      DialogueMoment.correct: [
        'Chính xác. Cháu hiểu đúng bản chất rồi đấy.',
        'Đúng rồi. Cách cháu lập luận mới là điều đáng giữ lại.',
      ],
      DialogueMoment.wrong: ['Chưa đúng, nhưng sai ở đây rất hữu ích: nó cho thấy cháu đang hiểu lệch ở một bước.'],
      DialogueMoment.thinking: ['Cô đang kiểm tra lại từng bước lập luận…'],
      DialogueMoment.celebrate: ['Một mốc đáng nhớ. Kiến thức này sẽ theo cháu suốt chặng đường.'],
      DialogueMoment.confused: ['Không sao. Khi khái niệm còn mờ, cách tốt nhất là ví dụ nhỏ nhất có thể.'],
      DialogueMoment.hint: ['Đây là một bước đệm, không phải lời giải. Cháu đi tiếp một mình được chứ?'],
      DialogueMoment.challenge: ['Thử thách này khó hơn một chút, nhưng cháu đã có đủ công cụ.'],
      DialogueMoment.quotaEmpty: ['Hôm nay cháu đã dùng hết lượt hỏi. Cô vẫn để lại gợi ý trong bài cho cháu.'],
    },
    CharacterId.kai: {
      DialogueMoment.greet: [
        'Ê, vào rồi à? Bài này mình chơi thử thấy vui lắm!',
        'Cùng thử nhé! Mình cá là bạn làm xong trước mình đó.',
      ],
      DialogueMoment.correct: [
        'Nhanh ghê! Chạy đúng luôn rồi!',
        'Được đó! Thử đổi số xem có vẫn đúng không?',
      ],
      DialogueMoment.wrong: ['Hụt rồi, nhưng vui mà! Sửa một chỗ rồi chạy lại xem.'],
      DialogueMoment.thinking: ['Mình đang nghĩ ra cách khác cho vui…'],
      DialogueMoment.celebrate: ['Xong bài! Làm thêm một ván nữa không?'],
      DialogueMoment.confused: ['Hơi khó thật! Mình chia nhỏ ra, làm từng chút một nha.'],
      DialogueMoment.hint: ['Chỉ gợi ý thôi, không nói đáp án đâu — thử đi!'],
      DialogueMoment.challenge: ['Đây là bản khó hơn nè, dám không?'],
      DialogueMoment.quotaEmpty: ['Hết lượt hỏi AI rồi, nhưng mình vẫn chơi cùng bạn được mà!'],
    },
    CharacterId.byte: {
      DialogueMoment.greet: [
        'Ha! Có dấu vết ở đây này. Đưa mình xem đoạn code bạn viết nhé?',
        'Mình vừa ngửi thấy một chỗ đáng ngờ trong chương trình của bạn đó.',
      ],
      DialogueMoment.correct: [
        'Đúng rồi. Không còn dấu vết lỗi nào nữa — vụ này khép lại!',
        'Chính xác! Manh mối cuối cùng đã khớp.',
      ],
      DialogueMoment.wrong: ['Chưa khớp chứng cứ. Mình thử lại từ dấu vết đầu tiên nhé.'],
      DialogueMoment.thinking: ['Đang lần theo dấu vết… có ba khả năng.'],
      DialogueMoment.celebrate: ['Phá án thành công! Bản báo cáo này ghi tên bạn nhé.'],
      DialogueMoment.confused: ['Lạc dấu rồi hả? Mình bắt đầu lại từ chỗ chắc chắn đã đúng.'],
      DialogueMoment.hint: ['Mình đưa một manh mối nhỏ, phần lần theo để bạn tự làm nhé.'],
      DialogueMoment.challenge: ['Vụ khó hơn đang chờ đây — có một lỗi ẩn chưa ai tìm ra.'],
      DialogueMoment.quotaEmpty: ['Hết lượt hỏi AI hôm nay. Mình vẫn để lại danh sách dấu vết cho bạn trong bài.'],
    },
    CharacterId.pixel: {
      DialogueMoment.greet: [
        'Trước khi viết code, mình hỏi một câu nhé: điều kiện này đúng hay sai?',
        'Mình thích câu hỏi kiểu này lắm. Ta xét từng trường hợp một nhé!',
      ],
      DialogueMoment.correct: [
        'Chính xác: trường hợp thứ nhất đúng, thứ hai sai — bạn phân tích rất tốt.',
        'Đúng rồi! Quy luật bạn tìm ra hoàn toàn khớp.',
      ],
      DialogueMoment.wrong: ['Chưa đúng. Thử tách ra: giá trị nào đang lớn hơn giá trị nào?'],
      DialogueMoment.thinking: ['Mình đang xét các trường hợp có thể xảy ra…'],
      DialogueMoment.celebrate: ['Bạn đã nắm được cách máy quyết định đúng/sai rồi!'],
      DialogueMoment.confused: ['Hơi nhiều trường hợp nhỉ? Mình gom lại thành hai nhóm cho dễ nhìn.'],
      DialogueMoment.hint: ['Gợi ý: chỉ cần quan tâm một phép so sánh ở dòng này thôi.'],
      DialogueMoment.challenge: ['Thử xét một trường hợp nữa xem quy luật có còn đúng không nhé!'],
      DialogueMoment.quotaEmpty: ['Hết lượt hỏi AI rồi. Bảng đúng/sai trong bài vẫn giúp bạn đi tiếp được.'],
    },
    CharacterId.loop: {
      DialogueMoment.greet: [
        'Chậm thôi nhé. Mình cùng đếm xem chương trình lặp mấy lần.',
        'Vòng lặp giống bước đi của mình: từng bước một, rồi tới nơi.',
      ],
      DialogueMoment.correct: [
        'Đúng rồi. Lần một, lần hai… và bạn đã biết lúc nào nó dừng.',
        'Chuẩn đấy! Vòng lặp chạy đúng số lần cần thiết.',
      ],
      DialogueMoment.wrong: ['Chưa đúng. Hỏi nhỏ nhé: sau mỗi lần lặp, giá trị nào đã thay đổi?'],
      DialogueMoment.thinking: ['Mình đang đếm… lần thứ nhất, lần thứ hai…'],
      DialogueMoment.celebrate: ['Bạn hiểu vòng lặp rồi! Đi đâu xa cũng tới, miễn đúng bước.'],
      DialogueMoment.confused: ['Không sao, kiên nhẫn là chuyện của mình mà. Đếm lại từ đầu nhé.'],
      DialogueMoment.hint: ['Gợi ý: điều kiện dừng phải đổi giá trị, không thì đi mãi không tới.'],
      DialogueMoment.challenge: ['Thử lặp lại với số lần khác xem chương trình có đúng không.'],
      DialogueMoment.quotaEmpty: ['Hết lượt hỏi AI hôm nay. Mình vẫn ở đây, chậm mà chắc.'],
    },
    CharacterId.bit: {
      DialogueMoment.greet: [
        'MÌNH LÀ BIT. Mình giữ giá trị trong ngăn kéo — mở ra xem cùng nhé?',
        'Bạn muốn biết ngăn kéo nào đang giữ số mấy không? Kiểm tra cùng mình!',
      ],
      DialogueMoment.correct: [
        'Đúng. Ngăn kéo giữ đúng giá trị bạn nói rồi.',
        'Chính xác! Giá trị đã được cất đúng chỗ.',
      ],
      DialogueMoment.wrong: ['Chưa đúng. Ngăn kéo này đang giữ giá trị khác cơ.'],
      DialogueMoment.thinking: ['Đang mở ngăn kéo và kiểm tra giá trị…'],
      DialogueMoment.celebrate: ['Bạn hiểu biến rồi! Ngăn kéo luôn nhớ giúp bạn.'],
      DialogueMoment.confused: ['Hơi lẫn ngăn kéo phải không? Mình dán nhãn lại từng cái nhé.'],
      DialogueMoment.hint: ['Gợi ý: chỗ nào giá trị thay đổi thì mình ghi rõ tên biến bên cạnh.'],
      DialogueMoment.challenge: ['Thử thêm một ngăn kéo nữa và xem chương trình có nhớ đúng không.'],
      DialogueMoment.quotaEmpty: ['Hết lượt hỏi AI hôm nay. Ngăn kéo trong bài vẫn giữ giá trị cho bạn.'],
    },
    CharacterId.lumi: {
      DialogueMoment.greet: [
        'Bạn đến đúng lúc lắm. Mình có một nhiệm vụ nhỏ dành cho bạn.',
        'Ngọn đèn trong rừng sáng lên khi bạn bắt đầu. Cùng đi nhé?',
      ],
      DialogueMoment.correct: [
        'Ánh sáng vừa mạnh hơn một chút — đó là dấu hiệu bạn làm đúng.',
        'Tốt lắm. Khu rừng ghi nhận điều bạn vừa làm.',
      ],
      DialogueMoment.wrong: ['Chưa phải lần này. Không sao, đường rừng luôn có lối khác.'],
      DialogueMoment.thinking: ['Mình đang lắng nghe khu rừng…'],
      DialogueMoment.celebrate: ['Nhiệm vụ hoàn thành! Phần thưởng nhỏ đang về với bạn.'],
      DialogueMoment.confused: ['Đường hơi mờ nhỉ? Mình thắp thêm một ngọn đèn cho bạn.'],
      DialogueMoment.hint: ['Mình đưa một dấu chỉ nhỏ, còn lại là phần phiêu lưu của bạn.'],
      DialogueMoment.challenge: ['Có một nhiệm vụ khó hơn, dành cho người đã sẵn sàng.'],
      DialogueMoment.quotaEmpty: ['Hôm nay hết lượt hỏi AI. Nhưng khu rừng vẫn mở cửa cho bạn học tiếp.'],
    },
    CharacterId.py: {
      DialogueMoment.greet: ['Chào bạn nhỏ! Thầy ở đây, mình học từng dòng một nhé.'],
      DialogueMoment.correct: ['Đúng rồi! Thầy rất vui vì bạn tự nghĩ ra.'],
      DialogueMoment.wrong: ['Chưa đúng không sao. Thầy chỉ tay vào chỗ cần xem lại nhé.'],
      DialogueMoment.thinking: ['Thầy đang đọc lại đoạn code của bạn…'],
      DialogueMoment.celebrate: ['Một bài nữa hoàn thành — tháp Python cao thêm một tầng!'],
      DialogueMoment.confused: ['Rối chỗ nào, nói thầy nghe. Ta gỡ từng nút nhé.'],
      DialogueMoment.hint: ['Thầy gợi ý nhẹ thôi, phần còn lại là của bạn.'],
      DialogueMoment.challenge: ['Thử thách cuối chặng đây, bạn sẵn sàng chưa?'],
      DialogueMoment.quotaEmpty: ['Hôm nay hết lượt hỏi AI rồi. Thầy vẫn ở Tháp, mình học tiếp nhé!'],
    },
    CharacterId.robo: {
      DialogueMoment.greet: ['Vào đi! Mình dẫn bạn qua mê cung nhé.'],
      DialogueMoment.correct: ['Tới đích rồi! Tuyệt quá!'],
      DialogueMoment.wrong: ['Ơ, mình đụng tường rồi. Đổi lệnh khác xem!'],
      DialogueMoment.celebrate: ['Bạn mở đường giỏi thật đấy!'],
      DialogueMoment.thinking: ['Mình đang tính đường đi…'],
    },
    CharacterId.pip: {
      DialogueMoment.greet: ['Nhặt xu cùng mình nhé!'],
      DialogueMoment.correct: ['Nhiều xu quá! Giỏi thật!'],
      DialogueMoment.wrong: ['Úi, hụt một chút rồi. Làm lại nhé!'],
      DialogueMoment.celebrate: ['Kho báu đầy lên rồi!'],
    },
    CharacterId.bitsy: {
      DialogueMoment.greet: ['Có vụ mới đây. Cùng điều tra không?'],
      DialogueMoment.correct: ['Đúng rồi, lỗi đã bị tóm!'],
      DialogueMoment.wrong: ['Manh mối chưa khớp, thử lại nhé.'],
      DialogueMoment.celebrate: ['Hồ sơ vụ án khép lại!'],
    },
  };

  static const Map<CharacterId, Map<DialogueMoment, List<String>>> _en = {
    CharacterId.nova: {
      DialogueMoment.greet: [
        'Hi! I am Nova. Shall we open this lesson and try one small command?',
        'You made it! I just thought of a fun way to test the code — want to try it?',
      ],
      DialogueMoment.correct: ['Amazing! You did exactly what I was hoping!', 'Spot on! I am writing this in my invention notebook!'],
      DialogueMoment.wrong: ['Not right yet — no problem, change one thing and see what the computer prints.'],
      DialogueMoment.thinking: ['Let me put the pieces together…'],
      DialogueMoment.celebrate: ['You did it! I have to write this invention down!'],
      DialogueMoment.confused: ['Feeling tangled? Let us start from the part you are sure about.'],
      DialogueMoment.hint: ['Just a tiny hint — the rest is yours to discover!'],
      DialogueMoment.challenge: ['Try a twist on this lesson and see how far you get!'],
      DialogueMoment.quotaEmpty: ['Today’s AI questions are done. I can still help you another way!'],
    },
    CharacterId.ada: {
      DialogueMoment.greet: ['Hello. Read the code first, then we will go step by step.'],
      DialogueMoment.correct: ['Correct. You understand the underlying idea now.'],
      DialogueMoment.wrong: ['Not yet — but this mistake is useful: it shows which step is misunderstood.'],
      DialogueMoment.thinking: ['Let me re-check each step of the reasoning…'],
      DialogueMoment.celebrate: ['A milestone worth remembering. This knowledge stays with you.'],
      DialogueMoment.confused: ['That is all right. When a concept is fuzzy, we use the smallest possible example.'],
      DialogueMoment.hint: ['This is a stepping stone, not the solution. Can you continue alone?'],
      DialogueMoment.challenge: ['This challenge is harder, but you already have the tools.'],
      DialogueMoment.quotaEmpty: ['Your questions for today are used up. I have left hints in the lesson for you.'],
    },
    CharacterId.kai: {
      DialogueMoment.greet: ['Oh, you are in? I tried this one already — it is fun!'],
      DialogueMoment.correct: ['So fast! It runs correctly already!'],
      DialogueMoment.wrong: ['Missed it — but that was fun! Fix one spot and run again.'],
      DialogueMoment.thinking: ['Thinking of another way to do it…'],
      DialogueMoment.celebrate: ['Lesson done! Another round?'],
      DialogueMoment.confused: ['This is tricky! Let us chop it into small bits.'],
      DialogueMoment.hint: ['Only a hint, no answers — go on, try it!'],
      DialogueMoment.challenge: ['Here is the harder version. Dare you?'],
      DialogueMoment.quotaEmpty: ['AI questions are used up, but we can still play!'],
    },
    CharacterId.byte: {
      DialogueMoment.greet: ['Ha! There are traces here. May I see the code you wrote?'],
      DialogueMoment.correct: ['Right. No traces left — this case is closed!'],
      DialogueMoment.wrong: ['The evidence does not match yet. Let us restart from the first trace.'],
      DialogueMoment.thinking: ['Following the trail… three suspects.'],
      DialogueMoment.celebrate: ['Case solved! This report will carry your name.'],
      DialogueMoment.confused: ['Lost the trail? Let us restart from what we know is correct.'],
      DialogueMoment.hint: ['One small clue from me; you do the tracking.'],
      DialogueMoment.challenge: ['A harder case is waiting — with a hidden mistake nobody found yet.'],
      DialogueMoment.quotaEmpty: ['No AI questions left today. I left the list of clues in the lesson.'],
    },
    CharacterId.pixel: {
      DialogueMoment.greet: ['Before we write code: is this condition true or false?'],
      DialogueMoment.correct: ['Exactly: the first case is true, the second false — well analysed.'],
      DialogueMoment.wrong: ['Not yet. Split it up: which value is larger than which?'],
      DialogueMoment.thinking: ['Checking every possible case…'],
      DialogueMoment.celebrate: ['You now know how the computer decides true or false!'],
      DialogueMoment.confused: ['Many cases? Let us group them into two piles.'],
      DialogueMoment.hint: ['Hint: only one comparison on this line matters.'],
      DialogueMoment.challenge: ['Check one more case and see whether the pattern still holds!'],
      DialogueMoment.quotaEmpty: ['No AI questions left. The true/false table in the lesson still guides you.'],
    },
    CharacterId.loop: {
      DialogueMoment.greet: ['Slowly now. Let us count how many times the program repeats.'],
      DialogueMoment.correct: ['Correct. Round one, round two… and you knew when to stop.'],
      DialogueMoment.wrong: ['Not yet. Small question: after each round, which value changed?'],
      DialogueMoment.thinking: ['Counting… round one, round two…'],
      DialogueMoment.celebrate: ['You understand loops now! Steady steps always arrive.'],
      DialogueMoment.confused: ['That is fine — patience is my speciality. Let us count again.'],
      DialogueMoment.hint: ['Hint: the loop must change something, or it never arrives.'],
      DialogueMoment.challenge: ['Try repeating a different number of times and check the program.'],
      DialogueMoment.quotaEmpty: ['No AI questions left today. I am still here, slow and steady.'],
    },
    CharacterId.bit: {
      DialogueMoment.greet: ['I AM BIT. I keep values in drawers — shall we open one?'],
      DialogueMoment.correct: ['Correct. This drawer holds exactly the value you said.'],
      DialogueMoment.wrong: ['Not yet. This drawer is holding a different value.'],
      DialogueMoment.thinking: ['Opening the drawer and checking the value…'],
      DialogueMoment.celebrate: ['You understand variables! The drawer always remembers for you.'],
      DialogueMoment.confused: ['Mixed up the drawers? Let us label each one again.'],
      DialogueMoment.hint: ['Hint: wherever the value changes, the variable name is written beside it.'],
      DialogueMoment.challenge: ['Add one more drawer and see whether the program still remembers.'],
      DialogueMoment.quotaEmpty: ['No AI questions left today. The drawers in the lesson still hold your values.'],
    },
    CharacterId.lumi: {
      DialogueMoment.greet: ['You arrived at the right moment. I have a small quest for you.'],
      DialogueMoment.correct: ['The light grew a little brighter — that is the sign you are right.'],
      DialogueMoment.wrong: ['Not this time. Forest paths always have another way.'],
      DialogueMoment.thinking: ['Listening to the forest…'],
      DialogueMoment.celebrate: ['Quest complete! A small reward is on its way.'],
      DialogueMoment.confused: ['The path is dim? Let me light one more lantern for you.'],
      DialogueMoment.hint: ['A small sign from me; the adventure stays yours.'],
      DialogueMoment.challenge: ['A harder quest, for someone who is ready.'],
      DialogueMoment.quotaEmpty: ['No AI questions left today. The forest still keeps its doors open for learning.'],
    },
    CharacterId.py: {
      DialogueMoment.greet: ['Hello, young coder! I am here; let us go line by line.'],
      DialogueMoment.correct: ['Correct! I am glad you worked it out yourself.'],
      DialogueMoment.wrong: ['Not yet, and that is fine. Let me point at the line to revisit.'],
      DialogueMoment.celebrate: ['Another lesson done — the Python Tower grows one floor taller!'],
      DialogueMoment.hint: ['A gentle hint from me; the rest is yours.'],
      DialogueMoment.quotaEmpty: ['No AI questions left today. I am still in the Tower — let us keep going!'],
    },
    CharacterId.robo: {
      DialogueMoment.greet: ['Come in! I will show you through the maze.'],
      DialogueMoment.correct: ['We reached the goal! Wonderful!'],
      DialogueMoment.wrong: ['Oops, I hit a wall. Try another command!'],
      DialogueMoment.celebrate: ['You are really good at opening paths!'],
    },
    CharacterId.pip: {
      DialogueMoment.greet: ['Let us collect coins together!'],
      DialogueMoment.correct: ['So many coins! Well done!'],
      DialogueMoment.wrong: ['Almost! One more try!'],
      DialogueMoment.celebrate: ['The treasure pile is growing!'],
    },
    CharacterId.bitsy: {
      DialogueMoment.greet: ['A new case. Shall we investigate?'],
      DialogueMoment.correct: ['Right — the bug is caught!'],
      DialogueMoment.wrong: ['The clues do not match yet. Try again.'],
      DialogueMoment.celebrate: ['Case closed!'],
    },
  };
}
