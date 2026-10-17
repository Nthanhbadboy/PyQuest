import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/localization/locale_preference.dart';
import '../core/settings_service.dart';
import '../l10n/generated/app_localizations.dart';
import '../shared/theme/app_theme.dart';
import '../shared/theme/palette.dart';
import '../shared/widgets/chunky_button.dart';
import '../shared/widgets/common.dart';
import 'app_scope.dart';

Future<void> showSettingsSheet(BuildContext context) {
  return showPQSheet<void>(context, builder: (_) => const _SettingsSheet());
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final services = AppScope.of(context);
    final settings = services.settings;
    return ListenableBuilder(
      listenable: settings,
      builder: (BuildContext context, Widget? _) {
        final AppLocalizations l10n = AppLocalizations.of(context)!;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(l10n.settingsTitle, style: PQText.h2),
              const SizedBox(height: 12),
              _LanguagePreferencePanel(settings: settings),
              const SizedBox(height: 12),
              PQPanel(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  children: <Widget>[
                    _ToggleRow(
                      key: const ValueKey<String>('toggle_sound'),
                      icon: Icons.volume_up_rounded,
                      label: l10n.settingsSound,
                      value: settings.soundOn,
                      onChanged: settings.setSoundOn,
                    ),
                    _ToggleRow(
                      key: const ValueKey<String>('toggle_music'),
                      icon: Icons.music_note_rounded,
                      label: l10n.settingsMusic,
                      value: settings.musicOn,
                      onChanged: settings.setMusicOn,
                    ),
                    _ToggleRow(
                      key: const ValueKey<String>('toggle_calm'),
                      icon: Icons.spa_rounded,
                      label: l10n.settingsCalm,
                      value: settings.calmMode,
                      onChanged: settings.setCalmMode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ChunkyButton(
                key: const ValueKey<String>('settings_about_python'),
                label: l10n.settingsAboutPython,
                icon: Icons.info_rounded,
                tone: PQTone.py,
                expand: true,
                onPressed: () => showPythonLimits(context),
              ),
              const SizedBox(height: 10),
              ChunkyButton(
                key: const ValueKey<String>('settings_reset_progress'),
                label: l10n.settingsResetProgress,
                icon: Icons.delete_forever_rounded,
                tone: PQTone.danger,
                expand: true,
                onPressed: () => _confirmReset(context),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.settingsFooter,
                key: const ValueKey<String>('settings_footer'),
                textAlign: TextAlign.center,
                style: PQText.small,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    // Parent gate: a small multiplication a young child is unlikely to solve by accident.
    final math.Random random = math.Random();
    final int a = 6 + random.nextInt(4);
    final int b = 6 + random.nextInt(4);
    final TextEditingController controller = TextEditingController();
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final AppLocalizations l10n = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          backgroundColor: PQColors.parchment,
          title: Text(
            l10n.settingsParentTitle,
            key: const ValueKey<String>('settings_parent_title'),
            style: PQText.h2,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.settingsParentWarning,
                key: const ValueKey<String>('settings_parent_warning'),
                style: PQText.body,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.settingsParentQuestion(a, b),
                key: const ValueKey<String>('settings_parent_question'),
                style: PQText.h2,
              ),
              TextField(
                key: const ValueKey<String>('parent_gate_field'),
                controller: controller,
                keyboardType: TextInputType.number,
                style: PQText.h3,
                decoration: InputDecoration(labelText: l10n.settingsParentAnswer),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.settingsCancel, style: PQText.label),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim() == '${a * b}'),
              child: Text(l10n.settingsDelete, style: PQText.label.copyWith(color: PQColors.danger)),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (ok == true && context.mounted) {
      await AppScope.of(context).resetAllProgress();
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _LanguagePreferencePanel extends StatefulWidget {
  const _LanguagePreferencePanel({required this.settings});

  final SettingsService settings;

  @override
  State<_LanguagePreferencePanel> createState() => _LanguagePreferencePanelState();
}

class _LanguagePreferencePanelState extends State<_LanguagePreferencePanel> {
  int _requestSequence = 0;
  int? _pendingRequest;

  Future<void> _savePreference(LocalePreference preference, {bool retry = false}) async {
    if (!retry && _pendingRequest == null && preference == widget.settings.localePreference) return;
    final int request = ++_requestSequence;
    setState(() => _pendingRequest = request);

    await widget.settings.setLocalePreference(preference);

    // Older writes may complete after a newer selection. Only the latest request owns
    // this panel's saving state; the SettingsService likewise owns the persisted error.
    if (!mounted || request != _requestSequence) return;
    setState(() => _pendingRequest = null);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final SettingsService settings = widget.settings;
    final LocalePreference preference = settings.localePreference;
    final String activeLanguage = settings.localeResolution.languageCode == 'vi'
        ? l10n.settingsLanguageVi
        : l10n.settingsLanguageEn;
    final bool showFallback = preference == LocalePreference.system &&
        settings.localeResolution.usedEnglishFallback;
    final bool isSaving = _pendingRequest != null;
    final bool hasSaveError = settings.localePreferenceSaveError != null;

    return PQPanel(
      key: const ValueKey<String>('settings_language_panel'),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(l10n.settingsLanguageTitle, style: PQText.bodyStrong),
          ),
          const SizedBox(height: 8),
          RadioGroup<LocalePreference>(
            groupValue: preference,
            onChanged: (LocalePreference? value) {
              if (value != null) unawaited(_savePreference(value));
            },
            child: Column(
              children: <Widget>[
                _LocalePreferenceRow(
                  value: LocalePreference.system,
                  label: l10n.settingsLanguageSystem,
                  selected: preference == LocalePreference.system,
                ),
                const SizedBox(height: 6),
                _LocalePreferenceRow(
                  value: LocalePreference.vi,
                  label: l10n.settingsLanguageVi,
                  selected: preference == LocalePreference.vi,
                ),
                const SizedBox(height: 6),
                _LocalePreferenceRow(
                  value: LocalePreference.en,
                  label: l10n.settingsLanguageEn,
                  selected: preference == LocalePreference.en,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settingsLanguageEffective(activeLanguage),
            key: const ValueKey<String>('language_effective'),
            style: PQText.small,
          ),
          if (showFallback) ...<Widget>[
            const SizedBox(height: 6),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.settingsLanguageFallback,
                key: const ValueKey<String>('language_fallback'),
                style: PQText.small.copyWith(color: PQColors.coralDeep),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(l10n.settingsLanguageScope, style: PQText.small),
          if (isSaving) ...<Widget>[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.settingsLanguageSaving,
                key: const ValueKey<String>('language_saving'),
                style: PQText.small,
              ),
            ),
          ] else if (hasSaveError) ...<Widget>[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.settingsLanguageSaveError,
                key: const ValueKey<String>('language_save_error'),
                style: PQText.small.copyWith(color: PQColors.coralDeep),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const ValueKey<String>('language_retry'),
                onPressed: () => unawaited(
                  _savePreference(settings.localePreference, retry: true),
                ),
                child: Text(l10n.settingsLanguageRetry),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LocalePreferenceRow extends StatelessWidget {
  const _LocalePreferenceRow({
    required this.value,
    required this.label,
    required this.selected,
  });

  final LocalePreference value;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? Colors.white : PQColors.parchment,
        border: Border.all(
          color: selected ? PQColors.ink : PQColors.inkSoft,
          width: selected ? 2.2 : 1.4,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: RadioListTile<LocalePreference>(
        key: ValueKey<String>('language_${value.storageValue}'),
        value: value,
        title: Text(label, softWrap: true, style: PQText.bodyStrong),
        selected: selected,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        minTileHeight: 52,
        visualDensity: VisualDensity.standard,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        activeColor: PQColors.sea,
        radioSide: const BorderSide(color: PQColors.ink, width: 1.8),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    void toggle() => onChanged(!value);
    return Semantics(
      container: true,
      button: true,
      label: label,
      toggled: value,
      onTap: toggle,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: toggle,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: <Widget>[
                Icon(icon, color: PQColors.inkSoft, size: 26),
                const SizedBox(width: 10),
                Expanded(child: Text(label, style: PQText.bodyStrong)),
                PQToggle(value: value),
              ],
            ),
          ),
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
    builder: (BuildContext context) {
      final AppLocalizations l10n = AppLocalizations.of(context)!;
      final List<String> supported = <String>[
        l10n.settingsPythonSupportedValues,
        l10n.settingsPythonSupportedOperators,
        l10n.settingsPythonSupportedFlow,
        l10n.settingsPythonSupportedLists,
        l10n.settingsPythonSupportedFunctions,
        l10n.settingsPythonSupportedFString('f"Xin chào {ten}"'),
        l10n.settingsPythonSupportedBuiltins,
      ];
      final List<String> limits = <String>[
        l10n.settingsPythonLimitFeatures,
        l10n.settingsPythonLimitSteps,
        l10n.settingsPythonLimitDepthOutput,
        l10n.settingsPythonLimitIntegers,
        l10n.settingsPythonLimitOutputTiming,
        l10n.settingsPythonLimitNames,
      ];
      return SingleChildScrollView(
        key: const ValueKey<String>('python_info_sheet'),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l10n.settingsPythonTitle, style: PQText.h2),
            const SizedBox(height: 6),
            Text(l10n.settingsPythonIntro, style: PQText.body),
            const SizedBox(height: 12),
            Text(
              l10n.settingsPythonSupportedTitle,
              style: PQText.h3.copyWith(color: PQColors.successDeep),
            ),
            for (final String line in supported) _bullet(line, Icons.check_circle_rounded, PQColors.success),
            const SizedBox(height: 10),
            Text(l10n.settingsPythonLimitsTitle, style: PQText.h3.copyWith(color: PQColors.coralDeep)),
            for (final String line in limits) _bullet(line, Icons.info_rounded, PQColors.coral),
          ],
        ),
      );
    },
  );
}

Widget _bullet(String text, IconData icon, Color color) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: PQText.body.copyWith(fontSize: 15.5))),
        ],
      ),
    );
