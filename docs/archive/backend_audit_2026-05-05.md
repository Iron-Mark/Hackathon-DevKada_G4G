# Backend Audit — feat/translate-update
**Date:** 2026-05-05  
**Branch:** `feat/translate-update`  
**Scope:** All modified backend & provider files — inconsistencies against CLAUDE.md rules, reliability issues, and improvement opportunities.

---

## TL;DR

The core inference pipeline is fundamentally sound. The main problems fall into three buckets:

1. **Clean Architecture violations** — controllers bypass the repository layer and route to raw datasources directly.
2. **CLAUDE.md rule violations** — `build()` overflows, no `@riverpod` codegen on several providers, computed values living in widgets.
3. **Reliability hazards** — dead method body, `_reactivateInstalledModel` triggers a redundant network re-download, fire-and-forget futures missing `unawaited()`.

---

## 1. Backend Inconsistencies

---

### I-1 — `TranslateSketchpadController` bypasses the repository layer
**File:** `lib/features/home/presentation/providers/translate_sketchpad_controller.dart`  
**Severity: High (Architecture)**

`requestFeedback()` reads `appPreferencesNotifierProvider` directly and routes to `localGemmaDatasourceProvider` or `cloudGemmaDatasourceProvider` by hand:

```dart
// controller doing routing that belongs in the repository:
final AiPreference mode = ref.read(appPreferencesNotifierProvider).value?.aiPreference ?? AiPreference.cloud;
if (!kIsWeb && mode == AiPreference.local) {
  await _analyzeLocalFirstWithCloudFallback(imageBytes, prompt: prompt);
} else {
  await _streamAnalysis(
    stream: ref.read(cloudGemmaDatasourceProvider).analyzeImage(...),
    ...
  );
}
```

`_analyzeLocalFirstWithCloudFallback` then reaches directly into both datasources. The entire purpose of `AiInferenceRepository` is to own this local-first-with-cloud-fallback logic. The controller should call `aiInferenceRepositoryProvider.analyzeImage(...)` and let the repository handle routing. Duplicating the fallback logic here means two code paths to maintain and diverge.

---

### I-2 — `ScannerEvaluationNotifier` uses two different inference paths for the same logical operation
**File:** `lib/features/scanner/presentation/providers/scanner_evaluation_provider.dart`  
**Severity: Medium (Architecture)**

```dart
// path A — imageBytes present: calls repository directly
stream = ref.read(aiInferenceRepositoryProvider).analyzeImage(imageBytes, ...);

// path B — no imageBytes: calls notifier
stream = ref.read(aiInferenceNotifierProvider.notifier).generateResponse([...]);
```

Path A bypasses `AiInferenceNotifier` entirely. Path B goes through it. These are two different entry points into the same underlying inference layer, which makes the routing rules inconsistent and harder to reason about. Both paths should go through the same entry point.

---

### I-3 — `ButtyOfflineStatus.installed` maps to a different field than `TranslateOfflineStatus.installed`
**Files:**  
- `lib/features/home/presentation/widgets/butty_chat/butty_model_mode_selector.dart`  
- `lib/features/home/presentation/providers/translate_page_controller.dart`  
**Severity: Medium (Semantic bug)**

```dart
// TranslateOfflineStatus — maps r.installed (file exists on disk)
TranslateOfflineStatus(installed: r.installed, usable: r.usable, ...)

// ButtyOfflineStatus — maps r.usable (engine is ready) to "installed"
ButtyOfflineStatus(installed: r.usable, ...)
```

The field named `installed` means two different things. In the translate screen it means "file is on disk." In the butty selector it means "engine is actually usable." A consumer reading `.installed` from each type will get different semantics. The root type `LocalGemmaReadiness` already has the right fields — both wrappers should be deleted and the screens should consume `LocalGemmaReadiness` directly.

---

### I-4 — `_reactivateInstalledModel` triggers a network download for a model already on disk
**File:** `lib/features/translator/data/datasources/local_gemma_datasource.dart:266`  
**Severity: High (Reliability / UX)**

