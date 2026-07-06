import 'package:kudlit_ph/features/scanner/data/datasources/web_vision_model_preflight.dart';

WebVisionModelPreflight createPlatformWebVisionModelPreflight() {
  return const _WebVisionModelPreflightStub();
}

class _WebVisionModelPreflightStub implements WebVisionModelPreflight {
  const _WebVisionModelPreflightStub();

  @override
  Future<WebVisionModelPreflightResult> run(String modelUrl) async {
    throw UnsupportedError('Web model preflight is only available on web.');
  }
}
