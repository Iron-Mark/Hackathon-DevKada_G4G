# 06 — Accessibility
**Auditor:** general-purpose (a11y lane) · **Skill invoked:** ui-ux-pro-max (a11y topic — heuristics-only) · **Date:** 2026-05-14

## Summary
- P0 count: 3 · P1 count: 6 · P2 count: 5
- Single biggest risk: **Body and hint text fail WCAG AA contrast in multiple core surfaces** (top bar foreground, body-small subtle text, chat/translate input hints), and **no widget in the app honors `MediaQuery.disableAnimations`**, so users with motion-sickness or reduced-motion OS settings still see all looping micro-animations.

## Findings

### Contrast (WCAG AA)

Tokens cited come from `lib/core/design_system/kudlit_colors.dart` and `lib/core/design_system/kudlit_theme.dart`. Ratios computed against pure WCAG formula. AA thresholds: **4.5:1** body / **3:1** large or non-text UI component.

**Light theme — failures (P0/P1):**

| # | Pair | Hex | Ratio | AA verdict | Evidence |
|---|------|-----|-------|------------|----------|
| C1 | App-bar foreground on topbar (P0) | `#E9EEFF` on `#6777B6` | **3.71:1** | FAIL body, pass large | `kudlit_theme.dart:86-87` (appBarTheme.backgroundColor `KudlitColors.topbar` = `blue500`; foregroundColor `blue900`). Affects every AppBar title/subtitle the theme produces. |
| C2 | `bodySmall` subtle text on app background (P0) | `grey300 #6C738E` on `blue900 #E9EEFF` | **4.05:1** | FAIL body (small) | `kudlit_theme.dart:68-72` declares `bodySmall.color = subtleForeground` and uses `fontSize: 12` (not "large" by WCAG). Used in topbar subtitle, `floating_tab_nav.dart:319-323`, `lesson_top_bar.dart:55-56`, history screens. |
| C3 | TextField hint `cs.onSurface.withAlpha(110)` on input fill `#F1F4FF` (P0) | blended `#989DAA` on `#F1F4FF` | **2.47:1** | FAIL | `chat_input_bar.dart:47-50`, `text_input_box.dart:45-48`. The hint text "Ask Butty anything..." / "Type in Filipino..." is essentially invisible to low-vision users. |
| C4 | Floating-nav border `cs.outline = borderSoft #D0D4E2` on pill bg `surfaceContainerHighest #C1CCEB` (P1) | — | **1.08:1** | FAIL 3:1 (non-text) | `floating_tab_nav.dart:131-134`. Border is decorative only, so this is P1, but it visually disappears, hurting affordance for low-contrast viewers. |
| C5 | Aggregated winner label `cs.onSurface.withAlpha(140)` on `surfaceContainerHigh #D3DBF0` (P1) | blended `#5E657B` on `#D3DBF0` | **~3.6:1** | FAIL body | `scan_tab.dart:505-511` ("Settled reading" eyebrow). |

**Light theme — passes (logged for completeness):**
- Primary button `#3F4E87` on `onPrimary #E9EEFF` = **6.84:1** PASS (`kudlit_theme.dart:116-117`).
- Foreground `#0F1725` on background `blue900 #E9EEFF` = **15.51:1** PASS.
- Collapsed nav icon `cs.onSurface` on `surfaceContainerHighest #C1CCEB` = **11.20:1** PASS (`floating_tab_nav.dart:208-212`).
- Expanded inactive nav-pill text `onSurface @ alpha 210` on `#C1CCEB` ≈ **7.46:1** PASS (`floating_tab_nav.dart:284, 319-323`).
- Scan status chip `onSurface @ 230` on blended `#D6DEF2` chip = **10.56:1** PASS (`scan_tab.dart:895-900`).

**Dark theme — failures (P1):**

