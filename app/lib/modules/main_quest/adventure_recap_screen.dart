import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../shared/characters/characters.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/game_icons.dart';
import '../achievements/achievement_catalog.dart';

/// Adventure Recap: built only from saved data (no invented facts).
class AdventureRecapScreen extends StatefulWidget {
  const AdventureRecapScreen({super.key});

  @override
  State<AdventureRecapScreen> createState() => _AdventureRecapScreenState();
}

class _RecapData {
  _RecapData({
    required this.lessons,
    required this.total,
    required this.exercises,
    required this.skills,
    required this.firstDay,
    required this.lastDay,
    required this.badges,
    required this.mazeLevels,
    required this.codeLines,
  });
  final int lessons;
  final int total;
  final int exercises;
  final List<String> skills;
  final DateTime? firstDay;
  final DateTime? lastDay;
  final List<AchievementDef> badges;
  final int mazeLevels;
  final int codeLines;
}

class _AdventureRecapScreenState extends State<AdventureRecapScreen> {
  _RecapData? _data;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_data == null) _load(AppScope.of(context));
  }

  Future<void> _load(AppServices s) async {
    final times = await s.progress.lessonCompletionTimes();
    final chapterLessons = s.mainQuest.lessons;
    final mine = {for (final l in chapterLessons) if (times.containsKey(l.id)) l.id: times[l.id]!};
    final sorted = mine.values.toList()..sort();
    final exercises = (await s.progress.claimsWithPrefix('exercise:')).where((e) => e.startsWith('mq1_')).length;
    final unlocked = s.achievements.unlocked;
    final badges = [for (final a in achievementCatalog) if (unlocked.containsKey(a.id)) a];
    final skills = [for (final l in chapterLessons) if (mine.containsKey(l.id)) l.skill];
    final lines = chapterLessons
        .where((l) => mine.containsKey(l.id))
        .expand((l) => l.steps)
        .map((st) => (st.raw['solution'] as String?) ?? '')
        .fold<int>(0, (a, code) => a + (code.isEmpty ? 0 : code.split('\n').length));
    final maze = await s.progress.completedLevelCount(gameId: 'robot_maze');
    if (!mounted) return;
    setState(() => _data = _RecapData(
          lessons: mine.length,
          total: chapterLessons.length,
          exercises: exercises,
          skills: skills,
          firstDay: sorted.isEmpty ? null : sorted.first,
          lastDay: sorted.isEmpty ? null : sorted.last,
          badges: badges,
          mazeLevels: maze,
          codeLines: lines,
        ));
  }

  String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final s = AppScope.of(context);
    return Scaffold(
      body: PQBackground(
        top: const Color(0xFFFFE6A6),
        child: SafeArea(
          child: Column(
            children: [
              PQTopBar(title: 'Hành trình Chặng ${s.mainQuest.chapterNumber}', subtitle: s.mainQuest.chapterTitle, tone: PQTone.sun),
              Expanded(
                child: d == null
                    ? const Center(child: CharacterView(id: CharacterId.py, size: 120))
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          Container(
                            key: const ValueKey('recap_25d_scene'),
                            height: 120,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7B5733),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: PQColors.ink,
                                width: 2.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: PQTone.sun.depth,
                                  offset: const Offset(0, 4),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/journal_recap_r36.webp',
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SpeechBubble(
                            character: CharacterId.py,
                            text: d.lessons == d.total
                                ? 'Nhìn lại chặng đường nào! Từ một dòng print() đầu tiên, giờ bạn đã biết ra quyết định bằng code.'
                                : 'Đây là hành trình của bạn cho tới lúc này. Cố lên, còn ${d.total - d.lessons} bài nữa thôi!',
                          ),
                          const SizedBox(height: 12),
                          if (d.firstDay != null)
                            PQPanel(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.event_rounded,
                                    color: PQColors.pyBlue,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      d.lastDay != null &&
                                              _date(d.firstDay!) !=
                                                  _date(d.lastDay!)
                                          ? 'Bắt đầu ngày ${_date(d.firstDay!)} · bài gần nhất ngày ${_date(d.lastDay!)}'
                                          : 'Học ngày ${_date(d.firstDay!)}',
                                      style: PQText.bodyStrong.copyWith(
                                        fontSize: 15.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 10),
                          GridView.count(
                            crossAxisCount:
                                MediaQuery.textScalerOf(context).scale(1) >= 1.5
                                ? 1
                                : 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio:
                                MediaQuery.textScalerOf(context).scale(1) >= 1.5
                                ? 2.4
                                : 1.6,
                            children: [
                              _Tile(
                                value: '${d.lessons}/${d.total}',
                                label: 'Bài học hoàn thành',
                                color: PQColors.pyBlue,
                              ),
                              _Tile(
                                value: '${d.exercises}',
                                label: 'Bài tập đã giải',
                                color: PQColors.grape,
                              ),
                              _Tile(
                                value: '${d.codeLines}',
                                label: 'Dòng code mẫu đã học',
                                color: PQColors.teal,
                              ),
                              _Tile(
                                value: '${d.mazeLevels}',
                                label: 'Mê cung đã vượt',
                                color: PQColors.grass,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Kỹ năng đã học', style: PQText.h3),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [for (final sk in d.skills) PillTag(label: sk, color: PQColors.pyBlue, icon: Icons.check_rounded)],
                          ),
                          const SizedBox(height: 12),
                          Text('Huy hiệu đã có (${d.badges.length})', style: PQText.h3),
                          const SizedBox(height: 6),
                          if (d.badges.isEmpty)
                            Text('Chưa có huy hiệu nào — chúng đang chờ bạn ngoài đảo!', style: PQText.body)
                          else
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final b in d.badges)
                                  SizedBox(
                                    width: 92,
                                    child: Column(
                                      children: [
                                        BadgeMedal(icon: b.icon, color: b.color, size: 64),
                                        Text(b.title, textAlign: TextAlign.center, maxLines: 2, style: PQText.small.copyWith(fontSize: 12.5)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          const SizedBox(height: 18),
                          ChunkyButton(
                            label: 'Về bản đồ',
                            icon: Icons.map_rounded,
                            tone: PQTone.sea,
                            expand: true,
                            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
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

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PQPanel(
      padding: const EdgeInsets.all(10),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: PQText.h1.copyWith(color: color, fontSize: 28)),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: PQText.small.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
