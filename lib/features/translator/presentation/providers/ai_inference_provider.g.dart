// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_inference_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Global, lazy AI inference notifier.
///
/// Not instantiated until first read. Once read it stays alive
/// (`keepAlive: true`) and routes to the correct backend
/// (local `flutter_gemma` or cloud stub) based on `AiPreference`.

@ProviderFor(AiInferenceNotifier)
final aiInferenceNotifierProvider = AiInferenceNotifierProvider._();

/// Global, lazy AI inference notifier.
///
/// Not instantiated until first read. Once read it stays alive
/// (`keepAlive: true`) and routes to the correct backend
/// (local `flutter_gemma` or cloud stub) based on `AiPreference`.
final class AiInferenceNotifierProvider
    extends $AsyncNotifierProvider<AiInferenceNotifier, AiInferenceState> {
  /// Global, lazy AI inference notifier.
  ///
  /// Not instantiated until first read. Once read it stays alive
  /// (`keepAlive: true`) and routes to the correct backend
  /// (local `flutter_gemma` or cloud stub) based on `AiPreference`.
  AiInferenceNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiInferenceNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiInferenceNotifierHash();

  @$internal
  @override
  AiInferenceNotifier create() => AiInferenceNotifier();
}

String _$aiInferenceNotifierHash() =>
    r'd9d4834088d63fc06ecd6761449fc33ae8d69319';

/// Global, lazy AI inference notifier.
///
/// Not instantiated until first read. Once read it stays alive
/// (`keepAlive: true`) and routes to the correct backend
/// (local `flutter_gemma` or cloud stub) based on `AiPreference`.

abstract class _$AiInferenceNotifier extends $AsyncNotifier<AiInferenceState> {
  FutureOr<AiInferenceState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<AiInferenceState>, AiInferenceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AiInferenceState>, AiInferenceState>,
              AsyncValue<AiInferenceState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
