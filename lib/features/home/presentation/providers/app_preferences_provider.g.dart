// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_preferences_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AppPreferencesNotifier)
final appPreferencesNotifierProvider = AppPreferencesNotifierProvider._();

final class AppPreferencesNotifierProvider
    extends $AsyncNotifierProvider<AppPreferencesNotifier, AppPreferences> {
  AppPreferencesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appPreferencesNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appPreferencesNotifierHash();

  @$internal
  @override
  AppPreferencesNotifier create() => AppPreferencesNotifier();
}

String _$appPreferencesNotifierHash() =>
    r'82d1d5426121b2f3b9571e2ba96c6ba342483a8d';

abstract class _$AppPreferencesNotifier extends $AsyncNotifier<AppPreferences> {
  FutureOr<AppPreferences> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppPreferences>, AppPreferences>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppPreferences>, AppPreferences>,
              AsyncValue<AppPreferences>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
