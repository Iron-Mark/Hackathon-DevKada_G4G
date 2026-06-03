import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kudlit_ph/features/home/presentation/providers/translate_text_controller.dart';

void main() {
  test(
    'setInput echoes raw text immediately without synchronous derive',
    () {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(translateTextControllerProvider.notifier)
          .setInput('kamusta');

      final TranslateTextState state = container.read(
        translateTextControllerProvider,
      );
      expect(state.inputText, 'kamusta');
      expect(state.hasInput, isTrue);
      // Heavy transliteration is debounced off the typing hot path.
      expect(state.baybayinText, isEmpty);
      // Typing must never bump the revision (would reset the field/cursor).
      expect(state.inputRevision, 0);
    },
  );

  test('setInput derives the preview after the debounce window', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(translateTextControllerProvider.notifier)
        .setInput('kamusta');

    await Future<void>.delayed(const Duration(milliseconds: 260));

    final TranslateTextState state = container.read(
      translateTextControllerProvider,
    );
    expect(state.inputText, 'kamusta');
    expect(state.baybayinText, isNotEmpty);
    expect(state.inputRevision, 0);
  });

  test('applyExternalInput derives immediately and bumps revision', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(translateTextControllerProvider.notifier)
        .applyExternalInput('ka');

    final TranslateTextState state = container.read(
      translateTextControllerProvider,
    );
    expect(state.inputText, 'ka');
    expect(state.baybayinText, isNotEmpty);
    expect(state.inputRevision, 1);
  });

  test('clearInput resets state and bumps revision', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    final TranslateTextController controller = container.read(
      translateTextControllerProvider.notifier,
    );
    controller.applyExternalInput('ka');
    controller.clearInput();

    final TranslateTextState state = container.read(
      translateTextControllerProvider,
    );
    expect(state.inputText, isEmpty);
    expect(state.baybayinText, isEmpty);
    expect(state.inputRevision, 2);
  });
}
