# Runtime Log Audit — 2026-05-17

**Source:** `flutter run -d android` debug session on device `22101320G` (PID 22361)
**Scope:** Issues observable from the run log only. Severities reflect user/runtime impact, not code aesthetics.

---

## Summary

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | Unhandled exception: disposed `Ref` in `ProfileSummaryNotifier.refresh` | **P0 — Crash** | ✅ Fixed |
| 2 | Local Gemma inference never works; every request silently falls back to cloud | **P1 — Functional regression** | ✅ Fixed |
| 3 | 33 dependencies behind latest compatible/major versions | **P3 — Maintenance** | Deferred (isolated change) |
| 4 | IME show/hide thrash + viewport-metrics spam | **P2 — Performance/UX** | ✅ Fixed |
| 5 | `FlutterRenderer: Width is zero. 0,0` at startup | **P4 — Cosmetic** | No action (benign) |

> **Fix log (2026-05-17):** #1, #2, and #4 resolved in this branch.
> `flutter analyze` clean on all touched files. #4's root cause was confirmed
> independent of #1 (a second runtime log showed local inference succeeding and
> no provider crash, but the IME thrash persisting). See "Resolution" notes
> under each issue.

---

## 1. P0 — Unhandled exception: `Ref` used after dispose

### Log evidence

```
E/flutter: [ERROR:...] Unhandled Exception: Cannot use the Ref of
profileSummaryNotifierProvider after it has been disposed.
#0  Ref._throwIfInvalidUsage (package:riverpod/.../ref.dart:236:7)
#1  AnyNotifier.state= (package:riverpod/.../notifier_provider.dart:91:9)
#2  ProfileSummaryNotifier.refresh
    (.../home/presentation/providers/profile_management_provider.dart:96:5)
<asynchronous suspension>
```

This fired **at least twice** in the session and is an *unhandled* exception — it
is not caught anywhere and will surface as a red error / crash in profile-stat
refresh paths (after a completed lesson, scan, or translation).

### Root cause

`profile_management_provider.dart` `ProfileSummaryNotifier.refresh()`:

```dart
Future<void> refresh() async {
  final String? userId = ref.read(profileManagementDatasourceProvider)
      .getCurrentUserId();
  if (userId != null) {
    try {
      await ref.read(localProfileManagementDatasourceProvider)
          .clearCachedSummary(userId: userId);   // <-- async gap #1
    } catch (_) {}
  }
  state = const AsyncLoading<...>();              // line 96
  final Option<ProfileSummary> summary = await _fetchSummary(); // gap #2
  state = AsyncValue<...>.data(summary);          // line 98
}
```

The provider is disposed (rebuilt/invalidated) during one of the `await` gaps —
consistent with the IME/rebuild churn seen in issue #4 — and the subsequent
`state =` assignment throws because the `Ref` is no longer valid. The notifier
never checks `ref.mounted` after its async suspensions, exactly the failure mode
the Riverpod error message describes.

### Recommended fix

Guard every post-`await` `state` write with a mounted check:

```dart
Future<void> refresh() async {
  // ... clearCachedSummary ...
  if (!ref.mounted) return;
  state = const AsyncLoading<Option<ProfileSummary>>();
  final summary = await _fetchSummary();
  if (!ref.mounted) return;
  state = AsyncValue.data(summary);
}
```

Apply the same audit to the other mutating methods in this notifier
(`updateDisplayName`, and any sibling notifiers that `await` then assign
`state`). Secondary: the `catch (_) {}` on `clearCachedSummary` silently
swallows cache-clear failures — at minimum log it.

### Resolution (2026-05-17)

Added `if (!ref.mounted) return;` guards after **every** async suspension that
precedes a `state` write, in all four affected methods that had the same latent
defect:

- `ProfileSummaryNotifier.refresh` (the crashing path)
- `ProfileSummaryNotifier.updateDisplayName`
- `ProfileSummaryNotifier.updateAvatar`
- `ProfilePreferencesNotifier.updatePreferences`

The unhandled exception can no longer occur: if the provider is disposed during
any in-flight `await`, the method returns instead of touching `state`.

---

## 2. P1 — Local Gemma inference is dead; 100% silent cloud fallback

### Log evidence (repeats on every translate/explain action)

```
[Gemma] generateResponse route=local-preferred | messages=1
[Gemma] local inference starting
[Gemma][local] generate called | history=1 | hasSystemInstruction=true
[Gemma][local] generate error: Bad state: No active inference model set.
              Use FlutterGemma.installModel() first.
#0  FlutterGemma.getActiveModel (package:flutter_gemma/.../flutter_gemma.dart:244:7)
#1  LocalGemmaDatasource.generate (.../local_gemma_datasource.dart:171:43)
[Gemma] local inference failed -> falling back to cloud
[Gemma] cloud fallback starting
```

### Root cause

