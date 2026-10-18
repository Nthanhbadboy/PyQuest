# r51 · source excerpts

Pin: `de01a490743982356ad5240d77ea99e9dbf8c7f5`. Excerpts display-only; hashes cover full raw blobs.

## `app/lib/modules/robot_maze/maze_play_screen.dart`

Lines 24–35:
```text
24: /// Plays one maze with command blocks (and, in Creator Mode, with Python).
25: class MazePlayScreen extends StatefulWidget {
26:   const MazePlayScreen({super.key, required this.level, this.customId, this.startInCode = false});
27:
28:   final MazeLevel level;
29:
30:   /// Set when playing a self-made maze from the workshop (Creator Mode).
31:   final int? customId;
32:   final bool startInCode;
33:
34:   bool get isCustom => customId != null;
35:
```

Lines 65–76:
```text
65:       });
66:     }
67:   }
68:   bool _showPython = false;
69:
70:   // Code mode (Creator Mode only)
71:   late bool _codeMode = widget.startInCode && widget.isCustom;
72:   final PythonCodeController _code = PythonCodeController(text: '# Điều khiển Robo bằng Python\nright()\n');
73:   ExecutionResult? _codeResult;
74:   bool _hadLimitError = false;
75:
76:   // Run state
```

Lines 224–267:
```text
224:   Future<void> _runProgram() async {
225:     if (_phase == _Phase.running) return;
226:     final services = AppScope.of(context);
227:     List<Dir> moves;
228:     List<StepRef?> refs;
229:     if (_codeMode) {
230:       FocusScope.of(context).unfocus();
231:       final sim = MazeSimulation(level);
232:       final result = await services.python.execute(_code.text,
233:           context: ExecutionContext(hostFunctions: {
234:             for (final d in Dir.values)
235:               d.py: (args) {
236:                 if (!sim.move(d)) throw HostHalt(sim.outcome == RunOutcome.win ? 'win' : 'stop');
237:                 return null;
238:               },
239:             'at_chest': (args) => sim.position == level.goal,
240:             'gems_left': (args) => level.gems.length - sim.gems.length,
241:           }));
242:       if (!mounted) return;
243:       final codeOk = result.success || (result.errorKind == ExecutionErrorKind.halted);
244:       final recovered = codeOk && _hadLimitError;
245:       if (result.hitLimit) _hadLimitError = true;
246:       if (recovered) _hadLimitError = false;
247:       final outcome = await services.events.emit(StandardEvent(
248:         type: EventTypes.codeRun,
249:         sourceId: 'robot_maze',
250:         data: {'success': codeOk && sim.outcome == RunOutcome.win, 'context': 'robot', 'recovered_from_limit': recovered},
251:       ));
252:       if (!mounted) return;
253:       _pendingNotices.addAll(outcome.notices);
254:       setState(() => _codeResult = (result.errorKind == ExecutionErrorKind.halted) ? null : result);
255:       if (!codeOk) {
256:         services.audio.play(Sfx.fail);
257:         setState(() {
258:           _message = 'Code có lỗi nên Robo chưa chạy được. Đọc lời nhắc bên dưới nhé!';
259:           _messageMood = Mood.thinking;
260:         });
261:         return;
262:       }
263:       moves = List.of(sim.moves);
264:       refs = List.filled(moves.length, null);
265:       _commandsUsed = _countCodeCommands(_code.text);
266:       _usedLoop = RegExp(r'^\s*(for|while)\b', multiLine: true).hasMatch(_code.text);
267:     } else {
```

Lines 301–310:
```text
301:   int _countCodeCommands(String code) {
302:     return code
303:         .split('\n')
304:         .where((l) => l.trim().isNotEmpty && !l.trim().startsWith('#'))
305:         .length;
306:   }
307:
308:   void _buildAnimation(List<Dir> moves, List<StepRef?> refs, RunResult result) {
309:     _anim = [];
310:     var pos = level.start;
```

