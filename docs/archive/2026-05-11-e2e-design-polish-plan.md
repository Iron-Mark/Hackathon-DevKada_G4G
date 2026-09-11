# E2E Design Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish one more end-to-end design-improvement pass that tightens the mobile app surfaces most likely to affect PR review: Settings, Translate, Learn, Butty, production preview, and evidence docs.

**Architecture:** Keep all changes inside Flutter presentation widgets, existing Riverpod presentation providers, tests, and docs. Preserve the current Kudlit design system, bottom navigation, shared app chrome, and existing user-facing copy unless a short label is required for clarity.

**Tech Stack:** Flutter, Dart, Riverpod, go_router, Flutter widget tests, repo PowerShell QA scripts, Playwright-driven screenshots through existing scripts, GitHub PR checks, Cloudflare Pages preview.

---

## Scope Guard

- Stay on `design-improvement`.
- Do not merge, rebase, or switch branches.
- Do not touch backend, Supabase schema, auth business logic, model pipeline internals, migrations, or production secrets.
- Prefer web/mobile viewport QA for this pass; real Android device QA remains a separate manual gap.
- Commit only when explicitly asked by checkpoint rules; push only when explicitly asked.

## File Map

- Modify: `lib/features/home/presentation/widgets/settings/ai_models_section.dart`
- Modify: `lib/features/home/presentation/widgets/settings/llm_download_tile.dart`
- Modify: `lib/features/home/presentation/widgets/settings/vision_download_tile.dart`
- Modify: `lib/features/home/presentation/widgets/settings/segmented_picker.dart`
- Modify: `lib/features/home/presentation/widgets/settings/theme_row.dart`
- Modify: `lib/features/home/presentation/widgets/settings/ai_preference_row.dart`
- Modify: `lib/features/home/presentation/widgets/translate/translate_text_mode_panel.dart`
- Modify: `lib/features/home/presentation/providers/translate_text_controller.dart`
- Modify: `lib/features/home/presentation/widgets/learn_home/lesson_card.dart`
- Modify: `lib/features/home/presentation/widgets/butty_chat/suggested_questions_row.dart`
- Modify: `docs/design-improvement-evidence-pack.md`
- Test: `test/features/home/presentation/widgets/ai_models_section_test.dart`
- Test: `test/features/home/presentation/screens/profile_settings_polish_test.dart`
- Test: `test/features/home/presentation/widgets/translate_density_test.dart`
- Test: `test/features/home/presentation/widgets/learn_density_test.dart`
- Test: `test/features/home/presentation/widgets/mobile_tap_targets_test.dart`
- Evidence: `test-results/ui-verify/`
- Evidence: `qa-artifact/prod-smoke-*`
- Evidence: `qa-artifact/scan-layout-strict-overlap-*`

## Design Quality Bar

- Mobile-first at `320x593`, `360x740`, `390x844`, `430x932`, and short landscape.
- Minimum tap target: 44px for actionable controls.
- No horizontal overflow, clipped text, or floating tab overlap.
- Use Material color scheme tokens instead of raw ad hoc colors.
- Keep hierarchy compact and operational, not marketing-style.
- Preserve existing Kudlit branding and familiar tab/chrome behavior.

---

### Task 1: Baseline PR And Preview Audit

**Files:**
- Read: `docs/design-improvement-evidence-pack.md`
- Read: `README.md`
- Evidence: `qa-artifact/prod-smoke-local-ui-polish/report.json`
- Evidence: `qa-artifact/scan-layout-strict-overlap-e2e/report.json`

- [ ] **Step 1: Confirm branch and PR state**

Run:

```powershell
git status --short --branch
gh pr view 36 --json number,title,headRefName,baseRefName,mergeable,state,url,statusCheckRollup --jq "{number,title,headRefName,baseRefName,mergeable,state,url,checks:[.statusCheckRollup[] | {name:.name,status:.status,conclusion:.conclusion}]}"
```

Expected:

```text
design-improvement tracks origin/design-improvement
PR #36 is open
mergeable is MERGEABLE
flutter analyze and Cloudflare Pages are either SUCCESS or clearly reported as pending
```

- [ ] **Step 2: Capture current branch delta**

Run:

```powershell
git fetch origin main
git rev-list --left-right --count origin/main...HEAD
git diff --name-status origin/main...HEAD
git diff --stat origin/main...HEAD
```

Expected:

```text
No branch switch occurs
Diff size and ahead/behind count are recorded for the evidence pack
```

- [ ] **Step 3: Review existing screenshots before editing**

Run:

```powershell
Get-ChildItem test-results\ui-verify -Filter *.png | Sort-Object Name | Select-Object -ExpandProperty Name
Get-Content qa-artifact\prod-smoke-local-ui-polish\report.json -Raw
```

Expected:

```text
Settings, Translate, Scan, Learn, and Butty evidence paths are available or missing paths are listed before changes
```

---

### Task 2: Settings Local AI Setup Polish

