import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../data/providers.dart';
import '../../models/dream.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) => DreamsBuilder(
    builder: (dreams, en) {
      final dream = dreams.where((d) => d.id == id).firstOrNull;
      if (dream == null) {
        return DreamPage(
          title: tr(en, 'Сон не найден', 'Dream not found'),
          back: true,
          children: const [],
        );
      }
      return DreamPage(
        title: tr(en, 'Сновидение', 'Dream'),
        back: true,
        actions: [
          IconButton(
            tooltip: tr(en, 'Избранное', 'Favorite'),
            onPressed: () => ref
                .read(repositoryProvider)
                .save(dream.copyWith(favorite: !dream.favorite)),
            icon: Icon(
              dream.favorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              color: Palette.lavender,
            ),
          ),
          IconButton(
            tooltip: tr(en, 'Редактировать', 'Edit'),
            onPressed: () => context.push('/record?id=$id'),
            icon: const Icon(CupertinoIcons.pencil),
          ),
        ],
        children: [
          SizedBox(
            height: 280,
            child: Hero(tag: 'dream-$id', child: DreamArtwork(dream.artwork)),
          ),
          const SizedBox(height: 26),
          Text(dream.title, style: display(36)),
          const SizedBox(height: 12),
          Text(
            formatDate(dream.date, en),
            style: const TextStyle(color: Palette.secondary),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (dream.mood != null)
                DreamChip(dream.mood!.label(en), color: moodColor(dream.mood)),
              DreamChip(dream.type.label(en)),
              if (dream.recurring)
                DreamChip(tr(en, 'Повторяется', 'Recurring')),
              if (dream.demo) DreamChip(tr(en, 'Пример', 'Sample')),
            ],
          ),
          const SizedBox(height: 26),
          DreamSurface(
            child: SelectableText(
              dream.description,
              style: const TextStyle(fontSize: 17, height: 1.75),
            ),
          ),
          for (final kind in ElementKind.values)
            if (dream.ofKind(kind).isNotEmpty) ...[
              const SizedBox(height: 28),
              SectionTitle(switch (kind) {
                ElementKind.symbol => tr(en, 'Символы', 'Symbols'),
                ElementKind.character => tr(en, 'Персонажи', 'Characters'),
                ElementKind.place => tr(en, 'Места', 'Places'),
              }),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in dream.ofKind(kind))
                    DreamChip(
                      e.name,
                      onTap: () => context.push(
                        '/elements/${Uri.encodeComponent(e.id)}',
                      ),
                    ),
                ],
              ),
            ],
          const SizedBox(height: 24),
          DreamSurface(
            child: Column(
              children: [
                _level(tr(en, 'Осознанность', 'Lucidity'), dream.lucidity, en),
                const SizedBox(height: 18),
                _level(tr(en, 'Яркость', 'Vividness'), dream.vividness, en),
                if (dream.theme != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      children: [
                        Expanded(child: Text(tr(en, 'Тема', 'Theme'))),
                        Text(dream.theme!.label(en)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          DreamButton(
            label: tr(en, 'Найти на карте', 'Show on Map'),
            icon: CupertinoIcons.sparkles,
            onPressed: () => context.go('/map?focus=$id'),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () async {
              if (!await confirm(
                context,
                en,
                tr(en, 'Удалить этот сон?', 'Delete this dream?'),
                tr(
                  en,
                  'Запись и её связи будут удалены.',
                  'This entry and its connections will be removed.',
                ),
              )) {
                return;
              }
              await ref.read(repositoryProvider).delete(id);
              if (context.mounted) context.pop();
            },
            child: Text(
              tr(en, 'Удалить сон', 'Delete Dream'),
              style: const TextStyle(color: Color(0xfff29ba9)),
            ),
          ),
        ],
      );
    },
  );
  Widget _level(String label, int? value, bool en) => Column(
    children: [
      Row(
        children: [
          Expanded(child: Text(label)),
          Text(value == null ? tr(en, 'Не указано', 'Not set') : '$value%'),
        ],
      ),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: LinearProgressIndicator(
          value: (value ?? 0) / 100,
          minHeight: 4,
          color: Palette.lavender,
          backgroundColor: Palette.raised,
        ),
      ),
    ],
  );
}
