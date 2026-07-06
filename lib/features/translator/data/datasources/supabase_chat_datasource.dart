import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kudlit_ph/features/translator/domain/entities/chat_message.dart';

/// Cloud-sync mirror for [SqliteChatDatasource].
///
/// All methods silently no-op for guest sessions (no auth user) — matching the
/// fire-and-forget convention used by scan_history and translation_history.
class SupabaseChatDatasource {
  SupabaseChatDatasource(this._client);

  final SupabaseClient _client;
  static const String _table = 'chat_messages';

  /// Inserts the message and returns the assigned remote UUID. Returns null
  /// for guest users or on transient failure (caller should keep going).
  Future<String?> insert(ChatMessage message) async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final Map<String, dynamic> row = await _client
          .from(_table)
          .insert(<String, dynamic>{
            'user_id': userId,
            'content': message.text,
            'is_user': message.isUser,
            'created_at': message.timestamp.toIso8601String(),
          })
          .select('id')
          .single();
      return row['id'] as String?;
    } catch (e) {
      debugPrint('[ChatHistory] Supabase insert failed (non-fatal): $e');
      return null;
    }
  }

  /// Restores up to [limit] most-recent messages, returned chronologically
  /// (oldest first) so they can be replayed into the local cache.
  Future<List<ChatMessage>> fetchRecent({int limit = 100}) async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return const <ChatMessage>[];
    try {
      final List<dynamic> rows = await _client
          .from(_table)
          .select('id, content, is_user, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      final List<ChatMessage> messages = rows
          .map((dynamic raw) {
            final Map<String, dynamic> r = raw as Map<String, dynamic>;
            return ChatMessage(
              remoteId: r['id'] as String?,
              text: r['content'] as String? ?? '',
              isUser: r['is_user'] as bool? ?? false,
              timestamp: DateTime.parse(r['created_at'] as String),
            );
          })
          .toList(growable: false);

      return messages.reversed.toList(growable: false);
    } catch (e) {
      debugPrint('[ChatHistory] Supabase fetch failed (non-fatal): $e');
      return const <ChatMessage>[];
    }
  }

  /// Wipes the user's chat history in Supabase. Used by the "Start fresh"
  /// action — memory facts table is intentionally untouched.
  Future<void> deleteAllForCurrentUser() async {
    final String? userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.from(_table).delete().eq('user_id', userId);
    } catch (e) {
      debugPrint('[ChatHistory] Supabase delete failed (non-fatal): $e');
    }
  }
}
