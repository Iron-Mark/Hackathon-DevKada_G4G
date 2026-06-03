# 01 — UX/UI per-screen, mobile-first
**Auditor:** general-purpose (UX lane) · **Skill invoked:** ui-ux-pro-max (deferred — not loaded in this run, applying heuristics manually) · **Date:** 2026-05-14

## Summary
- P0 count: 11 · P1 count: 34 · P2 count: 27
- Single biggest risk: `auth_welcome_screen.dart` and `sign_up_screen.dart` flagship sign-up flow shows "Authentication is UI-only for now." on the welcome card (auth_welcome_screen.dart:64) — this contradicts a working Supabase auth backend and will undermine user trust at the most fragile moment of the funnel.

## Findings

### lib/features/home/presentation/screens/splash_screen.dart — route `/splash`
- **Purpose:** Holding screen that pre-warms the YOLO detector while the router resolves auth/preferences.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Clean fade+scale entry; brand mark fallback if asset missing (splash_screen.dart:139, splash_screen.dart:144).
  - Loader has copy ("Starting Kudlit…") instead of a bare spinner (splash_screen.dart:192).
- **Cons:**
  - No timeout/escape hatch — if router redirect stalls, the splash never surfaces a retry or error (splash_screen.dart:14).
  - Subtitle "Baybayin · Learn · Translate" uses `letterSpacing: 0.8` at 13 px on a dark gradient, contrast borderline (splash_screen.dart:123).
  - `_kBackground` gradient ends at 0.85 stop, leaving a flat black band at the bottom that fights the otherwise soft transition (splash_screen.dart:86).
- **Improvements:**
  - **P1** — add a "Taking longer than usual…" affordance after ~6 s with a retry/diagnostics button (splash_screen.dart:42).
  - **P2** — extend gradient to `stops: [0.0, 1.0]` or pad subtitle contrast (splash_screen.dart:86).
- **Multiplatform notes:** Web skips detector pre-warm (splash_screen.dart:19) — fine, but the spinner copy is identical so users on web won't know the wait is shorter. Consider a web-specific status string.

### lib/features/home/presentation/screens/model_setup_screen.dart — route `/setup`
- **Purpose:** First-launch download gate for on-device LLM + YOLO models.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Strong friendly error mapper covers offline, cancel, missing-models, generic technical strings (model_setup_screen.dart:52).
  - Layout adapts to desktop/landscape/short-portrait variants without breaking thumb reach (model_setup_screen.dart:170-220).
  - Primary CTA min-height 52 px, secondary 48 px — both above 44 px target (model_setup_screen.dart:741, model_setup_screen.dart:758).
  - Continue button has full Semantics(label/hint) (model_setup_screen.dart:725).
- **Cons:**
  - Error banner uses `color: KudlitColors.grey500` on a faint red wash — `danger400.withAlpha(18)` plus grey500 text reads as muted/disabled rather than as an error (model_setup_screen.dart:798, model_setup_screen.dart:805).
  - "Not now - stay on internet mode" uses an ASCII hyphen-minus with surrounding spaces — preferable to use en-dash or rewrite for typographic consistency (model_setup_screen.dart:764).
  - `_DownloadNotice` icon size 12–13 px and 10–11 px copy is below the 12 px legibility floor at smaller scales (model_setup_screen.dart:683-693).
  - Compact-portrait variant ditches `Spacer` rhythm so headline → panel → CTA touch when keyboard absent (model_setup_screen.dart:478).
- **Improvements:**
  - **P1** — bump error text contrast to `KudlitColors.danger400` or `cs.onErrorContainer` so the banner reads as an alert (model_setup_screen.dart:805).
  - **P2** — increase `_DownloadNotice` text to 11.5–12 px and icon to 14 px (model_setup_screen.dart:683).
  - **P2** — replace " - " with " — " or remove dash in CTA copy (model_setup_screen.dart:764).
- **Multiplatform notes:** Web variant rewrites notice to "first setup happens in this browser" (model_setup_screen.dart:691); good. Web wraps content in scroll view, mobile uses fixed Spacer layout (model_setup_screen.dart:206).

### lib/features/auth/presentation/screens/auth_welcome_screen.dart — route `/welcome`
- **Purpose:** Entry choice between "Create account" and "Sign in".
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Hero/sheet split with drag handle reads as a familiar mobile sheet (auth_welcome_screen.dart:41).
  - Clear primary vs. secondary button hierarchy (auth_welcome_screen.dart:50-60).
- **Cons:**
  - "Authentication is UI-only for now." caption directly contradicts the working Supabase flow attached to these buttons (auth_welcome_screen.dart:62-66). This is the single biggest credibility risk in the funnel.
  - Hero takes 52% of the screen on every device (auth_welcome_screen.dart:35); on short Android phones the actual auth choices end up below the fold.
- **Improvements:**
  - **P0** — delete or replace the "UI-only" disclaimer with a real reassurance line (e.g., "We never share your email.") (auth_welcome_screen.dart:62).
  - **P1** — drop `heroFraction` to ≤0.42 on heights <700 so both CTAs render above the fold without scrolling (auth_welcome_screen.dart:35).
