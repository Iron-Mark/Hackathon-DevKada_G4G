// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Supabase-backed datasource. Falls back transparently to [AssetLessonDataSource]
/// in [LessonRepositoryImpl] if the network call fails.

@ProviderFor(lessonDataSource)
final lessonDataSourceProvider = LessonDataSourceProvider._();

/// Supabase-backed datasource. Falls back transparently to [AssetLessonDataSource]
/// in [LessonRepositoryImpl] if the network call fails.

final class LessonDataSourceProvider
    extends
        $FunctionalProvider<
          LessonDataSource,
          LessonDataSource,
          LessonDataSource
        >
    with $Provider<LessonDataSource> {
  /// Supabase-backed datasource. Falls back transparently to [AssetLessonDataSource]
  /// in [LessonRepositoryImpl] if the network call fails.
  LessonDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lessonDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lessonDataSourceHash();

  @$internal
  @override
  $ProviderElement<LessonDataSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LessonDataSource create(Ref ref) {
    return lessonDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LessonDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LessonDataSource>(value),
    );
  }
}

String _$lessonDataSourceHash() => r'1e55dbe67d249809ecad7d5de557f8a0507403b8';

@ProviderFor(assetLessonDataSource)
final assetLessonDataSourceProvider = AssetLessonDataSourceProvider._();

final class AssetLessonDataSourceProvider
    extends
        $FunctionalProvider<
          LessonDataSource,
          LessonDataSource,
          LessonDataSource
        >
    with $Provider<LessonDataSource> {
  AssetLessonDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'assetLessonDataSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$assetLessonDataSourceHash();

  @$internal
  @override
  $ProviderElement<LessonDataSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LessonDataSource create(Ref ref) {
    return assetLessonDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LessonDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LessonDataSource>(value),
    );
  }
}

String _$assetLessonDataSourceHash() =>
    r'b6311af90130de005e77d563041c47bfd605f2da';

@ProviderFor(lessonRepository)
final lessonRepositoryProvider = LessonRepositoryProvider._();

final class LessonRepositoryProvider
    extends
        $FunctionalProvider<
          LessonRepository,
          LessonRepository,
          LessonRepository
        >
    with $Provider<LessonRepository> {
  LessonRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lessonRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lessonRepositoryHash();

  @$internal
  @override
  $ProviderElement<LessonRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LessonRepository create(Ref ref) {
    return lessonRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LessonRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LessonRepository>(value),
    );
  }
}

String _$lessonRepositoryHash() => r'7e6339452d77c998768d471eb7bbd3d287d79523';

@ProviderFor(loadLessonUseCase)
final loadLessonUseCaseProvider = LoadLessonUseCaseProvider._();

final class LoadLessonUseCaseProvider
    extends $FunctionalProvider<LoadLesson, LoadLesson, LoadLesson>
    with $Provider<LoadLesson> {
  LoadLessonUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loadLessonUseCaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loadLessonUseCaseHash();

  @$internal
  @override
  $ProviderElement<LoadLesson> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LoadLesson create(Ref ref) {
    return loadLessonUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LoadLesson value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LoadLesson>(value),
    );
  }
}

String _$loadLessonUseCaseHash() => r'a512e63eedad6cd5b3b1180fbc94ce08e46ef831';
