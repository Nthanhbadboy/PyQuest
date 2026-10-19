(function(r){const c={
  "gameId": "robot_maze",
  "levels": [
    {
      "id": "rm_01",
      "number": 1,
      "title": {
        "vi": "Bước đi đầu tiên",
        "en": "First steps"
      },
      "story": {
        "vi": "Rương báu ở ngay phía trước! Hãy xếp các mũi tên để Robo đi tới rương.",
        "en": "The treasure chest is just ahead. Arrange the arrows to guide Robo to it."
      },
      "rows": [
        "#####",
        "S...C",
        "#####"
      ],
      "commandLimit": 4,
      "allowLoops": false,
      "gems": 0
    },
    {
      "id": "rm_02",
      "number": 2,
      "title": {
        "vi": "Rẽ ở góc đường",
        "en": "Turn the corner"
      },
      "story": {
        "vi": "Đường đi có một khúc rẽ. Nhặt viên đá quý trên đường nữa nhé!",
        "en": "There is a turn in the path. Pick up the gem along the way!"
      },
      "rows": [
        "S.*.",
        "###.",
        "###.",
        "###C"
      ],
      "commandLimit": 6,
      "allowLoops": false,
      "gems": 1
    },
    {
      "id": "rm_03",
      "number": 3,
      "title": {
        "vi": "Lối đi quanh co",
        "en": "The winding path"
      },
      "story": {
        "vi": "Bụi cây chắn đường rồi! Tìm lối đi vòng qua chúng.",
        "en": "Hedges block the way. Find a route around them."
      },
      "rows": [
        "S.#..",
        ".*#.#",
        "..#.C",
        "#...#"
      ],
      "commandLimit": 8,
      "allowLoops": false,
      "gems": 1
    },
    {
      "id": "rm_04",
      "number": 4,
      "title": {
        "vi": "Cẩn thận có nước!",
        "en": "Watch out for water!"
      },
      "story": {
        "vi": "Robo không biết bơi! Đường ngắn thì dễ, nhưng đá quý lại nằm ở đường xa hơn.",
        "en": "Robo cannot swim. A short route is easy, but the gem is on the longer route."
      },
      "rows": [
        "S..~..",
        ".#.~.#",
        ".#...C",
        ".#~~.#",
        "..*..."
      ],
      "commandLimit": 11,
      "allowLoops": false,
      "gems": 1
    },
    {
      "id": "rm_05",
      "number": 5,
      "title": {
        "vi": "Hai viên ngọc",
        "en": "Two gems"
      },
      "story": {
        "vi": "Có hai viên ngọc trong khu vườn. Bạn lấy được cả hai không?",
        "en": "There are two gems in the garden. Can you collect both?"
      },
      "rows": [
        "S.#.C",
        ".*#..",
        "..#*.",
        "#...."
      ],
      "commandLimit": 10,
      "allowLoops": false,
      "gems": 2
    },
    {
      "id": "rm_06",
      "number": 6,
      "title": {
        "vi": "Lặp lại cho nhanh",
        "en": "Repeat to go faster"
      },
      "story": {
        "vi": "Đường dài quá! Khối Lặp lại giúp Robo làm một việc nhiều lần mà bạn chỉ cần viết một lần.",
        "en": "A long path! Repeat blocks let Robo do the same thing several times."
      },
      "rows": [
        "######",
        "S*...C",
        "######"
      ],
      "commandLimit": 2,
      "allowLoops": true,
      "gems": 1
    },
    {
      "id": "rm_07",
      "number": 7,
      "title": {
        "vi": "Cầu thang",
        "en": "Staircase"
      },
      "story": {
        "vi": "Những bậc thang giống hệt nhau... Có mẫu nào lặp lại không nhỉ?",
        "en": "These steps look alike. Can you spot a repeating pattern?"
      },
      "rows": [
        "S.###",
        "#..##",
        "##.*#",
        "###..",
        "####C"
      ],
      "commandLimit": 3,
      "allowLoops": true,
      "gems": 1
    },
    {
      "id": "rm_08",
      "number": 8,
      "title": {
        "vi": "Vòng quanh hồ",
        "en": "Around the lake"
      },
      "story": {
        "vi": "Có hai con đường quanh hồ nước. Chỉ một đường có đá quý thôi!",
        "en": "Two paths go around the lake. Only one has a gem."
      },
      "rows": [
        "S....*",
        ".~~~~.",
        ".~~~~.",
        ".~~~~.",
        ".~~~~.",
        ".....C"
      ],
      "commandLimit": 4,
      "allowLoops": true,
      "gems": 1
    },
    {
      "id": "rm_09",
      "number": 9,
      "title": {
        "vi": "Bậc thang đôi",
        "en": "Double staircase"
      },
      "story": {
        "vi": "Lần này mỗi bậc thang rộng gấp đôi. Mẫu lặp lại là gì?",
        "en": "Each stair is twice as wide. What is the repeating pattern?"
      },
      "rows": [
        "S..###",
        "##.###",
        "##.*.#",
        "#~##.#",
        "####.C"
      ],
      "commandLimit": 6,
      "allowLoops": true,
      "gems": 1
    },
    {
      "id": "rm_10",
      "number": 10,
      "title": {
        "vi": "Đường rắn Py",
        "en": "The Python path"
      },
      "story": {
        "vi": "Con đường uốn lượn như thầy Py! Đây là thử thách lớn nhất của khu vườn.",
        "en": "A winding path like teacher Py. The garden’s biggest challenge."
      },
      "rows": [
        "S....*",
        "#####.",
        "..*...",
        ".#####",
        "....*.",
        "#####C"
      ],
      "commandLimit": 11,
      "allowLoops": true,
      "gems": 3
    }
  ],
  "costs": {
    "new": 2,
    "replay": 0,
    "creator": 0
  },
  "maxInitial": 20
};if(typeof module!=="undefined")module.exports=c;r.MazeCatalog=c;})(globalThis);
