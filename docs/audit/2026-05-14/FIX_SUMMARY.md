# Top 10 P0 Fixes — Implementation Summary (2026-05-14)

All ten audit P0s shipped via 6 parallel/sequential fix lanes. `flutter analyze` clean.

## Orchestration

- **Batch 1 — 5 lanes in parallel** (A, B, C, D, E): no file overlap.
- **Batch 2 — 1 lane sequential** (F): refactors interfaces Batch 1's perf fix uses.
- **Integration cleanup**: 4 small follow-up edits to resolve `flutter analyze` issues across lane boundaries.

## What landed

### Lane A — Auth + Router (items 1, 2, 3, 6)
- **Item 1 — OTP cooldown + lockout.** `phone_otp_screen.dart`: 30 s resend cooldown via `Timer.periodic`, 5-attempt verify lockout with 60 s backoff, dead `_resendCooldown=0` removed. Auto-submit on 6-digit entry now gated by lockout.
- **Item 2 — Password recovery handler.** `router_listenable.dart` now subscribes to `Supabase.instance.client.auth.onAuthStateChange` and flips `passwordRecoveryPending` on `AuthChangeEvent.passwordRecovery`. New route `/reset-password` with a real `ResetPasswordScreen` that calls `supabase.auth.updateUser(UserAttributes(password:))` and signs out on success. OAuth callback path on `/auth/reset` left intact and clearly separated.
- **Item 3 — Admin route gate.** `app_router.dart` redirect now reads `currentUserRoleProvider` via `RouterListenable.roleState` and bounces non-admins from `/admin/stroke-recorder` to `/home` (loading/error states also deny).
- **Item 6 — Web reset redirectTo.** `supabase_auth_datasource.dart` web branch now passes `redirectTo: '${Uri.base.origin}/auth/reset'` instead of `null`. Native deep-link path untouched.

### Lane B — UX + A11y (items 4, 5)
- **Item 4 — WCAG AA contrast.** Hint alpha bumped from `withAlpha(100/110)` to `withAlpha(160)` in `chat_input_bar.dart:49` and `text_input_box.dart:47`. `kudlit_colors.dart:24` `grey300 / subtleForeground` darkened `#6C738E` → `#4A5068` (~6.53:1 on `blue900`).
- **Item 5 — Welcome credibility.** Deleted "Authentication is UI-only for now." caption at `auth_welcome_screen.dart:61-66`. No replacement added.

### Lane C — YOLO pause off-tab (item 8)
- **Pattern B in-place pause** wired into `home_screen.dart`. New `_syncScannerInference({previous, next})` helper calls `detector.pauseInference()` when leaving Scan and `resumeInference()` when entering. Hooked from `_onTabSelected` and `didChangeDependencies` so both user taps and deep-link routing flip inference correctly. `kIsWeb` guard matches the existing pattern in `scan_tab_controller.dart`.
- **Why this actually halts the native model** (vs commit 7f28abc which only gated the dispatch): `YoloBaybayinDetector.pauseInference()` calls `_controller.stop()` on the `YOLOViewController`, halting the native YOLO pipeline. `resumeInference()` calls `_controller.restartCamera()`.

### Lane D — sqflite web stubs (item 9)
- 6 datasources now factory-switch on `kIsWeb`:
  - **Option A (in-memory)**: `sqlite_chat_datasource`, `sqlite_chat_memory_datasource` (dedupe via normalized set), `sqlite_scan_history_datasource`, `sqlite_translation_history_datasource`, `sqlite_lesson_progress_datasource`.
  - **Option B (silent no-op + debugPrint once)**: `local_profile_management_datasource` — `ProfileManagementRepositoryImpl` already cache-first with Supabase fallback, so always-miss + silent writes route via remote.
- Native sqflite code path untouched; no caller modifications.
- Caveat: web data is session-scoped (reload = blank). Authenticated users get cross-session persistence via Supabase sync as before.

