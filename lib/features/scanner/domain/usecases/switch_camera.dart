import 'package:fpdart/fpdart.dart';

import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/core/usecases/usecase.dart';
import 'package:kudlit_ph/features/scanner/domain/repositories/baybayin_detector.dart';

/// Switches between available camera lenses on the live preview.
class SwitchCamera implements UseCase<Unit, NoParams> {
  const SwitchCamera(this._detector);

  final BaybayinDetector _detector;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) {
    return _detector.switchCamera();
  }
}
