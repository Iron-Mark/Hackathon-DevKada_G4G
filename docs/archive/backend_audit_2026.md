# Kudlit Backend & Architecture Audit Report

**Date:** April 30, 2026
**Target:** Supabase Configuration, Database Migrations, Clean Architecture, Cross-Platform Support

## 1. Clean Architecture Adherence

The application correctly enforces a **Feature-First Clean Architecture**, effectively decoupling domain logic from the data layer and external libraries (like Supabase).

### Domain Layer (`lib/features/**/domain/`)
- Interfaces like `AuthRepository` depend only on pure Dart (`fpdart` for `Either` types, custom `Failure` and entity classes like `AuthUser`, `SignUpStatus`).
- **Validation:** No Flutter or Supabase SDK dependencies are present in the domain layer. This strictly adheres to the architecture guidelines.

### Data Layer (`lib/features/**/data/`)
- `AuthRepositoryImpl` successfully acts as an adapter, mapping `ServerException` to domain `Failure` instances.
- Data Sources (`SupabaseAuthDatasourceImpl`, `SupabaseAiModelsDatasourceImpl`) encapsulate all `SupabaseClient` interactions.
- `AuthUserModel.fromSupabaseUser()` is used to translate the third-party `User` object into an internal model, protecting the domain from vendor lock-in.

---

## 2. Supabase Configuration (`config.toml`)

- **Postgres Version:** Set to `17`, which provides access to modern Postgres optimizations.
- **Connection Pooler:** Enabled in `transaction` mode with a `default_pool_size` of 20 and `max_client_conn` of 100. This is best practice for serverless or highly concurrent applications.
- **Auth URLs:** `site_url` and `additional_redirect_urls` are correctly populated for cross-platform deep-linking (`kudlit://auth/reset`, `http://localhost:3000`).
- **⚠️ Action Required - Phone Auth:** The recent `PR_AUTH_SCANNER_UX_IMPROVEMENTS.md` and plans indicate phone OTP integration, but in `config.toml`, `[auth.sms]` `enable_signup = false` and `[auth.mfa.phone]` is disabled. Ensure these are enabled in the Supabase Dashboard and config before launching SMS features.

---

## 3. Postgres SQL & Database Migrations (Best Practices)

The database schema reflects a strong understanding of Postgres optimizations and Supabase security guidelines.

### Row Level Security (RLS)
- RLS is explicitly enabled on all public tables (`profiles`, `baybayin_models`).
- Policies are scoped and specific:
  - `profiles`: Users can strictly `SELECT` and `UPDATE` where `auth.uid() = id`.
  - `baybayin_models`: Publicly readable (`USING (true)`).
- **Validation:** Adheres perfectly to `security-rls-basics.md`. No exposed tables without RLS.

### Security Definer Functions
- The trigger functions (`handle_new_user`, `handle_updated_at`) are declared with `SECURITY DEFINER SET search_path = ''`.
- **Validation:** This is a crucial security best practice to prevent malicious users from overriding functions in the public schema and hijacking the execution context.

### Indexing & Query Performance
- An index was originally created on `(sort_order)` in `baybayin_models`.
- A later migration added an optimized composite index: `CREATE INDEX baybayin_models_enabled_sort_idx ON public.baybayin_models (enabled, sort_order)`.
- In `SupabaseAiModelsDatasourceImpl.dart`, the data fetch query is:
  ```dart
  .from('baybayin_models')
  .select()
  .eq('enabled', true)
  .order('sort_order', ascending: true);
  ```
- **Validation:** The query perfectly hits the composite index, avoiding sequential scans. This aligns beautifully with the `query-composite-indexes.md` best practice.

---

## 4. Cross-Platform Compatibility (Web, Mobile, iOS)

- **OAuth Redirects:** The `SupabaseAuthDatasourceImpl` handles redirects safely using the `kIsWeb` flag:
  - Native (iOS/Android): uses the `kudlit://` deep link scheme.
  - Web: dynamically uses `${Uri.base.origin}` to construct the redirect URL.
- **Platform-Specific ML Models:** The `baybayin_models` schema was extended with `android_model_link` and `ios_model_link`. This correctly accounts for the different ML formats required across OS runtimes (e.g., TFLite vs. CoreML), allowing the app to fall back to the generic `model_link` if needed.

---

## 5. Profile Management First-Wave Integration Status

The first-wave Profile Management surface is now scaffolded in
`SettingsScreen` using existing design-system components (`SettingsCard`,
`SettingsSectionLabel`, `SettingsDivider`, `RowIcon`) and remains aligned with
feature-first clean architecture boundaries.

### Implemented UI Surface (Current first wave)
- Edit profile identity
- Learning progress dashboard
- Scanner history
- Translator history and bookmarks
- Accessibility options
- Privacy controls
- Account deletion flow
- About app
- Version display

### Backend Readiness Classification
- **Included in migration:** user preferences, learning progress, scan history,
  translation history/bookmarks, avatar storage policies.
- **Not in this wave by request:** phone number management and password/security
  center UI entries.

### Required Backend Tasks Before Enabling Production Actions
1. Add/verify backend-safe account mutation endpoints:
   - Change display name/avatar metadata
   - Account deletion (with token/session invalidation guarantees)
2. Add persistence layer + policies for:
   - Learning progress summary
   - Scanner history
   - Translator bookmarks/history
3. Define privacy consent storage and audit trail strategy.
4. Re-run security review for auth/session flows before removing placeholders.

---

## Conclusion

The backend architecture is in excellent shape. The separation of concerns via Clean Architecture is solid, and the SQL migrations follow strict Supabase security and indexing best practices.

**Next Steps:**
- Validate the SMS Auth Configuration in Supabase if Phone Sign-in is moving out of the placeholder phase.
- Continue utilizing the `kIsWeb` pattern as new native plugins are integrated for scanner capabilities.
