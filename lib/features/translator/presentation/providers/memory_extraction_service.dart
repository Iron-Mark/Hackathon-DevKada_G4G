import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/features/learning/domain/entities/gemma_prompts.dart';
import 'package:kudlit_ph/features/translator/domain/entities/chat_memory_fact.dart';
import 'package:kudlit_ph/features/translator/domain/entities/chat_message.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/chat_history_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/chat_memory_provider.dart';

final Provider<MemoryExtractionService> memoryExtractionServiceProvider =
    Provider<MemoryExtractionService>((Ref ref) {
      return MemoryExtractionService(ref);
    });

/// Distills the recent chat transcript into structured [ChatMemoryFact]s.
///
/// Triggered from [ButtyChatController] every N user messages and from the
/// chat screen's lifecycle observer when the app pauses. Throttled so the
/// extraction never overlaps with itself or runs more often than necessary.
class MemoryExtractionService {
  MemoryExtractionService(this._ref);

  final Ref _ref;

  /// Hard floor between extraction runs. Keeps battery and tokens in check
  /// even if the controller and lifecycle observer both fire on the same edge.
  static const Duration _minInterval = Duration(seconds: 30);

  /// Number of most-recent messages fed to the extractor. Larger windows
  /// surface more facts but cost more tokens; 30 gets ~5 user/Butty rounds.
  static const int _windowSize = 30;

  /// Trigger an extraction on every Nth user message.
  static const int _everyNUserMessages = 4;

  bool _running = false;
  DateTime? _lastRun;

  /// Returns true if a new extraction should run for [userMessageCount].
  bool isDue(int userMessageCount) {
    if (userMessageCount <= 0) return false;
    return userMessageCount % _everyNUserMessages == 0;
  }

  /// Runs extraction if the turn counter says it is due. No-op otherwise.
  Future<void> extractIfDue(int userMessageCount) async {
    if (!isDue(userMessageCount)) return;
    await extractNow();
  }

  /// Runs extraction unconditionally (subject to the throttle and overlap
  /// guards). Safe to call from a lifecycle pause callback.
  Future<void> extractNow() async {
    if (_running) return;
    final DateTime now = DateTime.now();
    if (_lastRun != null && now.difference(_lastRun!) < _minInterval) {
      return;
    }
    _running = true;
    _lastRun = now;
    try {
      final List<ChatMessage> history =
          _ref.read(chatHistoryNotifierProvider).value ?? <ChatMessage>[];
      if (history.length < 2) return;

      final List<ChatMessage> window = history.length <= _windowSize
          ? history
          : history.sublist(history.length - _windowSize);

      final String transcript = _formatTranscript(window);
      final ChatMessage userMessage = ChatMessage(
        text: transcript,
        isUser: true,
        timestamp: now,
      );

      final Stream<String> stream = _ref
          .read(aiInferenceNotifierProvider.notifier)
          .generateResponse(<ChatMessage>[
            userMessage,
          ], systemInstruction: GemmaPrompts.memoryExtractor);

      final StringBuffer buf = StringBuffer();
      await for (final String chunk in stream) {
        buf.write(chunk);
      }

      final List<ChatMemoryFact> facts = _parseFacts(buf.toString(), now);
      if (facts.isEmpty) {
        debugPrint('[MemoryExtraction] no new facts');
        return;
      }
      debugPrint('[MemoryExtraction] extracted ${facts.length} fact(s)');
      await _ref.read(chatMemoryNotifierProvider.notifier).addFacts(facts);
    } catch (e) {
      debugPrint('[MemoryExtraction] failed (non-fatal): $e');
    } finally {
      _running = false;
    }
  }

  String _formatTranscript(List<ChatMessage> messages) {
    final StringBuffer buf = StringBuffer(
      'Transcript follows. Extract facts about the USER only.\n\n',
    );
    for (final ChatMessage m in messages) {
      buf
        ..write(m.isUser ? 'USER: ' : 'BUTTY: ')
        ..writeln(m.text.trim());
    }
    return buf.toString();
  }

  List<ChatMemoryFact> _parseFacts(String raw, DateTime now) {
    final String cleaned = _stripFences(raw).trim();
    if (cleaned.isEmpty) return const <ChatMemoryFact>[];
    try {
      final dynamic decoded = jsonDecode(cleaned);
      if (decoded is! List) return const <ChatMemoryFact>[];
      final List<ChatMemoryFact> result = <ChatMemoryFact>[];
      for (final dynamic item in decoded) {
        if (item is! Map) continue;
        final dynamic content = item['content'];
        if (content is! String || content.trim().isEmpty) continue;
        final String type = (item['type'] as String?)?.trim().isNotEmpty == true
            ? (item['type'] as String).trim()
            : 'general';
        result.add(
          ChatMemoryFact(
            factType: type,
            content: content.trim(),
            createdAt: now,
            lastReferencedAt: now,
          ),
        );
      }
      return result;
    } catch (e) {
      debugPrint('[MemoryExtraction] JSON parse failed: $e\nraw=$cleaned');
      return const <ChatMemoryFact>[];
    }
  }

  /// Defensive: strip ```json fences if the model emits them despite the prompt.
  String _stripFences(String raw) {
    final RegExp fence = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final RegExpMatch? match = fence.firstMatch(raw);
    if (match != null) return match.group(1) ?? raw;
    return raw;
  }
}
