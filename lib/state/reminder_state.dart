import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/alarm_channel.dart';

const String _kReminderKey = 'mm_reminders_v1';

/// One daily reminder. Days use 1 = Monday ... 7 = Sunday.
class Reminder {
  final String id;
  final int alarmId; // number the phone uses for this alarm
  final int hour; // 0-23
  final int minute;
  final Set<int> days;
  final String label;
  final bool enabled;

  const Reminder({
    required this.id,
    required this.alarmId,
    required this.hour,
    required this.minute,
    required this.days,
    this.label = 'Time to train',
    this.enabled = true,
  });

  Reminder copyWith({
    int? hour,
    int? minute,
    Set<int>? days,
    String? label,
    bool? enabled,
  }) =>
      Reminder(
        id: id,
        alarmId: alarmId,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        days: days ?? this.days,
        label: label ?? this.label,
        enabled: enabled ?? this.enabled,
      );

  /// "12:00 PM"
  String get timeText => formatTime12(hour, minute);

  /// "Every day", "Weekdays" or "Mon, Wed, Fri".
  String get daysText {
    if (days.length == 7) return 'Every day';
    if (days.isEmpty) return 'Never';
    if (days.length == 5 && !days.contains(6) && !days.contains(7)) {
      return 'Weekdays';
    }
    final sorted = days.toList()..sort();
    return sorted.map((d) => kDayShort[d - 1]).join(', ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'alarmId': alarmId,
        'hour': hour,
        'minute': minute,
        'days': (days.toList()..sort()),
        'label': label,
        'enabled': enabled,
      };

  /// The shape the Android side reads (its own `id` is the alarm number).
  Map<String, dynamic> toNative() => {
        'id': alarmId,
        'hour': hour,
        'minute': minute,
        'days': (days.toList()..sort()),
        'label': label,
        'enabled': enabled,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) {
    final rawDays = (j['days'] as List?) ?? const [];
    return Reminder(
      id: (j['id'] as String?) ?? newId(),
      alarmId: (j['alarmId'] as num?)?.toInt() ?? 1,
      hour: ((j['hour'] as num?)?.toInt() ?? 12).clamp(0, 23),
      minute: ((j['minute'] as num?)?.toInt() ?? 0).clamp(0, 59),
      days: rawDays
          .whereType<num>()
          .map((e) => e.toInt())
          .where((d) => d >= 1 && d <= 7)
          .toSet(),
      label: (j['label'] as String?) ?? 'Time to train',
      enabled: j['enabled'] != false,
    );
  }
}

/// 24h to "12:05 PM" style text.
String formatTime12(int hour, int minute) {
  final h = hour % 12 == 0 ? 12 : hour % 12;
  final m = minute.toString().padLeft(2, '0');
  return '$h:$m ${hour < 12 ? 'AM' : 'PM'}';
}

/// The next time this reminder rings after [now], or null if it never does.
DateTime? nextOccurrence(Reminder r, DateTime now) {
  if (!r.enabled || r.days.isEmpty) return null;
  for (var offset = 0; offset <= 7; offset++) {
    final day = DateTime(now.year, now.month, now.day + offset);
    final at = DateTime(day.year, day.month, day.day, r.hour, r.minute);
    if (at.isAfter(now) && r.days.contains(at.weekday)) return at;
  }
  return null;
}

/// "Today 12:00 PM", "Tomorrow 12:00 PM" or "Wed 12:00 PM".
String describeNext(DateTime at, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(at.year, at.month, at.day);
  final diff = that.difference(today).inDays;
  final time = formatTime12(at.hour, at.minute);
  if (diff == 0) return 'Today $time';
  if (diff == 1) return 'Tomorrow $time';
  return '${kDayShort[at.weekday - 1]} $time';
}

class ReminderState extends ChangeNotifier {
  ReminderState({AlarmChannel? channel}) : _channel = channel ?? AlarmChannel();

  final AlarmChannel _channel;

  bool loaded = false;
  List<Reminder> reminders = [];
  String soundPath = '';
  String soundName = '';
  bool vibrate = true;
  int ringSeconds = 60;

  static const List<int> ringOptions = [30, 60, 120, 300];

  bool get hasCustomSound => soundPath.isNotEmpty;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kReminderKey);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        soundPath = (j['soundPath'] as String?) ?? '';
        soundName = (j['soundName'] as String?) ?? '';
        vibrate = j['vibrate'] != false;
        ringSeconds = ((j['ringSeconds'] as num?)?.toInt() ?? 60).clamp(5, 600);
        reminders = ((j['reminders'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Reminder.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        // First launch: one reminder at 12:00 PM every day, ready to edit.
        reminders = [
          Reminder(
            id: newId(),
            alarmId: 1,
            hour: 12,
            minute: 0,
            days: {1, 2, 3, 4, 5, 6, 7},
            enabled: false,
          ),
        ];
      }
    } catch (_) {
      reminders = [];
    }
    loaded = true;
    notifyListeners();
    // Set the phone's alarms again, in case the phone forgot them.
    await _channel.scheduleAll(nativeConfig());
  }

  /// The JSON the Android side stores and reads.
  String nativeConfig() => jsonEncode({
        'sound': soundPath,
        'vibrate': vibrate,
        'ringSeconds': ringSeconds,
        'reminders': reminders.map((r) => r.toNative()).toList(),
      });

  Future<void> _commit() async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kReminderKey,
        jsonEncode({
          'soundPath': soundPath,
          'soundName': soundName,
          'vibrate': vibrate,
          'ringSeconds': ringSeconds,
          'reminders': reminders.map((r) => r.toJson()).toList(),
        }),
      );
    } catch (_) {}
    await _channel.scheduleAll(nativeConfig());
  }

  int _nextAlarmId() {
    var id = 1;
    final used = reminders.map((r) => r.alarmId).toSet();
    while (used.contains(id)) {
      id++;
    }
    return id;
  }

  Future<void> add({
    required int hour,
    required int minute,
    required Set<int> days,
    String label = 'Time to train',
  }) {
    reminders = [
      ...reminders,
      Reminder(
        id: newId(),
        alarmId: _nextAlarmId(),
        hour: hour,
        minute: minute,
        days: days,
        label: label.trim().isEmpty ? 'Time to train' : label.trim(),
      ),
    ];
    return _commit();
  }

  Future<void> update(Reminder r) {
    reminders = [for (final x in reminders) x.id == r.id ? r : x];
    return _commit();
  }

  Future<void> setEnabled(String id, bool on) {
    reminders = [
      for (final x in reminders) x.id == id ? x.copyWith(enabled: on) : x,
    ];
    return _commit();
  }

  Future<void> remove(String id) {
    reminders = reminders.where((x) => x.id != id).toList();
    return _commit();
  }

  Future<void> setSound(String path, String name) {
    soundPath = path;
    soundName = name;
    return _commit();
  }

  Future<void> useDefaultSound() => setSound('', '');

  Future<void> setVibrate(bool v) {
    vibrate = v;
    return _commit();
  }

  Future<void> setRingSeconds(int s) {
    ringSeconds = s.clamp(5, 600);
    return _commit();
  }

  /// Rings once in [seconds] using the current sound, to check it works.
  Future<bool> test({int seconds = 10}) => _channel.testIn(seconds, nativeConfig());
}
