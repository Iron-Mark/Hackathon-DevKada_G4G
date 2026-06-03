# 07 — Navigation, IA & Visual Language
**Auditor:** general-purpose (nav/IA lane) · **Skill invoked:** none · **Date:** 2026-05-14

## Summary
- P0 count: 2 · P1 count: 5 · P2 count: 4
- Single biggest risk: the four primary tabs (`AppTab` in `floating_tab_nav.dart:10`) and the four bottom-nav tabs (`AppBottomNav._defs` in `app_bottom_nav.dart:15-20`) describe two *different* information architectures. Only `FloatingTabNav` is wired into `HomeScreen` (`home_screen.dart:138`); `AppBottomNav`, `HomeTab` and `ProfileTab` are orphaned dead code from a previous IA. The app ships with a half-finished IA refactor that no audit has flagged.

## Route Map

All routes are declared in `lib/app/router/app_router.dart`. Paths come from `lib/app/constants.dart:6-23`.

| Path | Destination | Guard | Notes |
|---|---|---|---|
| `/` (routeSplash) | `SplashScreen` | open | Redirect-driven; `app_router.dart:55-68`. Holds while `authState`/`prefsState` load; routes to model-setup, login, or home. |
| `/model-setup` | `ModelSetupScreen` | open | `app_router.dart:71-86`. Returns to splash if loading, to home/login once `hasDownloadedModels`, `hasSeenModelPrompt`, or `sessionSkipped` is true. |
| `/login` | `LoginScreen` | guest-only | Authenticated users are bounced back to `/home` (`app_router.dart:104`). |
| `/sign-up` | `SignUpScreen` | guest-only | Same auth-bounce. |
| `/forgot-password` | `ForgotPasswordScreen` | guest-only | Same. |
| `/home` | `HomeScreen` | open (guest OK) | Listed in `isGuestAccessibleRoute` (`app_router.dart:33`). Hosts the 4-tab `FloatingTabNav`. |
| `/auth/reset` | `LoginScreen` (alias) | guest-only | Same screen as `/login` — duplicate route to absorb password-reset deep links. |
| `/settings` | `SettingsScreen` | open (guest OK) | `app_router.dart:34`. `SettingsList` (`settings_list.dart:38-83`) shows different sections by `user == null`. |
| `/learn/lesson/:id` | `LessonStageScreen` | open (guest OK) | Allow-listed via `matchedLocation.startsWith('${routeLesson}/')` (`app_router.dart:38`). |
| `/terms` | `TermsScreen` | open | Listed as `isOnAuthRoute` (`app_router.dart:96`), which means it bypasses the auth-required check but is *not* on the guest-allow list — odd routing logic, see findings. |
| `/privacy-policy` | `PrivacyPolicyScreen` | open | Same: classified as an "auth route" although it is also reachable when signed in. |
| `/admin/stroke-recorder` | `StrokeRecordingScreen` | **auth-required, but no role check** | Any signed-in user reaches this admin tool. No `isAdmin` gate in router or screen. **P0.** |
| `/learn/gallery` | `CharacterGalleryScreen` | open (guest OK) | `app_router.dart:35`. |
| `/learn/quiz` | `QuizScreen` | open (guest OK) | `app_router.dart:36`. |
| `/scan-history` | `ScanHistoryScreen` | auth-required | Not in guest-allow list; redirects to `/login`. |
| `/translation-history` | `TranslationHistoryScreen` | auth-required | Same. |
| `/learning-progress` | `LearningProgressScreen` | auth-required | Same — yet `learn` itself is open. Inconsistent (see findings). |
| `/butty-data` | `ButtyDataScreen` | auth-required | Same. |

Guest-allow list (`app_router.dart:32-39`): `/home`, `/settings`, `/learn/gallery`, `/learn/quiz`, `/learn/lesson`, `/learn/lesson/<id>`.

### Routing red flags
1. `/admin/stroke-recorder` is exposed to every authenticated user (`app_router.dart:163-167`); the entry-point gate is only the visibility check in `AdminSection` (`settings/admin_section.dart:63`) and there is no role check. The route should reject non-admins at the router layer. **P0.**
2. `routeLesson = '/learn/lesson'` (`constants.dart:14`) is declared as a *path* but the router only registers `/learn/lesson/:id` (`app_router.dart:149`). Hitting the bare `/learn/lesson` URL (which `isGuestAccessibleRoute` explicitly allows on line 37) returns a no-match 404. The constant is misleading and the allow-list entry is dead.
3. `/terms` and `/privacy-policy` are treated as `isOnAuthRoute` (`app_router.dart:96-97`). That short-circuits the `isGuestAccessibleRoute` check, so they work — but classifying them as auth routes makes the intent unclear and means signed-in users hitting `/terms` *don't* get bounced to home like real auth routes do (line 104 only fires for the routes already in `isOnAuthRoute` and authenticated). The semantic of "auth route" is overloaded.

