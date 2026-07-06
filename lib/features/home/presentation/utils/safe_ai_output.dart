const int _maxAssistantOutputLength = 4000;

final RegExp _finalAnswerLabelPattern = RegExp(
  r'^\s*(?:final\s+(?:answer|response|output)|assistant\s+answer|answer)\s*[:\-]\s*',
  caseSensitive: false,
  multiLine: true,
);

final RegExp _internalLabelPattern = RegExp(
  r'^\s*(?:[-*•]|\d+[.)])?\s*(?:[*_]{1,2})?\s*(?:'
  r'question|subject|character|'
  r'user\s+(?:asks|question|prompt|input|message)|'
  r'(?:character|target)\s+persona|persona|'
  r'system\s+(?:instruction|prompt|message)|'
  r'developer\s+(?:instruction|prompt|message)|'
  r'goal|topic|role|tone|style|voice|'
  r'persona\s*\/\s*tone|spirited\s*\/\s*passionate|'
  r'prompt|instruction|instructions|'
  r'draft(?:\s+\d+)?|idea(?:\s+\d+)?|'
  r'option(?:\s+\d+)?(?:\s*\([^)]*\))?|'
  r'refining|revision|reasoning|thinking|analysis|'
  r'output\s+(?:requirements|format|constraints)|'
  r'constraint|constraints|context|task'
  r')\s*(?:[*_]{1,2})?\s*[:\-]\s*',
  caseSensitive: false,
);

final RegExp _draftLikeLabelPattern = RegExp(
  r'^\s*(?:[-*•]|\d+[.)])?\s*(?:[*_]{1,2})?\s*(?:'
  r'draft(?:\s+\d+)?|idea(?:\s+\d+)?|'
  r'option(?:\s+\d+)?(?:\s*\([^)]*\))?|'
  r'refining|revision|reasoning|thinking|analysis'
  r')\s*(?:[*_]{1,2})?\s*[:\-]\s*',
  caseSensitive: false,
);

final RegExp _leadingPromptEchoPattern = RegExp(
  r'^(?:["“].{1,160}\?["”]?|butty\s*\(.{1,240}\)\.?)$',
  caseSensitive: false,
);

/// Returns only the final answer section when a model exposes draft scaffolding.
String extractFinalAnswer(String raw) {
  final String normalized = _normalizeNewlines(raw).trim();
  if (normalized.isEmpty) {
    return '';
  }

  final List<RegExpMatch> matches = _finalAnswerLabelPattern
      .allMatches(normalized)
      .toList(growable: false);
  if (matches.isEmpty) {
    return _normalizeVisibleText(normalized);
  }

  return _normalizeVisibleText(normalized.substring(matches.last.end));
}

/// Removes model prompt scaffolding before assistant text reaches the UI.
///
/// Note: `<baybayin>…</baybayin>` tags are intentionally preserved — they are
/// rendered by [BaybayinChatRenderer] in the bubble widget.
String cleanAssistantOutput(String raw) {
  final String extracted = extractFinalAnswer(raw);
  final List<String> cleanedLines = <String>[];
  bool skippingScaffoldBlock = false;

  for (final String line in _normalizeNewlines(extracted).split('\n')) {
    final String trimmed = line.trim();
    if (trimmed.isEmpty) {
      skippingScaffoldBlock = false;
      if (cleanedLines.isNotEmpty && cleanedLines.last.isNotEmpty) {
        cleanedLines.add('');
      }
      continue;
    }

    if (cleanedLines.isEmpty && _leadingPromptEchoPattern.hasMatch(trimmed)) {
      continue;
    }

    if (_draftLikeLabelPattern.hasMatch(trimmed) && cleanedLines.isNotEmpty) {
      break;
    }

    if (_internalLabelPattern.hasMatch(trimmed)) {
      skippingScaffoldBlock = true;
      final String remainder = trimmed.replaceFirst(_internalLabelPattern, '');
      if (remainder.trim().isNotEmpty) {
        skippingScaffoldBlock = false;
      }
      continue;
    }

    if (skippingScaffoldBlock) {
      continue;
    }

    skippingScaffoldBlock = false;
    cleanedLines.add(trimmed.replaceAll(RegExp(r'[ \t]+'), ' '));
  }

  final String cleaned = _normalizeVisibleText(cleanedLines.join('\n'));
  if (cleaned.length <= _maxAssistantOutputLength) {
    return cleaned;
  }

  return '${cleaned.substring(0, _maxAssistantOutputLength - 3).trimRight()}...';
}

String _normalizeNewlines(String value) {
  return value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
}

String _normalizeVisibleText(String value) {
  return _normalizeNewlines(value)
      .split('\n')
      .map((String line) => line.trim().replaceAll(RegExp(r'[ \t]+'), ' '))
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
