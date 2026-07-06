import 'package:flutter/material.dart';

class BeginButton extends StatelessWidget {
  const BeginButton({
    super.key,
    required this.onStart,
    this.isLocked = false,
    this.label = 'Begin Lesson',
    this.lockedReason,
  });

  final VoidCallback onStart;
  final bool isLocked;
  final String label;
  final String? lockedReason;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compactWidth = constraints.maxWidth < 420;
        final double trailingClearance = isLocked && compactWidth ? 78 : 16;

        return Padding(
          padding: EdgeInsets.fromLTRB(16, 6, trailingClearance, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FilledButton.icon(
                onPressed: isLocked ? null : onStart,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  disabledBackgroundColor: cs.surfaceContainerHighest,
                  disabledForegroundColor: cs.onSurface.withValues(alpha: 0.58),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  isLocked ? Icons.lock_rounded : Icons.play_arrow_rounded,
                  size: 18,
                ),
                label: Text(isLocked ? 'Locked' : label),
              ),
              if (isLocked && lockedReason != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  lockedReason!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
