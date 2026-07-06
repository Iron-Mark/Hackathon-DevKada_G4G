import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kudlit_ph/features/scanner/domain/entities/baybayin_detection.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/scan_tab_controller.dart';
import 'package:kudlit_ph/features/scanner/presentation/providers/scanner_provider.dart';
import 'package:kudlit_ph/features/home/presentation/screens/scan_tab.dart';

class _FixedScanTabController extends ScanTabController {
  _FixedScanTabController(this._state);

  final ScanTabState _state;

  @override
  ScanTabState build() => _state;
}

class _FixedScannerNotifier extends ScannerNotifier {
  _FixedScannerNotifier(this._state);

  final List<BaybayinDetection> _state;

  @override
  List<BaybayinDetection> build() => _state;
}

class _ViewportCase {
  const _ViewportCase(this.name, this.size, {this.strictTinyLandscape = false});

  final String name;
  final Size size;
  final bool strictTinyLandscape;
}

void main() {
  const List<_ViewportCase> cases = <_ViewportCase>[
    _ViewportCase('360x740', Size(360, 740)),
    _ViewportCase('390x844', Size(390, 844)),
    _ViewportCase('430x932', Size(430, 932)),
    _ViewportCase('844x390', Size(844, 390)),
    _ViewportCase('1024x768', Size(1024, 768)),
    _ViewportCase('340x260', Size(340, 260), strictTinyLandscape: true),
    _ViewportCase('320x240', Size(320, 240), strictTinyLandscape: true),
  ];

  Future<void> pumpScanTab(WidgetTester tester, Size viewport) async {
    await tester.binding.setSurfaceSize(viewport);

    const List<BaybayinDetection> fixedDetections = <BaybayinDetection>[
      BaybayinDetection(
        label: 'ka',
        confidence: 0.95,
        left: 0.12,
        top: 0.2,
        width: 0.21,
        height: 0.22,
      ),
      BaybayinDetection(
        label: 'la',
        confidence: 0.91,
        left: 0.42,
        top: 0.21,
        width: 0.21,
        height: 0.22,
      ),
    ];

    const String noticeMessage =
        'Camera is currently unavailable while the status '
        'stream refreshes. Keep the app in the foreground and retry '
        'with clear lighting.';

    final ScanTabState state = ScanTabState(
      resultVisible: false,
      flashOn: false,
      selectedImageBytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO2v9xAAAAAASUVORK5CYII=',
      ),
      capturedFrameBytes: null,
      isLoadingImage: false,
      detectionsFrozen: false,
      snapshot: fixedDetections,
      aggregatedWinner: 'ka-la',
      scanNotice: const ScanNotice(
        title: 'Camera temporarily unavailable for this session',
        message: noticeMessage,
        kind: ScanNoticeKind.warning,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          scanTabControllerProvider.overrideWith(
            () => _FixedScanTabController(state),
          ),
          scannerNotifierProvider.overrideWith(
            () => _FixedScannerNotifier(fixedDetections),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ScanTab())),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool hasOverlap(Rect a, Rect b) => a.overlaps(b) && !a.intersect(b).isEmpty;

  testWidgets('scan tab layout stays usable across responsive matrix', (
    WidgetTester tester,
  ) async {
    for (final _ViewportCase viewportCase in cases) {
      await pumpScanTab(tester, viewportCase.size);

      final Size viewport = viewportCase.size;
      final Rect utilityRect = tester.getRect(
        find.byKey(const ValueKey('scan-utility-bar')),
      );
      final Rect statusRect = tester.getRect(
        find.byKey(const ValueKey('scan-status-chip')),
      );
      final Rect controlsRect = tester.getRect(
        find.byKey(const ValueKey('scan-controls')),
      );
      final Rect noticeRect = tester.getRect(
        find.byKey(const ValueKey('scan-notice-panel')),
      );
      final Rect shutterRect = tester.getRect(find.byTooltip('Retake'));
      final Finder rotateFinder = find.byTooltip('Switch camera');
      final bool hasRotate = rotateFinder.evaluate().isNotEmpty;
      final Rect rotateRect = hasRotate
          ? tester.getRect(rotateFinder)
          : Rect.zero;
      final Rect galleryRect = tester.getRect(find.byTooltip('Open Gallery'));
      final Rect titleRect = tester.getRect(
        find.text('Camera temporarily unavailable for this session'),
      );
      final Rect messageRect = tester.getRect(
        find.text(
          'Camera is currently unavailable while the status stream refreshes. Keep the app in the foreground and retry with clear lighting.',
        ),
      );
      expect(utilityRect.left, greaterThan(0), reason: viewportCase.name);
      expect(
        utilityRect.top,
        greaterThanOrEqualTo(0),
        reason: viewportCase.name,
      );
      expect(
        utilityRect.right,
        lessThanOrEqualTo(viewport.width),
        reason: viewportCase.name,
      );

      expect(
        statusRect.top,
        greaterThanOrEqualTo(0),
        reason: viewportCase.name,
      );
      expect(
        statusRect.right,
        lessThanOrEqualTo(viewport.width),
        reason: viewportCase.name,
      );
      expect(
        statusRect.bottom,
        lessThanOrEqualTo(viewport.height),
        reason: viewportCase.name,
      );

      expect(
        hasOverlap(utilityRect, statusRect),
        isFalse,
        reason: viewportCase.name,
      );
      expect(
        hasOverlap(utilityRect, controlsRect),
        isFalse,
        reason: viewportCase.name,
      );
      expect(
        hasOverlap(statusRect, controlsRect),
        isFalse,
        reason: viewportCase.name,
      );
      expect(
        hasOverlap(utilityRect, noticeRect),
        isFalse,
        reason: viewportCase.name,
      );
      expect(
        hasOverlap(noticeRect, controlsRect),
        isFalse,
        reason: viewportCase.name,
      );

      expect(
        noticeRect.left,
        greaterThanOrEqualTo(0),
        reason: viewportCase.name,
      );
      expect(
        noticeRect.right,
        lessThanOrEqualTo(viewport.width),
        reason: viewportCase.name,
      );
      expect(
        noticeRect.bottom,
        lessThanOrEqualTo(controlsRect.top),
        reason: viewportCase.name,
      );
      if (!viewportCase.strictTinyLandscape) {
        expect(
          noticeRect.top,
          greaterThanOrEqualTo(0),
          reason: viewportCase.name,
        );
      }
      expect(
        noticeRect.bottom,
        lessThanOrEqualTo(viewport.height),
        reason: viewportCase.name,
      );

      expect(
        shutterRect.height,
        greaterThanOrEqualTo(58),
        reason: viewportCase.name,
      );
      expect(
        hasRotate ? rotateRect.height : 0,
        hasRotate ? greaterThanOrEqualTo(48) : greaterThanOrEqualTo(0),
        reason: viewportCase.name,
      );
      expect(
        rotateRect.width,
        hasRotate ? greaterThanOrEqualTo(48) : greaterThanOrEqualTo(0),
        reason: viewportCase.name,
      );
      expect(
        galleryRect.height,
        greaterThanOrEqualTo(48),
        reason: viewportCase.name,
      );
      expect(
        galleryRect.width,
        greaterThanOrEqualTo(48),
        reason: viewportCase.name,
      );

      expect(
        shutterRect.right,
        lessThanOrEqualTo(viewport.width),
        reason: viewportCase.name,
      );
      expect(
        shutterRect.left,
        greaterThanOrEqualTo(0),
        reason: viewportCase.name,
      );
      expect(
        shutterRect.width,
        greaterThanOrEqualTo(48),
        reason: viewportCase.name,
      );

      expect(
        titleRect.left,
        greaterThanOrEqualTo(0),
        reason: viewportCase.name,
      );
      expect(
        titleRect.right,
        lessThanOrEqualTo(viewport.width),
        reason: viewportCase.name,
      );
      expect(titleRect.top, greaterThanOrEqualTo(0), reason: viewportCase.name);
      expect(
        titleRect.bottom,
        lessThanOrEqualTo(viewport.height),
        reason: viewportCase.name,
      );
      expect(
        messageRect.left,
        greaterThanOrEqualTo(0),
        reason: viewportCase.name,
      );
      expect(
        messageRect.right,
        lessThanOrEqualTo(viewport.width),
        reason: viewportCase.name,
      );
      expect(
        messageRect.top,
        greaterThanOrEqualTo(0),
        reason: viewportCase.name,
      );
      expect(
        messageRect.bottom,
        lessThanOrEqualTo(viewport.height),
        reason: viewportCase.name,
      );

      if (viewportCase.strictTinyLandscape) {
        expect(
          controlsRect.height,
          greaterThanOrEqualTo(72),
          reason: viewportCase.name,
        );
        expect(
          utilityRect.left,
          greaterThanOrEqualTo(4),
          reason: viewportCase.name,
        );
        expect(
          utilityRect.right,
          lessThanOrEqualTo(viewport.width - 4),
          reason: viewportCase.name,
        );
      }

      expect(
        controlsRect.bottom,
        lessThanOrEqualTo(viewport.height),
        reason: viewportCase.name,
      );
      expect(
        controlsRect.left,
        greaterThanOrEqualTo(0),
        reason: viewportCase.name,
      );
      expect(
        controlsRect.right,
        lessThanOrEqualTo(viewport.width),
        reason: viewportCase.name,
      );

      expect(
        find.text('Camera temporarily unavailable for this session'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: viewportCase.name);
    }
  });
}
