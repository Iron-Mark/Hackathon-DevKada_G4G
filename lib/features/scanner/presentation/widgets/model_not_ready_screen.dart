import 'package:flutter/material.dart';

/// Shown inside [ScannerCamera] while the YOLO model is loading or unavailable.
///
/// Use the default constructor for the loading/downloading state.
/// Use [ModelNotReadyScreen.error] when the path resolution has failed and
/// the user needs a way to retry.
class ModelNotReadyScreen extends StatelessWidget {
  const ModelNotReadyScreen({super.key, int? progress})
    : _isLoading = true,
      _progress = progress,
      _errorMessage = null,
      _onRetry = null,
      _onSetup = null;

  const ModelNotReadyScreen.error({
    super.key,
    required String errorMessage,
    required VoidCallback onRetry,
    VoidCallback? onSetup,
  }) : _isLoading = false,
       _progress = null,
       _errorMessage = errorMessage,
       _onRetry = onRetry,
       _onSetup = onSetup;

  final bool _isLoading;
  final int? _progress;
  final String? _errorMessage;
  final VoidCallback? _onRetry;
  final VoidCallback? _onSetup;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _isLoading
                ? _LoadingContent(cs: cs, progress: _progress)
                : _ErrorContent(
                    cs: cs,
                    message:
                        _errorMessage ?? 'Scanner model could not be loaded.',
                    onRetry: _onRetry!,
                    onSetup: _onSetup,
                  ),
          ),
        ),
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent({required this.cs, required this.progress});

  final ColorScheme cs;
  final int? progress;

  @override
  Widget build(BuildContext context) {
    final int? clampedProgress = progress?.clamp(0, 100).toInt();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 3, color: cs.primary),
        ),
        const SizedBox(height: 20),
        Text(
          'Preparing Scanner',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          clampedProgress == null
              ? 'Loading the Baybayin recognition model...'
              : 'Downloading scanner model... $clampedProgress%',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: cs.onSurface.withAlpha(160),
          ),
        ),
        if (clampedProgress != null) ...<Widget>[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: clampedProgress / 100,
              color: cs.primary,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
        ],
      ],
    );
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({
    required this.cs,
    required this.message,
    required this.onRetry,
    this.onSetup,
  });

  final ColorScheme cs;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onSetup;

  @override
  Widget build(BuildContext context) {
    final bool needsSetup =
        message.contains('No scanner model') ||
        message.contains('download URL is missing');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.wifi_off_rounded, size: 56, color: cs.error.withAlpha(200)),
        const SizedBox(height: 20),
        Text(
          needsSetup ? 'Scanner model needs setup' : 'Scanner Unavailable',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: cs.onSurface.withAlpha(160),
          ),
        ),
        if (needsSetup) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            'Open Settings > Offline downloads to get camera reading ready.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: cs.onSurface.withAlpha(170),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            if (needsSetup && onSetup != null)
              FilledButton.icon(
                onPressed: onSetup,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const Text('Open downloads'),
              ),
            FilledButton.tonal(
              onPressed: onRetry,
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ],
    );
  }
}
