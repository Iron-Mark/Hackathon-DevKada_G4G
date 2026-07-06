import 'package:fpdart/fpdart.dart';

import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/core/usecases/usecase.dart';
import 'package:kudlit_ph/features/scanner/domain/repositories/baybayin_detector.dart';

/// Pauses the live scanner inference (e.g. when a result panel is visible
/// or the scan tab is no longer active).
class PauseScanner implements UseCase<Unit, NoParams> {
  const PauseScanner(this._detector);

  final BaybayinDetector _detector;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) {
    return _detector.pauseInference();
  }
}
