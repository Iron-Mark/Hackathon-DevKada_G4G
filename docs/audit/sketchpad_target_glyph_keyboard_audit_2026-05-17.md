# Sketchpad Target-Glyph Keyboard Audit — 2026-05-17

**Reported symptom:** In Translate → Sketchpad, tapping the "Target glyph"
field opens the keyboard and it immediately closes, in a loop. A target
glyph can never be entered, so "Get Feedback" stays disabled and the
feature is unusable.

**Status:** Root cause confirmed by code trace + runtime-log signature.
No fix applied (audit only).

---

## Summary

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | Sketchpad target field: IME show/hide thrash — keyboard opens then closes in a loop, target glyph cannot be entered | **P1 — Functional block** | Root-caused, unfixed |
| 2 | Same re-mount wipes in-progress strokes and typed target every cycle | **P2 — Data loss** | Same root cause |
| 3 | Sketchpad panel overflows when keyboard is open (fixed-height canvas + `Spacer`, no scroll/inset) | **P3 — Layout** | Latent, same path |

This is the **same defect class** as issue #4 in
`runtime_log_audit_2026-05-17.md` (IME thrash on the text field). That fix
was applied to the **text** panel only and never extended to the
**sketchpad** panel.

---

## Log evidence

Identical signature to the previously-fixed text-mode thrash:

```
ImeTracker: onRequestShow ... reason SHOW_SOFT_INPUT
ImeTracker: onCancelled at PHASE_CLIENT_ANIMATION_CANCEL
ImeTracker: onRequestHide ... reason HIDE_SOFT_INPUT
ImeTracker: onRequestHide ... reason HIDE_SOFT_INPUT_BY_INSETS_API
ImeTracker: onHidden
```

repeating, interleaved with viewport-metric spam.

## Root cause

`translate_screen.dart` — the keyboard-preservation guard only ever
evaluates true for **text** mode:

```dart
final bool textMode = pageState.mode == TranslateWorkspaceMode.text;
final bool preserveFocusedPortraitInput =
    (textMode && portraitKeyboardOpen) ||              // false in sketchpad
    (_textInputFocused && (...));                      // _textInputFocused
                                                       // is set ONLY by the
                                                       // text panel's
                                                       // onInputFocusChanged
```

In sketchpad mode:

- `textMode` is `false` → first clause false.
- `_textInputFocused` is fed exclusively by the text panel
  (`onInputFocusChanged: _setTextInputFocused`). The sketchpad target
  `TextField` (`translate_sketchpad_mode_panel.dart:239`) has **no
  `FocusNode`** and reports focus to nobody → second clause false.

So `preserveFocusedPortraitInput` is **permanently false** in sketchpad
mode. When the keyboard begins to open, `constrainedKeyboardLayout`
becomes true and the `LayoutBuilder` child changes widget type:

- Not constrained: `Column( … Expanded( switch → sketchpadPanel() ) … )`
- Constrained: `switch → sketchpadPanel()` returned bare

The widget at the `LayoutBuilder` child slot flips between `Column` and
`TranslateSketchpadModePanel`. Flutter cannot reuse the `Element`. Unlike
the text field — which received the `_textInputFieldKey` `GlobalKey` fix
so its `Element`/`State` migrates across the branch — the sketchpad panel
has **no `GlobalKey`**. So `_TranslateSketchpadModePanelState` is disposed
and recreated:

1. Tap target field → focus → keyboard animates in → `keyboardOpen` true.
2. `preserveFocusedPortraitInput` false → `constrainedKeyboardLayout` true.
3. Branch flips `Column` → bare panel → `TranslateSketchpadModePanel`
   State disposed, `TextField`'s internal `FocusNode` destroyed.
4. Focus lost → keyboard dismissed (`HIDE_SOFT_INPUT_BY_INSETS_API`).
5. `keyboardOpen` flips false → branch flips back → panel re-mounts.
6. Loop. User sees "opens and closes" and can never type a target.

### Collateral (same root cause)

`_targetController`, `_strokes`, and `_current` live in
`_TranslateSketchpadModePanelState`. Every re-mount **wipes the user's
drawing and typed target**, not only the keyboard.

### Latent layout bug on the same path

`_InlineCanvas` is a fixed `height: 300` followed by a `Spacer()` with no
scroll view and no keyboard-inset accommodation. Even if focus survived,
an open keyboard would overflow the sketchpad panel (RenderFlex overflow).

## Recommended fix (mirror the text-mode fix)

1. Add a screen-owned `GlobalKey` for the sketchpad panel; pass it as the
   panel's `key` so Flutter migrates the same `Element`/`State` across the
   layout-branch flip instead of re-mounting (preserves keyboard, strokes,
   and typed target).
2. Extend `preserveFocusedPortraitInput` to cover sketchpad mode — either
   add `((pageState.mode == sketchpad) && portraitKeyboardOpen)` or
   generalize the eager clause to `portraitKeyboardOpen` regardless of
   mode — so the layout locks on the first keyboard-animation frame.
3. Hardening: give the sketchpad target `TextField` a `FocusNode` that
   reports through to `_setTextInputFocused` (parity with the text field),
   and make the sketchpad body scrollable / inset-aware to remove the
   overflow.

> **Verification note:** `GlobalKey` / `State`-identity changes are **not**
> applied by Flutter hot reload (`r`). A hot **restart** (`R`) or full
> rebuild is required to validate.

---

## Resolution (2026-05-17) — eliminate the keyboard surface

Chosen over the GlobalKey patch because it removes the root cause for this
surface entirely rather than surviving it: the free-text target field was
**replaced with a tap-to-pick glyph selector**, so the sketchpad no longer
has any editable text and the keyboard never opens there. With no keyboard
animation, the `keyboardOpen`-driven layout-branch flip cannot fire from
the sketchpad, so the re-mount loop (issue #1) and the stroke/target wipe
(issue #2) are both unreachable in normal use.

- `baybayin_target_glyphs.dart` — 17 base glyphs as static const data
  (glyph + romanized label; label still feeds the AI prompt unchanged).
- `sketchpad_target_glyph_sheet.dart` — modal bottom-sheet grid picker.
- `sketchpad_target_glyph_button.dart` — bottom-bar trigger showing the
  current selection; opens the sheet (no `TextField`/`FocusNode`).
- `translate_sketchpad_mode_panel.dart` — dropped `_targetController`,
  its `dispose`, and the `didUpdateWidget` text sync; the `_BottomBar`
  `TextField` is now `SketchpadTargetGlyphButton`.

Secondary win: the picker accepts 3-letter labels like `nga`, which the
old `maxLength: 2` field could not even enter.

**Residual (now unreachable, not fixed):** `_TranslateSketchpadModePanelState`
still has no `GlobalKey`, so a layout-branch flip from some *other* future
keyboard/short-height path would still re-mount and wipe in-progress
strokes. Out of scope here since the sketchpad has no remaining trigger;
worth a `GlobalKey` if an editable surface is ever reintroduced.

> A word-builder variant was prototyped and then reverted by request —
> the single-glyph tap picker is the shipped resolution.

**Verification status:** `flutter analyze` clean on all touched files.
The regression test (`translate_density_test.dart` → "sketchpad target
uses a tap picker with no keyboard surface") was written but **could not
be executed locally**: `flutter test` on this macOS host aborts before
any test runs due to an unrelated `flutter_gemma` native-asset relink
failure (`install_name_tool` on `libGemmaModelConstraintProvider.dylib`).
Behavioral verification pending on device / CI.
