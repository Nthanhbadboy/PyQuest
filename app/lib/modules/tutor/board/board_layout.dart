/// Cấu trúc **nhìn thấy được** của bảng giảng — pure Dart, không import Flutter.
///
/// Vì sao tách tầng này: rev 7 §R7-B chê renderer "in mô tả op thay vì làm thao tác trên bảng".
/// Muốn biết bảng có thật sự tô đúng token, vẽ đủ 3 và 4 vật, nối đúng hai object và tôn trọng
/// `x/y/width/height` hay không, thì phải có một chỗ duy nhất trả ra **số đo** để cả renderer lẫn
/// test cùng đọc. Tầng này chỉ nhận/số và `String` (không `RenderBox`, không `TextPainter`), nên
/// phép toán layout chạy được trong unit test thông thường, không cần ảnh.
///
/// Hai quy tắc của tầng này:
///  * bảng là **lớp tích lũy**: op của beat trước còn trên bảng cho tới khi gặp `clearTutorLayer`;
///    đó là điều khiến beat 3 của `mq1_01_s2` nối được `print` (vẽ từ beat 1) với ô kết quả;
///  * object chỉ tồn tại trên bảng khi có op cấp hộp cho nó. `objectIds` của beat vì thế kiểm được
///    ngược: beat khai object mà không op nào vẽ nó là plan sai, không phải "thiếu hình trang trí".
library;

import 'board_models.dart';

/// Một hộp, đơn vị pixel trong không gian canvas của lớp Tutor.
class BoardRect {
  const BoardRect(this.x, this.y, this.w, this.h);

  final double x;
  final double y;
  final double w;
  final double h;

  static const BoardRect zero = BoardRect(0, 0, 0, 0);

  double get left => x;
  double get top => y;
  double get right => x + w;
  double get bottom => y + h;
  double get centerX => x + w / 2;
  double get centerY => y + h / 2;

  /// Hợp hai hộp — vùng phủ thật của một connector.
  BoardRect unite(BoardRect other) {
    final double l = left < other.left ? left : other.left;
    final double t = top < other.top ? top : other.top;
    final double r = right > other.right ? right : other.right;
    final double b = bottom > other.bottom ? bottom : other.bottom;
    return BoardRect(l, t, r - l, b - t);
  }

  /// Đổi hộp chuẩn hóa 0..1 thành pixel của canvas `width` × `height`.
  BoardRect scaled(double width, double height) =>
      BoardRect(x * width, y * height, w * width, h * height);

  @override
  String toString() =>
      'Rect(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)}, ${w.toStringAsFixed(1)}x${h.toStringAsFixed(1)})';
}

/// Điểm 2D tự khai để tầng layout không phụ thuộc `dart:ui`.
class Offset2 {
  const Offset2(this.x, this.y);

  final double x;
  final double y;
}

/// Một đoạn chữ trong dòng code. `highlighted` = nền tô sáng **thật** do `TextSpan` vẽ lên code.
class BoardRun {
  const BoardRun(this.text, {this.highlighted = false});

  final String text;
  final bool highlighted;

  @override
  String toString() => highlighted ? '[=$text]' : text;
}

enum BoardNodeKind { codeLine, prose, sample, group, shape, output }

/// Một thứ được vẽ lên bảng, kèm khóa widget và nhãn accessibility của chính nó.
class BoardNode {
  const BoardNode({
    required this.key,
    required this.kind,
    required this.beatIndex,
    required this.opIndex,
    required this.altText,
    required this.rect,
    this.norm,
    this.runs = const <BoardRun>[],
    this.chips = const <String>[],
    this.shape = '',
    this.lines = const <String>[],
    this.header = '',
  });

  final String key;
  final BoardNodeKind kind;

  /// `-1` với dòng code (thuộc panel của host, không thuộc một op nào).
  final int beatIndex;
  final int opIndex;

  /// altText **đã chọn theo locale** — phải mô tả đúng thứ đang vẽ.
  final String altText;

  final BoardRect rect;

  /// Hộp chuẩn hóa 0..1 mà op khai (chỉ có với `simpleShape`), giữ nguyên để test đối chiếu.
  final BoardRect? norm;

  /// codeLine: các đoạn chữ, đã cắt theo token được tô.
  final List<BoardRun> runs;

