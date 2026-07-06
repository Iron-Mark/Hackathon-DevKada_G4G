# Kudlit System Audit & Flow Guide

## 1. Current System Architecture
Kudlit is built using a **Feature-First Clean Architecture** with the following technology stack:
*   **Framework:** Flutter (Dart)
*   **Routing:** `go_router`
*   **State Management:** Riverpod (`@riverpod` annotations)
*   **Backend / Auth:** Supabase
*   **Error Handling:** Functional programming approach using `fpdart` (`Either<Failure, T>`)
*   **Design System:** Custom `Kudlit Design System` located in `lib/core/design_system/`, acting as the single source of truth for UI (colors, typography, spacing, and branded shells).

The codebase is organized by feature, with strict separation between:
*   **Presentation:** Widgets, Screens, and Riverpod Notifiers.
*   **Domain:** Pure Dart (Entities, Repository Interfaces, Use Cases). Zero Flutter dependencies here.
*   **Data:** Supabase Repositories, Data Sources, and Data Models.

## 2. Implemented Features & Working Parts
Based on the current directory structure (`lib/features/`):
*   **Auth (Fully Implemented):**
    *   **Flows:** Login, Sign Up, Forgot Password, and Password Reset.
    *   **UI:** Uses `KudlitAuthShell` for a branded, responsive layout. Includes error handling via `AuthErrorBanner`.
*   **Home / App Shell:**
    *   **Flows:** Splash screen initialization, settings, and main navigation tabs.
    *   **Screens:** `SplashScreen`, `ModelSetupScreen`, `HomeScreen`, `SettingsScreen`.
*   **Scanner:** 
    *   Contains native camera/gallery YOLO recognition plus web webcam preview with capture-based TFLite detection from the active vision model URL.
*   **Translator:** 
    *   Baybayin transliteration and offline language understanding (using Gemma 4).

## 3. Current Navigation Flow
The `go_router` configuration (`lib/app/router/app_router.dart`) orchestrates the user journey based on Riverpod state (`authNotifierProvider` and `appPreferencesNotifierProvider`):

1.  **App Launch (`/`)**: The user lands on the `SplashScreen` while the app initializes authentication and preferences.
2.  **Model Setup (`/setup-models`)**: If the app is running natively (not Web) and offline AI models have not been downloaded (or skipped), the user is routed to the `ModelSetupScreen`.
3.  **Authentication Gate**:
    *   **Authenticated:** The user is seamlessly routed to the `HomeScreen` (`/home`).
    *   **Unauthenticated:** The user is routed to the `LoginScreen` (`/login`).
4.  **Auth Actions**: Unauthenticated users can navigate between `/login`, `/signup`, and `/forgot-password` freely without being redirected.
5.  **Unprotected Routes**: `HomeScreen` and `SettingsScreen` do not force a login redirect for exploration.

---

## Testing the Current Flow

To test the current application and flow, follow these steps:

### A. Web / Design Validation (Recommended for UI work)
The primary target during UI and design system development is Chrome. Web supports layout validation, auth flow checks, and scanner webcam/capture validation when a compatible web model URL is configured:
```bash
flutter run -d chrome
```
*Note: Native-only scanner capabilities, such as torch control and local model setup, still require Android/iOS testing.*

### B. Native Emulator (Required for ML / Scanner features)
To test the `ModelSetupScreen`, YOLO character detection, and offline Gemma translation, you must run the app natively.
```bash
flutter run -d emulator-5554 --no-dds
```
*(If the debugger fails to attach, you can append `--disable-service-auth-codes`)*

### C. Validation Commands
Before committing or claiming a feature is complete, always verify structural integrity:
```bash
flutter analyze
dart format lib/ test/
flutter test
```

### D. Scan Layout Hardening
For scan-tab overlap, clipping, and transition status regressions:
```bash
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-layout-overlap-pass.ps1
```

Latest strict artifacts are under:

- `qa-artifact/scan-layout-strict-overlap/report.json`
- `qa-artifact/scan-layout-strict-overlap/scan-layout-overlap-contact-sheet.html`
- `qa-artifact/scan-layout-strict-overlap/matrix/`
- `qa-artifact/scan-layout-strict-overlap/transitions/`
