import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../python_runtime/python_runtime.dart';
import '../characters/characters.dart';
import '../theme/app_theme.dart';
import '../theme/palette.dart';

const Set<String> _keywords = {
  'False', 'None', 'True', 'and', 'as', 'break', 'class', 'continue', 'def', 'elif', 'else', 'for', 'from', 'global',
  'if', 'import', 'in', 'is', 'lambda', 'not', 'or', 'pass', 'return', 'try', 'while', 'with',
};
const Set<String> _builtins = {
  'print', 'len', 'range', 'str', 'int', 'float', 'bool', 'abs', 'round', 'min', 'max', 'sum', 'list', 'sorted', 'type',
  'input', 'up', 'down', 'left', 'right', 'at_chest', 'gems_left',
};

final RegExp _token = RegExp(
  r'''(#[^\n]*)|("(?:[^"\\\n]|\\.)*"?|'(?:[^'\\\n]|\\.)*'?)|(\d+(?:\.\d+)?)|([\p{L}_][\p{L}\p{N}_]*)|([+\-*/%=<>!:(),.\[\]]+)|(\s+)|(.)''',
  unicode: true,
);

/// Splits Python source into coloured spans (display only).
List<TextSpan> highlightPython(String code, TextStyle base) {
  final spans = <TextSpan>[];
  for (final m in _token.allMatches(code)) {
    final text = m.group(0)!;
    Color? color;
    var weight = base.fontWeight;
    if (m.group(1) != null) {
      color = PQColors.codeComment;
    } else if (m.group(2) != null) {
      color = PQColors.codeString;
    } else if (m.group(3) != null) {
      color = PQColors.codeNumber;
    } else if (m.group(4) != null) {
      if (_keywords.contains(text)) {
        color = PQColors.codeKeyword;
        weight = FontWeight.w700;
      } else if (_builtins.contains(text)) {
        color = PQColors.codeBuiltin;
      }
    } else if (m.group(5) != null) {
      color = PQColors.codeOp;
    }
    spans.add(TextSpan(text: text, style: color == null ? null : base.copyWith(color: color, fontWeight: weight)));
  }
  return spans;
}

/// Read-only, highlighted code block with line numbers.
class CodeView extends StatelessWidget {
  const CodeView({super.key, required this.code, this.highlightLine, this.errorLine, this.fontSize = 15.5, this.onLineTap, this.lineColors});
  final String code;
  final int? highlightLine;
  final int? errorLine;
  final double fontSize;
  final ValueChanged<int>? onLineTap;

  /// Optional per-line background colours (1-based line -> colour).
  final Map<int, Color>? lineColors;

  @override
  Widget build(BuildContext context) {
    final lines = code.split('\n');
    final style = PQText.code.copyWith(fontSize: fontSize);
    return Container(
      decoration: BoxDecoration(
        color: PQColors.codeBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PQColors.ink, width: 2.6),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < lines.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onLineTap == null ? null : () => onLineTap!(i + 1),
                  child: Container(
                    key: ValueKey('code_line_${i + 1}'),
                    color: lineColors?[i + 1] ??
                        (errorLine == i + 1
                            ? PQColors.danger.withValues(alpha: 0.35)
                            : (highlightLine == i + 1 ? PQColors.sun.withValues(alpha: 0.25) : Colors.transparent)),
                    padding: EdgeInsets.symmetric(vertical: onLineTap == null ? 0 : 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 34,
                          child: Text('${i + 1}', textAlign: TextAlign.right, style: style.copyWith(color: PQColors.codeLine)),
                        ),
                        const SizedBox(width: 12),
                        Text.rich(TextSpan(children: highlightPython(lines[i], style), style: style)),
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Text controller that paints Python syntax colours while typing.
class PythonCodeController extends TextEditingController {
  PythonCodeController({super.text});

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final base = style ?? PQText.code;
    if (value.composing.isValid && withComposing) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }
    return TextSpan(style: base, children: highlightPython(text, base));
  }

  /// Inserts [snippet] at the cursor; [caretBack] moves the caret left
  /// (e.g. to land inside parentheses).
  void insertSnippet(String snippet, {int caretBack = 0}) {
    final sel = selection.isValid ? selection : TextSelection.collapsed(offset: text.length);
    final newText = text.replaceRange(sel.start, sel.end, snippet);
    final caret = sel.start + snippet.length - caretBack;
    value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: caret));
  }
}

/// Code editor with line numbers, auto-indent and a helper key row.
class CodeEditor extends StatefulWidget {
  const CodeEditor({
    super.key,
    required this.controller,
    this.errorLine,
    this.minLines = 6,
    this.extraKeys = const [],
    this.hint = '# Viết code Python ở đây',
    this.focusNode,
  });

  final PythonCodeController controller;
  final int? errorLine;
  final int minLines;
  final List<CodeKey> extraKeys;
  final String hint;
  final FocusNode? focusNode;

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class CodeKey {
  const CodeKey(this.label, this.snippet, {this.caretBack = 0});
  final String label;
  final String snippet;
  final int caretBack;
}

const List<CodeKey> defaultCodeKeys = [
  CodeKey('Tab', '    '),
  CodeKey('print()', 'print()', caretBack: 1),
  CodeKey('" "', '""', caretBack: 1),
  CodeKey('( )', '()', caretBack: 1),
  CodeKey(':', ':'),
  CodeKey('=', ' = '),
  CodeKey('==', ' == '),
  CodeKey('+', ' + '),
  CodeKey('if', 'if :', caretBack: 1),
  CodeKey('else:', 'else:'),
  CodeKey('for', 'for i in range():', caretBack: 2),
];

class _CodeEditorState extends State<CodeEditor> {
  String _previous = '';

