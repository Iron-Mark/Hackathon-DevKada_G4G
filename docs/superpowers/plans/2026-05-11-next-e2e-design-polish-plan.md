# Next E2E Design Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run the next end-to-end polish pass for `design-improvement`, focused on native-feeling mobile screens, complete empty/loading/error states, and review-ready proof.

**Architecture:** Keep work inside Flutter presentation widgets, presentation providers only when needed for UI state, widget tests, QA scripts, and docs. Reuse the Kudlit design system, existing app chrome, and current feature contracts; do not touch backend, Supabase schema, model pipelines, migrations, or secrets.

**Tech Stack:** Flutter, Dart, Riverpod, go_router, Material 3 color tokens, Flutter widget tests, repo PowerShell QA scripts, Playwright Chromium screenshots, local static preview at `http://127.0.0.1:5174`.

---

## Scope Guard

- Stay on `design-improvement`.
- Do not merge, rebase, or switch branches.
- Do not change backend, auth business logic, Supabase schema, migrations, model download/inference contracts, or scanner inference behavior.
- Preserve current product wording unless the wording causes truncation, jargon, or unclear button hierarchy.
- Prefer mobile-first QA at `320x593`, `360x740`, `390x844`, `430x932`, and short landscape.
- Commit and push only when explicitly authorized by the checkpoint commit policy.

## File Map

- Modify: `lib/features/home/presentation/widgets/settings/ai_models_section.dart`
- Modify: `lib/features/home/presentation/widgets/settings/llm_download_tile.dart`
- Modify: `lib/features/home/presentation/widgets/settings/vision_download_tile.dart`
- Modify: `lib/features/home/presentation/widgets/translate/translate_text_mode_panel.dart`
- Modify: `lib/features/home/presentation/widgets/translate/empty_output.dart`
- Modify: `lib/features/home/presentation/widgets/butty_chat/butty_chat_view.dart`
- Modify: `lib/features/home/presentation/widgets/butty_chat/suggested_questions_row.dart`
- Modify: `lib/features/home/presentation/widgets/learn_home/lesson_card.dart`
- Modify: `lib/features/learning/presentation/widgets/lesson_detail_content.dart`
- Modify: `lib/features/scanner/presentation/widgets/scanner_camera_status.dart`
- Modify: `lib/features/scanner/presentation/widgets/scanner_result_panel.dart`
- Modify: `docs/design-improvement-evidence-pack.md`
- Test: `test/features/home/presentation/widgets/ai_models_section_test.dart`
- Test: `test/features/home/presentation/widgets/translate_density_test.dart`
- Test: `test/features/home/presentation/widgets/mobile_tap_targets_test.dart`
- Test: `test/features/learning/presentation/widgets/learning_density_test.dart`
- Test: `test/features/scanner/presentation/widgets/scanner_camera_status_test.dart`
- Test: `test/features/scanner/presentation/widgets/scanner_result_panel_polish_test.dart`
- Evidence: `test-results/ui-verify/`
- Evidence: `qa-artifact/prod-smoke-next-e2e-polish/`
- Evidence: `qa-artifact/scan-layout-strict-overlap-next-e2e-polish/`

## Design Quality Bar

- No horizontal overflow, clipped text, or floating-tab overlap in target viewports.
- Minimum 44px tap target for visible actions.
- Primary action is visually dominant; secondary actions are lower emphasis.
- Loading and progress states must reserve stable space and avoid layout shift.
- Empty states should tell the user what to do next in one short sentence.
- Error states should be human-readable and not expose raw exception text.
- Use `ColorScheme` and design-system spacing instead of raw colors or ad hoc gaps.
- Screens should feel like an app surface, not a marketing page.

---

### Task 1: Baseline Audit And Screenshot Inventory

**Files:**
- Read: `docs/design-improvement-evidence-pack.md`
- Read: `Kudlit Design System/README.md`
- Read: `Kudlit Design System/colors_and_type.css`
- Evidence: `test-results/ui-verify/`

- [ ] **Step 1: Confirm branch and clean starting point**

Run:

```powershell
git status --short --branch
git fetch origin main origin design-improvement
git rev-list --left-right --count origin/main...HEAD
```

Expected:

```text
Branch is design-improvement
No branch switch occurs
Ahead/behind count is recorded before editing
```

- [ ] **Step 2: Inventory current screenshots**

Run:

```powershell
Get-ChildItem test-results\ui-verify -Filter *.png | Sort-Object Name | Select-Object -ExpandProperty Name
Get-ChildItem qa-artifact -Directory | Sort-Object Name | Select-Object -ExpandProperty Name
```

