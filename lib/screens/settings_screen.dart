import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/chat_state.dart';
import '../state/planner_state.dart';
import '../state/rest_timer_state.dart';
import '../state/settings_state.dart';
import '../theme/pixel_theme.dart';
import 'reminders_screen.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/rest_timer_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _key;
  late final TextEditingController _model;

  static const List<int> _restOptions = [45, 60, 90, 120, 180];

  static const Map<AppThemeMode, String> _themeLabels = {
    AppThemeMode.system: 'System',
    AppThemeMode.light: 'Light',
    AppThemeMode.dark: 'Dark',
  };

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsState>();
    _key = TextEditingController(text: s.apiKey);
    _model = TextEditingController(text: s.model);
  }

  @override
  void dispose() {
    _key.dispose();
    _model.dispose();
    super.dispose();
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

  void _saveCoach(SettingsState settings) {
    settings.setApiKey(_key.text);
    settings.setModel(_model.text);
    _model.text = settings.model;
    showPixelSnack(context, 'Coach settings saved');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final timer = context.watch<RestTimerState>();

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
                  Text('SETTINGS', style: PX.title(16)),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    _section('Appearance', [
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: [
                          for (final m in AppThemeMode.values)
                            PixelChip(
                              label: _themeLabels[m] ?? m.name,
                              selected: settings.themeMode == m,
                              onTap: () => settings.setThemeMode(m),
                            ),
                        ],
                      ),
                      _note('System follows your phone. The pixel look stays in both.'),
                    ]),
                    _section('My equipment', [
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: [
                          for (final e in Equip.values)
                            if (e != Equip.bodyweight)
                              PixelChip(
                                label: kEquipLabel[e] ?? e.name,
                                selected: settings.owned.contains(e),
                                color: PX.green,
                                onTap: () => settings.toggleGear(e),
                              ),
                        ],
                      ),
                      _note(
                        'Exercises you can do with this gear show a HOME tag; '
                        'the rest show GYM. Bodyweight is always included.',
                      ),
                      const SizedBox(height: 12),
                      PixelChip(
                        label: 'Show home exercises only',
                        selected: settings.homeOnly,
                        color: PX.green,
                        onTap: () => settings.setHomeOnly(!settings.homeOnly),
                      ),
                    ]),
                    _section('Rest timer', [
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: [
                          for (final s in _restOptions)
                            PixelChip(
                              label: formatClock(s),
                              selected: timer.defaultSeconds == s,
                              onTap: () => timer.setDefault(s),
                            ),
                        ],
                      ),
                      _note('Starts by itself when you tick a set in the workout log.'),
                    ]),
                    _section('Week', [
                      Text(
                        'Every Monday the ticks clear by themselves and your plan '
                        'stays, so the loop keeps going.',
                        style: PX.body(14),
                      ),
                      const SizedBox(height: 12),
                      PixelButton(
                        label: 'Untick everything now',
                        color: PX.white,
                        expand: true,
                        onPressed: () {
                          context.read<PlannerState>().resetTicks();
                          showPixelSnack(context, 'All ticks cleared');
                        },
                      ),
                    ]),
                    _section('Reminders and alarm', [
                      Text(
                        'Set daily alarm reminders (for example every day at '
                        '12:00 PM) and pick a song from your phone as the ringtone.',
                        style: PX.body(14),
                      ),
                      const SizedBox(height: 12),
                      PixelButton(
                        label: 'Open reminders',
                        icon: Icons.alarm,
                        expand: true,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const RemindersScreen()),
                        ),
                      ),
                    ]),
                    _section('Coach (chat)', [
                      Text(
                        'The Coach tab needs an API key from console.anthropic.com. '
                        'It is saved only on this phone. Each question is billed '
                        'to your Anthropic account (small amounts).',
                        style: PX.body(14),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _key,
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        style: PX.body(15),
                        decoration: pixelInputDecoration(hint: 'API key (sk-ant-...)'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _model,
                        autocorrect: false,
                        enableSuggestions: false,
                        style: PX.body(15),
                        decoration: pixelInputDecoration(hint: 'Model name'),
                      ),
                      const SizedBox(height: 12),
                      PixelButton(
                        label: 'Save coach settings',
                        expand: true,
                        onPressed: () => _saveCoach(settings),
                      ),
                      _note(
                        settings.apiKey.isEmpty
                            ? 'No key saved yet.'
                            : 'A key is saved on this phone.',
                      ),
                      const SizedBox(height: 12),
                      PixelButton(
                        label: 'Clear chat history',
                        color: PX.pink,
                        expand: true,
                        onPressed: () async {
                          final chat = context.read<ChatState>();
                          final ok = await showPixelConfirm(
                            context,
                            title: 'Clear chat?',
                            message: 'This deletes your conversation with the coach.',
                            confirmLabel: 'Clear',
                          );
                          if (ok) chat.clear();
                        },
                      ),
                    ]),
                    _section('About', [
                      Text('Muscle Memory 1.0', style: PX.body(15, weight: FontWeight.w800)),
                      _note('Your schedule, logs and settings are stored on this phone.'),
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
