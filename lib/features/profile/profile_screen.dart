import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../data/providers.dart';
import '../dreams/journal_components.dart';
import '../insights/analytics.dart';
import 'profile_hero.dart';

abstract final class ProfileStyle {
  static const maxWidth = 460.0;
  static const gutter = 22.0;
  static const panelRadius = 27.0;
  static const divider = Color(0x26baa6ef);
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => DreamsBuilder(
    builder: (dreams, en) {
      final stats = DreamStats(dreams), settings = ref.watch(settingsProvider);
      final joined = DateTime.tryParse(settings['joined'] ?? '');
      final light = Theme.of(context).brightness == Brightness.light;
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        (light ? Colors.white : Palette.night).withValues(
                          alpha: .2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 300,
              child: ProfileLandscape(),
            ),
            CustomScrollView(
              key: const PageStorageKey('profile-scroll'),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: ProfileStyle.maxWidth,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          ProfileStyle.gutter,
                          MediaQuery.paddingOf(context).top + 24,
                          ProfileStyle.gutter,
                          MediaQuery.viewPaddingOf(context).bottom + 122,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    tr(en, 'Мой мир', 'My Universe'),
                                    style: display(
                                      MediaQuery.sizeOf(context).width < 360
                                          ? 35
                                          : 42,
                                    ).copyWith(height: 1.05),
                                  ),
                                ),
                                DreamGlassIconButton(en: en),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    tr(
                                      en,
                                      'Здесь живут твои сны\nи самые смелые идеи',
                                      'Your dreams and boldest\nideas live here',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.35,
                                      color: Palette.secondary,
                                    ),
                                  ),
                                ),
                                ProfileHandwritten(en: en),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const DreamProfileHero(),
                            Text(
                              tr(en, 'Исследователь снов', 'Dream Explorer'),
                              textAlign: TextAlign.center,
                              style: display(28).copyWith(height: 1.2),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              joined == null
                                  ? 'DreamSpace'
                                  : '${tr(en, 'В DreamSpace с', 'Dreamer since')} ${formatDate(joined, en)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                letterSpacing: 1,
                                height: 1.4,
                                color: Palette.secondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            DreamStatsPanel(
                              total: dreams.length,
                              streak: stats.streak,
                              lucid: stats.lucid,
                              en: en,
                            ),
                            const SizedBox(height: 16),
                            DreamProfileMenu(en: en),
                            const SizedBox(height: 24),
                            DreamPrivacyQuote(en: en),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (!light)
              Positioned(
                left: -30,
                right: -30,
                bottom: -20,
                height: 110,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: Opacity(
                      opacity: .43,
                      child: Image.asset(
                        'assets/backgrounds/nebula_foreground.webp',
                        fit: BoxFit.cover,
                        cacheWidth: 1000,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class DreamGlassIconButton extends ConsumerWidget {
  const DreamGlassIconButton({super.key, required this.en});
  final bool en;
  @override
  Widget build(BuildContext context, WidgetRef ref) => JournalGlass(
    radius: 28,
    child: SizedBox(
      width: 50,
      height: 50,
      child: JournalIconButton(
        label: tr(en, 'Настройки', 'Settings'),
        icon: CupertinoIcons.gear,
        onPressed: () {
          if (ref.read(settingsProvider)['haptics'] != 'false') {
            HapticFeedback.selectionClick();
          }
          context.push('/settings');
        },
      ),
    ),
  );
}

class DreamStatsPanel extends StatelessWidget {
  const DreamStatsPanel({
    super.key,
    required this.total,
    required this.streak,
    required this.lucid,
    required this.en,
  });
  final int total, streak, lucid;
  final bool en;
  @override
  Widget build(BuildContext context) => JournalGlass(
    radius: ProfileStyle.panelRadius,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: VerticalDivider(
                    width: 1,
                    thickness: .7,
                    color: ProfileStyle.divider,
                  ),
                ),
              Expanded(
                child: Semantics(
                  label: [
                    tr(en, '$total записанных снов', '$total recorded dreams'),
                    tr(en, '$streak дней подряд', '$streak day streak'),
                    tr(en, '$lucid осознанных сна', '$lucid lucid dreams'),
                  ][i],
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      Icon(
                        [
                          CupertinoIcons.sparkles,
                          CupertinoIcons.leaf_arrow_circlepath,
                          CupertinoIcons.cloud,
                        ][i],
                        size: 22,
                        color: Palette.lavender,
                      ),
                      const SizedBox(height: 5),
                      Text('${[total, streak, lucid][i]}', style: display(32)),
                      const SizedBox(height: 5),
                      Text(
                        [
                          tr(en, 'СНОВ', 'DREAMS'),
                          tr(en, 'ДНЕЙ ПОДРЯД', 'DAY STREAK'),
                          tr(en, 'ОСОЗНАННЫХ', 'LUCID'),
                        ][i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9,
                          letterSpacing: .9,
                          color: Palette.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class DreamProfileMenu extends StatelessWidget {
  const DreamProfileMenu({super.key, required this.en});
  final bool en;
  @override
  Widget build(BuildContext context) {
    final items = [
      (
        CupertinoIcons.photo,
        tr(en, 'Коллекция образов', 'Dream Elements'),
        tr(
          en,
          'Сохранённые места, люди и символы',
          'Saved places, people and symbols',
        ),
        '/elements',
      ),
      (
        CupertinoIcons.chart_bar_fill,
        tr(en, 'Наблюдения', 'Insights'),
        tr(en, 'Аналитика твоих снов', 'Patterns in your dreams'),
        '/insights',
      ),
      (
        CupertinoIcons.calendar,
        tr(en, 'Календарь снов', 'Dream Calendar'),
        tr(en, 'История по дням', 'Your history, day by day'),
        '/calendar',
      ),
      (
        CupertinoIcons.gear,
        tr(en, 'Настройки', 'Settings'),
        tr(en, 'Персонализация и параметры', 'Personalization and preferences'),
        '/settings',
      ),
    ];
    return JournalGlass(
      radius: ProfileStyle.panelRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  thickness: .7,
                  indent: 60,
                  color: ProfileStyle.divider,
                ),
              DreamProfileMenuItem(
                icon: items[i].$1,
                title: items[i].$2,
                subtitle: items[i].$3,
                path: items[i].$4,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DreamProfileMenuItem extends ConsumerWidget {
  const DreamProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.path,
  });
  final IconData icon;
  final String title, subtitle, path;
  @override
  Widget build(BuildContext context, WidgetRef ref) => CupertinoButton(
    padding: const EdgeInsets.symmetric(vertical: 12),
    onPressed: () {
      if (ref.read(settingsProvider)['haptics'] != 'false') {
        HapticFeedback.selectionClick();
      }
      context.push(path);
    },
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Palette.lavender.withValues(alpha: .24),
                Palette.lavender.withValues(alpha: .07),
              ],
            ),
            border: Border.all(
              color: Palette.lavender.withValues(alpha: .3),
              width: .7,
            ),
          ),
          child: Icon(icon, color: Palette.lavender, size: 23),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: display(
                  19,
                ).copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  height: 1.35,
                  color: Palette.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          CupertinoIcons.chevron_right,
          size: 17,
          color: Palette.lavender,
        ),
      ],
    ),
  );
}

class DreamPrivacyQuote extends StatelessWidget {
  const DreamPrivacyQuote({super.key, required this.en});
  final bool en;
  @override
  Widget build(BuildContext context) => Center(
    child: FractionallySizedBox(
      widthFactor: .86,
      child: Column(
        children: [
          Text(
            tr(
              en,
              '«Твои сны хранятся на этом устройстве.\nТолько ты решаешь, с кем ими поделиться».',
              '“Your dreams live on this device.\nYou decide who to share them with.”',
            ),
            textAlign: TextAlign.center,
            style: display(13).copyWith(
              fontStyle: FontStyle.italic,
              color: Palette.secondary,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 36,
            height: .7,
            color: Palette.lavender.withValues(alpha: .55),
          ),
        ],
      ),
    ),
  );
}