Expected:

```text
Existing Settings, Translate, Scan, Learn, and Butty screenshots are listed
Missing surfaces are written into the evidence pack before implementation starts
```

- [ ] **Step 3: Capture baseline mobile surfaces**

Run:

```powershell
npx playwright screenshot --browser=chromium --viewport-size=320,593 --wait-for-timeout=10000 http://127.0.0.1:5174/#/settings test-results/ui-verify/baseline-settings-320.png
npx playwright screenshot --browser=chromium --viewport-size=390,844 --wait-for-timeout=10000 http://127.0.0.1:5174/#/home?tab=translate test-results/ui-verify/baseline-translate-390.png
npx playwright screenshot --browser=chromium --viewport-size=390,844 --wait-for-timeout=10000 http://127.0.0.1:5174/#/home?tab=learn test-results/ui-verify/baseline-learn-390.png
npx playwright screenshot --browser=chromium --viewport-size=390,844 --wait-for-timeout=10000 http://127.0.0.1:5174/#/home?tab=butty test-results/ui-verify/baseline-butty-390.png
```

Expected:

```text
Screenshots write successfully
Any visible clipping, crowding, or weak hierarchy becomes a task note
```

---

### Task 2: Settings Model Setup State Polish

**Files:**
- Modify: `lib/features/home/presentation/widgets/settings/ai_models_section.dart`
- Modify: `lib/features/home/presentation/widgets/settings/llm_download_tile.dart`
- Modify: `lib/features/home/presentation/widgets/settings/vision_download_tile.dart`
- Test: `test/features/home/presentation/widgets/ai_models_section_test.dart`

- [ ] **Step 1: Add narrow-state test coverage**

Add a test shaped like this:

