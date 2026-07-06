import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/core/utils/baybayify.dart';
import 'package:kudlit_ph/features/home/domain/entities/translation_result.dart';
import 'package:kudlit_ph/features/home/presentation/providers/app_preferences_provider.dart';
import 'package:kudlit_ph/features/home/presentation/providers/translate_page_controller.dart';
import 'package:kudlit_ph/features/home/presentation/providers/translation_history_provider.dart';
import 'package:kudlit_ph/features/home/presentation/utils/safe_ai_output.dart';
import 'package:kudlit_ph/features/learning/domain/entities/gemma_prompts.dart';
import 'package:kudlit_ph/features/translator/domain/entities/chat_message.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_state.dart';

@immutable
class TranslateTextState {
  const TranslateTextState({
    required this.inputText,
    required this.latinToBaybayin,
    required this.baybayinText,
    required this.latinText,
    required this.feedbackMessages,
    required this.aiBusy,
    required this.aiResponse,
    this.cleanupPreview,
    this.aiSource,
    this.inputRevision = 0,
  });

  const TranslateTextState.initial()
    : this(
        inputText: '',
        latinToBaybayin: true,
        baybayinText: '',
        latinText: '',
        feedbackMessages: const <String>[],
        aiBusy: false,
        aiResponse: '',
      );

  final String inputText;
  final bool latinToBaybayin;
  final String baybayinText;
  final String latinText;
  final List<String> feedbackMessages;
  final bool aiBusy;
  final String aiResponse;
  final String? cleanupPreview;
  final TranslateAiResultSource? aiSource;

  /// Bumped only by external (non-typing) input mutations — example chips,
  /// clear, etc. The text field watches this to know when to resync its
  /// controller; plain typing never bumps it, so the cursor is never reset
  /// mid-sentence.
  final int inputRevision;

  bool get hasInput => inputText.trim().isNotEmpty;

  TranslateTextState copyWith({
    String? inputText,
    bool? latinToBaybayin,
    String? baybayinText,
    String? latinText,
    List<String>? feedbackMessages,
    bool? aiBusy,
    String? aiResponse,
    String? cleanupPreview,
    bool clearCleanupPreview = false,
    TranslateAiResultSource? aiSource,
    bool clearAiSource = false,
    int? inputRevision,
  }) {
    return TranslateTextState(
      inputText: inputText ?? this.inputText,
      latinToBaybayin: latinToBaybayin ?? this.latinToBaybayin,
      baybayinText: baybayinText ?? this.baybayinText,
      latinText: latinText ?? this.latinText,
      feedbackMessages: feedbackMessages ?? this.feedbackMessages,
      aiBusy: aiBusy ?? this.aiBusy,
      aiResponse: aiResponse ?? this.aiResponse,
      cleanupPreview: clearCleanupPreview
          ? null
          : (cleanupPreview ?? this.cleanupPreview),
      aiSource: clearAiSource ? null : (aiSource ?? this.aiSource),
      inputRevision: inputRevision ?? this.inputRevision,
    );
  }
}

final NotifierProvider<TranslateTextController, TranslateTextState>
translateTextControllerProvider =
    NotifierProvider<TranslateTextController, TranslateTextState>(
      TranslateTextController.new,
    );

class TranslateTextController extends Notifier<TranslateTextState> {
  static final RegExp _numberPattern = RegExp(r'[0-9]');
  static final RegExp _punctuationPattern = RegExp(r'[!-/:-@[-`{-~]');
  static final RegExp _unsupportedPattern = RegExp(r'[^A-Za-z0-9\sñÑᜀ-ᜟ]');
  static final RegExp _reverseUnsupportedPattern = RegExp(
    r'[^A-Za-z0-9+\sᜀ-ᜟ]',
  );
  static final RegExp _baybayinPattern = RegExp(r'[ᜀ-ᜟ]');

  /// How long after the last keystroke the heavy transliteration runs.
  /// Keeps `baybayifyWord` + regex feedback off the typing hot path so the
  /// keyboard stays responsive during continuous input.
  static const Duration _deriveDebounceDuration = Duration(milliseconds: 180);

  Timer? _saveDebounce;
  Timer? _deriveDebounce;

  @override
  TranslateTextState build() {
    ref.onDispose(() {
      _saveDebounce?.cancel();
      _deriveDebounce?.cancel();
    });
    return const TranslateTextState.initial();
  }

