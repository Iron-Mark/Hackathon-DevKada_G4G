# Profile Management Branch Comparison vs `origin/dev`

**Branch:** `profile-management`  
**Base compared:** `origin/dev`

## Summary

This document captures the current local delta in `profile-management` against
remote `dev` (`origin/dev`) before push.

## Tracked changes vs `origin/dev`

| Status | File |
|---|---|
| M | `docs/PR_AUTH_SCANNER_UX_IMPROVEMENTS.md` |
| M | `docs/superpowers/specs/2026-04-25-auth-polish-design.md` |
| M | `lib/features/auth/data/datasources/supabase_auth_datasource.dart` |
| M | `lib/features/auth/data/repositories/auth_repository_impl.dart` |
| M | `lib/features/auth/domain/repositories/auth_repository.dart` |
| A | `lib/features/auth/domain/usecases/send_phone_otp.dart` |
| A | `lib/features/auth/domain/usecases/verify_phone_otp.dart` |
| M | `lib/features/auth/presentation/providers/auth_notifier.dart` |
| M | `lib/features/auth/presentation/screens/phone_otp_screen.dart` |
| M | `lib/features/auth/presentation/screens/phone_sign_in_screen.dart` |
| M | `lib/features/auth/presentation/widgets/auth_button.dart` |
| M | `lib/features/auth/presentation/widgets/auth_submit_button.dart` |
| M | `lib/features/home/presentation/screens/settings_screen.dart` |
| M | `lib/features/home/presentation/widgets/settings/preferences_section.dart` |
| A | `test/features/auth/domain/usecases/send_phone_otp_test.dart` |
| A | `test/features/auth/domain/usecases/verify_phone_otp_test.dart` |

## Untracked local additions (not yet in Git)

- `docs/backend_audit_2026.md`
- `docs/profile_management_feature_plan.md`
- `docs/supabase_phone_otp_integration.md`
- `lib/core/design_system/widgets/kudlit_loading_indicator.dart`
- `lib/features/home/presentation/widgets/settings/about_section.dart`
- `lib/features/home/presentation/widgets/settings/profile_management_action_button.dart`
- `lib/features/home/presentation/widgets/settings/profile_management_item.dart`
- `lib/features/home/presentation/widgets/settings/profile_management_section.dart`
- `lib/features/home/presentation/widgets/settings/profile_management_tile.dart`
- `lib/features/home/presentation/widgets/settings/profile_management_tile_actions.dart`
- `lib/features/home/presentation/widgets/settings/profile_management_tile_header.dart`
- `lib/features/home/presentation/widgets/settings/settings_list.dart`
- `supabase/migrations/20260429190336_create_avatars_bucket.sql`
- `supabase/migrations/20260429194407_profile_management_tables.sql`

## Notes for push preparation

- UI scope reflects your latest direction:
  - Removed phone/password items from profile management section.
  - Added About + Version section.
  - Removed status-chip labeling from profile tiles.
  - Removed AI row from Settings preferences.
- Supabase migration dry-run was successful and includes:
  - `20260429194407_profile_management_tables.sql`
