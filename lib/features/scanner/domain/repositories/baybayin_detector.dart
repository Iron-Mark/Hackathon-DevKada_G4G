import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/features/scanner/domain/entities/baybayin_detection.dart';

/// Abstract interface for Baybayin detection.
///
/// Implementations:
/// - [YoloBaybayinDetector] — on-device YOLO (iOS / Android)
/// - [WebTfliteBaybayinDetector] — browser TFLite inference for web
///
/// Methods that can fail return [Either<Failure, T>] so presentation code can
/// `fold` on errors without relying on raw exceptions. The live detection
/// stream remains a plain [Stream] of detection lists; transient errors during
/// streaming are surfaced through the stream's own error channel by the
/// implementation.
abstract class BaybayinDetector {
  /// Live stream of detections from the camera feed.
  /// Emits a new list each time the model processes a frame.
  Stream<List<BaybayinDetection>> get detections;

  /// Run inference on a single image (e.g. from the gallery).
  Future<Either<Failure, List<BaybayinDetection>>> detectImage(
    Uint8List imageBytes,
  );

  /// Capture the current camera frame when the platform detector owns a live
  /// camera session. Returns [Right(null)] when the platform does not support
  /// frame capture or no frame is ready yet (this is a normal idle state, not
  /// a failure); returns [Left] when the capture attempt itself errors.
  Future<Either<Failure, Uint8List?>> captureFrame();

  /// Toggle the device torch / flash.
  Future<Either<Failure, Unit>> toggleTorch({required bool enabled});

  /// Switch between available camera lenses when the platform supports it.
  Future<Either<Failure, Unit>> switchCamera();

  /// Pause live inference (e.g. while a result panel is visible).
  Future<Either<Failure, Unit>> pauseInference();

  /// Resume live inference after a pause.
  Future<Either<Failure, Unit>> resumeInference();

  /// Release all resources (camera, model).
  void dispose();
}
