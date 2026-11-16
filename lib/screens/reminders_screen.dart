import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/alarm_channel.dart';
import '../state/reminder_state.dart';
import '../theme/pixel_theme.dart';
import '../widgets/pixel_widgets.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with WidgetsBindingObserver {
  final AlarmChannel _channel = AlarmChannel();
  AlarmStatus _status = const AlarmStatus();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from a phone settings page: check the permissions again.
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final s = await _channel.status();
    if (mounted) setState(() => _status = s);
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 4),
      child: PixelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: PX.title(10)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _note(String text) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(text, style: PX.body(13, color: PX.grey)),
      );

  Widget _permRow(String label, bool ok, String fixLabel, VoidCallback fix) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(ok ? Icons.check_box : Icons.error_outline,
              color: ok ? PX.green : PX.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: PX.body(14, weight: FontWeight.w700)),
          ),
          if (!ok)
            PixelButton(
              label: fixLabel,
              small: true,
              color: PX.yellow,
              onPressed: fix,
            ),
        ],
      ),
    );
  }

  Future<void> _pickMusic(ReminderState rs) async {
    final picked = await _channel.pickAudio();
    if (picked == null) return;
    await rs.setSound(picked.path, picked.name);
    if (mounted) showPixelSnack(context, 'Ringtone set: ${picked.name}');
  }

  Future<void> _test(ReminderState rs) async {
    await rs.test(seconds: 10);
    if (!mounted) return;
    showPixelSnack(
      context,
      'Rings in 10 seconds. You can lock the phone or leave the app.',
    );
  }

  Future<void> _edit({Reminder? existing}) async {
    final rs = context.read<ReminderState>();
    var hour = existing?.hour ?? 12;
    var minute = existing?.minute ?? 0;
    final days = <int>{...(existing?.days ?? {1, 2, 3, 4, 5, 6, 7})};
    final label = TextEditingController(text: existing?.label ?? 'Time to train');

    final save = await showPixelDialog<bool>(
      context,
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(existing == null ? 'NEW REMINDER' : 'EDIT REMINDER',
                style: PX.title(12)),
            const SizedBox(height: 14),
            PixelButton(
              label: formatTime12(hour, minute),
              icon: Icons.access_time,
              color: PX.white,
              expand: true,
              onPressed: () async {
                final t = await showTimePicker(
                  context: ctx,
                  initialTime: TimeOfDay(hour: hour, minute: minute),
                );
                if (t != null) {
                  setLocal(() {
                    hour = t.hour;
                    minute = t.minute;
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            Text('REPEAT ON', style: PX.title(9, color: PX.grey)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (var d = 1; d <= 7; d++)
                  PixelChip(
                    label: kDayShort[d - 1],
                    selected: days.contains(d),
                    onTap: () => setLocal(() {
                      if (!days.remove(d)) days.add(d);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: label,
              style: PX.body(15),
              decoration: pixelInputDecoration(hint: 'Message'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PixelButton(
                    label: 'Cancel',
                    color: PX.white,
                    expand: true,
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: PixelButton(
                    label: 'Save',
                    expand: true,
                    onPressed: days.isEmpty ? null : () => Navigator.pop(ctx, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final text = label.text;
    label.dispose();
    if (save != true) return;
    if (existing == null) {
      await rs.add(hour: hour, minute: minute, days: days, label: text);
    } else {
      await rs.update(existing.copyWith(
        hour: hour,
        minute: minute,
        days: days,
        label: text.trim().isEmpty ? 'Time to train' : text.trim(),
        enabled: true,
      ));
    }
    _refreshStatus();
  }

  Widget _reminderTile(ReminderState rs, Reminder r) {
    final next = nextOccurrence(r, DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PixelCard(
        color: r.enabled ? PX.white : PX.paper,
        onTap: () => _edit(existing: r),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.timeText, style: PX.title(16)),
                  const SizedBox(height: 4),
                  Text(r.daysText, style: PX.body(14, weight: FontWeight.w700)),
                  Text(r.label, style: PX.body(13, color: PX.grey)),
                  if (r.enabled && next != null)
                    Text('Next: ${describeNext(next, DateTime.now())}',
                        style: PX.body(13, color: PX.grey)),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: r.enabled,
                  activeTrackColor: PX.green,
                  onChanged: (v) => rs.setEnabled(r.id, v),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline, color: PX.ink),
                  onPressed: () async {
                    final ok = await showPixelConfirm(
                      context,
                      title: 'Delete reminder?',
                      message: '${r.timeText} (${r.daysText}) will be removed.',
                      confirmLabel: 'Delete',
                    );
                    if (ok) rs.remove(r.id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = context.watch<ReminderState>();
    final allGood = _status.notifications &&
        _status.exact &&
        _status.batteryUnrestricted;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PixelButton(
                    label: '',
                    icon: Icons.arrow_back,
                    small: true,
                    color: PX.white,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 6),
                  Text('REMINDERS', style: PX.title(16)),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    _section('Reminders', [
                      if (rs.reminders.isEmpty)
                        Text('No reminders yet.', style: PX.body(14)),
                      for (final r in rs.reminders) _reminderTile(rs, r),
                      PixelButton(
                        label: 'Add reminder',
                        icon: Icons.add,
                        expand: true,
                        onPressed: () => _edit(),
                      ),
                    ]),
                    _section('Ringtone', [
                      Text(
                        rs.hasCustomSound
                            ? 'Your music: ${rs.soundName}'
                            : 'Phone default alarm sound',
                        style: PX.body(15, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      PixelButton(
                        label: 'Choose music from phone',
                        icon: Icons.music_note,
                        expand: true,
                        onPressed: () => _pickMusic(rs),
                      ),
                      if (rs.hasCustomSound) ...[
                        const SizedBox(height: 10),
                        PixelButton(
                          label: 'Use default sound',
                          color: PX.white,
                          expand: true,
                          onPressed: rs.useDefaultSound,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text('RING FOR', style: PX.title(9, color: PX.grey)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: [
                          for (final s in ReminderState.ringOptions)
                            PixelChip(
                              label: s < 60 ? '$s sec' : '${s ~/ 60} min',
                              selected: rs.ringSeconds == s,
                              onTap: () => rs.setRingSeconds(s),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      PixelChip(
                        label: 'Vibrate',
                        selected: rs.vibrate,
                        color: PX.green,
                        onTap: () => rs.setVibrate(!rs.vibrate),
                      ),
                      _note(
                        'The song loops until you press STOP on the '
                        'notification or the time above runs out.',
                      ),
                    ]),
                    _section('Test', [
                      PixelButton(
                        label: 'Test alarm in 10 seconds',
                        icon: Icons.alarm,
                        color: PX.yellow,
                        expand: true,
                        onPressed: () => _test(rs),
                      ),
                      const SizedBox(height: 10),
                      PixelButton(
                        label: 'Stop ringing',
                        color: PX.white,
                        expand: true,
                        onPressed: _channel.stopAlarm,
                      ),
                    ]),
                    _section('Make it reliable', [
                      _permRow(
                        'Notifications allowed',
                        _status.notifications,
                        'Allow',
                        () async {
                          await _channel.requestNotifications();
                          await Future<void>.delayed(
                              const Duration(milliseconds: 800));
                          _refreshStatus();
                        },
                      ),
                      _permRow(
                        'Exact alarms allowed',
                        _status.exact,
                        'Allow',
                        _channel.openExactAlarmSettings,
                      ),
                      _permRow(
                        'Battery: no limits',
                        _status.batteryUnrestricted,
                        'Fix',
                        _channel.openBatterySettings,
                      ),
                      if (!allGood)
                        _note(
                          'Honor phones close apps to save battery, which can '
                          'stop alarms. On your Honor X7c also do this: Settings '
                          '> Apps > App launch > Muscle Memory > turn off '
                          '"Manage automatically", then turn ON Auto-launch, '
                          'Secondary launch and Run in background. In recent '
                          'apps, pull the app card down to lock it.',
                        ),
                      const SizedBox(height: 10),
                      PixelButton(
                        label: 'Open app settings',
                        color: PX.white,
                        expand: true,
                        onPressed: _channel.openAppSettings,
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
