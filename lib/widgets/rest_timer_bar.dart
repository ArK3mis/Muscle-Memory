import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/rest_timer_state.dart';
import '../theme/pixel_theme.dart';
import 'pixel_widgets.dart';

String formatClock(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// Countdown strip. Shows nothing unless the rest timer is running or done.
class RestTimerBar extends StatelessWidget {
  const RestTimerBar({
    super.key,
    this.margin = const EdgeInsets.fromLTRB(12, 8, 16, 4),
  });

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<RestTimerState>();
    if (!t.active) return const SizedBox.shrink();

    return Padding(
      padding: margin,
      child: PixelCard(
        color: t.finished ? PX.lime : PX.yellow,
        padding: const EdgeInsets.fromLTRB(12, 8, 6, 4),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: PX.ink),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.finished ? 'REST DONE - GO!' : 'REST ${formatClock(t.remaining)}',
                style: PX.title(12),
              ),
            ),
            if (!t.finished)
              PixelButton(
                label: '+15s',
                small: true,
                color: PX.white,
                onPressed: () => t.addSeconds(15),
              ),
            const SizedBox(width: 2),
            PixelButton(
              label: t.finished ? 'OK' : 'Skip',
              small: true,
              color: PX.white,
              onPressed: t.stop,
            ),
          ],
        ),
      ),
    );
  }
}

/// Lets the person pick how long the rest timer counts down.
Future<void> showRestPicker(BuildContext context) {
  return showPixelDialog<void>(context, child: const _RestPicker());
}

class _RestPicker extends StatelessWidget {
  const _RestPicker();

  static const List<int> _options = [45, 60, 90, 120, 180];

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<RestTimerState>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('REST TIMER', style: PX.title(12)),
        const SizedBox(height: 8),
        Text(
          'Starts automatically when you tick a set.',
          style: PX.body(14, color: PX.grey),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final s in _options)
              PixelChip(
                label: formatClock(s),
                selected: timer.defaultSeconds == s,
                onTap: () => timer.setDefault(s),
              ),
          ],
        ),
        const SizedBox(height: 18),
        PixelButton(
          label: 'Done',
          expand: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
