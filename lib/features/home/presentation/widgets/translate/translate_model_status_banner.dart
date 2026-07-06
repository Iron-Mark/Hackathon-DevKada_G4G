import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/features/home/presentation/providers/app_preferences_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_state.dart';

/// Offline-model status for the translate page, driven by the same
/// `aiInferenceNotifierProvider` Butty uses. Gives translate the identical
/// missing → download → ready lifecycle and setup affordance.
class TranslateModelStatusBanner extends ConsumerWidget {
  const TranslateModelStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<AiInferenceState> stateAsync = ref.watch(
      aiInferenceNotifierProvider,
    );

    final Widget content = stateAsync.when(
      loading: () => _line(cs, 'Preparing offline Gemma…'),
      error: (Object e, _) => _line(cs, 'Offline model error: $e', error: true),
      data: (AiInferenceState state) => _StatusContent(state: state),
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withAlpha(120)),
      ),
      child: content,
    );
  }

  static Widget _line(ColorScheme cs, String text, {bool error = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: error ? cs.error : cs.onSurface.withAlpha(180),
      ),
    );
  }
}

class _StatusContent extends ConsumerWidget {
  const _StatusContent({required this.state});

  final AiInferenceState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return switch (state) {
      AiReady(:final AiPreference mode) =>
        mode == AiPreference.cloud
            ? TranslateModelStatusBanner._line(
                cs,
                'Online Gemma is active.',
              )
            : Row(
                children: <Widget>[
                  Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Offline Gemma ready.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
      AiLocalModelMissing(:final String? note) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, size: 15, color: cs.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Offline Gemma is not downloaded yet.',
                  style: TextStyle(fontSize: 12, color: cs.error),
                ),
              ),
              TextButton(
                onPressed: () => ref
                    .read(aiInferenceNotifierProvider.notifier)
                    .downloadLocalModel(),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text(
                  'Set up',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (note != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              note,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withAlpha(150),
              ),
            ),
          ],
        ],
      ),
      AiDownloading(:final int progress, :final String? statusMessage) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Downloading offline Gemma… $progress%',
                  style: TextStyle(fontSize: 12, color: cs.primary),
                ),
                InkWell(
                  onTap: () => ref
                      .read(aiInferenceNotifierProvider.notifier)
                      .cancelDownload(),
                  child: Icon(
                    Icons.cancel_rounded,
                    size: 16,
                    color: cs.error,
                  ),
                ),
              ],
            ),
            if (statusMessage != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                statusMessage,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withAlpha(150),
                ),
              ),
            ],
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: progress / 100),
            ),
          ],
        ),
      AiInferenceError(:final String message) =>
        TranslateModelStatusBanner._line(
          cs,
          'Offline Gemma error: $message',
          error: true,
        ),
      _ => TranslateModelStatusBanner._line(cs, 'Getting offline Gemma ready…'),
    };
  }
}
