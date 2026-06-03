import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:kudlit_ph/core/error/exceptions.dart';
import 'package:kudlit_ph/features/home/data/models/profile_preferences_model.dart';
import 'package:kudlit_ph/features/home/data/models/profile_summary_model.dart';

abstract interface class LocalProfileManagementDatasource {
  Future<ProfileSummaryModel?> getCachedSummary({required String userId});
  Future<void> cacheSummary({
    required String userId,
    required ProfileSummaryModel summary,
  });
  Future<void> clearCachedSummary({required String userId});
  Future<ProfilePreferencesModel?> getCachedPreferences({
    required String userId,
  });
  Future<void> cachePreferences({
    required String userId,
    required ProfilePreferencesModel preferences,
  });
  Future<void> dispose();
}

class SqfliteProfileManagementDatasource
    implements LocalProfileManagementDatasource {
  factory SqfliteProfileManagementDatasource() {
    if (kIsWeb) return _WebProfileManagementDatasource();
    return SqfliteProfileManagementDatasource._native();
  }

  SqfliteProfileManagementDatasource._native();

  static const String _dbName = 'kudlit_profile.db';
  static const int _dbVersion = 2;
  static const String _summaryTable = 'profile_summary';
  static const String _preferencesTable = 'profile_preferences';

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final String dbPath = p.join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $_summaryTable (
            user_id TEXT PRIMARY KEY,
            display_name TEXT,
            avatar_url TEXT,
            completed_lessons INTEGER NOT NULL DEFAULT 0,
            scan_history_items INTEGER NOT NULL DEFAULT 0,
            translation_history_items INTEGER NOT NULL DEFAULT 0,
            bookmarked_translations INTEGER NOT NULL DEFAULT 0,
            cached_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $_preferencesTable (
            user_id TEXT PRIMARY KEY,
            high_contrast INTEGER NOT NULL DEFAULT 0,
            reduced_motion INTEGER NOT NULL DEFAULT 0,
            data_sharing_consent INTEGER NOT NULL DEFAULT 0,
            cached_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_summaryTable ADD COLUMN avatar_url TEXT',
          );
        }
      },
    );
    return _db!;
  }

  @override
  Future<ProfileSummaryModel?> getCachedSummary({
    required String userId,
  }) async {
    try {
      final Database db = await _open();
      final List<Map<String, Object?>> rows = await db.query(
        _summaryTable,
        where: 'user_id = ?',
        whereArgs: <Object?>[userId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return _summaryFromRow(rows.first);
    } catch (e) {
      throw CacheException(message: 'Load profile summary failed: $e');
    }
  }

  @override
  Future<void> cacheSummary({
    required String userId,
    required ProfileSummaryModel summary,
  }) async {
    try {
      final Database db = await _open();
      await db.insert(
        _summaryTable,
        _summaryToRow(userId, summary),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException(message: 'Cache profile summary failed: $e');
    }
  }

  @override
  Future<void> clearCachedSummary({required String userId}) async {
    try {
      final Database db = await _open();
      await db.delete(
        _summaryTable,
        where: 'user_id = ?',
        whereArgs: <Object?>[userId],
      );
    } catch (e) {
      throw CacheException(message: 'Clear profile summary cache failed: $e');
    }
  }

  @override
  Future<ProfilePreferencesModel?> getCachedPreferences({
    required String userId,
  }) async {
    try {
      final Database db = await _open();
      final List<Map<String, Object?>> rows = await db.query(
        _preferencesTable,
        where: 'user_id = ?',
        whereArgs: <Object?>[userId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return _preferencesFromRow(rows.first);
    } catch (e) {
      throw CacheException(message: 'Load preferences failed: $e');
    }
  }

  @override
  Future<void> cachePreferences({
    required String userId,
    required ProfilePreferencesModel preferences,
  }) async {
    try {
      final Database db = await _open();
      await db.insert(
        _preferencesTable,
        _preferencesToRow(userId, preferences),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException(message: 'Cache preferences failed: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await _db?.close();
    _db = null;
  }

  // ─── Mappers ────────────────────────────────────────────────────────────────

  Map<String, Object?> _summaryToRow(
    String userId,
    ProfileSummaryModel summary,
  ) {
    return <String, Object?>{
      'user_id': userId,
      'display_name': summary.displayName,
      'avatar_url': summary.avatarUrl,
      'completed_lessons': summary.completedLessons,
      'scan_history_items': summary.scanHistoryItems,
      'translation_history_items': summary.translationHistoryItems,
      'bookmarked_translations': summary.bookmarkedTranslations,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  ProfileSummaryModel _summaryFromRow(Map<String, Object?> row) {
    return ProfileSummaryModel(
      displayName: row['display_name'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      completedLessons: row['completed_lessons'] as int,
      scanHistoryItems: row['scan_history_items'] as int,
      translationHistoryItems: row['translation_history_items'] as int,
      bookmarkedTranslations: row['bookmarked_translations'] as int,
    );
  }

  Map<String, Object?> _preferencesToRow(
    String userId,
    ProfilePreferencesModel prefs,
  ) {
    return <String, Object?>{
      'user_id': userId,
      'high_contrast': prefs.highContrast ? 1 : 0,
      'reduced_motion': prefs.reducedMotion ? 1 : 0,
      'data_sharing_consent': prefs.dataSharingConsent ? 1 : 0,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  ProfilePreferencesModel _preferencesFromRow(Map<String, Object?> row) {
    return ProfilePreferencesModel(
      highContrast: (row['high_contrast'] as int) == 1,
      reducedMotion: (row['reduced_motion'] as int) == 1,
      dataSharingConsent: (row['data_sharing_consent'] as int) == 1,
    );
  }
}

/// Web fallback: graceful no-op cache. `ProfileManagementRepositoryImpl`
/// already treats the local layer as a best-effort cache with a remote
/// fallback, so always-miss reads + silent writes keep web functional —
/// every read just hits Supabase. We log the first cache miss so the
/// degraded mode is discoverable in DevTools.
class _WebProfileManagementDatasource extends SqfliteProfileManagementDatasource
    implements LocalProfileManagementDatasource {
  _WebProfileManagementDatasource() : super._native();

  bool _loggedDegradedMode = false;

  void _logOnce() {
    if (_loggedDegradedMode) return;
    _loggedDegradedMode = true;
    debugPrint(
      '[ProfileManagement] sqflite unavailable on web — '
      'profile cache disabled, reads will fall through to Supabase.',
    );
  }

  @override
  Future<ProfileSummaryModel?> getCachedSummary({
    required String userId,
  }) async {
    _logOnce();
    return null;
  }

  @override
  Future<void> cacheSummary({
    required String userId,
    required ProfileSummaryModel summary,
  }) async {
    _logOnce();
  }

  @override
  Future<void> clearCachedSummary({required String userId}) async {
    _logOnce();
  }

  @override
  Future<ProfilePreferencesModel?> getCachedPreferences({
    required String userId,
  }) async {
    _logOnce();
    return null;
  }

  @override
  Future<void> cachePreferences({
    required String userId,
    required ProfilePreferencesModel preferences,
  }) async {
    _logOnce();
  }

  @override
  Future<void> dispose() async {}
}
