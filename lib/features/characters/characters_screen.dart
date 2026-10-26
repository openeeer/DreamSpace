import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../core/internal_page.dart';
import '../../data/processing.dart' show characterCoAppearance;
import '../../data/providers.dart';
import '../../models/character.dart';
import '../../models/dream.dart';
import '../dreams/journal_screen.dart' show journalCount;

/// The dreamer's recurring cast. Profiles are filled in one's own time; the
/// assistant only ever matches against this list, never invents entries in it.
class CharactersScreen extends ConsumerWidget {
  const CharactersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final en = ref.watch(englishProvider);
    final characters = ref.watch(charactersProvider).value ?? const <DreamCharacter>[];
    final dreams = ref.watch(dreamsProvider).value ?? const <Dream>[];
    return DreamInternalPage(
      title: tr(en, 'Персонажи', 'Characters'),
      subtitle: tr(
        en,
        'Те, кто приходит в твои сны',
        'The people who visit your dreams',
      ),
      children: [
        if (characters.isEmpty)
          DreamGlassSurface(
            child: Column(
              children: [
                const DreamIconBubble(CupertinoIcons.person_crop_circle),
                const SizedBox(height: Rhythm.m),
                Text(
                  tr(
                    en,
                    'Персонажи появятся, когда отметишь их в снах',
                    'Characters appear once you mark them in dreams',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: InternalStyle.muted(context)),
                ),
              ],
            ),
          )
        else
          for (final character in characters)
            _CharacterTile(
              character: character,
              dreams: dreams,
              en: en,
            ),
      ],
    );
  }
}

