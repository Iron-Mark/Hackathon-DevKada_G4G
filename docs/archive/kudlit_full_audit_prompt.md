# Kudlit — Full-Project Multiplatform Audit Prompt (Multi-Agent Edition)

> Hand this entire markdown file to a Claude Code session (or any agent host with parallel subagent support) pointed at the Kudlit repository. The orchestrating model will fan out to **parallel specialist subagents** — one per audit lane — and emit a **suite of focused markdown reports** (one per lane plus a synthesis index), not a single mega-document. Paste verbatim. Repo root is assumed to be `/Users/kuya/Documents/Gemma/kudlit-app` or the equivalent on the host machine.

---

## 0. TL;DR for the Orchestrator

1. You are the **lead auditor**. You do not write findings yourself — you **orchestrate specialist subagents** and **synthesize** their outputs.
2. Spawn **multiple subagents in parallel** (single message, multiple `Agent` tool calls). Each subagent owns one **lane** from §5.
3. Each subagent writes **its own markdown file** under `docs/audit/<YYYY-MM-DD>/`. You never paste their full output into your own messages — you only summarize.
4. After all lanes return, run a **synthesis pass** that produces `00_index.md`, `99_top10_improvements.md`, and `EXECUTIVE_SUMMARY.md`.
5. Use parallelism aggressively. The audit should complete in roughly the time of the slowest lane, not the sum.

---

## 1. Role & Mission

You are a **senior multiplatform product audit lead** with the combined lens of a UX/product designer, principal Flutter engineer (Clean Architecture · Riverpod codegen · GoRouter · platform channels), and on-device ML / offline-first specialist.

Your mission: produce an **honest, prioritized, evidence-backed audit suite** of the Kudlit Flutter codebase across Android, iOS, and Web — delivered as a **set of focused markdown files** that engineers and designers can pick up independently.

No filler. No balance-padding. Every claim cites `file_path:line`. You are writing for the product owner and the engineering lead.

---

## 2. Project Snapshot

**Kudlit** is a vision-based **Baybayin** (ancient Philippine script) translator and learning app. On-device **YOLO (TFLite)** for character recognition, **Gemma 4** (local via `flutter_gemma`, cloud fallback) for language. Targets Android, iOS, Web. **Mobile-first** UI/UX.

Stack: Flutter · Riverpod (`@riverpod` codegen) · GoRouter · Supabase (auth + sync) · SQLite + Hive (offline cache) · `ultralytics_yolo` + TFLite · `flutter_gemma`.

Conventions live in `CLAUDE.md` at the repo root — **respect them**. Flag deviations explicitly rather than rewriting style.

---

## 3. Orchestration Model — multi-agent, parallel, skill-driven

This prompt is designed to run inside an agentic host (e.g., Claude Code with the `Agent` tool, or any equivalent that supports parallel subagent spawning and Skills). The lead model orchestrates; specialist subagents do the reading and writing.

### 3.1 Subagent types to use

Map the work to the agent types the host exposes. With Claude Code these are the defaults; substitute equivalents on other hosts:

| Subagent type | Used for |
|---|---|
| **Explore** | Read-only codebase reconnaissance — locate files, grep symbols, map call graphs. Cheap, fast, parallelizable. |
| **general-purpose / claude** | Lane auditors. Each owns one lane from §5, reads its files, and writes its lane markdown. |
| **Plan** | The synthesis pass — folds lane outputs into the Top-10 and Executive Summary. |
| **ui-ux-pro-max** (Skill) | Invoked by the UX lane auditor for design heuristics, palette/accessibility checks, and platform-idiom guidance. |
| **review** / **security-review** (Skill) | Invoked by the Architecture and Security lanes respectively. |

### 3.2 Parallelism rules (HARD requirements)

- **Reconnaissance fan-out:** in a **single message**, spawn **3 Explore subagents in parallel** (§4.1). Do not run them sequentially.
- **Lane fan-out:** in a **single message**, spawn **all 7 lane auditors in parallel** (§5). Do not stagger them.
- **No duplicate reads in the lead:** once a subagent is researching a file, the lead does not also read it. Trust the report.
- **Idempotent writes:** each subagent writes to its assigned filename in §6 — never to another lane's file.
- **No cross-talk:** subagents do not call each other. The lead is the only synchronization point.
- **Cite-or-omit:** if a subagent cannot find concrete evidence for a claim, it drops the claim. No hand-waving.

### 3.3 Skills (Obra-style superskills)

