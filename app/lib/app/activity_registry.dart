import '../modules/achievements/achievement_house_module.dart';
import '../modules/bug_hunter/bug_hunter_module.dart';
import '../modules/catch_stars/catch_stars_module.dart';
import '../modules/dragon_jump/dragon_jump_module.dart';
import '../modules/main_quest/main_quest_module.dart';
import '../modules/robot_maze/robot_maze_module.dart';
import 'activity.dart';

/// Places on Đảo Khởi Đầu (Starter Island). Order = guide priority.
final List<ActivityModule> activityRegistry = [
  MainQuestModule(),
  RobotMazeModule(),
  DragonJumpModule(),
  CatchStarsModule(),
  BugHunterModule(),
  AchievementHouseModule(),
];

ActivityModule? activityById(String id) {
  for (final m in activityRegistry) {
    if (m.def.id == id) return m;
  }
  return null;
}
