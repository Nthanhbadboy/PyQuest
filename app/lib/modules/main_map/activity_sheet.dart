import 'package:flutter/material.dart';

import '../../app/activity.dart';
import '../../shared/characters/characters.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/theme/palette.dart';
import '../../shared/widgets/chunky_button.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/game_icons.dart';

/// Scene 2,5D của bảng địa điểm theo `docs/design/arrival-entrance-r56`:
/// `arrival.webp` (bến/cổng làng) chỉ là không gian giới thiệu — SPEC r56 §4 bắt
/// buộc mọi chữ (tên, tag, status, CTA) là widget thật, không bake vào artwork,
/// và scene không được biến thành nút bản đồ hay bằng chứng geometry.
const String kSheetSceneAsset = 'assets/images/arrival_r56.webp';

/// Hai portrait study mới của r56 (ASSET_PLAN: Py và Bitsy là ảnh mới; Robo/Pip
/// "reuse r50/r54, không copy thêm" nên hai host kia vẫn dùng `CharacterView`
/// painter — identity canonical của app, không sinh một bản thứ hai).
const Map<String, String> kR56HostToken = <String, String>{
  'main_quest': 'assets/images/py_token_r56.png',
  'bug_hunter': 'assets/images/bitsy_token_r56.png',
};

/// Cỡ chữ mà `MainMapScreen` coi là "font lớn" (ngưỡng 1.5 của production, không
/// phải số mới bịa): dưới ngưỡng thì scene đứng đầu, trên ngưỡng thì nội dung
/// đứng trước artwork (SPEC r56 §4).
const double kR56LargeTextScale = 1.5;

/// Kích thước trong ASSET_PLAN r56 "Kích thước và cỡ chữ": header scene 180px,
/// portrait 115×140, và portrait KHÔNG bị thu nhỏ ở cỡ chữ lớn.
const double kSheetSceneHeight = 180;
const Size kSheetGuideSize = Size(115, 140);

/// Bottom sheet shown when a place on the map is tapped.
/// Pops with `open` or `lesson:<id>`.
class ActivitySheet extends StatelessWidget {
  const ActivitySheet({super.key, required this.module, required this.status});
  final ActivityModule module;
  final ActivityStatus status;

  @override
  Widget build(BuildContext context) {
    final ActivityDef def = module.def;
    final double scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final bool largeText = scale >= kR56LargeTextScale;

    final Widget scene = _SheetSceneHeader(def: def, status: status);
    final Widget body = _SheetBody(def: def, status: status);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            primary: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Reorder theo r56: ở font lớn, chữ đọc trước, artwork cuộn tới sau.
                if (largeText) ...[
                  const _SheetBar(),
                  Padding(padding: _kSheetCopyPadding, child: body),
                  const SizedBox(height: 18),
                  scene,
                ] else ...[
                  const _SheetBar(),
                  scene,
                  Padding(padding: _kSheetCopyPadding, child: body),
                ],
              ],
            ),
          ),
        ),
        _SheetActions(def: def, status: status),
      ],
    );
  }
}

const EdgeInsets _kSheetCopyPadding = EdgeInsets.fromLTRB(20, 14, 20, 2);

