# Auth Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update the Kudlit app's authentication screens to consistently utilize the Kudlit Design System, removing redundant UI elements and establishing a unified, responsive layout.

**Architecture:** Component-driven refactoring within the `auth/presentation` layer. Extract shared widgets (`AuthFooterAction`, `AuthErrorBanner`) and rely on `KudlitAuthShell` for the responsive hero layout. Unused files will be removed.

**Tech Stack:** Flutter, Riverpod, Kudlit Design System

---

### Task 1: Clean Up Obsolete Files

**Files:**
- Delete: `lib/features/auth/presentation/screens/sign_in_screen.dart`
- Delete: `lib/features/auth/presentation/widgets/auth_form_scaffold.dart`
- Delete: `lib/features/auth/presentation/widgets/auth_header.dart`

- [ ] **Step 1: Delete unused files**

Run:
```bash
rm lib/features/auth/presentation/screens/sign_in_screen.dart
rm lib/features/auth/presentation/widgets/auth_form_scaffold.dart
rm lib/features/auth/presentation/widgets/auth_header.dart
```

- [ ] **Step 2: Commit**

Run:
```bash
git add lib/features/auth/presentation/screens/sign_in_screen.dart lib/features/auth/presentation/widgets/auth_form_scaffold.dart lib/features/auth/presentation/widgets/auth_header.dart
git commit -m "refactor: remove obsolete auth UI components"
```

---

### Task 2: Create Shared Auth Widgets

**Files:**
- Create: `lib/features/auth/presentation/widgets/auth_footer_action.dart`
- Create: `lib/features/auth/presentation/widgets/auth_error_banner.dart`

- [ ] **Step 1: Create AuthErrorBanner**

Create `lib/features/auth/presentation/widgets/auth_error_banner.dart`:

```dart
import 'package:flutter/material.dart';

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.error),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create AuthFooterAction**

Create `lib/features/auth/presentation/widgets/auth_footer_action.dart`:

```dart
import 'package:flutter/material.dart';

class AuthFooterAction extends StatelessWidget {
  const AuthFooterAction({
    required this.prompt,
    required this.actionLabel,
    required this.onPressed,
    super.key,
  });

