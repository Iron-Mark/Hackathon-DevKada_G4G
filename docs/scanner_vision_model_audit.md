# KudVis 1 Turbo - Scanner Vision Model Loading Audit

Date: 2026-05-04
Last reviewed: 2026-05-10
Status: Active backlog, partially implemented

This audit tracks native scanner model loading, readiness states, and camera
inference latency. It is still useful as an implementation backlog, but several
original findings have already been fixed in code.

## Current State

Implemented since the original audit:

- `availableYoloModelsProvider` keeps the model catalog alive after successful
  fetches.
- `yoloModelPathProvider(scope)` keeps resolved local model paths alive after a
  successful cache/download check.
- Camera-scope path prewarm exists after first model setup download.
- `ModelNotReadyScreen` no longer shows a static future-update placeholder for
  both loading and error states; it now has a loading state and a retryable
  error state.
- `_kDetectionInterval` is now `250ms`.
- `_kConfidenceThreshold` is `0.8` and the comment matches that value.
- `_ScanningIndicator` is not present in the current scanner code.
- Native scan-tab model downloads now surface measured download percentage in
  `ModelNotReadyScreen` when the HTTP response reports content length.
- Missing scanner-model configuration now has a distinct setup-oriented error
  title and points users to `Settings > AI models`.
- Missing scanner-model configuration now includes a direct `Open AI models`
  action that navigates to Settings/model setup, plus a retry action.
- Settings now frames AI models as a local setup destination and the manual
  vision-model download path prewarms the camera model provider after install.

Still open:

- `_kRequiredConsecutiveHits` remains `2`, so the current `250ms` throttle still
  requires roughly `500ms` before non-empty detections surface.

## Active Backlog

### P0 - Add Scanner-Tab Download Progress

Status: Implemented for native scanner path resolution. The scan tab now watches
camera-scope YOLO download progress and renders a percentage with a linear
indicator while `yoloModelPathProvider(YoloModelScope.camera)` downloads.

Implementation direction:

- Add a camera-scope progress source near `YoloModelCache` or the scanner model
  provider layer.
- Pass the `onProgress` callback into `YoloModelCache.download()` from
  `yoloModelPathProvider(YoloModelScope.camera)`.
- Render percentage and a linear progress indicator in `ModelNotReadyScreen`
  when progress is available.

Acceptance:

- First scanner open during model download shows progress, not only a spinner.
- Failed downloads still render the retryable error state.

### P0 - Add Not-Installed / Empty-Catalog State

Status: Implemented for the native scanner unavailable state. Empty catalog and
missing platform URL now render a setup-oriented scanner error with direct
navigation to Settings/model setup.

Implementation direction:

- Treat an empty enabled catalog as a user-actionable unavailable state.
- Show clear copy and an action path to model setup/settings where available.
- Keep network/download failures as retryable errors.

Acceptance:

- Empty catalog, missing platform URL, and interrupted download do not all look
  identical.
- The user gets either a retry action or a setup/settings action.

### P1 - Prewarm Camera Scope After Manual Settings Download

Status: Implemented. First-run setup and manual Settings downloads now prewarm
the camera model path after downloading a vision model.

Implementation direction:

- After a successful `VisionDownloadTile` download, read
  `yoloModelPathProvider(YoloModelScope.camera).future` in a fire-and-forget
  guarded call.
- Keep failures non-fatal and visible only through existing scan-tab retry
  behavior.

Acceptance:

- Manual model downloads reduce scanner cold-start delay the same way first-run
  setup does.

### P1 - Decide Detection Smoothing Latency

Detection output is throttled to `250ms`, but `_kRequiredConsecutiveHits = 2`.
This is safer against transient false positives but introduces about `500ms`
before detections surface.

Implementation direction:

- Choose one product behavior:
  - keep `2` hits for conservative scanner stability, or
  - reduce to `1` hit for faster feedback after QA confirms false positives are
    acceptable.
- If changed, verify scanner overlay behavior with real model/device testing.

Acceptance:

- The chosen hit count is documented in the code comment.
- Camera QA confirms overlay behavior is acceptable.

## Reference Files

- `lib/features/scanner/presentation/providers/yolo_model_selection_provider.dart`
- `lib/features/scanner/data/datasources/yolo_model_cache.dart`
- `lib/features/scanner/presentation/widgets/model_not_ready_screen.dart`
- `lib/features/scanner/presentation/widgets/scanner_camera.dart`
- `lib/features/home/presentation/providers/model_setup_controller.dart`
- `lib/features/home/presentation/widgets/settings/vision_download_tile.dart`

## Already Verified Elsewhere

Scan layout overlap and camera-status transition rendering are tracked by the
strict artifact pass:

- `qa-artifact/scan-layout-strict-overlap/report.json`
- `qa-artifact/scan-layout-strict-overlap/scan-layout-overlap-contact-sheet.html`

That verification covers layout clipping/overlap. It does not prove native
YOLO runtime behavior, download progress, or on-device camera latency.
