/// Giải mã + kiểm cấu trúc **toàn bộ** plan trước khi render (rev 4 §D5: một lỗi là reject
/// nguyên plan; rev 7 §R7-A: sai kiểu cũng là reject, không phải ném exception hay mặc định).
///
/// Ba bất biến của file này:
///  * không `as` vào dữ liệu chưa kiểm — mọi trường đi qua [_Collector] để lệch kiểu thành
///    `BoardIssue`, nên một JSON bệnh hoạn không làm host nổ;
///  * không có giá trị "thân thiện": `x: "oops"` không được thành 0, `line` thiếu không được
///    thành 1, `shape` lạ không được thành rectangle — âm thầm sửa số là sửa nội dung giảng;
///  * `DeterministicReference` là nguồn duy nhất cho output; plan không tự khai kết quả.
library;

import 'dart:convert';

import 'board_models.dart';

final RegExp _idPattern = RegExp(r'^[a-z0-9][a-z0-9_.\-]{0,39}$');
final RegExp _genericAlt = RegExp(
  r'^(ảnh|hình|image|illustration|graphic)(\s*minh\s*h[ọo]a)?\.?$',
  caseSensitive: false,
);

/// Khóa mà plan **không** được phép mang: data chấm điểm/dịch vụ nằm ở lesson và engine,
/// copy sang overlay là đường để hai bên trôi nhau (rev 4 §D8).
const Set<String> _forbiddenKeys = <String>{
  'code',
  'expectedOutput',
  'expected_output',
  'answer',
  'answers',
  'solution',
  'rule',
  'rules',
  'prerequisite',
  'prerequisites',
  'score',
  'stars',
  'reward',
  'rewards',
  'energy',
  'html',
  'svg',
  'url',
  'src',
  'image',
  'imageUrl',
  'link',
  'script',
  'style',
  'className',
  'onclick',
};

/// Chuỗi mang nghĩa "tao ra kênh đánh dấu/URL": từ chối **làm** markup, không phải ký tự `<`
/// xuất hiện trong text thường (text thường thì hiển thị nguyên văn).
const List<String> _forbiddenSubstrings = <String>[
  'javascript:',
  'data:image',
  '<svg',
  '<script',
  'onerror=',
  'onclick=',
];

/// Bảng tra "câu lệnh -> output" dựng từ dataset/engine của đúng code ví dụ.
class DeterministicReference {
  const DeterministicReference(this._byStatement);

  final Map<String, String> _byStatement;

  bool knows(String statement) => _byStatement.containsKey(statement);

  /// Output thật của một statement; `null` khi reference không biết statement đó.
  String? outputOf(String statement) => _byStatement[statement];

  /// Những dòng code reference nhận — dùng cho highlight theo từ/đoạn.
  Iterable<String> get knownStatements => _byStatement.keys;

  /// Output của cả một đoạn chạy (nhiều dòng, giữ nguyên thứ tự).
  String? runOutputOf(String code) {
    final List<String> out = <String>[];
    for (final String line in const LineSplitter().convert(code)) {
      final String trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final String? value = _byStatement[trimmed];
      if (value == null) return null;
      out.add(value);
    }
    return out.join('\n');
  }
}

/// Kết quả decode thô: hoặc có plan, hoặc có lỗi. Không bao giờ "một nửa plan".
class DecodedPlan {
  const DecodedPlan(this.plan, this.issues);

  final TeachingPlan? plan;
  final List<BoardIssue> issues;

  bool get clean => issues.isEmpty;
}

/// Thu thập lỗi kèm vị trí, và chặn mọi cast không kiểm.
class _Collector {
  _Collector(this.issues);

  final List<BoardIssue> issues;
  int? beatIndex;
  int? opIndex;

  bool get failed => issues.isNotEmpty;

  void add(BoardIssueCode code, String message) {
    issues.add(BoardIssue(code, message, beatIndex: beatIndex, opIndex: opIndex));
  }

  Map<String, dynamic>? map(Object? value, String field) {
    if (value is Map<String, dynamic>) return value;
    add(BoardIssueCode.wrongType, '$field phải là object');
    return null;
  }

