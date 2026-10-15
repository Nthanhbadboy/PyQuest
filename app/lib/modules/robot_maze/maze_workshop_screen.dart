import 'dart:collection';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/settings_sheet.dart';
import '../../core/audio_service.dart';
import '../../core/events.dart';
import '../../data/repositories/state_repositories.dart';
import '../../shared/characters/characters.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/game_icons.dart';
import '../../shared/widgets/reward_toast.dart';
import '../../shared/widgets/transitions.dart';
import 'maze_board.dart';
import 'maze_models.dart';
import 'maze_play_screen.dart';

enum _Tool { wall, water, gem, start, chest, erase }

extension on _Tool {
  String get label => switch (this) {
        _Tool.wall => 'Bụi cây',
        _Tool.water => 'Nước',
        _Tool.gem => 'Đá quý',
        _Tool.start => 'Robo',
        _Tool.chest => 'Rương',
        _Tool.erase => 'Tẩy',
      };
}

/// Creator Mode for Robot Maze: design a maze, set its rules, prove it can be
/// solved (blocks or Python), and keep it in your collection.
class MazeWorkshopScreen extends StatefulWidget {
  const MazeWorkshopScreen({super.key});

  @override
  State<MazeWorkshopScreen> createState() => _MazeWorkshopScreenState();
}

class _MazeWorkshopScreenState extends State<MazeWorkshopScreen> with SingleTickerProviderStateMixin {
  static const _template = ['S.....', '.##.#.', '......', '.#.##.', '...*..', '.....C'];

  late final AnimationController _time = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late List<List<String>> _grid = _toGrid(_template);
  final TextEditingController _name = TextEditingController(text: 'Mê cung của tôi');
  int _limit = 10;
  bool _loops = true;
  _Tool _tool = _Tool.wall;
  int? _id;
  bool _verified = false;
  bool _dirty = false;
  List<CustomLevel> _saved = [];
  late MazePlayback _pb = MazePlayback(_level)..reset(_level);
  final GlobalKey _boardKey = GlobalKey();

  static List<List<String>> _toGrid(List<String> rows) => [for (final r in rows) r.split('')];

