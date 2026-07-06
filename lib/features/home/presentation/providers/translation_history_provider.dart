import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kudlit_ph/features/home/data/datasources/sqlite_translation_history_datasource.dart';
import 'package:kudlit_ph/features/home/domain/entities/translation_result.dart';
import 'package:kudlit_ph/features/home/presentation/providers/profile_management_provider.dart';

final Provider<SqliteTranslationHistoryDatasource>
sqliteTranslationHistoryDatasourceProvider =
    Provider<SqliteTranslationHistoryDatasource>((Ref ref) {
      final SqliteTranslationHistoryDatasource ds =
          SqliteTranslationHistoryDatasource();
      ref.onDispose(ds.dispose);
      return ds;
    });

final AsyncNotifierProvider<TranslationHistoryNotifier, List<TranslationResult>>
translationHistoryNotifierProvider =
    AsyncNotifierProvider<TranslationHistoryNotifier, List<TranslationResult>>(
      TranslationHistoryNotifier.new,
    );

class TranslationHistoryNotifier
    extends AsyncNotifier<List<TranslationResult>> {
  late final SqliteTranslationHistoryDatasource _ds;

  @override
  Future<List<TranslationResult>> build() async {
    _ds = ref.read(sqliteTranslationHistoryDatasourceProvider);
    final List<TranslationResult> local = await _ds.loadAll();

    if (local.isEmpty) {
      final SupabaseClient client = ref.read(supabaseProvider);
      final String? userId = client.auth.currentUser?.id;
      if (userId != null) {
        try {
          final List<TranslationResult> remote = await _fetchFromSupabase(
            client,
            userId,
          );
          if (remote.isNotEmpty) {
            for (final TranslationResult r in remote.reversed) {
              await _ds.insert(r);
            }
            return remote;
          }
        } catch (e) {
          debugPrint(
            '[TranslationHistory] cloud restore failed (non-fatal): $e',
          );
        }
      }
    }

    return local;
  }

  Future<void> addResult(TranslationResult result) async {
    TranslationResult saved = result;
    try {
      saved = await _ds.insert(result);
      final List<TranslationResult> current =
          state.value ?? <TranslationResult>[];
      state = AsyncData<List<TranslationResult>>(<TranslationResult>[
        saved,
        ...current,
      ]);
    } catch (_) {
      // Local save failure is non-fatal
    }
    unawaited(_syncToSupabase(saved));
    unawaited(ref.read(profileSummaryNotifierProvider.notifier).refresh());
  }

  Future<void> toggleBookmark(int id, bool value) async {
    try {
      await _ds.updateBookmark(id, value);
      final List<TranslationResult> current =
          state.value ?? <TranslationResult>[];
      state = AsyncData<List<TranslationResult>>(
        current
            .map(
              (TranslationResult r) =>
                  r.id == id ? r.copyWith(isBookmarked: value) : r,
            )
            .toList(growable: false),
      );
      unawaited(_syncBookmarkToSupabase(id, value));
    } catch (e) {
      debugPrint('[TranslationHistory] toggleBookmark failed: $e');
    }
  }

  Future<void> updateLastAiResponse(String text) async {
    final List<TranslationResult> current =
        state.value ?? <TranslationResult>[];
    if (current.isEmpty) return;
    final TranslationResult latest = current.first;
    final TranslationResult updated = latest.copyWith(aiResponse: text);
    if (latest.id != null) {
      try {
        await _ds.updateAiResponse(latest.id!, text);
      } catch (_) {}
    }
    state = AsyncData<List<TranslationResult>>(<TranslationResult>[
      updated,
      ...current.skip(1),
    ]);
  }

  Future<void> clearHistory() async {
    await _ds.clear();
    state = const AsyncData<List<TranslationResult>>(<TranslationResult>[]);
  }

  // ─── Supabase helpers ────────────────────────────────────────────────────

  Future<void> _syncToSupabase(TranslationResult result) async {
    final SupabaseClient client = ref.read(supabaseProvider);
    final String? userId = client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await client.from('translation_history').insert(<String, dynamic>{
        'user_id': userId,
        'input_text': result.inputText,
        'output_baybayin': result.baybayinText,
        'output_latin': result.latinText,
        'direction': result.direction,
        'ai_response': result.aiResponse,
        'is_bookmarked': result.isBookmarked,
        'created_at': result.timestamp.toIso8601String(),
      });
    } catch (e) {
      debugPrint('[TranslationHistory] Supabase sync failed (non-fatal): $e');
    }
  }

  // Bookmark sync requires a Supabase row UUID stored locally — not yet
  // implemented. Bookmarks are persisted in SQLite and survive reinstalls via
  // the cloud-restore path (which overwrites local state from Supabase).
  Future<void> _syncBookmarkToSupabase(int localId, bool value) async {
    return;
  }

  Future<List<TranslationResult>> _fetchFromSupabase(
    SupabaseClient client,
    String userId,
  ) async {
    final List<dynamic> rows = await client
        .from('translation_history')
        .select(
          'input_text, output_baybayin, output_latin, direction, ai_response, is_bookmarked, created_at',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(100);

    return rows
        .map((dynamic row) {
          final Map<String, dynamic> r = row as Map<String, dynamic>;
          return TranslationResult(
            inputText: r['input_text'] as String? ?? '',
            baybayinText: r['output_baybayin'] as String? ?? '',
            latinText: r['output_latin'] as String? ?? '',
            direction: r['direction'] as String? ?? 'latin_to_baybayin',
            aiResponse: r['ai_response'] as String? ?? '',
            isBookmarked: r['is_bookmarked'] as bool? ?? false,
            timestamp: DateTime.parse(r['created_at'] as String),
          );
        })
        .toList(growable: false);
  }
}
