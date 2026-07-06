import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/features/home/domain/entities/profile_preferences.dart';
import 'package:kudlit_ph/features/home/presentation/providers/profile_management_provider.dart';

import 'accessibility_dialog.dart';
import 'privacy_dialog.dart';
import 'profile_nav_row.dart';
import 'settings_card.dart';
import 'settings_divider.dart';
import 'settings_section_label.dart';

class PersonalizationSection extends ConsumerStatefulWidget {
  const PersonalizationSection({super.key});

  @override
  ConsumerState<PersonalizationSection> createState() =>
      _PersonalizationSectionState();
}

class _PersonalizationSectionState
    extends ConsumerState<PersonalizationSection> {
  ProfilePreferences _currentPrefs() {
    final opt = ref.read(profilePreferencesNotifierProvider).value;
    return opt?.toNullable() ??
        const ProfilePreferences(
          highContrast: false,
          reducedMotion: false,
          dataSharingConsent: false,
        );
  }

  Future<void> _openAccessibility() async {
    final ProfilePreferences? updated = await showDialog<ProfilePreferences>(
      context: context,
      builder: (_) => AccessibilityDialog(current: _currentPrefs()),
    );
    if (updated == null || !mounted) return;
    await ref
        .read(profilePreferencesNotifierProvider.notifier)
        .updatePreferences(updated);
    if (!mounted) return;
    _showFeedback(ref.read(profilePreferencesNotifierProvider).error);
  }

  Future<void> _openPrivacy() async {
    final ProfilePreferences? updated = await showDialog<ProfilePreferences>(
      context: context,
      builder: (_) => PrivacyDialog(current: _currentPrefs()),
    );
    if (updated == null || !mounted) return;
    await ref
        .read(profilePreferencesNotifierProvider.notifier)
        .updatePreferences(updated);
    if (!mounted) return;
    _showFeedback(ref.read(profilePreferencesNotifierProvider).error);
  }

  void _showFeedback(Object? error) {
    if (error != null) {
      String message = error.toString();
      if (error is Failure) {
        message = error.when(
          network: (String m) => m,
          unknown: (String m) => m,
          invalidCredentials: () => 'Invalid credentials',
          userNotFound: () => 'User not found',
          emailAlreadyInUse: () => 'Email already in use',
          weakPassword: () => 'Weak password',
          tooManyRequests: () => 'Too many requests',
          sessionExpired: () => 'Session expired',
          passwordResetEmailSent: () => 'Email sent',
        );
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $message')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preferences saved.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SettingsSectionLabel(text: 'Personalization'),
        SettingsCard(
          children: <Widget>[
            ProfileNavRow(
              icon: Icons.accessibility_new_rounded,
              title: 'Accessibility',
              subtitle: 'Contrast, motion, and display comfort.',
              onTap: _openAccessibility,
            ),
            const SettingsDivider(),
            ProfileNavRow(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy',
              subtitle: 'Analytics consent and data preferences.',
              onTap: _openPrivacy,
            ),
          ],
        ),
      ],
    );
  }
}
