# 05 — Security & Privacy
**Auditor:** general-purpose (security lane) · **Skill invoked:** security-review (deferred — applying security-review heuristics manually) · **Date:** 2026-05-14

## Summary
- P0 count: 2 · P1 count: 6 · P2 count: 5
- Single biggest risk: Phone OTP screen has **no client-side resend cooldown or lockout** — the `_resendCooldown` field is a hard-coded `0` and `_resendCode()` only blocks while a single request is in flight (`phone_otp_screen.dart:46,134-162`). Combined with the verify path that auto-submits on every 6 digits typed (`phone_otp_screen.dart:95`), the app can drive unlimited OTP send/verify traffic to Supabase from a compromised or scripted client. Server-side Supabase rate limits are the only defense, and prior audits (`supabase_phone_otp_integration.md` §4) flag this as "review before prod" rather than confirm it is configured.

## Findings

### Auth token handling & refresh
- **Token storage is delegated entirely to `supabase_flutter`.** `supabase_auth_datasource.dart:36-55` only holds a `SupabaseClient` reference; access/refresh tokens live in `gotrue`'s default `SharedPreferences`-backed store on mobile and `localStorage` on web. No explicit secure-storage option (`flutter_secure_storage` / Keychain / Keystore) is configured at init time in `lib/main.dart:13-16`. (P1) — On rooted/jailbroken Android the refresh token can be read from app private storage; on web `localStorage` is XSS-reachable.
- **No manual refresh path.** The app relies on the SDK's internal auto-refresh; there is no `refreshSession()` retry on `Failure.sessionExpired`, and `_mapServerExceptionToFailure` (`auth_repository_impl.dart:117-142`) does not produce `Failure.sessionExpired` for any 401-style payload — those fall through to `Failure.unknown`. (P2) — silent expiry surfaces as a generic error instead of forcing re-login.
- **`currentUserRole` reads `profiles.role` directly with the user's JWT** (`current_user_role_provider.dart:14-27`). If the `profiles` table allows the row owner to UPDATE `role`, a user could self-elevate to admin. RLS policy is implicit (see "RLS trust surface"). (P0) — verify `role` is non-writable client-side.

### Password reset deep-link safety
- **`/auth/reset` renders `LoginScreen` and nothing else** (`app_router.dart:138-142`). There is no widget that listens for `AuthChangeEvent.passwordRecovery` and prompts for a new password — `grep AuthChangeEvent.passwordRecovery` across `lib/` returns zero hits. The `authStateChanges` mapper in `supabase_auth_datasource.dart:42-48` only forwards `session?.user`, dropping the recovery event entirely. (P0) — the recovery deep link establishes a logged-in session (because `gotrue` honors the recovery token automatically) and drops the user on `LoginScreen`; if the redirect goes to `/auth/reset` while a session is already cached, the user appears to be already signed in without ever choosing a new password. The link effectively becomes a "click here to log in as me" capability if the recovery URL leaks.
- **Mobile deep-link scheme `kudlit://auth/reset`** (`supabase_auth_datasource.dart:87,179`) is not validated for authenticity by the app — Android intent filters / iOS `CFBundleURLSchemes` are not narrowed to a Supabase-signed payload, and any other app registered for the same scheme would intercept the token fragment. (P1) — App Links / Universal Links (HTTPS-verified) are stronger than custom schemes.
- **Web fallback uses `Uri.base.origin`** for OAuth (`supabase_auth_datasource.dart:85-87`). If the app is served from a host the Supabase dashboard hasn't allow-listed, the OAuth call will fail closed — that is acceptable, but it also means any environment that the attacker can host (e.g. PR preview deploy) will end up in the allow-list if Site URL/Redirect URLs are loosely configured server-side. (P2) — depends on dashboard config; flag for review.

### Phone OTP rate limit / lockout
- **`_resendCooldown` is a `const 0`** (`phone_otp_screen.dart:46`). The `_ResendRow` only ever shows "Resend code" link or "Sending…", never a countdown — the cooldown branch on line 435-442 is dead code. (P0) — see Summary.
- **Auto-submit on every 6-digit entry** (`phone_otp_screen.dart:95`) means a scripted brute-force does not even need a button press; it can paste 000000…999999. The `_isLoading` flag serializes attempts but does not throttle them. (P0)
- **No client-side attempt counter / lockout.** `_submit()` resets `_errorMessage` and immediately allows another attempt on failure (`phone_otp_screen.dart:98-125`). The repository only translates `429 / "too many requests"` into a user-readable failure (`auth_repository_impl.dart:129-131`) — it does not lock the screen. (P1)
- **Phone send screen has no rate guard** either (`phone_sign_in_screen.dart:89-119`); tapping "Send OTP" rapidly issues back-to-back `signInWithOtp` calls with `_isLoading` as the only gate, which races on `setState`. (P1)

