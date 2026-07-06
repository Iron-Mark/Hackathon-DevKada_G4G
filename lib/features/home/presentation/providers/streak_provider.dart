import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kudlit_ph/features/home/presentation/providers/profile_management_provider.dart';

part 'streak_provider.g.dart';

/// Returns the user's current consecutive-day learning streak.
///
/// A streak is the number of calendar days in a row (ending today or
/// yesterday) on which the user completed at least one lesson. Derived
/// purely from [learning_progress.completed_at] — no new table needed.
///
/// Returns 0 for unauthenticated users or on any network error.
@riverpod
Future<int> streak(Ref ref) async {
  final SupabaseClient client = ref.watch(supabaseProvider);
  final String? userId = client.auth.currentUser?.id;
  if (userId == null) return 0;

  try {
    final List<Map<String, dynamic>> rows = await client
        .from('learning_progress')
        .select('completed_at')
        .eq('user_id', userId)
        .eq('completed', true)
        .not('completed_at', 'is', null)
        .order('completed_at', ascending: false);
    return _computeStreak(rows);
  } catch (_) {
    return 0;
  }
}

int _computeStreak(List<Map<String, dynamic>> rows) {
  final Set<String> completionDates = rows.map((Map<String, dynamic> r) {
    final DateTime d = DateTime.parse(r['completed_at'] as String).toLocal();
    return _dateKey(d);
  }).toSet();

  if (completionDates.isEmpty) return 0;

  final DateTime now = DateTime.now();
  DateTime cursor = DateTime(now.year, now.month, now.day);

  // If the user hasn't completed anything today, allow the streak to
  // extend from yesterday (streak is still alive).
  if (!completionDates.contains(_dateKey(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
  }

  int streak = 0;
  while (completionDates.contains(_dateKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
