import 'package:flutter/material.dart';

import '../../core/events.dart';
import '../../shared/theme/palette.dart';

/// Read-only facts gathered from the database for badge checks.
class ProgressSnapshot {
  ProgressSnapshot({
    required this.completedLessons,
    required this.completedLevels,
    required this.threeStarLevels,
    required this.bestScores,
    required this.claimCounts,
    required this.visitedActivities,
    required this.verifiedCreations,
    required this.storeInts,
  });

  final Set<String> completedLessons;

  /// gameId -> number of completed levels.
  final Map<String, int> completedLevels;

  /// gameId -> number of 3-star levels.
  final Map<String, int> threeStarLevels;

  /// "gameId/levelId" -> best score.
  final Map<String, int> bestScores;

  /// claim prefix (e.g. `bug:`) -> count.
  final Map<String, int> claimCounts;
  final Set<String> visitedActivities;
  final int verifiedCreations;

  /// "gameId/key" -> int value from the game's private store.
  final Map<String, int> storeInts;

  int levels(String gameId) => completedLevels[gameId] ?? 0;
  int stars3(String gameId) => threeStarLevels[gameId] ?? 0;
  int claims(String prefix) => claimCounts[prefix] ?? 0;
  int totalLevels() => completedLevels.values.fold(0, (a, b) => a + b);
}

typedef AchievementCheck = bool Function(ProgressSnapshot s, StandardEvent e);

class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.howTo,
    required this.icon,
    required this.color,
    required this.check,
    this.secret = false,
    this.goal,
    this.progress,
  });

  final String id;
  final String title;

  /// Shown once unlocked.
  final String description;

  /// Shown while locked (for secret badges: a riddle-like hint).
  final String howTo;
  final IconData icon;
  final Color color;
  final AchievementCheck check;
  final bool secret;

  /// Optional numeric goal for a progress bar.
  final int? goal;
  final int Function(ProgressSnapshot s)? progress;
}

