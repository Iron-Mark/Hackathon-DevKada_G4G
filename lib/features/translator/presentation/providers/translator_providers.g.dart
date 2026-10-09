// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translator_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(availableGemmaModels)
final availableGemmaModelsProvider = AvailableGemmaModelsProvider._();

final class AvailableGemmaModelsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GemmaModelInfo>>,
          List<GemmaModelInfo>,
          FutureOr<List<GemmaModelInfo>>
        >
    with
        $FutureModifier<List<GemmaModelInfo>>,
        $FutureProvider<List<GemmaModelInfo>> {
  AvailableGemmaModelsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableGemmaModelsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availableGemmaModelsHash();

  @$internal
  @override
  $FutureProviderElement<List<GemmaModelInfo>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GemmaModelInfo>> create(Ref ref) {
    return availableGemmaModels(ref);
  }
}

String _$availableGemmaModelsHash() =>
    r'bee8c70ee97f8e432d17a3359f2a91ff48f0f30a';

@ProviderFor(supabaseAiModelsDatasource)
final supabaseAiModelsDatasourceProvider =
    SupabaseAiModelsDatasourceProvider._();

final class SupabaseAiModelsDatasourceProvider
    extends
        $FunctionalProvider<
          SupabaseAiModelsDatasource,
          SupabaseAiModelsDatasource,
          SupabaseAiModelsDatasource
        >
    with $Provider<SupabaseAiModelsDatasource> {
  SupabaseAiModelsDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseAiModelsDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseAiModelsDatasourceHash();

  @$internal
  @override
  $ProviderElement<SupabaseAiModelsDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SupabaseAiModelsDatasource create(Ref ref) {
    return supabaseAiModelsDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseAiModelsDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseAiModelsDatasource>(value),
    );
  }
}

String _$supabaseAiModelsDatasourceHash() =>
    r'6d0b27a557bb1343004c9fd030db9ebe491a590d';

@ProviderFor(supabaseGemmaModelsDatasource)
final supabaseGemmaModelsDatasourceProvider =
    SupabaseGemmaModelsDatasourceProvider._();

final class SupabaseGemmaModelsDatasourceProvider
    extends
        $FunctionalProvider<
          SupabaseGemmaModelsDatasource,
          SupabaseGemmaModelsDatasource,
          SupabaseGemmaModelsDatasource
        >
    with $Provider<SupabaseGemmaModelsDatasource> {
  SupabaseGemmaModelsDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supabaseGemmaModelsDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supabaseGemmaModelsDatasourceHash();

  @$internal
  @override
  $ProviderElement<SupabaseGemmaModelsDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SupabaseGemmaModelsDatasource create(Ref ref) {
    return supabaseGemmaModelsDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseGemmaModelsDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseGemmaModelsDatasource>(
        value,
      ),
    );
  }
}

String _$supabaseGemmaModelsDatasourceHash() =>
    r'4a86371c404ac1feb264161fd84ae62c4c44842c';

@ProviderFor(localGemmaDatasource)
final localGemmaDatasourceProvider = LocalGemmaDatasourceProvider._();

final class LocalGemmaDatasourceProvider
    extends
        $FunctionalProvider<
          LocalGemmaDatasource,
          LocalGemmaDatasource,
          LocalGemmaDatasource
        >
    with $Provider<LocalGemmaDatasource> {
  LocalGemmaDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localGemmaDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localGemmaDatasourceHash();

  @$internal
  @override
  $ProviderElement<LocalGemmaDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocalGemmaDatasource create(Ref ref) {
    return localGemmaDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalGemmaDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalGemmaDatasource>(value),
    );
  }
}

String _$localGemmaDatasourceHash() =>
    r'095003569ba4b3504442938404bed813de0f855b';

@ProviderFor(cloudGemmaDatasource)
final cloudGemmaDatasourceProvider = CloudGemmaDatasourceProvider._();

