# Design Improvement Evidence Pack

Date: 2026-05-11
Branch: `design-improvement`

## Scope

This pack summarizes the current design-improvement branch evidence for the
mobile-first UI pass. It covers Translate, Scan, Butty prompt clearance,
Settings AI model setup, and branch readiness against `origin/main`.

## Current UI Changes

- Settings AI models now use shorter local-setup copy, less technical status
  text, touch-safe progress/cancel controls, and clearer scanner/Butty model
  purposes. Model setup badges now use the app semantic color scheme instead
  of ad hoc red/green text colors. Narrow action rows now stack status copy
  above actions to prevent squeezed buttons at 320px.
- Translate text mode now renders cleanup previews as a higher-contrast helper
  pill and uses compact reverse-input layout after encoded examples produce
  actions. Empty output states now use direction-specific helper copy with
  tighter keyboard-inset spacing.
- Butty suggested prompts reserve space for the floating tab control on narrow
  mobile screens.
- Learn progress badges now use the app semantic color scheme instead of raw
  hard-coded colors.
- Scanner web status now uses concise camera readiness copy and semantic
  ready/warning/error containers without changing camera or model-loading
  behavior.
- Learn and lesson-detail actions keep actual 44px visual targets in compact
  and short-landscape layouts.
- Butty typing/loading bubbles now stay content-width on narrow phones while
  keeping runtime animation enabled.
- Codex review fixes are applied for reverse-mode `k+` cleanup handling, root
  PWA manifest launch path, sitemap same-host URLs, and failed YOLO model-load
  disposal.

## QA Evidence

Latest local visual evidence:

- `test-results/ui-verify/baseline-settings-320.png`
- `test-results/ui-verify/baseline-translate-390.png`
- `test-results/ui-verify/baseline-learn-390.png`
- `test-results/ui-verify/baseline-butty-390.png`
- `test-results/ui-verify/settings-320-next-polish.png`
- `test-results/ui-verify/settings-model-setup-next-e2e-320.png`
- `test-results/ui-verify/learn-next-e2e-390.png`
- `test-results/ui-verify/learn-next-e2e-844x390.png`
- `test-results/ui-verify/butty-next-e2e-390.png`
- `test-results/ui-verify/butty-carousel-clearance-390.png`
- `test-results/ui-verify/translate-header-translate-320.png`
- `test-results/ui-verify/translate-header-translate-360.png`
- `test-results/ui-verify/translate-header-translate-390.png`
- `test-results/ui-verify/translate-header-translate-430.png`
- `test-results/ui-verify/translate-header-translate-844.png`
- `test-results/ui-verify/translate-header-scan-360.png`
- `test-results/ui-verify/translate-header-learn-360.png`
- `test-results/ui-verify/translate-header-butty-360.png`

Latest E2E visual evidence:

- `test-results/ui-verify-e2e/translate-header-translate-360.png`
- `test-results/ui-verify-e2e/translate-header-translate-390.png`
- `test-results/ui-verify-e2e/translate-header-translate-430.png`
- `test-results/ui-verify-e2e/translate-header-translate-844.png`
- `test-results/ui-verify-e2e/translate-header-scan-360.png`
- `test-results/ui-verify-e2e/translate-header-scan-390.png`
- `test-results/ui-verify-e2e/translate-header-scan-430.png`
- `test-results/ui-verify-e2e/translate-header-scan-844.png`
- `test-results/ui-verify-e2e/translate-header-learn-360.png`
- `test-results/ui-verify-e2e/translate-header-learn-390.png`
- `test-results/ui-verify-e2e/translate-header-learn-430.png`
- `test-results/ui-verify-e2e/translate-header-learn-844.png`
- `test-results/ui-verify-e2e/translate-header-butty-360.png`
- `test-results/ui-verify-e2e/translate-header-butty-390.png`
- `test-results/ui-verify-e2e/translate-header-butty-430.png`
- `test-results/ui-verify-e2e/translate-header-butty-844.png`

Latest scanner layout evidence:

- `qa-artifact/scan-layout-strict-overlap/report.json`
- `qa-artifact/scan-layout-strict-overlap/scan-layout-overlap-contact-sheet.html`
- Latest timestamp: `2026-05-10T18:08:55.7427350+08:00`
- Status: `pass`

Latest E2E scanner layout evidence:

- `qa-artifact/scan-layout-strict-overlap-next-e2e-polish/report.json`
- `qa-artifact/scan-layout-strict-overlap-next-e2e-polish/scan-layout-overlap-contact-sheet.html`
- Latest timestamp: `2026-05-11T02:32:29.3741293+08:00`
- Viewports covered: `360x740`, `390x844`, `430x932`, `844x390`,
  `1024x768`, `340x260`, `320x240`
- Status: `pass`

Previous next-polish scanner layout evidence:

