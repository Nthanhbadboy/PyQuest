/// Mô hình miền của **bảng giảng Tutor** (PQC-010, PQD-003 rev 4 + rev 6).
///
/// Phạm vi của gói này — nói thẳng để không ai đọc vượt:
///  * plan **chỉ do authored fixture** sinh ra; chưa nối `LessonScreen`, provider,
///    relay, AI hay voice (đó là `PQC-011/012/013`, chưa được giao);
///  * renderer **chỉ hiển thị**: không có callback nào ghi score/quota/energy/reward,
///    không chạy code, không đọc URL/markup;
///  * token envelope (`sessionId` + `contextRevision` + `turnId` + `locale`) là guard
///    **trong biên của board**, không phải bằng chứng `TutorSession` đã được nối.
///
/// Hợp đồng lấy từ `docs/design/coordination/reviews/PQD-003-r4.md` §D5 +
/// `docs/implementation/coordination/tasks/PQD-003.md` §M (rev 4 overrides các mục cũ).
library;

/// Nguồn của một plan. Do **app** ghi, model không được tự khai (rev 4 §D5.4).
enum BoardPlanSource {
  /// Viết tay trong repo, có provenance. Slice đầu chỉ có nguồn này.
  authored,

  /// Bản authored được dùng làm fallback khi AI lỗi — vẫn là chữ do app dán nhãn.
  authoredFallback,
}

/// Ba layer có quyền khác nhau. Plan **không** có quyền chạm layer của trẻ.
enum BoardLayerKind {
  /// Khung bài học: tiêu đề, số bước — thuộc lesson, board không tự sửa.
  scaffold,

  /// Lớp của Tutor: mọi op của plan đều rơi vào đây, và chỉ đây.
  tutor,

  /// Lớp của trẻ: nét + ghi chú. Tutor không xóa, không ghi.
  learner,
}

/// Op được phép, đúng allowlist rev 4 §D5. Không có op nào khác; `unknown` tồn tại
/// chỉ để codec ghi nhận "plan gửi loại op không có trong hợp đồng" thay vì ném lỗi.
enum BoardOpKind {
  text('text'),
  codeSnippet('codeSnippet'),
  highlightToken('highlightToken'),
  highlightLine('highlightLine'),
  simpleShape('simpleShape'),
  connector('connector'),
  tokenGroup('tokenGroup'),
  output('output'),
  clearTutorLayer('clearTutorLayer'),
  unknown('unknown');

  const BoardOpKind(this.wire);

  /// Tên khóa trong JSON.
  final String wire;

  static BoardOpKind? fromWire(String value) {
    for (final BoardOpKind kind in BoardOpKind.values) {
      if (kind.wire == value) return kind;
    }
    return null;
  }
}

/// Trần ngân sách. Con số đến từ rev 4 §D5 (1..12 beats, ≤8 ops, ≤600 **code point**,
/// tokenGroup ≤12) — phần payload/geometry là của §PQC-010.1 để không một op nào
/// xin được payload tùy ý.
abstract final class BoardLimits {
  static const int minBeats = 1;
  static const int maxBeats = 12;
  static const int maxOpsPerBeat = 8;

  /// Tính bằng **Unicode code point** (`String.runes`), không phải `length`: tiếng Việt
  /// có dấu là tổ hợp nhiều code point/UTF-16 unit.
  static const int maxCopyField = 600;
  static const int maxOpText = 600;
  static const int maxCodeLines = 24;
  static const int maxCodeChars = 1200;
  static const int maxTokensPerGroup = 12;
  static const int maxTokenGroups = 4;
  static const int maxShapes = 8;
  static const int maxConnectors = 8;
  static const int maxIdLength = 40;

  /// Cả tài liệu plan: một payload khổng lồ phải bị từ chối **trước** khi parse sâu.
  static const int maxDocumentChars = 32 * 1024;

  /// Hình học: tọa độ chuẩn hóa 0..1, bán kính/độ dày trong (0..1].
  static const double maxGeometry = 1.0;
}

/// Nhãn hiển thị cho một beat, theo một locale.
class BoardBeatCopy {
  const BoardBeatCopy({
    required this.title,
    required this.say,
    required this.caption,
    required this.altText,
  });

  final String title;
  final String say;
  final String caption;

  /// Bắt buộc: beat không có mô tả thì plan bị reject (rev 4 §D4).
  final String altText;
}

/// Phạm vi của một output được minh họa. Rev 4 §D5 đòi hỏi rõ: `print(3 + 4)` in ra `7`
/// là **dòng đầu**, không phải output của cả hai lệnh.
enum BoardOutputScope {
  /// Output chỉ của `sourceStatement`.
  singleStatement('singleStatement'),

  /// Output của toàn bộ đoạn code ví dụ, theo đúng thứ tự dòng.
  wholeRun('wholeRun');

  const BoardOutputScope(this.wire);

  final String wire;

  static BoardOutputScope? fromWire(String value) {
    for (final BoardOutputScope scope in BoardOutputScope.values) {
      if (scope.wire == value) return scope;
    }
    return null;
  }
}

/// Một thao tác trên bảng.
class BoardOp {
  const BoardOp({
    required this.kind,
    required this.altText,
    this.text = '',
    this.statement = '',
    this.objectId,
    this.fromId,
    this.toId,
    this.tokenIds = const <String>[],
    this.shape = '',
    this.value = '',
    this.x = 0,
    this.y = 0,
    this.width = 0,
    this.height = 0,
    this.line = 1,
  });

  final BoardOpKind kind;

