import 'package:meta/meta.dart';

import 'package:kudlit_ph/features/translator/data/datasources/web_gemma_model_preflight_stub.dart'
    if (dart.library.js_interop) 'package:kudlit_ph/features/translator/data/datasources/web_gemma_model_preflight_web.dart';

abstract interface class WebGemmaModelPreflight {
  Future<WebGemmaModelPreflightResult> run(String modelUrl);
}

@immutable
class WebGemmaModelPreflightResult {
  const WebGemmaModelPreflightResult({
    required this.modelUrl,
    required this.installed,
    required this.responsePreview,
  });

  final String modelUrl;
  final bool installed;
  final String responsePreview;
}

WebGemmaModelPreflight createWebGemmaModelPreflight() {
  return createPlatformWebGemmaModelPreflight();
}
