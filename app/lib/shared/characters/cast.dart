import 'characters.dart';

/// Which family a cast member belongs to. Used by the roster UI and by the
/// tutor when it picks a tone for an answer.
enum CastScope {
  human('Người', 'Human'),
  animal('Bạn thú', 'Animal'),
  robot('Robot', 'Robot'),
  fantasy('Phép thuật', 'Fantasy');

  const CastScope(this.viLabel, this.enLabel);

  final String viLabel;
  final String enLabel;
}

/// A learning domain a cast member is responsible for. Kept small and mapped
/// from the real curriculum in `assets/data/main_quest_ch1.json`.
enum TutorTopic {
  basics('in ra màn hình và thứ tự lệnh', 'printing and the order of commands'),
  numbers('số và phép tính', 'numbers and arithmetic'),
  variables('biến và cách giá trị thay đổi', 'variables and how values change'),
  strings('ghép chuỗi', 'joining strings'),
  conditions('so sánh và điều kiện if', 'comparisons and if conditions'),
  loops('vòng lặp và sự kiên nhẫn', 'loops and patience'),
  functions('hàm và khối lệnh dùng lại được', 'functions and reusable blocks'),
  debugging('tìm nguyên nhân khi code lỗi', 'finding out why code fails'),
  logic('quy luật và tư duy thuật toán', 'patterns and algorithmic thinking'),
  creative('dự án sáng tạo của riêng bạn', 'your own creative projects'),
  quests('nhiệm vụ và phần thưởng', 'quests and rewards'),
  challenge('thử thách nâng cao', 'extra challenges');

  const TutorTopic(this.vi, this.en);

  final String vi;
  final String en;
}

/// One member of the cast: who they are, how they talk, what they teach and
/// the persona handed to the tutor when this character answers.
class CastMember {
  const CastMember({
    required this.id,
    required this.scope,
    required this.roleVi,
    required this.roleEn,
    required this.personalityVi,
    required this.personalityEn,
    required this.speakingStyleVi,
    required this.speakingStyleEn,
    required this.topics,
    this.unlockLessonId,
  });

  final CharacterId id;
  final CastScope scope;
  final String roleVi;
  final String roleEn;
  final String personalityVi;
  final String personalityEn;
  final String speakingStyleVi;
  final String speakingStyleEn;
  final List<TutorTopic> topics;

  /// When set, the character joins the roster after this lesson is completed.
  /// Core helpers (Nova, Thầy Py, Robo) are always available: nothing the
  /// learner needs for a lesson is ever locked away.
  final String? unlockLessonId;

  String get name => id.displayName;
  String get colourHex => '#${id.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

  /// English persona text for the tutor system prompt. Deliberately short:
  /// the lesson context carries the actual teaching content.
  String get promptPersona {
    final topic = topics.map((t) => t.en).join('; ');
    return '$name — $roleEn. Personality: $personalityEn. '
        'Speaking style: $speakingStyleEn. '
        'Leads: $topic. Stay in this character while answering.';
  }

  bool get alwaysAvailable => unlockLessonId == null;

  @override
  String toString() => 'CastMember(${id.name})';
}

/// The single place that knows the whole cast. Nothing else hardcodes a
/// character list, so adding a member or moving a topic happens here only.
abstract final class CastRegistry {
  static const CastMember robo = CastMember(
    id: CharacterId.robo,
    scope: CastScope.robot,
    roleVi: 'Robot nhỏ thích phiêu lưu',
    roleEn: 'A little robot who loves exploring',
    personalityVi: 'Háo hức, can đảm, luôn muốn thử ngay',
    personalityEn: 'Eager, brave, always ready to try',
    speakingStyleVi: 'Câu ngắn, hay rủ rê "chạm vào mình thử nhé!"',
    speakingStyleEn: 'Short sentences, invites you to try things',
    topics: [TutorTopic.basics, TutorTopic.quests],
  );

  static const CastMember pip = CastMember(
    id: CharacterId.pip,
    scope: CastScope.fantasy,
    roleVi: 'Chú rồng con mê sưu tầm xu',
    roleEn: 'A young dragon who collects coins',
    personalityVi: 'Vui vẻ, thích đùa, mê kho báu',
    personalityEn: 'Cheerful, playful, treasure-mad',
    speakingStyleVi: 'Hay so sánh bài học với việc nhặt xu',
    speakingStyleEn: 'Compares everything to collecting coins',
    topics: [TutorTopic.quests, TutorTopic.basics],
  );

