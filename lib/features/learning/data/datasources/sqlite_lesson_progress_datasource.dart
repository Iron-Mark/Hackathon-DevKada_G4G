import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:kudlit_ph/core/error/exceptions.dart';
import 'package:kudlit_ph/features/learning/domain/entities/lesson_progress.dart';

/// SQLite-backed lesson progress store.
///
/// On web, where `sqflite` is unavailable, this resolves to an in-memory
/// implementation keyed by `lesson_id` for the current browser session.
/// Supabase still acts as the source of truth across sessions — the
/// notifier seeds the in-memory cache from Supabase on cold start.
class SqliteLessonProgressDatasource {
  factory SqliteLessonProgressDatasource() {
    if (kIsWeb) return _InMemoryLessonProgressDatasource();
    return SqliteLessonProgressDatasource._native();
  }

  SqliteLessonProgressDatasource._native();

  static const String _dbName = 'kudlit_learning.db';
  static const int _dbVersion = 1;
  static const String _table = 'lesson_progress';

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
            lesson_id     TEXT PRIMARY KEY,
            current_step  INTEGER NOT NULL DEFAULT 0,
            total_steps   INTEGER NOT NULL DEFAULT 0,
            completed     INTEGER NOT NULL DEFAULT 0,
            score         INTEGER NOT NULL DEFAULT 0,
            last_modified INTEGER NOT NULL,
            completed_at  INTEGER
          )
        ''');
      },
    );
    return _db!;
  }

  Future<List<LessonProgress>> loadAll() async {
    try {
      final Database db = await _open();
      final List<Map<String, Object?>> rows = await db.query(
        _table,
        orderBy: 'last_modified DESC',
      );
      return rows.map(_fromRow).toList(growable: false);
    } catch (e) {
      throw CacheException(message: 'Load lesson progress failed: $e');
    }
  }

  Future<LessonProgress?> loadForLesson(String lessonId) async {
    try {
      final Database db = await _open();
      final List<Map<String, Object?>> rows = await db.query(
        _table,
        where: 'lesson_id = ?',
        whereArgs: <Object?>[lessonId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return _fromRow(rows.first);
    } catch (e) {
      throw CacheException(message: 'Load lesson progress failed: $e');
    }
  }

  Future<void> save(LessonProgress progress) async {
    try {
      final Database db = await _open();
      await db.insert(
        _table,
        _toRow(progress),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException(message: 'Save lesson progress failed: $e');
    }
  }

  Future<void> clear() async {
    try {
      final Database db = await _open();
      await db.delete(_table);
    } catch (e) {
      throw CacheException(message: 'Clear lesson progress failed: $e');
    }
  }

  Future<void> dispose() async {
    await _db?.close();
    _db = null;
  }

  // ─── Mappers ──────────────────────────────────────────────────────────────

  Map<String, Object?> _toRow(LessonProgress r) {
    return <String, Object?>{
      'lesson_id': r.lessonId,
      'current_step': r.currentStepIndex,
      'total_steps': r.totalSteps,
      'completed': r.completed ? 1 : 0,
      'score': r.score,
      'last_modified': r.lastModified.millisecondsSinceEpoch,
      'completed_at': r.completedAt?.millisecondsSinceEpoch,
    };
  }

  LessonProgress _fromRow(Map<String, Object?> row) {
    final Object? completedAtMs = row['completed_at'];
    return LessonProgress(
      lessonId: row['lesson_id'] as String,
      currentStepIndex: row['current_step'] as int,
      totalSteps: row['total_steps'] as int,
      completed: (row['completed'] as int) == 1,
      score: row['score'] as int,
      lastModified: DateTime.fromMillisecondsSinceEpoch(
        row['last_modified'] as int,
      ),
      completedAt: completedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(completedAtMs as int)
          : null,
    );
  }
}

/// Web fallback: session-scoped in-memory lesson progress, keyed by
/// `lesson_id` (mirrors the SQLite primary key). Replaced on conflict to
/// match the native `ConflictAlgorithm.replace` semantics.
class _InMemoryLessonProgressDatasource extends SqliteLessonProgressDatasource {
  _InMemoryLessonProgressDatasource() : super._native();

  final Map<String, LessonProgress> _byLessonId = <String, LessonProgress>{};

  @override
  Future<List<LessonProgress>> loadAll() async {
    final List<LessonProgress> sorted = _byLessonId.values.toList()
      ..sort(
        (LessonProgress a, LessonProgress b) =>
            b.lastModified.compareTo(a.lastModified),
      );
    return List<LessonProgress>.unmodifiable(sorted);
  }

  @override
  Future<LessonProgress?> loadForLesson(String lessonId) async {
    return _byLessonId[lessonId];
  }

  @override
  Future<void> save(LessonProgress progress) async {
    _byLessonId[progress.lessonId] = progress;
  }

  @override
  Future<void> clear() async {
    _byLessonId.clear();
  }

  @override
  Future<void> dispose() async {
    _byLessonId.clear();
  }
}
