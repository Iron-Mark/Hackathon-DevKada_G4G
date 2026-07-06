import 'package:flutter_gemma/flutter_gemma.dart';

import 'package:kudlit_ph/features/translator/data/datasources/flutter_gemma_bootstrap.dart';
import 'package:kudlit_ph/features/translator/data/datasources/gemma_model_file_type.dart';
import 'package:kudlit_ph/features/translator/data/datasources/web_gemma_model_preflight.dart';

WebGemmaModelPreflight createPlatformWebGemmaModelPreflight() {
  return const _WebGemmaModelPreflightWeb();
}

class _WebGemmaModelPreflightWeb implements WebGemmaModelPreflight {
  const _WebGemmaModelPreflightWeb();

  @override
  Future<WebGemmaModelPreflightResult> run(String modelUrl) async {
    await initializeFlutterGemma();

    final Uri uri = Uri.parse(modelUrl);
    final String fileName = uri.pathSegments.isEmpty
        ? modelUrl
        : uri.pathSegments.last;

    await FlutterGemma.installModel(
      modelType: ModelType.gemma4,
      fileType: resolveGemmaModelFileType(modelUrl),
    ).fromNetwork(modelUrl).install();

    final bool installed = await FlutterGemma.isModelInstalled(fileName);
    final InferenceModel model = await FlutterGemma.getActiveModel(
      maxTokens: 128,
    );
    final InferenceChat chat = await model.createChat(
      systemInstruction: 'Reply in plain text with exactly one word.',
    );

    final StringBuffer buffer = StringBuffer();
    try {
      await chat.addQueryChunk(Message.text(text: 'ready', isUser: true));
      await for (final ModelResponse response
          in chat.generateChatResponseAsync()) {
        if (response is TextResponse) {
          buffer.write(response.token);
          if (buffer.toString().trim().isNotEmpty) {
            break;
          }
        }
      }

      return WebGemmaModelPreflightResult(
        modelUrl: modelUrl,
        installed: installed,
        responsePreview: buffer.toString().trim(),
      );
    } finally {
      await chat.close();
      await model.close();
    }
  }
}
