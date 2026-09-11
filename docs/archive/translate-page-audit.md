# Translate Page Audit

Date: 2026-05-04

## Scope

This audit covers the current `Translate` tab implementation in:

- [lib/features/home/presentation/screens/translate_screen.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/features/home/presentation/screens/translate_screen.dart)
- [lib/features/home/presentation/widgets/translate/](/Users/kuya/Documents/Gemma/kudlit-app/lib/features/home/presentation/widgets/translate)
- [lib/core/utils/baybayify.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/core/utils/baybayify.dart)

It does not cover:

- scanner OCR translation flow
- Butty chat
- backend translation history tables beyond whether the page uses them

## Current Product Reality

The current page is a local transliteration tool, not a full translation experience.

What the page does today:

- accepts typed text via a `TextField`
- toggles between `Filipino -> Baybayin` and `Baybayin -> Filipino`
- converts input immediately on each change
- renders Baybayin output using the `Baybayin Simple TAWBID` font
- shows placeholder `Copy` and `Share` action pills
- shows a mic button with visual toggle state only

What the page does not do today:

- no real speech-to-text
- no AI translation
- no semantic explanation of results
- no history persistence
- no bookmarking
- no share/copy implementation
- no validation, suggestions, or error messaging

## Working Well

### 1. Basic page structure works

The screen is simple and stable:

- output area at the top
- direction toggle in the middle
- input strip at the bottom

Relevant files:

- [translate_screen.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/features/home/presentation/screens/translate_screen.dart)
- [output_stage.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/features/home/presentation/widgets/translate/output_stage.dart)
- [input_strip.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/features/home/presentation/widgets/translate/input_strip.dart)

### 2. Instant local conversion works

The page updates output immediately whenever text changes.

- `baybayifyWord(text)` is used for `Filipino -> Baybayin`
- `baybayinToLatin(text)` is used for `Baybayin -> Filipino`

Relevant files:

- [translate_screen.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/features/home/presentation/screens/translate_screen.dart:25)
- [baybayify.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/core/utils/baybayify.dart:26)

### 3. Empty state is clear enough

The empty state communicates the expected input flow:

- user should type or speak
- output area stays visually quiet until input exists

Relevant file:

- [empty_output.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/features/home/presentation/widgets/translate/empty_output.dart)

### 4. Baybayin output presentation is readable

The main output uses:

- dedicated Baybayin font
- large type size
- centered layout
- a second line for Latin text

Relevant file:

- [filled_output.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/features/home/presentation/widgets/translate/filled_output.dart)

## Partially Working

### 1. Direction toggle works, but labels oversell the feature

The toggle says:

- `Filipino -> Baybayin`
- `Baybayin -> Filipino`

But the implementation is transliteration-oriented, not language-aware translation. It does not understand grammar, spelling variants, context, or phrase meaning.

Relevant file:

- [direction_toggle.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/features/home/presentation/widgets/translate/direction_toggle.dart)

### 2. Reverse mode is technically present, but input expectations are unclear

`baybayinToLatin()` does not consume actual Baybayin glyphs. It only parses an internal ASCII-like encoding made of:

- Latin consonants
- vowels
- `+`
- spaces

That means a user pasting real Baybayin Unicode characters will not get the intended reverse conversion.

Relevant file:

- [baybayify.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/core/utils/baybayify.dart:77)

### 3. Input sanitization is consistent, but destructive

`_normalize()` strips non-alpha content:

- punctuation removed
- numbers removed
- symbols removed
- unsupported characters removed silently

This keeps the algorithm simple, but users get no explanation when characters disappear.

Relevant file:

- [baybayify.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/core/utils/baybayify.dart:13)

### 4. Mic button is interactive visually only

The mic button changes appearance and flips `_listening`, but it does not start speech recognition or produce text.

Relevant files:

- [translate_screen.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/features/home/presentation/screens/translate_screen.dart:19)
- [mic_button.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/features/home/presentation/widgets/translate/mic_button.dart)

## Not Working Or Missing

### 1. Copy action does nothing

The `Copy` pill has `onTap: () {}`.

Relevant file:

- [output_actions.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/features/home/presentation/widgets/translate/output_actions.dart:13)

### 2. Share action does nothing

The `Share` pill also has `onTap: () {}`.

Relevant file:

- [output_actions.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/features/home/presentation/widgets/translate/output_actions.dart:16)

### 3. No translation history integration

The app has profile counters and database references for translation history and bookmarks, but the translate page does not write to them or read from them.

Relevant files:

