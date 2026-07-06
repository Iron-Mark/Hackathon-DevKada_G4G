# Translate Page Implementation Plan

Date: 2026-05-04

## Current Implementation State (latest check)

Status summary: core translation-page implementation is largely in place and
matches most target behaviors in this plan.

Implemented now:

- dual-mode workspace (`Text` + `Sketchpad`) in one `Translate` route
- dedicated page/text/sketchpad providers under
  `lib/features/home/presentation/providers/`
- explicit Gemma source control (`Online` / `Offline`) with status banner
- offline readiness probing before AI-backed actions
- disabled AI actions when offline readiness is pending/unavailable
- visible input feedback messages for punctuation/numbers/unsupported characters and
  reverse-mode guidance
- cleaned-input preview in text mode when normalization changes what the
  converter uses
- encoded reverse-mode examples near the input (`ka`, `ki`, `ku`, `k+`) that
  can be tapped to fill the text field
- sketchpad target requirement + feedback request flow
- AI response source labels (`Offline Gemma`, `Online Gemma`, fallback label)

Still pending or needing follow-through:

- provider and widget test coverage listed in this plan
- remaining UX polish for deeper explanation/failure states beyond helper copy
- explicit reverse-mode Unicode acceptance decision (keep encoded helper vs native Unicode parser)

## Purpose

This document turns the findings in
[translate-page-audit.md](translate-page-audit.md)
into an implementation plan for the next version of the
`Translate` experience.

It is written to follow the architecture rules in
[CLAUDE.md](../CLAUDE.md):

- feature-first clean architecture
- Riverpod-driven state
- no business logic in widgets
- reusable repository-based AI integration
- extracted widgets instead of private builder methods

## Product Goal

Expand the current `Translate` tab from a simple transliteration screen
into a guided workspace with two modes:

- `Text` for typed Filipino or Baybayin transliteration
- `Sketchpad` for handwriting input and Gemma-based feedback

The page should also make Gemma runtime behavior explicit:

- `Online` and `Offline` modes must be visible
- local model readiness must be checked before user actions run
- the UI must show whether a response came from offline Gemma, online
  Gemma, or cloud fallback

## Scope

This plan covers:

- [translate_screen.dart](../lib/features/home/presentation/screens/translate_screen.dart)
- [lib/features/home/presentation/widgets/translate/](../lib/features/home/presentation/widgets/translate/)
- translator AI integration used by the page
- local/offline Gemma readiness behavior reused from Butty
- user feedback states for typed and drawn input

This plan does not cover:

- scanner OCR pipeline redesign
- Butty chat redesign beyond reusing its offline readiness pattern
- database history schema changes beyond page-level integration points

## Current Gap Summary

Based on
[translate-page-audit.md](translate-page-audit.md),
the current screen is useful as a local transliteration utility, but it
does not yet behave like an interactive translation workspace.

Main gaps:

- sketchpad mode and offline readiness are implemented
- feedback about stripped/unsupported input is visible in the text-mode input
  area; cleaned-input previews are implemented for normalization changes
- reverse-mode input invalidity messaging and tap-to-fill encoded examples are
  covered
- AI-assisted explanation depth is still partial

## Target Experience

### 1. Dual-mode translate workspace

The `Translate` screen should become a two-mode page:

- `Text`
- `Sketchpad`

`Text` mode keeps the current transliteration flow, but adds clearer
feedback and optional AI explanation.

`Sketchpad` mode lets the user draw Baybayin input and request Gemma
feedback on the drawn glyph or phrase.

This should remain one route, not two separate screens.

### 2. Explicit Gemma source control

The page should expose the active Gemma source in the translate
experience:

- `Online`
- `Offline`

If the user selects `Offline`, the screen must verify local readiness
before allowing AI-backed actions.

Required visible states:

- `Preparing offline Gemma...`
- `Offline ready`
- `Offline model found, but local runtime is unavailable`
- `Offline failed, cloud fallback used`

The page should never silently leave the user guessing which model path
was used.

### 3. Better feedback for user input

