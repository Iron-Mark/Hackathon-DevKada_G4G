import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/features/scanner/data/datasources/web_vision_model_url_resolver.dart';
import 'package:kudlit_ph/features/scanner/domain/entities/baybayin_detection.dart';
import 'package:kudlit_ph/features/scanner/domain/failures/scanner_failures.dart';
import 'package:kudlit_ph/features/scanner/domain/repositories/baybayin_detector.dart';

BaybayinDetector createPlatformWebBaybayinDetector({
  required WebVisionModelUrlResolver modelUrlResolver,
}) {
  return const WebBaybayinDetectorStub();
}

class WebBaybayinDetectorStub implements BaybayinDetector {
  const WebBaybayinDetectorStub();

  @override
  Stream<List<BaybayinDetection>> get detections =>
      const Stream<List<BaybayinDetection>>.empty();

  @override
  Future<Either<Failure, List<BaybayinDetection>>> detectImage(
    Uint8List imageBytes,
  ) async =>
      right(const <BaybayinDetection>[]);

  @override
  Future<Either<Failure, Uint8List?>> captureFrame() async => right(null);

  @override
  Future<Either<Failure, Unit>> toggleTorch({required bool enabled}) async =>
      left(
        ScannerFailures.webUnsupported(
          'Torch is not available on the web scanner.',
        ),
      );

  @override
  Future<Either<Failure, Unit>> switchCamera() async => left(
    ScannerFailures.webUnsupported(
      'Camera switching is not available on the web scanner.',
    ),
  );

  /// Pause is a no-op on the stub — the stub has nothing running to pause —
  /// so it returns success to keep tab-pause logic frictionless.
  @override
  Future<Either<Failure, Unit>> pauseInference() async => right(unit);

  /// See [pauseInference].
  @override
  Future<Either<Failure, Unit>> resumeInference() async => right(unit);

  @override
  void dispose() {}
}
