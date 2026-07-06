import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kudlit_ph/features/auth/domain/entities/auth_user.dart';
import 'package:kudlit_ph/features/home/domain/entities/profile_preferences.dart';
import 'package:kudlit_ph/features/home/domain/entities/profile_summary.dart';
import 'package:kudlit_ph/features/home/presentation/providers/profile_management_provider.dart';
import 'package:kudlit_ph/features/home/presentation/screens/profile_tab.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/accessibility_dialog.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/profile_management_action_button.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/profile_management_section.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/segmented_picker.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/settings_list.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/sign_out_tile.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/theme_row.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _FakeProfileSummaryNotifier extends ProfileSummaryNotifier {
  _FakeProfileSummaryNotifier(this.summary);

  ProfileSummary summary;
  String? updatedDisplayName;

  @override
  FutureOr<Option<ProfileSummary>> build() => Some(summary);

  @override
  Future<void> updateDisplayName(String displayName) async {
    updatedDisplayName = displayName;
    summary = ProfileSummary(
      displayName: displayName,
      avatarUrl: summary.avatarUrl,
      completedLessons: summary.completedLessons,
      scanHistoryItems: summary.scanHistoryItems,
      translationHistoryItems: summary.translationHistoryItems,
      bookmarkedTranslations: summary.bookmarkedTranslations,
    );
    state = AsyncValue.data(Some(summary));
  }
}

