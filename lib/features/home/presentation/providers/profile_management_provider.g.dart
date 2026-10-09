// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_management_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supabase)
final supabaseProvider = SupabaseProvider._();

final class SupabaseProvider
    extends $FunctionalProvider<SupabaseClient, SupabaseClient, SupabaseClient>
    with $Provider<SupabaseClient> {
  SupabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseHash();

  @$internal
  @override
  $ProviderElement<SupabaseClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseClient create(Ref ref) {
    return supabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseClient>(value),
    );
  }
}

String _$supabaseHash() => r'6abeb04f6d303eb0dd323e0401492c39546c0428';

@ProviderFor(profileManagementDatasource)
final profileManagementDatasourceProvider =
    ProfileManagementDatasourceProvider._();

final class ProfileManagementDatasourceProvider
    extends
        $FunctionalProvider<
          ProfileManagementDatasource,
          ProfileManagementDatasource,
          ProfileManagementDatasource
        >
    with $Provider<ProfileManagementDatasource> {
  ProfileManagementDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileManagementDatasourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileManagementDatasourceHash();

  @$internal
  @override
  $ProviderElement<ProfileManagementDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileManagementDatasource create(Ref ref) {
    return profileManagementDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileManagementDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileManagementDatasource>(value),
    );
  }
}

String _$profileManagementDatasourceHash() =>
    r'1d95a2a7a6eae4b562e1164fae0e9a2c1014dbb5';

@ProviderFor(localProfileManagementDatasource)
final localProfileManagementDatasourceProvider =
    LocalProfileManagementDatasourceProvider._();

final class LocalProfileManagementDatasourceProvider
    extends
        $FunctionalProvider<
          LocalProfileManagementDatasource,
          LocalProfileManagementDatasource,
          LocalProfileManagementDatasource
        >
    with $Provider<LocalProfileManagementDatasource> {
  LocalProfileManagementDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localProfileManagementDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localProfileManagementDatasourceHash();

  @$internal
  @override
  $ProviderElement<LocalProfileManagementDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalProfileManagementDatasource create(Ref ref) {
    return localProfileManagementDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalProfileManagementDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalProfileManagementDatasource>(
        value,
      ),
    );
  }
}

String _$localProfileManagementDatasourceHash() =>
    r'3732f86521a9eb8a70cc4a88cbf91ff49638c978';

@ProviderFor(profileManagementRepository)
final profileManagementRepositoryProvider =
    ProfileManagementRepositoryProvider._();

final class ProfileManagementRepositoryProvider
    extends
        $FunctionalProvider<
          ProfileManagementRepository,
          ProfileManagementRepository,
          ProfileManagementRepository
        >
    with $Provider<ProfileManagementRepository> {
  ProfileManagementRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileManagementRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileManagementRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileManagementRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProfileManagementRepository create(Ref ref) {
    return profileManagementRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileManagementRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProfileManagementRepository>(value),
    );
  }
}

String _$profileManagementRepositoryHash() =>
    r'82052fa2509d59d8b7e6bb0d0f148d63ec1ccb45';

@ProviderFor(getProfileSummaryUseCase)
final getProfileSummaryUseCaseProvider = GetProfileSummaryUseCaseProvider._();

final class GetProfileSummaryUseCaseProvider
    extends
        $FunctionalProvider<
          GetProfileSummary,
          GetProfileSummary,
          GetProfileSummary
        >
    with $Provider<GetProfileSummary> {
  GetProfileSummaryUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getProfileSummaryUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getProfileSummaryUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetProfileSummary> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetProfileSummary create(Ref ref) {
    return getProfileSummaryUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetProfileSummary value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetProfileSummary>(value),
    );
  }
}

String _$getProfileSummaryUseCaseHash() =>
    r'bbb50ca5d0b904165005ea4ad568beedfceb8b9a';

@ProviderFor(getProfilePreferencesUseCase)
final getProfilePreferencesUseCaseProvider =
    GetProfilePreferencesUseCaseProvider._();

