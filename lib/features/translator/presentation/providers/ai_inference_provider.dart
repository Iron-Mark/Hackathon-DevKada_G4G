import 'dart:async';

// ignore: unnecessary_import — flutter_riverpod is needed for AsyncNotifier
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/features/home/presentation/providers/app_preferences_provider.dart';
import 'package:kudlit_ph/features/translator/domain/entities/gemma_model_info.dart';
import 'package:kudlit_ph/features/translator/domain/entities/chat_message.dart';
import 'package:kudlit_ph/features/translator/domain/repositories/ai_inference_repository.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_state.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/translator_providers.dart';

part 'ai_inference_provider.g.dart';

/// Global, lazy AI inference notifier.
///
/// Not instantiated until first read. Once read it stays alive
/// (`keepAlive: true`) and routes to the correct backend
/// (local `flutter_gemma` or cloud stub) based on `AiPreference`.
@Riverpod(keepAlive: true)
class AiInferenceNotifier extends _$AiInferenceNotifier {
  static const Duration _stallThreshold = Duration(seconds: 20);

  Timer? _stallTimer;
  GemmaModelInfo? _downloadModel;
  bool _cancelRequested = false;

  @override
  Future<AiInferenceState> build() async {
    ref.onDispose(_clearDownloadWatchers);

    // Don't interrupt an active download triggered from the setup screen.
    final AiInferenceState? prev = state.value;
    if (prev is AiDownloading) return prev;

    final AiInferenceRepository repo = ref.watch(aiInferenceRepositoryProvider);
    final AppPreferences prefs = await ref.watch(
      appPreferencesNotifierProvider.future,
    );

    final Either<Failure, List<GemmaModelInfo>> modelsResult = await repo
        .getAvailableModels();
    if (modelsResult.isLeft()) {
      final Failure f = modelsResult.getLeft().getOrElse(
        () => const Failure.unknown(message: 'unknown'),
      );
      return AiInferenceError(_failureMessage(f));
    }
    final List<GemmaModelInfo> models = modelsResult.getRight().getOrElse(
      () => <GemmaModelInfo>[],
    );
    return _resolveInitialState(repo: repo, models: models, prefs: prefs);
  }

  Future<AiInferenceState> _resolveInitialState({
    required AiInferenceRepository repo,
    required List<GemmaModelInfo> models,
    required AppPreferences prefs,
  }) async {
    if (models.isEmpty) {
      return const AiInferenceError('No AI models configured.');
    }

    final GemmaModelInfo active = _resolveActiveModel(
      models,
      preferredId: prefs.selectedModelId,
    );

    if (prefs.aiPreference == AiPreference.cloud) {
      return AiReady(mode: AiPreference.cloud, activeModel: active);
    }

    final Either<Failure, bool> installedResult = await repo
        .isLocalModelInstalled(active);
    if (installedResult.isLeft()) {
      final Failure f = installedResult.getLeft().getOrElse(
        () => const Failure.unknown(message: 'unknown'),
      );
      return AiInferenceError(_failureMessage(f));
    }
    final bool installed = installedResult.getRight().getOrElse(() => false);
    if (installed) {
      // The native engine loses its active model on every app restart while
      // the downloaded file persists. Tell the datasource which model is
      // installed so the first inference call can reactivate it on demand
      // instead of silently falling back to cloud.
      ref.read(localGemmaDatasourceProvider).rememberModel(active);
      return AiReady(mode: AiPreference.local, activeModel: active);
    }
    return AiLocalModelMissing(active);
  }