| # | Pair | Hex | Ratio | Evidence |
|---|------|-----|-------|----------|
| C6 | Dark chat hint `onSurface @ 100` on `surfaceContainerLow #0E1828` | blended `#646C7C` on `#0E1828` | **3.37:1** FAIL body | `chat_input_bar.dart:47-50` (same code path, dark token blend). |
| C7 | Dark `bodySmall` `blue600 #7484C7` on dark surface `#0E1830` | `#7484C7` on `#0E1830` | **4.92:1** PASS (barely) — but `headlineMedium` and `titleLarge` use `blue800 #B3C5FF` (10+ pass). Captioned because subtle muted text in cards near edges drops below 4.5 once alpha-blended onto `surfaceContainerHighest #1E3578`. | `kudlit_theme.dart:230-233`. Verify in `scan_tab.dart` snackbar copy where `cs.onSurface.withAlpha(170)` is used (`scan_tab.dart:170-175`) — blended ratio against dark surface drops below 4.5. |

**Ocean theme on lesson_stage_screen** (`lesson_stage_screen.dart`) uses only `cs.surface` + `LessonTopBar` / `LessonProgressBar` / mode bodies; ocean gradient + bubbles live on `learning_progress_screen.dart` (`_Bubble`, `_OceanWaveClipper` at lines 282–328) and use solid `Container` colors driven by `cs.surfaceContainerLow`. Body copy in `_OverallRingCard` uses default `onSurface` (PASS). Lesson title via `text.titleMedium` PASS. **No lesson-stage-specific contrast failure observed** beyond the C2/C4 token issues above.

### Semantic labels on interactive elements

Grepped `IconButton`, `GestureDetector`, `InkWell` across `lib/features/`. Most navigation tabs and chat send buttons have proper `Semantics` + `Tooltip`. Items with **no** affordance (no `Tooltip`, no enclosing `Semantics`, and the child is a non-text `Container`/`Icon`, so screen readers see nothing):

| Severity | File:line | Element |
|---|---|---|
| P0 | `lib/features/home/presentation/widgets/app_header/profile_button.dart:12` | `GestureDetector` wrapping the profile avatar `Image.asset`. No `Semantics`, no `Tooltip`, no `semanticLabel`. TalkBack reads nothing. |
| P0 | `lib/features/home/presentation/widgets/translate/mic_button.dart:12` | `GestureDetector` over a 38×38 mic icon. No label, no tooltip. Critical because this triggers speech capture. |
| P1 | `lib/features/home/presentation/widgets/learn/lesson_header.dart:25-32` | `GestureDetector` wrapping a bare back-arrow `Icon`. No tooltip/semantics. Use `IconButton` or wrap in `Semantics(button: true, label: 'Back')`. |
| P1 | `lib/features/home/presentation/widgets/translate/translate_mode_switch.dart:81` | `_ModePill` `GestureDetector` (Text/Sketchpad toggle). Text is read, but pill is not announced as a toggle — needs `Semantics(button: true, selected: active, label: '$label mode')`. |
| P1 | `lib/features/home/presentation/widgets/translate/toggle_pill.dart:20` | Same pattern — generic toggle pill missing `selected` state. |
| P1 | `lib/features/home/presentation/widgets/butty_chat/butty_model_mode_selector.dart:135` | `_ModePill` (Cloud/Local AI). Same issue. |
| P1 | `lib/features/home/presentation/widgets/translate/translate_gemma_status_banner.dart:129` | `GestureDetector` "Use local Gemma" toggle. No `Semantics`. |
| P1 | `lib/features/home/presentation/screens/scan_tab.dart:821` | Shutter button `GestureDetector` — **note:** wrapped in `Semantics(label, button: true)` at line 817-820. PASS. (Logged because the line matched the grep.) |
| P1 | `lib/features/home/presentation/widgets/translate/text_input_box.dart:53` | Clear-button `GestureDetector` with bare `Icons.close_rounded`. No tooltip/semantics. |
| P1 | `lib/features/learning/presentation/widgets/butty_help_sheet.dart:432` | `GestureDetector` decorating an icon button inside help sheet. No label. |
| P2 | `lib/features/home/presentation/widgets/learn/pad_button.dart:32` | Carries visible `Text(label)`, so TalkBack reads it — but as static text, not a button. Wrap in `Semantics(button: true)` so the user knows it's actionable. |
| P2 | `lib/features/home/presentation/widgets/learn/draw_button.dart:33` | Same — visible label but not announced as a button. |
| P2 | `lib/features/home/presentation/widgets/lesson_detail_card.dart:53`, `lesson_preview_card.dart:46`, `home_tool_card.dart:47`, `learn_home/butty_talk_card.dart:21` | Card `InkWell`s have no `Semantics` wrapper. Visible text inside is read, but TalkBack does not announce "double-tap to activate" reliably for nested rich content. Add `Semantics(button: true, label: '$title card')`. |
| P2 | `lib/features/home/presentation/widgets/translate/translate_sketchpad_mode_panel.dart:165` | Drawing-pad `GestureDetector` for stroke capture. Needs `Semantics(label: 'Drawing canvas', hint: 'Draw a Baybayin glyph')`. |
| P2 | `lib/features/home/presentation/screens/learning_progress_screen.dart:546, 786` | Lesson-card `GestureDetector`s. Visible text is read, but no `Semantics(button: true)`. |

