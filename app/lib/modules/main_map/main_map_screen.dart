import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/activity.dart';
import '../../app/activity_registry.dart';
import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/settings_sheet.dart';
import '../../core/audio_service.dart';
import '../../core/events.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/characters/characters.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/reward_toast.dart';
import '../../shared/widgets/transitions.dart';
import '../daily_quests/daily_quests_sheet.dart';
import '../energy/energy_widgets.dart';
import '../main_quest/main_quest_module.dart';
import 'activity_sheet.dart';
import 'main_map_scene.dart';
import 'main_map_scene_state.dart';

/// The Main Map is a static R1-A scene with real routes to the existing activities.
class MainMapScreen extends StatefulWidget {
  const MainMapScreen({super.key});

  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends State<MainMapScreen> {
  AppServices? _services;
  MainMapSceneStatusController? _placeStatuses;
  final ScrollController _villageScroll = ScrollController();
  final ScrollController _directoryScroll = ScrollController();
  final Map<String, FocusNode> _placeFocus = <String, FocusNode>{
    for (final ActivityModule module in activityRegistry)
      module.def.id: FocusNode(debugLabel: 'main-map-${module.def.id}'),
  };
  bool _directoryMode = false;
  bool _modeChosenByUser = false;
  bool _modeInitialized = false;
  double? _lastTextScale;
  bool _routeBusy = false;
  bool _refreshPending = false;
  bool _introShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double textScale = MediaQuery.textScalerOf(context).scale(1);
    if (!_modeInitialized || _lastTextScale != textScale) {
      if (!_modeChosenByUser) _directoryMode = textScale >= 1.5;
      _modeInitialized = true;
      _lastTextScale = textScale;
    }

    final AppServices services = AppScope.of(context);
    if (_services != services) {
      _services?.events.revision.removeListener(_refresh);
      _services?.session.removeListener(_onSession);
      _placeStatuses?.dispose();
      _services = services;
      services.events.revision.addListener(_refresh);
      services.session.addListener(_onSession);
      _placeStatuses =
          MainMapSceneStatusController(<String, MainMapStatusLoader>{
            for (final ActivityModule module in activityRegistry)
              module.def.id: () => module.status(services),
          });
      unawaited(_placeStatuses!.refresh());
      services.audio.music(MusicTrack.island);
      if (!services.settings.introSeen && !_introShown) {
        _introShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showIntro());
      }
    }
  }

  @override
  void dispose() {
    _services?.events.revision.removeListener(_refresh);
    _services?.session.removeListener(_onSession);
    _placeStatuses?.dispose();
    _villageScroll.dispose();
    _directoryScroll.dispose();
    for (final FocusNode node in _placeFocus.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_routeBusy) {
      _refreshPending = true;
      return;
    }
    await _placeStatuses?.refresh();
  }

  Future<void> _retry(ActivityModule module) async {
    await _placeStatuses?.retry(module.def.id);
  }

  void _onSession() {
    final AppServices? services = _services;
    if (services == null ||
        services.session.pendingReminder == null ||
        !mounted)
      return;
    final int minutes = services.session.pendingReminder!;
    services.session.consumeReminder();
    showBreakReminder(context, minutes);
  }

  Future<void> _showIntro() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: PQColors.ink.withValues(alpha: 0.55),
      builder: (BuildContext context) => const _WelcomeDialog(),
    );
    if (mounted) await _services?.settings.setIntroSeen();
  }

  Future<void> _openPlace(ActivityModule module) async {
    final AppServices? services = _services;
    final MainMapPlaceState? place = _placeStatuses?.places[module.def.id];
    if (!mounted ||
        services == null ||
        _routeBusy ||
        place?.status == null ||
        place?.phase != MainMapPlacePhase.ready)
      return;

    final double villageOffset = _villageScroll.hasClients
        ? _villageScroll.offset
        : 0;
    final double directoryOffset = _directoryScroll.hasClients
        ? _directoryScroll.offset
        : 0;
    setState(() => _routeBusy = true);
    services.audio.play(Sfx.pop);
    bool enteredActivity = false;
    try {
      final String? action = await showPQSheet<String>(
        context,
        builder: (BuildContext context) =>
            ActivitySheet(module: module, status: place!.status!),
      );
      if (!mounted || action == null) return;
      if (action == 'open') {
        enteredActivity = true;
        await openActivity(context, module);
      } else if (action.startsWith('lesson:')) {
        final ActivityModule? main = activityById('main_quest');
        if (main is MainQuestModule) {
          enteredActivity = true;
          await openActivity(context, main, lessonId: action.substring(7));
        }
      }
    } finally {
      if (mounted) {
        final bool shouldRefresh = enteredActivity || _refreshPending;
        _refreshPending = false;
        setState(() => _routeBusy = false);
        if (shouldRefresh) await _placeStatuses?.refresh();
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _restoreScrollOffset(_villageScroll, villageOffset);
            _restoreScrollOffset(_directoryScroll, directoryOffset);
            _placeFocus[module.def.id]?.requestFocus();
          });
        }
      }
    }
  }

  void _restoreScrollOffset(ScrollController controller, double offset) {
    if (!controller.hasClients) return;
    final ScrollPosition position = controller.position;
    controller.jumpTo(
      offset
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble(),
    );
  }

  void _chooseMode(bool directory) {
    if (_directoryMode == directory) return;
    setState(() {
      _modeChosenByUser = true;
      _directoryMode = directory;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppServices services = AppScope.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final MainMapSceneStatusController? statuses = _placeStatuses;
    return Scaffold(
      backgroundColor: PQColors.cream,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: _MainMapHeader(services: services, l10n: l10n),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _MapModeButton(
                      key: const ValueKey<String>('main_map_mode_village'),
                      label: l10n.hubVillageTab,
                      selected: !_directoryMode,
                      onPressed: () => _chooseMode(false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MapModeButton(
                      key: const ValueKey<String>('main_map_mode_places'),
                      label: l10n.hubPlacesTab,
                      selected: _directoryMode,
                      onPressed: () => _chooseMode(true),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: PQColors.parchmentEdge),
            Expanded(
              child: statuses == null
                  ? const Center(child: CircularProgressIndicator())
                  : AnimatedBuilder(
                      animation: statuses,
                      builder: (BuildContext context, Widget? child) =>
                          MainMapScene(
                            modules: activityRegistry,
                            places: statuses.places,
                            directoryMode: _directoryMode,
                            villageScrollController: _villageScroll,
                            directoryScrollController: _directoryScroll,
                            focusNodeFor: (String id) => _placeFocus[id]!,
                            onOpen: _openPlace,
                            onRetry: (ActivityModule module) =>
                                unawaited(_retry(module)),
                          ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainMapHeader extends StatelessWidget {
  const _MainMapHeader({required this.services, required this.l10n});

  final AppServices services;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: _IslandTitle(name: l10n.hubIslandName),
          ),
          const EnergyPill(compact: true),
          ListenableBuilder(
            listenable: services.quests,
            builder: (BuildContext context, Widget? child) => RoundIconButton(
              key: const ValueKey<String>('daily_quests_button'),
              icon: Icons.assignment_turned_in_rounded,
              tooltip: l10n.hubQuestsTooltip,
              tone: PQTone.sun,
              size: 48,
              badge: services.quests.claimable,
              onPressed: () => showDailyQuests(context),
            ),
          ),
          RoundIconButton(
            key: const ValueKey<String>('settings_button'),
            icon: Icons.settings_rounded,
            tooltip: l10n.hubSettingsTooltip,
            size: 48,
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
    );
  }
}

class _IslandTitle extends StatelessWidget {
  const _IslandTitle({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: PQColors.seaDeep,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: PQColors.inkSoft,
                offset: Offset(0, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Text('PQ', style: PQText.h3.copyWith(color: Colors.white)),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('PyQuest', style: PQText.h3, softWrap: true),
              Text(
                name,
                style: PQText.small.copyWith(color: PQColors.inkSoft),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapModeButton extends StatelessWidget {
  const _MapModeButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: true,
      selected: selected,
      onTap: onPressed,
      label: label,
      child: ExcludeSemantics(
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            backgroundColor: selected ? PQColors.seaDeep : PQColors.cream,
            foregroundColor: selected ? Colors.white : PQColors.ink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: selected ? PQColors.seaDeep : PQColors.parchmentEdge,
                width: 1.5,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            softWrap: true,
            style: PQText.bodyStrong.copyWith(
              color: selected ? Colors.white : PQColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens an activity's existing home and records the existing activity-open event.
Future<void> openActivity(
  BuildContext context,
  ActivityModule module, {
  String? lessonId,
}) async {
  final AppServices s = AppScope.of(context);
  final outcome = await s.events.emit(
    StandardEvent(
      type: EventTypes.activityOpened,
      sourceId: 'main_map',
      data: <String, Object?>{'activity_id': module.def.id},
    ),
  );
  if (!context.mounted) return;
  s.audio.play(Sfx.whoosh);
  WidgetBuilder page = module.buildHome;
  if (lessonId != null && module is MainQuestModule) {
    final MainQuestModule main = module;
    page = (BuildContext context) =>
        main.buildHome(context, openLessonId: lessonId);
  }
  final NavigatorState navigator = Navigator.of(context);
  final route = navigator.push<void>(
    CloudRoute<void>(builder: page, calm: s.settings.calmMode),
  );
  if (outcome.notices.isNotEmpty) {
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (navigator.mounted)
          showRewardToasts(navigator.context, outcome.notices);
      }),
    );
  }
  await route;
  if (context.mounted) s.audio.music(MusicTrack.island);
}

class _WelcomeDialog extends StatefulWidget {
  const _WelcomeDialog();

  @override
  State<_WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<_WelcomeDialog> {
  int _page = 0;

  static const _pages = [
    (
      CharacterId.robo,
      'Chào mừng tới Đảo Khởi Đầu!',
      'Mình là Robo. Mỗi địa điểm trên đảo là một trò chơi hoặc một chặng phiêu lưu riêng. Chạm vào một nơi để khám phá nhé!',
    ),
    (
      CharacterId.py,
      'Học Python ở Tháp Python',
      'Tớ là thầy Py. Ở Tháp Python bạn sẽ học viết code thật từng bước. Nhiều trò chơi khác trên đảo không cần biết Python đâu!',
    ),
    (
      CharacterId.pip,
      'Năng lượng và nghỉ ngơi',
      'Chơi màn mới và học bài mới dùng một chút năng lượng. Năng lượng tự hồi theo thời gian. Không có quảng cáo, không có mua bán!',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final (character, title, body) = _pages[_page];
    final last = _page == _pages.length - 1;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: PQPanel(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CharacterView(key: ValueKey(character), id: character, size: 130),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center, style: PQText.h2),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: PQText.body),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  Container(
                    width: i == _page ? 22 : 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _page ? PQColors.sun : PQColors.parchmentDeep,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: PQColors.ink, width: 1.6),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            ChunkyButton(
              key: const ValueKey('welcome_next'),
              label: last ? 'Bắt đầu khám phá!' : 'Tiếp tục',
              tone: last ? PQTone.grass : PQTone.sun,
              expand: true,
              onPressed: () {
                if (last) {
                  Navigator.of(context).pop();
                } else {
                  setState(() => _page++);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Gentle, non-blocking break reminder (30 / 45 / 60 minutes).
Future<void> showBreakReminder(BuildContext context, int minutes) {
  AppScope.of(context).audio.play(Sfx.pop);
  return showDialog<void>(
    context: context,
    barrierColor: PQColors.ink.withValues(alpha: 0.5),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: PQPanel(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CharacterView(
              id: CharacterId.robo,
              size: 110,
              mood: Mood.neutral,
            ),
            Text(
              'Bạn đã chơi $minutes phút rồi!',
              textAlign: TextAlign.center,
              style: PQText.h2,
            ),
            const SizedBox(height: 8),
            Text(
              minutes >= 60
                  ? 'Đã đến lúc nghỉ dài hơn rồi. Đứng dậy vươn vai, uống nước và chơi ngoài trời một chút nhé!'
                  : 'Mình cùng đứng dậy vươn vai và nhìn ra xa một chút nhé. Tiến trình của bạn đã được lưu.',
              textAlign: TextAlign.center,
              style: PQText.body,
            ),
            const SizedBox(height: 16),
            ChunkyButton(
              label: 'Nghỉ mắt 20 giây',
              tone: PQTone.sea,
              expand: true,
              onPressed: () {
                Navigator.of(ctx).pop();
                showEyeBreak(context);
              },
            ),
            const SizedBox(height: 10),
            ChunkyButton(
              label: 'Chơi tiếp một chút',
              tone: PQTone.parchment,
              expand: true,
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}
