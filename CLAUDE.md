# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Kudlit** is a vision-based Baybayin (ancient Philippine script) translator and learning app. It uses a YOLO model (converted to TFLite) for on-device character recognition and Gemma 4 for language understanding. The app targets Android, iOS, and Web, but all UI/UX design is mobile-first.

## Commands

```bash
# Install dependencies
flutter pub get

# Run the app (web for design work)
flutter run -d chrome

# Run on a connected Android device
flutter run -d android

# Build for web
flutter build web

# Build for Android (release)
flutter build apk --release

# Analyze (lint)
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/features/scanner/domain/usecases/translate_baybayin_test.dart

# Run scan layout hardening verification
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-layout-overlap-pass.ps1

# Run tests matching a name pattern
flutter test --name "should return translation"

# Format code
dart format lib/ test/
```

## Architecture

Feature-first Clean Architecture: features are the top-level organizational unit; within each feature, layers follow Clean Architecture (domain → data → presentation).

```
lib/
├── main.dart
├── app/                        # App-wide setup: routing, theming, ProviderScope
├── core/                       # Shared utilities, base classes, constants, errors
│   ├── error/                  # Failure types, exceptions
│   ├── usecases/               # Base UseCase abstract class
│   └── utils/
└── features/
    └── <feature_name>/
        ├── domain/             # Pure Dart: entities, repository interfaces, use cases
        │   ├── entities/
        │   ├── repositories/   # Abstract interfaces only
        │   └── usecases/
        ├── data/               # Implementations: repos, data sources, models
        │   ├── datasources/    # Local (TFLite, Hive) and remote (Gemma API)
        │   ├── models/         # Data transfer objects extending domain entities
        │   └── repositories/   # Concrete implementations of domain interfaces
        └── presentation/       # Flutter: widgets, screens, Riverpod providers/notifiers
            ├── providers/      # Riverpod providers and state notifiers
            ├── screens/
            └── widgets/
```

**Current feature slices:**
- `scanner` — native camera/gallery YOLO plus web webcam preview with capture-based TFLite detection from the active vision model URL
- `translator` — Baybayin glyphs → romanized/Filipino text via Gemma 4
- `learn` — interactive lessons and character reference

## Key Technical Decisions

### State Management: Riverpod
- Use `@riverpod` code generation (`riverpod_annotation`) for all providers.
- Prefer `AsyncNotifierProvider` for async state, `NotifierProvider` for sync.
- Providers live in `presentation/providers/` within their feature.
- Repository and data source instances are exposed via providers in `data/` or `core/`.

### Dependency Rule
Dependencies flow inward only: `presentation` → `domain` ← `data`. The `domain` layer has zero Flutter dependencies—pure Dart only. Use cases accept repository interfaces, never concrete implementations.

### ML Models
- YOLO model is bundled as a TFLite asset and loaded via `ultralytics_yolo`.
- Gemma 4 integration should be isolated behind a repository interface in `translator/domain/repositories/` so the underlying model (on-device vs. API) can be swapped.

### Platform Notes
- Web is the primary design target during development; test layout on Chrome.
- Web has browser webcam preview and capture-based TFLite detection when a compatible model URL is configured. Native-only capabilities, such as torch control and local model setup, still need `kIsWeb` guards and fallback UI.
- Scan layout hardening proof lives under `qa-artifact/scan-layout-strict-overlap/`; regenerate it with `scripts/scan-layout-overlap-pass.ps1`.

## Coding Rules

### Dart/Flutter Style

**Naming**
- Files: `snake_case.dart`
- Classes/enums: `PascalCase`
- Variables/functions: `camelCase`
- Private members: `_camelCase`
- Constants: `camelCase` (not `SCREAMING_SNAKE`)

**Types**
- Never use `var` — always declare explicit types.
- `final` for anything that won't be reassigned; `late final` when initialization is deferred.
- `dynamic` is banned except at explicit interop boundaries (e.g., raw JSON before casting to a model).

**Strings**
- Single quotes everywhere (`'hello'`, not `"hello"`).

**Formatting**
- Trailing commas on all multi-line argument lists and collection literals.
- Max line length: 80 (dart format default).

**Imports**
- Order: `dart:` → `flutter:` → packages → local; blank line between groups.
- Relative imports within the same feature; `package:kudlit_ph/...` imports across features.

### Widget Rules

**Decomposition (strict)**
- `build()` must not exceed 40 lines. Extract if it does.
- Any subtree with 3+ levels of nesting must be extracted into its own widget.
- Never use private builder methods (`_buildSomething()`) to decompose UI — extract a real widget class instead. Private methods hide widget tree structure and break DevTools inspection.
- Each extracted widget lives in its own file.
- Prefer `const` constructors wherever possible.
- Prefer `StatelessWidget`; use `StatefulWidget` only for genuinely local ephemeral state. Reach for Riverpod before `StatefulWidget`.

**No logic in widgets**
- Widgets are for layout and display only — no business logic, no data transformation, no conditional chains that derive state.
- All logic lives in Riverpod notifiers/providers or use cases. Widgets only call methods and read state.
- Computed/derived values belong in a provider, not in `build()`.

### Error Handling
Domain layer returns `Either<Failure, T>` (using `fpdart` or `dartz`). Use cases propagate typed `Failure` subclasses; presentation layer maps them to user-facing messages.

## Commit Rules

1. **Branch off `dev`** — all work starts from a new branch cut from `dev`, never from `main`.
2. **Prefix with type** — commit messages must start with a conventional type:
   - `feat:` new feature
   - `fix:` bug fix
   - `chore:` tooling, dependencies, config
   - `refactor:` code change with no behavior change
   - `test:` adding or updating tests
   - `docs:` documentation only
   - `style:` formatting, no logic change
3. **Atomic and concise** — one logical change per commit; subject line under 72 characters; no filler words.
4. **Run the linter before committing** — always run `flutter analyze` and resolve all issues before creating a commit.
