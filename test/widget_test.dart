import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:muscle_memory/data/food_data.dart';
import 'package:muscle_memory/data/muscle_data.dart';
import 'package:muscle_memory/models/log_models.dart';
import 'package:muscle_memory/models/models.dart';
import 'package:muscle_memory/services/coach_api.dart';
import 'package:muscle_memory/state/chat_state.dart';
import 'package:muscle_memory/state/food_log_state.dart';
import 'package:muscle_memory/state/log_state.dart';
import 'package:muscle_memory/state/planner_state.dart';
import 'package:muscle_memory/state/reminder_state.dart';
import 'package:muscle_memory/state/rest_timer_state.dart';
import 'package:muscle_memory/state/settings_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Focus names', () {
    test('one, two and three groups', () {
      expect(focusTitle([]), '');
      expect(focusTitle(['Chest']), 'Chest Day');
      expect(focusTitle(['Core', 'Chest']), 'Core and Chest Day');
      expect(focusTitle(['Chest', 'Back', 'Legs']), 'Chest, Back and Legs Day');
      expect(focusTitle([kRestFocus]), 'Rest Day');
    });
  });

  group('PlannerState', () {
    test('first exercise on an empty day suggests the focus group', () async {
      final planner = PlannerState(persist: false);
      await planner.load();

      planner.addExercise(
        0,
        Exercise(name: 'Pull-ups', muscle: 'Lats'),
        suggestedGroup: 'Back',
      );
      planner.addExercise(
        0,
        Exercise(name: 'Curls', muscle: 'Biceps'),
        suggestedGroup: 'Arms',
      );

      expect(planner.days[0].focuses, ['Back']); // not mixed in automatically
      expect(planner.days[0].title, 'Back Day');
      expect(planner.days[0].exercises.length, 2);
    });

    test('mixed focus and adding several exercises at once', () async {
      final planner = PlannerState(persist: false);
      await planner.load();

      planner.setFocuses(1, ['Core', 'Chest']);
      expect(planner.days[1].title, 'Core and Chest Day');

      planner.addExercises(
        1,
        [Exercise(name: 'Plank'), Exercise(name: 'Push-ups')],
        groups: ['Arms'], // ignored: the day already has a focus
      );
      expect(planner.days[1].exercises.length, 2);
      expect(planner.days[1].focuses, ['Core', 'Chest']);

      planner.addExercises(
        2,
        [Exercise(name: 'Squat')],
        groups: ['Legs', 'Legs', 'Core'],
      );
      expect(planner.days[2].focuses, ['Legs', 'Core']);
    });

    test('schedule, focus and run are saved and loaded again', () async {
      final first = PlannerState();
      await first.load();
      first.setFocuses(2, ['Legs']);
      first.addExercise(2, Exercise(name: 'Goblet Squat', details: '4 x 10'));
      first.setRun(0, 10);
      await first.flush();

      final second = PlannerState();
      await second.load();

      expect(second.days[2].title, 'Legs Day');
      expect(second.days[2].exercises.single.name, 'Goblet Squat');
      expect(second.days[0].runKm, 10);
      expect(second.days[0].hasRun, isTrue);
    });

    test('remove, undo, reorder and tick', () async {
      final planner = PlannerState(persist: false);
      await planner.load();
      final a = Exercise(name: 'A');
      final b = Exercise(name: 'B');
      final c = Exercise(name: 'C');
      for (final e in [a, b, c]) {
        planner.addExercise(1, e);
      }

      final removed = planner.removeExercise(1, b.id)!;
      expect(planner.days[1].exercises.map((e) => e.name), ['A', 'C']);

      planner.insertExercise(1, 1, removed);
      expect(planner.days[1].exercises.map((e) => e.name), ['A', 'B', 'C']);

      planner.moveExercise(1, 0, 2);
      expect(planner.days[1].exercises.map((e) => e.name), ['B', 'C', 'A']);

      planner.toggleDone(1, a.id);
      expect(planner.days[1].doneCount, 1);
      planner.resetTicks();
      expect(planner.days[1].doneCount, 0);
    });

    test('running counts as part of the day', () async {
      final planner = PlannerState(persist: false);
      await planner.load();

      planner.setRun(0, 10);
      expect(planner.days[0].plannedCount, 1);
      expect(planner.days[0].isComplete, isFalse);

      planner.toggleRunDone(0);
      expect(planner.days[0].isComplete, isTrue);

      planner.setRun(0, 0); // remove the run
      expect(planner.days[0].hasRun, isFalse);
      expect(planner.days[0].runDone, isFalse);
      expect(planner.days[0].hasPlan, isFalse);

      // A rest day: nothing to toggle.
      planner.toggleRunDone(1);
      expect(planner.days[1].runDone, isFalse);
    });

    test('clearDay wipes focus, exercises and run', () async {
      final planner = PlannerState(persist: false);
      await planner.load();
      planner.setFocuses(4, ['Chest']);
      planner.addExercise(4, Exercise(name: 'Bench'));
      planner.setRun(4, 5);
      planner.clearDay(4);
      expect(planner.days[4].title, '');
      expect(planner.days[4].exercises, isEmpty);
      expect(planner.days[4].hasRun, isFalse);
    });

    test('day colours: done, missed, pending and rest', () async {
      final planner = PlannerState(persist: false);
      await planner.load();
      final wednesday = DateTime(2026, 11, 11); // index 2

      planner.addExercise(0, Exercise(name: 'A')); // Monday, not ticked
      final tuesday = Exercise(name: 'B');
      planner.addExercise(1, tuesday); // Tuesday, will be ticked
      planner.toggleDone(1, tuesday.id);
      planner.addExercise(2, Exercise(name: 'C')); // today, not ticked
      planner.setRun(4, 5); // Friday, future

      expect(planner.statusOf(0, now: wednesday), DayStatus.missed);
      expect(planner.statusOf(1, now: wednesday), DayStatus.done);
      expect(planner.statusOf(2, now: wednesday), DayStatus.pending);
      expect(planner.statusOf(3, now: wednesday), DayStatus.empty);
      expect(planner.statusOf(4, now: wednesday), DayStatus.pending);
    });

    test('a new week unticks everything but keeps the plan', () async {
      final planner = PlannerState(persist: false);
      await planner.load();

      planner.setFocuses(0, ['Back']);
      final e = Exercise(name: 'Pull-ups');
      planner.addExercise(0, e);
      planner.toggleDone(0, e.id);
      planner.setRun(1, 5);
      planner.toggleRunDone(1);

      // Pretend the ticks belong to an earlier week.
      planner.weekStart = '2026-11-02';

      // Same week as the saved one: nothing happens.
      expect(planner.refreshWeek(now: DateTime(2026, 11, 4)), isFalse);
      expect(planner.days[0].doneCount, 1);

      // Next Wednesday (Monday is 2026-11-09): new week.
      expect(planner.refreshWeek(now: DateTime(2026, 11, 11)), isTrue);
      expect(planner.weekStart, '2026-11-09');
      expect(planner.days[0].doneCount, 0);
      expect(planner.days[0].exercises.length, 1);
      expect(planner.days[0].focuses, ['Back']);
      expect(planner.days[1].runKm, 5);
      expect(planner.days[1].runDone, isFalse);

      // Asking again in the same week does nothing.
      expect(planner.refreshWeek(now: DateTime(2026, 11, 12)), isFalse);
    });

    test('schedules saved by the first version still load', () async {
      final old = jsonEncode({
        'days': [
          {
            'focus': 'Back Day',
            'exercises': [
              {
                'id': 'x1',
                'name': 'Pull-ups',
                'muscle': 'Lats',
                'details': '3 x 10',
                'done': true,
              },
            ],
          },
          {'focus': 'Cardio', 'exercises': []},
          {'focus': 'Leg Day', 'exercises': []},
        ],
      });
      SharedPreferences.setMockInitialValues({'gym_planner_v1': old});

      final planner = PlannerState();
      await planner.load();

      expect(planner.days[0].focuses, ['Back']);
      expect(planner.days[0].title, 'Back Day');
      expect(planner.days[0].exercises.single.name, 'Pull-ups');
      // No week was saved, so the ticks are kept for this week.
      expect(planner.days[0].exercises.single.done, isTrue);
      expect(planner.days[1].focuses, isEmpty);
      expect(planner.days[1].title, 'Cardio'); // kept as a custom label
      expect(planner.days[2].focuses, ['Legs']);
    });
  });

  group('Equipment and exercises', () {
    test('home or gym depends on the gear you own', () {
      final curl = findExerciseInfo('Dumbbell Curl')!;
      final pullups = findExerciseInfo('pull-ups')!; // not case sensitive
      final pulldown = findExerciseInfo('Lat Pulldown')!;
      final inclineDb = findExerciseInfo('Incline Dumbbell Press')!;

      expect(curl.doableWith(kDefaultGear), isTrue);
      expect(pullups.doableWith(kDefaultGear), isTrue);
      expect(pulldown.doableWith(kDefaultGear), isFalse);
      expect(inclineDb.doableWith(kDefaultGear), isFalse); // needs a bench

      final withBench = {...kDefaultGear, Equip.bench};
      expect(inclineDb.doableWith(withBench), isTrue);

      expect(curl.gearText, 'Dumbbell');
      expect(inclineDb.gearText, 'Dumbbell + Bench');
      expect(findExerciseInfo('Plank')!.gearText, 'Bodyweight');
      expect(findExerciseInfo('Nope'), isNull);
    });

    test('every muscle has something you can do with dumbbells and a bar', () {
      for (final m in kMuscles) {
        final home = m.exercises.where((e) => e.doableWith(kDefaultGear));
        expect(home, isNotEmpty, reason: '${m.name} has no home exercise');
      }
    });

    test('muscle data is consistent', () {
      final names = <String>{};
      for (final m in kMuscles) {
        expect(kRegions, contains(m.region), reason: m.name);
        expect(kFocusGroups, contains(m.group), reason: m.name);
        expect(m.exercises, isNotEmpty, reason: m.name);
        expect(names.add(m.name), isTrue, reason: 'duplicate ${m.name}');
        final inMuscle = <String>{};
        for (final e in m.exercises) {
          expect(inMuscle.add(e.name), isTrue, reason: 'duplicate ${e.name}');
          expect(e.gear, isNotEmpty, reason: e.name);
          expect(e.rx, isNotEmpty, reason: e.name);
        }
      }
      expect(groupForMuscle('Lats'), 'Back');
      expect(groupForMuscle('Abs'), 'Core');
      expect(groupForMuscle('Nope'), '');
      // Every focus group has at least one muscle.
      for (final g in kFocusGroups) {
        expect(kMuscles.any((m) => m.group == g), isTrue, reason: g);
      }
    });
  });

  group('SettingsState', () {
    test('gear, theme and coach key are saved', () async {
      final first = SettingsState();
      await first.load();
      expect(first.gear, unorderedEquals(kDefaultGear));
      expect(first.themeMode, AppThemeMode.system);

      first.toggleGear(Equip.bench);
      first.toggleGear(Equip.dumbbell); // switch off
      first.toggleGear(Equip.bodyweight); // always on, ignored
      first.setThemeMode(AppThemeMode.dark);
      first.setApiKey('  sk-test  ');
      first.setModel('   ');
      first.setHomeOnly(false);
      await first.flush();

      expect(first.model, kDefaultCoachModel);

      final second = SettingsState();
      await second.load();
      expect(second.gear.contains(Equip.bench), isTrue);
      expect(second.gear.contains(Equip.dumbbell), isFalse);
      expect(second.gear.contains(Equip.bodyweight), isTrue);
      expect(second.themeMode, AppThemeMode.dark);
      expect(second.apiKey, 'sk-test');
      expect(second.homeOnly, isFalse);
    });
  });

  group('Coach chat', () {
    test('messages are merged and start with the user', () {
      final msgs = buildApiMessages(const [
        ChatTurn('assistant', 'old reply'),
        ChatTurn('user', 'How do I plank?'),
        ChatTurn('user', 'And how long?'),
        ChatTurn('assistant', '  '),
        ChatTurn('assistant', 'Hold 30 seconds.'),
        ChatTurn('user', 'Thanks'),
      ]);
      expect(msgs.map((m) => m['role']), ['user', 'assistant', 'user']);
      expect(msgs.first['content'], 'How do I plank?\n\nAnd how long?');
    });

    test('the instructions mention your gear and plan', () async {
      final planner = PlannerState(persist: false);
      await planner.load();
      planner.setFocuses(0, ['Chest', 'Core']);
      planner.addExercise(0, Exercise(name: 'Push-ups'));
      planner.setRun(1, 10);

      final prompt = buildCoachSystemPrompt(
        gear: kDefaultGear,
        days: planner.days,
      );
      expect(prompt, contains('Dumbbell'));
      expect(prompt, contains('Pull-up bar'));
      expect(prompt, contains('Chest and Core Day'));
      expect(prompt, contains('Push-ups'));
      expect(prompt, contains('run 10 km'));
      expect(prompt, contains('Tuesday'));
    });

    test('a reply is added, an error is kept and retry works', () async {
      final chat = ChatState(persist: false);
      await chat.load();

      var calls = 0;
      Future<String> flaky(List<ChatTurn> turns) async {
        calls++;
        if (calls == 1) throw CoachException('No internet');
        return 'Hold it for 30 seconds.';
      }

      await chat.send('  How long should I plank?  ', ask: flaky);
      expect(chat.error, 'No internet');
      expect(chat.messages.length, 1);
      expect(chat.messages.single.text, 'How long should I plank?');
      expect(chat.sending, isFalse);

      await chat.retry(ask: flaky);
      expect(chat.error, isNull);
      expect(chat.messages.length, 2);
      expect(chat.messages.last.isUser, isFalse);
      expect(chat.messages.last.text, 'Hold it for 30 seconds.');

      chat.clear();
      expect(chat.messages, isEmpty);
    });

    test('the conversation is saved', () async {
      final first = ChatState();
      await first.load();
      await first.send('Hi', ask: (turns) async => 'Hello!');
      await first.flush();

      final second = ChatState();
      await second.load();
      expect(second.messages.map((m) => m.text), ['Hi', 'Hello!']);
    });

    test('asking without a key is refused', () async {
      await expectLater(
        askCoach(
          apiKey: '  ',
          model: kDefaultCoachModel,
          system: 'x',
          turns: const [ChatTurn('user', 'hi')],
        ),
        throwsA(isA<CoachException>()),
      );
    });
  });

  group('LogState', () {
    test('remembers last session and heaviest weight', () async {
      final log = LogState(persist: false);
      await log.load();

      log.saveSets('Bench Press', '2026-11-03',
          [SetEntry(weight: 40, reps: 10, done: true)]);
      log.saveSets('bench press ', '2026-11-08', [
        SetEntry(weight: 45, reps: 8, done: true),
        SetEntry(weight: 42.5, reps: 8, done: true),
      ]);

      // Names match regardless of capital letters and spaces.
      expect(log.entryOn('BENCH PRESS', '2026-11-08')!.sets.length, 2);
      expect(log.lastBefore('Bench Press', '2026-11-08')!.date, '2026-11-03');
      expect(log.lastBefore('Bench Press', '2026-11-03'), isNull);
      expect(log.bestWeightEver('Bench Press'), 45);
      expect(log.bestWeightEver('Squat'), isNull);
    });

    test('personal records', () async {
      final log = LogState(persist: false);
      await log.load();

      // First time ever is never a PR.
      expect(log.isPr('Squat', '2026-11-01', SetEntry(weight: 60, reps: 5)),
          isFalse);

      log.saveSets('Squat', '2026-11-01',
          [SetEntry(weight: 60, reps: 5, done: true)]);

      expect(log.isPr('Squat', '2026-11-08', SetEntry(weight: 62.5, reps: 5)),
          isTrue);
      expect(log.isPr('Squat', '2026-11-08', SetEntry(weight: 60, reps: 5)),
          isFalse);
      // Sets with no reps are never PRs.
      expect(log.isPr('Squat', '2026-11-08', SetEntry(weight: 100, reps: 0)),
          isFalse);

      // Bodyweight exercises compare reps.
      log.saveSets('Pull-ups', '2026-11-01', [SetEntry(reps: 8, done: true)]);
      expect(log.isPr('Pull-ups', '2026-11-08', SetEntry(reps: 9)), isTrue);
      expect(log.isPr('Pull-ups', '2026-11-08', SetEntry(reps: 8)), isFalse);
    });

    test('saving no sets removes the entry, and history is stored', () async {
      final first = LogState();
      await first.load();
      first.saveSets('Deadlift', '2026-11-05',
          [SetEntry(weight: 100, reps: 5, done: true)]);
      await first.flush();

      final second = LogState();
      await second.load();
      expect(second.entryOn('Deadlift', '2026-11-05')!.sets.single.weight, 100);

      second.saveSets('Deadlift', '2026-11-05', []);
      expect(second.entryOn('Deadlift', '2026-11-05'), isNull);
      expect(second.bestWeightEver('Deadlift'), isNull);
    });
  });

  group('FoodLogState', () {
    test('totals, servings, undo and saved goals', () async {
      final eggs = kFoods.firstWhere((f) => f.name == 'Itlog, nilaga');
      final rice = kFoods.firstWhere((f) => f.name == 'Kanin (white rice)');

      final log = FoodLogState();
      await log.load();
      expect(log.kcalGoal, 2000);

      log.addFood('2026-11-08', FoodEntry.fromFood(eggs, 2));
      log.addFood('2026-11-08', FoodEntry.fromFood(rice, 1.5));

      final t = log.totalsOn('2026-11-08');
      expect(t.kcal, closeTo(eggs.kcal * 2 + rice.kcal * 1.5, 0.001));
      expect(t.protein, closeTo(eggs.protein * 2 + rice.protein * 1.5, 0.001));
      expect(log.totalsOn('2026-11-09').kcal, 0);

      final id = log.entriesOn('2026-11-08').first.id;
      final removed = log.removeEntry('2026-11-08', id)!;
      expect(log.entriesOn('2026-11-08').length, 1);
      log.insertEntry('2026-11-08', 0, removed);
      expect(log.entriesOn('2026-11-08').first.name, 'Itlog, nilaga');

      log.setGoals(2400, 140);
      await log.flush();

      final again = FoodLogState();
      await again.load();
      expect(again.kcalGoal, 2400);
      expect(again.proteinGoal, 140);
      expect(again.entriesOn('2026-11-08').length, 2);
    });
  });

  group('Helpers', () {
    test('date keys, week start and labels', () {
      expect(dateKey(DateTime(2026, 11, 8)), '2026-11-08');
      expect(parseDateKey('2026-11-08'), DateTime(2026, 11, 8));
      // 2026-11-09 is a Monday: the whole week maps to it.
      expect(weekStartKey(DateTime(2026, 11, 9)), '2026-11-09');
      expect(weekStartKey(DateTime(2026, 11, 15)), '2026-11-09');
      expect(weekStartKey(DateTime(2026, 11, 16)), '2026-11-16');
      expect(weekStartKey(DateTime(2026, 11, 1)), '2026-10-26'); // a Sunday
      expect(dateLabel(DateTime.now()), 'Today');
      expect(
        dateLabel(DateTime.now().subtract(const Duration(days: 1))),
        'Yesterday',
      );
      expect(fmtNum(40), '40');
      expect(fmtNum(42.5), '42.5');
    });
  });

  group('RestTimerState', () {
    test('start, add time and stop', () {
      final t = RestTimerState();
      expect(t.active, isFalse);

      t.start(60);
      expect(t.running, isTrue);
      expect(t.remaining, inInclusiveRange(59, 60));

      t.addSeconds(15);
      expect(t.remaining, inInclusiveRange(74, 75));

      t.stop();
      expect(t.active, isFalse);
      t.dispose();
    });
  });

  group('Food data', () {
    test('foods are sane', () {
      for (final f in kFoods) {
        expect(kFoodCategories, contains(f.category), reason: f.name);
        expect(f.kcal, greaterThan(0), reason: f.name);
        final fromMacros = f.protein * 4 + f.carbs * 4 + f.fat * 9;
        expect((fromMacros - f.kcal).abs(), lessThan(f.kcal * 0.25 + 10),
            reason: '${f.name}: macros do not match kcal');
      }
    });

    test('food search finds English and Filipino words', () {
      expect(searchFoods('itlog'), isNotEmpty);
      expect(searchFoods('noodles').any((f) => f.name.contains('Cup')), isTrue);
      expect(searchFoods('zzzz'), isEmpty);

      final byProtein = searchFoods('', proteinFirst: true);
      expect(byProtein.first.protein >= byProtein.last.protein, isTrue);

      final fruit = searchFoods('', category: 'Fruits & Veg');
      expect(fruit.every((f) => f.category == 'Fruits & Veg'), isTrue);
    });
  });

  group('Reminders', () {
    Reminder make({int hour = 12, int minute = 0, Set<int>? days, bool on = true}) =>
        Reminder(
          id: 'a',
          alarmId: 1,
          hour: hour,
          minute: minute,
          days: days ?? {1, 2, 3, 4, 5, 6, 7},
          enabled: on,
        );

    test('time text uses 12 hours', () {
      expect(formatTime12(12, 0), '12:00 PM');
      expect(formatTime12(0, 5), '12:05 AM');
      expect(formatTime12(15, 30), '3:30 PM');
    });

    test('days text', () {
      expect(make().daysText, 'Every day');
      expect(make(days: {1, 2, 3, 4, 5}).daysText, 'Weekdays');
      expect(make(days: {1, 3, 5}).daysText, 'MON, WED, FRI');
    });

    test('next ring is today if the time has not passed, else tomorrow', () {
      // 2026-11-16 is a Monday.
      final morning = DateTime(2026, 11, 16, 9, 0);
      final next = nextOccurrence(make(), morning)!;
      expect(next, DateTime(2026, 11, 16, 12, 0));

      final afternoon = DateTime(2026, 11, 16, 13, 0);
      expect(nextOccurrence(make(), afternoon), DateTime(2026, 11, 17, 12, 0));
    });

    test('next ring skips days that are not chosen', () {
      final mondayNoon = DateTime(2026, 11, 16, 12, 0);
      final r = make(days: {1}); // Mondays only
      expect(nextOccurrence(r, mondayNoon), DateTime(2026, 11, 23, 12, 0));
    });

    test('disabled or empty reminders never ring', () {
      final now = DateTime(2026, 11, 16, 9, 0);
      expect(nextOccurrence(make(on: false), now), isNull);
      expect(nextOccurrence(make(days: {}), now), isNull);
    });

    test('describeNext', () {
      final now = DateTime(2026, 11, 16, 9, 0);
      expect(describeNext(DateTime(2026, 11, 16, 12), now), 'Today 12:00 PM');
      expect(describeNext(DateTime(2026, 11, 17, 12), now), 'Tomorrow 12:00 PM');
      expect(describeNext(DateTime(2026, 11, 19, 12), now), 'THU 12:00 PM');
    });

    test('json round trip', () {
      final r = make(hour: 18, minute: 45, days: {2, 4});
      final back = Reminder.fromJson(
          jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>);
      expect(back.hour, 18);
      expect(back.minute, 45);
      expect(back.days, {2, 4});
    });

    test('state adds, edits, saves and reloads', () async {
      final rs = ReminderState();
      await rs.load();
      expect(rs.reminders.length, 1); // starter 12:00 PM reminder
      await rs.add(hour: 7, minute: 30, days: {1, 3, 5});
      expect(rs.reminders.length, 2);
      expect(rs.reminders.map((r) => r.alarmId).toSet().length, 2);
      await rs.setSound('/x/ringtone.mp3', 'song.mp3');
      await rs.setVibrate(false);

      final native = jsonDecode(rs.nativeConfig()) as Map<String, dynamic>;
      expect(native['sound'], '/x/ringtone.mp3');
      expect(native['vibrate'], false);
      expect((native['reminders'] as List).length, 2);

      final again = ReminderState();
      await again.load();
      expect(again.reminders.length, 2);
      expect(again.soundName, 'song.mp3');

      await again.remove(again.reminders.first.id);
      expect(again.reminders.length, 1);
    });
  });
}
