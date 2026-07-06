import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/features/home/presentation/providers/app_preferences_provider.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/yolo_model_selection_provider.dart';
import 'package:kudlit_ph/features/translator/data/datasources/local_gemma_datasource.dart';
import 'package:kudlit_ph/features/translator/domain/entities/ai_model_info.dart';
import 'package:kudlit_ph/features/translator/domain/entities/gemma_model_info.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_state.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/translator_providers.dart';

@immutable
class ModelSetupState {
  const ModelSetupState({required this.busy, this.errorMessage});

  const ModelSetupState.initial() : this(busy: false);

  final bool busy;
  final String? errorMessage;

  ModelSetupState copyWith({
    bool? busy,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ModelSetupState(
      busy: busy ?? this.busy,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final NotifierProvider<ModelSetupController, ModelSetupState>
modelSetupControllerProvider =
    NotifierProvider<ModelSetupController, ModelSetupState>(
      ModelSetupController.new,
    );

class ModelSetupController extends Notifier<ModelSetupState> {
  @override
  ModelSetupState build() => const ModelSetupState.initial();

  Future<void> completeSetup() async {
    if (state.busy) {
      return;
    }

    state = state.copyWith(busy: true, clearError: true);

    try {
      final VisionModelSetupStatus visionStatus = await ref.refresh(
        visionModelSetupStatusProvider.future,
      );
      if (!visionStatus.ready) {
        state = state.copyWith(busy: false, errorMessage: visionStatus.message);
        return;
      }

      final LocalGemmaReadiness gemmaReadiness = await ref.refresh(
        localModelReadinessProvider.future,
      );
      if (!gemmaReadiness.installed || !gemmaReadiness.usable) {
        state = state.copyWith(
          busy: false,
          errorMessage: 'Finish the offline downloads before continuing.',
        );
        return;
      }

      await ref
          .read(appPreferencesNotifierProvider.notifier)
          .setAiPreference(AiPreference.local);
      await ref
          .read(appPreferencesNotifierProvider.notifier)
          .markModelsDownloaded();
      state = state.copyWith(busy: false, clearError: true);
    } catch (e) {
      state = state.copyWith(busy: false, errorMessage: e.toString());
    }
  }

  Future<void> download(GemmaModelInfo llmModel) async {
    if (state.busy) {
      return;
    }

    state = state.copyWith(busy: true, clearError: true);

    await ref
        .read(aiInferenceNotifierProvider.notifier)
        .triggerLocalDownload(llmModel);

    final AiInferenceState? inferenceState = ref
        .read(aiInferenceNotifierProvider)
        .value;
    if (inferenceState is AiInferenceError) {
      state = state.copyWith(busy: false, errorMessage: inferenceState.message);
      return;
    }

    try {
      if (kIsWeb) {
        final VisionModelSetupStatus visionStatus = await ref.refresh(
          visionModelSetupStatusProvider.future,
        );
        if (!visionStatus.ready) {
          state = state.copyWith(
            busy: false,
            errorMessage: visionStatus.message,
          );
          return;
        }
      } else {
        final List<AiModelInfo> visionModels = await ref.read(
          availableYoloModelsProvider.future,
        );
        final AiModelInfo? visionModel = visionModels.isEmpty
            ? null
            : visionModels.first;
        if (visionModel == null) {
          state = state.copyWith(
            busy: false,
            errorMessage: 'No scanner model is configured yet.',
          );
          return;
        }

        final String yoloUrl = resolveYoloModelUrl(visionModel);
        if (yoloUrl.isEmpty) {
          state = state.copyWith(
            busy: false,
            errorMessage:
                'The selected scanner model does not have a download URL.',
          );
          return;
        }

        await ref
            .read(yoloModelCacheProvider)
            .download(visionModel.id, yoloUrl, version: visionModel.version);
        ref.invalidate(visionModelSetupStatusProvider);
        ref.invalidate(yoloModelPathProvider);
        unawaited(
          ref
              .read(yoloModelPathProvider(YoloModelScope.camera).future)
              .catchError((Object _) => ''),
        );
      }
    } catch (e) {
      debugPrint('[ModelSetup] YOLO download failed: $e');
      state = state.copyWith(
        busy: false,
        errorMessage: friendlyVisionModelError(e.toString()),
      );
      return;
    }

    await ref
        .read(appPreferencesNotifierProvider.notifier)
        .setAiPreference(AiPreference.local);
    await ref
        .read(appPreferencesNotifierProvider.notifier)
        .markModelsDownloaded();
    state = state.copyWith(busy: false, clearError: true);
  }

  void skip() {
    if (state.busy) {
      return;
    }
    ref.read(modelSetupSkippedProvider.notifier).setSkipped();
  }
}
