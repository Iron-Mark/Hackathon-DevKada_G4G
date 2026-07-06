## Kudlit Branch Audit (kudlit-app)

Source: `C:\Codes Local\Hackathons (Workspace)\04-24-26 - Kudlit - DevKadav2xGDG\kudlit-app`

Checked: 2026-06-14

Base: `origin/main`

### Remote Keep/Delete Matrix

| Branch | PR State | Ahead(main) | Behind(main) | Decision |
|---|---|---:|---:|---|
| feat/add-flutter-web-build | MERGED | 2 | 70 | DELETE |
| feat/admin-rbac-stroke-recorder | MERGED | 4 | 123 | DELETE |
| feat/auth-scanner-ux-improvements | MERGED | 2 | 156 | DELETE |
| feat/backend-scan-translate | MERGED | 9 | 119 | DELETE |
| feat/baybayin-chat-rendering | MERGED | 1 | 28 | DELETE |
| feat/baybayin-permutations-scanner-overlay | MERGED | 6 | 151 | DELETE |
| feat/design | MERGED | 1 | 163 | DELETE |
| feat/gemma-offline-working | MERGED | 1 | 124 | DELETE |
| feat/lessons-revision | MERGED | 18 | 121 | DELETE |
| feat/scan-offline-gemma | MERGED | 5 | 120 | DELETE |
| feat/scanner-snap-freeze | MERGED | 4 | 72 | DELETE |
| feat/supabase-auth | MERGED | 8 | 164 | DELETE |
| feat/translate-export-image | MERGED | 6 | 113 | DELETE |
| feat/translate-sticky-input-ui-overhaul | CLOSED | 4 | 112 | DELETE |
| feat/translate-update | CLOSED | 2 | 124 | DELETE |
| feat/translate-ux-redesign | MERGED | 5 | 114 | DELETE |
| feat/ui-polish-input-bars-profile-markdown | MERGED | 3 | 78 | DELETE |
| feature/intro-main-nav-flow | CLOSED | 2 | 170 | DELETE |
| fix/env-cf | CLOSED | 6 | 58 | DELETE |

### Keep

- `origin/main`
- `origin/dev`

### Justification

- No open PRs exist for this repository (`gh pr list --state open` is empty).
- All 18 remote feature/fix branches above map to merged/closed PRs and currently have no independent active dependency on `main/dev`.
- PR history is preserved in GitHub; deleting these branches is a cleanup action, not a feature-loss action.

### Completed extraction notes (this repo state)

1. `feat/baybayin-chat-rendering` was reviewed first in the wider sweep. Cherry-pick conflicts were resolved conservatively by keeping current `dev` behavior where it already included equivalent functionality. No runtime regression was introduced; conflict resolution was committed as docs-only.

2. `feat/gemma-offline-working` conflict sweep similarly retained existing `dev` logic and only added `docs/translate-page-audit.md` for traceability.