## Findings

### Dual navigation (floating tab nav vs app bottom nav)
- `FloatingTabNav` (`lib/features/home/presentation/widgets/floating_tab_nav.dart:10-15`) defines `AppTab { scan, translate, learn, butty }` — a collapsible glass pill anchored bottom-right and rendered as the only nav inside `HomeScreen._HomeBody` (`home_screen.dart:135-141`).
- `AppBottomNav` (`lib/features/home/presentation/widgets/app_bottom_nav.dart:5-46`) defines a totally different IA: `Home / Scan / Learn / Profile` (`app_bottom_nav.dart:15-20`).
- **`AppBottomNav` is never imported or rendered anywhere** — `grep -rn AppBottomNav lib` only matches its own declaration. Same for `HomeTab` (`home_tab.dart:11`) and `ProfileTab` (`profile_tab.dart:11`), the screens it would have hosted; both are defined but not wired into the router or `_HomeBody`. **P1 — dead-code fragmentation.**
- This is not intentional dual nav. It is a stalled IA refactor: an earlier design used a static bottom bar with Home/Profile destinations; the current design replaced it with a floating action-style pill that omits Home and Profile and adds Butty. The artifacts of the previous IA still live in the tree.
- Symptom: the Translate tab uses `Icons.g_translate` in `FloatingTabNav` (`floating_tab_nav.dart:201, 240`) but the bottom-nav design called the tab "Scan"; a developer reading the two files cannot tell which is canon. New contributors may add features against the wrong nav.

### Guest-mode boundary correctness
Walk-through of a non-signed-in user:
1. Splash → since `prefs.hasDownloadedModels == false` on a fresh install, redirect to `/model-setup` (`app_router.dart:60-64`); user can skip; router lands them on `/login`.
2. From `/login`, the user can also reach `/home` because `routeHome` is on the guest-allow list (`app_router.dart:33`). The `LoginButton` is shown in `AppHeader` (`app_header.dart:151-155`).
3. On `/home`, all four tabs in `FloatingTabNav` are tappable (no auth check inside `_HomeBody`):
   - **Scan tab** — guest can scan, view detections, copy, share. The "Save reading" action calls `scanHistoryNotifierProvider.addResult()` (`scan_tab.dart:1243-1250`); inside that notifier (`scan_history_provider.dart:79-93`) a missing `userId` is silently treated as "guest" and Supabase sync is skipped. SQLite save still succeeds. **OK, no error.**
   - **Translate tab** — guest can use Online Gemma (`translate_screen.dart` invokes `translate_text_controller` with `mode = cloud` by default). Translation history save runs the same null-userId guard in `translation_history_provider.dart`. **OK.**
   - **Learn tab** — `LearnTab` (`learn_tab.dart:1-33`) pushes `/learn/lesson/:id`, `/learn/gallery`, `/learn/quiz`; all three are guest-allowed. **OK.**
   - **Butty tab** — `ButtyChatScreen` has *no* user-id check in `butty_chat_controller.dart` (grep returns zero matches). Guest can chat. Memory writes go to local SQLite. **OK at runtime, but Butty's "Open Butty Memory" links to `/butty-data` (auth-required) — that path is reachable from Settings (`activity_section.dart:79`), which is open to guests; tapping it as a guest causes a router redirect to `/login`. P2 — silent dead-end for guests.**
4. `AppHeader` profile button (`app_header.dart:157`) only renders `ProfileButton` for authenticated users; guests see `LoginButton`. **Correct.**
5. **However** the `/settings` screen is open to guests. Once there, the `ActivitySection` (`activity_section.dart:53-79`) lists "Learning Progress", "Scan History", "Translation History", "Butty Memory" — all four of those routes are auth-required (router redirects to `/login`). A guest tapping any of them is bounced to login without any explanation. **P1 — visible tile, hidden auth wall.**
6. `SettingsHeader` (`widgets/settings/settings_header.dart`) does a hard `context.go(routeHome)` on close (line 162). For guests this is fine; for an authenticated user who landed on `/settings` from a tab inside `/home`, this collapses the back-stack to a hard re-mount of `HomeScreen`. **P2.**