  /// Mỗi op phải tự mô tả được — op không có mô tả thì plan bị reject.
  final String altText;

  final String text;

  /// Câu lệnh/source mà op bám vào (highlight, output) — để đối chiếu deterministic.
  final String statement;
  final String? objectId;
  final String? fromId;
  final String? toId;
  final List<String> tokenIds;
  final String shape;
  final String value;

  /// Hình học chuẩn hóa 0..1.
  final double x;
  final double y;
  final double width;
  final double height;
  final int line;
}

/// Một beat: một ý ngắn + các thao tác bảng + có chờ người học hay không.
class BoardBeat {
  const BoardBeat({
    required this.beatId,
    required this.copy,
    required this.ops,
    this.waitForLearner = false,
    this.sourceStatement,
    this.outputScope = BoardOutputScope.singleStatement,
    this.objectIds = const <String>[],
  });

  final String beatId;

  /// `locale -> copy`. Locale lạ **không** được âm thầm rơi vào một nhánh "khác là en"
  /// ở tầng này: resolver quyết, board chỉ tra.
  final Map<String, BoardBeatCopy> copy;
  final List<BoardOp> ops;
  final bool waitForLearner;

  /// Statement mà beat minh họa (để validator đối chiếu với reference deterministic).
  final String? sourceStatement;
  final BoardOutputScope outputScope;

  /// Object mà beat được phép tham chiếu — đăng ký bởi lesson, không phải do plan tự đặt.
  final List<String> objectIds;

  BoardBeatCopy? copyFor(String locale) => copy[locale];

  Iterable<String> get locales => copy.keys;
}

/// Kế hoạch giảng cho một bước.
class TeachingPlan {
  const TeachingPlan({
    required this.schemaVersion,
    required this.planId,
    required this.lessonId,
    required this.stepId,
    required this.characterId,
    required this.source,
    required this.beats,
    this.registeredObjects = const <String>[],
  });

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String planId;
  final String lessonId;
  final String stepId;

  /// Identity do lesson chọn (qua `CastRegistry`), **không** hardcode Robo cho mọi bài.
  final String characterId;
  final BoardPlanSource source;
  final List<BoardBeat> beats;

  /// Danh sách object id mà lesson khai báo; plan tham chiếu ngoài danh sách này là sai.
  final List<String> registeredObjects;
}

/// Token envelope mà host phải khớp để plan được nhận.
class BoardPlanToken {
  const BoardPlanToken({
    required this.sessionId,
    required this.contextRevision,
    required this.turnId,
    required this.locale,
  });

  final String sessionId;
  final int contextRevision;
  final int turnId;
  final String locale;
}

/// Một lỗi validate. `code` là khóa ổn định để test gọi tên, không so chuỗi tự do.
enum BoardIssueCode {
  schemaVersion('schemaVersion'),
  emptyPlan('emptyPlan'),
  tooManyBeats('tooManyBeats'),
  tooManyOps('tooManyOps'),
  copyTooLong('copyTooLong'),
  missingCopy('missingCopy'),
  missingAltText('missingAltText'),
  genericAltText('genericAltText'),
  unknownOpKind('unknownOpKind'),
  unknownObject('unknownObject'),
  duplicateId('duplicateId'),
  malformedId('malformedId'),
  payloadTooLarge('payloadTooLarge'),
  tooManyTokens('tooManyTokens'),
  tooManyShapes('tooManyShapes'),
  tooManyConnectors('tooManyConnectors'),
  tooManyCodeLines('tooManyCodeLines'),
  badGeometry('badGeometry'),
  layerViolation('layerViolation'),
  outputWithoutStatement('outputWithoutStatement'),
  outputMismatch('outputMismatch'),
  outputScopeMismatch('outputScopeMismatch'),
  markupInText('markupInText'),
  documentTooLarge('documentTooLarge'),
  foreignKey('foreignKey'),
  invalidJson('invalidJson'),
  staleToken('staleToken'),
  wrongSession('wrongSession'),
  wrongTurn('wrongTurn'),
  wrongLocale('wrongLocale'),
  disposed('disposed'),
  canceled('canceled');

  const BoardIssueCode(this.wire);

  final String wire;
}

/// Một vấn đề cụ thể, trỏ đúng beat/op để reviewer không phải đoán.
class BoardIssue {
  const BoardIssue(this.code, this.message, {this.beatIndex, this.opIndex});

  final BoardIssueCode code;
  final String message;
  final int? beatIndex;
  final int? opIndex;

  @override
  String toString() =>
      '${code.wire}@beat${beatIndex ?? '-'}/op${opIndex ?? '-'}: $message';
}

/// Kết quả validate. **Atomic**: `accepted == false` nghĩa là *không có gì* được áp dụng.
class BoardValidation {
  const BoardValidation.accepted(this.plan) : issues = const <BoardIssue>[];

  const BoardValidation.rejected(this.issues) : plan = null;

  final TeachingPlan? plan;
  final List<BoardIssue> issues;

  bool get accepted => plan != null;

  Set<BoardIssueCode> get codes => issues.map((BoardIssue i) => i.code).toSet();
}

/// Kết quả áp plan vào controller.
enum BoardApplyOutcome {
  /// Plan hợp lệ, token hợp lệ -> board đổi.
  applied,

  /// Plan có lỗi -> **giữ nguyên** bảng đang hiển thị, kèm fallback có nhãn.
  rejectedPlan,

  /// Token không khớp (revision cũ / session khác / turn khác / locale khác).
  tokenRejected,

  /// Board của phiên đã bị dispose: không nhận gì, không notify.
  disposed,
}
