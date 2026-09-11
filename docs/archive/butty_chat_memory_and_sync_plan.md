# Butty Chat: Offline-First Memory & Sync Plan

> Status: Approved — implementation in progress
> Owner: Backend / chat feature
> Date: 2026-05-05

## Context

The Butty chat is the AI companion feature in Kudlit (`lib/features/translator/` for data + `lib/features/home/presentation/butty_chat_*` for UI). Today it persists messages to local SQLite (`kudlit_chat.db`) only — no cloud sync, no per-user memory, no profile awareness. Every Gemma inference call dumps the entire flat chat history with a static `assistantMode` system prompt.

This plan adds:

1. **Cloud sync** — chat history backed up to Supabase, restored on fresh install (mirroring `scan_history` and `translation_history`).
2. **Long-term memory** — Butty remembers facts across sessions ("user prefers Tagalog explanations", "user is learning the consonants") and injects them into future conversations as context, instead of relying only on raw history.
3. **Bounded context** — switch from full-history dump to a sliding window + memory facts to avoid context-window blow-up.

**Confirmed product decisions:**

- **Single ongoing thread** + memory layer (no per-session sidebar). A "Start fresh" action clears visible history but preserves memory facts.
- **Memory extraction** runs every 4 turns AND on `AppLifecycleState.paused`.

---

## Design

### Two-layer memory architecture

| Layer | Stores | Purpose |
|---|---|---|
| **Episodic** (`chat_messages`) | Raw user/Butty turns | Display, audit, recovery |
| **Semantic** (`chat_memory_facts`) | Distilled facts about user/topics | Injected into system prompt for long-term recall without context blow-up |

Sending all chat history verbatim grows unboundedly. The semantic layer keeps Butty contextually aware across hundreds of turns using only ~200 tokens of injected facts.

### Prompt structure (every Butty inference)

```
[SYSTEM]
1. assistantMode base prompt (existing — gemma_prompts.dart)
2. <profile>
   Name: {displayName}
   Lessons completed: {n}
   AI mode: {local|cloud}
   </profile>
3. <memory>
   - Prefers Tagalog explanations
   - Currently learning consonants
   - Asked about "pa" vs "ba" recently
   </memory>

[TURNS]
4. Last K=20 messages from sliding window (instead of full history)
5. New user message
```

### Sync strategy (mirror existing patterns)

- **Writes**: insert SQLite immediately → `unawaited(_syncToSupabase(...))` (same pattern as `translation_history_provider.dart:66`).
- **Reads**: SQLite first; if local empty on cold start, restore last N rows from Supabase (mirror `scan_history_provider.dart:31-53`).
- **Memory facts**: same write-through + cloud-restore pattern.
- **No connectivity package needed** — fire-and-forget tolerates offline. Supabase client retries internally; failures logged, not fatal.

### Memory extraction service

- **Trigger**: turn counter in `butty_chat_controller` (every 4 turns) + `WidgetsBindingObserver` on `AppLifecycleState.paused`.
- Runs Gemma locally with new `GemmaPrompts.memoryExtractor` system prompt that emits structured JSON facts.
- Dedupes against existing `chat_memory_facts` by normalized-string match (v1; embedding-based later).
- Persists to local SQLite + fires unawaited Supabase sync.
- No isolate needed — Gemma already streams off the UI thread.

### "Start fresh" UX

- Overflow menu in `ButtyHeader` → confirm dialog → clears `chat_messages` (local + remote soft-delete) → preserves `chat_memory_facts`.
- Banner copy: "Butty still remembers what you've talked about — facts are kept across fresh starts."

---

## Files to create / modify

### Supabase migration

- **NEW** `supabase/migrations/20260506000000_chat_history_and_memory.sql`
  - `chat_messages` (uuid pk, user_id fk, content text, is_user bool, created_at timestamptz, image_url text nullable) + RLS by user_id.
  - `chat_memory_facts` (uuid pk, user_id fk, fact_type text, content text, source_message_id uuid nullable, created_at timestamptz, last_referenced_at timestamptz) + RLS.
  - Mirror RLS policies from `20260505000000_update_history_schemas.sql`.

### Domain layer

- **NEW** `lib/features/translator/domain/entities/chat_memory_fact.dart`
- **NEW** `lib/features/translator/domain/repositories/chat_memory_repository.dart`
- **MODIFY** `lib/features/translator/domain/entities/chat_message.dart` — add `String? remoteId`.

### Data layer

