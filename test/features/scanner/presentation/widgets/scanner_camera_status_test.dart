import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kudlit_ph/features/scanner/presentation/widgets/model_not_ready_screen.dart';
import 'package:kudlit_ph/features/scanner/presentation/widgets/scanner_camera.dart';

void main() {
  test('web camera secure context allows HTTPS and localhost only', () {
    expect(
      isWebCameraSecureContext(Uri.parse('https://kudlit.example.com/#/home')),
      isTrue,
    );
    expect(
      isWebCameraSecureContext(Uri.parse('http://localhost:5173/#/home')),
      isTrue,
    );
    expect(
      isWebCameraSecureContext(Uri.parse('http://127.0.0.1:5173/#/home')),
      isTrue,
    );
    expect(
      isWebCameraSecureContext(Uri.parse('http://192.168.68.115:5173/#/home')),
      isFalse,
    );
  });

  test('web camera preference chooses back then external before front', () {
    const CameraDescription front = CameraDescription(
      name: 'front',
      lensDirection: CameraLensDirection.front,
      sensorOrientation: 0,
    );
    const CameraDescription back = CameraDescription(
      name: 'back',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    );
    const CameraDescription external = CameraDescription(
      name: 'external',
      lensDirection: CameraLensDirection.external,
      sensorOrientation: 0,
    );

    expect(preferredWebCameraIndex(<CameraDescription>[front]), 0);
    expect(preferredWebCameraIndex(<CameraDescription>[front, external]), 1);
    expect(
      preferredWebCameraIndex(<CameraDescription>[front, external, back]),
      2,
    );
  });

  test(
    'web camera alignment helper centers permission-related and initializing states',
    () {
      expect(
        shouldCenterWebScannerStatus(WebScannerStatus.initializing),
        isTrue,
      );
      expect(
        shouldCenterWebScannerStatus(WebScannerStatus.permissionNeeded),
        isTrue,
      );
      expect(shouldCenterWebScannerStatus(WebScannerStatus.error), isTrue);
      expect(shouldCenterWebScannerStatus(WebScannerStatus.ready), isFalse);
      expect(
        shouldCenterWebScannerStatus(WebScannerStatus.modelUnavailable),
        isFalse,
      );
      expect(shouldCenterWebScannerStatus(WebScannerStatus.detecting), isFalse);
    },
  );

  test('web camera permission helpers catch known denial variants', () {
    expect(isPermissionErrorCode('notAllowedError'), isTrue);
    expect(isPermissionErrorCode('PermissionDeniedError'), isTrue);
    expect(isPermissionErrorCode('NotReadableError'), isTrue);
    expect(isPermissionErrorCode('security'), isTrue);
    expect(isPermissionErrorCode('cameraUnknown'), isFalse);

    expect(isPermissionError('User denied camera access.'), isTrue);
    expect(
      isPermissionError(
        'getUserMedia failed due to denied permission from browser.',
      ),
      isTrue,
    );
    expect(isPermissionError('No camera found on this device.'), isFalse);
  });

  testWidgets('web camera status card fits narrow scanner viewport', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 288,
              child: WebStatusMessage(
                cs: ThemeData.dark().colorScheme,
                status: WebScannerStatus.permissionNeeded,
                showCompact: false,
                message:
                    'Camera permission is blocked. Allow camera access in the browser, then reload.',
              ),
            ),
          ),
        ),
      ),
    );

    final Rect cardRect = tester.getRect(find.byType(WebStatusMessage));

    expect(cardRect.width, lessThanOrEqualTo(288));
    expect(tester.takeException(), isNull);
  });

  testWidgets('web camera status announces title and recovery message', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: WebStatusMessage(
              cs: ThemeData.dark().colorScheme,
              status: WebScannerStatus.permissionNeeded,
              showCompact: false,
              message:
                  'Camera permission is blocked. Allow camera access in the browser, then reload.',
            ),
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel(
        'Allow camera. Camera permission is blocked. Allow camera access in the browser, then reload.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('web camera ready status uses concise semantic state', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: WebStatusMessage(
              cs: ThemeData.dark().colorScheme,
              status: WebScannerStatus.ready,
              showCompact: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Camera ready'), findsOneWidget);
    expect(find.textContaining('raw exception'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('model not ready screen shows download progress', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ModelNotReadyScreen(progress: 42)),
      ),
    );

    expect(find.text('Downloading scanner model... 42%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('model not ready error gives settings path for missing models', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    bool openedSettings = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModelNotReadyScreen.error(
            errorMessage: 'No scanner model is configured yet.',
            onRetry: () {},
            onSetup: () => openedSettings = true,
          ),
        ),
      ),
    );

    expect(find.text('Scanner model needs setup'), findsOneWidget);
    expect(
      find.text(
        'Open Settings > Offline downloads to get camera reading ready.',
      ),
      findsOneWidget,
    );
    expect(find.text('Open downloads'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);

    final Rect ctaRect = tester.getRect(
      find.widgetWithText(FilledButton, 'Open downloads'),
    );
    expect(ctaRect.height, greaterThanOrEqualTo(44));

    await tester.tap(find.text('Open downloads'));
    expect(openedSettings, isTrue);
    expect(tester.takeException(), isNull);
  });
}
