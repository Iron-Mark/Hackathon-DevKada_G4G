// ignore: unnecessary_import — flutter_riverpod is needed for Ref resolution
import 'dart:async';

import 'package:flutter/painting.dart' show Offset;
import 'package:flutter/foundation.dart' show Uint8List, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/features/home/presentation/providers/profile_management_provider.dart';
import 'package:kudlit_ph/features/learning/domain/entities/gemma_prompts.dart';
import 'package:kudlit_ph/features/learning/domain/entities/lesson.dart';
import 'package:kudlit_ph/features/learning/domain/entities/lesson_mode.dart';
import 'package:kudlit_ph/features/learning/domain/entities/lesson_progress.dart';
import 'package:kudlit_ph/features/learning/domain/entities/lesson_step.dart';
import 'package:kudlit_ph/features/learning/domain/usecases/load_lesson.dart';
import 'package:kudlit_ph/features/learning/presentation/providers/lesson_progress_provider.dart';
import 'package:kudlit_ph/features/learning/presentation/providers/lesson_repository_provider.dart';
import 'package:kudlit_ph/features/learning/presentation/providers/lesson_state.dart';
import 'package:kudlit_ph/features/translator/domain/entities/chat_message.dart';
import 'package:kudlit_ph/features/translator/domain/repositories/ai_inference_repository.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/ai_inference_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/translator_providers.dart';

part 'lesson_controller.g.dart';

@riverpod
class LessonController extends _$LessonController {
  @override
  Future<LessonState?> build() async {
    return null;
  }

  Future<void> loadLesson(String lessonId) async {
    state = const AsyncLoading<LessonState?>();
    final LoadLesson useCase = ref.read(loadLessonUseCaseProvider);
    final Either<Failure, Lesson> result = await useCase(lessonId);
    state = result.fold(
      (Failure failure) => AsyncError<LessonState?>(
        _failureToException(failure),
        StackTrace.current,
      ),
      (Lesson lesson) {
        final LessonProgress? saved = ref
            .read(lessonProgressNotifierProvider.notifier)
            .forLesson(lessonId);
        final int startIndex =
            (saved != null && !saved.completed && lesson.steps.isNotEmpty)
            ? saved.currentStepIndex.clamp(0, lesson.steps.length - 1)
            : 0;
        return AsyncData<LessonState?>(
          LessonState(
            lesson: lesson,
            currentStepIndex: startIndex,
            attemptStatus: AttemptStatus.idle,
            buttyMessage: _introFor(lesson.steps[startIndex]),
            completed: false,
          ),
        );
      },
    );
  }

  /// Marks the state as [AttemptStatus.checking] immediately so the UI can
  /// show a loading indicator while async work (e.g. YOLO sketch inference)
  /// runs in the background.
  void startChecking() {
    final LessonState? current = state.value;
    if (current == null || current.completed) return;
    if (current.attemptStatus == AttemptStatus.checking) return;
    state = AsyncData<LessonState?>(
      current.copyWith(
        attemptStatus: AttemptStatus.checking,
        buttyMessage: 'Analyzing your strokes...',
      ),
    );
  }

  /// Validates a YOLO-detected [label] for [LessonMode.draw] steps.
  ///
  /// Compares [label] (trimmed, lowercased) against [LessonStep.expected].
  void submitDetection(String label) {
    final LessonState? current = state.value;
    if (current == null || current.completed) return;
    final LessonStep step = current.currentStep;
    if (step.mode != LessonMode.draw) return;
    // YOLO joins multi-value class names with '_' (e.g. "e_i" for e/i).
    // Split and check whether any part matches the step's expected values.
    final List<String> parts = label
        .trim()
        .toLowerCase()
        .split('_')
        .map((String p) => p.trim())
        .where((String p) => p.isNotEmpty)
        .toList();
    final bool isCorrect = parts.any((String p) => step.expected.contains(p));
    final bool isFirstAttempt =
        current.attemptStatus == AttemptStatus.idle ||
        current.attemptStatus == AttemptStatus.checking;
    state = AsyncData<LessonState?>(
      current.copyWith(
        attemptStatus: isCorrect ? AttemptStatus.correct : AttemptStatus.retry,
        buttyMessage: isCorrect
            ? (step.successFeedback ?? 'Correct!')
            : (step.hint ?? 'Not quite — keep practicing.'),
        firstAttemptPasses: isCorrect && isFirstAttempt
            ? current.firstAttemptPasses + 1
            : current.firstAttemptPasses,
      ),
    );
  }

