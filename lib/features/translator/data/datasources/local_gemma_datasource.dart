import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import 'package:kudlit_ph/core/error/exceptions.dart';
import 'package:kudlit_ph/features/translator/data/datasources/ai_datasource.dart';
import 'package:kudlit_ph/features/translator/data/datasources/gemma_model_file_type.dart';
import 'package:kudlit_ph/features/translator/domain/entities/baybayin_challenge.dart';
import 'package:kudlit_ph/features/translator/domain/entities/chat_message.dart';
import 'package:kudlit_ph/features/translator/domain/entities/gemma_model_info.dart';

/// Wraps `flutter_gemma` for on-device inference.
///
/// Background download notes:
/// - Android: files >500 MB auto-promote to a foreground service
///   (notification shown), bypassing the 9-minute background limit.
/// - iOS: `flutter_gemma` uses `NSURLSession` which schedules the
///   download discretionarily — iOS picks the timing, the app may
///   be backgrounded or terminated while download proceeds.
class LocalGemmaDatasource implements AiDatasource {
  LocalGemmaDatasource();

  CancelToken? _cancelToken;
  InferenceModel? _activeModel;
  bool _activeModelHasVision = false;
  InferenceChat? _chat;

  /// Last model we know is installed for this device. flutter_gemma's native
  /// "active model" is process-scoped and is lost on every app restart, while
  /// the downloaded file persists. Remembering the model lets the inference
  /// path reactivate it on demand instead of relying on a UI readiness probe
  /// having run first.
  GemmaModelInfo? _knownModel;

  /// Records [model] as the installed model without doing any native work.
  /// Called from the inference notifier as soon as it resolves the active
  /// model so reactivation can self-heal even before any readiness probe.
  void rememberModel(GemmaModelInfo model) {
    _knownModel = model;
  }

  /// Reactivates the installed model into the native engine when the engine
  /// reports no active model (typical after an app restart). No-op when an
  /// active model already exists, when we don't know the model, or when the
  /// file is not installed (the caller's `getActiveModel()` then surfaces the
  /// error and the repository falls back to cloud).
  Future<void> _reactivateIfNeeded() async {
    if (FlutterGemma.hasActiveModel() || _knownModel == null) return;
    final bool installed = await FlutterGemma.isModelInstalled(
      _knownModel!.fileName,
    );
    if (!installed) return;
    debugPrint(
      '[Gemma][local] engine has no active model — reactivating '
      '${_knownModel!.fileName}',
    );
    await _reactivateInstalledModel(_knownModel!);
  }

  // Mutex so concurrent probeReadiness calls share one native operation.
  bool _probing = false;
  Future<LocalGemmaReadiness>? _pendingProbe;

  Future<LocalGemmaReadiness> probeReadiness(GemmaModelInfo model) {
    _knownModel = model;
    // Fast path: model is already loaded — skip all native work.
    if (_activeModel != null) {
      debugPrint(
        '[Gemma][local] readiness probe fast-path (model already loaded)',
      );
      return Future<LocalGemmaReadiness>.value(
        LocalGemmaReadiness(
          installed: true,
          usable: true,
          detail: 'Offline ready: ${model.name}',
          modelName: model.name,
        ),
      );
    }
    // Coalesce concurrent calls: callers share the in-flight result.
    if (_probing) return _pendingProbe!;
    _probing = true;
    _pendingProbe = _doProbe(model).whenComplete(() {
      _probing = false;
      _pendingProbe = null;
    });
    return _pendingProbe!;
  }

  Future<LocalGemmaReadiness> _doProbe(GemmaModelInfo model) async {
    try {
      final bool installed = await FlutterGemma.isModelInstalled(
        model.fileName,
      );
      if (!installed) {
        return LocalGemmaReadiness(
          installed: false,
          usable: false,
          detail: '${model.name} is not installed on this device.',
          modelName: model.name,
        );
      }
      if (!FlutterGemma.hasActiveModel()) {
        debugPrint(
          '[Gemma][local] installed file found but no active model set; reactivating ${model.fileName}',
        );
        await _reactivateInstalledModel(model);
      }
      // Load and KEEP the model (pre-warm) instead of load+close.
      // This makes the first real inference call instant.
      _activeModel ??= await FlutterGemma.getActiveModel();
      _activeModelHasVision = false;
      debugPrint('[Gemma][local] readiness probe complete — model pre-warmed');
      return LocalGemmaReadiness(
        installed: true,
        usable: true,
        detail: 'Offline ready: ${model.name}',
        modelName: model.name,
      );
    } catch (e, s) {
      debugPrint('[Gemma][local] readiness probe failed: $e');
      debugPrintStack(stackTrace: s, label: '[Gemma][local] readiness stack');
      return LocalGemmaReadiness(
        installed: true,
        usable: false,
        detail: 'Model files exist, but offline Gemma is not usable yet: $e',
        modelName: model.name,
      );
    }
  }

  /// Ensures the model is loaded into memory without blocking inference.
  /// Safe to call fire-and-forget after download completes.
  Future<void> ensureModelLoaded() async {
    if (_activeModel != null) return;
    try {
      _activeModel = await FlutterGemma.getActiveModel();
      _activeModelHasVision = false;
      debugPrint('[Gemma][local] model pre-warmed via ensureModelLoaded');
    } catch (e) {
      debugPrint('[Gemma][local] ensureModelLoaded failed (non-fatal): $e');
    }
  }

  Future<bool> isInstalled(GemmaModelInfo model) async {
    try {
      return await FlutterGemma.isModelInstalled(model.fileName);
    } catch (e) {
      throw ServerException(message: 'Install check failed: $e');
    }
  }

