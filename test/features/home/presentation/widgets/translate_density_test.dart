import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kudlit_ph/features/home/presentation/providers/translate_page_controller.dart';
import 'package:kudlit_ph/features/home/presentation/providers/translate_text_controller.dart';
import 'package:kudlit_ph/features/home/presentation/screens/translate_screen.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/app_header/app_header.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/translate/filled_output.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/translate/output_actions.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/translate/translate_header.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/translate/sketchpad_target_glyph_button.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/translate/translate_text_mode_panel.dart';

void main() {
  bool hasOverlap(Rect a, Rect b) => a.overlaps(b) && !a.intersect(b).isEmpty;

  testWidgets('translate header fits narrow phone without overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 593));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranslateHeader(
            workspaceMode: TranslateWorkspaceMode.text,
            onWorkspaceModeChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Text'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('app header stays responsive on narrow widths', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 72));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AppHeader(showTranslateControls: true)),
        ),
      ),
    );

    expect(find.text('Translate'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('app header remains stable at very narrow widths', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(300, 72));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AppHeader(showTranslateControls: true)),
        ),
      ),
    );

    expect(find.text('Translate'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('app header uses compact source labels at ultra-narrow widths', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(280, 72));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AppHeader(showTranslateControls: true)),
        ),
      ),
    );

    expect(find.text('Translate'), findsOneWidget);
    expect(find.text('On'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('app header stays usable on narrow width with large text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(280, 72));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.5)),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const Scaffold(body: AppHeader(showTranslateControls: true)),
        ),
      ),
    );

    expect(find.text('Translate'), findsOneWidget);
    expect(find.text('On'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('translate header keeps spacing on tablet widths', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TranslateHeader(
            workspaceMode: TranslateWorkspaceMode.text,
            onWorkspaceModeChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Text'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('app header keeps translate controls at tablet widths', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 72));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AppHeader(showTranslateControls: true)),
        ),
      ),
    );

    expect(find.text('Translate'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'app header keeps translate controls and spacing on wide breakpoints',
    (tester) async {
      final List<double> widths = <double>[768, 1024, 1366, 1920];

      for (final double width in widths) {
        await tester.binding.setSurfaceSize(Size(width, 72));
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: AppHeader(showTranslateControls: true)),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Translate'), findsOneWidget);
        expect(find.text('Online'), findsOneWidget);
        expect(find.text('Offline'), findsOneWidget);

        final Rect headerRect = tester.getRect(find.byType(AppHeader));
        final Rect titleRect = tester.getRect(find.text('Translate'));
        final Rect onlineRect = tester.getRect(find.text('Online'));
        final Rect offlineRect = tester.getRect(find.text('Offline'));

        expect(headerRect.left, equals(0));
        expect(headerRect.right, lessThanOrEqualTo(width));
        expect(titleRect.left, greaterThanOrEqualTo(0));
        expect(onlineRect.left, greaterThanOrEqualTo(titleRect.right));
        expect(offlineRect.left, greaterThanOrEqualTo(onlineRect.right));
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'translate mode tabs stay compact and non-overlapping on wide breakpoints',
    (tester) async {
      final List<double> widths = <double>[768, 1024, 1366, 1920];

      for (final double width in widths) {
        await tester.binding.setSurfaceSize(Size(width, 120));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TranslateHeader(
                workspaceMode: TranslateWorkspaceMode.text,
                onWorkspaceModeChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pump();

        final Finder textFinder = find.text('Text');
        final Finder sketchFinder = find.text('Sketchpad');
        expect(textFinder, findsOneWidget);
        expect(sketchFinder, findsOneWidget);

        final Rect textRect = tester.getRect(textFinder);
        final Rect sketchRect = tester.getRect(sketchFinder);

        expect(textRect.left, greaterThanOrEqualTo(0), reason: '$width');
        expect(sketchRect.right, lessThanOrEqualTo(width), reason: '$width');
        expect(hasOverlap(textRect, sketchRect), isFalse, reason: '$width');
        expect(textRect.top, equals(sketchRect.top), reason: '$width');
        expect(tester.takeException(), isNull, reason: '$width');
      }
    },
  );

  testWidgets('app header keeps translate controls at wide tablet widths', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(768, 72));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AppHeader(showTranslateControls: true)),
        ),
      ),
    );

    expect(find.text('Translate'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Kudlit'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('app header keeps translate controls at desktop widths', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 72));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AppHeader(showTranslateControls: true)),
        ),
      ),
    );

    expect(find.text('Translate'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('app header hides source switch on non-translate views', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 72));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: AppHeader(showTranslateControls: false)),
        ),
      ),
    );

    expect(find.text('Kudlit'), findsOneWidget);
    expect(find.text('Online'), findsNothing);
    expect(find.text('Offline'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long translate output stays inside a narrow viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 593));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: 288,
                  child: FilledOutput(
                    baybayin: 'ᜃᜓᜇ᜔ᜎᜒᜆ᜔ ᜋᜑᜊᜅ᜔ ᜑᜎᜒᜋ᜔ᜊᜏ ᜉᜇᜒᜈ᜔ ᜉᜇᜒᜈ᜔',
                    latin:
                        'Kudlit long translation preview that should wrap cleanly.',
                    copyLabel: 'Copy',
                    shareLabel: 'Share',
                    onCopy: () {},
                    onShare: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Kudlit long translation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('output actions wrap on compact mobile widths', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 593));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(child: SizedBox(width: 180, child: OutputActions())),
          ),
        ),
      ),
    );

    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('translate text mode keeps input actions usable in landscape', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(593, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TranslateTextModePanel(
              state: const TranslateTextState.initial().copyWith(
                inputText: 'kumusta',
                baybayinText: 'ᜃᜓᜋᜓᜐ᜔ᜆ',
                latinText: 'kumusta',
              ),
              inputEnabled: true,
              disabledReason: null,
              onDirectionChanged: (_) {},
              onInputChanged: (_) {},
              onExternalInput: (_) {},
              onClear: () {},
              onExplain: () {},
              onCheckInput: () {},
              onCopy: () {},
              onShare: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Explain'), findsOneWidget);
    expect(find.text('Check Input'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('filipino input renders as a taller text area', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TranslateTextModePanel(
              state: const TranslateTextState.initial(),
              inputEnabled: true,
              disabledReason: null,
              onDirectionChanged: (_) {},
              onInputChanged: (_) {},
              onExternalInput: (_) {},
              onClear: () {},
              onExplain: () {},
              onCheckInput: () {},
              onCopy: () {},
              onShare: () {},
            ),
          ),
        ),
      ),
    );

    final Finder filipinoInput = find.byKey(
      const ValueKey<String>('translate-filipino-input'),
    );

    expect(filipinoInput, findsOneWidget);
    expect(tester.getSize(filipinoInput).height, greaterThanOrEqualTo(120));
    expect(tester.takeException(), isNull);
  });

  testWidgets('encoded baybayin reverse input renders as a taller text area', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TranslateTextModePanel(
              state: const TranslateTextState.initial().copyWith(
                latinToBaybayin: false,
              ),
              inputEnabled: true,
              disabledReason: null,
              onDirectionChanged: (_) {},
              onInputChanged: (_) {},
              onExternalInput: (_) {},
              onClear: () {},
              onExplain: () {},
              onCheckInput: () {},
              onCopy: () {},
              onShare: () {},
            ),
          ),
        ),
      ),
    );

    final Finder encodedInput = find.byKey(
      const ValueKey<String>('translate-encoded-baybayin-input'),
    );

    expect(encodedInput, findsOneWidget);
    expect(tester.getSize(encodedInput).height, greaterThanOrEqualTo(120));
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty translate input sits near the prompt on portrait phones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TranslateTextModePanel(
              state: const TranslateTextState.initial(),
              inputEnabled: true,
              disabledReason: null,
              onDirectionChanged: (_) {},
              onInputChanged: (_) {},
              onExternalInput: (_) {},
              onClear: () {},
              onExplain: () {},
              onCheckInput: () {},
              onCopy: () {},
              onShare: () {},
            ),
          ),
        ),
      ),
    );

    final Finder filipinoInput = find.byKey(
      const ValueKey<String>('translate-filipino-input'),
    );

    expect(find.text('Type below to preview Baybayin'), findsOneWidget);
    expect(filipinoInput, findsOneWidget);
    expect(tester.getTopLeft(filipinoInput).dy, lessThan(330));
    expect(tester.takeException(), isNull);
  });

  testWidgets('translate empty states stay close to input on narrow phones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TranslateTextModePanel(
              state: const TranslateTextState.initial(),
              inputEnabled: true,
              disabledReason: null,
              onDirectionChanged: (_) {},
              onInputChanged: (_) {},
              onExternalInput: (_) {},
              onClear: () {},
              onExplain: () {},
              onCheckInput: () {},
              onCopy: () {},
              onShare: () {},
            ),
          ),
        ),
      ),
    );

    final Rect emptyState = tester.getRect(
      find.text('Type below to preview Baybayin'),
    );
    final Rect input = tester.getRect(find.byType(TextField).first);

    expect(input.top - emptyState.bottom, lessThan(180));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'translate screen keeps input visible in landscape route height',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: TranslateScreen())),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('translate-filipino-input')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'translate screen does not overflow with portrait keyboard inset',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      tester.view.viewInsets = const FakeViewPadding(bottom: 420);
      addTearDown(() {
        tester.view.resetViewInsets();
        tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: TranslateScreen())),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('translate-filipino-input')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'translate input keeps focus when portrait keyboard inset appears',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      double keyboardInset = 0;
      late StateSetter setHarnessState;
      addTearDown(() {
        tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                setHarnessState = setState;
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: const Size(390, 844),
                    viewInsets: EdgeInsets.only(bottom: keyboardInset),
                  ),
                  child: const Scaffold(body: TranslateScreen()),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      final Finder input = find.byKey(
        const ValueKey<String>('translate-filipino-input'),
      );
      await tester.tap(input);
      await tester.pump();

      TextField textField = tester.widget<TextField>(input);
      expect(textField.maxLines, equals(7));

      EditableText editable = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      expect(editable.focusNode.hasFocus, isTrue);

      setHarnessState(() => keyboardInset = 420);
      await tester.pump();

      textField = tester.widget<TextField>(input);
      expect(textField.maxLines, equals(7));
      editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'translate screen does not overflow with landscape keyboard inset',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      addTearDown(() {
        tester.view.resetViewInsets();
        tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: TranslateScreen())),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('translate-filipino-input')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'translate screen does not overflow when keyboard is open and actions appear',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      tester.view.viewInsets = const FakeViewPadding(bottom: 420);
      addTearDown(() {
        tester.view.resetViewInsets();
        tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: TranslateScreen())),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.enterText(
        find.byKey(const ValueKey<String>('translate-filipino-input')),
        'kumusta',
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      expect(find.text('Explain'), findsOneWidget);
      expect(find.text('Check Input'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'home translate layout does not overflow when keyboard opens actions',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      addTearDown(() {
        tester.view.resetViewInsets();
        tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            builder: _largeTextBuilder,
            home: Scaffold(
              body: Column(
                children: <Widget>[
                  AppHeader(),
                  Expanded(child: TranslateScreen()),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.enterText(
        find.byKey(const ValueKey<String>('translate-filipino-input')),
        'kumusta',
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      expect(find.text('Explain'), findsOneWidget);
      expect(find.text('Check Input'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('translate text mode surfaces input cleanup helper messages', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: TranslateTextModePanel(
              state: const TranslateTextState(
                inputText: 'Kumusta, 123!',
                latinToBaybayin: true,
                baybayinText: 'kumusta',
                latinText: 'Kumusta, 123!',
                feedbackMessages: <String>[
                  'Removed punctuation from input.',
                  'Numbers were ignored.',
                  'Transliteration may be approximate for modern spelling.',
                ],
                cleanupPreview: 'kumusta',
                aiBusy: false,
                aiResponse: '',
              ),
              inputEnabled: true,
              disabledReason: null,
              onDirectionChanged: (_) {},
              onInputChanged: (_) {},
              onExternalInput: (_) {},
              onClear: () {},
              onExplain: () {},
              onCheckInput: () {},
              onCopy: () {},
              onShare: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Removed punctuation from input.'), findsOneWidget);
    expect(find.text('Numbers were ignored.'), findsOneWidget);
    expect(
      find.text('Transliteration may be approximate for modern spelling.'),
      findsOneWidget,
    );
    expect(find.text('Used as: kumusta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('translate text mode previews cleaned input while typing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: TranslateScreen())),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('translate-filipino-input')),
      'Kumusta, 123!',
    );
    await tester.pump();

    expect(find.text('Used as: kumusta'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byKey(const ValueKey<String>('translate-filipino-input')),
      'Kumusta',
    );
    await tester.pump();

    expect(find.text('Used as: kumusta'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reverse mode explains encoded input instead of Unicode glyphs', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: TranslateScreen())),
      ),
    );

    await tester.tap(find.text('Baybayin → Filipino'));
    await tester.pump();

    expect(find.text('Examples:'), findsOneWidget);
    expect(find.text('ka'), findsOneWidget);
    expect(find.text('ki'), findsOneWidget);
    expect(find.text('ku'), findsOneWidget);
    expect(find.text('k+'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('translate-encoded-baybayin-input')),
      'ᜊ',
    );
    await tester.pump();

    expect(
      find.text('Type encoded Baybayin like ka, ki, or k+...'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Pasted Baybayin glyphs are not parsed yet. Use encoded text like ka, ki, or k+.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reverse mode example chips fill encoded input', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: TranslateScreen())),
      ),
    );

    await tester.tap(find.text('Baybayin → Filipino'));
    await tester.pump();
    await tester.tap(find.text('k+'));
    await tester.pump();

    final TextField field = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('translate-encoded-baybayin-input')),
    );
    expect(field.controller?.text, 'k+');
    expect(find.text('Used as:'), findsNothing);
    expect(find.text('Removed punctuation from input.'), findsNothing);
    expect(
      find.text('Some unsupported characters were ignored.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'sketchpad target uses a tap picker with no keyboard surface',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: TranslateScreen())),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Sketchpad'));
      await tester.pump();

      // The keyboard-driven re-mount loop was rooted in the target
      // TextField. The picker must not introduce any editable surface.
      expect(find.byType(EditableText), findsNothing);
      expect(find.byType(SketchpadTargetGlyphButton), findsOneWidget);
      expect(find.text('Target glyph'), findsOneWidget);

      await tester.tap(find.byType(SketchpadTargetGlyphButton));
      await tester.pumpAndSettle();
      expect(find.text('Choose target glyph'), findsOneWidget);

      await tester.tap(find.widgetWithText(InkWell, 'ba').last);
      await tester.pumpAndSettle();

      expect(find.text('Choose target glyph'), findsNothing);
      expect(find.byType(EditableText), findsNothing);
      expect(
        tester
            .widget<SketchpadTargetGlyphButton>(
              find.byType(SketchpadTargetGlyphButton),
            )
            .currentLabel,
        'ba',
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Widget _largeTextBuilder(BuildContext context, Widget? child) {
  return MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: const TextScaler.linear(1.35)),
    child: child ?? const SizedBox.shrink(),
  );
}
