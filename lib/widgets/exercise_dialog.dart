import 'package:flutter/material.dart';

import '../data/muscle_data.dart';
import '../models/models.dart';
import '../theme/pixel_theme.dart';
import 'pixel_widgets.dart';

/// Add or edit an exercise. Returns null if the person cancels.
Future<Exercise?> showExerciseDialog(
  BuildContext context, {
  Exercise? existing,
}) {
  return showPixelDialog<Exercise>(
    context,
    child: _ExerciseForm(existing: existing),
  );
}

class _ExerciseForm extends StatefulWidget {
  const _ExerciseForm({this.existing});

  final Exercise? existing;

  @override
  State<_ExerciseForm> createState() => _ExerciseFormState();
}

class _ExerciseFormState extends State<_ExerciseForm> {
  late final TextEditingController _name;
  late final TextEditingController _details;
  late String _muscle;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _details = TextEditingController(text: e?.details ?? '3 x 10');
    final known = kMuscles.any((m) => m.name == e?.muscle);
    _muscle = known ? e!.muscle : '';
  }

  @override
  void dispose() {
    _name.dispose();
    _details.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give the exercise a name');
      return;
    }
    final result = widget.existing == null
        ? Exercise(name: name, muscle: _muscle, details: _details.text.trim())
        : widget.existing!.copyWith(
            name: name,
            muscle: _muscle,
            details: _details.text.trim(),
          );
    Navigator.pop(context, result);
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(text, style: PX.body(13, color: PX.grey, weight: FontWeight.w700)),
      );

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(editing ? 'EDIT EXERCISE' : 'ADD EXERCISE', style: PX.title(12)),
        _label('NAME'),
        TextField(
          controller: _name,
          autofocus: !editing,
          textCapitalization: TextCapitalization.sentences,
          style: PX.body(16),
          decoration: pixelInputDecoration(hint: 'e.g. Pull-ups')
              .copyWith(errorText: _error),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        _label('SETS x REPS (OR NOTES)'),
        TextField(
          controller: _details,
          style: PX.body(16),
          decoration: pixelInputDecoration(hint: 'e.g. 4 x 8'),
        ),
        _label('MUSCLE (OPTIONAL)'),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: PX.white,
            border: Border.all(color: PX.ink, width: PX.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _muscle,
              dropdownColor: PX.white,
              borderRadius: BorderRadius.zero,
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text('None', style: PX.body(15, color: PX.grey)),
                ),
                for (final m in kMuscles)
                  DropdownMenuItem(
                    value: m.name,
                    child: Text(m.name, style: PX.body(15)),
                  ),
              ],
              onChanged: (v) => setState(() => _muscle = v ?? ''),
            ),
          ),
        ),
        const SizedBox(height: 18),
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

/// Result of the "add to which day?" sheet on the Muscle tab.
class AddToDayResult {
  const AddToDayResult(this.day, this.details);

  final int day; // 0 = Monday
  final String details;
}

Future<AddToDayResult?> showAddToDaySheet(
  BuildContext context, {
  required String exerciseName,
  required String muscleName,
  String initialDetails = '3 x 10',
}) {
  return showModalBottomSheet<AddToDayResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: PX.paper,
    shape: const RoundedRectangleBorder(
      side: BorderSide(color: PX.ink, width: PX.border),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _AddToDayBody(
        exerciseName: exerciseName,
        muscleName: muscleName,
        initialDetails: initialDetails,
      ),
    ),
  );
}

class _AddToDayBody extends StatefulWidget {
  const _AddToDayBody({
    required this.exerciseName,
    required this.muscleName,
    required this.initialDetails,
  });

  final String exerciseName;
  final String muscleName;
  final String initialDetails;

  @override
  State<_AddToDayBody> createState() => _AddToDayBodyState();
}

class _AddToDayBodyState extends State<_AddToDayBody> {
  int _day = DateTime.now().weekday - 1;
  late final TextEditingController _details;

  @override
  void initState() {
    super.initState();
    _details = TextEditingController(text: widget.initialDetails);
  }

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.exerciseName.toUpperCase(), style: PX.title(12)),
            const SizedBox(height: 6),
            Text(widget.muscleName, style: PX.body(14, color: PX.grey)),
            const SizedBox(height: 16),
            Text('ADD TO WHICH DAY?',
                style: PX.body(13, color: PX.grey, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: [
                for (var i = 0; i < 7; i++)
                  PixelChip(
                    label: kDayShort[i],
                    selected: _day == i,
                    onTap: () => setState(() => _day = i),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('SETS x REPS',
                style: PX.body(13, color: PX.grey, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _details,
              style: PX.body(16),
              decoration: pixelInputDecoration(hint: 'e.g. 4 x 8'),
            ),
            const SizedBox(height: 16),
            PixelButton(
              label: 'Add to ${kDayNames[_day]}',
              icon: Icons.add,
              expand: true,
              onPressed: () => Navigator.pop(
                context,
                AddToDayResult(_day, _details.text.trim()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
