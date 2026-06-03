import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/core/usecases/usecase.dart';
import 'package:kudlit_ph/features/scanner/domain/repositories/baybayin_detector.dart';

/// Captures the current camera frame from a live preview.
///
/// A successful `Right(null)` means the platform does not own a live frame
/// (e.g. web preview) — callers should fall back to a still-image source.
class CaptureFrame implements UseCase<Uint8List?, NoParams> {
  const CaptureFrame(this._detector);

  final BaybayinDetector _detector;

  @override
  Future<Either<Failure, Uint8List?>> call(NoParams params) {
    return _detector.captureFrame();
  }
}