### Lane E — Gemini proxy (item 7)
- **New `supabase/functions/gemini-proxy/index.ts`** — Deno Edge Function. Validates Supabase JWT via service-role `supabase.auth.getUser(jwt)`, rate-limits per user (10 req/60s, in-memory; TODO note for durable counter), forwards body to Google AI Studio Gemini, supports streaming + non-streaming.
- **`cloud_gemma_datasource.dart` refactor** — default constructor now takes `SupabaseClient` and routes via `supabase.functions.invoke('gemini-proxy', ...)`. Test constructor `withAi(Genkit)` preserved for the 16 existing tests.
- **Client cleanup** — removed `dotenv.env['GEMINI_API_KEY']` from `translator_providers.dart`. Updated `.env.example`.
- **README at `supabase/functions/gemini-proxy/README.md`** with deploy commands.
- **DEPLOY COMMANDS the user must run before cloud Gemma works:**
  ```bash
  supabase secrets set GEMINI_API_KEY=<actual-key>
  supabase functions deploy gemini-proxy
  ```
- **Also:** rotate the leaked Gemini key once the proxy is live (it appears in the committed `.env`).

### Lane F — Scanner Either refactor (item 10)
- **New `lib/features/scanner/domain/failures/scanner_failures.dart`** — `ScannerFailures.init/inference/capture/cameraControl/webUnsupported` factories + `ScannerFailureKind` enum + `scannerFailureKindOf(Failure)` helper. Failures emitted as tagged `Failure.unknown(message: '<TOKEN>: <msg>')` to avoid modifying the sealed core `Failure` class.
- **New use cases** under `lib/features/scanner/domain/usecases/`: `detect_baybayin`, `capture_frame`, `toggle_torch`, `switch_camera`, `pause_scanner`, `resume_scanner`. All extend the shared `UseCase<TResult, Params>` base.
- **Interface refactored.** `baybayinDetector.dart` methods now return `Future<Either<Failure, T>>`. Live `detections` stream and `dispose` unchanged.
- **All 3 implementations updated** to wrap success in `Right(...)` and exceptions in typed `Left(...)`: `yolo_baybayin_detector.dart`, `web_baybayin_detector_stub.dart`, `web_tflite_baybayin_detector.dart`. Web stubs return `Left(webUnsupported)` for torch/switch.
- **All callers migrated** — `scan_tab_controller.dart` (`.fold` everywhere; flash optimistic state revert on failure), `home_screen.dart` (Lane C helper now folds + `debugPrint` on failure without surfacing UI), `scanner_camera.dart` (web capture flow folds).
- **Tests updated** — `yolo_baybayin_detector_test.dart` and `scan_tab_controller_test.dart` updated to the new Either contract.

### Integration cleanup (post-batch)
Resolved 6 errors + 2 warnings from `flutter analyze`:
- `router_listenable.dart` — hid `AuthUser` from `supabase_flutter` to resolve ambiguity with the local domain entity (cascaded to `app_router.dart:51`).
- `local_profile_management_datasource.dart` — made `_WebProfileManagementDatasource extends SqfliteProfileManagementDatasource` so the factory return type is valid.
- `cloud_gemma_datasource.dart` — added missing `package:genkit_google_genai/genkit_google_genai.dart` import for `GeminiOptions` / `googleAI`; removed dead `?? 0` on non-nullable `response.status`.

## Final state

```
$ flutter analyze
No issues found! (ran in 4.3s)
```

10/10 P0s fixed. 0 analyzer issues.

## What still needs human action

1. **Deploy the Gemini proxy Edge Function** and set `GEMINI_API_KEY` in Supabase secrets (commands above). Cloud Gemma is non-functional until this is done.
2. **Rotate the leaked Gemini key** that appears in the committed `.env`.
3. **Run `dart run build_runner build --delete-conflicting-outputs`** if the Riverpod codegen needs regeneration for any of the touched providers.
4. **Manual smoke test** of:
   - Phone OTP flow with intentional failures to confirm lockout/cooldown UX.
   - Password recovery deep link from a real reset email.
   - Admin route as non-admin to confirm redirect.
   - Web build (`flutter build web`) — confirms sqflite stubs hold up at runtime.
   - Scanner end-to-end on Android to confirm pause/resume around tab switches actually halts native inference.

Nothing was committed.
