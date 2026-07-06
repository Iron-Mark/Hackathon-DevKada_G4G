import 'package:flutter/material.dart';

class EmptyOutput extends StatelessWidget {
  const EmptyOutput({
    super.key,
    this.message = 'Type below to preview Baybayin',
    this.icon = Icons.text_fields_rounded,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Empty translation output',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 32, color: cs.onSurface.withAlpha(120)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: cs.onSurface.withAlpha(170),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
