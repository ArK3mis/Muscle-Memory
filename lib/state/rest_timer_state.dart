import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rest countdown shared by the whole app, so it keeps running while you
/// switch tabs. It only runs while the app is open.
class RestTimerState extends ChangeNotifier {
  static const String _storageKey = 'mm_rest_seconds_v1';

  int defaultSeconds = 90;

  /// True after the countdown hits zero, until you dismiss it.
  bool finished = false;

  DateTime? _end;
  Timer? _timer;
  int _shown = -1;

  bool get running => _end != null;
  bool get active => running || finished;

  /// Whole seconds left (rounded up).
  int get remaining {
    final end = _end;
    if (end == null) return 0;
    final ms = end.difference(DateTime.now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  /// Loads the rest length you chose last time.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_storageKey);
      if (saved != null && saved >= 10 && saved <= 600) {
        defaultSeconds = saved;
        notifyListeners();
      }
    } catch (_) {
      // Keep the default.
    }
  }

  void setDefault(int seconds) {
    defaultSeconds = seconds;
    notifyListeners();
    _saveDefault();
  }

  Future<void> _saveDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_storageKey, defaultSeconds);
    } catch (_) {
      // Best effort.
    }
  }

  void start([int? seconds]) {
    _timer?.cancel();
    finished = false;
    _end = DateTime.now().add(Duration(seconds: seconds ?? defaultSeconds));
    _shown = -1;
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    notifyListeners();
  }

  void addSeconds(int seconds) {
    final end = _end;
    if (end == null) return;
    _end = end.add(Duration(seconds: seconds));
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _end = null;
    finished = false;
    notifyListeners();
  }

  void _tick() {
    final left = remaining;
    if (left <= 0) {
      _timer?.cancel();
      _timer = null;
      _end = null;
      finished = true;
      // Some devices have no vibration or sound; ignore that quietly.
      HapticFeedback.vibrate().catchError((_) {});
      SystemSound.play(SystemSoundType.alert).catchError((_) {});
      notifyListeners();
    } else if (left != _shown) {
      _shown = left;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