```dart
Future<void> _reactivateInstalledModel(GemmaModelInfo model) async {
  final String? hfToken = dotenv.env['HUGGINGFACE_TOKEN'];
  await FlutterGemma.installModel(
    modelType: ModelType.gemma4,
    fileType: _modelFileTypeFor(model),
  ).fromNetwork(model.modelLink, token: hfToken).install(); // ← downloads again
}
```

This is called when `isModelInstalled()` returns `true` but `hasActiveModel()` returns `false` — meaning the file exists but the plugin's internal active-model pointer is stale. The fix should activate the already-present file without a network call. If `flutter_gemma` has no activation-without-download API, the fallback should be `getActiveModel()` directly (since the file is confirmed present) and let the plugin load from disk. Downloading over an existing file wastes bandwidth and can take minutes on a slow connection.

---

### I-5 — `_assertLlmModel` is an empty method body
**File:** `lib/features/translator/data/datasources/local_gemma_datasource.dart:261`  
**Severity: Low (Dead code)**

```dart
void _assertLlmModel(GemmaModelInfo model) {
  // GemmaModelInfo is always an LLM model by definition.
  // This guard exists for future AiModelInfo migration.
}
```

The method does nothing. The comment justifies it by citing a hypothetical future migration — exactly the kind of forward-planning CLAUDE.md prohibits ("Don't design for hypothetical future requirements"). Remove the method and its call site.

---

### I-6 — Several providers use non-codegen syntax, violating CLAUDE.md
**Severity: Medium (Consistency)**

CLAUDE.md requires `@riverpod` codegen for all providers. These use manual syntax instead:

| Provider | File | Manual Form Used |
|---|---|---|
| `scannerEvaluationProvider` | `scanner_evaluation_provider.dart` | `NotifierProvider(...)` |
| `translatePageControllerProvider` | `translate_page_controller.dart` | `NotifierProvider(...)` |
| `translateSketchpadControllerProvider` | `translate_sketchpad_controller.dart` | `NotifierProvider(...)` |
| `modelSetupControllerProvider` | `model_setup_controller.dart` | `NotifierProvider(...)` |
| `translateOfflineStatusProvider` | `translate_page_controller.dart` | `FutureProvider(...)` |
| `buttyOfflineStatusProvider` | `butty_model_mode_selector.dart` | `FutureProvider(...)` |
| `yoloModelSelectionProvider` | `yolo_model_selection_provider.dart` | `AsyncNotifierProvider(...)` |
| `availableYoloModelsProvider` | `yolo_model_selection_provider.dart` | `FutureProvider(...)` |
| `yoloModelPathProvider` | `yolo_model_selection_provider.dart` | `FutureProvider.family(...)` |
| `yoloDrawingPadModelProvider` | `yolo_model_selection_provider.dart` | `FutureProvider(...)` |

The codegen providers (`@riverpod`) and manual providers (`FutureProvider(...)`) have different keepAlive semantics by default and mixing them makes the lifecycle harder to reason about.

---

### I-7 — `GemmaPrompts.translatorMode` and `teacherMode` are unreferenced dead code
**File:** `lib/features/learning/domain/entities/gemma_prompts.dart`  
**Severity: Low (Dead code)**

`translatorMode` (line 11) and `teacherMode` (line 21) are defined as constants but no provider or controller in the modified files references them. `scanTranslatorMode()` and `assistantMode` are the active prompts. If these two are legacy stubs for a feature not yet wired in, they should be removed until they're needed.

---

### I-8 — Fire-and-forget futures without `unawaited()` in `ScannerEvaluationNotifier`
**File:** `lib/features/scanner/presentation/providers/scanner_evaluation_provider.dart:97,129`  
**Severity: Low (Code clarity)**

```dart
// evaluate():
_listenToTranslation(stream);  // Future<void> silently discarded

// requestFollowUp():
_listenToFollowUp(stream);  // same
```

