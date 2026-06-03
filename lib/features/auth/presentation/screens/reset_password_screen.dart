import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kudlit_ph/app/constants.dart';
import 'package:kudlit_ph/app/router/router_listenable.dart';
import 'package:kudlit_ph/core/design_system/kudlit_colors.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_drag_handle.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_sheet.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_sheet_headline.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/confirm_password_field.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/login_hero.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/password_field.dart';

/// Screen reached after the user taps the password-recovery deep link from
/// Supabase. The recovery session is already established by `gotrue`; this
/// screen forces the user to choose a new password before doing anything else
/// and signs them out on success so they re-authenticate with the new one.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) return AppConstants.passwordRequiredMessage;
    if (password.length < 6) return AppConstants.passwordTooShortMessage;
    return null;
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) {
      return AppConstants.confirmPasswordRequiredMessage;
    }
    if (value != _passwordController.text) {
      return AppConstants.passwordsDoNotMatchMessage;
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final SupabaseClient client = Supabase.instance.client;
      await client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );
      // Force a fresh sign-in with the new credentials. Clearing the
      // recovery flag here lets the router redirect to /login after signOut.
      ref.read(routerListenableProvider).clearPasswordRecoveryPending();
      await client.auth.signOut();

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _successMessage =
            'Password updated. Please sign in with your new password.';
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.message;
      });
    } on Exception catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = AppConstants.unexpectedError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      heroFraction: 0.38,
      hero: const LoginHero(
        buttyAsset: 'assets/brand/ButtyPhone.webp',
        bubbleText: 'Choose a new password',
        showBackButton: false,
        showLanguageToggle: false,
      ),
      sheet: AuthSheet(
        child: _ResetPasswordSheetBody(
          formKey: _formKey,
          passwordController: _passwordController,
          confirmController: _confirmController,
          validatePassword: _validatePassword,
          validateConfirm: _validateConfirm,
          isSubmitting: _isSubmitting,
          errorMessage: _errorMessage,
          successMessage: _successMessage,
          onSubmit: _submit,
        ),
      ),
    );
  }
}

class _ResetPasswordSheetBody extends StatelessWidget {
  const _ResetPasswordSheetBody({
    required this.formKey,
    required this.passwordController,
    required this.confirmController,
    required this.validatePassword,
    required this.validateConfirm,
    required this.isSubmitting,
    required this.errorMessage,
    required this.successMessage,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final String? Function(String?) validatePassword;
  final String? Function(String?) validateConfirm;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AuthDragHandle(),
        const SizedBox(height: 10),
        const AuthSheetHeadline(
          title: 'Set a new password',
          subtitle: 'You\'ll use this the next time you sign in.',
        ),
        const SizedBox(height: 20),
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              PasswordField(
                controller: passwordController,
                validator: validatePassword,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              ConfirmPasswordField(
                controller: confirmController,
                validator: validateConfirm,
              ),
            ],
          ),
        ),
        if (errorMessage != null) ...<Widget>[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: KudlitColors.danger400,
                fontSize: 12,
              ),
            ),
          ),
        ],
        if (successMessage != null) ...<Widget>[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              successMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        AuthSubmitButton(
          label: 'Update password',
          isLoading: isSubmitting,
          onTap: onSubmit,
        ),
      ],
    );
  }
}
