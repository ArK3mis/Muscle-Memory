import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/muscle_data.dart';
import '../models/models.dart';
import '../state/settings_state.dart';
import '../theme/pixel_theme.dart';
import 'exercise_dialog.dart';
import 'gear_tags.dart';
import 'pixel_widgets.dart';

/// One exercise the person ticked in the picker (or typed as a custom one).
class PickedExercise {
  const PickedExercise({
    required this.name,
    required this.muscle,
    required this.details,
    required this.group,
  });

  final String name;
  final String muscle;
  final String details;

  /// Focus group such as "Chest", or '' for a custom exercise.
  final String group;
}

/// Full-screen picker. Shows the muscles and exercises of the day's focus
/// groups and lets the person tick several to add at once.
/// Returns null if the person goes back without adding anything.
Future<List<PickedExercise>?> showExercisePicker(
  BuildContext context, {
  required String dayName,
  required List<String> focuses,
}) {
  return Navigator.of(context).push<List<PickedExercise>>(
    MaterialPageRoute(
      builder: (_) => ExercisePickerScreen(dayName: dayName, focuses: focuses),
    ),
  );
}

class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({
    super.key,
    required this.dayName,
    required this.focuses,
  });

  final String dayName;
  final List<String> focuses;

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  late final Set<String> _groups;

  // Ticked exercises, in the order they were ticked.
  final Map<String, PickedExercise> _picked = {};

  @override
  void initState() {
    super.initState();
    _groups = widget.focuses.where(kFocusGroups.contains).toSet();
  }

  String _key(MuscleGroup m, ExerciseInfo e) => '${m.name}|${e.name}';

  void _toggle(MuscleGroup m, ExerciseInfo e) {
    final key = _key(m, e);
    setState(() {
      if (_picked.containsKey(key)) {
        _picked.remove(key);
      } else {
        _picked[key] = PickedExercise(
          name: e.name,
          muscle: m.name,
          details: e.rx,
          group: m.group,
        );
      }
    });
  }

  Future<void> _addCustom() async {
    final created = await showExerciseDialog(context);
    if (created == null || !mounted) return;
    Navigator.pop(context, [
      ..._picked.values,
      PickedExercise(
        name: created.name,
        muscle: created.muscle,
        details: created.details,
        group: groupForMuscle(created.muscle),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final gear = settings.gear;
    final homeOnly = settings.homeOnly;

    final activeGroups = _groups.isEmpty ? kFocusGroups.toSet() : _groups;
    final muscles = <MuscleGroup>[];
    final visible = <MuscleGroup, List<ExerciseInfo>>{};
    for (final m in kMuscles) {
      if (!activeGroups.contains(m.group)) continue;
      final list = m.exercises
          .where((e) => !homeOnly || e.doableWith(gear))
          .toList();
      if (list.isEmpty) continue;
      muscles.add(m);
      visible[m] = list;
    }

    final count = _picked.length;

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
                  Expanded(
                    child: Text(
                      'ADD TO ${widget.dayName.toUpperCase()}',
                      style: PX.title(13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _groups.isEmpty
                    ? 'Showing every group. Tap a group to narrow it down.'
                    : 'Showing: ${_groups.join(', ')}',
                style: PX.body(14, color: PX.grey),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      PixelChip(
                        label: 'Home only',
                        selected: homeOnly,
                        color: PX.green,
                        onTap: () => settings.setHomeOnly(!homeOnly),
                      ),
                      const SizedBox(width: 10),
                      for (final g in kFocusGroups)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: PixelChip(
                            label: g,
                            selected: _groups.contains(g),
                            onTap: () => setState(() {
                              if (!_groups.remove(g)) _groups.add(g);
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: muscles.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Nothing matches your equipment here. '
                            'Turn off HOME ONLY or add gear in Settings.',
                            textAlign: TextAlign.center,
                            style: PX.body(15, color: PX.grey),
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(top: 4, bottom: 12),
                        children: [
                          for (final m in muscles) ...[
                            _sectionHeader(m),
                            for (final e in visible[m]!) _row(m, e, gear),
                          ],
                        ],
                      ),
              ),
              Row(
                children: [
                  PixelButton(
                    label: 'Custom',
                    icon: Icons.edit,
                    color: PX.white,
                    onPressed: _addCustom,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: PixelButton(
                      label: count == 0 ? 'Pick exercises' : 'Add $count',
                      icon: Icons.check,
                      expand: true,
                      color: count == 0 ? PX.white : PX.lime,
                      onPressed: count == 0
                          ? null
                          : () => Navigator.pop(context, _picked.values.toList()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(MuscleGroup m) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10, right: 4),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: PX.regionColor(m.region),
              border: Border.all(color: PX.ink, width: 2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(m.name.toUpperCase(), style: PX.title(10))),
          PixelTag(m.group, color: PX.sky),
        ],
      ),
    );
  }

  Widget _row(MuscleGroup m, ExerciseInfo e, Set<Equip> gear) {
    final selected = _picked.containsKey(_key(m, e));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 4),
      child: PixelCard(
        color: selected ? PX.mint : PX.white,
        onTap: () => _toggle(m, e),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            PixelCheck(checked: selected, onTap: () => _toggle(m, e)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name, style: PX.body(15, weight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      GearBadge(info: e, owned: gear),
                      PixelTag(e.gearText, color: PX.white),
                      PixelTag(e.rx, color: PX.yellow),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