/// Badges that can actually be earned in this build. Badges for content that
/// does not exist yet (functions chapter, final project) are intentionally
/// left out instead of being shown as impossible goals.
final List<AchievementDef> achievementCatalog = [
  AchievementDef(
    id: 'first_steps',
    title: 'Bước Chân Đầu Tiên',
    description: 'Vượt qua màn chơi đầu tiên trên đảo.',
    howTo: 'Thắng một màn bất kỳ trong mini-game.',
    icon: Icons.directions_walk_rounded,
    color: PQColors.grass,
    check: (s, e) => s.totalLevels() >= 1,
  ),
  AchievementDef(
    id: 'first_line',
    title: 'Dòng Code Đầu Tiên',
    description: 'Viết dòng Python đầu tiên cùng Py.',
    howTo: 'Hoàn thành Bài 1 của Main Quest.',
    icon: Icons.code_rounded,
    color: PQColors.pyBlue,
    check: (s, e) => s.completedLessons.contains('mq1_01'),
  ),
  AchievementDef(
    id: 'maze_explorer',
    title: 'Nhà Thám Hiểm Mê Cung',
    description: 'Đưa Robo qua cả 10 mê cung.',
    howTo: 'Hoàn thành 10 màn Robot Maze.',
    icon: Icons.route_rounded,
    color: PQColors.teal,
    goal: 10,
    progress: (s) => s.levels('robot_maze'),
    check: (s, e) => s.levels('robot_maze') >= 10,
  ),
  AchievementDef(
    id: 'perfectionist',
    title: 'Hoàn Hảo',
    description: 'Đạt 3 sao ở mọi màn của một mini-game.',
    howTo: 'Đạt 3 sao ở cả 10 màn Robot Maze hoặc cả 12 câu đố Bug Hunter.',
    icon: Icons.auto_awesome_rounded,
    color: PQColors.sun,
    goal: 10,
    progress: (s) => s.stars3('robot_maze'),
    check: (s, e) => s.stars3('robot_maze') >= 10 || s.stars3('bug_hunter') >= 12,
  ),
  AchievementDef(
    id: 'loopy',
    title: 'Vòng Lặp Vui Vẻ',
    description: 'Dùng vòng lặp để giải 5 thử thách.',
    howTo: 'Giải 5 thử thách bằng khối Lặp lại hoặc vòng lặp for.',
    icon: Icons.loop_rounded,
    color: PQColors.sky,
    goal: 5,
    progress: (s) => s.claims('loop:'),
    check: (s, e) => s.claims('loop:') >= 5,
  ),
  AchievementDef(
    id: 'condition_master',
    title: 'Bậc Thầy Điều Kiện',
    description: 'Giải 10 bài tập về điều kiện if/else.',
    howTo: 'Giải 10 bài tập dùng if / elif / else.',
    icon: Icons.call_split_rounded,
    color: PQColors.grape,
    goal: 10,
    progress: (s) => s.claims('cond_ex:'),
    check: (s, e) => s.claims('cond_ex:') >= 10,
  ),
  AchievementDef(
    id: 'debugger',
    title: 'Thợ Săn Lỗi',
    description: 'Cùng Bitsy sửa 20 lỗi trong code.',
    howTo: 'Sửa 20 lỗi trong Bug Hunter.',
    icon: Icons.bug_report_rounded,
    color: PQColors.coral,
    goal: 20,
    progress: (s) => s.claims('bug:'),
    check: (s, e) => s.claims('bug:') >= 20,
  ),
  AchievementDef(
    id: 'code_apprentice',
    title: 'Code Apprentice',
    description: 'Hoàn thành Chặng 1 — trở thành Học Việc Lập Trình!',
    howTo: 'Hoàn thành cả 12 bài của Chặng 1 Main Quest.',
    icon: Icons.school_rounded,
    color: PQColors.pyYellow,
    goal: 12,
    progress: (s) => s.completedLessons.where((l) => l.startsWith('mq1_')).length,
    check: (s, e) => s.claims('chapter:code_apprentice') >= 1,
  ),
  AchievementDef(
    id: 'sky_dragon',
    title: 'Rồng Bay Cao',
    description: 'Đạt 500 điểm trong Rồng Nhảy.',
    howTo: 'Đạt 500 điểm trong một lượt Rồng Nhảy.',
    icon: Icons.local_fire_department_rounded,
    color: PQColors.coral,
    check: (s, e) => (s.bestScores['dragon_jump/run'] ?? 0) >= 500,
  ),
  AchievementDef(
    id: 'star_catcher',
    title: 'Người Hái Sao',
    description: 'Hái 40 ngôi sao trong một lượt chơi.',
    howTo: 'Hái 40 ngôi sao trong một lượt Hái Sao.',
    icon: Icons.star_rounded,
    color: PQColors.sun,
    check: (s, e) => (s.storeInts['catch_stars/best_caught'] ?? 0) >= 40,
  ),
  AchievementDef(
    id: 'maze_architect',
    title: 'Kiến Trúc Sư Mê Cung',
    description: 'Tự thiết kế một mê cung và chứng minh nó giải được.',
    howTo: 'Tạo một mê cung trong Xưởng Mê Cung rồi tự giải thành công.',
    icon: Icons.architecture_rounded,
    color: PQColors.tealDeep,
    check: (s, e) => s.verifiedCreations >= 1,
  ),
  AchievementDef(
    id: 'island_explorer',
    title: 'Nhà Thám Hiểm Đảo',
    description: 'Ghé thăm mọi địa điểm trên Đảo Khởi Đầu.',
    howTo: 'Mở cả 6 địa điểm trên bản đồ.',
    icon: Icons.explore_rounded,
    color: PQColors.sea,
    goal: 6,
    progress: (s) => s.visitedActivities.length,
    check: (s, e) => s.visitedActivities.length >= 6,
  ),
  AchievementDef(
    id: 'night_owl',
    title: 'Cú Đêm',
    description: 'Hoàn thành một bài học sau 8 giờ tối. Nhớ đi ngủ sớm nhé!',
    howTo: 'Bí mật: có gì đó xảy ra khi trời tối...',
    icon: Icons.nightlight_round,
    color: PQColors.night,
    secret: true,
    check: (s, e) => e.type == EventTypes.lessonCompleted && e.timestamp.toLocal().hour >= 20,
  ),
  AchievementDef(
    id: 'different_path',
    title: 'Lối Đi Khác',
    description: 'Giải lại một mê cung bằng một con đường hoàn toàn mới.',
    howTo: 'Bí mật: luôn có nhiều hơn một con đường...',
    icon: Icons.alt_route_rounded,
    color: PQColors.grassDeep,
    secret: true,
    check: (s, e) => e.type == EventTypes.levelCompleted && e.data['different_path'] == true,
  ),
  AchievementDef(
    id: 'loop_tamer',
    title: 'Thuần Hoá Vòng Lặp',
    description: 'Gặp một vòng lặp vô tận rồi tự sửa cho nó dừng lại.',
    howTo: 'Bí mật: có những vòng lặp không bao giờ chịu dừng...',
    icon: Icons.all_inclusive_rounded,
    color: PQColors.berry,
    secret: true,
    check: (s, e) => e.type == EventTypes.codeRun && e.data['recovered_from_limit'] == true,
  ),
];

AchievementDef? achievementById(String id) {
  for (final a in achievementCatalog) {
    if (a.id == id) return a;
  }
  return null;
}
