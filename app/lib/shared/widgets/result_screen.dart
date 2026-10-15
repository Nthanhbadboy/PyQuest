import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/audio_service.dart';
import '../../core/events.dart';
import '../../modules/achievements/achievement_catalog.dart';
import '../characters/characters.dart';
import '../theme/app_theme.dart';
import '../theme/palette.dart';
import 'chunky_button.dart';
import 'common.dart';
import 'confetti.dart';
import 'game_icons.dart';
import 'transitions.dart';

class ResultGoal {
  const ResultGoal(this.label, this.achieved);
  final String label;
  final bool achieved;
}

class ResultStat {
  const ResultStat(this.label, this.value, {this.icon});
  final String label;
  final String value;
  final GameIconKind? icon;
}

/// Data for the shared "Màn tổng kết" (level summary) screen.
class LevelResultData {
  const LevelResultData({
    required this.gameName,
    required this.levelTitle,
    required this.success,
    required this.stars,
    required this.host,
    required this.hostLine,
    this.score,
    this.bestScore,
    this.newBest = false,
    this.goals = const [],
    this.stats = const [],
    this.skill,
    this.notices = const [],
    this.primaryLabel,
    this.primaryCost = 0,
    this.tone = PQTone.grass,
  });

  final String gameName;
  final String levelTitle;
  final bool success;
  final int stars;
  final int? score;
  final int? bestScore;
  final bool newBest;
  final List<ResultGoal> goals;
  final List<ResultStat> stats;
  final String? skill;
  final CharacterId host;
  final String hostLine;
  final List<RewardNotice> notices;

  /// Label of the main button (e.g. "Màn tiếp theo", "Chơi lại"). Null hides it.
  final String? primaryLabel;
  final int primaryCost;
  final PQTone tone;
}

enum ResultAction { primary, replay, back, map }

/// Shows the summary screen and returns what the child picked.
Future<ResultAction> showLevelResult(BuildContext context, LevelResultData data) async {
  final calm = AppScope.of(context).settings.calmMode;
  final action = await Navigator.of(context).push<ResultAction>(
    CloudRoute(builder: (_) => LevelResultScreen(data: data), calm: calm),
  );
  return action ?? ResultAction.back;
}

class LevelResultScreen extends StatefulWidget {
  const LevelResultScreen({super.key, required this.data});
  final LevelResultData data;

  @override
  State<LevelResultScreen> createState() => _LevelResultScreenState();
}

