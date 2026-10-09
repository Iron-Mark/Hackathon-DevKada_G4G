import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kudlit_ph/core/utils/baybayify.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/butty_chat/baybayin_chat_renderer.dart';

const TextStyle _base = TextStyle(fontSize: 13.5, height: 1.5);

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SizedBox(width: 300, child: child)),
);

void main() {
  group('BaybayinChatRenderer — plain markdown', () {
    testWidgets('renders text without tags as markdown', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BaybayinChatRenderer(text: 'Hello **world**', baseStyle: _base),
        ),
      );

      expect(find.textContaining('Hello'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no Baybayin font when no tags present', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BaybayinChatRenderer(
            text: 'No baybayin here',
            baseStyle: _base,
          ),
        ),
      );

      final Iterable<Text> texts = tester.widgetList<Text>(find.byType(Text));
      final bool hasBaybayinFont = texts.any(
        (Text t) => t.style?.fontFamily == 'Baybayin Simple TAWBID',
      );
      expect(hasBaybayinFont, isFalse);
      expect(tester.takeException(), isNull);
    });
  });

  group('BaybayinChatRenderer — baybayin tags', () {
    testWidgets('renders baybayin tag with correct font family', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const BaybayinChatRenderer(
            text: '<baybayin>mahal</baybayin>',
            baseStyle: _base,
          ),
        ),
      );

      final Text baybayinText = tester.widget<Text>(
        find.byWidgetPredicate(
          (Widget w) =>
              w is Text && w.style?.fontFamily == 'Baybayin Simple TAWBID',
        ),
      );
      // baybayifyWord('mahal') → 'mhl+'
      expect(baybayinText.data, baybayifyWord('mahal'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('applies baybayifyWord encoding to tag content', (
      tester,
    ) async {
      const String input = 'salamat';
      await tester.pumpWidget(
        _wrap(
          BaybayinChatRenderer(
            text: '<baybayin>$input</baybayin>',
            baseStyle: _base,
          ),
        ),
      );

      final Text baybayinText = tester.widget<Text>(
        find.byWidgetPredicate(
          (Widget w) =>
              w is Text && w.style?.fontFamily == 'Baybayin Simple TAWBID',
        ),
      );
      expect(baybayinText.data, baybayifyWord(input));
    });

    testWidgets('tag matching is case-insensitive', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BaybayinChatRenderer(
            text: '<BAYBAYIN>anak</BAYBAYIN>',
            baseStyle: _base,
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is Text && w.style?.fontFamily == 'Baybayin Simple TAWBID',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('BaybayinChatRenderer — mixed content', () {
    testWidgets('renders both markdown and baybayin segments', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BaybayinChatRenderer(
            text: 'The word is <baybayin>mahal</baybayin> in Baybayin.',
            baseStyle: _base,
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is Text && w.style?.fontFamily == 'Baybayin Simple TAWBID',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders multiple baybayin tags', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BaybayinChatRenderer(
            text: '<baybayin>mahal</baybayin> and <baybayin>salamat</baybayin>',
            baseStyle: _base,
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is Text && w.style?.fontFamily == 'Baybayin Simple TAWBID',
        ),
        findsNWidgets(2),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('ignores empty baybayin tags', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BaybayinChatRenderer(
            text: 'Before<baybayin>  </baybayin>After',
            baseStyle: _base,
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is Text && w.style?.fontFamily == 'Baybayin Simple TAWBID',
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('BaybayinChatRenderer — font size', () {
    testWidgets('baybayin text is larger than base font', (tester) async {
      const double baseFontSize = 13.5;
      await tester.pumpWidget(
        _wrap(
          const BaybayinChatRenderer(
            text: '<baybayin>ina</baybayin>',
            baseStyle: TextStyle(fontSize: baseFontSize),
          ),
        ),
      );

      final Text baybayinText = tester.widget<Text>(
        find.byWidgetPredicate(
          (Widget w) =>
              w is Text && w.style?.fontFamily == 'Baybayin Simple TAWBID',
        ),
      );
      expect(baybayinText.style!.fontSize, greaterThan(baseFontSize));
    });
  });
}