  /// group: id từng vật — **chỉ** dùng cho anchor/nhãn; renderer vẽ số vật, không in id.
  final List<String> chips;

  /// shape: `circle` | `rect` | `roundedRect` (đã validate theo allowlist).
  final String shape;

  /// output: các dòng kết quả nguyên văn từ reference.
  final List<String> lines;

  /// output: nhãn "Kết quả chạy" đã localize, do view đưa vào.
  final String header;

  BoardNode withRect(BoardRect next) => BoardNode(
        key: key,
        kind: kind,
        beatIndex: beatIndex,
        opIndex: opIndex,
        altText: altText,
        rect: next,
        norm: norm,
        runs: runs,
        chips: chips,
        shape: shape,
        lines: lines,
        header: header,
      );

  @override
  String toString() => '$key ${kind.name} ${chips.length}chip $rect';
}

/// Một connector giữa hai hộp đã thật sự được vẽ.
class BoardConnector {
  const BoardConnector({
    required this.key,
    required this.beatIndex,
    required this.opIndex,
    required this.altText,
    required this.fromRect,
    required this.toRect,
    required this.rect,
  });

  final String key;
  final int beatIndex;
  final int opIndex;
  final String altText;
  final BoardRect fromRect;
  final BoardRect toRect;

  /// Vùng phủ của cả mũi tên, để node semantics chiếm đúng chỗ nó vẽ.
  final BoardRect rect;


  /// Hai hộp có đứng chồng lên nhau không (case thật của bảng: dòng code ở trên, ô kết quả
  /// ở dưới). rev 7 §R8-B1: mũi tên phải **nối** hai hộp, không phải một nét ngang ở độ cao
  /// trung bình của chúng — nên hướng đi quyết định điểm cắm vào cạnh nào.
  bool get isVertical => toRect.top >= fromRect.bottom - 0.5 || toRect.bottom <= fromRect.top + 0.5;

  /// Điểm đầu nằm trên cạnh của hộp nguồn, điểm có mũi tên nằm trên cạnh hộp đích.
  Offset2 get start {
    if (!isVertical) return Offset2(fromRect.right, fromRect.centerY);
    return toRect.top >= fromRect.bottom
        ? Offset2(fromRect.centerX, fromRect.bottom)
        : Offset2(fromRect.centerX, fromRect.top);
  }

  Offset2 get end {
    if (!isVertical) return Offset2(toRect.left, toRect.centerY);
    return toRect.top >= fromRect.bottom
        ? Offset2(toRect.centerX, toRect.top)
        : Offset2(toRect.centerX, toRect.bottom);
  }

  /// Hướng đi tới của nét bút, để mũ mũi tên quay đúng chiều (xuống khi đích ở dưới, sang
  /// phải khi đích ở bên phải). Mũ tên vẽ từ vector này nên không có chuyện đầu tên luôn hướng
  /// trái như bản cũ.
  Offset2 get headDirection => isVertical
      ? Offset2(0, end.y >= start.y ? 1.0 : -1.0)
      : Offset2(end.x >= start.x ? 1.0 : -1.0, 0);

  @override
  String toString() => '$key $fromRect -> $toRect';
}

/// Op còn trên bảng, kèm vị trí gốc để đặt khóa và chỉ điểm khi debug.
class BoardVisibleOp {
  const BoardVisibleOp({required this.beatIndex, required this.opIndex, required this.op});

  final int beatIndex;
  final int opIndex;
  final BoardOp op;
}

/// Lớp Tutor **tích lũy** tới hết `beatIndex`. `clearTutorLayer` xóa mọi thứ đã xếp trước nó —
/// kể cả của beat trước, vì đó là lúc thầy lau bảng. Chỗ này là định nghĩa duy nhất của
/// "cái gì còn trên bảng": validator, renderer và test đều đọc từ đây.
List<BoardVisibleOp> visibleOpsThrough(TeachingPlan plan, int beatIndex) {
  final List<BoardVisibleOp> out = <BoardVisibleOp>[];
  if (plan.beats.isEmpty) return out;
  final int last = beatIndex < 0
      ? 0
      : (beatIndex >= plan.beats.length ? plan.beats.length - 1 : beatIndex);
  for (int b = 0; b <= last; b++) {
    final List<BoardOp> ops = plan.beats[b].ops;
    for (int i = 0; i < ops.length; i++) {
      final BoardOp op = ops[i];
      if (op.kind == BoardOpKind.clearTutorLayer) {
        out.clear();
        continue;
      }
      out.add(BoardVisibleOp(beatIndex: b, opIndex: i, op: op));
    }
  }
  return out;
}

