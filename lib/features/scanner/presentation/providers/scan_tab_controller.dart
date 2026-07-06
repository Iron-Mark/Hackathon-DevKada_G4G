import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';

import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/core/utils/baybayify.dart';
import 'package:kudlit_ph/features/scanner/domain/entities/baybayin_detection.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/scanner_evaluation_provider.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/scanner_provider.dart';

@immutable
class ScanNotice {
  const ScanNotice({
    required this.title,
    required this.message,
    required this.kind,
  });

  final String title;
  final String message;
  final ScanNoticeKind kind;
}

enum ScanNoticeKind { info, warning, error }

class ScanCaptureException implements Exception {
  const ScanCaptureException(this.notice);

  final ScanNotice notice;

  @override
  String toString() => '${notice.title}: ${notice.message}';
}

@immutable
class ScanTabState {
  const ScanTabState({
    required this.resultVisible,
    required this.flashOn,
    required this.selectedImageBytes,
    required this.capturedFrameBytes,
    required this.isLoadingImage,
    required this.detectionsFrozen,
    required this.snapshot,
    required this.aggregatedWinner,
    this.scanNotice,
  });

  const ScanTabState.initial()
    : this(
        resultVisible: false,
        flashOn: false,
        selectedImageBytes: null,
        capturedFrameBytes: null,
        isLoadingImage: false,
        detectionsFrozen: false,
        snapshot: const <BaybayinDetection>[],
        aggregatedWinner: null,
        scanNotice: null,
      );

  final bool resultVisible;
  final bool flashOn;
  final Uint8List? selectedImageBytes;

  /// Frozen frame captured when the shutter button is pressed on a live camera.
  /// Distinct from [selectedImageBytes] (gallery pick) — no re-detection is
  /// run against it; existing live detections are reused as the snapshot.
  final Uint8List? capturedFrameBytes;
  final bool isLoadingImage;
  final bool detectionsFrozen;
  final List<BaybayinDetection> snapshot;

  /// True when the result panel is showing a shutter-frozen frame
  /// (as opposed to a gallery image or live aggregated win).
  bool get isShutterFrozen => capturedFrameBytes != null;

  /// Most-frequent reading from the recent live-scan rolling window.
  final String? aggregatedWinner;
  final ScanNotice? scanNotice;

  ScanTabState copyWith({
    bool? resultVisible,
    bool? flashOn,
    Uint8List? selectedImageBytes,
    bool clearSelectedImage = false,
    Uint8List? capturedFrameBytes,
    bool clearCapturedFrame = false,
    bool? isLoadingImage,
    bool? detectionsFrozen,
    List<BaybayinDetection>? snapshot,
    String? aggregatedWinner,
    bool clearAggregatedWinner = false,
    ScanNotice? scanNotice,
    bool clearScanNotice = false,
  }) {
    return ScanTabState(
      resultVisible: resultVisible ?? this.resultVisible,
      flashOn: flashOn ?? this.flashOn,
      selectedImageBytes: clearSelectedImage
          ? null
          : (selectedImageBytes ?? this.selectedImageBytes),
      capturedFrameBytes: clearCapturedFrame
          ? null
          : (capturedFrameBytes ?? this.capturedFrameBytes),
      isLoadingImage: isLoadingImage ?? this.isLoadingImage,
      detectionsFrozen: detectionsFrozen ?? this.detectionsFrozen,
      snapshot: snapshot ?? this.snapshot,
      aggregatedWinner: clearAggregatedWinner
          ? null
          : (aggregatedWinner ?? this.aggregatedWinner),
      scanNotice: clearScanNotice ? null : (scanNotice ?? this.scanNotice),
    );
  }
}

final NotifierProvider<ScanTabController, ScanTabState>
scanTabControllerProvider = NotifierProvider<ScanTabController, ScanTabState>(
  ScanTabController.new,
);

enum _StillImageSource { gallery, camera }