`AiInferenceNotifier` correctly uses `unawaited(...)` in the same situation. These calls should do the same to signal the fire-and-forget intent and keep the analyzer quiet.

---

## 2. CLAUDE.md Rule Violations

---

### R-1 — `TranslateScreen.build()` is ~136 lines (limit: 40)
**File:** `lib/features/home/presentation/screens/translate_screen.dart:21`  
**Severity: High**

The entire method from `@override Widget build(...)` to its closing brace spans ~136 lines. The header section alone (title text, subtitle, banner, mode switch) could be a `_TranslateHeader` widget. Each mode panel is already extracted — the issue is the inlined header and the dense conditional argument construction.

---

### R-2 — Derived values computed inside `TranslateScreen.build()`
**File:** `lib/features/home/presentation/screens/translate_screen.dart:40-53`  
**Severity: Medium**

```dart
// These belong in a provider, not build():
final bool offlinePending = mode == AiPreference.local && offlineStatus.isLoading;
final bool offlineUnavailable = mode == AiPreference.local && !offlineStatus.isLoading && !(offlineStatus.value?.usable ?? false);
final bool aiActionsEnabled = !offlinePending && !offlineUnavailable;
final String? disabledReason = switch (mode) { ... };
```

CLAUDE.md: "Computed/derived values belong in a provider, not in `build()`." These should be a selector or a `TranslatePageController` getter that the widget simply reads.

---

### R-3 — `_renderSketchAsPng` is image-processing logic inside a Notifier
**File:** `lib/features/home/presentation/providers/translate_sketchpad_controller.dart:179`  
**Severity: Medium**

Eighty lines of `Canvas`, `PictureRecorder`, coordinate math, and PNG encoding inside a Riverpod `Notifier`. This is pure, stateless utility logic — it has no dependency on provider state — and belongs in a top-level function in `core/utils/` or a dedicated service. It's also untestable in its current location because it can't be exercised without a full Riverpod/Flutter test harness.

---

## 3. Improvements

---

### P-1 — Delete `TranslateOfflineStatus` and `ButtyOfflineStatus`; use `LocalGemmaReadiness` directly
Both wrappers add zero information over `LocalGemmaReadiness` (and I-3 above shows they already map fields incorrectly). Deleting them removes ~30 lines of boilerplate and one class of semantic confusion. Both widgets can watch `localModelReadinessProvider` directly.

---

### P-2 — `_kRequiredConsecutiveHits` at 2 hits × 250ms = 500ms minimum glyph latency
**File:** `lib/features/scanner/presentation/widgets/scanner_camera.dart:39`

The current combination requires a character to appear in two consecutive 250ms windows before it's shown. That's a minimum 500ms from detection to overlay. For a live scanner this is noticeable — the user tends to move the camera before the box renders. Reducing to `_kRequiredConsecutiveHits = 1` cuts the latency to ~250ms. The single-frame phantom problem is already mitigated by the area and edge filters; the consecutive-hit filter is now over-conservative.

If phantoms do increase, consider a "dim box on first hit, full opacity on second hit" approach that gives instant feedback without committing to a label.

---

### P-3 — `ModelNotReadyScreen` loading state has no progress indicator
**File:** `lib/features/scanner/presentation/widgets/model_not_ready_screen.dart`

The loading variant shows a spinner with the copy "Loading the Baybayin recognition model…" but no progress %. `YoloModelCache.download()` already exposes a `void Function(int progress)?` callback. A secondary `StreamProvider` fed by that callback (similar to the Gemma download flow) would let the scanner show `42% — Downloading scanner model` instead of a dead spinner.

---

### P-4 — `GemmaPrompts.sketchpadEvaluator` is not used in `TranslateSketchpadController`
**File:** `lib/features/home/presentation/providers/translate_sketchpad_controller.dart:87`

The controller builds its own inline prompt:
```dart
final String prompt =
    'Evaluate this Baybayin sketch for target "${state.target.trim()}". '
    'Start with encouragement, then one concrete stroke tip.';
```

