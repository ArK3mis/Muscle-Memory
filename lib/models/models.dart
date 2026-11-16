const List<String> kDayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const List<String> kDayShort = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

int _idCounter = 0;

String newId() => '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

// ---------------------------------------------------------------------------
// Focus groups
// ---------------------------------------------------------------------------

/// Body-part groups you can mix on one day (Core + Chest, and so on).
const List<String> kFocusGroups = [
  'Chest',
  'Back',
  'Legs',
  'Shoulders',
  'Arms',
  'Core',
];

/// Special focus for a day off. It cannot be mixed with the groups above.
const String kRestFocus = 'Rest';

/// "Chest Day", "Core and Chest Day", "Chest, Back and Legs Day", "Rest Day".
String focusTitle(List<String> groups) {
  if (groups.isEmpty) return '';
  if (groups.length == 1) return '${groups.first} Day';
  final head = groups.sublist(0, groups.length - 1).join(', ');
  return '$head and ${groups.last} Day';
}

/// Turns the free-text focus used by older versions ("Back Day") into a group.
String? _legacyGroup(String label) {
  const map = {
    'chest day': 'Chest',
    'back day': 'Back',
    'leg day': 'Legs',
    'legs day': 'Legs',
    'shoulder day': 'Shoulders',
    'shoulders day': 'Shoulders',
    'arms day': 'Arms',
    'arm day': 'Arms',
    'core day': 'Core',
    'rest day': kRestFocus,
  };
  return map[label.trim().toLowerCase()];
}

// ---------------------------------------------------------------------------
// Schedule
// ---------------------------------------------------------------------------

/// One exercise inside a day of the weekly schedule.
class Exercise {
  Exercise({
    String? id,
    required this.name,
    this.muscle = '',
    this.details = '',
    this.done = false,
  }) : id = id ?? newId();

  final String id;
  String name;
  String muscle;
  String details; // e.g. "4 x 10" or "30 min"
  bool done;

  Exercise copyWith({String? name, String? muscle, String? details, bool? done}) {
    return Exercise(
      id: id,
      name: name ?? this.name,
      muscle: muscle ?? this.muscle,
      details: details ?? this.details,
      done: done ?? this.done,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'muscle': muscle,
        'details': details,
        'done': done,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String?,
        name: (json['name'] as String?) ?? '',
        muscle: (json['muscle'] as String?) ?? '',
        details: (json['details'] as String?) ?? '',
        done: (json['done'] as bool?) ?? false,
      );
}

/// One day of the week: its focus groups, exercises and an optional run.
class DayPlan {
  DayPlan({
    List<String>? focuses,
    this.customLabel = '',
    List<Exercise>? exercises,
    this.runKm = 0,
    this.runDone = false,
  })  : focuses = focuses ?? <String>[],
        exercises = exercises ?? <Exercise>[];

  /// Focus groups in the order they were picked, e.g. ['Core', 'Chest'].
  final List<String> focuses;

  /// Free-text label carried over from older versions that could not be mapped.
  String customLabel;

  final List<Exercise> exercises;

  /// Planned run distance in km. 0 means no run today.
  double runKm;
  bool runDone;

  /// "Core and Chest Day", or the old custom label, or '' when nothing is set.
  String get title =>
      focuses.isNotEmpty ? focusTitle(focuses) : customLabel.trim();

  bool get hasRun => runKm > 0;

  /// Exercises plus the run (if any).
  int get plannedCount => exercises.length + (hasRun ? 1 : 0);

  int get doneCount =>
      exercises.where((e) => e.done).length + (hasRun && runDone ? 1 : 0);

  bool get hasPlan => plannedCount > 0;

  bool get isComplete => hasPlan && doneCount == plannedCount;

  Map<String, dynamic> toJson() => {
        'focuses': focuses,
        'custom': customLabel,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'runKm': runKm,
        'runDone': runDone,
      };

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    final focuses = <String>[];
    var legacyCustom = '';

    final raw = json['focuses'];
    if (raw is List) {
      for (final f in raw) {
        if (f is String) focuses.add(f);
      }
    } else {
      // Saved by an older version: a single text label such as "Back Day".
      final old = ((json['focus'] as String?) ?? '').trim();
      if (old.isNotEmpty) {
        final group = _legacyGroup(old);
        if (group != null) {
          focuses.add(group);
        } else {
          legacyCustom = old;
        }
      }
    }

    return DayPlan(
      focuses: focuses,
      customLabel: (json['custom'] as String?) ?? legacyCustom,
      exercises: ((json['exercises'] as List?) ?? const [])
          .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      runKm: (json['runKm'] as num?)?.toDouble() ?? 0,
      runDone: (json['runDone'] as bool?) ?? false,
    );
  }
}

// ---------------------------------------------------------------------------
// Muscles, exercises and equipment
// ---------------------------------------------------------------------------

/// Gear an exercise can need.
enum Equip {
  bodyweight,
  dumbbell,
  pullupBar,
  pushupBars,
  bench,
  bands,
  barbell,
  cable,
  machine,
  dipBars,
}

const Map<Equip, String> kEquipLabel = {
  Equip.bodyweight: 'Bodyweight',
  Equip.dumbbell: 'Dumbbell',
  Equip.pullupBar: 'Pull-up bar',
  Equip.pushupBars: 'Push-up bars',
  Equip.bench: 'Bench',
  Equip.bands: 'Bands',
  Equip.barbell: 'Barbell',
  Equip.cable: 'Cable',
  Equip.machine: 'Machine',
  Equip.dipBars: 'Dip bars',
};

/// What the app assumes you own until you change it in Settings.
const Set<Equip> kDefaultGear = {
  Equip.bodyweight,
  Equip.dumbbell,
  Equip.pullupBar,
  Equip.pushupBars,
};

/// One suggested exercise and the gear it needs.
class ExerciseInfo {
  const ExerciseInfo(this.name, this.gear, {this.rx = '3 x 10'});

  final String name;
  final Set<Equip> gear;

  /// Suggested sets x reps (or time) used as the starting value.
  final String rx;

  /// True when [owned] covers everything this exercise needs.
  /// Bodyweight is always available.
  bool doableWith(Set<Equip> owned) =>
      gear.every((g) => g == Equip.bodyweight || owned.contains(g));

  /// "Dumbbell + Bench", or "Bodyweight" when nothing else is needed.
  String get gearText {
    final list = gear.where((g) => g != Equip.bodyweight).toList();
    if (list.isEmpty) return 'Bodyweight';
    return list.map((g) => kEquipLabel[g] ?? g.name).join(' + ');
  }
}

/// A trainable muscle with suggested exercises.
class MuscleGroup {
  const MuscleGroup({
    required this.name,
    required this.region,
    required this.group,
    required this.exercises,
  });

  final String name; // "Upper Chest"
  final String region; // Upper, Lower or Core
  final String group; // one of kFocusGroups, e.g. "Chest"
  final List<ExerciseInfo> exercises;
}

// ---------------------------------------------------------------------------
// Food
// ---------------------------------------------------------------------------

/// A food entry. Macros are per the listed serving.
class Food {
  const Food(
    this.name,
    this.alt,
    this.category,
    this.serving,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat, [
    this.note = '',
  ]);

  final String name;
  final String alt; // extra search words (English and Filipino)
  final String category;
  final String serving;
  final int kcal;
  final double protein;
  final double carbs;
  final double fat;
  final String note;

  /// Share of the listed calories that comes from protein (0 to 100).
  int get proteinPct {
    if (kcal <= 0) return 0;
    final pct = (protein * 4 / kcal * 100).round();
    return pct > 100 ? 100 : pct;
  }
}
