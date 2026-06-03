import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/features/scanner/domain/entities/baybayin_detection.dart';
import 'package:kudlit_ph/features/scanner/domain/repositories/baybayin_detector.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/scan_tab_controller.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/scanner_provider.dart';

void main() {
  test('captureWebFrame hides result panel when capture fails empty', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(scanTabControllerProvider.notifier)
        .captureWebFrame(() async => (const <BaybayinDetection>[], null));

    final ScanTabState state = container.read(scanTabControllerProvider);
    expect(state.isLoadingImage, isFalse);
    expect(state.resultVisible, isFalse);
    expect(state.snapshot, isEmpty);
    expect(state.scanNotice, isNotNull);
    expect(state.scanNotice!.title, 'No glyphs detected');
  });

  test('clearNotice returns no-glyph notice to camera state', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(scanTabControllerProvider.notifier)
        .captureWebFrame(() async => (const <BaybayinDetection>[], null));

    container.read(scanTabControllerProvider.notifier).clearNotice();

    final ScanTabState state = container.read(scanTabControllerProvider);
    expect(state.resultVisible, isFalse);
    expect(state.snapshot, isEmpty);
    expect(state.scanNotice, isNull);
  });

  test('captureWebFrame shows result panel when detections exist', () async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(scanTabControllerProvider.notifier)
        .captureWebFrame(
          () async => (
            const <BaybayinDetection>[
              BaybayinDetection(
                label: 'ba',
                confidence: 0.91,
                left: 0.2,
                top: 0.2,
                width: 0.3,
                height: 0.3,
              ),
            ],
            null,
          ),
        );

    final ScanTabState state = container.read(scanTabControllerProvider);
    expect(state.isLoadingImage, isFalse);
    expect(state.resultVisible, isTrue);
    expect(state.snapshot, hasLength(1));
    expect(state.scanNotice, isNull);
  });

  test('processGalleryImageBytes replaces the previous scan result', () async {
    final _FakeBaybayinDetector detector = _FakeBaybayinDetector(
      detections: _detections('ba'),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: [baybayinDetectorProvider.overrideWithValue(detector)],
    );
    addTearDown(container.dispose);

    await container
        .read(scanTabControllerProvider.notifier)
        .processGalleryImageBytes(Uint8List.fromList(<int>[1, 2, 3]));

    ScanTabState state = container.read(scanTabControllerProvider);
    expect(state.resultVisible, isTrue);
    expect(state.selectedImageBytes, isNotNull);
    expect(state.snapshot.single.label, 'ba');

    detector.nextDetections = _detections('ka');
    final Uint8List nextBytes = Uint8List.fromList(<int>[4, 5, 6]);
    await container
        .read(scanTabControllerProvider.notifier)
        .processGalleryImageBytes(nextBytes);

    state = container.read(scanTabControllerProvider);
    expect(state.resultVisible, isTrue);
    expect(state.selectedImageBytes, same(nextBytes));
    expect(state.snapshot.single.label, 'ka');
    expect(container.read(scannerNotifierProvider).single.label, 'ka');
  });

  test(
    'processGalleryImageBytes clears stale result when no glyphs are found',
    () async {
      final _FakeBaybayinDetector detector = _FakeBaybayinDetector(
        detections: _detections('ba'),
      );
      final ProviderContainer container = ProviderContainer(
        overrides: [baybayinDetectorProvider.overrideWithValue(detector)],
      );
      addTearDown(container.dispose);

      await container
          .read(scanTabControllerProvider.notifier)
          .processGalleryImageBytes(Uint8List.fromList(<int>[1]));

      detector.nextDetections = const <BaybayinDetection>[];
      await container
          .read(scanTabControllerProvider.notifier)
          .processGalleryImageBytes(Uint8List.fromList(<int>[2]));

      final ScanTabState state = container.read(scanTabControllerProvider);
      expect(state.resultVisible, isFalse);
      expect(state.selectedImageBytes, isNull);
      expect(state.snapshot, isEmpty);
      expect(state.scanNotice?.title, 'No glyphs detected');
      expect(container.read(scannerNotifierProvider), isEmpty);
    },
  );

  test(
    'captureNativeFrame runs detection on the captured frame bytes',
    () async {
      final Uint8List captured = Uint8List.fromList(<int>[9, 8, 7]);
      final _FakeBaybayinDetector detector = _FakeBaybayinDetector(
        detections: _detections('ka'),
        capturedFrame: captured,
      );
      final ProviderContainer container = ProviderContainer(
        overrides: [baybayinDetectorProvider.overrideWithValue(detector)],
      );
      addTearDown(container.dispose);

      container
          .read(scannerNotifierProvider.notifier)
          .update(_detections('stale'));

      await container
          .read(scanTabControllerProvider.notifier)
          .captureNativeFrame(fallbackBytes: Uint8List.fromList(<int>[1]));

      final ScanTabState state = container.read(scanTabControllerProvider);
      expect(detector.lastImageBytes, captured);
      expect(state.resultVisible, isTrue);
      expect(state.capturedFrameBytes, captured);
      expect(state.snapshot.single.label, 'ka');
    },
  );

  test(
    'captureNativeFrame clears stale result when no frame is available',
    () async {
      final _FakeBaybayinDetector detector = _FakeBaybayinDetector(
        detections: _detections('ba'),
      );
      final ProviderContainer container = ProviderContainer(
        overrides: [baybayinDetectorProvider.overrideWithValue(detector)],
      );
      addTearDown(container.dispose);

      await container
          .read(scanTabControllerProvider.notifier)
          .processGalleryImageBytes(Uint8List.fromList(<int>[1]));

      detector
        ..nextDetections = _detections('ka')
        ..nextCapturedFrame = null;

      await container
          .read(scanTabControllerProvider.notifier)
          .captureNativeFrame();

      final ScanTabState state = container.read(scanTabControllerProvider);
      expect(state.resultVisible, isFalse);
      expect(state.snapshot, isEmpty);
      expect(state.scanNotice?.title, 'Capture failed');
      expect(container.read(scannerNotifierProvider), isEmpty);
    },
  );
}