/// Những object mà các op đang vẽ trên bảng — để validator đòi `objectIds` ⊆ tập này
/// (rev 7 §R7-B: bảng phải thật sự có thứ mà beat tuyên bố).
Set<String> drawnObjectIds(List<BoardVisibleOp> visible) {
  final Set<String> out = <String>{};
  for (final BoardVisibleOp entry in visible) {
    final BoardOp op = entry.op;
    final String? id = op.objectId;
    if (id != null) out.add(id);
    out.addAll(op.tokenIds);
  }
  return out;
}

/// Layout của một beat: danh sách node vẽ được + anchor theo objectId + connector đã giải mã.
class BoardLayout {
  BoardLayout._({
    required this.nodes,
    required this.anchors,
    required this.connectors,
    required this.height,
    required this.panelHeight,
    required this.codeLines,
  });

  factory BoardLayout.build({
    required List<BoardVisibleOp> visible,
    required String codeText,
    required double width,
    required double lineHeight,
    required String Function(BoardOp op) altOf,
    required String Function(BoardOp op) proseOf,
    required String outputHeader,
    double Function(String text)? codeWidthOf,
    double Function(String text, double maxWidth)? proseHeightOf,
  }) {
    final List<String> codeLines =
        codeText.trim().isEmpty ? _statementUnion(visible) : codeText.split('\n');
    const double gutter = 8;
    const double boxChrome = 6;
    final double inner = width < 40 ? width : width - gutter * 2;
    final List<BoardNode> nodes = <BoardNode>[];
    final Map<String, BoardRect> anchors = <String, BoardRect>{};

    // Hai số đo này là chỗ duy nhất tầng layout biết về font. View truyền số đo THẬT
    // (`TextPainter` trên đúng `TextStyle` sẽ vẽ); test pure Dart dùng ước lượng để
    // arithmetic trong test không phụ thuộc font.
    final double Function(String) widthOf =
        codeWidthOf ?? ((String t) => t.runes.length * lineHeight * 0.44);
    final double Function(String, double) proseHeight = proseHeightOf ??
        ((String t, double w) {
          final double perLine = w / (lineHeight * 0.46);
          final int lines = (t.runes.length / (perLine < 8 ? 8 : perLine)).ceil();
          return (lines < 1 ? 1 : lines) * lineHeight + 4;
        });
    // `FittedBox(fit: scaleDown)` co chữ lại khi dòng dài hơn bảng; anchor và nền tô
    // phải nhân cùng hệ số, nếu không là "tô một chỗ, neo một nẻo".
    double fitOf(int line) {
      final double natural = widthOf(codeLines[line]);
      return natural <= inner ? 1.0 : inner / natural;
    }
    double xOf(int line, int runeIndex) {
      final double fit = fitOf(line);
      return gutter + widthOf(codeLines[line].substring(0, runeIndex)) * fit;
    }
    BoardRect tokenRect(int line, int start, int end) {
      final double fit = fitOf(line);
      final double x = xOf(line, start);
      final double w = widthOf(codeLines[line].substring(start, end)) * fit;
      return BoardRect(x, nodes[line].rect.y, w < 1 ? 1 : w, nodes[line].rect.h);
    }

    // 1) Bảng code: mỗi dòng một node. Dòng code là **nội dung thật**, không phải mô tả.
    //    Đánh dấu tô sáng được ghi bằng `List<bool>` theo ký tự, không thay chuỗi: nhiều op
    //    highlight trên cùng một dòng phải **cộng dồn** (bảng tích lũy), và hợp nhất đoạn chồng
    //    nhau ở bước dựng `runs` nên không thể mất ký tự nào.
    final List<List<bool>> marks = <List<bool>>[
      for (final String line in codeLines) List<bool>.filled(line.length, false),
    ];
    double y = 0;
    for (int i = 0; i < codeLines.length; i++) {
      nodes.add(BoardNode(
        key: 'board_code_line_$i',
        kind: BoardNodeKind.codeLine,
        beatIndex: -1,
        opIndex: -1,
        altText: '',
        rect: BoardRect(gutter, y, inner, lineHeight),
      ));
      y += lineHeight;
    }
    final double panelHeight = y;

    // 2) Tô sáng thật lên đúng dòng/đoạn, rồi neo object vào hộp vừa tô.
    for (final BoardVisibleOp entry in visible) {
      final BoardOp op = entry.op;
      if (op.kind != BoardOpKind.highlightToken && op.kind != BoardOpKind.highlightLine) continue;
      // Rev 7 §R8-B3: phạm vi tô là **đúng các dòng của statement được chỉ định**, không phải
      // "mọi dòng từ đó trở đi". Host không chứa statement thì không tô đâu cả — beat khai
      // object cho phần tô đó sẽ bị `unanchoredObject` chặn, chứ không phải vẽ bừa.
      final int firstLine = _statementStart(codeLines, op.statement);
      if (firstLine < 0) continue;
      final int stmtLines = op.statement.split('\n').length;
      final int lastLine = firstLine + stmtLines - 1;
      if (op.kind == BoardOpKind.highlightLine) {
        final int at = firstLine + op.line - 1;
        if (at < firstLine || at > lastLine || at >= marks.length) continue;
        _markRange(marks[at], 0, codeLines[at].length);
        if (op.objectId != null) anchors[op.objectId!] = nodes[at].rect;
        continue;
      }
      // (dòng, start, end) của từng lần xuất hiện, theo thứ tự đọc.
      final List<List<int>> hits = <List<int>>[];
      for (int line = firstLine; line <= lastLine && line < marks.length; line++) {
        int at = 0;
        while (op.token.isNotEmpty) {
          final int found = codeLines[line].indexOf(op.token, at);
          if (found < 0) break;
          _markRange(marks[line], found, found + op.token.length);
          hits.add(<int>[line, found, found + op.token.length]);
          at = found + op.token.length;
        }
      }
      if (op.objectId != null && hits.isNotEmpty) {
        final List<int> first = hits.first;
        anchors[op.objectId!] = tokenRect(first[0], first[1], first[2]);
      }
      for (int k = 0; k < op.tokenIds.length; k++) {
        // Mỗi lần xuất hiện một object: `quote-open` là dấu ngoặc đầu, `quote-close` dấu sau,
        // nên hai anchor phải là hai đoạn khác nhau trên cùng một dòng.
        if (hits.isEmpty) break;
        final List<int> hit = k < hits.length ? hits[k] : hits.last;
        anchors[op.tokenIds[k]] = tokenRect(hit[0], hit[1], hit[2]);
      }
    }

    // 2b) Dựng runs từ mask: ký tự được đánh dấu -> đoạn `highlighted`.
    for (int line = 0; line < marks.length; line++) {
      nodes[line] = nodes[line].copyRuns(_runsOf(codeLines[line], marks[line]));
    }

    // 3) Nhóm vật / hình / chữ / ô kết quả, xếp dưới bảng code.
    double cursor = panelHeight + 10;
    for (final BoardVisibleOp entry in visible) {
      final BoardOp op = entry.op;
      final String suffix = '${entry.beatIndex}_${entry.opIndex}';
      switch (op.kind) {
        case BoardOpKind.tokenGroup:
          const double chip = chipSize;
          const double gap = chipGap;
          final double rowW = op.tokenIds.length * (chip + gap);
          nodes.add(BoardNode(
            key: 'board_group_$suffix',
            kind: BoardNodeKind.group,
            beatIndex: entry.beatIndex,
            opIndex: entry.opIndex,
            altText: altOf(op),
            // Không kẹp `rowW` vào `inner`: làm vậy là để hộp widget và số đo anchor lệch nhau.
            // 12 vật (trần hợp đồng) luôn nhỏ hơn bảng hẹp nhất mà test dựng, và `Stack` ở đây
            // `clipBehavior: Clip.none` nên thậm chí vẽ tràn cũng không cắt mất nội dung.
            rect: BoardRect(gutter, cursor, rowW, chip),
            chips: op.tokenIds,
          ));
          for (int k = 0; k < op.tokenIds.length; k++) {
            anchors[op.tokenIds[k]] = BoardRect(gutter + k * (chip + gap), cursor, chip, chip);
          }
          cursor += chip + 10;
        case BoardOpKind.simpleShape:
          // Hình theo đúng `x/y/width/height` của op, chuẩn hóa trên **cả canvas** — nên hộp
          // pixel chỉ chốt được sau khi biết chiều cao canvas (pass 2 ở dưới).
          nodes.add(BoardNode(
            key: 'board_shape_$suffix',
            kind: BoardNodeKind.shape,
            beatIndex: entry.beatIndex,
            opIndex: entry.opIndex,
            altText: altOf(op),
            rect: BoardRect.zero,
            norm: BoardRect(op.x, op.y, op.width, op.height),
            shape: op.shape,
          ));
          cursor += lineHeight * 1.5;
        case BoardOpKind.text:
          // Rev 7 §R8-C: chiều cao hộp chữ là số đo font THẬT của đoạn chữ ở bề rộng thật,
          // không phải "4 dòng cho chắc" — 600 code point mà đặt 4 dòng thì RenderBox overflow,
          // tức là ảnh nghiệm thu thành dải chữ bị cắt.
          final String prose = proseOf(op);
          final double proseH = proseHeight(prose, inner);
          nodes.add(BoardNode(
            key: 'board_prose_$suffix',
            kind: BoardNodeKind.prose,
            beatIndex: entry.beatIndex,
            opIndex: entry.opIndex,
            altText: altOf(op),
            rect: BoardRect(gutter, cursor, inner, proseH),
            lines: <String>[prose],
          ));
          cursor += proseH + 6;
        case BoardOpKind.output:
          final List<String> lines = op.value.split('\n');
          // Nhãn header = `lineHeight * 0.85` (view đặt `fontSize 0.85` với `height 1.35`, tức
          // cùng đơn vị dòng) và hộp có padding 2+2 + border 1+1 = `boxChrome`. Bỏ số hạng nào
          // trong hai số đó là hộp thấp hơn nội dung: đúng cái bẫy mà ca `codeSnippet` đã trả giá
          // ở run 4a2a582 — và lần này là overflow thật, không phải assertion sai.
          final double h = lines.length * lineHeight + lineHeight * 0.85 + boxChrome;
          final BoardRect box = BoardRect(gutter, cursor, inner, h);
          nodes.add(BoardNode(
            key: 'board_output_$suffix',
            kind: BoardNodeKind.output,
            beatIndex: entry.beatIndex,
            opIndex: entry.opIndex,
            altText: altOf(op),
            rect: box,
            lines: lines,
            header: outputHeader,
          ));
          if (op.objectId != null) anchors[op.objectId!] = box;
          cursor += h + 10;
        case BoardOpKind.codeSnippet:
          // `codeSnippet` là Code của beat, không phải lời kể. Nếu dòng đó chưa có trên bảng
          // (ví dụ câu lệnh mẫu trẻ sắp gõ) thì vẽ thành block code riêng, font code — chứ
          // không được bỏ trống rồi để caption kể lại.
          final List<String> snippet = proseOf(op).split('\n');
          if (snippet.any((String l) => !codeLines.contains(l))) {
            nodes.add(BoardNode(
              key: 'board_code_snippet_$suffix',
              kind: BoardNodeKind.sample,
              beatIndex: entry.beatIndex,
              opIndex: entry.opIndex,
              altText: altOf(op),
              rect: BoardRect(gutter, cursor, inner, snippet.length * lineHeight + boxChrome),
              lines: snippet,
              runs: <BoardRun>[for (final String l in snippet) BoardRun(l)],
            ));
            cursor += snippet.length * lineHeight + boxChrome + 8;
          }
        case BoardOpKind.highlightToken:
        case BoardOpKind.highlightLine:
        case BoardOpKind.connector:
        case BoardOpKind.clearTutorLayer:
        case BoardOpKind.unknown:
          break;
      }
    }

    final double height = cursor < panelHeight + 24 ? panelHeight + 24 : cursor;

    // 3b) Hình: giờ mới đổi chuẩn hóa 0..1 sang pixel của canvas.
    for (int i = 0; i < nodes.length; i++) {
      final BoardNode node = nodes[i];
      if (node.kind != BoardNodeKind.shape) continue;
      final BoardRect box = node.norm!.scaled(width, height);
      nodes[i] = node.withRect(box);
      final BoardOp op = _opAt(visible, node);
      if (op.objectId != null) anchors[op.objectId!] = box;
    }

    // 4) Connector: chỉ nối hai hộp đã có trên bảng.
    final List<BoardConnector> connectors = <BoardConnector>[];
    for (final BoardVisibleOp entry in visible) {
      final BoardOp op = entry.op;
      if (op.kind != BoardOpKind.connector) continue;
      final BoardRect? from = op.fromId == null ? null : anchors[op.fromId!];
      final BoardRect? to = op.toId == null ? null : anchors[op.toId!];
      if (from == null || to == null) continue;
      connectors.add(BoardConnector(
        key: 'board_connector_${entry.beatIndex}_${entry.opIndex}',
        beatIndex: entry.beatIndex,
        opIndex: entry.opIndex,
        altText: altOf(op),
        fromRect: from,
        toRect: to,
        rect: from.unite(to),
      ));
    }

    return BoardLayout._(
      nodes: nodes,
      anchors: anchors,
      connectors: connectors,
      height: height,
      panelHeight: panelHeight,
      codeLines: codeLines,
    );
  }

