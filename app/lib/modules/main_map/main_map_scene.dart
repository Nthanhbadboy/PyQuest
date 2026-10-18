import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../app/activity.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/palette.dart';
import 'main_map_scene_geometry.dart';
import 'main_map_scene_state.dart';

void _ensureVisibleIfNeeded(BuildContext context, {required double alignment}) {
  final RenderObject? target = context.findRenderObject();
  final RenderAbstractViewport? viewport = RenderAbstractViewport.maybeOf(
    target,
  );
  final ScrollableState? scrollable = Scrollable.maybeOf(context);
  if (target != null && viewport != null && scrollable != null) {
    final ScrollPosition position = scrollable.position;
    final double leading = viewport.getOffsetToReveal(target, 0).offset;
    final double trailing = viewport.getOffsetToReveal(target, 1).offset;
    if (position.pixels >= trailing && position.pixels <= leading) return;
  }
  Scrollable.ensureVisible(
    context,
    alignment: alignment,
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOut,
  );
}

/// R1-A presentation for the six existing registry activities.
/// The W01 background is deliberately one flattened, static image; the
/// interactive buttons are ordinary Flutter controls layered above it.
class MainMapScene extends StatelessWidget {
  const MainMapScene({
    super.key,
    required this.modules,
    required this.places,
    required this.directoryMode,
    required this.villageScrollController,
    required this.directoryScrollController,
    required this.focusNodeFor,
    required this.onOpen,
    required this.onRetry,
  });

