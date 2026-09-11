# Kudlit Master Plan: Gemma Learning Integration

> **For agentic workers:** This is the unified master plan for integrating Gemma's capabilities into the Kudlit app. Implement this plan step-by-step using `subagent-driven-development` or `executing-plans`.

**Goal:** Implement the three major learning features requested by Jam, integrating the existing YOLOv12 object detection with Gemma's multimodal and conversational capabilities to create an intelligent Baybayin tutor. This relies on a 3-tier architecture: YOLO + Corpus (Correctness) -> Gemma (Understanding & Disambiguation) -> Gemma (Retention & Coaching).

**Tech Stack:** Flutter, Riverpod, Local TFLite (YOLO), Gemma 4 (LLM).

---

## Phase 1: Feature Setup & Core Prompts

To make Gemma act correctly in different contexts, we need to establish strong system prompts and an interface for Flutter to communicate with the Gemma model.

### Task 1.1: Define Gemma Roles (System Prompts)
We need to create the system prompts that dictate how Gemma behaves.

**Files:**
- Create: `lib/features/learning/domain/entities/gemma_prompts.dart`

- [ ] **Step 1: Write the System Prompts**
Create a new file holding the specific prompts for the three modes:
1.  **Translator Mode:** "You are a Baybayin translator. Given an array of detected shapes from YOLO, disambiguate them using linguistic context and provide the correct Latin translation. Do not provide conversational filler."
2.  **Teacher Mode:** "You are Butty, a friendly Baybayin teacher. Analyze the provided image of handwritten Baybayin. Provide 1-2 short, encouraging, and specific tips on how to improve the stroke shapes. Do not use generic feedback."
3.  **Coach Mode:** "You are Butty, a Baybayin tutor. The user is currently learning the character [INJECT_CHARACTER_HERE]. Answer their questions specifically regarding this character and its traditional form."

---

## Phase 2: Feature 1 - Smart Translation & "Teacher Mode" (Scanner)

**Context:** The user takes a picture in the Scanner tab. YOLO detects the bounding boxes, and Gemma analyzes the image to decide if it's printed or handwritten text.

### Task 2.1: Multimodal Handoff (Scanner to Gemma)
We need to modify the Scanner's capture logic to pass the image and the YOLO array to the Gemma interface.

**Files:**
- Modify: `lib/features/scanner/presentation/providers/scanner_notifier.dart` (or equivalent)

- [ ] **Step 1: Update the capture logic**
When the shutter is pressed, wait for YOLO to finish its detection. Then, bundle the `List<BaybayinDetection>` and the raw image bytes.
- [ ] **Step 2: Gemma classification**
Send the bundle to Gemma and ask: "Is this printed text or handwritten text?"
- [ ] **Step 3: Route the result**
If Printed -> Activate Translator Mode prompt -> Display clean text.
If Handwritten -> Activate Teacher Mode prompt -> Display the UI feedback card.

---

## Phase 3: Feature 2 - Butty Coach & Sketchpad Feedback

**Context:** The user is inside a lesson (e.g., `consonants_01.json`). They can ask Butty for help, or they can draw on the sketchpad and get real-time feedback.

### Task 3.1: Context Injection for Butty Coach
The existing "Ask Butty" feature needs to know *what* the user is learning.

**Files:**
- Modify: `lib/features/home/presentation/screens/learn_tab.dart`
- Modify: `lib/features/learning/presentation/widgets/butty_help_sheet.dart` (or equivalent chat interface)

- [ ] **Step 1: Pass the context**
When the user taps the Butty icon inside a lesson, pass the current `LessonStep`'s `expected` array (e.g., `["ba"]`) to the chat interface.
- [ ] **Step 2: Inject the prompt**
Prepend the user's chat message with the Coach Mode system prompt, injecting the target character.

### Task 3.2: Real-Time Sketchpad Feedback
When the user finishes drawing on the pad, we evaluate the strokes.

**Files:**
- Modify: `lib/features/home/presentation/widgets/learn/drawing_pad_sheet.dart`

- [ ] **Step 1: Capture and Send**
In `_onAttemptSubmitted()`, capture the final stroke image. Send it to Gemma along with the `expected` target character.
- [ ] **Step 2: Evaluate Form**
Ask Gemma: "Does this drawing look like the Baybayin character [TARGET]? Provide a 1-sentence tip on how to improve the shape."
- [ ] **Step 3: Display Feedback**
Render Gemma's response natively in the Flutter UI instead of the hardcoded `_kSteps` feedback.

---

## Phase 4: Feature 3 - Butty Assistant (Global Companion)

**Context:** The general chat interface accessed from the main Home tab.

### Task 4.1: General Knowledge Prompt
Update the `ButtyChatScreen` to use a global assistant prompt.

**Files:**
- Modify: `lib/features/home/presentation/screens/butty_chat_screen.dart`

- [ ] **Step 1: Connect to Gemma**
Currently, `ButtyChatScreen` uses hardcoded `if (lower.contains('baybayin'))` logic. We need to replace this by wiring the chat input directly to the Gemma provider.
- [ ] **Step 2: Assistant Prompt**
Set the system prompt to: "You are Butty, a friendly Baybayin assistant. Answer general historical or linguistic questions about Baybayin, and translate simple English/Tagalog words into Baybayin when asked."