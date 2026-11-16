import 'models.dart';

/// Change this to 'lb' if your gym uses pounds. Numbers are not converted,
/// so pick one unit and stick with it.
const String kWeightUnit = 'kg';

const List<String> kMonthShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// 40 -> "40", 42.5 -> "42.5"
String fmtNum(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// "2026-11-08". Sorts correctly as plain text.
String dateKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Date key of the Monday of the week that contains [d]. Used to start a
/// fresh week (all ticks cleared) every Monday.
String weekStartKey(DateTime d) =>
    dateKey(DateTime(d.year, d.month, d.day - (d.weekday - 1)));

DateTime parseDateKey(String key) {
  final p = key.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// "Today", "Yesterday", "Tomorrow" or "Sat Nov 7".
String dateLabel(DateTime d) {
  final now = DateTime.now();
  final diff = DateTime.utc(d.year, d.month, d.day)
      .difference(DateTime.utc(now.year, now.month, now.day))
      .inDays;
  if (diff == 0) return 'Today';
  if (diff == -1) return 'Yesterday';
  if (diff == 1) return 'Tomorrow';
  final weekday = kDayNames[d.weekday - 1].substring(0, 3);
  return '$weekday ${kMonthShort[d.month - 1]} ${d.day}';
}

/// One logged set: weight (0 = bodyweight), reps, and whether it was ticked.
class SetEntry {
  SetEntry({this.weight = 0, this.reps = 0, this.done = false});

  double weight;
  int reps;
  bool done;

  String get label =>
      weight > 0 ? '${fmtNum(weight)} $kWeightUnit x $reps' : '$reps reps';

  Map<String, dynamic> toJson() => {'w': weight, 'r': reps, 'd': done};

  factory SetEntry.fromJson(Map<String, dynamic> json) => SetEntry(
        weight: (json['w'] as num?)?.toDouble() ?? 0,
        reps: (json['r'] as num?)?.toInt() ?? 0,
        done: (json['d'] as bool?) ?? false,
      );
}

/// All sets of one exercise on one day.
class LogEntry {
  LogEntry({required this.date, required this.sets});

  final String date; // dateKey
  final List<SetEntry> sets;

  Map<String, dynamic> toJson() => {
        'date': date,
        'sets': sets.map((s) => s.toJson()).toList(),
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        date: (json['date'] as String?) ?? '',
        sets: ((json['sets'] as List?) ?? const [])
            .map((s) => SetEntry.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList(),
      );
}

/// A food eaten. Nutrients are per serving and copied from the dictionary,
/// so changing the dictionary later does not rewrite your history.
class FoodEntry {
  FoodEntry({
    String? id,
    required this.name,
    required this.serving,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.servings = 1,
  }) : id = id ?? newId();

  factory FoodEntry.fromFood(Food f, double servings) => FoodEntry(
        name: f.name,
        serving: f.serving,
        kcal: f.kcal,
        protein: f.protein,
        carbs: f.carbs,
        fat: f.fat,
        servings: servings,
      );

  final String id;
  final String name;
  final String serving;
  final int kcal;
  final double protein;
  final double carbs;
  final double fat;
  final double servings;

  double get totalKcal => kcal * servings;
  double get totalProtein => protein * servings;
  double get totalCarbs => carbs * servings;
  double get totalFat => fat * servings;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'serving': serving,
        'kcal': kcal,
        'p': protein,
        'c': carbs,
        'f': fat,
        'n': servings,
      };

  factory FoodEntry.fromJson(Map<String, dynamic> json) => FoodEntry(
        id: json['id'] as String?,
        name: (json['name'] as String?) ?? '',
        serving: (json['serving'] as String?) ?? '',
        kcal: (json['kcal'] as num?)?.toInt() ?? 0,
        protein: (json['p'] as num?)?.toDouble() ?? 0,
        carbs: (json['c'] as num?)?.toDouble() ?? 0,
        fat: (json['f'] as num?)?.toDouble() ?? 0,
        servings: (json['n'] as num?)?.toDouble() ?? 1,
      );
}

class DayTotals {
  const DayTotals(this.kcal, this.protein, this.carbs, this.fat);

  final double kcal;
  final double protein;
  final double carbs;
  final double fat;
}