**Files:**
- Modify: `lib/features/home/presentation/widgets/settings/ai_models_section.dart`
- Modify: `lib/features/home/presentation/widgets/settings/llm_download_tile.dart`
- Modify: `lib/features/home/presentation/widgets/settings/vision_download_tile.dart`
- Modify: `lib/features/home/presentation/widgets/settings/segmented_picker.dart`
- Test: `test/features/home/presentation/widgets/ai_models_section_test.dart`
- Test: `test/features/home/presentation/screens/profile_settings_polish_test.dart`

- [ ] **Step 1: Add failing narrow Settings assertions**

Add or extend widget tests so they assert:

```dart
expect(find.text('Local AI setup'), findsOneWidget);
expect(find.text('Ready for local Butty replies.'), findsOneWidget);
expect(find.text('Download once before live recognition.'), findsOneWidget);
expect(tester.takeException(), isNull);
```

For the narrow preference row, assert the segmented picker sits below the label at `320x593`:

```dart
final Rect label = tester.getRect(find.text('App theme'));
final Rect option = tester.getRect(find.text('System'));
expect(option.top, greaterThan(label.bottom));
```

- [ ] **Step 2: Run the targeted tests**

Run:

```powershell
flutter test test\features\home\presentation\widgets\ai_models_section_test.dart test\features\home\presentation\screens\profile_settings_polish_test.dart
```

Expected before implementation if adding new assertions:

```text
At least one assertion fails for the missing polish behavior
```

- [ ] **Step 3: Tighten Settings visual hierarchy**

Implementation rules:

```text
Use short status labels
Keep setup copy under two lines at 320px
Keep Download, Re-download, and Cancel at 44px minimum height
Use colorScheme primaryContainer/errorContainer instead of raw red/green
Use Wrap or LayoutBuilder only where it prevents overflow
```

- [ ] **Step 4: Verify Settings tests pass**

Run:

```powershell
flutter test test\features\home\presentation\widgets\ai_models_section_test.dart test\features\home\presentation\screens\profile_settings_polish_test.dart
```

Expected:

```text
All targeted Settings tests pass
No tester overflow exception
```

- [ ] **Step 5: Capture Settings screenshot**

Run:

```powershell
npx playwright screenshot --browser=chromium --viewport-size=320,593 --wait-for-timeout=10000 http://127.0.0.1:5174/#/settings test-results/ui-verify/settings-320-next-polish.png
```

Expected:

```text
Screenshot writes successfully
No visible segmented control wrapping, clipping, or dense text collision
```

---

### Task 3: Translate Cleanup, Empty, And Keyboard Polish

**Files:**
- Modify: `lib/features/home/presentation/widgets/translate/translate_text_mode_panel.dart`
- Modify: `lib/features/home/presentation/providers/translate_text_controller.dart`
- Test: `test/features/home/presentation/widgets/translate_density_test.dart`

- [ ] **Step 1: Add focused Translate assertions**

Add or keep tests for:

```dart
expect(find.text('Used as: kumusta'), findsOneWidget);
expect(find.text('Examples:'), findsOneWidget);
expect(find.text('ka'), findsOneWidget);
expect(find.text('ki'), findsOneWidget);
expect(find.text('ku'), findsOneWidget);
expect(find.text('k+'), findsOneWidget);
expect(tester.takeException(), isNull);
```

For portrait keyboard stability:

```dart
final TextField textField = tester.widget<TextField>(
  find.byKey(const ValueKey<String>('translate-filipino-input')),
);
expect(textField.maxLines, equals(7));
```

- [ ] **Step 2: Run Translate tests**

Run:

```powershell
flutter test test\features\home\presentation\widgets\translate_density_test.dart
```

Expected:

```text
Translate density, keyboard, cleanup-preview, and reverse-example tests pass
```

- [ ] **Step 3: Improve only if screenshots show issues**

Implementation rules:

```text
Keep focused portrait input expanded when keyboard opens
Keep reverse example chips visible but compact
Keep cleanup preview high contrast but secondary to output
Keep output empty state useful without adding tutorial text
Do not change transliteration business logic beyond display helper text
```

- [ ] **Step 4: Capture Translate screenshots**