- **Multiplatform notes:** Web inherits the same sheet metaphor; consider a centered card layout for desktop widths via `AuthScreenShell`. Not screen-local.

### lib/features/auth/presentation/screens/sign_in_screen.dart — pushed from welcome / login
- **Purpose:** Email+password sign-in with phone alternative and forgot-password link.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Error messages run through a typed `_mapFailure` so users see plain English ("Incorrect email or password.") (sign_in_screen.dart:51).
  - Hero bubble personalisation ("Great to see you again!") matches the design polish noted in `docs/auth_polish_updates.md` (sign_in_screen.dart:112).
- **Cons:**
  - On success, `Navigator.canPop` loop (sign_in_screen.dart:82) silently pops every page; if the user navigated in from a deep link with extra routes, they lose context with no transition cue.
  - No keyboard-aware scroll fallback when the sheet content + keyboard exceed viewport (relies on shell). Form field overflow on small screens not screen-tested here.
- **Improvements:**
  - **P1** — show a brief success snackbar/checkmark before popping so the abrupt nav doesn't feel like a crash (sign_in_screen.dart:81).
  - **P2** — surface caps-lock indicator inside the password field on web (sign_in_screen.dart:127).
- **Multiplatform notes:** Phone sign-in pathway is mobile-centric but reachable on web; no degradation message if OTP send fails for region.

### lib/features/auth/presentation/screens/login_screen.dart — route `/login`
- **Purpose:** Alternate login entry with Google + email + guest path.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Landscape branch swaps to side-by-side hero/sheet (login_screen.dart:81).
  - Google loading is gated against double-tap (login_screen.dart:47).
- **Cons:**
  - Two parallel screens (LoginScreen + AuthWelcomeScreen) coexist with overlapping responsibilities and inconsistent copy ("Continue with Email" vs "Create account") (login_screen.dart:38 vs auth_welcome_screen.dart:51). This creates branching mental models.
  - Google failure surfaces as raw SnackBar — no retry CTA, no "use email instead" link (login_screen.dart:54).
  - "Continue as Guest" is silently equivalent to skipping account creation; no explanation of what guest mode loses (login_screen.dart:65).
- **Improvements:**
  - **P0** — consolidate `LoginScreen` and `AuthWelcomeScreen` to one entry; the duplication is a UX hazard and design-debt cause (login_screen.dart:1, auth_welcome_screen.dart:1).
  - **P1** — surface a "What you'll miss" tooltip or microcopy under "Continue as Guest" (login_screen.dart:65).
- **Multiplatform notes:** Same sheet copy on web — Google sign-in popup behaviour differs between platforms; no platform-specific hint shown.

### lib/features/auth/presentation/screens/sign_up_screen.dart — pushed from welcome
- **Purpose:** Email/password account creation with confirmation-pending state.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Inline validators for email/password/confirm with localized constants (sign_up_screen.dart:46-72).
  - Confirmation-sent state branches to a dedicated view (sign_up_screen.dart:116).
  - Hero bubble "Let's get you set up!" matches brand voice (sign_up_screen.dart:122).
