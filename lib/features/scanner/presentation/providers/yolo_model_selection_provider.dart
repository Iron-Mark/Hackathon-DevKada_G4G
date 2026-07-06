import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import 'package:kudlit_ph/features/scanner/data/datasources/web_vision_model_preflight.dart';
import 'package:kudlit_ph/features/scanner/data/datasources/yolo_model_cache.dart';
import 'package:kudlit_ph/features/translator/data/datasources/supabase_ai_models_datasource.dart';
import 'package:kudlit_ph/features/translator/domain/entities/ai_model_info.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/translator_providers.dart';

/// Well-known scope identifiers used by screens that consume the YOLO model.
///
/// New screens should add their own constant here so the dropdown widget and
/// the persisted override map share a single source of truth.
class YoloModelScope {
  YoloModelScope._();

  /// Sentinel scope key for the app-wide default.
  static const String global = '_global';

  /// Live camera viewfinder (scan tab).
  static const String camera = 'camera';

  /// Drawing pad (translate tab — finger drawing).
  static const String drawingPad = 'drawing_pad';
}

// ─── Selection state ─────────────────────────────────────────────────────────

/// Per-scope YOLO model selection.
///
/// [globalId] is the app-wide default. [overrides] maps a scope key
/// (see [YoloModelScope]) to a model id that overrides [globalId] for
/// that scope. Both fields may be null/empty before the user has chosen
/// anything.
@immutable
class YoloModelSelection {
  const YoloModelSelection({
    this.globalId,
    this.overrides = const <String, String>{},
  });

  final String? globalId;
  final Map<String, String> overrides;

  /// Resolves the selected model id for [scope], falling back through:
  ///   1. per-scope override
  ///   2. app-wide [globalId]
  /// Returns null if neither has been set yet.
  String? idFor(String scope) {
    final String? override = overrides[scope];
    if (override != null && override.isNotEmpty) return override;
    return globalId;
  }

  YoloModelSelection copyWith({
    String? globalId,
    Map<String, String>? overrides,
    bool clearGlobal = false,
  }) {
    return YoloModelSelection(
      globalId: clearGlobal ? null : (globalId ?? this.globalId),
      overrides: overrides ?? this.overrides,
    );
  }
}

// ─── Persistence ─────────────────────────────────────────────────────────────

const String _kGlobalKey = 'yolo_model_global';
const String _kOverridesKey = 'yolo_model_overrides';

class YoloModelSelectionNotifier extends AsyncNotifier<YoloModelSelection> {
  late SharedPreferences _prefs;

  @override
  Future<YoloModelSelection> build() async {
    _prefs = await SharedPreferences.getInstance();
    final String? globalId = _prefs.getString(_kGlobalKey);
    final String? raw = _prefs.getString(_kOverridesKey);
    final Map<String, String> overrides = raw == null
        ? const <String, String>{}
        : Map<String, String>.from(
            (jsonDecode(raw) as Map<dynamic, dynamic>).map(
              (dynamic k, dynamic v) =>
                  MapEntry<String, String>(k as String, v as String),
            ),
          );
    return YoloModelSelection(globalId: globalId, overrides: overrides);
  }

  Future<void> setForScope(String scope, String modelId) async {
    final YoloModelSelection current = state.requireValue;
    if (scope == YoloModelScope.global) {
      state = AsyncData(current.copyWith(globalId: modelId));
      await _prefs.setString(_kGlobalKey, modelId);
      return;
    }
    final Map<String, String> next = <String, String>{
      ...current.overrides,
      scope: modelId,
    };
    state = AsyncData(current.copyWith(overrides: next));
    await _prefs.setString(_kOverridesKey, jsonEncode(next));
  }

  Future<void> clearScope(String scope) async {
    final YoloModelSelection current = state.requireValue;
    if (scope == YoloModelScope.global) {
      state = AsyncData(current.copyWith(clearGlobal: true));
      await _prefs.remove(_kGlobalKey);
      return;
    }
    final Map<String, String> next = <String, String>{...current.overrides}
      ..remove(scope);
    state = AsyncData(current.copyWith(overrides: next));
    await _prefs.setString(_kOverridesKey, jsonEncode(next));
  }
}

final yoloModelSelectionProvider =
    AsyncNotifierProvider<YoloModelSelectionNotifier, YoloModelSelection>(
      YoloModelSelectionNotifier.new,
    );

final yoloModelCacheProvider = Provider<YoloModelCacheStore>((Ref ref) {
  return YoloModelCache.instance;
});

// ─── Catalog ─────────────────────────────────────────────────────────────────

