# 04 — Performance, offline-first, integrations
**Auditor:** general-purpose (performance lane) · **Skill invoked:** none · **Date:** 2026-05-14

## Summary
- P0 count: 2 · P1 count: 6 · P2 count: 4
- Single biggest risk: `ScanTab` and its `YOLOView` are never disposed when the user switches tabs (PageView retains all children), so YOLO native inference continues running on every frame for the life of the app even while the user is in Translate/Learn/Butty — the `paused` flag only suppresses dispatch, not the underlying inference.

---

## Findings

### Model load lifecycle

**flutter_gemma (LLM)**
- `lib/main.dart:18` calls `initializeFlutterGemma(huggingFaceToken: hfToken)` on `WidgetsFlutterBinding.ensureInitialized()` — this is awaited before `runApp`, so plugin init blocks first-frame paint.
- `lib/features/translator/data/datasources/flutter_gemma_bootstrap.dart:9` configures `webStorageMode: WebStorageMode.cacheApi` for web (only relevant on web).
- The actual model is loaded lazily via `LocalGemmaDatasource.probeReadiness()` (`lib/features/translator/data/datasources/local_gemma_datasource.dart:32-55`). Probe is gated by an in-flight mutex (`_probing` + `_pendingProbe`) so concurrent callers coalesce.
- Pre-warm happens inside the probe (`local_gemma_datasource.dart:78-80`): `_activeModel ??= await FlutterGemma.getActiveModel()`. So readiness probe is also the warm-up — the next `generate()` reuses `_activeModel` (`local_gemma_datasource.dart:171`).
- Probe is wired via `localModelReadinessProvider` (`translator_providers.dart:100-127`). It re-runs only when `selectedModelId` changes — by using `.select((v) => v.value?.selectedModelId)`.
- `ModelSetupController.completeSetup()` (`model_setup_controller.dart:46-83`) calls `ref.refresh(localModelReadinessProvider.future)` synchronously while the "Continue" button is in a busy state. This is the only blocking call site for warm-up. Setup UI shows a spinner via `KudlitLoadingIndicator`.
- Vision support requires recreating the engine (`local_gemma_datasource.dart:228-236`): if `_activeModel` exists without vision, it is closed and reloaded with `supportImage: true, maxNumImages: 1`. Reload is paid the first time the user runs `analyzeImage` after a text chat.
- `ensureModelLoaded()` exists (`local_gemma_datasource.dart:101-110`) but no caller invokes it — pre-warm only happens through the probe path. **P2** — dead code or missing call site for post-download warmup.

**YOLO (vision)**
- `baybayinDetectorProvider` is `@Riverpod(keepAlive: true)` (`scanner_provider.dart:17`). The detector is instantiated when first read. On mobile this creates a `YoloBaybayinDetector` with a lazy model resolver — no native model is loaded until the live YOLOView mounts or `detectImage()` is called.
- Pre-warm: `SplashScreen.build()` (`splash_screen.dart:19-21`) calls `ref.watch(baybayinDetectorProvider)` on non-web during the splash phase. This only instantiates the Dart class, not the native model. The native load happens when `YOLOView` mounts (`scanner_camera.dart:355-368`) — first scan-tab open pays the model-load cost.
- Live and still-image inference use separate YOLO instances:
  - Live: managed by `YOLOView` widget; loads native model via `modelPath` prop on mount.
  - Still: `_singleImageYolo` instance (`yolo_baybayin_detector.dart:89-114`), cached by `modelPath`. Recreated only when `modelPath` changes; `loadModel()` is awaited synchronously per request that requires a new path.
- YOLO download/cache (`lib/features/scanner/data/datasources/yolo_model_cache.dart`) — keyed by Supabase model id with a `.version` sidecar file. Version check (`isUpToDate`) decides whether to redownload. Download is plain `HttpClient` streamed to disk; failure deletes the partial file (`yolo_model_cache.dart:120`).

