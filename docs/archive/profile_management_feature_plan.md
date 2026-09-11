# Profile Management Feature Plan (Top 20)

## Scope
Authenticated profile-management experience for Kudlit, aligned with current
project surfaces (`SettingsScreen`, `ProfileTab`, Auth + Learn + Scan +
Translate flows).

## Current Baseline
Current profile/settings support is limited to:
- Account identity display (`UserTile`)
- App theme preference
- AI processing preference (local/cloud)
- Sign out

## Prioritization Rubric
Each feature is ranked by:
1. User value and frequency of use
2. Security/privacy impact
3. Reuse of existing project capabilities
4. Implementation readiness in current architecture

## Top 20 Features, Options, and Buttons

| # | Feature | Main options/buttons | Functionality + use case | Antithesis (why not yet) | Synthesis |
|---|---|---|---|---|---|
| 1 | Edit profile identity | **Edit Name**, **Save**, **Cancel** | Update display name/avatar. Use case: learner wants recognizable account identity. | Low immediate impact vs. core learning flow. | Ship in MVP; low risk and high visibility. |
| 2 | Phone number management | **Add Phone**, **Verify OTP**, **Change Number**, **Remove Phone** | Bind phone auth to account and allow updates. Use case: migrate from email-only to phone login. | OTP/SMS setup and abuse controls needed. | MVP if OTP infra is stable; otherwise next wave. |
| 3 | Email management | **Change Email**, **Send Verification**, **Resend**, **Confirm** | Change account email safely. Use case: user loses old email access. | Confirmation and rollback flow complexity. | Next wave after basic profile edits. |
| 4 | Password & security center | **Change Password**, **Forgot Password**, **Sign out all devices** | Centralize credential security actions. Use case: suspected account compromise. | Requires robust session handling across devices. | MVP for change password; global sign-out next wave. |
| 5 | Linked sign-in methods | **Link Google**, **Link Phone**, **Unlink**, **Set Primary** | Manage multi-provider login. Use case: avoid lockout by having backup sign-in methods. | Provider-linking edge cases and conflict handling. | Next wave; high account safety value. |
| 6 | Session/device activity | **View Devices**, **Revoke Device**, **Revoke All** | Show active sessions and allow revocation. Use case: remove unknown device access. | Needs session metadata and secure revocation UX. | Next wave; security-focused. |
| 7 | Learning progress dashboard | **View Progress**, **Continue Lesson**, **Reset Progress** | Show completion by lesson/mode. Use case: resume Baybayin learning path quickly. | Requires reliable progress persistence model. | MVP for read-only dashboard; reset later. |
| 8 | Lesson achievements & streaks | **View Achievements**, **Share**, **Hide from Profile** | Surface motivation stats (streaks, milestones). Use case: retention through visible progress. | Gamification may distract from core utility. | Next wave behind optional visibility toggle. |
| 9 | Scanner history | **View Scans**, **Re-run Translation**, **Delete Item**, **Clear History** | Keep prior scan results and revisit them. Use case: compare old/new readings. | Storage growth and privacy considerations. | MVP with local history + clear/delete controls. |
| 10 | Translator history/bookmarks | **Save Translation**, **Bookmark**, **Search History**, **Delete** | Personal translation memory and quick recall. Use case: frequent phrase reuse. | Needs query/index strategy and retention policy. | MVP with basic saved items; search next wave. |
| 11 | AI model preference center | **AI Mode (Local/Cloud)**, **Select Model**, **Model Info** | Expand current AI preference into a full model center. Use case: choose speed vs quality/cost. | More settings can overwhelm casual users. | MVP with simple defaults; advanced options collapsed. |
| 12 | Downloaded model management | **Download Models**, **Update**, **Delete Local Models**, **Storage Usage** | Control on-device model assets. Use case: reclaim storage or update quality. | Platform-specific file handling complexity. | Next wave after model setup stabilizes. |
| 13 | Notification preferences | **Lesson Reminders**, **Streak Alerts**, **Product Updates**, **Mute All** | Fine-grained push/email reminder controls. Use case: personalized engagement without spam. | Notification infra may be incomplete today. | Next wave once messaging pipeline exists. |
| 14 | Language and locale settings | **App Language**, **Regional Format**, **Baybayin Learning Locale** | User-facing language personalization. Use case: Filipino/English learning preference. | Requires i18n coverage beyond profile surface. | Later wave; start with limited locale options. |
| 15 | Accessibility profile options | **Text Size**, **High Contrast**, **Reduced Motion**, **Haptic Toggle** | Personalized accessibility experience. Use case: low vision / sensory sensitivity support. | Broad UI audit needed beyond profile screen. | MVP for text + contrast, then expand. |
| 16 | Privacy controls and consent | **Data Sharing Toggle**, **Analytics Opt-out**, **Consent History** | Let users manage privacy decisions directly. Use case: trust and regulatory alignment. | Legal/product policy dependencies. | MVP with analytics toggle + consent view. |
| 17 | Data export and account portability | **Export My Data**, **Download JSON/CSV**, **Request Archive** | User can retrieve personal learning/history data. Use case: ownership and backup. | Export scope and security hardening required. | Later wave; compliance-driven milestone. |
| 18 | Account deletion flow | **Delete Account**, **Type Confirmation**, **Final Delete** | Safe irreversible deletion with warnings. Use case: privacy rights and account cleanup. | Must handle cascade deletion and token invalidation. | MVP required for trust/compliance, with guardrails. |
| 19 | Help and support hub | **FAQ**, **Report Issue**, **Contact Support**, **View Status** | Central support access from profile/settings. Use case: unblock auth/profile issues quickly. | Support backend/process may be early stage. | MVP with FAQ + issue reporting link. |
| 20 | Public/Shareable learner profile (optional) | **Public Profile Toggle**, **Share Link**, **Hide Stats** | Optional social layer for achievements/progress. Use case: community motivation. | Not essential for core translator/scanner utility. | Later wave, strictly opt-in. |