### Google OAuth redirect URIs
- **`signInWithGoogle` pins web redirect to `${Uri.base.origin}/auth/reset`** (`supabase_auth_datasource.dart:85-92`). The `/auth/reset` path here is reused for OAuth callback even though no recovery handler exists at that route — functionally it is just "land back on Login". This conflates two flows (password reset and OAuth callback) on the same route, which makes router logic brittle. (P1) — a dedicated `/auth/callback` route avoids ambiguity.
- **Allowed origins not enforced client-side.** `Uri.base.origin` is whatever the page is served from; the only enforcement is the Supabase dashboard's "Redirect URLs" allow-list. Code does not assert that the resolved origin matches an expected hostname. (P2) — defense-in-depth: pin `kudlit.app` (or the env-configured host) instead of trusting `Uri.base`.
- **`prompt: 'select_account'`** is intentional — good — prevents silent re-auth onto the wrong Google identity.

### Supabase RLS trust surface (tables accessed)
Every table below is read or written with the user's JWT and assumes RLS confines rows to `auth.uid() = user_id`. None of this is verified in code.

| Table | File:line | Operation | Trust assumption |
| --- | --- | --- | --- |
| `profiles` | `current_user_role_provider.dart:21` | SELECT `role` by `id=user.id` | **RLS must forbid client UPDATE on `role`** — otherwise self-elevation. (P0) |
| `profiles` | `profile_management_datasource.dart:44,126,169` | SELECT / UPSERT / UPDATE | Owner-only RLS expected; `upsert` payload trusted to set `id=user.id`. |
| `learning_progress` | `profile_management_datasource.dart:46,210`; `streak_provider.dart:23`; `lesson_progress_provider.dart:98,119` | SELECT / UPSERT | RLS must scope by `user_id`. |
| `scan_history` | `profile_management_datasource.dart:50`; `scan_history_provider.dart:84,100` | SELECT / INSERT | RLS must scope by `user_id`. |
| `translation_history` | `profile_management_datasource.dart:52,56`; `translation_history_provider.dart:126,153` | SELECT / INSERT (incl. `input_text`, `ai_response`) | RLS must scope by `user_id`. Stores raw user input. (P1 — sensitive content) |
| `user_preferences` | `profile_management_datasource.dart:92,191` | SELECT / UPSERT | RLS must scope by `user_id`. |
| `chat_messages` | `supabase_chat_datasource.dart:23,47,77` | INSERT / SELECT / DELETE | **Full Butty conversation content uploaded.** RLS must scope by `user_id`. (P1) |
| `chat_memory_facts` | `supabase_chat_memory_datasource.dart:18,52,74,86,104` | SELECT / INSERT / DELETE / UPDATE | Distilled personal facts about the user. RLS critical. (P1) |
| `lessons`, `lesson_steps` | `supabase_lesson_datasource.dart:17,24`; `quiz_provider.dart:70`; `character_gallery_provider.dart:15,57` | SELECT | Read-only public content — should be `select` policy = `published=true`. |
| `stroke_patterns` | `supabase_stroke_pattern_datasource.dart:27,46`; `supabase_lesson_datasource.dart:68`; `character_gallery_provider.dart:57` | INSERT / SELECT | Admin recorder (`stroke_recording_screen`) writes here. RLS must restrict INSERT to admin role; otherwise any user can corrupt the stroke-order canon. (P0/P1 — depends on policy) |
| `avatars` (Storage bucket) | `profile_management_datasource.dart:150,160` | upload `{user.id}/avatar.{ext}`; `getPublicUrl` | **Bucket is treated as public** — bucket policy must restrict writes to `auth.uid()::text = (storage.foldername(name))[1]`. (P1) |

Prior audits (`backend_audit_2026.md`, `backend_audit_2026-05-05.md`) noted RLS as a pending task — this audit confirms code still implicitly trusts it.

### PII in logs
All `debugPrint` calls are compile-stripped in release builds in Flutter, so this is principally a debug/staging concern. Still worth tightening:

- **Message length leaked, content not.** `butty_chat_controller.dart:99-101,156-158` logs `chars=<n>`, not the message body — good. `local_gemma_datasource.dart:186-188` likewise.
- **Raw model output printed verbatim** during memory parsing: `memory_extraction_service.dart:143` — `debugPrint('[MemoryExtraction] JSON parse failed: $e\nraw=$cleaned')`. `cleaned` is Gemma's distilled facts about the user (names, location, preferences). In debug-mode IDE consoles this is the most sensitive PII surface in the app. (P1) — gate behind `assert(false)` or log only a hash/length.
- **Phone numbers / emails / OTP codes never logged.** `phone_otp_screen.dart` / `phone_sign_in_screen.dart` / `supabase_auth_datasource.dart` — clean. Good.
- **Tokens never logged.** `flutter_gemma_bootstrap.dart:5-12` trims but doesn't print the HF token. `local_gemma_datasource.dart:128` reads the token but never logs it. Good.
- **Server error messages forwarded into UI** via `Failure.unknown(message: e.message)` (`auth_repository_impl.dart:141`) — Supabase auth error strings can contain account hints ("user already registered", "email rate limit exceeded"). User enumeration risk is mild but present. (P2)