class ScanTabController extends Notifier<ScanTabState> {
  static const int _kAggMaxBuffer = 50;
  static const Duration _kAggIdleTimeout = Duration(milliseconds: 1000);

  final Queue<String> _aggBuffer = Queue<String>();
  final Map<String, int> _aggFreq = <String, int>{};
  Timer? _aggIdleTimer;

  @override
  ScanTabState build() {
    ref.onDispose(_resetAggregator);
    return const ScanTabState.initial();
  }

  Future<void> toggleFlash() async {
    final bool next = !state.flashOn;
    state = state.copyWith(flashOn: next);
    final Either<Failure, Unit> result = await ref
        .read(baybayinDetectorProvider)
        .toggleTorch(enabled: next);
    result.fold(
      (Failure failure) {
        debugPrint('[ScanTab] toggleTorch failed: ${_messageOf(failure)}');
        // Revert the optimistic flash state so the UI doesn't lie about it.
        state = state.copyWith(flashOn: !next);
      },
      (_) {},
    );
  }

  Future<void> switchCamera() async {
    final Either<Failure, Unit> result = await ref
        .read(baybayinDetectorProvider)
        .switchCamera();
    result.fold(
      (Failure failure) {
        debugPrint('[ScanTab] switchCamera failed: ${_messageOf(failure)}');
      },
      (_) {},
    );
  }

