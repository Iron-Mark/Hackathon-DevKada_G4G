import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';

import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/features/scanner/domain/entities/baybayin_detection.dart';
import 'package:kudlit_ph/features/scanner/domain/failures/scanner_failures.dart';
import 'package:kudlit_ph/features/scanner/domain/repositories/baybayin_detector.dart';

typedef SingleImageYoloFactory = YOLO Function(String modelPath);

/// On-device YOLO implementation of [BaybayinDetector] for iOS and Android.
///
/// The live preview model path is supplied by `yoloModelPathProvider` (in the
/// scanner presentation layer), which downloads the active catalog model on
/// demand and surfaces [ModelNotReadyScreen] until it is ready.
class YoloBaybayinDetector implements BaybayinDetector {
  YoloBaybayinDetector({
    this.modelPathResolver,
    SingleImageYoloFactory? singleImageYoloFactory,
  }) : _singleImageYoloFactory =
           singleImageYoloFactory ?? _createSingleImageYolo,
       _controller = YOLOViewController() {
    debugPrint('[YOLO] YoloBaybayinDetector created');
  }

  static const double _kConfidenceThreshold = 0.8;
  static const double _kIoUThreshold = 0.45;
  static const double _kMinBoxArea = 0.001;
  static const double _kEdgeMargin = 0.02;

  final Future<String> Function()? modelPathResolver;
  final SingleImageYoloFactory _singleImageYoloFactory;
  final YOLOViewController _controller;
  final StreamController<List<BaybayinDetection>> _streamController =
      StreamController<List<BaybayinDetection>>.broadcast();
  YOLO? _singleImageYolo;
  String? _singleImageModelPath;

  /// The [YOLOViewController] — pass this to [YOLOView].
  YOLOViewController get controller => _controller;

  /// Called by [YOLOView.onResult] to push detections into the stream.
  void onYoloResults(List<YOLOResult> results) {
    final List<BaybayinDetection> detections = results
        .map(
          (YOLOResult r) => BaybayinDetection(
            label: r.className,
            confidence: r.confidence,
            left: r.normalizedBox.left,
            top: r.normalizedBox.top,
            width: r.normalizedBox.width,
            height: r.normalizedBox.height,
          ),
        )
        .toList();
    if (!_streamController.isClosed) {
      _streamController.add(detections);
    }
  }

  @override
  Stream<List<BaybayinDetection>> get detections => _streamController.stream;

  @override
  Future<Either<Failure, List<BaybayinDetection>>> detectImage(
    Uint8List imageBytes,
  ) async {
    try {
      final YOLO yolo = await _singleImageModel();
      final Map<String, dynamic> result = await yolo.predict(
        imageBytes,
        confidenceThreshold: _kConfidenceThreshold,
        iouThreshold: _kIoUThreshold,
      );
      final List<BaybayinDetection> detections =
          (result['detections'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<dynamic, dynamic>>()
              .map(YOLOResult.fromMap)
              .where(_isUsefulStillImageResult)
              .map(_toDetection)
              .toList(growable: false);
      if (!_streamController.isClosed) {
        _streamController.add(detections);
      }
      return right(detections);
    } on StateError catch (e) {
      return left(ScannerFailures.init(e.message));
    } catch (e) {
      return left(ScannerFailures.inference(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Uint8List?>> captureFrame() async {
    try {
      final Uint8List? frame = await _controller.captureFrame();
      return right(frame);
    } catch (e) {
      return left(ScannerFailures.capture(e.toString()));
    }
  }

  Future<YOLO> _singleImageModel() async {
    final Future<String> Function()? resolver = modelPathResolver;
    if (resolver == null) {
      throw StateError('No YOLO model resolver is configured.');
    }

    final String modelPath = await resolver();
    if (_singleImageYolo != null && _singleImageModelPath == modelPath) {
      return _singleImageYolo!;
    }

    await _singleImageYolo?.dispose();
    _singleImageYolo = null;
    _singleImageModelPath = null;

    final YOLO yolo = _singleImageYoloFactory(modelPath);
    try {
      await yolo.loadModel();
    } catch (_) {
      await yolo.dispose();
      rethrow;
    }
    _singleImageYolo = yolo;
    _singleImageModelPath = modelPath;
    return yolo;
  }

  static YOLO _createSingleImageYolo(String modelPath) {
    return YOLO(
      modelPath: modelPath,
      task: YOLOTask.detect,
      useGpu: false,
      useMultiInstance: true,
    );
  }

  bool _isUsefulStillImageResult(YOLOResult result) {
    if (result.confidence < _kConfidenceThreshold) return false;
    final Rect box = result.normalizedBox;
    if (box.width * box.height < _kMinBoxArea) return false;
    const double edge = _kEdgeMargin;
    return box.left >= edge &&
        box.top >= edge &&
        box.right <= 1 - edge &&
        box.bottom <= 1 - edge;
  }

  BaybayinDetection _toDetection(YOLOResult result) {
    final Rect box = result.normalizedBox;
    return BaybayinDetection(
      label: result.className,
      confidence: result.confidence,
      left: box.left,
      top: box.top,
      width: box.width,
      height: box.height,
    );
  }

  @override
  Future<Either<Failure, Unit>> toggleTorch({required bool enabled}) async {
    try {
      await _controller.setTorchMode(enabled);
      return right(unit);
    } catch (e) {
      return left(ScannerFailures.cameraControl(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> switchCamera() async {
    try {
      await _controller.switchCamera();
      return right(unit);
    } catch (e) {
      return left(ScannerFailures.cameraControl(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> pauseInference() async {
    try {
      await _controller.stop();
      return right(unit);
    } catch (e) {
      return left(ScannerFailures.cameraControl(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> resumeInference() async {
    try {
      await _controller.restartCamera();
      return right(unit);
    } catch (e) {
      return left(ScannerFailures.cameraControl(e.toString()));
    }
  }

  @override
  void dispose() {
    debugPrint('[YOLO] YoloBaybayinDetector disposed');
    final YOLO? yolo = _singleImageYolo;
    _singleImageYolo = null;
    _singleImageModelPath = null;
    unawaited(yolo?.dispose());
    _streamController.close();
  }
}