class _LevelResultScreenState extends State<LevelResultScreen> {
  final List<Timer> _timers = [];
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final audio = AppScope.maybeOf(context)?.audio;
    if (widget.data.success) {
      audio?.play(Sfx.success);
      for (var i = 0; i < widget.data.stars; i++) {
        _timers.add(Timer(Duration(milliseconds: 650 + i * 380), () => audio?.play(Sfx.star)));
      }
      if (widget.data.notices.any((n) => n.kind == RewardKind.badge)) {
        _timers.add(Timer(Duration(milliseconds: 900 + widget.data.stars * 380), () => audio?.play(Sfx.unlock)));
      }
    } else {
      audio?.play(Sfx.fail);
    }
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final calm = AppScope.of(context).settings.calmMode;
    final badges = d.notices.where((n) => n.kind == RewardKind.badge).toList();
    final others = d.notices.where((n) => n.kind != RewardKind.badge).toList();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(ResultAction.back);
      },
      child: Scaffold(
        body: PQBackground(
          top: d.success ? const Color(0xFFFFE9A8) : const Color(0xFFDDE9F7),
          child: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(d.gameName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: PQText.small.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w900, color: d.tone.depth)),
                      Text(d.levelTitle, textAlign: TextAlign.center, style: PQText.h3),
                      const SizedBox(height: 6),
                      Text(
                        d.success ? (d.stars >= 3 ? 'Hoàn hảo!' : 'Hoàn thành!') : 'Gần được rồi!',
                        key: const ValueKey('result_title'),
                        textAlign: TextAlign.center,
                        style: PQText.hero.copyWith(color: d.success ? PQColors.ink : PQColors.inkSoft),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Padding(
                              padding: EdgeInsets.only(left: 6, right: 6, top: i == 1 ? 0 : 14),
                              child: i < d.stars
                                  ? PopIn(delay: Duration(milliseconds: calm ? 0 : 600 + i * 380), child: StarIcon(size: i == 1 ? 74 : 60))
                                  : StarIcon(filled: false, size: i == 1 ? 74 : 60),
                            ),
                        ],
                      ),
                      if (d.score != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${d.score} điểm', style: PQText.h2),
                            if (d.newBest) ...[
                              const SizedBox(width: 8),
                              const PillTag(label: 'Kỷ lục mới!', color: PQColors.berry),
                            ],
                          ],
                        ),
                        if (d.bestScore != null && !d.newBest)
                          Text('Kỷ lục: ${d.bestScore}', textAlign: TextAlign.center, style: PQText.small),
                      ],
                      const SizedBox(height: 14),
                      if (d.goals.isNotEmpty)
                        PQPanel(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          child: Column(
                            children: [
                              for (var i = 0; i < d.goals.length; i++)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      StarIcon(filled: d.goals[i].achieved, size: 24),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(d.goals[i].label, style: PQText.bodyStrong.copyWith(fontSize: 16))),
                                      Icon(
                                        d.goals[i].achieved ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                        color: d.goals[i].achieved ? PQColors.success : PQColors.inkFaint,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (d.stats.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [for (final s in d.stats) _StatChip(stat: s)],
                        ),
                      ],
                      if (d.skill != null) ...[
                        const SizedBox(height: 12),
                        PQPanel(
                          color: const Color(0xFFE8F1FF),
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb_rounded, color: PQColors.sunDeep, size: 30),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Kỹ năng', style: PQText.small.copyWith(color: PQColors.pyBlue, fontWeight: FontWeight.w900)),
                                    Text(d.skill!, style: PQText.bodyStrong.copyWith(fontSize: 16)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (badges.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        for (final b in badges) _BadgeRow(notice: b),
                      ],
                      for (final n in others)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: PQPanel(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                GameIcon(n.kind == RewardKind.quest ? GameIconKind.stamp : GameIconKind.energy, size: 36),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(n.title, style: PQText.bodyStrong),
                                      Text(n.description, style: PQText.small),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      SpeechBubble(character: d.host, text: d.hostLine, mood: d.success ? Mood.happy : Mood.thinking),
                      const SizedBox(height: 18),
                      if (d.primaryLabel != null)
                        ChunkyButton(
                          key: const ValueKey('result_primary'),
                          label: d.primaryLabel!,
                          icon: Icons.play_arrow_rounded,
                          tone: d.tone,
                          expand: true,
                          trailing: d.primaryCost > 0 ? _CostBadge(cost: d.primaryCost) : null,
                          onPressed: () => Navigator.of(context).pop(ResultAction.primary),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ChunkyButton(
                              key: const ValueKey('result_back'),
                              label: 'Danh sách',
                              icon: Icons.grid_view_rounded,
                              tone: PQTone.parchment,
                              size: ChunkySize.medium,
                              expand: true,
                              onPressed: () => Navigator.of(context).pop(ResultAction.back),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ChunkyButton(
                              key: const ValueKey('result_map'),
                              label: 'Về bản đồ',
                              icon: Icons.map_rounded,
                              tone: PQTone.sea,
                              size: ChunkySize.medium,
                              expand: true,
                              onPressed: () => Navigator.of(context).pop(ResultAction.map),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (d.success && !calm) const Positioned.fill(child: ConfettiBurst()),
            ],
          ),
        ),
      ),
    );
  }
}

class _CostBadge extends StatelessWidget {
  const _CostBadge({required this.cost});
  final int cost;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(2, 1, 8, 1),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const GameIcon(GameIconKind.energy, size: 20),
          Text('$cost', style: PQText.number.copyWith(color: Colors.white, fontSize: 17)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.stat});
  final ResultStat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: PQColors.cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PQColors.ink, width: 2.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (stat.icon != null) ...[GameIcon(stat.icon!, size: 22), const SizedBox(width: 4)],
              Text(stat.value, style: PQText.number),
            ],
          ),
          Text(stat.label, style: PQText.small.copyWith(fontSize: 13)),
        ],
      ),
    );
  }
}

class _BadgeRow extends StatelessWidget {
  const _BadgeRow({required this.notice});
  final RewardNotice notice;

  @override
  Widget build(BuildContext context) {
    final def = achievementById(notice.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PopIn(
        delay: const Duration(milliseconds: 1500),
        child: PQPanel(
          color: const Color(0xFFFFF6D6),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (def != null) BadgeMedal(icon: def.icon, color: def.color, size: 62),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Huy hiệu mới!', style: PQText.small.copyWith(color: PQColors.berry, fontWeight: FontWeight.w900)),
                    Text(notice.title, style: PQText.h3),
                    Text(notice.description, style: PQText.small),
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