### Back-stack & deep-link behavior
- The 4 in-tab screens are siblings inside a `PageView` in `_HomeBody` (`home_screen.dart:125-134`). Switching tabs does *not* push a route — the URL stays at `/home`. The `?tab=learn` query param is *consumed* once on `didChangeDependencies` (`home_screen.dart:38-54`) but never *written back* when the user switches tabs in-app. So:
  - Deep-link `/home?tab=butty` works on cold start.
  - In-app tab switches do not update the URL. If the user backgrounds the app or shares the URL, the tab state is lost. **P2 — deep-link is one-way.**
- Lesson → back: `LessonStageScreen` is pushed via `context.push` (`learn_tab.dart:14`), so OS back / `LearnRouteBackButton` pops to `/home` and the `_HomeBody` keeps the `learn` tab selected because the `PageController` state survives. **Correct.**
- `learning_route_back.dart:6-16` has the right fallback: if `Navigator.canPop()` is false (cold-launched directly into the lesson via deep link), it `context.go('/home?tab=learn')`. Good.
- Next-lesson uses `pushReplacement` (`lesson_stage_screen.dart:87`) — replaces the current lesson on the stack so a chain of lessons collapses to a single back-pop. **Correct.**
- `context.go` vs `context.push` inconsistencies:
  - `settings_header.dart:162` uses `context.go(routeHome)` (resets stack). For a user who arrived at `/settings` via `context.push` from `ProfileButton` (`profile_button.dart:13`), the natural back action would be `Navigator.pop`. Using `go` instead loses any nested route state above `/home`. **P2.**
  - `create_account_button.dart:19` uses `context.go(routeSignUp)`. From a settings push, this also wipes the stack. Minor.
  - `app_header.dart:154` uses `context.go(routeLogin)` for the header's Login button when guest. Correct because we want to *replace* the current navigation, not stack a login on top of home.
- `ProfileButton.onTap` → `context.push(routeSettings)` (`profile_button.dart:13`) stacks settings on top of home. Back works. Good.

### Visual language consistency across tabs
Comparing the five primary surfaces:

| Surface | Surface color source | Header source | Accent color | Custom fonts | Decorative motion |
|---|---|---|---|---|---|
| Scan (`scan_tab.dart`) | `cs.surfaceContainerHigh` and ad-hoc `Color(0x40000000)` shadows (e.g. `scan_tab.dart:489, 698, 830, 852, 883, 959, 1269`) | None (overlay UI) | `cs.primary`, plus hard-coded `Color(0xFF0E1425)` (`scan_tab.dart:830`) and `Color(0x4D7AAAFF)` (`scan_tab.dart:852`) for the shutter | Baybayin inline `fontFamily: 'Baybayin Simple TAWBID'` (`scan_tab.dart:1350`) instead of `KudlitTheme.baybayinDisplay` (`kudlit_theme.dart:327`) | Camera flash, status chip fade |
| Translate (`translate_screen.dart` + `widgets/translate/`) | `cs.surface` (`translate_screen.dart:118`) | `TranslateHeader` (toggle bar) | `cs.primary` and one-off mic glow `Color(0x66FF5040)` (`mic_button.dart:26`) and the export theme palette `Space/Violet/Teal/Ember/Sakura/Parchment` (`export_sheet.dart:31-36`) — six hard-coded colorways with no design-system tie-in | Baybayin inline (`filled_output.dart:39`, `translate_sketchpad_mode_panel.dart:184`, `export_sheet.dart:337`) | None notable |
| Learn — `LearnTab` → `LearnHomeBody` | `cs.surface` (`learn_tab.dart:23`) | None on tab itself | `cs.primary`, `cs.primaryContainer`, `cs.tertiaryContainer` for streak | Baybayin inline in `glyph_item.dart:23` | None — pure list. **Despite MEMORY.md describing a "Philippine Sea ocean theme with glassmorphism cards, drifting bubbles, wave animations" — that theme is not in `LearnHomeBody` or `LearnTab`.** Ocean theme is only on `LearningProgressScreen` (which is *behind an auth wall*) and `SettingsHeader`. **P1 — documented design system not implemented in the surface the user actually sees.** |
| Learn → Learning Progress (`learning_progress_screen.dart`) | `_oceanDeep / _oceanTeal / _oceanCyan / _oceanFoam` (lines 108-111), all hex literals not in `KudlitColors` | Custom `SliverAppBar` with `_OceanWaveClipper` and `_Bubble`s (`learning_progress_screen.dart:159, 173-192, 302`) | The ocean palette **plus** success `Color(0xFF46B986)` and warning `Color(0xFFF5A623)` hard-coded (`learning_progress_screen.dart:616, 632, 660, 674, 722, 734, 752, 754`) — none in the token file | None | Wave clipper, drifting bubbles |
| Butty (`butty_chat_screen.dart` + `widgets/butty_chat/`) | `cs.surface` (`butty_chat_screen.dart:119`) | `ButtyHeader` with hard-coded `Color(0xFF46B986)` for the online dot (`butty_header.dart:81`, `online_dot.dart:13`) — not from `KudlitColors.success400` (`kudlit_colors.dart:27`) which is the *exact same value* | `cs.primary` and `cs.surfaceContainer` mostly. Cleanest tokenization of the five surfaces. | Baybayin inline (`baybayin_chat_renderer.dart:161`), `monospace` for pre/code blocks (`baybayin_chat_renderer.dart:82`) | Typing indicator |
| Profile (orphan `ProfileTab` — see findings) / Settings | `Theme.of(context).colorScheme.surface` (`profile_tab.dart:18`); Settings uses its own ocean palette (`settings_header.dart:16-19`) re-declared as private constants | `SettingsHeader` shares ocean palette with `learning_progress_screen.dart` — duplicated hex literals across files | `_deep/_teal/_cyan/_foam` ocean palette | None | Same ocean motif |

