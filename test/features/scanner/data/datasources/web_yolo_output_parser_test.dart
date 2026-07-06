import 'package:flutter_test/flutter_test.dart';
import 'package:kudlit_ph/features/scanner/domain/entities/baybayin_detection.dart';
import 'package:kudlit_ph/features/scanner/data/datasources/web_yolo_output_parser.dart';

void main() {
  const WebYoloOutputParser parser = WebYoloOutputParser(
    labels: <String>['ba', 'ka'],
    confidenceThreshold: 0.5,
    iouThreshold: 0.45,
    minBoxArea: 0.001,
    edgeMargin: 0.02,
  );

  test('parses row-major YOLO output into detections', () {
    final detections = parser.parse(
      <double>[
        0.5,
        0.5,
        0.2,
        0.2,
        0.9,
        0.1,
        0.8,
        0.1,
        0.1,
        0.1,
        0.1,
        0.4,
        0.9,
        0.1,
      ],
      shape: <int>[1, 2, 7],
    );

    expect(detections, hasLength(1));
    expect(detections.single.label, 'ka');
    expect(detections.single.confidence, closeTo(0.72, 0.001));
    expect(detections.single.left, closeTo(0.4, 0.001));
    expect(detections.single.top, closeTo(0.4, 0.001));
  });

  test('parses transposed YOLO output into detections', () {
    final detections = parser.parse(
      <double>[
        0.5,
        0.1,
        0.5,
        0.1,
        0.2,
        0.1,
        0.2,
        0.1,
        0.9,
        0.4,
        0.1,
        0.9,
        0.8,
        0.1,
      ],
      shape: <int>[1, 7, 2],
    );

    expect(detections, hasLength(1));
    expect(detections.single.label, 'ka');
    expect(detections.single.confidence, closeTo(0.72, 0.001));
  });

  test('parses 2D web model output shape into detections', () {
    final List<BaybayinDetection> detections = parser.parse(
      <double>[
        0.5,
        0.5,
        0.2,
        0.2,
        0.9,
        0.1,
        0.8,
        0.1,
        0.1,
        0.1,
        0.1,
        0.4,
        0.9,
        0.1,
      ],
      shape: <int>[2, 7],
    );

    expect(detections, hasLength(1));
    expect(detections.single.label, 'ka');
    expect(detections.single.confidence, closeTo(0.72, 0.001));
  });

  test('suppresses lower-confidence overlapping boxes', () {
    final detections = parser.parse(
      <double>[
        0.5,
        0.5,
        0.2,
        0.2,
        0.9,
        0.1,
        0.8,
        0.51,
        0.51,
        0.2,
        0.2,
        0.8,
        0.1,
        0.75,
      ],
      shape: <int>[1, 2, 7],
    );

    expect(detections, hasLength(1));
    expect(detections.single.confidence, closeTo(0.72, 0.001));
  });

  test('drops edge-clipped and tiny boxes', () {
    final detections = parser.parse(
      <double>[
        0.01,
        0.5,
        0.04,
        0.2,
        0.95,
        0.1,
        0.9,
        0.5,
        0.5,
        0.01,
        0.01,
        0.95,
        0.1,
        0.9,
      ],
      shape: <int>[1, 2, 7],
    );

    expect(detections, isEmpty);
  });
}
