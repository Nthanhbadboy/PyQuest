import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/audio_service.dart';
import '../../core/events.dart';
import '../../modules/achievements/achievement_catalog.dart';
import '../theme/app_theme.dart';
import '../theme/palette.dart';
import 'game_icons.dart';

/// Slides celebratory banners (new badge, quest done...) in from the top.
void showRewardToasts(BuildContext context, List<RewardNotice> notices) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null || notices.isEmpty) return;
  final audio = AppScope.maybeOf(context)?.audio;
  var delay = Duration.zero;
  for (final n in notices) {
    Future<void>.delayed(delay, () {
      if (!overlay.mounted) return;
      audio?.play(n.kind == RewardKind.badge ? Sfx.unlock : Sfx.sparkle);
      late OverlayEntry entry;
      entry = OverlayEntry(builder: (ctx) => _Toast(notice: n, onDone: () => entry.remove()));
      overlay.insert(entry);
    });
    delay += const Duration(milliseconds: 1600);
  }
}

class _Toast extends StatefulWidget {
  const _Toast({required this.notice, required this.onDone});
  final RewardNotice notice;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(const Duration(milliseconds: 2800), _close);
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    await _c.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notice;
    final def = n.kind == RewardKind.badge ? achievementById(n.id) : null;
    final header = switch (n.kind) {
      RewardKind.badge => 'Huy hiệu mới!',
      RewardKind.quest => 'Nhiệm vụ hoàn thành!',
      RewardKind.energy => 'Phần thưởng cột mốc!',
      RewardKind.unlock => 'Mở khoá!',
      RewardKind.item => 'Vật phẩm mới!',
    };
    return Positioned(
      top: 0,
      left: 12,
      right: 12,
      child: SafeArea(
        child: SlideTransition(
          position: Tween(begin: const Offset(0, -1.4), end: Offset.zero)
              .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn)),
          child: GestureDetector(
            onTap: _close,
            child: Material(
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                decoration: BoxDecoration(
                  color: PQColors.cream,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PQColors.ink, width: 2.6),
                  boxShadow: [BoxShadow(color: PQColors.sunDeep, offset: const Offset(0, 4), blurRadius: 0)],
                ),
                child: Row(
                  children: [
                    if (def != null)
                      BadgeMedal(icon: def.icon, color: def.color, size: 52)
                    else
                      GameIcon(
                        n.kind == RewardKind.quest
                            ? GameIconKind.stamp
                            : (n.kind == RewardKind.energy ? GameIconKind.energy : GameIconKind.chest),
                        size: 44,
                      ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(header, style: PQText.small.copyWith(color: PQColors.berry, fontWeight: FontWeight.w900)),
                          Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: PQText.h3.copyWith(fontSize: 18)),
                          Text(n.description,
                              maxLines: 2, overflow: TextOverflow.ellipsis, style: PQText.small.copyWith(fontSize: 13.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
