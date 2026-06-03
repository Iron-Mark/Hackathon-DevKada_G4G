# 02 — Multiplatform parity (Android / iOS / Web)
**Auditor:** general-purpose (multiplatform lane) · **Skill invoked:** none · **Date:** 2026-05-14

## Summary
- P0 count: 3 · P1 count: 5 · P2 count: 4
- Single biggest risk: Web build silently loses live YOLO accuracy, torch/flash, gallery picker file-system bytes, and Supabase password-reset deep linking — multiple core flows are degraded on the web build but presented to the user with the same UI affordances as mobile.

## Parity Matrix
| Feature | Android | iOS | Web | Notes |
| --- | --- | --- | --- | --- |
| Camera live preview | ✅ Native `YOLOView` via `ultralytics_yolo` (`lib/features/scanner/presentation/widgets/scanner_camera.dart:358`) | ✅ Same `YOLOView` (`scanner_camera.dart:358`) | ⚠ `_WebCameraPreview` uses `camera` plugin (`scanner_camera.dart:320`) — different code path, no live YOLO overlay; user has to capture a frame. |
| Torch / flash | ✅ `detector.toggleTorch` → `_controller.setTorchMode` (`yolo_baybayin_detector.dart:149`) | ✅ Same | ❌ Flash toggle hidden on web (`scan_tab.dart:300`, `:343`) — no API path; getUserMedia torch unsupported. |
| Switch camera | ✅ `YOLOViewController.switchCamera` (`yolo_baybayin_detector.dart:153`) | ✅ Same | ⚠ Routed through `_webSwitchCamera` callback (`scan_tab.dart:192-198`); falls back to "Only one camera available" if browser exposes <2 devices (`scan_tab.dart:424`). |
| Local Gemma inference | ✅ `flutter_gemma` via `LocalGemmaDatasource` | ✅ Same | ❌ Image analysis explicitly throws on web (`local_gemma_datasource.dart:210`); text generate routed cloud-only (`ai_inference_repository_impl.dart:141`). |
| Cloud Gemma inference | ✅ `cloudDatasource.generate` (`ai_inference_repository_impl.dart:81-89`) | ✅ Same | ✅ Same — `kIsWeb` forces this branch (`ai_inference_repository_impl.dart:141`). |
| YOLO inference — live | ✅ `YOLOView` GPU off (`yolo_baybayin_detector.dart:120`) | ✅ Same | ⚠ `web_tflite_baybayin_detector.dart` via JS interop conditional import (`web_baybayin_detector_factory.dart:1-2`) — only runs on captured frame, not live stream. |
| YOLO inference — still image | ✅ `yolo.predict(...)` (`yolo_baybayin_detector.dart:68`) | ✅ Same | ⚠ Web TFLite path (`web_tflite_baybayin_detector.dart`, parser at `web_yolo_output_parser.dart`). |
| Vision model fetch (preflight) | ✅ `YoloModelCache.download` to filesystem (`vision_download_tile.dart:36-47`) | ✅ Same | ⚠ `createWebVisionModelPreflight().run(...)` (browser caches/IndexedDB) (`vision_download_tile.dart:33-34`, `web_vision_model_preflight_web.dart`). |
| Google OAuth deep link | ✅ `redirectTo: 'kudlit://auth/reset'` (`supabase_auth_datasource.dart:85-87`) | ✅ Same | ⚠ `${Uri.base.origin}/auth/reset` — origin-relative; depends on Site URL config and a `/auth/reset` route handler. |
| Phone OTP | ✅ `signInWithOtp(phone:)` (`supabase_auth_datasource.dart:106`) | ✅ Same | ✅ Same code path, no `kIsWeb` guard. |
| Password reset deep link | ✅ `kudlit://auth/reset` (`supabase_auth_datasource.dart:179`) | ✅ Same | ❌ `redirectTo: null` falls back to Supabase Site URL (`supabase_auth_datasource.dart:179`) — no app-side deep-link handler; user is redirected to whatever Site URL is configured. |
| Gallery picker | ✅ `image_picker` (`scan_tab_controller.dart:151-158`) | ✅ Same | ⚠ `image_picker` web returns blob; `readAsBytes()` works but no permission UX, no folder picker. |
| SQLite cache | ✅ `sqflite` (`sqlite_chat_datasource.dart`, `sqlite_lesson_progress_datasource.dart`, `sqlite_scan_history_datasource.dart`, `sqlite_chat_memory_datasource.dart`, `sqlite_translation_history_datasource.dart`, `local_profile_management_datasource.dart`) | ✅ Same | ❌ `sqflite` does not support web — any code path importing these datasources will fail at runtime on web; no `kIsWeb` guards observed around datasource construction in feature DI. |
| Hive | n/a | n/a | n/a | Not used; codebase has migrated to `sqflite`. |
| File / blob saving (YOLO model) | ✅ `path_provider` → app docs (`yolo_model_cache.dart:5`) | ✅ Same | ⚠ Web branch returns model URL directly via `web_vision_model_url_resolver.dart`; no filesystem write. |
| Share | ✅ `share_plus` `SharePlus.instance.share(...)` (`scan_tab.dart:1231`, `output_actions.dart:48`, `export_sheet.dart:87`, `stroke_export_service.dart:32`) | ✅ Same | ✅ `share_plus` falls back to Web Share API where supported; otherwise no-ops. |