  final String prompt;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: <Widget>[
        Text(
          prompt,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: onPressed,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Verify formatting and analyze**

Run: `dart format lib/features/auth/presentation/widgets/auth_error_banner.dart lib/features/auth/presentation/widgets/auth_footer_action.dart`
Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 4: Commit**

Run:
```bash
git add lib/features/auth/presentation/widgets/auth_error_banner.dart lib/features/auth/presentation/widgets/auth_footer_action.dart
git commit -m "feat: add shared AuthErrorBanner and AuthFooterAction widgets"
```

---

### Task 3: Refactor LoginFormBody

**Files:**
- Modify: `lib/features/auth/presentation/widgets/login_form_body.dart`

- [ ] **Step 1: Simplify LoginFormBody**

Update `lib/features/auth/presentation/widgets/login_form_body.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kudlit_ph/app/constants.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_button.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_footer_action.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/email_field.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/password_field.dart';

class LoginFormBody extends StatelessWidget {
  const LoginFormBody({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSignIn,
    this.errorMessage,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSignIn;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        EmailField(controller: emailController),
        const SizedBox(height: 16),
        PasswordField(controller: passwordController),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push(AppConstants.routeForgotPassword),
            child: const Text(AppConstants.forgotPasswordAction),
          ),
        ),
        if (errorMessage != null) AuthErrorBanner(message: errorMessage!),
        const SizedBox(height: 16),
        AuthButton(
          label: AppConstants.loginAction,
          isLoading: isLoading,
          onPressed: onSignIn,
        ),
        const SizedBox(height: 16),
        AuthFooterAction(
          prompt: AppConstants.noAccountPrompt,
          actionLabel: AppConstants.createOneAction,
          onPressed: () => context.push(AppConstants.routeSignUp),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify formatting and analyze**

Run: `dart format lib/features/auth/presentation/widgets/login_form_body.dart`
Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 3: Commit**

Run:
```bash
git add lib/features/auth/presentation/widgets/login_form_body.dart
git commit -m "refactor: simplify LoginFormBody, use shared error and footer widgets"
```

---

### Task 4: Refactor SignUpFormBody

**Files:**
- Modify: `lib/features/auth/presentation/widgets/sign_up_form_body.dart`

- [ ] **Step 1: Simplify SignUpFormBody**

Update `lib/features/auth/presentation/widgets/sign_up_form_body.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kudlit_ph/app/constants.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_button.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_footer_action.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/confirm_password_field.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/email_field.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/password_field.dart';

class SignUpFormBody extends StatelessWidget {
  const SignUpFormBody({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.isLoading,
    required this.onSignUp,
    required this.validateEmail,
    required this.validatePassword,
    required this.validateConfirm,
    this.errorMessage,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool isLoading;
  final VoidCallback onSignUp;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;
  final String? Function(String?) validateConfirm;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        EmailField(controller: emailController, validator: validateEmail),
        const SizedBox(height: 16),
        PasswordField(
          controller: passwordController,
          validator: validatePassword,
        ),
        const SizedBox(height: 16),
        ConfirmPasswordField(
          controller: confirmController,
          validator: validateConfirm,
        ),
        const SizedBox(height: 24),
        if (errorMessage != null) AuthErrorBanner(message: errorMessage!),
        AuthButton(
          label: AppConstants.signUpAction,
          isLoading: isLoading,
          onPressed: onSignUp,
        ),
        const SizedBox(height: 16),
        AuthFooterAction(
          prompt: AppConstants.existingAccountPrompt,
          actionLabel: AppConstants.loginAction,
          onPressed: () => context.go(AppConstants.routeLogin),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify formatting and analyze**

Run: `dart format lib/features/auth/presentation/widgets/sign_up_form_body.dart`
Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 3: Commit**

Run:
```bash
git add lib/features/auth/presentation/widgets/sign_up_form_body.dart
git commit -m "refactor: use shared error and footer widgets in SignUpFormBody"
```

---

### Task 5: Refactor ForgotPasswordScreen

**Files:**
- Modify: `lib/features/auth/presentation/screens/forgot_password_screen.dart`

- [ ] **Step 1: Refactor ForgotPasswordScreen**

Update `lib/features/auth/presentation/screens/forgot_password_screen.dart` to use `AuthErrorBanner` for errors (success message remains simple text for now, but aligned properly).

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:kudlit_ph/app/constants.dart';
import 'package:kudlit_ph/core/design_system/kudlit_colors.dart';
import 'package:kudlit_ph/core/design_system/widgets/kudlit_auth_shell.dart';
import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/features/auth/presentation/providers/auth_notifier.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_button.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/email_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _onReset() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final Either<Failure, Unit> result = await ref
        .read(authNotifierProvider.notifier)
        .resetPassword(email: _emailController.text.trim());

    result.fold(
      (Failure f) => setState(() {
        _isLoading = false;
        _isSuccess = false;
        _message = f.when(
          userNotFound: () => AppConstants.noAccountFoundMessage,
          tooManyRequests: () => AppConstants.tooManyRequestsMessage,
          network: (String msg) => '${AppConstants.networkErrorPrefix}$msg',
          unknown: (String msg) => msg,
          invalidCredentials: () => AppConstants.unexpectedError,
          emailAlreadyInUse: () => AppConstants.unexpectedError,
          weakPassword: () => AppConstants.unexpectedError,
          sessionExpired: () => AppConstants.unexpectedError,
          passwordResetEmailSent: () => AppConstants.unexpectedError,
        );
      }),
      (_) => setState(() {
        _isLoading = false;
        _isSuccess = true;
        _message = AppConstants.resetEmailSentSuccessMessage;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KudlitAuthShell(
      title: AppConstants.resetPasswordTitle,
      subtitle: AppConstants.resetPasswordSubtitle,
      heroAsset: 'assets/brand/ButtyTextBubble.webp',
      showBackButton: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          EmailField(controller: _emailController),
          const SizedBox(height: 24),
          if (_message != null && !_isSuccess) ...<Widget>[
            AuthErrorBanner(message: _message!),
          ],
          AuthButton(
            label: AppConstants.sendResetEmailAction,
            isLoading: _isLoading,
            onPressed: _onReset,
          ),
          if (_isSuccess && _message != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              _message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: KudlitColors.success400,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(AppConstants.routeLogin),
              child: const Text(AppConstants.backToLoginAction),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify formatting and analyze**

Run: `dart format lib/features/auth/presentation/screens/forgot_password_screen.dart`
Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 3: Commit**

Run:
```bash
git add lib/features/auth/presentation/screens/forgot_password_screen.dart
git commit -m "refactor: use shared error banner in ForgotPasswordScreen"
```