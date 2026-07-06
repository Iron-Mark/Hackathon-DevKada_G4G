# Realtime Scan Aggregator Plan

> Status: Implemented; scan layout hardening verified by `scripts/scan-layout-overlap-pass.ps1` on 2026-05-10
> Owner: Scanner feature
> Date: 2026-05-05

## Context

The scan tab (`lib/features/home/presentation/screens/scan_tab.dart`) already runs the YOLO Baybayin detector continuously through `ScannerCamera`, throttled to a detection callback every 250 ms. Each callback produces a fresh list of `BaybayinDetection`s, which is shown live as an aggregated bounding box + chip (`AggregatedBoundingBox`) and only "finalised" into the result panel when the user taps the shutter.

Two issues with this flow:

1. **Snap-style finalisation** — the result panel reads the *current frame* at the instant of the shutter tap. If that frame is noisy, the user gets a noisy reading even though earlier frames may have been cleaner.
2. **No temporal voting** — frame-to-frame variance from the model (e.g., `bi` vs `be` flickering) is never reconciled. The chip just shows whatever the latest frame said.

The goal of this aggregator is to add a lightweight rolling vote on top of the existing realtime stream, so the UI can show the *most-frequent* candidate from a recent window — and surface it automatically when the camera goes idle, without requiring a shutter tap.

**Non-goals for v1:** dictionary lookup, weighted voting by confidence, replacing the shutter snapshot flow, refactoring the scanner camera filters.

---

## Design

### Where the aggregator lives

Per project rules (`CLAUDE.md` → "All logic lives in Riverpod notifiers/providers"), the aggregator is **not** a `StatefulWidget` field. It lives inside the existing `ScanTabController` (`lib/features/scanner/presentation/providers/scan_tab_controller.dart`), which is already the natural integration point — `applyLiveDetections(...)` is called every detection tick from `ScannerCamera.onDetections`.

### Data flow

```
YOLO frame
  → ScannerCamera (throttle 250ms, confidence/edge/IoU/consecutive-hit filters)
  → ScannerCamera.onDetections(filtered)
  → ScanTabController.applyLiveDetections(detections)
        ├── ScannerNotifier.update(detections)            ← existing live overlay
        └── _pushAggregatedScan(detections)               ← NEW
              ├── derive tokens (sorted by left, lowercased)
              ├── candidate = permuteBaybayin(tokens).first
              ├── push candidate to rolling buffer (cap 50, evict oldest)
              ├── update freq map
              ├── recompute winner (max-freq entry)
              ├── if winner changed → state = state.copyWith(aggregatedWinner: top)
              └── reset 1s idle timer
                    on fire → clear buffer + freq, KEEP winner in state
```

### State changes

`ScanTabState` gains a single new field:

```dart
final String? aggregatedWinner;
```

Plus the standard `clearAggregatedWinner` flag in `copyWith` (matching the existing `clearSelectedImage` pattern).

The rolling buffer (`Queue<String>`) and frequency map (`Map<String, int>`) are kept as **private fields on the controller**, not in the immutable state — they are implementation detail and mutating them in-place would not trigger Riverpod rebuilds anyway. Only `aggregatedWinner` is exposed.

### Constants

```dart
static const int _kAggMaxBuffer = 50;                          // rolling window size
static const Duration _kAggIdleTimeout = Duration(milliseconds: 1000);
```

50 entries × 250 ms throttle ≈ 12.5 s of history at full detection rate. Empty frames don't push, so the effective window is "last 50 frames that had detections."

### Idle behaviour

- Each non-empty `_pushAggregatedScan` cancels and re-arms the idle timer.
- Empty frames (no detections this tick) do **not** reset the timer — they let it expire.
- On expiry: clear `_aggBuffer` + `_aggFreq`. **Do not** clear `aggregatedWinner` — the user should keep seeing the last stable read after pulling the camera away.

### Reset triggers

`aggregatedWinner` is cleared (and the rolling state torn down via `_resetAggregator()`) on:

- `dismissResult()` — user dismissed the result panel.
- `clearSelectedImage()` — exiting gallery image mode.
- `pickImageFromGallery()` — switching modes; the live winner shouldn't bleed into image mode.
- `ref.onDispose` — controller torn down.

`onShutterTapped()` is **not** a reset trigger. After the user dismisses the snapshot panel, the winner banner reappears (if still set) so they can keep referencing the rolling read.

### Selection of the candidate

For v1 we use `permuteBaybayin(tokens).first` as the per-frame candidate. This is deterministic given a fixed token list, so frames with identical tokens vote for the same string. Ambiguous-glyph permutations (e.g. `bi_be`) all collapse to the first option for voting purposes; this is acceptable for v1 because the goal is stability across noisy frames, not disambiguation. Future work can swap in a dictionary-match scorer.

---

## UI

