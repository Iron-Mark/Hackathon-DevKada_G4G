import 'package:flutter/material.dart';

/// Three inline stats: count above a small label. No icons, no separators —
/// just typography and spacing carrying the hierarchy.
class ProfileStatsBar extends StatelessWidget {
  const ProfileStatsBar({
    super.key,
    required this.lessons,
    required this.scans,
    required this.translations,
  });

  final int lessons;
  final int scans;
  final int translations;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _Stat(count: lessons, label: 'Lessons'),
        ),
        Expanded(
          child: _Stat(count: scans, label: 'Scans'),
        ),
        Expanded(
          child: _Stat(count: translations, label: 'Translated'),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
            height: 1.1,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: cs.onSurface.withAlpha(140),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
