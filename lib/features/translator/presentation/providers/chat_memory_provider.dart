import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kudlit_ph/features/home/presentation/providers/profile_management_provider.dart';
import 'package:kudlit_ph/features/translator/data/datasources/sqlite_chat_memory_datasource.dart';
import 'package:kudlit_ph/features/translator/data/datasources/supabase_chat_memory_datasource.dart';
import 'package:kudlit_ph/features/translator/data/repositories/chat_memory_repository_impl.dart';
import 'package:kudlit_ph/features/translator/domain/entities/chat_memory_fact.dart';
import 'package:kudlit_ph/features/translator/domain/repositories/chat_memory_repository.dart';

final Provider<SqliteChatMemoryDatasource> sqliteChatMemoryDatasourceProvider =
    Provider<SqliteChatMemoryDatasource>((Ref ref) {
      final SqliteChatMemoryDatasource ds = SqliteChatMemoryDatasource();
      ref.onDispose(ds.dispose);
      return ds;
    });

final Provider<SupabaseChatMemoryDatasource>
supabaseChatMemoryDatasourceProvider = Provider<SupabaseChatMemoryDatasource>((
  Ref ref,
) {
  return SupabaseChatMemoryDatasource(ref.watch(supabaseProvider));
});

final Provider<ChatMemoryRepository> chatMemoryRepositoryProvider =
    Provider<ChatMemoryRepository>((Ref ref) {
      return ChatMemoryRepositoryImpl(
        local: ref.watch(sqliteChatMemoryDatasourceProvider),
        remote: ref.watch(supabaseChatMemoryDatasourceProvider),
      );
    });

final AsyncNotifierProvider<ChatMemoryNotifier, List<ChatMemoryFact>>
chatMemoryNotifierProvider =
    AsyncNotifierProvider<ChatMemoryNotifier, List<ChatMemoryFact>>(
      ChatMemoryNotifier.new,
    );

class ChatMemoryNotifier extends AsyncNotifier<List<ChatMemoryFact>> {
  late final ChatMemoryRepository _repo;

  @override
  Future<List<ChatMemoryFact>> build() async {
    _repo = ref.watch(chatMemoryRepositoryProvider);
    return _repo.getFacts();
  }

  Future<void> addFacts(List<ChatMemoryFact> facts) async {
    if (facts.isEmpty) return;
    final List<ChatMemoryFact> updated = await _repo.addFacts(facts);
    state = AsyncData<List<ChatMemoryFact>>(updated);
  }

  Future<void> updateFact(ChatMemoryFact fact) async {
    final List<ChatMemoryFact> updated = await _repo.updateFact(fact);
    state = AsyncData<List<ChatMemoryFact>>(updated);
  }

  Future<void> removeFact(int id) async {
    final List<ChatMemoryFact> updated = await _repo.removeFact(id);
    state = AsyncData<List<ChatMemoryFact>>(updated);
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    state = const AsyncData<List<ChatMemoryFact>>(<ChatMemoryFact>[]);
  }
}
