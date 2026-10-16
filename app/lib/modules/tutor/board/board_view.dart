/// Renderer của bảng giảng — **chỉ hiển thị**.
///
/// Chủ ý thiết kế cho slice `PQC-010`:
///  * không animation ngầm, không `Timer`, không `Future.delayed`: vì board không tự chạy,
///    yêu cầu "calmMode/reduced-motion bỏ chuyển động nhưng **không** skip nội dung" (rev 4 §D3)
///    được thỏa bằng cấu trúc, và `BoardController.reduceMotion` chỉ còn là cờ cho host tương lai;
///  * mọi chuỗi được vẽ bằng `Text` nguyên văn — không HTML/SVG/markup, kể cả khi chuỗi chứa `<`;
///  * ba layer tách quyền nhìn thấy được ngay trong cây: scaffold / tutor / learner;
///  * control ≥ 48 logical px, có `Semantics` và focus traversal.
library;

import 'package:flutter/material.dart';

import 'board_controller.dart';
import 'board_layout.dart';
import 'board_models.dart';

/// Nhãn của board. Host tương lai lấy từ pack của `PQC-016`; ở slice này board tự có nhãn
/// để test độc lập với phần còn lại của app (và **không** hardcode mọi bài thành một nhân vật).
class BoardLabels {
  const BoardLabels({
    required this.fallbacks,
    required this.previous,
    required this.next,
    required this.replay,
    required this.waiting,
    required this.ink,
    required this.undo,
    required this.clearInk,
    required this.noteHint,
    required this.outputLabel,
    required this.fallbackPrefix,
  });

  static const BoardLabels vi = BoardLabels(
    fallbacks: _viFallback,
    previous: 'Trước',
    next: 'Tiếp',
    replay: 'Xem lại từ đầu',
    waiting: 'Đến lượt con. Bảng sẽ chờ.',
    ink: 'Nét của con',
    undo: 'Hoàn tác nét',
    clearInk: 'Xóa nét của con',
    noteHint: 'Ghi chú của con',
    outputLabel: 'Kết quả chạy',
    fallbackPrefix: 'Bảng soạn sẵn',
  );

  /// Ba câu fallback, theo locale. Rev 7 §R7-C: controller giữ **mã** lỗi, còn câu chữ nằm ở
  /// bảng nhãn này, nên một lỗi sinh ra trước khi đổi ngôn ngữ vẫn được đọc bằng ngôn ngữ
  /// hiện hành thay vì treo câu tiếng cũ.
  static const Map<BoardFallbackReason, String> _viFallback = <BoardFallbackReason, String>{
    BoardFallbackReason.staleReply:
        'Trợ giảng đang soạn cho bước khác, nên bảng giữ nguyên bước này.',
    BoardFallbackReason.rejectedPlan:
        'Bảng tác giả không hợp lệ nên thầy dùng bước cũ. Đây là nội dung soạn sẵn, không phải AI.',
    BoardFallbackReason.foreignLesson:
        'Bảng nhận được thuộc về bài khác nên bị chặn; bảng đang hiển thị không bị ghi đè.',
  };

  static const Map<BoardFallbackReason, String> _enFallback = <BoardFallbackReason, String>{
    BoardFallbackReason.staleReply:
        'The tutor was answering an older step, so the board stayed on this step.',
    BoardFallbackReason.rejectedPlan:
        'The authored board was rejected, so the previous step stays. This is authored content, not AI.',
    BoardFallbackReason.foreignLesson:
        'A board for another lesson was blocked; what is on the board was not overwritten.',
  };

  static const BoardLabels en = BoardLabels(
    fallbacks: _enFallback,
    previous: 'Back',
    next: 'Next',
    replay: 'Replay from start',
    waiting: 'Your turn. The board will wait.',
    ink: 'Your ink',
    undo: 'Undo stroke',
    clearInk: 'Clear my ink',
    noteHint: 'Your note',
    outputLabel: 'Run output',
    fallbackPrefix: 'Authored board',
  );

  static BoardLabels of(String locale) => locale.startsWith('vi') ? vi : en;

  /// Câu fallback đầy đủ cho một mã lý do; `null` khi không có fallback.
  String? fallbackFor(BoardFallbackReason? reason) =>
      reason == null ? null : fallbacks[reason];

  /// Bảng câu fallback của **chính locale này** — không suy ra bằng cách so `this == vi`,
  /// vì host tương lai có thể truyền một bảng nhãn riêng.
  final Map<BoardFallbackReason, String> fallbacks;

  final String previous;
  final String next;
  final String replay;
  final String waiting;
  final String ink;
  final String undo;
  final String clearInk;
  final String noteHint;
  final String outputLabel;
  final String fallbackPrefix;
}