  Future<void> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }

    try {
      final Uint8List bytes = await image.readAsBytes();
      await processGalleryImageBytes(bytes);
    } catch (e) {
      _beginStillImageScan();
      _finishStillImageError(_noticeForStillImageError(e.toString()));
    }
  }

  @visibleForTesting
  Future<void> processGalleryImageBytes(Uint8List bytes) {
    return _processStillImage(bytes, source: _StillImageSource.gallery);
  }

  Future<void> captureNativeFrame({Uint8List? fallbackBytes}) async {
    _beginStillImageScan();

    final Either<Failure, Uint8List?> result = await ref
        .read(baybayinDetectorProvider)
        .captureFrame();
    Uint8List? imageBytes = result.fold(
      (Failure failure) {
        debugPrint(
          '[ScanTab] native camera frame capture failed: ${_messageOf(failure)}',
        );
        return null;
      },
      (Uint8List? bytes) => bytes,
    );
    imageBytes ??= fallbackBytes;

    if (imageBytes == null || imageBytes.isEmpty) {
      _finishStillImageError(
        const ScanNotice(
          title: 'Capture failed',
          message: 'The camera frame was not ready. Try again or use Gallery.',
          kind: ScanNoticeKind.error,
        ),
      );
      return;
    }

    await _processStillImage(
      imageBytes,
      source: _StillImageSource.camera,
      begin: false,
    );
  }

  Future<void> captureWebFrame(
    Future<(List<BaybayinDetection>, Uint8List?)> Function() capture,
  ) async {
    _resetAggregator();
    ref.read(scannerNotifierProvider.notifier).clear();
    ref.read(scannerEvaluationProvider.notifier).clear();
    state = state.copyWith(
      isLoadingImage: true,
      resultVisible: false,
      clearSelectedImage: true,
      clearCapturedFrame: true,
      snapshot: const <BaybayinDetection>[],
      clearAggregatedWinner: true,
      clearScanNotice: true,
    );

    try {
      final (List<BaybayinDetection> results, Uint8List? imageBytes) =
          await capture();
      ref.read(scannerNotifierProvider.notifier).update(results);
      if (results.isNotEmpty) {
        _evaluateSafely(results, null);
      } else {
        ref.read(scannerEvaluationProvider.notifier).clear();
      }
      state = state.copyWith(
        isLoadingImage: false,
        resultVisible: results.isNotEmpty,
        capturedFrameBytes: results.isNotEmpty ? imageBytes : null,
        snapshot: List<BaybayinDetection>.of(results),
        scanNotice: results.isEmpty
            ? const ScanNotice(
                title: 'No glyphs detected',
                message:
                    'Keep the Baybayin text centered and well lit, then capture again.',
                kind: ScanNoticeKind.warning,
              )
            : null,
        clearScanNotice: results.isNotEmpty,
      );
    } on ScanCaptureException catch (e) {
      ref.read(scannerNotifierProvider.notifier).clear();
      ref.read(scannerEvaluationProvider.notifier).clear();
      state = state.copyWith(
        isLoadingImage: false,
        resultVisible: false,
        clearCapturedFrame: true,
        snapshot: const <BaybayinDetection>[],
        scanNotice: e.notice,
      );
    } catch (e) {
      debugPrint('[ScanTab] capture failed: $e');
      ref.read(scannerNotifierProvider.notifier).clear();
      ref.read(scannerEvaluationProvider.notifier).clear();
      state = state.copyWith(
        isLoadingImage: false,
        resultVisible: false,
        clearCapturedFrame: true,
        snapshot: const <BaybayinDetection>[],
        scanNotice: const ScanNotice(
          title: 'Capture failed',
          message: 'Try again or use Gallery to test an image.',
          kind: ScanNoticeKind.error,
        ),
      );
    }
  }

  /// Freezes the live camera into a result view.
  ///
  /// [capturedBytes] is the PNG snapshot of the camera frame taken just before
  /// this call. When provided the live [ScannerCamera] widget is replaced by a
  /// static [Image.memory] so inference stops. Pass `null` to fall back to the
  /// legacy behaviour (result panel only, camera keeps running).
  void onShutterTapped({Uint8List? capturedBytes}) {
    final List<BaybayinDetection> detections = ref.read(
      scannerNotifierProvider,
    );
    if (state.isShutterFrozen) {
      dismissResult();
      return;
    }

    if (detections.isEmpty) {
      state = state.copyWith(
        resultVisible: false,
        snapshot: const <BaybayinDetection>[],
        scanNotice: const ScanNotice(
          title: 'No glyphs detected',
          message: 'Frame one or more Baybayin glyphs before capturing.',
          kind: ScanNoticeKind.warning,
        ),
      );
      return;
    }

    state = state.copyWith(
      resultVisible: true,
      capturedFrameBytes: capturedBytes,
      snapshot: List<BaybayinDetection>.of(detections),
      clearScanNotice: true,
    );
    _evaluateSafely(
      detections,
      // Prefer the frozen camera frame for visual AI analysis; fall back to
      // a gallery-selected image if one was active.
      capturedBytes ?? state.selectedImageBytes,
      aggregatedHint: state.aggregatedWinner,
    );
  }

  void applyLiveDetections(List<BaybayinDetection> detections) {
    if (state.isLoadingImage ||
        state.selectedImageBytes != null ||
        state.capturedFrameBytes != null ||
        state.detectionsFrozen) {
      return;
    }
    ref.read(scannerNotifierProvider.notifier).update(detections);
    if (detections.isEmpty) {
      // Nothing in frame — user moved away. Reset the buffer immediately so
      // the next scan starts with a clean slate.
      _resetAggregator();
      if (state.aggregatedWinner != null) {
        state = state.copyWith(clearAggregatedWinner: true);
      }
      return;
    }
    _pushAggregatedScan(detections);
  }

  void dismissResult() {
    if (state.selectedImageBytes != null) {
      clearSelectedImage();
      return;
    }

    ref.read(scannerNotifierProvider.notifier).clear();
    _resetAggregator();
    state = state.copyWith(
      resultVisible: false,
      clearCapturedFrame: true,
      detectionsFrozen: false,
      snapshot: const <BaybayinDetection>[],
      clearAggregatedWinner: true,
      clearScanNotice: true,
    );
    if (!kIsWeb) {
      unawaited(
        ref.read(baybayinDetectorProvider).resumeInference().then((
          Either<Failure, Unit> result,
        ) {
          result.fold(
            (Failure failure) => debugPrint(
              '[ScanTab] resumeInference failed: ${_messageOf(failure)}',
            ),
            (_) {},
          );
        }),
      );
    }
  }

  void clearSelectedImage() {
    ref.read(scannerNotifierProvider.notifier).clear();
    _resetAggregator();
    state = state.copyWith(
      clearSelectedImage: true,
      resultVisible: false,
      detectionsFrozen: false,
      snapshot: const <BaybayinDetection>[],
      clearAggregatedWinner: true,
      clearScanNotice: true,
    );
  }

  void showNotice(ScanNotice notice) {
    state = state.copyWith(scanNotice: notice, resultVisible: false);
  }

  void clearNotice() {
    state = state.copyWith(clearScanNotice: true);
  }

  void setDetectionsFrozen(bool value) {
    state = state.copyWith(detectionsFrozen: value);
  }

  void _evaluateSafely(
    List<BaybayinDetection> detections,
    Uint8List? imageBytes, {
    String? aggregatedHint,
  }) {
    try {
      ref
          .read(scannerEvaluationProvider.notifier)
          .evaluate(detections, imageBytes, aggregatedHint: aggregatedHint);
    } catch (_) {
      // OCR result remains usable if optional AI evaluation is unavailable.
    }
  }

  Future<void> _processStillImage(
    Uint8List bytes, {
    required _StillImageSource source,
    bool begin = true,
  }) async {
    if (begin) {
      _beginStillImageScan();
    }

    final Either<Failure, List<BaybayinDetection>> result = await ref
        .read(baybayinDetectorProvider)
        .detectImage(bytes);
    result.fold(
      (Failure failure) {
        final String message = _messageOf(failure);
        debugPrint('[ScanTab] still-image scan failed: $message');
        _finishStillImageError(_noticeForStillImageError(message));
      },
      (List<BaybayinDetection> results) {
        _finishStillImageScan(results, imageBytes: bytes, source: source);
      },
    );
  }

  void _beginStillImageScan() {
    _resetAggregator();
    ref.read(scannerNotifierProvider.notifier).clear();
    ref.read(scannerEvaluationProvider.notifier).clear();
    state = state.copyWith(
      isLoadingImage: true,
      resultVisible: false,
      clearSelectedImage: true,
      clearCapturedFrame: true,
      detectionsFrozen: true,
      snapshot: const <BaybayinDetection>[],
      clearAggregatedWinner: true,
      clearScanNotice: true,
    );
  }

  void _finishStillImageScan(
    List<BaybayinDetection> results, {
    required Uint8List imageBytes,
    required _StillImageSource source,
  }) {
    final List<BaybayinDetection> snapshot = List<BaybayinDetection>.of(
      results,
    );
    ref.read(scannerNotifierProvider.notifier).update(snapshot);

    if (snapshot.isEmpty) {
      ref.read(scannerEvaluationProvider.notifier).clear();
      state = state.copyWith(
        isLoadingImage: false,
        resultVisible: false,
        clearSelectedImage: true,
        clearCapturedFrame: true,
        detectionsFrozen: false,
        snapshot: const <BaybayinDetection>[],
        scanNotice: const ScanNotice(
          title: 'No glyphs detected',
          message:
              'Use a clearer, well-lit image with the Baybayin glyphs centered.',
          kind: ScanNoticeKind.warning,
        ),
      );
      return;
    }

    _evaluateSafely(snapshot, imageBytes);
    state = state.copyWith(
      isLoadingImage: false,
      resultVisible: true,
      selectedImageBytes: source == _StillImageSource.gallery
          ? imageBytes
          : null,
      capturedFrameBytes: source == _StillImageSource.camera
          ? imageBytes
          : null,
      detectionsFrozen: false,
      snapshot: snapshot,
      clearScanNotice: true,
    );
  }

  void _finishStillImageError(ScanNotice notice) {
    ref.read(scannerNotifierProvider.notifier).clear();
    ref.read(scannerEvaluationProvider.notifier).clear();
    state = state.copyWith(
      isLoadingImage: false,
      resultVisible: false,
      clearSelectedImage: true,
      clearCapturedFrame: true,
      detectionsFrozen: false,
      snapshot: const <BaybayinDetection>[],
      scanNotice: notice,
    );
  }

  /// Extracts a human-readable message from any [Failure] sealed variant for
  /// debug logging. Presentation copy lives in [_noticeForStillImageError] and
  /// the scan notice widgets, not here.
  String _messageOf(Failure failure) {
    return switch (failure) {
      NetworkFailure(:final String message) => message,
      UnknownFailure(:final String message) => message,
      _ => failure.toString(),
    };
  }

  ScanNotice _noticeForStillImageError(String error) {
    final String raw = error.toLowerCase();
    if (raw.contains('permission')) {
      return const ScanNotice(
        title: 'Image access blocked',
        message: 'Allow photo access, then try Gallery again.',
        kind: ScanNoticeKind.error,
      );
    }
    if (raw.contains('model') ||
        raw.contains('yolo') ||
        raw.contains('tflite')) {
      return const ScanNotice(
        title: 'Scanner model unavailable',
        message:
            'The scanner model could not run on this image. Check the model setup and retry.',
        kind: ScanNoticeKind.error,
      );
    }
    return const ScanNotice(
      title: 'Image scan failed',
      message: 'Try a clearer image, retake the photo, or use Gallery again.',
      kind: ScanNoticeKind.error,
    );
  }

  /// Collapses i/e vowel ambiguity to a canonical form so that frames
  /// producing e.g. "mahalkita" and "mahalketa" (the same Baybayin glyph
  /// sequence) are counted as identical entries in the frequency map.
  static String _normalizeVowelAmbiguity(String s) => s.replaceAll('e', 'i');

  void _resetAggregator() {
    _aggIdleTimer?.cancel();
    _aggIdleTimer = null;
    _aggBuffer.clear();
    _aggFreq.clear();
  }

  void _pushAggregatedScan(List<BaybayinDetection> detections) {
    if (detections.isEmpty) return;

    final List<BaybayinDetection> ordered =
        List<BaybayinDetection>.of(detections)..sort(
          (BaybayinDetection a, BaybayinDetection b) =>
              a.left.compareTo(b.left),
        );
    final List<String> tokens = ordered
        .map((BaybayinDetection d) => d.label.trim().toLowerCase())
        .where((String s) => s.isNotEmpty)
        .toList(growable: false);
    final List<String> perms = permuteBaybayin(tokens);
    if (perms.isEmpty) return;
    // Normalize i/e ambiguity so "mahalkita" and "mahalketa" (same Baybayin
    // glyph sequence) always map to the same freq-map key, preventing the
    // vote from being split across superficially different romanizations.
    final String candidate = _normalizeVowelAmbiguity(perms.first);

    if (_aggBuffer.length >= _kAggMaxBuffer) {
      final String evicted = _aggBuffer.removeFirst();
      final int prev = _aggFreq[evicted] ?? 0;
      if (prev <= 1) {
        _aggFreq.remove(evicted);
      } else {
        _aggFreq[evicted] = prev - 1;
      }
    }
    _aggBuffer.addLast(candidate);
    _aggFreq.update(candidate, (int v) => v + 1, ifAbsent: () => 1);

    String top = '';
    int max = 0;
    _aggFreq.forEach((String key, int value) {
      if (value > max) {
        max = value;
        top = key;
      }
    });

    if (top.isNotEmpty && top != state.aggregatedWinner) {
      state = state.copyWith(aggregatedWinner: top);
    }

    _aggIdleTimer?.cancel();
    _aggIdleTimer = Timer(_kAggIdleTimeout, () {
      _aggBuffer.clear();
      _aggFreq.clear();
      // Also dismiss the winner banner so stale text doesn't linger on screen.
      if (state.aggregatedWinner != null) {
        state = state.copyWith(clearAggregatedWinner: true);
      }
    });
  }
}
