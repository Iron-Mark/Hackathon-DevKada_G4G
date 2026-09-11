# Gemma 4 (2B) Offline Model Loading Audit

**Date:** 2026-05-04  
**Branch:** `feat/translate-update`  
**Scope:** Local on-device Gemma 4 (2B) inference — initialization, lifecycle, session management, and UX impact

---

## TL;DR

The model singleton is correctly scoped and never multi-instantiated. The critical problems are:

1. **Readiness probes run on every widget rebuild** — not once.
2. **No pre-warming** — cold start latency hits the user on their very first inference tap.
3. **Forced chat-session teardown on mode switch** — text ↔ image alternation closes sessions mid-flight.
4. **Repository dispose-and-recreate on preference toggle** — switching Local ↔ Cloud closes the active `InferenceModel` immediately.

These compound to make it feel like the model is "reconnecting" repeatedly — it is, because state teardown is too aggressive and probing is too frequent.

---

## 1. Current Architecture Snapshot

### Model Initialization Chain

```
main.dart
  └─ FlutterGemma.initialize()           ← once, at app start (non-web)

localGemmaDatasourceProvider             ← keepAlive: true, singleton
  └─ LocalGemmaDatasource
       └─ _activeModel: InferenceModel?  ← null until first inference call
            └─ _chat: InferenceChat?     ← null until first generate() call
```

### Where Inference Is Called

| Feature | Entry Point | Session Type | Triggers |
|---|---|---|---|
| Text translate | `TranslateTextController.explain()` | `generate()` (text chat) | User taps "Explain" |
| Sketchpad feedback | `TranslateSketchpadController.requestFeedback()` | `analyzeImage()` (image chat) | User draws + taps "Feedback" |
| Scanner evaluation | `ScannerEvaluationNotifier.evaluate()` | `analyzeImage()` or `generate()` | YOLO detection completes |
| Butty chat | `ButtyChatController.sendMessage()` | `generate()` (text chat) | User sends message |

### Where Readiness Is Probed

| Provider | Screen | Probe Frequency | What It Does |
|---|---|---|---|
| `translateOfflineStatusProvider` | `TranslateScreen` | Every widget rebuild | Calls `localGemmaDatasource.probeReadiness()` |
| `buttyOfflineStatusProvider` | `ButtyChatScreen` | Every widget rebuild | Calls `localGemmaDatasource.probeReadiness()` |

---

## 2. Issues

### Issue 1 — Readiness Probes Run Too Often

**Severity: High (UX + Performance)**

`translateOfflineStatusProvider` and `buttyOfflineStatusProvider` are both `FutureProvider`s — not `keepAlive`. Every time their parent widget rebuilds, Riverpod can invalidate and re-run them. Inside each probe:

```dart
// LocalGemmaDatasource.probeReadiness()
final InferenceModel probeModel = await FlutterGemma.getActiveModel();
await probeModel.close();  // ← loads the model, then immediately throws it away
```

This means any widget rebuild on `TranslateScreen` or `ButtyChatScreen` (e.g. a keyboard appearing, a stream token arriving, an animation tick) can trigger a full model load → close cycle. On a cold device this is 1–3 seconds of blocking native work — and it races with the real inference calls.

**Root cause:** The probes are not memoized with a TTL, not cached in a `keepAlive` provider, and are not guarded against concurrent re-entry.

---

### Issue 2 — No Pre-warming: Cold Start Latency on First Inference

**Severity: Medium (UX)**

`_activeModel` is `null` at startup. The model is not loaded until the first call to `generate()` or `analyzeImage()`:

```dart
_activeModel ??= await FlutterGemma.getActiveModel();
```

For Gemma 4 (2B) this can take several seconds on mid-range hardware. The user taps "Explain" or sends a message and waits with no feedback except a generic loading state. There is no background warm-up.

---

### Issue 3 — Text Chat Is Destroyed Whenever Image Analysis Runs

**Severity: Medium (Performance + UX)**

The datasource allows only one session at a time. Switching from text generation to image analysis forcibly closes the text chat:

```dart
// inside analyzeImage()
if (_chat != null) {
  await _chat!.close();
  _chat = null;
}
```

This means:
- User translates text → chat session is live
- User switches to sketchpad, draws, asks for feedback → text session is destroyed
- User switches back to text translate → a new text session must be created from scratch

Each session creation reinitializes the chat context (including re-sending the system instruction). The experience is a perceptible pause every time the mode switches.

---

### Issue 4 — Repository Dispose-and-Recreate on Preference Toggle

**Severity: High (Reliability)**

`aiInferenceRepositoryProvider` watches `appPreferencesNotifierProvider`:

```dart
@Riverpod(keepAlive: true)
AiInferenceRepository aiInferenceRepository(Ref ref) {
  ref.watch(appPreferencesNotifierProvider);  // ← triggers dispose on any pref change
  ...
  ref.onDispose(repo.dispose);
  return repo;
}
```

When `repo.dispose()` is called it closes `_activeModel`:

