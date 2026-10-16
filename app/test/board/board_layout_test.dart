/// Unit test cho tầng layout của bảng (`PQC-010` rev 7 §R7-B).
///
/// Tầng này pure Dart, nên **không cần ảnh** để chứng minh bảng đã vẽ đúng: mỗi ca dưới đây đọc
/// số đo mà renderer sẽ dùng — đoạn nào được tô, nhóm có bao nhiêu vật, hình nằm ở đâu theo
/// `x/y/width/height`, mũi tên nối hai hộp nào, và `clearTutorLayer` cắt gì.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:pyquest/modules/tutor/board/board_layout.dart';
import 'package:pyquest/modules/tutor/board/board_models.dart';

import 'board_test_support.dart';

const double kW = 360;
const double kLine = 20;
const String kGreetingCode = 'print("Xin chào!")';
const String kNumbersCode = 'print(3 + 4)\nprint("3 + 4")';

TeachingPlan planOf(int index) {
  final TeachingPlan? plan = validateComposed(index).plan;
  expect(plan, isNotNull);
  return plan!;
}

BoardLayout layoutOf(
  int index,
  int beatIndex, {
  String code = '',
  String locale = 'vi',
  String header = 'out',
  double Function(String text)? codeWidthOf,
  double Function(String text, double maxWidth)? proseHeightOf,
}) {
  final TeachingPlan plan = planOf(index);
  final BoardLayout layout = BoardLayout.build(
    visible: visibleOpsThrough(plan, beatIndex),
    codeText: code.isEmpty ? (index == 0 ? kGreetingCode : kNumbersCode) : code,
    width: kW,
    lineHeight: kLine,
    altOf: (BoardOp op) => op.altFor(locale),
    proseOf: (BoardOp op) => op.proseFor(locale),
    outputHeader: header,
    codeWidthOf: codeWidthOf,
    proseHeightOf: proseHeightOf,
  );
  return layout;
}

/// Bề rộng layout tự ước lượng khi không có số đo font: 0.44 * lineHeight cho mỗi code point.
double kEstimate(String text) => text.runes.length * kLine * 0.44;

List<BoardRun> lineRuns(BoardLayout layout, int line) =>
    layout.nodes.firstWhere((BoardNode n) => n.key == 'board_code_line_$line').runs;

List<String> highlighted(BoardLayout layout, int line) => lineRuns(layout, line)
    .where((BoardRun r) => r.highlighted)
    .map((BoardRun r) => r.text)
    .toList();

BoardNode node(BoardLayout layout, String key) =>
    layout.nodes.firstWhere((BoardNode n) => n.key == key);

bool hasNode(BoardLayout layout, String key) => layout.nodes.any((BoardNode n) => n.key == key);