Lines 659–706:
```text
659:                   child: CustomPaint(
660:                     size: Size.infinite,
661:                     painter: MazeBoardPainter(level: level, playback: _pb, time: _time),
662:                   ),
663:                 ),
664:               ),
665:               if (_showPython && !_codeMode)
666:                 Padding(
667:                   padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
668:                   child: ConstrainedBox(
669:                     constraints: const BoxConstraints(maxHeight: 120),
670:                     child: SingleChildScrollView(child: CodeView(code: programToPython(_program), fontSize: 14)),
671:                   ),
672:                 ),
673:               if (widget.isCustom) _modeSwitch(),
674:               if (_codeMode) _codePanel() else _blocksPanel(),
675:               _runRow(),
676:             ],
677:           ),
678:         ),
679:       ),
680:     );
681:   }
682:
683:   Widget _modeSwitch() {
684:     Widget seg(String label, bool code) {
685:       final active = _codeMode == code;
686:       return Expanded(
687:         child: GestureDetector(
688:           key: ValueKey(code ? 'mode_code' : 'mode_blocks'),
689:           onTap: _phase == _Phase.running
690:               ? null
691:               : () {
692:                   setState(() {
693:                     if (code && !_codeMode && _program.isNotEmpty) {
694:                       _code.text = '${programToPython(_program)}\n';
695:                     }
696:                     _codeMode = code;
697:                   });
698:                   _tryAgain();
699:                 },
700:           child: AnimatedContainer(
701:             duration: const Duration(milliseconds: 180),
702:             padding: const EdgeInsets.symmetric(vertical: 8),
703:             decoration: BoxDecoration(
704:               color: active ? PQColors.grape : Colors.transparent,
705:               borderRadius: BorderRadius.circular(14),
706:             ),
```

Lines 726–750:
```text
726:   }
727:
728:   Widget _codePanel() {
729:     return ConstrainedBox(
730:       constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.36),
731:       child: SingleChildScrollView(
732:         padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
733:         child: Column(
734:           crossAxisAlignment: CrossAxisAlignment.stretch,
735:           children: [
736:             CodeEditor(
737:               controller: _code,
738:               minLines: 4,
739:               errorLine: _codeResult?.errorLine,
740:               extraKeys: const [
741:                 CodeKey('right()', 'right()'),
742:                 CodeKey('left()', 'left()'),
743:                 CodeKey('up()', 'up()'),
744:                 CodeKey('down()', 'down()'),
745:                 CodeKey('at_chest()', 'at_chest()'),
746:               ],
747:             ),
748:             if (_codeResult != null && !_codeResult!.success) ...[
749:               const SizedBox(height: 8),
750:               ErrorCard(result: _codeResult!, helper: CharacterId.robo),
```

## `app/lib/modules/robot_maze/maze_workshop_screen.dart`

Lines 163–205:
```text
163:   Future<int> _save({bool? verified}) async {
164:     final s = AppScope.of(context);
165:     final lvl = _level;
166:     final id = await s.customLevels.save(
167:       id: _id,
168:       gameId: RobotMazeContent.gameId,
169:       name: lvl.title,
170:       data: lvl.toJson(),
171:       verified: verified ?? _verified,
172:       at: s.clock.now(),
173:     );
174:     _id = id;
175:     _dirty = false;
176:     await _loadSaved();
177:     return id;
178:   }
179:
180:   Future<void> _testRun({bool code = false}) async {
181:     final s = AppScope.of(context);
182:     final lvl = _level;
183:     if (!_solvable(lvl)) {
184:       s.audio.play(Sfx.bonk);
185:       _toast('Chưa có đường nào từ Robo tới rương! Hãy mở một lối đi nhé.');
186:       return;
187:     }
188:     final id = await _save();
189:     if (!mounted) return;
190:     final result = await Navigator.of(context).push<Object?>(
191:       CloudRoute(
192:         builder: (_) => MazePlayScreen(level: MazeLevel.fromCustomJson(id, lvl.toJson()), customId: id, startInCode: code),
193:         calm: s.settings.calmMode,
194:       ),
195:     );
196:     final report = readCustomRunReport(result);
197:     if (!mounted || report == null || !report.won) return;
198:     final firstVerify = !_verified;
199:     setState(() => _verified = true);
200:     await _save(verified: true);
201:     final notices = [...report.notices];
202:     if (firstVerify) {
203:       final outcome = await s.events.emit(StandardEvent(
204:         type: EventTypes.customGameVerified,
205:         sourceId: RobotMazeContent.gameId,
```