  /// Typing path. Echoes the raw text instantly (cheap, no rebuild storm)
  /// and defers the expensive derive until typing pauses. Never bumps
  /// [TranslateTextState.inputRevision], so the field/cursor is untouched.
  void setInput(String value) {
    if (value.trim().isEmpty) {
      _deriveDebounce?.cancel();
      state = state.copyWith(
        inputText: value,
        baybayinText: '',
        latinText: '',
        feedbackMessages: const <String>[],
        clearCleanupPreview: true,
        aiResponse: '',
        clearAiSource: true,
      );
      _scheduleAutoSave();
      return;
    }
    state = state.copyWith(inputText: value);
    _deriveDebounce?.cancel();
    _deriveDebounce = Timer(_deriveDebounceDuration, () {
      state = _deriveState(
        inputText: state.inputText,
        latinToBaybayin: state.latinToBaybayin,
      );
      _scheduleAutoSave();
    });
  }

  /// External input (example chips, etc). Derives immediately and bumps
  /// [TranslateTextState.inputRevision] so the field resyncs its controller.
  void applyExternalInput(String value) {
    _deriveDebounce?.cancel();
    final TranslateTextState derived = _deriveState(
      inputText: value,
      latinToBaybayin: state.latinToBaybayin,
    );
    state = derived.copyWith(inputRevision: state.inputRevision + 1);
    _scheduleAutoSave();
  }

  void setDirection(bool latinToBaybayin) {
    _deriveDebounce?.cancel();
    state = _deriveState(
      inputText: state.inputText,
      latinToBaybayin: latinToBaybayin,
    );
    _scheduleAutoSave();
  }

  void clearInput() {
    _saveDebounce?.cancel();
    _deriveDebounce?.cancel();
    state = const TranslateTextState.initial().copyWith(
      inputRevision: state.inputRevision + 1,
    );
  }

