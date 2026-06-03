import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import 'package:kudlit_ph/core/auth/current_user_role_provider.dart';
import 'package:kudlit_ph/core/auth/user_role.dart';
import 'package:kudlit_ph/features/auth/domain/entities/auth_user.dart';
import 'package:kudlit_ph/features/auth/presentation/providers/auth_notifier.dart';
import 'package:kudlit_ph/features/home/presentation/providers/app_preferences_provider.dart';

class RouterListenable extends ChangeNotifier {
  RouterListenable(this._ref) {
    _ref.listen<AsyncValue<AuthUser?>>(
      authNotifierProvider,
      (previous, next) => notifyListeners(),
    );
    _ref.listen<AsyncValue<AppPreferences>>(
      appPreferencesNotifierProvider,
      (previous, next) => notifyListeners(),
    );
    _ref.listen<bool>(
      modelSetupSkippedProvider,
      (previous, next) => notifyListeners(),
    );
    _ref.listen<AsyncValue<UserRole>>(
      currentUserRoleProvider,
      (previous, next) => notifyListeners(),
    );

    // Listen for password-recovery deep-link events from Supabase. When the
    // user opens the reset email, `gotrue` establishes a session and fires
    // `AuthChangeEvent.passwordRecovery` — we flip the gate so the router
    // forces navigation to the dedicated reset screen.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
      (AuthState event) {
        if (event.event == AuthChangeEvent.passwordRecovery) {
          _passwordRecoveryPending = true;
          notifyListeners();
        }
      },
    );
  }

  final Ref _ref;
  StreamSubscription<AuthState>? _authSub;
  bool _passwordRecoveryPending = false;

  AsyncValue<AuthUser?> get authState => _ref.read(authNotifierProvider);
  AsyncValue<AppPreferences> get prefsState =>
      _ref.read(appPreferencesNotifierProvider);
  AsyncValue<UserRole> get roleState => _ref.read(currentUserRoleProvider);

  /// True when the user tapped "Not now" this session.
  /// Resets to false on every cold launch — setup screen shows again next time.
  bool get sessionSkipped => _ref.read(modelSetupSkippedProvider);

  /// True between the moment a recovery deep link establishes a session and
  /// the moment the user completes (or abandons) the password update.
  bool get passwordRecoveryPending => _passwordRecoveryPending;

  /// Called by the reset screen after the password is updated (or the user
  /// signs out) so the router stops forcing redirects to `/reset-password`.
  void clearPasswordRecoveryPending() {
    if (!_passwordRecoveryPending) return;
    _passwordRecoveryPending = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}

final routerListenableProvider = Provider<RouterListenable>(
  (ref) => RouterListenable(ref),
);
