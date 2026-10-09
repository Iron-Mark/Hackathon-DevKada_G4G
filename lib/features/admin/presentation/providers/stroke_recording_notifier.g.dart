// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stroke_recording_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StrokeRecordingNotifier)
final strokeRecordingNotifierProvider = StrokeRecordingNotifierProvider._();

final class StrokeRecordingNotifierProvider
    extends $NotifierProvider<StrokeRecordingNotifier, StrokeRecordingState> {
  StrokeRecordingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'strokeRecordingNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$strokeRecordingNotifierHash();

  @$internal
  @override
  StrokeRecordingNotifier create() => StrokeRecordingNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StrokeRecordingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StrokeRecordingState>(value),
    );
  }
}

String _$strokeRecordingNotifierHash() =>
    r'805828988e47b49a2dd652a8ad204609c1e946db';

abstract class _$StrokeRecordingNotifier
    extends $Notifier<StrokeRecordingState> {
  StrokeRecordingState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<StrokeRecordingState, StrokeRecordingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<StrokeRecordingState, StrokeRecordingState>,
              StrokeRecordingState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