The page should explain what happened to the user input when needed.

Examples:

- punctuation removed
- numbers removed
- unsupported characters ignored
- reverse mode input is not real Baybayin Unicode
- transliteration result may be approximate for modern spelling

This should be product-facing guidance, not raw debug output.

## Proposed UX Structure

### Top section

- page title
- short helper copy
- Gemma source selector or source status chip
- offline readiness banner when applicable

### Mode selector

- `Text`
- `Sketchpad`

### Main content

For `Text` mode:

- output stage
- output actions
- direction toggle
- input area
- optional AI explanation card

For `Sketchpad` mode:

- target glyph or syllable selector
- drawing canvas
- clear/reset action
- `Get Feedback` action
- Gemma response card

### Footer state behavior

The input and action controls should be disabled when:

- offline readiness is still loading
- offline mode was selected but the model is unusable
- a Gemma request is already running

The disabled state must explain why.

## Architecture Plan

### Feature and layer responsibilities

The new behavior should follow existing clean architecture boundaries.

#### Presentation

Add or refactor page-specific presentation state in:

- `lib/features/home/presentation/providers/`
- `lib/features/home/presentation/widgets/translate/`

Presentation responsibilities:

- render page mode
- render loading/error/ready states
- trigger actions through providers
- never embed transliteration or Gemma routing logic directly in widgets

#### Domain

If the page grows beyond basic UI orchestration, add domain-level
contracts for:

- translate feedback requests
- sketchpad analysis requests
- user-facing validation results

Domain should remain pure Dart.

#### Data

Reuse existing translator/Gemma data sources and repositories where
possible.

Data responsibilities:

- local Gemma inference
- cloud fallback behavior
- model readiness probing
- translation feedback fetching

## Provider Design

Introduce a translate-page-focused provider layer instead of storing
mixed state directly in the screen widget.

Recommended state domains:

- active mode: `text` or `sketchpad`
- text input state
- text output state
- input feedback state
- sketchpad target state
- sketchpad analysis state
- Gemma source preference state
- offline readiness state
- AI result source state

Recommended provider split:

- one provider for page mode
- one provider/notifier for text translation state
- one provider/notifier for sketchpad interaction state
- one provider for translate-page Gemma readiness
- one provider/notifier for AI explanation requests

This keeps widget builds small and follows `CLAUDE.md` guidance against
logic-heavy widgets.

## Text Mode Plan

### Base behavior

Keep the current fast local transliteration path.

The immediate result should still come from:

- `baybayifyWord(...)`
- `baybayinToLatin(...)`

That local result should remain available even if AI is unavailable.

### New feedback behavior

Add structured input feedback such as:

- `Removed punctuation from input.`
- `Numbers were ignored.`
- `Reverse mode currently expects Baybayin-compatible input format.`
- `This transliteration may not capture full word meaning.`

### AI explanation behavior

AI feedback should be explicit, not automatic on every keystroke.

Recommended actions:

- `Explain`
- `Check Input`

Reason:

- avoids unnecessary online/offline inference calls
- preserves fast local text editing
- keeps architecture simpler and more testable

## Sketchpad Mode Plan

### V1 behavior

Sketchpad mode should support:

- drawing Baybayin input
- choosing an intended target glyph or syllable
- requesting Gemma feedback on the drawing

The initial version should require a target before analysis.

Reason:

- generic drawing feedback will be too vague
- a target makes the response more actionable

### Expected controls

- target selector or text field
- drawing canvas
- clear button
- analyze or feedback button
- response card

### Gemma prompt behavior

Reuse the sketchpad evaluation approach already present in the learning
feature, but adapt it for translate mode where lesson context is absent.

## Offline Gemma UX Rules

Translate should reuse the Butty offline readiness pattern, but make the
result clearer in-page.

### Required readiness flow

When `Offline` is selected:

1. check whether the selected local model exists
2. reactivate it if needed
3. probe whether it can actually be opened for inference
4. only enable AI-backed actions when the probe succeeds

### Required UX rules

- disable `Explain`, `Check Input`, and `Get Feedback` while readiness is
  pending
