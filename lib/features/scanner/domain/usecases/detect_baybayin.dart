import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/core/usecases/usecase.dart';
import 'package:kudlit_ph/features/scanner/domain/entities/baybayin_detection.dart';
import 'package:kudlit_ph/features/scanner/domain/repositories/baybayin_detector.dart';

/// Runs Baybayin detection on a single still image (gallery pick or a
/// captured camera frame).
class DetectBaybayin
    implements UseCase<List<BaybayinDetection>, Uint8List> {
  const DetectBaybayin(this._detector);

  final BaybayinDetector _detector;

  @override
  Future<Either<Failure, List<BaybayinDetection>>> call(Uint8List params) {
    return _detector.detectImage(params);
  }
}
