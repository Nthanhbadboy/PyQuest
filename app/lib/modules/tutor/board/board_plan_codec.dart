/// Giải mã + validate **toàn bộ** plan trước khi render (rev 4 §D5: một lỗi là reject
/// nguyên plan, không bỏ beat/connector rồi vẽ nốt).
///
/// Codec không biết gì về provider/network/marc-up renderer: chuỗi chỉ là chuỗi.
/// `DeterministicReference` là **nguồn sự thật duy nhất** cho output — plan không được
/// tự khai kết quả rồi tin như đã chạy.
library;

import 'dart:convert';

import 'board_models.dart';

final RegExp _idPattern = RegExp(r'^[a-z0-9][a-z0-9_.\-]{0,39}$');

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

/// Chuỗi mang nghĩa "tao ra kênh đánh dấu/URL": từ chối **làm** markup, không phải
/// ký tự `<` xuất hiện trong text thường (text thường thì hiển thị nguyên văn).
const List<String> _forbiddenSubstrings = <String>[
  'javascript:',
  'data:image',
  '<svg',
  '<script',
  'onerror=',
  'onclick=',
];

/// Bảng tra "câu lệnh -> output" dựng từ dataset/fixture của đúng code ví dụ.
class DeterministicReference {
  const DeterministicReference(this._byStatement);

  final Map<String, String> _byStatement;

  bool knows(String statement) => _byStatement.containsKey(statement);

  /// Những dòng code reference nhận — dùng cho highlight theo từ/đoạn.
  Iterable<String> get knownStatements => _byStatement.keys;

  /// Output thật của một statement; `null` khi reference không biết statement đó.
  String? outputOf(String statement) => _byStatement[statement];