  static const CastMember bitsy = CastMember(
    id: CharacterId.bitsy,
    scope: CastScope.animal,
    roleVi: 'Cô mèo thám tử săn lỗi',
    roleEn: 'A cat detective who hunts bugs',
    personalityVi: 'Tinh ý, thích đặt câu hỏi, không bỏ cuộc',
    personalityEn: 'Sharp-eyed, asks questions, never gives up',
    speakingStyleVi: 'Nói như đang điều tra: "Manh mối nằm ở đây này…"',
    speakingStyleEn: 'Talks like an investigation: "Here is the clue…"',
    topics: [TutorTopic.debugging, TutorTopic.logic],
  );

  static const CastMember py = CastMember(
    id: CharacterId.py,
    scope: CastScope.animal,
    roleVi: 'Người thầy ở Tháp Python',
    roleEn: 'The teacher of the Python Tower',
    personalityVi: 'Ấm áp, kiên nhẫn, thích kể chuyện code',
    personalityEn: 'Warm, patient, tells stories about code',
    speakingStyleVi: 'Giải thích chậm rãi, luôn kết bằng một câu động viên',
    speakingStyleEn: 'Explains slowly, ends with encouragement',
    topics: [TutorTopic.basics, TutorTopic.functions, TutorTopic.conditions],
  );

  static const CastMember nova = CastMember(
    id: CharacterId.nova,
    scope: CastScope.human,
    roleVi: 'Bạn đồng hành tò mò, thích sáng chế',
    roleEn: 'Curious inventor, your main companion',
    personalityVi: 'Năng lượng cao, thích thử nghiệm, hay reo lên khi hiểu ra',
    personalityEn: 'High energy, loves experimenting, celebrates discoveries',
    speakingStyleVi: 'Gọi bạn là "bạn", hay hỏi "cùng thử nhé?"',
    speakingStyleEn: 'Talks to you as a partner, asks "shall we try?"',
    topics: [TutorTopic.basics, TutorTopic.strings, TutorTopic.creative],
  );

  static const CastMember ada = CastMember(
    id: CharacterId.ada,
    scope: CastScope.human,
    roleVi: 'Giáo sư dạy điều kiện, hàm và giải thích sâu',
    roleEn: 'Professor of conditions, functions and deep explanations',
    personalityVi: 'Điềm tĩnh, chính xác, thích dùng ví dụ đời thường',
    personalityEn: 'Calm, precise, uses everyday analogies',
    speakingStyleVi: 'Nói rõ từng bước, không bỏ qua bước khó',
    speakingStyleEn: 'Clear step by step, never skips the hard part',
    topics: [TutorTopic.functions, TutorTopic.conditions, TutorTopic.challenge],
  );

  static const CastMember kai = CastMember(
    id: CharacterId.kai,
    scope: CastScope.human,
    roleVi: 'Cậu bạn mê thử thách và gỡ rối',
    roleEn: 'A friend who loves challenges and untangling puzzles',
    personalityVi: 'Tinh nghịch, thích thử cách khác khi cách cũ bí',
    personalityEn: 'Playful, tries another way when stuck',
    speakingStyleVi: 'Hay rủ "thử xem sao!", nói chuyện như thi đấu nhẹ nhàng',
    speakingStyleEn: 'Says "let us give it a go!", turns work into a friendly game',
    topics: [TutorTopic.challenge, TutorTopic.creative, TutorTopic.numbers],
    unlockLessonId: 'mq1_03',
  );

  static const CastMember byte = CastMember(
    id: CharacterId.byte,
    scope: CastScope.animal,
    roleVi: 'Cáo cam truy tìm nguyên nhân lỗi',
    roleEn: 'An orange fox who hunts down why code fails',
    personalityVi: 'Tò mò, thích truy vết, không phán xét khi bạn sai',
    personalityEn: 'Inquisitive, traces causes, never judges a mistake',
    speakingStyleVi: 'Kể lại quá trình điều tra, đưa ra 2–3 khả năng rồi mới kết luận',
    speakingStyleEn: 'Recaps the investigation, offers 2–3 suspects before concluding',
    topics: [TutorTopic.debugging, TutorTopic.logic],
  );

  static const CastMember pixel = CastMember(
    id: CharacterId.pixel,
    scope: CastScope.animal,
    roleVi: 'Cú xanh nhỏ giảng điều kiện và quy luật',
    roleEn: 'A small blue owl who explains conditions and patterns',
    personalityVi: 'Quan sát kỹ, thích hỏi "điều này đúng hay sai?"',
    personalityEn: 'Observant, always asks "is this true or false?"',
    speakingStyleVi: 'Chia mọi thứ thành đúng/sai, bảng nhỏ, quy luật',
    speakingStyleEn: 'Breaks things into true/false, little tables, patterns',
    topics: [TutorTopic.conditions, TutorTopic.logic, TutorTopic.numbers],
    // Pixel teaches numbers (lesson 3) as well as comparisons (lesson 7), so it
    // joins at the numbers lesson: no lesson may route to an absent helper.
    unlockLessonId: 'mq1_03',
  );

