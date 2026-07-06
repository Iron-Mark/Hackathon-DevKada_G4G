import 'package:flutter_gemma/flutter_gemma.dart';

ModelFileType resolveGemmaModelFileType(String modelUrl) {
  final Uri uri = Uri.parse(modelUrl);
  final String fileName = uri.pathSegments.isEmpty
      ? modelUrl
      : uri.pathSegments.last;
  final String lower = fileName.toLowerCase();

  if (lower.endsWith('.litertlm')) {
    return ModelFileType.litertlm;
  }
  return ModelFileType.task;
}