**Observations:**
1. The ocean palette `0xFF0A4D68 / 0xFF088395 / 0xFF05BFDB / 0xFFBBE1FA` is declared three times: `learning_progress_screen.dart:108-111`, `settings_header.dart:16-19`, and `profile_hero_avatar.dart:19-20`. Identical hex values, three different `static const` declarations. None of them are in `KudlitColors`. **P1.**
2. The success green `0xFF46B986` is declared in `KudlitColors.success400` (`kudlit_colors.dart:27`) but inline-duplicated in `butty_header.dart:81`, `online_dot.dart:13`, `feedback_card.dart:12`, and seven sites in `learning_progress_screen.dart`. **P1 — token exists, it just isn't used.**
3. The amber/warning `Color(0xFFF5A623)` (`learning_progress_screen.dart:616, 674, 722`) does not exist in the token file at all — the closest token is `KudlitColors.yellow200 = 0xFFFFD8B8`, which is a different hue. The Learning Progress screen invented its own warning color. **P2.**
4. The Baybayin font is declared via `KudlitTheme.baybayinDisplay()` (`kudlit_theme.dart:327-332`) but every consumer reaches past the helper and writes `fontFamily: 'Baybayin Simple TAWBID'` directly (22 sites — see grep output in Methods). If the font asset name ever changes, those 22 sites all break. **P1.**
5. `KudlitColors.background` is `blue900 = 0xFFE9EEFF` (`kudlit_colors.dart:6, 32`) — a *light blue*. The theme then sets `scaffoldBackgroundColor: KudlitColors.background` (`kudlit_theme.dart:83`) so the app's default surface is a faint blue. But every tab body forces `cs.surface` (paper white) via `DecoratedBox`/`ColoredBox` (e.g. `learn_tab.dart:23`, `butty_chat_screen.dart:119`, `translate_screen.dart:118`). The scaffold background is never visible; the token is effectively dead. **P2.**
6. The four tabs are stylistically incoherent: Scan is a dark/photographic surface with translucent chrome; Translate is a paper card with workspace toggle; Learn is a flat list; Butty is a chat surface with header pill. Only Settings/Learning Progress carry the ocean motif. The "two-app feel" critique is accurate — the app does feel like four prototypes glued together via the floating pill. **P1.**

### Token vs ad-hoc styling divergences
Sorted by impact (full list, not exhaustive):

