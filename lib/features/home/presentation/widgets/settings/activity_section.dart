import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kudlit_ph/app/constants.dart';
import 'package:kudlit_ph/features/home/presentation/providers/profile_management_provider.dart';
import 'package:kudlit_ph/features/translator/domain/entities/chat_memory_fact.dart';
import 'package:kudlit_ph/features/translator/domain/entities/chat_message.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/chat_history_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/chat_memory_provider.dart';

import 'profile_nav_row.dart';
import 'settings_card.dart';
import 'settings_divider.dart';
import 'settings_section_label.dart';

class ActivitySection extends ConsumerWidget {
  const ActivitySection({super.key, required this.onActionTap});

  final void Function(String message) onActionTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref
        .watch(profileSummaryNotifierProvider)
        .value
        ?.toNullable();

    final int lessons = summary?.completedLessons ?? 0;
    final int scans = summary?.scanHistoryItems ?? 0;
    final int translations = summary?.translationHistoryItems ?? 0;
    final int bookmarks = summary?.bookmarkedTranslations ?? 0;

    final List<ChatMessage> chatMsgs =
        ref.watch(chatHistoryNotifierProvider).value ?? <ChatMessage>[];
    final List<ChatMemoryFact> facts =
        ref.watch(chatMemoryNotifierProvider).value ?? <ChatMemoryFact>[];
    final String? buttySubtitle = (chatMsgs.isNotEmpty || facts.isNotEmpty)
        ? '${chatMsgs.length} msg · ${facts.length} fact${facts.length == 1 ? '' : 's'}'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SettingsSectionLabel(text: 'Your Progress'),
        SettingsCard(
          children: <Widget>[
            ProfileNavRow(
              icon: Icons.menu_book_rounded,
              title: 'Learning progress',
              subtitle: 'Lessons, milestones, and streaks.',
              trailingLabel: lessons > 0 ? '$lessons done' : null,
              onTap: () => context.push(AppConstants.routeLearningProgress),
            ),
            const SettingsDivider(),
            ProfileNavRow(
              icon: Icons.document_scanner_outlined,
              title: 'Scanner history',
              subtitle: 'Prior scans and retry results.',
              trailingLabel: scans > 0 ? '$scans scans' : null,
              onTap: () => context.push(AppConstants.routeScanHistory),
            ),
            const SettingsDivider(),
            ProfileNavRow(
              icon: Icons.translate_rounded,
              title: 'Translations & bookmarks',
              subtitle: 'Saved phrases and quick revisits.',
              trailingLabel: (translations > 0 || bookmarks > 0)
                  ? '$translations · $bookmarks saved'
                  : null,
              onTap: () => context.push(AppConstants.routeTranslationHistory),
            ),
            const SettingsDivider(),
            ProfileNavRow(
              icon: Icons.psychology_outlined,
              title: 'Butty chat & memory',
              subtitle: 'Manage chat history and what Butty remembers.',
              trailingLabel: buttySubtitle,
              onTap: () => context.push(AppConstants.routeButtyData),
            ),
          ],
        ),
      ],
    );
  }
}
