# Local Gemma Concurrency — Audit & Fix Plan

Date: 2026-05-17
Branch: `feat/audit-suite-and-p0-fixes`
Status: Plan — awaiting approval before implementation

## 1. Symptom

On device, "multiple local models run at the same time" and the phone lags
during/after using Baybayin AI features (scanner live evaluation, Butty chat,
translate, lessons).

## 2. Root Cause (single, verified)

`localGemmaDatasourceProvider` is `@Riverpod(keepAlive: true)` — there is
**exactly one** `LocalGemmaDatasource` for the whole app, owning **one**
native `InferenceModel _activeModel` and **one** `InferenceChat _chat`.

That single object is driven by eight independent, concurrently-activatable
callers, none of which coordinate:

| Caller | Entry | File |
|---|---|---|
| Butty chat | `generate` | `butty_chat_controller.dart:137` |
| Translate text | `generate` | `translate_text_controller.dart:348` |
| Scanner live eval | `analyzeImage` + `generate` + follow-up | `scanner_evaluation_provider.dart:90,100,136` |
| Translate sketchpad | `analyzeImage` (reads datasource directly) | `translate_sketchpad_controller.dart:106,122,153` |
| Learning lessons | `analyzeImage` + `generate` | `lesson_controller.dart:138,145` |
| Butty help sheet | `generateResponse` | `butty_help_sheet.dart:127` |
| Memory-extraction | `generateResponse`, `unawaited` background | `memory_extraction_service.dart:82` |
| Readiness / prewarm | `getActiveModel` | `local_gemma_datasource.dart` probe / `ensureModelLoaded` |

`generate()` and `analyzeImage()` have **no concurrency control**. The only
serialized path is `probeReadiness` (`_probing` / `_pendingProbe`); that
discipline is absent everywhere else.

When any two callers overlap (reachable cases: scanner auto-evaluates frame
N+1 while frame N runs; a new Butty/translate request or scanner open while
the background memory-extraction `generateResponse` is still running):

1. **Concurrent native inference loops** share and clobber the single
   `_chat` — one caller's `addQueryChunk` interleaves into another's stream.
2. **`analyzeImage` tears the model down mid-use**: it `close()`s `_chat`,
   and if the active model is text-only it `close()`s `_activeModel` and
   reloads a vision model via `getActiveModel(supportImage: true)` — while a
   concurrent `generate()` still iterates the old `_activeModel!` / `_chat!`.
   During that window **two native InferenceModel contexts are resident at
   once** → the memory/CPU spike that lags the device. The `finally` then
   nulls `_chat` out from under the other caller.
3. **Stale work is never cancelled.** Scanner's `_translationGeneration`
   counter and stream consumers only discard late Dart values; the native
   `generateChatResponseAsync()` keeps running to completion. Rapid frames /
   repeated triggers pile up a backlog of running native inferences.

**One-sentence root cause:** a single shared native model/session is driven
by many features with zero serialization or cancellation, so overlapping
calls run concurrent inferences and trigger model teardown-while-in-use,
leaving multiple native model contexts resident → the lag.

## 3. Chosen Policy — Supersede + Queue

- **Same-lane requests supersede.** A newer request in a lane cancels the
  older in-flight/queued request in that same lane. Used for rapid,
  self-replacing streams: scanner live-frame evaluation, sketchpad feedback.
- **Cross-lane requests queue (FIFO).** Distinct features (chat, translate,
  lessons, background memory-extraction, readiness) run strictly
  one-after-another — never concurrently, never cancelling each other. No
  Butty reply is killed by a background task.
- **Invariant:** at most one native operation (generate / analyzeImage /
  model load / close) touches the engine at any instant.

Lanes:

| Lane | Callers | Behaviour |
|---|---|---|
| `scan` | scanner translation + image analysis + follow-up | supersede previous `scan` |
| `sketch` | translate sketchpad | supersede previous `sketch` |
| `chat` | Butty, translate, lessons text, help sheet | queue |
| `system` | memory-extraction, readiness, prewarm | queue (lowest priority, never cancels others) |

## 4. Design

### 4.1 New unit — `InferenceGate` (pure Dart, isolated, TDD-able)

`lib/features/translator/data/datasources/inference_gate.dart`

Responsibilities:

- **Serialize:** maintain a single `Future` tail; every `run()` awaits the
  previous completion before starting. Guarantees the one-op-at-a-time
  invariant.
- **Supersede:** `run({required String lane, ...})` — on enqueue, if a
  pending or in-flight op shares `lane`, mark it cancelled before this one
  proceeds.
