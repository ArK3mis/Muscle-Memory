import '../models/models.dart';

const List<String> kRegions = ['Upper', 'Lower', 'Core'];

// Short names for the gear sets used below.
const Set<Equip> _bw = {Equip.bodyweight};
const Set<Equip> _db = {Equip.dumbbell};
const Set<Equip> _dbBench = {Equip.dumbbell, Equip.bench};
const Set<Equip> _pullBar = {Equip.pullupBar};
const Set<Equip> _pushBars = {Equip.pushupBars};
const Set<Equip> _bench = {Equip.bench};
const Set<Equip> _barbell = {Equip.barbell};
const Set<Equip> _barbellBench = {Equip.barbell, Equip.bench};
const Set<Equip> _cable = {Equip.cable};
const Set<Equip> _machine = {Equip.machine};
const Set<Equip> _dips = {Equip.dipBars};

/// Edit this list to add your own muscles or exercises.
///
/// ExerciseInfo(name, gear needed, rx: suggested sets x reps)
/// An exercise shows as HOME when you own all the gear it needs
/// (set that in Settings), otherwise as GYM.
const List<MuscleGroup> kMuscles = [
  // ======================= CHEST =======================
  MuscleGroup(
    name: 'Upper Chest',
    region: 'Upper',
    group: 'Chest',
    exercises: [
      ExerciseInfo('Decline Push-ups (feet elevated)', _bw),
      ExerciseInfo('Incline Dumbbell Press', _dbBench),
      ExerciseInfo('Incline Dumbbell Fly', _dbBench),
      ExerciseInfo('Incline Barbell Press', _barbellBench, rx: '4 x 8'),
      ExerciseInfo('Low-to-High Cable Fly', _cable, rx: '3 x 12'),
    ],
  ),
  MuscleGroup(
    name: 'Mid Chest',
    region: 'Upper',
    group: 'Chest',
    exercises: [
      ExerciseInfo('Push-ups', _bw, rx: '3 x 15'),
      ExerciseInfo('Push-up Bar Push-ups (deep)', _pushBars, rx: '3 x 12'),
      ExerciseInfo('Dumbbell Floor Press', _db),
      ExerciseInfo('Dumbbell Floor Fly', _db, rx: '3 x 12'),
      ExerciseInfo('Dumbbell Pullover', _db, rx: '3 x 12'),
      ExerciseInfo('Flat Dumbbell Press', _dbBench),
      ExerciseInfo('Flat Barbell Bench Press', _barbellBench, rx: '4 x 8'),
      ExerciseInfo('Machine Chest Press', _machine),
    ],
  ),
  MuscleGroup(
    name: 'Lower Chest',
    region: 'Upper',
    group: 'Chest',
    exercises: [
      ExerciseInfo('Incline Push-ups (hands elevated)', _bw, rx: '3 x 15'),
      ExerciseInfo('Chest Dips', _dips, rx: '3 x 10'),
      ExerciseInfo('Decline Barbell Press', _barbellBench, rx: '4 x 8'),
      ExerciseInfo('High-to-Low Cable Fly', _cable, rx: '3 x 12'),
    ],
  ),

  // ======================= BACK =======================
  MuscleGroup(
    name: 'Lats',
    region: 'Upper',
    group: 'Back',
    exercises: [
      ExerciseInfo('Pull-ups', _pullBar, rx: '4 x 6'),
      ExerciseInfo('Chin-ups', _pullBar, rx: '4 x 6'),
      ExerciseInfo('Wide-grip Pull-ups', _pullBar, rx: '3 x 5'),
      ExerciseInfo('Negative Pull-ups (slow lowering)', _pullBar, rx: '3 x 5'),
      ExerciseInfo('Single-arm Dumbbell Row', _db),
      ExerciseInfo('Dumbbell Pullover', _db, rx: '3 x 12'),
      ExerciseInfo('Lat Pulldown', _machine),
      ExerciseInfo('Straight-arm Pulldown', _cable, rx: '3 x 12'),
    ],
  ),
  MuscleGroup(
    name: 'Upper Back',
    region: 'Upper',
    group: 'Back',
    exercises: [
      ExerciseInfo('Bent-over Dumbbell Row', _db),
      ExerciseInfo('Renegade Row', _db, rx: '3 x 8'),
      ExerciseInfo('Dumbbell Shrugs', _db, rx: '3 x 15'),
      ExerciseInfo('Chest-supported Dumbbell Row', _dbBench),
      ExerciseInfo('Barbell Row', _barbell, rx: '4 x 8'),
      ExerciseInfo('Seated Cable Row', _cable),
      ExerciseInfo('Face Pulls', _cable, rx: '3 x 15'),
    ],
  ),
  MuscleGroup(
    name: 'Lower Back',
    region: 'Upper',
    group: 'Back',
    exercises: [
      ExerciseInfo('Superman Hold', _bw, rx: '3 x 30s'),
      ExerciseInfo('Bird Dog', _bw, rx: '3 x 12'),
      ExerciseInfo('Dumbbell Good Mornings', _db, rx: '3 x 12'),
      ExerciseInfo('Deadlift', _barbell, rx: '4 x 5'),
      ExerciseInfo('Back Extensions (Roman chair)', _machine, rx: '3 x 12'),
    ],
  ),

  // ======================= SHOULDERS =======================
  MuscleGroup(
    name: 'Front Shoulders',
    region: 'Upper',
    group: 'Shoulders',
    exercises: [
      ExerciseInfo('Dumbbell Shoulder Press', _db),
      ExerciseInfo('Arnold Press', _db),
      ExerciseInfo('Dumbbell Front Raise', _db, rx: '3 x 12'),
      ExerciseInfo('Pike Push-ups', _bw, rx: '3 x 10'),
      ExerciseInfo('Barbell Overhead Press', _barbell, rx: '4 x 8'),
    ],
  ),
  MuscleGroup(
    name: 'Side Shoulders',
    region: 'Upper',
    group: 'Shoulders',
    exercises: [
      ExerciseInfo('Dumbbell Lateral Raise', _db, rx: '3 x 15'),
      ExerciseInfo('Dumbbell Upright Row', _db, rx: '3 x 12'),
      ExerciseInfo('Cable Lateral Raise', _cable, rx: '3 x 15'),
    ],
  ),
  MuscleGroup(
    name: 'Rear Shoulders',
    region: 'Upper',
    group: 'Shoulders',
    exercises: [
      ExerciseInfo('Bent-over Dumbbell Rear Fly', _db, rx: '3 x 15'),
      ExerciseInfo('Reverse Pec Deck', _machine, rx: '3 x 15'),
      ExerciseInfo('Cable Face Pulls', _cable, rx: '3 x 15'),
    ],
  ),

  // ======================= ARMS =======================
  MuscleGroup(
    name: 'Biceps',
    region: 'Upper',
    group: 'Arms',
    exercises: [
      ExerciseInfo('Dumbbell Curl', _db),
      ExerciseInfo('Hammer Curl', _db),
      ExerciseInfo('Concentration Curl', _db),
      ExerciseInfo('Chin-ups', _pullBar, rx: '4 x 6'),
      ExerciseInfo('Incline Dumbbell Curl', _dbBench),
      ExerciseInfo('Barbell Curl', _barbell),
      ExerciseInfo('Preacher Curl', _machine),
    ],
  ),
  MuscleGroup(
    name: 'Triceps',
    region: 'Upper',
    group: 'Arms',
    exercises: [
      ExerciseInfo('Diamond Push-ups', _bw, rx: '3 x 10'),
      ExerciseInfo('Close-grip Push-ups', _bw, rx: '3 x 12'),
      ExerciseInfo('Overhead Dumbbell Tricep Extension', _db),
      ExerciseInfo('Dumbbell Skull Crushers (on the floor)', _db),
      ExerciseInfo('Dumbbell Tricep Kickback', _db, rx: '3 x 12'),
      ExerciseInfo('Bench Dips (chair works)', _bench, rx: '3 x 12'),
      ExerciseInfo('Tricep Pushdown', _cable),
      ExerciseInfo('Close-grip Bench Press', _barbellBench, rx: '4 x 8'),
    ],
  ),
  MuscleGroup(
    name: 'Forearms',
    region: 'Upper',
    group: 'Arms',
    exercises: [
      ExerciseInfo('Dumbbell Wrist Curls', _db, rx: '3 x 15'),
      ExerciseInfo('Dumbbell Reverse Curls', _db),
      ExerciseInfo("Farmer's Carry (dumbbells)", _db, rx: '3 x 30s'),
      ExerciseInfo('Dead Hang', _pullBar, rx: '3 x 30s'),
    ],
  ),

  // ======================= LEGS =======================
  MuscleGroup(
    name: 'Quads',
    region: 'Lower',
    group: 'Legs',
    exercises: [
      ExerciseInfo('Bodyweight Squats', _bw, rx: '3 x 20'),
      ExerciseInfo('Goblet Squat', _db, rx: '4 x 10'),
      ExerciseInfo('Dumbbell Walking Lunges', _db, rx: '3 x 12'),
      ExerciseInfo('Dumbbell Reverse Lunges', _db, rx: '3 x 10'),
      ExerciseInfo('Jump Squats', _bw, rx: '3 x 12'),
      ExerciseInfo('Wall Sit', _bw, rx: '3 x 40s'),
      ExerciseInfo('Bulgarian Split Squat', _dbBench, rx: '3 x 10'),
      ExerciseInfo('Dumbbell Step-ups', _dbBench, rx: '3 x 10'),
      ExerciseInfo('Barbell Squat', _barbell, rx: '4 x 8'),
      ExerciseInfo('Leg Press', _machine),
      ExerciseInfo('Leg Extension', _machine, rx: '3 x 12'),
    ],
  ),
  MuscleGroup(
    name: 'Hamstrings',
    region: 'Lower',
    group: 'Legs',
    exercises: [
      ExerciseInfo('Dumbbell Romanian Deadlift', _db, rx: '4 x 10'),
      ExerciseInfo('Single-leg Dumbbell RDL', _db, rx: '3 x 8'),
      ExerciseInfo('Towel Sliding Leg Curl', _bw, rx: '3 x 10'),
      ExerciseInfo('Barbell Romanian Deadlift', _barbell, rx: '4 x 8'),
      ExerciseInfo('Lying Leg Curl', _machine, rx: '3 x 12'),
    ],
  ),
  MuscleGroup(
    name: 'Glutes',
    region: 'Lower',
    group: 'Legs',
    exercises: [
      ExerciseInfo('Glute Bridge', _bw, rx: '3 x 15'),
      ExerciseInfo('Single-leg Glute Bridge', _bw, rx: '3 x 12'),
      ExerciseInfo('Dumbbell Glute Bridge', _db, rx: '4 x 12'),
      ExerciseInfo('Dumbbell Sumo Squat', _db, rx: '3 x 12'),
      ExerciseInfo('Donkey Kicks', _bw, rx: '3 x 15'),
      ExerciseInfo('Dumbbell Hip Thrust (bench)', _dbBench, rx: '4 x 10'),
      ExerciseInfo('Barbell Hip Thrust', _barbellBench, rx: '4 x 8'),
      ExerciseInfo('Cable Kickback', _cable, rx: '3 x 12'),
    ],
  ),
  MuscleGroup(
    name: 'Calves',
    region: 'Lower',
    group: 'Legs',
    exercises: [
      ExerciseInfo('Single-leg Calf Raise', _bw, rx: '3 x 15'),
      ExerciseInfo('Dumbbell Calf Raise', _db, rx: '4 x 15'),
      ExerciseInfo('Standing Calf Raise Machine', _machine, rx: '4 x 12'),
      ExerciseInfo('Seated Calf Raise Machine', _machine, rx: '4 x 12'),
    ],
  ),

  // ======================= CORE =======================
  MuscleGroup(
    name: 'Abs',
    region: 'Core',
    group: 'Core',
    exercises: [
      ExerciseInfo('Plank', _bw, rx: '3 x 40s'),
      ExerciseInfo('Crunches', _bw, rx: '3 x 20'),
      ExerciseInfo('Lying Leg Raises', _bw, rx: '3 x 12'),
      ExerciseInfo('Bicycle Crunches', _bw, rx: '3 x 20'),
      ExerciseInfo('Mountain Climbers', _bw, rx: '3 x 30s'),
      ExerciseInfo('V-ups', _bw, rx: '3 x 12'),
      ExerciseInfo('Dead Bug', _bw, rx: '3 x 12'),
      ExerciseInfo('Hanging Knee Raise', _pullBar, rx: '3 x 12'),
      ExerciseInfo('Hanging Leg Raise', _pullBar, rx: '3 x 10'),
      ExerciseInfo('Weighted Crunch (dumbbell)', _db, rx: '3 x 15'),
      ExerciseInfo('Cable Crunch', _cable, rx: '3 x 15'),
    ],
  ),
  MuscleGroup(
    name: 'Obliques',
    region: 'Core',
    group: 'Core',
    exercises: [
      ExerciseInfo('Side Plank', _bw, rx: '3 x 30s'),
      ExerciseInfo('Russian Twist (dumbbell)', _db, rx: '3 x 20'),
      ExerciseInfo('Dumbbell Side Bend', _db, rx: '3 x 15'),
      ExerciseInfo('Hanging Oblique Knee Raise', _pullBar, rx: '3 x 10'),
      ExerciseInfo('Cable Woodchopper', _cable, rx: '3 x 12'),
    ],
  ),
];

/// Group for a muscle name ("Lats" -> "Back"), or '' if unknown.
String groupForMuscle(String muscleName) {
  for (final m in kMuscles) {
    if (m.name == muscleName) return m.group;
  }
  return '';
}

/// Looks an exercise up by name (not case sensitive). Null for custom ones.
ExerciseInfo? findExerciseInfo(String name) {
  final key = name.trim().toLowerCase();
  if (key.isEmpty) return null;
  for (final m in kMuscles) {
    for (final e in m.exercises) {
      if (e.name.toLowerCase() == key) return e;
    }
  }
  return null;
}
