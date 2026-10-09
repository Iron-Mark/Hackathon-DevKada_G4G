// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persisted Butty chat history backed by sqflite, with Supabase mirroring
/// for cross-device continuity.
///
/// Mirrors the offline-first pattern used by [TranslationHistoryNotifier]:
/// reads come from SQLite first, fall back to Supabase on cold-empty,
/// writes are local-first with fire-and-forget cloud sync.

@ProviderFor(ChatHistoryNotifier)
final chatHistoryNotifierProvider = ChatHistoryNotifierProvider._();

/// Persisted Butty chat history backed by sqflite, with Supabase mirroring
/// for cross-device continuity.
///
/// Mirrors the offline-first pattern used by [TranslationHistoryNotifier]:
/// reads come from SQLite first, fall back to Supabase on cold-empty,
/// writes are local-first with fire-and-forget cloud sync.
final class ChatHistoryNotifierProvider
    extends $AsyncNotifierProvider<ChatHistoryNotifier, List<ChatMessage>> {
  /// Persisted Butty chat history backed by sqflite, with Supabase mirroring
  /// for cross-device continuity.
  ///
  /// Mirrors the offline-first pattern used by [TranslationHistoryNotifier]:
  /// reads come from SQLite first, fall back to Supabase on cold-empty,
  /// writes are local-first with fire-and-forget cloud sync.
  ChatHistoryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatHistoryNotifierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatHistoryNotifierHash();

  @$internal
  @override
  ChatHistoryNotifier create() => ChatHistoryNotifier();
}

String _$chatHistoryNotifierHash() =>
    r'66c167d921041e2bcd87f9d518c789e207b3b682';

/// Persisted Butty chat history backed by sqflite, with Supabase mirroring
/// for cross-device continuity.
///
/// Mirrors the offline-first pattern used by [TranslationHistoryNotifier]:
/// reads come from SQLite first, fall back to Supabase on cold-empty,
/// writes are local-first with fire-and-forget cloud sync.

abstract class _$ChatHistoryNotifier extends $AsyncNotifier<List<ChatMessage>> {
  FutureOr<List<ChatMessage>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ChatMessage>>, List<ChatMessage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ChatMessage>>, List<ChatMessage>>,
              AsyncValue<List<ChatMessage>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
