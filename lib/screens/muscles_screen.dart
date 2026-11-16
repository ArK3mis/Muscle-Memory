import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/muscle_data.dart';
import '../models/models.dart';
import '../state/planner_state.dart';
import '../state/settings_state.dart';
import '../theme/pixel_theme.dart';
import '../widgets/exercise_dialog.dart';
import '../widgets/gear_tags.dart';
import '../widgets/pixel_widgets.dart';

class MusclesScreen extends StatefulWidget {
  const MusclesScreen({super.key});

  @override
  State<MusclesScreen> createState() => _MusclesScreenState();
}

class _MusclesScreenState extends State<MusclesScreen> {
  String _region = 'All';
  String? _open; // name of the expanded muscle

  Future<void> _addToDay(MuscleGroup muscle, ExerciseInfo info) async {
    final planner = context.read<PlannerState>();
    final result = await showAddToDaySheet(
      context,
      exerciseName: info.name,
      muscleName: muscle.name,
      initialDetails: info.rx,
    );
    if (result == null || !mounted) return;
    planner.addExercise(
      result.day,
      Exercise(name: info.name, muscle: muscle.name, details: result.details),
      suggestedGroup: muscle.group,
    );
    showPixelSnack(context, 'Added ${info.name} to ${kDayNames[result.day]}');
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState>();
    final gear = settings.gear;
    final homeOnly = settings.homeOnly;

    final muscles = <MuscleGroup>[];
    final visible = <MuscleGroup, List<ExerciseInfo>>{};
    for (final m in kMuscles) {
      if (_region != 'All' && m.region != _region) continue;
      final list =
          m.exercises.where((e) => !homeOnly || e.doableWith(gear)).toList();
      if (list.isEmpty) continue;
      muscles.add(m);
      visible[m] = list;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MUSCLES', style: PX.title(18)),
            const SizedBox(height: 8),
            Text(
              'Tap a muscle, then ADD an exercise to any day of your week. '
              'HOME means you own the gear for it.',
              style: PX.body(14, color: PX.grey),
            ),
            const SizedBox(height: 12),
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
                    for (final r in ['All', ...kRegions])
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: PixelChip(
                          label: r,
                          selected: _region == r,
                          color: r == 'All' ? PX.lime : PX.regionColor(r),
                          onTap: () => setState(() => _region = r),
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
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 16),
                      itemCount: muscles.length,
                      itemBuilder: (context, i) =>
                          _muscleCard(muscles[i], visible[muscles[i]]!, gear),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _muscleCard(
    MuscleGroup m,
    List<ExerciseInfo> exercises,
    Set<Equip> gear,
  ) {
    final open = _open == m.name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, right: 4),
      child: PixelCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _open = open ? null : m.name),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: PX.regionColor(m.region),
                        border: Border.all(color: PX.ink, width: 2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(m.name.toUpperCase(), style: PX.title(10)),
                    ),
                    PixelTag(m.group, color: PX.yellow),
                    const SizedBox(width: 6),
                    PixelTag('${exercises.length}', color: PX.sky),
                    const SizedBox(width: 6),
                    Icon(
                      open ? Icons.expand_less : Icons.expand_more,
                      color: PX.ink,
                    ),
                  ],
                ),
              ),
            ),
            if (open)
              Container(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                decoration: const BoxDecoration(
                  color: PX.paper,
                  border: Border(
                    top: BorderSide(color: PX.ink, width: PX.border),
                  ),
                ),
                child: Column(
                  children: [
                    for (final ex in exercises)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex.name,
                                    style: PX.body(15, weight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  GearTags(info: ex, owned: gear),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            PixelButton(
                              label: 'Add',
                              icon: Icons.add,
                              small: true,
                              onPressed: () => _addToDay(m, ex),
                            ),
                          ],
                        ),
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
