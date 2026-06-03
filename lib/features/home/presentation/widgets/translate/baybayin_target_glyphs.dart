import 'package:meta/meta.dart';

/// A selectable Baybayin base character for the sketchpad target picker.
///
/// [glyph] is the Unicode codepoint (rendered with the Baybayin font);
/// [label] is the romanized name fed to the AI coach prompt (unchanged
/// from the previous free-text field, so feedback behavior is identical).
@immutable
class BaybayinTargetGlyph {
  const BaybayinTargetGlyph(this.glyph, this.label);

  final String glyph;
  final String label;
}

/// The 17 base Baybayin characters (U+1700–U+1711, excluding the reserved
/// U+170D and the kudlit/virama marks). Static reference data, not user
/// input — picking from this list replaces the keyboard textbox entirely,
/// so the sketchpad never opens the IME (see the runtime-log audit:
/// the target field's keyboard was what drove the layout re-mount loop).
const List<BaybayinTargetGlyph> kBaybayinTargetGlyphs = <BaybayinTargetGlyph>[
  BaybayinTargetGlyph('ᜀ', 'a'),
  BaybayinTargetGlyph('ᜁ', 'i'),
  BaybayinTargetGlyph('ᜂ', 'u'),
  BaybayinTargetGlyph('ᜃ', 'ka'),
  BaybayinTargetGlyph('ᜄ', 'ga'),
  BaybayinTargetGlyph('ᜅ', 'nga'),
  BaybayinTargetGlyph('ᜆ', 'ta'),
  BaybayinTargetGlyph('ᜇ', 'da'),
  BaybayinTargetGlyph('ᜈ', 'na'),
  BaybayinTargetGlyph('ᜉ', 'pa'),
  BaybayinTargetGlyph('ᜊ', 'ba'),
  BaybayinTargetGlyph('ᜋ', 'ma'),
  BaybayinTargetGlyph('ᜌ', 'ya'),
  BaybayinTargetGlyph('ᜎ', 'la'),
  BaybayinTargetGlyph('ᜏ', 'wa'),
  BaybayinTargetGlyph('ᜐ', 'sa'),
  BaybayinTargetGlyph('ᜑ', 'ha'),
];