```dart
// AiInferenceRepositoryImpl.dispose()
await localDatasource.dispose();
// which calls:
await _activeModel?.close();
_activeModel = null;
_chat = null;
```

If the user switches from Local → Cloud (or if any other preference key updates `AppPreferences`), the active `InferenceModel` is closed immediately — even if an inference stream is mid-flight. The next inference re-enters cold start.

This is the direct cause of the "needs to reconnect" symptom described in the issue.

---

### Issue 5 — No Download Resume on Crash

**Severity: Low (Reliability)**

If the app crashes or is killed during a model download, on restart `AiInferenceNotifier.build()` sees no in-progress download and marks state as `AiLocalModelMissing`. There is no partial-download resume. The user must restart from 0%.

This is an upstream `flutter_gemma` plugin limitation, but the app should at minimum show progress of a partial download if the file exists.

---

### Issue 6 — Two Independent Readiness Probes for the Same Model

**Severity: Medium (Redundancy)**

`translateOfflineStatusProvider` and `buttyOfflineStatusProvider` are separate providers with separate return types (`TranslateOfflineStatus` vs `ButtyOfflineStatus`) but they call the same underlying `localGemmaDatasource.probeReadiness()` on the same singleton datasource. If both screens are mounted (e.g. in a tab navigation), both probes run concurrently — against the same `InferenceModel`.

---

## 3. Call Graph (Current)

```
TranslateScreen rebuild
  └─ translateOfflineStatusProvider (FutureProvider, no keepAlive)
       └─ localGemmaDatasource.probeReadiness()
            └─ FlutterGemma.getActiveModel()  → load model
            └─ probeModel.close()             → unload model
  
ButtyChatScreen rebuild
  └─ buttyOfflineStatusProvider (FutureProvider, no keepAlive)
       └─ localGemmaDatasource.probeReadiness()  ← concurrent with above
            └─ FlutterGemma.getActiveModel()  → load model (again)
            └─ probeModel.close()             → unload model (again)

User taps "Explain" (text mode)
  └─ translateTextController.explain()
       └─ localGemmaDatasource.generate()
            └─ _activeModel ??= FlutterGemma.getActiveModel()  → COLD START
            └─ _chat ??= _activeModel.createChat()
            └─ stream tokens...

User switches to sketchpad, taps "Feedback"
  └─ translateSketchpadController.requestFeedback()
       └─ localGemmaDatasource.analyzeImage()
            └─ _chat?.close()  ← DESTROYS text session
            └─ imageChat = _activeModel.createChat(supportImage: true)
            └─ stream tokens...
            └─ imageChat.close()

User toggles to Cloud mode in settings
  └─ appPreferencesNotifierProvider emits
       └─ aiInferenceRepositoryProvider disposes
            └─ localGemmaDatasource.dispose()
                 └─ _activeModel?.close()  ← KILLS MODEL
                 └─ _activeModel = null
```

---

## 4. Recommendations

### Rec 1 — Cache the Readiness Result (Fix Issue 1 + 6)

**Priority: P0**

Replace the two separate `FutureProvider`s with a single shared `keepAlive` provider that caches the result for a TTL (e.g. 30 seconds) and gates on a mutex to prevent concurrent probes.

```dart
// Single shared probe, result cached
@Riverpod(keepAlive: true)
class LocalModelReadinessNotifier extends _$LocalModelReadinessNotifier {
  DateTime? _lastChecked;

  @override
  Future<LocalGemmaReadiness> build() async {
    return _probe();
  }

  Future<LocalGemmaReadiness> _probe() async {
    final ds = ref.read(localGemmaDatasourceProvider);
    final active = ref.read(appPreferencesNotifierProvider).activeGemmaModel;
    final result = await ds.probeReadiness(active);
    _lastChecked = DateTime.now();
    return result;
  }

  Future<void> refresh() async {
    final since = _lastChecked;
    if (since != null &&
        DateTime.now().difference(since) < const Duration(seconds: 30)) {
      return; // Still fresh — skip
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(_probe);
  }
}
```

Both `TranslateScreen` and `ButtyChatScreen` watch this single provider. Rebuilds that happen within 30 seconds of the last probe return the cached `AsyncData` immediately — no native call.

---

### Rec 2 — Pre-warm the Model on App Resume (Fix Issue 2)

**Priority: P1**

Add an eager warm-up call when:
- The app comes to the foreground and mode is `AiPreference.local`
- The download completes (model just became available)

```dart
// In AiInferenceNotifier, after state becomes AiReady (local)
Future<void> _warmUpModel() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;
  final ds = ref.read(localGemmaDatasourceProvider);
  await ds.ensureModelLoaded(); // new method: _activeModel ??= await getActiveModel()
}
```

This hides the first-load cost behind navigation time. The user picks up their phone → the model loads quietly in the background → by the time they open Translate, the model is already in memory.

Do NOT pre-warm during download or when preference is Cloud — only on confirmed local-ready state.

---

### Rec 3 — Decouple Repository Lifecycle from Preference Watching (Fix Issue 4)

**Priority: P0 — This is the reconnect bug**

