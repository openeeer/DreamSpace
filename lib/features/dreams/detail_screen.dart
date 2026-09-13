import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/design.dart';
import '../../core/internal_page.dart';
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
        return DreamInternalPage(
          title: tr(en, 'Сон не найден', 'Dream not found'),
          children: const [],
        );
      }
      return DreamInternalPage(
        title: tr(en, 'Сон', 'Dream'),
        compact: true,
        hero: SizedBox(
          height: 290,
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (r) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0, .65, 1],
            ).createShader(r),
            child: DreamArtwork(dream.artwork, radius: 0),
          ),
        ),
        actions: [
          DreamGlassAction(
            label: tr(en, 'Избранное', 'Favorite'),
            onPressed: () => ref
                .read(repositoryProvider)
                .save(dream.copyWith(favorite: !dream.favorite)),
            icon: dream.favorite
                ? CupertinoIcons.heart_fill
                : CupertinoIcons.heart,
          ),
          DreamGlassAction(
            label: tr(en, 'Редактировать', 'Edit'),
            onPressed: () => context.push('/record?id=$id'),
            icon: CupertinoIcons.pencil,
          ),
          DreamGlassAction(
            label: tr(en, 'Действия со сном', 'Dream actions'),
            icon: CupertinoIcons.ellipsis,
            onPressed: () => actions(context, ref, dream, en),
          ),
        ],
        children: [
          Text(
            formatDate(dream.date, en),
            style: const TextStyle(color: Palette.secondary),
          ),
          const SizedBox(height: 18),
          Text(dreamTitle(dream, en), style: display(34)),
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
          DreamGlassSurface(
            child: SelectableText(
              dream.description,
              style: const TextStyle(fontSize: 17, height: 1.55),
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
          DreamGlassSurface(
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
        ],
      );
    },
  );
  Future<void> actions(
    BuildContext context,
    WidgetRef ref,
    Dream dream,
    bool en,
  ) async {
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(dreamTitle(dream, en)),
        actions: [
          for (final (value, title) in [
            ('edit', tr(en, 'Редактировать', 'Edit')),
            ('share', tr(en, 'Поделиться', 'Share')),
            ('delete', tr(en, 'Удалить сон', 'Delete Dream')),
          ])
            CupertinoActionSheetAction(
              isDestructiveAction: value == 'delete',
              onPressed: () => Navigator.pop(ctx, value),
              child: Text(title),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(tr(en, 'Отмена', 'Cancel')),
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'edit') context.push('/record?id=$id');
    if (action == 'share') {
      final box = context.findRenderObject() as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          text:
              '${dreamTitle(dream, en)}\n${formatDate(dream.date, en)}\n\n${dream.description}',
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    }
    if (context.mounted &&
        action == 'delete' &&
        await confirm(
          context,
          en,
          tr(en, 'Удалить этот сон?', 'Delete this dream?'),
          tr(
            en,
            'Запись и её связи будут удалены.',
            'This entry and its connections will be removed.',
          ),
        )) {
      await ref.read(repositoryProvider).delete(id);
      if (context.mounted) context.pop();
    }
  }

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
