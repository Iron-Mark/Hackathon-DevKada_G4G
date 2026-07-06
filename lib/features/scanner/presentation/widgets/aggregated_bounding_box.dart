import 'package:flutter/material.dart';

import 'package:kudlit_ph/core/utils/baybayify.dart';
import 'package:kudlit_ph/features/scanner/domain/entities/baybayin_detection.dart';

/// Draws a single union bounding box around all [detections] plus a
/// tappable permutation-label chip.
///
/// [BaybayinDetection] coordinates are normalised (0–1) relative to the
/// camera inference frame. Place this widget in a [Stack] that fills the
/// same area as the camera feed.
class AggregatedBoundingBox extends StatelessWidget {
  const AggregatedBoundingBox({
    required this.detections,
    this.onPermutationsTap,
    super.key,
  });

  final List<BaybayinDetection> detections;

  /// Called when the user taps the permutation chip. Receives the full list
  /// of computed permutations (always non-empty when this fires).
  final void Function(List<String> permutations)? onPermutationsTap;

  static const Color _boxColor = Color(0xFF4CFFA0);
  static const double _strokeWidth = 2.0;
  static const double _radius = 6.0;
  static const double _unionPadH = 40.0;
  static const double _unionPadV = 18.0;

  @override
  Widget build(BuildContext context) {
    if (detections.isEmpty) return const SizedBox.shrink();

    final List<BaybayinDetection> ordered =
        List<BaybayinDetection>.of(detections)..sort(
          (BaybayinDetection a, BaybayinDetection b) =>
              a.left.compareTo(b.left),
        );
    final List<String> tokens = ordered
        .map((BaybayinDetection d) => d.label.trim().toLowerCase())
        .where((String s) => s.isNotEmpty)
        .toList(growable: false);
    final List<String> perms = permuteBaybayin(tokens);
    final String primary = perms.isEmpty ? tokens.join() : perms.first;
    final int extras = perms.length > 1 ? perms.length - 1 : 0;

    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints constraints) {
        final Size size = constraints.biggest;

        // Union of all detection boxes in pixel space.
        Rect union = _toPixels(ordered.first, size);
        for (int i = 1; i < ordered.length; i++) {
          union = union.expandToInclude(_toPixels(ordered[i], size));
        }
        final Rect outer = Rect.fromLTRB(
          (union.left - _unionPadH).clamp(0.0, size.width),
          (union.top - _unionPadV).clamp(0.0, size.height),
          (union.right + _unionPadH).clamp(0.0, size.width),
          (union.bottom + _unionPadV).clamp(0.0, size.height),
        );

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CustomPaint(
              painter: _BoxPainter(rect: outer),
              child: const SizedBox.expand(),
            ),
            _ChipPositioner(
              outer: outer,
              size: size,
              primary: primary,
              extras: extras,
              onTap: (extras > 0 && onPermutationsTap != null)
                  ? () => onPermutationsTap!(perms)
                  : null,
            ),
          ],
        );
      },
    );
  }

  static Rect _toPixels(BaybayinDetection d, Size size) => Rect.fromLTWH(
    d.left * size.width,
    d.top * size.height,
    d.width * size.width,
    d.height * size.height,
  );
}

// ── Box painter ───────────────────────────────────────────────────────────────

class _BoxPainter extends CustomPainter {
  _BoxPainter({required this.rect});

  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        const Radius.circular(AggregatedBoundingBox._radius),
      ),
      Paint()
        ..color = AggregatedBoundingBox._boxColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = AggregatedBoundingBox._strokeWidth,
    );
  }

  @override
  bool shouldRepaint(_BoxPainter old) => old.rect != rect;
}

// ── Tappable chip ─────────────────────────────────────────────────────────────

class _ChipPositioner extends StatelessWidget {
  const _ChipPositioner({
    required this.outer,
    required this.size,
    required this.primary,
    required this.extras,
    required this.onTap,
  });

  final Rect outer;
  final Size size;
  final String primary;
  final int extras;
  final VoidCallback? onTap;

  static const double _chipHeight = 32.0;
  static const double _gap = 6.0;

  @override
  Widget build(BuildContext context) {
    if (primary.isEmpty) return const SizedBox.shrink();

    // Prefer above the box; fall back to below if there isn't room.
    double top = outer.top - _chipHeight - _gap;
    if (top < 4) top = outer.bottom + _gap;

    return Positioned(
      left: outer.left.clamp(4.0, size.width - 80),
      top: top,
      child: _PermutationChip(primary: primary, extras: extras, onTap: onTap),
    );
  }
}

class _PermutationChip extends StatelessWidget {
  const _PermutationChip({
    required this.primary,
    required this.extras,
    required this.onTap,
  });

  final String primary;
  final int extras;
  final VoidCallback? onTap;

  static const Color _chipBg = Color(0xFF4CFFA0);
  static const Color _chipText = Color(0xFF050A14);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _chipBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                primary,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _chipText,
                  letterSpacing: 0.3,
                ),
              ),
              if (extras > 0) ...<Widget>[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _chipText.withAlpha(30),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '+$extras',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _chipText,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.unfold_more_rounded,
                  size: 14,
                  color: _chipText,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