```dart
testWidgets('AI model setup keeps action hierarchy stable on narrow phones', (tester) async {
  tester.view.physicalSize = const Size(320, 593);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await pumpAiModelsSection(tester);

  expect(find.text('Local AI setup'), findsOneWidget);
  expect(find.text('Setup needed'), findsWidgets);
  expect(find.byType(ProfileManagementActionButton), findsWidgets);
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: Run the failing test**

Run:

```powershell
flutter test test\features\home\presentation\widgets\ai_models_section_test.dart --name "AI model setup keeps action hierarchy stable on narrow phones"
```

Expected:

```text
FAIL before implementation if the state or hierarchy is not yet covered
PASS only after the Settings implementation is updated
```

- [ ] **Step 3: Tighten the UI**

Implementation requirements:

```text
Use one short status label per model state
Keep helper copy below two lines at 320px
Use primary button styling only for the next required action
Use lower-emphasis style for optional re-download or cloud fallback actions
Keep progress and cancel controls in a stable row or stacked column with 10-12px spacing
```

- [ ] **Step 4: Verify Settings**

Run:

```powershell
flutter test test\features\home\presentation\widgets\ai_models_section_test.dart
npx playwright screenshot --browser=chromium --viewport-size=320,593 --wait-for-timeout=10000 http://127.0.0.1:5174/#/settings test-results/ui-verify/settings-model-setup-next-e2e-320.png
```

Expected:

```text
Widget tests pass
Screenshot shows no compressed buttons or clipped model status text
```

---

### Task 3: Translate Input, Empty, And Keyboard-Inset Polish

**Files:**
- Modify: `lib/features/home/presentation/widgets/translate/translate_text_mode_panel.dart`
- Modify: `lib/features/home/presentation/widgets/translate/empty_output.dart`
- Test: `test/features/home/presentation/widgets/translate_density_test.dart`

- [ ] **Step 1: Add empty and reverse-mode assertions**

Add tests shaped like this:

```dart
testWidgets('translate empty states stay close to input on narrow phones', (tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await pumpTranslatePanel(tester);

  final Rect emptyState = tester.getRect(find.text('Type below to preview Baybayin'));
  final Rect input = tester.getRect(find.byType(TextField).first);
  expect(input.top - emptyState.bottom, lessThan(180));
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: Run the targeted test**

Run:

```powershell
flutter test test\features\home\presentation\widgets\translate_density_test.dart --name "translate empty states stay close to input on narrow phones"
```

Expected:

```text
FAIL if vertical spacing regresses
PASS after layout spacing is tightened
```

- [ ] **Step 3: Implement polish**

Implementation requirements:

```text
Use compact empty-state height when the keyboard is open
Use direction-specific helper copy
Keep example chips on one row when possible, then wrap with 8px run spacing
Keep cleanup preview readable without becoming the primary visual element
Avoid new provider or translation logic changes
```

- [ ] **Step 4: Verify Translate screenshots**

Run:

```powershell
flutter test test\features\home\presentation\widgets\translate_density_test.dart
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\verify-translate-header-ui.ps1 -Url http://127.0.0.1:5174 -Tabs "translate" -Widths "320,360,390,430,844" -SkipTests
```

Expected:

```text
Tests pass
Screenshots show readable input/output states with no keyboard-density crowding
```

---

### Task 4: Scanner Status And Result Panel Polish

**Files:**
- Modify: `lib/features/scanner/presentation/widgets/scanner_camera_status.dart`
- Modify: `lib/features/scanner/presentation/widgets/scanner_result_panel.dart`
- Test: `test/features/scanner/presentation/widgets/scanner_camera_status_test.dart`
- Test: `test/features/scanner/presentation/widgets/scanner_result_panel_polish_test.dart`

- [ ] **Step 1: Add tests for status hierarchy and action reachability**

Add assertions shaped like this:

```dart
expect(find.text('Camera ready'), findsOneWidget);
expect(find.textContaining('raw exception'), findsNothing);
expect(tester.getSize(find.byType(FilledButton).first).height, greaterThanOrEqualTo(44));
expect(tester.takeException(), isNull);
```

- [ ] **Step 2: Run targeted scanner tests**

Run:

```powershell
flutter test test\features\scanner\presentation\widgets\scanner_camera_status_test.dart test\features\scanner\presentation\widgets\scanner_result_panel_polish_test.dart
```

Expected:

```text
Tests fail if status copy or actions are not covered
Tests pass after UI-only scanner polish
```

- [ ] **Step 3: Implement UI-only scanner polish**

Implementation requirements:

```text
Keep camera/model readiness state clear without changing scanner logic
Shorten unavailable/error state copy
Keep retry/setup actions visible above the floating nav
Use semantic color containers for ready, warning, and blocked states
Do not change camera permission, model loading, or inference code
```

- [ ] **Step 4: Verify scan overlap**

Run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\scan-layout-overlap-pass.ps1 -Url http://127.0.0.1:5174/#/home?tab=scan -OutRoot qa-artifact/scan-layout-strict-overlap-next-e2e-polish
```

Expected:

```text
Report status is pass
Contact sheet is written
No overlap appears in 320x240, 340x260, 360x740, 390x844, 430x932, 844x390, or 1024x768 captures
```

---

### Task 5: Learn And Quiz Detail Density Polish

**Files:**
- Modify: `lib/features/home/presentation/widgets/learn_home/lesson_card.dart`
- Modify: `lib/features/learning/presentation/widgets/lesson_detail_content.dart`
- Test: `test/features/home/presentation/widgets/learn_density_test.dart`
- Test: `test/features/learning/presentation/widgets/learning_density_test.dart`

- [ ] **Step 1: Add card and lesson-detail assertions**

Add tests shaped like this:

```dart
expect(find.text('Continue'), findsWidgets);
expect(tester.getSize(find.text('Continue').first).height, lessThanOrEqualTo(48));
expect(tester.takeException(), isNull);
```

For lesson detail:

```dart
expect(find.byType(SingleChildScrollView), findsWidgets);
expect(find.textContaining('Start'), findsWidgets);
expect(tester.takeException(), isNull);
```

- [ ] **Step 2: Run focused Learn tests**

Run:

```powershell
flutter test test\features\home\presentation\widgets\learn_density_test.dart test\features\learning\presentation\widgets\learning_density_test.dart
```

Expected:

```text
Tests pass after Learn density changes
No overflow exceptions are reported
```

- [ ] **Step 3: Implement Learn polish**

Implementation requirements:

```text
Reduce repeated chrome inside compact cards
Use semantic progress colors from ColorScheme
Keep lesson thumbnails and text aligned at 320px
Avoid nested card styling
Keep quiz actions reachable in short landscape
```

- [ ] **Step 4: Capture Learn screenshots**

Run:

```powershell
npx playwright screenshot --browser=chromium --viewport-size=390,844 --wait-for-timeout=10000 http://127.0.0.1:5174/#/home?tab=learn test-results/ui-verify/learn-next-e2e-390.png
npx playwright screenshot --browser=chromium --viewport-size=844,390 --wait-for-timeout=10000 http://127.0.0.1:5174/#/home?tab=learn test-results/ui-verify/learn-next-e2e-844x390.png
```

Expected:

```text
Screenshots show no clipped lesson cards and no unreachable quick actions
```

---

### Task 6: Butty Chat Suggestions And Empty/Loading States

**Files:**
- Modify: `lib/features/home/presentation/widgets/butty_chat/butty_chat_view.dart`
- Modify: `lib/features/home/presentation/widgets/butty_chat/suggested_questions_row.dart`
- Test: `test/features/home/presentation/widgets/mobile_tap_targets_test.dart`

- [ ] **Step 1: Add prompt-clearance and message-state assertions**

Add tests shaped like this:

```dart
testWidgets('Butty suggestions keep floating nav clearance at 390px', (tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await pumpButtyPromptRow(tester);

  final Rect row = tester.getRect(find.byType(ListView).first);
  expect(row.right, lessThanOrEqualTo(282));
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: Run the focused Butty test**

Run:

```powershell
flutter test test\features\home\presentation\widgets\mobile_tap_targets_test.dart --name "Butty suggestions keep floating nav clearance at 390px"
```

Expected:

```text
FAIL if suggestions collide with floating navigation
PASS after prompt row clearance is stable
```

- [ ] **Step 3: Implement Butty polish**

Implementation requirements:

```text
Keep suggestion chips easy to scan and tap
Reserve room for floating navigation at 390px and below
Keep empty chat and waiting states compact
Do not change chat provider, sync, memory, or model behavior
```

- [ ] **Step 4: Capture Butty screenshot**

Run:

```powershell
npx playwright screenshot --browser=chromium --viewport-size=390,844 --wait-for-timeout=10000 http://127.0.0.1:5174/#/home?tab=butty test-results/ui-verify/butty-next-e2e-390.png
```

Expected:

```text
Screenshot shows suggestions clear of floating nav with readable prompt chips
```

---

### Task 7: Full Verification And Evidence Pack

**Files:**
- Modify: `docs/design-improvement-evidence-pack.md`
- Evidence: `test-results/ui-verify/`
- Evidence: `qa-artifact/prod-smoke-next-e2e-polish/`
- Evidence: `qa-artifact/scan-layout-strict-overlap-next-e2e-polish/`

- [ ] **Step 1: Run command verification**

Run:

```powershell
git diff --check
flutter analyze
flutter test
flutter build web --release
```

Expected:

```text
git diff --check exits 0, allowing line-ending warnings only
flutter analyze reports No issues found
flutter test reports all tests passed
flutter build web writes build\web
Any flutter_gemma wasm dry-run warnings are recorded as third-party warnings if build exits 0
```

- [ ] **Step 2: Run static-preview smoke**

Run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\prod-smoke.ps1 -BaseUrl http://127.0.0.1:5174 -OutRoot qa-artifact/prod-smoke-next-e2e-polish -Viewport "390,844" -WaitMs 10000
```

Expected:

```text
Routes /#/login, /#/home, and /#/settings return 200
Screenshots are written
Report status is pass
```

- [ ] **Step 3: Refresh evidence pack**

Update `docs/design-improvement-evidence-pack.md` with:

```text
Latest screenshots
Latest smoke report timestamp and status
Latest scan overlap report timestamp and status
Latest flutter analyze/test/build results
Branch ahead/behind count
Remaining Android device QA gap if device QA was not run
```

- [ ] **Step 4: Final local review**

Run:

```powershell
git diff --stat
git diff -- docs/design-improvement-evidence-pack.md
git status --short --branch
```

Expected:

```text
Diff contains only UI, widget test, QA docs, and plan changes
No backend, schema, auth logic, model pipeline, or secret files changed
```

---

### Task 8: PR Readiness Check Without Merge

**Files:**
- Read: Git history and PR metadata only
- Do not modify files unless evidence docs need a timestamp/status correction

- [ ] **Step 1: Check diff against main**

Run:

```powershell
git fetch origin main origin design-improvement
git rev-list --left-right --count origin/main...HEAD
git diff --stat origin/main...HEAD
git diff --name-status origin/main...HEAD
```

Expected:

```text
No branch switch occurs
Diff is understandable and reviewable
Any unexpectedly changed files are investigated before commit
```

- [ ] **Step 2: Check PR status**

Run:

```powershell
gh pr view 36 --json number,title,headRefName,baseRefName,mergeable,state,url,statusCheckRollup --jq "{number,title,headRefName,baseRefName,mergeable,state,url,checks:[.statusCheckRollup[] | {name:.name,status:.status,conclusion:.conclusion}]}"
```

Expected:

```text
PR is open
Head is design-improvement
Base is main
Checks are green or pending checks are listed with exact names
```

- [ ] **Step 3: Report blockers**

Report:

```text
Codex-controlled blockers fixed
GitHub checks status
Real Android device QA status
Any remaining user-controlled review, merge, account, or device actions
```
