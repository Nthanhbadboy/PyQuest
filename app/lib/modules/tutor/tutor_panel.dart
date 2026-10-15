import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../shared/characters/cast.dart';
import '../../shared/characters/characters.dart';
import '../../shared/characters/dialogue.dart';
import '../../shared/l10n/pq_l10n.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/code_widgets.dart';
import '../../shared/widgets/common.dart';
import 'tutor_models.dart';
import 'tutor_session.dart';

/// Opens the tutor as a bottom sheet. Used from a Main Quest lesson (with the
/// live exercise as context) and from the Main Map (island questions).
Future<void> showTutorPanel(
  BuildContext context, {
  required TutorContext tutorContext,
  CharacterId? character,
  bool startWithHint = false,
}) {
  final services = AppScope.of(context);
  return showPQSheet<void>(
    context,
    builder: (ctx) => TutorPanel(
      services: services,
      tutorContext: tutorContext,
      character: character ?? CastRegistry.tutorForSkill(tutorContext.skill).id,
      startWithHint: startWithHint,
    ),
  );
}

/// One line of the on-screen transcript.
class _Line {
  _Line({required this.reply, this.question = ''});
  final String question;
  final TutorReply reply;
}

/// The tutor sheet: who is answering, what was asked, and what came back —
/// always labelled with where the answer came from.
class TutorPanel extends StatefulWidget {
  const TutorPanel({
    super.key,
    required this.services,
    required this.tutorContext,
    required this.character,
    this.startWithHint = false,
  });

  final AppServices services;
  final TutorContext tutorContext;
  final CharacterId character;
  final bool startWithHint;

  @override
  State<TutorPanel> createState() => _TutorPanelState();
}