| Site | Ad-hoc value | Should be |
|---|---|---|
| `settings_header.dart:16-19` | private `_deep/_teal/_cyan/_foam` constants | `KudlitColors.ocean*` (new tokens) |
| `learning_progress_screen.dart:108-111` | same private ocean constants, duplicated | same |
| `widgets/settings/profile_hero_avatar.dart:19-20, 57` | private ocean constants + `Color(0xFFE6F4FA)` | same |
| `learning_progress_screen.dart:433, 632, 660, 752, 754` | `Color(0xFF46B986)` literal | `KudlitColors.success400` |
| `butty_header.dart:81`, `online_dot.dart:13`, `feedback_card.dart:12` | same green literal | `KudlitColors.success400` |
| `learning_progress_screen.dart:616, 674, 722` | `Color(0xFFF5A623)` literal | new `KudlitColors.warning400` token |
| `scan_tab.dart:830, 852` | `Color(0xFF0E1425)`, `Color(0x4D7AAAFF)` | `cs.scrim`, `cs.primary.withAlpha(0x4D)` |
| `welcome_banner.dart:27, 44, 102, 125`, `home_topbar.dart:26`, `home_tool_card.dart:40, 112`, `lesson_preview_card.dart:40`, `lesson_detail_card.dart:46, 110, 163` | ad-hoc shadow / surface ARGB literals | `cs.shadow` (defined in `kudlit_theme.dart:29`) and `cs.onSurface.withAlpha(...)` |
| `widgets/translate/export_sheet.dart:31-36` | six hard-coded gradient palettes | dedicated `ExportPaletteTokens` |
| `widgets/translate/mic_button.dart:26` | `Color(0x66FF5040)` mic glow | `cs.error.withAlpha(...)` |
| 22 sites listed in Methods | `fontFamily: 'Baybayin Simple TAWBID'` | `KudlitTheme.baybayinDisplay(context)` |
| `widgets/home/home_topbar.dart`, `widgets/home/home_tool_card.dart`, `welcome_banner.dart`, `home_tab.dart` | entire `HomeTab` IA | **delete** (dead code from the earlier 5-tab IA — see dual-nav finding) |

## Top Recommendations (nav/IA-local, severity-ordered)