**UI blocking**
- `await dotenv.load()` and `await Supabase.initialize()` in `main.dart:12-16` run before `runApp`. Combined with `initializeFlutterGemma` they delay the first frame. No reports of pathological times in the codebase, but this is a single sequential await chain — moving to fire-and-forget for non-critical init is a **P1** optimization.

---

### Inference cadence & camera lifecycle

**Throttling and persistence**
- `_kDetectionInterval = 250 ms` (`scanner_camera.dart:23`) — only one dispatch per quarter second to `onDetections`. The underlying YOLO native inference still fires on every frame; the `Stopwatch` only throttles the Dart-side dispatch.
- Two-tier filtering in `_onYoloResult` (`scanner_camera.dart:256-296`):
  1. Confidence ≥ 0.8 (`_kConfidenceThreshold`), area ≥ 0.001, in-frame margin 0.02.
  2. Temporal: requires `_kRequiredConsecutiveHits = 2` consecutive non-empty intervals before surfacing — kills single-frame phantoms.

**Paused state (commit 7f28abc)**
- `ScannerCamera.paused` (`scanner_camera.dart:208-210`, line 257): `if (widget.paused) return;` — guards `_onYoloResult` so detections are discarded while the result panel is up. This **does not** stop the native YOLO model from running; the camera and inference pipeline continue, only the dispatch is suppressed. **P1** — wasted battery while the user sits on the frozen result. The detector has `pauseInference()`/`resumeInference()` methods (`yolo_baybayin_detector.dart:155-159`) that call `_controller.stop()` / `_controller.restartCamera()`, but `ScannerCamera` does not invoke them when `paused` flips.
- Pause is wired in: `scan_tab.dart:298` (`scannerPaused: scanState.resultVisible && !kIsWeb`). Dismiss restores via `controller.resumeInference()` (`scan_tab_controller.dart:347-349`). The asymmetry is the gap — entering pause never calls `pauseInference()` on the controller, only the dispatch-suppress flag.

**Tab switch / camera lifecycle**
- **P0** — `HomeScreen._HomeBody` (`auth/presentation/screens/home_screen.dart:122-145`) uses a `PageView` with `physics: NeverScrollableScrollPhysics()` and all four children mounted simultaneously (`ScanTab`, `TranslateScreen`, `LearnTab`, `ButtyChatScreen`). PageView keeps offscreen children **alive**, so `ScannerCamera` is never disposed when the user goes to another tab. `YOLOView` continues running native inference; the camera hardware stream is still open.
- This is consistent with the keepAlive intent of `baybayinDetectorProvider` (`scanner_provider.dart:17`), but the lack of any `pauseInference()` call on tab switch is a major battery and thermal concern. Recommend gating `ScannerCamera` mount on `_activeTab == AppTab.scan`, or invoking `pauseInference()` when the scan tab loses focus.
- Web is partially better: `_WebCameraPreview.dispose()` (`scanner_camera.dart:411-417`) disposes the `CameraController` — but only fires when ScannerCamera itself unmounts, which (due to the PageView) never happens.

**Inference path branching**
- Live frame: YOLO native (mobile) or `_captureAndDetect` snapshot (web) — `scanner_camera.dart:552-582` calls `detectImage(bytes)` on every web capture (no live web stream inference).
- Captured shutter frame: reuses existing live detections (`scan_tab_controller.dart:171-198`), so no extra inference pass.
- Gallery: full `detectImage()` pass via the cached `_singleImageYolo` instance.
- Frame capture via `RenderRepaintBoundary.toImage(pixelRatio: 1.5)` on mobile (`scan_tab.dart:237`) — synchronous-ish render-thread work; PNG encode happens on a separate isolate via `toByteData`. **P2** — `pixelRatio: 1.5` is arbitrary; on hi-DPI Android the PNG can be large enough to noticeably stall the shutter feedback.

**Aggregation buffer**
- `_kAggMaxBuffer = 50` frames, `_kAggIdleTimeout = 1000 ms` (`scan_tab_controller.dart:127-128`). Reset on empty detection or after 1 s idle. Reasonable bounds. Vowel ambiguity collapse (`e` → `i`) lives at `scan_tab_controller.dart:515`.