## `app/lib/shared/widgets/code_widgets.dart`

Lines 125–164:
```text
125:     }
126:     return TextSpan(style: base, children: highlightPython(text, base));
127:   }
128:
129:   /// Inserts [snippet] at the cursor; [caretBack] moves the caret left
130:   /// (e.g. to land inside parentheses).
131:   void insertSnippet(String snippet, {int caretBack = 0}) {
132:     final sel = selection.isValid ? selection : TextSelection.collapsed(offset: text.length);
133:     final newText = text.replaceRange(sel.start, sel.end, snippet);
134:     final caret = sel.start + snippet.length - caretBack;
135:     value = TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: caret));
136:   }
137: }
138:
139: /// Code editor with line numbers, auto-indent and a helper key row.
140: class CodeEditor extends StatefulWidget {
141:   const CodeEditor({
142:     super.key,
143:     required this.controller,
144:     this.errorLine,
145:     this.minLines = 6,
146:     this.extraKeys = const [],
147:     this.hint = '# Viết code Python ở đây',
148:     this.focusNode,
149:   });
150:
151:   final PythonCodeController controller;
152:   final int? errorLine;
153:   final int minLines;
154:   final List<CodeKey> extraKeys;
155:   final String hint;
156:   final FocusNode? focusNode;
157:
158:   @override
159:   State<CodeEditor> createState() => _CodeEditorState();
160: }
161:
162: class CodeKey {
163:   const CodeKey(this.label, this.snippet, {this.caretBack = 0});
164:   final String label;
```

Lines 209–231:
```text
209:   void _onChanged() {
210:     final c = widget.controller;
211:     final text = c.text;
212:     // Auto-indent when a single newline was typed.
213:     if (text.length == _previous.length + 1 && c.selection.isCollapsed) {
214:       final caret = c.selection.baseOffset;
215:       if (caret > 0 && caret <= text.length && text[caret - 1] == '\n') {
216:         final before = text.substring(0, caret - 1);
217:         final lineStart = before.lastIndexOf('\n') + 1;
218:         final line = before.substring(lineStart);
219:         final indent = RegExp(r'^ *').firstMatch(line)!.group(0)!.length;
220:         final extra = line.trimRight().endsWith(':') ? 4 : 0;
221:         final pad = ' ' * (indent + extra);
222:         if (pad.isNotEmpty) {
223:           _previous = text.replaceRange(caret, caret, pad);
224:           c.value = TextEditingValue(text: _previous, selection: TextSelection.collapsed(offset: caret + pad.length));
225:           setState(() {});
226:           return;
227:         }
228:       }
229:     }
230:     _previous = text;
231:     setState(() {});
```

## `app/lib/python_runtime/python_runtime.dart`

