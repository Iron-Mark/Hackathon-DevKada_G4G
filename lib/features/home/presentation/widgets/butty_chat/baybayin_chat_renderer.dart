import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import 'package:kudlit_ph/core/utils/baybayify.dart';

// ---------------------------------------------------------------------------
// Internal segment model — pure data, no widgets
// ---------------------------------------------------------------------------

sealed class _Segment {
  const _Segment();
}

final class _MarkdownSegment extends _Segment {
  const _MarkdownSegment(this.text);
  final String text;
}

final class _BaybayinSegment extends _Segment {
  const _BaybayinSegment(this.text);
  final String text;
}

// ---------------------------------------------------------------------------
// Public renderer
// ---------------------------------------------------------------------------

/// Renders assistant bubble text that may contain `<baybayin>…</baybayin>` tags.
///
/// Tag content is run through [baybayifyWord] and displayed with the
/// *Baybayin Simple TAWBID* font at a slightly larger size so the glyphs
/// are legible. Everything outside the tags is rendered as Markdown.
class BaybayinChatRenderer extends StatelessWidget {
  const BaybayinChatRenderer({
    super.key,
    required this.text,
    required this.baseStyle,
  });

  final String text;
  final TextStyle baseStyle;

  static final RegExp _tagRe = RegExp(
    r'<baybayin>(.*?)</baybayin>',
    caseSensitive: false,
    dotAll: true,
  );

  List<_Segment> _parseSegments() {
    final List<_Segment> result = <_Segment>[];
    int lastEnd = 0;
    for (final RegExpMatch m in _tagRe.allMatches(text)) {
      if (m.start > lastEnd) {
        final String part = text.substring(lastEnd, m.start);
        if (part.trim().isNotEmpty) result.add(_MarkdownSegment(part));
      }
      final String inner = m.group(1) ?? '';
      if (inner.trim().isNotEmpty) result.add(_BaybayinSegment(inner));
      lastEnd = m.end;
    }
    if (lastEnd < text.length) {
      final String tail = text.substring(lastEnd);
      if (tail.trim().isNotEmpty) result.add(_MarkdownSegment(tail));
    }
    return result.isEmpty ? <_Segment>[_MarkdownSegment(text)] : result;
  }

  MarkdownStyleSheet _styleSheet(ColorScheme cs) {
    return MarkdownStyleSheet(
      p: baseStyle,
      h1: baseStyle.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
      h2: baseStyle.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      h3: baseStyle.copyWith(fontSize: 14.5, fontWeight: FontWeight.w700),
      strong: baseStyle.copyWith(fontWeight: FontWeight.w700),
      em: baseStyle.copyWith(fontStyle: FontStyle.italic),
      listBullet: baseStyle,
      a: baseStyle.copyWith(
        color: cs.primary,
        decoration: TextDecoration.underline,
      ),
      code: baseStyle.copyWith(
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

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final MarkdownStyleSheet styleSheet = _styleSheet(cs);
    final List<_Segment> segments = _parseSegments();

    if (segments.length == 1 && segments.first is _MarkdownSegment) {
      return _MarkdownBlock(
        text: (segments.first as _MarkdownSegment).text,
        styleSheet: styleSheet,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final _Segment seg in segments)
          if (seg is _MarkdownSegment)
            _MarkdownBlock(text: seg.text, styleSheet: styleSheet)
          else if (seg is _BaybayinSegment)
            _BaybayinBlock(text: seg.text, baseStyle: baseStyle),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private implementation widgets
// ---------------------------------------------------------------------------

class _MarkdownBlock extends StatelessWidget {
  const _MarkdownBlock({required this.text, required this.styleSheet});

  final String text;
  final MarkdownStyleSheet styleSheet;

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: text,
      shrinkWrap: true,
      softLineBreak: true,
      styleSheet: styleSheet,
    );
  }
}

class _BaybayinBlock extends StatelessWidget {
  const _BaybayinBlock({required this.text, required this.baseStyle});

  final String text;
  final TextStyle baseStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        baybayifyWord(text),
        style: baseStyle.copyWith(
          fontFamily: 'Baybayin Simple TAWBID',
          fontSize: (baseStyle.fontSize ?? 13.5) * 1.4,
          height: 1.3,
        ),
      ),
    );
  }
}