/// `.panel-bar` của r56: nhãn + nút đóng luôn thấy mà không cần vuốt để thoát.
class _SheetBar extends StatelessWidget {
  const _SheetBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 6),
      decoration: const BoxDecoration(
        color: Color(0xFFF7EDCF),
        border: Border(bottom: BorderSide(color: Color(0xFFDFC9A6), width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_rounded, size: 20, color: PQColors.inkFaint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Giới thiệu địa điểm',
              style: PQText.small,
              maxLines: 2,
            ),
          ),
          ChunkyButton(
            key: const ValueKey('sheet_close'),
            label: 'Đóng',
            tone: PQTone.parchment,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Scene 2,5D: ảnh nền cover + dải fade về nền parchment, seal tên địa điểm,
/// và portrait host đè mép dưới scene (đúng `.scene .guide` của style.css r56).
class _SheetSceneHeader extends StatelessWidget {
  const _SheetSceneHeader({required this.def, required this.status});

  final ActivityDef def;
  final ActivityStatus status;

  @override
  Widget build(BuildContext context) {
    final String? token = kR56HostToken[def.id];
    return SizedBox(
      height: kSheetSceneHeight,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // `center 57%` trong CSS -> Alignment(0, -1 + 2*0.57). Scene crop chỉ
            // để giới thiệu, không phải ảnh thu nhỏ của map thật.
            Image.asset(
              kSheetSceneAsset,
              key: const ValueKey('sheet_scene'),
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.14),
              filterQuality: FilterQuality.medium,
              semanticLabel: 'Cảnh bến làng nơi ${def.name} tọa lạc',
              gaplessPlayback: true,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const [Color(0x00FFF8E7), Color(0x66FFF8E7), PQColors.parchment],
                  stops: const [0.65, 0.86, 1],
                ),
              ),
              child: const SizedBox.expand(),
            ),
            Positioned(
              left: 16,
              top: 14,
              child: _SceneSeal(locked: status.locked),
            ),
            Positioned(
              right: 20,
              bottom: 0,
              child: _SheetGuide(def: def, token: token, status: status),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.scene-seal` của r56 (`#fff6dfeb` + viền `#b39c72`, radius 16, 11px): chip nhỏ
/// trả lời "địa điểm này đang mở hay khóa" bằng CHỮ, không bằng màu — tên canonical
/// vẫn nằm ở `panel-copy h2` (một chỗ duy nhất, như `findsOneWidget` mà
/// `main_map_scene_route_test.dart` và oracle semantics của R3 đang bắt buộc), còn
/// tên nhân vật do `SpeechBubble` lo.
class _SceneSeal extends StatelessWidget {
  const _SceneSeal({required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 232),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xE6FFF6DF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB39C72), width: 1),
      ),
      child: Text(
        locked ? 'Đang khóa' : 'Đã mở',
        style: PQText.bodyStrong.copyWith(fontSize: 13.5),
      ),
    );
  }
}

/// Portrait host: token study mới nếu địa điểm có trong `kR56HostToken`, nếu
/// không thì `CharacterView` painter của app. Cùng một ô 115×140, không co ở
/// cỡ chữ lớn (ASSET_PLAN: "portrait không thu nhỏ").
class _SheetGuide extends StatelessWidget {
  const _SheetGuide({
    required this.def,
    required this.token,
    required this.status,
  });

  final ActivityDef def;
  final String? token;
  final ActivityStatus status;

  @override
  Widget build(BuildContext context) {
    // `token` là field public nên KHÔNG được flow-promotion (CFE báo
    // `String? -> String` ở run 6b74744): đọc ra local rồi mới rẻ nhánh.
    final String? asset = token;
    final String label = 'Chân dung ${def.host.displayName}';
    final Widget portrait;
    if (asset == null) {
      portrait = CharacterView(
        key: const ValueKey('sheet_guide'),
        id: def.host,
        size: kSheetGuideSize.height,
        mood: status.locked ? Mood.thinking : Mood.happy,
        animate: false,
      );
    } else {
      portrait = Image.asset(
        asset,
        key: const ValueKey('sheet_guide'),
        width: kSheetGuideSize.width,
        height: kSheetGuideSize.height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        semanticLabel: label,
        gaplessPlayback: true,
      );
    }
    return Semantics(image: true, label: label, child: portrait);
  }
}