void main() {
  testWidgets('guest profile fits short landscape with comfortable CTA', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(593, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: ProfileTab())),
      ),
    );

    final Rect action = tester.getRect(find.byType(InkWell).first);

    expect(action.height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets('signed-in profile keeps history shortcuts inside phone width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 593));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileSummaryNotifierProvider.overrideWith(
            () => _FakeProfileSummaryNotifier(
              const ProfileSummary(
                displayName: 'Kudlit Learner With A Long Name',
                avatarUrl: null,
                completedLessons: 12,
                scanHistoryItems: 8,
                translationHistoryItems: 6,
                bookmarkedTranslations: 3,
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ProfileTab(
              user: AuthUser(id: 'u1', email: 'learner@example.com'),
            ),
          ),
        ),
      ),
    );

    final Rect scanShortcut = tester.getRect(find.text('Scanner History'));
    final Rect translateShortcut = tester.getRect(
      find.text('Translation History'),
    );

    expect(scanShortcut.left, greaterThanOrEqualTo(0));
    expect(scanShortcut.right, lessThanOrEqualTo(320));
    expect(translateShortcut.left, greaterThanOrEqualTo(0));
    expect(translateShortcut.right, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('display name edits inline on the profile card', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _FakeProfileSummaryNotifier notifier = _FakeProfileSummaryNotifier(
      const ProfileSummary(
        displayName: 'Kudlit Learner',
        avatarUrl: null,
        completedLessons: 12,
        scanHistoryItems: 8,
        translationHistoryItems: 6,
        bookmarkedTranslations: 3,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileSummaryNotifierProvider.overrideWith(() => notifier),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SettingsList(
              user: const AuthUser(id: 'u1', email: 'learner@example.com'),
              isAuthLoading: false,
              bottomPadding: 0,
              onActionTap: (_) {},
              onSignOutTap: () async {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Kudlit Learner'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Kudlit Pro');
    await tester.tap(find.byTooltip('Save display name'));
    await tester.pumpAndSettle();

    expect(notifier.updatedDisplayName, 'Kudlit Pro');
    expect(find.text('Kudlit Pro'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile management name action uses inline editor', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _FakeProfileSummaryNotifier notifier = _FakeProfileSummaryNotifier(
      const ProfileSummary(
        displayName: 'Kudlit Learner',
        avatarUrl: null,
        completedLessons: 12,
        scanHistoryItems: 8,
        translationHistoryItems: 6,
        bookmarkedTranslations: 3,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileSummaryNotifierProvider.overrideWith(() => notifier),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProfileManagementSection(
                isAuthenticated: true,
                onActionTap: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Edit name (Kudlit Learner)'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Kudlit Max');
    await tester.tap(find.byTooltip('Save display name'));
    await tester.pumpAndSettle();

    expect(notifier.updatedDisplayName, 'Kudlit Max');
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('display name inline edit can be cancelled', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _FakeProfileSummaryNotifier notifier = _FakeProfileSummaryNotifier(
      const ProfileSummary(
        displayName: 'Kudlit Learner',
        avatarUrl: null,
        completedLessons: 12,
        scanHistoryItems: 8,
        translationHistoryItems: 6,
        bookmarkedTranslations: 3,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileSummaryNotifierProvider.overrideWith(() => notifier),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SettingsList(
              user: const AuthUser(id: 'u1', email: 'learner@example.com'),
              isAuthLoading: false,
              bottomPadding: 0,
              onActionTap: (_) {},
              onSignOutTap: () async {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Kudlit Learner'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Discarded Name');
    await tester.tap(find.byTooltip('Cancel display name edit'));
    await tester.pumpAndSettle();

    expect(notifier.updatedDisplayName, isNull);
    expect(find.text('Kudlit Learner'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('display name inline edit rejects blank names', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final _FakeProfileSummaryNotifier notifier = _FakeProfileSummaryNotifier(
      const ProfileSummary(
        displayName: 'Kudlit Learner',
        avatarUrl: null,
        completedLessons: 12,
        scanHistoryItems: 8,
        translationHistoryItems: 6,
        bookmarkedTranslations: 3,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileSummaryNotifierProvider.overrideWith(() => notifier),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SettingsList(
              user: const AuthUser(id: 'u1', email: 'learner@example.com'),
              isAuthLoading: false,
              bottomPadding: 0,
              onActionTap: (_) {},
              onSignOutTap: () async {},
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Kudlit Learner'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byTooltip('Save display name'));
    await tester.pump();

    expect(notifier.updatedDisplayName, isNull);
    expect(find.text('Display name cannot be empty.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings list fits narrow guest account surface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 593));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SettingsList(
              user: null,
              isAuthLoading: false,
              bottomPadding: 0,
              onActionTap: (_) {},
              onSignOutTap: () async {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Guest'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accessibility dialog fits compact landscape', (tester) async {
    await tester.binding.setSurfaceSize(const Size(593, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AccessibilityDialog(
            current: ProfilePreferences(
              highContrast: false,
              reducedMotion: false,
              dataSharingConsent: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Accessibility'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile management action pill exposes material tap semantics', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(320, 593));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ProfileManagementActionButton(
              label: 'Edit profile',
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Edit profile'), findsOneWidget);
    expect(find.byType(InkWell), findsOneWidget);

    final Rect target = tester.getRect(find.byType(InkWell));
    expect(target.height, greaterThanOrEqualTo(44));
    expect(target.width, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets(
    'segmented picker options expose selected semantics and targets',
    (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.binding.setSurfaceSize(const Size(320, 593));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SegmentedPicker<String>(
                options: const <(String, String)>[
                  ('system', 'System'),
                  ('light', 'Light'),
                  ('dark', 'Dark'),
                ],
                selected: 'system',
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('System option'), findsOneWidget);
      expect(find.byTooltip('System'), findsOneWidget);

      for (final Element element in find.byType(InkWell).evaluate()) {
        final Rect target = tester.getRect(find.byWidget(element.widget));
        expect(target.height, greaterThanOrEqualTo(44));
        expect(target.width, greaterThanOrEqualTo(44));
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('settings preference controls stack on narrow cards', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 593));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 288,
                child: ThemeRow(current: ThemeMode.system),
              ),
            ),
          ),
        ),
      ),
    );

    final Rect label = tester.getRect(find.text('App theme'));
    final Rect pickerOption = tester.getRect(find.text('System'));

    expect(pickerOption.top, greaterThan(label.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign out tile uses a labeled material tap target', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(320, 593));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: SignOutTile(onTap: () {})),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Sign out'), findsOneWidget);
    expect(find.byType(InkWell), findsOneWidget);

    final Rect target = tester.getRect(find.byType(InkWell));
    expect(target.height, greaterThanOrEqualTo(44));
    expect(target.width, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