---

### SQLite cache-first patterns (per repository)

**`ProfileManagementRepositoryImpl`** (`lib/features/home/data/repositories/profile_management_repository_impl.dart`)
- `getSummary()` (lines 21-49): cache-first — returns cached value immediately if present, only hits remote on cache miss. **P1** — no TTL/staleness check. If the cache is ever populated, the read path never sees server-side changes (e.g., when avatar/displayName changes happen on another device). Mitigated only by explicit invalidation in `updateDisplayName`/`updateAvatar` on the *same* device.
- `getPreferences()` (lines 52-80): same cache-first pattern.
- Write paths (`updateDisplayName`, `updateAvatar`, `savePreferences`): remote first, then either invalidate (`clearCachedSummary`) or update cache directly. Write order is correct — server write is the source of truth for ack, cache only mirrors on success.
- `saveLessonProgress` (lines 168-185): remote-only; no cache layer. **P2** — lesson progress reads would always hit Supabase; check whether `ProfileSummary.completedLessons` is the snapshot path (it is, via the cached summary).

**`ChatMemoryRepositoryImpl`** (`lib/features/translator/data/repositories/chat_memory_repository_impl.dart`)
- `getFacts()` (lines 27-44): SQLite first; on empty, cold-start restore from Supabase. Each remote row is `insertIfNew()` into SQLite (dedupes on `normalized` UNIQUE index). Returns the re-loaded local list.
- `addFacts()` (lines 47-58): local insert with `ConflictAlgorithm.ignore`; if persisted, fire-and-forget `_syncFact()` which captures the returned remote UUID and back-fills `remote_id` locally (lines 96-104).
- `updateFact()`/`removeFact()`: local first, then mirror to Supabase by `remote_id` if known.
- **P1** — failed Supabase inserts (returning `null`) leave the row with `remote_id IS NULL` forever. No retry queue. Cross-device sync silently breaks for those rows. (Already called out in `docs/butty_chat_memory_ai_audit.md` Gap 1.)

**`ChatHistoryNotifier`** (`lib/features/translator/presentation/providers/chat_history_provider.dart`) — uses datasources directly, no repository indirection
- Same offline-first pattern: `build()` loads from SQLite first; on empty, calls `_remote.fetchRecent(limit: 100)` and rehydrates.
- `addMessage()` inserts locally first, updates state immediately, then `unawaited(_syncMessage(saved))` for cloud. `remote_id` back-fill mutates state (lines 73-81) to keep it consistent.
- Same retry gap as chat memory.

**`ScanHistoryNotifier`** (`lib/features/scanner/presentation/providers/scan_history_provider.dart`) — no repository abstraction
- Direct SQLite via `SqliteScanHistoryDatasource` + inline Supabase calls (lines 79-93, 95-121).
- Cold-start restore from Supabase (lines 36-55) — inserts rows in reverse to preserve chronological order.
- Write: local-first, fire-and-forget cloud sync. No `remote_id` column in scan_history schema (`sqlite_scan_history_datasource.dart:33-43`) — there is **no idempotency key** between local and remote rows, so the cold-start restore relies on local being empty. If a user partially synced from device A and reinstalls on device B, both rows may end up in the cloud causing duplicates on next restore. **P1** — schema lacks remote_id.

**SQLite connection management**
- All four datasources open the DB lazily, cache the `Database` in a field, and expose `dispose()`. All datasource providers wire `ref.onDispose(ds.dispose)`. Good.
- No `WAL` mode / journal-mode tuning — Flutter sqflite default is `DELETE` journal. Fine for current write volumes but **P2** — chat memory writes during streaming are sparse, scan-history is one row per save.

---

### Gemma local↔cloud fallback