  /// Chuỗi đã kiểm kiểu. `required` + vắng mặt là lỗi, không phải chuỗi rỗng mặc định.
  String str(Object? value, String field, {bool required = true, int maxRunes = 1 << 30}) {
    if (value == null) {
      if (required) add(BoardIssueCode.missingOpField, 'thiếu $field');
      return '';
    }
    if (value is! String) {
      add(BoardIssueCode.wrongType, '$field phải là chuỗi');
      return '';
    }
    if (value.runes.length > maxRunes) {
      add(BoardIssueCode.copyTooLong, '$field dài ${value.runes.length} code point vượt $maxRunes');
    }
    return value;
  }

  /// `null` = đã có lỗi được ghi (đừng báo thêm lỗi "trống" chồng lên),
  /// `[]` = vắng mặt hợp lệ hoặc mảng rỗng thật sự.
  List<String>? stringList(Object? value, String field, {required bool allowAbsent, int? maxLen}) {
    if (value == null) {
      if (!allowAbsent) add(BoardIssueCode.missingOpField, 'thiếu $field');
      return const <String>[];
    }
    if (value is! List<dynamic>) {
      add(BoardIssueCode.wrongType, '$field phải là mảng chuỗi, nhận ${value.runtimeType}');
      return null;
    }
    final List<String> out = <String>[];
    for (final Object? element in value) {
      if (element is! String) {
        add(BoardIssueCode.wrongType, '$field có phần tử không phải chuỗi');
        return null;
      }
      out.add(element);
    }
    if (maxLen != null && out.length > maxLen) {
      add(BoardIssueCode.tooManyTokens, '$field có ${out.length} phần tử vượt $maxLen');
    }
    return out;
  }

  /// Số học, nghiêm ngặt: không ép `"3"` hay `true` thành số, và không mặc định 0.
  double? number(Object? value, String field, {bool required = true}) {
    if (value == null) {
      if (required) add(BoardIssueCode.missingOpField, 'thiếu $field');
      return null;
    }
    if (value is! num) {
      add(BoardIssueCode.wrongType, '$field phải là số, nhận ${value.runtimeType}');
      return null;
    }
    final double d = value.toDouble();
    if (d.isNaN || d.isInfinite) {
      add(BoardIssueCode.badGeometry, '$field không hữu hạn: $d');
      return null;
    }
    return d;
  }

  int? integer(Object? value, String field, {bool required = true, int? max}) {
    if (value == null) {
      if (required) add(BoardIssueCode.missingOpField, 'thiếu $field');
      return null;
    }
    if (value is! int) {
      add(BoardIssueCode.wrongType, '$field phải là số nguyên');
      return null;
    }
    if (value < 1 || (max != null && value > max)) {
      add(BoardIssueCode.badHighlightRange, '$field=$value ngoài khoảng cho phép (1..${max ?? '∞'})');
      return null;
    }
    return value;
  }

  /// Bản sao per-locale: đủ mọi locale yêu cầu, không khóa lạ, mỗi giá trị là chuỗi trong trần.
  Map<String, String>? localeStrings(Object? value, String field, List<String> locales,
      {required bool allowAbsent}) {
    if (value == null) {
      if (!allowAbsent) add(BoardIssueCode.missingCopy, 'thiếu $field');
      return null;
    }
    if (value is! Map<String, dynamic>) {
      add(BoardIssueCode.wrongType, '$field phải là object theo locale');
      return null;
    }
    final Map<String, dynamic> raw = value;
    for (final String unexpected in raw.keys.where((String k) => !locales.contains(k))) {
      add(BoardIssueCode.wrongType, '$field có khóa locale lạ: $unexpected');
    }
    final Map<String, String> out = <String, String>{};
    for (final String locale in locales) {
      final Object? entry = raw[locale];
      if (entry == null) {
        add(BoardIssueCode.missingCopy, '$field thiếu locale $locale');
        continue;
      }
      if (entry is! String) {
        add(BoardIssueCode.wrongType, '$field.$locale phải là chuỗi');
        continue;
      }
      if (entry.runes.length > BoardLimits.maxCopyField) {
        add(BoardIssueCode.copyTooLong,
            '$field.$locale dài ${entry.runes.length} code point vượt ${BoardLimits.maxCopyField}');
      }
      out[locale] = entry;
    }
    return out.length == locales.length ? out : null;
  }