/// All enabled vision models from the Supabase catalog, ordered by `sort_order`.
///
/// Only rows with `model_type = 'vision'` are returned — these are the YOLO
/// TFLite / mlpackage files used for OCR and camera detection.
/// Disabled rows (`enabled = false`) are filtered out at the data source.
final availableYoloModelsProvider = FutureProvider<List<AiModelInfo>>((
  Ref ref,
) async {
  final SupabaseAiModelsDatasource ds = ref.watch(
    supabaseAiModelsDatasourceProvider,
  );
  final List<AiModelInfo> models = await ds.fetchModels(type: ModelKind.vision);
  // Catalog doesn't change at runtime — keep alive to avoid re-fetching on
  // every scan tab visit.
  ref.keepAlive();
  return models;
});

/// Download percentage for a YOLO model scope while its local path resolves.
///
/// `null` means no measured download is active. This lets the scanner keep the
/// normal spinner for catalog/path checks and switch to a percentage only when
/// the HTTP response reports a content length.
final yoloModelDownloadProgressProvider = StateProvider.family<int?, String>((
  Ref ref,
  String scope,
) {
  return null;
});

// ─── Scope-aware resolution ──────────────────────────────────────────────────

/// Resolves the active [AiModelInfo] for [scope].
///
/// Resolution order:
///   1. per-scope override
///   2. app-wide global selection
///   3. first enabled model in the catalog (fallback default)
///
/// Returns null only if the catalog is empty.
final activeYoloModelProvider =
    Provider.family<AsyncValue<AiModelInfo?>, String>((Ref ref, String scope) {
      final AsyncValue<List<AiModelInfo>> modelsAsync = ref.watch(
        availableYoloModelsProvider,
      );
      final AsyncValue<YoloModelSelection> selectionAsync = ref.watch(
        yoloModelSelectionProvider,
      );

      return modelsAsync.whenData((List<AiModelInfo> models) {
        if (models.isEmpty) return null;
        final YoloModelSelection? selection = selectionAsync.value;
        final String? selectedId = selection?.idFor(scope);
        if (selectedId != null) {
          for (final AiModelInfo m in models) {
            if (m.id == selectedId) return m;
          }
        }
        return models.first;
      });
    });

// ─── Local file path (download on demand) ────────────────────────────────────

/// Returns the local filesystem path to the YOLO model file for [scope].
///
/// Downloads the active model on first use, or whenever the catalog `version`
/// is greater than the locally cached version. Throws if the catalog has no
/// enabled rows.
///
/// On web returns an empty string — the camera widget short-circuits with a
/// fallback view before this is dereferenced.
final yoloModelPathProvider = FutureProvider.family<String, String>((
  Ref ref,
  String scope,
) async {
  if (kIsWeb) return '';

  final AsyncValue<AiModelInfo?> activeAsync = ref.watch(
    activeYoloModelProvider(scope),
  );
  final AiModelInfo? model = activeAsync.when(
    data: (AiModelInfo? m) => m,
    loading: () => null,
    error: (Object _, StackTrace _) => null,
  );

  if (activeAsync.isLoading) {
    throw const _YoloModelLoadingState();
  }
  if (model == null) {
    throw StateError('No enabled Baybayin models configured.');
  }

  final String url = resolveYoloModelUrl(model);
  if (url.isEmpty) {
    throw StateError('Selected model "${model.name}" has no download URL.');
  }

  ref.read(yoloModelDownloadProgressProvider(scope).notifier).state = null;
  final YoloModelCacheStore cache = ref.read(yoloModelCacheProvider);
  final bool upToDate = await cache.isUpToDate(model.id, model.version);
  if (!upToDate) {
    ref.read(yoloModelDownloadProgressProvider(scope).notifier).state = 0;
    await cache.download(
      model.id,
      url,
      version: model.version,
      onProgress: (int received, int total) {
        if (total <= 0) return;
        final int percent = ((received / total) * 100)
            .round()
            .clamp(0, 100)
            .toInt();
        ref.read(yoloModelDownloadProgressProvider(scope).notifier).state =
            percent;
      },
    );
    ref.read(yoloModelDownloadProgressProvider(scope).notifier).state = 100;
  }
  final String? path = await cache.pathFor(model.id);
  if (path == null) {
    throw StateError('YOLO model download succeeded but no file is on disk.');
  }
  // Keep the resolved path alive so navigating away from the scan tab and
  // back doesn't re-trigger the download-check → loading sequence.
  ref.keepAlive();
  return path;
});

String resolveYoloModelUrl(AiModelInfo model) {
  if (kIsWeb) return model.modelLink;
  // dart:io is safe here because kIsWeb guards above.
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return model.iosModelLink ?? model.modelLink;
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return model.androidModelLink ?? model.modelLink;
  }
  return model.modelLink;
}

@immutable
class VisionModelSetupStatus {
  const VisionModelSetupStatus({
    required this.ready,
    required this.title,
    required this.message,
    this.model,
  });

