# Technical Implementation Plan: Gemma Learning Features

**Assigned to:** Kuya (Learnings Lead)
**Goal:** Implement the three major learning features requested by Jam, integrating the existing YOLOv12 object detection with Gemma's multimodal and conversational capabilities to create an intelligent Baybayin tutor.

---

## Feature 1: Smart Translation & "Teacher Mode" (Scanner/Camera)
**Context:** When the user takes a picture using the Scanner tab.

### The Flow
1. **Capture:** The user presses the shutter button.
2. **Detection:** YOLOv12 analyzes the image and returns an array of bounding boxes and classified characters (the Corpus output).
3. **Multimodal Analysis:** Both the raw image and the YOLOv12 array are fed into Gemma.
4. **Classification:** Gemma analyzes the image to determine the source material. Is this printed text (e.g., a sign or document) or handwritten text?

### Execution Paths
*   **Path A: Printed Text (Translation Mode)**
    *   Gemma acts as a smart disambiguator. It takes the YOLO array, resolves ambiguities (e.g., distinguishing between E/I or O/U based on word context), and provides a clean, accurate translation of the text.
*   **Path B: Handwritten Text (Teacher Mode)**
    *   Gemma activates "Teacher Mode."
    *   It analyzes the handwriting against standard Baybayin forms.
    *   **UX Requirement:** Instead of a wall of text, Gemma will provide structured, actionable tips. E.g., *"Your 'Ba' is clear, but the curve on your 'Ka' is a bit too sharp. Try rounding the bottom stroke."* These tips will be displayed in a clean, non-intrusive UI card below the image.

---

## Feature 2: Butty Coach (Context-Aware Lesson Tutoring)
**Context:** The "Ask Butty" feature within the specific learning modules (e.g., Vowels, Consonants).

### The Flow
1. **Context Injection:** When a user opens a lesson (e.g., `consonants_01.json`), the specific lesson ID and current step (e.g., "Learning Ba") are injected into Gemma's system prompt.
2. **Scoped Assistance:** If the user is struggling and taps the Butty icon, Gemma knows exactly what they are trying to learn.
3. **Dynamic Response:** Gemma does not give generic answers. If the user asks, "How do I write this?", Gemma responds specifically about the current character: *"You are working on 'Ba'. Remember, it looks like a heart shape. Start from the top left..."*

### Feature 2.5: Real-Time Sketchpad Feedback
**Context:** The drawing pad within the lessons.

1. **Stroke Capture:** As the user draws on the sketchpad, the stroke coordinates are captured.
2. **Evaluation:** When the user submits, the image of the stroke and the intended target character (from the JSON `expected` array) are sent to Gemma.
3. **Form Analysis:** Gemma evaluates the shape, proportion, and form of the drawn character against the standard.
4. **Feedback Loop:** Gemma provides instant, specific feedback on the stroke execution (e.g., *"Good effort! Next time, make the loop on the left a bit larger."*), displayed directly on the sketchpad UI.

---

## Feature 3: Butty Assistant (Global Companion)
**Context:** The general Butty chat interface accessible from the Home/Learn tab.

### The Flow
1. **Role:** A versatile, engaging companion for all things Baybayin.
2. **Capabilities:** 
    *   Answering general historical or linguistic questions about Baybayin.
    *   Translating English/Tagalog words into Baybayin on the fly.
    *   Testing the user's knowledge (e.g., *"Want to play a quick game? What does this character mean: ᜃ?"*).
3. **Implementation:** A dedicated chat UI (`ButtyChatScreen`) powered by Gemma, maintaining conversation history for continuous context.

---

## Technical Write-up Requirements
*(To be expanded as implementation progresses, per Jam's instructions)*

*   **Architecture:** Detail the handoff between the Flutter UI (presentation), YOLO (vision), and Gemma (reasoning).
*   **Prompt Engineering:** Document the specific system prompts used to switch Gemma between Translation, Teacher, Coach, and Assistant modes.
*   **Data Structures:** Explain how the JSON curriculum files (`consonants_01.json`, etc.) provide the necessary state and context for Gemma's evaluations.