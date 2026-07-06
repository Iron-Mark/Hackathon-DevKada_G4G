# Supabase Phone + Google Auth Implementation Plan (Kudlit)

> Status: Historical reference — core phone and Google auth flows are now wired in code on the current branch; this document is kept for context and diffing.

## Problem (historical context)

This plan was written while phone/google auth were partially missing.
It is no longer a reflection of the current in-tree implementation state.

## Current State (now implemented in-code)

- **Data/domain**
  - `AuthRepository` includes phone OTP and Google sign-in methods.
  - `SupabaseAuthDatasource` includes `signInWithOtp`, `verifyOTP`, and `signInWithGoogle` calls.
- **Presentation**
  - `LoginScreen` actions route through notifier methods for phone and Google actions.
  - OTP and Google flows are no longer placeholder-only in notifier/UI wiring.
- **Routing/auth state**
  - `AuthNotifier` remains stream-driven from Supabase auth state and continues to drive redirect behavior.
- **Config**
  - Supabase initialization remains via `.env` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`), with provider settings still required in the Supabase project.

## What to validate next

This legacy plan should now be treated as archival context. Before production use, validate:

- Environment-level Supabase provider settings (Phone + Google) are correctly configured.
- OTP and Google flows work across target devices/browsers.
- Redirect/deep-link handling is validated for OAuth callbacks.
- Error + rate-limit messaging remains aligned with the active copy.

## Approach
Keep auth state centralized in `AuthNotifier` so GoRouter redirects continue to work without route hacks.

## Todos
1. **Define product behavior for account creation paths** ✅
   - **Confirmed:** phone and Google stay on the Login entry points.
   - First successful phone/Google auth proceeds through normal authenticated routing.

2. **Supabase Auth provider setup**
   - Enable **Phone** and **Google** providers in Supabase project auth settings.
   - Configure OTP settings (expiry, retry/rate constraints) and allowed redirect URLs.
   - Configure mobile/web callback URLs for OAuth and verify they map to app routing/deep-link behavior.

3. **Legacy implementation milestones**
- Domain/contracts, datasource/repository, use cases, providers/notifier wiring, and presentation action wiring for phone/google auth are now represented in the active code branch.

4. **Platform callback/deep-link integration**
- Configure platform files for OAuth callback handling as required by `supabase_flutter` for Android/iOS/Web.
- Ensure callback returns into app and auth stream update redirects to home.
- Validate callback handling in target environments before release.

5. **Error handling + messaging + limits**
- Verify user-facing messaging for OTP invalid/expired, rate-limit, provider cancellation, and OAuth failure states.

6. **Testing and hardening**
- Run analyze + tests after implementation changes.
- Verify manual happy paths:
  - phone sign-in (new + returning)
  - Google sign-in (new + returning)
  - email sign-up/sign-in regression

## Notes / Guardrails
- Reuse existing clean architecture boundaries; do not place Supabase SDK logic in presentation.
- Keep domain pure Dart (no Flutter imports).
- Keep `AuthNotifier` as the single orchestrator for auth state transitions.
- Avoid silent auth failures; surface mapped errors to UI.
- Confirm final implementation details against current Supabase docs before coding.
