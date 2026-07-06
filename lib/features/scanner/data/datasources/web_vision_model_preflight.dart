import 'package:meta/meta.dart';

import 'package:kudlit_ph/features/scanner/data/datasources/web_vision_model_preflight_stub.dart'
    if (dart.library.js_interop) 'package:kudlit_ph/features/scanner/data/datasources/web_vision_model_preflight_web.dart';

abstract interface class WebVisionModelPreflight {
  Future<WebVisionModelPreflightResult> run(String modelUrl);
}

@immutable
class WebVisionModelPreflightResult {
  const WebVisionModelPreflightResult({
    required this.modelUrl,
    required this.inputShape,
    required this.outputShapes,
  });

  final String modelUrl;
  final List<int> inputShape;
  final List<List<int>> outputShapes;
}

WebVisionModelPreflight createWebVisionModelPreflight() {
  return createPlatformWebVisionModelPreflight();
}
