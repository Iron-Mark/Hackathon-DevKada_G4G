import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kudlit_ph/features/home/presentation/providers/app_preferences_provider.dart';
import 'package:kudlit_ph/features/home/presentation/providers/model_setup_controller.dart';
import 'package:kudlit_ph/features/home/presentation/screens/model_setup_screen.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/yolo_model_selection_provider.dart';
import 'package:kudlit_ph/features/translator/data/datasources/local_gemma_datasource.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_state.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/translator_providers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('model setup hides raw network exception details', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 593));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiInferenceNotifierProvider.overrideWith(
            _RawErrorInferenceNotifier.new,
          ),
        ],
        child: const MaterialApp(home: ModelSetupScreen()),
      ),
    );
    await tester.pump();

    expect(
      find.textContaining(
        'Check your connection, then retry the model download.',
      ),
      findsWidgets,
    );
    expect(find.textContaining('AuthRetryableFetchException'), findsNothing);
    expect(find.textContaining('SocketException'), findsNothing);
    expect(find.textContaining('supabase.co'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('model setup download error also uses friendly copy', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(593, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          modelSetupControllerProvider.overrideWith(
            _RawErrorModelSetupController.new,
          ),
          aiInferenceNotifierProvider.overrideWith(
            _RawErrorInferenceNotifier.new,
          ),
        ],
        child: const MaterialApp(home: ModelSetupScreen()),
      ),
    );
    await tester.pump();

    expect(
      find.textContaining(
        'Check your connection, then retry the model download.',
      ),
      findsWidgets,
    );
    expect(find.textContaining('SocketException'), findsNothing);
    expect(find.textContaining('supabase.co'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test(
    'complete setup requires offline downloads and enables local mode',
    () async {
      int statusReads = 0;
      int readinessReads = 0;
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          visionModelSetupStatusProvider.overrideWith((Ref ref) async {
            statusReads++;
            return const VisionModelSetupStatus(
              ready: true,
              title: 'Scanner ready',
              message: 'Scanner ready.',
            );
          }),
          localModelReadinessProvider.overrideWith((Ref ref) async {
            readinessReads++;
            return const LocalGemmaReadiness(
              installed: true,
              usable: true,
              detail: 'Offline ready.',
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appPreferencesNotifierProvider.future);
      await container
          .read(modelSetupControllerProvider.notifier)
          .completeSetup();

      final AppPreferences prefs = await container.read(
        appPreferencesNotifierProvider.future,
      );
      expect(statusReads, 1);
      expect(readinessReads, 1);
      expect(prefs.aiPreference, AiPreference.local);
      expect(prefs.hasDownloadedModels, isTrue);
      expect(container.read(modelSetupControllerProvider).errorMessage, isNull);
    },
  );
}

class _RawErrorInferenceNotifier extends AiInferenceNotifier {
  @override
  Future<AiInferenceState> build() async => const AiInferenceError(
    'AuthRetryableFetchException(message: ClientException with '
    'SocketException: Failed host lookup: rxrreoftioidkvdowauv.supabase.co)',
  );
}

class _RawErrorModelSetupController extends ModelSetupController {
  @override
  ModelSetupState build() => const ModelSetupState(
    busy: false,
    errorMessage:
        'ClientException with SocketException: Failed host lookup: '
        'rxrreoftioidkvdowauv.supabase.co',
  );
}
