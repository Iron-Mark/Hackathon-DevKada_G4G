# Top 10 Prioritized Improvements — Kudlit Audit 2026-05-14

**Synthesizer:** Plan agent · **Sources:** 7 lane reports in this directory

## Method
- Pulled the P0 and highest-impact P1 items from each lane.
- Sorted by severity (P0→P1→P2) then effort (S→M→L).
- Every row has Evidence (`file_path:line`) drawn from the source lane file.

## Top 10

| # | Lane | Area | Severity | Effort | Recommendation | Evidence |
|---|---|---|---|---|---|---|
| 1 | Security | OTP brute-force defense | P0 | S | Implement client-side OTP resend cooldown (30–60s) and a 5-attempt verify lockout with backoff; remove the dead `_resendCooldown=0` field and dead cooldown branch. | `lib/features/auth/presentation/screens/phone_otp_screen.dart:46,95,134-162` (from `05_security_privacy.md`) |
| 2 | Security | Password recovery deep link | P0 | S | Wire `AuthChangeEvent.passwordRecovery` to a dedicated reset screen that forces `updateUser(password:)`; stop reusing `/auth/reset` for both OAuth callback and recovery. | `lib/app/router/app_router.dart:138-142`; `lib/features/auth/data/datasources/supabase_auth_datasource.dart:179` (from `05_security_privacy.md`) |
| 3 | Nav/IA | Admin route exposure | P0 | S | Gate `/admin/stroke-recorder` at the router with a role check (`is_admin` from `profile_summary`), not just at the Settings tile. | `lib/app/router/app_router.dart:163-167`; `lib/features/home/presentation/widgets/settings/admin_section.dart:63` (from `07_nav_ia_visual.md`) |
| 4 | Accessibility | WCAG AA contrast — TextField hints | P0 | S | Raise TextField hint alpha from `withAlpha(110)` to `withAlpha(160)` (≈4.5:1 on light surface); darken `subtleForeground` token so 12pt `bodySmall` clears AA. | `lib/features/home/presentation/widgets/butty_chat/chat_input_bar.dart:47-50`; `lib/features/home/presentation/widgets/translate/text_input_box.dart:45-48`; `lib/core/design_system/kudlit_colors.dart:24` (from `06_accessibility.md`) |
| 5 | UX | Auth welcome credibility | P0 | S | Delete the "Authentication is UI-only for now." caption from the welcome card — it contradicts the working Supabase backend at the most fragile point in the funnel. | `lib/features/auth/presentation/screens/auth_welcome_screen.dart:62` (from `01_ux_screens.md`) |
| 6 | Multiplatform | Web password reset redirect | P0 | S | Provide explicit `redirectTo: '${Uri.base.origin}/auth/reset'` for password reset on web (currently `null`) and register an in-app `/auth/reset` handler. | `lib/features/auth/data/datasources/supabase_auth_datasource.dart:179`,`:85-87` (from `02_multiplatform.md`) |
| 7 | Security | Bundled cloud API key | P0 | M | Move Gemini API calls behind a server proxy (Supabase Edge Function); remove `GEMINI_API_KEY` from the client bundle so it cannot be extracted from the APK/web bundle. | `lib/features/translator/presentation/providers/translator_providers.dart:54-55`; `lib/features/translator/data/datasources/cloud_gemma_datasource.dart:47` (from `05_security_privacy.md`) |
| 8 | Performance | YOLO inference leak | P0 | M | Stop YOLO inference when ScanTab is off-screen — PageView keeps it alive. Either gate `ScannerCamera` mount on `_activeTab == AppTab.scan`, or call `detector.pauseInference()` on tab change. | `lib/features/auth/presentation/screens/home_screen.dart:122-145`; `lib/features/scanner/data/datasources/yolo_baybayin_detector.dart:155-159` (from `04_performance_offline.md`) |
| 9 | Multiplatform | Web data layer crash | P0 | M | Add web-stub or `sqflite_common_ffi_web` adapters for every `sqflite` datasource so chat history, scan history, lesson progress and profile cache do not crash on web; currently no `kIsWeb` guard around construction. | `lib/features/translator/data/datasources/sqlite_*.dart`; `lib/features/scanner/data/datasources/sqlite_scan_history_datasource.dart`; `lib/features/learning/data/datasources/sqlite_lesson_progress_datasource.dart`; `lib/features/home/data/datasources/local_profile_management_datasource.dart` (from `02_multiplatform.md`) |
| 10 | Architecture | Scanner failure surface | P0 | L | Add `Either<Failure, T>` to the scanner domain — wrap detect/capture/torch/switch/pause/resume in typed failures and add a `scanner/domain/usecases/` directory; today every error in the highest-failure-rate feature bubbles as a raw exception. | `lib/features/scanner/domain/repositories/baybayin_detector.dart:16-32` (from `03_architecture.md`) |

## Why these 10
Every item is a P0 from its source lane and together they span all seven lanes — Security (2), Multiplatform (2), plus one each from UX, Nav/IA, Accessibility, Performance, and Architecture. The ordering is severity-then-effort: six S-effort wins precede three M-effort fixes, and the single L-effort refactor closes the list. Deferred-but-tempting P0s — consolidating Login/Welcome (UX, M), failed-write reaper (Perf, M), deleting orphan nav widgets (Nav/IA, S), reduced-motion helper (A11y, M), guarding `initializeFlutterGemma` on web (Multiplatform, M), and the presentation→data import refactor (Architecture, L) — were held back because they either duplicate the lane coverage already chosen here or depend on one of the Top 10 landing first.

## Companion Sections
- Item 1 → `05_security_privacy.md` § "Phone OTP rate limit / lockout"
- Item 2 → `05_security_privacy.md` § "Password reset deep-link safety"
- Item 3 → `07_nav_ia_visual.md` § "Routing red flags"
- Item 4 → `06_accessibility.md` § "Contrast (WCAG AA)"
- Item 5 → `01_ux_screens.md` § `auth_welcome_screen.dart`
- Item 6 → `02_multiplatform.md` § "Auth deep links"
- Item 7 → `05_security_privacy.md` § "Secrets / env handling"
- Item 8 → `04_performance_offline.md` § "Inference cadence & camera lifecycle"
- Item 9 → `02_multiplatform.md` § "Platform idiom mismatches"
- Item 10 → `03_architecture.md` § "Error handling (Either<Failure, T>) coverage"