  /// Trả về id đã sạch; `null` khi vắng mặt hoặc sai — không bao giờ trả chuỗi bẩn.
  String? id(Object? value, String field, List<String> registered, {required bool allowAbsent}) {
    if (value == null) {
      if (!allowAbsent) add(BoardIssueCode.missingOpField, 'thiếu $field');
      return null;
    }
    if (value is! String) {
      add(BoardIssueCode.wrongType, '$field phải là chuỗi id');
      return null;
    }
    if (!_idPattern.hasMatch(value)) {
      add(BoardIssueCode.malformedId, '$field không hợp lệ: $value');
      return null;
    }
    if (!registered.contains(value)) {
      add(BoardIssueCode.unknownObject, '$field trỏ object chưa đăng ký: $value');
      return null;
    }
    return value;
  }

  void geometry(Map<String, dynamic> raw) {
    for (final String field in <String>['x', 'y', 'width', 'height']) {
      final double? value = number(raw[field], field);
      if (value == null) continue;
      if (value < 0 || value > BoardLimits.maxGeometry) {
        add(BoardIssueCode.badGeometry, '$field=$value ngoài 0..${BoardLimits.maxGeometry}');
      }
      if ((field == 'width' || field == 'height') && value <= 0) {
        add(BoardIssueCode.badGeometry, '$field=$value phải > 0 để vẽ được');
      }
    }
  }
}

/// Đường dẫn JSON cho message, để reviewer trỏ đúng chỗ hỏng.
String _pathOf(List<String> path, String key) => <String>[...path, key].join('.');

int _lineCount(String value) {
  int count = 0;
  for (final String line in const LineSplitter().convert(value)) {
    if (line.trim().isNotEmpty) count++;
  }
  return count == 0 ? 1 : count;
}

/// Đếm số lần xuất hiện không chồng nhau — dùng để bắt highlight bịa đoạn chữ.
int _occurrences(String haystack, String needle) {
  if (needle.isEmpty) return 0;
  int count = 0;
  int at = haystack.indexOf(needle);
  while (at >= 0) {
    count++;
    at = haystack.indexOf(needle, at + needle.length);
  }
  return count;
}

DecodedPlan decodePlan(
  String source, {
  required List<String> registeredObjects,
  required List<String> requiredLocales,
}) {
  final List<BoardIssue> issues = <BoardIssue>[];
  final _Collector c = _Collector(issues);

  if (source.length > BoardLimits.maxDocumentChars) {
    c.add(BoardIssueCode.documentTooLarge,
        'tài liệu ${source.length} ký tự vượt trần ${BoardLimits.maxDocumentChars}');
    return DecodedPlan(null, issues);
  }

  Object? raw;
  try {
    raw = jsonDecode(source);
  } on FormatException catch (e) {
    c.add(BoardIssueCode.invalidJson, 'json: ${e.message}');
    return DecodedPlan(null, issues);
  } on Object catch (e) {
    // Mọi lỗi giải mã khác cũng phải là reject, không phải exception nổ lên host.
    c.add(BoardIssueCode.invalidJson, 'json: ${e.runtimeType}');
    return DecodedPlan(null, issues);
  }
  final Map<String, dynamic>? doc = c.map(raw, 'gốc');
  if (doc == null) return DecodedPlan(null, issues);

  _collectBadKeys(doc, issues, <String>[]);
  if (c.failed) return DecodedPlan(null, issues);

  final Object? version = doc['schemaVersion'];
  if (version is! int || version != TeachingPlan.currentSchemaVersion) {
    c.add(BoardIssueCode.schemaVersion, 'schemaVersion=$version, cần ${TeachingPlan.currentSchemaVersion}');
  }

  final String planId = c.str(doc['planId'], 'planId');
  final String lessonId = c.str(doc['lessonId'], 'lessonId');
  final String stepId = c.str(doc['stepId'], 'stepId');
  final String characterId = c.str(doc['characterId'], 'characterId');
  for (final MapEntry<String, String> e in <String, String>{
    'planId': planId,
    'lessonId': lessonId,
    'stepId': stepId,
    'characterId': characterId,
  }.entries) {
    if (e.value.isNotEmpty && !_idPattern.hasMatch(e.value)) {
      c.add(BoardIssueCode.malformedId, '${e.key} không hợp lệ: ${e.value}');
    }
  }

  final String sourceWire = c.str(doc['source'], 'source');
  BoardPlanSource? planSource;
  for (final BoardPlanSource value in BoardPlanSource.values) {
    if (value.name == sourceWire) planSource = value;
  }
  if (planSource == null) {
    c.add(BoardIssueCode.wrongType, 'source không thuộc hợp đồng: $sourceWire');
  }

  final Object? beatsRaw = doc['beats'];
  if (beatsRaw is! List<dynamic>) {
    c.add(beatsRaw == null ? BoardIssueCode.missingCopy : BoardIssueCode.wrongType,
        beatsRaw == null ? 'thiếu beats' : 'beats phải là mảng');
    return DecodedPlan(null, issues);
  }
  if (beatsRaw.isEmpty) {
    // rev 4 §D5: plan rỗng KHÔNG phải "thành công".
    c.add(BoardIssueCode.emptyPlan, 'plan không có beat nào');
  }
  if (beatsRaw.length > BoardLimits.maxBeats) {
    c.add(BoardIssueCode.tooManyBeats, '${beatsRaw.length} beats vượt trần ${BoardLimits.maxBeats}');
  }

  final List<BoardBeat> beats = <BoardBeat>[];
  final Set<String> seenBeatIds = <String>{};
  for (int i = 0; i < beatsRaw.length; i++) {
    c.beatIndex = i;
    c.opIndex = null;
    final Map<String, dynamic>? beat = c.map(beatsRaw[i], 'beats[$i]');
    if (beat == null) continue;
    final BoardBeat? parsed = _decodeBeat(
      c,
      beat,
      registeredObjects: registeredObjects,
      requiredLocales: requiredLocales,
    );
    if (parsed == null) continue;
    if (!seenBeatIds.add(parsed.beatId)) {
      c.add(BoardIssueCode.duplicateId, 'beatId lặp: ${parsed.beatId}');
    }
    beats.add(parsed);
  }
  c.beatIndex = null;
  c.opIndex = null;

  if (c.failed) return DecodedPlan(null, issues);
  return DecodedPlan(
    TeachingPlan(
      schemaVersion: version is int ? version : 0,
      planId: planId,
      lessonId: lessonId,
      stepId: stepId,
      characterId: characterId,
      source: planSource ?? BoardPlanSource.authored,
      beats: beats,
      registeredObjects: registeredObjects,
    ),
    issues,
  );
}

