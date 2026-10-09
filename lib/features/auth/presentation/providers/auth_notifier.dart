import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/core/usecases/usecase.dart';
import 'package:kudlit_ph/features/auth/domain/entities/auth_user.dart';
import 'package:kudlit_ph/features/auth/domain/entities/sign_up_status.dart';
import 'package:kudlit_ph/features/auth/domain/repositories/auth_repository.dart';
import 'package:kudlit_ph/features/auth/domain/usecases/reset_password.dart';
import 'package:kudlit_ph/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:kudlit_ph/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:kudlit_ph/features/auth/domain/usecases/send_phone_otp.dart';
import 'package:kudlit_ph/features/auth/domain/usecases/sign_out.dart';
import 'package:kudlit_ph/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:kudlit_ph/features/auth/domain/usecases/verify_phone_otp.dart';
import 'package:kudlit_ph/features/auth/presentation/providers/auth_provider.dart';

part 'auth_notifier.g.dart';

@Riverpod(keepAlive: true, name: 'authNotifierProvider')
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<AuthUser?> build() {
    final AuthRepository repository = ref.watch(authRepositoryProvider);

    final StreamSubscription<AuthUser?> sub = repository.authStateChanges
        .listen(
          (AuthUser? user) => state = AsyncData(user),
          onError: (Object error, StackTrace stack) =>
              state = AsyncError(error, stack),
        );

    ref.onDispose(sub.cancel);

    // After Supabase.initialize(), setInitialSession() has already populated
    // currentUser synchronously. The async wrapper gives the router an
    // AsyncLoading window so it never fires a premature redirect.
    return Future.value(repository.currentUser);
  }

  Future<Either<Failure, AuthUser>> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final SignInWithEmail useCase = ref.read(signInWithEmailProvider);
    final Either<Failure, AuthUser> result = await useCase(
      SignInWithEmailParams(email: email, password: password),
    );
    result.fold(
      (Failure failure) => state = AsyncError(failure, StackTrace.current),
      (AuthUser user) => state = AsyncData(user),
    );
    return result;
  }

  Future<Either<Failure, Unit>> signInWithGoogle() async {
    final AuthRepository repository = ref.read(authRepositoryProvider);
    final SignInWithGoogle useCase = SignInWithGoogle(repository);
    return useCase(const NoParams());
  }

  Future<Either<Failure, Unit>> sendPhoneOtp({
    required String phoneNumber,
  }) async {
    final AuthRepository repository = ref.read(authRepositoryProvider);
    final SendPhoneOtp useCase = SendPhoneOtp(repository);
    return useCase(SendPhoneOtpParams(phoneNumber: phoneNumber));
  }

  Future<Either<Failure, Unit>> verifyPhoneOtp({
    required String phoneNumber,
    required String token,
  }) async {
    final AuthRepository repository = ref.read(authRepositoryProvider);
    final VerifyPhoneOtp useCase = VerifyPhoneOtp(repository);
    return useCase(
      VerifyPhoneOtpParams(phoneNumber: phoneNumber, token: token),
    );
  }

  Future<Either<Failure, SignUpStatus>> signUp({
    required String email,
    required String password,
  }) async {
    final SignUpWithEmail useCase = ref.read(signUpWithEmailProvider);
    return useCase(SignUpWithEmailParams(email: email, password: password));
  }

  Future<void> signOut() async {
    state = const AsyncLoading<AuthUser?>();
    final SignOut useCase = ref.read(signOutProvider);
    await useCase(const NoParams());
    // Auth stream emits null and updates state automatically via listener
  }

  Future<Either<Failure, Unit>> resetPassword({required String email}) async {
    final ResetPassword useCase = ref.read(resetPasswordProvider);
    return useCase(ResetPasswordParams(email: email));
  }
}
