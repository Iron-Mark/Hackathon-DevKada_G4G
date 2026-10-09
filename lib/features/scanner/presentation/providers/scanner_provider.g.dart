// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scanner_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the correct [BaybayinDetector] for the current platform.

@ProviderFor(baybayinDetector)
final baybayinDetectorProvider = BaybayinDetectorProvider._();

/// Provides the correct [BaybayinDetector] for the current platform.

final class BaybayinDetectorProvider
    extends
        $FunctionalProvider<
          BaybayinDetector,
          BaybayinDetector,
          BaybayinDetector
        >
    with $Provider<BaybayinDetector> {
  /// Provides the correct [BaybayinDetector] for the current platform.
  BaybayinDetectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'baybayinDetectorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$baybayinDetectorHash();

  @$internal
  @override
  $ProviderElement<BaybayinDetector> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BaybayinDetector create(Ref ref) {
    return baybayinDetector(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BaybayinDetector value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BaybayinDetector>(value),
    );
  }
}

String _$baybayinDetectorHash() => r'be38bac3428b81b2c112cf61d7aa98d1378c7a65';

@ProviderFor(ScannerNotifier)
final scannerNotifierProvider = ScannerNotifierProvider._();

final class ScannerNotifierProvider
    extends $NotifierProvider<ScannerNotifier, List<BaybayinDetection>> {
  ScannerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scannerNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scannerNotifierHash();

  @$internal
  @override
  ScannerNotifier create() => ScannerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<BaybayinDetection> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<BaybayinDetection>>(value),
    );
  }
}

String _$scannerNotifierHash() => r'b0915a255deef509006ce9bb813f48ea24b70c50';

abstract class _$ScannerNotifier extends $Notifier<List<BaybayinDetection>> {
  List<BaybayinDetection> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<List<BaybayinDetection>, List<BaybayinDetection>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<BaybayinDetection>, List<BaybayinDetection>>,
              List<BaybayinDetection>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
