import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:kudlit_ph/core/error/exceptions.dart';
import 'package:kudlit_ph/features/scanner/domain/entities/scan_result.dart';

/// SQLite-backed scan result history store.
///
/// On web, where `sqflite` is unavailable, this resolves to an in-memory
/// implementation that keeps scan history for the current browser session
/// only. Supabase sync still provides cross-session persistence for
/// authenticated users.
///
/// Schema:
/// ```sql
/// CREATE TABLE scan_history (
///   id INTEGER PRIMARY KEY AUTOINCREMENT,
///   tokens TEXT NOT NULL,       -- JSON array of YOLO label strings
///   translation TEXT NOT NULL,  -- Butty's full response
///   timestamp INTEGER NOT NULL  -- epoch millis
/// );
/// ```
class SqliteScanHistoryDatasource {
  factory SqliteScanHistoryDatasource() {
    if (kIsWeb) return _InMemoryScanHistoryDatasource();
    return SqliteScanHistoryDatasource._native();
  }

  SqliteScanHistoryDatasource._native();

  static const String _dbName = 'kudlit_scan.db';
  static const int _dbVersion = 1;
  static const String _table = 'scan_history';

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
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tokens TEXT NOT NULL,
            translation TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<List<ScanResult>> loadAll({int? limit}) async {
    try {
      final Database db = await _open();
      final List<Map<String, Object?>> rows = await db.query(
        _table,
        orderBy: 'id DESC',
        limit: limit,
      );
      return rows.map(_fromRow).toList(growable: false);
    } catch (e) {
      throw CacheException(message: 'Load scan history failed: $e');
    }
  }

  Future<ScanResult> insert(ScanResult result) async {
    try {
      final Database db = await _open();
      final int id = await db.insert(_table, _toRow(result));
      return result.copyWith(id: id);
    } catch (e) {
      throw CacheException(message: 'Save scan result failed: $e');
    }
  }

  Future<void> clear() async {
    try {
      final Database db = await _open();
      await db.delete(_table);
    } catch (e) {
      throw CacheException(message: 'Clear scan history failed: $e');
    }
  }

  Future<void> dispose() async {
    await _db?.close();
    _db = null;
  }

  // ─── Mappers ──────────────────────────────────────────────────────────────

  Map<String, Object?> _toRow(ScanResult r) {
    return <String, Object?>{
      'tokens': jsonEncode(r.tokens),
      'translation': r.translation,
      'timestamp': r.timestamp.millisecondsSinceEpoch,
    };
  }

  ScanResult _fromRow(Map<String, Object?> row) {
    final List<dynamic> decoded =
        jsonDecode(row['tokens'] as String) as List<dynamic>;
    return ScanResult(
      id: row['id'] as int?,
      tokens: decoded.cast<String>(),
      translation: row['translation'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(row['timestamp'] as int),
    );
  }
}

/// Web fallback: session-scoped in-memory scan history. Data is lost on page
/// reload — Supabase sync gives cross-session persistence for authenticated
/// users.
class _InMemoryScanHistoryDatasource extends SqliteScanHistoryDatasource {
  _InMemoryScanHistoryDatasource() : super._native();

  final List<ScanResult> _results = <ScanResult>[];
  int _nextId = 1;

  @override
  Future<List<ScanResult>> loadAll({int? limit}) async {
    final List<ScanResult> sorted = List<ScanResult>.from(_results)
      ..sort((ScanResult a, ScanResult b) => (b.id ?? 0).compareTo(a.id ?? 0));
    if (limit == null || sorted.length <= limit) {
      return List<ScanResult>.unmodifiable(sorted);
    }
    return List<ScanResult>.unmodifiable(sorted.take(limit));
  }

  @override
  Future<ScanResult> insert(ScanResult result) async {
    final ScanResult saved = result.copyWith(id: _nextId++);
    _results.add(saved);
    return saved;
  }

  @override
  Future<void> clear() async {
    _results.clear();
    _nextId = 1;
  }

  @override
  Future<void> dispose() async {
    _results.clear();
    _nextId = 1;
  }
}
