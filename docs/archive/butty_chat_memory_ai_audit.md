# Butty Chat & Memory — AI Setup Audit

> Covers chat history persistence, memory extraction, and local vs cloud inference across all platforms.

---

## Architecture at a Glance

```
User sends message
  → ButtyChatController.send()
      → read AiPreference (cloud | local)
      → insert user msg → SQLite (native) / in-memory (web)
      → fire-and-forget Supabase sync
      → build system instruction (profile + 12 memory facts)
      → AiInferenceRepository.generateResponse()
            kIsWeb → always CloudGemmaDatasource (Gemini via Genkit)
            AiPreference.cloud → CloudGemmaDatasource
            AiPreference.local → LocalGemmaDatasource
                                   ↳ on any error: transparent fallback to cloud
      → stream tokens to UI
      → insert assistant msg → SQLite / in-memory
      → fire-and-forget Supabase sync
      → MemoryExtractionService.extractIfDue() (every 4 user msgs)
            → AI extracts facts → insertIfNew() → fire-and-forget Supabase
```

**Persistence by platform:**

| Platform | Chat History | Memory Facts | AI Inference |
|----------|-------------|--------------|--------------|
| Android / iOS | SQLite → Supabase | SQLite → Supabase | Local Gemma OR Cloud Gemini |
| Web | In-memory → Supabase | In-memory → Supabase | Cloud only (forced) |

---

## What's Working ✅

- **Offline-first** — SQLite is source of truth; Supabase is async mirror
- **kIsWeb guard** — forces cloud inference; swaps SQLite for `ChatHistoryWebStore` / `ChatMemoryWebStore`
- **Transparent local→cloud fallback** — `_localWithCloudFallback()` in repo catches any local model error and retries via cloud without interrupting the user
- **Cold-start restore** — empty local cache triggers Supabase fetch (last 100 msgs / 200 facts) on provider `build()`
- **Deduplication** — normalized unique index in both SQLite and Supabase prevents duplicate memory facts
- **Soft-fail sync** — all Supabase writes are `unawaited()` and non-blocking; network failures are logged only
- **Guest mode** — unauthenticated users work locally; Supabase calls silently no-op
- **Memory extraction throttle** — runs every 4 user messages, minimum 30-second interval, flushes on app pause

---

## Identified Gaps ⚠️

### Gap 1 — Failed Supabase Syncs Are Never Retried
Messages / facts with `remoteId == null` (sync failed) stay local-only indefinitely. There is no retry queue. Next device never sees them.

**Fix:** On provider `build()`, after cold-load, query SQLite for rows where `remote_id IS NULL` and re-attempt Supabase sync.  
**Files:** `sqlite_chat_datasource.dart`, `chat_history_provider.dart`, `chat_memory_repository_impl.dart`

---

### Gap 2 — Memory Extraction Uses Same AiPreference as Chat
If the user is in local mode and the model is unavailable, memory extraction silently skips. Facts are never distilled for that session.

**Fix:** Memory extraction should always call cloud for its own inference request, independent of user preference.  
**File:** `memory_extraction_service.dart` — override the preference resolver to force `AiPreference.cloud` for extraction-only calls.

---

### Gap 3 — Web: Offline Pill is a False Affordance
The mode selector shows "Offline" as a tappable option on web even though local inference is always blocked by `kIsWeb`. Tapping it sets the preference to local but inference silently falls back to cloud anyway.

**Fix:** When `kIsWeb`, disable the Offline pill with a tooltip: *"Offline model is not available on web."*  
**File:** `butty_model_mode_selector.dart`

---

### Gap 4 — Web: Blank State on Page Refresh
`ChatHistoryWebStore` and `ChatMemoryWebStore` are pure in-memory. Every page refresh starts empty. Supabase cold-load restores data on next provider `build()` but there is a visible blank window.

**Mitigation (current):** Supabase restore runs automatically.  
**Full fix:** Add `localStorage` / IndexedDB persistence layer for web.  
**Files:** `chat_history_web_store.dart`, `chat_memory_web_store.dart`

---

### Gap 5 — `imageBytes` Declared in Entity but Never Persisted (Low Priority)
`ChatMessage.imageBytes` field exists but has no SQLite column and no Supabase Storage upload path.