  /// Submits a drawing attempt. Always marks correct so the lesson flow
  /// continues; streams Gemma image feedback into [buttyMessage].
  ///
  /// [imageBytes] is a PNG snapshot of the canvas. When provided the image
  /// is sent to the model for visual evaluation. Falls back to a text-only
  /// prompt when null (e.g. canvas capture failed).
  Future<void> submitDraw(
    List<List<Offset>> strokes, {
    Uint8List? imageBytes,
  }) async {
    final LessonState? current = state.value;
    if (current == null || current.completed) return;
    // Note: do NOT guard on AttemptStatus.checking here — the draw path
    // calls startChecking() before this, so the state is already checking.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final LessonStep step = current.currentStep;

    try {
      final Stream<String> responseStream;
      if (imageBytes != null) {
        final AiInferenceRepository repo = ref.read(
          aiInferenceRepositoryProvider,
        );
        responseStream = repo.analyzeImage(
          imageBytes,
          prompt: GemmaPrompts.sketchpadEvaluator(step.label),
        );
      } else {
        responseStream = ref
            .read(aiInferenceNotifierProvider.notifier)
            .generateResponse(<ChatMessage>[
              ChatMessage(
                text: 'Evaluate my drawing for ${step.label}',
                isUser: true,
                timestamp: DateTime.now(),
              ),
            ], systemInstruction: GemmaPrompts.sketchpadEvaluator(step.label));
      }

      final StringBuffer buffer = StringBuffer();

      // Update state to correct immediately so they can proceed,
      // but stream the feedback from Gemma into buttyMessage.
      state = AsyncData<LessonState?>(
        current.copyWith(
          attemptStatus: AttemptStatus.correct,
          buttyMessage: '',
        ),
      );

      await for (final String chunk in responseStream) {
        buffer.write(chunk);
        final ({String think, String answer}) parsed =
            GemmaPrompts.parseThinkBlock(buffer.toString());
        // While the think block is still open, show nothing.
        final String visible = parsed.answer;
        final LessonState? updated = state.value;
        if (updated != null &&
            updated.currentStepIndex == current.currentStepIndex) {
          state = AsyncData<LessonState?>(
            updated.copyWith(buttyMessage: visible),
          );
        }
      }
    } catch (e) {
      final LessonState? updated = state.value;
      if (updated != null) {
        state = AsyncData<LessonState?>(
          updated.copyWith(
            attemptStatus: AttemptStatus.correct,
            buttyMessage: step.successFeedback ?? 'Correct.',
          ),
        );
      }
    }
  }

  /// Validates a typed answer for [LessonMode.freeInput] steps.
  Future<void> submitText(String value) async {
    final LessonState? current = state.value;
    if (current == null || current.completed) return;
    final LessonStep step = current.currentStep;
    if (step.mode != LessonMode.freeInput) return;

    final String normalized = value.trim().toLowerCase();
    final bool isCorrect = step.expected.contains(normalized);
    final bool isFirstAttempt = current.attemptStatus == AttemptStatus.idle;

    state = AsyncData<LessonState?>(
      current.copyWith(
        attemptStatus: isCorrect ? AttemptStatus.correct : AttemptStatus.retry,
        buttyMessage: isCorrect
            ? (step.successFeedback ?? 'Correct.')
            : (step.hint ?? 'Not quite — try again.'),
        firstAttemptPasses: isCorrect && isFirstAttempt
            ? current.firstAttemptPasses + 1
            : current.firstAttemptPasses,
      ),
    );
  }

