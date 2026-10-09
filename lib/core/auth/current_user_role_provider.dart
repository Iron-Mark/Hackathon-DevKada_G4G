import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kudlit_ph/core/auth/user_role.dart';

part 'current_user_role_provider.g.dart';

/// Fetches and caches the current user's [UserRole] from `public.profiles`.
///
/// Returns [UserRole.user] when the user is unauthenticated or when the row
/// has no `role` set.  Throws if the DB call fails so callers can show an
/// error state.
@riverpod
Future<UserRole> currentUserRole(Ref ref) async {
  final SupabaseClient client = Supabase.instance.client;
  final User? user = client.auth.currentUser;
  if (user == null) return UserRole.user;

  final Map<String, dynamic>? row = await client
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .maybeSingle();

  return UserRole.fromString(row?['role'] as String?);
}
