import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import '../../core/native_presentations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/design.dart';
import '../../core/native_glass.dart';
import '../../data/providers.dart';
import '../../models/dream.dart';

class JournalGlass extends ConsumerWidget {
  const JournalGlass({
    super.key,
    required this.child,
    this.radius = 24,
    this.accent = false,
    this.floating = false,
  });
  final Widget child;
  final double radius;
  final bool accent;
  final bool floating;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (usesNativeGlass) {
      if (child case final JournalIconButton button) {
        return NativeGlassButton(
          label: button.label,
          icon: button.icon,
          prominent: accent,
          onPressed: button.onPressed,
        );
      }
      if (floating) return NativeGlassBackdrop(radius: radius, child: child);
    }
    final light = Theme.of(context).brightness == Brightness.light;
    final opaque =
        ref.watch(settingsProvider)['opaque'] == 'true' ||
        MediaQuery.highContrastOf(context);
    // Deep Tide: tonal plate; an accent panel is the moonlit jade well,
    // the single interactive plate style.
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: accent
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xff17604c), Color(0xff0d382e)],
              )
            : null,
        color: accent
            ? null
            : (light
                  ? Colors.white.withValues(alpha: opaque ? 1 : .96)
                  : Palette.surface.withValues(alpha: opaque ? 1 : .93)),
        border: Border.all(
          color: accent
              ? Palette.lavender.withValues(alpha: .45)
              : Palette.hairline(light),
          width: .7,
        ),
      ),
      child: child,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: surface,
    );
  }
}

class JournalIconButton extends StatelessWidget {
  const JournalIconButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.glass = true,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool glass;
  @override
  Widget build(BuildContext context) {
    if (usesNativeGlass && nativeSymbol(icon) != null) {
      return NativeGlassButton(
        label: label,
        icon: icon,
        onPressed: onPressed,
        glass: glass,
      );
    }
    return Tooltip(
      message: label,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        onPressed: onPressed,
        child: Icon(
          icon,
          size: 19,
          semanticLabel: label,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
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
    if (usesNativeGlass) {
      return NativeGlassButton(
        label: label,
        selected: selected,
        onPressed: () {
          if (ref.read(settingsProvider)['haptics'] != 'false') {
            HapticFeedback.selectionClick();
          }
          onTap();
        },
      );
    }
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
            borderRadius: BorderRadius.circular(11),
            color: Palette.lavender.withValues(alpha: selected ? .22 : .06),
            border: selected
                ? Border.all(color: Palette.lavender.withValues(alpha: .7), width: .7)
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: selected
                  ? Palette.lavender
                  : Theme.of(context).colorScheme.onSurface,
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

/// Museum plate for the journal: framed painting, caption beneath it on the
/// page. The scrim era is over — the art never carries text again.
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

  Future<void> failure() => dreamAlert(
    context,
    title: tr(
      widget.en,
      'Не удалось выполнить действие',
      'Could not complete action',
    ),
    message: tr(widget.en, 'Попробуй ещё раз.', 'Please try again.'),
    closeLabel: tr(widget.en, 'Закрыть', 'Close'),
  );

  Future<void> menu() async {
    final en = widget.en, dream = widget.dream;
    final action = await dreamActionSheet(
      context,
      title: dreamTitle(dream, en),
      actions: [
        ('edit', tr(en, 'Редактировать', 'Edit')),
        (
          'favorite',
          dream.favorite
              ? tr(en, 'Убрать из избранного', 'Remove from favorites')
              : tr(en, 'В избранное', 'Add to favorites'),
        ),
        ('share', tr(en, 'Поделиться', 'Share')),
        ('delete', tr(en, 'Удалить', 'Delete')),
      ],
      cancelLabel: tr(en, 'Отмена', 'Cancel'),
      destructive: const {'delete'},
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
        padding: const EdgeInsets.only(bottom: Rhythm.section),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Framed painting. Press feedback: the art dims.
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 120),
                  opacity: pressed && !reduced ? .78 : 1,
                  child: SizedBox(
                    height:
                        math.max(170.0, c.maxWidth / 2.2) * math.max(1, scale),
                    child: DreamArtwork(dream.artwork, radius: 20),
                  ),
                ),
                // Museum caption: on the page, under the frame.
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 10, 2, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              formatDate(dream.date, en),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                letterSpacing: .3,
                                color: Palette.secondary,
                              ),
                            ),
                          ),
                          // Actions live in the caption row, quiet and
                          // reachable, not floating over the art.
                          TweenAnimationBuilder<double>(
                            key: ValueKey(dream.favorite),
                            tween: Tween(
                              begin:
                                  dream.favorite &&
                                  !reduced &&
                                  !usesNativeGlass
                                  ? 1.18
                                  : 1,
                              end: 1,
                            ),
                            duration: const Duration(milliseconds: 220),
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
                      const SizedBox(height: 3),
                      Text(
                        dreamTitle(dream, en),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: diary(
                          19,
                        ).copyWith(color: Palette.text, height: 1.12),
                      ),
                      const SizedBox(height: Rhythm.s),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (dream.pendingProcessing)
                            JournalStatusChip(en: en, dream: dream),
                          if (dream.mood != null)
                            JournalTag(
                              dream.mood!.label(en),
                              color: moodColor(dream.mood),
                            ),
                          JournalTag(dream.type.label(en)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
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
    // Tonal tag: soft fill, no border — mood color carries the meaning.
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, height: 1.2, color: color),
    ),
  );
}

/// Quiet badge for server-pending or offline-queued dreams. Tapping it opens
/// the live processing view instead of the dream detail — the dreamer sees
/// what stage the assistant is on. Never blocks the rest of the card.
class JournalStatusChip extends StatelessWidget {
  const JournalStatusChip({super.key, required this.en, required this.dream});
  final bool en;
  final Dream dream;
  @override
  Widget build(BuildContext context) {
    final color = dream.status == ProcessingStatus.failed
        ? Palette.gold
        : Palette.blue;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/processing/${dream.id}'),
      child: Semantics(
        label: dream.status == ProcessingStatus.failed
            ? tr(en, 'Обработка не удалась. Открыть статус', 'Processing failed. Open status')
            : tr(en, 'Ещё обрабатывается. Открыть статус', 'Still processing. Open status'),
        button: true,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                dream.status == ProcessingStatus.failed
                    ? CupertinoIcons.wifi_exclamationmark
                    : CupertinoIcons.hourglass,
                size: 9,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                dream.status == ProcessingStatus.failed
                    ? tr(en, 'ждёт сети', 'awaiting network')
                    : tr(en, 'обрабатывается', 'processing'),
                style: TextStyle(fontSize: 10, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
