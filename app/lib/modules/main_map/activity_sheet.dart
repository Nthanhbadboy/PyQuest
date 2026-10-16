import 'package:flutter/material.dart';

import '../../app/activity.dart';
import '../../shared/characters/characters.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/game_icons.dart';

/// Bottom sheet shown when a place on the map is tapped.
/// Pops with `open` or `lesson:<id>`.
class ActivitySheet extends StatelessWidget {
  const ActivitySheet({super.key, required this.module, required this.status});
  final ActivityModule module;
  final ActivityStatus status;

  @override
  Widget build(BuildContext context) {
    final def = module.def;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: PQColors.ink, width: 2.6),
                  boxShadow: [BoxShadow(color: def.tone.depth, offset: const Offset(0, 4), blurRadius: 0)],
                  image: DecorationImage(image: AssetImage(def.thumbnail), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(def.name, style: PQText.h2),
                    Text(def.tagline, style: PQText.small.copyWith(color: def.tone.depth)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        PillTag(
                          label: def.needsPython ? 'Học Python' : 'Không cần biết Python',
                          color: def.needsPython ? PQColors.pyBlue : PQColors.grass,
                          icon: def.needsPython ? Icons.code_rounded : Icons.sports_esports_rounded,
                        ),
                        if (def.hasCreatorMode)
                          const PillTag(label: 'Có Xưởng sáng tạo', color: PQColors.grape, icon: Icons.construction_rounded),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SpeechBubble(character: def.host, text: def.description, portraitSize: 72, mood: status.locked ? Mood.thinking : Mood.happy),
          const SizedBox(height: 14),
          if (status.locked)
            PQPanel(
              color: const Color(0xFFFFF0E0),
              child: Row(
                children: [
                  const GameIcon(GameIconKind.lock, size: 40),
                  const SizedBox(width: 12),
                  Expanded(child: Text(status.lockReason ?? 'Chưa mở.', style: PQText.bodyStrong)),
                ],
              ),
            )
          else
            PQPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Tiến trình', style: PQText.h3),
                      const Spacer(),
                      if (status.stars != null) ...[
                        const StarIcon(size: 22),
                        const SizedBox(width: 4),
                        Text('${status.stars}', style: PQText.number.copyWith(fontSize: 20)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(status.progressLabel, style: PQText.bodyStrong),
                  for (final line in status.detailLines)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(line, style: PQText.body.copyWith(fontSize: 15.5)),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          if (status.locked && status.unlockLessonId != null)
            ChunkyButton(
              key: const ValueKey('sheet_go_lesson'),
              label: 'Đi tới bài học',
              icon: Icons.school_rounded,
              tone: PQTone.py,
              expand: true,
              onPressed: () => Navigator.of(context).pop('lesson:${status.unlockLessonId}'),
            )
          else if (!status.locked)
            ChunkyButton(
              key: const ValueKey('sheet_open'),
              label: 'Vào ${def.name}',
              icon: Icons.play_arrow_rounded,
              tone: def.tone,
              expand: true,
              onPressed: () => Navigator.of(context).pop('open'),
            ),
          const SizedBox(height: 10),
          ChunkyButton(
            label: 'Để sau',
            tone: PQTone.parchment,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
