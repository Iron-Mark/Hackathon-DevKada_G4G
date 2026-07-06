# Kudlit — Executive Summary (Audit 2026-05-14)

## Overall readiness

**`needs-polish`** — Kudlit's product surface and offline architecture are genuinely strong, but a small number of P0 issues block a confident public release. None are intractable; nine of the Top 10 are S/M-effort and can be cleared in a focused sprint. The single L-effort item (scanner domain `Either<Failure, T>` refactor) is structural and can be sequenced after the rest.

## Top 3 strengths

1. **Butty chat memory architecture is sound and verified.** Two-layer split (episodic chat history + semantic memory facts with a `normalized` UNIQUE index), 20-turn sliding window, and "Start fresh" that preserves memory all behave as designed. See `04_performance_offline.md` § Butty chat memory.
2. **Design tokens are real, the theme is wired through `MaterialApp.router`, and shared shells (`KudlitAuthShell`, `HomeTopbar`, `FloatingTabNav`) are reused consistently across auth and home.** Light/dark variants are both present. Many of the visual fragmentation issues called out by Lane 7 are inline-duplication of *existing* tokens, not missing tokens — i.e., the fix is mechanical.
3. **Clean Architecture's domain boundary is held cleanly.** Lane 3 found zero `package:flutter` imports inside `domain/`, single-quote and trailing-comma compliance is solid, and there are no `_buildXxxWidget()` private UI helpers — the codebase already enforces the harder rules in `CLAUDE.md`.

## Top 5 risks

1. **`GEMINI_API_KEY` is shipped in the client bundle** (`translator_providers.dart:54-55`). Anyone can extract it from the APK or web bundle. Must move behind a server proxy before any public release.
2. **YOLO inference runs forever.** `HomeScreen` mounts all four tabs in a PageView (`home_screen.dart:122-145`); the native YOLO model keeps detecting even when the user is in Translate/Learn/Butty. Battery, heat, and a recent "pause on result" commit (7f28abc) only papered over the dispatch — not the model.
3. **Web is silently broken in the data layer.** Every `sqflite` datasource is constructed without a `kIsWeb` guard; the first cache read on web will throw `MissingPluginException`. Compounding this, password reset on web passes `redirectTo: null`, so flow correctness depends on Supabase Site URL configuration that is invisible to the code.
4. **Auth is one mis-step from a take-over.** Password recovery deep link establishes a Supabase session but has no `AuthChangeEvent.passwordRecovery` handler and no forced-password-update screen — if a recovery email leaks, the link is effectively a "log in as me." Combined with no client-side OTP cooldown (`phone_otp_screen.dart:46` has a dead `_resendCooldown = 0`), the auth surface is the weakest part of the app.
5. **Admin route is reachable by any signed-in user.** `/admin/stroke-recorder` is only hidden in Settings; the router has no role guard (`app_router.dart:163-167`). A typed URL bypasses the entire affordance.

## One-paragraph verdict

Kudlit is a well-shaped, opinionated app that has clearly been built with care — the offline-first memory architecture, the unified design system, and the held-firm Clean Architecture boundary on `domain/` are above-average for a Flutter project of this size. The risks blocking ship cluster narrowly in three areas: an exposed cloud key, a leaking inference loop, and a soft auth surface (password reset handler, OTP throttling, admin route guard). Fix the Top 10 in `99_top10_improvements.md` — six are ≤1-day changes, three are 1–3 days, one is the larger scanner-domain refactor — and Kudlit moves from "needs-polish" to "ship-ready" inside a single focused sprint. Defer the broader presentation→data refactor (24 sites) to a follow-up release; it is real debt but not blocking.