  static const CastMember loop = CastMember(
    id: CharacterId.loop,
    scope: CastScope.animal,
    roleVi: 'Rùa xanh kiên nhẫn dạy vòng lặp',
    roleEn: 'A patient green turtle who teaches loops',
    personalityVi: 'Chậm rãi, kiên nhẫn, thích đếm và lặp lại',
    personalityEn: 'Slow, patient, loves counting and repeating',
    speakingStyleVi: 'Nói về lần lặp thứ nhất, thứ hai… và lúc nào thì dừng',
    speakingStyleEn: 'Talks about round one, round two… and when to stop',
    topics: [TutorTopic.loops, TutorTopic.logic],
    unlockLessonId: 'mq1_08',
  );

  static const CastMember bit = CastMember(
    id: CharacterId.bit,
    scope: CastScope.robot,
    roleVi: 'Robot nhỏ minh hoạ biến và hàm',
    roleEn: 'A compact robot who demonstrates variables and functions',
    personalityVi: 'Chính xác, thích đóng vai chiếc hộp đựng giá trị',
    personalityEn: 'Precise, likes acting as the box that holds a value',
    speakingStyleVi: 'Hiện "ngăn kéo" và giá trị bên trong bằng lời ngắn gọn',
    speakingStyleEn: 'Shows the "drawer" and the value inside it, in short lines',
    topics: [TutorTopic.variables, TutorTopic.functions],
    unlockLessonId: 'mq1_04',
  );

  static const CastMember lumi = CastMember(
    id: CharacterId.lumi,
    scope: CastScope.fantasy,
    roleVi: 'Sinh vật rừng phép thuật trao nhiệm vụ',
    roleEn: 'A forest spirit who hands out quests and rewards',
    personalityVi: 'Dịu dàng, bí ẩn, thích trao thử thách vừa sức',
    personalityEn: 'Gentle, a little mysterious, hands out fitting challenges',
    speakingStyleVi: 'Nói như kể chuyện cổ tích, hay mời "đi theo mình nhé"',
    speakingStyleEn: 'Talks like a fairy tale, invites you to follow along',
    topics: [TutorTopic.quests, TutorTopic.creative, TutorTopic.challenge],
    unlockLessonId: 'mq1_10',
  );

  /// Original islanders first, then the learning companions.
  static const List<CastMember> members = [
    robo, pip, bitsy, py, nova, ada, kai, byte, pixel, loop, bit, lumi,
  ];

  static CastMember of(CharacterId id) =>
      members.firstWhere((m) => m.id == id, orElse: () => nova);

  /// The tutor for a Main Quest lesson, chosen by the lesson's own skill text.
  /// Falls back to Thầy Py (the tower's teacher) and never returns null, so a
  /// new lesson with a new skill still gets a tutor.
  static CastMember tutorForSkill(String skill) {
    final s = skill.toLowerCase();
    bool has(List<String> needles) => needles.any((n) => s.contains(n));
    if (has(['biến', 'variable'])) return bit;
    if (has(['so sánh', 'if', 'else', 'elif', 'điều kiện', 'bool'])) return pixel;
    if (has(['hàm', 'def', 'return', 'gọi hàm', 'function'])) return ada;
    if (has(['vòng lặp', 'loop', 'while', 'for '])) return loop;
    if (has(['tổng hợp', 'thử thách', 'challenge'])) return ada;
    if (has(['chuỗi', 'str', 'string', 'ghép'])) return nova;
    if (has(['số', 'phép tính', 'number', 'toán'])) return pixel;
    if (has(['in ra', 'print', 'thứ tự', 'lệnh'])) return nova;
    return py;
  }

  /// The tutor for a whole activity (mini-games have their own host).
  static CastMember tutorForSkillOrModule(String skill, {String? moduleId}) {
    switch (moduleId) {
      case 'robot_maze':
        return robo;
      case 'bug_hunter':
        return byte;
      case 'dragon_jump':
        return pip;
      case 'catch_stars':
        return pixel;
      case 'achievements':
        return lumi;
      default:
        return tutorForSkill(skill);
    }
  }

  /// Characters the learner has met so far (roster view).
  static List<CastMember> unlocked(Set<String> completedLessons) => [
        for (final m in members)
          if (m.alwaysAvailable || completedLessons.contains(m.unlockLessonId)) m,
      ];

  static List<CastMember> byScope(CastScope scope) =>
      [for (final m in members) if (m.scope == scope) m];

  /// The cast member whose domain best matches a topic (used by quick actions
  /// and by the offline tutor when it needs a voice).
  static CastMember tutorForTopic(TutorTopic topic) {
    for (final m in members) {
      if (m.topics.contains(topic)) return m;
    }
    return nova;
  }
}
