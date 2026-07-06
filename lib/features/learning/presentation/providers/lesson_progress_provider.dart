import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kudlit_ph/features/home/presentation/providers/app_preferences_provider.dart';
import 'package:kudlit_ph/features/home/presentation/providers/profile_management_provider.dart';
import 'package:kudlit_ph/features/learning/data/datasources/sqlite_lesson_progress_datasource.dart';
import 'package:kudlit_ph/features/learning/domain/entities/lesson_progress.dart';

final Provider<SqliteLessonProgressDatasource>
sqliteLessonProgressDatasourceProvider =
    Provider<SqliteLessonProgressDatasource>((Ref ref) {
      final SqliteLessonProgressDatasource ds =
          SqliteLessonProgressDatasource();
      ref.onDispose(ds.dispose);
      return ds;
    });

final AsyncNotifierProvider<LessonProgressNotifier, Map<String, LessonProgress>>
lessonProgressNotifierProvider =
    AsyncNotifierProvider<LessonProgressNotifier, Map<String, LessonProgress>>(
      LessonProgressNotifier.new,
    );

class LessonProgressNotifier
    extends AsyncNotifier<Map<String, LessonProgress>> {
  late final SqliteLessonProgressDatasource _ds;

  @override
  Future<Map<String, LessonProgress>> build() async {
    _ds = ref.read(sqliteLessonProgressDatasourceProvider);
    final List<LessonProgress> local = await _ds.loadAll();

    if (local.isEmpty) {
      final SupabaseClient client = ref.read(supabaseProvider);
      final String? userId = client.auth.currentUser?.id;
      if (userId != null) {
        try {
          final List<LessonProgress> remote = await _fetchFromSupabase(
            client,
            userId,
          );
          if (remote.isNotEmpty) {
            for (final LessonProgress r in remote) {
              await _ds.save(r);
            }
            return _toMap(remote);
          }
        } catch (e) {
          debugPrint('[LessonProgress] cloud restore failed (non-fatal): $e');
        }
      }
    }

    return _toMap(local);
  }

  LessonProgress? forLesson(String lessonId) => state.value?[lessonId];

  Future<void> saveProgress(LessonProgress progress) async {
    try {
      await _ds.save(progress);
      final Map<String, LessonProgress> current =
          Map<String, LessonProgress>.from(state.value ?? {});
      current[progress.lessonId] = progress;
      state = AsyncData<Map<String, LessonProgress>>(current);

      if (progress.completed) {
        unawaited(
          ref
              .read(appPreferencesNotifierProvider.notifier)
              .completeLesson(progress.lessonId),
        );
      }
    } catch (_) {
      // Local save failure is non-fatal
    }

    if (progress.completed) {
      // Await the Supabase write so completed=true exists in the DB before
      // the profile summary count query runs.
      await _syncToSupabase(progress);
      unawaited(ref.read(profileSummaryNotifierProvider.notifier).refresh());
    } else {
      unawaited(_syncToSupabase(progress));
    }
  }

  // ─── Supabase helpers ────────────────────────────────────────────────────

  Future<void> _syncToSupabase(LessonProgress progress) async {
    final SupabaseClient client = ref.read(supabaseProvider);
    final String? userId = client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await client.from('learning_progress').upsert(<String, dynamic>{
        'user_id': userId,
        'lesson_id': progress.lessonId,
        'current_step': progress.currentStepIndex,
        'total_steps': progress.totalSteps,
        'completed': progress.completed,
        'score': progress.score,
        'updated_at': progress.lastModified.toIso8601String(),
        if (progress.completedAt != null)
          'completed_at': progress.completedAt!.toIso8601String(),
      }, onConflict: 'user_id,lesson_id');
    } catch (e) {
      debugPrint('[LessonProgress] Supabase sync failed (non-fatal): $e');
    }
  }

  Future<List<LessonProgress>> _fetchFromSupabase(
    SupabaseClient client,
    String userId,
  ) async {
    final List<dynamic> rows = await client
        .from('learning_progress')
        .select(
          'lesson_id, current_step, total_steps, completed, score, updated_at, completed_at',
        )
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .limit(20);

    return rows
        .map((dynamic row) {
          final Map<String, dynamic> r = row as Map<String, dynamic>;
          final String? completedAtStr = r['completed_at'] as String?;
          final String updatedAtStr =
              r['updated_at'] as String? ?? DateTime.now().toIso8601String();
          return LessonProgress(
            lessonId: r['lesson_id'] as String,
            currentStepIndex: r['current_step'] as int? ?? 0,
            totalSteps: r['total_steps'] as int? ?? 0,
            completed: r['completed'] as bool? ?? false,
            score: r['score'] as int? ?? 0,
            lastModified: DateTime.parse(updatedAtStr),
            completedAt: completedAtStr != null
                ? DateTime.parse(completedAtStr)
                : null,
          );
        })
        .toList(growable: false);
  }

  static Map<String, LessonProgress> _toMap(List<LessonProgress> list) {
    return <String, LessonProgress>{
      for (final LessonProgress p in list) p.lessonId: p,
    };
  }
}
