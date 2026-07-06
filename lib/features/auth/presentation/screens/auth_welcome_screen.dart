import 'package:flutter/material.dart';

import '../widgets/auth_drag_handle.dart';
import '../widgets/auth_screen_shell.dart';
import '../widgets/auth_sheet.dart';
import '../widgets/auth_sheet_headline.dart';
import '../widgets/login_hero.dart';
import '../widgets/primary_auth_option_button.dart';
import '../widgets/secondary_auth_option_button.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class AuthWelcomeScreen extends StatelessWidget {
  const AuthWelcomeScreen({super.key});

  void _openSignIn(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const SignInScreen(),
      ),
    );
  }

  void _openSignUp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const SignUpScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      heroFraction: 0.52,
      hero: const LoginHero(showBackButton: false, showLanguageToggle: true),
      sheet: AuthSheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const AuthDragHandle(),
            const SizedBox(height: 10),
            const AuthSheetHeadline(
              title: 'Kudlit',
              subtitle:
                  'Read Baybayin, practice kudlit marks, and keep your '
                  'learning progress ready for every session.',
            ),
            const SizedBox(height: 32),
            PrimaryAuthOptionButton(
              label: 'Create account',
              icon: Icons.person_add_rounded,
              onTap: () => _openSignUp(context),
            ),
            const SizedBox(height: 12),
            SecondaryAuthOptionButton(
              label: 'Sign in',
              icon: Icons.login_rounded,
              onTap: () => _openSignIn(context),
            ),
          ],
        ),
      ),
    );
  }
}
