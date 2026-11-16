import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

enum AppThemeMode { system, light, dark }

/// Model the coach chat uses. You can change it in Settings.
const String kDefaultCoachModel = 'claude-haiku-5-5';

/// App-wide choices: appearance, owned equipment and the coach API key.
class SettingsState extends ChangeNotifier {
  SettingsState({this.persist = true});

  static const String _storageKey = 'mm_settings_v1';

  final bool persist;
  bool loaded = false;

  AppThemeMode themeMode = AppThemeMode.system;

  /// Equipment you own. Bodyweight is always included.
  final Set<Equip> owned = {...kDefaultGear};

  /// When true, exercise lists only show what your equipment allows.
  bool homeOnly = true;

  /// Key for the coach chat. It is saved on this phone only.
  String apiKey = '';
  String model = kDefaultCoachModel;

  Future<void> _pending = Future<void>.value();

  /// Completes when the latest save has finished (handy in tests).
  Future<void> flush() => _pending;

  /// Copy of [owned] that can be handed to widgets.
  Set<Equip> get gear => {...owned, Equip.bodyweight};

  Future<void> load() async {
    if (persist) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_storageKey);
        if (raw != null) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          final mode = data['theme'] as String?;
          for (final m in AppThemeMode.values) {
            if (m.name == mode) themeMode = m;
          }
          final gear = data['gear'];
          if (gear is List) {
            owned
              ..clear()
              ..addAll(Equip.values.where((e) => gear.contains(e.name)));
          }
          homeOnly = (data['homeOnly'] as bool?) ?? homeOnly;
          apiKey = (data['apiKey'] as String?) ?? '';
          final savedModel = (data['model'] as String?) ?? '';
          if (savedModel.trim().isNotEmpty) model = savedModel.trim();
        }
      } catch (_) {
        // Unreadable saved data: keep the defaults.
      }
    }
    owned.add(Equip.bodyweight);
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    if (!persist) return;
    try {
      final json = jsonEncode({
        'theme': themeMode.name,
        'gear': owned.map((e) => e.name).toList(),
        'homeOnly': homeOnly,
        'apiKey': apiKey,
        'model': model,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json);
    } catch (_) {
      // Best effort.
    }
  }

  void _changed() {
    notifyListeners();
    _pending = _save();
  }

  void setThemeMode(AppThemeMode mode) {
    themeMode = mode;
    _changed();
  }

  void toggleGear(Equip e) {
    if (e == Equip.bodyweight) return;
    if (!owned.remove(e)) owned.add(e);
    _changed();
  }

  void setHomeOnly(bool value) {
    homeOnly = value;
    _changed();
  }

  void setApiKey(String value) {
    apiKey = value.trim();
    _changed();
  }

  void setModel(String value) {
    final v = value.trim();
    model = v.isEmpty ? kDefaultCoachModel : v;
    _changed();
  }
}
