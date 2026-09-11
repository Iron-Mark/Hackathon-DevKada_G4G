# Kudlit Learning Architecture: YOLO + Corpus + Gemma

Based on the architectural discussions with Jam, the Kudlit app employs a sophisticated three-tier pipeline to teach Baybayin effectively. This pipeline handles the unique challenges of the script, particularly its inherent ambiguities.

## The Challenge: Baybayin Ambiguity
Baybayin is not a 1-to-1 mapping with the Latin alphabet. It relies heavily on context and shared symbols:
- **Shared Base Characters:** `Da` and `Ra` traditionally share the exact same character (ᜇ).
- **The Kudlit System:** A dot placed above a character changes its vowel sound to either `E` or `I`. A dot placed below changes it to `O` or `U`. 
- **Contextual Meaning:** Because one shape (e.g., a character with a top kudlit) can mean two different things (e.g., "be" or "bi"), mechanical translation often fails without understanding the word being spelled (like "bibe" vs "tite").

## The Three-Tier Solution

### 1. YOLO + Corpus (The "Correctness" Layer)
- **Role:** Mechanical Vision.
- **How it works:** The user draws a character on the screen or points their camera. The YOLOv12 model detects the bounding boxes of the strokes, and the local TFLite classification model (the Corpus) identifies the shapes.
- **Limitation:** It only sees shapes. If the user draws ᜇ, the Corpus simply says "This is Da/Ra". It doesn't know which one the user intended to write.

### 2. Gemma as the Smart Corrector & Disambiguator (The "Understanding" Layer)
- **Role:** Contextual Logic.
- **How it works:** Gemma takes the raw, ambiguous output from the Corpus and uses linguistic context to figure out the user's intent. If the lesson asks the user to write "Bibe" (duck) and the Corpus detects two "Ba" shapes with top kudlits, Gemma knows the user successfully wrote "Bibe", rather than getting confused by the "E/I" overlap.
- **Multimodal capabilities:** By feeding both the image and the Corpus output to Gemma, it can verify if the stroke order or kudlit placement makes sense in the context of the requested word.

### 3. Gemma as the Feedback Engine & Companion (The "Retention" Layer)
- **Role:** Personal Tutor (embodied by the mascot, Butty).
- **How it works (Feedback):** Instead of a binary "Correct/Incorrect" prompt, Gemma provides specific, linguistic feedback. If a user forgets a bottom kudlit on "bo", Gemma says: *"You drew 'ba'. To make it 'bo', remember to add the kudlit (dot) below the character."*
- **How it works (Companion):** Gemma closes the learning loop. It can read what the user wrote and respond conversationally, prompting the user to write back, transforming the app from a flashcard game into an interactive language companion.

## What This Means for Development
This architecture splits responsibilities beautifully:
1. **The App UI (Flutter):** Handles the drawing pad and camera feed.
2. **The Scanner (YOLO):** Handles raw shape detection.
3. **The Brain (Gemma):** Handles grading, feedback, and conversation.

By designing the lessons (like the JSON files we just created) with `expected` text arrays, we are scaffolding the exact data that Gemma needs to verify the user's intent against their drawn input!