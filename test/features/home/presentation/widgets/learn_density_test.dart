import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kudlit_ph/features/home/presentation/screens/learn_home_body.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/learn_home/lesson_card.dart';
import 'package:kudlit_ph/features/learning/domain/entities/lesson_progress.dart';

void main() {
  testWidgets('learn quick actions use compact labels on narrow phones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 593));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LearnHomeBody(
              onStartLesson: (_) {},
              onChatWithButty: () {},
              onOpenGallery: () {},
              onStartQuiz: () {},
              bottomPad: 112,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Glyphs'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('All Glyphs'), findsNothing);
    expect(find.text('Quick Quiz'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('locked lesson card stays readable without global opacity fade', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LearnHomeBody(
              onStartLesson: (_) {},
              onChatWithButty: () {},
              onOpenGallery: () {},
              onStartQuiz: () {},
              bottomPad: 112,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Core Consonants'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Core Consonants'),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
    final Rect lockedButton = tester.getRect(
      find.widgetWithText(FilledButton, 'Locked').first,
    );

    expect(lockedButton.right, lessThanOrEqualTo(300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('lesson card keeps compact progress action on narrow phones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 593));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 288,
                child: LessonCard(
                  index: 1,
                  title: 'Baybayin Vowels',
                  subtitle: 'Practice the three starting sounds.',
                  glyphCount: 3,
                  estimatedLength: '5 min',
                  items: const <(String, String)>[('a', 'A')],
                  progress: LessonProgress(
                    lessonId: 'vowels-01',
                    currentStepIndex: 1,
                    totalSteps: 4,
                    completed: false,
                    score: 0,
                    lastModified: DateTime(2026),
                  ),
                  onStart: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Step 2 / 4'), findsOneWidget);
    final Rect action = tester.getRect(
      find.widgetWithText(FilledButton, 'Resume'),
    );
    expect(action.height, lessThanOrEqualTo(48));
    expect(action.height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });
}