**Boundary** — `lib/features/translator/data/repositories/ai_inference_repository_impl.dart:80-131`
- Router (`generateResponse`): `_useCloud` reads `preferenceResolver()` per call. Cloud path is direct; local path goes through `_localWithCloudFallback`.
- Local path uses `await for ... yield` (not `yield*`) so stream errors from `localDatasource.generate` are caught inside the try block (line 109-122). On any caught error, the `localFailed = true` branch yields from cloud (lines 123-130).
- Same pattern for `analyzeImage` (lines 160-184). Mobile-only — `kIsWeb || _useCloud` shortcircuits to cloud at line 141.
- `generateChallenge` (lines 188-215): try local, catch any, retry cloud — synchronous (not streamed).

**User visibility**
- Fallback is **silent**. The only signal is `debugPrint('[Gemma] local inference failed -> falling back to cloud')` (line 120). No UI affordance: the user sets `AiPreference.local`, fires a chat, and may transparently land on cloud without knowing.
- **P1** — silent fallback can mask "model is broken" failure modes (e.g. file deleted, version mismatch). The chat memory audit doc lists the local→cloud transparent fallback as working as intended, but there is no telemetry / banner that surfaces it. Recommend a one-shot snackbar (or toggle the AI mode pill state) when the repo silently downgrades.

**preferenceResolver design**
- `translator_providers.dart:75-92` deliberately does not `watch` preferences — to avoid disposing the repo (which closes the native InferenceModel) on every preference toggle. Resolver is read at call-time. This is correct but worth noting: switching local→cloud mid-stream has no effect on in-flight generation.

---

### Butty chat memory architecture (episodic + semantic + sliding window)

**Layering** — two stores:
- Episodic: `chat_messages` table (`sqlite_chat_datasource.dart:35-43`) — full turn transcript, schema: `id, remote_id, text, is_user, timestamp`.
- Semantic: `chat_memory_facts` table (`sqlite_chat_memory_datasource.dart:46-58`) — distilled facts about the user with a `normalized` UNIQUE index for dedup. Schema: `id, remote_id, fact_type, content, normalized, created_at, last_referenced_at`.

**Sliding window**
- `ButtyChatController._historyWindow = 20` (`butty_chat_controller.dart:61`). On every `send()`, the last 20 entries from the in-memory `state.messages` are converted to `ChatMessage` and shipped to `generateResponse` (lines 119-131). The system instruction injects 12 most-recent facts (`_buildMemoryBlock`, lines 240-254).
- Window snapshot uses `DateTime.now()` for the timestamp of historical messages (line 128), discarding the actual stored timestamp — **P2**, harmless for prompt assembly but breaks any downstream time-based reasoning in the prompt.

**Memory extraction (semantic distillation)**
- `MemoryExtractionService` (`lib/features/translator/presentation/providers/memory_extraction_service.dart`).
- Triggers: every 4 user messages (`isDue`, line 38, 46); flushes on app pause via `flushMemoryNow()` (called from `ButtyChatController` lines 197-199, presumably wired to a lifecycle observer in `butty_chat_screen.dart`).
- Throttle: `_minInterval = 30 seconds`, `_running` mutex (lines 31, 40-42, 58-63). Both extraction triggers can fire on the same edge but only one runs.
- Window: 30 messages (`_windowSize` line 35) — independent from the chat sliding window.
- Output: model-generated JSON (with fence stripping) → `ChatMemoryFact[]` → `_repo.addFacts()` which dedupes via the SQLite UNIQUE index.
- **P1 (already documented)** — extraction calls `aiInferenceNotifierProvider.notifier.generateResponse` (line 82-85), which respects the user's `AiPreference`. If the user is in local mode and the local model fails, extraction silently skips (the transparent fallback runs but extraction-specific prompts may misfire on the cloud model only sporadically). Force cloud for extraction.

**"Start fresh" preserves memory**
- Verified — `ButtyChatController.startFresh()` (`butty_chat_controller.dart:204-208`): clears `chatHistoryNotifierProvider` (chat_messages local + remote) and resets the controller state to `ButtyChatState.initial()`. It does **not** touch `chatMemoryNotifierProvider` or `chat_memory_facts`. The semantic memory survives.
- `_userMessageCount` is reset to 0 so the next 4 messages re-trigger extraction from the freshly-empty episodic window.

