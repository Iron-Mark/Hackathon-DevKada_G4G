import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/features/home/presentation/providers/app_preferences_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_state.dart';

class LocalModelStatusRow extends ConsumerWidget {
  const LocalModelStatusRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AsyncValue<AiInferenceState> stateAsync = ref.watch(
      aiInferenceNotifierProvider,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 44),
          Expanded(
            child: stateAsync.when(
              loading: () => Text(
                'Checking offline download status...',
                style: TextStyle(
                  color: cs.onSurface.withAlpha(150),
                  fontSize: 13,
                ),
              ),
              error: (Object e, _) => Text(
                'Error: $e',
                style: TextStyle(color: cs.error, fontSize: 13),
              ),
              data: (AiInferenceState state) => _StatusContent(state: state),
            ),
          ),
        ],
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
            ? Text(
                'Internet mode is active. Offline download is optional.',
                style: TextStyle(
                  color: cs.onSurface.withAlpha(150),
                  fontSize: 13,
                ),
              )
            : Text(
                'Offline download is ready.',
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
      AiLocalModelMissing(:final String? note) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, size: 14, color: cs.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Offline replies are not downloaded yet.',
                  style: TextStyle(color: cs.error, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () => ref
                    .read(aiInferenceNotifierProvider.notifier)
                    .downloadLocalModel(),
                child: const Text('Download', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (note != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              note,
              style: TextStyle(
                color: cs.onSurface.withAlpha(150),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
      AiDownloading(:final progress, :final String? statusMessage) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Downloading… $progress%',
                style: TextStyle(color: cs.primary, fontSize: 13),
              ),
              InkWell(
                onTap: () => ref
                    .read(aiInferenceNotifierProvider.notifier)
                    .cancelDownload(),
                child: Icon(Icons.cancel_rounded, size: 16, color: cs.error),
              ),
            ],
          ),
          if (statusMessage != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              statusMessage,
              style: TextStyle(
                color: cs.onSurface.withAlpha(150),
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress / 100),
        ],
      ),
      AiInferenceError(:final message) => Text(
        'Offline download error: $message',
        style: TextStyle(color: cs.error, fontSize: 13),
      ),
      _ => Text(
        'Getting offline replies ready…',
        style: TextStyle(color: cs.onSurface.withAlpha(150), fontSize: 13),
      ),
    };
  }
}
