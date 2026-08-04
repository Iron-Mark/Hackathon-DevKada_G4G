---
name: kudlit-app
description: Repository workflow for building the Kudlit Flutter app with the bundled Kudlit Design System and feature-first clean architecture.
user-invocable: false
---

# Kudlit App Skill

Use this repo as a Flutter implementation of the bundled `Kudlit Design System`.

## Source of Truth

- Product rules and architecture: [AGENTS.md](AGENTS.md) and
  [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)
- Brand rules and visual references: [Kudlit Design System/README.md](<Kudlit Design System/README.md>)
- Design-system skill manifest: [Kudlit Design System/SKILL.md](<Kudlit Design System/SKILL.md>)
- Gemini extension entrypoint: [GEMINI.md](GEMINI.md)
- Repo-local Gemini skill: [skills/flutter-frontend/SKILL.md](skills/flutter-frontend/SKILL.md)

## Project Expectations

- Keep the app mobile-first even when validating on Chrome.
- Treat `lib/core/design_system/` as the app-facing translation layer for colors, type, spacing, assets, and shared shells.
- Use the copied Flutter assets in `assets/brand/` and `assets/fonts/` instead of referencing files directly from `Kudlit Design System/`.
- Preserve feature-first clean architecture under `lib/features/`.
- Use the current home/auth screens as branded placeholders until scanner, translator, and learn flows are implemented.

## Folder Intent

```text
lib/
  app/                  App bootstrapping, routing, global constants
  core/
    config/             Environment and Supabase setup
    design_system/      Flutter theme, tokens, and shared branded widgets
    error/              Shared failures and exceptions
    usecases/           Base use case abstractions
  features/
    auth/               Existing end-to-end feature slice
assets/
  brand/                Copied Kudlit illustrations and UI imagery
  fonts/                Bundled Baybayin display font
Kudlit Design System/   Reference kit, previews, and original brand docs
```

## Implementation Notes

- The repo currently bundles the Baybayin display font. The UI font in the design docs is Geist, but no Flutter font asset is included yet.
- `lib/core/design_system/widgets/kudlit_auth_shell.dart` and `kudlit_home_placeholder.dart` are the starter placeholders derived from the mobile UI kit.
- When adding new features, create presentation widgets that consume the theme rather than redefining colors and spacing locally.
- If Gemini CLI also has `obra/superpowers` installed, use it for process skills and use the local `flutter-frontend` skill for Kudlit-specific UI execution.
