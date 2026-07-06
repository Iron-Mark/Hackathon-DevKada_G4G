import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/features/home/presentation/providers/app_preferences_provider.dart';
import 'package:kudlit_ph/features/translator/data/datasources/local_gemma_datasource.dart';
import 'package:kudlit_ph/features/translator/domain/entities/gemma_model_info.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_state.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/translator_providers.dart';

import 'profile_management_action_button.dart';

class LlmDownloadTile extends ConsumerWidget {
  const LlmDownloadTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AiInferenceNotifier notifier = ref.read(
      aiInferenceNotifierProvider.notifier,
    );
    final AsyncValue<AiInferenceState> stateAsync = ref.watch(
      aiInferenceNotifierProvider,
    );
    final AsyncValue<AppPreferences> prefsAsync = ref.watch(
      appPreferencesNotifierProvider,
    );
    final AsyncValue<LocalGemmaReadiness> readinessAsync = ref.watch(
      localModelReadinessProvider,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _TileHeader(
            icon: Icons.psychology_rounded,
            label: 'Butty replies',
            sublabel: 'Offline replies  ·  large download',
          ),
          const SizedBox(height: 10),
          _LlmStatusRow(
            stateAsync: stateAsync,
            prefsAsync: prefsAsync,
            readinessAsync: readinessAsync,
            onCancel: notifier.cancelDownload,
            onTrigger: (GemmaModelInfo m) => notifier.triggerLocalDownload(m),
          ),
        ],
      ),
    );
  }
}

class _LlmStatusRow extends StatelessWidget {
  const _LlmStatusRow({
    required this.stateAsync,
    required this.prefsAsync,
    required this.readinessAsync,
    required this.onCancel,
    required this.onTrigger,
  });

  final AsyncValue<AiInferenceState> stateAsync;
  final AsyncValue<AppPreferences> prefsAsync;
  final AsyncValue<LocalGemmaReadiness> readinessAsync;
  final void Function() onCancel;
  final void Function(GemmaModelInfo) onTrigger;

  @override
  Widget build(BuildContext context) {
    if (stateAsync.hasError) {
      return _ErrRow(
        message: _friendlyLlmModelError(stateAsync.asError!.error.toString()),
      );
    }

    final AiInferenceState? state = stateAsync.value;
    if (state is AiDownloading) {
      return _ProgressRow(
        progress: state.progress,
        onCancel: onCancel,
        statusMessage: state.statusMessage,
      );
    }
    if (state is AiInferenceError) {
      return _ErrRow(message: _friendlyLlmModelError(state.message));
    }

    if (prefsAsync.hasError) {
      return _ErrRow(
        message: _friendlyLlmModelError(prefsAsync.asError!.error.toString()),
      );
    }
    if (readinessAsync.hasError) {
      return _ErrRow(
        message: _friendlyLlmModelError(readinessAsync.error.toString()),
      );
    }

    final AppPreferences? prefs = prefsAsync.value;
    final LocalGemmaReadiness? readiness = readinessAsync.value;
    final GemmaModelInfo? activeModel = switch (state) {
      AiReady(:final GemmaModelInfo activeModel) => activeModel,
      AiLocalModelMissing(:final GemmaModelInfo model) => model,
      _ => null,
    };

    if (prefs == null || readiness == null || activeModel == null) {
      return const _CheckingRow();
    }

    if (readiness.installed && readiness.usable) {
      return _ReadyRow(
        cloudMode: prefs.aiPreference == AiPreference.cloud,
        note: prefs.aiPreference == AiPreference.cloud
            ? 'Downloaded and ready whenever you switch to Offline mode.'
            : 'Downloaded and ready to use without internet.',
      );
    }

    return _ActionRow(
      badge: _StatusBadge(
        label: readiness.installed ? 'Almost ready' : 'Needs download',
        ok: readiness.installed ? null : false,
      ),
      primary: readiness.installed ? 'Reload' : 'Download',
      onPrimary: () => onTrigger(activeModel),
      note: readiness.installed
          ? 'We are still getting this ready.'
          : 'Download once to use Butty without internet.',
    );
  }
}

class _ReadyRow extends StatelessWidget {
  const _ReadyRow({required this.cloudMode, this.note});

  final bool cloudMode;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            _StatusBadge(
              label: cloudMode ? 'Downloaded' : 'Ready offline',
              ok: true,
            ),
          ],
        ),
        if (note != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            note!,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.badge,
    required this.primary,
    required this.onPrimary,
    this.note,
  });

  final Widget badge;
  final String primary;
  final VoidCallback onPrimary;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            badge,
            const Spacer(),
            ProfileManagementActionButton(
              label: primary,
              isPrimary: true,
              onTap: onPrimary,
            ),
          ],
        ),
        if (note != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            note!,
            style: TextStyle(fontSize: 11, color: cs.onSurface.withAlpha(150)),
          ),
        ],
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.progress,
    required this.onCancel,
    this.statusMessage,
  });

  final int progress;
  final VoidCallback onCancel;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Downloading… $progress%',
              style: TextStyle(color: cs.primary, fontSize: 13),
            ),
            GestureDetector(
              onTap: onCancel,
              child: Text(
                'Cancel',
                style: TextStyle(color: cs.error, fontSize: 12),
              ),
            ),
          ],
        ),
        if (statusMessage != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            statusMessage!,
            style: TextStyle(color: cs.onSurface.withAlpha(150), fontSize: 11),
          ),
        ],
        const SizedBox(height: 6),
        LinearProgressIndicator(value: progress / 100),
      ],
    );
  }
}

class _TileHeader extends StatelessWidget {
  const _TileHeader({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  final IconData icon;
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              Text(
                sublabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withAlpha(128),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.ok});

  final String label;
  final bool? ok;

  @override
  Widget build(BuildContext context) {
    final Color bg = ok == true
        ? Colors.green.shade800.withAlpha(40)
        : ok == false
        ? Colors.red.shade800.withAlpha(40)
        : Theme.of(context).colorScheme.surfaceContainerHigh;
    final Color fg = ok == true
        ? Colors.green.shade300
        : ok == false
        ? Colors.red.shade300
        : Theme.of(context).colorScheme.onSurface.withAlpha(150);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: fg)),
    );
  }
}

class _CheckingRow extends StatelessWidget {
  const _CheckingRow();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Checking…',
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
      ),
    );
  }
}

class _ErrRow extends StatelessWidget {
  const _ErrRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Error: $message',
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

String _friendlyLlmModelError(String rawMessage) {
  final String message = rawMessage.trim();
  if (message.isEmpty) {
    return 'Offline setup is paused. You can stay on internet mode and try again later.';
  }

  final String lower = message.toLowerCase();
  final bool looksLikeNetworkIssue =
      lower.contains('socketexception') ||
      lower.contains('clientexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('network') ||
      lower.contains('connection') ||
      lower.contains('timeout') ||
      lower.contains('supabase.co');
  if (looksLikeNetworkIssue) {
    return 'Check your connection, then retry the model download.';
  }

  if (lower.contains('cancel')) {
    return 'Download canceled. You can retry when you are ready.';
  }

  if (lower.contains('no ai models configured')) {
    return 'Offline downloads are not available right now. You can stay on internet mode for now.';
  }

  final bool looksTechnical =
      lower.contains('exception') ||
      lower.contains('stacktrace') ||
      lower.contains('statuscode') ||
      lower.contains('errno') ||
      lower.contains('uri=') ||
      lower.contains('https://');
  if (looksTechnical) {
    return 'Offline setup is paused. You can stay on internet mode and try again later.';
  }

  return message;
}