- **Cons:**
  - Password requirement floor is 6 chars (sign_up_screen.dart:61) — under modern recommendation of 8+; copy gives no strength feedback.
  - No "show password" toggle exposed at the screen level (lives in form widget — not visible from this screen's code).
  - Error banner shown only as a single string with no field-level highlight when Supabase reports field-specific failures.
- **Improvements:**
  - **P0** — raise password minimum to 8 and add a basic strength indicator (sign_up_screen.dart:61).
  - **P1** — when `_mapFailure` returns "Email already in use," offer a one-tap "Sign in instead" inline action (sign_up_screen.dart:77).
- **Multiplatform notes:** Web autofill behaviour fine because `Form` is standard, but no explicit `autofillHints` configured at this layer.

### lib/features/auth/presentation/screens/phone_sign_in_screen.dart — pushed from sign-in
- **Purpose:** Phone-number entry feeding into OTP send.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Defaults to +63 PH; country picker via bottom sheet (phone_sign_in_screen.dart:35, phone_sign_in_screen.dart:72).
  - `_normalizePhone` strips leading 0 — friendly for PH user habits (phone_sign_in_screen.dart:52).
  - "Prefer email?" escape hatch (phone_sign_in_screen.dart:180).
- **Cons:**
  - Validation message "Enter a valid phone number." returned on length<7 (phone_sign_in_screen.dart:48) — no example of expected format.
  - Error text is small (12 px) and centered, not associated with the field (phone_sign_in_screen.dart:160).
- **Improvements:**
  - **P1** — show placeholder/example "9XX XXX XXXX" within `PhoneField` for the selected country, and surface errors as field-level helper text (phone_sign_in_screen.dart:144).
- **Multiplatform notes:** Country picker is a bottom-sheet, which works well on mobile; on web it's still a sheet — okay but a select dropdown would feel more native there.

### lib/features/auth/presentation/screens/phone_otp_screen.dart — pushed from phone sign-in
- **Purpose:** Six-digit OTP entry with resend.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Live regions for resend and error messages (phone_otp_screen.dart:253, phone_otp_screen.dart:273).
  - Auto-advance focus + auto-submit on completion (phone_otp_screen.dart:90-95).
  - Masked phone display preserves last 4 digits (phone_otp_screen.dart:196).
- **Cons:**
  - `_resendCooldown` is hard-coded to 0 (phone_otp_screen.dart:46) so the cooldown branch never fires — users can spam resend and get rate-limited server-side without UI feedback.
  - Boxes are 44×54 (phone_otp_screen.dart:353) — width 44 meets minimum but with `spacing: 6` and 6 boxes, the row needs ≥300 px; on 320-px screens it wraps awkwardly via Wrap (phone_otp_screen.dart:311).
  - No autofill / `TextInputType.numberWithOptions(signed:false)` or `autofillHints: [oneTimeCode]` plumbed at this screen (phone_otp_screen.dart:358-363).
- **Improvements:**
  - **P0** — implement the resend cooldown timer to back the existing UI branch (phone_otp_screen.dart:46, phone_otp_screen.dart:435).
  - **P1** — add `autofillHints: [AutofillHints.oneTimeCode]` so iOS/Android can suggest the SMS code (phone_otp_screen.dart:355).
  - **P2** — collapse to a single 6-char hidden field with painted boxes to fix narrow-viewport wrap (phone_otp_screen.dart:311).
- **Multiplatform notes:** OTP autofill is mobile-only — web users must paste; ensure paste-across-boxes works (currently `maxLength: 1` per box blocks paste).

### lib/features/auth/presentation/screens/forgot_password_screen.dart — pushed from sign-in
- **Purpose:** Send password-reset email.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Success state replaces form with a friendly "Email sent!" headline and a Back-to-login CTA (forgot_password_screen.dart:99, forgot_password_screen.dart:135).
- **Cons:**
  - Error messages render in a thin 12 px red caption (forgot_password_screen.dart:121) with no icon, easy to miss.
  - No "Resend" affordance from success state, despite reset emails commonly going to spam.
- **Improvements:**
  - **P1** — add a "Didn't get it? Send again" link on the success view (forgot_password_screen.dart:135).
  - **P2** — wrap error in an icon+text banner consistent with `_SetupErrorBanner` style (forgot_password_screen.dart:120).
- **Multiplatform notes:** No notable platform divergence.

### lib/features/auth/presentation/screens/reset_password_screen.dart — separate route
- **Purpose:** Stub reset-password form (separate from `ForgotPasswordScreen`).
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Minimal, consistent shell with hero/sheet style (reset_password_screen.dart:48).
- **Cons:**
  - **Functionally empty** — `_submit` just flips `_hasSent` to `true` with no provider call (reset_password_screen.dart:29-37). Live users tapping this think a reset has been sent when it has not.
  - Overlapping with `ForgotPasswordScreen` — UX has two screens with similar names and different (one fake) behaviours.
- **Improvements:**
  - **P0** — either wire `_submit` to `authNotifierProvider.resetPassword` or delete the route in favour of `ForgotPasswordScreen` (reset_password_screen.dart:29).
- **Multiplatform notes:** N/A — screen is dead UI.

### lib/features/auth/presentation/screens/terms_screen.dart — route `/terms`
- **Purpose:** Static Terms-of-Service content.
- **Platforms reviewed:** Android · iOS · Web
- No notable UX issues (delegated to `LegalDocumentScreen` widget; copy is well-structured and dated). One nit: "Last updated" date is hard-coded to "May 6, 2026" (terms_screen.dart:14) — would benefit from a build-time constant to avoid drift.

### lib/features/auth/presentation/screens/privacy_policy_screen.dart — route `/privacy`
- **Purpose:** Static Privacy Policy content.
- **Platforms reviewed:** Android · iOS · Web
- No notable UX issues — same `LegalDocumentScreen` pattern, well-scoped content. Same hard-coded date caveat (privacy_policy_screen.dart:14).

### lib/features/auth/presentation/screens/home_screen.dart — route `/home` shell
- **Purpose:** Tabbed shell for Scan/Translate/Learn/Butty with floating navigation.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - `PageView` swipe disabled (home_screen.dart:127) — prevents accidental tab change in scanner/learn flows.
  - Route-driven tab switching honours `?tab=` deep links (home_screen.dart:38-53).
  - Floating nav offset clears safe area + 56 (home_screen.dart:68-70).
- **Cons:**
  - No tab label/Indicator hint when the bar is collapsed — relies entirely on icons; new users on first launch land on Scan with the camera permission prompt, no orientation toward the tab bar.
  - `MediaQuery.removePadding(removeTop: true)` (home_screen.dart:77) discards top padding for the entire body — fine for camera tab, but for translate/learn this clips header spacing.
  - `AppHeader` is shown for every tab but only "translate" toggles `showTranslateControls` (home_screen.dart:75); other tabs render a header that may not be needed (e.g., Butty has its own `ButtyHeader` resulting in a double-stack).
- **Improvements:**
  - **P1** — remove top header for `butty` and `scan` tabs (or hide it when those tabs are active) to fix the double-header on Butty (home_screen.dart:75; cf butty_chat_screen.dart:122).
  - **P1** — add a first-launch coachmark on the floating nav before user reaches camera permission (home_screen.dart:135).
- **Multiplatform notes:** Web touch targets are fine; floating nav `navRight: 18` is small for desktop pointer use — consider centering on desktop.

### lib/features/home/presentation/screens/home_tab.dart — embedded in HomeScreen (legacy "home" landing)
- **Purpose:** Marketing-style landing tab with welcome banner, tool shortcuts, lesson grid.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Background asset opacity at 12% (home_tab.dart:55) keeps reading surface usable.
  - Tools row uses `IntrinsicHeight` so both cards match heights (home_tab.dart:107).
- **Cons:**
  - "Coming Soon" tile is a dead tile that occupies grid space with no disclosure (home_tab.dart:161). It looks tappable.
  - Lesson grid `childAspectRatio: 0.85` (home_tab.dart:177) yields cramped images on 320 px width.
  - "See all" action declared (home_tab.dart:86) but no navigation wired here — easy to miss because section header widget is external.
  - This tab is not visible in the `HomeScreen` PageView (only Scan/Translate/Learn/Butty are present home_screen.dart:128) — appears orphaned/dead code. Confirm in routes.
- **Improvements:**
  - **P0** — verify whether `home_tab.dart` is actually mounted; if not, delete (home_tab.dart:1). Dead UI competes with the live `LearnTab` for the "home" mental model.
  - **P1** — make Coming-Soon tile non-tappable with an explicit "Locked" affordance (home_tab.dart:163).
- **Multiplatform notes:** N/A — likely unreachable.

### lib/features/home/presentation/screens/scan_tab.dart — `/home?tab=scan`
- **Purpose:** Live YOLO scanner with capture, gallery, flash, retake, permutation cycling, save/share.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Shutter haptic + 200 ms white flash gives strong capture feedback (scan_tab.dart:228, scan_tab.dart:319).
  - Status chip has Semantics label and auto-hide after 6 s (scan_tab.dart:97, scan_tab.dart:874).
  - Tiny-viewport branch reduces icon and font sizes to keep controls usable on <340 px screens (scan_tab.dart:625).
  - Retry CTA in the notice panel calls a haptic-backed snackbar so users feel the action (scan_tab.dart:111).
  - Permutation cycler exposes "Reading N of M" with min-44-px chevrons (scan_tab.dart:1460).
- **Cons:**
  - First-launch onboarding completely absent — users see a camera with no "Frame a glyph" coachmark.
  - `_AggregatedWinnerBanner` (scan_tab.dart:473) renders without a dismiss; if the panel competes with the result panel, both can stack visually.
  - Result-panel typography mixes 28 px Baybayin display with 18 px Latin and 12 px tokens — readable but `tokenPreview` joined with " · " (scan_tab.dart:1197) is decorative rather than informative for screen readers.
  - "Tell me more" pill is left-aligned at 12 px (scan_tab.dart:1633) — touch target 48 px height is fine but the visual weight competes with Butty bubble.
  - Status chip and YOLO model dropdown both pinned to top-right at slightly different `top` offsets (scan_tab.dart:357, scan_tab.dart:389) — risk of overlap on small screens; relies on hand-tuned offsets.
  - The "Aggregated winner banner" carries `_settledReading` semantics but no announcement (no Semantics liveRegion) (scan_tab.dart:480-528).
- **Improvements:**
  - **P0** — add a first-run onboarding overlay (single tap-to-dismiss card) explaining capture/gallery/flash; the camera tab is the app's hero surface and currently has no orientation (scan_tab.dart:251).
  - **P1** — give `_AggregatedWinnerBanner` a Semantics(liveRegion) wrapper so VoiceOver/TalkBack announce settled readings (scan_tab.dart:480).
  - **P1** — collapse the YOLO model dropdown into a settings sheet on screens <380 px; presently it overlaps the status chip vertical column (scan_tab.dart:389).
  - **P2** — replace " · " token preview with comma-joined string for SR clarity (scan_tab.dart:1197).
- **Multiplatform notes:** Web has its own `WebScannerStatus` chain with `initializing|permissionNeeded|error` states (scan_tab.dart:84). Native hides gallery/flash when frozen but web hides flash always (scan_tab.dart:343). Web "Capture Webcam Frame" label is awkward — consider "Capture frame" everywhere (scan_tab.dart:419).

### lib/features/home/presentation/screens/translate_screen.dart — `/home?tab=translate`
- **Purpose:** Text translator + sketchpad mode with AI integration; respects offline/online prefs.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - `disabledReason` propagated to children — buttons disable with explanation ("Preparing offline Gemma…") (translate_screen.dart:60-65).
  - Adaptive layout collapses header when keyboard or short-landscape (translate_screen.dart:137).
  - Copy/Share snackbars handle empty-state ("Nothing to copy yet.") (translate_screen.dart:181).
- **Cons:**
  - `disabledReason` is rendered indirectly; not surfaced as a visible banner on this screen — user has to attempt an action to discover why it's disabled (translate_screen.dart:60).
  - When keyboard opens, the header disappears entirely (translate_screen.dart:148) — workspace mode toggle becomes inaccessible mid-edit.
  - Both copy and share use SnackBar with no undo/feedback consistency (translate_screen.dart:189).
- **Improvements:**
  - **P1** — render `disabledReason` as a sticky helper strip at top of the panel so users see "Preparing offline Gemma…" before pressing (translate_screen.dart:60).
  - **P1** — keep workspace mode pill visible above the keyboard (e.g., float a 36 px chip), or restore the header on focus-out (translate_screen.dart:148).
- **Multiplatform notes:** `view.viewInsets.bottom / devicePixelRatio` (translate_screen.dart:69) is a manual keyboard inset calc; on iOS web this can return 0 even when on-screen keyboard is up — needs platform check.

### lib/features/home/presentation/screens/learn_tab.dart — `/home?tab=learn`
- **Purpose:** Wrapper around `LearnHomeBody` that wires up nav to lesson/gallery/quiz/butty.
- **Platforms reviewed:** Android · iOS · Web
- No notable UX issues at this thin shell. `bottomPad` correctly accounts for safe area + floating nav clearance (learn_tab.dart:19-20). See `learn_home_body.dart` for content concerns (not in scope).

### lib/features/home/presentation/screens/butty_chat_screen.dart — `/home?tab=butty`
- **Purpose:** Conversational chat with Butty (online or offline Gemma).
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Lifecycle-aware memory flush on app pause/inactive (butty_chat_screen.dart:42-51).
  - Suggested questions row appears only for the first system message (butty_chat_screen.dart:165).
  - Offline-status hint banner reuses `cs.surfaceContainer` (butty_chat_screen.dart:131).
- **Cons:**
  - The offline-pending banner sits *below* the message list so users scrolling messages may not notice why input is disabled (butty_chat_screen.dart:130).
  - Auto-scroll triggers on every message-count change (butty_chat_screen.dart:113); if the user scrolled up to read past content, new tokens yank them back — common chat anti-pattern.
  - `ChatInputBar` `enabled` flag is set but `disabledHint` may not surface as a tooltip on long-press for mobile (butty_chat_screen.dart:172).
  - No "stop generating" affordance during `responding` (butty_chat_screen.dart:128).
- **Improvements:**
  - **P0** — only auto-scroll if user is already at the bottom (use `_scroll.position.pixels >= maxScrollExtent - 80`) (butty_chat_screen.dart:73).
  - **P1** — show a "Stop" button while responding (butty_chat_screen.dart:172).
  - **P2** — move offline-pending banner above the message list so it's the first thing seen after the header (butty_chat_screen.dart:130).
- **Multiplatform notes:** Lifecycle observer flush is irrelevant on web; no harm but `paused/inactive` rarely fires there.

### lib/features/home/presentation/screens/profile_tab.dart — `/home?tab=profile` (or settings path)
- **Purpose:** Guest sign-in prompt OR authenticated user profile shortcuts.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Guest copy "Kumusta, Bisita!" is on-brand and warm (profile_tab.dart:66).
  - Profile row + history shortcuts all use 64-px min-height tappable tiles (profile_tab.dart:287, profile_tab.dart:373).
  - Mascot scales between compact/regular (profile_tab.dart:42).
- **Cons:**
  - No way to *reach* settings other than tapping the small edit icon at the right of the profile row — discovery is poor for an "edit profile" affordance (profile_tab.dart:337).
  - Initials avatar fallback uses email[0] (profile_tab.dart:251) — looks broken if the email starts with a digit or symbol.
  - Email shown in 11.5 px secondary text (profile_tab.dart:328) — borderline AA at the chosen alpha.
- **Improvements:**
  - **P0** — add an explicit "Settings" icon-button at the top of the user profile state, not just the edit chevron (profile_tab.dart:280).
  - **P1** — guard initials against non-letter first chars (profile_tab.dart:251).
  - **P2** — raise email size to 12.5 px or alpha to 160+ (profile_tab.dart:328).
- **Multiplatform notes:** Avatar `Image.network` has no width/cache-policy hints — repeated rebuilds on web flicker.

### lib/features/home/presentation/screens/settings_screen.dart — route `/settings`
- **Purpose:** Hosts `SettingsHeader` + `SettingsList` with sign-out.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Sign-out chains into `context.go(routeLogin)` cleanly (settings_screen.dart:33).
- **Cons:**
  - Sign-out has no confirmation dialog — accidental tap signs the user out and pops them all the way back to login (settings_screen.dart:33).
  - Action snackbars are generic `Text(message)` with no semantic role (settings_screen.dart:48).
- **Improvements:**
  - **P0** — add an "Are you sure?" confirmation before sign-out, or at least an undo snackbar with 5-second window (settings_screen.dart:33).
- **Multiplatform notes:** N/A.

### lib/features/home/presentation/screens/translation_history_screen.dart — route `/translation-history`
- **Purpose:** List saved translations with bookmark toggle.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Empty state has icon + descriptive copy + bounded width 360 (translation_history_screen.dart:112-156).
  - Date formatter coverages today/yesterday/<7 days/other (translation_history_screen.dart:200-207).
  - Bookmark IconButton enforces min 44×44 (translation_history_screen.dart:259).
- **Cons:**
  - No search/filter when list grows; pure chronological list will scale poorly past ~30 items (translation_history_screen.dart:91).
  - Error state displays raw exception text (translation_history_screen.dart:180) — leaks technical info.
  - No "delete entry" affordance — bookmarking is the only mutation.
  - Cards lack a tap target for "view details" — only the bookmark toggle is interactive (translation_history_screen.dart:215).
- **Improvements:**
  - **P1** — add an `InkWell` tap to expand into a detail sheet showing full AI response (translation_history_screen.dart:215).
  - **P1** — sanitise error text (translation_history_screen.dart:180); show "Couldn't load history. Pull to retry." with a retry button.
  - **P2** — add filter chips for "Bookmarked" / "Latin→Baybayin" / "Baybayin→Latin" (translation_history_screen.dart:32).
- **Multiplatform notes:** N/A.

### lib/features/home/presentation/screens/learning_progress_screen.dart — route `/learning-progress`
- **Purpose:** Ocean-themed progress hub with overall ring, per-lesson tiles, and continue-CTA.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Strong themed hero with bubbles + wave clipper + mascot (learning_progress_screen.dart:151-279).
  - Animated ring (TweenAnimationBuilder) and tile press-scale feel premium (learning_progress_screen.dart:423, learning_progress_screen.dart:546).
  - Status-aware borders (completed/in-progress/notStarted) read clearly (learning_progress_screen.dart:629).
  - Tile message ("Magaling ka!") personalised by progress (learning_progress_screen.dart:119-128).
- **Cons:**
  - "Not started" tiles are non-tappable (learning_progress_screen.dart:544) — but visually still look like cards. Users will tap, get nothing, and read it as a bug.
  - Hero takes 210 px (learning_progress_screen.dart:133); on short Android (<640 px), the overall ring card is the only above-the-fold content.
  - Score-only completion subtitle ("Score: 0 pts") shows for completed lessons even if score is missing (learning_progress_screen.dart:727).
  - Lesson IDs and names are hard-coded twice in this file and again in `learn_home_body.dart` — content drift risk; not a UX bug per se but a copy-consistency hazard.
- **Improvements:**
  - **P1** — give "Not started" tiles a tappable hint that opens an "Unlock by finishing X first" sheet, or visibly lock with a `pointerEvents: none` + tooltip (learning_progress_screen.dart:544).
  - **P2** — let the SliverAppBar collapse to ~110 px so the ring is visible without scroll on small phones (learning_progress_screen.dart:133).
- **Multiplatform notes:** N/A.

### lib/features/home/presentation/screens/butty_data_screen.dart — route `/butty-data`
- **Purpose:** Chat history + memory facts management.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Two-layer explanation upfront (butty_data_screen.dart:174-222).
  - Memory entries support add/edit/delete via dialog with type dropdown (butty_data_screen.dart:839).
  - Destructive actions gated with confirmation dialogs (butty_data_screen.dart:323, butty_data_screen.dart:720).
  - Markdown rendering for assistant content in the full-message sheet (butty_data_screen.dart:546-595).
- **Cons:**
  - "Clear all chat history" and "Clear all memory" buttons are visually identical red text buttons with subtle icon differences — high collision risk (butty_data_screen.dart:298, butty_data_screen.dart:683).
  - Memory list shows only fact content + type chip — no "last referenced" timestamp surfaced in the tile (butty_data_screen.dart:799).
  - `_FullMessageSheet` uses `SelectableText` for user but `MarkdownBody` for assistant (butty_data_screen.dart:544); inconsistent (user can't get markdown if they pasted code, assistant text can't be plain-copied easily).
  - No empty-state for filter when memory has 1 fact and user doesn't realise more come from chat (butty_data_screen.dart:660).
- **Improvements:**
  - **P1** — add an icon glyph (chat vs brain) in front of each "Clear" CTA to prevent accidental loss (butty_data_screen.dart:298, butty_data_screen.dart:683).
  - **P2** — show last-referenced relative time on each fact tile (butty_data_screen.dart:799).
- **Multiplatform notes:** Web `MarkdownBody` may render code blocks wide; this screen does not constrain max width.

### lib/features/scanner/presentation/screens/scan_history_screen.dart — route `/scan-history`
- **Purpose:** Show saved scan results.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Empty/error states match `TranslationHistoryScreen` (scan_history_screen.dart:109-198).
  - Token chips give a glanceable breakdown of recognised glyphs (scan_history_screen.dart:332-365).
- **Cons:**
  - Cards are not tappable — no "rescan" or "share" action from history (scan_history_screen.dart:221).
  - Error state shows raw exception (scan_history_screen.dart:184), same leak as `TranslationHistoryScreen`.
  - No bookmark/delete affordance — users cannot prune history.
- **Improvements:**
  - **P1** — tap card → details sheet with rescan/share/delete (scan_history_screen.dart:221).
  - **P1** — sanitise error text (scan_history_screen.dart:184).
- **Multiplatform notes:** N/A.

### lib/features/learning/presentation/screens/lesson_stage_screen.dart — route `/lesson/:id`
- **Purpose:** Lesson runner with reference/draw/free-input modes and completion overlay.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - `AnimatedSwitcher` between step modes uses fade+slide for context preservation (lesson_stage_screen.dart:185-203).
  - Completion overlay supports next-lesson/practice-again/back (lesson_stage_screen.dart:131-141).
  - Top bar action label adapts per mode and status (lesson_stage_screen.dart:232-244).
- **Cons:**
  - Help sheet is opened via a transparent modal (lesson_stage_screen.dart:48) but no Semantics indicator that one is open.
  - Error view ("Back" button) does not retry the lesson load (lesson_stage_screen.dart:294).
  - Step label inside progress bar concatenates with em-dash ("Step 1 of 3 — Step label") which can wrap awkwardly on tiny widths (lesson_stage_screen.dart:181).
  - No keyboard handling for hardware-keyboard users on free-input mode at this screen level.
- **Improvements:**
  - **P1** — add Retry button in `_ErrorView` that re-calls `loadLesson` (lesson_stage_screen.dart:294).
  - **P2** — wrap step label in Tooltip + Semantics(label: step.label) and let progress text be just "Step 1 of 3" (lesson_stage_screen.dart:178).
- **Multiplatform notes:** YOLO drawing-pad model is watched on non-web (lesson_stage_screen.dart:107) — web users get free-input + reference only; no explicit message if they hit "draw" mode by accident.

### lib/features/learning/presentation/screens/character_gallery_screen.dart — route `/character-gallery`
- **Purpose:** Browseable Baybayin glyph library with filters and search.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - ChoiceChip filters + search field combine nicely (character_gallery_screen.dart:198-220).
  - `LayoutBuilder` switches to 2-column grid at ≥560 px (character_gallery_screen.dart:262).
  - Rich Semantics labels on each glyph cell (character_gallery_screen.dart:323).
- **Cons:**
  - Search trigger lives on every `onChanged` (character_gallery_screen.dart:56) which forces a full state rebuild and re-filter; on large libraries this will jank.
  - Empty state copy is functional but cold ("No glyphs match that search.") (character_gallery_screen.dart:234) — no "clear search" CTA.
  - Filter chips have no "All" feedback colour distinct from selected — selected vs unselected ChoiceChip is the default theme; on dark mode this can be flat.
- **Improvements:**
  - **P1** — add a "Clear search" link inside `_EmptyGalleryMessage` (character_gallery_screen.dart:230).
  - **P2** — debounce search by 120 ms to avoid rebuild thrash (character_gallery_screen.dart:56).
- **Multiplatform notes:** N/A — pure layout.

### lib/features/learning/presentation/screens/quiz_screen.dart — route `/quiz`
- **Purpose:** Romanization quiz over previously learned glyphs.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Linear progress + glyph display + answered-section structure is clear (quiz_screen.dart:200-275).
  - Result card branches cleanly (quiz_screen.dart:83-90).
- **Cons:**
  - Wrong-answer feedback only shows the correct answer once — no "explain" or "see in gallery" link (quiz_screen.dart:347-364).
  - No life/retry budget shown; user doesn't know how many wrong answers cost score.
  - Empty body "Complete a lesson first to unlock the quiz." is a dead-end; no CTA back to Learn (quiz_screen.dart:121).
  - "Check" button gets `Size.fromHeight(44)` (quiz_screen.dart:309) which meets minimum but no visual prominence — hard to find after a long romanization field.
- **Improvements:**
  - **P1** — add a "See in gallery" or "Practice again" inline link on wrong-answer banner (quiz_screen.dart:347).
  - **P2** — give the empty body a `FilledButton` "Go to lessons" (quiz_screen.dart:121).
- **Multiplatform notes:** N/A.

### lib/features/admin/presentation/screens/stroke_recording_screen.dart — admin-only route
- **Purpose:** Internal stroke-pattern recording for training data.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - Clear state-machine UI (idle/saving/saved/error) (stroke_recording_screen.dart:42-57).
  - Session strip surfaces "what you already saved" so the recorder doesn't lose track (stroke_recording_screen.dart:310).
  - Confirmation dialog on clear-all (stroke_recording_screen.dart:666).
- **Cons:**
  - Admin-only context but no badge/banner labelling it as "Admin tool — not for users" (stroke_recording_screen.dart:33). Risk if route leaks to production user.
  - "Image ✓" affordance uses a checkmark in the button label (stroke_recording_screen.dart:189) — confusing as it doubles as both state and action.
  - Slider thumb radius 8 + track height 3 produces a thin track that's hard to grab on mobile (stroke_recording_screen.dart:425).
- **Improvements:**
  - **P1** — add a debug/admin chip in the AppBar so it's obvious this isn't user-facing (stroke_recording_screen.dart:33).
  - **P2** — bump slider track height to 4–6 px and thumb to 10 (stroke_recording_screen.dart:424-426).
- **Multiplatform notes:** N/A — internal.

## Top Recommendations (UX-local, severity-ordered)

| # | Severity | Effort | Recommendation | Evidence |
|---|---|---|---|---|
| 1 | P0 | S | Remove "Authentication is UI-only for now." from welcome card | auth_welcome_screen.dart:62 |
| 2 | P0 | M | Wire `ResetPasswordScreen._submit` to provider or delete the screen | reset_password_screen.dart:29 |
| 3 | P0 | M | Consolidate `LoginScreen` and `AuthWelcomeScreen` into one entry | login_screen.dart:1; auth_welcome_screen.dart:1 |
| 4 | P0 | S | Raise password min to 8 chars + add strength feedback | sign_up_screen.dart:61 |
| 5 | P0 | M | Implement OTP resend cooldown timer | phone_otp_screen.dart:46 |
| 6 | P0 | M | Verify/delete unused `home_tab.dart` ghost screen | home_tab.dart:1 |
| 7 | P0 | M | Add scan-tab first-run coachmark | scan_tab.dart:251 |
| 8 | P0 | S | Stop auto-scroll yanking Butty chat when user scrolled up | butty_chat_screen.dart:73 |
| 9 | P0 | S | Add sign-out confirmation dialog | settings_screen.dart:33 |
| 10 | P0 | S | Add explicit Settings entry to authed Profile tab | profile_tab.dart:280 |
| 11 | P1 | S | Replace raw exception strings in error states | translation_history_screen.dart:180; scan_history_screen.dart:184 |
| 12 | P1 | M | Surface `disabledReason` as a sticky banner on Translate | translate_screen.dart:60 |
| 13 | P1 | S | Add liveRegion + sanitised SR text on aggregated winner | scan_tab.dart:480 |
| 14 | P1 | M | "Not started" lesson tiles need explicit locked affordance | learning_progress_screen.dart:544 |
| 15 | P1 | S | Add `autofillHints: [oneTimeCode]` to OTP boxes | phone_otp_screen.dart:355 |

## Methods
- Files read:
  - lib/features/home/presentation/screens/splash_screen.dart
  - lib/features/home/presentation/screens/model_setup_screen.dart
  - lib/features/auth/presentation/screens/auth_welcome_screen.dart
  - lib/features/auth/presentation/screens/sign_in_screen.dart
  - lib/features/auth/presentation/screens/login_screen.dart
  - lib/features/auth/presentation/screens/sign_up_screen.dart
  - lib/features/auth/presentation/screens/phone_sign_in_screen.dart
  - lib/features/auth/presentation/screens/phone_otp_screen.dart
  - lib/features/auth/presentation/screens/forgot_password_screen.dart
  - lib/features/auth/presentation/screens/reset_password_screen.dart
  - lib/features/auth/presentation/screens/terms_screen.dart
  - lib/features/auth/presentation/screens/privacy_policy_screen.dart
  - lib/features/auth/presentation/screens/home_screen.dart
  - lib/features/home/presentation/screens/home_tab.dart
  - lib/features/home/presentation/screens/scan_tab.dart
  - lib/features/home/presentation/screens/translate_screen.dart
  - lib/features/home/presentation/screens/learn_tab.dart
  - lib/features/home/presentation/screens/butty_chat_screen.dart
  - lib/features/home/presentation/screens/profile_tab.dart
  - lib/features/home/presentation/screens/settings_screen.dart
  - lib/features/home/presentation/screens/translation_history_screen.dart
  - lib/features/home/presentation/screens/learning_progress_screen.dart
  - lib/features/home/presentation/screens/butty_data_screen.dart
  - lib/features/scanner/presentation/screens/scan_history_screen.dart
  - lib/features/learning/presentation/screens/lesson_stage_screen.dart
  - lib/features/learning/presentation/screens/character_gallery_screen.dart
  - lib/features/learning/presentation/screens/quiz_screen.dart
  - lib/features/admin/presentation/screens/stroke_recording_screen.dart
  - lib/features/home/presentation/screens/learn_home_body.dart (skim)
- Skills invoked: ui-ux-pro-max (heuristics-only, schema not loaded in this run)
- Prior audits reconciled: docs/design-improvement-evidence-pack.md, docs/translate-page-audit.md, docs/auth_polish_updates.md, docs/kudlit_design_and_setup.md
