import 'package:flutter/material.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.responding,
    required this.enabled,
    required this.onSend,
    this.disabledHint,
  });

  final TextEditingController controller;
  final bool responding;
  final bool enabled;
  final VoidCallback onSend;
  final String? disabledHint;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool inputEnabled = enabled && !responding;
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.paddingOf(context).bottom + 8,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(top: BorderSide(color: cs.outline)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              enabled: inputEnabled,
              style: TextStyle(fontSize: 14, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: responding
                    ? 'Butty is typing...'
                    : inputEnabled
                    ? 'Ask Butty anything...'
                    : (disabledHint ?? 'Preparing offline Gemma...'),
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withAlpha(160),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
              ),
              onSubmitted: inputEnabled ? (_) => onSend() : null,
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            enabled: inputEnabled,
            label: 'Send message',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: inputEnabled ? onSend : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: inputEnabled ? cs.primary : cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    size: 16,
                    color: inputEnabled
                        ? cs.onPrimary
                        : cs.onSurface.withAlpha(80),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