Lines 1–94:
```text
1: /// Public gateway to running child-written code.
2: ///
3: /// Every module must go through [PythonRuntime]; nobody touches the
4: /// interpreter directly (see docs/TECHNICAL_ARCHITECTURE.md §2.4). Today the
5: /// only implementation is [SimulatedPythonRuntime] — a limited Python-like
6: /// subset written in Dart. It is **not** CPython and the UI says so.
7: library;
8:
9: export 'src/errors.dart' show HostHalt, PyErrorKind;
10:
11: /// A host function exposed to the child's program, e.g. `right()` in Robot
12: /// Maze. It may return a Python-compatible value (bool, int, double, String,
13: /// null for None) or throw [HostHalt] to stop the program on purpose.
14: typedef HostFunction = Object? Function(List<Object?> args);
15:
16: class RuntimeLimits {
17:   const RuntimeLimits({
18:     this.stepBudget = 100000,
19:     this.maxCallDepth = 50,
20:     this.maxOutputChars = 10000,
21:     this.maxCollectionLength = 10000,
22:     this.maxStringLength = 50000,
23:   });
24:
25:   /// Hard stop: number of interpreter steps (statements, loop iterations,
26:   /// calls). This is the primary guarantee that `while True:` terminates.
27:   final int stepBudget;
28:   final int maxCallDepth;
29:   final int maxOutputChars;
30:   final int maxCollectionLength;
31:   final int maxStringLength;
32:
33:   factory RuntimeLimits.fromJson(Map<String, dynamic> json) => RuntimeLimits(
34:         stepBudget: (json['step_budget'] as num?)?.toInt() ?? 100000,
35:         maxCallDepth: (json['max_call_depth'] as num?)?.toInt() ?? 50,
36:         maxOutputChars: (json['max_output_chars'] as num?)?.toInt() ?? 10000,
37:         maxCollectionLength: (json['max_collection_length'] as num?)?.toInt() ?? 10000,
38:         maxStringLength: (json['max_string_length'] as num?)?.toInt() ?? 50000,
39:       );
40: }
41:
42: class ExecutionContext {
43:   const ExecutionContext({this.hostFunctions = const {}, this.limits});
44:
45:   final Map<String, HostFunction> hostFunctions;
46:
47:   /// Overrides the runtime's default limits for this execution.
48:   final RuntimeLimits? limits;
49: }
50:
51: enum ExecutionErrorKind { none, syntax, runtime, limit, unsupported, halted, cancelled }
52:
53: class ExecutionResult {
54:   const ExecutionResult({
55:     required this.success,
56:     required this.output,
57:     this.errorMessage,
58:     this.errorLine,
59:     this.errorKind = ExecutionErrorKind.none,
60:     this.pythonError,
61:     this.executionTime = Duration.zero,
62:     this.steps = 0,
63:   });
64:
65:   final bool success;
66:
67:   /// Everything printed by the program (possibly truncated at the limit).
68:   final String output;
69:
70:   /// Kid-friendly explanation (Vietnamese) when [success] is false.
71:   final String? errorMessage;
72:   final int? errorLine;
73:   final ExecutionErrorKind errorKind;
74:
75:   /// What real Python would have reported, e.g. `NameError: name 'x' is not defined`.
76:   final String? pythonError;
77:   final Duration executionTime;
78:   final int steps;
79:
80:   bool get hitLimit => errorKind == ExecutionErrorKind.limit;
81: }
82:
83: abstract class PythonRuntime {
84:   /// Human readable name shown in the UI (honest about being a simulation).
85:   String get displayName;
86:
87:   Future<ExecutionResult> execute(String code, {ExecutionContext? context});
88:
89:   /// Requests cancellation. The simulated runtime checks this between steps;
90:   /// the step budget remains the hard guarantee for CPU-bound loops.
91:   void interrupt();
92:
93:   bool get isRunning;
94: }
```

## `app/lib/modules/robot_maze/maze_models.dart`

Lines 1–25:
```text
1: import 'dart:convert';
2: import 'dart:math' as math;
3:
4: import 'package:flutter/material.dart';
5:
6: typedef Cell = math.Point<int>;
7:
8: enum Dir { up, down, left, right }
9:
10: extension DirInfo on Dir {
11:   int get dx => switch (this) { Dir.left => -1, Dir.right => 1, _ => 0 };
12:   int get dy => switch (this) { Dir.up => -1, Dir.down => 1, _ => 0 };
13:   String get py => name; // up(), down(), left(), right()
14:   String get label => switch (this) { Dir.up => 'Lên', Dir.down => 'Xuống', Dir.left => 'Trái', Dir.right => 'Phải' };
15:   String get letter => switch (this) { Dir.up => 'U', Dir.down => 'D', Dir.left => 'L', Dir.right => 'R' };
16:   IconData get icon => switch (this) {
17:         Dir.up => Icons.arrow_upward_rounded,
18:         Dir.down => Icons.arrow_downward_rounded,
19:         Dir.left => Icons.arrow_back_rounded,
20:         Dir.right => Icons.arrow_forward_rounded,
21:       };
22:
23:   static Dir fromLetter(String l) => switch (l) {
24:         'U' => Dir.up,
25:         'D' => Dir.down,
```
