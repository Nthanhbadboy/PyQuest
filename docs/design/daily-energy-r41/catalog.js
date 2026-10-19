/* VI definitions/config pinned; EN DESIGN translation. No event evaluator. */
(function(g){const data={
  "quests": [
    {
      "id": "lesson_1",
      "title": {
        "vi": "Hoàn thành 1 bài học Main Quest",
        "en": "Complete 1 Main Quest lesson"
      },
      "category": "learn",
      "target": 1,
      "requiresBugHunter": false
    },
    {
      "id": "code_runs_3",
      "title": {
        "vi": "Chạy code Python 3 lần",
        "en": "Run Python code 3 times"
      },
      "category": "learn",
      "target": 3,
      "requiresBugHunter": false
    },
    {
      "id": "three_stars",
      "title": {
        "vi": "Đạt 3 sao ở một màn bất kỳ",
        "en": "Earn 3 stars in any level"
      },
      "category": "practice",
      "target": 1,
      "requiresBugHunter": false
    },
    {
      "id": "maze_2",
      "title": {
        "vi": "Vượt qua 2 màn Robot Maze",
        "en": "Complete 2 Robot Maze levels"
      },
      "category": "practice",
      "target": 2,
      "requiresBugHunter": false
    },
    {
      "id": "arcade_star",
      "title": {
        "vi": "Nhận sao trong Rồng Nhảy hoặc Hái Sao",
        "en": "Earn a star in Dragon Jump or Catch Stars"
      },
      "category": "practice",
      "target": 1,
      "requiresBugHunter": false
    },
    {
      "id": "bug_1",
      "title": {
        "vi": "Sửa 1 lỗi cùng Bitsy",
        "en": "Fix 1 bug with Bitsy"
      },
      "category": "practice",
      "target": 1,
      "requiresBugHunter": true
    },
    {
      "id": "creator_test",
      "title": {
        "vi": "Chạy thử một mê cung trong Xưởng Mê Cung",
        "en": "Test a maze in the Maze Workshop"
      },
      "category": "create",
      "target": 1,
      "requiresBugHunter": false
    },
    {
      "id": "robot_code",
      "title": {
        "vi": "Điều khiển Robo bằng code Python",
        "en": "Control Robo with Python code"
      },
      "category": "create",
      "target": 1,
      "requiresBugHunter": false
    }
  ],
  "energy": {
    "max_initial": 20,
    "max_cap": 40,
    "regen_minutes_per_unit": 10,
    "milestone_bonus": {
      "chapter:code_apprentice": 5
    }
  },
  "costs": {
    "mini_game_new_level": 2,
    "mini_game_replay_completed": 0,
    "arcade_run": 2,
    "creator_mode": 0,
    "main_quest_lesson_first": 1,
    "main_quest_review": 0,
    "chapter_challenge_first": 3
  }
};if(typeof module!=="undefined")module.exports=data;g.DailyCatalog=data})(typeof window!=="undefined"?window:globalThis);
