import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:tflite_web/tflite_web.dart';

Future<void> ensureTfliteWebInitialized() async {
  await TFLiteWeb.initializeUsingCDN();
}

Future<void> validateWebTfliteModelUrl(String modelUrl) async {
  final Uri uri = Uri.parse(modelUrl);
  final http.Response response = await http
      .head(uri)
      .timeout(const Duration(seconds: 12));
  if (response.statusCode == 404) {
    throw StateError('Scanner model URL returned HTTP 404: $modelUrl');
  }
  if (response.statusCode >= 400) {
    throw StateError(
      'Scanner model URL returned HTTP ${response.statusCode}: $modelUrl',
    );
  }
}

Future<TFLiteModel> loadWebTfliteModel(String modelUrl) async {
  await ensureTfliteWebInitialized();
  await validateWebTfliteModelUrl(modelUrl);
  return TFLiteModel.fromUrl(modelUrl).timeout(const Duration(seconds: 25));
}

List<int> resolvedWebInputShape(List<int>? shape) {
  if (shape == null || shape.length != 4) {
    return const <int>[1, 640, 640, 3];
  }
  return shape.map((int value) => value <= 0 ? 1 : value).toList();
}

int webInputWidth(List<int> shape) {
  if (shape[1] == 3) return shape[3];
  return shape[2];
}

int webInputHeight(List<int> shape) {
  if (shape[1] == 3) return shape[2];
  return shape[1];
}

Tensor createWebImageInputTensor(
  Uint8List bytes, {
  required List<int> inputShape,
  required TFLiteDataType dataType,
}) {
  final int width = webInputWidth(inputShape);
  final int height = webInputHeight(inputShape);
  final img.Image? decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw StateError('The captured webcam frame could not be decoded.');
  }
  final img.Image resized = img.copyResize(
    img.bakeOrientation(decoded),
    width: width,
    height: height,
    interpolation: img.Interpolation.linear,
  );

  switch (dataType) {
    case TFLiteDataType.float32:
      final Float32List input = Float32List(width * height * 3);
      int offset = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final img.Pixel pixel = resized.getPixel(x, y);
          input[offset++] = pixel.r / 255.0;
          input[offset++] = pixel.g / 255.0;
          input[offset++] = pixel.b / 255.0;
        }
      }
      return Tensor(input, shape: inputShape, type: dataType);
    case TFLiteDataType.int32:
      final Int32List input = Int32List(width * height * 3);
      int offset = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final img.Pixel pixel = resized.getPixel(x, y);
          input[offset++] = pixel.r.toInt();
          input[offset++] = pixel.g.toInt();
          input[offset++] = pixel.b.toInt();
        }
      }
      return Tensor(input, shape: inputShape, type: dataType);
    default:
      throw StateError(
        'The web scanner model expects unsupported input type '
        '"${dataType.name}".',
      );
  }
}

Tensor createWebSmokeTestTensor({
  required List<int> inputShape,
  required TFLiteDataType dataType,
}) {
  final int elementCount = inputShape.fold<int>(
    1,
    (int total, int value) => total * value,
  );
  final Object data = switch (dataType) {
    TFLiteDataType.float32 => Float32List(elementCount),
    TFLiteDataType.int32 => Int32List(elementCount),
    TFLiteDataType.bool => List<bool>.filled(elementCount, false),
    TFLiteDataType.string => List<String>.filled(elementCount, ''),
    TFLiteDataType.complex64 => throw StateError(
      'The web scanner smoke test does not support complex64 inputs.',
    ),
  };
  return Tensor(data, shape: inputShape, type: dataType);
}

List<Tensor> coerceWebOutputTensors(
  Object rawOutput, {
  List<String> outputNames = const <String>[],
}) {
  // ignore: invalid_runtime_check_with_js_interop_types
  if (rawOutput is Tensor) {
    return <Tensor>[rawOutput];
  }
  if (rawOutput is List) {
    return rawOutput.whereType<Tensor>().toList(growable: false);
  }
  if (outputNames.isNotEmpty) {
    try {
      final NamedTensorMap namedOutputs = rawOutput as NamedTensorMap;
      return outputNames
          .map((String name) => namedOutputs[name])
          .toList(growable: false);
    } catch (_) {
      return const <Tensor>[];
    }
  }
  return const <Tensor>[];
}

List<double> webTensorValues(Tensor tensor) {
  final Object raw = tensor.dataSync<Object>();
  if (raw is Float32List) {
    return raw.toList(growable: false);
  }
  if (raw is Float64List) {
    return raw.toList(growable: false);
  }
  if (raw is Int32List) {
    return raw.map((int value) => value.toDouble()).toList(growable: false);
  }
  if (raw is List) {
    return raw
        .whereType<num>()
        .map((num value) => value.toDouble())
        .toList(growable: false);
  }
  throw StateError('The web scanner model returned an unreadable tensor.');
}