  @override
  void initState() {
    super.initState();
    _previous = widget.controller.text;
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(CodeEditor old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
      _previous = widget.controller.text;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final c = widget.controller;
    final text = c.text;
    // Auto-indent when a single newline was typed.
    if (text.length == _previous.length + 1 && c.selection.isCollapsed) {
      final caret = c.selection.baseOffset;
      if (caret > 0 && caret <= text.length && text[caret - 1] == '\n') {
        final before = text.substring(0, caret - 1);
        final lineStart = before.lastIndexOf('\n') + 1;
        final line = before.substring(lineStart);
        final indent = RegExp(r'^ *').firstMatch(line)!.group(0)!.length;
        final extra = line.trimRight().endsWith(':') ? 4 : 0;
        final pad = ' ' * (indent + extra);
        if (pad.isNotEmpty) {
          _previous = text.replaceRange(caret, caret, pad);
          c.value = TextEditingValue(text: _previous, selection: TextSelection.collapsed(offset: caret + pad.length));
          setState(() {});
          return;
        }
      }
    }
    _previous = text;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lines = math.max(widget.minLines, '\n'.allMatches(widget.controller.text).length + 1);
    final longest = widget.controller.text.split('\n').fold<int>(0, (m, l) => math.max(m, l.length));
    const style = PQText.code;
    const charW = 9.7;
    final lineH = (style.fontSize ?? 16) * (style.height ?? 1.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: PQColors.codeBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: PQColors.ink, width: 2.6),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: LayoutBuilder(builder: (context, constraints) {
            final textWidth = math.max(constraints.maxWidth - 50, longest * charW + 40);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 42,
                  child: Column(
                    children: [
                      for (var i = 1; i <= lines; i++)
                        Container(
                          height: lineH,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 6),
                          color: widget.errorLine == i ? PQColors.danger.withValues(alpha: 0.5) : null,
                          child: Text('$i', style: style.copyWith(color: PQColors.codeLine, height: 1.0)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: textWidth,
                      child: TextField(
                        key: const ValueKey('code_editor_field'),
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        maxLines: null,
                        minLines: widget.minLines,
                        keyboardType: TextInputType.multiline,
                        autocorrect: false,
                        enableSuggestions: false,
                        enableIMEPersonalizedLearning: false,
                        textCapitalization: TextCapitalization.none,
                        smartQuotesType: SmartQuotesType.disabled,
                        smartDashesType: SmartDashesType.disabled,
                        style: style,
                        strutStyle: StrutStyle(fontFamily: PQFonts.code, fontSize: style.fontSize, height: style.height, forceStrutHeight: true),
                        cursorColor: PQColors.pyYellow,
                        cursorWidth: 2.5,
                        decoration: InputDecoration.collapsed(
                          hintText: widget.hint,
                          hintStyle: style.copyWith(color: PQColors.codeComment),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final k in [...widget.extraKeys, ...defaultCodeKeys])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _KeyChip(
                    label: k.label,
                    highlighted: widget.extraKeys.contains(k),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.controller.insertSnippet(k.snippet, caretBack: k.caretBack);
                    },
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyChip extends StatelessWidget {
  const _KeyChip({required this.label, required this.onTap, this.highlighted = false});
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? PQColors.pyBlue : PQColors.codeBgSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: PQColors.ink, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 46),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Text(label, style: PQText.code.copyWith(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}

/// Program output + friendly error explanation.
class OutputConsole extends StatelessWidget {
  const OutputConsole({super.key, required this.result, this.expected, this.helper = CharacterId.py});
  final ExecutionResult? result;
  final String? expected;
  final CharacterId helper;

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const ValueKey('output_console'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF14182E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PQColors.ink, width: 2.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.terminal_rounded, color: PQColors.codeNumber, size: 18),
                  const SizedBox(width: 6),
                  Text('Kết quả', style: PQText.small.copyWith(color: PQColors.codeNumber, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                r == null ? 'Bấm "Chạy" để xem kết quả' : (r.output.isEmpty ? '(chương trình không in gì)' : r.output.trimRight()),
                style: PQText.code.copyWith(fontSize: 15, color: r == null || r.output.isEmpty ? PQColors.codeComment : Colors.white),
              ),
            ],
          ),
        ),
        if (r != null && !r.success && r.errorMessage != null) ...[
          const SizedBox(height: 8),
          ErrorCard(result: r, helper: helper),
        ],
      ],
    );
  }
}

class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.result, this.helper = CharacterId.py});
  final ExecutionResult result;
  final CharacterId helper;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final title = switch (r.errorKind) {
      ExecutionErrorKind.syntax => 'Code viết chưa đúng quy tắc',
      ExecutionErrorKind.limit => 'Chương trình bị dừng an toàn',
      ExecutionErrorKind.unsupported => 'PyQuest Python chưa hỗ trợ',
      ExecutionErrorKind.halted => 'Chương trình dừng lại',
      _ => 'Có lỗi khi chạy',
    };
    return Container(
      key: const ValueKey('error_card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEE8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PQColors.ink, width: 2.4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CharacterView(id: helper, size: 56, mood: Mood.thinking),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.errorLine != null ? '$title (dòng ${r.errorLine})' : title,
                    style: PQText.bodyStrong.copyWith(color: PQColors.coralDeep)),
                const SizedBox(height: 2),
                Text(r.errorMessage!, style: PQText.body.copyWith(fontSize: 15.5, color: PQColors.ink)),
                if (r.pythonError != null) ...[
                  const SizedBox(height: 6),
                  Text('Python thật sẽ báo:', style: PQText.small.copyWith(fontSize: 12.5)),
                  Text(r.pythonError!, style: PQText.code.copyWith(fontSize: 13, color: PQColors.coralDeep)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
