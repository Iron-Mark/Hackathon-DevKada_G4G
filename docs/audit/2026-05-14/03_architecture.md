# 03 — Architecture & code quality
**Auditor:** general-purpose (architecture lane) · **Skills invoked:** review (deferred — schema not loaded, applying review heuristics manually); simplify (heuristics-only) · **Date:** 2026-05-14

## Summary
- P0 count: 2 · P1 count: 3 · P2 count: 3
- Single biggest risk: Presentation layer routinely reaches into `data/` (datasources + repository impls), so the Clean-Architecture inward-dependency rule from CLAUDE.md is broken in roughly two dozen call sites across scanner/translator/learning/home/admin/auth — feature swaps and unit tests can no longer rely on the domain boundary.

## Findings

### Clean Architecture boundary violations

CLAUDE.md rule: *“Dependencies flow inward only: presentation → domain ← data. The domain layer has zero Flutter dependencies.”*

1. **Domain → Flutter (rule #1):** CLEAN. `grep -rn "package:flutter" lib/features/*/domain/` returns **zero** hits. `package:flutter_riverpod` likewise absent from every `domain/` tree. Pure-Dart contract honoured across auth, home, learning, translator, scanner, admin.

2. **Presentation → data (rule #2):** **VIOLATED in 24 import sites.** Presentation providers/widgets import concrete datasources and repository implementations directly instead of resolving them through a domain interface + DI provider. Hits:

   - `lib/features/admin/presentation/providers/stroke_pattern_providers.dart:4-5` — imports `supabase_stroke_pattern_datasource.dart` + `stroke_pattern_repository_impl.dart`.
   - `lib/features/admin/presentation/providers/stroke_recording_notifier.dart:8` — imports `supabase_stroke_pattern_datasource.dart`.
   - `lib/features/admin/presentation/screens/stroke_recording_screen.dart:8` — imports `stroke_export_service.dart`.
   - `lib/features/auth/presentation/providers/auth_provider.dart:7-8` — imports `supabase_auth_datasource.dart` + `auth_repository_impl.dart`.
   - `lib/features/home/presentation/providers/translation_history_provider.dart:7` — imports `sqlite_translation_history_datasource.dart`.
   - `lib/features/home/presentation/providers/profile_management_provider.dart:10-12` — imports two profile datasources + repository impl.
   - `lib/features/home/presentation/providers/translate_page_controller.dart:4` — imports `local_gemma_datasource.dart`.
   - `lib/features/home/presentation/providers/model_setup_controller.dart:8` — imports `local_gemma_datasource.dart`.
   - `lib/features/home/presentation/widgets/settings/vision_download_tile.dart:7` — imports `web_vision_model_preflight.dart`.
   - `lib/features/home/presentation/widgets/settings/llm_download_tile.dart:5` — imports `local_gemma_datasource.dart`.
   - `lib/features/home/presentation/widgets/butty_chat/butty_model_mode_selector.dart:5` — imports `local_gemma_datasource.dart`.
   - `lib/features/learning/presentation/providers/lesson_repository_provider.dart:8-10` — imports `asset_lesson_data_source.dart`, `supabase_lesson_datasource.dart`, `lesson_repository_impl.dart`.
   - `lib/features/learning/presentation/providers/lesson_progress_provider.dart:9` — imports `sqlite_lesson_progress_datasource.dart`.
   - `lib/features/scanner/presentation/providers/scan_history_provider.dart:9` — imports `sqlite_scan_history_datasource.dart`.
   - `lib/features/scanner/presentation/providers/scanner_provider.dart:6-8` — imports `device_inference_capability_checker.dart`, `web_baybayin_detector_factory.dart`, `yolo_baybayin_detector.dart`.
   - `lib/features/scanner/presentation/providers/yolo_model_selection_provider.dart:10-12` — imports `web_vision_model_preflight.dart`, `yolo_model_cache.dart`, **cross-feature** `translator/data/datasources/supabase_ai_models_datasource.dart`.
   - `lib/features/scanner/presentation/widgets/scanner_camera.dart:12` — imports `yolo_baybayin_detector.dart`.
   - `lib/features/translator/presentation/providers/translator_providers.dart:10-17` — imports seven datasources + `ai_inference_repository_impl.dart`.
   - `lib/features/translator/presentation/providers/chat_history_provider.dart:9-10` — imports `sqlite_chat_datasource.dart` + `supabase_chat_datasource.dart`.
   - `lib/features/translator/presentation/providers/chat_memory_provider.dart:4-6` — imports two chat-memory datasources + `chat_memory_repository_impl.dart`.

   **Severity P0.** This is a systemic clean-architecture break. The provider files do at least keep the datasource wiring in *one place per feature* (so they function as an ad-hoc composition root), but the rule in CLAUDE.md is unambiguous; the wiring belongs in a `core/di/` root or in `data/`-owned provider files that expose only domain interfaces to presentation.

### Riverpod convention compliance

CLAUDE.md rule: *“Use @riverpod code generation (riverpod_annotation) for all providers.”*

- **42 files** in `lib/features/` use `@riverpod` (`.g.dart` partners present and current). Examples: `auth_notifier.dart`, `profile_management_provider.dart`, `scanner_provider.dart`, `translator_providers.dart`, `chat_history_provider.dart`, `ai_inference_provider.dart`.
- **15 provider files** mix in raw `NotifierProvider<>`, `AsyncNotifierProvider<>`, `FutureProvider<>`, or `Provider<>` — convention violation:
  - `lib/features/home/presentation/providers/translate_page_controller.dart:47-49` (`NotifierProvider<TranslatePageController, …>`) and `:62-63` (`FutureProvider<TranslateOfflineStatus>`).
  - `lib/features/home/presentation/providers/translate_text_controller.dart:82-84` (`NotifierProvider`).
  - `lib/features/home/presentation/providers/translate_sketchpad_controller.dart:46-48` (`NotifierProvider`).
  - `lib/features/home/presentation/providers/model_setup_controller.dart:36-38` (`NotifierProvider`).
  - `lib/features/home/presentation/providers/butty_chat_controller.dart:51-53` (`NotifierProvider`).
  - `lib/features/home/presentation/providers/app_preferences_provider.dart:169-174` (`NotifierProvider<ModelSetupSkippedNotifier, bool>`).
  - `lib/features/home/presentation/providers/translation_history_provider.dart:11-22` (raw `Provider<>` + `AsyncNotifierProvider<>`).
  - `lib/features/home/presentation/widgets/butty_chat/butty_model_mode_selector.dart:19-20` (`FutureProvider<ButtyOfflineStatus>`).
  - `lib/features/translator/presentation/providers/translator_providers.dart:100-101` (`FutureProvider<LocalGemmaReadiness>`).
  - `lib/features/translator/presentation/providers/chat_memory_provider.dart:10,17,24,32` (raw `Provider<>` × 3 + `AsyncNotifierProvider<>`).
  - `lib/features/scanner/presentation/providers/scan_history_provider.dart:13,22` (raw `Provider<>` + `AsyncNotifierProvider`).
  - `lib/features/scanner/presentation/providers/scanner_provider.dart:58` (`Provider<bool>` deviceInferenceCapableProvider).
  - `lib/features/scanner/presentation/providers/scanner_evaluation_provider.dart:41` (`Notifier<ScanEvalState>` w/ raw NotifierProvider wiring).
  - `lib/features/scanner/presentation/providers/scan_tab_controller.dart:126` (`Notifier<ScanTabState>` w/ raw NotifierProvider wiring).
  - `lib/features/scanner/presentation/providers/yolo_model_selection_provider.dart:78,131,142,294-295,396,426` (raw `AsyncNotifier`, `Provider<>`, `FutureProvider<>` quartet).
  - `lib/features/learning/presentation/providers/lesson_progress_provider.dart:14,23` (raw `Provider<>` + `AsyncNotifierProvider<>`).
  - `lib/features/admin/presentation/providers/stroke_pattern_providers.dart:10,16` (raw `Provider<>` × 2).

  Note: `app/router/router_listenable.dart:8` uses `extends ChangeNotifier` — acceptable for a `go_router` `Listenable`, but worth flagging. **Severity P1** (codebase is half-codegen, half-hand-rolled; pattern drift creates real maintenance cost).

### Widget rule compliance (build() ≤40, no _buildX, nesting)

build() length measurements (manual count from end-to-end reads):

| File | Widget | `build()` lines | Verdict |
|---|---|---|---|
| `lib/features/home/presentation/screens/scan_tab.dart` | `_ScanTabState` | **~216 (252→468)** | FAIL — 5.4× budget |
| `lib/features/home/presentation/screens/translate_screen.dart` | `_TranslateScreenState` | **~140 (33→172)** | FAIL — 3.5× budget |
| `lib/features/home/presentation/screens/butty_chat_screen.dart` | `_ButtyChatScreenState` | **~97 (86→182)** | FAIL — 2.4× budget |
| `lib/features/home/presentation/screens/profile_tab.dart` | `_GuestProfile` | **~65 (35→99)** | FAIL |
| `lib/features/home/presentation/screens/profile_tab.dart` | `_UserProfile` | **~60 (146→206)** | FAIL |
| `lib/features/home/presentation/screens/profile_tab.dart` | `ProfileTab` | 10 | OK |
| `lib/features/home/presentation/screens/settings_screen.dart` | `SettingsScreen` | 31 | OK |
| `lib/features/home/presentation/screens/learn_tab.dart` | `LearnTab` | 15 | OK |
| `lib/features/learning/presentation/screens/lesson_stage_screen.dart` | `_LessonStageScreenState` | **~55 (94→148)** | FAIL |
| `lib/features/learning/presentation/screens/lesson_stage_screen.dart` | `_LessonScaffold` | **~62 (169→230)** | FAIL |
| `lib/features/learning/presentation/screens/lesson_stage_screen.dart` | `_ModeSwitcher` | 14 | OK |

Private `_build…()` UI-builder methods: **none found in the audited screens.** All `_build…` matches surface in non-widget contexts:

- `lib/features/home/presentation/providers/butty_chat_controller.dart:212-240` — `_buildSystemInstruction`, `_buildProfileBlock`, `_buildMemoryBlock` build *prompt strings*, not widgets. OK.
- `lib/features/learning/presentation/widgets/butty_help_sheet.dart:14` — `_buildSystemPrompt(LessonStep)` returns `String`. OK.
- `lib/features/translator/data/datasources/cloud_gemma_datasource.dart:69,217` — `_buildMessages` returns `List<Message>` for the LLM call. OK.

Nesting depth: `scan_tab.dart` `_ScanTabState.build()` reaches 7+ levels of indentation through `LayoutBuilder → Stack → Positioned → SafeArea → Padding → AnimatedOpacity → Center → _ScanStatusChip` (lines 356–387). `translate_screen.dart` build nests `ColoredBox → SafeArea → LayoutBuilder → Column → Expanded → switch → TextModePanel`. Both exceed the “3+ levels triggers extraction” rule.

**Severity P1** — 7 out of 11 build() methods in the requested screens exceed the 40-line budget, and the worst offender is 5× the limit. Extraction is mechanical: the scan_tab.dart `_ScanTabState.build()` already has six sub-widgets co-located in the same file (`_ScanCameraStack`, `_ScanControls`, `_ScanUtilityBar`, `_ScanNoticePanel`, `ScannerResultPanel`, `_ScanStatusChip`); the parent build is simply orchestrating them inline rather than via an extracted `_ScanTabLayout({...})` widget that owns the `Stack`/`Positioned` math.

### Error handling (Either<Failure, T>) coverage

`fpdart` is imported across the codebase; `dartz` is not used. Domain `Either<Failure, T>` coverage:

- **Auth domain:** complete. Every method on `AuthRepository` and every use case (`sign_in_with_email`, `sign_up_with_email`, `sign_in_with_google`, `sign_out`, `send_phone_otp`, `verify_phone_otp`, `reset_password`) returns `Either<Failure, T>`.
- **Home domain:** complete. `ProfileManagementRepository` + all four use cases (`get_profile_summary`, `get_profile_preferences`, `update_display_name`, `save_profile_preferences`) return `Either<Failure, T>`.
- **Learning domain:** complete. `LessonRepository.loadLesson` and `LoadLesson` use case return `Either<Failure, Lesson>`.
- **Admin domain:** complete. `StrokePatternRepository.save` / `fetchByGlyph` return `Either<Failure, T>`.
- **Translator domain:** **PARTIAL.** `ai_inference_repository.dart` returns `Either<Failure, T>` for `getAvailableModels`, `isLocalModelInstalled`, `downloadLocalModel`, `generateChallenge`. But `lib/features/translator/domain/repositories/chat_memory_repository.dart:6,10,14,18,22` returns raw `Future<List<ChatMemoryFact>>` / `Future<void>` — no `Either`. The corresponding use cases (`generate_chat_response`, `analyze_baybayin_image`) also do not use `Either` consistently — `analyze_baybayin_image.dart` and `generate_chat_response.dart` need verification on a follow-up pass.
- **Scanner domain:** **MISSING.** `lib/features/scanner/domain/repositories/baybayin_detector.dart:16-32` is the sole scanner repo interface and uses raw `Future<List<BaybayinDetection>>`, `Future<Uint8List?>`, `Future<void>` for every method. No use-case layer exists in `lib/features/scanner/domain/` (the dir has only `entities/` and `repositories/`). All detection error paths bubble through exceptions in `data/` and presentation notifiers.

**Severity P0** for scanner (this is the feature with the most-likely failure modes — TFLite load, camera permission, web preflight) and **P1** for the partial translator coverage.

### Style rules (no var, single quotes)

- **`var` usage:** one isolated violation: `lib/features/home/presentation/screens/translate_screen.dart:67` — `final view = View.of(context);` (type inferred as `FlutterView` rather than declared). Rest of the audited files are clean.
- **Double-quoted strings:** every double-quote hit found in `lib/features/` is *inside* a single-quoted string literal (escaped quotes embedded in user-facing copy or prompts — e.g. `'Translate "mahal kita"'`, `'Input: "${state.inputText.trim()}"'`). No genuine `"..."` Dart string literals identified. OK.
- **Trailing commas, single-quote imports, file naming:** spot checks across the seven screens read end-to-end show full compliance.

**Severity P2** — isolated `var` fix.

### Test coverage map (feature × test type)

`test/` enumeration (42 files):

| Feature | Domain (use cases) | Data (datasources) | Presentation (widgets/providers) | Verdict |
|---|---|---|---|---|
| auth | 6 use case tests | 0 | 6 widget/screen tests | strong |
| home | 0 | 0 | 13 widget/screen + 1 utility (`safe_ai_output_test`) + 2 profile avatar contract tests | UI-heavy, no domain |
| learning | 0 | 0 | 1 widget (`learning_density_test`) | sparse |
| scanner | 0 | 3 (`yolo_baybayin_detector`, `web_yolo_output_parser`, `web_vision_model_preflight_browser`) | 1 provider (`scan_tab_controller_test`) + 4 widget tests | data-side covered, **no domain tests** (no use cases yet) |
| translator | 0 | 2 (`cloud_gemma_datasource`, `web_gemma_model_preflight_browser`) | 0 | **no presentation tests, no domain tests** |
| admin | 0 | 0 | 0 | uncovered |
| app/router | 1 (`guest_route_access_test`) | — | — | minimal |

**Gaps:**
- Translator: no `analyze_baybayin_image`, `generate_chat_response`, `generate_baybayin_challenge`, `get_available_models`, `download_local_model`, `check_local_model_installed` use case tests.
- Home: no use case tests for `get_profile_summary`, `get_profile_preferences`, `update_display_name`, `save_profile_preferences`. No provider tests for `butty_chat_controller`, `translate_page_controller`, `translate_text_controller`, `translate_sketchpad_controller`, `model_setup_controller`, `translation_history_provider`, `profile_management_provider`.
- Learning: no use case tests for `load_lesson`. No provider tests (`lesson_controller`, `lesson_progress_provider`).
- Scanner: no use cases at all → nothing to test there; provider tests cover only `scan_tab_controller`. `scanner_provider`, `scanner_evaluation_provider`, `yolo_model_selection_provider`, `scan_history_provider` are untested.
- Admin: zero tests.

**Severity P2** for coverage breadth — the audited feature has tests, but ML-touching presentation logic (butty chat, lesson controller, sketchpad) is unguarded.

## Top Recommendations (architecture-local, severity-ordered)

| # | Severity | Effort | Recommendation | Evidence |
|---|---|---|---|---|
| 1 | P0 | L | Add `Either<Failure, T>` to **scanner** domain (`baybayin_detector.dart:10-32`) — wrap detect/capture/torch/switch/pause/resume in typed failures; add a `scanner/domain/usecases/` directory. | `lib/features/scanner/domain/repositories/baybayin_detector.dart:16-32` (raw Futures); the only feature whose failure surface is invisible to presentation. |
| 2 | P0 | L | Migrate `data/` imports out of `presentation/` by introducing per-feature composition-root providers (e.g. `data/di/scanner_providers.dart`) that expose only the **domain interface**; presentation should import the interface, not the datasource. | 24 import sites enumerated above (`translator_providers.dart:10-17`, `scanner_provider.dart:6-8`, `auth_provider.dart:7-8`, etc.). |
| 3 | P1 | M | Finish the `@riverpod` codegen migration across the 15 files mixing raw `NotifierProvider<>` / `AsyncNotifierProvider<>` / `FutureProvider<>` / `Provider<>`. Half the presentation layer is already on codegen — close the gap so dispose semantics and family typing are consistent. | `translate_page_controller.dart:47`, `butty_chat_controller.dart:51`, `translation_history_provider.dart:11-22`, `chat_memory_provider.dart:10-32`, etc. |
| 4 | P1 | M | Extract `_ScanTabState.build()` into a `_ScanTabLayout` widget (and similarly for `TranslateScreen`, `ButtyChatScreen`, `_GuestProfile`, `_UserProfile`, `_LessonStageScreenState`, `_LessonScaffold`). Sub-widgets already exist in-file; the rule says compose them, not inline the Stack/Positioned math. | scan_tab.dart 252→468 (216 lines); translate_screen.dart 33→172 (140 lines). |
| 5 | P1 | M | Add `Either<Failure, T>` to translator `ChatMemoryRepository` and audit `generate_chat_response` / `analyze_baybayin_image` use cases. | `lib/features/translator/domain/repositories/chat_memory_repository.dart:6,10,14,18,22`. |
| 6 | P2 | S | Replace `final view = View.of(context);` with `final FlutterView view = View.of(context);`. | `lib/features/home/presentation/screens/translate_screen.dart:67`. |
| 7 | P2 | M | Backfill use-case unit tests for translator (`analyze_baybayin_image`, `generate_chat_response`, `generate_baybayin_challenge`), home (`update_display_name`, `save_profile_preferences`), and learning (`load_lesson`). | Test inventory above. |
| 8 | P2 | S | Add provider tests for `butty_chat_controller`, `translate_page_controller`, and `lesson_controller` — they orchestrate the AI inference path and currently have no regression net. | Test inventory above. |

## Methods
- Files read end-to-end: `lib/features/home/presentation/screens/scan_tab.dart`, `…/translate_screen.dart`, `…/butty_chat_screen.dart`, `…/learn_tab.dart`, `…/profile_tab.dart`, `…/settings_screen.dart`, `lib/features/learning/presentation/screens/lesson_stage_screen.dart`. Spot-read: provider files in `home/presentation/providers/`, `translator/presentation/providers/`, `scanner/presentation/providers/`, `learning/presentation/providers/`, `admin/presentation/providers/`; every `domain/repositories/*.dart` under `lib/features/`. Existing audit docs reviewed for prior signal: `docs/system_audit.md`, `docs/system_audit_next_steps.md`, `docs/backend_audit_2026.md` (the first two already note `@riverpod` + `fpdart` as the intended pattern — this lane quantifies the gap between intent and the current tree).
- Grep sweeps run: `package:flutter` in `features/*/domain/` (0 hits — clean); `package:flutter_riverpod` in `features/*/domain/` (0 hits); `import …/data/` inside `features/*/presentation/` (24 hits, enumerated); `@riverpod` (42 files); raw `Provider<` / `NotifierProvider<` / `AsyncNotifierProvider<` / `FutureProvider<` outside `.g.dart` (15 files); `StateNotifierProvider` / `extends StateNotifier` (0 hits); `extends ChangeNotifier` (1 hit, router only); `_build[A-Z]` (10 hits, all returning `String`/`List<Message>`, none UI builders); `Either<` / `Failure` inside `features/*/domain/` (counted per-feature, scanner missing entirely); `var ` in audited screens (1 hit); double-quoted Dart literals (0 — all double quotes are inside single-quoted strings).
- Prior audits reconciled: `system_audit.md` claims `@riverpod` codegen and `Either<Failure>` are the codebase pattern — accurate as *target state* but ~30% of presentation providers and the entire scanner domain still need migration; `system_audit_next_steps.md` priorities (scanner reliability, translator polish) align with this lane’s P0 list; `backend_audit_2026.md` is data-layer focused and does not overlap with these findings.
