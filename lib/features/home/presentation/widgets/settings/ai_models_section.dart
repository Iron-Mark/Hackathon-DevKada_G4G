import 'package:flutter/material.dart';

import 'llm_download_tile.dart';
import 'settings_card.dart';
import 'settings_divider.dart';
import 'settings_section_label.dart';
import 'vision_download_tile.dart';

class AiModelsSection extends StatelessWidget {
  const AiModelsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SettingsSectionLabel(text: 'Offline downloads'),
        SettingsCard(
          children: <Widget>[
            const _AiModelsIntro(),
            const SettingsDivider(),
            const LlmDownloadTile(),
            const SettingsDivider(),
            const VisionDownloadTile(),
          ],
        ),
      ],
    );
  }
}

class _AiModelsIntro extends StatelessWidget {
  const _AiModelsIntro();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.offline_bolt_rounded,
              size: 18,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Use Kudlit offline',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Set these up once to keep replies and camera reading available without internet.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: cs.onSurface.withAlpha(160),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
