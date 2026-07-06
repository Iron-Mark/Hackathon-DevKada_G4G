import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:kudlit_ph/app/constants.dart';
import 'package:kudlit_ph/core/design_system/kudlit_colors.dart';
import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/features/auth/presentation/providers/auth_notifier.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_drag_handle.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_sheet.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_sheet_headline.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/auth_text_link.dart';
import 'package:kudlit_ph/features/auth/presentation/widgets/login_hero.dart';

/// OTP verification screen. Receives the [phoneNumber] the code was sent to.
/// Renders 6 individual digit boxes that auto-advance focus on input.
class PhoneOtpScreen extends ConsumerStatefulWidget {
  const PhoneOtpScreen({required this.phoneNumber, super.key});

  final String phoneNumber;

  @override
  ConsumerState<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends ConsumerState<PhoneOtpScreen> {
  static const int _length = 6;
  static const int _resendCooldownSeconds = 30;
  static const int _maxVerifyAttempts = 5;
  static const int _lockoutSeconds = 60;

  final List<TextEditingController> _controllers =
      List<TextEditingController>.generate(
        _length,
        (_) => TextEditingController(),
      );
  final List<FocusNode> _focusNodes = List<FocusNode>.generate(
    _length,
    (_) => FocusNode(),
  );

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _resendMessage;
  int _resendCooldown = 0;
  int _failedAttempts = 0;
  int _lockoutCountdown = 0;
  Timer? _resendTimer;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    // OTP was requested by the previous screen — start the cooldown
    // immediately so the user cannot hammer "Resend" right away.
    _startResendCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _lockoutTimer?.cancel();
    for (final TextEditingController c in _controllers) {
      c.dispose();
    }
    for (final FocusNode f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp =>
      _controllers.map((TextEditingController c) => c.text).join();

  bool get _isComplete => _otp.length == _length;
  bool get _hasError => _errorMessage != null;
  bool get _isLockedOut => _lockoutCountdown > 0;

  String _mapFailure(Failure failure) => failure.when(
    network: (String msg) => '${AppConstants.networkErrorPrefix}$msg',
    tooManyRequests: () => AppConstants.tooManyRequestsMessage,
    invalidCredentials: () => 'Incorrect or expired code. Please try again.',
    unknown: (String msg) => msg,
    emailAlreadyInUse: () => AppConstants.unexpectedError,
    weakPassword: () => AppConstants.unexpectedError,
    userNotFound: () => AppConstants.unexpectedError,
    sessionExpired: () => AppConstants.unexpectedError,
    passwordResetEmailSent: () => AppConstants.unexpectedError,
  );

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendCooldown = _resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        t.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  void _startLockout() {
    _lockoutTimer?.cancel();
    setState(() {
      _lockoutCountdown = _lockoutSeconds;
      _errorMessage =
          'Too many incorrect attempts. Try again in ${_lockoutSeconds}s.';
    });
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_lockoutCountdown <= 1) {
        t.cancel();
        setState(() {
          _lockoutCountdown = 0;
          _failedAttempts = 0;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _lockoutCountdown -= 1;
          _errorMessage =
              'Too many incorrect attempts. Try again in ${_lockoutCountdown}s.';
        });
      }
    });
  }

  void _onDigitChanged(int index, String value) {
    if (_errorMessage != null || _resendMessage != null) {
      setState(() {
        if (!_isLockedOut) _errorMessage = null;
        _resendMessage = null;
      });
    }
    if (value.isEmpty) {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      return;
    }
    if (index < _length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
    // Do not auto-submit when locked out — user must wait for backoff.
    if (_isComplete && !_isLockedOut) _submit();
  }

  Future<void> _submit() async {
    if (!_isComplete || _isLoading || _isLockedOut) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resendMessage = null;
    });
    final Either<Failure, Unit> result = await ref
        .read(authNotifierProvider.notifier)
        .verifyPhoneOtp(phoneNumber: widget.phoneNumber, token: _otp);

    if (!mounted) return;
    result.fold(
      (Failure failure) {
        _failedAttempts += 1;
        if (_failedAttempts >= _maxVerifyAttempts) {
          setState(() => _isLoading = false);
          _startLockout();
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = _mapFailure(failure);
          });
        }
      },
      (_) {
        setState(() {
          _isLoading = false;
          _failedAttempts = 0;
        });
        final NavigatorState navigator = Navigator.of(context);
        while (navigator.canPop()) {
          navigator.pop();
        }
      },
    );
  }

  void _clearOtpFields() {
    for (final TextEditingController c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  Future<void> _resendCode() async {
    if (_isResending || _isLoading || _resendCooldown > 0) return;
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _resendMessage = null;
    });

    final Either<Failure, Unit> result = await ref
        .read(authNotifierProvider.notifier)
        .sendPhoneOtp(phoneNumber: widget.phoneNumber);

    if (!mounted) return;
    result.fold(
      (Failure failure) {
        setState(() {
          _isResending = false;
          _errorMessage = _mapFailure(failure);
        });
      },
      (_) {
        _clearOtpFields();
        setState(() {
          _isResending = false;
          _resendMessage = 'A new code was sent.';
        });
        _startResendCooldown();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String maskedNumber = _maskPhone(widget.phoneNumber);

    return AuthScreenShell(
      heroFraction: 0.38,
      hero: const LoginHero(
        buttyAsset: 'assets/brand/ButtyTextBubble.webp',
        bubbleText: 'Check your phone!',
        showBackButton: true,
        showLanguageToggle: false,
      ),
      sheet: AuthSheet(
        child: _OtpSheetBody(
          maskedNumber: maskedNumber,
          controllers: _controllers,
          focusNodes: _focusNodes,
          hasError: _hasError,
          errorMessage: _errorMessage,
          isLoading: _isLoading,
          isResending: _isResending,
          isLockedOut: _isLockedOut,
          resendMessage: _resendMessage,
          resendCooldown: _resendCooldown,
          onDigitChanged: _onDigitChanged,
          onSubmit: _submit,
          onResend: _resendCode,
        ),
      ),
    );
  }

  /// Masks all but the last 4 digits: +63 917 *** 3456
  static String _maskPhone(String phone) {
    if (phone.length <= 4) return phone;
    final String last4 = phone.substring(phone.length - 4);
    final String prefix = phone.substring(0, phone.length - 7);
    return '$prefix *** $last4';
  }
}

class _OtpSheetBody extends StatelessWidget {
  const _OtpSheetBody({
    required this.maskedNumber,
    required this.controllers,
    required this.focusNodes,
    required this.hasError,
    required this.errorMessage,
    required this.isLoading,
    required this.isResending,
    required this.isLockedOut,
    required this.resendMessage,
    required this.resendCooldown,
    required this.onDigitChanged,
    required this.onSubmit,
    required this.onResend,
  });

  final String maskedNumber;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool hasError;
  final String? errorMessage;
  final bool isLoading;
  final bool isResending;
  final bool isLockedOut;
  final String? resendMessage;
  final int resendCooldown;
  final void Function(int index, String value) onDigitChanged;
  final VoidCallback onSubmit;
  final Future<void> Function() onResend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AuthDragHandle(),
        const SizedBox(height: 10),
        AuthSheetHeadline(
          title: 'Enter the code',
          subtitle: 'Sent to $maskedNumber',
        ),
        const SizedBox(height: 24),
        _OtpRow(
          controllers: controllers,
          focusNodes: focusNodes,
          hasError: hasError,
          onChanged: onDigitChanged,
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
        const SizedBox(height: 24),
        AuthSubmitButton(
          label: 'Verify',
          isLoading: isLoading,
          onTap: isLockedOut ? () {} : onSubmit,
        ),
        if (resendMessage != null) ...<Widget>[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              resendMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _ResendRow(
          cooldown: resendCooldown,
          isResending: isResending,
          onResend: onResend,
        ),
      ],
    );
  }
}

