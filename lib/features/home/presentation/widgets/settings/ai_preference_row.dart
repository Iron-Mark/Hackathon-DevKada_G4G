import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/features/home/presentation/providers/app_preferences_provider.dart';

import 'row_icon.dart';
import 'segmented_picker.dart';

class AiPreferenceRow extends ConsumerWidget {
  const AiPreferenceRow({super.key, required this.current});

  final AiPreference current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final SegmentedPicker<AiPreference> picker = SegmentedPicker<AiPreference>(
      options: const <(AiPreference, String)>[
        (AiPreference.cloud, 'Cloud'),
        (AiPreference.local, 'Local'),
      ],
      selected: current,
      onSelect: (AiPreference v) =>
          ref.read(appPreferencesNotifierProvider.notifier).setAiPreference(v),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget label = Text(
            'AI Engine',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          );
          if (constraints.maxWidth < 300) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const RowIcon(icon: Icons.memory_rounded),
                    const SizedBox(width: 12),
                    Expanded(child: label),
                  ],
                ),
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerLeft, child: picker),
              ],
            );
          }

          return Row(
            children: <Widget>[
              const RowIcon(icon: Icons.memory_rounded),
              const SizedBox(width: 12),
              Expanded(child: label),
              picker,
            ],
          );
        },
      ),
    );
  }
}
