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
    required this.codeMismatch,
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
    codeMismatch:
        'Code trên bảng khác với phần thầy đã soạn cho bước này, nên bảng không tô sáng theo dòng. '
        'Nội dung chữ vẫn nguyên văn, chỉ có phần tô bị tắt để không chỉ sai.',
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
    codeMismatch:
        'The code on the board differs from what the authored plan describes, so line highlighting '
        'is off. The text is still verbatim; only the paint is skipped, so nothing points at the '
        'wrong line.',
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
  final String codeMismatch;
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

  /// Chiều cao engine xếp cho MỘT dòng của `style`. View và layout cùng dùng số này, nên hộp do
  /// layout tính và paragraph do renderer dựng không thể lệch nhau ở bất kỳ fontScale nào.
  static double measureLineHeight(TextStyle style) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: 'X', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final double h = painter.height;
    painter.dispose();
    return h;
  }

  static const double _copyFontSize = 15;
  static const double _codeFontSize = 13;

  @override
  Widget build(BuildContext context) {
    // rev 7 §R8-C: hệ số co chữ chỉ được áp dụng **một lần**. `Text` tự đọc `textScaler` từ
    // MediaQuery trong khi `RichText`/`TextPainter`/layout thì không, nên để nguyên thì mỗi
    // dòng code một cao độ khác nhau, scale nhân đôi (15 -> 30 -> 60) ở nhãn và hộp chữ vẫn
    // nhân một. Cách sửa: tự scale ở đây, rồi tắt kế thừa scaler cho cả subtree bên dưới.
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double copySize = scaler.scale(_copyFontSize);
    final double codeSize = scaler.scale(_codeFontSize);
    // rev 9 §R9-B3: `Text` kế thừa `fontFamily`/`color`/`height` từ `DefaultTextStyle` của host,
    // còn `TextPainter` thì KHÔNG. Đo bằng một style, vẽ bằng một style khác (r8 chỉ đưa
    // `_proseStyle` trần vào painter trong khi `Text` lại nhận font của host) là nguồn của hộp
    // "khớp số đo tưởng tượng". Resolve MỘT cặp style ở đây rồi đưa cho cả bên đo lẫn bên vẽ.
    final TextStyle base = DefaultTextStyle.of(context).style;
    final TextStyle codeStyle = base.merge(_codeStyle(codeSize));
    final TextStyle proseStyle = base.merge(_proseStyle(codeSize));
    // `lineHeight` là số nguyên duy nhất giữa layout và chữ, nhưng phải là số ĐÃ ĐO: mỗi dòng code
    // chiếm đúng chiều cao mà engine xếp cho một paragraph một dòng của `codeStyle`. Dùng
    // `codeSize * 1.35` danh nghĩa thì mọi hộp output/snippet dựng từ nó lệch đúng phần làm tròn
    // của engine — đó là chỗ `4 failure` công khai ở r9 còn treo.
    final double lineHeight = measureLineHeight(codeStyle);
    final List<BoardVisibleOp> visible = visibleOpsThrough(plan, beatIndex);

    return MediaQuery.withNoTextScaling(
      child: _buildLayer(visible, copySize, codeSize, lineHeight, codeStyle, proseStyle),
    );
  }

  Widget _buildLayer(
    List<BoardVisibleOp> visible,
    double copySize,
    double codeSize,
    double lineHeight,
    TextStyle codeStyle,
    TextStyle proseStyle,
  ) {
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

              // Số đo font THẬT, do `TextPainter` trên đúng style sẽ vẽ trả về. Layout dùng
              // nó cho bề rộng anchor của token được tô và cho chiều cao hộp chữ, nên hộp
              // widget và nền tô không thể lệch nhau ở fontScale 1.3/2.0.
              double measureCodeWidth(String text) {
                final TextPainter painter = TextPainter(
                  text: TextSpan(text: text, style: codeStyle),
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                )..layout();
                final double w = painter.width;
                painter.dispose();
                return w;
              }

              double measureProseHeight(String text, double maxWidth) {
                final TextPainter painter = TextPainter(
                  text: TextSpan(text: text, style: proseStyle),
                  textDirection: TextDirection.ltr,
                )..layout(maxWidth: maxWidth);
                final double h = painter.height;
                painter.dispose();
                return h + 4;
              }

              final BoardLayout layout = BoardLayout.build(
                visible: visible,
                codeText: codeText,
                width: width,
                lineHeight: lineHeight,
                altOf: (BoardOp op) => op.altFor(locale),
                proseOf: (BoardOp op) => op.proseFor(locale),
                outputHeader: labels.outputLabel,
                codeWidthOf: measureCodeWidth,
                proseHeightOf: measureProseHeight,
                // Dòng code dài thì xuống dòng trong hộp của nó (view đã bỏ `FittedBox`), nên chiều
                // cao hộp PHẢI đo ra; và nhãn output cũng vậy — hai chỗ này là nơi hộp và chữ từng
                // lệch nhau 6px mà test không giải thích được.
                codeHeightOf: (String text, double maxWidth) {
                  final TextPainter painter = TextPainter(
                    text: TextSpan(text: text, style: codeStyle),
                    textDirection: TextDirection.ltr,
                  )..layout(maxWidth: maxWidth);
                  final double h = painter.height;
                  painter.dispose();
                  return h;
                },
                outputHeaderHeightOf: (String text, double maxWidth) {
                  final TextPainter painter = TextPainter(
                    text: TextSpan(text: text, style: _outputHeaderStyle(codeStyle, codeSize)),
                    textDirection: TextDirection.ltr,
                  )..layout(maxWidth: maxWidth);
                  final double h = painter.height;
                  painter.dispose();
                  return h;
                },
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
                    for (final BoardNode node in layout.nodes)
                      _nodeWidget(node, codeSize, codeStyle, proseStyle),
                  // rev 9 §R9-D: plan nói tô dòng này mà host không có dòng đó -> nói thẳng ra,
                  // thay vì `continue` im lặng trong layout (mất nền tô, mất anchor, không ai giải
                  // thích được). Board vẫn hiển thị chữ nguyên văn; chỉ phần tô bị tắt.
                  if (layout.unresolvedStatements.isNotEmpty)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: _Notice(
                            key: const ValueKey<String>('board_code_mismatch'),
                            text: labels.codeMismatch,
                          ),
                        ),
                      ),
                    ),
                    for (final BoardConnector link in layout.connectors)
                      Positioned.fromRect(
                        key: ValueKey<String>(link.key),
                        rect: _toRect(link.rect),
                        child: Semantics(
                          key: ValueKey<String>('${link.key}_label'),
                          label: link.altText,
                          child: const SizedBox.shrink(),
                        ),
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
  /// Một node của layout -> một hộp widget ở **đúng** chỗ layout đã tính, và dùng **đúng cặp style
  /// đã resolve** mà bên đo đã dùng. Không nhận `DefaultTextStyle` ở đây: hai bên lệch nhau một
  /// `fontFamily` là hộp và chữ lệch nhau cả dòng.
  Widget _nodeWidget(BoardNode node, double codeSize, TextStyle codeStyle, TextStyle proseStyle) {
    final Widget body;
    switch (node.kind) {
      case BoardNodeKind.codeLine:
        // rev 9 §R9-B4: không còn `FittedBox(fit: scaleDown)`. Co chữ để vừa hộp là cách dễ nhất
        // làm test "không overflow" xanh mà lại ăn cắp cỡ chữ của trẻ; ở đây chữ giữ nguyên cỡ và
        // xuống dòng, hộp cao theo số dòng đo được (xem `codeHeightOf`).
        body = RichText(
          text: TextSpan(
            style: codeStyle,
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
          softWrap: true,
          overflow: TextOverflow.visible,
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
                    style: codeStyle, textDirection: TextDirection.ltr, softWrap: false),
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
          style: proseStyle,
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
                // `0.85` và `height: 1.35` là cặp số mà `BoardLayout` dùng cho chiều cao nhãn
                // (`lineHeight * 0.85`): khác nhau ở đây thì Column cao hơn hộp và RenderFlex báo
                // overflow dù mọi con số trong layout đều "đúng".
                // Một hàm style duy nhất cho cả đo lẫn vẽ: `outputHeaderHeightOf` ở `_buildLayer`
                // dùng đúng thể thức này, nên hộp output không thể cao hơn/thấp hơn Column của nó.
                style: _outputHeaderStyle(codeStyle, codeSize),
              ),
              for (final String line in node.lines)
                Text(line,
                    style: codeStyle,
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
      // Node `Semantics` mang key riêng: test đọc **cây semantics thật** qua
      // `tester.getSemantics(byKey('<node>_label'))` thay vì đoán từ widget properties.
      child: node.altText.isEmpty
          ? body
          : Semantics(
              key: ValueKey<String>('${node.key}_label'),
              label: node.altText,
              // rev 9 §R9-C2: `container: true` biến node này thành một ranh giới thật. Không có
              // nó, `Semantics` chỉ là một lớp properties gộp xuống node của con, và người đọc
              // nghe altText dính liền với chữ trong hộp — test so nhãn == altText sẽ đỏ vì lý do
              // không liên quan tới việc nhãn có đúng bản locale hay không.
              container: true,
              child: body,
            ),
    );
  }

  /// Style của hộp chữ op. Cùng một thể thức này được dùng để **đo** cao hộp trong layout và
  /// để **vẽ** — hai chỗ khác nhau là nguồn của overflow mà test không giải thích được.
  /// Nhãn "Kết quả chạy"/"Run output": cỡ 0.85 dòng code, cùng `height` 1.35 để
  /// `outputHeaderHeightOf` đo ra đúng cái mà Column sẽ chiếm.
  static TextStyle _outputHeaderStyle(TextStyle codeStyle, double codeSize) => codeStyle.copyWith(
        fontSize: codeSize * 0.85,
        fontWeight: FontWeight.w700,
        color: const Color(0x99000000),
      );

  static TextStyle _proseStyle(double size) => TextStyle(
        fontSize: size,
        height: 1.35,
        color: const Color(0xE6000000),
      );

  static TextStyle _codeStyle(double size) => TextStyle(
        // `PQFonts.code` — board giữ biên giới import của mình nên nhắc tên font trực tiếp;
        // font này đã có trong assets của app (pubspec), không phải dependency mới.
        fontFamily: 'JetBrainsMono',
        fontSize: size,
        // `1.35` là cùng một số với `lineHeight = codeSize * 1.35` mà layout dùng để đặt hộp:
        // khác nhau ở đây thì nền tô và ô neo lệch nhau, dù cả hai đều "không tràn".
        height: 1.35,
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
      // rev 7 §R8-B1: route phải đi từ cạnh của hộp nguồn tới cạnh hộp đích. Hai hộp của
      // bảng thường chồng nhau theo trục Y (dòng code ở trên, ô kết quả ở dưới) nên đường
      // cong phải uốn theo trục Y; uốn theo X sẽ cho một nét ngang lơ lửng giữa hai hộp.
      final Path route = Path()..moveTo(from.dx, from.dy);
      if (link.isVertical) {
        final double midY = (from.dy + to.dy) / 2;
        route.cubicTo(from.dx, midY, to.dx, midY, to.dx, to.dy);
      } else {
        final double midX = (from.dx + to.dx) / 2;
        route.cubicTo(midX, from.dy, midX, to.dy, to.dx, to.dy);
      }
      canvas.drawPath(route, stroke);
      final double head = codeSize * 0.55;
      final Offset unit = Offset(link.headDirection.x, link.headDirection.y);
      final Offset perp = Offset(-unit.dy, unit.dx);
      canvas.drawPath(
        Path()
          ..moveTo(to.dx, to.dy)
          ..lineTo(to.dx - unit.dx * head + perp.dx * head * 0.6,
              to.dy - unit.dy * head + perp.dy * head * 0.6)
          ..lineTo(to.dx - unit.dx * head - perp.dx * head * 0.6,
              to.dy - unit.dy * head - perp.dy * head * 0.6)
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