| # | Severity | Effort | Recommendation | Evidence |
|---|---|---|---|---|
| 1 | P0 | S | Gate `/admin/stroke-recorder` at the router with a role check (`is_admin` flag from `profile_summary`), not only at the Settings tile. Today any authenticated user who knows the URL reaches it. | `app_router.dart:163-167`; entry-tile-only gate at `widgets/settings/admin_section.dart:63` |
| 2 | P0 | S | Delete `AppBottomNav` (`app_bottom_nav.dart`), `HomeTab` (`home_tab.dart`), `ProfileTab` (`profile_tab.dart`), `WelcomeBanner`, `HomeTopbar`, `HomeToolCard`, `LessonPreviewCard` if confirmed orphaned. Either delete or wire the bottom-nav IA back in — but the current state, where two contradictory 4-tab navs co-exist in source, will mislead every new contributor. | `grep -rn AppBottomNav lib` returns only its own declaration; same for `HomeTab`, `ProfileTab` |
| 3 | P1 | M | Add `KudlitColors.oceanDeep/oceanTeal/oceanCyan/oceanFoam`, `KudlitColors.warning400`, and ensure `success400` is used everywhere green is rendered. Remove the three duplicate private ocean palettes. | `settings_header.dart:16-19`, `learning_progress_screen.dart:108-111`, `profile_hero_avatar.dart:19-20`; success-green inline sites listed above |
| 4 | P1 | S | Replace every `fontFamily: 'Baybayin Simple TAWBID'` literal with `KudlitTheme.baybayinDisplay(context)` (or a new `baybayinInline(context, size: ...)` helper). 22 call sites today. | grep listed in Methods |
| 5 | P1 | M | Either bring the ocean/glassmorphism theme to the Learn tab body (matching MEMORY.md's documented design) or update MEMORY.md and the auditor docs to reflect that the ocean theme is scoped to Learning Progress + Settings. Today the user-facing Learn tab does not match its design spec. | `learn_home_body.dart:138-179` is a flat list; ocean theme lives only in `learning_progress_screen.dart` (behind auth) and `settings_header.dart` |
| 6 | P1 | S | Either hide the "Learning Progress / Scan History / Translation History / Butty Memory" tiles in `ActivitySection` for guests, or change the router so those routes are guest-readable (showing the local SQLite slice). Today a guest taps a visible tile and is bounced to `/login` with no copy explaining why. | `widgets/settings/activity_section.dart:53-79`; router redirect at `app_router.dart:99-103` |
| 7 | P1 | M | Decide whether `/terms` and `/privacy-policy` are auth routes or open routes and pick one. Today they live in `isOnAuthRoute` (`app_router.dart:96-97`) but are never gated. Move them to a separate "publicRoutes" predicate to clarify intent. | `app_router.dart:91-104` |
| 8 | P2 | S | Persist tab selection back to the URL: write `tab=scan/translate/learn/butty` on `_onTabSelected` (`home_screen.dart:56-64`) via `context.replace`. Today `?tab=` is read-only. | `home_screen.dart:38-54` reads but never writes |
| 9 | P2 | S | Drop the dead `routeLesson = '/learn/lesson'` entry from `isGuestAccessibleRoute` (`app_router.dart:37`). The path is never registered as a no-`:id` route. | `app_router.dart:149` only registers `${routeLesson}/:id` |
| 10 | P2 | S | Replace the `context.go(routeHome)` in `settings_header.dart:162` with `context.pop()` (with a `canPop` guard fallback to `go`). Today closing settings resets the home stack. | `widgets/settings/settings_header.dart:162` |
| 11 | P2 | S | Remove `Color(0xFF0E1425)`/`Color(0x4D7AAAFF)` literals from `scan_tab.dart:830, 852`; use `cs.scrim` and `cs.primary.withAlpha(...)`. | `scan_tab.dart:830, 852` |

## Methods
- Files read:
  - `lib/app/router/app_router.dart`
  - `lib/app/constants.dart`
  - `lib/features/auth/presentation/screens/home_screen.dart`
  - `lib/features/home/presentation/widgets/floating_tab_nav.dart`
  - `lib/features/home/presentation/widgets/app_bottom_nav.dart`
  - `lib/features/home/presentation/screens/scan_tab.dart`
  - `lib/features/home/presentation/screens/translate_screen.dart`
  - `lib/features/home/presentation/screens/learn_tab.dart`
  - `lib/features/home/presentation/screens/learn_home_body.dart`
  - `lib/features/home/presentation/screens/butty_chat_screen.dart`
  - `lib/features/home/presentation/screens/profile_tab.dart`
  - `lib/features/home/presentation/screens/settings_screen.dart`
  - `lib/features/home/presentation/screens/home_tab.dart`
  - `lib/features/home/presentation/screens/learning_progress_screen.dart` (selected sections via grep)
  - `lib/features/home/presentation/widgets/settings/settings_list.dart`
  - `lib/features/home/presentation/widgets/settings/settings_header.dart` (selected lines)
  - `lib/features/home/presentation/widgets/app_header/app_header.dart`
  - `lib/features/home/presentation/widgets/app_header/profile_button.dart`
  - `lib/features/scanner/presentation/providers/scan_history_provider.dart`
  - `lib/features/learning/presentation/widgets/learning_route_back.dart`
  - `lib/features/learning/presentation/screens/lesson_stage_screen.dart`
  - `lib/core/design_system/kudlit_colors.dart`
  - `lib/core/design_system/kudlit_theme.dart`
- Targeted greps:
  - `grep -rn "FloatingTabNav\|AppBottomNav" lib --include="*.dart"`
  - `grep -rn "ProfileTab\b\|HomeTab\b" lib --include="*.dart"`
  - `grep -rn "Color(0xFF\|Color(0x" lib/features/home/presentation --include="*.dart"`
  - `grep -rn "fontFamily:" lib --include="*.dart"` → 22 sites for `Baybayin Simple TAWBID`, 3 for `monospace`
  - `grep -rn "context\.go\|context\.push" lib/features/home/presentation --include="*.dart"`
  - `grep -rn "isGuestAccessibleRoute" lib --include="*.dart"`
  - `grep -rn "tab=" lib --include="*.dart"`
- Prior audits reconciled:
  - `docs/kudlit_design_and_setup.md` — does not mention the dual-nav, the orphan `HomeTab`/`ProfileTab`, the admin role gap, or the duplicated ocean palette. All four findings here are new.
  - `docs/design-improvement-evidence-pack.md` — does not mention `FloatingTabNav` vs `AppBottomNav` fragmentation.
  - `docs/jam_the_dev_review_notes.md` and `docs/jam-updates.md` — no `FloatingTabNav`, `AppBottomNav`, "two nav", "dual nav" matches. The earlier review cycle did not catch the IA fragmentation.
  - `MEMORY.md` (auto-memory) entry `project_learn_ocean_theme` describes an ocean theme on the Learn page that does not exist on the current `LearnTab`/`LearnHomeBody` surfaces — flagged as P1 #5 above.
