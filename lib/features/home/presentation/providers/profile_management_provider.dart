import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/core/usecases/usecase.dart';
import 'package:kudlit_ph/features/home/data/datasources/local_profile_management_datasource.dart';
import 'package:kudlit_ph/features/home/data/datasources/profile_management_datasource.dart';
import 'package:kudlit_ph/features/home/data/repositories/profile_management_repository_impl.dart';
import 'package:kudlit_ph/features/home/domain/entities/profile_preferences.dart';
import 'package:kudlit_ph/features/home/domain/entities/profile_summary.dart';
import 'package:kudlit_ph/features/home/domain/repositories/profile_management_repository.dart';
import 'package:kudlit_ph/features/home/domain/usecases/get_profile_preferences.dart';
import 'package:kudlit_ph/features/home/domain/usecases/get_profile_summary.dart';
import 'package:kudlit_ph/features/home/domain/usecases/save_profile_preferences.dart';
import 'package:kudlit_ph/features/home/domain/usecases/update_display_name.dart';

part 'profile_management_provider.g.dart';

@riverpod
SupabaseClient supabase(Ref ref) {
  return Supabase.instance.client;
}

@riverpod
ProfileManagementDatasource profileManagementDatasource(Ref ref) {
  return SupabaseProfileManagementDatasource(ref.watch(supabaseProvider));
}

@Riverpod(keepAlive: true)
LocalProfileManagementDatasource localProfileManagementDatasource(Ref ref) {
  final SqfliteProfileManagementDatasource ds =
      SqfliteProfileManagementDatasource();
  ref.onDispose(ds.dispose);
  return ds;
}

@riverpod
ProfileManagementRepository profileManagementRepository(Ref ref) {
  return ProfileManagementRepositoryImpl(
    ref.watch(profileManagementDatasourceProvider),
    ref.watch(localProfileManagementDatasourceProvider),
  );
}

@riverpod
GetProfileSummary getProfileSummaryUseCase(Ref ref) {
  return GetProfileSummary(ref.watch(profileManagementRepositoryProvider));
}

@riverpod
GetProfilePreferences getProfilePreferencesUseCase(Ref ref) {
  return GetProfilePreferences(ref.watch(profileManagementRepositoryProvider));
}

@riverpod
UpdateDisplayName updateDisplayNameUseCase(Ref ref) {
  return UpdateDisplayName(ref.watch(profileManagementRepositoryProvider));
}

@riverpod
SaveProfilePreferences saveProfilePreferencesUseCase(Ref ref) {
  return SaveProfilePreferences(ref.watch(profileManagementRepositoryProvider));
}

@riverpod
class ProfileSummaryNotifier extends _$ProfileSummaryNotifier {
  @override
  FutureOr<Option<ProfileSummary>> build() async {
    return _fetchSummary();
  }

  Future<Option<ProfileSummary>> _fetchSummary() async {
    final useCase = ref.read(getProfileSummaryUseCaseProvider);
    final result = await useCase(const NoParams());
    return result.fold((l) => const None(), (r) => Some(r));
  }

  /// Clears the local summary cache and re-fetches fresh counts from Supabase.
  /// Call this after any write that changes profile stats (lesson complete,
  /// new scan, new translation).
  Future<void> refresh() async {
    final String? userId = ref
        .read(profileManagementDatasourceProvider)
        .getCurrentUserId();
    if (userId != null) {
      try {
        await ref
            .read(localProfileManagementDatasourceProvider)
            .clearCachedSummary(userId: userId);
      } catch (_) {}
    }
    // The provider can be disposed while the awaits above are in flight
    // (e.g. the profile screen is popped). Touching `state` after disposal
    // throws an unhandled exception, so bail out if we're no longer mounted.
    if (!ref.mounted) return;
    state = const AsyncLoading<Option<ProfileSummary>>();
    final Option<ProfileSummary> summary = await _fetchSummary();
    if (!ref.mounted) return;
    state = AsyncValue<Option<ProfileSummary>>.data(summary);
  }

  Future<void> updateDisplayName(String displayName) async {
    state = AsyncValue.data(state.value ?? const None());

    final useCase = ref.read(updateDisplayNameUseCaseProvider);
    final result = await useCase(
      UpdateDisplayNameParams(displayName: displayName),
    );

    if (!ref.mounted) return;
    if (result.isLeft()) {
      state = AsyncError<Option<ProfileSummary>>(
        result.getLeft().toNullable()!,
        StackTrace.current,
      );
      return;
    }

    final summary = await _fetchSummary();
    if (!ref.mounted) return;
    state = AsyncValue.data(summary);
  }

  Future<void> updateAvatar({
    required Uint8List bytes,
    required String fileName,
    required String? mimeType,
  }) async {
    final Option<ProfileSummary> previousSummary = state.value ?? const None();
    state = AsyncValue.data(previousSummary);

    final repository = ref.read(profileManagementRepositoryProvider);
    final result = await repository.updateAvatar(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );

    if (!ref.mounted) return;
    if (result.isLeft()) {
      final Failure failure = result.getLeft().toNullable()!;
      state = AsyncValue.data(previousSummary);
      throw Exception(_failureMessage(failure));
    }

    final summary = await _fetchSummary();
    if (!ref.mounted) return;
    state = AsyncValue.data(summary);
  }
}

String _failureMessage(Failure failure) {
  return switch (failure) {
    NetworkFailure(:final message) => message,
    UnknownFailure(:final message) => message,
    InvalidCredentialsFailure() => 'Invalid credentials.',
    UserNotFoundFailure() => 'User not found.',
    EmailAlreadyInUseFailure() => 'Email is already in use.',
    WeakPasswordFailure() => 'Weak password.',
    TooManyRequestsFailure() => 'Too many requests. Try again later.',
    SessionExpiredFailure() => 'Session expired. Sign in again.',
    PasswordResetEmailSentFailure() => 'Password reset email sent.',
  };
}

@riverpod
class ProfilePreferencesNotifier extends _$ProfilePreferencesNotifier {
  @override
  FutureOr<Option<ProfilePreferences>> build() async {
    return _fetchPreferences();
  }

  Future<Option<ProfilePreferences>> _fetchPreferences() async {
    final useCase = ref.read(getProfilePreferencesUseCaseProvider);
    final result = await useCase(const NoParams());
    return result.fold((l) => const None(), (r) => Some(r));
  }

  Future<void> updatePreferences(ProfilePreferences preferences) async {
    state = AsyncValue.data(state.value ?? const None());

    final useCase = ref.read(saveProfilePreferencesUseCaseProvider);
    final result = await useCase(
      SaveProfilePreferencesParams(preferences: preferences),
    );

    if (!ref.mounted) return;
    if (result.isLeft()) {
      state = AsyncError<Option<ProfilePreferences>>(
        result.getLeft().toNullable()!,
        StackTrace.current,
      );
      return;
    }

    final prefs = await _fetchPreferences();
    if (!ref.mounted) return;
    state = AsyncValue.data(prefs);
  }
}
