import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kudlit_ph/features/scanner/data/datasources/web_vision_model_preflight.dart';

const String _kSupabaseVisionModelUrl = String.fromEnvironment(
  'TEST_WEB_VISION_MODEL_URL',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'runs real browser inference against the Supabase vision model',
    (WidgetTester tester) async {
      if (!kIsWeb) {
        return;
      }
      if (_kSupabaseVisionModelUrl.isEmpty) {
        return;
      }
      final WebVisionModelPreflightResult result =
          await createWebVisionModelPreflight().run(_kSupabaseVisionModelUrl);

      expect(result.modelUrl, _kSupabaseVisionModelUrl);
      expect(result.inputShape, isNotEmpty);
      expect(result.outputShapes, isNotEmpty);
      expect(result.inputShape.first, greaterThan(0));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
