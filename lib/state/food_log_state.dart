import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/log_models.dart';

/// What you ate each day, plus your daily calorie and protein goals.
class FoodLogState extends ChangeNotifier {
  FoodLogState({this.persist = true}) : selected = dateOnly(DateTime.now());

  static const String _storageKey = 'gym_foodlog_v1';

  final bool persist;
  bool loaded = false;

  /// The day shown on the "My day" view. New foods are added to this day.
  DateTime selected;

  int kcalGoal = 2000;
  int proteinGoal = 100;

  final Map<String, List<FoodEntry>> _days = {};

  Future<void> _pending = Future<void>.value();

  /// Completes when the latest save has finished (handy in tests).
  Future<void> flush() => _pending;

  Future<void> load() async {
    if (persist) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_storageKey);
        if (raw != null) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          kcalGoal = (data['kcalGoal'] as num?)?.toInt() ?? kcalGoal;
          proteinGoal = (data['proteinGoal'] as num?)?.toInt() ?? proteinGoal;
          final days = (data['days'] as Map?) ?? const {};
          days.forEach((key, value) {
            _days[key as String] = (value as List)
                .map((e) =>
                    FoodEntry.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
          });
        }
      } catch (_) {
        // Unreadable saved data: start fresh.
      }
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    if (!persist) return;
    try {
      final json = jsonEncode({
        'kcalGoal': kcalGoal,
        'proteinGoal': proteinGoal,
        'days': _days.map(
          (key, list) => MapEntry(key, list.map((e) => e.toJson()).toList()),
        ),
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

  /// Read only. Do not modify the returned list.
  List<FoodEntry> entriesOn(String date) => _days[date] ?? const <FoodEntry>[];

  DayTotals totalsOn(String date) {
    var kcal = 0.0, protein = 0.0, carbs = 0.0, fat = 0.0;
    for (final e in entriesOn(date)) {
      kcal += e.totalKcal;
      protein += e.totalProtein;
      carbs += e.totalCarbs;
      fat += e.totalFat;
    }
    return DayTotals(kcal, protein, carbs, fat);
  }

  void selectDate(DateTime d) {
    selected = dateOnly(d);
    notifyListeners();
  }

  void addFood(String date, FoodEntry entry) {
    _days.putIfAbsent(date, () => <FoodEntry>[]).add(entry);
    _changed();
  }

  /// Removes and returns the entry so the caller can offer "undo".
  FoodEntry? removeEntry(String date, String id) {
    final list = _days[date];
    if (list == null) return null;
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return null;
    final removed = list.removeAt(i);
    if (list.isEmpty) _days.remove(date);
    _changed();
    return removed;
  }

  void insertEntry(String date, int index, FoodEntry entry) {
    final list = _days.putIfAbsent(date, () => <FoodEntry>[]);
    final safeIndex = index.clamp(0, list.length).toInt();
    list.insert(safeIndex, entry);
    _changed();
  }

  void setGoals(int kcal, int protein) {
    kcalGoal = kcal;
    proteinGoal = protein;
    _changed();
  }
}
