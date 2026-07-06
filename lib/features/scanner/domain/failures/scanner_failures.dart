import 'package:kudlit_ph/core/error/failures.dart';

/// Scanner-specific failure constructors.
///
/// The core [Failure] type is a sealed `freezed` class shared across the app,
/// so scanner failure kinds are produced here as tagged [Failure.unknown]
/// instances. Each factory prefixes the message with a stable scanner kind
/// token so presentation code can both display the message verbatim *and*
/// (optionally) branch on the failure kind via [scannerFailureKindOf].
///
/// This keeps the [Either<Failure, T>] return type consistent with the rest
/// of the codebase (auth, translator, learning, home, admin) while still
/// giving the scanner domain its own taxonomy of typed errors.
final class ScannerFailures {
  const ScannerFailures._();

  /// Model could not load, camera permission denied, hardware unsupported.
  static Failure init(String message) =>
      Failure.unknown(message: '${ScannerFailureKind.init.token}: $message');

  /// Inference (still-image or live frame) threw at runtime.
  static Failure inference(String message) => Failure.unknown(
    message: '${ScannerFailureKind.inference.token}: $message',
  );

  /// Camera frame capture failed (e.g. native controller returned null or
  /// the platform raised an error while grabbing the bytes).
  static Failure capture(String message) =>
      Failure.unknown(message: '${ScannerFailureKind.capture.token}: $message');

  /// Camera control (torch / lens switch) failed.
  static Failure cameraControl(String message) => Failure.unknown(
    message: '${ScannerFailureKind.cameraControl.token}: $message',
  );

  /// The requested method is not supported on the current platform — used
  /// by the web detector for torch / switch-camera / pause / resume so the
  /// UI can render an explicit notice rather than silently succeeding.
  static Failure webUnsupported(String message) => Failure.unknown(
    message: '${ScannerFailureKind.webUnsupported.token}: $message',
  );
}

/// Stable taxonomy of scanner failure kinds. The [token] is the leading
/// substring in [Failure.unknown.message] produced by [ScannerFailures].
enum ScannerFailureKind {
  init('SCANNER_INIT'),
  inference('SCANNER_INFERENCE'),
  capture('SCANNER_CAPTURE'),
  cameraControl('SCANNER_CAMERA_CONTROL'),
  webUnsupported('SCANNER_WEB_UNSUPPORTED');

  const ScannerFailureKind(this.token);

  final String token;
}

/// Returns the [ScannerFailureKind] encoded in [failure], when [failure] was
/// produced by [ScannerFailures]. Returns `null` for any other [Failure].
ScannerFailureKind? scannerFailureKindOf(Failure failure) {
  if (failure is! UnknownFailure) return null;
  final String message = failure.message;
  for (final ScannerFailureKind kind in ScannerFailureKind.values) {
    if (message.startsWith('${kind.token}:')) return kind;
  }
  return null;
}
