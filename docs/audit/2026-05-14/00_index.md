# Kudlit Full Audit — 2026-05-14 (Index)

Multi-agent orchestrated audit produced via `docs/kudlit_full_audit_prompt.md`. Seven specialist lanes ran in parallel; this index links to each lane's findings, the synthesis, and the executive summary.

## Start Here

- **[EXECUTIVE_SUMMARY.md](./EXECUTIVE_SUMMARY.md)** — one-page verdict, top strengths/risks, readiness call.
- **[99_top10_improvements.md](./99_top10_improvements.md)** — the prioritized ship list, severity-then-effort.

## Lane Reports

| # | Lane | File | Headline finding |
|---|---|---|---|
| 01 | UX/UI per-screen, mobile-first | [`01_ux_screens.md`](./01_ux_screens.md) | 29 screens audited (11 P0 / 34 P1 / 27 P2). Welcome card still says "Authentication is UI-only for now." despite working Supabase auth. |
| 02 | Multiplatform parity (Android / iOS / Web) | [`02_multiplatform.md`](./02_multiplatform.md) | Every `sqflite` datasource imports without a `kIsWeb` guard — web crashes on first cache hit. Live YOLO is mobile-only; web is single-frame capture. |
| 03 | Architecture & code quality | [`03_architecture.md`](./03_architecture.md) | 24 sites import `data/` from `presentation/` — clean-architecture inward-only rule systemically broken. Scanner domain has no `Either<Failure, T>` and no use cases. |
| 04 | Performance, offline-first, integrations | [`04_performance_offline.md`](./04_performance_offline.md) | `ScanTab` never disposes — PageView keeps all four tabs alive, so YOLO inference runs for the app's lifetime. The recent "pause on result" commit only gated the dispatch, not the native model. |
| 05 | Security & privacy | [`05_security_privacy.md`](./05_security_privacy.md) | `GEMINI_API_KEY` ships in the client bundle; phone OTP has no client-side rate limit; password recovery deep link has no `AuthChangeEvent.passwordRecovery` handler. |
| 06 | Accessibility | [`06_accessibility.md`](./06_accessibility.md) | 3 P0 WCAG AA contrast failures; primary profile/mic buttons have zero semantic labels; zero widgets honor `MediaQuery.disableAnimations`. |
| 07 | Navigation, IA & visual language | [`07_nav_ia_visual.md`](./07_nav_ia_visual.md) | Two 4-tab navs coexist — one live (`FloatingTabNav`), one orphaned (`AppBottomNav` + `HomeTab` + `ProfileTab`). `/admin/stroke-recorder` is reachable by any signed-in user. |

## How this audit was produced

The orchestrator ran in three phases per `docs/kudlit_full_audit_prompt.md`:

1. **Phase A (parallel)** — 3 Explore subagents mapped surface, data/integrations, and design system in one fan-out.
2. **Phase B (parallel)** — 7 lane auditors ran in a single fan-out, each writing its own markdown.
3. **Phase C (synthesis)** — a Plan subagent drafted the Top-10; the lead wrote this index and the executive summary.

Every finding cites `file_path:line`. No fabricated metrics. Prior audits in `docs/` were reconciled per each lane's Methods footer.

## What's NOT included

- No performance numbers (frame rate, bundle size, memory) — would require a profiling run.
- No browser-specific manual QA — findings come from code review and platform-branch tracing.
- No live Supabase RLS policy verification — code-side assumptions are flagged for backend review.
