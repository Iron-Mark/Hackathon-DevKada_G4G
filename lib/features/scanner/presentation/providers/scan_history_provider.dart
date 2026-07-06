import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kudlit_ph/features/home/presentation/providers/profile_management_provider.dart';
import 'package:kudlit_ph/features/scanner/data/datasources/sqlite_scan_history_datasource.dart';
import 'package:kudlit_ph/features/scanner/domain/entities/scan_result.dart';

final Provider<SqliteScanHistoryDatasource>
sqliteScanHistoryDatasourceProvider = Provider<SqliteScanHistoryDatasource>((
  Ref ref,
) {
  final SqliteScanHistoryDatasource ds = SqliteScanHistoryDatasource();
  ref.onDispose(ds.dispose);
  return ds;
});

final AsyncNotifierProvider<ScanHistoryNotifier, List<ScanResult>>
scanHistoryNotifierProvider =
    AsyncNotifierProvider<ScanHistoryNotifier, List<ScanResult>>(
      ScanHistoryNotifier.new,
    );

class ScanHistoryNotifier extends AsyncNotifier<List<ScanResult>> {
  late final SqliteScanHistoryDatasource _ds;

  @override
  Future<List<ScanResult>> build() async {
    _ds = ref.read(sqliteScanHistoryDatasourceProvider);
    final List<ScanResult> local = await _ds.loadAll();

    // On an empty local store (e.g. fresh install), restore from Supabase.
    if (local.isEmpty) {
      final SupabaseClient client = ref.read(supabaseProvider);
      final String? userId = client.auth.currentUser?.id;
      if (userId != null) {
        try {
          final List<ScanResult> remote = await _fetchFromSupabase(
            client,
            userId,
          );
          if (remote.isNotEmpty) {
            for (final ScanResult r in remote.reversed) {
              await _ds.insert(r);
            }
            return remote;
          }
        } catch (e) {
          debugPrint('[ScanHistory] cloud restore failed (non-fatal): $e');
        }
      }
    }

    return local;
  }

  Future<void> addResult(ScanResult result) async {
    try {
      final ScanResult saved = await _ds.insert(result);
      final List<ScanResult> current = state.value ?? <ScanResult>[];
      state = AsyncData<List<ScanResult>>(<ScanResult>[saved, ...current]);
    } catch (_) {
      // Local save failure is non-fatal — UI already shows the result
    }
    unawaited(_syncToSupabase(result));
    unawaited(ref.read(profileSummaryNotifierProvider.notifier).refresh());
  }

  Future<void> clearHistory() async {
    await _ds.clear();
    state = const AsyncData<List<ScanResult>>(<ScanResult>[]);
  }

  // ─── Supabase helpers ────────────────────────────────────────────────────

  Future<void> _syncToSupabase(ScanResult result) async {
    final SupabaseClient client = ref.read(supabaseProvider);
    final String? userId = client.auth.currentUser?.id;
    if (userId == null) return; // Guest user — skip silently
    try {
      await client.from('scan_history').insert(<String, dynamic>{
        'user_id': userId,
        'tokens': jsonEncode(result.tokens),
        'translation': result.translation,
        'scanned_at': result.timestamp.toIso8601String(),
      });
    } catch (e) {
      debugPrint('[ScanHistory] Supabase sync failed (non-fatal): $e');
    }
  }

  Future<List<ScanResult>> _fetchFromSupabase(
    SupabaseClient client,
    String userId,
  ) async {
    final List<dynamic> rows = await client
        .from('scan_history')
        .select('tokens, translation, scanned_at')
        .eq('user_id', userId)
        .order('scanned_at', ascending: false)
        .limit(100);

    return rows
        .map((dynamic row) {
          final Map<String, dynamic> r = row as Map<String, dynamic>;
          final dynamic rawTokens = r['tokens'];
          final List<String> tokens = rawTokens is List
              ? rawTokens.cast<String>()
              : (jsonDecode(rawTokens as String) as List<dynamic>)
                    .cast<String>();
          return ScanResult(
            tokens: tokens,
            translation: r['translation'] as String? ?? '',
            timestamp: DateTime.parse(r['scanned_at'] as String),
          );
        })
        .toList(growable: false);
  }
}