class _CharacterTile extends ConsumerWidget {
  const _CharacterTile({
    required this.character,
    required this.dreams,
    required this.en,
  });
  final DreamCharacter character;
  final List<Dream> dreams;
  final bool en;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = _stats(character, dreams);
    return Padding(
      padding: const EdgeInsets.only(bottom: Rhythm.m),
      child: DreamGlassSurface(
        onTap: () => context.push('/characters/${character.id}'),
        child: Row(
          children: [
            const DreamIconBubble(CupertinoIcons.person_crop_circle),
            const SizedBox(width: Rhythm.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(character.name, style: display(17)),
                  const SizedBox(height: Rhythm.xs),
                  Text(
                    stats == null
                        ? (character.relation ?? '')
                        : '${stats.appearances} ${journalCount(stats.appearances, en)} · ${formatDate(stats.lastSeen, en)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: InternalStyle.muted(context),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 15),
          ],
        ),
      ),
    );
  }

  ({int appearances, DateTime lastSeen})? _stats(
    DreamCharacter character,
    List<Dream> dreams,
  ) {
    // Character profiles link to dreams through element ids; a profile is
    // found by matching its element entry (character kind, same name).
    final appearances = dreams
        .where(
          (d) => d.ofKind(ElementKind.character).any(
            (e) => e.id == character.id || normalize(e.name) == normalize(character.name),
          ),
        )
        .toList();
    if (appearances.isEmpty) return null;
    return (
      appearances: appearances.length,
      lastSeen: appearances.map((d) => d.date).reduce(
            (a, b) => a.isAfter(b) ? a : b,
          ),
    );
  }
}

/// One character's full profile: frequency, first and last visit, who they
/// appear with, and the dreamer's own notes.
class CharacterDetailScreen extends ConsumerStatefulWidget {
  const CharacterDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<CharacterDetailScreen> createState() =>
      _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends ConsumerState<CharacterDetailScreen> {
  late final notes = TextEditingController();
  late final relation = TextEditingController();
  bool loaded = false, saving = false;

  @override
  void dispose() {
    notes.dispose();
    relation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final en = ref.watch(englishProvider);
    final characters = ref.watch(charactersProvider).value ?? const <DreamCharacter>[];
    final character = characters.where((c) => c.id == widget.id).firstOrNull;
    if (character == null) {
      return DreamInternalPage(
        title: tr(en, 'Персонаж не найден', 'Character not found'),
        children: const [],
      );
    }
    if (!loaded) {
      notes.text = character.notes ?? '';
      relation.text = character.relation ?? '';
      loaded = true;
    }
    final dreams = ref.watch(dreamsProvider).value ?? const <Dream>[];
    final appearances = dreams
        .where(
          (d) => d.ofKind(ElementKind.character).any(
            (e) => e.id == character.id || normalize(e.name) == normalize(character.name),
          ),
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return DreamInternalPage(
      title: character.name,
      compact: true,
      children: [
        DreamGlassSurface(
          child: Row(
            children: [
              const DreamIconBubble(CupertinoIcons.person_crop_circle),
              const SizedBox(width: Rhythm.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appearances.isEmpty
                          ? tr(en, 'Ещё не встречался', 'Not seen yet')
                          : '${appearances.length} ${journalCount(appearances.length, en)}',
                      style: display(22),
                    ),
                    if (appearances.isNotEmpty)
                      Text(
                        '${formatDate(appearances.last.date, en)} — ${formatDate(appearances.first.date, en)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: InternalStyle.muted(context),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (appearances.isNotEmpty) ...[
          const SizedBox(height: Rhythm.section),
          _TogetherWith(
            character: character,
            dreams: dreams,
            en: en,
          ),
        ],
        const SizedBox(height: Rhythm.section),
        DreamSettingsSection(
          title: tr(en, 'Профиль', 'Profile'),
          icon: CupertinoIcons.person,
          children: [
            DreamSettingsRow(
              icon: CupertinoIcons.person_2,
              title: tr(en, 'Кто он тебе', 'Who they are to you'),
              subtitle: tr(
                en,
                'Например: мама, друг детства, сущность',
                'For example: mom, childhood friend, an entity',
              ),
              child: TextField(
                controller: relation,
                decoration: InputDecoration(
                  hintText: tr(en, 'Свободная форма', 'Free form'),
                ),
              ),
            ),
            DreamSettingsRow(
              icon: CupertinoIcons.pencil,
              title: tr(en, 'Заметки', 'Notes'),
              subtitle: tr(
                en,
                'Всё, что хочется запомнить об этом персонаже',
                'Anything worth remembering about them',
              ),
              child: TextField(
                controller: notes,
                minLines: 3,
                maxLines: 5,
              ),
            ),
          ],
        ),
        const SizedBox(height: Rhythm.m),
        DreamButton(
          label: saving
              ? tr(en, 'Сохраняю…', 'Saving…')
              : tr(en, 'Сохранить профиль', 'Save profile'),
          icon: CupertinoIcons.check_mark,
          onPressed: saving
              ? null
              : () async {
                  setState(() => saving = true);
                  try {
                    await ref
                        .read(repositoryProvider)
                        .saveCharacter(
                          character.copyWith(
                            relation: relation.text,
                            notes: notes.text,
                          ),
                        );
                    if (context.mounted) context.pop();
                  } catch (_) {
                    if (context.mounted) {
                      await dreamNotice(
                        context,
                        tr(en, 'Не удалось сохранить', 'Could not save'),
                        tr(en, 'Попробуй ещё раз.', 'Please try again.'),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => saving = false);
                  }
                },
        ),
        const SizedBox(height: Rhythm.section),
        _AppearanceTimeline(appearances: appearances, en: en),
      ],
    );
  }
}

class _TogetherWith extends ConsumerWidget {
  const _TogetherWith({required this.character, required this.dreams, required this.en});
  final DreamCharacter character;
  final List<Dream> dreams;
  final bool en;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final characters = ref.watch(charactersProvider).value ?? const <DreamCharacter>[];
    final co = characterCoAppearance(dreams);
    final related = [
      for (final entry in co.entries)
        if (entry.key.$1 == character.id || entry.key.$2 == character.id)
          (
            character: characters
                .where(
                  (c) => c.id == (entry.key.$1 == character.id ? entry.key.$2 : entry.key.$1),
                )
                .firstOrNull,
            count: entry.value,
          ),
    ]
        .where((r) => r.character != null)
        .map((r) => (r.character!, r.count))
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    if (related.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(tr(en, 'Кто снится рядом', 'Appears together with')),
        const SizedBox(height: Rhythm.m),
        DreamGlassSurface(
          child: Column(
            children: [
              for (var i = 0; i < related.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: .7,
                    indent: 62,
                    color: InternalStyle.accent(context).withValues(alpha: .2),
                  ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () =>
                      context.push('/characters/${related[i].$1.id}'),
                  child: Row(
                    children: [
                      const DreamIconBubble(CupertinoIcons.person_2),
                      const SizedBox(width: Rhythm.m),
                      Expanded(child: Text(related[i].$1.name)),
                      Text(
                        '${related[i].$2} ${journalCount(related[i].$2, en)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: InternalStyle.muted(context),
                        ),
                      ),
                      const SizedBox(width: Rhythm.s),
                      const Icon(CupertinoIcons.chevron_right, size: 15),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AppearanceTimeline extends StatelessWidget {
  const _AppearanceTimeline({required this.appearances, required this.en});
  final List<Dream> appearances;
  final bool en;
  @override
  Widget build(BuildContext context) {
    if (appearances.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(tr(en, 'Когда снился', 'When they appeared')),
        const SizedBox(height: Rhythm.m),
        DreamGlassSurface(
          child: Column(
            children: [
              for (var i = 0; i < appearances.length && i < 8; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    thickness: .7,
                    indent: 62,
                    color: InternalStyle.accent(context).withValues(alpha: .2),
                  ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () => context.push('/dream/${appearances[i].id}'),
                  child: Row(
                    children: [
                      DreamIconBubble(
                        appearances[i].mood != null
                            ? moodIcon(appearances[i].mood!)
                            : CupertinoIcons.moon,
                      ),
                      const SizedBox(width: Rhythm.m),
                      Expanded(
                        child: Text(
                          dreamTitle(appearances[i], en),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: display(16),
                        ),
                      ),
                      const SizedBox(width: Rhythm.s),
                      Text(
                        formatDate(appearances[i].date, en),
                        style: TextStyle(
                          fontSize: 12,
                          color: InternalStyle.muted(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}