// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'password_field.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PasswordVisible)
final passwordVisibleProvider = PasswordVisibleProvider._();

final class PasswordVisibleProvider
    extends $NotifierProvider<PasswordVisible, bool> {
  PasswordVisibleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passwordVisibleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passwordVisibleHash();

  @$internal
  @override
  PasswordVisible create() => PasswordVisible();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$passwordVisibleHash() => r'6f5d2b4572527f371908efff97087002db9285c1';

abstract class _$PasswordVisible extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