## kIsWeb Branches
| file:line | What native does | What web does |
| --- | --- | --- |
| `lib/main.dart` (no guard) | `initializeFlutterGemma(huggingFaceToken: hfToken)` runs unconditionally at line `lib/main.dart:18`. | Same call — but `flutter_gemma` on web has no vision and limited text inference. No `kIsWeb` skip. |
| `lib/features/home/presentation/screens/splash_screen.dart:19` | Pre-warms `baybayinDetectorProvider` on mobile. | Skips warm-up — web detector is created lazily by scanner screen. |
| `lib/features/home/presentation/providers/translate_sketchpad_controller.dart:100` | Runs local-first Gemma image analysis when `mode == local`. | Forces cloud analysis (local not supported on web). |
| `lib/features/home/presentation/providers/model_setup_controller.dart:105` | Reads `availableYoloModelsProvider` + downloads via `YoloModelCache`. | Refreshes `visionModelSetupStatusProvider` (web preflight via blob cache). |
| `lib/features/home/presentation/screens/model_setup_screen.dart:188 / :196 / :203 / :206` | Standard portrait/landscape/desktop layouts; no extra scroll wrapper. | Centers content and wraps in `SingleChildScrollView` to ensure scrollability in browser viewports. |
| `lib/features/home/presentation/screens/model_setup_screen.dart:639,:689` | Setup copy emphasises one-time download and Wi-Fi recommendation. | Setup copy emphasises "browser" and warns first setup may take a while. |
| `lib/features/home/presentation/screens/scan_tab.dart:85-89` | n/a | Determines whether to center the status chip on web. |
| `scan_tab.dart:192-198` | `controller.switchCamera()` (native). | Calls `_webSwitchCamera` callback registered by `_WebCameraPreview`. |
| `scan_tab.dart:206` | Try-again handler retries native scan notice. | Skips: try-again handler returns `null` until a web capture callback is registered. |
| `scan_tab.dart:280-289` | Status chip uses "Camera ready" + camera icon. | Status chip uses `_webStatus.label` + dynamic icon (initializing / permission-needed / error / ready). |
| `scan_tab.dart:298` | Pauses live YOLO inference when result panel is open. | Does not pause — `scannerPaused: scanState.resultVisible && !kIsWeb` keeps web preview running because web is non-live. |
| `scan_tab.dart:300,:343` | Flash toggle wired up. | Flash toggle disabled — `onFlashToggle: kIsWeb ? null : ...`. |
| `scan_tab.dart:411-420` | Shutter button captures native camera frame. | Shutter button calls `controller.captureWebFrame(_webCapture!)` and label changes to "Capture Webcam Frame". |
| `scan_tab.dart:424-426` | "Switch camera" tooltip always available. | "Only one camera available" tooltip when `_webSwitchCamera == null`. |
| `lib/features/home/presentation/widgets/settings/vision_download_tile.dart:33-48` | Calls `YoloModelCache.download(...)`. | Calls `createWebVisionModelPreflight().run(model.modelLink)`. |
| `vision_download_tile.dart:55-61` | Pre-fetches active YOLO path after download. | Skips — no filesystem path. |
| `vision_download_tile.dart:65-67` | Surfaces raw error text. | Routes error through `friendlyVisionModelError`. |
| `vision_download_tile.dart:126,:166,:319` | UI strings reference "download". | UI strings reference "browser" / "set up once in this browser". |
| `lib/features/auth/data/datasources/supabase_auth_datasource.dart:85-87` | `redirectTo: 'kudlit://auth/reset'`. | `redirectTo: '${Uri.base.origin}/auth/reset'`. |
| `supabase_auth_datasource.dart:179` | `redirectTo: 'kudlit://auth/reset'`. | `redirectTo: null` (falls back to Supabase Site URL). |
| `lib/features/learning/presentation/screens/lesson_stage_screen.dart:107` | Warms `yoloDrawingPadModelProvider`. | Skips warm. |
| `lib/features/learning/presentation/widgets/modes/draw_mode_body.dart:100` | Runs draw-mode local YOLO. | Skipped. |
| `lib/features/translator/data/datasources/local_gemma_datasource.dart:210` | Local Gemma vision path. | Throws `UnsupportedError('Image analysis is not supported by flutter_gemma on web yet.')`. |
| `lib/features/translator/data/repositories/ai_inference_repository_impl.dart:141` | Local-first with cloud fallback. | Forces cloud for any image analysis (`kIsWeb || _useCloud`). |
| `lib/features/scanner/presentation/providers/scan_tab_controller.dart:347` | Calls `detector.resumeInference()` after dismissing result. | Skipped (no live inference loop to resume). |
| `lib/features/scanner/presentation/providers/yolo_model_selection_provider.dart:213,:268,:269,:321,:397,:427` | Returns native filesystem paths and downloads via cache; reads dart:io. | Returns model URL directly; throws `UnsupportedError('YOLO is not available on web.')` for path-only APIs. |
| `lib/features/scanner/presentation/providers/scanner_provider.dart:19-26` | Constructs `YoloBaybayinDetector`. | Constructs `createWebBaybayinDetector(...)` via conditional import factory. |
| `lib/features/scanner/presentation/widgets/scanner_camera.dart:320` | Falls through to `YOLOView`. | Returns `_WebCameraPreview` (uses `camera` plugin). |

