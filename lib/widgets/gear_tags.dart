import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/pixel_theme.dart';
import 'pixel_widgets.dart';

/// Small icon tag: a house for HOME-friendly, a dumbbell for GYM.
class GearBadge extends StatelessWidget {
  const GearBadge({super.key, required this.info, required this.owned});

  final ExerciseInfo info;

  /// The equipment the person owns (from Settings).
  final Set<Equip> owned;

  @override
  Widget build(BuildContext context) {
    final home = info.doableWith(owned);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: home ? PX.green : PX.orange,
        border: Border.all(color: PX.ink, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            home ? Icons.home : Icons.fitness_center,
            size: 14,
            color: PX.ink,
          ),
          const SizedBox(width: 4),
          Text(
            home ? 'HOME' : 'GYM',
            style: PX.body(12, weight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// The badge plus the gear text ("Dumbbell + Bench") for one exercise.
class GearTags extends StatelessWidget {
  const GearTags({super.key, required this.info, required this.owned});

  final ExerciseInfo info;
  final Set<Equip> owned;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        GearBadge(info: info, owned: owned),
        PixelTag(info.gearText, color: PX.white),
      ],
    );
  }
}
