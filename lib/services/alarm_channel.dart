import 'package:flutter/services.dart';

/// What the phone says about the permissions the alarm needs.
class AlarmStatus {
  final bool notifications;
  final bool exact;
  final bool batteryUnrestricted;

  const AlarmStatus({
    this.notifications = true,
    this.exact = true,
    this.batteryUnrestricted = false,
  });
}

/// A picked music file, copied into the app's own storage.
class PickedSound {
  final String path;
  final String name;
  const PickedSound(this.path, this.name);
}

/// Talks to the Android side (Kotlin) that sets the real phone alarms.
/// Off Android, or if something fails, every call quietly does nothing.
class AlarmChannel {
  static const MethodChannel _ch = MethodChannel('muscle_memory/alarms');

  Future<bool> scheduleAll(String configJson) =>
      _bool('scheduleAll', {'config': configJson});

  Future<bool> testIn(int seconds, String configJson) =>
      _bool('testIn', {'seconds': seconds, 'config': configJson});

  Future<bool> stopAlarm() => _bool('stopAlarm');
  Future<bool> requestNotifications() => _bool('requestNotifications');
  Future<bool> openExactAlarmSettings() => _bool('openExactAlarmSettings');
  Future<bool> openBatterySettings() => _bool('openBatterySettings');
  Future<bool> openAppSettings() => _bool('openAppSettings');

  Future<AlarmStatus> status() async {
    try {
      final m = await _ch.invokeMapMethod<String, dynamic>('status');
      if (m == null) return const AlarmStatus();
      return AlarmStatus(
        notifications: m['notifications'] != false,
        exact: m['exact'] != false,
        batteryUnrestricted: m['batteryUnrestricted'] == true,
      );
    } catch (_) {
      return const AlarmStatus();
    }
  }

  /// Opens the phone's file picker for music. Returns null if cancelled.
  Future<PickedSound?> pickAudio() async {
    try {
      final m = await _ch.invokeMapMethod<String, dynamic>('pickAudio');
      if (m == null) return null;
      final path = m['path'] as String?;
      if (path == null || path.isEmpty) return null;
      return PickedSound(path, (m['name'] as String?) ?? 'Your music');
    } catch (_) {
      return null;
    }
  }

  Future<bool> _bool(String method, [Map<String, dynamic>? args]) async {
    try {
      final r = await _ch.invokeMethod<dynamic>(method, args);
      return r == true;
    } catch (_) {
      return false;
    }
  }
}