void main() {
  group('lớp tích lũy và clear', () {
    test('beat 3 của mq1_01_s2 vẫn thấy op của beat 1 — connector mới có cái để nối', () {
      final TeachingPlan plan = planOf(0);
      final List<BoardVisibleOp> visible = visibleOpsThrough(plan, 2);
      expect(visible.map((BoardVisibleOp e) => e.beatIndex), containsAll(<int>[0, 2]));
      expect(visible.firstWhere((BoardVisibleOp e) => e.op.kind == BoardOpKind.highlightToken).beatIndex, 0);
    });

    test('clearTutorLayer xóa mọi thứ đã xếp trước nó, kể cả của beat trước', () {
      final TeachingPlan plan = planOf(1);
      final List<BoardVisibleOp> before = visibleOpsThrough(plan, 0);
      expect(before, hasLength(3));
      final List<BoardVisibleOp> after = visibleOpsThrough(plan, 1);
      // b2 = clear + tokenGroup + output: hai op đầu tiên của beat nằm **sau** clear.
      expect(after, hasLength(2));
      expect(after.map((BoardVisibleOp e) => e.op.kind),
          <BoardOpKind>[BoardOpKind.tokenGroup, BoardOpKind.output]);
      expect(after.every((BoardVisibleOp e) => e.beatIndex == 1), isTrue);
    });
  });

  group('highlight là tô trên code, không phải in mô tả', () {
    test('highlightToken tô đúng từ trong dòng code', () {
      final BoardLayout layout = layoutOf(0, 0);
      expect(layout.codeLines, <String>[kGreetingCode]);
      expect(highlighted(layout, 0), <String>['print']);
      expect(lineRuns(layout, 0).map((BoardRun r) => r.text).join(), kGreetingCode);
      expect(node(layout, 'board_code_line_0').altText, isEmpty,
          reason: 'dòng code không tự đặt altText: nhãn là của beat và của op');
    });

    test('object được neo vào chính hộp đã tô, không phải một điểm tùy ý', () {
      final BoardLayout layout = layoutOf(0, 0);
      final BoardRect anchor = layout.anchors['cmd-print']!;
      final BoardRect rowRect = node(layout, 'board_code_line_0').rect;
      // rev 7 §R8-B1: anchor là **đoạn token được tô**, không phải nguyên dòng — mũi tên nối từ
      // `print` mà cắm vào mép dòng trắng bên phải thì hình vẽ nói dối trẻ.
      expect(anchor.x, closeTo(rowRect.x, 0.01), reason: 'token bắt đầu từ đầu dòng nên neo = mép trái');
      expect(anchor.w, closeTo(kEstimate('print'), 0.01));
      expect(anchor.w, lessThan(rowRect.w), reason: 'anchor hẹp hơn dòng: $anchor vs $rowRect');
      expect(anchor.y, closeTo(rowRect.y, 0.01));
      expect(anchor.h, closeTo(rowRect.h, 0.01));
      expect(layout.anchors.containsKey('out-box'), isFalse,
          reason: 'beat này chưa vẽ ô kết quả thì không có anchor');
    });

    test('hai dấu ngoặc kép = hai lần xuất hiện, mỗi id một anchor', () {
      final BoardLayout layout = layoutOf(0, 1);
      final List<BoardRun> runs = lineRuns(layout, 0);
      // Bảng là lớp tích lũy: dấu tô của beat 1 vẫn còn, beat 2 tô thêm **hai** dấu ngoặc.
      expect(highlighted(layout, 0), <String>['print', '"', '"'],
          reason: 'phải tô đúng số lần token xuất hiện: ${runs.map((BoardRun r) => r.text).join()}');
      // rev 7 §R8-B1: `quote-open` và `quote-close` là hai vật KHÁC NHAU trên cùng một dòng; nếu
      // cả hai nhận nguyên hộp dòng làm anchor thì mũi tên/hình vẽ của chúng chồng khít lên nhau
      // và không chứng minh được gì.
      final BoardRect open = layout.anchors['quote-open']!;
      final BoardRect close = layout.anchors['quote-close']!;
      expect(open.y, closeTo(close.y, 0.01), reason: 'cùng một dòng code');
      expect(open.x, lessThan(close.x), reason: 'dấu mở phải ở trước dấu đóng: $open vs $close');
      expect(open.w, closeTo(kEstimate('"'), 0.01));
      expect(close.w, closeTo(kEstimate('"'), 0.01));
      // Vị trí theo UTF-16 của hai dấu ngoặc trong `print("Xin chào!")`.
      expect(open.x, closeTo(8 + kEstimate('print('), 0.01));
      expect(close.x, closeTo(8 + kEstimate('print("Xin chào!'), 0.01));
      expect(runs.map((BoardRun r) => r.text).join(), kGreetingCode,
          reason: 'tô xong thì chữ vẫn phải nguyên văn, không mất ký tự nào');
    });

    test('highlightLine tô cả dòng được chỉ, không tô dòng bên cạnh', () {
      final BoardLayout layout = layoutOf(1, 0);
      expect(layout.codeLines, <String>['print(3 + 4)', 'print("3 + 4")']);
      expect(highlighted(layout, 0), <String>['print(3 + 4)']);
      expect(highlighted(layout, 1), isEmpty);
      expect(layout.anchors['expr-add'], node(layout, 'board_code_line_0').rect);
    });

    test('beat 3 numbers: tô dòng HAI của đoạn code, không phải dòng đầu', () {
      final BoardLayout layout = layoutOf(1, 2);
      expect(highlighted(layout, 0), isEmpty, reason: 'dòng một đã in ở beat trước, beat này nói dòng hai');
      expect(highlighted(layout, 1), <String>['print("3 + 4")']);
      expect(layout.anchors['lit-text'], node(layout, 'board_code_line_1').rect);
    });
  });

  group('nhóm vật, hình và ô kết quả', () {
    test('tokenGroup vẽ đủ số vật: 3 và 4, không in object ID', () {
      final BoardLayout layout = layoutOf(1, 0);
      final BoardNode left = node(layout, 'board_group_0_1');
      final BoardNode right = node(layout, 'board_group_0_2');
      expect(left.chips, hasLength(3));
      expect(right.chips, hasLength(4));
      expect(left.kind, BoardNodeKind.group);
      // Nhóm 4 phải rộng hơn nhóm 3 đúng `chipSize + chipGap` cho mỗi vật thêm.
      expect(right.rect.w - left.rect.w, closeTo(BoardLayout.chipSize + BoardLayout.chipGap, 0.01));
      // Anchor của từng vật nằm trong hàng của nhóm nó, cách đều nhau.
      final double step = BoardLayout.chipSize + BoardLayout.chipGap;
      for (int k = 0; k < 3; k++) {
        expect(layout.anchors['stone-${k + 1}']!.x, closeTo(left.rect.x + k * step, 0.01));
      }
      expect(layout.anchors['stone-4']!.x, closeTo(right.rect.x, 0.01));
    });

    test('altText của nhóm là bản locale đang hiển thị', () {
      expect(node(layoutOf(1, 0, locale: 'vi'), 'board_group_0_1').altText, contains('Ba viên đá'));
      expect(node(layoutOf(1, 0, locale: 'en'), 'board_group_0_1').altText, contains('Three stones'));
    });

    test('beat sau clear: nhóm 7 vật + ô kết quả CHỈ dòng đầu', () {
      final BoardLayout layout = layoutOf(1, 1);
      expect(hasNode(layout, 'board_group_0_1'), isFalse, reason: 'bảng đã lau, nhóm 3/4 không còn');
      final BoardNode seven = node(layout, 'board_group_1_1');
      expect(seven.chips, hasLength(7));
      final BoardNode out = node(layout, 'board_output_1_2');
      expect(out.lines, <String>['7'],
          reason: 'print(3 + 4) chỉ in ra dòng đầu — không được tích hai dòng vào một ô');
      expect(out.header, 'out');
      expect(out.altText, contains('chỉ ghi dòng đầu'));
    });

    test('wholeRun: ô kết quả có hai dòng, đúng thứ tự', () {
      final BoardLayout layout = layoutOf(1, 2);
      final BoardNode out = node(layout, 'board_output_2_1');
      expect(out.lines, <String>['7', '3 + 4']);
      // Nhãn header (0.85 chữ, dòng 1.2) + padding 2+2 + border 1+1: bỏ `boxChrome` là hộp
      // thấp hơn chữ và RenderBox báo overflow ở fontScale 2.0.
      expect(out.rect.h, closeTo(2 * kLine + kLine * 0.85 + 6, 0.01),
          reason: 'hộp phải đủ chỗ cho cả nhãn và 2 dòng, kể cả padding/border');
    });

    test('simpleShape tôn trọng x/y/width/height đã validate', () {
      final BoardLayout layout = layoutOf(1, 3);
      final BoardNode shape = node(layout, 'board_shape_3_1');
      expect(shape.shape, 'circle');
      expect(shape.rect.x, closeTo(0.2 * kW, 0.01));
      expect(shape.rect.w, closeTo(0.08 * kW, 0.01));
      expect(shape.rect.y, closeTo(0.4 * layout.height, 0.01));
      expect(shape.rect.h, closeTo(0.06 * layout.height, 0.01));
      expect(layout.anchors['stone-1'], shape.rect);
    });

    test('prose của op lấy theo locale, không dịch code', () {
      final BoardLayout vi = layoutOf(1, 3, locale: 'vi');
      final BoardLayout en = layoutOf(1, 3, locale: 'en');
      expect(node(vi, 'board_prose_3_0').lines.single, startsWith('Quan sát'));
      expect(node(en, 'board_prose_3_0').lines.single, startsWith('Look before'));
      expect(highlighted(vi, 0), highlighted(en, 0), reason: 'code thì không đổi khi đổi ngôn ngữ');
    });
  });

  group('connector', () {
    test('codeSnippet trùng code trên bảng thì không vẽ hai lần, khác thì có block riêng', () {
      // beat 1: câu lệnh mẫu đúng bằng dòng code đang có -> không có block thứ hai.
      expect(hasNode(layoutOf(0, 0), 'board_code_snippet_0_0'), isFalse);
      // beat 4: câu lệnh mẫu trẻ sắp gõ, chưa có trên bảng -> phải thấy nó trên bảng.
      final BoardLayout late = layoutOf(0, 3);
      final BoardNode snippet = node(late, 'board_code_snippet_3_1');
      expect(snippet.kind, BoardNodeKind.sample);
      expect(snippet.lines, <String>['print("Robo thông minh")']);
      expect(snippet.rect.w, closeTo(360 - 16, 0.01));
      expect(snippet.altText, contains('Câu lệnh mẫu'));
    });

    test('mũi tên nối đúng hai hộp đang có trên bảng', () {
      final BoardLayout layout = layoutOf(0, 2);
      expect(layout.connectors, hasLength(1));
      final BoardConnector link = layout.connectors.single;
      expect(link.fromRect, layout.anchors['cmd-print']);
      expect(link.toRect, layout.anchors['out-box']);
      expect(link.altText, contains('Mũi tên'));
      expect(link.rect.left, lessThanOrEqualTo(link.fromRect.left));
      expect(link.rect.bottom, greaterThanOrEqualTo(link.toRect.bottom));
    });

    test('rev 7 §R8-B1: hai hộp chồng nhau thì mũi tên phải dọc và cắm vào cạnh thật', () {
      final BoardLayout layout = layoutOf(0, 2);
      final BoardConnector link = layout.connectors.single;
      // Case thật của bảng: dòng code ở trên, ô kết quả ở dưới. Trước fix, `start`/`end` lấy
      // (centerY của hai hộp)/2 cho cả hai đầu -> một nét ngang lơ lửng, vẽ xong không nối gì.
      expect(link.isVertical, isTrue, reason: 'đích nằm dưới nguồn: $link');
      expect(link.toRect.top, greaterThanOrEqualTo(link.fromRect.bottom));
      expect(link.start.x, closeTo(link.fromRect.centerX, 0.01));
      expect(link.start.y, closeTo(link.fromRect.bottom, 0.01),
          reason: 'điểm đầu phải nằm trên ĐÁY hộp nguồn, không ở độ cao trung bình');
      expect(link.end.x, closeTo(link.toRect.centerX, 0.01));
      expect(link.end.y, closeTo(link.toRect.top, 0.01),
          reason: 'mũi tên phải cắm vào ĐỈNH hộp đích');
      expect(link.end.y, greaterThan(link.start.y), reason: 'nét bút đi xuống');
      expect(link.headDirection.y, closeTo(1, 0.001));
      expect(link.headDirection.x, closeTo(0, 0.001));
    });

    test('hai hộp đặt cạnh nhau thì mũi tên ngang, cắm vào mép phải/trái', () {
      // Hướng do hình học quyết định, không phải do tên beat: cùng một op, chỉ khác chỗ đặt ô
      // kết quả (shape ở phải, ngang tầm dòng code) là phải đi ngang.
      final BoardLayout layout = layoutOf(1, 3);
      final BoardRect a = const BoardRect(10, 10, 40, 20);
      final BoardRect b = const BoardRect(120, 10, 60, 20);
      final BoardConnector link = BoardConnector(
        key: 'board_connector_test',
        beatIndex: 0,
        opIndex: 0,
        altText: 'nối ngang',
        fromRect: a,
        toRect: b,
        rect: a.unite(b),
      );
      expect(link.isVertical, isFalse);
      expect(link.headDirection.x, closeTo(1, 0.001), reason: 'mũ mũi tên phải quay sang phải');
      expect(link.headDirection.y, closeTo(0, 0.001));
      expect(link.start.x, closeTo(a.right, 0.01));
      expect(link.start.y, closeTo(a.centerY, 0.01));
      expect(link.end.x, closeTo(b.left, 0.01));
      expect(link.end.y, closeTo(b.centerY, 0.01));
      expect(layout.nodes, isNotEmpty, reason: 'chỉ để chắc layout dựng được trước khi so hình học');
    });

    test('chưa có ô kết quả trên bảng thì không vẽ mũi tên giả', () {
      final BoardLayout layout = layoutOf(0, 0);
      expect(layout.connectors, isEmpty);
    });
  });

  // rev 7 §R8-B3: tô sáng phải bị chặn trong **đúng các dòng của statement được chỉ định**.
  // Luật cũ "mọi dòng từ firstLine trở đi" nhân bản một token sang các dòng chưa nhắc tới, và
  // khi host code không chứa statement thì nó tô bừa từ dòng đầu.
  group('tô sáng chỉ nằm trong phạm vi statement', () {
    test('token lặp ở dòng khác không bị tô theo', () {
      // beat 1 greeting tô hai dấu ngoặc kép, statement một dòng. Host có thêm dòng thứ hai cũng
      // chứa dấu nháy: dòng đó chưa được nhắc tới ở beat này thì không được tô.
      final BoardLayout layout =
          layoutOf(0, 1, code: 'print("Xin chào!")\nprint("dòng khác cũng có nháy")');
      expect(highlighted(layout, 0), <String>['print', '"', '"']);
      expect(highlighted(layout, 1), isEmpty,
          reason: 'dòng ngoài statement phải còn nguyên: ${lineRuns(layout, 1)}');
      expect(lineRuns(layout, 1).map((BoardRun r) => r.text).join(), 'print("dòng khác cũng có nháy")');
    });

    test('statement nhiều dòng: dòng thứ ba của host không bị vơ vào', () {
      final BoardLayout layout = layoutOf(
        1,
        2,
        code: 'print(3 + 4)\nprint("3 + 4")\nprint("3 + 4")',
      );
      expect(highlighted(layout, 0), isEmpty,
          reason: 'beat 2 của plan có clearTutorLayer nên dòng một không còn dấu tô của beat 1');
      expect(highlighted(layout, 1), <String>['print("3 + 4")']);
      expect(highlighted(layout, 2), isEmpty, reason: 'statement chỉ dài hai dòng, dòng ba là của host');
    });

    test('host code không chứa statement thì không tô đâu cả, cũng không có anchor', () {
      // Plan nói về `print("Xin chào!")` nhưng bảng đang cầm một đoạn code khác (lesson/source
      // lệch nhau). Vẽ bừa lên dòng đầu là biến bug dữ liệu thành hình vẽ sai trên màn hình trẻ.
      final BoardLayout layout = layoutOf(0, 1, code: 'x = 1');
      expect(highlighted(layout, 0), isEmpty);
      expect(layout.anchors.containsKey('quote-open'), isFalse);
      expect(layout.anchors.containsKey('quote-close'), isFalse);
    });
  });

  // rev 7 §R8-C: số đo font là thứ view đưa vào (`TextPainter` trên đúng style sẽ vẽ). Test pure
  // Dart giữ arithmetic bằng ước lượng, nhưng phải chứng minh layout **tuân theo** số đo được
  // đưa chứ không cứng con số trong file.
  group('số đo font đi vào hình học', () {
    test('anchor token rộng theo bề rộng ký tự được đo', () {
      final BoardLayout narrow =
          layoutOf(0, 0, codeWidthOf: (String text) => text.runes.length * 4.0);
      final BoardLayout wide =
          layoutOf(0, 0, codeWidthOf: (String text) => text.runes.length * 12.0);
      expect(narrow.anchors['cmd-print']!.w, closeTo(5 * 4.0, 0.01));
      expect(wide.anchors['cmd-print']!.w, closeTo(5 * 12.0, 0.01));
      expect(wide.anchors['cmd-print']!.w, greaterThan(narrow.anchors['cmd-print']!.w));
      // Anchor không được vượt ra ngoài hàng của nó kể cả khi chữ rộng bất thường:
      // `FittedBox(scaleDown)` co chữ thì anchor phải nhân cùng hệ số.
      final BoardRect wideAnchor = wide.anchors['cmd-print']!;
      final BoardRect row = node(wide, 'board_code_line_0').rect;
      expect(wideAnchor.right, lessThanOrEqualTo(row.right + 0.01),
          reason: 'anchor tràn hàng: $wideAnchor vs $row');
    });

    test('hộp chữ cao theo số đo xếp chữ thật, không theo ước lượng cố định', () {
      final BoardLayout compact =
          layoutOf(1, 3, proseHeightOf: (String text, double w) => 3 * kLine);
      expect(node(compact, 'board_prose_3_0').rect.h, closeTo(3 * kLine, 0.01));
      final BoardLayout tall =
          layoutOf(1, 3, proseHeightOf: (String text, double w) => 9 * kLine);
      expect(node(tall, 'board_prose_3_0').rect.h, closeTo(9 * kLine, 0.01));
      expect(tall.height, greaterThan(compact.height),
          reason: 'chữ cao hơn thì canvas phải dài ra, nếu không là tràn khỏi khung');
      expect(node(tall, 'board_prose_3_0').rect.bottom, lessThanOrEqualTo(tall.height + 0.01));
    });
  });

  group('mọi object được khai đều có hộp', () {
    test('hai plan, bốn beat: objectIds luôn nằm trong tập op vẽ', () {
      for (int index = 0; index < 2; index++) {
        final TeachingPlan plan = planOf(index);
        for (int b = 0; b < plan.beats.length; b++) {
          final Set<String> drawn = drawnObjectIds(visibleOpsThrough(plan, b));
          for (final String id in plan.beats[b].objectIds) {
            expect(drawn, contains(id), reason: 'beat ${plan.beats[b].beatId} khai $id nhưng không op nào vẽ');
          }
        }
      }
    });
  });
}
