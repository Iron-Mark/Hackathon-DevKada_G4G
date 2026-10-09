// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supabaseClient)
final supabaseClientProvider = SupabaseClientProvider._();

final class SupabaseClientProvider
    extends $FunctionalProvider<SupabaseClient, SupabaseClient, SupabaseClient>
    with $Provider<SupabaseClient> {
  SupabaseClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseClientProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseClientHash();

  @$internal
  @override
  $ProviderElement<SupabaseClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseClient create(Ref ref) {
    return supabaseClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseClient>(value),
    );
  }
}

String _$supabaseClientHash() => r'de6240783d7dddb57e07d034deb0ddf8e2fcc3e4';

@ProviderFor(supabaseAuthDatasource)
final supabaseAuthDatasourceProvider = SupabaseAuthDatasourceProvider._();

final class SupabaseAuthDatasourceProvider
    extends
        $FunctionalProvider<
          SupabaseAuthDatasource,
          SupabaseAuthDatasource,
          SupabaseAuthDatasource
        >
    with $Provider<SupabaseAuthDatasource> {
  SupabaseAuthDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseAuthDatasourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseAuthDatasourceHash();

  @$internal
  @override
  $ProviderElement<SupabaseAuthDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SupabaseAuthDatasource create(Ref ref) {
    return supabaseAuthDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseAuthDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseAuthDatasource>(value),
    );
  }
}

String _$supabaseAuthDatasourceHash() =>
    r'5a1d3fea329bdc9109688a402252eae3cc24afd5';

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'b0388b99144dd641bfb8bb0f229a6c5b4a46e0cc';

@ProviderFor(signInWithEmail)
final signInWithEmailProvider = SignInWithEmailProvider._();

final class SignInWithEmailProvider
    extends
        $FunctionalProvider<SignInWithEmail, SignInWithEmail, SignInWithEmail>
    with $Provider<SignInWithEmail> {
  SignInWithEmailProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInWithEmailProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInWithEmailHash();

  @$internal
  @override
  $ProviderElement<SignInWithEmail> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignInWithEmail create(Ref ref) {
    return signInWithEmail(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignInWithEmail value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignInWithEmail>(value),
    );
  }
}

String _$signInWithEmailHash() => r'10c3dcfa5bcfafcc21056691bd92486f58e7aa3b';

@ProviderFor(signUpWithEmail)
final signUpWithEmailProvider = SignUpWithEmailProvider._();

final class SignUpWithEmailProvider
    extends
        $FunctionalProvider<SignUpWithEmail, SignUpWithEmail, SignUpWithEmail>
    with $Provider<SignUpWithEmail> {
  SignUpWithEmailProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signUpWithEmailProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signUpWithEmailHash();

  @$internal
  @override
  $ProviderElement<SignUpWithEmail> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignUpWithEmail create(Ref ref) {
    return signUpWithEmail(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignUpWithEmail value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignUpWithEmail>(value),
    );
  }
}

String _$signUpWithEmailHash() => r'043ba52f93860ffdb09536b33d9e02ab9ff53ded';

@ProviderFor(signOut)
final signOutProvider = SignOutProvider._();

final class SignOutProvider
    extends $FunctionalProvider<SignOut, SignOut, SignOut>
    with $Provider<SignOut> {
  SignOutProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signOutProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signOutHash();

  @$internal
  @override
  $ProviderElement<SignOut> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignOut create(Ref ref) {
    return signOut(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignOut value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignOut>(value),
    );
  }
}

String _$signOutHash() => r'10456630b32ae1cfab6e5b6295f6bb2e2b1ac376';

@ProviderFor(resetPassword)
final resetPasswordProvider = ResetPasswordProvider._();

final class ResetPasswordProvider
    extends $FunctionalProvider<ResetPassword, ResetPassword, ResetPassword>
    with $Provider<ResetPassword> {
  ResetPasswordProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resetPasswordProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resetPasswordHash();

  @$internal
  @override
  $ProviderElement<ResetPassword> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ResetPassword create(Ref ref) {
    return resetPassword(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResetPassword value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResetPassword>(value),
    );
  }
}

String _$resetPasswordHash() => r'1b68bed78b5e67512878b58b29ee08ded4112255';