## Avatar Upload Implementation Notes

- Avatar upload is wired through `image_picker` gallery selection for Web,
  iOS, and Android.
- Selected image bytes are uploaded to the public Supabase Storage `avatars`
  bucket under the signed-in user's folder, then saved to `profiles.avatar_url`
  and auth user metadata.
- Platform setup required:
  - Android declares `READ_MEDIA_IMAGES` and legacy
    `READ_EXTERNAL_STORAGE` for gallery selection.
  - iOS declares `NSPhotoLibraryUsageDescription` for photo-library access.

## Recommended Rollout Phases

### MVP (ship first)
1. Edit profile identity
2. Phone number management (if OTP infra is ready)
3. Password & security center (core actions)
4. Learning progress dashboard (read-only)
5. Scanner history
6. Translator history/bookmarks
7. AI model preference center
8. Accessibility baseline (text size + contrast)
9. Privacy controls baseline
10. Account deletion flow

### Next wave
1. Linked sign-in methods
2. Session/device activity
3. Email management
4. Achievements/streaks
5. Downloaded model management
6. Notification preferences
7. Help and support hub

### Later wave
1. Language/locale expansion
2. Data export and portability
3. Public/shareable learner profile

## Profile Management Screen Information Architecture

Suggested sections for the profile-management screen:
1. **Identity** (avatar, name, email/phone summary)
2. **Security** (password, linked methods, sessions, deletion)
3. **Learning Data** (progress, streaks, scan/translation history)
4. **AI & Models** (local/cloud mode, selected model, model storage)
5. **Preferences** (theme, language, accessibility, notifications)
6. **Privacy & Support** (consent, data controls, help/report issue)

## Implementation Notes
- Reuse current `SettingsScreen` composition pattern (`section + card + row`).
- Keep initial release focused on high-frequency user actions and account
  security.
- Prefer incremental rollout with feature flags for higher-risk actions
  (link/unlink auth methods, session revocation, deletion).
