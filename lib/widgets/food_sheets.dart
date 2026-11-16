import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/log_models.dart';
import '../models/models.dart';
import '../state/food_log_state.dart';
import '../theme/pixel_theme.dart';
import 'pixel_widgets.dart';

/// Ask how many servings and which day, then add the food to the log.
/// Returns true if the food was logged.
Future<bool?> showLogFoodSheet(BuildContext context, Food food) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: PX.paper,
    shape: const RoundedRectangleBorder(
      side: BorderSide(color: PX.ink, width: PX.border),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _LogFoodBody(food: food),
    ),
  );
}

class _LogFoodBody extends StatefulWidget {
  const _LogFoodBody({required this.food});

  final Food food;

  @override
  State<_LogFoodBody> createState() => _LogFoodBodyState();
}

class _LogFoodBodyState extends State<_LogFoodBody> {
  late final FoodLogState _log;
  late String _date;
  late final List<String> _dates;
  double _servings = 1;

  @override
  void initState() {
    super.initState();
    _log = context.read<FoodLogState>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    _date = dateKey(_log.selected);
    _dates = {dateKey(today), dateKey(yesterday), _date}.toList()
      ..sort((a, b) => b.compareTo(a));
  }

  void _step(double delta) {
    final next = _servings + delta;
    if (next < 0.5 || next > 20) return;
    setState(() => _servings = next);
  }

  void _confirm() {
    _log.addFood(_date, FoodEntry.fromFood(widget.food, _servings));
    _log.selectDate(parseDateKey(_date));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.food;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f.name.toUpperCase(), style: PX.title(12)),
            const SizedBox(height: 6),
            Text('1 serving = ${f.serving}', style: PX.body(14, color: PX.grey)),
            const SizedBox(height: 16),
            Text('HOW MANY SERVINGS?',
                style: PX.body(13, color: PX.grey, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                PixelButton(
                  label: '',
                  icon: Icons.remove,
                  color: PX.white,
                  onPressed: () => _step(-0.5),
                ),
                Expanded(
                  child: Center(
                    child: Text('${fmtNum(_servings)} x', style: PX.title(16)),
                  ),
                ),
                PixelButton(
                  label: '',
                  icon: Icons.add,
                  color: PX.white,
                  onPressed: () => _step(0.5),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PixelCard(
              color: PX.yellow,
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  '${(f.kcal * _servings).round()} kcal   '
                  'P ${fmtNum(f.protein * _servings)}g   '
                  'C ${fmtNum(f.carbs * _servings)}g   '
                  'F ${fmtNum(f.fat * _servings)}g',
                  style: PX.body(15, weight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('WHICH DAY?',
                style: PX.body(13, color: PX.grey, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: [
                for (final k in _dates)
                  PixelChip(
                    label: dateLabel(parseDateKey(k)),
                    selected: _date == k,
                    onTap: () => setState(() => _date = k),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            PixelButton(
              label: 'Log it',
              icon: Icons.check,
              expand: true,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }
}

/// Edit the daily calorie and protein goals.
Future<void> showGoalsDialog(BuildContext context) {
  return showPixelDialog<void>(context, child: const _GoalsForm());
}

class _GoalsForm extends StatefulWidget {
  const _GoalsForm();

  @override
  State<_GoalsForm> createState() => _GoalsFormState();
}

class _GoalsFormState extends State<_GoalsForm> {
  late final TextEditingController _kcal;
  late final TextEditingController _protein;
  String? _error;

  @override
  void initState() {
    super.initState();
    final log = context.read<FoodLogState>();
    _kcal = TextEditingController(text: '${log.kcalGoal}');
    _protein = TextEditingController(text: '${log.proteinGoal}');
  }

  @override
  void dispose() {
    _kcal.dispose();
    _protein.dispose();
    super.dispose();
  }

  void _save() {
    final kcal = int.tryParse(_kcal.text.trim());
    final protein = int.tryParse(_protein.text.trim());
    if (kcal == null || protein == null || kcal <= 0 || protein <= 0) {
      setState(() => _error = 'Enter a number above 0 for both goals.');
      return;
    }
    context.read<FoodLogState>().setGoals(kcal, protein);
    Navigator.pop(context);
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(text,
            style: PX.body(13, color: PX.grey, weight: FontWeight.w700)),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('DAILY GOALS', style: PX.title(12)),
        _label('CALORIES (KCAL)'),
        TextField(
          controller: _kcal,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: PX.body(16),
          decoration: pixelInputDecoration(hint: 'e.g. 2200'),
        ),
        _label('PROTEIN (GRAMS)'),
        TextField(
          controller: _protein,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: PX.body(16),
          decoration: pixelInputDecoration(hint: 'e.g. 120'),
        ),
        const SizedBox(height: 10),
        Text(
          'A common rule of thumb for people who lift is about 1.6 to 2.2 g of '
          'protein per kg of bodyweight. Your calorie goal depends on whether '
          'you are bulking, cutting or maintaining.',
          style: PX.body(12, color: PX.grey),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: PX.body(13, color: PX.pink, weight: FontWeight.w700)),
        ],
        const SizedBox(height: 16),
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
