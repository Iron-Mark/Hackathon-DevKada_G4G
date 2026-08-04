---
description: "Use when writing or reviewing Flutter widgets or Dart files. Covers widget decomposition, build() size limits, Riverpod provider patterns, import ordering, and type rules."
applyTo: "lib/**/*.dart"
---
# Dart / Flutter Coding Rules

Full rules: [docs/DEVELOPMENT.md](../../docs/DEVELOPMENT.md). Key constraints enforced here:

## Types & Variables
- Never use `var` — always declare explicit types.
- `final` for anything not reassigned; `late final` for deferred init.
- `dynamic` only at explicit interop boundaries (raw JSON before model cast).

## Strings & Formatting
- Single quotes everywhere: `'hello'` not `"hello"`.
- Trailing commas on all multi-line argument lists and collection literals.
- Max line length: 80.

## Imports
Order: `dart:` → `flutter:` → packages → local. Blank line between each group. Relative imports within the same feature; `package:kudlit_ph/…` across features.

## Widgets
- `build()` must not exceed 40 lines — extract real widget classes if it does.
- Never use `_buildSomething()` private builder methods — extract a `StatelessWidget` subclass instead.
- Each extracted widget lives in its own file.
- Prefer `const` constructors; prefer `StatelessWidget`; reach for Riverpod before `StatefulWidget`.
- No business logic, data transformation, or conditional chains in `build()` — all logic lives in notifiers/providers.

## Riverpod
- `@riverpod` codegen for all providers (`riverpod_annotation`).
- `@Riverpod(keepAlive: true)` for platform-lifetime; `@riverpod` for auto-dispose.
- `build()` uses `ref.watch`; action methods use `ref.read`.
- Providers live in `presentation/providers/` inside their feature.

## Domain Layer
- Zero Flutter dependencies — pure Dart only.
- Use `package:meta/meta.dart` for `@immutable`, not `package:flutter/foundation.dart`.
- Return `Either<Failure, T>` (fpdart) from use cases.
