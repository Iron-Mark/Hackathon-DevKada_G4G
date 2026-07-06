import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kudlit_ph/features/translator/domain/entities/chat_memory_fact.dart';

/// Cloud mirror for chat_memory_facts. Silent no-ops for guest sessions.
class SupabaseChatMemoryDatasource {
  SupabaseChatMemoryDatasource(this._client);

  final SupabaseClient _client;
  static const String _table = 'chat_memory_facts';

  Future<List<ChatMemoryFact>> fetchAll({int limit = 200}) async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return const <ChatMemoryFact>[];
    try {
      final List<dynamic> rows = await _client
          .from(_table)
          .select('id, fact_type, content, created_at, last_referenced_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return rows
          .map((dynamic raw) {
            final Map<String, dynamic> r = raw as Map<String, dynamic>;
            return ChatMemoryFact(
              remoteId: r['id'] as String?,
              factType: r['fact_type'] as String? ?? 'general',
              content: r['content'] as String? ?? '',
              createdAt: DateTime.parse(r['created_at'] as String),
              lastReferencedAt: DateTime.parse(
                r['last_referenced_at'] as String,
              ),
            );
          })
          .toList(growable: false);
    } catch (e) {
      debugPrint('[ChatMemory] Supabase fetch failed (non-fatal): $e');
      return const <ChatMemoryFact>[];
    }
  }

  /// Inserts the fact upstream. Returns the assigned UUID, or null on
  /// guest/duplicate/transient-error so the caller can keep going.
  Future<String?> insert(ChatMemoryFact fact) async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final Map<String, dynamic> row = await _client
          .from(_table)
          .insert(<String, dynamic>{
            'user_id': userId,
            'fact_type': fact.factType,
            'content': fact.content,
            'created_at': fact.createdAt.toIso8601String(),
            'last_referenced_at': fact.lastReferencedAt.toIso8601String(),
          })
          .select('id')
          .single();
      return row['id'] as String?;
    } catch (e) {
      // Unique-violation on (user_id, lower(content)) is expected when the
      // local dedupe missed (e.g. cross-device race). Treat as soft-fail.
      debugPrint('[ChatMemory] Supabase insert non-fatal: $e');
      return null;
    }
  }

  Future<void> deleteAllForCurrentUser() async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.from(_table).delete().eq('user_id', userId);
    } catch (e) {
      debugPrint('[ChatMemory] Supabase delete failed (non-fatal): $e');
    }
  }

  Future<void> deleteByRemoteId(String remoteId) async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client
          .from(_table)
          .delete()
          .eq('id', remoteId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[ChatMemory] Supabase delete-one failed (non-fatal): $e');
    }
  }

  Future<void> updateByRemoteId({
    required String remoteId,
    required String factType,
    required String content,
  }) async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client
          .from(_table)
          .update(<String, dynamic>{
            'fact_type': factType,
            'content': content,
            'last_referenced_at': DateTime.now().toIso8601String(),
          })
          .eq('id', remoteId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[ChatMemory] Supabase update failed (non-fatal): $e');
    }
  }
}
