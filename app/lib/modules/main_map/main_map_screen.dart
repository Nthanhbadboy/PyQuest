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
  bool _restoreFocusInProgress = false;
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
        setState(() {
          _routeBusy = false;
          _restoreFocusInProgress = true;
        });
        if (shouldRefresh) await _placeStatuses?.refresh();
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _restoreScrollOffset(_villageScroll, villageOffset);
            _restoreScrollOffset(_directoryScroll, directoryOffset);
            _placeFocus[module.def.id]?.requestFocus();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _restoreFocusInProgress = false);
              }
            });
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
                            suppressFocusAutoScroll:
                                _routeBusy || _restoreFocusInProgress,
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

/// Cỡ scene của panel chào, theo ASSET_PLAN r56: 300px bình thường, 250px khi
/// chữ >=1.5x (chỉ scene đổi cỡ, portrait 152×175 giữ nguyên).
const double kWelcomeSceneHeight = 300;
const double kWelcomeSceneLargeHeight = 250;
const Size kWelcomeGuideSize = Size(152, 175);

/// Viền gỗ và nền panel theo `.panel` của r56 (`border:5px #9e754c`,
/// `border-radius:26px`, nền `#fff8e7`). Ở chữ >=1.5x panel full-bleed
/// (`.phone.large .panel{border:0;border-radius:0}`) nên bỏ cả hai.
const Color kWelcomeEdge = Color(0xFF9E754C);
const Color kWelcomePanelFill = Color(0xFFFFF8E7);
const BorderRadius kWelcomePanelRadius = BorderRadius.all(Radius.circular(26));

/// Host nào có portrait study mới thì hiện ảnh đó, các host khác giữ painter.
const Map<CharacterId, String> kWelcomeHostToken = <CharacterId, String>{
  CharacterId.py: 'assets/images/py_token_r56.png',
};

/// Chào mừng ba bước, khung panel gỗ 2,5D theo r56. `welcome_next` giữ nguyên
/// tên (hợp đồng với `journey_widget_test.dart` và harness render); scene chỉ là
/// không gian giới thiệu, mọi chữ vẫn là widget Flutter thật.
class _WelcomeDialog extends StatefulWidget {
  const _WelcomeDialog();

  @override
  State<_WelcomeDialog> createState() => _WelcomeDialogState();
}

class _WelcomeDialogState extends State<_WelcomeDialog> {
  int _page = 0;

