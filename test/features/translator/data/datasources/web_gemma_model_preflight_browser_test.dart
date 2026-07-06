import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kudlit_ph/features/translator/data/datasources/web_gemma_model_preflight.dart';

const String _kGemmaWebModelUrl = String.fromEnvironment(
  'TEST_WEB_GEMMA_MODEL_URL',
  defaultValue:
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'loads the real Gemma web model in a browser session',
    (WidgetTester tester) async {
      if (!kIsWeb) {
        return;
      }

      final WebGemmaModelPreflightResult result =
          await createWebGemmaModelPreflight().run(_kGemmaWebModelUrl);

      expect(result.modelUrl, _kGemmaWebModelUrl);
      expect(result.installed, isTrue);
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );

  testWidgets(
    'generates real browser output from the Gemma web model',
    (WidgetTester tester) async {
      if (!kIsWeb) {
        return;
      }

      final WebGemmaModelPreflightResult result =
          await createWebGemmaModelPreflight().run(_kGemmaWebModelUrl);

      expect(result.responsePreview.trim(), isNotEmpty);
    },
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