  final List<BoardNode> nodes;

  /// objectId -> hộp thật sự đang vẽ object đó.
  final Map<String, BoardRect> anchors;
  final List<BoardConnector> connectors;
  final double height;
  final double panelHeight;
  final List<String> codeLines;

  /// Một vật trong `tokenGroup`: 18px ô + 6px kẽ. 12 vật (trần hợp đồng) = 288px, vẫn nằm
  /// trong bảng 360px trừ hai lần gutter — nên không cần kẹp bề rộng hàng và làm lệch anchor.
  static const double chipSize = 18;
  static const double chipGap = 6;

  static BoardOp _opAt(List<BoardVisibleOp> visible, BoardNode node) {
    for (final BoardVisibleOp entry in visible) {
      if (entry.beatIndex == node.beatIndex && entry.opIndex == node.opIndex) return entry.op;
    }
    return const BoardOp(kind: BoardOpKind.unknown, altTexts: <String, String>{});
  }

  static List<String> _statementUnion(List<BoardVisibleOp> visible) {
    final List<String> out = <String>[];
    for (final BoardVisibleOp entry in visible) {
      final String s = entry.op.statement;
      if (s.trim().isEmpty) continue;
      for (final String line in s.split('\n')) {
        if (!out.contains(line)) out.add(line);
      }
    }
    return out;
  }

