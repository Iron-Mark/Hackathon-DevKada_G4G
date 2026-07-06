import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kudlit_ph/features/home/presentation/screens/scan_tab.dart';
import 'package:kudlit_ph/features/scanner/domain/entities/baybayin_detection.dart';

void main() {
  const List<BaybayinDetection> detections = <BaybayinDetection>[
    BaybayinDetection(
      label: 'ka',
      confidence: 0.94,
      left: 0.1,
      top: 0.2,
      width: 0.12,
      height: 0.18,
    ),
    BaybayinDetection(
      label: 'ba',
      confidence: 0.9,
      left: 0.3,
      top: 0.2,
      width: 0.12,
      height: 0.18,
    ),
  ];

  Future<void> pumpPanel(
    WidgetTester tester, {
    required Size viewport,
    required double width,
  }) async {
    await tester.binding.setSurfaceSize(viewport);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Center(
                child: SizedBox(
                  width: width,
                  child: ScannerResultPanel(
                    detections: detections,
                    onDismiss: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('scanner result actions stay reachable on narrow portrait', (
    tester,
  ) async {
    await pumpPanel(tester, viewport: const Size(320, 593), width: 288);

    expect(find.byTooltip('Copy reading'), findsOneWidget);
    expect(find.byTooltip('Share reading'), findsOneWidget);
    expect(find.byTooltip('Save reading'), findsOneWidget);
    expect(find.byTooltip('Close result'), findsOneWidget);
    for (final String tooltip in <String>[
      'Copy reading',
      'Share reading',
      'Save reading',
      'Close result',
    ]) {
      final Rect action = tester.getRect(find.byTooltip(tooltip));
      expect(action.height, greaterThanOrEqualTo(44));
      expect(action.width, greaterThanOrEqualTo(44));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('scanner result panel fits compact landscape', (tester) async {
    await pumpPanel(tester, viewport: const Size(593, 360), width: 520);

    expect(find.byType(ScannerResultPanel), findsOneWidget);
    expect(find.byTooltip('Copy reading'), findsOneWidget);
    expect(find.byTooltip('Close result'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