BoardBeat? _decodeBeat(
  _Collector c,
  Map<String, dynamic> raw, {
  required List<String> registeredObjects,
  required List<String> requiredLocales,
}) {
  final String beatId = c.str(raw['beatId'], 'beatId');
  if (beatId.isNotEmpty && !_idPattern.hasMatch(beatId)) {
    c.add(BoardIssueCode.malformedId, 'beatId không hợp lệ: $beatId');
  }

  final Map<String, dynamic>? copy = c.map(raw['copy'], 'copy');
  final Map<String, BoardBeatCopy> byLocale = <String, BoardBeatCopy>{};
  if (copy != null) {
    for (final String locale in requiredLocales) {
      final Map<String, dynamic>? entry = c.map(copy[locale], 'copy.$locale');
      if (entry == null) continue;
      final String title = c.str(entry['title'], 'copy.$locale.title');
      final String say = c.str(entry['say'], 'copy.$locale.say');
      final String caption = c.str(entry['caption'], 'copy.$locale.caption');
      final String alt = c.str(entry['altText'], 'copy.$locale.altText');
      if (alt.trim().isEmpty) {
        c.add(BoardIssueCode.missingAltText, 'altText rỗng ở $locale');
      } else if (_genericAlt.hasMatch(alt.trim())) {
        c.add(BoardIssueCode.genericAltText, 'altText chỉ là nhãn chung ở $locale');
      }
      byLocale[locale] = BoardBeatCopy(title: title, say: say, caption: caption, altText: alt);
    }
    for (final String unexpected in copy.keys.where((String k) => !requiredLocales.contains(k))) {
      c.add(BoardIssueCode.wrongType, 'copy có khóa locale lạ: $unexpected');
    }
  }
  if (byLocale.length < 2) {
    c.add(BoardIssueCode.missingCopy, 'beat phải có copy cho đủ các locale yêu cầu');
  }

  BoardOutputScope scope = BoardOutputScope.singleStatement;
  if (raw['outputScope'] != null) {
    final String wire = c.str(raw['outputScope'], 'outputScope');
    final BoardOutputScope? parsed = BoardOutputScope.fromWire(wire);
    if (parsed == null) {
      c.add(BoardIssueCode.wrongType, 'outputScope lạ: $wire');
    } else {
      scope = parsed;
    }
  }

  final String? statement = raw['sourceStatement'] == null ? null : c.str(raw['sourceStatement'], 'sourceStatement');

  // `ops` vắng mặt = beat không có op nào (chỉ copy), **không** phải "bỏ beat này khỏi plan":
  // âm thầm xóa beat là đúng cái lỗi R7-A cấm.
  final List<Object?>? opsRaw = raw['ops'] == null ? const <Object?>[] : _asList(raw['ops'], 'ops', c);
  if (opsRaw == null) return null;
  if (opsRaw.length > BoardLimits.maxOpsPerBeat) {
    c.add(BoardIssueCode.tooManyOps, '${opsRaw.length} ops vượt trần ${BoardLimits.maxOpsPerBeat}');
  }

  final List<BoardOp> ops = <BoardOp>[];
  int tokenGroups = 0;
  int shapes = 0;
  int connectors = 0;
  for (int i = 0; i < opsRaw.length; i++) {
    c.opIndex = i;
    final Map<String, dynamic>? op = c.map(opsRaw[i], 'ops[$i]');
    if (op == null) continue;
    final BoardOp? parsed = _decodeOp(
      c,
      op,
      registeredObjects: registeredObjects,
      requiredLocales: requiredLocales,
      statement: statement,
    );
    if (parsed == null) continue;
    switch (parsed.kind) {
      case BoardOpKind.tokenGroup:
        tokenGroups++;
      case BoardOpKind.simpleShape:
        shapes++;
      case BoardOpKind.connector:
        connectors++;
      default:
        break;
    }
    ops.add(parsed);
  }
  c.opIndex = null;
  if (tokenGroups > BoardLimits.maxTokenGroups) {
    c.add(BoardIssueCode.tooManyTokens, '$tokenGroups tokenGroup vượt ${BoardLimits.maxTokenGroups}');
  }
  if (shapes > BoardLimits.maxShapes) {
    c.add(BoardIssueCode.tooManyShapes, '$shapes shape vượt ${BoardLimits.maxShapes}');
  }
  if (connectors > BoardLimits.maxConnectors) {
    c.add(BoardIssueCode.tooManyConnectors, '$connectors connector vượt ${BoardLimits.maxConnectors}');
  }

  final List<String>? objectIdsRaw = c.stringList(raw['objectIds'], 'objectIds', allowAbsent: true);
  final List<String> objectIds = objectIdsRaw ?? const <String>[];
  for (final String id in objectIds) {
    if (!registeredObjects.contains(id)) {
      c.add(BoardIssueCode.unknownObject, 'beat tham chiếu object chưa đăng ký: $id');
    }
  }

  final bool waits = raw['waitForLearner'] == true;
  if (raw['waitForLearner'] != null && raw['waitForLearner'] is! bool) {
    c.add(BoardIssueCode.wrongType, 'waitForLearner phải là boolean');
  }

  if (c.failed) return null;
  return BoardBeat(
    beatId: beatId,
    copy: byLocale,
    ops: ops,
    waitForLearner: waits,
    sourceStatement: statement,
    outputScope: scope,
    objectIds: objectIds,
  );
}