  /// Enqueues a background download for [model]. Resolves when the
  /// underlying handler reports the file is fully written.
  Future<void> download(
    GemmaModelInfo model, {
    void Function(int progress)? onProgress,
  }) async {
    _knownModel = model;
    _cancelToken = CancelToken();
    try {
      final String? hfToken = dotenv.env['HUGGINGFACE_TOKEN'];
      final InferenceInstallationBuilder builder =
          FlutterGemma.installModel(
                modelType: ModelType.gemma4,
                fileType: resolveGemmaModelFileType(model.modelLink),
              )
              .fromNetwork(model.modelLink, token: hfToken)
              .withCancelToken(_cancelToken!);

      if (onProgress != null) {
        builder.withProgress(onProgress);
      }

      await builder.install();
      debugPrint(
        '[Gemma][local] download/install completed for ${model.fileName}',
      );
    } on Exception catch (e) {
      if (CancelToken.isCancel(e)) {
        throw const ServerException(message: 'Download cancelled');
      }
      throw ServerException(message: 'Download failed: $e');
    } finally {
      _cancelToken = null;
    }
  }

  void cancelDownload() {
    _cancelToken?.cancel('User cancelled download');
  }

  /// Lazily creates the active model + chat and streams text tokens.
  @override
  Stream<String> generate(
    List<ChatMessage> history, {
    String? systemInstruction,
  }) async* {
    try {
      debugPrint(
        '[Gemma][local] generate called | history=${history.length} | hasSystemInstruction=${systemInstruction != null}',
      );
      // Vision-enabled models work fine for text generation, so reuse
      // _activeModel regardless of _activeModelHasVision.
      if (_activeModel == null) {
        await _reactivateIfNeeded();
      }
      _activeModel ??= await FlutterGemma.getActiveModel();
      debugPrint('[Gemma][local] active model ready');
      _chat ??= await _activeModel!.createChat(
        systemInstruction: systemInstruction,
      );
      debugPrint('[Gemma][local] chat session ready');

      if (history.isEmpty) {
        debugPrint('[Gemma][local] history empty -> no output');
        return;
      }
      final ChatMessage last = history.last;
      await _chat!.addQueryChunk(
        Message.text(text: last.text, isUser: last.isUser),
      );
      debugPrint(
        '[Gemma][local] last message enqueued | isUser=${last.isUser} | chars=${last.text.length}',
      );

      await for (final ModelResponse response
          in _chat!.generateChatResponseAsync()) {
        if (response is TextResponse) {
          yield response.token;
        }
      }
      debugPrint('[Gemma][local] token stream finished');
    } catch (e, s) {
      debugPrint('[Gemma][local] generate error: $e');
      debugPrintStack(stackTrace: s, label: '[Gemma][local] stack');
      rethrow;
    }
  }

  @override
  Stream<String> analyzeImage(
    Uint8List imageBytes, {
    String mimeType = 'image/png',
    String? prompt,
  }) async* {
    if (kIsWeb) {
      throw UnsupportedError(
        'Image analysis is not supported by flutter_gemma on web yet.',
      );
    }
    InferenceChat? imageChat;
    try {
      debugPrint(
        '[Gemma][local] analyzeImage called | bytes=${imageBytes.length}',
      );
      // Close any active text chat — native model allows one session at a time.
      if (_chat != null) {
        await _chat!.close();
        _chat = null;
      }
      // Vision must be enabled at ENGINE creation time (max_num_images > 0).
      // Reuse _activeModel if it was already loaded with vision support;
      // otherwise close it and reload.
      if (_activeModel != null && !_activeModelHasVision) {
        await _activeModel!.close();
        _activeModel = null;
      }
      if (_activeModel == null) {
        await _reactivateIfNeeded();
      }
      _activeModel ??= await FlutterGemma.getActiveModel(
        supportImage: true,
        maxNumImages: 1,
      );
      _activeModelHasVision = true;
      imageChat = await _activeModel!.createChat(supportImage: true);
      await imageChat.addQueryChunk(
        Message.withImage(
          text: prompt ?? 'Analyze this image.',
          imageBytes: imageBytes,
          isUser: true,
        ),
      );
      await for (final ModelResponse response
          in imageChat.generateChatResponseAsync()) {
        if (response is TextResponse) {
          yield response.token;
        }
      }
      debugPrint('[Gemma][local] analyzeImage stream finished');
    } catch (e, s) {
      debugPrint('[Gemma][local] analyzeImage error: $e');
      debugPrintStack(
        stackTrace: s,
        label: '[Gemma][local] analyzeImage stack',
      );
      rethrow;
    } finally {
      await imageChat?.close();
      // Reset _chat so the next generate() call creates a fresh session.
      // _activeModel stays loaded (with vision) for reuse if analyzeImage
      // is called again; generate() works fine on a vision-enabled model.
      _chat = null;
    }
  }

  @override
  Future<BaybayinChallenge> generateChallenge({List<String>? characters}) =>
      throw UnsupportedError('generateChallenge is not supported on-device');

  Future<void> _reactivateInstalledModel(GemmaModelInfo model) async {
    final String? hfToken = dotenv.env['HUGGINGFACE_TOKEN'];
    await FlutterGemma.installModel(
      modelType: ModelType.gemma4,
      fileType: resolveGemmaModelFileType(model.modelLink),
    ).fromNetwork(model.modelLink, token: hfToken).install();
    debugPrint('[Gemma][local] active model restored for ${model.fileName}');
  }

  @override
  Future<void> dispose() async {
    await _activeModel?.close();
    _activeModel = null;
    _activeModelHasVision = false;
    _chat = null;
  }
}

class LocalGemmaReadiness {
  const LocalGemmaReadiness({
    required this.installed,
    required this.usable,
    required this.detail,
    this.modelName,
  });

  final bool installed;
  final bool usable;
  final String detail;
  final String? modelName;
}
