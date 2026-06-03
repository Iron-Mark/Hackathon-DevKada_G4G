import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:kudlit_ph/core/error/exceptions.dart';
import 'package:kudlit_ph/features/home/domain/entities/translation_result.dart';

/// SQLite-backed translation history store.
///
/// On web, where `sqflite` is unavailable, this resolves to an in-memory
/// implementation that keeps translation history for the current browser
/// session only. Supabase sync still provides cross-session persistence for
/// authenticated users.
class SqliteTranslationHistoryDatasource {
  factory SqliteTranslationHistoryDatasource() {
    if (kIsWeb) return _InMemoryTranslationHistoryDatasource();
    return SqliteTranslationHistoryDatasource._native();
  }

  SqliteTranslationHistoryDatasource._native();

  static const String _dbName = 'kudlit_translations.db';
  static const int _dbVersion = 1;
  static const String _table = 'translation_history';

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final String dbPath = p.join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id               INTEGER PRIMARY KEY AUTOINCREMENT,
            input_text       TEXT NOT NULL,
            output_baybayin  TEXT NOT NULL,
            output_latin     TEXT NOT NULL,
            direction        TEXT NOT NULL,
            ai_response      TEXT NOT NULL,
            is_bookmarked    INTEGER NOT NULL DEFAULT 0,
            timestamp        INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<List<TranslationResult>> loadAll({int? limit}) async {
    try {
      final Database db = await _open();
      final List<Map<String, Object?>> rows = await db.query(
        _table,
        orderBy: 'id DESC',
        limit: limit,
      );
      return rows.map(_fromRow).toList(growable: false);
    } catch (e) {
      throw CacheException(message: 'Load translation history failed: $e');
    }
  }

  Future<TranslationResult> insert(TranslationResult result) async {
    try {
      final Database db = await _open();
      final int id = await db.insert(_table, _toRow(result));
      return result.copyWith(id: id);
    } catch (e) {
      throw CacheException(message: 'Save translation result failed: $e');
    }
  }

  Future<void> updateBookmark(int id, bool value) async {
    try {
      final Database db = await _open();
      await db.update(
        _table,
        <String, Object?>{'is_bookmarked': value ? 1 : 0},
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
    } catch (e) {
      throw CacheException(message: 'Update bookmark failed: $e');
    }
  }

  Future<void> updateAiResponse(int id, String aiResponse) async {
    try {
      final Database db = await _open();
      await db.update(
        _table,
        <String, Object?>{'ai_response': aiResponse},
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
    } catch (e) {
      throw CacheException(message: 'Update AI response failed: $e');
    }
  }

  Future<void> clear() async {
    try {
      final Database db = await _open();
      await db.delete(_table);
    } catch (e) {
      throw CacheException(message: 'Clear translation history failed: $e');
    }
  }

  Future<void> dispose() async {
    await _db?.close();
    _db = null;
  }

  // ─── Mappers ──────────────────────────────────────────────────────────────

  Map<String, Object?> _toRow(TranslationResult r) {
    return <String, Object?>{
      'input_text': r.inputText,
      'output_baybayin': r.baybayinText,
      'output_latin': r.latinText,
      'direction': r.direction,
      'ai_response': r.aiResponse,
      'is_bookmarked': r.isBookmarked ? 1 : 0,
      'timestamp': r.timestamp.millisecondsSinceEpoch,
    };
  }

  TranslationResult _fromRow(Map<String, Object?> row) {
    return TranslationResult(
      id: row['id'] as int?,
      inputText: row['input_text'] as String,
      baybayinText: row['output_baybayin'] as String,
      latinText: row['output_latin'] as String,
      direction: row['direction'] as String,
      aiResponse: row['ai_response'] as String,
      isBookmarked: (row['is_bookmarked'] as int) == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
    );
  }
}

/// Web fallback: session-scoped in-memory translation history. Data is lost
/// on page reload — Supabase sync gives cross-session persistence for
/// authenticated users.
class _InMemoryTranslationHistoryDatasource
    extends SqliteTranslationHistoryDatasource {
  _InMemoryTranslationHistoryDatasource() : super._native();

  final Map<int, TranslationResult> _byId = <int, TranslationResult>{};
  int _nextId = 1;

  @override
  Future<List<TranslationResult>> loadAll({int? limit}) async {
    final List<TranslationResult> sorted = _byId.values.toList()
      ..sort(
        (TranslationResult a, TranslationResult b) =>
            (b.id ?? 0).compareTo(a.id ?? 0),
      );
    if (limit == null || sorted.length <= limit) {
      return List<TranslationResult>.unmodifiable(sorted);
    }
    return List<TranslationResult>.unmodifiable(sorted.take(limit));
  }

  @override
  Future<TranslationResult> insert(TranslationResult result) async {
    final int id = _nextId++;
    final TranslationResult saved = result.copyWith(id: id);
    _byId[id] = saved;
    return saved;
  }

  @override
  Future<void> updateBookmark(int id, bool value) async {
    final TranslationResult? existing = _byId[id];
    if (existing == null) return;
    _byId[id] = existing.copyWith(isBookmarked: value);
  }

  @override
  Future<void> updateAiResponse(int id, String aiResponse) async {
    final TranslationResult? existing = _byId[id];
    if (existing == null) return;
    _byId[id] = existing.copyWith(aiResponse: aiResponse);
  }

  @override
  Future<void> clear() async {
    _byId.clear();
    _nextId = 1;
  }

  @override
  Future<void> dispose() async {
    _byId.clear();
    _nextId = 1;
  }
}
