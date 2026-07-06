import 'dart:math';

import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kudlit_ph/features/home/presentation/providers/app_preferences_provider.dart';
import 'package:kudlit_ph/features/home/presentation/providers/profile_management_provider.dart';
import 'package:kudlit_ph/features/learning/domain/entities/lesson_mode.dart';
import 'package:kudlit_ph/features/learning/domain/entities/lesson_step.dart';

part 'quiz_provider.g.dart';

enum QuizStatus { answering, correct, wrong, complete }

@immutable
class QuizState {
  const QuizState({
    required this.steps,
    required this.currentIndex,
    required this.correctCount,
    required this.status,
  });

  final List<LessonStep> steps;
  final int currentIndex;
  final int correctCount;
  final QuizStatus status;

  LessonStep get currentStep => steps[currentIndex];
  int get totalQuestions => steps.length;

  QuizState copyWith({
    int? currentIndex,
    int? correctCount,
    QuizStatus? status,
  }) {
    return QuizState(
      steps: steps,
      currentIndex: currentIndex ?? this.currentIndex,
      correctCount: correctCount ?? this.correctCount,
      status: status ?? this.status,
    );
  }
}

@riverpod
class QuizNotifier extends _$QuizNotifier {
  @override
  Future<QuizState?> build() async => null;

  Future<void> loadQuiz() async {
    state = const AsyncLoading<QuizState?>();

    final Set<String> completed = ref
        .read(appPreferencesNotifierProvider)
        .maybeWhen(
          data: (AppPreferences p) => p.completedLessons,
          orElse: () => const <String>{},
        );

    if (completed.isEmpty) {
      state = const AsyncData<QuizState?>(null);
      return;
    }

    try {
      final SupabaseClient client = ref.read(supabaseProvider);
      final List<Map<String, dynamic>> rows = await client
          .from('lesson_steps')
          .select()
          .eq('mode', 'freeInput')
          .inFilter('lesson_id', completed.toList());

      if (rows.isEmpty) {
        state = const AsyncData<QuizState?>(null);
        return;
      }

      final List<Map<String, dynamic>> shuffled =
          List<Map<String, dynamic>>.from(rows)..shuffle(Random());
      final List<LessonStep> steps = shuffled
          .take(5)
          .map(_parseStep)
          .toList(growable: false);

      state = AsyncData<QuizState?>(
        QuizState(
          steps: steps,
          currentIndex: 0,
          correctCount: 0,
          status: QuizStatus.answering,
        ),
      );
    } catch (e, st) {
      state = AsyncError<QuizState?>(e, st);
    }
  }

  void submitAnswer(String value) {
    final QuizState? current = state.value;
    if (current == null || current.status != QuizStatus.answering) return;

    final String normalized = value.trim().toLowerCase();
    final bool isCorrect = current.currentStep.expected.contains(normalized);

    state = AsyncData<QuizState?>(
      current.copyWith(
        status: isCorrect ? QuizStatus.correct : QuizStatus.wrong,
        correctCount: isCorrect
            ? current.correctCount + 1
            : current.correctCount,
      ),
    );
  }

  void next() {
    final QuizState? current = state.value;
    if (current == null || current.status == QuizStatus.answering) return;

    final int nextIndex = current.currentIndex + 1;
    if (nextIndex >= current.totalQuestions) {
      state = AsyncData<QuizState?>(
        current.copyWith(status: QuizStatus.complete),
      );
      return;
    }

    state = AsyncData<QuizState?>(
      current.copyWith(currentIndex: nextIndex, status: QuizStatus.answering),
    );
  }

  static LessonStep _parseStep(Map<String, dynamic> row) {
    final List<dynamic> rawExpected =
        (row['expected'] as List<dynamic>?) ?? const <dynamic>[];
    return LessonStep(
      id: row['id'] as String,
      mode: LessonMode.freeInput,
      label: (row['label'] as String?) ?? '',
      glyph: row['glyph'] as String,
      expected: rawExpected
          .map((dynamic e) => (e as String).trim().toLowerCase())
          .toList(growable: false),
    );
  }
}
