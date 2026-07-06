import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/features/scanner/data/datasources/web_vision_model_preflight.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/yolo_model_selection_provider.dart';
import 'package:kudlit_ph/features/translator/domain/entities/ai_model_info.dart';

import 'profile_management_action_button.dart';

class VisionDownloadTile extends ConsumerStatefulWidget {
  const VisionDownloadTile({super.key});

  @override
  ConsumerState<VisionDownloadTile> createState() => _VisionDownloadTileState();
}

class _VisionDownloadTileState extends ConsumerState<VisionDownloadTile> {
  bool _downloading = false;
  int _progress = 0;
  String? _error;

  Future<void> _prepare(AiModelInfo model) async {
    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
    });

    try {
      if (kIsWeb) {
        await createWebVisionModelPreflight().run(model.modelLink);
      } else {
        final String url = resolveYoloModelUrl(model);
        await ref
            .read(yoloModelCacheProvider)
            .download(
              model.id,
              url,
              version: model.version,
              onProgress: (int received, int total) {
                if (!mounted || total <= 0) return;
                setState(() => _progress = ((received / total) * 100).round());
              },
            );
      }

      ref.invalidate(visionModelSetupStatusProvider);
      ref.invalidate(yoloModelPathProvider);
      final AiModelInfo? activeCameraModel = ref
          .read(activeYoloModelProvider(YoloModelScope.camera))
          .value;
      if (!kIsWeb && activeCameraModel?.id == model.id) {
        unawaited(
          ref
              .read(yoloModelPathProvider(YoloModelScope.camera).future)
              .catchError((Object _) => ''),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = kIsWeb
              ? friendlyVisionModelError(e.toString())
              : e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<AiModelInfo>> modelsAsync = ref.watch(
      availableYoloModelsProvider,
    );
    final AsyncValue<AiModelInfo?> activeModelAsync = ref.watch(
      activeYoloModelProvider(YoloModelScope.camera),
    );
    final List<AiModelInfo>? availableModels = modelsAsync.asData?.value;
    final AiModelInfo? activeModel = activeModelAsync.asData?.value;
    final String headerLabel =
        activeModel?.name ??
        ((availableModels != null && availableModels.isNotEmpty)
            ? availableModels.first.name
            : 'Scanner model');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _VisionTileHeader(label: headerLabel),
          const SizedBox(height: 10),
          modelsAsync.when(
            loading: () => const _CheckingRow(),
            error: (Object e, _) => _ErrRow(message: e.toString()),
            data: (List<AiModelInfo> models) => _body(models, activeModelAsync),
          ),
        ],
      ),
    );
  }

  Widget _body(
    List<AiModelInfo> models,
    AsyncValue<AiModelInfo?> activeModelAsync,
  ) {
    if (models.isEmpty) {
      return const _NoModelRow();
    }

    return activeModelAsync.when(
      loading: () => const _CheckingRow(),
      error: (Object e, _) => _ErrRow(message: e.toString()),
      data: (AiModelInfo? activeModel) {
        final AiModelInfo model = activeModel ?? models.first;

        if (_downloading) {
          return _DownloadProgressRow(
            label: model.name,
            progress: _progress,
            checkingWebModel: kIsWeb,
          );
        }
        if (_error != null) {
          return _ErrRow(message: _error!);
        }
        return _VisionStatusRow(model: model, onPrepare: () => _prepare(model));
      },
    );
  }
}

class _VisionStatusRow extends ConsumerWidget {
  const _VisionStatusRow({required this.model, required this.onPrepare});

  final AiModelInfo model;
  final VoidCallback onPrepare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<VisionModelSetupStatus> statusAsync = ref.watch(
      visionModelSetupStatusProvider,
    );
    return statusAsync.when(
      loading: () => const _CheckingRow(),
      error: (Object e, _) => _ErrRow(message: e.toString()),
      data: (VisionModelSetupStatus status) {
        if (status.ready) {
          return _VisionActionRow(
            badge: const _StatusBadge(label: 'Ready to scan', ok: true),
            supportingText: 'Downloaded and ready when you open the scanner.',
            action: ProfileManagementActionButton(
              label: 'Set up again',
              onTap: onPrepare,
            ),
          );
        }

        return _VisionActionRow(
          badge: const _StatusBadge(label: 'Needs download', ok: false),
          supportingText: kIsWeb
              ? 'Set this up once to use camera reading in this browser.'
              : 'Download once before using camera reading.',
          action: ProfileManagementActionButton(
            label: 'Set up',
            isPrimary: true,
            onTap: onPrepare,
          ),
        );
      },
    );
  }
}

class _VisionActionRow extends StatelessWidget {
  const _VisionActionRow({
    required this.badge,
    required this.supportingText,
    required this.action,
  });

  final Widget badge;
  final String supportingText;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Widget statusCopy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        badge,
        const SizedBox(height: 6),
        Text(
          supportingText,
          style: TextStyle(
            fontSize: 11,
            height: 1.25,
            color: cs.onSurface.withAlpha(150),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              statusCopy,
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: action),
            ],
          );
        }

        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: <Widget>[
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
              child: statusCopy,
            ),
            action,
          ],
        );
      },
    );
  }
}

class _DownloadProgressRow extends StatelessWidget {
  const _DownloadProgressRow({
    required this.label,
    required this.progress,
    required this.checkingWebModel,
  });

  final String label;
  final int progress;
  final bool checkingWebModel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    if (checkingWebModel) {
      return Row(
        children: <Widget>[
          Flexible(
            child: Text(
              'Getting camera reading ready...',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.primary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Downloading… $progress%',
          style: TextStyle(color: cs.primary, fontSize: 13),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: progress / 100),
      ],
    );
  }
}

class _VisionTileHeader extends StatelessWidget {
  const _VisionTileHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        Icon(Icons.camera_alt_rounded, size: 18, color: cs.primary),
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
                kIsWeb
                    ? 'Baybayin camera reading in this browser'
                    : 'Reads Baybayin with your camera',
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
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color bg = ok ? cs.primaryContainer : cs.errorContainer;
    final Color fg = ok ? cs.onPrimaryContainer : cs.onErrorContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, color: fg),
      ),
    );
  }
}

class _NoModelRow extends StatelessWidget {
  const _NoModelRow();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Scanner model setup is unavailable in this build.',
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
      ),
    );
  }
}

class _CheckingRow extends StatelessWidget {
  const _CheckingRow();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Checking status...',
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
    return Semantics(
      label: 'Setup failed: $message',
      child: Text(
        'Setup failed. Check your connection and try again.',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}
