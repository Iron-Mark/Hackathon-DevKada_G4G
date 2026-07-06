import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import 'package:kudlit_ph/core/utils/baybayify.dart';
import 'package:kudlit_ph/features/learning/domain/entities/gemma_prompts.dart';
import 'package:kudlit_ph/features/scanner/domain/entities/baybayin_detection.dart';
import 'package:kudlit_ph/features/scanner/domain/entities/scan_result.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/scan_history_provider.dart';
import 'package:kudlit_ph/features/translator/domain/entities/chat_message.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/translator_providers.dart';

@immutable
class ScanEvalState {
  const ScanEvalState({required this.translation, this.followUp});

  final AsyncValue<String> translation;
  final AsyncValue<String>? followUp;

  bool get canRequestFollowUp {
    if (followUp != null) return false;
    return translation.asData?.value.isNotEmpty == true;
  }

  ScanEvalState withTranslation(AsyncValue<String> t) =>
      ScanEvalState(translation: t, followUp: followUp);

  ScanEvalState withFollowUp(AsyncValue<String>? f) =>
      ScanEvalState(translation: translation, followUp: f);
}

final NotifierProvider<ScannerEvaluationNotifier, ScanEvalState>
scannerEvaluationProvider =
    NotifierProvider<ScannerEvaluationNotifier, ScanEvalState>(
      ScannerEvaluationNotifier.new,
    );

class ScannerEvaluationNotifier extends Notifier<ScanEvalState> {
  List<String> _lastTokens = <String>[];
  int _translationGeneration = 0;
  int _followUpGeneration = 0;

  @override
  ScanEvalState build() =>
      const ScanEvalState(translation: AsyncData<String>(''));

  void evaluate(
    List<BaybayinDetection> detections,
    Uint8List? imageBytes, {
    String? aggregatedHint,
  }) {
    final int generation = ++_translationGeneration;
    _followUpGeneration++;
    if (detections.isEmpty) {
      clear();
      return;
    }

    final List<BaybayinDetection> ordered =
        List<BaybayinDetection>.of(detections)..sort(
          (BaybayinDetection a, BaybayinDetection b) =>
              a.left.compareTo(b.left),
        );
    final List<String> tokens = ordered
        .map((BaybayinDetection d) => d.label.trim().toLowerCase())
        .where((String s) => s.isNotEmpty)
        .toList(growable: false);
    _lastTokens = tokens;
    final List<String> perms = permuteBaybayin(tokens);

    // When the aggregated winner is available (majority vote from up to 50
    // live frames), surface it first so the model weights it heavily.
    final String candidates = aggregatedHint != null
        ? '$aggregatedHint (highest confidence — majority vote across recent '
              'frames), '
              '${perms.isEmpty ? tokens.join(' ') : perms.take(9).join(', ')}'
        : (perms.isEmpty ? tokens.join(' ') : perms.take(10).join(', '));

    state = const ScanEvalState(translation: AsyncLoading<String>());

    final Stream<String> stream;
    if (imageBytes != null) {
      // Image available — use the visual-inspection variant so the model can
      // check the actual glyphs against the vocabulary, then predict.
      stream = ref
          .read(aiInferenceRepositoryProvider)
          .analyzeImage(
            imageBytes,
            mimeType: 'image/jpeg',
            prompt: GemmaPrompts.scanTranslatorModeWithImage(candidates),
          );
    } else {
      // Text-only path — vocabulary + scanner reliability chain-of-thought.
      final String query =
          'Detected glyphs (left to right): ${tokens.join(", ")}. '
          'Which word is this?';
      stream = ref.read(aiInferenceNotifierProvider.notifier).generateResponse(
        <ChatMessage>[
          ChatMessage(text: query, isUser: true, timestamp: DateTime.now()),
        ],
        systemInstruction: GemmaPrompts.scanTranslatorMode(candidates),
      );
    }

    unawaited(_listenToTranslation(stream, generation));
  }

  void requestFollowUp() {
    final String? translationText = state.translation.asData?.value;
    if (translationText == null || translationText.isEmpty) return;
    if (state.followUp != null) return;

    final int generation = ++_followUpGeneration;
    state = state.withFollowUp(const AsyncLoading<String>());

    final List<ChatMessage> history = <ChatMessage>[
      ChatMessage(
        text: translationText,
        isUser: false,
        timestamp: DateTime.now(),
      ),
      ChatMessage(
        text:
            'Tell me more about this word — its meaning, how it\'s used, '
            'or something interesting about it.',
        isUser: true,
        timestamp: DateTime.now(),
      ),
    ];

    final Stream<String> stream = ref
        .read(aiInferenceNotifierProvider.notifier)
        .generateResponse(
          history,
          systemInstruction: GemmaPrompts.assistantMode,
        );

    unawaited(_listenToFollowUp(stream, generation));
  }

  void clear() {
    _lastTokens = <String>[];
    _translationGeneration++;
    _followUpGeneration++;
    state = const ScanEvalState(translation: AsyncData<String>(''));
  }

  Future<void> _listenToTranslation(
    Stream<String> stream,
    int generation,
  ) async {
    final StringBuffer buffer = StringBuffer();
    try {
      await for (final String chunk in stream) {
        if (generation != _translationGeneration) return;
        buffer.write(chunk);
        final String raw = buffer.toString();
        final ({String think, String answer}) parsed =
            GemmaPrompts.parseThinkBlock(raw);
        // While the <think> block is still open the model is reasoning
        // privately — keep the TypingBubble spinning (AsyncLoading).
        // Once </think> closes, stream the clean answer to the UI.
        final AsyncValue<String> next =
            (parsed.answer.isEmpty && parsed.think.isNotEmpty)
            ? const AsyncLoading<String>()
            : AsyncData<String>(parsed.answer);
        if (generation == _translationGeneration) {
          state = state.withTranslation(next);
        }
      }
      if (generation != _translationGeneration) return;
      // Save only the clean answer (no <think> content) to history.
      final String finalAnswer = GemmaPrompts.parseThinkBlock(
        buffer.toString(),
      ).answer.trim();
      if (finalAnswer.isNotEmpty && _lastTokens.isNotEmpty) {
        ref
            .read(scanHistoryNotifierProvider.notifier)
            .addResult(
              ScanResult(
                tokens: List<String>.of(_lastTokens),
                translation: finalAnswer,
                timestamp: DateTime.now(),
              ),
            );
      }
    } catch (e) {
      if (generation == _translationGeneration) {
        state = state.withTranslation(
          AsyncError<String>(e, StackTrace.current),
        );
      }
    }
  }

  Future<void> _listenToFollowUp(Stream<String> stream, int generation) async {
    final StringBuffer buffer = StringBuffer();
    try {
      await for (final String chunk in stream) {
        if (generation != _followUpGeneration) return;
        buffer.write(chunk);
        if (generation == _followUpGeneration) {
          state = state.withFollowUp(AsyncData<String>(buffer.toString()));
        }
      }
    } catch (e) {
      if (generation == _followUpGeneration) {
        state = state.withFollowUp(AsyncError<String>(e, StackTrace.current));
      }
    }
  }
}