List<Object?>? _asList(Object? value, String field, _Collector c) {
  if (value is List<dynamic>) return value;
  c.add(BoardIssueCode.wrongType, '$field phải là mảng');
  return null;
}

BoardOp? _decodeOp(
  _Collector c,
  Map<String, dynamic> raw, {
  required List<String> registeredObjects,
  required List<String> requiredLocales,
  required String? statement,
}) {
  final String kindWire = c.str(raw['type'], 'type');
  final BoardOpKind? kind = BoardOpKind.fromWire(kindWire);
  if (kind == null || kind == BoardOpKind.unknown) {
    c.add(BoardIssueCode.unknownOpKind, 'op type không có trong allowlist: $kindWire');
    return null;
  }
  if (raw['layer'] != null) {
    // Một op tự khai layer nghĩa là nó xin ghi/xóa lớp khác lớp Tutor.
    c.add(BoardIssueCode.layerViolation, 'op không được chọn layer');
    return null;
  }

  final Map<String, String>? altTexts =
      c.localeStrings(raw['altText'], 'op.altText', requiredLocales, allowAbsent: false);
  if (altTexts != null) {
    for (final MapEntry<String, String> e in altTexts.entries) {
      if (e.value.trim().isEmpty) {
        c.add(BoardIssueCode.missingAltText, 'op thiếu altText ở ${e.key}');
      } else if (_genericAlt.hasMatch(e.value.trim())) {
        c.add(BoardIssueCode.genericAltText, 'op.altText chỉ là nhãn chung ở ${e.key}');
      }
    }
  }
  final Map<String, String> prose =
      c.localeStrings(raw['text'], 'op.text', requiredLocales, allowAbsent: true) ??
          const <String, String>{};
  for (final MapEntry<String, String> e in prose.entries) {
    if (e.value.runes.length > BoardLimits.maxOpText) {
      c.add(BoardIssueCode.copyTooLong, 'op.text.${e.key} dài ${e.value.runes.length} code point');
    }
    if (kind == BoardOpKind.codeSnippet) {
      final int lines = const LineSplitter().convert(e.value).length;
      if (lines > BoardLimits.maxCodeLines || e.value.runes.length > BoardLimits.maxCodeChars) {
        c.add(BoardIssueCode.tooManyCodeLines,
            'codeSnippet ${e.key}: $lines dòng / ${e.value.runes.length} code point vượt trần');
      }
    }
    if (kind == BoardOpKind.text && e.value.trim().isEmpty) {
      c.add(BoardIssueCode.missingOpField, 'op text rỗng ở ${e.key}');
    }
  }
  if (prose.isEmpty && (kind == BoardOpKind.text || kind == BoardOpKind.codeSnippet)) {
    c.add(BoardIssueCode.missingOpField, '${kind.wire} cần text cho mọi locale');
  }

  final String opStatement = raw['statement'] == null ? '' : c.str(raw['statement'], 'statement');
  final String token = c.str(raw['token'], 'token', required: false, maxRunes: BoardLimits.maxTokenLiteral);
  final String value = c.str(raw['value'], 'value', required: false);
  final String shape = c.str(raw['shape'], 'shape', required: false);
  final List<String>? tokenIdsRaw =
      c.stringList(raw['tokenIds'], 'tokenIds', allowAbsent: true, maxLen: BoardLimits.maxTokensPerGroup);
  final List<String> tokenIds = tokenIdsRaw ?? const <String>[];

  final double? x = raw['x'] == null ? null : c.number(raw['x'], 'x');
  final double? y = raw['y'] == null ? null : c.number(raw['y'], 'y');
  final double? width = raw['width'] == null ? null : c.number(raw['width'], 'width');
  final double? height = raw['height'] == null ? null : c.number(raw['height'], 'height');
  for (final double? measured in <double?>[x, y, width, height]) {
    if (measured != null && (measured < 0 || measured > BoardLimits.maxGeometry)) {
      c.add(BoardIssueCode.badGeometry, 'hình học $measured ngoài 0..${BoardLimits.maxGeometry}');
      break;
    }
  }

  final String? objectId = c.id(raw['objectId'], 'objectId', registeredObjects, allowAbsent: true);
  final String? fromId = c.id(raw['fromId'], 'fromId', registeredObjects, allowAbsent: true);
  final String? toId = c.id(raw['toId'], 'toId', registeredObjects, allowAbsent: true);
  for (final String id in tokenIds) {
    if (!_idPattern.hasMatch(id)) {
      c.add(BoardIssueCode.malformedId, 'tokenId không hợp lệ: $id');
    } else if (!registeredObjects.contains(id)) {
      c.add(BoardIssueCode.unknownObject, 'tokenId trỏ object chưa đăng ký: $id');
    }
  }

  switch (kind) {
    case BoardOpKind.highlightToken:
      _checkHighlight(c, opStatement, statement, token, tokenIds);
    case BoardOpKind.highlightLine:
      _checkHighlightLine(c, opStatement, statement, raw['line']);
    case BoardOpKind.output:
      if (opStatement.trim().isEmpty && (statement ?? '').trim().isEmpty) {
        c.add(BoardIssueCode.outputWithoutStatement, 'op output phải nêu statement nó mô tả');
      }
      if (!raw.containsKey('value')) {
        c.add(BoardIssueCode.missingOpField, 'op output thiếu value');
      }
    case BoardOpKind.simpleShape:
      if (!BoardLimits.shapeAllowlist.contains(shape)) {
        c.add(BoardIssueCode.unknownShape, 'shape "$shape" không thuộc ${BoardLimits.shapeAllowlist}');
      }
      if (raw['objectId'] == null) {
        c.add(BoardIssueCode.missingOpField, 'simpleShape cần objectId để neo hình');
      }
      c.geometry(raw);
    case BoardOpKind.connector:
      if (raw['fromId'] == null || raw['toId'] == null) {
        c.add(BoardIssueCode.missingOpField, 'connector cần cả fromId và toId');
      } else if (raw['fromId'] == raw['toId']) {
        c.add(BoardIssueCode.missingOpField, 'connector có hai đầu mút trùng nhau');
      }
    case BoardOpKind.tokenGroup:
      // `tokenIds` rỗng nghĩa là renderer không còn gì để đếm số vật — với op này mảng
      // **phải có nội dung**, chứ không được suy ra từ số object mà beat đã đăng ký.
      if (tokenIdsRaw != null && tokenIds.isEmpty) {
        c.add(BoardIssueCode.missingOpField, 'tokenGroup cần tokenIds để vẽ đủ số vật');
      }
    case BoardOpKind.text:
    case BoardOpKind.codeSnippet:
    case BoardOpKind.clearTutorLayer:
    case BoardOpKind.unknown:
      break;
  }

  if (c.failed) return null;
  return BoardOp(
    kind: kind,
    altTexts: altTexts ?? const <String, String>{},
    text: prose,
    token: token,
    statement: opStatement,
    objectId: objectId,
    fromId: fromId,
    toId: toId,
    tokenIds: tokenIds,
    shape: shape,
    value: value,
    x: x ?? 0,
    y: y ?? 0,
    width: width ?? 0,
    height: height ?? 0,
    line: raw['line'] is int ? raw['line'] as int : 1,
  );
}