**Profile injection**
- `_buildProfileBlock` (`butty_chat_controller.dart:221-238`) pulls from `profileSummaryNotifierProvider.value` and concatenates name, lessons completed, AI mode into the system instruction. Best-effort: returns `''` if not loaded. **P2** — no fallback to cached SQLite if the provider is in `loading` state at send time; the first message after a cold start may go out without profile context.

---

### Supabase sync & retry behavior

- All Supabase writes across `SupabaseChatMemoryDatasource`, `SupabaseChatDatasource`, and inline `_syncToSupabase` calls are wrapped in try/catch with `debugPrint` only. No retry, no queue, no `remote_id IS NULL` reaper. Once a sync fails, the row stays orphaned locally.
- Guest mode handled: every cloud call checks `_client.auth.currentUser?.id` first and silently no-ops when null (`supabase_chat_memory_datasource.dart:15, 47, 71, 81, 98`). Same in scan history `_syncToSupabase` (line 82).
- Cold-start restore is the only "sync recovery" mechanism — it runs only when the local store is empty (or scan history is empty). After the first row lands locally, restore is permanently skipped for that device.
- **P0** — no failed-write reconciliation. If a user is in airplane mode for a session, all messages/facts/scans are orphaned forever from the cloud mirror. (Also flagged in butty audit doc Gap 1.)
- Network error classification — `ModelSetupScreen._friendlyModelSetupError` (`model_setup_screen.dart:52-91`) shows that the team is aware of common transient signatures (`socketexception`, `failed host lookup`, etc.) but this awareness is only applied to model setup UX, not to sync writes.

---

## Top Recommendations (perf/offline-local, severity-ordered)

| # | Severity | Effort | Recommendation | Evidence |
|---|----------|--------|---------------|----------|
| 1 | P0 | M | Stop YOLO inference when ScanTab is off-screen (PageView keeps it alive). Either gate `ScannerCamera` mount on `_activeTab == AppTab.scan` in `HomeScreen._HomeBody`, or call `detector.pauseInference()` / `resumeInference()` from a tab-change callback. | `auth/presentation/screens/home_screen.dart:122-145` (PageView with all four children), `scanner_camera.dart:355-368` (YOLOView), `yolo_baybayin_detector.dart:155-159` (pause/resume methods) |
| 2 | P0 | M | Add a failed-write reaper: on chat/memory/scan provider build, scan local rows with `remote_id IS NULL` (or any equivalent local-only flag for scan_history) and retry Supabase insert. Without this, offline-only sessions never reach the cloud mirror. | `chat_memory_repository_impl.dart:46-58`, `chat_history_provider.dart:53-58`, `scan_history_provider.dart:60-93` (no retry path) |
| 3 | P1 | S | When `ScannerCamera.paused` flips true, call `detector.pauseInference()` so the native YOLO pipeline actually stops (currently only dispatch is suppressed). Resume in the dismiss path already exists. | `scanner_camera.dart:257` (only dispatch guard), `scan_tab_controller.dart:347-349` (existing resume call) |
| 4 | P1 | S | Make memory extraction force `AiPreference.cloud` (or use a dedicated extraction route) so distillation still runs when the user is in local mode and the local model is broken. | `memory_extraction_service.dart:82-85` (uses default route), `ai_inference_repository_impl.dart:80-97` |
| 5 | P1 | S | Surface silent local→cloud fallback to the user (e.g., transient banner or pill flicker) so "Offline" doesn't lie when it's secretly cloud. | `ai_inference_repository_impl.dart:104-131` (silent fallback) |
| 6 | P1 | S | Add a `remote_id` column to `scan_history` SQLite schema + Supabase, so cross-device sync is idempotent. Today, reinstall after partial sync duplicates rows on next cloud restore. | `sqlite_scan_history_datasource.dart:33-43`, `scan_history_provider.dart:79-93` |
| 7 | P1 | M | Add TTL/staleness to `ProfileManagementRepositoryImpl` cache reads, or invalidate on auth state changes — current cache-first-forever means cross-device profile edits never appear. | `profile_management_repository_impl.dart:21-49` |
| 8 | P1 | M | Move non-critical `main.dart` boot work (Supabase, FlutterGemma init) off the awaited-before-runApp path, or show a true splash that doesn't block painting. | `main.dart:10-19` (all awaits before `runApp`) |
| 9 | P2 | S | Call `ensureModelLoaded()` after `download()` completes so the first inference after fresh-download is instant. Currently this method is unused. | `local_gemma_datasource.dart:101-110` (no callers) |
| 10 | P2 | S | Stop rebuilding `ChatMessage.timestamp = DateTime.now()` for the sliding-window snapshot — preserve the original `state.messages` timestamps if you want temporal reasoning in the prompt. | `butty_chat_controller.dart:127-128` |
| 11 | P2 | S | Tune `RenderRepaintBoundary.toImage(pixelRatio: 1.5)` on hi-DPI Android — large PNGs can stall shutter feedback. Consider JPEG with lower quality for the capture path. | `scan_tab.dart:237` |
| 12 | P2 | S | Allow profile block to fall back to the cached SQLite summary when `profileSummaryNotifierProvider` is still loading at send time, so cold-start first messages have context. | `butty_chat_controller.dart:221-238` |

