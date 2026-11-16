# Muscle Memory (Flutter)

A pixel-style gym app for your phone. Everything is saved on the phone.

## What it does

Four tabs along the bottom: **WEEK, MUSCLE, FOOD, COACH**.

### WEEK
- **Mon to Sun boxes.** Green = everything planned that day is ticked. Red = the day has passed and something was not ticked. White = still to do (or a rest day with nothing planned). The orange bar marks today.
- **Mix the focus.** Tap the focus card and pick more than one group (Chest, Back, Legs, Shoulders, Arms, Core, or Rest). Pick Core then Chest and the day is named "Core and Chest Day".
- **Add exercise** opens a list filtered to that day's focus. Every exercise has a HOME or GYM tag (HOME means you own the gear for it). Tick as many as you like and add them all at once, or use Custom for your own.
- **Run.** Press Run to plan a distance for the day (for example 10 km on Monday). Leave a day empty if you are not running. Tick the run when done.
- **Log your sets.** Tap an exercise to log weight and reps per set. It shows last time and your heaviest weight, and flags a new PR. Ticking a set starts the rest timer.
- **Every Monday** all ticks clear by themselves and your plan stays, so the loop continues.
- The gear icon (top right) opens **Settings**.

### MUSCLE
Upper, mid and lower chest, lats, upper and lower back, shoulders, arms, forearms, quads, hamstrings, glutes, calves, abs and obliques, with plenty of dumbbell, pull-up bar and bodyweight options. "Home only" hides what your equipment cannot do.

### FOOD
- **Dictionary** of everyday Filipino foods with calories, protein, carbs and fat. Tap the + to log one.
- **My day** shows what you ate against your calorie and protein goals.

### COACH
A chat that answers fitness questions: exercise form, workouts, running, food. It knows your equipment and your week. It needs internet and an API key (see below).

### Settings
Light, dark or system appearance; the equipment you own; rest timer length; reset ticks; **Reminders**; coach key.

## Coach key (for the COACH tab)
1. Create an API key at console.anthropic.com (billed per use, separate from a Claude.ai plan).
2. In the app: WEEK, gear icon, Coach, paste the key, Save.

The key is stored only on your phone. Do not publish the app with a personal key inside it.

## Reminders and alarm
Settings, Reminders. Add as many daily reminders as you like (for example 12:00 PM every day), choose the days, and pick a song from your phone as the ringtone. It rings through the phone's real alarm clock, loops until you press STOP (or the time you chose runs out), and survives restarts.

Use **Test alarm in 10 seconds** to check it. On an Honor phone also set: Settings > Apps > App launch > Muscle Memory > turn off "Manage automatically", then turn on Auto-launch, Secondary launch and Run in background. The "Make it reliable" box in the app shows what is still missing.

## Setup
```
cd "Muscle Memory"
flutter pub get
flutter analyze
flutter test
flutter run
```
Use a phone with USB debugging on, or an emulator. In VS Code press F5. After editing, Ctrl+S hot-reloads.

Weights are in kg. For pounds, change `kWeightUnit` in `lib/models/log_models.dart`.

## File structure
```
Muscle Memory/
  pubspec.yaml               package name: muscle_memory
  android/                   Android project (app name: Muscle Memory)
  lib/
    main.dart                app start, dark mode, 4-tab navigation
    models/
      models.dart            days, exercises, focus groups, equipment, foods
      log_models.dart        sets, food entries, date helpers, kg/lb setting
    data/
      muscle_data.dart       muscles and exercises with gear needed (edit freely)
      food_data.dart         foods and nutrients (edit freely)
    state/
      planner_state.dart     the week, run, red/green days, Monday reset
      log_state.dart         workout history and PRs
      food_log_state.dart    food log and daily goals
      rest_timer_state.dart  rest countdown
      settings_state.dart    theme, equipment, coach key
      reminder_state.dart    reminders, ringtone, next-ring maths
      chat_state.dart        the coach conversation
    services/
      coach_api.dart         talks to the AI coach
      alarm_channel.dart     talks to the Android alarm code
    screens/
      schedule_screen.dart   WEEK tab
      muscles_screen.dart    MUSCLE tab
      foods_screen.dart      FOOD tab (dictionary)
      food_log_view.dart     FOOD tab (my day)
      chat_screen.dart       COACH tab
      settings_screen.dart   Settings
      reminders_screen.dart  alarms and ringtone
    widgets/
      pixel_widgets.dart     cards, buttons, chips, dialogs, nav bar
      exercise_picker.dart   filtered multi-select exercise list
      exercise_dialog.dart   add/edit one exercise, add-to-day sheet
      gear_tags.dart         HOME / GYM tags
      workout_log_sheet.dart set-by-set logging
      rest_timer_bar.dart    rest countdown bar
      food_sheets.dart       log a food, daily goals
    theme/pixel_theme.dart   colors and fonts
  android/app/src/main/kotlin/com/example/gym/
    MainActivity.kt          music picker and permissions
    AlarmScheduler.kt        sets the phone alarms
    AlarmReceiver.kt         runs when an alarm time arrives
    AlarmService.kt          plays the song, STOP button
    BootReceiver.kt          sets alarms again after a restart
  test/widget_test.dart      automated tests (flutter test)
```
