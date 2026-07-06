import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:kudlit_ph/core/error/exceptions.dart';
import 'package:kudlit_ph/features/translator/domain/entities/chat_memory_fact.dart';

/// SQLite-backed long-term memory for the Butty chat.
///
/// On web, where `sqflite` is unavailable, this resolves to an in-memory
/// implementation that keeps facts for the current browser session only.
/// Supabase sync still provides cross-session persistence for authenticated
/// users.
///
/// Schema:
/// ```sql
/// CREATE TABLE chat_memory_facts (
///   id INTEGER PRIMARY KEY AUTOINCREMENT,
///   remote_id TEXT,
///   fact_type TEXT NOT NULL,
///   content TEXT NOT NULL,
///   normalized TEXT NOT NULL,           -- lower-cased, trimmed; for dedupe
///   created_at INTEGER NOT NULL,        -- epoch millis
///   last_referenced_at INTEGER NOT NULL
/// );
/// CREATE UNIQUE INDEX chat_memory_facts_norm ON chat_memory_facts(normalized);
/// ```
class SqliteChatMemoryDatasource {
  factory SqliteChatMemoryDatasource() {
    if (kIsWeb) return _InMemoryChatMemoryDatasource();
    return SqliteChatMemoryDatasource._native();
  }

  SqliteChatMemoryDatasource._native();

