# Baybayin Consonant Curriculum Design

## 1. Overview
Expand the offline-first Baybayin learning curriculum in Kudlit by adding all 14 base consonants and the *kudlit* vowel modifiers. This will create a complete foundational alphabet course.

## 2. Architecture & Data
The curriculum relies entirely on the existing `AssetLessonDataSource` and the `Baybayin Simple TAWBID` font. No new machine learning models or heavy image assets are required. The font handles all ligature mapping (e.g., typing 'ka' renders ᜃ).

### Existing Capabilities
The new lessons will utilize the currently implemented `LessonMode` enum:
- `reference`: Shows the glyph and explains its shape.
- `draw`: Prompts the user to trace the glyph.
- `freeInput`: Prompts the user to type the romanization.

## 3. Curriculum Grouping
The 14 consonants and the kudlit rule are grouped into 5 distinct JSON files to prevent cognitive overload.

### 1. `consonants_01.json` (The Core Four)
- **Characters:** Ba, Ka, Da/Ra, Ga
- **Concept:** Introduce the first set of consonants and the rule that Da/Ra share a glyph.

### 2. `consonants_02.json` (The Waves)
- **Characters:** Ha, La, Ma, Na
- **Concept:** Characters with wave-like horizontal strokes.

### 3. `consonants_03.json` (The Loops)
- **Characters:** Nga, Pa, Sa, Ta
- **Concept:** Characters with distinct loops or curves.

### 4. `consonants_04.json` (The Tails)
- **Characters:** Wa, Ya
- **Concept:** The final two consonants.

### 5. `kudlit_01.json` (Changing Sounds)
- **Characters:** Ba -> Bi/Be -> Bo/Bu
- **Concept:** Teaching the top and bottom *kudlit* marks to change the inherent "a" sound.

## 4. Implementation Steps
1. Create the 5 JSON files in `assets/lessons/` following the schema of `vowels_01.json`.
2. Update the `AssetLessonDataSource` or `LearnTab` UI to list these new lessons instead of using placeholders.
3. Verify that tapping a lesson loads the correct JSON and progresses through the `LessonStageScreen`.