Good citizens (do not need changes): `floating_tab_nav.dart:55-64, 285-292`, `app_bottom_nav.dart:72`, `scan_tab.dart:764, 817, 1075, 1531`, `chat_input_bar.dart:61`, `learning_route_back.dart:25-33`, `sign_in_form.dart:131-134`, `login_button.dart:12, 36`.

### Touch target sizes

WCAG/Material guideline: **48 dp** (Material) or **44 dp** (Apple HIG). Sampled interactive elements:

| Severity | File:line | Element | Measured | Verdict |
|---|---|---|---|---|
| P1 | `floating_tab_nav.dart:299-301` | Expanded nav-pill | `minHeight: 54` × ~70 wide | PASS |
| P1 | `floating_tab_nav.dart:128-129` | Collapsed pill `_collapsedSize: 64` | 64×64 | PASS |
| P1 | `home_topbar.dart:53-56` | `_MenuButton` 32×32 | **32×32 — FAIL** | The "hamburger" icon is below 44 dp. Wrap in `IconButton(constraints: BoxConstraints.tightFor(44, 44))` or `SizedBox(48, 48)`. |
| P1 | `home_topbar.dart:121-124` | `_AvatarButton` 34×34 | **34×34 — FAIL** | Same issue, and there is no `Semantics`/`Tooltip` (see P0 above). |
| P1 | `home_topbar.dart:88-94` | `_SignInButton` pill, padding 11×5 + 11.5pt text | computed ≈ 26 dp tall — **FAIL** | Wrap in `ConstrainedBox(minHeight: 44)`. |
| P1 | `profile_button.dart:14-16` | Avatar 34×34 | **34×34 — FAIL** | Below 44. |
| P1 | `mic_button.dart:14-17` | Mic button 38×38 | **38×38 — FAIL** | Below 44. Speech capture is a primary action. |
| P1 | `learn/lesson_header.dart:25-32` | Back arrow `GestureDetector` over a bare `Icon(size: 18)` | **≈18×18 — FAIL** | No padding, no `IconButton`. |
| P1 | `translate/text_input_box.dart:53-63` | Clear-X over `Icon(size: 16)` | **≈16×16 — FAIL** | |
| P1 | `translate/translate_mode_switch.dart:85-100` | Mode-toggle pill `minHeight: 34-44` depending on density | compact = 34 — **FAIL** | Compact path is below 44 dp. |
| P1 | `translate/toggle_pill.dart:24-31` | Toggle pill — only padded by 4-6 vertical (no minHeight) | **~24 dp — FAIL** | Used in `translate_screen` row of toggles. |
| P1 | `butty_chat/butty_model_mode_selector.dart:137-141` | Mode pill `minHeight: 36` | **36 — FAIL** | |
| P1 | `translate/translate_gemma_status_banner.dart:131-135` | Status-toggle pill, no `minHeight` | **~26 dp — FAIL** | |
| P2 | `scan_tab.dart:1462-1466` | `_CyclerButton` 48×48 | PASS |
| P2 | `scan_tab.dart:776-786` | `_ControlIcon`, `size: 44+` | PASS |
| PASS | `_ShutterButton` 64–72 dp; `_ActionChip` 48 dp; `lesson_top_bar.dart:32-35` IconButton 44×44; `learning_route_back.dart` IconButton; chat send 44×44; `_RememberMeToggle` `minHeight: 44`; `_AuxiliaryAuthLink` `minimumSize: Size(44, 44)`. |