void _checkHighlight(
  _Collector c,
  String opStatement,
  String? beatStatement,
  String token,
  List<String> tokenIds,
) {
  final String target = opStatement.trim().isNotEmpty ? opStatement.trim() : (beatStatement ?? '').trim();
  if (target.isEmpty) {
    c.add(BoardIssueCode.outputWithoutStatement, 'highlight không nêu câu lệnh nguồn');
    return;
  }
  if (token.isEmpty) {
    c.add(BoardIssueCode.badHighlightRange, 'highlightToken thiếu đoạn chữ `token` để tô');
    return;
  }
  final int found = _occurrences(target, token);
  if (found == 0) {
    c.add(BoardIssueCode.badHighlightRange, 'token "$token" không xuất hiện trong "$target"');
    return;
  }
  if (tokenIds.isNotEmpty && tokenIds.length != found) {
    c.add(BoardIssueCode.badHighlightRange,
        'tokenIds có ${tokenIds.length} mục nhưng "$token" xuất hiện $found lần trong code nguồn');
  }
}

void _checkHighlightLine(_Collector c, String opStatement, String? beatStatement, Object? lineValue) {
  final String target = opStatement.trim().isNotEmpty ? opStatement.trim() : (beatStatement ?? '').trim();
  if (target.isEmpty) {
    c.add(BoardIssueCode.outputWithoutStatement, 'highlightLine không nêu câu lệnh nguồn');
    return;
  }
  c.integer(lineValue, 'line', max: _lineCount(target));
}

void _collectBadKeys(Object? node, List<BoardIssue> issues, List<String> path) {
  if (node is Map<String, dynamic>) {
    for (final MapEntry<String, dynamic> entry in node.entries) {
      if (_forbiddenKeys.contains(entry.key)) {
        final String where = _pathOf(path, entry.key);
        issues.add(BoardIssue(BoardIssueCode.foreignKey, 'khóa ngoài hợp đồng: $where'));
      }
      final Object? value = entry.value;
      if (value is String) {
        for (final String bad in _forbiddenSubstrings) {
          if (value.contains(bad)) {
            final String where = _pathOf(path, entry.key);
            issues.add(BoardIssue(BoardIssueCode.markupInText, 'chuỗi có $bad ở $where'));
            break;
          }
        }
      }
      _collectBadKeys(value, issues, <String>[...path, entry.key]);
    }
  } else if (node is List<dynamic>) {
    for (int i = 0; i < node.length; i++) {
      _collectBadKeys(node[i], issues, <String>[...path, '$i']);
    }
  }
}
