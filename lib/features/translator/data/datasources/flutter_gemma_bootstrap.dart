import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_gemma/core/domain/web_storage_mode.dart';

Future<void> initializeFlutterGemma({String? huggingFaceToken}) async {
  final String? normalizedToken = huggingFaceToken?.trim().isEmpty ?? true
      ? null
      : huggingFaceToken?.trim();

  await FlutterGemma.initialize(
    huggingFaceToken: normalizedToken,
    webStorageMode: WebStorageMode.cacheApi,
  );
}