final class GetProfilePreferencesUseCaseProvider
    extends
        $FunctionalProvider<
          GetProfilePreferences,
          GetProfilePreferences,
          GetProfilePreferences
        >
    with $Provider<GetProfilePreferences> {
  GetProfilePreferencesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getProfilePreferencesUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getProfilePreferencesUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetProfilePreferences> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetProfilePreferences create(Ref ref) {
    return getProfilePreferencesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetProfilePreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetProfilePreferences>(value),
    );
  }
}

String _$getProfilePreferencesUseCaseHash() =>
    r'a96b77869599dcd1456af0d2b1a4e45c28a2067d';

@ProviderFor(updateDisplayNameUseCase)
final updateDisplayNameUseCaseProvider = UpdateDisplayNameUseCaseProvider._();

final class UpdateDisplayNameUseCaseProvider
    extends
        $FunctionalProvider<
          UpdateDisplayName,
          UpdateDisplayName,
          UpdateDisplayName
        >
    with $Provider<UpdateDisplayName> {
  UpdateDisplayNameUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateDisplayNameUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateDisplayNameUseCaseHash();

  @$internal
  @override
  $ProviderElement<UpdateDisplayName> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UpdateDisplayName create(Ref ref) {
    return updateDisplayNameUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateDisplayName value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateDisplayName>(value),
    );
  }
}

String _$updateDisplayNameUseCaseHash() =>
    r'bf5d68bc9e8004d1053a3c789278d7bb0cb59b33';

@ProviderFor(saveProfilePreferencesUseCase)
final saveProfilePreferencesUseCaseProvider =
    SaveProfilePreferencesUseCaseProvider._();

final class SaveProfilePreferencesUseCaseProvider
    extends
        $FunctionalProvider<
          SaveProfilePreferences,
          SaveProfilePreferences,
          SaveProfilePreferences
        >
    with $Provider<SaveProfilePreferences> {
  SaveProfilePreferencesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saveProfilePreferencesUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saveProfilePreferencesUseCaseHash();

  @$internal
  @override
  $ProviderElement<SaveProfilePreferences> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SaveProfilePreferences create(Ref ref) {
    return saveProfilePreferencesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SaveProfilePreferences value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SaveProfilePreferences>(value),
    );
  }
}

String _$saveProfilePreferencesUseCaseHash() =>
    r'914b1bc150b6638d83b992da7823714090b9e2c3';

@ProviderFor(ProfileSummaryNotifier)
final profileSummaryNotifierProvider = ProfileSummaryNotifierProvider._();

final class ProfileSummaryNotifierProvider
    extends
        $AsyncNotifierProvider<ProfileSummaryNotifier, Option<ProfileSummary>> {
  ProfileSummaryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileSummaryNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileSummaryNotifierHash();

  @$internal
  @override
  ProfileSummaryNotifier create() => ProfileSummaryNotifier();
}

String _$profileSummaryNotifierHash() =>
    r'a2c8854cea12f2d518b5c68085610ee33df7f3de';

abstract class _$ProfileSummaryNotifier
    extends $AsyncNotifier<Option<ProfileSummary>> {
  FutureOr<Option<ProfileSummary>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<Option<ProfileSummary>>, Option<ProfileSummary>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Option<ProfileSummary>>,
                Option<ProfileSummary>
              >,
              AsyncValue<Option<ProfileSummary>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ProfilePreferencesNotifier)
final profilePreferencesNotifierProvider =
    ProfilePreferencesNotifierProvider._();

final class ProfilePreferencesNotifierProvider
    extends
        $AsyncNotifierProvider<
          ProfilePreferencesNotifier,
          Option<ProfilePreferences>
        > {
  ProfilePreferencesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profilePreferencesNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profilePreferencesNotifierHash();

  @$internal
  @override
  ProfilePreferencesNotifier create() => ProfilePreferencesNotifier();
}

String _$profilePreferencesNotifierHash() =>
    r'6500bf934f2434a151a255d614de936c5bda7781';

abstract class _$ProfilePreferencesNotifier
    extends $AsyncNotifier<Option<ProfilePreferences>> {
  FutureOr<Option<ProfilePreferences>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<Option<ProfilePreferences>>,
              Option<ProfilePreferences>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<Option<ProfilePreferences>>,
                Option<ProfilePreferences>
              >,
              AsyncValue<Option<ProfilePreferences>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