  final bool ready;
  final String title;
  final String message;
  final AiModelInfo? model;
}

final FutureProvider<VisionModelSetupStatus> visionModelSetupStatusProvider =
    FutureProvider<VisionModelSetupStatus>((Ref ref) async {
      final List<AiModelInfo> models = await ref.watch(
        availableYoloModelsProvider.future,
      );
      if (models.isEmpty) {
        return const VisionModelSetupStatus(
          ready: false,
          title: 'Scanner setup unavailable',
          message: 'Scanning is not ready yet.',
        );
      }

      final YoloModelSelection selection = await ref.watch(
        yoloModelSelectionProvider.future,
      );
      final String? selectedId = selection.idFor(YoloModelScope.camera);
      AiModelInfo active = models.first;
      if (selectedId != null) {
        for (final AiModelInfo model in models) {
          if (model.id == selectedId) {
            active = model;
            break;
          }
        }
      }

      if (kIsWeb) {
        try {
          await createWebVisionModelPreflight().run(active.modelLink);
          return VisionModelSetupStatus(
            ready: true,
            title: 'Scanner ready',
            message: 'Camera reading is ready to use.',
            model: active,
          );
        } catch (e) {
          return VisionModelSetupStatus(
            ready: false,
            title: 'Scanner needs attention',
            message: friendlyVisionModelError(e.toString()),
            model: active,
          );
        }
      }

      final bool upToDate = await ref
          .read(yoloModelCacheProvider)
          .isUpToDate(active.id, active.version);
      if (upToDate) {
        return VisionModelSetupStatus(
          ready: true,
          title: 'Scanner ready',
          message: 'Camera reading is ready to use.',
          model: active,
        );
      }

      return VisionModelSetupStatus(
        ready: false,
        title: 'Scanner needs download',
        message: 'Download this to use camera reading.',
        model: active,
      );
    });

String friendlyVisionModelError(String rawMessage) {
  final String raw = rawMessage.trim();
  final String lower = raw.toLowerCase();
  if (lower.contains('404') ||
      lower.contains('not found') ||
      lower.contains('object not found')) {
    return 'This download is unavailable right now. Please try again later.';
  }
  if (lower.contains('cors') || lower.contains('failed to fetch')) {
    return 'This download could not be prepared right now. Please try again.';
  }
  if (lower.contains('input type')) {
    return 'This download is not ready for this device yet.';
  }
  if (lower.contains('shape') || lower.contains('tensor')) {
    return 'This download is not ready for this device yet.';
  }
  if (lower.contains('model') || lower.contains('tflite')) {
    return 'This download could not be prepared right now.';
  }
  return raw.isEmpty
      ? 'This download could not be prepared right now.'
      : 'Something went wrong while getting this ready. Please try again.';
}

/// Sentinel thrown while the model catalog is still loading. Callers
/// (the scanner camera) treat this the same as `AsyncLoading`.
class _YoloModelLoadingState implements Exception {
  const _YoloModelLoadingState();
}

/// A pre-loaded [YOLO] instance for the camera scope.
///
/// Used for single-image (gallery) inference in [ScanTabController].
/// Shares the same downloaded model file as the live camera view so no
/// additional download is triggered.
final yoloCameraModelProvider = FutureProvider<YOLO>((Ref ref) async {
  if (kIsWeb) throw UnsupportedError('YOLO is not available on web.');

  final String modelPath = await ref.watch(
    yoloModelPathProvider(YoloModelScope.camera).future,
  );

  ref.keepAlive();

  final YOLO yolo = YOLO(
    modelPath: modelPath,
    task: YOLOTask.detect,
    useGpu: false,
    useMultiInstance: true,
  );
  await yolo.loadModel();

  ref.onDispose(yolo.dispose);

  return yolo;
});

/// A pre-loaded [YOLO] instance for the drawing pad scope.
///
/// Watching or reading this provider triggers model download (via
/// [yoloModelPathProvider]) and native model initialisation so that the first
/// sketch submission has no cold-start latency.
///
/// The provider keeps itself alive once loaded so the instance is reused
/// for the entire lesson without reloading.
final yoloDrawingPadModelProvider = FutureProvider<YOLO>((Ref ref) async {
  if (kIsWeb) throw UnsupportedError('YOLO is not available on web.');

  final String modelPath = await ref.watch(
    yoloModelPathProvider(YoloModelScope.drawingPad).future,
  );

  // Keep the loaded instance alive so it is not discarded between steps.
  ref.keepAlive();

  final YOLO yolo = YOLO(
    modelPath: modelPath,
    task: YOLOTask.detect,
    useGpu: false,
  );
  await yolo.loadModel();

  // Dispose the native model when the provider is finally released.
  ref.onDispose(yolo.dispose);

  return yolo;
});
