import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';
import 'board/board_view_test.dart' as board_view_test;

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  testWidgets('00-D1-sem-diagnostic: dump actual semantics labels at output beat',
      (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    addTearDown(handle.dispose);
    final controller = await board_view_test.pumpBoard(
      tester,
      planIndex: 1,
      locale: 'vi',
      reduceMotion: true,
      codeText: 'print(3 + 4)\nprint("3 + 4")',
    );
    while (controller.beatIndex < 2) {
      expect(controller.next() || controller.learnerAdvance(), isTrue);
      await tester.pump();
    }
    await tester.ensureVisible(find.byKey(const ValueKey<String>('board_output_2_1_label')));
    await tester.pumpAndSettle();
    final Finder allLabels = find.bySemanticsLabel(RegExp('.*'));
    final List<String> labels = <String>[];
    for (final Element element in allLabels.evaluate()) {
      if (element is RenderObjectElement) {
        labels.add(element.renderObject.debugSemantics?.label ?? '<null>');
      }
    }
    // ignore: avoid_print
    print('D1_SEMANTICS_LABELS=$labels');
    expect(labels, isNotEmpty, reason: 'semantics-enabled test host exposed no labeled nodes');
  });
}