`local_gemma_datasource.dart:171`:

```dart
_activeModel ??= await FlutterGemma.getActiveModel();
```

`getActiveModel()` requires a model previously installed via
`FlutterGemma.installModel()`. In this session no model was ever
downloaded/installed, so `getActiveModel()` throws `Bad state: No active
inference model set` on **every** request. `_localWithCloudFallback` in
`ai_inference_repository_impl.dart` correctly catches it and falls back to
cloud, so the feature *works* — but:

- The app's offline-first / on-device Gemma value proposition is **completely
  inert** on this device.
- Every single AI action pays a wasted local-attempt round trip plus a full
  stack-trace log before the cloud call begins — added latency and log noise on
  the hot path.

### Assessment

This is **expected behavior when no local model is installed**, so it is not a
code defect per se. It is flagged P1 because:

1. There is no signal that anything is wrong — the user silently never gets
   on-device inference, and there is no UI prompt to download the model.
2. The fallback is attempted *per message* rather than being short-circuited
   after the first `No active inference model` failure (cache the "local
   unavailable" state for the session to skip the redundant attempt + stack
   dump).

### Real root cause (confirmed)

This was **not** "no model installed" — it is a genuine activation regression.
flutter_gemma's *active model* is process-scoped and is lost on every app
restart, while the downloaded model **file** persists on disk.
`AiInferenceNotifier._resolveInitialState` reported `AiReady(local)` purely from
a file-exists check (`isLocalModelInstalled`) and **never reactivated** the
model into the native engine. The only code path that reactivates is
`probeReadiness()` → `_reactivateInstalledModel()`, which fires only as a side
effect of `localModelReadinessProvider` (a UI status-banner provider). In the
logged session the user triggered Butty / translate `explain` / `checkInput`
before that banner probe ran, so `getActiveModel()` threw on every request and
the offline model — though fully downloaded — was never used.

Butty's offline setup confirmed this: `butty_model_mode_selector.dart` reads
`localModelReadinessProvider.future`, i.e. the mode selector is what
incidentally reactivates the model. Inference must not depend on a widget
having been built.

### Resolution (2026-05-17)

Made `LocalGemmaDatasource` self-healing instead of depending on a UI probe:

- Added `_knownModel` + `rememberModel(model)` — a no-native-work setter so the
  datasource always knows the installed model.
- `AiInferenceNotifier._resolveInitialState` now calls `rememberModel(active)`
  the moment it confirms the model file is installed (before any banner).
- `probeReadiness()` and `download()` also record `_knownModel`.
- Added `_reactivateIfNeeded()`: when the engine reports no active model and the
  file is installed, it reactivates via the existing
  `_reactivateInstalledModel()` before `getActiveModel()`. It is invoked from
  both `generate()` (text) and `analyzeImage()` (scanner vision).

Net effect: the first inference after an app restart reactivates the
already-downloaded model on demand and runs **on-device**, instead of silently
falling back to cloud on every message. If no model is genuinely installed,
the guard is a no-op and the existing cloud fallback still applies (no crash,
no behavior change).

---

## 3. P3 — 33 outdated dependencies

```
33 packages have newer versions incompatible with dependency constraints.
```

Notable, including a **major** bump:

| Package | Current | Available | Note |
|---|---|---|---|
| `xml` | 6.6.1 | 7.0.1 | **major** — review changelog before bumping |
| `json_serializable` | 6.11.4 | 6.14.0 | codegen |
| `json_annotation` | 4.9.0 | 4.12.0 | codegen |
| `mockito` | 5.6.4 | 5.6.5 | test only |
| `test` / `test_api` / `test_core` | 1.30.0 / 0.7.10 / 0.6.16 | 1.31.1 / 0.7.12 / 0.6.18 | test toolchain |
| `ultralytics_yolo` | 0.3.1 | 0.3.4 | **scanner-critical** — review for detection fixes |
| `google_cloud_*` | 0.4.0 | 0.5.2 | API clients |
| `matcher`, `meta`, `vector_math`, `win32`, `gtk`, etc. | — | — | transitive/platform |

Most are constrained transitively. **Action:** run `flutter pub outdated`,
prioritize `ultralytics_yolo` (scanner accuracy) and the `test`/`mockito`
toolchain (CI parity); treat `xml` major and `json_serializable` as a separate,
tested change since they affect codegen output.

---

## 4. P3 — IME focus thrash and viewport-metrics spam

### Log evidence

Hundreds of consecutive:

```
D/FlutterJNI: Sending viewport metrics to the engine.
```

interleaved with a repeating soft-keyboard cycle:

```
ImeTracker: onRequestShow ... SHOW_SOFT_INPUT
ImeTracker: onCancelled at PHASE_CLIENT_ANIMATION_CANCEL
ImeTracker: onRequestHide ... HIDE_SOFT_INPUT
ImeTracker: onHidden
```