  void _scheduleAutoSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 1500), _doAutoSave);
  }

  void _doAutoSave() {
    final TranslateTextState s = state;
    if (s.baybayinText.isEmpty && s.latinText.isEmpty) return;
    unawaited(
      ref
          .read(translationHistoryNotifierProvider.notifier)
          .addResult(
            TranslationResult(
              inputText: s.inputText.trim(),
              baybayinText: s.baybayinText,
              latinText: s.latinText,
              direction: s.latinToBaybayin
                  ? 'latin_to_baybayin'
                  : 'baybayin_to_latin',
              aiResponse: '',
              isBookmarked: false,
              timestamp: DateTime.now(),
            ),
          ),
    );
  }

  Future<void> explain() async {
    await _runAiAction(
      userPrompt:
          'Input: "${state.inputText.trim()}"\n'
          'Baybayin: "${state.baybayinText}"\n'
          'Filipino: "${state.latinText}"\n'
          'Give a short explanation of this transliteration.',
    );
  }

  Future<void> checkInput() async {
    await _runAiAction(
      userPrompt:
          'Input: "${state.inputText.trim()}".\n'
          'Direction: ${state.latinToBaybayin ? 'Filipino to Baybayin' : 'Baybayin to Filipino'}.\n'
          'Give one short warning and one short improvement tip.',
    );
  }

  TranslateTextState _deriveState({
    required String inputText,
    required bool latinToBaybayin,
  }) {
    final String trimmed = inputText.trim();
    if (trimmed.isEmpty) {
      return state.copyWith(
        inputText: inputText,
        latinToBaybayin: latinToBaybayin,
        baybayinText: '',
        latinText: '',
        feedbackMessages: const <String>[],
        clearCleanupPreview: true,
        aiResponse: '',
        clearAiSource: true,
      );
    }

    final String baybayinText = latinToBaybayin
        ? baybayifyWord(trimmed)
        : trimmed;
    final String latinText = latinToBaybayin
        ? trimmed
        : baybayinToLatin(trimmed);
    final String? cleanupPreview = _cleanupPreviewFor(trimmed, latinToBaybayin);
    return state.copyWith(
      inputText: inputText,
      latinToBaybayin: latinToBaybayin,
      baybayinText: baybayinText,
      latinText: latinText,
      feedbackMessages: _feedbackFor(trimmed, latinToBaybayin),
      cleanupPreview: cleanupPreview,
      clearCleanupPreview: cleanupPreview == null,
    );
  }

  String? _cleanupPreviewFor(String input, bool latinToBaybayin) {
    final bool hasRemovedCharacters = latinToBaybayin
        ? _hasPunctuation(input, latinToBaybayin: true) ||
              _numberPattern.hasMatch(input) ||
              _unsupportedPattern.hasMatch(input)
        : _hasPunctuation(input, latinToBaybayin: false) ||
              _numberPattern.hasMatch(input) ||
              _reverseUnsupportedPattern.hasMatch(input) ||
              _baybayinPattern.hasMatch(input);
    if (!hasRemovedCharacters) return null;

    final String normalized = latinToBaybayin
        ? input.toLowerCase().replaceAll(RegExp(r'[^a-z\s]'), '')
        : input.toLowerCase().replaceAll(RegExp(r'[^a-z+\s]'), '');
    final String compact = normalized.trim().replaceAll(RegExp(r'\s+'), ' ');
    return compact.isEmpty ? null : compact;
  }

  List<String> _feedbackFor(String input, bool latinToBaybayin) {
    final List<String> messages = <String>[];
    if (_hasPunctuation(input, latinToBaybayin: latinToBaybayin)) {
      messages.add('Removed punctuation from input.');
    }
    if (_numberPattern.hasMatch(input)) {
      messages.add('Numbers were ignored.');
    }
    final bool hasUnsupportedCharacters = latinToBaybayin
        ? _unsupportedPattern.hasMatch(input)
        : _reverseUnsupportedPattern.hasMatch(input);
    if (hasUnsupportedCharacters) {
      messages.add('Some unsupported characters were ignored.');
    }
    if (!latinToBaybayin) {
      if (_baybayinPattern.hasMatch(input)) {
        messages.add(
          'Pasted Baybayin glyphs are not parsed yet. Use encoded text like ka, ki, or k+.',
        );
      } else {
        messages.add('Reverse mode reads encoded Baybayin like ka, ki, or k+.');
      }
    }
    if (latinToBaybayin) {
      messages.add('Transliteration may be approximate for modern spelling.');
    }
    return messages;
  }

  bool _hasPunctuation(String input, {required bool latinToBaybayin}) {
    if (latinToBaybayin) {
      return _punctuationPattern.hasMatch(input);
    }
    for (final int codePoint in input.runes) {
      final String character = String.fromCharCode(codePoint);
      if (character != '+' && _punctuationPattern.hasMatch(character)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _runAiAction({required String userPrompt}) async {
    if (!state.hasInput || state.aiBusy) {
      return;
    }
    state = state.copyWith(aiBusy: true, aiResponse: '', clearAiSource: true);

    final List<ChatMessage> history = <ChatMessage>[
      ChatMessage(text: userPrompt, isUser: true, timestamp: DateTime.now()),
    ];

    // Route through the same shared inference notifier Butty uses. The
    // repository owns model resolution, local-vs-cloud selection, and
    // cloud fallback — translate no longer hand-rolls any of that, so the
    // local Gemma model loads and behaves identically to the Butty chat.
    final AiInferenceState? inference = ref
        .read(aiInferenceNotifierProvider)
        .value;
    final TranslateAiResultSource source = switch (inference) {
      AiReady(mode: AiPreference.local) => TranslateAiResultSource.offline,
      _ => TranslateAiResultSource.online,
    };

    await _streamResponse(
      stream: ref
          .read(aiInferenceNotifierProvider.notifier)
          .generateResponse(
            history,
            systemInstruction: GemmaPrompts.translatorMode,
          ),
      source: source,
      rethrowOnError: false,
    );
  }

  Future<void> _streamResponse({
    required Stream<String> stream,
    required TranslateAiResultSource source,
    String prefix = '',
    required bool rethrowOnError,
  }) async {
    final StringBuffer buffer = StringBuffer(prefix);
    try {
      await for (final String chunk in stream) {
        buffer.write(chunk);
        final String displayResponse = cleanAssistantOutput(buffer.toString());
        state = state.copyWith(
          aiBusy: true,
          aiResponse: displayResponse,
          aiSource: source,
        );
      }
      final String displayResponse = cleanAssistantOutput(buffer.toString());
      state = state.copyWith(
        aiBusy: false,
        aiResponse: displayResponse,
        aiSource: source,
      );
      if (buffer.isNotEmpty) {
        unawaited(
          ref
              .read(translationHistoryNotifierProvider.notifier)
              .updateLastAiResponse(buffer.toString()),
        );
      }
    } catch (error) {
      state = state.copyWith(
        aiBusy: false,
        aiResponse: 'Could not complete AI request: $error',
        clearAiSource: true,
      );
      if (rethrowOnError) {
        rethrow;
      }
    }
  }
}