## Web-Specific Files
| Path | Role |
| --- | --- |
| `lib/features/scanner/data/datasources/web_baybayin_detector_factory.dart` | Factory entry-point — conditional import dispatches between stub and real web TFLite implementation. |
| `lib/features/scanner/data/datasources/web_baybayin_detector_stub.dart` | Stub used when `dart.library.js_interop` is unavailable (mobile builds). |
| `lib/features/scanner/data/datasources/web_tflite_baybayin_detector.dart` | Real web detector implementing `BaybayinDetector` via TFLite JS runtime. |
| `lib/features/scanner/data/datasources/web_tflite_model_runtime.dart` | JS interop wrapper around the TFLite.js runtime. |
| `lib/features/scanner/data/datasources/web_yolo_output_parser.dart` | Parses raw YOLO web output tensors into `BaybayinDetection`. |
| `lib/features/scanner/data/datasources/web_vision_model_preflight.dart` | Cross-platform entry to web vision preflight (selects stub or web). |
| `lib/features/scanner/data/datasources/web_vision_model_preflight_stub.dart` | Stub preflight for native builds. |
| `lib/features/scanner/data/datasources/web_vision_model_preflight_web.dart` | Real web preflight: downloads/caches model in browser. |
| `lib/features/scanner/data/datasources/web_vision_model_url_resolver.dart` | Resolves the active web vision model URL. |
| `lib/features/translator/data/datasources/web_gemma_model_preflight.dart` | Entry point for web Gemma preflight. |
| `lib/features/translator/data/datasources/web_gemma_model_preflight_stub.dart` | Stub for native builds. |
| `lib/features/translator/data/datasources/web_gemma_model_preflight_web.dart` | Real web Gemma preflight implementation. |

