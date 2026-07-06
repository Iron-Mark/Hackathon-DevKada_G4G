# Comprehensive TODO — Scan UI Hardening + Documentation Sync

## Scope

This checklist tracks remaining actionable work after the latest scan UI hardening pass.
Current state: core scan-tab responsive / overlap / transition hardening updates are already implemented in code and validated in matrix scripts.

## Conventions

- unchecked = pending
- in-progress = active work
- checked = done
- **P0** = blocker / urgent
- **P1** = important for project integrity
- **P2** = follow-up / cleanup

## P0 — Docs drift blockers (must fix)

- [x] Update `CLAUDE.md`
  - Replace web-platform statement in **Platform Notes**:
    - remove “Camera/TFLite features are unavailable on web”
    - document webcam-first web behavior with capture-based scanner flow and fallback paths
  - Keep design rules intact.
  - **Acceptance:** no web scanner-availability mismatch remains in `CLAUDE.md`.

- [x] Update `docs/system_audit.md`
  - Section **Scanner**:
    - replace “Native only (Android/iOS)” with current scanner capability statement.
  - Section **A. Web / Design Validation**:
    - replace “native YOLO/Gemma scanner features will not work on Web” with the correct Web-UI/testing guidance.
  - **Acceptance:** feature capability claims match reality in code/docs.

- [x] Update `README.md` “Folder Structure”
  - reflect implemented active feature slices as:
    - `auth`
    - `home` / `scanner`
    - `translator`
    - `learn` (if still planned, mark accurately as planned)
  - **Acceptance:** no contradictory claims in feature list.

## P1 — Scan hardening documentation + evidence index

- [x] Add a dedicated **scan hardening runbook** section in `README.md` (or `docs/scan-layout-hardening.md`):
 - command for running strict matrix + transitions:
    - `pwsh -NoProfile -ExecutionPolicy Bypass -File scripts/scan-layout-overlap-pass.ps1`
  - latest verified artifact timestamp: `2026-05-10 18:08:55 +08:00`
  - matrix size presets used by script
    - `360x740`, `390x844`, `430x932`, `844x390`, `1024x768`
    - optional strict tiny widths currently enabled: `340x260`, `320x240`
  - transition capture behavior
    - `qa_camera_status=unavail-ready` probe
    - phases: `early`, `mid`, `late`
    - artifact output locations
  - output paths
    - `qa-artifact/scan-layout-strict-overlap/matrix`
    - `qa-artifact/scan-layout-strict-overlap/transitions`
    - `qa-artifact/scan-layout-strict-overlap/scan-layout-overlap-contact-sheet.html`
    - `qa-artifact/scan-layout-strict-overlap/report.json`
  - expected result: script exits success and validates artifacts.

- [x] Add one-line mention in `README.md` and/or docs that run-time proof for hardening is captured under `qa-artifact`.
  - Include last verified timestamp from script output.
  - **Acceptance:** future contributors can reproduce and review scan hardening artifacts quickly.

- [x] Update `scripts/scan-layout-overlap-pass.ps1` to ensure documented and generated artifact paths are explicit in usage text (if/when argument `-TestPath` / `-OutRoot` differ from defaults).
  - If no change needed, record as `[x]` with reason.
  - Not needed in this pass because artifact paths and usage are already explicit.

## P1 — Bring legacy plan docs into non-confusing state

- [x] Resolve `docs/realtime_scan_aggregator_plan.md` status mismatch
  - either mark implementation status as complete (and move acceptance checklist to historical appendix), or
  - move to archive/backlog if feature is now represented elsewhere.
  - **Acceptance:** no unfinished-work document falsely representing implemented behavior.

- [x] Reconcile `docs/PR_AUTH_SCANNER_UX_IMPROVEMENTS.md` manual verification checklist
  - mark items complete where validated
  - leave only truly unverified checks as pending
  - **Acceptance:** checklist reflects real verification state.

- [x] Review `docs/supabase_phone_otp_integration.md`

- [x] Review `docs/supabase_phone_google_auth_plan.md`
  - convert it into historical context and remove stale placeholder-only claims
  - add environment/provider validation notes
  - **Acceptance:** no misleading “pending” claims in a document considered active.

- [x] Clean stale behavior claims and link debt in translate docs
  - update `docs/translate-page-audit.md` and
    `docs/translate-page-implementation-plan.md` to reflect current implemented
    behavior (`Copy/Share/Save` status and provider-driven translate state).
  - verify no missing markdown targets in updated translate docs and remove
    broken/legacy path assumptions.
  - **Acceptance:** no stale transfer of implementation status in translate docs.

## P1 — Scan UX hardening follow-up checks

- [x] Add/verify a concise test matrix note in docs for **tiny landscape behavior**
  - explicitly mention target widths/heights used for overlap stress checks.
  - include failure criteria:
    - no control clipping
    - no overlap between camera controls and result panel
    - no clipped status/chip labels under status-churn conditions
  - **Acceptance:** explicit acceptance language in docs.

- [x] Link `docs` and `README` to latest known verification artifacts:
  - `qa-artifact/scan-layout-strict-overlap/report.json`
  - `qa-artifact/scan-layout-strict-overlap/scan-layout-overlap-contact-sheet.html`
  - if stale artifacts exist, include “last verified” date.
  - **Acceptance:** scan QA evidence is discoverable from docs.

## P2 — Optional cleanup / long-running backlog

- [x] Decide ownership for docs in `docs/system_audit_next_steps.md`
  - either split into:
    - in-scope items (scan/gemma work planned for this sprint), or
    - clearly labeled backlog items.
  - Decision: converted into a backlog ownership index with Immediate Backlog,
    Strategic Backlog, Verified Elsewhere, and Historical Notes sections.
  - **Acceptance:** avoids mixing “immediate” and “strategic” items.

- [x] Decide whether `docs/scanner_vision_model_audit.md` remains active
  - if active, move into implementation backlog with status and owners.
  - if superseded by scan hardening progress, archive as historical reference.
  - Decision: remains active as a partially implemented scanner/ML backlog.
    Already-implemented findings are marked separately from open model-loading
    and latency decisions.
  - **Acceptance:** no duplicate/conflicting scanner roadmaps for same area.

## Completed (already in repo from this cycle)

- [x] `lib/features/home/presentation/screens/scan_tab.dart` responsive + tiny-layout hardening updates.
- [x] `test/features/scanner/presentation/widgets/scan_tab_responsive_matrix_test.dart` overlap checks + strict tiny viewport cases.
- [x] `scripts/scan-layout-overlap-pass.ps1` added for matrix + transition captures and report integrity check.
- [x] Artifacts captured in `qa-artifact/scan-layout-strict-overlap/` with passing report JSON.
- [x] Butty prompt carousel reserves space for the floating tab control on narrow mobile screens.

## Notes

- Keep this `todo.md` synced with each PR.
- If a task is intentionally deferred, mark it in progress with a short blocker note, not delete it.
