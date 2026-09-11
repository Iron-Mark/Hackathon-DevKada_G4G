---
name: flutter-frontend
description: Use when building or refining Flutter UI, screens, widgets, theming, responsive layout, or design-system integration in this repository.
---

# Flutter Frontend

## Overview

This skill covers Flutter UI implementation for Kudlit. It complements `obra/superpowers` rather than replacing it: use Superpowers for process, planning, and testing discipline; use this skill for repository-specific frontend execution.

## Required Context

- Follow `CLAUDE.md` for repo architecture and coding constraints.
- Use the bundled `Kudlit Design System` as the visual source of truth.
- Treat `lib/core/design_system/` as the shared Flutter translation layer for brand tokens and reusable surfaces.

## Use This Skill For

- New Flutter screens or widgets
- Applying or extending the Kudlit design system
- Porting visual references into Flutter-native components
- Refactoring large widget trees into smaller files
- Building mobile-first placeholder flows for unfinished features

## Do Not Use This Skill For

- Domain logic or repository implementation details outside UI concerns
- Replacing TDD, planning, or review workflows from `obra/superpowers`
- Referencing JSX/CSS kits directly from app code instead of using Flutter assets and theme files

## Repo-Specific Rules

- Keep widgets display-focused; business logic belongs in providers, notifiers, and use cases.
- Keep `build()` under 40 lines.
- If a subtree nests 3+ levels deep, extract a real widget into its own file.
- Prefer `StatelessWidget`; use `StatefulWidget` only for local ephemeral UI state.
- Use single quotes and explicit types.
- Reuse shared tokens from `lib/core/design_system/` before introducing new colors, radii, or spacing.

## Design-System Rules

- Use colors and typography from `lib/core/design_system/kudlit_colors.dart` and `lib/core/design_system/kudlit_theme.dart`.
- Use shared branded shells and placeholders from `lib/core/design_system/widgets/` when extending auth or top-level app surfaces.
- Use assets from `assets/brand/` and the Baybayin display font from `assets/fonts/`.
- Keep the visual language aligned with Kudlit: blue-tinted paper surfaces, dark denim ink, card-first layout, and Butty illustrations for expressive empty or helper states.
- Treat `kudlit-design-system/ui_kits/mobile/` as reference-only. Rebuild layouts in Flutter instead of copying web structure.

## Folder Placement

- App-wide reusable visual primitives: `lib/core/design_system/`
- Feature-specific screens: `lib/features/<feature>/presentation/screens/`
- Feature-specific widgets: `lib/features/<feature>/presentation/widgets/`
- Shared assets: `assets/brand/`

## Delivery Expectations

- Keep changes mobile-first, even if validated on Chrome.
- Update docs when structure or frontend conventions change.
- Run `flutter analyze` before finishing.