### Font scale tolerance

The only file in the codebase that reads `MediaQuery.textScalerOf(context)` and reacts is **`app_header.dart:22, 43`** — it shrinks the title and switches to "ultraCompact" when `textScale > 1.35 && compact`. No other widget in the app calls `textScaler` or `textScaleFactor`. **`grep -rn 'textScaleFactor\|textScalerOf' lib/ → 1 hit total`.**

Hard-coded `fontSize:` inside `TextStyle(...)` is used **364 times** across `lib/features/`. Flutter still scales these by the OS text scaler by default, so the *typography* will grow — but the **containers around them are fixed pixel heights**, which causes clipping at 200%. Concrete examples:

| Severity | File:line | Issue |
|---|---|---|
| P0 | `floating_tab_nav.dart:128-129` | `_collapsedSize = 64.0`, but inside is `Icon(size: 22) + Text(fontSize: 10.5)`. At 200% text scale the column grows past 64 and overflows the `FittedBox` only partially (icon is fixed). Acceptable in collapsed; **expanded items (lines 305-326)** use a `FittedBox(fit: BoxFit.scaleDown)` which *shrinks* the label so users with large text get a *smaller* label, defeating their setting. |
| P0 | `home_topbar.dart:16` | `height: 56` is fixed. Title font scales but bar does not — risk of label clipping vertically at 150%+. |
| P1 | `lesson_top_bar.dart:32-35` | `IconButton` is locked to 44×44 via `BoxConstraints.tightFor` and the icon size is fixed `Icon(...)` — fine. But `Row` children include `Expanded Text` with `maxLines: 1, overflow: ellipsis` (`scan_history_screen.dart:50-58`, `translation_history_screen.dart:49-58`) — at large text scale the screen title clips. |
| P1 | `scan_tab.dart:891-900` | `_ScanStatusChip` `minHeight: 48`, but the `Text(fontSize: 11.5, maxLines: 2, overflow: ellipsis)` will clip on large scaling. Consider `Semantics(label: …)` + allow taller chip. |
| P1 | `scan_tab.dart:1083` `_NoticeButton` height: 48 + `Text(fontSize: 12.5)` with `overflow: ellipsis` | At 200% the "Use Gallery"/"Try Again" labels clip. |
| P1 | `floating_tab_nav.dart:307-326` | `FittedBox(fit: BoxFit.scaleDown)` shrinks tab labels at large text scale instead of allowing the pill to grow — actively works against the user. |
| P2 | `home_tool_card.dart`, `lesson_preview_card.dart`, `lesson_detail_card.dart` | Card content uses fixed pixel paddings — text grows but icons/illustrations stay the same size, so layout drifts but does not break catastrophically. |

### Motion / reduced motion

**`grep -rn disableAnimations lib/ → 0 hits.`** Zero animations honor `MediaQuery.disableAnimations`.

Looping / infinite animations that will be the most uncomfortable:

| Severity | File:line | Animation |
|---|---|---|
| P1 | `lib/features/home/presentation/widgets/butty_chat/typing_bubble.dart:65, 107, 155` | Three repeating bobbing/scaling tweens on the typing indicator. |
| P1 | `lib/features/home/presentation/widgets/butty_chat/butty_bubble.dart:125` | Repeating shimmer/wobble. |
| P1 | `lib/features/home/presentation/screens/learning_progress_screen.dart:295` | Ocean bubble `moveY` repeating reverse. |
| P1 | `lib/features/home/presentation/widgets/settings/settings_header.dart:185` | Repeating animation in header. |
| P1 | `lib/features/learning/presentation/widgets/lesson_completion_overlay.dart:236-249` | Three controllers (arc, count, particle) on completion overlay — runs unconditionally. |
| P1 | `lib/features/home/presentation/screens/splash_screen.dart:42` | Splash animation. |
| P2 | `lib/features/learning/presentation/widgets/lesson_progress_bar.dart:26, 41` | `TweenAnimationBuilder` + `AnimatedSwitcher` (non-looping). |
| P2 | `lib/features/learning/presentation/screens/lesson_stage_screen.dart:185` | `AnimatedSwitcher` slide+fade on step change (non-looping). |
| P2 | All `AnimatedContainer` / `AnimatedOpacity` (18 occurrences) | One-shot state transitions; ignorable unless user is in vestibular crisis. |

Fix pattern: introduce a `useReducedMotion(context)` helper that returns `MediaQuery.maybeOf(context)?.disableAnimations ?? false`, and gate every `.animate(onPlay: (c) => c.repeat())` and `AnimationController(...)..repeat()` behind it.

### Focus order on web

| Screen | Wires FocusNodes? | Evidence | Verdict |
|---|---|---|---|
| `sign_in_screen.dart` | Implicit — relies on `TextInputAction.next` → `done` via `EmailField` + `PasswordField` (`sign_in_form.dart:56, 62`). No explicit `FocusNode`. | `sign_in_form.dart:53-64` | **Web: random tab order risk** — Flutter's default web focus traversal follows widget tree order, which is fine for two stacked fields, but the `Remember me` toggle and `Forgot password` links sit in a `Row` with `Expanded+Align`. Tab order on web will be: email → password → remember-me → forgot-password → continue-with-phone → submit. That happens to read correctly, but it is **not enforced** by `FocusTraversalGroup`. P2. |
| `sign_up_screen.dart` | Same pattern — no explicit FocusNodes. | (`grep -n FocusNode lib/features/auth/presentation/screens/sign_up_screen.dart` → 0 hits) | P2 — same as above. |
| `phone_otp_screen.dart` | **Explicit `List<FocusNode>` with auto-advance** between 6 OTP digits. | `phone_otp_screen.dart:37-39, 53, 222, 305, 340` | PASS. |
| `phone_sign_in_screen.dart` | No explicit FocusNodes; single phone field. | Default fine. |
| `translate_screen.dart` → `translate_text_mode_panel.dart` | Has `FocusNode _focusNode = FocusNode()` for the main text area + listener. | `translate_text_mode_panel.dart:288, 295, 330` | PASS (single field). |
| `butty_chat_screen.dart` → `chat_input_bar.dart` | **No `FocusNode` on the chat `TextField`.** | `chat_input_bar.dart:37-58` | P1 — when the user tabs back into the screen after the send button, focus may jump unpredictably. Bigger issue: after pressing Send, the controller is cleared (`butty_chat_screen.dart:64`) but focus is *not* explicitly returned to the input, so keyboard users must click again. Wire a `FocusNode`, expose it through `ChatInputBar`, and `_focusNode.requestFocus()` in `_handleSend()` after clearing. |
| `forgot_password_screen.dart` | (Not inspected — single-field; likely OK.) | — | — |

### Screen-reader empty / error state coverage

