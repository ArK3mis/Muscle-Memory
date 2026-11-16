import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/muscle_data.dart';
import '../models/log_models.dart';
import '../models/models.dart';
import '../state/log_state.dart';
import '../state/planner_state.dart';
import '../state/settings_state.dart';
import '../theme/pixel_theme.dart';
import '../widgets/exercise_dialog.dart';
import '../widgets/exercise_picker.dart';
import '../widgets/gear_tags.dart';
import '../widgets/pixel_widgets.dart';
import '../widgets/workout_log_sheet.dart';
import 'settings_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _selected = DateTime.now().weekday - 1; // start on today

  /// Calendar date of the selected weekday in the current week.
  DateTime _dateFor(int dayIndex) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday - 1) + dayIndex);
  }

  Future<void> _addExercises(PlannerState planner) async {
    final day = _selected;
    final plan = planner.days[day];
    final picked = await showExercisePicker(
      context,
      dayName: kDayNames[day],
      focuses: List<String>.from(plan.focuses),
    );
    if (picked == null || picked.isEmpty) return;

    final groups = <String>[];
    for (final p in picked) {
      if (p.group.isNotEmpty && !groups.contains(p.group)) groups.add(p.group);
    }
    planner.addExercises(
      day,
      picked
          .map((p) => Exercise(name: p.name, muscle: p.muscle, details: p.details))
          .toList(),
      groups: groups,
    );
  }

  Future<void> _logExercise(PlannerState planner, Exercise e) async {
    final day = _selected;
    final allDone = await showWorkoutLogSheet(
      context,
      exerciseName: e.name,
      date: dateKey(_dateFor(day)),
      plan: e.details,
    );
    if (allDone == true) {
      // Every set was ticked, so tick the exercise on the week plan too.
      final current =
          planner.days[day].exercises.where((x) => x.id == e.id).toList();
      if (current.isNotEmpty && !current.first.done) {
        planner.toggleDone(day, e.id);
      }
    }
  }

  Future<void> _editExercise(PlannerState planner, Exercise e) async {
    final updated = await showExerciseDialog(context, existing: e);
    if (updated != null) planner.updateExercise(_selected, updated);
  }

  void _deleteExercise(PlannerState planner, Exercise e) {
    final day = _selected;
    final index = planner.days[day].exercises.indexWhere((x) => x.id == e.id);
    final removed = planner.removeExercise(day, e.id);
    if (removed == null) return;
    showPixelSnack(
      context,
      'Removed ${removed.name}',
      actionLabel: 'UNDO',
      onAction: () => planner.insertExercise(day, index, removed),
    );
  }

  Future<void> _editFocus(PlannerState planner) async {
    final plan = planner.days[_selected];
    final result = await showPixelDialog<List<String>>(
      context,
      child: _FocusForm(
        dayName: kDayNames[_selected],
        initial: List<String>.from(plan.focuses),
      ),
    );
    if (result != null) planner.setFocuses(_selected, result);
  }

  Future<void> _editRun(PlannerState planner) async {
    final plan = planner.days[_selected];
    final km = await showPixelDialog<double>(
      context,
      child: _RunForm(
        dayName: kDayNames[_selected],
        initialKm: plan.runKm,
      ),
    );
    if (km != null) planner.setRun(_selected, km);
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerState>();
    final log = context.watch<LogState>();
    final gear = context.watch<SettingsState>().gear;
    final today = DateTime.now().weekday - 1;
    final plan = planner.days[_selected];
    final statuses = List<DayStatus>.generate(7, (i) => planner.statusOf(i));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('MY WEEK', style: PX.title(18))),
                IconButton(
                  tooltip: 'Settings',
                  icon: const Icon(Icons.settings, color: PX.ink),
                  onPressed: _openSettings,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _DayStrip(
              selected: _selected,
              today: today,
              days: planner.days,
              statuses: statuses,
              onSelect: (i) => setState(() => _selected = i),
            ),
            const SizedBox(height: 2),
            const _Legend(),
            const SizedBox(height: 10),
            _focusCard(planner, plan),
            const SizedBox(height: 10),
            if (plan.hasRun) _runTile(planner, plan),
            Expanded(
              child: plan.exercises.isNotEmpty
                  ? _exerciseList(planner, log, gear, plan)
                  : (plan.hasRun ? const SizedBox.shrink() : _emptyState()),
            ),
            Row(
              children: [
                Expanded(
                  child: PixelButton(
                    label: 'Add exercise',
                    icon: Icons.add,
                    expand: true,
                    onPressed: () => _addExercises(planner),
                  ),
                ),
                const SizedBox(width: 6),
                PixelButton(
                  label: 'Run',
                  icon: Icons.directions_run,
                  color: PX.sky,
                  onPressed: () => _editRun(planner),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _focusCard(PlannerState planner, DayPlan plan) {
    final title = plan.title;
    final hasFocus = title.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 4),
      child: PixelCard(
        color: hasFocus ? PX.yellow : PX.white,
        onTap: () => _editFocus(planner),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kDayNames[_selected].toUpperCase(),
                    style: PX.title(8, color: PX.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasFocus ? title : 'Tap to set a focus (you can mix, e.g. Chest + Core)',
                    style: hasFocus
                        ? PX.title(12)
                        : PX.body(15, color: PX.grey, weight: FontWeight.w600),
                  ),
                  if (plan.hasPlan) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        PixelProgress(
                          done: plan.doneCount,
                          total: plan.plannedCount,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${plan.doneCount}/${plan.plannedCount}',
                          style: PX.body(14, weight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.edit, size: 18, color: PX.ink),
          ],
        ),
      ),
    );
  }

  Widget _runTile(PlannerState planner, DayPlan plan) {
    final style = PX.body(16, weight: FontWeight.w800).copyWith(
      decoration:
          plan.runDone ? TextDecoration.lineThrough : TextDecoration.none,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: PixelCard(
        color: plan.runDone ? PX.mint : PX.sky,
        padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
        child: Row(
          children: [
            PixelCheck(
              checked: plan.runDone,
              onTap: () => planner.toggleRunDone(_selected),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.directions_run, color: PX.ink),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _editRun(planner),
                child: Text('Run ${fmtNum(plan.runKm)} km', style: style),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Edit run',
              icon: const Icon(Icons.edit, size: 20, color: PX.ink),
              onPressed: () => _editRun(planner),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: PX.sky,
                border: Border.all(color: PX.ink, width: PX.border),
              ),
              child: const Icon(Icons.fitness_center, size: 28, color: PX.ink),
            ),
            const SizedBox(height: 14),
            Text('NOTHING PLANNED', style: PX.title(11)),
            const SizedBox(height: 8),
            Text(
              'Rest day? Leave it empty. Otherwise add exercises or a run below.',
              textAlign: TextAlign.center,
              style: PX.body(14, color: PX.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exerciseList(
    PlannerState planner,
    LogState log,
    Set<Equip> gear,
    DayPlan plan,
  ) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      itemCount: plan.exercises.length,
      proxyDecorator: (child, index, animation) =>
          Material(color: Colors.transparent, child: child),
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex -= 1;
        planner.moveExercise(_selected, oldIndex, newIndex);
      },
      itemBuilder: (context, i) =>
          _exerciseTile(planner, log, gear, plan.exercises[i], i),
    );
  }

  Widget _exerciseTile(
    PlannerState planner,
    LogState log,
    Set<Equip> gear,
    Exercise e,
    int index,
  ) {
    final logged = log.entryOn(e.name, dateKey(_dateFor(_selected)));
    final info = findExerciseInfo(e.name);
    final nameStyle = PX.body(16, weight: FontWeight.w700).copyWith(
      decoration: e.done ? TextDecoration.lineThrough : TextDecoration.none,
    );
    return Padding(
      key: ValueKey(e.id),
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: PixelCard(
        color: e.done ? PX.mint : PX.white,
        padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
        child: Row(
          children: [
            PixelCheck(
              checked: e.done,
              onTap: () => planner.toggleDone(_selected, e.id),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _logExercise(planner, e),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name, style: nameStyle),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (info != null) GearBadge(info: info, owned: gear),
                        if (e.details.isNotEmpty)
                          PixelTag(e.details, color: PX.yellow),
                        if (e.muscle.isNotEmpty)
                          PixelTag(e.muscle, color: PX.sky),
                        if (logged != null)
                          PixelTag('${logged.sets.length} sets logged',
                              color: PX.lime)
                        else
                          const PixelTag('tap to log', color: PX.white),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: PX.ink),
              color: PX.white,
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: PX.ink, width: PX.border),
              ),
              onSelected: (v) {
                if (v == 'edit') {
                  _editExercise(planner, e);
                } else if (v == 'delete') {
                  _deleteExercise(planner, e);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit', style: PX.body(14)),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: PX.body(14)),
                ),
              ],
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.drag_indicator, color: PX.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Mon..Sun boxes. Green = everything done, red = a past day with
/// something missed, white = still to do or a rest day.
class _DayStrip extends StatelessWidget {
  const _DayStrip({
    required this.selected,
    required this.today,
    required this.days,
    required this.statuses,
    required this.onSelect,
  });

  final int selected;
  final int today;
  final List<DayPlan> days;
  final List<DayStatus> statuses;
  final ValueChanged<int> onSelect;

  Color _fill(DayStatus s, bool isSelected) {
    switch (s) {
      case DayStatus.done:
        return PX.green;
      case DayStatus.missed:
        return PX.red;
      case DayStatus.pending:
      case DayStatus.empty:
        return isSelected ? PX.lime : PX.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(7, (i) {
        final isSelected = i == selected;
        final count = days[i].plannedCount;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 6 ? 4 : 6, bottom: 3),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(i),
              child: Container(
                // The selected day looks pressed in.
                transform: isSelected
                    ? Matrix4.translationValues(3, 3, 0)
                    : Matrix4.identity(),
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: _fill(statuses[i], isSelected),
                  border: Border.all(color: PX.ink, width: PX.border),
                  boxShadow: isSelected
                      ? null
                      : const [BoxShadow(color: PX.ink, offset: Offset(3, 3))],
                ),
                child: Column(
                  children: [
                    Text(kDayShort[i], style: PX.title(7)),
                    const SizedBox(height: 6),
                    Text(
                      count == 0 ? '-' : '$count',
                      style: PX.body(14, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    // Orange bar marks today.
                    Container(
                      height: 5,
                      color: i == today ? PX.orange : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  Widget _item(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: PX.ink, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: PX.body(12, color: PX.grey, weight: FontWeight.w700)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        _item(PX.green, 'Done'),
        _item(PX.red, 'Missed'),
        _item(PX.orange, 'Today'),
      ],
    );
  }
}

/// Pick one or more focus groups. The day name is built from them,
/// in the order they were tapped: "Core and Chest Day".
class _FocusForm extends StatefulWidget {
  const _FocusForm({required this.dayName, required this.initial});

  final String dayName;
  final List<String> initial;

  @override
  State<_FocusForm> createState() => _FocusFormState();
}

class _FocusFormState extends State<_FocusForm> {
  late final List<String> _sel;

  @override
  void initState() {
    super.initState();
    _sel = List<String>.from(widget.initial);
  }

  void _toggle(String group) {
    setState(() {
      if (_sel.contains(group)) {
        _sel.remove(group);
      } else if (group == kRestFocus) {
        _sel
          ..clear()
          ..add(kRestFocus);
      } else {
        _sel
          ..remove(kRestFocus)
          ..add(group);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final preview = focusTitle(_sel);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${widget.dayName.toUpperCase()} FOCUS', style: PX.title(12)),
        const SizedBox(height: 8),
        Text(
          'Tap more than one to mix them.',
          style: PX.body(14, color: PX.grey),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final g in [...kFocusGroups, kRestFocus])
              PixelChip(
                label: g,
                selected: _sel.contains(g),
                onTap: () => _toggle(g),
              ),
          ],
        ),
        const SizedBox(height: 16),
        PixelCard(
          color: _sel.isEmpty ? PX.white : PX.yellow,
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              _sel.isEmpty ? 'No focus' : preview,
              style: _sel.isEmpty
                  ? PX.body(15, color: PX.grey, weight: FontWeight.w600)
                  : PX.title(11),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: PixelButton(
                label: 'Clear',
                color: PX.white,
                expand: true,
                onPressed: () => Navigator.pop(context, <String>[]),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: PixelButton(
                label: 'Save',
                expand: true,
                onPressed: () => Navigator.pop(context, List<String>.from(_sel)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Plan a run for the day. 0 km (or Remove run) means no run.
class _RunForm extends StatefulWidget {
  const _RunForm({required this.dayName, required this.initialKm});

  final String dayName;
  final double initialKm;

  @override
  State<_RunForm> createState() => _RunFormState();
}

class _RunFormState extends State<_RunForm> {
  late final TextEditingController _km;
  String? _error;

  static const List<double> _quick = [3, 5, 8, 10, 15, 21];

  @override
  void initState() {
    super.initState();
    _km = TextEditingController(
      text: widget.initialKm > 0 ? fmtNum(widget.initialKm) : '',
    );
  }

  @override
  void dispose() {
    _km.dispose();
    super.dispose();
  }

  double get _value =>
      double.tryParse(_km.text.trim().replaceAll(',', '.')) ?? 0;

  void _save() {
    final v = _value;
    if (v <= 0) {
      setState(() => _error = 'Enter a distance above 0, or tap Remove run.');
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${widget.dayName.toUpperCase()} RUN', style: PX.title(12)),
        const SizedBox(height: 14),
        TextField(
          controller: _km,
          autofocus: widget.initialKm <= 0,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          style: PX.body(18, weight: FontWeight.w800),
          decoration: pixelInputDecoration(hint: 'Distance in km')
              .copyWith(errorText: _error, suffixText: 'km'),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final q in _quick)
              PixelChip(
                label: '${fmtNum(q)} km',
                selected: _value == q,
                onTap: () => setState(() {
                  _km.text = fmtNum(q);
                  _error = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (widget.initialKm > 0) ...[
          PixelButton(
            label: 'Remove run',
            color: PX.pink,
            expand: true,
            onPressed: () => Navigator.pop(context, 0.0),
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Expanded(
              child: PixelButton(
                label: 'Cancel',
                color: PX.white,
                expand: true,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: PixelButton(
                label: 'Save',
                expand: true,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