- show a visible loading state while the local engine is initializing
- if offline fails, show a visible explanation
- if cloud fallback is used, label the response accordingly

### Response source labels

AI result cards should display one of:

- `Offline Gemma`
- `Online Gemma`
- `Cloud fallback used`

## UI Guidelines

### Loading

Use direct, short status copy:

- `Preparing offline Gemma...`
- `Checking local model...`
- `Offline ready`

Avoid vague states like `Loading...` with no context.

### Disabled inputs

Disabled controls must explain the reason.

Examples:

- `Offline model is still loading.`
- `Select a target glyph first.`
- `Offline model is unavailable for this action.`

### Feedback tone

Feedback should be:

- concise
- instructional
- non-technical
- visible near the relevant input

Avoid surfacing native or plugin exception text directly in the main UI.

## Suggested File Direction

This is a suggested direction, not a strict file list.

Potential additions or refactors:

- `lib/features/home/presentation/providers/translate_page_controller.dart`
- `lib/features/home/presentation/providers/translate_text_controller.dart`
- `lib/features/home/presentation/providers/translate_sketchpad_controller.dart`
- `lib/features/home/presentation/widgets/translate/translate_mode_switch.dart`
- `lib/features/home/presentation/widgets/translate/translate_gemma_status_banner.dart`
- `lib/features/home/presentation/widgets/translate/translate_text_mode_panel.dart`
- `lib/features/home/presentation/widgets/translate/translate_sketchpad_mode_panel.dart`
- `lib/features/home/presentation/widgets/translate/translate_feedback_card.dart`

If shared translator logic becomes broad enough, feature extraction into a
dedicated `translator` presentation flow can be considered later, but the
next step should stay incremental.

## Delivery Phases

### Phase 1: Text mode UX upgrade

Status: **Completed**

- keep current transliteration flow
- add mode switch shell
- add Gemma source status UI
- add offline readiness banner
- add input feedback messages
- make output actions production-ready

### Phase 2: Sketchpad mode integration

Status: **Completed**

- embed sketchpad mode in translate
- add target selector
- wire Gemma feedback request path
- add loading, disabled, and result states

### Phase 3: Response-source clarity and polish

Status: **In progress**

- label AI result source ✅
- surface local failure and fallback states clearly ✅
- improve helper copy and edge-case messaging ✅
- add test coverage ⏳

## Test Plan

### Provider tests

- switching between `Text` and `Sketchpad`
- offline readiness pending to ready
- offline readiness pending to unavailable
- local success path
- local failure with visible fallback state
- sketchpad target requirement behavior

### Widget tests

- mode switch rendering
- disabled controls while offline is loading
- visible helper copy for invalid input
- response-source labels
- text mode and sketchpad mode separation

### Functional checks

- text transliteration still updates immediately
- reverse mode communicates limitations clearly
- sketchpad feedback cannot run without required target input
- offline mode does not allow AI-backed actions before readiness succeeds

## Acceptance Criteria

The plan is complete when the upgraded translate page:

- supports both `Text` and `Sketchpad` modes in one screen
- exposes `Online` and `Offline` Gemma state clearly
- blocks AI actions until offline readiness is complete
- provides useful feedback for typed input issues
- supports Gemma-powered sketchpad feedback
- labels whether the answer came from offline, online, or fallback
- keeps logic inside providers and repositories rather than widgets

## Recommended Next Execution Order

1. Add the page-level mode and Gemma status shell.
2. Move translate page state into dedicated providers.
3. Add text-mode feedback states and action wiring.
4. Add sketchpad mode with target requirement.
5. Add response-source labeling and tests.

## Updated Next Execution Order (remaining)

1. Add/complete provider tests for mode switching, offline readiness states,
   local success, and fallback behavior.
2. Add/complete widget tests for mode rendering, disabled controls, and source
   labels.
3. Decide whether cleanup preview should grow into a full before/after
   explanation, or stay as the current compact `Used as` helper.
4. Decide whether to keep copy-based share behavior or add platform share.