- **Cancellation handle:** each op receives a `CancelSignal` (a checked
  flag + `isCancelled` getter). Long-running streams poll it between tokens
  and abort cooperatively (break loop → close session → return).

Public surface (draft):

```dart
class CancelSignal {
  bool get isCancelled;
  void throwIfCancelled(); // throws InferenceCancelled
}

class InferenceGate {
  Future<T> run<T>(String lane, Future<T> Function(CancelSignal) op);
  Stream<T> runStream<T>(String lane, Stream<T> Function(CancelSignal) op);
  void cancelLane(String lane);
}
```

What it does NOT do: it does not know about Gemma. It is a generic
serializer + lane-supersession primitive — that is why it is unit-testable
without the native engine.

### 4.2 Wire into `LocalGemmaDatasource`

- Hold one `InferenceGate _gate`.
- `generate()` / `analyzeImage()` become `_gate.runStream(lane, (sig) async* { ... })`.
  Inside the loop: `if (sig.isCancelled) { break; }` each iteration; the
  existing `finally` closes the per-op `InferenceChat`.
- `probeReadiness`, `ensureModelLoaded`, model `close()`/reload, and
  `dispose()` route through `_gate.run('system', ...)` so a load can never
  overlap an in-flight generate (kills root-cause #2). The current
  `_probing` / `_pendingProbe` coalescing is replaced by the gate.
- `analyzeImage`'s model close/reload now executes only when it owns the
  gate, so no other call holds `_activeModel` during teardown.
- Lane is a new optional parameter on `generate` / `analyzeImage`
  (default `chat`); the `AiDatasource` interface gains the optional param.

### 4.3 Caller changes

- `scanner_evaluation_provider.dart`: pass lane `scan`. Each new `evaluate`
  / `requestFollowUp` supersedes the prior `scan` op (replaces the
  ineffective generation-counter approach for native cancellation; the
  counter stays for Dart-side state correctness).
- `translate_sketchpad_controller.dart`: pass lane `sketch`; also stop
  reading `localGemmaDatasourceProvider` directly — go through the
  repository like every other caller (consistency; keeps lane routing in
  one place).
- `memory_extraction_service.dart`: lane `system` (queued, never supersedes
  foreground chat).
- Butty / translate / lessons / help sheet: default `chat` lane (queue).

## 5. TDD Test Plan (Phase 4)

`test/features/translator/data/datasources/inference_gate_test.dart`
(runs as pure Dart — unaffected by the `flutter_gemma` native-asset issue
that currently blocks `flutter test` on this macOS host):

1. **Serialization:** two overlapping `run` ops never execute concurrently
   (assert max in-flight == 1 via a shared counter).
2. **FIFO across lanes:** ops from different lanes complete in start order.
3. **Same-lane supersession:** enqueuing a second `scan` op cancels the
   first; the first's `CancelSignal.isCancelled` becomes true and it stops
   early.
4. **Cancelled op is observable:** a superseded streaming op stops emitting
   after cancellation and releases the gate so the next op runs.
5. **System lane never cancels chat:** a `system` op does not supersede an
   in-flight `chat` op.

Each test written red-first, watched fail, then `InferenceGate` implemented
minimally to green.

## 6. Affected Files

- **New:** `lib/features/translator/data/datasources/inference_gate.dart`
- **New:** `test/features/translator/data/datasources/inference_gate_test.dart`
- `lib/features/translator/data/datasources/local_gemma_datasource.dart`
- `lib/features/translator/data/datasources/ai_datasource.dart` (lane param)
- `lib/features/translator/data/repositories/ai_inference_repository_impl.dart` (thread lane)
- `lib/features/scanner/presentation/providers/scanner_evaluation_provider.dart`
- `lib/features/home/presentation/providers/translate_sketchpad_controller.dart`
- `lib/features/translator/presentation/providers/memory_extraction_service.dart`

## 7. Verification

- TDD suite for `InferenceGate` green.
- `flutter analyze` clean.
- Manual device check: scanner live-scan + open Butty + trigger translate in
  quick succession → only one inference active, no two-model memory spike,
  no lag; Butty replies are never truncated by background memory-extraction.
- (`flutter test` full-suite still blocked by the upstream `flutter_gemma`
  macOS prebuilt dylib relink failure — unrelated; note for CI/Linux.)

## 8. Out of Scope

- Replacing `flutter_gemma`, model quantization, or memory-budget tuning.
- The web `analyzeImage` `UnsupportedError` path (already correct: cloud
  fallback).