- `qa-artifact/scan-layout-strict-overlap-next-polish/report.json`
- `qa-artifact/scan-layout-strict-overlap-next-polish/scan-layout-overlap-contact-sheet.html`
- Latest timestamp: `2026-05-11T01:22:42.8039564+08:00`
- Viewports covered: `360x740`, `390x844`, `430x932`, `844x390`,
  `1024x768`, `340x260`, `320x240`
- Status: `pass`

Previous E2E scanner layout evidence:

- `qa-artifact/scan-layout-strict-overlap-e2e/report.json`
- `qa-artifact/scan-layout-strict-overlap-e2e/scan-layout-overlap-contact-sheet.html`
- Latest timestamp: `2026-05-10T18:57:58.7644946+08:00`
- Viewports covered: `360x740`, `390x844`, `430x932`, `844x390`,
  `1024x768`, `340x260`, `320x240`
- Status: `pass`

Latest smoke evidence:

- `qa-artifact/prod-smoke-next-e2e-polish/report.json`
- Latest timestamp: `2026-05-11T02:31:07.8496704+08:00`
- Base URL: `http://127.0.0.1:5174`
- Viewport: `390,844`
- Routes covered: `/#/login`, `/#/home`, `/#/settings`
- Status: `pass`

Previous next-polish smoke evidence:

- `qa-artifact/prod-smoke-next-polish/report.json`
- Latest timestamp: `2026-05-11T01:21:22.6193113+08:00`
- Base URL: `http://127.0.0.1:5174`
- Viewport: `390,844`
- Routes covered: `/#/login`, `/#/home`, `/#/settings`
- Status: `pass`

Previous smoke evidence:

- `qa-artifact/prod-smoke/report.json`
- Latest timestamp: `2026-05-10T18:09:44.6657712+08:00`
- Routes covered: `/#/login`, `/#/home`, `/#/settings`
- Status: `pass`

Latest design-cycle static build smoke:

- `qa-artifact/prod-smoke-design-cycle/report.json`
- Latest timestamp: `2026-05-10T18:41:44.2500076+08:00`
- Base URL: `http://127.0.0.1:5174`
- Viewport: `390,844`
- Routes covered: `/#/login`, `/#/home`, `/#/settings`
- Status: `pass`

Latest E2E static build smoke:

- `qa-artifact/prod-smoke-e2e/report.json`
- Latest timestamp: `2026-05-10T18:56:43.9550825+08:00`
- Base URL: `http://127.0.0.1:5174`
- Viewport: `390,844`
- Routes covered: `/#/login`, `/#/home`, `/#/settings`
- Status: `pass`

Latest command checks:

- `flutter analyze`: `pass`
- `flutter test`: `pass` (`177` tests)
- `flutter build web --release --base-href "/kudlit-app/"`: `pass`
- `flutter build web --release`: `pass`
- `build.sh`: `pass`; generated root manifest `start_url` points at `/app/`
  and generated sitemap contains only same-host URLs.
- `npx playwright screenshot ... /#/settings`: `pass`
- `npx playwright screenshot ... baseline/settings/learn/butty`: `pass`
- `pwsh scripts/verify-translate-header-ui.ps1 ... -Tabs "translate,scan,learn,butty" -SkipTests`: `pass`
- `pwsh scripts/verify-translate-header-ui.ps1 ... -Tabs "translate" -Widths "320,360,390,430,844" -SkipTests`: `pass`
- `pwsh scripts/prod-smoke.ps1 ...`: `pass`
- `pwsh scripts/scan-layout-overlap-pass.ps1 ...`: `pass`
- `git diff --check`: `pass` with CRLF normalization warnings only
- GitHub PR #36 `flutter analyze`: `pass`
- GitHub PR #36 `Cloudflare Pages`: `pass`

## Branch Readiness

Checked without merging or switching branches:

- Fetched `origin/main` and `origin/design-improvement`.
- `git rev-list --left-right --count origin/main...HEAD`: `0 17`
- `design-improvement` is 17 commits ahead of `origin/main` and 0 commits
  behind.
- `git merge-tree $(git merge-base HEAD origin/main) origin/main HEAD` reported
  no conflict markers in the checked output.
- GitHub PR #36 is open, mergeable, and targets `main` from
  `design-improvement`.
- The branch is pushed and the PR check rollup is green for `flutter analyze`
  and `Cloudflare Pages` at pushed HEAD `b6ce176`.
- The latest next-E2E polish diff is local and uncommitted, so PR checks do not
  yet cover those local changes until a checkpoint commit and push are
  explicitly requested.

Branch diff size against `origin/main`:

- 69 files changed.
- Includes app UI, scanner/translate model-readiness UX, tests, docs, web
  release assets, and deployment/docs updates.

## Remaining Gaps

- Real-device Android QA is still the main remaining confidence gap for native
  Settings model setup and scanner runtime behavior.
- Current checks prove layout, build, tests, and local web/static-preview
  behavior. They do not prove real model downloads from production data or
  physical camera latency.
- Merge is not performed here. This pack only reports readiness signals.