class BoardView extends StatelessWidget {
  const BoardView({
    required this.controller,
    this.labels,
    this.codeText = '',
    super.key,
  });

  final BoardController controller;
  final BoardLabels? labels;

  /// Code của bước đang học — host đưa vào để bảng **tô lên code thật** thay vì mô tả nó
  /// (rev 7 §R7-B). Board không chạy code, không đọc file, không nhận URL/markup.
  final String codeText;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[controller, controller.learner]),
      builder: (BuildContext context, Widget? child) {
        // Rev 7 §R7-C: **mọi** thứ phụ thuộc locale phải resolve bên trong builder đang nghe
        // controller. Tính `labels` ở ngoài thì `setLocale` chỉ rebuild subtree trong, còn nhãn
        // điều khiển / ô kết quả vẫn là tiếng cũ khi host không dựng lại parent.
        final BoardLabels labels = this.labels ?? BoardLabels.of(controller.locale);
        final String? fallbackText = labels.fallbackFor(controller.fallbackReason);
        final BoardBeat? beat = controller.currentBeat;
        final BoardBeatCopy? copy = beat?.copyFor(controller.locale);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ScaffoldLayer(
                lessonId: controller.lessonId,
                stepId: controller.stepId,
                characterId: controller.plan?.characterId ?? '',
                beatIndex: controller.beatIndex,
                beatCount: controller.beatCount,
              ),
              const SizedBox(height: 8),
              if (fallbackText != null)
                _Notice(
                  key: const ValueKey<String>('board_fallback'),
                  text: '${labels.fallbackPrefix}: $fallbackText',
                ),
              if (beat == null)
                const SizedBox(height: 8)
              else
                _TutorLayer(
                  copy: copy,
                  labels: labels,
                  locale: controller.locale,
                  plan: controller.plan!,
                  beatIndex: controller.beatIndex,
                  codeText: codeText,
                ),
              const SizedBox(height: 8),
              _LearnerLayerView(layer: controller.learner, labels: labels),
              const SizedBox(height: 12),
              if (controller.isWaitingForLearner)
                _Notice(key: const ValueKey<String>('board_waiting'), text: labels.waiting),
              BoardControls(controller: controller, labels: labels),
            ],
          ),
        );
      },
    );
  }
}

/// Hàng nút điều khiển. Tách ra widget riêng để test bắn focus/bấm mà không cần tìm trong cây.
class BoardControls extends StatelessWidget {
  const BoardControls({required this.controller, required this.labels, super.key});

  final BoardController controller;
  final BoardLabels labels;

  @override
  Widget build(BuildContext context) {
    // `Wrap` chứ không `Row`: ở 360×640 với font 2.0, một hàng ba nút dài sẽ tràn ngang;
    // Wrap giữ nguyên từng nút >= 48 px và chỉ xuống dòng — không cắt mất điều khiển.
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: <Widget>[
        _control(labels.previous, 'board_previous', controller.canGoPrevious ? controller.previous : null),
        _control(labels.replay, 'board_replay', controller.replay),
        // Nút Tiếp là **ý định của trẻ**: nó nhả `waitForLearner` rồi mới tiến (rev 7 §R7-D),
        // và bị tắt khi vừa hết beat vừa không chờ gì — không có nút.enabled mà bấm vô ích.
        _control(labels.next, 'board_next', controller.canGoNext ? controller.learnerAdvance : null),
      ],
    );
  }

  Widget _control(String label, String key, VoidCallback? onTap) {
    return Semantics(
      button: true,
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: TextButton(
          key: ValueKey<String>(key),
          onPressed: onTap,
          child: Text(label),
        ),
      ),
    );
  }
}

class _ScaffoldLayer extends StatelessWidget {
  const _ScaffoldLayer({
    required this.lessonId,
    required this.stepId,
    required this.characterId,
    required this.beatIndex,
    required this.beatCount,
  });

