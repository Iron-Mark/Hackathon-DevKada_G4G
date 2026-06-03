import 'dart:async';
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:tflite_web/tflite_web.dart';

import 'package:kudlit_ph/core/error/failures.dart';
import 'package:kudlit_ph/features/scanner/data/datasources/web_tflite_model_runtime.dart';
import 'package:kudlit_ph/features/scanner/data/datasources/web_vision_model_url_resolver.dart';
import 'package:kudlit_ph/features/scanner/data/datasources/web_yolo_output_parser.dart';
import 'package:kudlit_ph/features/scanner/domain/entities/baybayin_detection.dart';
import 'package:kudlit_ph/features/scanner/domain/failures/scanner_failures.dart';
import 'package:kudlit_ph/features/scanner/domain/repositories/baybayin_detector.dart';

const List<String> kBaybayinWebYoloLabels = <String>[
  'a',
  'e',
  'o',
  'k',
  'g',
  'ng',
  't',
  'd',
  'n',
  'p',
  'b',
  'bi',
  'bu',
  'm',
  'y',
  'l',
  'w',
  's',
  'h',
];

BaybayinDetector createPlatformWebBaybayinDetector({
  required WebVisionModelUrlResolver modelUrlResolver,
}) {
  return WebTfliteBaybayinDetector(modelUrlResolver: modelUrlResolver);
}

class WebTfliteBaybayinDetector implements BaybayinDetector {
  WebTfliteBaybayinDetector({required this.modelUrlResolver});

  final WebVisionModelUrlResolver modelUrlResolver;
  final StreamController<List<BaybayinDetection>> _detections =
      StreamController<List<BaybayinDetection>>.broadcast();
  final WebYoloOutputParser _parser = const WebYoloOutputParser(
    labels: kBaybayinWebYoloLabels,
    confidenceThreshold: 0.8,
    iouThreshold: 0.45,
    minBoxArea: 0.001,
    edgeMargin: 0.02,
  );

  TFLiteModel? _model;
  String? _loadedModelUrl;

  @override
  Stream<List<BaybayinDetection>> get detections => _detections.stream;

  @override
  Future<Either<Failure, List<BaybayinDetection>>> detectImage(
    Uint8List imageBytes,
  ) async {
    final TFLiteModel model;
    try {
      model = await _loadModel();
    } on StateError catch (e) {
      return left(ScannerFailures.init(e.message));
    } catch (e) {
      return left(ScannerFailures.init(e.toString()));
    }

    if (model.inputs.isEmpty) {
      return left(
        ScannerFailures.init('The web scanner model has no input tensor.'),
      );
    }
    final ModelTensorInfo inputInfo = model.inputs.first;
    final List<int> inputShape = resolvedWebInputShape(inputInfo.shape);
    final Tensor input = createWebImageInputTensor(
      imageBytes,
      inputShape: inputShape,
      dataType: inputInfo.dataType,
    );

    final List<Tensor> outputTensors = <Tensor>[];
    try {
      final Object rawOutput = model.predict<Object>(input);
      outputTensors.addAll(
        coerceWebOutputTensors(
          rawOutput,
          outputNames: model.outputs
              .map((ModelTensorInfo info) => info.name)
              .toList(growable: false),
        ),
      );
      final List<BaybayinDetection> detections = _parseOutputTensors(
        outputTensors,
        model,
      );
      if (!_detections.isClosed) {
        _detections.add(detections);
      }
      return right(detections);
    } on StateError catch (e) {
      return left(ScannerFailures.inference(e.message));
    } catch (e) {
      return left(ScannerFailures.inference(e.toString()));
    } finally {
      input.dispose();
      for (final Tensor tensor in outputTensors) {
        tensor.dispose();
      }
    }
  }

  List<BaybayinDetection> _parseOutputTensors(
    List<Tensor> outputTensors,
    TFLiteModel model,
  ) {
    if (outputTensors.isEmpty) {
      throw StateError('The web scanner model returned no readable outputs.');
    }

    int fallbackIndex = 0;
    for (int index = 0; index < outputTensors.length; index++) {
      final List<int>? outputShape = index < model.outputs.length
          ? model.outputs[index].shape
          : null;
      final List<double> values = webTensorValues(outputTensors[index]);
      if (_parser.canParse(values, shape: outputShape)) {
        fallbackIndex = index;
        return _parser.parse(values, shape: outputShape);
      }
    }

    final List<int>? fallbackShape = fallbackIndex < model.outputs.length
        ? model.outputs[fallbackIndex].shape
        : null;
    final List<double> fallbackValues = webTensorValues(
      outputTensors[fallbackIndex],
    );
    return _parser.parse(fallbackValues, shape: fallbackShape);
  }

  @override
  Future<Either<Failure, Uint8List?>> captureFrame() async => right(null);

  Future<TFLiteModel> _loadModel() async {
    final String? modelUrl = await modelUrlResolver();
    if (modelUrl == null || modelUrl.trim().isEmpty) {
      throw StateError('No web scanner model URL is configured.');
    }

    if (_model != null && _loadedModelUrl == modelUrl) {
      return _model!;
    }
    _model = await loadWebTfliteModel(modelUrl);
    _loadedModelUrl = modelUrl;
    return _model!;
  }

  @override
  Future<Either<Failure, Unit>> toggleTorch({required bool enabled}) async =>
      left(
        ScannerFailures.webUnsupported(
          'Torch is not available on the web scanner.',
        ),
      );

  @override
  Future<Either<Failure, Unit>> switchCamera() async => left(
    ScannerFailures.webUnsupported(
      'Camera switching is not available on the web scanner.',
    ),
  );

  @override
  Future<Either<Failure, Unit>> pauseInference() async => right(unit);

  @override
  Future<Either<Failure, Unit>> resumeInference() async => right(unit);

  @override
  void dispose() {
    _detections.close();
  }
}