## Findings

### Camera & vision pipeline
- **Live inference parity broken on web.** Native uses `YOLOView` to push detections in real time (`yolo_baybayin_detector.dart:44-60`, `scanner_camera.dart:358-368`). Web's `_WebCameraPreview` does not run continuous inference — the user must press a "Capture Webcam Frame" shutter (`scan_tab.dart:411-420`). The UI does not visually communicate this difference beyond the button label.
- **Result-panel pause asymmetry.** Native pauses inference while result panel is open (`scan_tab.dart:298`, `scan_tab_controller.dart:347-349`). Web skips both, which is correct (no loop) but the comment trail makes it look intentional — no inline note explaining the asymmetry.
- **Frame capture path divergent.** Native shutter uses `RenderRepaintBoundary.toImage(pixelRatio: 1.5)` (`scan_tab.dart:234-243`) to snapshot the live preview. Web shutter relies on the `WebScannerCapture` callback wired by the `camera` plugin's preview. Two distinct capture pipelines.
- **Pre-warming asymmetry.** Splash pre-warms `baybayinDetectorProvider` only on mobile (`splash_screen.dart:19-21`); the web first-detect is therefore slower because model fetching happens at the moment of capture rather than at startup.
- **TFLite model resolver tightly coupled to platform.** `_resolveWebVisionModelUrl` (`scanner_provider.dart:31-47`) only resolves the camera scope; the drawing-pad scope is never resolved for web. Combined with `draw_mode_body.dart:100`'s `!kIsWeb` guard, draw-mode practice silently has no detector on web.

### Auth deep links
- **Password reset on web is broken if Site URL is not configured.** `resetPassword(...)` sets `redirectTo: null` for web (`supabase_auth_datasource.dart:179`). Without an explicit redirect, Supabase uses the dashboard Site URL. If the deployment's `/auth/reset` route is not registered there, users will be redirected to a 404 or the marketing page. There is no in-app fallback (e.g. instructions copy).
- **Google OAuth web origin must include `/auth/reset` route.** `signInWithGoogle()` returns to `${Uri.base.origin}/auth/reset` on web (`supabase_auth_datasource.dart:85-87`). For shareable preview/staging builds with non-canonical origins, this redirect needs the origin to be allow-listed in Supabase Auth → URL Configuration.
- **Phone OTP has no platform guard.** `sendPhoneOtp` and `verifyPhoneOtp` (`supabase_auth_datasource.dart:104-136`) run identically on all platforms. Web reCAPTCHA invocation is not handled in code; it relies on Supabase JS shim through `supabase_flutter`. Worth verifying on web build.

