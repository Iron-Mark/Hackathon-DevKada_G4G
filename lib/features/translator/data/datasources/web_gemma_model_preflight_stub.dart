import 'package:kudlit_ph/features/translator/data/datasources/web_gemma_model_preflight.dart';

WebGemmaModelPreflight createPlatformWebGemmaModelPreflight() {
  return const _WebGemmaModelPreflightStub();
}

class _WebGemmaModelPreflightStub implements WebGemmaModelPreflight {
  const _WebGemmaModelPreflightStub();

  @override
  Future<WebGemmaModelPreflightResult> run(String modelUrl) async {
    throw UnsupportedError('Web Gemma preflight is only available on web.');
  }
}
