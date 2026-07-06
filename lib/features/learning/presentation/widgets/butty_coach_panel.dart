import 'package:flutter/material.dart';

import 'package:kudlit_ph/features/learning/presentation/providers/lesson_state.dart';

class ButtyCoachPanel extends StatelessWidget {
  const ButtyCoachPanel({
    super.key,
    required this.message,
    required this.attemptStatus,
    required this.completed,
    required this.actionLabel,
    required this.showPrimaryAction,
    required this.onAvatarTap,
    required this.onContinue,
    required this.onAskHelp,
    required this.onRetry,
  });

  final String message;
  final AttemptStatus attemptStatus;
  final bool completed;
  final String actionLabel;
  final bool showPrimaryAction;
  final VoidCallback onAvatarTap;
  final VoidCallback onContinue;
  final VoidCallback onAskHelp;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool compact = MediaQuery.sizeOf(context).height < 430;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, compact ? 6 : 10, 12, 10),
          child: _CoachCard(
            message: message,
            attemptStatus: attemptStatus,
            completed: completed,
            actionLabel: actionLabel,
            showPrimaryAction: showPrimaryAction,
            compact: compact,
            onAvatarTap: onAvatarTap,
            onAskHelp: onAskHelp,
            onRetry: onRetry,
            onContinue: onContinue,
          ),
        ),
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.message,
    required this.attemptStatus,
    required this.completed,
    required this.actionLabel,
    required this.showPrimaryAction,
    required this.compact,
    required this.onAvatarTap,
    required this.onAskHelp,
    required this.onRetry,
    required this.onContinue,
  });

  final String message;
  final AttemptStatus attemptStatus;
  final bool completed;
  final String actionLabel;
  final bool showPrimaryAction;
  final bool compact;
  final VoidCallback onAvatarTap;
  final VoidCallback onAskHelp;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(10, compact ? 8 : 10, 10, compact ? 8 : 10),
      decoration: BoxDecoration(
        color: _statusSurface(cs),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusBorder(cs)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ButtyButton(onTap: onAvatarTap, compact: compact),
              SizedBox(width: compact ? 8 : 10),
              Expanded(
                child: _CoachText(
                  message: message,
                  attemptStatus: attemptStatus,
                  compact: compact,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 6 : 8),
          _CoachActions(
            attemptStatus: attemptStatus,
            completed: completed,
            actionLabel: actionLabel,
            showPrimaryAction: showPrimaryAction,
            compact: compact,
            onAskHelp: onAskHelp,
            onRetry: onRetry,
            onContinue: onContinue,
          ),
        ],
      ),
    );
  }

  Color _statusSurface(ColorScheme cs) {
    switch (attemptStatus) {
      case AttemptStatus.correct:
        return cs.primaryContainer;
      case AttemptStatus.retry:
        return cs.errorContainer;
      case AttemptStatus.checking:
      case AttemptStatus.idle:
        return cs.surfaceContainerLow;
    }
  }

  Color _statusBorder(ColorScheme cs) {
    switch (attemptStatus) {
      case AttemptStatus.correct:
        return cs.primary.withValues(alpha: 0.4);
      case AttemptStatus.retry:
        return cs.error.withValues(alpha: 0.4);
      case AttemptStatus.checking:
      case AttemptStatus.idle:
        return cs.outlineVariant;
    }
  }
}

class _ButtyButton extends StatelessWidget {
  const _ButtyButton({required this.onTap, required this.compact});

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ask Butty for help',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: compact ? 50 : 62,
          height: compact ? 54 : 68,
          child: Image.asset(
            'assets/brand/ButtyWave.webp',
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}

class _CoachText extends StatelessWidget {
  const _CoachText({
    required this.message,
    required this.attemptStatus,
    required this.compact,
  });

  final String message;
  final AttemptStatus attemptStatus;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool isThinking =
        attemptStatus == AttemptStatus.checking && message.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Butty',
          style: text.labelSmall?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 3),
        isThinking
            ? const _ThinkingDots()
            : Text(
                message,
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  height: 1.28,
                ),
              ),
      ],
    );
  }
}

class _CoachActions extends StatelessWidget {
  const _CoachActions({
    required this.attemptStatus,
    required this.completed,
    required this.actionLabel,
    required this.showPrimaryAction,
    required this.compact,
    required this.onAskHelp,
    required this.onRetry,
    required this.onContinue,
  });

  final AttemptStatus attemptStatus;
  final bool completed;
  final String actionLabel;
  final bool showPrimaryAction;
  final bool compact;
  final VoidCallback onAskHelp;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final bool isChecking = attemptStatus == AttemptStatus.checking;
    final bool canRetry = attemptStatus == AttemptStatus.retry;
    final ButtonStyle compactStyle = TextButton.styleFrom(
      minimumSize: const Size(44, 44),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
    );
    return Wrap(
      spacing: 8,
      runSpacing: compact ? 6 : 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: <Widget>[
        TextButton.icon(
          onPressed: onAskHelp,
          icon: const Icon(Icons.help_outline_rounded, size: 18),
          label: const Text('Help'),
          style: compactStyle,
        ),
        if (canRetry)
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(44, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
            ),
          ),
        if (showPrimaryAction)
          FilledButton.icon(
            onPressed: isChecking ? null : onContinue,
            icon: isChecking
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    completed
                        ? Icons.flag_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                  ),
            label: Text(isChecking ? 'Checking' : actionLabel),
            style: FilledButton.styleFrom(
              minimumSize: const Size(44, 44),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
            ),
          ),
      ],
    );
  }
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (BuildContext context, Widget? _) {
        final int dotCount = (_ctrl.value * 3).floor() + 1;
        return Text(
          'Butty is thinking${'.' * dotCount}',
          style: text.bodyMedium?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.55),
            fontStyle: FontStyle.italic,
          ),
        );
      },
    );
  }
}