- **MODIFY** `lib/features/translator/data/datasources/sqlite_chat_datasource.dart` — add `remote_id` column, schema migration, `getRecent(limit)`, `clearAll()`.
- **NEW** `lib/features/translator/data/datasources/supabase_chat_datasource.dart` — `fetchRecent(limit)`, `insert(message)`, `softDeleteAll()`.
- **NEW** `lib/features/translator/data/datasources/sqlite_chat_memory_datasource.dart`
- **NEW** `lib/features/translator/data/datasources/supabase_chat_memory_datasource.dart`
- **NEW** `lib/features/translator/data/repositories/chat_memory_repository_impl.dart` (mirror `profile_management_repository_impl.dart:19-78`).
- **MODIFY** `lib/features/translator/data/repositories/ai_inference_repository_impl.dart` — accept optional `profileBlock`/`memoryBlock` strings appended to system instruction.

### Presentation layer

- **MODIFY** `lib/features/translator/presentation/providers/chat_history_provider.dart` — cloud restore on `build()` when local empty; `clearVisible()` for "Start fresh".
- **NEW** `lib/features/translator/presentation/providers/chat_memory_provider.dart` — `AsyncNotifier<List<ChatMemoryFact>>`.
- **NEW** `lib/features/translator/presentation/providers/memory_extraction_service.dart` — `extractIfDue(turnCount)` and `extractNow()`.
- **MODIFY** `lib/features/home/presentation/providers/butty_chat_controller.dart`:
  - Send sliding window (last 20) instead of full history.
  - Build profile + memory blocks (read `profileSummaryProvider` + `chatMemoryProvider`) and pass via `systemInstruction`.
  - Increment turn counter + call `memoryExtractionService.extractIfDue(turnCount)` after each Butty response.
  - Register `WidgetsBindingObserver` for `AppLifecycleState.paused` → `extractNow()`.
- **MODIFY** `lib/features/learning/domain/entities/gemma_prompts.dart`:
  - Add `assistantModeWithContext({required String profile, required String memory})`.
  - Add `memoryExtractor` prompt that returns JSON fact array.
- **MODIFY** `lib/features/home/presentation/widgets/butty_chat/butty_header.dart` — overflow menu with "Start fresh" action.

---

## Critical reuse (do not reinvent)

| Pattern | Reference |
|---|---|
| Cache-first read + write-through invalidation | `lib/features/home/data/repositories/profile_management_repository_impl.dart:19-78` |
| Write-through + cloud-restore-on-empty | `lib/features/home/presentation/providers/translation_history_provider.dart:31-91` |
| Same pattern (second reference) | `lib/features/scanner/presentation/providers/scan_history_provider.dart:28-91` |
| RLS policy template | `supabase/migrations/20260505000000_update_history_schemas.sql` |
| Local Gemma client | `lib/features/translator/data/datasources/local_gemma_datasource.dart` |
| System prompts | `lib/features/learning/domain/entities/gemma_prompts.dart` |

---

## Implementation phases

| Phase | Scope | Ships |
|---|---|---|
| **1** | Supabase sync of raw chat (migration, supabase datasource, repo + provider for cloud restore + write-through) | History survives reinstall |
| **2** | Sliding window + profile injection (stop sending full history; inject `<profile>` block) | Bounded context, name-aware Butty |
| **3** | Memory layer (migration, repo, extraction service, lifecycle hook) | Long-term recall across "Start fresh" |
| **4** | Polish ("Start fresh" UI, settings toggle to view/clear facts, analytics) | Production polish |

Each phase ships independently. Phase 1 is the most valuable on its own.

---

## Verification

- `flutter analyze` clean.
- **Sync**: Chat → kill app → reopen → history loads from local. Clear app data → reopen → history loads from Supabase.
- **Offline**: Airplane mode → send message in local Gemma mode → reply works → reconnect → message visible in Supabase dashboard.
- **Memory**: Tell Butty "I prefer short answers in Tagalog" → continue 4 more turns → confirm `chat_memory_facts` row exists → "Start fresh" → next message: Butty still applies the preference.
- **Sliding window**: Send 30+ messages → confirm only last 20 turns sent (datasource log).
- **RLS**: Sign in as user A, send messages, sign out, sign in as user B → B sees no A messages.
- **Lifecycle extraction**: Chat 2 turns → background app → reopen → `chat_memory_facts` gained an entry.
- Migration applies cleanly: `supabase db reset` or apply via dashboard.
