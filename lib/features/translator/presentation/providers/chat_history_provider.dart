import 'dart:async';

import 'package:flutter/foundation.dart';
// ignore: unnecessary_import — flutter_riverpod is needed for AsyncNotifier
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:kudlit_ph/features/translator/data/datasources/sqlite_chat_datasource.dart';
import 'package:kudlit_ph/features/translator/data/datasources/supabase_chat_datasource.dart';
import 'package:kudlit_ph/features/translator/domain/entities/chat_message.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/translator_providers.dart';

part 'chat_history_provider.g.dart';

/// Persisted Butty chat history backed by sqflite, with Supabase mirroring
/// for cross-device continuity.
///
/// Mirrors the offline-first pattern used by [TranslationHistoryNotifier]:
/// reads come from SQLite first, fall back to Supabase on cold-empty,
/// writes are local-first with fire-and-forget cloud sync.
@Riverpod(keepAlive: true)
class ChatHistoryNotifier extends _$ChatHistoryNotifier {
  late final SqliteChatDatasource _local;
  late final SupabaseChatDatasource _remote;

  @override
  Future<List<ChatMessage>> build() async {
    _local = ref.watch(sqliteChatDatasourceProvider);
    _remote = ref.watch(supabaseChatDatasourceProvider);

    final List<ChatMessage> local = await _local.loadAll();
    if (local.isNotEmpty) return local;

    // Fresh install (or first sign-in) — restore last 100 turns from cloud.
    final List<ChatMessage> remote = await _remote.fetchRecent(limit: 100);
    if (remote.isEmpty) return local;

    final List<ChatMessage> rehydrated = <ChatMessage>[];
    for (final ChatMessage m in remote) {
      try {
        final ChatMessage saved = await _local.insert(m);
        rehydrated.add(saved);
      } catch (e) {
        debugPrint(
          '[ChatHistory] cloud→local rehydrate failed (non-fatal): $e',
        );
      }
    }
    return rehydrated;
  }

  Future<void> addMessage(ChatMessage message) async {
    final ChatMessage saved = await _local.insert(message);
    final List<ChatMessage> current = state.value ?? <ChatMessage>[];
    state = AsyncData<List<ChatMessage>>(<ChatMessage>[...current, saved]);
    unawaited(_syncMessage(saved));
  }

  Future<void> clearHistory() async {
    await _local.clear();
    state = const AsyncData<List<ChatMessage>>(<ChatMessage>[]);
    unawaited(_remote.deleteAllForCurrentUser());
  }

  Future<void> _syncMessage(ChatMessage saved) async {
    final String? remoteId = await _remote.insert(saved);
    if (remoteId == null || saved.id == null) return;
    try {
      await _local.setRemoteId(localId: saved.id!, remoteId: remoteId);
      // Reflect the remote_id in the current state so any later soft-delete or
      // bookmark flow can address the cloud row directly.
      final List<ChatMessage> current = state.value ?? <ChatMessage>[];
      state = AsyncData<List<ChatMessage>>(
        current
            .map(
              (ChatMessage m) =>
                  m.id == saved.id ? m.copyWith(remoteId: remoteId) : m,
            )
            .toList(growable: false),
      );
    } catch (e) {
      debugPrint('[ChatHistory] remote_id back-fill failed (non-fatal): $e');
    }
  }
}
