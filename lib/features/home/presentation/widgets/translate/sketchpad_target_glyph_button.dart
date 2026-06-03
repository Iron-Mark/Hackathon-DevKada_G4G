import 'package:flutter/material.dart';

import 'package:kudlit_ph/features/home/presentation/widgets/translate/baybayin_target_glyphs.dart';
import 'package:kudlit_ph/features/home/presentation/widgets/translate/sketchpad_target_glyph_sheet.dart';

/// Tap-to-pick replacement for the old free-text target field. Opens the
/// glyph grid sheet instead of a keyboard, so the sketchpad never
/// triggers the keyboard-driven layout re-mount loop from the audit.
class SketchpadTargetGlyphButton extends StatelessWidget {
  const SketchpadTargetGlyphButton({
    super.key,
    required this.currentLabel,
    required this.onSelected,
  });

  /// The romanized label currently stored in the controller state.
  final String currentLabel;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String trimmed = currentLabel.trim();
    final BaybayinTargetGlyph? selected = trimmed.isEmpty
        ? null
        : kBaybayinTargetGlyphs
              .where((BaybayinTargetGlyph g) => g.label == trimmed)
              .firstOrNull;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final String? picked = await SketchpadTargetGlyphSheet.show(
            context,
            currentLabel: trimmed,
          );
          if (picked != null) {
            onSelected(picked);
          }
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline),
          ),
          child: Row(
            children: <Widget>[
              if (selected != null) ...<Widget>[
                Text(
                  selected.glyph,
                  style: const TextStyle(
                    fontFamily: 'Baybayin Simple TAWBID',
                    fontSize: 22,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  selected?.label ?? 'Target glyph',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected != null
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: selected != null
                        ? cs.onSurface
                        : cs.onSurface.withAlpha(120),
                  ),
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                size: 20,
                color: cs.onSurface.withAlpha(150),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