List<BaybayinDetection> _detections(String label) {
  return <BaybayinDetection>[
    BaybayinDetection(
      label: label,
      confidence: 0.91,
      left: 0.2,
      top: 0.2,
      width: 0.3,
      height: 0.3,
    ),
  ];
}

class _FakeBaybayinDetector implements BaybayinDetector {
  _FakeBaybayinDetector({
    required List<BaybayinDetection> detections,
    Uint8List? capturedFrame,
  }) : nextDetections = detections,
       nextCapturedFrame = capturedFrame;

  final StreamController<List<BaybayinDetection>> _stream =
      StreamController<List<BaybayinDetection>>.broadcast();

  List<BaybayinDetection> nextDetections;
  Uint8List? nextCapturedFrame;
  Uint8List? lastImageBytes;

  @override
  Stream<List<BaybayinDetection>> get detections => _stream.stream;

  @override
  Future<Either<Failure, List<BaybayinDetection>>> detectImage(
    Uint8List imageBytes,
  ) async {
    lastImageBytes = imageBytes;
    _stream.add(nextDetections);
    return right(nextDetections);
  }

  @override
  Future<Either<Failure, Uint8List?>> captureFrame() async =>
      right(nextCapturedFrame);

  @override
  Future<Either<Failure, Unit>> toggleTorch({required bool enabled}) async =>
      right(unit);

  @override
  Future<Either<Failure, Unit>> switchCamera() async => right(unit);

  @override
  Future<Either<Failure, Unit>> pauseInference() async => right(unit);

  @override
  Future<Either<Failure, Unit>> resumeInference() async => right(unit);

  @override
  void dispose() {
    unawaited(_stream.close());
  }
}