`GemmaPrompts.sketchpadEvaluator(target)` exists for exactly this purpose and includes the `<think>...</think>` structured reasoning the other evaluation paths use. Wiring the controller to use the shared prompt constant ensures consistency across all feedback surfaces and makes prompt iteration easier.

---

### P-5 — Introduce `AiInferenceRepository.analyzeImage()` as the single image-inference entry point
Currently `TranslateSketchpadController` and `ScannerEvaluationNotifier` both reach into the datasource layer directly for image analysis. The repository already has `generateResponse()` as the single text-inference entry point. Adding an `analyzeImage()` method to `AiInferenceRepository` (with local-first + cloud-fallback routing inside) would eliminate both bypasses and consolidate the fallback logic in one place.

---

## 4. Prioritized Fix Order

| Priority | Issue | File(s) | Effort |
|---|---|---|---|
| P0 | I-4 — `_reactivateInstalledModel` re-downloads model already on disk | `local_gemma_datasource.dart` | Small |
| P0 | I-3 — `installed` field maps different things in the two wrapper types | `translate_page_controller.dart`, `butty_model_mode_selector.dart` | Small |
| P0 | R-1 — `TranslateScreen.build()` 136 lines, extract header widget | `translate_screen.dart` | Small |
| P1 | I-1 — Sketchpad controller bypasses repository for image analysis | `translate_sketchpad_controller.dart` | Medium |
| P1 | I-2 — Scanner eval uses two different inference paths | `scanner_evaluation_provider.dart` | Medium |
| P1 | R-2 — Derived values computed in `build()` | `translate_screen.dart` | Small |
| P1 | P3 — Extract `_renderSketchAsPng` to `core/utils/` | `translate_sketchpad_controller.dart` | Small |
| P2 | P-4 — Use `GemmaPrompts.sketchpadEvaluator` in sketchpad controller | `translate_sketchpad_controller.dart` | Trivial |
| P2 | I-8 — Wrap fire-and-forget futures with `unawaited()` | `scanner_evaluation_provider.dart` | Trivial |
| P2 | I-5 — Remove empty `_assertLlmModel` body | `local_gemma_datasource.dart` | Trivial |
| P2 | I-7 — Remove dead `translatorMode`/`teacherMode` constants | `gemma_prompts.dart` | Trivial |
| P3 | P-2 — Reduce `_kRequiredConsecutiveHits` to 1 at 250ms | `scanner_camera.dart` | Trivial |
| P3 | P-3 — Wire download progress to `ModelNotReadyScreen` loading state | `scanner_camera.dart`, model cache | Medium |
| P3 | I-6 — Migrate remaining manual providers to `@riverpod` codegen | multiple files | Large |
| P3 | P-5 — Add `analyzeImage()` to `AiInferenceRepository` interface | repo interface + impl | Medium |

---

## 5. What Is Working Well (Do Not Change)

- **`localModelReadinessProvider` shared across both screens** — correct fix for the duplicate-probe problem.
- **`aiInferenceRepositoryProvider` not watching preferences** — the `preferenceResolver` callback pattern is the right fix for the reconnect bug.
- **`probeReadiness` mutex** — `_probing` / `_pendingProbe` coalescing is correct.
- **`ensureModelLoaded()` called after download** — pre-warming after `AiReady` transition is the right place.
- **`ref.keepAlive()` in `yoloModelPathProvider` and `availableYoloModelsProvider`** — both are correctly kept alive after resolution.
- **`yoloDrawingPadModelProvider` eager load + keepAlive** — lesson drawing pad has zero cold-start latency. Camera scope should mirror this.
- **`GemmaPrompts.parseThinkBlock()`** — clean parser, well-placed in the domain entity.
- **`ModelNotReadyScreen` loading / error split** — two-constructor pattern correctly differentiates states.
- **Temporal smoothing at 250ms** — interval is correct; only `_kRequiredConsecutiveHits` is the problem (see P-2).
