# Kudlit development guide

Kudlit is a Flutter application for Baybayin scanning, translation, and learning. This file is the canonical coding and architecture guide; current commands and environment names are summarized in the root `AGENTS.md`.

## Commands

```powershell
flutter pub get
flutter run -d chrome
flutter run -d android
flutter build web
flutter build apk --release
flutter analyze
flutter test
flutter test test/features/scanner/domain/usecases/translate_baybayin_test.dart
flutter test --name "should return translation"
dart format lib/ test/
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-layout-overlap-pass.ps1
```

The UI is mobile-first even when Chrome is used for design work. Validate native
camera, torch, model, and gallery behavior on the relevant target platform.

## Architecture

Use feature-first clean architecture:

```text
lib/
  app/          app-wide routing, theme, and ProviderScope
  core/         shared configuration, errors, use cases, and utilities
  features/
    <feature>/
      domain/   pure Dart entities, repository interfaces, and use cases
      data/     data sources, models, and repository implementations
      presentation/ providers, screens, and widgets
```

Dependencies flow `presentation -> domain <- data`. Domain code must not import Flutter. Repository implementations stay behind domain interfaces.

## State, ML, and platform boundaries

- Use generated Riverpod providers. Prefer `AsyncNotifier`/`Notifier` over ad-hoc widget state for domain behavior.
- YOLO/TFLite loading and platform selection stay behind the scanner data/provider boundary.
- Gemma integration stays behind the translator repository interface so local and server-backed implementations remain swappable.
- Web needs `kIsWeb` guards and fallback UI for native-only capabilities.
- Server-only model credentials belong in the Supabase function environment, never the bundled Flutter `.env` asset.

## Dart and widget rules

- Use explicit types, `final` for non-reassigned values, and `dynamic` only at narrow interop boundaries.
- Use single quotes, trailing commas, standard Dart formatting, snake_case files, and PascalCase types.
- Keep widget `build()` methods small. Extract deeply nested or reusable subtrees into real widget classes rather than private builder methods.
- A widget `build()` method should not exceed 40 lines. Extract any subtree with
  three or more nesting levels, keep each extracted widget in its own file, and
  do not use private `_buildSomething()` methods as a substitute for widgets.
- Widgets display state and dispatch actions; transformations and business decisions belong in providers/use cases.
- Domain failures use `Either<Failure, T>`; presentation maps failures to user-facing messages.
- Prefer `const` and `StatelessWidget` where behavior allows.
- Order imports as Dart, Flutter, packages, then local imports, with blank lines
  between groups. Use relative imports within one feature and
  `package:kudlit_ph/...` imports across feature boundaries.

## Change and verification rules

- Branch from `dev`, not `main`, for normal feature work. Use conventional commit prefixes if a commit is later authorized.
- Run `flutter analyze`, relevant tests, format checks, and platform builds appropriate to the change.
- Regenerate `.g.dart`/Freezed output through build_runner; never hand-edit generated files.
- Scanner layout changes must rerun `scripts/scan-layout-overlap-pass.ps1` and preserve its QA artifacts.
- Never commit secrets or server-only keys.