| Screen | Empty state has `Semantics`? | Error state has `Semantics`? | Evidence | Verdict |
|---|---|---|---|---|
| `lib/features/scanner/presentation/screens/scan_history_screen.dart` | **No** — `_EmptyState` (lines 109-162) is plain `Center > Container > Column > Icon + Text("No scans yet") + Text(...)`. TalkBack will still read both `Text` widgets, but the icon is decorative and there is no grouping `Semantics(label: …, container: true)`. P2. | **No** — `_ErrorState` (lines 164-198) is a single `Text` with the failure message. Not announced as a `liveRegion`, no `label`. P2. | scan_history_screen.dart:109, 164 | Add `Semantics(container: true, label: 'No scans yet. Scan Baybayin and your saved readings will appear here.')` and `Semantics(liveRegion: true, label: 'Could not load history: $message')`. |
| `lib/features/home/presentation/screens/translation_history_screen.dart` | Same pattern as above. | Same. | translation_history_screen.dart:108, 159 | Same fix. P2. |
| `lib/features/home/presentation/screens/learning_progress_screen.dart` | No dedicated `_EmptyState` — the screen always shows the ring + lesson list. If `lessons.isEmpty`, just renders an empty list (silent for SR). | No `_ErrorState` widget detected via grep. | (no _Empty/_Error class) | P2 — add a "No lessons available" state with `Semantics(liveRegion: true)`. |
| `scan_tab.dart` notice panel | **PASS** — `_ScanNoticePanel` wraps the panel in `Semantics(liveRegion: true, label: '${notice.title}. ${notice.message}')`. | scan_tab.dart:948-950 | Good citizen — copy this pattern to history screens. |

## Top Recommendations (a11y-local, severity-ordered)

| # | Severity | Effort | Recommendation | Evidence |
|---|---|---|---|---|
| 1 | P0 | S | Darken `subtleForeground` from `grey300 #6C738E` to at least `#5A6076` so `bodySmall` 12pt clears 4.5:1 against `blue900` background. | `kudlit_colors.dart:24`, `kudlit_theme.dart:68-72` |
| 2 | P0 | S | Raise TextField hint alpha from `withAlpha(110)` to `withAlpha(160)` (≈4.5:1 on light surface). | `chat_input_bar.dart:47-50`, `text_input_box.dart:45-48` |
| 3 | P0 | S | Either change topbar background `KudlitColors.topbar` to a darker shade (e.g., `blue400 #3F4E87`, which gives 6.8:1 with `blue900` foreground), or swap the foreground to a darker token. | `kudlit_colors.dart:37`, `kudlit_theme.dart:85-91` |
| 4 | P0 | S | Add `Semantics(button: true, label: 'Profile')` / `'Open microphone'` wrappers to `profile_button.dart:12`, `mic_button.dart:12`, and bump those hit targets to ≥44 dp. | `profile_button.dart:12-30`, `mic_button.dart:12-37` |
| 5 | P0 | M | Introduce `useReducedMotion(context)` helper and gate every repeating `AnimationController` / `.animate(onPlay: (c) => c.repeat())` behind it. Start with `typing_bubble.dart`, `butty_bubble.dart`, `lesson_completion_overlay.dart`, `learning_progress_screen.dart:295`, `settings_header.dart:185`. | sections above |
| 6 | P1 | S | Enlarge `_MenuButton`, `_AvatarButton`, `_SignInButton` in `home_topbar.dart` to 44×44 minimum (wrap in `SizedBox` or use `IconButton`). | `home_topbar.dart:47-113` |
| 7 | P1 | S | Add `Semantics(button: true, selected: active, label: ...)` to every `_ModePill`/toggle pill (translate, sketchpad/text, AI cloud/local, status banner). | files cited in §"Semantic labels" |
| 8 | P1 | S | Replace `FittedBox(fit: BoxFit.scaleDown)` in `floating_tab_nav.dart:307-326` with `FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.center)` only when `MediaQuery.textScalerOf(context).scale(1) ≤ 1.15`; otherwise let the pill grow vertically. | `floating_tab_nav.dart:307` |
| 9 | P1 | S | Wire a `FocusNode` into `ChatInputBar` and re-request focus after send (`_handleSend`). | `chat_input_bar.dart:37`, `butty_chat_screen.dart:58-66` |
| 10 | P1 | S | Add `Semantics(button: true, label: 'Back')` and bump tap area on the bare back-arrow `Icon` in `learn/lesson_header.dart:25-32`. | `learn/lesson_header.dart:25` |
| 11 | P2 | S | Wrap history `_EmptyState` / `_ErrorState` in `Semantics(liveRegion: true, container: true, label: ...)`. | `scan_history_screen.dart:109, 164`, `translation_history_screen.dart:108, 159` |
| 12 | P2 | M | Add `Semantics(button: true, label: '<title> card')` to large card `InkWell`s in `home_tool_card.dart`, `lesson_preview_card.dart`, `lesson_detail_card.dart`, `learn_home/butty_talk_card.dart`. | files cited |
| 13 | P2 | S | Wrap `sign_in_form.dart` and `sign_up_form.dart` body in `FocusTraversalGroup(policy: OrderedTraversalPolicy())` and assign `FocusTraversalOrder` to each field for explicit web tab order. | `sign_in_form.dart:46-113` |
| 14 | P2 | M | Audit every fixed `height:`/`SizedBox.fromHeight` that contains text and replace with `ConstrainedBox(minHeight: ...)` or `IntrinsicHeight`, so 200% text scale doesn't clip. Start with `home_topbar.dart:16`, `scan_tab.dart:1083, 891`. | sections above |

