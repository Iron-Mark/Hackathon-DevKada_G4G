import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/butty_chat/chat_input_bar.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/butty_chat/suggested_questions_row.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/butty_chat/typing_bubble.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/home_tool_card.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/lesson_preview_card.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/translate/output_action_pill.dart';

void main() {
  testWidgets('Butty suggestion chips keep 44px tap targets', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 593));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SuggestedQuestionsRow(onTap: (_) {})),
      ),
    );

    final Rect firstChip = tester.getRect(find.byType(InkWell).first);

    expect(firstChip.height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Butty suggestion row clears the floating tab control', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 593));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SuggestedQuestionsRow(onTap: (_) {})),
      ),
    );

    final Rect scrollWindow = tester.getRect(find.byType(ListView));

    expect(scrollWindow.right, lessThanOrEqualTo(224));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Butty suggestion row leaves shadow clearance on 390px phones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SuggestedQuestionsRow(onTap: (_) {})),
      ),
    );

    final Rect scrollWindow = tester.getRect(find.byType(ListView));

    expect(scrollWindow.right, lessThanOrEqualTo(282));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Butty chat send action keeps 44px tap target', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 593));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final TextEditingController controller = TextEditingController(text: 'hi');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ChatInputBar(
              controller: controller,
              responding: false,
              enabled: true,
              onSend: () {},
            ),
          ),
        ),
      ),
    );

    final Rect sendAction = tester.getRect(find.byType(InkWell).last);

    expect(sendAction.width, greaterThanOrEqualTo(44));
    expect(sendAction.height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Butty loading bubble stays compact on narrow phones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 593));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: TypingBubble(animationsEnabled: false)),
      ),
    );

    final Rect bubble = tester.getRect(find.byType(TypingBubble));

    expect(bubble.width, lessThanOrEqualTo(180));
    expect(bubble.height, lessThanOrEqualTo(64));
    expect(tester.takeException(), isNull);
  });

  testWidgets('translate output action pill keeps 44px tap target', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 593));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: OutputActionPill(
              icon: Icons.copy_rounded,
              label: 'Copy',
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    final Rect pill = tester.getRect(find.byType(OutputActionPill));

    expect(pill.height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets('home tool card uses material tap behavior and semantics', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(320, 593));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 260,
              child: HomeToolCard(
                icon: Icons.document_scanner_outlined,
                title: 'Scanner',
                description: 'Read Baybayin from a camera image.',
                accentColor: Colors.blue,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Scanner. Read Baybayin from a camera image.'),
      findsOneWidget,
    );
    expect(find.byType(InkWell), findsOneWidget);

    final Rect tapTarget = tester.getRect(find.byType(InkWell));
    expect(tapTarget.height, greaterThanOrEqualTo(44));
    expect(tapTarget.width, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('lesson preview card has a semantic material tap target', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(320, 593));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 160,
              child: LessonPreviewCard(
                title: 'Baybayin basics',
                description: 'Practice familiar letters.',
                imageAsset: 'assets/brand/baybayin.vowels.webp',
                tag: 'New',
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Baybayin basics. Practice familiar letters.'),
      findsOneWidget,
    );
    expect(find.byType(InkWell), findsOneWidget);

    final Rect tapTarget = tester.getRect(find.byType(InkWell));
    expect(tapTarget.height, greaterThanOrEqualTo(44));
    expect(tapTarget.width, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