A new `_AggregatedWinnerBanner` widget sits in `scan_tab.dart`, placed in the existing `Stack` at the same vertical slot as `_ScanResultPanel`:

```dart
if (!scanState.resultVisible && scanState.aggregatedWinner != null)
  Positioned(
    left: 14,
    right: 14,
    bottom: controlsBottom + 96,
    child: _AggregatedWinnerBanner(winner: scanState.aggregatedWinner!),
  ),
```

The banner is **mutually exclusive** with the snapshot result panel — so the shutter flow is unchanged. Banner visual: card with a small "Settled reading" eyebrow label, the winning word in display weight, and a discreet sparkle icon to differentiate from the live green chip on the bounding box. No interactions in v1 (no tap-to-copy, no dismiss button) — keep it informational.

### Visual hierarchy

| Surface | Source | Lifetime |
|---|---|---|
| Green chip on bounding box | `perms.first` of the *current frame* | Live, vanishes when frame goes empty |
| Winner banner above controls | Mode of recent rolling buffer | Persists across idle; cleared on dismiss / mode switch |
| Result panel | Snapshot from shutter tap | Modal-ish, until dismissed |

---

## Files touched

1. `lib/features/scanner/presentation/providers/scan_tab_controller.dart`
   - Add imports: `dart:async`, `dart:collection`, `package:kudlit_ph/core/utils/baybayify.dart`.
   - `ScanTabState`: add `aggregatedWinner` to ctor, `initial`, `copyWith` (with `clearAggregatedWinner` flag).
   - `ScanTabController`: add buffer, freq map, idle timer, two constants.
   - Override `build()` to register `ref.onDispose(_resetAggregator)`.
   - New private methods: `_resetAggregator()`, `_pushAggregatedScan(detections)`.
   - `applyLiveDetections` calls `_pushAggregatedScan(detections)` after the existing notifier update.
   - `dismissResult`, `clearSelectedImage`, `pickImageFromGallery` all reset aggregator + clear winner.

2. `lib/features/home/presentation/screens/scan_tab.dart`
   - New `_AggregatedWinnerBanner` widget.
   - One conditional `Positioned` in the main `Stack`.

No changes to `ScannerCamera`, `AggregatedBoundingBox`, `ScannerNotifier`, or any datasource — the aggregator is purely additive.

---

## Why this matches "drop-in"

- No new files, no new providers, no new repositories.
- Reuses the existing throttled detection callback as the only input — no new model calls, no extra inference.
- Buffer + freq map are O(1) per push (queue evict + map update), bounded at 50 entries, ~kilobytes of memory.
- Single `Timer` instance, cancelled on dispose.
- Backwards compatible: shutter, gallery, frozen-detections, permutation dialog all behave exactly as today. The banner is purely additive UI.

---

## Risks / open questions

- **Vote-splitting on similar glyphs** — frames detecting `[pa, bi, da]` and `[pa, be, da]` produce different candidates. With 50-entry window, the more frequent one wins, which is correct. Edge case: if both are detected exactly evenly, the winner ties on `>` comparison and stays whichever was reached first. Acceptable.
- **Stale winner after camera move-away** — by design, the winner persists. If users find this confusing, add a longer secondary timeout (e.g., 10 s of idle → clear winner) in v2.
- **Interaction with `evaluate(...)`** — the aggregator does not currently trigger `scannerEvaluationProvider.evaluate(...)`. The Gemma translation still requires shutter tap. v2 candidate: auto-trigger `evaluate` on idle when winner is stable for N consecutive ticks.

---

## Out of scope (v2+)

- Dictionary-aware candidate selection (rank perms by Filipino word likelihood).
- Confidence-weighted voting (each frame's vote weighted by mean detection confidence).
- Auto-translate on stable winner (skip shutter entirely for clear scans).
- Persisted aggregator stats (e.g., "you scanned this word 5× today" history hints).

---

## Scan layout hardening proof

Run:

```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-layout-overlap-pass.ps1
```

Artifacts:

- `qa-artifact/scan-layout-strict-overlap/report.json`
- `qa-artifact/scan-layout-strict-overlap/scan-layout-overlap-contact-sheet.html`
- `qa-artifact/scan-layout-strict-overlap/matrix/`
- `qa-artifact/scan-layout-strict-overlap/transitions/`

---

## Acceptance checklist

- [x] `aggregatedWinner` set after >=1 non-empty live detection frame.
- [ ] Winner stable across noisy frames (manually verify with shaky camera over a printed Baybayin word).
- [ ] Banner appears when result panel is hidden and winner is set.
- [ ] Banner hidden when result panel is open.
- [ ] Idle for 1 s → buffer cleared (verifiable: next single detection becomes new winner immediately).
- [ ] Winner survives idle clear; cleared only on dismiss / gallery / dispose.
- [ ] `flutter analyze` clean for the current branch.
- [ ] No regression in shutter flow, gallery flow, permutation dialog freeze.
