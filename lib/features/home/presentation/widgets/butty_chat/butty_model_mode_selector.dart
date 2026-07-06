import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/features/home/presentation/providers/app_preferences_provider.dart';
import 'package:kudlit_ph/features/translator/data/datasources/local_gemma_datasource.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_state.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/translator_providers.dart';

@immutable
class ButtyOfflineStatus {
  const ButtyOfflineStatus({required this.usable, this.modelName, this.detail});

  final bool usable;
  final String? modelName;
  final String? detail;
}

final FutureProvider<ButtyOfflineStatus> buttyOfflineStatusProvider =
    FutureProvider<ButtyOfflineStatus>((Ref ref) async {
      final LocalGemmaReadiness r = await ref.watch(
        localModelReadinessProvider.future,
      );
      return ButtyOfflineStatus(
        usable: r.usable,
        modelName: r.modelName,
        detail: r.detail,
      );
    });

class ButtyModelModeSelector extends ConsumerWidget {
  const ButtyModelModeSelector({super.key, this.showHelperText = true});

  final bool showHelperText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<AppPreferences> prefsAsync = ref.watch(
      appPreferencesNotifierProvider,
    );
    final AsyncValue<AiInferenceState> inferenceAsync = ref.watch(
      aiInferenceNotifierProvider,
    );
    final AsyncValue<ButtyOfflineStatus> offlineStatusAsync = ref.watch(
      buttyOfflineStatusProvider,
    );

    final AiPreference currentMode =
        prefsAsync.value?.aiPreference ?? AiPreference.cloud;
    final ButtyOfflineStatus? offlineStatus = offlineStatusAsync.value;
    final bool offlineReady = offlineStatus?.usable ?? false;
    final bool offlineChecking =
        offlineStatusAsync.isLoading || inferenceAsync.isLoading;
    final String helperText = switch (offlineStatusAsync) {
      AsyncData(:final ButtyOfflineStatus value) =>
        value.detail ?? 'Offline status unknown.',
      AsyncError() =>
        'Offline check failed. Stay on internet mode or try again later.',
      _ => 'Checking whether offline replies are ready…',
    };

    final Widget pills = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ModePill(
            label: showHelperText ? 'Online' : 'Cloud',
            active: currentMode == AiPreference.cloud,
            onTap: () => _setMode(ref, AiPreference.cloud),
          ),
          _ModePill(
            label: showHelperText ? 'Offline' : 'Local',
            active: currentMode == AiPreference.local,
            enabled: offlineReady && !offlineChecking,
            onTap: () => _setMode(ref, AiPreference.local),
          ),
        ],
      ),
    );

    if (!showHelperText) return pills;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        pills,
        const SizedBox(height: 6),
        Text(
          helperText,
          style: TextStyle(fontSize: 10.5, color: cs.onSurface.withAlpha(170)),
        ),
      ],
    );
  }

  Future<void> _setMode(WidgetRef ref, AiPreference mode) async {
    debugPrint('[Butty] model mode selected -> ${mode.name}');
    final AppPreferencesNotifier notifier = ref.read(
      appPreferencesNotifierProvider.notifier,
    );
    await notifier.setAiPreference(mode);
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.label,
    required this.active,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color bg = active ? cs.primary : Colors.transparent;
    final Color fg = active
        ? cs.onPrimary
        : enabled
        ? cs.primary
        : cs.onSurface.withAlpha(110);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: const BoxConstraints(minHeight: 36),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
