import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kudlit_ph/features/home/presentation/providers/app_preferences_provider.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/ai_models_section.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/profile_management_action_button.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/settings/vision_download_tile.dart';
import 'package:kudlit_ph/features/scanner/data/datasources/yolo_model_cache.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/yolo_model_selection_provider.dart';
import 'package:kudlit_ph/features/translator/domain/entities/ai_model_info.dart';
import 'package:kudlit_ph/features/translator/domain/entities/gemma_model_info.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_state.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('offline downloads section frames setup in plain language', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: _modelOverrides(_FakeYoloModelCache()),
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: AiModelsSection())),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('OFFLINE DOWNLOADS'), findsOneWidget);
    expect(find.text('Use Kudlit offline'), findsOneWidget);
    expect(
      find.text(
        'Set these up once to keep replies and camera reading available without internet.',
      ),
      findsOneWidget,
    );
    expect(find.text('Butty replies'), findsOneWidget);
    expect(find.text('Offline replies  ·  large download'), findsOneWidget);
    expect(find.text('Needs download'), findsWidgets);
    expect(find.text('KudVis-1-Turbo'), findsOneWidget);
    expect(find.text('Reads Baybayin with your camera'), findsOneWidget);
    expect(
      find.text('Download once before using camera reading.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('vision model download prewarms camera path after install', (
    tester,
  ) async {
    final _FakeYoloModelCache cache = _FakeYoloModelCache();

    await tester.pumpWidget(
      ProviderScope(
        overrides: _modelOverrides(cache),
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: VisionDownloadTile()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Set up'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(cache.downloadedIds, contains('vision-1'));
    expect(cache.upToDateChecks, contains('vision-1'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('vision model tile manages the selected camera model', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'yolo_model_overrides': '{"camera":"vision-2"}',
    });
    final _FakeYoloModelCache cache = _FakeYoloModelCache()..installed = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: _modelOverrides(
          cache,
          visionModels: const <AiModelInfo>[
            AiModelInfo(
              id: 'vision-1',
              name: 'KudVis-1-Turbo',
              modelLink: 'https://example.com/kudvis.tflite',
              sortOrder: 0,
              version: 1,
              enabled: true,
              modelType: ModelKind.vision,
            ),
            AiModelInfo(
              id: 'vision-2',
              name: 'KudVis-Pro',
              modelLink: 'https://example.com/kudvis-pro.tflite',
              sortOrder: 1,
              version: 2,
              enabled: true,
              modelType: ModelKind.vision,
            ),
          ],
        ),
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: VisionDownloadTile()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('KudVis-Pro'), findsOneWidget);
    expect(find.text('Ready to scan'), findsOneWidget);

    await tester.tap(find.text('Set up again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(cache.downloadedIds, contains('vision-2'));
    expect(cache.downloadedIds, isNot(contains('vision-1')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI model actions stack below status copy on narrow cards', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: _modelOverrides(_FakeYoloModelCache()),
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 288,
                child: SingleChildScrollView(child: AiModelsSection()),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final Rect supportText = tester.getRect(
      find.text('Download once before using camera reading.'),
    );
    final Rect downloadButton = tester.getRect(
      find.widgetWithText(ProfileManagementActionButton, 'Set up'),
    );

    expect(downloadButton.top, greaterThan(supportText.bottom));
    expect(downloadButton.height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI model setup keeps action hierarchy stable on narrow phones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 593));
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: _modelOverrides(_FakeYoloModelCache()),
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 288,
                child: SingleChildScrollView(child: AiModelsSection()),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Use Kudlit offline'), findsOneWidget);
    expect(find.text('Needs download'), findsWidgets);
    expect(find.byType(ProfileManagementActionButton), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

List<Override> _modelOverrides(
  _FakeYoloModelCache cache, {
  List<AiModelInfo>? visionModels,
}) {
  return <Override>[
    yoloModelCacheProvider.overrideWithValue(cache),
    availableYoloModelsProvider.overrideWith((Ref ref) async {
      return visionModels ??
          const <AiModelInfo>[
            AiModelInfo(
              id: 'vision-1',
              name: 'KudVis-1-Turbo',
              modelLink: 'https://example.com/kudvis.tflite',
              sortOrder: 0,
              version: 1,
              enabled: true,
              modelType: ModelKind.vision,
            ),
          ];
    }),
    aiInferenceNotifierProvider.overrideWith(_ReadyInferenceNotifier.new),
  ];
}

class _ReadyInferenceNotifier extends AiInferenceNotifier {
  @override
  Future<AiInferenceState> build() async {
    return const AiReady(
      mode: AiPreference.local,
      activeModel: GemmaModelInfo(
        id: 'gemma-1',
        name: 'Gemma 4 E2B',
        modelLink: 'https://example.com/gemma.bin',
      ),
    );
  }
}

class _FakeYoloModelCache implements YoloModelCacheStore {
  bool installed = false;
  final List<String> downloadedIds = <String>[];
  final List<String> upToDateChecks = <String>[];

  @override
  Future<String?> pathFor(String modelId) async {
    return installed ? '/tmp/$modelId.tflite' : null;
  }

  @override
  Future<int?> downloadedVersion(String modelId) async {
    return installed ? 1 : null;
  }

  @override
  Future<bool> isUpToDate(String modelId, int version) async {
    upToDateChecks.add(modelId);
    return installed;
  }

  @override
  Future<String> download(
    String modelId,
    String url, {
    required int version,
    void Function(int received, int total)? onProgress,
  }) async {
    downloadedIds.add(modelId);
    onProgress?.call(1, 2);
    installed = true;
    onProgress?.call(2, 2);
    return '/tmp/$modelId.tflite';
  }

  @override
  Future<void> clear(String modelId) async {
    installed = false;
  }
}
