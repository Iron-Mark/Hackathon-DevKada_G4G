import 'dart:math' as math;

import 'package:kudlit_ph/features/scanner/domain/entities/baybayin_detection.dart';

class WebYoloOutputParser {
  const WebYoloOutputParser({
    required this.labels,
    required this.confidenceThreshold,
    required this.iouThreshold,
    required this.minBoxArea,
    required this.edgeMargin,
  });

  final List<String> labels;
  final double confidenceThreshold;
  final double iouThreshold;
  final double minBoxArea;
  final double edgeMargin;

  bool canParse(List<double> output, {List<int>? shape}) {
    return _rowsFor(output, shape).isNotEmpty;
  }

  List<BaybayinDetection> parse(List<double> output, {List<int>? shape}) {
    if (labels.isEmpty || output.isEmpty) return const <BaybayinDetection>[];

    final List<List<double>> rows = _rowsFor(output, shape);
    final List<BaybayinDetection> detections = <BaybayinDetection>[];
    for (final List<double> row in rows) {
      final BaybayinDetection? detection = _parseRow(row);
      if (detection != null) {
        detections.add(detection);
      }
    }

    detections.sort(
      (BaybayinDetection a, BaybayinDetection b) =>
          b.confidence.compareTo(a.confidence),
    );
    return _nonMaxSuppress(detections)..sort(
      (BaybayinDetection a, BaybayinDetection b) => a.left.compareTo(b.left),
    );
  }

  List<List<double>> _rowsFor(List<double> output, List<int>? shape) {
    final int attrsWithObjectness = labels.length + 5;
    final int attrsWithoutObjectness = labels.length + 4;

    if (shape != null && shape.length >= 2) {
      final int second = shape[shape.length - 2];
      final int third = shape[shape.length - 1];
      if (third == attrsWithObjectness || third == attrsWithoutObjectness) {
        return _rowMajor(output, third);
      }
      if (second == attrsWithObjectness || second == attrsWithoutObjectness) {
        return _transposed(output, attrs: second, boxes: third);
      }
    }

    if (output.length % attrsWithObjectness == 0) {
      return _rowMajor(output, attrsWithObjectness);
    }
    if (output.length % attrsWithoutObjectness == 0) {
      return _rowMajor(output, attrsWithoutObjectness);
    }
    return const <List<double>>[];
  }

  List<List<double>> _rowMajor(List<double> output, int attrs) {
    final int rowCount = output.length ~/ attrs;
    return List<List<double>>.generate(rowCount, (int row) {
      final int offset = row * attrs;
      return output.sublist(offset, offset + attrs);
    }, growable: false);
  }

  List<List<double>> _transposed(
    List<double> output, {
    required int attrs,
    required int boxes,
  }) {
    if (output.length < attrs * boxes) return const <List<double>>[];
    return List<List<double>>.generate(boxes, (int box) {
      return List<double>.generate(
        attrs,
        (int attr) => output[(attr * boxes) + box],
        growable: false,
      );
    }, growable: false);
  }

  BaybayinDetection? _parseRow(List<double> row) {
    if (row.length < labels.length + 4) return null;

    final bool hasObjectness = row.length >= labels.length + 5;
    final int classOffset = hasObjectness ? 5 : 4;
    final double objectness = hasObjectness ? row[4] : 1;

    int bestClass = 0;
    double bestScore = double.negativeInfinity;
    for (int i = 0; i < labels.length; i++) {
      final double score = row[classOffset + i];
      if (score > bestScore) {
        bestScore = score;
        bestClass = i;
      }
    }

    final double confidence = objectness * bestScore;
    if (confidence < confidenceThreshold) return null;

    final double width = row[2].clamp(0, 1).toDouble();
    final double height = row[3].clamp(0, 1).toDouble();
    if (width * height < minBoxArea) return null;

    final double left = (row[0] - (width / 2)).clamp(0, 1).toDouble();
    final double top = (row[1] - (height / 2)).clamp(0, 1).toDouble();
    final double right = (left + width).clamp(0, 1).toDouble();
    final double bottom = (top + height).clamp(0, 1).toDouble();

    if (left < edgeMargin ||
        top < edgeMargin ||
        right > 1 - edgeMargin ||
        bottom > 1 - edgeMargin) {
      return null;
    }

    return BaybayinDetection(
      label: labels[bestClass],
      confidence: confidence,
      left: left,
      top: top,
      width: width,
      height: height,
    );
  }

  List<BaybayinDetection> _nonMaxSuppress(List<BaybayinDetection> detections) {
    final List<BaybayinDetection> kept = <BaybayinDetection>[];
    for (final BaybayinDetection detection in detections) {
      final bool overlapsKept = kept.any(
        (BaybayinDetection other) => _iou(detection, other) > iouThreshold,
      );
      if (!overlapsKept) {
        kept.add(detection);
      }
    }
    return kept;
  }

  double _iou(BaybayinDetection a, BaybayinDetection b) {
    final double left = math.max(a.left, b.left);
    final double top = math.max(a.top, b.top);
    final double right = math.min(a.left + a.width, b.left + b.width);
    final double bottom = math.min(a.top + a.height, b.top + b.height);
    final double intersection =
        math.max(0, right - left) * math.max(0, bottom - top);
    final double union =
        (a.width * a.height) + (b.width * b.height) - intersection;
    return union <= 0 ? 0 : intersection / union;
  }
}
