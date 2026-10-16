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
    super.key,
  });

  final BoardController controller;
  final BoardLabels? labels;

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
                  beat: beat,
                  copy: copy,
                  labels: labels,
                  locale: controller.locale,
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

class _TutorLayer extends StatelessWidget {
  const _TutorLayer({
    required this.beat,
    required this.copy,
    required this.labels,
    required this.locale,
  });

  final BoardBeat beat;
  final BoardBeatCopy? copy;
  final BoardLabels labels;

  /// Locale đang hiển thị, do [BoardView] lấy từ controller trong builder đang rebuild.
  final String locale;

  @override
  Widget build(BuildContext context) {
    // `clearTutorLayer` chỉ có hiệu lực trong lớp Tutor, và bị cắt ngay tại chỗ nó xuất hiện:
    // op nào đứng trước bị bỏ, op đứng sau còn nguyên. Không có đường nào chạm layer khác.
    final List<Widget> children = <Widget>[];
    final List<BoardOp> visible = <BoardOp>[];
    for (final BoardOp op in beat.ops) {
      if (op.kind == BoardOpKind.clearTutorLayer) {
        visible.clear();
        continue;
      }
      visible.add(op);
    }
    for (int i = 0; i < visible.length; i++) {
      children.add(_opWidget(visible[i], i, locale));
    }
    return Semantics(
      container: true,
      label: copy?.altText ?? '',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (copy != null) ...<Widget>[
            Text(copy!.title, key: const ValueKey<String>('board_title')),
            Text(copy!.say, key: const ValueKey<String>('board_say')),
            Text(copy!.caption, key: const ValueKey<String>('board_caption')),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _opWidget(BoardOp op, int index, String locale) {
    final Key key = ValueKey<String>('board_op_${op.kind.wire}_$index');
    switch (op.kind) {
      case BoardOpKind.text:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Semantics(label: op.altFor(locale), child: Text(op.proseFor(locale), key: key)),
        );
      case BoardOpKind.codeSnippet:
        return Semantics(
          label: op.altFor(locale),
          child: Container(
            key: key,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0x11000000),
              border: Border.all(color: const Color(0x33000000)),
            ),
            child: Text(op.proseFor(locale), style: const TextStyle(fontFamily: 'monospace')),
          ),
        );
      case BoardOpKind.highlightToken:
      case BoardOpKind.highlightLine:
        return Semantics(
          label: op.altFor(locale),
          child: Text(
            '→ ${op.statement.isEmpty ? op.proseFor(locale) : op.statement}',
            key: key,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      case BoardOpKind.output:
        return Semantics(
          label: '${labels.outputLabel}: ${op.value}',
          child: Container(
            key: key,
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(border: Border.all(color: const Color(0x66000000))),
            child: Text('${labels.outputLabel}\n${op.value}'),
          ),
        );
      case BoardOpKind.tokenGroup:
        return Wrap(
          key: key,
          spacing: 4,
          children: <Widget>[
            for (final String token in op.tokenIds)
              Semantics(label: op.altFor(locale), child: Text('[$token]')),
          ],
        );
      case BoardOpKind.simpleShape:
        return Semantics(
          label: op.altFor(locale),
          child: Container(
            key: key,
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x66000000)),
              shape: op.shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
            ),
          ),
        );
      case BoardOpKind.connector:
        return Semantics(
          label: op.altFor(locale),
          child: Text('↔ ${op.fromId ?? ''} → ${op.toId ?? ''}', key: key),
        );
      case BoardOpKind.clearTutorLayer:
      case BoardOpKind.unknown:
        return const SizedBox.shrink();
    }
  }
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
