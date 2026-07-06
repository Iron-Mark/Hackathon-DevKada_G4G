import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kudlit_ph/features/translator/domain/entities/chat_memory_fact.dart';
import 'package:kudlit_ph/features/translator/domain/entities/chat_message.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/chat_history_provider.dart';
import 'package:kudlit_ph/features/translator/presentation/providers/chat_memory_provider.dart';

const List<String> _memoryTypes = <String>[
  'preference',
  'topic',
  'personal',
  'skill',
  'goal',
  'general',
];

/// Settings page for inspecting and managing Butty's data:
/// - Episodic chat history (raw messages, synced to Supabase)
/// - Semantic memory facts (distilled, survives "Start fresh", user-editable)
class ButtyDataScreen extends ConsumerWidget {
  const ButtyDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          const _ButtyHeroAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                const _IntroBlurb()
                    .animate()
                    .fadeIn(duration: 220.ms)
                    .slideY(begin: 0.05, end: 0, duration: 220.ms),
                const SizedBox(height: 16),
                const _ChatHistorySection()
                    .animate(delay: 80.ms)
                    .fadeIn(duration: 260.ms)
                    .slideY(begin: 0.06, end: 0, duration: 260.ms),
                const SizedBox(height: 14),
                const _MemorySection()
                    .animate(delay: 160.ms)
                    .fadeIn(duration: 280.ms)
                    .slideY(begin: 0.06, end: 0, duration: 280.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero app bar with Butty mascot ──────────────────────────────────────────

class _ButtyHeroAppBar extends StatelessWidget {
  const _ButtyHeroAppBar();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        color: cs.onPrimary,
        onPressed: () => context.pop(),
      ),
      backgroundColor: cs.primary,
      title: const Text('Butty data'),
      foregroundColor: cs.onPrimary,
      flexibleSpace: FlexibleSpaceBar(
        background: _HeroBanner(cs: cs),
        collapseMode: CollapseMode.pin,
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[cs.primary, cs.primary.withAlpha(200)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            Positioned(
              right: -10,
              bottom: -8,
              child:
                  Image.asset(
                        'assets/brand/ButtyTextBubble.webp',
                        height: 150,
                        fit: BoxFit.fitHeight,
                      )
                      .animate(delay: 100.ms)
                      .slideX(
                        begin: 0.25,
                        end: 0,
                        duration: 420.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .fadeIn(duration: 320.ms),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 150, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: cs.onPrimary.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Butty says',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: cs.onPrimary.withAlpha(220),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                        'Tara, ayusin natin!\nYour chats and what I remember about you.',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: cs.onPrimary,
                          height: 1.4,
                        ),
                      )
                      .animate(delay: 80.ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1, end: 0, duration: 300.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Intro blurb ──────────────────────────────────────────────────────────────

class _IntroBlurb extends StatelessWidget {
  const _IntroBlurb();

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, color: cs.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Two layers',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: cs.primary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chat history is the raw conversation log. Memory is what '
                  'Butty has distilled about you — it survives "Start fresh" '
                  'so future chats stay personal. Tap any item to read or edit.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: cs.onSurface.withAlpha(200),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chat history section ─────────────────────────────────────────────────────

class _ChatHistorySection extends ConsumerWidget {
  const _ChatHistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ChatMessage>> async = ref.watch(
      chatHistoryNotifierProvider,
    );
    return _SectionCard(
      mascot: 'assets/brand/ButtyRead.webp',
      title: 'Chat history',
      subtitle: async.when(
        loading: () => 'Loading…',
        error: (_, _) => 'Could not load chat history.',
        data: (List<ChatMessage> msgs) => msgs.isEmpty
            ? 'No messages stored yet.'
            : '${msgs.length} message${msgs.length == 1 ? '' : 's'} synced to Supabase.',
      ),
      child: async.when(
        loading: () => const _Skeleton(),
        error: (Object e, _) => _ErrorBlock(message: e.toString()),
        data: (List<ChatMessage> msgs) => _ChatHistoryBody(messages: msgs),
      ),
    );
  }
}

class _ChatHistoryBody extends ConsumerWidget {
  const _ChatHistoryBody({required this.messages});
  final List<ChatMessage> messages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (messages.isEmpty) {
      return const _EmptyHint(
        mascot: 'assets/brand/ButtyWave.webp',
        title: 'No conversations yet',
        body: 'Open Butty and ask anything — your messages will land here.',
      );
    }

    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<ChatMessage> recent = messages.length <= 8
        ? messages.reversed.toList(growable: false)
        : messages.reversed.take(8).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Most recent — tap to read full',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withAlpha(140),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        ...recent.map(
          (ChatMessage m) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _MessagePreview(
              message: m,
              onTap: () => _openFullMessage(context, m),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _confirmClearChat(context, ref),
            icon: Icon(Icons.delete_outline_rounded, color: cs.error),
            label: Text(
              'Clear all chat history',
              style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openFullMessage(BuildContext context, ChatMessage m) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FullMessageSheet(message: m),
    );
  }

  Future<void> _confirmClearChat(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Clear all chat history?'),
          content: const Text(
            'This deletes every chat message — local and on Supabase. '
            'Memory facts are kept. This cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: const Text('Clear chat'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await ref.read(chatHistoryNotifierProvider.notifier).clearHistory();
  }
}

class _MessagePreview extends StatelessWidget {
  const _MessagePreview({required this.message, required this.onTap});
  final ChatMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool user = message.isUser;
    final Color tag = user ? cs.primary : cs.tertiary;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!user)
                ClipOval(
                  child: Image.asset(
                    'assets/brand/ButtyRead.webp',
                    width: 22,
                    height: 22,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: tag.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, size: 14, color: tag),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          user ? 'YOU' : 'BUTTY',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: tag,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurface.withAlpha(130),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message.text.replaceAll('\n', ' ').trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: cs.onSurface.withAlpha(220),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: cs.onSurface.withAlpha(80),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime t) {
    final Duration ago = DateTime.now().difference(t);
    if (ago.inMinutes < 1) return 'now';
    if (ago.inMinutes < 60) return '${ago.inMinutes}m';
    if (ago.inHours < 24) return '${ago.inHours}h';
    if (ago.inDays < 7) return '${ago.inDays}d';
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }
}

class _FullMessageSheet extends StatelessWidget {
  const _FullMessageSheet({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool user = message.isUser;
    final TextStyle bodyStyle = TextStyle(
      fontSize: 14,
      color: cs.onSurface.withAlpha(230),
      height: 1.55,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, ScrollController scroll) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  if (!user)
                    ClipOval(
                      child: Image.asset(
                        'assets/brand/ButtyRead.webp',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cs.primary.withAlpha(50),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person, color: cs.primary, size: 18),
                    ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user ? 'You said' : 'Butty said',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _fullTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: cs.onSurface.withAlpha(140),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  controller: scroll,
                  child: user
                      ? SelectableText(message.text, style: bodyStyle)
                      : MarkdownBody(
                          data: message.text,
                          shrinkWrap: true,
                          softLineBreak: true,
                          selectable: true,
                          styleSheet: _markdownStyle(context, bodyStyle),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _fullTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }
}

MarkdownStyleSheet _markdownStyle(BuildContext context, TextStyle base) {
  final ColorScheme cs = Theme.of(context).colorScheme;
  return MarkdownStyleSheet(
    p: base,
    h1: base.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
    h2: base.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
    h3: base.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
    strong: base.copyWith(fontWeight: FontWeight.w700),
    em: base.copyWith(fontStyle: FontStyle.italic),
    listBullet: base,
    a: base.copyWith(color: cs.primary, decoration: TextDecoration.underline),
    code: base.copyWith(
      fontFamily: 'monospace',
      fontSize: 13,
      backgroundColor: cs.surfaceContainerHighest,
    ),
    codeblockDecoration: BoxDecoration(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: cs.outline),
    ),
    codeblockPadding: const EdgeInsets.all(10),
    blockquoteDecoration: BoxDecoration(
      border: Border(left: BorderSide(color: cs.primary, width: 3)),
    ),
    blockquotePadding: const EdgeInsets.only(left: 10),
    blockSpacing: 8,
  );
}

// ─── Memory section ───────────────────────────────────────────────────────────

class _MemorySection extends ConsumerWidget {
  const _MemorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ChatMemoryFact>> async = ref.watch(
      chatMemoryNotifierProvider,
    );
    return _SectionCard(
      mascot: 'assets/brand/ButtyPaint.webp',
      title: 'What Butty remembers',
      subtitle: async.when(
        loading: () => 'Loading…',
        error: (_, _) => 'Could not load memory.',
        data: (List<ChatMemoryFact> facts) => facts.isEmpty
            ? 'No memory yet — add one or chat with Butty.'
            : '${facts.length} fact${facts.length == 1 ? '' : 's'}. Tap to edit.',
      ),
      trailing: IconButton(
        tooltip: 'Add a memory',
        icon: const Icon(Icons.add_circle_outline_rounded),
        onPressed: () => _openAddDialog(context, ref),
      ),
      child: async.when(
        loading: () => const _Skeleton(),
        error: (Object e, _) => _ErrorBlock(message: e.toString()),
        data: (List<ChatMemoryFact> facts) => _MemoryBody(facts: facts),
      ),
    );
  }

  Future<void> _openAddDialog(BuildContext context, WidgetRef ref) async {
    final _MemoryFactDraft? draft = await showDialog<_MemoryFactDraft>(
      context: context,
      builder: (_) => const _EditFactDialog(),
    );
    if (draft == null) return;
    final DateTime now = DateTime.now();
    await ref
        .read(chatMemoryNotifierProvider.notifier)
        .addFacts(<ChatMemoryFact>[
          ChatMemoryFact(
            factType: draft.factType,
            content: draft.content,
            createdAt: now,
            lastReferencedAt: now,
          ),
        ]);
  }
}

class _MemoryBody extends ConsumerWidget {
  const _MemoryBody({required this.facts});
  final List<ChatMemoryFact> facts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    if (facts.isEmpty) {
      return const _EmptyHint(
        mascot: 'assets/brand/ButtyPencilRun.webp',
        title: 'No memory yet',
        body:
            'Chat with Butty for a few turns or tap the + above to add your '
            'own. Memory makes future conversations feel personal.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ...facts.map(
          (ChatMemoryFact f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FactTile(
              fact: f,
              onTap: () => _openEditDialog(context, ref, f),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _confirmClearMemory(context, ref),
            icon: Icon(Icons.delete_sweep_outlined, color: cs.error),
            label: Text(
              'Clear all memory',
              style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openEditDialog(
    BuildContext context,
    WidgetRef ref,
    ChatMemoryFact f,
  ) async {
    final _EditFactResult? result = await showDialog<_EditFactResult>(
      context: context,
      builder: (_) => _EditFactDialog(initial: f),
    );
    if (result == null) return;
    if (result.delete) {
      if (f.id != null) {
        await ref.read(chatMemoryNotifierProvider.notifier).removeFact(f.id!);
      }
      return;
    }
    final _MemoryFactDraft? draft = result.draft;
    if (draft == null) return;
    await ref
        .read(chatMemoryNotifierProvider.notifier)
        .updateFact(
          f.copyWith(factType: draft.factType, content: draft.content),
        );
  }

  Future<void> _confirmClearMemory(BuildContext context, WidgetRef ref) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Clear Butty memory?'),
          content: const Text(
            'This permanently removes everything Butty has learned about you '
            'across past conversations. Visible chat history is not affected. '
            'This cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: const Text('Clear memory'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await ref.read(chatMemoryNotifierProvider.notifier).clearAll();
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({required this.fact, required this.onTap});
  final ChatMemoryFact fact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        fact.factType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: cs.onPrimaryContainer,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      fact.content,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: cs.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.edit_outlined,
                size: 16,
                color: cs.onSurface.withAlpha(110),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Edit / add memory dialog ─────────────────────────────────────────────────

class _MemoryFactDraft {
  const _MemoryFactDraft({required this.factType, required this.content});
  final String factType;
  final String content;
}

class _EditFactResult {
  const _EditFactResult.update(this.draft) : delete = false;
  const _EditFactResult.delete() : draft = null, delete = true;
  final _MemoryFactDraft? draft;
  final bool delete;
}

class _EditFactDialog extends StatefulWidget {
  const _EditFactDialog({this.initial});
  final ChatMemoryFact? initial;

  @override
  State<_EditFactDialog> createState() => _EditFactDialogState();
}

class _EditFactDialogState extends State<_EditFactDialog> {
  late final TextEditingController _content;
  late String _type;

  @override
  void initState() {
    super.initState();
    _content = TextEditingController(text: widget.initial?.content ?? '');
    final String startType = widget.initial?.factType ?? 'preference';
    _type = _memoryTypes.contains(startType) ? startType : 'general';
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool editing = widget.initial != null;
    return AlertDialog(
      title: Text(editing ? 'Edit memory fact' : 'Add a memory fact'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _memoryTypes
                  .map(
                    (String t) =>
                        DropdownMenuItem<String>(value: t, child: Text(t)),
                  )
                  .toList(growable: false),
              onChanged: (String? v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _content,
              maxLines: 4,
              minLines: 2,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Fact',
                hintText: 'e.g. Prefers Tagalog explanations.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        if (editing)
          TextButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(const _EditFactResult.delete()),
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            label: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final String content = _content.text.trim();
            if (content.isEmpty) return;
            final _MemoryFactDraft draft = _MemoryFactDraft(
              factType: _type,
              content: content,
            );
            // Add flow returns the draft directly; edit flow wraps in a result
            // so the caller can also handle the delete branch from the same
            // dialog.
            if (editing) {
              Navigator.of(context).pop(_EditFactResult.update(draft));
            } else {
              Navigator.of(context).pop(draft);
            }
          },
          child: Text(editing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}

// ─── Shared building blocks ───────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.mascot,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String mascot;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(child: Image.asset(mascot, fit: BoxFit.cover)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withAlpha(160),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
              if (trailing == null) const SizedBox(width: 6),
            ],
          ),
          const SizedBox(height: 12),
          Padding(padding: const EdgeInsets.only(right: 6), child: child),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.mascot,
    required this.title,
    required this.body,
  });

  final String mascot;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          ClipOval(
            child: Image.asset(
              mascot,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withAlpha(170),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: TextStyle(color: cs.error, fontSize: 12.5)),
    );
  }
}
