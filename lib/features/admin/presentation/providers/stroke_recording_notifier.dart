import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kudlit_ph/features/admin/data/datasources/supabase_stroke_pattern_datasource.dart';
import 'package:kudlit_ph/features/admin/domain/entities/stroke_pattern.dart';
import 'package:kudlit_ph/features/admin/domain/entities/timed_point.dart';
import 'package:kudlit_ph/features/admin/presentation/providers/stroke_pattern_providers.dart';
import 'package:kudlit_ph/features/admin/presentation/providers/stroke_recording_state.dart';

part 'stroke_recording_notifier.g.dart';

@Riverpod(name: 'strokeRecordingNotifierProvider')
class StrokeRecordingNotifier extends _$StrokeRecordingNotifier {
  // Session-level values preserved across glyph changes and state transitions.
  Uint8List? _overlayBytes;
  double _strokeWidth = 4.0;
  final List<StrokePattern> _sessionPatterns = <StrokePattern>[];

  /// Constructs an idle state using the current session-level values.
  StrokeRecordingIdle _makeIdle(
    String glyph,
    String label, {
    List<StrokeData> strokes = const <StrokeData>[],
    List<TimedPoint> currentStroke = const <TimedPoint>[],
    DateTime? strokeStartTime,
    bool clearStrokeStart = false,
  }) {
    return StrokeRecordingIdle(
      selectedGlyph: glyph,
      selectedLabel: label,
      strokes: strokes,
      currentStroke: currentStroke,
      strokeStartTime: clearStrokeStart ? null : strokeStartTime,
      overlayImageBytes: _overlayBytes,
      strokeWidth: _strokeWidth,
      sessionPatterns: List<StrokePattern>.unmodifiable(_sessionPatterns),
    );
  }

  @override
  StrokeRecordingState build() {
    final ({String glyph, String label}) first = kBaybayinGlyphs.first;
    return _makeIdle(first.glyph, first.label);
  }

  // ─── Glyph selection ──────────────────────────────────────────────────────

  void selectGlyph(String glyph, String label) {
    state = _makeIdle(glyph, label);
  }

  // ─── Overlay image ────────────────────────────────────────────────────────

  void setOverlayImage(Uint8List? bytes) {
    _overlayBytes = bytes;
    if (state is! StrokeRecordingIdle) return;
    final StrokeRecordingIdle s = state as StrokeRecordingIdle;
    state = s.copyWith(overlayImageBytes: bytes, clearOverlay: bytes == null);
  }

  // ─── Stroke width ─────────────────────────────────────────────────────────

  void setStrokeWidth(double width) {
    _strokeWidth = width;
    if (state is! StrokeRecordingIdle) return;
    final StrokeRecordingIdle s = state as StrokeRecordingIdle;
    state = s.copyWith(strokeWidth: width);
  }

  // ─── Drawing events ───────────────────────────────────────────────────────

  void onPanStart(Offset position, Size canvasSize) {
    if (state is! StrokeRecordingIdle) return;
    final StrokeRecordingIdle s = state as StrokeRecordingIdle;

    final TimedPoint first = TimedPoint(
      x: position.dx / canvasSize.width,
      y: position.dy / canvasSize.height,
      t: 0,
    );

    state = s.copyWith(
      currentStroke: <TimedPoint>[first],
      strokeStartTime: DateTime.now(),
    );
  }

  void onPanUpdate(Offset position, Size canvasSize) {
    if (state is! StrokeRecordingIdle) return;
    final StrokeRecordingIdle s = state as StrokeRecordingIdle;
    if (s.strokeStartTime == null) return;

    final int elapsed = DateTime.now()
        .difference(s.strokeStartTime!)
        .inMilliseconds;

    final TimedPoint point = TimedPoint(
      x: position.dx / canvasSize.width,
      y: position.dy / canvasSize.height,
      t: elapsed,
    );

    state = s.copyWith(currentStroke: <TimedPoint>[...s.currentStroke, point]);
  }

  void onPanEnd(Size canvasSize) {
    if (state is! StrokeRecordingIdle) return;
    final StrokeRecordingIdle s = state as StrokeRecordingIdle;
    if (s.currentStroke.isEmpty) return;

    final StrokeData committed = StrokeData(points: s.currentStroke);

    state = s.copyWith(
      strokes: <StrokeData>[...s.strokes, committed],
      currentStroke: <TimedPoint>[],
      clearStrokeStart: true,
    );
  }

  // ─── Editing ──────────────────────────────────────────────────────────────

  void undoLastStroke() {
    if (state is! StrokeRecordingIdle) return;
    final StrokeRecordingIdle s = state as StrokeRecordingIdle;
    if (s.strokes.isEmpty) return;

    final List<StrokeData> updated = List<StrokeData>.from(s.strokes)
      ..removeLast();
    state = s.copyWith(strokes: updated, currentStroke: <TimedPoint>[]);
  }

  void clearAll() {
    if (state is! StrokeRecordingIdle) return;
    final StrokeRecordingIdle s = state as StrokeRecordingIdle;
    state = _makeIdle(s.selectedGlyph, s.selectedLabel);
  }

  // ─── Save ─────────────────────────────────────────────────────────────────

  Future<void> save(Size canvasSize) async {
    if (state is! StrokeRecordingIdle) return;
    final StrokeRecordingIdle s = state as StrokeRecordingIdle;
    if (s.strokes.isEmpty) return;

    state = StrokeRecordingSaving(
      selectedGlyph: s.selectedGlyph,
      selectedLabel: s.selectedLabel,
    );

    final String userId = Supabase.instance.client.auth.currentUser!.id;
    final Map<String, dynamic> deviceInfo = buildDeviceInfo(
      canvasWidth: canvasSize.width,
      canvasHeight: canvasSize.height,
    );

    final StrokePattern pattern = StrokePattern(
      id: '',
      userId: userId,
      glyph: s.selectedGlyph,
      label: s.selectedLabel,
      strokes: s.strokes,
      canvasWidth: canvasSize.width,
      canvasHeight: canvasSize.height,
      deviceInfo: deviceInfo,
      createdAt: DateTime.now(),
    );

    final result = await ref
        .read(strokePatternRepositoryProvider)
        .save(pattern);

    result.fold(
      (failure) => state = StrokeRecordingError(
        message: failure.toString(),
        selectedGlyph: s.selectedGlyph,
        selectedLabel: s.selectedLabel,
        strokes: s.strokes,
      ),
      (saved) {
        _sessionPatterns.add(saved);
        state = StrokeRecordingSaved(
          pattern: saved,
          sessionPatterns: List<StrokePattern>.unmodifiable(_sessionPatterns),
        );
      },
    );
  }

  /// After a successful save, reset to idle for the same glyph.
  void resetAfterSave() {
    if (state is! StrokeRecordingSaved) return;
    final StrokeRecordingSaved s = state as StrokeRecordingSaved;
    state = _makeIdle(s.pattern.glyph, s.pattern.label);
  }

  /// After an error, go back to idle preserving the strokes.
  void dismissError() {
    if (state is! StrokeRecordingError) return;
    final StrokeRecordingError s = state as StrokeRecordingError;
    state = _makeIdle(s.selectedGlyph, s.selectedLabel, strokes: s.strokes);
  }
}