### Responsive / SafeArea / keyboard
- **SafeArea coverage.** 59 hits for `SafeArea` / `MediaQuery.paddingOf` / `resizeToAvoidBottomInset` across `lib/`. The scanner overlays correctly wrap controls in `SafeArea(bottom: false, ...)` (`scan_tab.dart:332-393`) and account for `safeBottom` (`scan_tab.dart:260`).
- **Notch/landscape tuning.** `scan_tab.dart:261-269` derives `compactLandscape`, `tinyViewport`, `tinyLandscapeNotice` from `LayoutBuilder` — solid. Model setup screen has four explicit layouts (desktop, landscape, short portrait, portrait) at `model_setup_screen.dart:168-204` — good coverage.
- **Web scrolling fix.** `model_setup_screen.dart:206-213` wraps the layout in `SingleChildScrollView` only when `kIsWeb`. Native short-portrait also has a `SingleChildScrollView` (`:478`). The portrait layout uses `Spacer` + `Center` and may overflow on small browser windows without scroll — but this is hedged by the `kIsWeb` scroll wrapper.
- **Keyboard avoidance.** Auth shells set `resizeToAvoidBottomInset: true` (`auth_screen_shell.dart:31,:50`); auth_form_scaffold uses `Scaffold` defaults. No keyboard handling issues found in scanner/translate flows because those screens are camera-led.

### Platform idiom mismatches
- **Material 3 is the single design language.** No Cupertino / `CupertinoApp` switching detected. iOS users see Material chips, sheets, and tooltips throughout (e.g. `scan_tab.dart:762-790` Material tooltips). On iOS this is a minor HIG mismatch — share sheet and toasts behave Material, not iOS native.
- **Tooltips on touch-only platforms.** Many controls wrap in `Tooltip(...)` (e.g. `scan_tab.dart:762`, `scan_tab.dart:1454`). On Android/iOS these only show on long-press; on web they show on hover — fine, but the Semantics labels are still correct.
- **No keyboard navigation polish.** No explicit `Shortcuts` / `Actions` / focus traversal customization. On web, tab-key flow follows widget tree order, which may not match visual order for stack-positioned scanner overlays. Mainly affects the scan_tab where multiple `Positioned` children share the same `Stack`.
- **`flutter_gemma` initialised unconditionally on web.** `main.dart:18` calls `initializeFlutterGemma` even when `kIsWeb` and the package's web support is limited. If the bootstrap does network/IO that fails on web, the entire app may stall at boot.
- **`sqflite` is web-incompatible.** All SQLite datasources import `package:sqflite/sqflite.dart` and have no `kIsWeb` guards (`sqlite_chat_datasource.dart`, `sqlite_lesson_progress_datasource.dart`, `sqlite_scan_history_datasource.dart`, `sqlite_chat_memory_datasource.dart`, `sqlite_translation_history_datasource.dart`, `local_profile_management_datasource.dart`). If their providers are ever read on web (chat history, scan history, lesson progress, profile cache), runtime will throw `MissingPluginException`. Need `sqflite_common_ffi_web` or web-stub datasource.

