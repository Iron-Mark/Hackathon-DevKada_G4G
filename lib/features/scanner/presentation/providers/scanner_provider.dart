import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:kudlit_ph/features/scanner/data/datasources/device_inference_capability_checker.dart';
import 'package:kudlit_ph/features/scanner/data/datasources/web_baybayin_detector_factory.dart';
import 'package:kudlit_ph/features/scanner/data/datasources/yolo_baybayin_detector.dart';
import 'package:kudlit_ph/features/scanner/domain/entities/baybayin_detection.dart';
import 'package:kudlit_ph/features/scanner/domain/repositories/baybayin_detector.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/yolo_model_selection_provider.dart';
import 'package:kudlit_ph/features/translator/domain/entities/ai_model_info.dart';

part 'scanner_provider.g.dart';

/// Provides the correct [BaybayinDetector] for the current platform.
@Riverpod(keepAlive: true)
BaybayinDetector baybayinDetector(Ref ref) {
  final BaybayinDetector detector = kIsWeb
      ? createWebBaybayinDetector(
          modelUrlResolver: () => _resolveWebVisionModelUrl(ref),
        )
      : YoloBaybayinDetector(
          modelPathResolver: () =>
              ref.read(yoloModelPathProvider(YoloModelScope.camera).future),
        );
  ref.onDispose(detector.dispose);
  return detector;
}

Future<String?> _resolveWebVisionModelUrl(Ref ref) async {
  final List<AiModelInfo> models = await ref.read(
    availableYoloModelsProvider.future,
  );
  if (models.isEmpty) return null;

  final YoloModelSelection selection = await ref.read(
    yoloModelSelectionProvider.future,
  );
  final String? selectedId = selection.idFor(YoloModelScope.camera);
  if (selectedId != null) {
    for (final AiModelInfo model in models) {
      if (model.id == selectedId) return model.modelLink;
    }
  }
  return models.first.modelLink;
}

/// Holds the latest list of detections pushed from [ScannerCamera].
/// Updated imperatively via [ScannerNotifier.update].

/// True when the current device meets the minimum OS requirements to run
/// on-device YOLO inference.
///
/// Web is excluded via the `kIsWeb` guard in [ScannerCamera] before this is
/// consulted, so [DeviceInferenceCapabilityChecker.check] is only called on
/// iOS / Android.
final deviceInferenceCapableProvider = Provider<bool>((Ref ref) {
  return DeviceInferenceCapabilityChecker.instance.check();
});

@riverpod
class ScannerNotifier extends _$ScannerNotifier {
  @override
  List<BaybayinDetection> build() => const <BaybayinDetection>[];

  void update(List<BaybayinDetection> detections) {
    state = detections;
  }

  void clear() {
    state = const <BaybayinDetection>[];
  }
}