## Methods
- Files read:
  - `lib/core/design_system/kudlit_colors.dart`, `lib/core/design_system/kudlit_theme.dart`
  - `lib/features/home/presentation/widgets/floating_tab_nav.dart`, `home_topbar.dart`, `home_tool_card.dart`, `lesson_detail_card.dart`, `lesson_preview_card.dart`, `app_bottom_nav.dart`
  - `lib/features/home/presentation/widgets/app_header/app_header.dart`, `profile_button.dart`, `login_button.dart`
  - `lib/features/home/presentation/widgets/butty_chat/chat_input_bar.dart`, `butty_model_mode_selector.dart`
  - `lib/features/home/presentation/widgets/translate/mic_button.dart`, `translate_mode_switch.dart`, `toggle_pill.dart`, `text_input_box.dart`, `translate_sketchpad_mode_panel.dart`, `translate_gemma_status_banner.dart`
  - `lib/features/home/presentation/widgets/learn/pad_button.dart`, `draw_button.dart`, `lesson_header.dart`
  - `lib/features/home/presentation/widgets/learn_home/butty_talk_card.dart`
  - `lib/features/home/presentation/screens/butty_chat_screen.dart`, `scan_tab.dart`, `translation_history_screen.dart`, `learning_progress_screen.dart`
  - `lib/features/scanner/presentation/screens/scan_history_screen.dart`
  - `lib/features/learning/presentation/screens/lesson_stage_screen.dart`
  - `lib/features/learning/presentation/widgets/lesson_top_bar.dart`, `learning_route_back.dart`, `lesson_completion_overlay.dart`
  - `lib/features/auth/presentation/screens/sign_in_screen.dart`, `phone_otp_screen.dart`
  - `lib/features/auth/presentation/widgets/sign_in_form.dart`
- Grep sweeps: `IconButton`, `GestureDetector`, `InkWell`, `AnimationController`, `AnimatedSwitcher`, `TweenAnimationBuilder`, `disableAnimations`, `textScaleFactor|textScalerOf`, `FocusNode`, `fontSize:`.
- Contrast: computed WCAG 2.1 ratios with the standard sRGB→linear luminance formula for each token pair, including alpha-blended foregrounds where the codebase uses `withAlpha(...)`.
- Prior audits reconciled: `docs/design-improvement-evidence-pack.md`, `docs/kudlit_design_and_setup.md` (referenced for visual-system intent; neither covers contrast, semantics, motion, or focus order in this depth, so this lane stands as the canonical a11y record).
