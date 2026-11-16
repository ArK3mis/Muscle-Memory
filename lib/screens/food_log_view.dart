import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/log_models.dart';
import '../state/food_log_state.dart';
import '../theme/pixel_theme.dart';
import '../widgets/food_sheets.dart';
import '../widgets/pixel_widgets.dart';

/// "My day" view: what you ate on the chosen day against your goals.
class MyDayView extends StatelessWidget {
  const MyDayView({super.key, required this.onAddFood});

  /// Called when the person wants to pick a food (switches to the dictionary).
  final VoidCallback onAddFood;

  void _shiftDay(FoodLogState log, int days) {
    final s = log.selected;
    log.selectDate(DateTime(s.year, s.month, s.day + days));
  }

  void _delete(BuildContext context, FoodLogState log, String date, FoodEntry e) {
    final index = log.entriesOn(date).indexWhere((x) => x.id == e.id);
    final removed = log.removeEntry(date, e.id);
    if (removed == null) return;
    showPixelSnack(
      context,
      'Removed ${removed.name}',
      actionLabel: 'UNDO',
      onAction: () => log.insertEntry(date, index, removed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final log = context.watch<FoodLogState>();
    final date = dateKey(log.selected);
    final totals = log.totalsOn(date);
    final entries = log.entriesOn(date);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Row(
            children: [
              PixelButton(
                label: '',
                icon: Icons.chevron_left,
                small: true,
                color: PX.white,
                onPressed: () => _shiftDay(log, -1),
              ),
              Expanded(
                child: Center(
                  child: Text(dateLabel(log.selected).toUpperCase(),
                      style: PX.title(11)),
                ),
              ),
              PixelButton(
                label: '',
                icon: Icons.chevron_right,
                small: true,
                color: PX.white,
                onPressed: () => _shiftDay(log, 1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            children: [
              _summary(context, log, totals),
              const SizedBox(height: 14),
              if (entries.isEmpty)
                _empty()
              else
                for (final e in entries) _entryCard(context, log, date, e),
            ],
          ),
        ),
        PixelButton(
          label: 'Add food',
          icon: Icons.add,
          expand: true,
          onPressed: onAddFood,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _summary(BuildContext context, FoodLogState log, DayTotals t) {
    final kcal = t.kcal.round();
    final over = kcal > log.kcalGoal;
    final diff = (kcal - log.kcalGoal).abs();

    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 4),
      child: PixelCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('CALORIES',
                      style: PX.title(8, color: PX.grey)),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showGoalsDialog(context),
                  child: Row(
                    children: [
                      Text('GOALS', style: PX.title(8)),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, size: 14, color: PX.ink),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('$kcal / ${log.kcalGoal}', style: PX.title(16)),
            const SizedBox(height: 8),
            PixelProgress(
              done: kcal,
              total: log.kcalGoal,
              blocks: 20,
              expand: true,
              color: over ? PX.pink : PX.lime,
            ),
            const SizedBox(height: 6),
            Text(
              over ? '$diff kcal over your goal' : '$diff kcal left',
              style: PX.body(14, weight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Text('PROTEIN', style: PX.title(8, color: PX.grey)),
            const SizedBox(height: 8),
            Text('${t.protein.round()} / ${log.proteinGoal} g',
                style: PX.title(12)),
            const SizedBox(height: 8),
            PixelProgress(
              done: t.protein.round(),
              total: log.proteinGoal,
              blocks: 20,
              expand: true,
              color: PX.orange,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                PixelTag('Carbs ${t.carbs.round()}g', color: PX.sky),
                PixelTag('Fat ${t.fat.round()}g', color: PX.yellow),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: PX.mint,
              border: Border.all(color: PX.ink, width: PX.border),
            ),
            child: const Icon(Icons.restaurant, size: 28, color: PX.ink),
          ),
          const SizedBox(height: 14),
          Text('NOTHING LOGGED', style: PX.title(11)),
          const SizedBox(height: 8),
          Text(
            'Tap ADD FOOD, then the + on any food in the dictionary.',
            textAlign: TextAlign.center,
            style: PX.body(14, color: PX.grey),
          ),
        ],
      ),
    );
  }

  Widget _entryCard(
    BuildContext context,
    FoodLogState log,
    String date,
    FoodEntry e,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: PixelCard(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.name, style: PX.body(16, weight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('${fmtNum(e.servings)} x ${e.serving}',
                      style: PX.body(13, color: PX.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      PixelTag('P ${fmtNum(e.totalProtein)}g', color: PX.lime),
                      PixelTag('C ${fmtNum(e.totalCarbs)}g', color: PX.sky),
                      PixelTag('F ${fmtNum(e.totalFat)}g', color: PX.yellow),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Text('${e.totalKcal.round()}', style: PX.title(14)),
                const SizedBox(height: 4),
                Text('kcal', style: PX.body(12, color: PX.grey)),
              ],
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline, color: PX.ink),
              onPressed: () => _delete(context, log, date, e),
            ),
          ],
        ),
      ),
    );
  }
}
