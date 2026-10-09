// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LessonController)
final lessonControllerProvider = LessonControllerProvider._();

final class LessonControllerProvider
    extends $AsyncNotifierProvider<LessonController, LessonState?> {
  LessonControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lessonControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lessonControllerHash();

  @$internal
  @override
  LessonController create() => LessonController();
}

String _$lessonControllerHash() => r'8bebb6eb5534251e297f2fa987b41ee95bcb60c7';

abstract class _$LessonController extends $AsyncNotifier<LessonState?> {
  FutureOr<LessonState?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<LessonState?>, LessonState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<LessonState?>, LessonState?>,
              AsyncValue<LessonState?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
