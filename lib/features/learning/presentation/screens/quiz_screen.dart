import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/features/learning/domain/entities/lesson_step.dart';
import 'package:kudlit_ph/features/learning/presentation/providers/quiz_provider.dart';
import 'package:kudlit_ph/features/learning/presentation/widgets/learning_route_back.dart';
import 'package:kudlit_ph/features/learning/presentation/widgets/quiz_result_card.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizProvider.notifier).loadQuiz();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    ref.read(quizProvider.notifier).submitAnswer(_controller.text);
  }

  void _next() {
    _controller.clear();
    ref.read(quizProvider.notifier).next();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<QuizState?> quizAsync = ref.watch(quizProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const LearnRouteBackButton(),
        title: const Text('Quick Quiz'),
      ),
      body: quizAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => const _QuizErrorBody(),
        data: (QuizState? state) => state == null
            ? const _QuizEmptyBody()
            : _QuizDataBody(
                state: state,
                controller: _controller,
                onCheck: _checkAnswer,
                onNext: _next,
              ),
      ),
    );
  }
}

// ─── Body ──────────────────────────────────────────────────────────────────────

class _QuizDataBody extends ConsumerWidget {
  const _QuizDataBody({
    required this.state,
    required this.controller,
    required this.onCheck,
    required this.onNext,
  });

  final QuizState state;
  final TextEditingController controller;
  final VoidCallback onCheck;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.status == QuizStatus.complete) {
      return QuizResultCard(
        score: state.correctCount,
        total: state.totalQuestions,
        onRetry: () => ref.read(quizProvider.notifier).loadQuiz(),
        onDone: () => returnToLearn(context),
      );
    }
    return _QuizBody(
      quizState: state,
      controller: controller,
      onCheck: onCheck,
      onNext: onNext,
    );
  }
}

class _QuizErrorBody extends StatelessWidget {
  const _QuizErrorBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Failed to load quiz.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _QuizEmptyBody extends StatelessWidget {
  const _QuizEmptyBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Complete a lesson first to unlock the quiz.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

class _QuizBody extends StatelessWidget {
  const _QuizBody({
    required this.quizState,
    required this.controller,
    required this.onCheck,
    required this.onNext,
  });

  final QuizState quizState;
  final TextEditingController controller;
  final VoidCallback onCheck;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final bool isAnswered = quizState.status != QuizStatus.answering;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact =
            constraints.maxHeight < 500 ||
            constraints.maxWidth > constraints.maxHeight;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 24,
            compact ? 10 : 16,
            compact ? 16 : 24,
            MediaQuery.paddingOf(context).bottom + (compact ? 16 : 24),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _QuizProgressBar(
                    current: quizState.currentIndex + 1,
                    total: quizState.totalQuestions,
                  ),
                  SizedBox(height: compact ? 14 : 24),
                  _GlyphDisplay(step: quizState.currentStep, compact: compact),
                  SizedBox(height: compact ? 14 : 24),
                  if (isAnswered)
                    _AnsweredSection(
                      status: quizState.status,
                      step: quizState.currentStep,
                      isLast:
                          quizState.currentIndex + 1 >=
                          quizState.totalQuestions,
                      onNext: onNext,
                    )
                  else
                    _AnsweringSection(
                      controller: controller,
                      onCheck: onCheck,
                      compact: compact,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _QuizProgressBar extends StatelessWidget {
  const _QuizProgressBar({required this.current, required this.total});

  final int current;
  final int total;

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
              'Question $current of $total',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: current / total, minHeight: 6),
        ),
      ],
    );
  }
}

class _GlyphDisplay extends StatelessWidget {
  const _GlyphDisplay({required this.step, required this.compact});

  final LessonStep step;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 16 : 26),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            step.glyph,
            style: TextStyle(
              fontFamily: 'Baybayin Simple TAWBID',
              fontSize: compact ? 72 : 88,
              height: 1,
              color: cs.onPrimaryContainer,
            ),
          ),
          SizedBox(height: compact ? 4 : 8),
          Text(
            'What is this character?',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: cs.onPrimaryContainer.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnsweringSection extends StatelessWidget {
  const _AnsweringSection({
    required this.controller,
    required this.onCheck,
    required this.compact,
  });

  final TextEditingController controller;
  final VoidCallback onCheck;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Romanization',
            hintText: 'e.g. ba, ka, da...',
            border: const OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: compact ? 12 : 14,
            ),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.none,
          onSubmitted: (_) => onCheck(),
        ),
        SizedBox(height: compact ? 10 : 14),
        FilledButton(
          onPressed: onCheck,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
          child: const Text('Check'),
        ),
      ],
    );
  }
}

class _AnsweredSection extends StatelessWidget {
  const _AnsweredSection({
    required this.status,
    required this.step,
    required this.isLast,
    required this.onNext,
  });

  final QuizStatus status;
  final LessonStep step;
  final bool isLast;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool isCorrect = status == QuizStatus.correct;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isCorrect ? cs.primaryContainer : cs.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCorrect ? cs.primary : cs.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCorrect
                      ? 'Correct!'
                      : 'Answer: ${step.expected.first.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCorrect
                        ? cs.onPrimaryContainer
                        : cs.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: onNext,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
          child: Text(isLast ? 'See Results' : 'Next'),
        ),
      ],
    );
  }
}
