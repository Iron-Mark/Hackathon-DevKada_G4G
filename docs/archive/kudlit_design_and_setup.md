# 🏛️ Kudlit Project & Design Guide

This document provides a comprehensive overview of the **Kudlit** project, bridging the gap between design philosophy and technical implementation.

---

## 🌟 1. The Big Picture
f- **Core Tech:** YOLOv12 for character detection, Gemma 4 for linguistic understanding.
- **Goal:** Offline-first accessibility for endangered writing systems.
- **Mascot:** *Butty*, a friendly blue-and-peach creature who handles the emotional lift of the app.

---

## 🎨 2. Visual Design System (Kudlit DS)
The design system is a "mobile-first" translation of a paper-and-ink aesthetic.

### **Core Foundations**
- **Vibe:** Blue-tinted paper surfaces, dark denim ink, and friendly hand-drawn illustrations.
- **Colors:**
  - **Surface:** `KudlitColors.paper` (`#E9EEFF`) - A pale blue-tinted "paper" feel.
  - **Ink:** `KudlitColors.blue300` / `blue400` - Deep navy for headings and primary buttons.
  - **Accents:** Semantic use only (Danger, Success, Warning). No decorative gradients.
- **Typography:**
  - **UI Font:** **Geist** (Google Fonts) for all interface text.
  - **Display Font:** **Baybayin Simple TAWBID** - Used *strictly* for Baybayin glyphs.
- **Layout:**
  - **Grid:** 4-pixel base grid.
  - **Corners:** `10px` default radius for cards; `8px` for buttons.
  - **Shadows:** Soft, crisp shadows (`0 4px 4px 0 rgba(0,0,0,0.25)`).

### **Content Voice**
- **Butty's Voice:** First-person, playful, and encouraging ("Wow! I can read Baybayin!").
- **UI Chrome:** Plain, functional, and imperative ("Start Learning", "Clear History").

---

## 🏗️ 3. Architecture & State Management
Kudlit follows a **Feature-First Clean Architecture** pattern.

### **Directory Structure**
- `lib/app/`: Routing (`go_router`) and global theme setup.
- `lib/core/`: Shared design system, base classes, and configuration.
- `lib/features/`: Isolated modules (e.g., `auth`, `scanner`, `home`).
  - `domain/`: Pure Dart. Entities, Repository Interfaces, Use Cases. **Zero Flutter deps.**
  - `data/`: Repositories, Data Sources, and Models.
  - `presentation/`: Widgets, Screens, and Riverpod Providers.

### **State Management**
- **Riverpod:** Use `@riverpod` annotations.
- **Patterns:**
  - Prefer `AsyncNotifier` for asynchronous data.
  - Use `Either<Failure, T>` (`fpdart`) for error handling in the domain layer.
  - Presentation maps failures to user-facing messages.

---

## 🛠️ 4. Coding Standards
Strict adherence to these rules ensures consistency and maintainability.

- **Widget Decomposition:**
  - `build()` methods **must not exceed 40 lines**.
  - Subtrees deeper than 3 levels **must** be extracted into their own widget files.
  - No logic in widgets; they are strictly for layout and reading state.
- **Type Safety:**
  - **No `var`**: Always use explicit types.
  - **No `dynamic`**: Except at raw JSON boundaries.
- **Naming:**
  - `snake_case` for files.
  - `PascalCase` for classes.
  - `camelCase` for variables/functions.
- **Formatting:** Single quotes for strings; trailing commas everywhere.

---

## ⚠️ 5. Technical Gotchas & Workflow

### **Critical Constraints**
- **`build_runner` is broken:** Do not run it. You must **hand-write `.g.dart` files** or use standard boilerplate.
- **Domain Purity:** The `domain/` folder must not import `package:flutter`. Use `package:meta` for `@immutable`.
- **Target Target:** Web is the primary design target during development. Native uses `ultralytics_yolo` for live YOLO scanning; web uses browser webcam preview with capture-based TFLite detection from the active vision model URL. Keep platform-specific scanner code behind `kIsWeb` or conditional imports.

### **Quick Commands**
```bash
flutter analyze          # RUN BEFORE COMMITTING
flutter run -d chrome    # Design work
dart format lib/ test/   # Formatting
```

---

## 📂 6. Key Design Assets
- **Mascots:** `assets/brand/Butty*.webp`
- **Theme:** `lib/core/design_system/kudlit_theme.dart`
- **Colors:** `lib/core/design_system/kudlit_colors.dart`
- **Shells:** `lib/core/design_system/widgets/kudlit_auth_shell.dart`