  MazeLevel get _level => MazeLevel.fromRows(
        id: 'draft',
        title: _name.text.trim().isEmpty ? 'Mê cung của tôi' : _name.text.trim(),
        rows: [for (final r in _grid) r.join()],
        commandLimit: _limit,
        allowLoops: _loops,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSaved());
  }

  @override
  void dispose() {
    _time.dispose();
    _name.dispose();
    _pb.dispose();
    super.dispose();
  }

  Future<void> _loadSaved() async {
    final list = await AppScope.of(context).customLevels.list(RobotMazeContent.gameId);
    if (mounted) setState(() => _saved = list);
  }

  void _refreshBoard() {
    final old = _pb;
    _pb = MazePlayback(_level)..reset(_level);
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  void _paintAt(Offset local, Size size) {
    final lvl = _level;
    final g = MazeBoardPainter.geometry(lvl, size);
    final x = ((local.dx - g.origin.dx) / g.cell).floor();
    final y = ((local.dy - g.origin.dy) / g.cell).floor();
    if (x < 0 || y < 0 || x >= lvl.width || y >= lvl.height) return;
    final current = _grid[y][x];
    String next;
    switch (_tool) {
      case _Tool.wall:
        next = '#';
      case _Tool.water:
        next = '~';
      case _Tool.gem:
        next = '*';
      case _Tool.erase:
        next = '.';
      case _Tool.start:
      case _Tool.chest:
        final mark = _tool == _Tool.start ? 'S' : 'C';
        for (final row in _grid) {
          for (var i = 0; i < row.length; i++) {
            if (row[i] == mark) row[i] = '.';
          }
        }
        next = mark;
    }
    if (current == next) return;
    if ((current == 'S' || current == 'C') && _tool != _Tool.start && _tool != _Tool.chest) return;
    setState(() {
      _grid[y][x] = next;
      _dirty = true;
      _verified = false;
      _refreshBoard();
    });
    AppScope.of(context).audio.play(Sfx.pop, volume: 0.5);
  }

  void _resize(int w, int h) {
    setState(() {
      final g = List.generate(h, (y) => List.generate(w, (x) => (y < _grid.length && x < _grid[0].length) ? _grid[y][x] : '.'));
      final flat = g.expand((r) => r).toList();
      if (!flat.contains('S')) g[0][0] = 'S';
      if (!flat.contains('C')) g[h - 1][w - 1] = 'C';
      _grid = g;
      _dirty = true;
      _verified = false;
      _refreshBoard();
    });
  }

  /// BFS: is the chest reachable at all?
  bool _solvable(MazeLevel lvl) {
    final seen = <Cell>{lvl.start};
    final queue = Queue<Cell>()..add(lvl.start);
    while (queue.isNotEmpty) {
      final c = queue.removeFirst();
      if (c == lvl.goal) return true;
      for (final d in Dir.values) {
        final n = Cell(c.x + d.dx, c.y + d.dy);
        if (!lvl.inside(n) || seen.contains(n) || lvl.tileAt(n) != Tile.floor) continue;
        seen.add(n);
        queue.add(n);
      }
    }
    return false;
  }

  Future<int> _save({bool? verified}) async {
    final s = AppScope.of(context);
    final lvl = _level;
    final id = await s.customLevels.save(
      id: _id,
      gameId: RobotMazeContent.gameId,
      name: lvl.title,
      data: lvl.toJson(),
      verified: verified ?? _verified,
      at: s.clock.now(),
    );
    _id = id;
    _dirty = false;
    await _loadSaved();
    return id;
  }

  Future<void> _testRun({bool code = false}) async {
    final s = AppScope.of(context);
    final lvl = _level;
    if (!_solvable(lvl)) {
      s.audio.play(Sfx.bonk);
      _toast('Chưa có đường nào từ Robo tới rương! Hãy mở một lối đi nhé.');
      return;
    }
    final id = await _save();
    if (!mounted) return;
    final result = await Navigator.of(context).push<Object?>(
      CloudRoute(
        builder: (_) => MazePlayScreen(level: MazeLevel.fromCustomJson(id, lvl.toJson()), customId: id, startInCode: code),
        calm: s.settings.calmMode,
      ),
    );
    final report = readCustomRunReport(result);
    if (!mounted || report == null || !report.won) return;
    final firstVerify = !_verified;
    setState(() => _verified = true);
    await _save(verified: true);
    final notices = [...report.notices];
    if (firstVerify) {
      final outcome = await s.events.emit(StandardEvent(
        type: EventTypes.customGameVerified,
        sourceId: RobotMazeContent.gameId,
        data: {'custom_id': id},
      ));
      notices.addAll(outcome.notices);
    }
    if (!mounted) return;
    s.audio.play(Sfx.success);
    _toast('Tuyệt! Mê cung "${lvl.title}" đã được chứng minh là giải được.');
    if (notices.isNotEmpty) showRewardToasts(context, notices);
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: PQColors.ink,
      content: Text(text, style: PQText.bodyStrong.copyWith(color: Colors.white)),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _newMaze() {
    setState(() {
      _grid = _toGrid(_template);
      _name.text = 'Mê cung mới';
      _limit = 10;
      _loops = true;
      _id = null;
      _verified = false;
      _dirty = false;
      _refreshBoard();
    });
  }

  void _load(CustomLevel c) {
    final rows = (c.data['rows'] as List).cast<String>();
    setState(() {
      _grid = _toGrid(rows);
      _name.text = c.name;
      _limit = (c.data['command_limit'] as num?)?.toInt() ?? 10;
      _loops = c.data['allow_loops'] as bool? ?? true;
      _id = c.id;
      _verified = c.verified;
      _dirty = false;
      _refreshBoard();
    });
  }

  Future<void> _openList() async {
    await _loadSaved();
    if (!mounted) return;
    final picked = await showPQSheet<CustomLevel>(
      context,
      builder: (ctx) => _SavedList(
        saved: _saved,
        onDelete: (c) async {
          await AppScope.of(context).customLevels.delete(c.id);
          if (_id == c.id) _id = null;
          await _loadSaved();
        },
      ),
    );
    if (picked != null) _load(picked);
  }

  @override
  Widget build(BuildContext context) {
    final lvl = _level;
    return Scaffold(
      body: PQBackground(
        top: const Color(0xFFE2D9FF),
        bottom: const Color(0xFFF6F0DA),
        child: SafeArea(
          child: Column(
            children: [
              PQTopBar(
                title: 'Xưởng Mê Cung',
                subtitle: _verified ? 'Đã chứng minh giải được' : (_dirty ? 'Chưa lưu' : 'Chế độ sáng tạo'),
                tone: PQTone.grape,
                trailing: [
                  RoundIconButton(
                    key: const ValueKey('workshop_list'),
                    icon: Icons.folder_open_rounded,
                    tooltip: 'Mê cung của tôi',
                    size: 46,
                    badge: _saved.length,
                    onPressed: _openList,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: PQColors.cream,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: PQColors.ink, width: 2.2),
                        ),
                        alignment: Alignment.centerLeft,
                        child: TextField(
                          key: const ValueKey('workshop_name'),
                          controller: _name,
                          maxLength: 28,
                          style: PQText.bodyStrong,
                          decoration: const InputDecoration.collapsed(hintText: 'Tên mê cung').copyWith(counterText: ''),
                          onChanged: (_) => setState(() => _dirty = true),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SizePicker(
                      width: lvl.width,
                      height: lvl.height,
                      onChanged: _resize,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(builder: (context, c) {
                  final size = Size(c.maxWidth - 16, c.maxHeight);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: GestureDetector(
                      key: _boardKey,
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) => _paintAt(d.localPosition, size),
                      onPanStart: (d) => _paintAt(d.localPosition, size),
                      onPanUpdate: (d) => _paintAt(d.localPosition, size),
                      child: CustomPaint(
                        size: size,
                        painter: MazeBoardPainter(level: lvl, playback: _pb, time: _time, editorMode: true),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(
                height: 70,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                  children: [
                    for (final t in _Tool.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _ToolChip(
                          key: ValueKey('tool_${t.name}'),
                          tool: t,
                          selected: t == _tool,
                          onTap: () => setState(() => _tool = t),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 4),
                child: Row(
                  children: [
                    Text('Giới hạn 3 sao:', style: PQText.small),
                    const SizedBox(width: 6),
                    _Stepper(
                      value: _limit,
                      onChanged: (v) => setState(() {
                        _limit = v.clamp(3, 20);
                        _dirty = true;
                        _verified = false;
                      }),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() {
                        _loops = !_loops;
                        _dirty = true;
                      }),
                      child: Row(
                        children: [
                          Text('Khối Lặp', style: PQText.small),
                          const SizedBox(width: 6),
                          PQToggle(value: _loops),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: ChunkyButton(
                        key: const ValueKey('workshop_new'),
                        label: 'Mới',
                        icon: Icons.add_rounded,
                        tone: PQTone.parchment,
                        size: ChunkySize.medium,
                        expand: true,
                        onPressed: _newMaze,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChunkyButton(
                        key: const ValueKey('workshop_code'),
                        label: 'Code',
                        icon: Icons.code_rounded,
                        tone: PQTone.py,
                        size: ChunkySize.medium,
                        expand: true,
                        onPressed: () => _testRun(code: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ChunkyButton(
                        key: const ValueKey('workshop_test'),
                        label: 'Chạy thử',
                        icon: Icons.play_arrow_rounded,
                        tone: PQTone.grass,
                        size: ChunkySize.medium,
                        expand: true,
                        onPressed: () => _testRun(),
                      ),
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

class _ToolChip extends StatelessWidget {
  const _ToolChip({super.key, required this.tool, required this.selected, required this.onTap});
  final _Tool tool;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget icon = switch (tool) {
      _Tool.wall => const Icon(Icons.park_rounded, color: Color(0xFF3E8F35), size: 26),
      _Tool.water => const Icon(Icons.water_rounded, color: PQColors.seaDeep, size: 26),
      _Tool.gem => const GameIcon(GameIconKind.gem, size: 24),
      _Tool.start => const SizedBox(width: 28, height: 28, child: CharacterView(id: CharacterId.robo, size: 28, animate: false)),
      _Tool.chest => const GameIcon(GameIconKind.chest, size: 24),
      _Tool.erase => const Icon(Icons.cleaning_services_rounded, color: PQColors.inkSoft, size: 24),
    };
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 66,
        decoration: BoxDecoration(
          color: selected ? PQColors.sun : PQColors.cream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PQColors.ink, width: selected ? 3 : 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            Text(tool.label, style: PQText.small.copyWith(fontSize: 12, height: 1.1)),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RoundIconButton(icon: Icons.remove_rounded, size: 34, onPressed: () => onChanged(value - 1)),
        SizedBox(width: 34, child: Text('$value', textAlign: TextAlign.center, style: PQText.number)),
        RoundIconButton(icon: Icons.add_rounded, size: 34, onPressed: () => onChanged(value + 1)),
      ],
    );
  }
}

class _SizePicker extends StatelessWidget {
  const _SizePicker({required this.width, required this.height, required this.onChanged});
  final int width;
  final int height;
  final void Function(int w, int h) onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Kích thước',
      onSelected: (n) => onChanged(n, n),
      itemBuilder: (ctx) => [
        for (final n in const [4, 5, 6]) PopupMenuItem(value: n, child: Text('$n × $n', style: PQText.bodyStrong)),
      ],
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: PQColors.cream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PQColors.ink, width: 2.2),
        ),
        child: Row(
          children: [
            const Icon(Icons.grid_on_rounded, size: 20, color: PQColors.inkSoft),
            const SizedBox(width: 4),
            Text('$width×$height', style: PQText.bodyStrong),
          ],
        ),
      ),
    );
  }
}

class _SavedList extends StatefulWidget {
  const _SavedList({required this.saved, required this.onDelete});
  final List<CustomLevel> saved;
  final Future<void> Function(CustomLevel) onDelete;

  @override
  State<_SavedList> createState() => _SavedListState();
}

class _SavedListState extends State<_SavedList> {
  late List<CustomLevel> _items = List.of(widget.saved);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Mê cung của tôi', style: PQText.h2),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            Text('Bạn chưa lưu mê cung nào. Hãy thiết kế rồi bấm "Chạy thử" nhé!', style: PQText.body),
          for (final c in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PQPanel(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(c.verified ? Icons.verified_rounded : Icons.edit_note_rounded,
                        color: c.verified ? PQColors.success : PQColors.inkFaint, size: 30),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: PQText.bodyStrong),
                          Text(c.verified ? 'Đã giải được' : 'Chưa chứng minh', style: PQText.small),
                        ],
                      ),
                    ),
                    ChunkyButton(
                      label: 'Mở',
                      size: ChunkySize.small,
                      tone: PQTone.grape,
                      onPressed: () => Navigator.of(context).pop(c),
                    ),
                    const SizedBox(width: 6),
                    RoundIconButton(
                      icon: Icons.delete_rounded,
                      size: 40,
                      tone: PQTone.danger,
                      tooltip: 'Xoá',
                      onPressed: () async {
                        await widget.onDelete(c);
                        setState(() => _items.removeWhere((x) => x.id == c.id));
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
