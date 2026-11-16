import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/log_models.dart';

/// History of every set you log, per exercise name (not case sensitive).
class LogState extends ChangeNotifier {
  LogState({this.persist = true});

  static const String _storageKey = 'gym_log_v1';

  final bool persist;
  bool loaded = false;

  // exercise key -> entries sorted by date (oldest first)
  final Map<String, List<LogEntry>> _history = {};

  Future<void> _pending = Future<void>.value();

  /// Completes when the latest save has finished (handy in tests).
  Future<void> flush() => _pending;

  static String keyFor(String name) => name.trim().toLowerCase();

  Future<void> load() async {
    if (persist) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_storageKey);
        if (raw != null) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          data.forEach((key, value) {
            final list = (value as List)
                .map((e) =>
                    LogEntry.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList()
              ..sort((a, b) => a.date.compareTo(b.date));
            _history[key] = list;
          });
        }
      } catch (_) {
        // Unreadable saved data: start with an empty history.
      }
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    if (!persist) return;
    try {
      final json = jsonEncode(_history.map(
        (key, list) => MapEntry(key, list.map((e) => e.toJson()).toList()),
      ));
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

  List<LogEntry> _entries(String name) =>
      _history[keyFor(name)] ?? const <LogEntry>[];

  LogEntry? entryOn(String name, String date) {
    for (final e in _entries(name)) {
      if (e.date == date) return e;
    }
    return null;
  }

  /// The most recent session before [date], or null.
  LogEntry? lastBefore(String name, String date) {
    LogEntry? found;
    for (final e in _entries(name)) {
      if (e.date.compareTo(date) < 0) found = e;
    }
    return found;
  }

  /// Heaviest weight ever logged for this exercise, or null.
  double? bestWeightEver(String name) {
    double? best;
    for (final e in _entries(name)) {
      for (final s in e.sets) {
        if (s.reps > 0 && s.weight > 0 && (best == null || s.weight > best)) {
          best = s.weight;
        }
      }
    }
    return best;
  }

  /// Replaces the sets for [date]. An empty list removes that day's entry.
  void saveSets(String name, String date, List<SetEntry> sets) {
    final key = keyFor(name);
    final list = _history.putIfAbsent(key, () => <LogEntry>[]);
    list.removeWhere((e) => e.date == date);
    if (sets.isNotEmpty) {
      list.add(LogEntry(date: date, sets: sets));
      list.sort((a, b) => a.date.compareTo(b.date));
    }
    if (list.isEmpty) _history.remove(key);
    _changed();
  }

  /// A set is a personal record when it beats everything logged before [date].
  /// Weighted sets compare weight; bodyweight sets compare reps.
  /// The very first time you log an exercise is never called a PR.
  bool isPr(String name, String date, SetEntry s) {
    if (s.reps <= 0) return false;
    double? bestWeight;
    int? bestReps;
    for (final e in _entries(name)) {
      if (e.date.compareTo(date) >= 0) continue;
      for (final p in e.sets) {
        if (p.reps <= 0) continue;
        if (p.weight > 0) {
          if (bestWeight == null || p.weight > bestWeight) {
            bestWeight = p.weight;
          }
        } else {
          if (bestReps == null || p.reps > bestReps) bestReps = p.reps;
        }
      }
    }
    if (s.weight > 0) return bestWeight != null && s.weight > bestWeight;
    return bestReps != null && s.reps > bestReps;
  }
}
