---
name: kudlit-design
description: Use this skill to generate well-branded interfaces and assets for Kudlit, either for production or throwaway prototypes/mocks/etc. Contains essential design guidelines, colors, type, fonts, assets, and UI kit components for prototyping.
user-invocable: true
---

Read the README.md file within this skill, and explore the other available files.
If creating visual artifacts (slides, mocks, throwaway prototypes, etc), copy assets out and create static HTML files for the user to view. If working on production code, you can copy assets and read the rules here to become an expert in designing with this brand.
If the user invokes this skill without any other guidance, ask them what they want to build or design, ask some questions, and act as an expert designer who outputs HTML artifacts _or_ production code, depending on the need.

Kudlit is built in **Flutter** (Android + iOS). The bundled JSX UI kit is a visual reference only — port styles/layouts into Flutter widgets. CSS tokens in `colors_and_type.css` map 1:1 to Flutter `ThemeData` values (colors, radii, spacing). The Baybayin display font ships in `fonts/` and the mascot illustrations live in `assets/` — bundle both into the Flutter project's `assets/` directory.

## Flutter Frontend Development Skills & Guidelines
When developing Flutter frontend code for Kudlit:

1. **State Management:** Use Riverpod (`flutter_riverpod` and `riverpod_annotation`). Prefer functional, immutable state using `freezed` and `fpdart` for error handling.
2. **Routing:** Utilize `go_router` for declarative navigation and deep linking.
3. **Theming:** Strictly map the CSS tokens from the design system to Flutter's `ThemeData`. Create a robust `AppTheme` class for colors, typography, and spacing defined in the design system.
4. **Widget Composition:** Build small, reusable, and stateless widgets. Keep presentation separate from business logic.
5. **Asset Integration:** Ensure all SVGs, mascot illustrations, and custom Baybayin fonts are correctly declared in `pubspec.yaml` and loaded efficiently. Use `flutter_svg` for vector graphics.
6. **Code Generation:** Use `build_runner` for `freezed`, `json_serializable`, and `riverpod_generator`. Run `dart run build_runner build -d` when models or providers change.
7. **Best Practices:** Follow strict linting rules (`flutter_lints`). Prefer `const` constructors everywhere possible for performance. Write comprehensive widget tests for core components.
