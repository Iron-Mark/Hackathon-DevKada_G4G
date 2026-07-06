import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:kudlit_ph/features/home/presentation/utils/safe_ai_output.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/butty_chat/baybayin_chat_renderer.dart';

class ButtyBubble extends StatelessWidget {
  const ButtyBubble({super.key, required this.text, this.isStreaming = false});

  final String text;

  /// True when this bubble is the active streaming response. Drives the
  /// trailing cursor that blinks until the stream closes.
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String displayText = cleanAssistantOutput(text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primaryContainer,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/brand/ButtyRead.webp',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (MediaQuery.sizeOf(context).width * 0.78).clamp(
                  220.0,
                  280.0,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                  border: Border.all(color: cs.outline),
                ),
                child: _BubbleContent(
                  text: displayText,
                  isStreaming: isStreaming,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleContent extends StatelessWidget {
  const _BubbleContent({required this.text, required this.isStreaming});

  final String text;
  final bool isStreaming;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final TextStyle baseStyle = TextStyle(
      fontSize: 13.5,
      color: cs.onSurface.withAlpha(220),
      height: 1.5,
    );

    final Widget body = BaybayinChatRenderer(text: text, baseStyle: baseStyle);

    if (!isStreaming) return body;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Flexible(child: body),
        const SizedBox(width: 2),
        _StreamingCursor(color: cs.primary),
      ],
    );
  }
}

class _StreamingCursor extends StatelessWidget {
  const _StreamingCursor({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child:
          Container(
                width: 6,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              )
              .animate(
                onPlay: (AnimationController c) => c.repeat(reverse: true),
              )
              .fadeOut(duration: 600.ms, curve: Curves.easeInOut),
    );
  }
}
