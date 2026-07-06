import 'package:flutter/material.dart';

import 'package:kudlit_ph/features/home/presentation/widgets/translate/baybayin_target_glyphs.dart';

/// Keyboard-free target picker: a grid of Baybayin base glyphs. Tapping a
/// tile pops the sheet with the romanized label; no text input, so the
/// keyboard never opens here (the textbox was what drove the layout
/// re-mount loop — see the runtime-log audit).
class SketchpadTargetGlyphSheet extends StatelessWidget {
  const SketchpadTargetGlyphSheet({super.key, required this.currentLabel});

  final String currentLabel;

  /// Opens the picker and resolves to the chosen romanized label, or
  /// `null` if dismissed without a selection.
  static Future<String?> show(
    BuildContext context, {
    required String currentLabel,
  }) {
    // No `showDragHandle` / `isScrollControlled`: both make the sheet
    // measure its child under unbounded constraints. The content bounds
    // its own width/height instead.
    return showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) =>
          SketchpadTargetGlyphSheet(currentLabel: currentLabel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Size screen = MediaQuery.sizeOf(context);
    return SafeArea(
      top: false,
      child: SizedBox(
        width: screen.width,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screen.height * 0.7),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: cs.onSurface.withAlpha(60),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 4),
                    child: Text(
                      'Choose target glyph',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      for (final BaybayinTargetGlyph entry
                          in kBaybayinTargetGlyphs)
                        _TargetGlyphTile(
                          entry: entry,
                          selected: entry.label == currentLabel.trim(),
                          onTap: () =>
                              Navigator.of(context).pop(entry.label),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TargetGlyphTile extends StatelessWidget {
  const _TargetGlyphTile({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final BaybayinTargetGlyph entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Target glyph ${entry.label}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? cs.primaryContainer
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? cs.primary : cs.outline.withAlpha(90),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  entry.glyph,
                  style: TextStyle(
                    fontFamily: 'Baybayin Simple TAWBID',
                    fontSize: 30,
                    height: 1,
                    color: selected ? cs.onPrimaryContainer : cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? cs.onPrimaryContainer
                        : cs.onSurface.withAlpha(180),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
