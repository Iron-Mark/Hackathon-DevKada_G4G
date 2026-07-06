import 'package:meta/meta.dart';

@immutable
class TranslationResult {
  const TranslationResult({
    this.id,
    required this.inputText,
    required this.baybayinText,
    required this.latinText,
    required this.direction,
    required this.aiResponse,
    required this.isBookmarked,
    required this.timestamp,
  });

  final int? id;
  final String inputText;
  final String baybayinText;
  final String latinText;
  final String direction;
  final String aiResponse;
  final bool isBookmarked;
  final DateTime timestamp;

  TranslationResult copyWith({
    int? id,
    bool? isBookmarked,
    String? aiResponse,
  }) {
    return TranslationResult(
      id: id ?? this.id,
      inputText: inputText,
      baybayinText: baybayinText,
      latinText: latinText,
      direction: direction,
      aiResponse: aiResponse ?? this.aiResponse,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      timestamp: timestamp,
    );
  }
}