  /// Used by [LessonMode.reference] steps: user taps "Got it" to continue.
  void acknowledge() {
    final LessonState? current = state.value;
    if (current == null) return;
    // Reference steps are always first-attempt (no wrong answer possible).
    state = AsyncData<LessonState?>(
      current.copyWith(
        attemptStatus: AttemptStatus.correct,
        firstAttemptPasses: current.firstAttemptPasses + 1,
      ),
    );
  }

  /// Advances to the next step or marks the lesson complete.
  void next() {
    final LessonState? current = state.value;
    if (current == null) return;
    final int nextIndex = current.currentStepIndex + 1;
    if (nextIndex >= current.lesson.steps.length) {
      final LessonState completed = current.copyWith(
        completed: true,
        attemptStatus: AttemptStatus.idle,
        buttyMessage: 'Lesson complete. Magaling!',
      );
      state = AsyncData<LessonState?>(completed);
      unawaited(
        ref
            .read(lessonProgressNotifierProvider.notifier)
            .saveProgress(
              LessonProgress(
                lessonId: completed.lesson.id,
                currentStepIndex: completed.lesson.steps.length,
                totalSteps: completed.lesson.steps.length,
                completed: true,
                score: completed.score,
                lastModified: DateTime.now(),
                completedAt: DateTime.now(),
              ),
            ),
      );
      unawaited(_saveLessonProgress(completed));
      return;
    }
    final LessonStep nextStep = current.lesson.steps[nextIndex];
    state = AsyncData<LessonState?>(
      current.copyWith(
        currentStepIndex: nextIndex,
        attemptStatus: AttemptStatus.idle,
        buttyMessage: _introFor(nextStep),
      ),
    );
    unawaited(
      ref
          .read(lessonProgressNotifierProvider.notifier)
          .saveProgress(
            LessonProgress(
              lessonId: current.lesson.id,
              currentStepIndex: nextIndex,
              totalSteps: current.lesson.steps.length,
              completed: false,
              score: 0,
              lastModified: DateTime.now(),
            ),
          ),
    );
  }

  void resetAttempt() {
    final LessonState? current = state.value;
    if (current == null) return;
    state = AsyncData<LessonState?>(
      current.copyWith(
        attemptStatus: AttemptStatus.idle,
        buttyMessage: _introFor(current.currentStep),
      ),
    );
  }

  void restart() {
    final LessonState? current = state.value;
    if (current == null) return;
    unawaited(
      ref
          .read(lessonProgressNotifierProvider.notifier)
          .saveProgress(
            LessonProgress(
              lessonId: current.lesson.id,
              currentStepIndex: 0,
              totalSteps: current.lesson.steps.length,
              completed: false,
              score: 0,
              lastModified: DateTime.now(),
            ),
          ),
    );
    state = AsyncData<LessonState?>(
      LessonState(
        lesson: current.lesson,
        currentStepIndex: 0,
        attemptStatus: AttemptStatus.idle,
        buttyMessage: _introFor(current.lesson.steps.first),
        completed: false,
      ),
    );
  }

  Future<void> _saveLessonProgress(LessonState completed) async {
    try {
      await ref
          .read(profileManagementRepositoryProvider)
          .saveLessonProgress(
            lessonId: completed.lesson.id,
            completed: true,
            score: completed.score,
          );
      debugPrint(
        '[LessonController] progress saved: ${completed.lesson.id} score=${completed.score}',
      );
    } catch (e) {
      debugPrint('[LessonController] progress save failed (non-fatal): $e');
    }
  }

  static String _introFor(LessonStep step) {
    return step.intro ?? step.prompt ?? step.narration ?? step.label;
  }

  static Exception _failureToException(Failure failure) {
    return failure.when(
      network: (String message) => Exception(message),
      invalidCredentials: () => Exception('Invalid credentials.'),
      userNotFound: () => Exception('User not found.'),
      emailAlreadyInUse: () => Exception('Email already in use.'),
      weakPassword: () => Exception('Weak password.'),
      tooManyRequests: () => Exception('Too many requests.'),
      sessionExpired: () => Exception('Session expired.'),
      passwordResetEmailSent: () => Exception('Password reset email sent.'),
      unknown: (String message) => Exception(message),
    );
  }
}
