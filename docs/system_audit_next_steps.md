# Kudlit System Audit Next Steps

Last reviewed: 2026-05-10

This file is now a backlog ownership index. It separates immediate technical
follow-up from longer-running product/backend decisions so this document does
not read like an active sprint plan.

## Immediate Backlog

### Phone and Google Authentication

**Owner:** Auth/backend implementation

**Status:** Active backlog. UI and planning docs exist, but provider, Supabase,
and end-to-end verification still need final implementation work.

Remaining work:

- Confirm Supabase SMS and provider configuration in the target environment.
- Finish any missing `AuthRepository` phone OTP and Google sign-in methods.
- Wire the login surfaces through `AuthNotifier` without route-level hacks.
- Verify redirect behavior after successful OAuth and OTP flows.

Reference docs:

- [supabase_phone_otp_integration.md](supabase_phone_otp_integration.md)
- [supabase_phone_google_auth_plan.md](supabase_phone_google_auth_plan.md)

### Auth Review Notes

**Owner:** Auth/data cleanup

**Status:** Active backlog.

Remaining work:

- Centralize repeated app strings into shared constants where still applicable.
- Replace boolean auth result values with explicit status enums where the code
  still needs clearer state.

Reference doc:

- [jam_the_dev_review_notes.md](jam_the_dev_review_notes.md)

## Strategic Backlog

### Profile Management Next Wave

**Owner:** Profile/backend implementation

**Status:** Strategic backlog. First-wave profile management is implemented, but
account-level capabilities need backend guarantees before UI activation.

Remaining work:

- Linked sign-in methods for Phone/Google.
- Session activity and revocation.
- Reliable learning-progress persistence before enabling writes or resets.
- Account deletion with backend session/token invalidation guarantees.

Reference docs:

- [profile_management_feature_plan.md](profile_management_feature_plan.md)
- [PR_PROFILE_MANAGEMENT_E2E.md](PR_PROFILE_MANAGEMENT_E2E.md)

### Scanner and Translator Native Capability Backlog

**Owner:** Scanner/ML implementation

**Status:** Active but partially implemented. Scanner layout hardening has been
verified separately; model-loading and offline capability work remains tracked
in dedicated audit docs.

Remaining work:

- Close the active items in [scanner_vision_model_audit.md](scanner_vision_model_audit.md).
- Keep Gemma/offline model-loading work tracked in
  [gemma_offline_model_loading_audit.md](gemma_offline_model_loading_audit.md).
- Keep scanner history and translator bookmark persistence aligned with profile
  and Supabase sync decisions.

## Verified Elsewhere

### Scan Layout Hardening

**Owner:** Scan UI QA

**Status:** Verified and no longer tracked as open work here.

Latest strict evidence:

- `qa-artifact/scan-layout-strict-overlap/report.json`
- `qa-artifact/scan-layout-strict-overlap/scan-layout-overlap-contact-sheet.html`
- `qa-artifact/scan-layout-strict-overlap/matrix/`
- `qa-artifact/scan-layout-strict-overlap/transitions/`

Latest verified timestamp: `2026-05-10T18:08:55.7427350+08:00`.

The current matrix covers `360x740`, `390x844`, `430x932`, `844x390`,
`1024x768`, plus strict tiny landscape checks at `340x260` and `320x240`.

## Historical Notes

Older wording in this file described `build_runner` and merge conflicts as
current blockers. Those claims are not treated as current work unless a fresh
verification pass reproduces them.
