import 'package:flutter/material.dart';

import '../data/food_data.dart';
import '../models/log_models.dart';
import '../models/models.dart';
import '../theme/pixel_theme.dart';
import '../widgets/food_sheets.dart';
import '../widgets/pixel_widgets.dart';
import 'food_log_view.dart';

class FoodsScreen extends StatefulWidget {
  const FoodsScreen({super.key});

  @override
  State<FoodsScreen> createState() => _FoodsScreenState();
}

class _FoodsScreenState extends State<FoodsScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _category = 'All';
  bool _proteinFirst = false;
  int _mode = 0; // 0 = dictionary, 1 = my day

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _logFood(Food f) async {
    final ok = await showLogFoodSheet(context, f);
    if (ok == true && mounted) {
      showPixelSnack(context, 'Logged ${f.name}');
    }
  }

  void _showDetail(Food f) {
    showPixelDialog<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(f.name.toUpperCase(), style: PX.title(12)),
          const SizedBox(height: 6),
          Text(f.serving, style: PX.body(14, color: PX.grey)),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${f.kcal}', style: PX.title(26)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('kcal', style: PX.body(16, weight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MacroBar(f),
          const SizedBox(height: 12),
          _macroRow('Protein', '${fmtNum(f.protein)} g', PX.lime),
          _macroRow('Carbs', '${fmtNum(f.carbs)} g', PX.sky),
          _macroRow('Fat', '${fmtNum(f.fat)} g', PX.yellow),
          const SizedBox(height: 10),
          Text(
            'Protein gives ${f.proteinPct}% of the calories here.',
            style: PX.body(14, weight: FontWeight.w600),
          ),
          if (f.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Note: ${f.note}', style: PX.body(14, color: PX.grey)),
          ],
          const SizedBox(height: 8),
          Text(
            'Estimates only. Brands and cooking oil change the numbers.',
            style: PX.body(12, color: PX.grey),
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (ctx) => PixelButton(
              label: 'Log this food',
              icon: Icons.add,
              expand: true,
              onPressed: () {
                Navigator.pop(ctx);
                _logFood(f);
              },
            ),
          ),
          Builder(
            builder: (ctx) => PixelButton(
              label: 'Close',
              color: PX.white,
              expand: true,
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
        ],
      ),
    );
  }

  Widget _macroRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: PX.ink, width: 2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: PX.body(15))),
          Text(value, style: PX.body(15, weight: FontWeight.w800)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FOOD', style: PX.title(18)),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  PixelChip(
                    label: 'Dictionary',
                    selected: _mode == 0,
                    onTap: () => setState(() => _mode = 0),
                  ),
                  const SizedBox(width: 10),
                  PixelChip(
                    label: 'My day',
                    selected: _mode == 1,
                    color: PX.orange,
                    onTap: () => setState(() => _mode = 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _mode == 0
                  ? _dictionary()
                  : MyDayView(onAddFood: () => setState(() => _mode = 0)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dictionary() {
    final foods = searchFoods(
      _query,
      category: _category,
      proteinFirst: _proteinFirst,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: TextField(
            controller: _search,
            style: PX.body(16),
            onChanged: (v) => setState(() => _query = v),
            decoration: pixelInputDecoration(
              hint: 'Search: itlog, chicken, noodles...',
              prefixIcon: const Icon(Icons.search, color: PX.ink),
            ).copyWith(
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, color: PX.ink),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                PixelChip(
                  label: 'High protein',
                  selected: _proteinFirst,
                  color: PX.orange,
                  onTap: () => setState(() => _proteinFirst = !_proteinFirst),
                ),
                const SizedBox(width: 10),
                for (final c in ['All', ...kFoodCategories])
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: PixelChip(
                      label: c,
                      selected: _category == c,
                      onTap: () => setState(() => _category = c),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: foods.isEmpty
              ? Center(
                  child: Text(
                    'No food found. Try another word.',
                    style: PX.body(15, color: PX.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  itemCount: foods.length,
                  itemBuilder: (context, i) => _foodCard(foods[i]),
                ),
        ),
      ],
    );
  }

  Widget _foodCard(Food f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: PixelCard(
        onTap: () => _showDetail(f),
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f.name, style: PX.body(16, weight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(f.serving, style: PX.body(13, color: PX.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      PixelTag('P ${fmtNum(f.protein)}g', color: PX.lime),
                      PixelTag('C ${fmtNum(f.carbs)}g', color: PX.sky),
                      PixelTag('F ${fmtNum(f.fat)}g', color: PX.yellow),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                Text('${f.kcal}', style: PX.title(16)),
                const SizedBox(height: 4),
                Text('kcal', style: PX.body(12, color: PX.grey)),
                const SizedBox(height: 6),
                PixelButton(
                  label: '',
                  icon: Icons.add,
                  small: true,
                  onPressed: () => _logFood(f),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Stacked bar showing where the calories come from.
class _MacroBar extends StatelessWidget {
  const _MacroBar(this.food);

  final Food food;

  @override
  Widget build(BuildContext context) {
    final p = food.protein * 4;
    final c = food.carbs * 4;
    final f = food.fat * 9;
    final total = p + c + f;

    final parts = <Widget>[];
    if (total > 0) {
      void add(double kcal, Color color) {
        final share = (kcal / total * 1000).round();
        if (share > 0) {
          parts.add(Expanded(flex: share, child: Container(color: color)));
        }
      }

      add(p, PX.lime);
      add(c, PX.sky);
      add(f, PX.yellow);
    }

    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: PX.white,
        border: Border.all(color: PX.ink, width: PX.border),
      ),
      child: Row(children: parts),
    );
  }
}