  final List<ActivityModule> modules;
  final Map<String, MainMapPlaceState> places;
  final bool directoryMode;
  final ScrollController villageScrollController;
  final ScrollController directoryScrollController;
  final FocusNode Function(String activityId) focusNodeFor;
  final ValueChanged<ActivityModule> onOpen;
  final ValueChanged<ActivityModule> onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return directoryMode ? _buildDirectory(l10n) : _buildVillage(l10n);
  }

  Widget _buildVillage(AppLocalizations l10n) {
    final ActivityModule? recommendation = _recommendation();
    return SingleChildScrollView(
      key: const PageStorageKey<String>('main_map_village_scroll'),
      controller: villageScrollController,
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (recommendation != null) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _RecommendationCard(
                title: l10n.hubRecommendationTitle,
                placeName: placeName(l10n, recommendation.def.id),
                onPressed: () => onOpen(recommendation),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              l10n.hubSceneScrollHint,
              style: PQText.small.copyWith(color: PQColors.inkSoft),
            ),
          ),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double width = constraints.maxWidth;
              final double height = villageSceneHeight(width);
              final Size sceneSize = Size(width, height);
              return FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: SizedBox(
                  key: const ValueKey<String>('main_map_village_scene'),
                  width: width,
                  height: height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Semantics(
                        image: true,
                        label: l10n.hubHomeSemantics,
                        child: Image.asset(
                          'assets/images/village_r53.webp',
                          width: width,
                          height: height,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.medium,
                          gaplessPlayback: true,
                        ),
                      ),
                      for (int i = 0; i < modules.length; i++)
                        _positionedMarker(
                          l10n,
                          modules[i],
                          sceneSize,
                          order: i + 1,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _positionedMarker(
    AppLocalizations l10n,
    ActivityModule module,
    Size sceneSize, {
    required int order,
  }) {
    final String id = module.def.id;
    final Offset center = villageMarkerCenter(id, sceneSize);
    final double width = sceneSize.width * kVillageMarkerWidthFraction;
    return Align(
      alignment: Alignment(
        2 * center.dx / sceneSize.width - 1,
        2 * center.dy / sceneSize.height - 1,
      ),
      child: SizedBox(
        width: width,
        child: FocusTraversalOrder(
          order: NumericFocusOrder(order.toDouble()),
          child: _PlaceButton(
            key: ValueKey<String>('map_label_$id'),
            activityId: id,
            name: placeName(l10n, id),
            state: places[id] ?? const MainMapPlaceState.loading(),
            focusNode: focusNodeFor(id),
            onFocused: (BuildContext buttonContext) =>
                _ensureVisibleIfNeeded(buttonContext, alignment: 0.45),
            onPressed: () => _activate(module),
            l10n: l10n,
          ),
        ),
      ),
    );
  }

  Widget _buildDirectory(AppLocalizations l10n) {
    return SingleChildScrollView(
      key: const PageStorageKey<String>('main_map_directory_scroll'),
      controller: directoryScrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.hubDirectoryHint,
              style: PQText.bodyStrong.copyWith(color: PQColors.inkSoft),
            ),
          ),
          FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < modules.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(height: 10),
                  FocusTraversalOrder(
                    order: NumericFocusOrder((i + 1).toDouble()),
                    child: _DirectoryPlaceButton(
                      key: ValueKey<String>(
                        'directory_place_${modules[i].def.id}',
                      ),
                      name: placeName(l10n, modules[i].def.id),
                      state:
                          places[modules[i].def.id] ??
                          const MainMapPlaceState.loading(),
                      focusNode: focusNodeFor(modules[i].def.id),
                      onFocused: (BuildContext buttonContext) =>
                          _ensureVisibleIfNeeded(
                            buttonContext,
                            alignment: 0.35,
                          ),
                      onPressed: () => _activate(modules[i]),
                      l10n: l10n,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  ActivityModule? _recommendation() {
    for (final ActivityModule module in modules) {
      final MainMapPlaceState? state = places[module.def.id];
      final ActivityStatus? status = state?.status;
      if (state?.phase == MainMapPlacePhase.ready &&
          status != null &&
          !status.locked &&
          status.recommended) {
        return module;
      }
    }
    for (final ActivityModule module in modules) {
      final MainMapPlaceState? state = places[module.def.id];
      final ActivityStatus? status = state?.status;
      if (module.def.id == 'main_quest' &&
          state?.phase == MainMapPlacePhase.ready &&
          status != null &&
          !status.locked) {
        return module;
      }
    }
    return null;
  }

  void _activate(ActivityModule module) {
    final MainMapPlaceState? state = places[module.def.id];
    if (state?.phase == MainMapPlacePhase.error) {
      onRetry(module);
    } else if (state?.phase == MainMapPlacePhase.ready) {
      onOpen(module);
    }
  }
}

String placeName(AppLocalizations l10n, String id) => switch (id) {
  'main_quest' => l10n.hubMainQuest,
  'robot_maze' => l10n.hubRobotMaze,
  'dragon_jump' => l10n.hubDragonJump,
  'catch_stars' => l10n.hubCatchStars,
  'bug_hunter' => l10n.hubBugHunter,
  'achievement_house' => l10n.hubAchievements,
  _ => id,
};

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.title,
    required this.placeName,
    required this.onPressed,
  });

  final String title;
  final String placeName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PQColors.cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PQColors.parchmentEdge, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: PQText.small.copyWith(
                color: PQColors.inkSoft,
                letterSpacing: 1.2,
              ),
            ),
          ),
          TextButton(
            key: const ValueKey<String>('main_map_recommended'),
            onPressed: onPressed,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, kVillageMinimumTargetSize),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              backgroundColor: PQColors.seaDeep,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              l10n.hubVisitRecommended(placeName),
              textAlign: TextAlign.center,
              softWrap: true,
              style: PQText.button.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceButton extends StatelessWidget {
  const _PlaceButton({
    super.key,
    required this.activityId,
    required this.name,
    required this.state,
    required this.focusNode,
    required this.onFocused,
    required this.onPressed,
    required this.l10n,
  });

  final String activityId;
  final String name;
  final MainMapPlaceState state;
  final FocusNode focusNode;
  final ValueChanged<BuildContext> onFocused;
  final VoidCallback onPressed;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final bool isError = state.phase == MainMapPlacePhase.error;
    final bool isLoading = state.phase == MainMapPlacePhase.loading;
    final bool locked = state.status?.locked ?? false;
    final String statusLabel = isLoading
        ? l10n.hubLoading
        : isError
        ? '${l10n.hubStatusUnavailable} · ${l10n.hubRetry}'
        : locked
        ? l10n.hubLocked
        : l10n.hubExplore;
    final Color face = locked ? const Color(0xFFEDE4D7) : PQColors.cream;
    return Focus(
      skipTraversal: true,
      canRequestFocus: false,
      onFocusChange: (bool focused) {
        if (focused) onFocused(context);
      },
      child: Semantics(
        button: true,
        enabled: !isLoading,
        onTap: isLoading ? null : onPressed,
        label: '$name, $statusLabel',
        hint: isError ? l10n.hubRetry : null,
        child: ExcludeSemantics(
          child: TextButton(
            focusNode: focusNode,
            onPressed: isLoading ? null : onPressed,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, kVillageMinimumTargetSize),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              backgroundColor: face,
              foregroundColor: PQColors.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(
                  color: PQColors.parchmentEdge,
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Keep the historical map_hit test key on the visible label only;
                // the button itself is the sole hit target (there is no hidden hit rect).
                Text(
                  name,
                  key: ValueKey<String>('map_hit_$activityId'),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: PQText.small.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                _PlaceStateLine(state: state, label: statusLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectoryPlaceButton extends StatelessWidget {
  const _DirectoryPlaceButton({
    super.key,
    required this.name,
    required this.state,
    required this.focusNode,
    required this.onFocused,
    required this.onPressed,
    required this.l10n,
  });

  final String name;
  final MainMapPlaceState state;
  final FocusNode focusNode;
  final ValueChanged<BuildContext> onFocused;
  final VoidCallback onPressed;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final bool isLoading = state.phase == MainMapPlacePhase.loading;
    final bool isError = state.phase == MainMapPlacePhase.error;
    final bool locked = state.status?.locked ?? false;
    final String stateLabel = isLoading
        ? l10n.hubLoading
        : isError
        ? '${l10n.hubStatusUnavailable} · ${l10n.hubRetry}'
        : locked
        ? l10n.hubLocked
        : l10n.hubExplore;
    return Focus(
      skipTraversal: true,
      canRequestFocus: false,
      onFocusChange: (bool focused) {
        if (focused) onFocused(context);
      },
      child: Semantics(
        button: true,
        enabled: !isLoading,
        onTap: isLoading ? null : onPressed,
        label: '$name, $stateLabel',
        hint: isError ? l10n.hubRetry : null,
        child: ExcludeSemantics(
          child: TextButton(
            focusNode: focusNode,
            onPressed: isLoading ? null : onPressed,
            style: TextButton.styleFrom(
              alignment: Alignment.centerLeft,
              minimumSize: const Size(0, kVillageMinimumTargetSize),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              backgroundColor: PQColors.cream,
              foregroundColor: PQColors.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: PQColors.parchmentEdge,
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 32,
                  height: 32,
                  child: _PlaceStateIcon(state: state),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(name, softWrap: true, style: PQText.h3),
                      const SizedBox(height: 2),
                      _PlaceStateLine(
                        state: state,
                        label: stateLabel,
                        alignStart: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceStateLine extends StatelessWidget {
  const _PlaceStateLine({
    required this.state,
    required this.label,
    this.alignStart = false,
  });

  final MainMapPlaceState state;
  final String label;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    if (state.phase == MainMapPlacePhase.loading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: alignStart
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 6),
          Flexible(child: Text(label, softWrap: true, style: PQText.small)),
        ],
      );
    }
    if (state.phase == MainMapPlacePhase.error) {
      return Text(
        label,
        textAlign: alignStart ? TextAlign.start : TextAlign.center,
        softWrap: true,
        style: PQText.small.copyWith(color: PQColors.dangerDeep),
      );
    }
    return Text(
      label,
      textAlign: alignStart ? TextAlign.start : TextAlign.center,
      softWrap: true,
      style: PQText.small.copyWith(color: PQColors.inkSoft),
    );
  }
}

class _PlaceStateIcon extends StatelessWidget {
  const _PlaceStateIcon({required this.state});

  final MainMapPlaceState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.phase) {
      MainMapPlacePhase.loading => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      MainMapPlacePhase.error => const Icon(
        Icons.refresh_rounded,
        color: PQColors.dangerDeep,
      ),
      MainMapPlacePhase.ready when (state.status?.locked ?? false) =>
        const Icon(Icons.lock_outline_rounded, color: PQColors.inkSoft),
      MainMapPlacePhase.ready => const Icon(
        Icons.place_outlined,
        color: PQColors.seaDeep,
      ),
    };
  }
}