  final String lessonId;
  final String stepId;
  final String characterId;
  final int beatIndex;
  final int beatCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$lessonId $stepId, ${beatIndex + 1}/$beatCount',
      child: ExcludeSemantics(
        child: Text(
          '$lessonId · $stepId · ${beatIndex + 1}/$beatCount · $characterId',
          key: const ValueKey<String>('board_scaffold'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// Lớp Tutor — **vẽ** bảng, không kể lại bảng.
///
/// Rev 7 §R7-B: mọi thao tác của một bảng giảng thật phải hiện ra trên bảng, nên layer này
/// dựng từ `BoardLayout` (số đo đã tính từ plan đã validate): dòng code có đoạn được tô sáng
/// bằng `TextSpan`, nhóm vật được vẽ đúng số lượng, hình tôn trọng `x/y/width/height`, và
/// connector là mũi tên nối hai hộp đang thật sự nằm trên bảng. Chuỗi mô tả của op **không**
/// còn thế chỗ hình; nó xuống `Semantics` để reader đọc được.
class _TutorLayer extends StatelessWidget {
  const _TutorLayer({
    required this.copy,
    required this.labels,
    required this.locale,
    required this.plan,
    required this.beatIndex,
    required this.codeText,
  });

  final BoardBeatCopy? copy;
  final BoardLabels labels;
  final String locale;
  final TeachingPlan plan;
  final int beatIndex;

  /// Code của bước, do **host** đưa vào (board không tự chạy code, không tự bịa nội dung).
  final String codeText;

  static const double _copyFontSize = 15;
  static const double _codeFontSize = 13;

  @override
  Widget build(BuildContext context) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double copySize = scaler.scale(_copyFontSize);
    final double codeSize = scaler.scale(_codeFontSize);
    // `lineHeight` là số nguyên duy nhất giữa layout và chữ: mỗi dòng code chiếm đúng
    // `codeSize * 1.35`, nên hộp do layout tính và hộp do text chiếm không thể lệch nhau.
    final double lineHeight = codeSize * 1.35;
    final List<BoardVisibleOp> visible = visibleOpsThrough(plan, beatIndex);

    return Semantics(
      container: true,
      label: copy?.altText ?? '',
      child: Column(
        key: const ValueKey<String>('board_tutor_layer'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (copy != null) ...<Widget>[
            Text(copy!.title,
                key: const ValueKey<String>('board_title'),
                style: TextStyle(fontSize: copySize * 1.25, fontWeight: FontWeight.w800, height: 1.3)),
            Text(copy!.say,
                key: const ValueKey<String>('board_say'),
                style: TextStyle(fontSize: copySize, height: 1.35)),
            Text(copy!.caption,
                key: const ValueKey<String>('board_caption'),
                style: TextStyle(fontSize: copySize, fontWeight: FontWeight.w600, height: 1.35)),
          ],
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints box) {
              final double width = box.maxWidth.isFinite && box.maxWidth > 40
                  ? box.maxWidth
                  : _fallbackCanvasWidth;
              final BoardLayout layout = BoardLayout.build(
                visible: visible,
                codeText: codeText,
                width: width,
                lineHeight: lineHeight,
                altOf: (BoardOp op) => op.altFor(locale),
                proseOf: (BoardOp op) => op.proseFor(locale),
                outputHeader: labels.outputLabel,
              );
              return SizedBox(
                key: const ValueKey<String>('board_canvas'),
                width: width,
                height: layout.height,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Positioned.fill(
                      child: CustomPaint(painter: _BoardCanvasPainter(layout: layout, codeSize: codeSize)),
                    ),
                    for (final BoardNode node in layout.nodes) _nodeWidget(node, codeSize),
                    for (final BoardConnector link in layout.connectors)
                      Positioned.fromRect(
                        key: ValueKey<String>(link.key),
                        rect: _toRect(link.rect),
                        child: Semantics(label: link.altText, child: const SizedBox.shrink()),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static const double _fallbackCanvasWidth = 320;

  static Rect _toRect(BoardRect r) => Rect.fromLTWH(r.x, r.y, r.w, r.h);

  /// Một node của layout -> một hộp widget ở **đúng** chỗ layout đã tính.
  Widget _nodeWidget(BoardNode node, double codeSize) {
    final Widget body;
    switch (node.kind) {
      case BoardNodeKind.codeLine:
        body = FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: RichText(
            text: TextSpan(
              style: _codeStyle(codeSize),
              children: <InlineSpan>[
                for (final BoardRun run in node.runs)
                  TextSpan(
                    text: run.text,
                    style: run.highlighted ? _highlightStyle(codeSize) : null,
                  ),
              ],
            ),
            // Code luôn LTR; board không suy ra hướng đọc từ dữ liệu của trẻ.
            textDirection: TextDirection.ltr,
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
        );
      case BoardNodeKind.sample:
        body = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x33000000)),
            color: const Color(0x05000000),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (final BoardRun run in node.runs)
                Text(run.text,
                    style: _codeStyle(codeSize), textDirection: TextDirection.ltr, softWrap: false),
            ],
          ),
        );
      case BoardNodeKind.group:
        body = Row(
          textDirection: TextDirection.ltr,
          children: <Widget>[
            for (int k = 0; k < node.chips.length; k++)
              Padding(
                key: ValueKey<String>('${node.key}_chip_$k'),
                padding: const EdgeInsets.only(right: BoardLayout.chipGap),
                child: Container(
                  width: BoardLayout.chipSize,
                  height: BoardLayout.chipSize,
                  decoration: BoxDecoration(
                    color: const Color(0x1A000000),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x99000000), width: 1.5),
                  ),
                ),
              ),
          ],
        );
      case BoardNodeKind.shape:
        body = Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xCC1B2A4A), width: 2),
            shape: node.shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: node.shape == 'roundedRect' ? BorderRadius.circular(codeSize * 0.5) : null,
          ),
        );
      case BoardNodeKind.prose:
        body = Text(
          node.lines.isEmpty ? '' : node.lines.first,
          style: TextStyle(fontSize: codeSize, height: 1.35, color: const Color(0xE6000000)),
          softWrap: true,
        );
      case BoardNodeKind.output:
        body = Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x66000000)),
            color: const Color(0x08000000),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                node.header,
                style: TextStyle(
                    fontSize: codeSize * 0.85,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: const Color(0x99000000)),
              ),
              for (final String line in node.lines)
                Text(line,
                    style: _codeStyle(codeSize),
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    textDirection: TextDirection.ltr),
            ],
          ),
        );
    }
    return Positioned.fromRect(
      key: ValueKey<String>(node.key),
      rect: _toRect(node.rect),
      child: node.altText.isEmpty ? body : Semantics(label: node.altText, child: body),
    );
  }

  static TextStyle _codeStyle(double size) => TextStyle(
        // `PQFonts.code` — board giữ biên giới import của mình nên nhắc tên font trực tiếp;
        // font này đã có trong assets của app (pubspec), không phải dependency mới.
        fontFamily: 'JetBrainsMono',
        fontSize: size,
        height: 1,
        color: const Color(0xE6000000),
        fontWeight: FontWeight.w500,
      );

  static TextStyle _highlightStyle(double size) => TextStyle(
        backgroundColor: const Color(0x66FFC94D),
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1B2A4A),
        height: 1,
        fontSize: size,
      );
}