  /// Picks the median-ranked model unless [preferredId] is set
  /// and present in the catalog.
  GemmaModelInfo _resolveActiveModel(
    List<GemmaModelInfo> models, {
    String? preferredId,
  }) {
    if (preferredId != null) {
      for (final GemmaModelInfo m in models) {
        if (m.id == preferredId) return m;
      }
    }
    final List<GemmaModelInfo> sorted = <GemmaModelInfo>[...models]
      ..sort((GemmaModelInfo a, GemmaModelInfo b) => a.id.compareTo(b.id));
    return sorted[sorted.length ~/ 2];
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Starts/continues the local model download. Updates state with
  /// progress and ends in [AiReady] on success.
  Future<void> downloadLocalModel() async {
    final AiInferenceState? current = state.value;
    final GemmaModelInfo? model = switch (current) {
      AiLocalModelMissing(:final GemmaModelInfo model) => model,
      AiDownloading(:final GemmaModelInfo model) => model,
      _ => null,
    };
    if (model == null) return;
    await _runDownload(model);
  }

  void cancelDownload() {
    _cancelRequested = true;
    final GemmaModelInfo? model =
        _downloadModel ??
        switch (state.value) {
          AiDownloading(:final GemmaModelInfo model) => model,
          AiLocalModelMissing(:final GemmaModelInfo model) => model,
          _ => null,
        };
    if (model != null) {
      state = AsyncData(
        AiDownloading(
          model: model,
          progress: switch (state.value) {
            AiDownloading(:final int progress) => progress,
            _ => 0,
          },
          statusMessage: 'Cancel requested. Waiting for downloader cleanup…',
        ),
      );
    }
    ref.read(aiInferenceRepositoryProvider).cancelDownload();
  }

  /// Starts a download for [model] unconditionally — used by the
  /// model setup screen where the inference state may still be `AiReady(cloud)`.
  ///
  /// Safe to call fire-and-forget; the `build()` guard preserves
  /// `AiDownloading` state even if prefs change mid-download.
  Future<void> triggerLocalDownload(GemmaModelInfo model) async {
    await _runDownload(model);
  }

  /// Persist a different active model and reload state.
  Future<void> setActiveModel(GemmaModelInfo model) async {
    await ref
        .read(appPreferencesNotifierProvider.notifier)
        .setSelectedModel(model.id);
    ref.invalidateSelf();
  }

  /// Streams model output. Caller is responsible for appending the
  /// user message to history first.
  Stream<String> generateResponse(
    List<ChatMessage> history, {
    String? systemInstruction,
  }) {
    return ref
        .read(aiInferenceRepositoryProvider)
        .generateResponse(history, systemInstruction: systemInstruction);
  }

  String _failureMessage(Failure f) => switch (f) {
    NetworkFailure(:final String message) => message,
    UnknownFailure(:final String message) => message,
    _ => 'Unexpected error',
  };

  Future<void> _runDownload(GemmaModelInfo model) async {
    _cancelRequested = false;
    _downloadModel = model;
    _setDownloadingState(
      model,
      progress: 0,
      statusMessage: 'Preparing download…',
    );
    _restartStallTimer(model, progress: 0);

    final AiInferenceRepository repo = ref.read(aiInferenceRepositoryProvider);
    final Either<Failure, Unit> result = await repo.downloadLocalModel(
      model,
      onProgress: (int progress) {
        final String statusMessage = progress >= 100
            ? 'Finalizing downloaded file…'
            : 'Downloading in background. Keep this screen open if updates pause.';
        _setDownloadingState(
          model,
          progress: progress,
          statusMessage: statusMessage,
        );
        _restartStallTimer(model, progress: progress);
      },
    );

    final bool wasCancelRequested = _cancelRequested;
    _clearDownloadWatchers();

    if (wasCancelRequested) {
      state = AsyncData(
        AiLocalModelMissing(
          model,
          note:
              'Download canceled. You can retry when the connection is stable.',
        ),
      );
      return;
    }

    state = AsyncData(
      result.isRight()
          ? AiReady(mode: AiPreference.local, activeModel: model)
          : AiInferenceError(
              _failureMessage(
                result.getLeft().getOrElse(
                  () => const Failure.unknown(message: 'download failed'),
                ),
              ),
            ),
    );

    if (result.isRight()) {
      // Pre-warm the model so the first inference request doesn't cold-start.
      // Fire-and-forget — state is already AiReady at this point.
      unawaited(ref.read(localGemmaDatasourceProvider).ensureModelLoaded());
      // Refresh status banners that show offline readiness.
      ref.invalidate(localModelReadinessProvider);
    }
  }

  void _restartStallTimer(GemmaModelInfo model, {required int progress}) {
    _stallTimer?.cancel();
    _stallTimer = Timer(_stallThreshold, () {
      final AiInferenceState? current = state.value;
      if (current is! AiDownloading || current.model.id != model.id) {
        return;
      }
      _setDownloadingState(
        model,
        progress: progress,
        statusMessage:
            'No new progress yet. Android may be retrying or resuming the download.',
      );
    });
  }

  void _setDownloadingState(
    GemmaModelInfo model, {
    required int progress,
    required String statusMessage,
  }) {
    state = AsyncData(
      AiDownloading(
        model: model,
        progress: progress,
        statusMessage: statusMessage,
      ),
    );
  }

  void _clearDownloadWatchers() {
    _stallTimer?.cancel();
    _stallTimer = null;
    _downloadModel = null;
  }
}