### Cloud Gemma data flow & user disclosure
- **All chat history is sent to Google AI in cloud mode** (`cloud_gemma_datasource.dart:64-97`). The full sliding window — including any personal facts injected via the system prompt assembled in `butty_chat_controller.dart:212-254` — is shipped to `gemma-4-26b-a4b-it` via the Genkit Google AI plugin. This includes:
  - User display name (from `profiles.display_name`)
  - Lessons-completed count
  - Up to 12 most-recent memory facts (free-form distilled PII)
  - All recent chat turns
- **Sketchpad / image analysis uploads base64-encoded drawings** (`cloud_gemma_datasource.dart:106-162`) plus an optional caller-supplied prompt.
- **Challenge generator** uploads only a focus list of glyphs — low risk.
- **Privacy disclosure is generic.** `privacy_policy_screen.dart:51-71` says "Inputs may be processed locally on your device or sent to configured app services" and "Some Kudlit features use model-based processing." It does **not name Google / Gemini**, does not list the specific data fields (memory facts, profile name) that are forwarded, and does not provide an in-app toggle to switch off cloud mode (the toggle exists in `app_preferences`, but its privacy implication isn't surfaced near the on/off switch). (P1) — GDPR/PH-DPA "transfer to third country / processor disclosure" expectation.
- **No data-minimization on the prompt.** `_buildProfileBlock` always includes display name even when the user could have remained pseudonymous. (P2)
- **No content filter / safety guard** before sending sketchpad images to the cloud — if the user draws something off-topic, it ships anyway. (P2)

### Secrets / env handling
- **`.env` is committed to the working tree.** `find . -maxdepth 2 -name '.env'` returns both `.env` and `.env.example`. (P0 if `.env` is tracked in git; P1 if only present locally.) **Action:** confirm `.env` is in `.gitignore` and was never committed — `.env.example` (`.env.example:1-3`) is the only file that should be tracked.
- **No hard-coded keys in `lib/`.** `grep -E 'AIza|sk-…|hf_…|eyJ…'` over `lib/` returns zero hits. All secrets flow through `dotenv.env[...]` at runtime: `supabase_config.dart:4-5` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`), `main.dart:17` (`HUGGINGFACE_TOKEN`), `translator_providers.dart:54` (`GEMINI_API_KEY`). Good.
- **`GEMINI_API_KEY` is bundled into the client build at run time.** Because Flutter loads `.env` via `flutter_dotenv` (`main.dart:12`), the Gemini key is shipped inside the APK / web bundle. Any user can extract it from the APK assets and abuse the project's Google AI quota. (P0) — cloud Gemini calls **must** be proxied through a server (Edge Function / backend) so the key never ships to clients. The Supabase anon key is designed for client exposure; the Gemini key is not.
- **`HUGGINGFACE_TOKEN` likewise ships to clients** (`main.dart:17`, `local_gemma_datasource.dart:128`). It is used to authorize Gemma model downloads from HF; treat scope as "read public gated model" and rotate if compromised. (P1)
- **Supabase anon key exposure is expected**, but the project's RLS posture (see above) determines whether that exposure is safe. If RLS is permissive the anon key is effectively a service key. (Cross-ref P0 in "Supabase RLS trust surface".)

## Top Recommendations (security-local, severity-ordered)

| # | Severity | Effort | Recommendation | Evidence |
| --- | --- | --- | --- | --- |
| 1 | P0 | M | Move Gemini API calls behind a server proxy (Supabase Edge Function or dedicated backend); remove `GEMINI_API_KEY` from the client bundle. | `translator_providers.dart:54-55`, `cloud_gemma_datasource.dart:47` |
| 2 | P0 | S | Implement client-side OTP resend cooldown (30–60s) and a 5-attempt verify lockout with backoff; remove the dead `_resendCooldown=0` field. | `phone_otp_screen.dart:46,95,134-162` |
| 3 | P0 | S | Wire `AuthChangeEvent.passwordRecovery` to a dedicated `ResetPasswordScreen` that forces `updateUser(password:)` before letting the user proceed; stop reusing `/auth/reset` for both OAuth callback and recovery. | `app_router.dart:138-142`, `supabase_auth_datasource.dart:179`, no `passwordRecovery` handler anywhere in `lib/` |
| 4 | P0 | S | Verify and document Supabase RLS for: `profiles.role` non-writable by row owner; `stroke_patterns` INSERT admin-only; `avatars` bucket write scoped to `auth.uid()` prefix. Add an integration test that asserts each policy. | `current_user_role_provider.dart:21`, `supabase_stroke_pattern_datasource.dart:27`, `profile_management_datasource.dart:150` |
| 5 | P0 | S | Confirm `.env` is git-ignored and was never committed (rotate any leaked keys if it was). | repo root `.env` present |
| 6 | P1 | M | Switch to `flutter_secure_storage`-backed Supabase auth persistence (configure `Supabase.initialize(authOptions: ...)`); replace `kudlit://` custom scheme with Android App Links / iOS Universal Links. | `main.dart:13-16`, `supabase_auth_datasource.dart:87,179` |
| 7 | P1 | S | Update privacy policy + add an in-app "Cloud AI" disclosure next to the AI-mode toggle naming Google/Gemini and listing forwarded fields (display name, memory facts, chat turns, sketches). | `privacy_policy_screen.dart:51-71`, `butty_chat_controller.dart:212-254` |
| 8 | P1 | XS | Strip raw fact content from `[MemoryExtraction] JSON parse failed` debug log; log only error class + length. | `memory_extraction_service.dart:143` |
| 9 | P1 | S | Add per-session attempt counters for both `sendPhoneOtp` and `verifyPhoneOtp`; surface `Failure.tooManyRequests` distinct from `invalidCredentials` in the UI. | `phone_sign_in_screen.dart:89`, `phone_otp_screen.dart:98` |
| 10 | P2 | S | Map 401/`session_not_found` Supabase errors to `Failure.sessionExpired` so the router can force re-login instead of showing "Unexpected error." | `auth_repository_impl.dart:117-142` |
| 11 | P2 | S | Pin OAuth `redirectTo` to an env-configured allow-list instead of `Uri.base.origin`; assert host matches before calling `signInWithOAuth`. | `supabase_auth_datasource.dart:85-92` |
| 12 | P2 | XS | Suppress raw Supabase error strings in `Failure.unknown` for auth flows (use generic copy) to avoid account enumeration. | `auth_repository_impl.dart:141` |
| 13 | P2 | S | Add a "minimize cloud context" toggle that omits profile/memory blocks from the system prompt when cloud mode is on. | `butty_chat_controller.dart:212-254` |

## Methods
- **Files read:** `lib/features/auth/data/datasources/supabase_auth_datasource.dart`, `lib/features/auth/data/repositories/auth_repository_impl.dart`, `lib/core/auth/current_user_role_provider.dart`, `lib/app/router/app_router.dart`, `lib/app/constants.dart`, `lib/features/auth/presentation/screens/phone_sign_in_screen.dart`, `lib/features/auth/presentation/screens/phone_otp_screen.dart`, `lib/features/auth/presentation/screens/privacy_policy_screen.dart`, `lib/features/translator/data/datasources/cloud_gemma_datasource.dart`, `lib/features/translator/data/datasources/local_gemma_datasource.dart`, `lib/features/translator/data/datasources/supabase_chat_datasource.dart`, `lib/features/translator/data/datasources/supabase_chat_memory_datasource.dart`, `lib/features/translator/data/datasources/flutter_gemma_bootstrap.dart`, `lib/features/translator/presentation/providers/translator_providers.dart`, `lib/features/translator/presentation/providers/memory_extraction_service.dart`, `lib/features/home/data/datasources/profile_management_datasource.dart`, `lib/features/home/presentation/providers/butty_chat_controller.dart`, `lib/features/home/presentation/providers/translation_history_provider.dart`, `lib/features/scanner/presentation/providers/scan_history_provider.dart`, `lib/features/learning/data/datasources/supabase_lesson_datasource.dart`, `lib/features/admin/data/datasources/supabase_stroke_pattern_datasource.dart`, `lib/main.dart`, `lib/core/config/supabase_config.dart`, `.env.example`.
- **Greps:** `\.from\('` (all Supabase tables), `debugPrint|print\(|Logger\.|log\(` (PII logs), `AIza|sk-…|hf_…|eyJ…` (hard-coded keys), `AuthChangeEvent.passwordRecovery|onAuthStateChange` (recovery handler).
- **Prior audits reconciled:** `docs/supabase_phone_otp_integration.md` (server-side OTP rate-limits flagged as "review before prod" — confirmed client never enforces them), `docs/supabase_phone_google_auth_plan.md`, `docs/backend_audit_2026.md`, `docs/backend_audit_2026-05-05.md` (RLS noted as outstanding — confirmed every table still trusts RLS implicitly).
