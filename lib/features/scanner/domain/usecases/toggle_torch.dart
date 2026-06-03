import 'package:fpdart/fpdart.dart';

import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/core/usecases/usecase.dart';
import 'package:kudlit_ph/features/scanner/domain/repositories/baybayin_detector.dart';

/// Toggles the device torch / flash on the live camera preview.
class ToggleTorch implements UseCase<Unit, bool> {
  const ToggleTorch(this._detector);

  final BaybayinDetector _detector;

  @override
  Future<Either<Failure, Unit>> call(bool params) {
    return _detector.toggleTorch(enabled: params);
  }
}