**Fix:** Add `imageBytes BLOB` column in SQLite v3 migration + upload to Supabase Storage for cloud sync. Only needed when image messages are exposed in UI — leave for that feature branch.  
**Files:** `sqlite_chat_datasource.dart`, `supabase_chat_datasource.dart`, `chat_message.dart`

---

## Local vs Cloud — Setup Checklist

### Online (Cloud) — Gemini via Genkit

| Item | Where | Status |
|------|-------|--------|
| `GEMINI_API_KEY` set in `.env` | `translator_providers.dart` line 68 | Must confirm in prod |
| `kIsWeb` forces cloud | `ai_inference_repository_impl.dart` line 32 | ✅ |
| Guest users skip sync | `supabase_chat_datasource.dart` line 20 | ✅ |
| All network errors non-fatal | Supabase datasources | ✅ |

**Action:** Confirm `GEMINI_API_KEY` is present in production environment variables.

---

### Local (Offline) — flutter_gemma

| Item | Where | Status |
|------|-------|--------|
| `probeReadiness()` before first use | `local_gemma_datasource.dart` | ✅ |
| Model missing → `AiLocalModelMissing` state | `ai_inference_provider.dart` | ✅ |
| Model missing → cloud fallback transparent | `ai_inference_repository_impl.dart` | ✅ |
| UI disables input when model unavailable | `butty_chat_screen.dart` | ✅ |
| Supabase `gemma_models` table has ≥1 row | Production DB | Must confirm |
| Download progress shown | `AiDownloading` state | ✅ |
| Stall detection (20 s Android) | `ai_inference_provider.dart` | ✅ |

**Action:** Ensure `gemma_models` Supabase table has at least one row with a valid download URL for the production environment.

---

## Key Files

```
lib/features/translator/
  data/datasources/
    ai_datasource.dart                     ← shared AiDatasource interface
    local_gemma_datasource.dart            ← flutter_gemma wrapper
    cloud_gemma_datasource.dart            ← Genkit / Gemini wrapper
    sqlite_chat_datasource.dart            ← native chat history (kIsWeb guard)
    sqlite_chat_memory_datasource.dart     ← native memory facts (kIsWeb guard)
    chat_history_web_store.dart            ← in-memory fallback (web)
    chat_memory_web_store.dart             ← in-memory fallback (web)
    supabase_chat_datasource.dart          ← cloud sync for chat messages
    supabase_chat_memory_datasource.dart   ← cloud sync for memory facts
  data/repositories/
    ai_inference_repository_impl.dart      ← local/cloud router + transparent fallback
    chat_memory_repository_impl.dart       ← cache-first + fire-and-forget sync
  presentation/providers/
    translator_providers.dart              ← DI wiring for all datasources
    ai_inference_provider.dart             ← state machine (download, readiness)
    chat_history_provider.dart             ← chat message state
    chat_memory_provider.dart              ← memory fact state
    memory_extraction_service.dart         ← background fact distillation

lib/features/home/presentation/providers/
  app_preferences_provider.dart           ← AiPreference enum + SharedPreferences
  butty_chat_controller.dart              ← send message, stream tokens, trigger extraction

lib/features/home/presentation/screens/
  butty_chat_screen.dart                  ← UI + lifecycle hooks (flush on pause)

lib/features/home/presentation/widgets/butty_chat/
  butty_model_mode_selector.dart          ← Online / Offline toggle pills
```

---

## Manual QA Checklist

### Cloud path (web)
- [ ] Open on Chrome, sign in, send a message → response streams
- [ ] Refresh page → messages restore from Supabase
- [ ] Send 4+ messages → facts appear in Supabase `chat_memory_facts`
- [ ] Offline pill is disabled / greyed with tooltip *(after Gap 3 fix)*

### Cloud path (native, Online mode)
- [ ] Set preference to Online, send message → Gemini streams response
- [ ] Kill and reopen app → history intact from SQLite
- [ ] Go fully offline → send message → graceful error shown

### Local path (native, Offline mode)
- [ ] Download a model from setup screen
- [ ] Set preference to Offline, send message → local model responds
- [ ] Turn off WiFi → send message → local model still responds ✓
- [ ] Delete model file → send message → transparent cloud fallback (no error shown to user)

### Memory extraction
- [ ] Send 4 messages with personal context ("I am learning BA characters")
- [ ] Check SQLite `chat_memory_facts` → at least one fact row exists
- [ ] Check Supabase `chat_memory_facts` → same fact synced with `remoteId`
- [ ] Send same context again → no duplicate facts created
