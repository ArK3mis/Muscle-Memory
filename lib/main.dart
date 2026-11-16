import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/chat_screen.dart';
import 'screens/foods_screen.dart';
import 'screens/muscles_screen.dart';
import 'screens/schedule_screen.dart';
import 'state/chat_state.dart';
import 'state/food_log_state.dart';
import 'state/log_state.dart';
import 'state/planner_state.dart';
import 'state/reminder_state.dart';
import 'state/rest_timer_state.dart';
import 'state/settings_state.dart';
import 'theme/pixel_theme.dart';
import 'widgets/pixel_widgets.dart';
import 'widgets/rest_timer_bar.dart';

void main() {
  runApp(const MuscleMemoryApp());
}

/// Dark mode: lightness is inverted and the hues are turned back, so the
/// cream paper becomes near-black, dark ink becomes light, and each accent
/// colour keeps its hue as a darker shade.
const List<double> _kDarkMatrix = <double>[
  0.574, -1.430, -0.144, 0, 255, //
  -0.426, -0.430, -0.144, 0, 255, //
  -0.426, -1.430, 0.856, 0, 255, //
  0, 0, 0, 1, 0, //
];

class MuscleMemoryApp extends StatelessWidget {
  const MuscleMemoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlannerState()..load()),
        ChangeNotifierProvider(create: (_) => LogState()..load()),
        ChangeNotifierProvider(create: (_) => FoodLogState()..load()),
        ChangeNotifierProvider(create: (_) => RestTimerState()..load()),
        ChangeNotifierProvider(create: (_) => SettingsState()..load()),
        ChangeNotifierProvider(create: (_) => ChatState()..load()),
        ChangeNotifierProvider(create: (_) => ReminderState()..load()),
      ],
      child: MaterialApp(
        title: 'Muscle Memory',
        debugShowCheckedModeBanner: false,
        theme: buildPixelTheme(),
        builder: (context, child) {
          final mode = context.watch<SettingsState>().themeMode;
          final phoneIsDark =
              MediaQuery.platformBrightnessOf(context) == Brightness.dark;
          final dark = mode == AppThemeMode.dark ||
              (mode == AppThemeMode.system && phoneIsDark);
          final content = child ?? const SizedBox.shrink();
          if (!dark) return content;
          return ColorFiltered(
            colorFilter: const ColorFilter.matrix(_kDarkMatrix),
            child: content,
          );
        },
        home: const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back to the app on a new Monday starts a fresh, unticked week.
    if (state == AppLifecycleState.resumed) {
      context.read<PlannerState>().refreshWeek();
    }
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.select<PlannerState, bool>((s) => s.loaded);
    final log = context.select<LogState, bool>((s) => s.loaded);
    final food = context.select<FoodLogState, bool>((s) => s.loaded);
    final settings = context.select<SettingsState, bool>((s) => s.loaded);
    final chat = context.select<ChatState, bool>((s) => s.loaded);

    if (!(planner && log && food && settings && chat)) {
      return Scaffold(
        body: Center(child: Text('LOADING...', style: PX.title(14))),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [
          ScheduleScreen(),
          MusclesScreen(),
          FoodsScreen(),
          ChatScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Shows only while the rest timer is running or has just finished.
          const RestTimerBar(),
          PixelNavBar(
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
        ],
      ),
    );
  }
}
