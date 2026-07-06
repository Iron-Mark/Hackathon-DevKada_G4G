import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Local on-disk cache for Baybayin YOLO models.
///
/// Each catalog model is cached separately, keyed by its Supabase row id, so
/// switching the active model (camera vs. drawing pad, app-wide vs. per-screen)
/// does not force a redownload. A sidecar `.version` file records the
/// integer version that was downloaded — when the catalog version is bumped,
/// the cache is considered stale and is replaced on next use.
///
/// Layout:
///   `<app-support>/yolo_models/<id>.{tflite|mlpackage.zip}`
///   `<app-support>/yolo_models/<id>.version`   (text file, integer)
abstract class YoloModelCacheStore {
  Future<int?> downloadedVersion(String modelId);
  Future<String?> pathFor(String modelId);
  Future<bool> isUpToDate(String modelId, int version);
  Future<String> download(
    String modelId,
    String url, {
    required int version,
    void Function(int received, int total)? onProgress,
  });
  Future<void> clear(String modelId);
}

class YoloModelCache implements YoloModelCacheStore {
  YoloModelCache._();

  static final YoloModelCache instance = YoloModelCache._();

  /// Platform-specific extension for the YOLO model file.
  String get _extension => Platform.isIOS ? 'mlpackage.zip' : 'tflite';

  Future<Directory> _modelsDir() async {
    final Directory base = await getApplicationSupportDirectory();
    final Directory dir = Directory(p.join(base.path, 'yolo_models'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _modelFile(String modelId) async {
    final Directory dir = await _modelsDir();
    return File(p.join(dir.path, '$modelId.$_extension'));
  }

  Future<File> _versionFile(String modelId) async {
    final Directory dir = await _modelsDir();
    return File(p.join(dir.path, '$modelId.version'));
  }

  /// Returns the cached version integer for [modelId], or `null` if no
  /// downloaded copy exists.
  @override
  Future<int?> downloadedVersion(String modelId) async {
    final File model = await _modelFile(modelId);
    if (!model.existsSync()) return null;
    final File version = await _versionFile(modelId);
    if (!version.existsSync()) return 0; // legacy file from previous schema
    final String raw = (await version.readAsString()).trim();
    return int.tryParse(raw);
  }

  /// Returns the absolute path of the cached model for [modelId], or `null`
  /// if it has not been downloaded yet.
  @override
  Future<String?> pathFor(String modelId) async {
    final File file = await _modelFile(modelId);
    return file.existsSync() ? file.path : null;
  }

  /// True when a local copy exists at the requested [version] or newer.
  @override
  Future<bool> isUpToDate(String modelId, int version) async {
    final int? local = await downloadedVersion(modelId);
    return local != null && local >= version;
  }

  /// Downloads [url] for [modelId] and records [version] in the sidecar file.
  ///
  /// [onProgress] is called with `(bytesReceived, totalBytes)` each chunk;
  /// `totalBytes` is `-1` when the server does not send Content-Length.
  @override
  Future<String> download(
    String modelId,
    String url, {
    required int version,
    void Function(int received, int total)? onProgress,
  }) async {
    final File target = await _modelFile(modelId);
    final HttpClient client = HttpClient();
    try {
      final HttpClientRequest request = await client.getUrl(Uri.parse(url));
      final HttpClientResponse response = await request.close();
      if (response.statusCode != 200) {
        throw Exception(
          'YOLO model download failed — HTTP ${response.statusCode}',
        );
      }
      final int total = response.contentLength;
      int received = 0;
      final IOSink sink = target.openWrite();
      await for (final List<int> chunk in response) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
      await sink.close();
      // Only stamp the version after a successful write.
      final File versionFile = await _versionFile(modelId);
      await versionFile.writeAsString(version.toString(), flush: true);
    } catch (e) {
      if (target.existsSync()) await target.delete();
      rethrow;
    } finally {
      client.close();
    }
    debugPrint(
      '[YoloModelCache] downloaded $modelId v$version → ${target.path}',
    );
    return target.path;
  }

  /// Deletes the cached model file (and its version sidecar) for [modelId].
  @override
  Future<void> clear(String modelId) async {
    final File file = await _modelFile(modelId);
    if (file.existsSync()) await file.delete();
    final File version = await _versionFile(modelId);
    if (version.existsSync()) await version.delete();
    debugPrint('[YoloModelCache] cleared $modelId');
  }
}