  /// Dòng đầu tiên trong panel khớp với dòng đầu của `statement`; `-1` khi không khớp.
  static int _statementStart(List<String> codeLines, String statement) {
    final String trimmed = statement.trim();
    if (trimmed.isEmpty) return -1;
    final String first = trimmed.split('\n').first.trim();
    for (int i = 0; i < codeLines.length; i++) {
      if (codeLines[i].trim() == first) return i;
    }
    return -1;
  }

  static void _markRange(List<bool> marks, int from, int to) {
    for (int i = from; i < to && i < marks.length; i++) {
      marks[i] = true;
    }
  }

  /// Chia dòng thành các đoạn liên tiếp cùng trạng thái tô sáng. Không có nhánh nào bỏ ký tự:
  /// `join(runs.text) == line` là bất biến mà test đọc trực tiếp.
  static List<BoardRun> _runsOf(String line, List<bool> marks) {
    if (line.isEmpty) return const <BoardRun>[BoardRun('')];
    final List<BoardRun> out = <BoardRun>[];
    int start = 0;
    bool state = marks[0];
    for (int i = 1; i < line.length; i++) {
      if (marks[i] != state) {
        out.add(BoardRun(line.substring(start, i), highlighted: state));
        start = i;
        state = marks[i];
      }
    }
    out.add(BoardRun(line.substring(start), highlighted: state));
    return out;
  }

}

extension on BoardNode {
  BoardNode copyRuns(List<BoardRun> next) => BoardNode(
        key: key,
        kind: kind,
        beatIndex: beatIndex,
        opIndex: opIndex,
        altText: altText,
        rect: rect,
        norm: norm,
        runs: next,
        chips: chips,
        shape: shape,
        lines: lines,
        header: header,
      );
}