### Assessment

The keyboard is being requested and immediately cancelled/hidden in tight
loops, and the engine is receiving an unusually high volume of viewport-metric
updates. This points to a **rebuild loop on the translate screen** — likely a
`TextField`/`FocusNode` fighting `autofocus` or a provider rebuilding on every
frame. This is plausibly the *same* churn that disposes
`profileSummaryNotifierProvider` mid-`await` in issue #1, so the two may share a
root cause.

### Real root cause (confirmed via second log)

A second runtime log showed on-device inference completing cleanly with **no**
provider crash, yet the IME thrash persisted — so #4 is **independent** of #1.

In `translate_screen.dart`, `keyboardOpen` is derived from
`view.viewInsets.bottom`, which animates frame-by-frame as the soft keyboard
slides in/out. `keyboardOpen` gates two structural changes:

1. The `constrainedKeyboardLayout` branch returns a **bare panel root**, while
   the normal path returns a full `Column` — a completely different ancestor
   chain.
2. The `TranslateHeader` and `TranslateModelStatusBanner` are conditionally
   added/removed, shifting the body's index inside the `Column`.

Both re-parent the deeply-nested `_InputField`, **disposing its `FocusNode`**
mid-edit. That fires `HIDE_SOFT_INPUT_BY_INSETS_API`; focus is then
re-requested, the keyboard re-shows, the next animation frame flips
`keyboardOpen` again, and the cycle repeats — the observed
`onRequestShow → onCancelled → onRequestHide → onHidden` loop and the
unbounded "Sending viewport metrics to the engine" stream.

`preserveFocusedPortraitInput` was meant to prevent this but depends on
`_textInputFocused`, which is set **asynchronously** by the focus listener — so
on the first keyboard-animation frame it is still `false`, the constrained
branch fires, the field re-mounts, and the loop starts before the flag can
ever flip true.

### Resolution (2026-05-17)

- Added a screen-owned `GlobalKey` (`_textInputFieldKey`) threaded through
  `TranslateTextModePanel` → `_BottomInputArea` → `_InputField`. Flutter now
  **migrates** the same `Element`/`State` (and its `TextEditingController` +
  `FocusNode`) across every layout branch instead of re-mounting it, so focus —
  and the keyboard — survive the layout switches entirely.
- Made `preserveFocusedPortraitInput` **eager**: in portrait text mode the
  keyboard can only be open because the field is focused, so the layout locks
  immediately rather than waiting a frame for the async focus flag. This
  removes the per-frame structural churn that drove the viewport-metric spam.

Net effect: the keyboard stays up while editing; the show/hide loop and the
sustained viewport-metric flood are eliminated. Severity raised P3 → P2 since
it caused a continuous main-thread relayout storm during normal typing.

#### Second cause (found in third log, also fixed)

A third runtime log — captured with the on-device model working — showed the
layout loop gone (hundreds of cycles → ~2) but a short keyboard burst
**starting exactly at `[Gemma] local inference completed`**. Cause:
`translate_text_mode_panel.dart` set the input field
`enabled: inputEnabled && !state.aiBusy`. While the AI streamed, `aiBusy` was
true, so the `TextField` was **disabled** — which drops focus and force-closes
the keyboard (`HIDE_SOFT_INPUT`). On completion `aiBusy` flipped false, the
field re-enabled, focus restored, and the keyboard reopened, then bounced once
as insets settled.

Fix: the input field now stays `enabled: inputEnabled` regardless of `aiBusy`.
Re-entry is still prevented by `_TextActionsRow` (buttons disable on `busy`)
and the controller guard (`if (!state.hasInput || state.aiBusy) return;`), so
keeping the field editable during inference is safe and removes the
post-inference IME burst.

> **Verification note:** GlobalKey / widget-`State` identity changes are **not**
> applied by Flutter hot reload (`r`). A hot **restart** (`R`) or a full
> rebuild/reinstall is required to validate these fixes.

---

## 5. P4 — `FlutterRenderer: Width is zero. 0,0` at startup

```
D/FlutterRenderer: Width is zero. 0,0
```

Logged a few times during cold start before the first real frame. This is a
transient pre-layout state and is almost always benign; flagged only for
completeness. No action unless a blank/zero-size first frame is observed
visually.

---

## Recommended priority order

1. **Fix #1** (P0 crash) — add `ref.mounted` guards in `ProfileSummaryNotifier`;
   smallest, highest-impact change.
2. **Investigate #4** (rebuild/IME loop) — likely shares a root cause with #1
   and is on the actively-modified branch.
3. **Decide on #2** — confirm whether a local Gemma model should ship/install;
   at minimum short-circuit the per-message fallback and add a download hint.
4. **Schedule #3** — dependency bump as an isolated, tested change.
5. **Note #5** — no action; monitor.