class _OtpRow extends StatelessWidget {
  const _OtpRow({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    this.hasError = false,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool hasError;
  final void Function(int index, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 8,
      children: List<Widget>.generate(controllers.length, (int i) {
        return _OtpBox(
          index: i,
          controller: controllers[i],
          focusNode: focusNodes[i],
          hasError: hasError,
          onChanged: (String v) => onChanged(i, v),
        );
      }),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    this.hasError = false,
  });

  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color borderColor = hasError ? KudlitColors.danger400 : cs.primary;

    return Semantics(
      textField: true,
      label: 'OTP digit ${index + 1}',
      child: SizedBox(
        width: 44,
        height: 54,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          onChanged: onChanged,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
            height: 1,
          ),
          decoration: _otpDecoration(cs: cs, borderColor: borderColor),
        ),
      ),
    );
  }

  InputDecoration _otpDecoration({
    required ColorScheme cs,
    required Color borderColor,
  }) {
    return InputDecoration(
      counterText: '',
      contentPadding: EdgeInsets.zero,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: borderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: KudlitColors.danger400, width: 1.5),
      ),
      filled: true,
      fillColor: cs.surface,
    );
  }
}

class _ResendRow extends StatelessWidget {
  const _ResendRow({
    required this.onResend,
    this.cooldown = 0,
    this.isResending = false,
  });

  final Future<void> Function() onResend;
  final int cooldown;
  final bool isResending;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: <Widget>[
        Text(
          'Didn\'t get a code?',
          style: TextStyle(fontSize: 12.5, color: cs.onSurface.withAlpha(185)),
        ),
        if (isResending)
          Text(
            'Sending...',
            style: TextStyle(
              fontSize: 12.5,
              color: cs.onSurface.withAlpha(150),
            ),
          )
        else if (cooldown > 0)
          Text(
            'Resend in ${cooldown}s',
            style: TextStyle(
              fontSize: 12.5,
              color: cs.onSurface.withAlpha(150),
            ),
          )
        else
          AuthTextLink(label: 'Resend code', onTap: () => onResend()),
      ],
    );
  }
}
