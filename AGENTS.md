# AGENTS.md

## Scope

Kudlit — Flutter app for Baybayin scanning (YOLO/TFLite), translation (Gemma),
and lessons. On `main` (synced with `origin/main`; working tree clean apart
from this uncommitted AGENTS.md refresh). `dev` is one commit behind `main`.
Full coding standard, architecture, and commit rules: [CLAUDE.md](CLAUDE.md).

## Environment / Stack

- Flutter app, Dart SDK `^3.11.5` (pubspec), package manager: pub (`pubspec.lock`).
- Riverpod 3 (`riverpod_annotation` codegen), go_router, fpdart, freezed,
  supabase_flutter, flutter_gemma, ultralytics_yolo, flutter_dotenv.
- Supabase backend lives in `supabase/` (config.toml, functions, migrations).

## Key commands

| Task | Command |
|------|---------|
| Install deps | `flutter pub get` |
| Dev (primary target) | `flutter run -d chrome` |
| Lint (must pass pre-commit) | `flutter analyze` |
| Tests | `flutter test` |
| Format | `dart format lib/ test/` |
| Codegen (riverpod/freezed) | `dart run build_runner build --delete-conflicting-outputs` |
| Build | `flutter build web` / `flutter build apk --release` |
| Scan layout proof | `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-layout-overlap-pass.ps1` |

## Secrets / env

- Copy `.env.example` → `.env` (gitignored). Keys by name: `SUPABASE_URL`,
  `SUPABASE_ANON_KEY`, `HUGGINGFACE_TOKEN`. Loaded via `flutter_dotenv` in
  `lib/main.dart` and `lib/core/config/supabase_config.dart`.
- `GEMINI_API_KEY` is deliberately NOT a client `.env` key — it lives only as a
  Supabase Edge Function secret for `supabase/functions/gemini-proxy/`.
- Caution: pubspec bundles `.env` as a Flutter asset — it ships inside builds.
  Never put server-only keys in it; the cloud Gemma path keeps `GEMINI_API_KEY`
  server-side (`lib/features/translator/data/datasources/cloud_gemma_datasource.dart`).

## Project layout

```
lib/
├── app/        # KudlitApp, go_router setup, constants
├── core/       # auth, config, design_system, error, usecases, utils
└── features/   # admin, auth, home, learning, scanner, translator
```

Feature structure: `domain/` (pure Dart) → `data/` → `presentation/` (widgets + providers).

## Gotchas

- `.g.dart` files are build_runner-generated; regenerate, never hand-edit.
- Domain `@immutable` comes from `package:meta/meta.dart`, never
  `flutter/foundation.dart` — domain layer has zero Flutter deps.
- Domain returns `Either<Failure, T>` (fpdart); presentation maps `Left` to messages.
- Scanner model path resolves dynamically via
  `lib/features/scanner/presentation/providers/yolo_model_selection_provider.dart`;
  web uses `kIsWeb` guards, capture-based TFLite detection, and fallback UI.

## Skills (load before working in these domains)

- `skills/flutter-frontend/SKILL.md` — widget patterns, design system
- `skills/supabase/SKILL.md` — Supabase integration patterns
- `skills/supabase-postgres-best-practices/SKILL.md` — schema/query optimisation

## Current status

- v1.0.0 Android APK published on GitHub Releases (`ACSADians/kudlit-app`).
- Repo rule: branch off `dev` (never `main`); conventional-commit prefixes.

Last verified: 2026-07-22 (workspace AGENTS.md refresh pass).
