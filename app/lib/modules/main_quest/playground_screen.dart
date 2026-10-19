import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/settings_sheet.dart';
import '../../core/audio_service.dart';
import '../../core/events.dart';
import '../../python_runtime/python_runtime.dart';
import '../../shared/characters/characters.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/code_widgets.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/reward_toast.dart';

/// Free-form Python sandbox (always free, no energy).
class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  final PythonCodeController _code = PythonCodeController(text: 'print("Xin chào PyQuest!")\n');
  ExecutionResult? _result;
  bool _running = false;
  bool _hadLimit = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final s = AppScope.of(context);
    FocusScope.of(context).unfocus();
    setState(() => _running = true);
    final r = await s.python.execute(_code.text);
    final recovered = r.success && _hadLimit;
    if (r.hitLimit) _hadLimit = true;
    if (recovered) _hadLimit = false;
    final outcome = await s.events.emit(StandardEvent(
      type: EventTypes.codeRun,
      sourceId: 'playground',
      data: {'success': r.success, 'context': 'playground', 'recovered_from_limit': recovered},
    ));
    if (!mounted) return;
    s.audio.play(r.success ? Sfx.sparkle : Sfx.bonk);
    setState(() {
      _result = r;
      _running = false;
    });
    if (outcome.notices.isNotEmpty) showRewardToasts(context, outcome.notices);
  }

  @override
  Widget build(BuildContext context) {
    final examples = AppScope.of(context).mainQuest.examples;
    return Scaffold(
      body: PQBackground(
        top: const Color(0xFFCDEFD9),
        child: SafeArea(
          child: Column(
            children: [
              PQTopBar(
                title: 'Sân tập code',
                subtitle: 'PyQuest Python · miễn phí',
                tone: PQTone.success,
                trailing: [
                  RoundIconButton(
                    icon: Icons.info_rounded,
                    tooltip: 'Giới hạn của PyQuest Python',
                    size: 46,
                    onPressed: () => showPythonLimits(context),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
                  children: [
                    Container(
                      key: const ValueKey('playground_25d_scene'),
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: PQColors.ink, width: 2.4),
                        boxShadow: [
                          BoxShadow(
                            color: PQTone.success.depth,
                            offset: const Offset(0, 3),
                            blurRadius: 0,
                          ),
                        ],
                        image: const DecorationImage(
                          image: AssetImage(
                            'assets/images/journal_recap_r36.webp',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final e in examples)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                backgroundColor: PQColors.cream,
                                side: const BorderSide(
                                  color: PQColors.ink,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                label: Text(
                                  e.title,
                                  style: PQText.small.copyWith(
                                    color: PQColors.ink,
                                  ),
                                ),
                                onPressed: () => setState(() {
                                  _code.text = '${e.code}\n';
                                  _result = null;
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    CodeEditor(controller: _code, errorLine: _result?.errorLine, minLines: 8),
                    const SizedBox(height: 10),
                    ChunkyButton(
                      key: const ValueKey('playground_run'),
                      label: _running ? 'Đang chạy...' : 'Chạy',
                      icon: Icons.play_arrow_rounded,
                      tone: PQTone.grass,
                      expand: true,
                      sfx: null,
                      onPressed: _running ? null : _run,
                    ),
                    const SizedBox(height: 10),
                    OutputConsole(result: _result),
                    const SizedBox(height: 10),
                    const SpeechBubble(
                      character: CharacterId.py,
                      text: 'Ở đây bạn được thử mọi thứ! Viết sai cũng không sao — tớ sẽ giải thích lỗi giúp bạn.',
                      portraitSize: 64,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
