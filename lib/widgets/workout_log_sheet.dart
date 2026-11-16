import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/log_models.dart';
import '../state/log_state.dart';
import '../state/rest_timer_state.dart';
import '../theme/pixel_theme.dart';
import 'pixel_widgets.dart';
import 'rest_timer_bar.dart';

/// Bottom sheet for logging the sets of one exercise on one day.
/// Returns true if every set with reps was ticked, false if not,
/// and null if the sheet was dismissed without saving.
Future<bool?> showWorkoutLogSheet(
  BuildContext context, {
  required String exerciseName,
  required String date,
  String plan = '',
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: PX.paper,
    shape: const RoundedRectangleBorder(
      side: BorderSide(color: PX.ink, width: PX.border),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _LogBody(name: exerciseName, date: date, plan: plan),
    ),
  );
}

class _SetRow {
  _SetRow({String w = '', String r = '', this.done = false})
      : weight = TextEditingController(text: w),
        reps = TextEditingController(text: r);

  final TextEditingController weight;
  final TextEditingController reps;
  bool done;

  double get weightValue =>
      double.tryParse(weight.text.trim().replaceAll(',', '.')) ?? 0;
  int get repsValue => int.tryParse(reps.text.trim()) ?? 0;

  void dispose() {
    weight.dispose();
    reps.dispose();
  }
}

class _LogBody extends StatefulWidget {
  const _LogBody({required this.name, required this.date, required this.plan});

  final String name;
  final String date;
  final String plan;

  @override
  State<_LogBody> createState() => _LogBodyState();
}

class _LogBodyState extends State<_LogBody> {
  late final LogState _log;
  final List<_SetRow> _rows = [];
  LogEntry? _last;
  String _hint = '';

  @override
  void initState() {
    super.initState();
    _log = context.read<LogState>();
    final existing = _log.entryOn(widget.name, widget.date);
    _last = _log.lastBefore(widget.name, widget.date);

    if (existing != null) {
      for (final s in existing.sets) {
        _rows.add(_SetRow(
          w: s.weight > 0 ? fmtNum(s.weight) : '',
          r: '${s.reps}',
          done: true,
        ));
      }
    } else if (_last != null) {
      // Start from last time's numbers, unticked, so you only change what's new.
      for (final s in _last!.sets) {
        _rows.add(_SetRow(
          w: s.weight > 0 ? fmtNum(s.weight) : '',
          r: '${s.reps}',
        ));
      }
    }
    while (_rows.length < 3) {
      _rows.add(_SetRow());
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  void _toggle(_SetRow r) {
    if (!r.done && r.repsValue <= 0) {
      setState(() => _hint = 'Enter the reps first, then tick the set.');
      return;
    }
    setState(() {
      _hint = '';
      r.done = !r.done;
    });
    if (r.done) context.read<RestTimerState>().start();
  }

  void _addSet() {
    setState(() {
      // Copy the previous row so adding a set is quick.
      final prev = _rows.isEmpty ? null : _rows.last;
      _rows.add(_SetRow(
        w: prev?.weight.text ?? '',
        r: prev?.reps.text ?? '',
      ));
    });
  }

  void _removeSet() {
    if (_rows.length <= 1) return;
    setState(() => _rows.removeLast().dispose());
  }

  void _save() {
    final sets = <SetEntry>[];
    var withReps = 0;
    for (final r in _rows) {
      if (r.repsValue > 0) withReps++;
      if (r.done && r.repsValue > 0) {
        sets.add(SetEntry(
          weight: r.weightValue,
          reps: r.repsValue,
          done: true,
        ));
      }
    }
    _log.saveSets(widget.name, widget.date, sets);
    Navigator.pop(context, sets.isNotEmpty && sets.length == withReps);
  }

  Widget _header(String text, {double? width}) {
    final label = Text(text, style: PX.body(12, color: PX.grey, weight: FontWeight.w800));
    if (width != null) return SizedBox(width: width, child: label);
    return Expanded(child: Center(child: label));
  }

  Widget _setRow(int i) {
    final r = _rows[i];
    final isPr = r.done &&
        r.repsValue > 0 &&
        _log.isPr(
          widget.name,
          widget.date,
          SetEntry(weight: r.weightValue, reps: r.repsValue),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 28,
                child: Text('${i + 1}', style: PX.title(10)),
              ),
              Expanded(
                child: TextField(
                  controller: r.weight,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  textAlign: TextAlign.center,
                  style: PX.body(16, weight: FontWeight.w800),
                  decoration: pixelInputDecoration(hint: kWeightUnit),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: r.reps,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: PX.body(16, weight: FontWeight.w800),
                  decoration: pixelInputDecoration(hint: 'reps'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              PixelCheck(checked: r.done, onTap: () => _toggle(r)),
            ],
          ),
          if (isPr)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: const PixelTag('NEW PR!', color: PX.orange),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final best = _log.bestWeightEver(widget.name);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.name.toUpperCase(), style: PX.title(12)),
            const SizedBox(height: 6),
            Text(
              '${dateLabel(parseDateKey(widget.date))}'
              '${widget.plan.isEmpty ? '' : '  -  plan: ${widget.plan}'}',
              style: PX.body(14, color: PX.grey),
            ),
            const SizedBox(height: 12),
            PixelCard(
              color: PX.sky,
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _last == null
                          ? 'First time logging this exercise.'
                          : 'Last time (${dateLabel(parseDateKey(_last!.date))}): '
                              '${_last!.sets.map((s) => s.label).join(', ')}',
                      style: PX.body(14, weight: FontWeight.w600),
                    ),
                    if (best != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Heaviest ever: ${fmtNum(best)} $kWeightUnit',
                        style: PX.body(14, weight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _header('SET', width: 28),
                _header(kWeightUnit.toUpperCase()),
                const SizedBox(width: 8),
                _header('REPS'),
                const SizedBox(width: 10),
                _header('DONE', width: 30),
              ],
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < _rows.length; i++) _setRow(i),
            Row(
              children: [
                PixelButton(
                  label: 'Set',
                  icon: Icons.add,
                  small: true,
                  color: PX.white,
                  onPressed: _addSet,
                ),
                const SizedBox(width: 4),
                PixelButton(
                  label: 'Set',
                  icon: Icons.remove,
                  small: true,
                  color: PX.white,
                  onPressed: _rows.length > 1 ? _removeSet : null,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _hint.isNotEmpty
                  ? _hint
                  : 'Tick a set when you finish it. Only ticked sets are saved.',
              style: PX.body(13, color: _hint.isNotEmpty ? PX.pink : PX.grey),
            ),
            const RestTimerBar(margin: EdgeInsets.only(top: 12, right: 4)),
            const SizedBox(height: 14),
            PixelButton(
              label: 'Save',
              expand: true,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
