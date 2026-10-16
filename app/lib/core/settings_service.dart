import 'package:flutter/foundation.dart';

import '../data/repositories/state_repositories.dart';
import '../shared/l10n/pq_l10n.dart';

/// Player preferences, persisted in the `settings` table.
class SettingsService extends ChangeNotifier {
  SettingsService(this._repo);

  final SettingsRepository _repo;
  Map<String, String> _values = {};

  Future<void> load() async {
    _values = await _repo.all();
  }

  bool _bool(String key, bool fallback) {
    final v = _values[key];
    return v == null ? fallback : v == '1';
  }

  Future<void> _set(String key, String value) async {
    _values[key] = value;
    notifyListeners();
    await _repo.put(key, value);
  }

  bool get soundOn => _bool('sound_on', true);
  bool get musicOn => _bool('music_on', true);

  /// Fewer moving decorations and shorter celebrations.
  bool get calmMode => _bool('calm_mode', false);
  bool get introSeen => _bool('intro_seen', false);

  Future<void> setSoundOn(bool v) => _set('sound_on', v ? '1' : '0');
  Future<void> setMusicOn(bool v) => _set('music_on', v ? '1' : '0');
  Future<void> setCalmMode(bool v) => _set('calm_mode', v ? '1' : '0');
  Future<void> setIntroSeen() => _set('intro_seen', '1');

  /// Language used by the cast dialogue and the AI tutor. The rest of the
  /// island is Vietnamese-only for now, and says so in Settings.
  PqLang get lang => PqLang.fromCode(_values['ui_lang']);
  PqStrings get strings => PqStrings.of(lang);
  Future<void> setLang(PqLang v) => _set('ui_lang', v.code);

  String? raw(String key) => _values[key];
  Future<void> setRaw(String key, String value) => _set(key, value);
}