---

## Methods
- Files read:
  - `lib/main.dart`
  - `lib/app/app.dart` (listed, not opened — confirmed app root via `main.dart`)
  - `lib/features/auth/presentation/screens/home_screen.dart`
  - `lib/features/translator/data/datasources/flutter_gemma_bootstrap.dart`
  - `lib/features/translator/data/datasources/local_gemma_datasource.dart`
  - `lib/features/translator/data/datasources/sqlite_chat_datasource.dart`
  - `lib/features/translator/data/datasources/sqlite_chat_memory_datasource.dart`
  - `lib/features/translator/data/datasources/supabase_chat_memory_datasource.dart`
  - `lib/features/translator/data/repositories/ai_inference_repository_impl.dart`
  - `lib/features/translator/data/repositories/chat_memory_repository_impl.dart`
  - `lib/features/translator/presentation/providers/translator_providers.dart`
  - `lib/features/translator/presentation/providers/chat_history_provider.dart`
  - `lib/features/translator/presentation/providers/chat_memory_provider.dart`
  - `lib/features/translator/presentation/providers/memory_extraction_service.dart`
  - `lib/features/home/presentation/providers/butty_chat_controller.dart`
  - `lib/features/home/presentation/providers/model_setup_controller.dart`
  - `lib/features/home/presentation/screens/model_setup_screen.dart`
  - `lib/features/home/presentation/screens/splash_screen.dart`
  - `lib/features/home/presentation/screens/scan_tab.dart`
  - `lib/features/home/data/repositories/profile_management_repository_impl.dart`
  - `lib/features/scanner/data/datasources/yolo_baybayin_detector.dart`
  - `lib/features/scanner/data/datasources/yolo_model_cache.dart`
  - `lib/features/scanner/data/datasources/sqlite_scan_history_datasource.dart`
  - `lib/features/scanner/presentation/providers/scanner_provider.dart`
  - `lib/features/scanner/presentation/providers/scan_tab_controller.dart`
  - `lib/features/scanner/presentation/providers/scan_history_provider.dart`
  - `lib/features/scanner/presentation/providers/scanner_evaluation_provider.dart`
  - `lib/features/scanner/presentation/widgets/scanner_camera.dart`
- Prior audits reconciled:
  - `docs/gemma_offline_model_loading_audit.md` (referenced — not re-opened in this session)
  - `docs/scanner_vision_model_audit.md` (referenced — not re-opened in this session)
  - `docs/butty_chat_memory_ai_audit.md` (read in full; Gap 1 and Gap 2 are reflected as P0 #2 and P1 #4 above)
  - `docs/butty_chat_memory_and_sync_plan.md` (referenced via butty audit cross-link)
  - `docs/realtime_scan_aggregator_plan.md` (referenced via scan_tab_controller aggregator constants)
  - `docs/profile_management_feature_plan.md` (referenced via profile repo cache patterns)
