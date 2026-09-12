import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/design.dart';
import '../../data/providers.dart';
import '../../models/dream.dart';

class JournalGlass extends ConsumerWidget {
  const JournalGlass({
    super.key,
    required this.child,
    this.radius = 24,
    this.accent = false,
  });
  final Widget child;
  final double radius;
  final bool accent;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final light = Theme.of(context).brightness == Brightness.light;
    final opaque =
        ref.watch(settingsProvider)['opaque'] == 'true' ||
        MediaQuery.highContrastOf(context);
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: accent
              ? [const Color(0xaaab8bf6), const Color(0x776e57bd)]
              : light
              ? [const Color(0xeef5f2fc), const Color(0xccdfdaee)]
              : [
                  Color(opaque ? 0xff171c3c : 0x66171c3c),
                  Color(opaque ? 0xff0e142f : 0x440e142f),
                ],
        ),
        border: Border.all(
          color: Palette.lavender.withValues(alpha: accent ? .65 : .24),
          width: .7,
        ),
      ),
      child: child,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: opaque
          ? surface
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: surface,
            ),
    );
  }
}

class JournalIconButton extends StatelessWidget {
  const JournalIconButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      onPressed: onPressed,
      child: Icon(
        icon,
        size: 21,
        semanticLabel: label,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

class JournalFilter extends ConsumerWidget {
  const JournalFilter({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        ref.watch(settingsProvider)['animations'] == 'reduced';
    return Semantics(
      selected: selected,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        onPressed: () {
          if (ref.read(settingsProvider)['haptics'] != 'false') {
            HapticFeedback.selectionClick();
          }
          onTap();
        },
        child: AnimatedContainer(
          duration: reduced ? Duration.zero : const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            color: Palette.lavender.withValues(alpha: selected ? .28 : .055),
            border: Border.all(
              color: Palette.lavender.withValues(alpha: selected ? .8 : .22),
              width: .7,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Palette.lavender.withValues(alpha: .2),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class DreamJournalCard extends ConsumerStatefulWidget {
  const DreamJournalCard({super.key, required this.dream, required this.en});
  final Dream dream;
  final bool en;
  @override
  ConsumerState<DreamJournalCard> createState() => _DreamJournalCardState();
}

class _DreamJournalCardState extends ConsumerState<DreamJournalCard> {
  bool pressed = false, saving = false;
  Future<void> favorite() async {
    if (saving) return;
    setState(() => saving = true);
    if (ref.read(settingsProvider)['haptics'] != 'false') {
      HapticFeedback.lightImpact();
    }
    try {
      await ref
          .read(repositoryProvider)
          .save(widget.dream.copyWith(favorite: !widget.dream.favorite));
    } catch (_) {
      if (mounted) await failure();
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> failure() => showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(
        tr(
          widget.en,
          'Не удалось выполнить действие',
          'Could not complete action',
        ),
      ),
      content: Text(tr(widget.en, 'Попробуй ещё раз.', 'Please try again.')),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(tr(widget.en, 'Закрыть', 'Close')),
        ),
      ],
    ),
  );

  Future<void> menu() async {
    final en = widget.en, dream = widget.dream;
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(dreamTitle(dream, en)),
        actions: [
          for (final (id, label) in [
            ('edit', tr(en, 'Редактировать', 'Edit')),
            (
              'favorite',
              dream.favorite
                  ? tr(en, 'Убрать из избранного', 'Remove from favorites')
                  : tr(en, 'В избранное', 'Add to favorites'),
            ),
            ('share', tr(en, 'Поделиться', 'Share')),
            ('delete', tr(en, 'Удалить', 'Delete')),
          ])
            CupertinoActionSheetAction(
              isDestructiveAction: id == 'delete',
              onPressed: () => Navigator.pop(ctx, id),
              child: Text(label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(tr(en, 'Отмена', 'Cancel')),
        ),
      ),
    );
    if (!mounted || action == null) return;
    try {
      switch (action) {
        case 'edit':
          context.push('/record?id=${dream.id}');
        case 'favorite':
          await favorite();
        case 'share':
          final box = context.findRenderObject() as RenderBox;
          await SharePlus.instance.share(
            ShareParams(
              title: dreamTitle(dream, en),
              text:
                  '${dreamTitle(dream, en)}\n${formatDate(dream.date, en)}\n\n${dream.description}',
              sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
            ),
          );
        case 'delete':
          if (await confirm(
                context,
                en,
                tr(en, 'Удалить этот сон?', 'Delete this dream?'),
                tr(
                  en,
                  'Запись и её связи будут удалены.',
                  'This entry and its connections will be removed.',
                ),
              ) &&
              mounted) {
            await ref.read(repositoryProvider).delete(dream.id);
          }
      }
    } catch (_) {
      if (mounted) await failure();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dream = widget.dream, en = widget.en;
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        ref.watch(settingsProvider)['animations'] == 'reduced';
    final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
    return LayoutBuilder(
      builder: (context, c) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: AnimatedScale(
          scale: pressed && !reduced ? .985 : 1,
          duration: const Duration(milliseconds: 110),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => pressed = true),
            onTapUp: (_) => setState(() => pressed = false),
            onTapCancel: () => setState(() => pressed = false),
            onTap: () => context.push('/dream/${dream.id}'),
            onLongPress: menu,
            child: Semantics(
              button: true,
              label: dreamTitle(dream, en),
              child: Container(
                height: math.max(198.0, c.maxWidth / 1.85) * math.max(1, scale),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33080c29), blurRadius: 22),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/dreams/${dream.artwork}.webp',
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      errorBuilder: (_, error, stack) =>
                          DreamArtwork(dream.artwork),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xf5080d25),
                            Color(0xc0080d25),
                            Color(0x05080d25),
                          ],
                          stops: [0, .44, 1],
                        ),
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x66080d25)],
                          stops: [.65, 1],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 13, 10, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatDate(dream.date, en),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Palette.secondary,
                            ),
                          ),
                          const SizedBox(height: 7),
                          FractionallySizedBox(
                            widthFactor: .88,
                            child: Text(
                              dreamTitle(dream, en),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: display(
                                23,
                              ).copyWith(color: Palette.text, height: 1.15),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: FractionallySizedBox(
                              widthFactor: .62,
                              alignment: Alignment.topLeft,
                              child: LayoutBuilder(
                                builder: (context, area) => Text(
                                  dream.description,
                                  maxLines:
                                      (area.maxHeight /
                                              MediaQuery.textScalerOf(
                                                context,
                                              ).scale(17.55))
                                          .floor()
                                          .clamp(1, 5),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: Palette.secondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (dream.mood != null)
                                      JournalTag(
                                        dream.mood!.label(en),
                                        color: moodColor(dream.mood),
                                      ),
                                    JournalTag(dream.type.label(en)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xbb171b38),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Palette.lavender.withValues(
                                      alpha: .18,
                                    ),
                                    width: .6,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TweenAnimationBuilder<double>(
                                      key: ValueKey(dream.favorite),
                                      tween: Tween(
                                        begin: dream.favorite && !reduced
                                            ? 1.18
                                            : 1,
                                        end: 1,
                                      ),
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      builder: (context, value, child) =>
                                          Transform.scale(
                                            scale: value,
                                            child: child,
                                          ),
                                      child: JournalIconButton(
                                        label: dream.favorite
                                            ? tr(
                                                en,
                                                'Убрать из избранного',
                                                'Remove from favorites',
                                              )
                                            : tr(
                                                en,
                                                'В избранное',
                                                'Add to favorites',
                                              ),
                                        icon: dream.favorite
                                            ? CupertinoIcons.heart_fill
                                            : CupertinoIcons.heart,
                                        onPressed: saving ? null : favorite,
                                      ),
                                    ),
                                    JournalIconButton(
                                      label: tr(
                                        en,
                                        'Действия со сном',
                                        'Dream actions',
                                      ),
                                      icon: CupertinoIcons.ellipsis,
                                      onPressed: menu,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(23),
                          border: Border.all(
                            color: Palette.lavender.withValues(alpha: .23),
                            width: .7,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class JournalTag extends StatelessWidget {
  const JournalTag(this.label, {super.key, this.color = Palette.lavender});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: .3), width: .6),
    ),
    child: Text(label, style: TextStyle(fontSize: 10, color: color)),
  );
}