class _TutorPanelState extends State<TutorPanel> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();
  final List<_Line> _lines = [];
  bool _asking = false;
  bool _opened = false;

  /// Last question sent, so «Thử lại» resends it through the AI provider
  /// instead of leaving the child with the offline answer.
  TutorRequest? _lastRequest;

  PqStrings get _s => widget.services.settings.strings;
  PqLang get _lang => widget.services.settings.lang;
  CastMember get _member => CastRegistry.of(widget.character);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_opened) return;
    _opened = true;
    _seedFromHistory();
    if (widget.startWithHint) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _askHint());
    }
  }

  /// Reopens with the transcript of this lesson (or this island topic).
  void _seedFromHistory() {
    final session = widget.services.tutor;
    final lessonId = widget.tutorContext.lessonId;
    final past = session.history.where((t) => t.lessonId == lessonId).toList();
    final recent = past.length > 12 ? past.sublist(past.length - 12) : past;
    for (final turn in recent) {
      _lines.add(_Line(
        question: turn.question,
        reply: TutorReply(
          text: turn.answer,
          source: turn.source,
          character: turn.character,
          hintLevel: turn.hintLevel,
        ),
      ));
    }
    setState(() {});
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  TutorRequest _request(String question, {TutorQuickAction? action}) => TutorRequest(
        question: question,
        context: widget.tutorContext,
        lang: _lang,
        character: widget.character,
        quickAction: action,
      );

  Future<void> _send([String? preset, TutorQuickAction? action]) async {
    final question = (preset ?? _input.text).trim();
    if (question.isEmpty || _asking) return;
    _input.clear();
    final request = _request(question, action: action);
    setState(() {
      _asking = true;
      _lastRequest = request;
    });
    final session = widget.services.tutor;
    final reply = await session.askAndRemember(request);
    if (!mounted) return;
    setState(() {
      _asking = false;
      _lines.add(_Line(question: question, reply: reply));
    });
    _scrollToEnd();
  }

  Future<void> _askHint() async {
    if (_asking) return;
    setState(() => _asking = true);
    final session = widget.services.tutor;
    final reply = await session.rememberHint(_request(_s.hintLadder));
    if (!mounted) return;
    setState(() {
      _asking = false;
      _lines.add(_Line(question: widget.tutorContext.stepPrompt, reply: reply));
    });
    _scrollToEnd();
  }

  /// Retries the last question through the AI provider. Called from the
  /// fallback notice, so a failed AI call never becomes a dead end.
  Future<void> _retryLast() async {
    final last = _lastRequest;
    if (last == null || _asking) return;
    setState(() => _asking = true);
    final reply = await widget.services.tutor.askAndRemember(last);
    if (!mounted) return;
    setState(() {
      _asking = false;
      _lines.add(_Line(question: last.question, reply: reply));
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Mood get _mood {
    if (_asking || widget.services.tutor.busy) return Mood.thinking;
    final last = _lines.isEmpty ? null : _lines.last.reply;
    if (last == null) return Mood.happy;
    if (last.hintLevel == TutorHintLevel.full) return Mood.surprised;
    return Mood.happy;
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.services.settings;
    return AnimatedBuilder(
      animation: Listenable.merge([settings, widget.services.tutor]),
      builder: (context, _) {
        final session = widget.services.tutor;
        final busy = _asking || session.busy;
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(session),
              if (!widget.services.tutor.hasAi) ...[
                const SizedBox(height: 8),
                _FallbackNotice(
                  key: const ValueKey('tutor_no_ai_banner'),
                  text: _s.errNoConfig,
                  canRetry: false,
                  retryLabel: _s.retry,
                  onRetry: _retryLast,
                ),
              ],
              const SizedBox(height: 10),
              Flexible(
                child: _transcript(busy),
              ),
              const SizedBox(height: 10),
              _quickActions(),
              const SizedBox(height: 8),
              _composer(busy),
              const SizedBox(height: 8),
              _footer(session),
            ],
          ),
        );
      },
    );
  }

  Widget _header(TutorSession session) {
    final strings = _s;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CharacterView(id: widget.character, size: 62, mood: _mood),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _member.name,
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: PQColors.ink,
                ),
              ),
              Text(
                _lang == PqLang.vi ? _member.roleVi : _member.roleEn,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12.5,
                  color: PQColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        _quotaChip(),
        IconButton(
          key: const ValueKey('tutor_close'),
          tooltip: strings.close,
          iconSize: 28,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.close_rounded, color: PQColors.ink),
        ),
      ],
    );
  }

  Widget _quotaChip() {
    final session = widget.services.tutor;
    if (!session.hasAi) {
      return _Tag(
        key: const ValueKey('tutor_offline_tag'),
        text: _s.labelOffline,
        colour: PQColors.inkSoft,
      );
    }
    final empty = session.quotaEmpty;
    return _Tag(
      key: const ValueKey('tutor_quota'),
      text: _s.quotaLeft(session.quotaLeft, session.quotaLimit),
      colour: empty ? PQColors.coralDeep : PQColors.seaDeep,
    );
  }

  Widget _transcript(bool busy) {
    if (_lines.isEmpty && !busy) {
      return Align(
        alignment: Alignment.topLeft,
        child: SpeechBubble(
          character: widget.character,
          mood: _mood,
          showPortrait: false,
          text: CastDialogue.line(_member.id, DialogueMoment.greet, _lang),
        ),
      );
    }
    return ListView.builder(
      key: const ValueKey('tutor_transcript'),
      controller: _scroll,
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 4),
      itemCount: _lines.length + (busy ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= _lines.length) return _thinkingBubble();
        final line = _lines[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (line.question.trim().isNotEmpty) _questionBubble(line.question),
              _answerBubble(line.reply, i),
            ],
          ),
        );
      },
    );
  }

  Widget _questionBubble(String question) => Padding(
        padding: const EdgeInsets.only(left: 46, bottom: 6),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: PQColors.parchmentDeep,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(4),
              ),
              border: Border.all(color: PQColors.parchmentEdge, width: 2),
            ),
            child: Text(
              question,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, color: PQColors.ink),
            ),
          ),
        ),
      );

  Widget _answerBubble(TutorReply reply, int index) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CharacterView(id: widget.character, size: 40, mood: Mood.happy, animate: false),
        const SizedBox(width: 6),
        Expanded(
          child: PQPanel(
            key: ValueKey('tutor_answer_$index'),
            color: PQColors.cream,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (reply.hintLevel != null) ...[
                  _Tag(
                    key: ValueKey('tutor_hint_level_$index'),
                    text: '${_s.hintLadder}: ${reply.hintLevel!.label(_lang)}',
                    colour: PQColors.grapeDeep,
                  ),
                  const SizedBox(height: 6),
                ],
                TutorAnswerText(
                  key: ValueKey('tutor_answer_text_$index'),
                  text: reply.text,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Tag(
                      key: ValueKey('tutor_source_$index'),
                      text: reply.isAi
                          ? '${_s.labelAiWritten} · ${_member.name}'
                          : reply.source.label(_s),
                      colour: reply.isAi ? PQColors.seaDeep : PQColors.inkSoft,
                    ),
                  ],
                ),
                if (reply.source.isOffline) ...[
                  const SizedBox(height: 8),
                  _FallbackNotice(
                    key: ValueKey('tutor_fallback_$index'),
                    text: reply.failKind == null
                        ? _s.offlineNoFakeAi
                        : '${reply.failKind!.message(_s)}\n${_s.offlineNoFakeAi}',
                    canRetry: reply.failKind != null &&
                        reply.failKind != TutorFailKind.notConfigured &&
                        widget.services.tutor.hasAi,
                    retryLabel: _s.retry,
                    onRetry: _retryLast,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _thinkingBubble() {
    return Row(
      children: [
        CharacterView(id: widget.character, size: 40, mood: Mood.thinking),
        const SizedBox(width: 6),
        PQPanel(
          color: PQColors.cream,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ThinkingDots(),
              const SizedBox(width: 10),
              Text(
                '${_member.name} ${_s.thinking}',
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: PQColors.inkSoft),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickActions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final action in TutorQuickAction.values)
          _QuickChip(
            key: ValueKey('tutor_quick_${action.name}'),
            label: action.label(_s),
            onTap: () => _send(action.question(_lang), action),
          ),
        _QuickChip(
          key: const ValueKey('tutor_hint_ladder'),
          label: _s.hintLadder,
          icon: Icons.stairs_rounded,
          onTap: _askHint,
        ),
      ],
    );
  }

  Widget _composer(bool busy) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: PQColors.cream,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: PQColors.ink, width: 2.2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              key: const ValueKey('tutor_input'),
              controller: _input,
              focusNode: _focus,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 15, color: PQColors.ink),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: _s.askPlaceholder,
                hintStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: PQColors.inkFaint,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ChunkyButton(
          key: const ValueKey('tutor_send'),
          label: _s.send,
          icon: Icons.send_rounded,
          size: ChunkySize.medium,
          onPressed: busy ? null : () => _send(),
        ),
      ],
    );
  }

  Widget _footer(TutorSession session) {
    final strings = _s;
    final hasAi = widget.services.tutor.hasAi;
    final notes = <String>[
      strings.childPrivacyNote,
      strings.aiMayInventCode,
      if (hasAi) strings.aiNotice else strings.offlineNoFakeAi,
      if (hasAi && widget.services.tutor.quotaEmpty) strings.quotaEmpty,
      if (hasAi && widget.services.tutor.quotaEmpty) strings.quotaResetHint,
      strings.quotaNotForSale,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final note in notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3, right: 6),
                  child: Icon(Icons.info_outline_rounded, size: 13, color: PQColors.inkFaint),
                ),
                Expanded(
                  child: Text(
                    note,
                    key: note == notes.first ? const ValueKey('tutor_privacy_note') : null,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11.5,
                      height: 1.25,
                      color: PQColors.inkFaint,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Renders an answer: plain text plus any ```python blocks as real code views.
class TutorAnswerText extends StatelessWidget {
  const TutorAnswerText({super.key, required this.text, this.fontSize = 14.5});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final segments = _split(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final segment in segments)
          if (segment.isCode)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: CodeView(code: segment.text, fontSize: fontSize - 1),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                segment.text,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: fontSize,
                  height: 1.35,
                  color: PQColors.ink,
                ),
              ),
            ),
      ],
    );
  }

  static List<_Segment> _split(String raw) {
    final segments = <_Segment>[];
    final pattern = RegExp(r'```(?:python|py)?\s*\n?(.*?)```', dotAll: true);
    var cursor = 0;
    for (final m in pattern.allMatches(raw)) {
      if (m.start > cursor) {
        final prose = raw.substring(cursor, m.start).trim();
        if (prose.isNotEmpty) segments.add(_Segment(prose, false));
      }
      final code = (m.group(1) ?? '').trimRight();
      if (code.isNotEmpty) segments.add(_Segment(code, true));
      cursor = m.end;
    }
    final tail = raw.substring(cursor).trim();
    if (tail.isNotEmpty) segments.add(_Segment(tail, false));
    if (segments.isEmpty) segments.add(_Segment(raw.trim(), false));
    return segments;
  }
}

class _Segment {
  const _Segment(this.text, this.isCode);
  final String text;
  final bool isCode;
}

class _Tag extends StatelessWidget {
  const _Tag({super.key, required this.text, required this.colour, this.wrap = false});

  final String text;
  final Color colour;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      maxLines: wrap ? 3 : 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: colour,
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: colour.withValues(alpha: 0.45), width: 1.6),
      ),
      child: label,
    );
  }
}

/// Shown under every answer that was NOT written by the AI, and as a banner
/// when this build has no AI provider at all. The child (and the parent) must
/// never have to guess whether a sentence came from a model.
class _FallbackNotice extends StatelessWidget {
  const _FallbackNotice({
    super.key,
    required this.text,
    required this.canRetry,
    required this.retryLabel,
    required this.onRetry,
  });

  final String text;
  final bool canRetry;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: PQColors.sun.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PQColors.sunDeep.withValues(alpha: 0.55), width: 1.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2, right: 6),
            child: Icon(Icons.cloud_off_rounded, size: 16, color: PQColors.sunDeep),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12.5,
                height: 1.3,
                fontWeight: FontWeight.w700,
                color: PQColors.inkSoft,
              ),
            ),
          ),
          if (canRetry) ...[
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: TextButton(
                key: const ValueKey('tutor_retry'),
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  backgroundColor: PQColors.cream,
                  foregroundColor: PQColors.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: PQColors.ink, width: 1.8),
                  ),
                ),
                child: Text(
                  retryLabel,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({super.key, required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Material(
        color: PQColors.parchmentDeep,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PQColors.parchmentEdge, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: PQColors.inkSoft),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: PQColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Three dots that keep moving while an answer is on its way.
class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Opacity(
                opacity: 0.35 + 0.65 * (0.5 + 0.5 * math.sin((_c.value * 2 * math.pi) - i * 0.6)),
                child: const CircleAvatar(radius: 4, backgroundColor: PQColors.inkSoft),
              ),
            ),
        ],
      ),
    );
  }
}
