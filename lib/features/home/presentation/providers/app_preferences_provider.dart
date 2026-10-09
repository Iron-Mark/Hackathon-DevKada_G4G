import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_preferences_provider.g.dart';

enum AiPreference { local, cloud }

// ─── State ────────────────────────────────────────────────────────────────────

class AppPreferences {
  const AppPreferences({
    this.themeMode = ThemeMode.system,
    this.aiPreference = AiPreference.cloud,
    this.selectedModelId,
    this.hasSeenModelPrompt = false,
    this.hasDownloadedModels = false,
    this.completedLessons = const <String>{},
  });

  final ThemeMode themeMode;
  final AiPreference aiPreference;

  /// Supabase row id of the user-chosen model. Null = use default
  /// (median of `sort_order ASC`).
  final String? selectedModelId;

  /// Whether the user has already seen the AI model download prompt.
  /// Legacy: kept for backward-compat so existing users who already saw/skipped
  /// the prompt don't see it again.
  final bool hasSeenModelPrompt;

  /// Whether the user has successfully downloaded the AI models.
  /// Only set to true after a completed download — not on skip.
  /// When false (and [hasSeenModelPrompt] is also false), the
  /// `/model-setup` screen is shown on the next cold launch.
  final bool hasDownloadedModels;

  /// Set of lesson IDs the user has completed at least once.
  final Set<String> completedLessons;

  AppPreferences copyWith({
    ThemeMode? themeMode,
    AiPreference? aiPreference,
    String? selectedModelId,
    bool? hasSeenModelPrompt,
    bool? hasDownloadedModels,
    Set<String>? completedLessons,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      aiPreference: aiPreference ?? this.aiPreference,
      selectedModelId: selectedModelId ?? this.selectedModelId,
      hasSeenModelPrompt: hasSeenModelPrompt ?? this.hasSeenModelPrompt,
      hasDownloadedModels: hasDownloadedModels ?? this.hasDownloadedModels,
      completedLessons: completedLessons ?? this.completedLessons,
    );
  }
}

// ─── Persistence keys ─────────────────────────────────────────────────────────

const String _kThemeKey = 'pref_theme';
const String _kAiKey = 'pref_ai';
const String _kSelectedModelKey = 'pref_selected_model';
const String _kModelPromptSeenKey = 'pref_model_prompt_seen';
const String _kModelsDownloadedKey = 'pref_models_downloaded';
const String _kCompletedLessonsKey = 'pref_completed_lessons';

ThemeMode _themeFromString(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

String _themeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

AiPreference _aiFromString(String? value) {
  return value == 'local' ? AiPreference.local : AiPreference.cloud;
}

// ─── Notifier ────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true, name: 'appPreferencesNotifierProvider')
class AppPreferencesNotifier extends _$AppPreferencesNotifier {
  late final SharedPreferences _prefs;

  @override
  Future<AppPreferences> build() async {
    _prefs = await SharedPreferences.getInstance();
    return AppPreferences(
      themeMode: _themeFromString(_prefs.getString(_kThemeKey)),
      aiPreference: _aiFromString(_prefs.getString(_kAiKey)),
      selectedModelId: _prefs.getString(_kSelectedModelKey),
      hasSeenModelPrompt: _prefs.getBool(_kModelPromptSeenKey) ?? false,
      hasDownloadedModels: _prefs.getBool(_kModelsDownloadedKey) ?? false,
      completedLessons:
          _prefs
              .getString(_kCompletedLessonsKey)
              ?.split(',')
              .where((String s) => s.isNotEmpty)
              .toSet() ??
          const <String>{},
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(state.requireValue.copyWith(themeMode: mode));
    await _prefs.setString(_kThemeKey, _themeToString(mode));
  }

  Future<void> setAiPreference(AiPreference pref) async {
    state = AsyncData(state.requireValue.copyWith(aiPreference: pref));
    await _prefs.setString(_kAiKey, pref.name);
  }

  Future<void> setSelectedModel(String modelId) async {
    state = AsyncData(state.requireValue.copyWith(selectedModelId: modelId));
    await _prefs.setString(_kSelectedModelKey, modelId);
  }

  Future<void> markModelPromptSeen() async {
    state = AsyncData(state.requireValue.copyWith(hasSeenModelPrompt: true));
    await _prefs.setBool(_kModelPromptSeenKey, true);
  }

  Future<void> completeLesson(String lessonId) async {
    final AppPreferences? current = state.asData?.value;
    if (current == null) return;
    final Set<String> updated = <String>{...current.completedLessons, lessonId};
    state = AsyncData(current.copyWith(completedLessons: updated));
    await _prefs.setString(_kCompletedLessonsKey, updated.join(','));
  }

  /// Called after a successful AI model download.
  /// Once set, the `/model-setup` screen is never shown again on cold launch.
  Future<void> markModelsDownloaded() async {
    state = AsyncData(
      state.requireValue.copyWith(
        hasSeenModelPrompt: true,
        hasDownloadedModels: true,
      ),
    );
    await _prefs.setBool(_kModelPromptSeenKey, true);
    await _prefs.setBool(_kModelsDownloadedKey, true);
  }
}

// ─── Session-only skip flag ───────────────────────────────────────────────────

/// In-memory flag set when the user taps "Not now" on the model setup screen.
/// Allows the router to navigate away for this session only — resets on next
/// cold launch so the setup screen is shown again until models are downloaded.
final NotifierProvider<ModelSetupSkippedNotifier, bool>
modelSetupSkippedProvider = NotifierProvider<ModelSetupSkippedNotifier, bool>(
  ModelSetupSkippedNotifier.new,
);

class ModelSetupSkippedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setSkipped() {
    state = true;
  }
}