final class CloudGemmaDatasourceProvider
    extends
        $FunctionalProvider<
          CloudGemmaDatasource,
          CloudGemmaDatasource,
          CloudGemmaDatasource
        >
    with $Provider<CloudGemmaDatasource> {
  CloudGemmaDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudGemmaDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudGemmaDatasourceHash();

  @$internal
  @override
  $ProviderElement<CloudGemmaDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CloudGemmaDatasource create(Ref ref) {
    return cloudGemmaDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CloudGemmaDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CloudGemmaDatasource>(value),
    );
  }
}

String _$cloudGemmaDatasourceHash() =>
    r'af8a3a04d8681fa607cc6c603058dfec90f3eb27';

@ProviderFor(sqliteChatDatasource)
final sqliteChatDatasourceProvider = SqliteChatDatasourceProvider._();

final class SqliteChatDatasourceProvider
    extends
        $FunctionalProvider<
          SqliteChatDatasource,
          SqliteChatDatasource,
          SqliteChatDatasource
        >
    with $Provider<SqliteChatDatasource> {
  SqliteChatDatasourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sqliteChatDatasourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sqliteChatDatasourceHash();

  @$internal
  @override
  $ProviderElement<SqliteChatDatasource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SqliteChatDatasource create(Ref ref) {
    return sqliteChatDatasource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SqliteChatDatasource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SqliteChatDatasource>(value),
    );
  }
}

String _$sqliteChatDatasourceHash() =>
    r'9d9305f8453fe5ccebd04f5da9f37229c002c863';

@ProviderFor(aiInferenceRepository)
final aiInferenceRepositoryProvider = AiInferenceRepositoryProvider._();

final class AiInferenceRepositoryProvider
    extends
        $FunctionalProvider<
          AiInferenceRepository,
          AiInferenceRepository,
          AiInferenceRepository
        >
    with $Provider<AiInferenceRepository> {
  AiInferenceRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiInferenceRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiInferenceRepositoryHash();

  @$internal
  @override
  $ProviderElement<AiInferenceRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AiInferenceRepository create(Ref ref) {
    return aiInferenceRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiInferenceRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiInferenceRepository>(value),
    );
  }
}

String _$aiInferenceRepositoryHash() =>
    r'58b5d1b9a8f32aa3d1091a8508f1410aebcfd4d4';

@ProviderFor(analyzeBaybayinImage)
final analyzeBaybayinImageProvider = AnalyzeBaybayinImageProvider._();

final class AnalyzeBaybayinImageProvider
    extends
        $FunctionalProvider<
          AnalyzeBaybayinImage,
          AnalyzeBaybayinImage,
          AnalyzeBaybayinImage
        >
    with $Provider<AnalyzeBaybayinImage> {
  AnalyzeBaybayinImageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyzeBaybayinImageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyzeBaybayinImageHash();

  @$internal
  @override
  $ProviderElement<AnalyzeBaybayinImage> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AnalyzeBaybayinImage create(Ref ref) {
    return analyzeBaybayinImage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnalyzeBaybayinImage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnalyzeBaybayinImage>(value),
    );
  }
}

String _$analyzeBaybayinImageHash() =>
    r'26c6ced6a8c483676371fb31ed0b42959e35ce6d';

@ProviderFor(generateBaybayinChallenge)
final generateBaybayinChallengeProvider = GenerateBaybayinChallengeProvider._();

final class GenerateBaybayinChallengeProvider
    extends
        $FunctionalProvider<
          GenerateBaybayinChallenge,
          GenerateBaybayinChallenge,
          GenerateBaybayinChallenge
        >
    with $Provider<GenerateBaybayinChallenge> {
  GenerateBaybayinChallengeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'generateBaybayinChallengeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$generateBaybayinChallengeHash();

  @$internal
  @override
  $ProviderElement<GenerateBaybayinChallenge> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GenerateBaybayinChallenge create(Ref ref) {
    return generateBaybayinChallenge(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GenerateBaybayinChallenge value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GenerateBaybayinChallenge>(value),
    );
  }
}

String _$generateBaybayinChallengeHash() =>
    r'5e96e6e12c74c96ca21043a7b0c4f1df86db6f1d';
