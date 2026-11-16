import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/log_models.dart';
import '../models/models.dart';

/// How a day looks in the week strip.
enum DayStatus {
  /// Nothing planned (a rest day).
  empty,

  /// Planned, not finished yet, and the day is today or still to come.
  pending,

  /// Everything planned for the day is ticked.
  done,

  /// The day has passed and something planned was not ticked.
  missed,
}

/// Holds the 7-day schedule and saves it on the phone after every change.
class PlannerState extends ChangeNotifier {
  PlannerState({this.persist = true});

  // Kept from the first version so existing saved schedules still load.
  static const String _storageKey = 'gym_planner_v1';

  /// Set to false in tests that should not touch storage.
  final bool persist;

  /// Index 0 = Monday ... 6 = Sunday.
  final List<DayPlan> days = List<DayPlan>.generate(7, (_) => DayPlan());

  bool loaded = false;

  /// Date key of the Monday the current ticks belong to.
  String weekStart = '';

  Future<void> _pending = Future<void>.value();

  /// Completes when the latest save has finished (handy in tests).
  Future<void> flush() => _pending;

  Future<void> load() async {
    String? savedWeek;
    if (persist) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_storageKey);
        if (raw != null) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          savedWeek = data['weekStart'] as String?;
          final list = (data['days'] as List?) ?? const [];
          for (var i = 0; i < 7 && i < list.length; i++) {
            final plan =
                DayPlan.fromJson(Map<String, dynamic>.from(list[i] as Map));
            days[i].focuses
              ..clear()
              ..addAll(plan.focuses);
            days[i].customLabel = plan.customLabel;
            days[i].exercises
              ..clear()
              ..addAll(plan.exercises);
            days[i].runKm = plan.runKm;
            days[i].runDone = plan.runDone;
          }
        }
      } catch (_) {
        // Unreadable saved data: start with an empty week instead of crashing.
      }
    }
    // Data saved before weekly resets existed is treated as this week's.
    weekStart = savedWeek ?? weekStartKey(DateTime.now());
    loaded = true;
    refreshWeek();
    notifyListeners();
  }

  Future<void> _save() async {
    if (!persist) return;
    try {
      final json = jsonEncode({
        'weekStart': weekStart,
        'days': days.map((d) => d.toJson()).toList(),
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json);
    } catch (_) {
      // Saving is best effort; the app keeps working in memory.
    }
  }

  void _changed() {
    notifyListeners();
    _pending = _save();
  }

  /// Starts a fresh week when the calendar week has changed: every tick and
  /// run check is cleared and the plan itself stays, so the loop continues.
  /// Returns true if a new week was started.
  bool refreshWeek({DateTime? now}) {
    final current = weekStartKey(now ?? DateTime.now());
    if (current == weekStart) return false;
    weekStart = current;
    for (final plan in days) {
      plan.runDone = false;
      for (final e in plan.exercises) {
        e.done = false;
      }
    }
    _changed();
    return true;
  }

  /// Red / green / neutral state of a day box.
  DayStatus statusOf(int day, {DateTime? now}) {
    final plan = days[day];
    if (!plan.hasPlan) return DayStatus.empty;
    if (plan.isComplete) return DayStatus.done;
    final today = (now ?? DateTime.now()).weekday - 1;
    return day < today ? DayStatus.missed : DayStatus.pending;
  }

  /// Replaces the focus groups of a day, e.g. ['Core', 'Chest'].
  void setFocuses(int day, List<String> groups) {
    final plan = days[day];
    plan.focuses
      ..clear()
      ..addAll(groups);
    if (groups.isNotEmpty) plan.customLabel = '';
    _changed();
  }

  /// Adds an exercise. If the day has no focus yet, [suggestedGroup]
  /// (for example "Back") becomes its focus.
  void addExercise(int day, Exercise exercise, {String suggestedGroup = ''}) {
    addExercises(
      day,
      [exercise],
      groups: suggestedGroup.isEmpty ? const [] : [suggestedGroup],
    );
  }

  /// Adds several exercises with a single save. If the day has no focus yet,
  /// [groups] become its focus.
  void addExercises(int day, List<Exercise> list,
      {List<String> groups = const []}) {
    if (list.isEmpty) return;
    final plan = days[day];
    plan.exercises.addAll(list);
    if (plan.focuses.isEmpty && plan.customLabel.trim().isEmpty) {
      for (final g in groups) {
        if (g.isNotEmpty && !plan.focuses.contains(g)) plan.focuses.add(g);
      }
    }
    _changed();
  }

  void updateExercise(int day, Exercise updated) {
    final list = days[day].exercises;
    final i = list.indexWhere((e) => e.id == updated.id);
    if (i < 0) return;
    list[i] = updated;
    _changed();
  }

  /// Removes and returns the exercise so the caller can offer "undo".
  Exercise? removeExercise(int day, String id) {
    final list = days[day].exercises;
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return null;
    final removed = list.removeAt(i);
    _changed();
    return removed;
  }

  void insertExercise(int day, int index, Exercise exercise) {
    final list = days[day].exercises;
    final safeIndex = index.clamp(0, list.length).toInt();
    list.insert(safeIndex, exercise);
    _changed();
  }

  void toggleDone(int day, String id) {
    final list = days[day].exercises;
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return;
    list[i].done = !list[i].done;
    _changed();
  }

  /// [newIndex] must already be adjusted (as after a ReorderableListView drop).
  void moveExercise(int day, int oldIndex, int newIndex) {
    final list = days[day].exercises;
    if (oldIndex < 0 || oldIndex >= list.length) return;
    final item = list.removeAt(oldIndex);
    final safeIndex = newIndex.clamp(0, list.length).toInt();
    list.insert(safeIndex, item);
    _changed();
  }

  /// Plans a run of [km] kilometres. 0 (or less) removes the run.
  void setRun(int day, double km) {
    final plan = days[day];
    plan.runKm = km > 0 ? km : 0;
    if (plan.runKm == 0) plan.runDone = false;
    _changed();
  }

  void toggleRunDone(int day) {
    final plan = days[day];
    if (!plan.hasRun) return;
    plan.runDone = !plan.runDone;
    _changed();
  }

  void clearDay(int day) {
    final plan = days[day];
    plan.exercises.clear();
    plan.focuses.clear();
    plan.customLabel = '';
    plan.runKm = 0;
    plan.runDone = false;
    _changed();
  }

  /// Un-ticks everything (this also happens by itself every Monday).
  void resetTicks() {
    for (final plan in days) {
      plan.runDone = false;
      for (final e in plan.exercises) {
        e.done = false;
      }
    }
    _changed();
  }
}
