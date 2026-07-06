import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import 'package:kudlit_ph/core/error/exceptions.dart';
import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/features/home/presentation/providers/app_preferences_provider.dart';
import 'package:kudlit_ph/features/translator/data/datasources/ai_datasource.dart';
import 'package:kudlit_ph/features/translator/data/datasources/local_gemma_datasource.dart';
import 'package:kudlit_ph/features/translator/data/datasources/supabase_gemma_models_datasource.dart';
import 'package:kudlit_ph/features/translator/domain/entities/baybayin_challenge.dart';
import 'package:kudlit_ph/features/translator/domain/entities/chat_message.dart';
import 'package:kudlit_ph/features/translator/domain/entities/gemma_model_info.dart';
import 'package:kudlit_ph/features/translator/domain/repositories/ai_inference_repository.dart';

class AiInferenceRepositoryImpl implements AiInferenceRepository {
  AiInferenceRepositoryImpl({
    required this.modelsDatasource,
    required this.localDatasource,
    required this.cloudDatasource,
    required this.preferenceResolver,
  });

  final SupabaseGemmaModelsDatasource modelsDatasource;
  final LocalGemmaDatasource localDatasource;
  final AiDatasource cloudDatasource;

  /// Resolves the current [AiPreference] at call time.
  /// Allows the repo to react to preference changes without holding
  /// a stale snapshot.
  final AiPreference Function() preferenceResolver;

  bool get _useCloud => preferenceResolver() == AiPreference.cloud;

  @override
  Future<Either<Failure, List<GemmaModelInfo>>> getAvailableModels() async {
    try {
      final List<GemmaModelInfo> models = await modelsDatasource.fetchModels();
      return right(models);
    } on ServerException catch (e) {
      return left(Failure.network(message: e.message));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isLocalModelInstalled(
    GemmaModelInfo model,
  ) async {
    try {
      final bool installed = await localDatasource.isInstalled(model);
      return right(installed);
    } on ServerException catch (e) {
      return left(Failure.unknown(message: e.message));
    }
  }

  @override
  Future<Either<Failure, Unit>> downloadLocalModel(
    GemmaModelInfo model, {
    void Function(int progress)? onProgress,
  }) async {
    try {
      await localDatasource.download(model, onProgress: onProgress);
      return right(unit);
    } on ServerException catch (e) {
      return left(Failure.network(message: e.message));
    }
  }

  @override
  void cancelDownload() {
    localDatasource.cancelDownload();
  }

  @override
  Stream<String> generateResponse(
    List<ChatMessage> history, {
    String? systemInstruction,
  }) {
    if (_useCloud) {
      debugPrint(
        '[Gemma] generateResponse route=cloud | messages=${history.length}',
      );
      return cloudDatasource.generate(
        history,
        systemInstruction: systemInstruction,
      );
    }
    debugPrint(
      '[Gemma] generateResponse route=local-preferred | messages=${history.length}',
    );
    return _localWithCloudFallback(
      history,
      systemInstruction: systemInstruction,
    );
  }

  /// Tries local inference; transparently falls back to cloud on any error
  /// (e.g. model not downloaded, session not initialised).
  ///
  /// Uses `await for` instead of `yield*` so that stream errors emitted by
  /// the local datasource are caught by the surrounding try/catch.
  Stream<String> _localWithCloudFallback(
    List<ChatMessage> history, {
    String? systemInstruction,
  }) async* {
    bool localFailed = false;
    try {
      debugPrint('[Gemma] local inference starting');
      await for (final String token in localDatasource.generate(
        history,
        systemInstruction: systemInstruction,
      )) {
        yield token;
      }
      debugPrint('[Gemma] local inference completed');
    } catch (e) {
      localFailed = true;
      debugPrint('[Gemma] local inference failed -> falling back to cloud');
      debugPrint('[Gemma] local failure detail: $e');
    }
    if (localFailed) {
      debugPrint('[Gemma] cloud fallback starting');
      yield* cloudDatasource.generate(
        history,
        systemInstruction: systemInstruction,
      );
      debugPrint('[Gemma] cloud fallback completed');
    }
  }

  // ─── 2. Image analysis ────────────────────────────────────────────────────

  @override
  Stream<String> analyzeImage(
    Uint8List imageBytes, {
    String mimeType = 'image/png',
    String? prompt,
  }) {
    if (kIsWeb || _useCloud) {
      return cloudDatasource.analyzeImage(
        imageBytes,
        mimeType: mimeType,
        prompt: prompt,
      );
    }
    return _localAnalyzeWithCloudFallback(
      imageBytes,
      mimeType: mimeType,
      prompt: prompt,
    );
  }

  /// Tries local image analysis; falls back to cloud if local is unsupported
  /// or errors (local Gemma does not support vision input).
  ///
  /// Uses `await for` instead of `yield*` so that stream errors emitted by
  /// the local datasource are caught by the surrounding try/catch.
  Stream<String> _localAnalyzeWithCloudFallback(
    Uint8List imageBytes, {
    String mimeType = 'image/png',
    String? prompt,
  }) async* {
    bool localFailed = false;
    try {
      await for (final String token in localDatasource.analyzeImage(
        imageBytes,
        mimeType: mimeType,
        prompt: prompt,
      )) {
        yield token;
      }
    } catch (_) {
      localFailed = true;
    }
    if (localFailed) {
      yield* cloudDatasource.analyzeImage(
        imageBytes,
        mimeType: mimeType,
        prompt: prompt,
      );
    }
  }

  // ─── 3. Challenge generation ──────────────────────────────────────────────

  @override
  Future<Either<Failure, BaybayinChallenge>> generateChallenge({
    List<String>? characters,
  }) async {
    try {
      late final BaybayinChallenge challenge;
      if (_useCloud) {
        challenge = await cloudDatasource.generateChallenge(
          characters: characters,
        );
      } else {
        try {
          challenge = await localDatasource.generateChallenge(
            characters: characters,
          );
        } catch (_) {
          challenge = await cloudDatasource.generateChallenge(
            characters: characters,
          );
        }
      }
      return right(challenge);
    } on ServerException catch (e) {
      return left(Failure.network(message: e.message));
    } catch (e) {
      return left(Failure.unknown(message: e.toString()));
    }
  }

  @override
  Future<void> dispose() async {
    await Future.wait(<Future<void>>[
      localDatasource.dispose(),
      cloudDatasource.dispose(),
    ]);
  }
}