/// Vẽ những thứ không phải hộp widget: viền bảng code và các mũi tên connector.
class _BoardCanvasPainter extends CustomPainter {
  _BoardCanvasPainter({required this.layout, required this.codeSize});

  final BoardLayout layout;
  final double codeSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.codeLines.isNotEmpty) {
      final Paint panel = Paint()
        ..color = const Color(0x22000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(0, 0, size.width, layout.panelHeight + 6),
          Radius.circular(codeSize * 0.45),
        ),
        panel,
      );
    }
    for (final BoardConnector link in layout.connectors) {
      final Color ink = const Color(0xCC1B2A4A);
      final Paint stroke = Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      final Offset from = Offset(link.start.x, link.start.y);
      final Offset to = Offset(link.end.x, link.end.y);
      final double midX = (from.dx + to.dx) / 2;
      canvas.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..cubicTo(midX, from.dy, midX, to.dy, to.dx, to.dy),
        stroke,
      );
      final double head = codeSize * 0.55;
      canvas.drawPath(
        Path()
          ..moveTo(to.dx, to.dy)
          ..lineTo(to.dx - head, to.dy - head * 0.6)
          ..lineTo(to.dx - head, to.dy + head * 0.6)
          ..close(),
        Paint()
          ..color = ink
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_BoardCanvasPainter oldDelegate) =>
      oldDelegate.layout != layout || oldDelegate.codeSize != codeSize;
}

class _LearnerLayerView extends StatelessWidget {
  const _LearnerLayerView({required this.layer, required this.labels});

  final LearnerLayer layer;
  final BoardLabels labels;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '${labels.ink}: ${layer.strokes.length}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(labels.ink, style: const TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            key: const ValueKey<String>('board_ink'),
            spacing: 4,
            children: <Widget>[
              for (final String stroke in layer.strokes)
                Container(
                  key: ValueKey<String>('board_ink_$stroke'),
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0x66000000),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          if (layer.note.isNotEmpty) Text(layer.note, key: const ValueKey<String>('board_note_text')),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: <Widget>[
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: TextButton(
                  key: const ValueKey<String>('board_ink_undo'),
                  onPressed: layer.strokes.isEmpty ? null : layer.undoStroke,
                  child: Text(labels.undo),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: TextButton(
                  key: const ValueKey<String>('board_ink_clear'),
                  onPressed: layer.isEmpty ? null : layer.clearOwned,
                  child: Text(labels.clearInk),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: text,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0x11000000),
          border: Border.all(color: const Color(0x22000000)),
        ),
        child: Text(text),
      ),
    );
  }
}
