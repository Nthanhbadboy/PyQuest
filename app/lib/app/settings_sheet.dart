import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../python_runtime/simulated_runtime.dart';
import '../shared/theme/app_theme.dart';
import '../shared/theme/palette.dart';
import '../shared/widgets/chunky_button.dart';
import '../shared/widgets/common.dart';
import 'app_scope.dart';

Future<void> showSettingsSheet(BuildContext context) {
  return showPQSheet<void>(context, builder: (ctx) => const _SettingsSheet());
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final settings = s.settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Cài đặt', style: PQText.h2),
            const SizedBox(height: 12),
            PQPanel(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                children: [
                  _ToggleRow(
                    key: const ValueKey('toggle_sound'),
                    icon: Icons.volume_up_rounded,
                    label: 'Âm thanh hiệu ứng',
                    value: settings.soundOn,
                    onChanged: settings.setSoundOn,
                  ),
                  _ToggleRow(
                    key: const ValueKey('toggle_music'),
                    icon: Icons.music_note_rounded,
                    label: 'Nhạc nền',
                    value: settings.musicOn,
                    onChanged: settings.setMusicOn,
                  ),
                  _ToggleRow(
                    key: const ValueKey('toggle_calm'),
                    icon: Icons.spa_rounded,
                    label: 'Chế độ êm dịu (ít chuyển động)',
                    value: settings.calmMode,
                    onChanged: settings.setCalmMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ChunkyButton(
              label: 'Về PyQuest Python',
              icon: Icons.info_rounded,
              tone: PQTone.py,
              expand: true,
              onPressed: () => showPythonLimits(context),
            ),
            const SizedBox(height: 10),
            ChunkyButton(
              label: 'Xoá toàn bộ tiến trình',
              icon: Icons.delete_forever_rounded,
              tone: PQTone.danger,
              expand: true,
              onPressed: () => _confirmReset(context),
            ),
            const SizedBox(height: 14),
            Text(
              'PyQuest 0.1 · Đảo Khởi Đầu. Mọi dữ liệu chỉ lưu trên máy này. '
              'Không quảng cáo, không mua hàng, không thu thập thông tin cá nhân.',
              textAlign: TextAlign.center,
              style: PQText.small,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    // Parent gate: a small multiplication a young child is unlikely to solve by accident.
    final rnd = math.Random();
    final a = 6 + rnd.nextInt(4);
    final b = 6 + rnd.nextInt(4);
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PQColors.parchment,
        title: Text('Dành cho bố mẹ', style: PQText.h2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thao tác này xoá mọi tiến trình, huy hiệu và mê cung tự tạo. Để tiếp tục, hãy nhập kết quả:',
                style: PQText.body),
            const SizedBox(height: 8),
            Text('$a × $b = ?', style: PQText.h2),
            TextField(
              key: const ValueKey('parent_gate_field'),
              controller: controller,
              keyboardType: TextInputType.number,
              style: PQText.h3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Huỷ', style: PQText.label)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim() == '${a * b}'),
            child: Text('Xoá', style: PQText.label.copyWith(color: PQColors.danger)),
          ),
        ],
      ),
    );
    controller.dispose();
    if (ok == true && context.mounted) {
      await AppScope.of(context).resetAllProgress();
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({super.key, required this.icon, required this.label, required this.value, required this.onChanged});
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: PQColors.inkSoft, size: 26),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: PQText.bodyStrong)),
            PQToggle(value: value),
          ],
        ),
      ),
    );
  }
}

/// Chunky on/off switch (custom to keep the look consistent).
class PQToggle extends StatelessWidget {
  const PQToggle({super.key, required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 60,
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? PQColors.success : PQColors.disabled,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PQColors.ink, width: 2.4),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: PQColors.ink, width: 2),
          ),
        ),
      ),
    );
  }
}

Future<void> showPythonLimits(BuildContext context) {
  return showPQSheet<void>(
    context,
    builder: (ctx) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('PyQuest Python (mô phỏng)', style: PQText.h2),
          const SizedBox(height: 6),
          Text(
            'Code của bạn chạy trên một phiên bản Python thu nhỏ được viết riêng cho PyQuest, ngay trên máy, '
            'không cần mạng. Nó giống Python thật ở những phần cơ bản nhưng KHÔNG phải Python đầy đủ.',
            style: PQText.body,
          ),
          const SizedBox(height: 12),
          Text('Bạn có thể dùng', style: PQText.h3.copyWith(color: PQColors.successDeep)),
          for (final line in pyQuestPythonSupported) _bullet(line, Icons.check_circle_rounded, PQColors.success),
          const SizedBox(height: 10),
          Text('Giới hạn', style: PQText.h3.copyWith(color: PQColors.coralDeep)),
          for (final line in pyQuestPythonLimits) _bullet(line, Icons.info_rounded, PQColors.coral),
        ],
      ),
    ),
  );
}

Widget _bullet(String text, IconData icon, Color color) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: PQText.body.copyWith(fontSize: 15.5))),
        ],
      ),
    );