The root cause of the "reconnect" issue: `aiInferenceRepositoryProvider` re-watching preferences causes full dispose → recreate → cold start.

**Fix:** Stop watching preferences inside the provider. Instead, let the repository read the preference lazily at call time:

```dart
// Before (causes dispose on any pref change):
@Riverpod(keepAlive: true)
AiInferenceRepository aiInferenceRepository(Ref ref) {
  ref.watch(appPreferencesNotifierProvider); // ← remove this
  ...
}

// After (repository is stable; routing is dynamic):
@Riverpod(keepAlive: true)
AiInferenceRepository aiInferenceRepository(Ref ref) {
  final repo = AiInferenceRepositoryImpl(
    localDatasource: ref.read(localGemmaDatasourceProvider),
    cloudDatasource: ref.read(cloudGemmaDatasourceProvider),
    getPreference: () => ref.read(appPreferencesNotifierProvider), // pass reader
  );
  ref.onDispose(repo.dispose);
  return repo;
}
```

`AiInferenceRepositoryImpl` reads `getPreference()` at call time to route to local vs cloud — no reactive watch. The repository and its `InferenceModel` survive preference changes. The model only closes on actual app teardown.

---

### Rec 4 — Introduce a Session Pool for Text vs Image (Fix Issue 3)

**Priority: P2**

The one-session-at-a-time constraint is a plugin-level constraint, not easily lifted. The mitigation is to be smarter about when to close:

1. **Don't close the text chat on image analysis** — instead, hold the text chat in a paused state and open the image chat. Restore the text chat reference after image analysis completes, without destroying it (if the plugin supports creating a new session without closing the prior one — currently untested).

2. **If sessions cannot coexist:** introduce a `_sessionLock` (mutex) and a `_pendingMode` flag so that a "reopen text chat" after image analysis is instant (session already recreated in the background during image streaming).

3. **Minimum viable fix:** After `analyzeImage()` completes, immediately `createChat()` for text mode again (background re-warm), so the next text request hits a live session instead of cold-creating one.

---

### Rec 5 — Add a Model State Guard to Prevent Concurrent Probes (Fix Issue 1, 6)

**Priority: P1**

Add a `_probeLock` semaphore inside `LocalGemmaDatasource.probeReadiness()`:

```dart
bool _probing = false;
Future<LocalGemmaReadiness>? _pendingProbe;

Future<LocalGemmaReadiness> probeReadiness(GemmaModelInfo model) {
  if (_probing) return _pendingProbe!;  // Return in-flight result
  _probing = true;
  _pendingProbe = _doProbe(model).whenComplete(() {
    _probing = false;
    _pendingProbe = null;
  });
  return _pendingProbe!;
}
```

This makes concurrent callers share a single native probe call rather than stacking them.

---

## 5. Prioritized Fix Order

| Priority | Fix | Issue Addressed | Effort |
|---|---|---|---|
| P0 | Decouple repo from preference watch | Reconnect bug (Issue 4) | Small |
| P0 | Cache readiness result with TTL | Excessive probing (Issue 1, 6) | Small |
| P1 | Pre-warm model on app foreground + download complete | Cold start latency (Issue 2) | Medium |
| P1 | Probe concurrency guard (mutex) | Race conditions (Issue 1, 6) | Small |
| P2 | Re-warm text chat after image session | Session teardown lag (Issue 3) | Medium |
| P3 | Partial download resume detection | Crash recovery (Issue 5) | Large (plugin-dependent) |

---

## 6. What NOT to Change

- **`localGemmaDatasourceProvider` is `keepAlive: true`** — this is correct; do not remove it.
- **`FlutterGemma.initialize()` in `main.dart`** — this is correct; one-time plugin init.
- **The `_activeModel ??=` lazy-load pattern** — correct; do not eagerly load in the constructor.
- **The cloud fallback** — the local-first-with-cloud-fallback repository pattern is sound. Do not remove it during the refactor.
- **`AiInferenceNotifier` being `keepAlive`** — correct; global state machine must survive navigation.

---

## 7. Files to Touch for the Fixes

| File | Change |
|---|---|
| `lib/features/translator/presentation/providers/translator_providers.dart` | Remove `ref.watch(appPreferencesNotifierProvider)` from repo provider; pass preference reader |
| `lib/features/translator/data/repositories/ai_inference_repository_impl.dart` | Accept `getPreference` callback instead of reading from watch |
| `lib/features/translator/data/datasources/local_gemma_datasource.dart` | Add probe mutex; add `ensureModelLoaded()` method |
| `lib/features/home/presentation/providers/translate_page_controller.dart` | Switch `translateOfflineStatusProvider` to watch shared `LocalModelReadinessNotifier` |
| `lib/features/home/presentation/widgets/butty_chat/butty_model_mode_selector.dart` | Switch `buttyOfflineStatusProvider` to watch shared `LocalModelReadinessNotifier` |
| `lib/features/translator/presentation/providers/ai_inference_provider.dart` | Call `_warmUpModel()` after state transitions to `AiReady` in local mode |

Total surface area: 6 files. No domain-layer changes required.
