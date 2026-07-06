import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kudlit_ph/features/home/presentation/providers/profile_management_provider.dart';
import 'package:kudlit_ph/features/learning/domain/entities/glyph_entry.dart';
import 'package:kudlit_ph/features/learning/domain/entities/glyph_stroke.dart';

part 'character_gallery_provider.g.dart';

@riverpod
Future<List<GlyphEntry>> characterGallery(Ref ref) async {
  final SupabaseClient client = ref.watch(supabaseProvider);

  final List<Map<String, dynamic>> stepRows = await client
      .from('lesson_steps')
      .select('glyph, label, lesson_id')
      .eq('mode', 'reference')
      .order('lesson_id')
      .order('sort_order');

  final Set<String> seen = <String>{};
  final List<Map<String, dynamic>> unique = <Map<String, dynamic>>[];
  for (final Map<String, dynamic> row in stepRows) {
    final String glyph = row['glyph'] as String;
    if (seen.add(glyph)) unique.add(row);
  }

  final List<String> glyphs = unique
      .map((Map<String, dynamic> r) => r['glyph'] as String)
      .toList();
  final Map<String, StrokeOrderData> strokeOrders = await _fetchStrokeOrders(
    client,
    glyphs,
  );

  return unique
      .map((Map<String, dynamic> row) {
        final String glyph = row['glyph'] as String;
        final String lessonId = (row['lesson_id'] as String?) ?? '';
        return GlyphEntry(
          glyph: glyph,
          label: (row['label'] as String?) ?? glyph,
          group: _groupFromLessonId(lessonId),
          strokeOrder: strokeOrders[glyph],
        );
      })
      .toList(growable: false);
}

Future<Map<String, StrokeOrderData>> _fetchStrokeOrders(
  SupabaseClient client,
  List<String> glyphs,
) async {
  if (glyphs.isEmpty) return const <String, StrokeOrderData>{};
  try {
    final List<Map<String, dynamic>> rows = await client
        .from('stroke_patterns')
        .select('glyph, strokes, canvas_width, canvas_height')
        .inFilter('glyph', glyphs)
        .order('created_at', ascending: false);

    final Map<String, StrokeOrderData> result = <String, StrokeOrderData>{};
    for (final Map<String, dynamic> row in rows) {
      final String glyph = row['glyph'] as String;
      if (result.containsKey(glyph)) continue;
      final double w = (row['canvas_width'] as num?)?.toDouble() ?? 1.0;
      final double h = (row['canvas_height'] as num?)?.toDouble() ?? 1.0;
      final double aspect = (w > 0 && h > 0) ? w / h : 1.0;
      final List<dynamic> rawStrokes =
          (row['strokes'] as List<dynamic>?) ?? const <dynamic>[];
      final List<GlyphStroke> strokes = rawStrokes
          .cast<Map<String, dynamic>>()
          .map(GlyphStroke.fromJson)
          .toList(growable: false);
      result[glyph] = StrokeOrderData(strokes: strokes, aspectRatio: aspect);
    }
    return result;
  } catch (_) {
    return const <String, StrokeOrderData>{};
  }
}

String _groupFromLessonId(String lessonId) {
  if (lessonId.contains('vowel')) return 'Vowels';
  if (lessonId.contains('kudlit')) return 'Kudlit';
  return 'Consonants';
}