Run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\verify-translate-header-ui.ps1 -Url http://127.0.0.1:5174 -Tabs "translate" -Widths "320,360,390,430,844" -SkipTests
```

Expected:

```text
Screenshots write under test-results/ui-verify
No overflow, clipped header, keyboard-cramped input, or floating tab overlap
```

---

### Task 4: Learn And Butty Final Touch Pass

**Files:**
- Modify: `lib/features/home/presentation/widgets/learn_home/lesson_card.dart`
- Modify: `lib/features/home/presentation/widgets/butty_chat/suggested_questions_row.dart`
- Test: `test/features/home/presentation/widgets/learn_density_test.dart`
- Test: `test/features/home/presentation/widgets/mobile_tap_targets_test.dart`

- [ ] **Step 1: Protect current Learn and Butty contracts**

Expected assertions:

```dart
expect(find.text('Core Consonants'), findsOneWidget);
expect(find.ancestor(of: find.text('Core Consonants'), matching: find.byType(Opacity)), findsNothing);
expect(tester.takeException(), isNull);
```

For Butty:

```dart
final Rect scrollWindow = tester.getRect(find.byType(ListView));
expect(scrollWindow.right, lessThanOrEqualTo(224));
```

- [ ] **Step 2: Run focused tests**

Run:

```powershell
flutter test test\features\home\presentation\widgets\learn_density_test.dart test\features\home\presentation\widgets\mobile_tap_targets_test.dart
```

Expected:

```text
Both files pass with no overflow exceptions
```

- [ ] **Step 3: Polish only visible weak spots**

Implementation rules:

```text
Do not add new cards inside cards
Keep locked lesson cards readable without global opacity fade
Keep Butty prompt chips clear of the floating tab
Use trailing fade only where it communicates horizontal scroll
Keep all prompt chips tappable and readable at 320px
```

- [ ] **Step 4: Capture screenshots**

Run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\verify-translate-header-ui.ps1 -Url http://127.0.0.1:5174 -Tabs "learn,butty" -Widths "320,390,430" -SkipTests
```

Expected:

```text
Learn and Butty screenshots write successfully
No content hidden behind the floating tab
```

---

### Task 5: Full Local QA And Artifact Refresh

**Files:**
- Modify: `docs/design-improvement-evidence-pack.md`
- Evidence: `qa-artifact/prod-smoke-next-polish/report.json`
- Evidence: `qa-artifact/scan-layout-strict-overlap-next-polish/report.json`

- [ ] **Step 1: Run analyzer**

Run:

```powershell
flutter analyze
```

Expected:

```text
No issues found
```

- [ ] **Step 2: Run full test suite**

Run:

```powershell
flutter test
```

Expected:

```text
All tests passed
```

- [ ] **Step 3: Build web**

Run:

```powershell
flutter build web --release
```

Expected:

```text
Build exits 0
Known flutter_gemma web warnings may appear only if they match existing package warnings
```

- [ ] **Step 4: Run smoke and scanner layout evidence**

Run:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\prod-smoke.ps1 -BaseUrl http://127.0.0.1:5174 -OutRoot qa-artifact/prod-smoke-next-polish -Viewport "390,844" -WaitMs 10000
pwsh -NoProfile -ExecutionPolicy Bypass -File scripts\scan-layout-overlap-pass.ps1 -Url http://127.0.0.1:5174/#/home?tab=scan -OutRoot qa-artifact/scan-layout-strict-overlap-next-polish
```

Expected:

```text
Both report.json files show "status": "pass"
```

- [ ] **Step 5: Refresh the evidence pack**

Update `docs/design-improvement-evidence-pack.md` with:

```text
Current date
Latest commit hash
Flutter analyze result
Flutter test count
Build result
Screenshot folders
Smoke report path
Scanner overlap report path
GitHub PR #36 status
Remaining Android device QA gap
```

---

### Task 6: Final PR Readiness And Checkpoint

**Files:**
- Read: all modified files
- Read: PR #36 check rollup

- [ ] **Step 1: Check final diff**

Run:

```powershell
git diff --stat
git diff --check
git status --short --branch
```

Expected:

```text
Only planned UI/test/docs files changed
git diff --check has no whitespace errors
```

- [ ] **Step 2: Check PR status**

Run:

```powershell
gh pr view 36 --json number,title,mergeable,state,url,statusCheckRollup --jq "{number,title,mergeable,state,url,checks:[.statusCheckRollup[] | {name:.name,status:.status,conclusion:.conclusion}]}"
```

Expected:

```text
PR #36 remains open and mergeable
Any pending checks are reported with exact names
```

- [ ] **Step 3: Prepare checkpoint commit only after approval**

Use this message shape when the user explicitly says `checkpoint commit`:

```text
fix(ui): checkpoint final design polish

## Summary

- Tighten final mobile design polish across Settings, Translate, Learn, and Butty.
- Refresh QA evidence and reviewer-facing docs.
- Preserve existing branch and PR flow without merge actions.

## Changes Made
### Mobile UI Polish

- ...

### Tests And QA

- ...

### Evidence

- ...

## Why

- ...

## Notes for Reviewers

- ...
```

- [ ] **Step 4: Push only after approval**

Run only when the user explicitly asks to push:

```powershell
git push origin design-improvement
git rev-parse HEAD
git ls-remote origin refs/heads/design-improvement
```

Expected:

```text
Local HEAD hash matches remote design-improvement hash
```

## Self-Review Checklist

- [ ] Each task has exact files and commands.
- [ ] Each task has a verification step with expected output.
- [ ] The plan keeps backend/auth/model-pipeline scope out.
- [ ] The plan includes mobile, short-landscape, screenshot, tests, and PR readiness proof.
- [ ] The plan leaves real Android device QA as a separate user-side gap.
