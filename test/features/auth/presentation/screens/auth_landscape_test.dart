import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kudlit_ph/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:kudlit_ph/features/auth/presentation/screens/login_screen.dart';
import 'package:kudlit_ph/features/auth/presentation/screens/phone_otp_screen.dart';
import 'package:kudlit_ph/features/auth/presentation/screens/phone_sign_in_screen.dart';
import 'package:kudlit_ph/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:kudlit_ph/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:kudlit_ph/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_submit_button.dart';

void main() {
  Future<void> pumpLandscape(WidgetTester tester, Widget screen) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(ProviderScope(child: MaterialApp(home: screen)));
    await tester.pump();
  }

  testWidgets('welcome auth screen fits phone landscape', (tester) async {
    await pumpLandscape(tester, const LoginScreen());

    expect(find.text('Welcome, ka-Baybayin!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('email sign-in screen fits phone landscape', (tester) async {
    await pumpLandscape(tester, const SignInScreen());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('email sign-in phone option opens phone sign-in screen', (
    tester,
  ) async {
    await pumpLandscape(tester, const SignInScreen());

    await tester.tap(find.text('Continue with Phone Number'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in with phone'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-up screen fits phone landscape', (tester) async {
    await pumpLandscape(tester, const SignUpScreen());

    expect(find.text('Create account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-up submit remains reachable with landscape keyboard', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    addTearDown(() {
      tester.view.resetViewInsets();
      tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SignUpScreen())),
    );
    await tester.pump();

    final Finder submitButton = find.widgetWithText(
      AuthSubmitButton,
      'Create Account',
    );

    await tester.drag(
      find.byType(SingleChildScrollView).last,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    final Rect buttonRect = tester.getRect(submitButton);
    final double keyboardTop =
        tester.view.physicalSize.height / tester.view.devicePixelRatio -
        tester.view.viewInsets.bottom;

    expect(buttonRect.bottom, lessThanOrEqualTo(keyboardTop - 24));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'sign-up submit remains reachable when keyboard resizes viewport',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(844, 190);
      addTearDown(() {
        tester.view.resetDevicePixelRatio();
        tester.view.resetPhysicalSize();
      });

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SignUpScreen())),
      );
      await tester.pump();

      final Finder submitButton = find.widgetWithText(
        AuthSubmitButton,
        'Create Account',
      );

      await tester.drag(
        find.byType(SingleChildScrollView).last,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      final Rect buttonRect = tester.getRect(submitButton);

      expect(buttonRect.bottom, lessThanOrEqualTo(190 - 24));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('phone sign-in screen fits phone landscape', (tester) async {
    await pumpLandscape(tester, const PhoneSignInScreen());

    expect(find.text('Sign in with phone'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'phone OTP screen keeps digit boxes and resend action accessible',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await tester.binding.setSurfaceSize(const Size(360, 593));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PhoneOtpScreen(phoneNumber: '+639171234567'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Enter the code'), findsOneWidget);
      expect(find.textContaining('Resend in '), findsOneWidget);
      expect(find.bySemanticsLabel('OTP digit 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('phone OTP screen fits compact landscape', (
    WidgetTester tester,
  ) async {
    await pumpLandscape(
      tester,
      const PhoneOtpScreen(phoneNumber: '+639171234567'),
    );

    expect(find.text('Enter the code'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
    expect(find.textContaining('Resend in '), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('forgot password screen fits phone landscape', (tester) async {
    await pumpLandscape(tester, const ForgotPasswordScreen());

    expect(find.text('Reset Password'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reset password screen fits phone landscape', (tester) async {
    await pumpLandscape(tester, const ResetPasswordScreen());

    expect(find.text('Set a new password'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