- [profile_management_datasource.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/features/home/data/datasources/profile_management_datasource.dart:40)
- [profile_management_section.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/features/home/presentation/widgets/settings/profile_management_section.dart:96)
- [translate_screen.dart](/Users/kuya/Documents/Gemma/kudlit-app/lib/features/home/presentation/screens/translate_screen.dart)

### 4. No bookmark/save flow

There is no UI or logic for:

- saving a translation
- pinning favorites
- reopening recent translations

### 5. No model- or AI-assisted explanation

The page does not explain:

- why a Latin string maps to a given Baybayin output
- ambiguous syllables
- invalid combinations
- pronunciation help
- modern Filipino spelling caveats

### 6. No user feedback for unsupported input

Examples of missing feedback:

- punctuation removed
- numbers removed
- unsupported Baybayin glyph input
- mixed-script input

The current behavior silently normalizes or drops content.

### 7. No actual Baybayin Unicode parsing in reverse mode

This is one of the biggest product gaps. The reverse path is named `Baybayin -> Filipino`, but the utility currently parses only the internal Latin-plus-`+` representation.

This will confuse real users unless the page either:

- accepts actual Baybayin glyphs, or
- clearly states that reverse mode expects encoded transliteration text

### 8. No tests found for this page or utility

There appear to be no dedicated tests for:

- `translate_screen.dart`
- `baybayify.dart`
- copy/share behavior
- reverse conversion edge cases

## UX Problems

### 1. The page promise is larger than the implementation

The product language says `Translate`, but the feature is closer to:

- transliterate text
- preview Baybayin rendering

That mismatch will create user disappointment.

### 2. The page is not yet interactive enough

Current interaction depth is low:

- type
- toggle
- see output

There are no assistive states like:

- examples
- suggestions
- teaching moments
- explanations
- corrections
- actions after conversion

### 3. Reverse mode lacks trust

Because there is no explicit explanation of input format and no validation hints, users cannot reliably tell whether reverse conversion is working correctly.

### 4. Placeholder actions reduce perceived completeness

Buttons for copy/share are visible but non-functional. That makes the page feel unfinished immediately.

## Technical Constraints In Current Logic

### 1. `baybayifyWord()` is rule-based and narrow

It currently models:

- consonant + `a`
- consonant + other vowel
- bare consonant -> `+`
- standalone vowel
- spaces

It does not model richer language or orthography behavior beyond that.

### 2. Output depends on font rendering convention

The transliteration result is an encoded string intended for the Baybayin font, not necessarily a true Unicode Baybayin text pipeline.

That is fine for visual rendering, but it makes interoperability weaker for:

- copy/share
- search
- reverse parsing
- persistence

### 3. Page state is fully local widget state

`TranslateScreen` is a `StatefulWidget` with:

- `TextEditingController`
- `_latinToBaybayin`
- `_listening`

There is no provider/notifier layer for:

- history
- analytics
- recent entries
- saved translations
- async actions

## Recommended Next Improvements

### Priority 1: Fix broken expectations

1. Implement real `Copy`.
2. Implement real `Share`.
3. Rename or clarify the feature if it remains transliteration-only.
4. Add visible helper text for reverse mode input expectations.

### Priority 2: Make it trustworthy

1. Add validation and helper states for unsupported characters.
2. Show when input was normalized or stripped.
3. Add tests for `baybayifyWord()` and `baybayinToLatin()`.
4. Define whether reverse mode should support actual Baybayin Unicode.

### Priority 3: Make it useful

1. Add recent translations.
2. Add bookmark/save.
3. Add quick examples users can tap.
4. Add pronunciation or syllable breakdown.
5. Add explanation chips like `final consonant`, `implied a`, `vowel mark`.

### Priority 4: Make it interactive

1. Add speech-to-text if the mic remains visible.
2. Add paste detection and auto-cleanup messaging.
3. Add educational overlays for how the output was formed.
4. Add a bridge to Butty for explanation, not just raw conversion.

## Suggested Future Feature Shape

If you want the page to feel complete, the best product split is:

### Option A: Keep this as a transliterator

Position it as:

- `Baybayin Converter`
- fast, offline, instant

Then improve:

- accuracy
- copy/share/save
- breakdown/explanation
- Unicode support

### Option B: Make it a real translate experience

Keep the current instant converter, but add:

- AI explanation
- context-aware translation notes
- OCR handoff from scanner
- phrase meaning help
- history and saved outputs

## Audit Summary

### Working

- typed input
- instant local conversion
- direction toggle
- Baybayin font rendering
- clear empty state

### Partial

- reverse conversion
- mic interaction
- feature naming
- input normalization

### Broken or missing

- copy
- share
- history
- bookmarks
- save flow
- validation
- real speech input
- actual Baybayin Unicode reverse support
- tests