## Top Recommendations (multiplatform-local, severity-ordered)
| # | Severity | Effort | Recommendation | Evidence |
| --- | --- | --- | --- | --- |
| 1 | P0 | M | Add web-stub or `sqflite_common_ffi_web` adapters for every `sqflite` datasource so chat history, scan history, lesson progress, and profile cache do not crash on web. Currently no `kIsWeb` guard around construction. | `lib/features/translator/data/datasources/sqlite_*.dart`, `lib/features/scanner/data/datasources/sqlite_scan_history_datasource.dart`, `lib/features/learning/data/datasources/sqlite_lesson_progress_datasource.dart`, `lib/features/home/data/datasources/local_profile_management_datasource.dart` |
| 2 | P0 | S | Provide an explicit `redirectTo` for password reset on web (e.g. `'${Uri.base.origin}/auth/reset'`) instead of `null`, mirroring the OAuth web path. Add an in-app `/auth/reset` route handler. | `lib/features/auth/data/datasources/supabase_auth_datasource.dart:179`, `:85-87` |
| 3 | P0 | M | Guard `initializeFlutterGemma(...)` behind `!kIsWeb` (or a web-safe init) in `lib/main.dart:18` so the app boots on web even when the package's web side has limited support. | `lib/main.dart:18` |
| 4 | P1 | S | Surface to users that the web scanner runs single-frame capture, not live YOLO, with a clearer status chip copy and a one-time onboarding hint. Today the difference is implicit in the button label. | `scan_tab.dart:280-289`, `:411-420`, `_WebCameraPreview` in `scanner_camera.dart:320` |
| 5 | P1 | S | Disable the flash button as "Unavailable in browser" on web rather than rendering it hidden (`onFlashToggle: null`) — gives users a discoverable explanation. | `scan_tab.dart:300`, `:343` |
| 6 | P1 | M | Pre-warm the web vision detector on `SplashScreen` (currently mobile-only at `splash_screen.dart:19-21`) so the first capture on web is not slowed by lazy model fetch. | `splash_screen.dart:19-21`, `scanner_provider.dart:19-26` |
| 7 | P1 | S | Resolve the draw-mode YOLO model for web in `draw_mode_body.dart:100` and `lesson_stage_screen.dart:107` (currently `!kIsWeb` only), or provide an explicit "Draw practice requires the mobile app" notice. | `draw_mode_body.dart:100`, `lesson_stage_screen.dart:107` |
| 8 | P1 | S | Add a code comment near `scan_tab.dart:298` explaining why `scannerPaused` is forced false on web (no live loop) — easy to misread as a bug today. | `scan_tab.dart:298` |
| 9 | P2 | S | Audit Supabase Auth URL allow-list for staging/preview origins, since `Uri.base.origin` will vary per deploy. | `supabase_auth_datasource.dart:85-87` |
| 10 | P2 | M | Consider switching to `CupertinoTheme`-aware widgets (`SharePlus` is fine; share sheet, dialogs, action sheets) for iOS to meet HIG expectations, or document the Material-everywhere choice. | App-wide; `scan_tab.dart` Dialog/SnackBar usage |
| 11 | P2 | M | Add focus-traversal order to scanner stack overlays (`scan_tab.dart` `_ScanUtilityBar`, `_ScanControls`, status chip) so keyboard-only web users tab in visual order. | `scan_tab.dart:329-430` |
| 12 | P2 | S | Document phone OTP web behaviour (reCAPTCHA, allowed origins) — code path is shared with mobile (`supabase_auth_datasource.dart:104-136`) but web has additional Supabase requirements. | `supabase_auth_datasource.dart:104-136` |

## Methods
- Files read:
  - `lib/main.dart`
  - `lib/features/scanner/presentation/providers/scanner_provider.dart`
  - `lib/features/translator/data/repositories/ai_inference_repository_impl.dart`
  - `lib/features/scanner/data/datasources/yolo_baybayin_detector.dart`
  - `lib/features/scanner/data/datasources/web_baybayin_detector_factory.dart`
  - `lib/features/home/presentation/screens/scan_tab.dart`
  - `lib/features/home/presentation/screens/model_setup_screen.dart`
  - `lib/features/auth/data/datasources/supabase_auth_datasource.dart`
  - `lib/features/home/presentation/screens/splash_screen.dart`
  - `lib/features/home/presentation/widgets/settings/vision_download_tile.dart`
  - `lib/features/home/presentation/providers/model_setup_controller.dart`
  - `lib/features/home/presentation/providers/translate_sketchpad_controller.dart`
  - `lib/features/scanner/presentation/providers/scan_tab_controller.dart`
  - `lib/features/scanner/presentation/widgets/scanner_camera.dart` (excerpt)
  - `lib/features/translator/data/datasources/local_gemma_datasource.dart` (excerpt)
- Greps run: `kIsWeb` in `lib/`, `web_*.dart`/`*_web.dart`/`*_native.dart` file glob, `image_picker`, `sqflite|Hive|path_provider`, `share_plus`, `SafeArea|MediaQuery.paddingOf|resizeToAvoidBottomInset`.
- Prior audits reconciled: `docs/scanner_vision_model_audit.md`, `docs/gemma_offline_model_loading_audit.md`, `docs/supabase_phone_google_auth_plan.md` (referenced for prior context; not re-read in this pass).