  /// Output của cả một đoạn chạy (nhiều dòng, giữ nguyên thứ tự).
  String? runOutputOf(String code) {
    final List<String> lines = const LineSplitter().convert(code);
    final List<String> out = <String>[];
    for (final String line in lines) {
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

DecodedPlan decodePlan(
  String source, {
  required List<String> registeredObjects,
  required List<String> requiredLocales,
}) {
  final List<BoardIssue> issues = <BoardIssue>[];
  if (source.length > BoardLimits.maxDocumentChars) {
    issues.add(BoardIssue(
      BoardIssueCode.documentTooLarge,
      'tài liệu ${source.length} ký tự vượt trần ${BoardLimits.maxDocumentChars}',
    ));
    return DecodedPlan(null, issues);
  }

  Object? raw;
  try {
    raw = jsonDecode(source);
  } on FormatException catch (e) {
    issues.add(BoardIssue(BoardIssueCode.invalidJson, 'json: ${e.message}'));
    return DecodedPlan(null, issues);
  }
  if (raw is! Map<String, dynamic>) {
    issues.add(const BoardIssue(BoardIssueCode.invalidJson, 'gốc phải là object'));
    return DecodedPlan(null, issues);
  }

  _collectBadKeys(raw, issues, <String>[]);
  if (issues.isNotEmpty) return DecodedPlan(null, issues);

  final Object? version = raw['schemaVersion'];
  if (version is! int || version != TeachingPlan.currentSchemaVersion) {
    issues.add(BoardIssue(
      BoardIssueCode.schemaVersion,
      'schemaVersion=$version, cần ${TeachingPlan.currentSchemaVersion}',
    ));
  }

  final String planId = _str(raw['planId']);
  final String lessonId = _str(raw['lessonId']);
  final String stepId = _str(raw['stepId']);
  final String characterId = _str(raw['characterId']);
  for (final MapEntry<String, String> e in <String, String>{
    'planId': planId,
    'lessonId': lessonId,
    'stepId': stepId,
  }.entries) {
    if (!_idPattern.hasMatch(e.value)) {
      issues.add(BoardIssue(BoardIssueCode.malformedId, '${e.key} không hợp lệ: ${e.value}'));
    }
  }
  final String sourceWire = _str(raw['source']);
  if (!_idPattern.hasMatch(characterId)) {
    issues.add(BoardIssue(BoardIssueCode.malformedId, 'characterId không hợp lệ: $characterId'));
  }
  BoardPlanSource? planSource;
  for (final BoardPlanSource value in BoardPlanSource.values) {
    if (value.name == sourceWire) planSource = value;
  }
  if (planSource == null) {
    issues.add(BoardIssue(BoardIssueCode.invalidJson, 'source không thuộc hợp đồng: $sourceWire'));
  }

  final Object? beatsRaw = raw['beats'];
  if (beatsRaw is! List<dynamic>) {
    issues.add(const BoardIssue(BoardIssueCode.invalidJson, 'beats phải là mảng'));
    return DecodedPlan(null, issues);
  }
  if (beatsRaw.isEmpty) {
    // rev 4 §D5: plan rỗng KHÔNG phải "thành công".
    issues.add(const BoardIssue(BoardIssueCode.emptyPlan, 'plan không có beat nào'));
  }
  if (beatsRaw.length > BoardLimits.maxBeats) {
    issues.add(BoardIssue(
      BoardIssueCode.tooManyBeats,
      '${beatsRaw.length} beats vượt trần ${BoardLimits.maxBeats}',
    ));
  }

  final List<BoardBeat> beats = <BoardBeat>[];
  final Set<String> seenBeatIds = <String>{};
  for (int i = 0; i < beatsRaw.length; i++) {
    final Object? beatRaw = beatsRaw[i];
    if (beatRaw is! Map<String, dynamic>) {
      issues.add(BoardIssue(BoardIssueCode.invalidJson, 'beat không phải object', beatIndex: i));
      continue;
    }
    final BoardBeat? beat = _decodeBeat(
      beatRaw,
      index: i,
      issues: issues,
      requiredLocales: requiredLocales,
      registeredObjects: registeredObjects,
    );
    if (beat == null) continue;
    if (!seenBeatIds.add(beat.beatId)) {
      issues.add(BoardIssue(BoardIssueCode.duplicateId, 'beatId lặp: ${beat.beatId}', beatIndex: i));
    }
    beats.add(beat);
  }

  if (issues.isNotEmpty) return DecodedPlan(null, issues);
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
  Map<String, dynamic> raw, {
  required int index,
  required List<BoardIssue> issues,
  required List<String> requiredLocales,
  required List<String> registeredObjects,
}) {
  final String beatId = _str(raw['beatId']);
  if (!_idPattern.hasMatch(beatId)) {
    issues.add(BoardIssue(BoardIssueCode.malformedId, 'beatId không hợp lệ: $beatId', beatIndex: index));
  }

  final Map<String, BoardBeatCopy> copy = <String, BoardBeatCopy>{};
  final Object? copyRaw = raw['copy'];
  if (copyRaw is! Map<String, dynamic>) {
    issues.add(BoardIssue(BoardIssueCode.missingCopy, 'beat thiếu bảng copy', beatIndex: index));
  } else {
    for (final String locale in requiredLocales) {
      final Object? entry = copyRaw[locale];
      if (entry is! Map<String, dynamic>) {
        issues.add(BoardIssue(BoardIssueCode.missingCopy, 'thiếu copy cho locale $locale', beatIndex: index));
        continue;
      }
      final BoardBeatCopy parsed = BoardBeatCopy(
        title: _str(entry['title']),
        say: _str(entry['say']),
        caption: _str(entry['caption']),
        altText: _str(entry['altText']),
      );
      for (final String field in <String>['title', 'say', 'caption', 'altText']) {
        final int length = _str(entry[field]).runes.length;
        if (length > BoardLimits.maxCopyField) {
          issues.add(BoardIssue(
            BoardIssueCode.copyTooLong,
            '$field dài $length code point vượt ${BoardLimits.maxCopyField}',
            beatIndex: index,
          ));
        }
      }
      if (parsed.altText.trim().isEmpty) {
        issues.add(BoardIssue(BoardIssueCode.missingAltText, 'altText rỗng', beatIndex: index));
      } else if (RegExp(r'^(ảnh|hình|image|illustration|graphic)(\s*minh\s*h[ọo]a)?\.?$', caseSensitive: false)
          .hasMatch(parsed.altText.trim())) {
        // rev 4 §D4: không được lấy nhãn chung làm altText.
        issues.add(BoardIssue(BoardIssueCode.genericAltText, 'altText chỉ là nhãn chung', beatIndex: index));
      }
      copy[locale] = parsed;
    }
  }

  BoardOutputScope scope = BoardOutputScope.singleStatement;
  final Object? scopeRaw = raw['outputScope'];
  if (scopeRaw != null) {
    final BoardOutputScope? parsed = BoardOutputScope.fromWire(_str(scopeRaw));
    if (parsed == null) {
      issues.add(BoardIssue(BoardIssueCode.invalidJson, 'outputScope lạ: $scopeRaw', beatIndex: index));
    } else {
      scope = parsed;
    }
  }

  final Object? opsRaw = raw['ops'];
  if (opsRaw is! List<dynamic>) {
    issues.add(BoardIssue(BoardIssueCode.invalidJson, 'ops phải là mảng', beatIndex: index));
    return null;
  }
  if (opsRaw.length > BoardLimits.maxOpsPerBeat) {
    issues.add(BoardIssue(
      BoardIssueCode.tooManyOps,
      '${opsRaw.length} ops vượt trần ${BoardLimits.maxOpsPerBeat}',
      beatIndex: index,
    ));
  }

  final List<BoardOp> ops = <BoardOp>[];
  int tokenGroups = 0;
  int shapes = 0;
  int connectors = 0;
  for (int i = 0; i < opsRaw.length; i++) {
    final Object? opRaw = opsRaw[i];
    if (opRaw is! Map<String, dynamic>) {
      issues.add(BoardIssue(BoardIssueCode.invalidJson, 'op không phải object', beatIndex: index, opIndex: i));
      continue;
    }
    final BoardOp? op = _decodeOp(
      opRaw,
      beatIndex: index,
      opIndex: i,
      issues: issues,
      registeredObjects: registeredObjects,
    );
    if (op == null) continue;
    switch (op.kind) {
      case BoardOpKind.tokenGroup:
        tokenGroups++;
        if (op.tokenIds.length > BoardLimits.maxTokensPerGroup) {
          issues.add(BoardIssue(
            BoardIssueCode.tooManyTokens,
            '${op.tokenIds.length} token vượt ${BoardLimits.maxTokensPerGroup}',
            beatIndex: index,
            opIndex: i,
          ));
        }
      case BoardOpKind.simpleShape:
        shapes++;
      case BoardOpKind.connector:
        connectors++;
      default:
        break;
    }
    ops.add(op);
  }
  if (tokenGroups > BoardLimits.maxTokenGroups) {
    issues.add(BoardIssue(
      BoardIssueCode.tooManyTokens,
      '$tokenGroups tokenGroup vượt ${BoardLimits.maxTokenGroups}',
      beatIndex: index,
    ));
  }
  if (shapes > BoardLimits.maxShapes) {
    issues.add(BoardIssue(BoardIssueCode.tooManyShapes, '$shapes shape vượt ${BoardLimits.maxShapes}',
        beatIndex: index));
  }
  if (connectors > BoardLimits.maxConnectors) {
    issues.add(BoardIssue(BoardIssueCode.tooManyConnectors, '$connectors connector vượt ${BoardLimits.maxConnectors}',
        beatIndex: index));
  }

  final List<String> objectIds = (raw['objectIds'] as List<dynamic>?)
          ?.map((Object? e) => '$e')
          .toList(growable: false) ??
      const <String>[];
  for (final String id in objectIds) {
    if (!registeredObjects.contains(id)) {
      issues.add(BoardIssue(BoardIssueCode.unknownObject, 'beat tham chiếu object chưa đăng ký: $id',
          beatIndex: index));
    }
  }

  if (issues.isNotEmpty) return null;
  return BoardBeat(
    beatId: beatId,
    copy: copy,
    ops: ops,
    waitForLearner: raw['waitForLearner'] == true,
    sourceStatement: raw['sourceStatement'] == null ? null : _str(raw['sourceStatement']),
    outputScope: scope,
    objectIds: objectIds,
  );
}

BoardOp? _decodeOp(
  Map<String, dynamic> raw, {
  required int beatIndex,
  required int opIndex,
  required List<BoardIssue> issues,
  required List<String> registeredObjects,
}) {
  final String kindWire = _str(raw['type']);
  final BoardOpKind? kind = BoardOpKind.fromWire(kindWire);
  if (kind == null || kind == BoardOpKind.unknown) {
    issues.add(BoardIssue(BoardIssueCode.unknownOpKind, 'op type không có trong allowlist: $kindWire',
        beatIndex: beatIndex, opIndex: opIndex));
    return null;
  }
  if (raw['layer'] != null) {
    // Một op tự khai layer nghĩa là nó xin ghi/xóa lớp khác lớp Tutor.
    issues.add(BoardIssue(BoardIssueCode.layerViolation, 'op không được chọn layer: ${_str(raw['layer'])}',
        beatIndex: beatIndex, opIndex: opIndex));
    return null;
  }

  final String text = _str(raw['text']);
  final String statement = _str(raw['statement']);
  final String altText = _str(raw['altText']);
  if (text.runes.length > BoardLimits.maxOpText) {
    issues.add(BoardIssue(BoardIssueCode.copyTooLong, 'op.text dài ${text.runes.length} code point',
        beatIndex: beatIndex, opIndex: opIndex));
  }
  if (kind == BoardOpKind.codeSnippet) {
    final int lines = const LineSplitter().convert(text).length;
    if (lines > BoardLimits.maxCodeLines || text.runes.length > BoardLimits.maxCodeChars) {
      issues.add(BoardIssue(
        BoardIssueCode.tooManyCodeLines,
        'codeSnippet $lines dòng / ${text.runes.length} code point vượt trần',
        beatIndex: beatIndex,
        opIndex: opIndex,
      ));
    }
  }
  if (altText.trim().isEmpty) {
    issues.add(BoardIssue(BoardIssueCode.missingAltText, 'op thiếu altText',
        beatIndex: beatIndex, opIndex: opIndex));
  }

  final double x = _num(raw['x']), y = _num(raw['y']), width = _num(raw['width']), height = _num(raw['height']);
  for (final double value in <double>[x, y, width, height]) {
    if (value.isNaN || value.isInfinite || value < 0 || value > BoardLimits.maxGeometry) {
      issues.add(BoardIssue(BoardIssueCode.badGeometry, 'tọa độ $value ngoài 0..1',
          beatIndex: beatIndex, opIndex: opIndex));
      break;
    }
  }

  final List<String> tokenIds = (raw['tokenIds'] as List<dynamic>?)
          ?.map((Object? e) => '$e')
          .toList(growable: false) ??
      const <String>[];

  // Mọi id mà op tham chiếu phải nằm trong danh sách lesson đã đăng ký: một id "tự đặt"
  // sẽ render thành hình vẽ không nghĩa, và reviewer không còn cách nào phát hiện.
  final List<String?> referenced = <String?>[
    if (raw['objectId'] != null) _str(raw['objectId']),
    if (raw['fromId'] != null) _str(raw['fromId']),
    if (raw['toId'] != null) _str(raw['toId']),
    ...tokenIds,
  ];
  for (final String? id in referenced) {
    if (id == null) continue;
    if (!_idPattern.hasMatch(id)) {
      issues.add(BoardIssue(BoardIssueCode.malformedId, 'id không hợp lệ: $id',
          beatIndex: beatIndex, opIndex: opIndex));
      continue;
    }
    if (!registeredObjects.contains(id)) {
      issues.add(BoardIssue(BoardIssueCode.unknownObject, 'op tham chiếu object chưa đăng ký: $id',
          beatIndex: beatIndex, opIndex: opIndex));
    }
  }
  if (kind == BoardOpKind.highlightToken || kind == BoardOpKind.highlightLine) {
    if (statement.trim().isEmpty) {
      issues.add(BoardIssue(BoardIssueCode.outputWithoutStatement, 'highlight không nêu statement nguồn',
          beatIndex: beatIndex, opIndex: opIndex));
    }
  }

  return BoardOp(
    kind: kind,
    altText: altText,
    text: text,
    statement: statement,
    objectId: raw['objectId'] == null ? null : _str(raw['objectId']),
    fromId: raw['fromId'] == null ? null : _str(raw['fromId']),
    toId: raw['toId'] == null ? null : _str(raw['toId']),
    tokenIds: tokenIds,
    shape: _str(raw['shape']),
    value: _str(raw['value']),
    x: x,
    y: y,
    width: width,
    height: height,
    line: raw['line'] is int ? (raw['line'] as int) : 1,
  );
}

void _collectBadKeys(Object? node, List<BoardIssue> issues, List<String> path) {
  if (node is Map<String, dynamic>) {
    for (final MapEntry<String, dynamic> entry in node.entries) {
      if (_forbiddenKeys.contains(entry.key)) {
        issues.add(BoardIssue(
          BoardIssueCode.foreignKey,
          'khóa ngoài hợp đồng: ' + _pathOf(path, entry.key),
        ));
      }
      final Object? value = entry.value;
      if (value is String) {
        for (final String bad in _forbiddenSubstrings) {
          if (value.contains(bad)) {
            issues.add(BoardIssue(
              BoardIssueCode.markupInText,
              'chuỗi có ' + bad + ' ở ' + _pathOf(path, entry.key),
            ));
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

/// Đường dẫn JSON cho message, để reviewer trỏ đúng chỗ hỏng.
String _pathOf(List<String> path, String key) => <String>[...path, key].join('.');

String _str(Object? value) => value is String ? value : '';

double _num(Object? value) => value is num ? value.toDouble() : 0;
