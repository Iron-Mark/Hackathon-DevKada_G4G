import 'package:meta/meta.dart';

/// Distinguishes the inference engine a model is built for.
///
/// - [llm]: offline chatbot via flutter_gemma / MediaPipe LlmInference.
/// - [vision]: YOLO OCR detection model (TFLite on Android, mlpackage on iOS).
enum ModelKind { llm, vision }

/// Metadata describing an available Baybayin AI model.
///
/// Mirrors the `public.baybayin_models` row in Supabase.
@immutable
class AiModelInfo {
  const AiModelInfo({
    required this.id,
    required this.name,
    required this.modelLink,
    required this.sortOrder,
    required this.version,
    required this.enabled,
    this.modelType = ModelKind.llm,
    this.description,
    this.androidModelLink,
    this.iosModelLink,
  });

  /// Stable Supabase row id (uuid).
  final String id;

  /// Human-readable name (e.g. "Gemma 4 E2B").
  final String name;

  /// Generic download URL — used when no platform-specific link is set.
  final String modelLink;

  /// Android-specific download URL. Overrides [modelLink] on Android.
  final String? androidModelLink;

  /// iOS-specific download URL. Overrides [modelLink] on iOS.
  final String? iosModelLink;

  /// Lower number = higher rank (more powerful).
  final int sortOrder;

  /// Optional marketing/description copy.
  final String? description;

  /// Monotonic version of the published model assets. Bumping this server-side
  /// forces the client to redownload the local cache.
  final int version;

  /// When false, the model is hidden from in-app selectors. Existing local
  /// downloads are left in place.
  final bool enabled;

  /// Inference engine this model targets.
  ///
  /// [ModelKind.llm] → flutter_gemma / MediaPipe LlmInference (Butty chatbot).
  /// [ModelKind.vision] → YOLO TFLite / mlpackage (OCR / camera pipeline).
  final ModelKind modelType;

  /// Filename derived from [modelLink], used by `flutter_gemma`
  /// to check whether the model is already installed locally.
  String get fileName {
    final Uri uri = Uri.parse(modelLink);
    final String last = uri.pathSegments.isEmpty
        ? modelLink
        : uri.pathSegments.last;
    return last.isEmpty ? modelLink : last;
  }
}
