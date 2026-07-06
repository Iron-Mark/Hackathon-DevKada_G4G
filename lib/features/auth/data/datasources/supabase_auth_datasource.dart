import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kudlit_ph/core/error/exceptions.dart';
import 'package:kudlit_ph/features/auth/data/models/auth_user_model.dart';
import 'package:kudlit_ph/features/auth/domain/entities/sign_up_status.dart';

abstract interface class SupabaseAuthDatasource {
  Stream<AuthUserModel?> get authStateChanges;

  AuthUserModel? get currentUser;

  Future<AuthUserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signInWithGoogle();

  Future<void> sendPhoneOtp({required String phoneNumber});

  Future<void> verifyPhoneOtp({
    required String phoneNumber,
    required String token,
  });

  Future<SignUpStatus> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> resetPassword({required String email});
}

class SupabaseAuthDatasourceImpl implements SupabaseAuthDatasource {
  const SupabaseAuthDatasourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Stream<AuthUserModel?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((AuthState event) {
      final User? user = event.session?.user;
      if (user == null) return null;
      return AuthUserModel.fromSupabaseUser(user);
    });
  }

  @override
  AuthUserModel? get currentUser {
    final User? user = _client.auth.currentUser;
    if (user == null) return null;
    return AuthUserModel.fromSupabaseUser(user);
  }

  @override
  Future<AuthUserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final User? user = response.user;
      if (user == null) {
        throw const ServerException(message: 'Sign in returned no user.');
      }
      return AuthUserModel.fromSupabaseUser(user);
    } on AuthException catch (e) {
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.statusCode ?? ''),
      );
    } on Exception catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      final String redirectTo = kIsWeb
          ? '${Uri.base.origin}/auth/reset'
          : 'kudlit://auth/reset';
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        queryParams: <String, String>{'prompt': 'select_account'},
      );
    } on AuthException catch (e) {
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.statusCode ?? ''),
      );
    } on Exception catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> sendPhoneOtp({required String phoneNumber}) async {
    try {
      await _client.auth.signInWithOtp(phone: phoneNumber);
    } on AuthException catch (e) {
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.statusCode ?? ''),
      );
    } on Exception catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> verifyPhoneOtp({
    required String phoneNumber,
    required String token,
  }) async {
    try {
      await _client.auth.verifyOTP(
        phone: phoneNumber,
        token: token,
        type: OtpType.sms,
      );
    } on AuthException catch (e) {
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.statusCode ?? ''),
      );
    } on Exception catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<SignUpStatus> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      if (response.user == null) {
        throw const ServerException(message: 'Sign up returned no user.');
      }
      return response.session == null
          ? SignUpStatus.confirmationPending
          : SignUpStatus.autoConfirmed;
    } on AuthException catch (e) {
      throw ServerException(
        message: e.message,
        statusCode: int.tryParse(e.statusCode ?? ''),
      );
    } on Exception catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      // On web, route the user back to the in-app `/auth/reset` handler.
      // On native, use the deep link so the OS re-opens Kudlit directly.
      final String redirectTo = kIsWeb
          ? '${Uri.base.origin}/auth/reset'
          : 'kudlit://auth/reset';
      await _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
    } on AuthException catch (e) {
      throw ServerException(message: e.message);
    }
  }
}
