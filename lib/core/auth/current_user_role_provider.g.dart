// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_user_role_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches and caches the current user's [UserRole] from `public.profiles`.
///
/// Returns [UserRole.user] when the user is unauthenticated or when the row
/// has no `role` set.  Throws if the DB call fails so callers can show an
/// error state.

@ProviderFor(currentUserRole)
final currentUserRoleProvider = CurrentUserRoleProvider._();

/// Fetches and caches the current user's [UserRole] from `public.profiles`.
///
/// Returns [UserRole.user] when the user is unauthenticated or when the row
/// has no `role` set.  Throws if the DB call fails so callers can show an
/// error state.

final class CurrentUserRoleProvider
    extends
        $FunctionalProvider<AsyncValue<UserRole>, UserRole, FutureOr<UserRole>>
    with $FutureModifier<UserRole>, $FutureProvider<UserRole> {
  /// Fetches and caches the current user's [UserRole] from `public.profiles`.
  ///
  /// Returns [UserRole.user] when the user is unauthenticated or when the row
  /// has no `role` set.  Throws if the DB call fails so callers can show an
  /// error state.
  CurrentUserRoleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserRoleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserRoleHash();

  @$internal
  @override
  $FutureProviderElement<UserRole> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<UserRole> create(Ref ref) {
    return currentUserRole(ref);
  }
}

String _$currentUserRoleHash() => r'5376529c1354ca5b60da154ac4bc362901468e91';