  static const String _dbName = 'kudlit_chat_memory.db';
  static const int _dbVersion = 1;
  static const String _table = 'chat_memory_facts';

  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final String dbPath = p.join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (Database db, int version) async {
        await _createSchema(db);
      },
    );
    return _db!;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id TEXT,
        fact_type TEXT NOT NULL,
        content TEXT NOT NULL,
        normalized TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_referenced_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS chat_memory_facts_norm '
      'ON $_table(normalized)',
    );
  }

  Future<List<ChatMemoryFact>> loadAll({int? limit}) async {
    try {
      final Database db = await _open();
      final List<Map<String, Object?>> rows = await db.query(
        _table,
        orderBy: 'created_at DESC',
        limit: limit,
      );
      return rows.map(_fromRow).toList(growable: false);
    } catch (e) {
      throw CacheException(message: 'Load chat memory failed: $e');
    }
  }

  /// Inserts the fact, ignoring duplicates by normalized content.
  /// Returns the persisted fact (with `id`) on success, null on dedupe-skip.
  Future<ChatMemoryFact?> insertIfNew(ChatMemoryFact fact) async {
    try {
      final Database db = await _open();
      final int id = await db.insert(
        _table,
        _toRow(fact),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      if (id == 0) return null; // duplicate — ignored
      return fact.copyWith(id: id);
    } catch (e) {
      throw CacheException(message: 'Save memory fact failed: $e');
    }
  }

  Future<void> setRemoteId({
    required int localId,
    required String remoteId,
  }) async {
    try {
      final Database db = await _open();
      await db.update(
        _table,
        <String, Object?>{'remote_id': remoteId},
        where: 'id = ?',
        whereArgs: <Object?>[localId],
      );
    } catch (e) {
      throw CacheException(message: 'Update memory remote_id failed: $e');
    }
  }

  /// Updates content/type for a fact identified by local [localId]. The
  /// `normalized` column is recomputed so the unique-content index stays
  /// consistent.
  Future<void> updateFact({
    required int localId,
    required String factType,
    required String content,
  }) async {
    try {
      final Database db = await _open();
      await db.update(
        _table,
        <String, Object?>{
          'fact_type': factType,
          'content': content,
          'normalized': normalize(content),
          'last_referenced_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: <Object?>[localId],
      );
    } catch (e) {
      throw CacheException(message: 'Update memory fact failed: $e');
    }
  }

  /// Reads a single row by local id. Used when we need the remote_id to
  /// mirror a delete to Supabase.
  Future<ChatMemoryFact?> findById(int localId) async {
    try {
      final Database db = await _open();
      final List<Map<String, Object?>> rows = await db.query(
        _table,
        where: 'id = ?',
        whereArgs: <Object?>[localId],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return _fromRow(rows.first);
    } catch (e) {
      throw CacheException(message: 'Find memory fact failed: $e');
    }
  }

  Future<void> deleteById(int localId) async {
    try {
      final Database db = await _open();
      await db.delete(_table, where: 'id = ?', whereArgs: <Object?>[localId]);
    } catch (e) {
      throw CacheException(message: 'Delete memory fact failed: $e');
    }
  }

  Future<void> clear() async {
    try {
      final Database db = await _open();
      await db.delete(_table);
    } catch (e) {
      throw CacheException(message: 'Clear chat memory failed: $e');
    }
  }

  Future<void> dispose() async {
    await _db?.close();
    _db = null;
  }

  static String normalize(String content) {
    return content.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  Map<String, Object?> _toRow(ChatMemoryFact f) {
    return <String, Object?>{
      'remote_id': f.remoteId,
      'fact_type': f.factType,
      'content': f.content,
      'normalized': normalize(f.content),
      'created_at': f.createdAt.millisecondsSinceEpoch,
      'last_referenced_at': f.lastReferencedAt.millisecondsSinceEpoch,
    };
  }

  ChatMemoryFact _fromRow(Map<String, Object?> row) {
    return ChatMemoryFact(
      id: row['id'] as int?,
      remoteId: row['remote_id'] as String?,
      factType: row['fact_type'] as String,
      content: row['content'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      lastReferencedAt: DateTime.fromMillisecondsSinceEpoch(
        row['last_referenced_at'] as int,
      ),
    );
  }
}

/// Web fallback: session-scoped in-memory chat memory store, keyed by
/// normalized content to honour the dedupe contract.
class _InMemoryChatMemoryDatasource extends SqliteChatMemoryDatasource {
  _InMemoryChatMemoryDatasource() : super._native();

  final Map<int, ChatMemoryFact> _factsById = <int, ChatMemoryFact>{};
  final Set<String> _normalizedSeen = <String>{};
  int _nextId = 1;

  @override
  Future<List<ChatMemoryFact>> loadAll({int? limit}) async {
    final List<ChatMemoryFact> sorted = _factsById.values.toList()
      ..sort(
        (ChatMemoryFact a, ChatMemoryFact b) =>
            b.createdAt.compareTo(a.createdAt),
      );
    if (limit == null || sorted.length <= limit) {
      return List<ChatMemoryFact>.unmodifiable(sorted);
    }
    return List<ChatMemoryFact>.unmodifiable(sorted.take(limit));
  }

  @override
  Future<ChatMemoryFact?> insertIfNew(ChatMemoryFact fact) async {
    final String normalized = SqliteChatMemoryDatasource.normalize(
      fact.content,
    );
    if (_normalizedSeen.contains(normalized)) return null;
    final ChatMemoryFact saved = fact.copyWith(id: _nextId++);
    _factsById[saved.id!] = saved;
    _normalizedSeen.add(normalized);
    return saved;
  }

  @override
  Future<void> setRemoteId({
    required int localId,
    required String remoteId,
  }) async {
    final ChatMemoryFact? existing = _factsById[localId];
    if (existing == null) return;
    _factsById[localId] = existing.copyWith(remoteId: remoteId);
  }

  @override
  Future<void> updateFact({
    required int localId,
    required String factType,
    required String content,
  }) async {
    final ChatMemoryFact? existing = _factsById[localId];
    if (existing == null) return;
    final String oldNorm = SqliteChatMemoryDatasource.normalize(
      existing.content,
    );
    final String newNorm = SqliteChatMemoryDatasource.normalize(content);
    _normalizedSeen
      ..remove(oldNorm)
      ..add(newNorm);
    _factsById[localId] = existing.copyWith(
      factType: factType,
      content: content,
      lastReferencedAt: DateTime.now(),
    );
  }

  @override
  Future<ChatMemoryFact?> findById(int localId) async {
    return _factsById[localId];
  }

  @override
  Future<void> deleteById(int localId) async {
    final ChatMemoryFact? existing = _factsById.remove(localId);
    if (existing == null) return;
    _normalizedSeen.remove(
      SqliteChatMemoryDatasource.normalize(existing.content),
    );
  }

  @override
  Future<void> clear() async {
    _factsById.clear();
    _normalizedSeen.clear();
    _nextId = 1;
  }

  @override
  Future<void> dispose() async {
    _factsById.clear();
    _normalizedSeen.clear();
    _nextId = 1;
  }
}
