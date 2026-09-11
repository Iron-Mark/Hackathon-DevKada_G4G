# Auth Polish Design

## Overview
Update the Kudlit app's authentication screens to properly and consistently utilize the Kudlit Design System (`lib/core/design_system/`). The focus is on a component-driven polish to ensure responsive, mobile-first layouts that adapt cleanly on tablet and web platforms (Android, iOS, Web).

## Architecture & Components

1.  **Remove Obsolete Components**
    *   Delete unused files like `SignInScreen` and `AuthFormScaffold` that duplicate functionality already handled by the `KudlitAuthShell` and the Riverpod-based `LoginScreen`/`SignUpScreen`.
2.  **Deduplicate UI Elements**
    *   Remove redundant hardcoded titles (like the Baybayin text) from `LoginFormBody` and `SignUpFormBody` because `KudlitAuthShell` already provides a unified, responsive hero section.
3.  **Standardize Form Elements**
    *   Extract bottom actions (e.g., "Don't have an account? Sign up") into a shared `AuthFooterAction` widget so it looks fidentical across all auth screens.
    *   Use `KudlitTheme` text styles and `KudlitColors` strictly.
4.  **Shared Error Display**
    *   Extract a shared `AuthErrorBanner` widget to display error messages consistently across `LoginScreen`, `SignUpScreen`, and `ForgotPasswordScreen` using `KudlitColors.danger400` or the design system's semantic error tokens.
5.  **Responsive Refinements**
    *   Ensure `KudlitAuthShell` handles layout constraints cleanly, providing appropriate padding and max-widths so forms aren't stretched too wide on desktop/tablet browsers.
    *   Ensure `KudlitHomePlaceholder` respects spacing and max-width constraints for larger screens.

## Data Flow
*   Unchanged. The presentation layer will continue to use `authNotifierProvider` for signing in, signing up, and resetting passwords, reading from and writing to the domain layer via Riverpod.

## Error Handling
*   Errors returned from the notifier (as `Failure` objects) will be mapped to user-friendly messages and passed to the new `AuthErrorBanner` widget.

## Testing
*   Rely on `flutter analyze` and widget structure checks to ensure zero regressions in UI layout.
*   Verify responsive layout visually on Chrome (`flutter run -d chrome`)ff