Where the host exposes Skills (e.g., Claude Code's `Skill` tool — `ui-ux-pro-max`, `review`, `security-review`, `simplify`, `claude-api`), the **lane auditor must invoke the relevant Skill before writing its report**. The Skill output is treated as a co-author and cited in the lane file's "Methods" footer. Example mappings:

- UX lane → invoke `ui-ux-pro-max` (Flutter stack, mobile app project type, dark/light considerations).
- Architecture lane → invoke `review`.
- Security & Privacy lane → invoke `security-review`.
- Code-smell sweep → invoke `simplify`.
- Any Gemma API code touched → invoke `claude-api`.

If a Skill is unavailable on the host, the lane proceeds without it and notes "Skill unavailable" in its Methods footer.

---

## 4. Workflow

### 4.1 Phase A — Reconnaissance (parallel, 3 Explore subagents in ONE message)

Spawn these three Explore subagents in a single message. Each returns a structured inventory; the lead merges them into a working map.

1. **Explore-A — Surface map.** List every screen under `lib/features/**/presentation/screens/`, every route in `lib/app/router/app_router.dart`, and the floating tab nav (`AppTab` enum). Return file paths only.
2. **Explore-B — Data & integration map.** Catalog every datasource under `lib/features/**/data/datasources/` (Supabase, SQLite, Hive, local/cloud Gemma, YOLO, TFLite web). Note `kIsWeb` branches and platform splits.
3. **Explore-C — Design system & shared chrome.** Map `lib/core/design_system/*`, shared widgets (`kudlit_auth_shell`, `kudlit_home_placeholder`, `kudlit_loading_indicator`, `floating_tab_nav`, app header), Riverpod providers used app-wide, and theming.

The lead consolidates the three outputs into a single in-memory inventory. **The lead does not write files in Phase A.**

### 4.2 Phase B — Lane audits (parallel, ALL lanes in ONE message)

Spawn every lane in §5 in a single message. Each lane is a self-contained subagent that:

1. Reads only the files in its lane's "Scope" list (plus prior audits relevant to it from §8).
2. Invokes its assigned Skill if available.
3. Writes its lane markdown to `docs/audit/<YYYY-MM-DD>/<NN>_<lane>.md` using the schema in §7.
4. Returns a ≤200-word summary to the lead, naming P0/P1 counts and the lane's single biggest risk.

### 4.3 Phase C — Synthesis (Plan agent + lead)

After all lanes return:

1. Spawn one **Plan** subagent to draft `99_top10_improvements.md` by reading the lane files and producing a sorted Top-10 table.
2. The lead writes `00_index.md` (the navigation hub) and `EXECUTIVE_SUMMARY.md` (one page).
3. The lead verifies §9 acceptance criteria. If a lane file is missing or under-cited, re-spawn that lane only.

---

## 5. The Seven Audit Lanes

Each lane is owned by exactly one subagent. The subagent's prompt is the **Charter** verbatim — copy it into the `Agent` call's `prompt` field.

### Lane 1 — UX/UI per-screen, mobile-first
- **Output file:** `docs/audit/<DATE>/01_ux_screens.md`
- **Skill:** `ui-ux-pro-max` (stack: Flutter, project: mobile app)
- **Scope:** every screen in §6.1.
- **Charter:**
  > You are the UX lane auditor for Kudlit. Read each screen in the list, plus its immediate providers and extracted widgets. Invoke the `ui-ux-pro-max` Skill once at the start. For each screen, produce a per-screen block using the schema in §7.A. Evaluate: visual hierarchy, touch targets (≥44 px), thumb-zone reachability, copy quality, loading/empty/error/offline states, motion purpose, accessibility (contrast, semantics, font-scale), onboarding clarity. Cite `file_path:line` for every claim. Do not assess architecture or performance — that's other lanes. Write your report to `docs/audit/<DATE>/01_ux_screens.md`. Return ≤200-word summary.

### Lane 2 — Multiplatform parity (Android / iOS / Web)
- **Output file:** `docs/audit/<DATE>/02_multiplatform.md`
- **Scope:** every `kIsWeb` branch, every web-specific datasource, every native-only capability.
- **Charter:**
  > You are the Multiplatform Parity lane auditor. Grep the codebase for every `kIsWeb` branch and every file matching `web_*` or `*_web.dart`. Produce a Parity Matrix (feature × Android × iOS × Web) covering camera, torch, local Gemma, cloud Gemma, YOLO inference, file picker, deep links, OAuth, phone OTP, voice/speech, SQLite, Hive. Mark each cell ✅ full, ⚠ degraded, ❌ missing, and cite `file_path:line`. Call out responsive-layout failures, SafeArea/notch issues, keyboard handling, and platform-idiom mismatches (iOS HIG vs Material 3 vs Web). Output to `docs/audit/<DATE>/02_multiplatform.md` per §7.B.

### Lane 3 — Architecture & code quality
- **Output file:** `docs/audit/<DATE>/03_architecture.md`
- **Skill:** `review` (plus `simplify` if available)
- **Scope:** Clean Architecture boundaries, Riverpod conventions, widget rules from `CLAUDE.md`.
- **Charter:**
  > You are the Architecture lane auditor. Invoke the `review` Skill once at the start. Verify (a) `domain/` has zero Flutter imports, (b) `presentation/` never imports concrete repositories, (c) every provider uses `@riverpod` codegen, (d) `build()` is ≤40 lines everywhere, (e) no `_buildSomething()` private builders are used to decompose UI, (f) widgets contain no business logic. List every violation with `file_path:line`. Note test coverage gaps per feature. Output to `docs/audit/<DATE>/03_architecture.md` per §7.B.

### Lane 4 — Performance, offline-first, integrations
- **Output file:** `docs/audit/<DATE>/04_performance_offline.md`
- **Scope:** model loaders, inference cadence, camera lifecycle, Supabase sync, SQLite cache-first patterns, Gemma fallback, chat memory two-layer.
- **Charter:**
  > You are the Performance & Offline lane auditor. Trace: when each model loads, whether warm-up blocks the UI thread, inference cadence on `scan_tab`, camera open/pause/dispose semantics, Supabase write retry/optimistic patterns, SQLite cache-then-network in each repository, Gemma local↔cloud fallback boundaries, and the Butty chat memory sliding window + "Start fresh" behavior. Cite `file_path:line` for every observed pattern. Do NOT fabricate timings — describe risk qualitatively unless you have a measured number. Output to `docs/audit/<DATE>/04_performance_offline.md` per §7.B.

### Lane 5 — Security & Privacy
- **Output file:** `docs/audit/<DATE>/05_security_privacy.md`
- **Skill:** `security-review`
- **Scope:** auth flows, token handling, deep-link safety, Supabase RLS assumptions, PII in logs, on-device vs cloud data flow.
- **Charter:**
  > You are the Security & Privacy lane auditor. Invoke the `security-review` Skill once at the start. Audit: auth token storage, refresh handling, password reset deep-link validation, phone OTP rate-limiting assumptions, Google OAuth redirect URIs, Supabase RLS assumptions (note where the code assumes RLS without verifying), PII leakage in logs (`debugPrint`, `print`, `Logger`), and the data residency of Gemma cloud calls. Cite `file_path:line`. Output to `docs/audit/<DATE>/05_security_privacy.md` per §7.B.

### Lane 6 — Accessibility
- **Output file:** `docs/audit/<DATE>/06_accessibility.md`
- **Skill:** `ui-ux-pro-max` (re-invoke with topic: accessibility)
- **Scope:** every interactive screen.
- **Charter:**
  > You are the Accessibility lane auditor. Sample contrast on the design tokens in `lib/core/design_system/kudlit_colors.dart` and the major screens. Check semantic labels on icon buttons, touch target minimums, font-scale tolerance, keyboard/focus order on web, and any motion that ignores `MediaQuery.disableAnimations`. List every gap with `file_path:line`. Output to `docs/audit/<DATE>/06_accessibility.md` per §7.B.

### Lane 7 — Navigation, IA & Visual Language
- **Output file:** `docs/audit/<DATE>/07_nav_ia_visual.md`
- **Scope:** `app_router.dart`, the 4-tab floating nav, guest-mode boundary, deep links, visual consistency across the ocean-themed Learn tab vs the rest.
- **Charter:**
  > You are the Navigation, IA & Visual Language lane auditor. Map every route and its auth guard from `lib/app/router/app_router.dart`. Validate the 4-tab `AppTab` floating nav for back-stack behavior and guest-mode boundary correctness. Compare visual language across the Learn tab's ocean theme and the rest of the app — flag fragmentation. Cite `file_path:line`. Output to `docs/audit/<DATE>/07_nav_ia_visual.md` per §7.B.

---

## 6. Screen & File Inventory the lanes must respect

### 6.1 Screen inventory (the UX lane covers ALL of these)

**Splash & setup**
- `lib/features/home/presentation/screens/splash_screen.dart`
- `lib/features/home/presentation/screens/model_setup_screen.dart`

**Auth**
- `lib/features/auth/presentation/screens/auth_welcome_screen.dart`
- `lib/features/auth/presentation/screens/sign_in_screen.dart`
- `lib/features/auth/presentation/screens/login_screen.dart`
- `lib/features/auth/presentation/screens/sign_up_screen.dart`
- `lib/features/auth/presentation/screens/phone_sign_in_screen.dart`
- `lib/features/auth/presentation/screens/phone_otp_screen.dart`
- `lib/features/auth/presentation/screens/forgot_password_screen.dart`
- `lib/features/auth/presentation/screens/reset_password_screen.dart`
- `lib/features/auth/presentation/screens/terms_screen.dart`
- `lib/features/auth/presentation/screens/privacy_policy_screen.dart`

**Home shell + tabs**
- `lib/features/auth/presentation/screens/home_screen.dart`
- `lib/features/home/presentation/screens/home_tab.dart`
- `lib/features/home/presentation/screens/scan_tab.dart`
- `lib/features/home/presentation/screens/translate_screen.dart`
- `lib/features/home/presentation/screens/learn_tab.dart` (+ `learn_home_body.dart`)
- `lib/features/home/presentation/screens/butty_chat_screen.dart`
- `lib/features/home/presentation/screens/profile_tab.dart`

**Profile, history & internal**
- `lib/features/home/presentation/screens/settings_screen.dart`
- `lib/features/home/presentation/screens/translation_history_screen.dart`
- `lib/features/home/presentation/screens/learning_progress_screen.dart`
- `lib/features/home/presentation/screens/butty_data_screen.dart`
- `lib/features/scanner/presentation/screens/scan_history_screen.dart`

**Learning depth**
- `lib/features/learning/presentation/screens/lesson_stage_screen.dart`
- `lib/features/learning/presentation/screens/character_gallery_screen.dart`
- `lib/features/learning/presentation/screens/quiz_screen.dart`

**Admin / internal**
- `lib/features/admin/presentation/screens/stroke_recording_screen.dart`

**Cross-cutting widgets**
- `lib/features/home/presentation/widgets/floating_tab_nav.dart` (`AppTab` enum)
- App header(s), `kudlit_auth_shell.dart`, `kudlit_home_placeholder.dart`, `kudlit_loading_indicator.dart`

**Routing & design tokens**
- `lib/app/router/app_router.dart`
- `lib/core/design_system/kudlit_theme.dart`
- `lib/core/design_system/kudlit_colors.dart`

---

## 7. Output Schemas — STRICT

All lane files live under `docs/audit/<YYYY-MM-DD>/`. Use exactly these schemas.

### 7.A Per-screen block (Lane 1 only)

```markdown
### <relative/path/to/screen_file.dart> — <route or tab name>
- **Purpose:** one line.
- **Platforms reviewed:** Android · iOS · Web
- **Pros:**
  - bullet (`file_path:line`)
- **Cons:**
  - bullet (`file_path:line`)
- **Improvements:**
  - **P0** — concrete change (`file_path:line`)
  - **P1** — concrete change
  - **P2** — concrete change
- **Multiplatform notes:** any web/native divergence specific to this screen.
```

### 7.B Lane file skeleton (Lanes 2–7 and the body of Lane 1)

```markdown
# <NN> — <Lane Name>

**Auditor:** <subagent type> · **Skill invoked:** <skill or "none"> · **Date:** <YYYY-MM-DD>

## Summary
- P0 count: N
- P1 count: N
- P2 count: N
- Single biggest risk: <one line>

## Findings
<lane-appropriate sections — see each lane's charter>

## Top Recommendations (lane-local, severity-ordered)
| # | Severity | Effort | Recommendation | Evidence |
|---|---|---|---|---|
| 1 | P0 | S | ... | `file:line` |

## Methods
- Files read: <list>
- Skills invoked: <list>
- Prior audits reconciled: <list from §8>
```

### 7.C Top-10 synthesis file

`docs/audit/<DATE>/99_top10_improvements.md` — produced by the Plan agent.

```markdown
# Top 10 Prioritized Improvements

| # | Lane | Area | Severity | Effort | Recommendation | Evidence |
|---|---|---|---|---|---|---|
| 1 | UX | ... | P0 | S | ... | `file:line` |
```

Sorted by **severity ascending (P0 first), then effort ascending (S first)**.

### 7.D Index + Executive Summary

- `docs/audit/<DATE>/00_index.md` — table linking to every lane file, the Top-10, and the Executive Summary, with one-line hooks.
- `docs/audit/<DATE>/EXECUTIVE_SUMMARY.md` — one page. Top 3 strengths, top 5 risks, overall readiness (`ship-ready` | `needs-polish` | `needs-rework`), one-paragraph verdict.

Severity legend: **P0** blocks ship / data loss / broken platform · **P1** degrades a core flow · **P2** polish.
Effort legend: **S** ≤1 day · **M** 1–3 days · **L** >3 days.

---

## 8. Prior audits to reconcile (do not restate — extend)

The lanes must read and reference these as prior art:

- `system_audit.md`, `system_audit_next_steps.md`
- `backend_audit_2026.md`, `backend_audit_2026-05-05.md`
- `gemma_offline_model_loading_audit.md`
- `scanner_vision_model_audit.md`
- `butty_chat_memory_ai_audit.md`, `butty_chat_memory_and_sync_plan.md`
- `gemma_learning_architecture.md`, `gemma_learning_implementation_plan.md`
- `translate-page-audit.md`, `translate-page-implementation-plan.md`
- `profile_management_feature_plan.md`, `profile_management_remote_dev_comparison.md`
- `realtime_scan_aggregator_plan.md`
- `supabase_phone_otp_integration.md`, `supabase_phone_google_auth_plan.md`
- `auth_polish_updates.md`, `kudlit_design_and_setup.md`
- `design-improvement-evidence-pack.md`, `jam_the_dev_review_notes.md`, `jam-updates.md`

Each lane lists in its **Methods** footer which of these it reconciled against.

---

## 9. Ground Rules (all subagents + lead)

1. **Read the actual code.** Never hallucinate paths, functions, or line numbers.
2. **Cite everything.** Every con / improvement bullet ends with `file_path:line`. If no evidence, drop the claim.
3. **Respect `CLAUDE.md`.** Flag deviations rather than recommending wholesale rewrites to a different style.
4. **No fabricated metrics.** No invented frame rates, bundle sizes, or memory numbers. Describe risk qualitatively when unmeasured.
5. **No vague advice.** Every "improvement" names (a) the screen/symbol, (b) the observed behavior, (c) the concrete change.
6. **No cross-talk between subagents.** Lead synchronizes; subagents don't call each other.
7. **One file per lane.** Never edit another lane's file.
8. **Idempotent re-runs.** Re-spawning a lane overwrites only its own file.

---

## 10. Acceptance Criteria

The audit suite is acceptable **only if all of the following are true**:

- [ ] Directory `docs/audit/<YYYY-MM-DD>/` exists with all of: `00_index.md`, `01_ux_screens.md`, `02_multiplatform.md`, `03_architecture.md`, `04_performance_offline.md`, `05_security_privacy.md`, `06_accessibility.md`, `07_nav_ia_visual.md`, `99_top10_improvements.md`, `EXECUTIVE_SUMMARY.md`.
- [ ] `01_ux_screens.md` contains a per-screen block for **every** screen in §6.1.
- [ ] `02_multiplatform.md` contains a Parity Matrix listing every native-only or web-only capability found in the code.
- [ ] Every con and every improvement across every lane file cites at least one `file_path:line`.
- [ ] `99_top10_improvements.md` is sorted by severity then effort and every row has an Evidence column with a real `file:line`.
- [ ] `EXECUTIVE_SUMMARY.md` states a concrete readiness verdict.
- [ ] No fabricated paths, functions, or measurements appear anywhere.
- [ ] Prior audits in §8 are referenced (in each lane's Methods footer) rather than restated.

If a criterion cannot be satisfied for a legitimate reason (e.g., a screen file does not exist), state so explicitly in the relevant file and continue — never silently drop a section.

---

## 11. Begin

Acknowledge in one line that you have read this prompt and `CLAUDE.md`. Then:

1. Run **Phase A** by spawning the **3 Explore subagents in a single message** (§4.1).
2. After they return, run **Phase B** by spawning **all 7 lane auditors in a single message** (§4.2, §5).
3. After they return, run **Phase C** (§4.3) and verify §10.

Do not write findings yourself outside of `00_index.md` and `EXECUTIVE_SUMMARY.md`. Trust your subagents; verify by reading the files they produced.
