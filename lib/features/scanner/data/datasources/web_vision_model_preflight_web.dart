import 'package:tflite_web/tflite_web.dart';

import 'package:kudlit_ph/features/scanner/data/datasources/web_tflite_model_runtime.dart';
import 'package:kudlit_ph/features/scanner/data/datasources/web_vision_model_preflight.dart';

WebVisionModelPreflight createPlatformWebVisionModelPreflight() {
  return const _WebVisionModelPreflightWeb();
}

class _WebVisionModelPreflightWeb implements WebVisionModelPreflight {
  const _WebVisionModelPreflightWeb();

  @override
  Future<WebVisionModelPreflightResult> run(String modelUrl) async {
    final TFLiteModel model = await loadWebTfliteModel(modelUrl);
    if (model.inputs.isEmpty) {
      throw StateError('The web scanner model has no input tensor.');
    }

    final List<int> inputShape = resolvedWebInputShape(
      model.inputs.first.shape,
    );
    final Tensor input = createWebSmokeTestTensor(
      inputShape: inputShape,
      dataType: model.inputs.first.dataType,
    );
    final List<Tensor> outputs = <Tensor>[];

    try {
      final Object rawOutput = model.predict<Object>(input);
      outputs.addAll(
        coerceWebOutputTensors(
          rawOutput,
          outputNames: model.outputs
              .map((ModelTensorInfo info) => info.name)
              .toList(growable: false),
        ),
      );
      return WebVisionModelPreflightResult(
        modelUrl: modelUrl,
        inputShape: inputShape,
        outputShapes: model.outputs
            .map((ModelTensorInfo info) => info.shape ?? const <int>[])
            .toList(growable: false),
      );
    } finally {
      input.dispose();
      for (final Tensor tensor in outputs) {
        tensor.dispose();
      }
    }
  }
}
