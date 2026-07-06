import 'package:flutter/material.dart';

import 'glyph_item.dart';

class GlyphPreviewRow extends StatelessWidget {
  const GlyphPreviewRow({super.key, required this.items, this.muted = false});

  final List<(String, String)> items;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool tight = constraints.maxWidth < 280;
          if (tight) {
            return Wrap(
              alignment: WrapAlignment.spaceAround,
              runAlignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: _glyphItems(),
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _glyphItems(),
          );
        },
      ),
    );
  }

  List<Widget> _glyphItems() {
    return items
        .map(
          ((String, String) item) =>
              GlyphItem(glyph: item.$1, label: item.$2, muted: muted),
        )
        .toList();
  }
}
