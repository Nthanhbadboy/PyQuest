import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/audio_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/game_icons.dart';
import 'daily_quest_service.dart';

Future<void> showDailyQuests(BuildContext context) async {
  final s = AppScope.of(context);
  await s.quests.ensureToday();
  if (!context.mounted) return;
  await showPQSheet<void>(context, builder: (ctx) => const _DailyQuestsSheet());
}

class _DailyQuestsSheet extends StatelessWidget {
  const _DailyQuestsSheet();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return ListenableBuilder(
      listenable: s.quests,
      builder: (context, _) {
        final quests = s.quests.quests;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nhiệm vụ hôm nay', style: PQText.h2),
              Text('3 nhiệm vụ mới mỗi ngày, làm mới lúc nửa đêm. Không bắt buộc, không chuỗi ngày.',
                  style: PQText.body.copyWith(fontSize: 15.5)),
              const SizedBox(height: 14),
              for (final q in quests) ...[
                _QuestCard(state: q),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
              PQPanel(
                color: const Color(0xFFFFF0F5),
                child: Row(
                  children: [
                    const GameIcon(GameIconKind.stamp, size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Sổ tem của bạn: ${s.quests.totalStamps} tem',
                          style: PQText.bodyStrong),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.state});
  final DailyQuestState state;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final (label, color, icon) = switch (state.def.category) {
      QuestCategory.learn => ('Học', PQColors.pyBlue, Icons.school_rounded),
      QuestCategory.practice => ('Luyện tập', PQColors.coral, Icons.sports_esports_rounded),
      QuestCategory.create => ('Sáng tạo', PQColors.grape, Icons.construction_rounded),
    };
    return PQPanel(
      padding: const EdgeInsets.all(12),
      color: state.rewarded ? const Color(0xFFEFF8EA) : PQColors.cream,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: PQColors.ink, width: 2.4),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: PQText.small.copyWith(color: color, fontWeight: FontWeight.w900)),
                Text(state.def.title, style: PQText.bodyStrong.copyWith(fontSize: 16)),
                const SizedBox(height: 6),
                ChunkyProgress(value: state.progress / state.def.target, color: color, height: 12),
                const SizedBox(height: 2),
                Text('${state.progress.clamp(0, state.def.target)}/${state.def.target}', style: PQText.small.copyWith(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (state.rewarded)
            const GameIcon(GameIconKind.stamp, size: 44)
          else if (state.completed)
            ChunkyButton(
              label: 'Nhận tem',
              size: ChunkySize.small,
              tone: PQTone.grass,
              sfx: Sfx.sparkle,
              onPressed: () => s.quests.claimStamp(state.def.id),
            )
          else
            const GameIcon(GameIconKind.stamp, size: 40, dimmed: true),
        ],
      ),
    );
  }
}