  /// (host, title, body, sceneAsset, sceneFocusY). Scene lấy từ bộ export r56:
  /// `arrival` cho Robo và Pip, `main_quest` (tower-garden của r43) cho bước của
  /// Py. `sceneFocusY` mô phỏng `background-position: center NN%` trong study.
  /// Copy giữ nguyên văn bản đang có: đổi lời chào là việc của đơn localize riêng
  /// (D56-P1), không làm chui trong đợt 2,5D này.
  static const List<(CharacterId, String, String, String, double)> _pages = [
    (
      CharacterId.robo,
      'Chào mừng tới Đảo Khởi Đầu!',
      'Mình là Robo. Mỗi địa điểm trên đảo là một trò chơi hoặc một chặng phiêu lưu riêng. Chạm vào một nơi để khám phá nhé!',
      'assets/images/arrival_r56.webp',
      0.53,
    ),
    (
      CharacterId.py,
      'Học Python ở Tháp Python',
      'Tớ là thầy Py. Ở Tháp Python bạn sẽ học viết code thật từng bước. Nhiều trò chơi khác trên đảo không cần biết Python đâu!',
      'assets/images/main_quest_r56.webp',
      0.60,
    ),
    (
      CharacterId.pip,
      'Năng lượng và nghỉ ngơi',
      'Chơi màn mới và học bài mới dùng một chút năng lượng. Năng lượng tự hồi theo thời gian. Không có quảng cáo, không có mua bán!',
      'assets/images/arrival_r56.webp',
      0.70,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final (host, title, body, scene, focus) = _pages[_page];
    final bool last = _page == _pages.length - 1;
    final double scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final bool largeText = scale >= kR56LargeTextScale;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.fromLTRB(10, largeText ? 10 : 18, 10, 10),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: kWelcomePanelFill,
          borderRadius: largeText ? BorderRadius.zero : kWelcomePanelRadius,
          border: largeText ? null : Border.all(color: kWelcomeEdge, width: 5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WelcomeBar(page: _page, host: host, pages: _pages.length),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SPEC r56 §4: font lớn thì chữ đứng trước, artwork cuộn sau.
                    if (largeText) ...[
                      _WelcomeCopy(
                        title: title,
                        body: body,
                        page: _page,
                        pages: _pages.length,
                        host: host,
                      ),
                      _WelcomeScene(
                        asset: scene,
                        host: host,
                        focus: focus,
                        largeText: largeText,
                      ),
                    ] else ...[
                      _WelcomeScene(
                        asset: scene,
                        host: host,
                        focus: focus,
                        largeText: largeText,
                      ),
                      _WelcomeCopy(
                        title: title,
                        body: body,
                        page: _page,
                        pages: _pages.length,
                        host: host,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _WelcomeFooter(
              page: _page,
              last: last,
              onPrevious: () => setState(() => _page--),
              onNext: () {
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

class _WelcomeBar extends StatelessWidget {
  const _WelcomeBar({
    required this.page,
    required this.host,
    required this.pages,
  });

  final int page;
  final CharacterId host;
  final int pages;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 6),
      decoration: const BoxDecoration(
        color: Color(0xFFF7EDCF),
        border: Border(bottom: BorderSide(color: Color(0xFFDFC9A6), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Lời chào từ đảo · ${page + 1}/$pages · ${host.displayName}',
              style: PQText.small.copyWith(color: const Color(0xFF536553)),
              maxLines: 2,
            ),
          ),
          ChunkyButton(
            key: const ValueKey('welcome_close'),
            label: 'Đóng',
            size: ChunkySize.small,
            tone: PQTone.parchment,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Scene 2,5D: ảnh cover + dải fade về màu panel, seal caption góc trái trên,
/// chân dung host giữa mép dưới (`.scene.welcome-scene .guide` của r56).
class _WelcomeScene extends StatelessWidget {
  const _WelcomeScene({
    required this.asset,
    required this.host,
    required this.focus,
    required this.largeText,
  });

  final String asset;
  final CharacterId host;
  final double focus;
  final bool largeText;

  @override
  Widget build(BuildContext context) {
    final double height = largeText
        ? kWelcomeSceneLargeHeight
        : kWelcomeSceneHeight;
    final String? token = kWelcomeHostToken[host];
    const Key guideKey = ValueKey<String>('welcome_guide');
    final Widget guide;
    if (token == null) {
      guide = CharacterView(
        key: guideKey,
        id: host,
        size: kWelcomeGuideSize.height,
        animate: false,
      );
    } else {
      guide = Image.asset(
        token,
        key: guideKey,
        width: kWelcomeGuideSize.width,
        height: kWelcomeGuideSize.height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'Chân dung ${host.displayName}',
        gaplessPlayback: true,
      );
    }
    return SizedBox(
      key: const ValueKey<String>('welcome_scene'),
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: Alignment(0, focus * 2 - 1),
            filterQuality: FilterQuality.medium,
            semanticLabel: 'Cảnh 2,5D của Đảo Khởi Đầu',
            gaplessPlayback: true,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [
                  Color(0x00FFF8E7),
                  Color(0x80FFF8E7),
                  Color(0xFFFFF8E7),
                ],
                stops: const [0.60, 0.86, 1],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: guide,
          ),
        ],
      ),
    );
  }
}

/// `.panel-copy`: thanh bước (segments 5px), caption, then title + lời nhân vật.
class _WelcomeCopy extends StatelessWidget {
  const _WelcomeCopy({
    required this.title,
    required this.body,
    required this.page,
    required this.pages,
    required this.host,
  });

  final String title;
  final String body;
  final int page;
  final int pages;
  final CharacterId host;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bước ${page + 1}/$pages · ${host.displayName}',
            style: PQText.small.copyWith(
              fontSize: 11.5,
              color: const Color(0xFF5E7765),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < pages; i++)
                Expanded(
                  child: Container(
                    height: 5,
                    margin: EdgeInsets.only(right: i == pages - 1 ? 0 : 7),
                    decoration: BoxDecoration(
                      color: i == page
                          ? const Color(0xFF3B7D77)
                          : const Color(0xFFD8D9B9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: PQText.h2.copyWith(fontSize: 28, height: 1.12),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: PQText.body.copyWith(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// `.footer` của r56: nút ngoài vùng cuộn, `previous` để đọc lại bước đã xem
/// (D56-P2), CTA cuối vẫn là `welcome_next` với cùng hành động pop.
class _WelcomeFooter extends StatelessWidget {
  const _WelcomeFooter({
    required this.page,
    required this.last,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final bool last;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF7EFD8),
        border: Border(top: BorderSide(color: Color(0xFFD5C6A4), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (page > 0)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChunkyButton(
                key: const ValueKey('welcome_previous'),
                label: 'Lùi',
                icon: Icons.arrow_back_rounded,
                tone: PQTone.parchment,
                onPressed: onPrevious,
              ),
            ),
          Expanded(
            child: ChunkyButton(
              key: const ValueKey('welcome_next'),
              label: last ? 'Bắt đầu khám phá!' : 'Tiếp tục',
              tone: last ? PQTone.grass : PQTone.sun,
              expand: true,
              onPressed: onNext,
            ),
          ),
        ],
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