/// Phần chữ: khung thumbnail đã pin 104×104 (`kPinnedThumb` trong
/// `activity_sheet_thumbnails_test.dart` tìm đúng một `Container` có
/// `BoxDecoration.image` là `AssetImage` — scene ở trên phải dùng `Image.asset`,
/// không được vẽ bằng DecorationImage thứ hai), rồi tên/tagline/tags/lời host.
class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.def, required this.status});
  final ActivityDef def;
  final ActivityStatus status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: PQColors.ink, width: 2.6),
                boxShadow: [
                  BoxShadow(
                    color: def.tone.depth,
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
                image: DecorationImage(
                  image: AssetImage(def.thumbnail),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(def.name, style: PQText.h2),
                  Text(
                    def.tagline,
                    style: PQText.small.copyWith(color: def.tone.depth),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      PillTag(
                        label: def.needsPython
                            ? 'Học Python'
                            : 'Không cần biết Python',
                        color: def.needsPython ? PQColors.pyBlue : PQColors.grass,
                        icon: def.needsPython
                            ? Icons.code_rounded
                            : Icons.sports_esports_rounded,
                      ),
                      if (def.hasCreatorMode)
                        const PillTag(
                          label: 'Có Xưởng sáng tạo',
                          color: PQColors.grape,
                          icon: Icons.construction_rounded,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Lời host không kèm portrait lần hai: `.guide-copy` của r56 chỉ có tên
        // và chữ, chân dung đã nằm ở mép scene phía trên.
        SpeechBubble(
          character: def.host,
          text: def.description,
          showPortrait: false,
          mood: status.locked ? Mood.thinking : Mood.happy,
        ),
        const SizedBox(height: 14),
        if (status.locked)
          PQPanel(
            color: const Color(0xFFFFF0E0),
            child: Row(
              children: [
                const GameIcon(GameIconKind.lock, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    status.lockReason ?? 'Chưa mở.',
                    style: PQText.bodyStrong,
                  ),
                ),
              ],
            ),
          )
        else
          _StatusBox(status: status),
      ],
    );
  }
}

/// `.status-box` + `.metric` của r56: nhãn trái, số phải, mỗi dòng một metric có
/// kiểu; không parse chuỗi để bịa số (D56-P1) và không truncate.
class _StatusBox extends StatelessWidget {
  const _StatusBox({required this.status});
  final ActivityStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1DA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC4CDA9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricRow(
            label: 'Tiến trình',
            value: status.progressLabel,
            trailing: status.stars == null
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const StarIcon(size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${status.stars}',
                        style: PQText.number.copyWith(fontSize: 20),
                      ),
                    ],
                  ),
          ),
          for (final String line in status.detailLines)
            _MetricRow(label: line, value: null, dense: true),
          if (status.recommended)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: PillTag(
                label: 'Đề xuất cho bạn',
                color: PQColors.sun,
                textColor: Color(0xFF304747),
                icon: Icons.auto_awesome_rounded,
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    this.value,
    this.trailing,
    this.dense = false,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: dense ? 5 : 7),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFD1D7B8), width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(label, style: PQText.body.copyWith(fontSize: 13.5))),
          if (value != null) ...[
            const SizedBox(width: 12),
            Text(
              value!,
              style: PQText.h3.copyWith(fontSize: 20, color: const Color(0xFF32605B)),
            ),
          ],
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

/// `.footer` của r56: nằm ngoài vùng cuộn, không đè hero/chữ, action text wrap
/// tự nhiên và nút cao >=48px. Hành vi pop giữ nguyên hợp đồng nguồn
/// (`open` / `lesson:<id>` / null) — R56 không đổi navigation hay phí.
class _SheetActions extends StatelessWidget {
  const _SheetActions({required this.def, required this.status});
  final ActivityDef def;
  final ActivityStatus status;

  @override
  Widget build(BuildContext context) {
    final String? lessonId = status.unlockLessonId;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF7EFD8),
        border: Border(top: BorderSide(color: Color(0xFFD5C6A4), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (status.locked && lessonId != null)
            ChunkyButton(
              key: const ValueKey('sheet_go_lesson'),
              label: 'Đi tới bài học',
              icon: Icons.school_rounded,
              tone: PQTone.py,
              expand: true,
              onPressed: () => Navigator.of(context).pop('lesson:$lessonId'),
            )
          else if (!status.locked)
            ChunkyButton(
              key: const ValueKey('sheet_open'),
              label: 'Vào ${def.name}',
              icon: Icons.play_arrow_rounded,
              tone: def.tone,
              expand: true,
              onPressed: () => Navigator.of(context).pop('open'),
            ),
          const SizedBox(height: 10),
          ChunkyButton(
            label: 'Để sau',
            tone: PQTone.parchment,
            expand: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
