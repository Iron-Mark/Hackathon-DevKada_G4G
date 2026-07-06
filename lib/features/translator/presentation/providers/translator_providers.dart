// ignore: unnecessary_import — flutter_riverpod is needed for Ref resolution
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kudlit_ph/features/auth/presentation/providers/auth_provider.dart';
import 'package:kudlit_ph/features/home/presentation/providers/app_preferences_provider.dart';
import 'package:kudlit_ph/features/translator/data/datasources/cloud_gemma_datasource.dart';
import 'package:kudlit_ph/features/translator/data/datasources/local_gemma_datasource.dart';
import 'package:kudlit_ph/features/home/presentation/providers/profile_management_provider.dart';
import 'package:kudlit_ph/features/translator/data/datasources/sqlite_chat_datasource.dart';
import 'package:kudlit_ph/features/translator/data/datasources/supabase_ai_models_datasource.dart';
import 'package:kudlit_ph/features/translator/data/datasources/supabase_chat_datasource.dart';
import 'package:kudlit_ph/features/translator/data/datasources/supabase_gemma_models_datasource.dart';
import 'package:kudlit_ph/features/translator/data/repositories/ai_inference_repository_impl.dart';
import 'package:kudlit_ph/features/translator/domain/entities/gemma_model_info.dart';
import 'package:kudlit_ph/features/translator/domain/repositories/ai_inference_repository.dart';
import 'package:kudlit_ph/features/translator/domain/usecases/analyze_baybayin_image.dart';
import 'package:kudlit_ph/features/translator/domain/usecases/generate_baybayin_challenge.dart';

part 'translator_providers.g.dart';

@riverpod
Future<List<GemmaModelInfo>> availableGemmaModels(Ref ref) async {
  final SupabaseGemmaModelsDatasource ds = ref.watch(
    supabaseGemmaModelsDatasourceProvider,
  );
  return ds.fetchModels();
}

@Riverpod(keepAlive: true)
SupabaseAiModelsDatasource supabaseAiModelsDatasource(Ref ref) {
  final SupabaseClient client = ref.watch(supabaseClientProvider);
  return SupabaseAiModelsDatasourceImpl(client);
}

@Riverpod(keepAlive: true)
SupabaseGemmaModelsDatasource supabaseGemmaModelsDatasource(Ref ref) {
  final SupabaseClient client = ref.watch(supabaseClientProvider);
  return SupabaseGemmaModelsDatasourceImpl(client);
}

@Riverpod(keepAlive: true)
LocalGemmaDatasource localGemmaDatasource(Ref ref) {
  final LocalGemmaDatasource ds = LocalGemmaDatasource();
  ref.onDispose(ds.dispose);
  return ds;
}

@Riverpod(keepAlive: true)
CloudGemmaDatasource cloudGemmaDatasource(Ref ref) {
  // The Gemini API key is intentionally NOT read on the client. All cloud
  // Gemma calls are proxied through the Supabase Edge Function
  // `gemini-proxy`, which holds the upstream key server-side and verifies
  // the caller's Supabase JWT.
  final SupabaseClient client = ref.watch(supabaseClientProvider);
  final CloudGemmaDatasource ds = CloudGemmaDatasource(supabase: client);
  ref.onDispose(ds.dispose);
  return ds;
}

@Riverpod(keepAlive: true)
SqliteChatDatasource sqliteChatDatasource(Ref ref) {
  final SqliteChatDatasource ds = SqliteChatDatasource();
  ref.onDispose(ds.dispose);
  return ds;
}

/// Cloud mirror for chat messages. Plain Provider (no codegen) so the file
/// does not require a regen step.
final Provider<SupabaseChatDatasource> supabaseChatDatasourceProvider =
    Provider<SupabaseChatDatasource>((Ref ref) {
      return SupabaseChatDatasource(ref.watch(supabaseProvider));
    });

@Riverpod(keepAlive: true)
AiInferenceRepository aiInferenceRepository(Ref ref) {
  // Do NOT watch preferences here — the preferenceResolver callback reads
  // them at call-time. Watching would dispose the repo (and close the active
  // InferenceModel) on any preference change, causing unnecessary reconnects.
  final AiInferenceRepositoryImpl repo = AiInferenceRepositoryImpl(
    modelsDatasource: ref.watch(supabaseGemmaModelsDatasourceProvider),
    localDatasource: ref.watch(localGemmaDatasourceProvider),
    cloudDatasource: ref.watch(cloudGemmaDatasourceProvider),
    preferenceResolver: () {
      final AsyncValue<AppPreferences> prefs = ref.read(
        appPreferencesNotifierProvider,
      );
      return prefs.value?.aiPreference ?? AiPreference.cloud;
    },
  );
  ref.onDispose(repo.dispose);
  return repo;
}

/// Single shared readiness probe for the active offline Gemma model.
///
/// keepAlive — the result is cached across navigation. Re-runs only when
/// [selectedModelId] changes; unrelated preference updates are ignored so
/// the probe (which pre-warms the native model) does not fire on every
/// settings toggle.
final FutureProvider<LocalGemmaReadiness> localModelReadinessProvider =
    FutureProvider<LocalGemmaReadiness>((Ref ref) async {
      final String? selectedModelId = ref.watch(
        appPreferencesNotifierProvider.select(
          (AsyncValue<AppPreferences> v) => v.value?.selectedModelId,
        ),
      );
      final List<GemmaModelInfo> models = await ref.read(
        availableGemmaModelsProvider.future,
      );
      if (models.isEmpty) {
        return const LocalGemmaReadiness(
          installed: false,
          usable: false,
          detail: 'Offline model is unavailable on this device.',
        );
      }
      GemmaModelInfo active = models[models.length ~/ 2];
      if (selectedModelId != null) {
        for (final GemmaModelInfo m in models) {
          if (m.id == selectedModelId) {
            active = m;
            break;
          }
        }
      }
      return ref.read(localGemmaDatasourceProvider).probeReadiness(active);
    });

@Riverpod(keepAlive: true)
AnalyzeBaybayinImage analyzeBaybayinImage(Ref ref) {
  return AnalyzeBaybayinImage(ref.watch(aiInferenceRepositoryProvider));
}

@Riverpod(keepAlive: true)
GenerateBaybayinChallenge generateBaybayinChallenge(Ref ref) {
  return GenerateBaybayinChallenge(ref.watch(aiInferenceRepositoryProvider));
}
