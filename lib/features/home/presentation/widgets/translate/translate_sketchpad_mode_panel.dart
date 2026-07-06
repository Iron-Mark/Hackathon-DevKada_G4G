import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:kudlit_ph/features/home/presentation/providers/translate_sketchpad_controller.dart';
import 'package:kudlit_ph/features/home/presentation/utils/safe_ai_output.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/learn/live_stroke_painter.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/translate/sketchpad_target_glyph_button.dart';

class TranslateSketchpadModePanel extends StatefulWidget {
  const TranslateSketchpadModePanel({
    super.key,
    required this.state,
    required this.aiActionsEnabled,
    required this.disabledReason,
    required this.onTargetChanged,
    required this.onGetFeedback,
  });

  final TranslateSketchpadState state;
  final bool aiActionsEnabled;
  final String? disabledReason;
  final ValueChanged<String> onTargetChanged;
  final Future<void> Function(List<List<Offset>> strokes) onGetFeedback;

  @override
  State<TranslateSketchpadModePanel> createState() =>
      _TranslateSketchpadModePanelState();
}

class _TranslateSketchpadModePanelState
    extends State<TranslateSketchpadModePanel> {
  final List<List<Offset>> _strokes = <List<Offset>>[];
  final List<Offset> _current = <Offset>[];

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _current
        ..clear()
        ..add(d.localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _current.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails _) {
    if (_current.isNotEmpty) {
      setState(() {
        _strokes.add(List<Offset>.from(_current));
        _current.clear();
      });
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _current.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canRequest =
        widget.aiActionsEnabled &&
        !widget.state.aiBusy &&
        _strokes.isNotEmpty &&
        widget.state.target.trim().isNotEmpty;

    final bool showFeedback =
        widget.state.aiBusy || widget.state.aiResponse.trim().isNotEmpty;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _InlineCanvas(
            target: widget.state.target,
            strokes: _strokes,
            currentStroke: _current,
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
          ),
        ),
        if (showFeedback)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _ButtyFeedback(
                text: widget.state.aiResponse,
                isLoading: widget.state.aiBusy,
              ),
            ),
          )
        else
          const Spacer(),
        _BottomBar(
          state: widget.state,
          canRequest: canRequest,
          disabledReason: widget.disabledReason,
          hasStrokes: _strokes.isNotEmpty,
          onTargetChanged: widget.onTargetChanged,
          onClear: _clear,
          onGetFeedback: () => widget.onGetFeedback(_strokes),
        ),
      ],
    );
  }
}

class _InlineCanvas extends StatelessWidget {
  const _InlineCanvas({
    required this.target,
    required this.strokes,
    required this.currentStroke,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  final String target;
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final void Function(DragStartDetails) onPanStart;
  final void Function(DragUpdateDetails) onPanUpdate;
  final void Function(DragEndDetails) onPanEnd;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String preview = target.trim().isEmpty ? '?' : target.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 300,
        width: double.infinity,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline),
        ),
        child: Stack(
          children: <Widget>[
            GestureDetector(
              onPanStart: onPanStart,
              onPanUpdate: onPanUpdate,
              onPanEnd: onPanEnd,
              child: CustomPaint(
                painter: LiveStrokePainter(
                  strokes: strokes,
                  current: currentStroke,
                  strokeColor: cs.onSurface,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 12,
              child: Text(
                preview,
                style: TextStyle(
                  fontFamily: 'Baybayin Simple TAWBID',
                  fontSize: 48,
                  color: cs.onSurface.withAlpha(18),
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.state,
    required this.canRequest,
    required this.disabledReason,
    required this.hasStrokes,
    required this.onTargetChanged,
    required this.onClear,
    required this.onGetFeedback,
  });

  final TranslateSketchpadState state;
  final bool canRequest;
  final String? disabledReason;
  final bool hasStrokes;
  final ValueChanged<String> onTargetChanged;
  final VoidCallback onClear;
  final VoidCallback onGetFeedback;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outline.withAlpha(80))),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SketchpadTargetGlyphButton(
                  currentLabel: state.target,
                  onSelected: onTargetChanged,
                ),
              ),
              const SizedBox(width: 8),
              _PillButton(label: 'Clear', enabled: hasStrokes, onTap: onClear),
              const SizedBox(width: 8),
              _PillButton(
                label: state.aiBusy ? 'Working...' : 'Get Feedback',
                enabled: canRequest,
                primary: true,
                onTap: onGetFeedback,
              ),
            ],
          ),
          if (disabledReason != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              disabledReason!,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withAlpha(160),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color bg = switch ((primary, enabled)) {
      (true, true) => cs.primary,
      (true, false) => cs.surfaceContainerLowest,
      (false, true) => cs.surfaceContainer,
      _ => cs.surfaceContainerLowest,
    };
    final Color fg = switch ((primary, enabled)) {
      (true, true) => cs.onPrimary,
      _ => cs.onSurface.withAlpha(enabled ? 220 : 110),
    };
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _ButtyFeedback extends StatelessWidget {
  const _ButtyFeedback({required this.text, required this.isLoading});

  final String text;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool showDots = isLoading && text.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Butty avatar circle.
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primaryContainer,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/brand/ButtyPaint.webp',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Speech bubble.
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(color: cs.outline),
              ),
              child: showDots
                  ? const _ThinkingDots()
                  : MarkdownBody(
                      data: cleanAssistantOutput(text),
                      shrinkWrap: true,
                      softLineBreak: true,
                      styleSheet: _feedbackMarkdownStyle(cs),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

MarkdownStyleSheet _feedbackMarkdownStyle(ColorScheme cs) {
  final TextStyle base = TextStyle(
    fontSize: 13.5,
    color: cs.onSurface.withAlpha(220),
    height: 1.5,
  );
  return MarkdownStyleSheet(
    p: base,
    h1: base.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
    h2: base.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
    h3: base.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
    strong: base.copyWith(fontWeight: FontWeight.w700),
    em: base.copyWith(fontStyle: FontStyle.italic),
    listBullet: base,
    a: base.copyWith(color: cs.primary, decoration: TextDecoration.underline),
    code: base.copyWith(
      fontFamily: 'monospace',
      fontSize: 12.5,
      backgroundColor: cs.surface,
    ),
    codeblockDecoration: BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: cs.outline),
    ),
    codeblockPadding: const EdgeInsets.all(10),
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: cs.primary, width: 3)),
    ),
    blockquotePadding: const EdgeInsets.only(left: 10),
    blockSpacing: 6,
  );
}

class _ThinkingDots extends StatefulWidget {
  const _ThinkingDots();

  @override
  State<_ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<_ThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 500),
        )..addListener(() {
          final int next = (_ctrl.value * 3).floor() + 1;
          if (next != _dotCount) setState(() => _dotCount = next);
        });
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Text(
      'Butty is thinking${'.' * _dotCount}',
      style: TextStyle(
        fontSize: 13.5,
        color: cs.onSurface.withAlpha(140),
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
