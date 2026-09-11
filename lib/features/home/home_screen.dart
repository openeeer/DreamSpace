import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../models/dream.dart';
import '../dream_map/map_screen.dart';
import '../insights/analytics.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => DreamsBuilder(
    builder: (dreams, en) {
      final stats = DreamStats(dreams);
      final themes = stats.themes.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return DreamPage(
        title: 'DreamSpace',
        subtitle: tr(en, 'Твой дневник сновидений', 'Your dream journal'),
        actions: [
          DreamSurface(
            radius: 40,
            padding: EdgeInsets.zero,
            child: IconButton(
              tooltip: tr(en, 'Профиль', 'Profile'),
              onPressed: () => context.go('/profile'),
              icon: const Icon(
                CupertinoIcons.moon_fill,
                color: Palette.lavender,
                size: 27,
              ),
            ),
          ),
        ],
        children: [
          if (dreams.isEmpty)
            EmptyDreams(en: en)
          else ...[
            Text(
              tr(en, 'ПОСЛЕДНИЙ СОН', 'LAST DREAM'),
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 2.8,
                color: Palette.secondary,
              ),
            ),
            const SizedBox(height: 12),
            DreamCard(dreams.first, en: en, large: true),
            DreamButton(
              label: tr(en, 'Записать сон', 'Record Dream'),
              onPressed: () => context.push('/record'),
            ),
            const SizedBox(height: 10),
            Text(
              tr(en, 'Каждый сон имеет значение', 'Every dream matters'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Palette.secondary,
                letterSpacing: .5,
              ),
            ),
            const SizedBox(height: 26),
            DreamSurface(
              child: Column(
                children: [
                  SectionTitle(
                    tr(en, 'Настроение снов', 'Dream Mood'),
                    action: tr(en, 'Все', 'See All'),
                    onTap: () => context.push('/insights'),
                  ),
                  SizedBox(
                    height: 102,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final mood in [
                          Mood.calm,
                          Mood.strange,
                          Mood.happy,
                          Mood.peaceful,
                          Mood.mysterious,
                        ])
                          MoodOrb(
                            mood,
                            en: en,
                            onTap: () =>
                                context.go('/journal?mood=${mood.name}'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DreamSurface(
              onTap: () => context.go('/map'),
              child: Column(
                children: [
                  SectionTitle(
                    tr(en, 'Карта снов', 'Dream Map'),
                    action: tr(en, 'Открыть', 'Explore'),
                    onTap: () => context.go('/map'),
                  ),
                  MapPreview(dreams),
                  Text(
                    tr(
                      en,
                      'Твои сны связаны между собой',
                      'Your dreams are connected',
                    ),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Palette.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionTitle(
              tr(en, 'Наблюдения', 'Insights'),
              action: tr(en, 'Все', 'See All'),
              onTap: () => context.push('/insights'),
            ),
            LayoutBuilder(
              builder: (context, c) {
                final width = (c.maxWidth - 20) / 3;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Metric(
                      icon: CupertinoIcons.sparkles,
                      title: tr(en, 'Символы', 'Symbols'),
                      value: '${stats.recurringSymbols}',
                      subtitle: tr(en, 'повторяются', 'recurring'),
                      width: width < 110 ? c.maxWidth : width,
                      onTap: () => context.push('/elements'),
                    ),
                    _Metric(
                      icon: CupertinoIcons.flame,
                      title: tr(en, 'Серия', 'Streak'),
                      value: '${stats.streak}',
                      subtitle: tr(en, 'дней подряд', 'days in a row'),
                      width: width < 110 ? c.maxWidth : width,
                      onTap: () => context.push('/calendar'),
                    ),
                    _Metric(
                      icon: CupertinoIcons.moon_stars,
                      title: tr(en, 'Тема', 'Theme'),
                      value: themes.isEmpty ? '—' : themes.first.key.label(en),
                      subtitle: tr(en, 'чаще всего', 'most common'),
                      width: width < 110 ? c.maxWidth : width,
                      onTap: () => context.push('/insights'),
                    ),
                  ],
                );
              },
            ),
            if (dreams.any((d) => d.demo))
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(
                  tr(
                    en,
                    'Включены примеры снов · Управление в профиле',
                    'Includes sample dreams · Manage in Profile',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Palette.secondary,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 30),
          Text(
            tr(en, 'ПУСТЬ ПРИСНИТСЯ ПРЕКРАСНОЕ', 'SWEETER DREAMS AHEAD'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 2.6,
              color: Palette.secondary,
            ),
          ),
        ],
      );
    },
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.width,
    required this.onTap,
  });
  final IconData icon;
  final String title, value, subtitle;
  final double width;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: DreamSurface(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Palette.lavender, size: 23),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 9),
          Text(value, style: display(value.length > 5 ? 19 : 31)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Palette.secondary),
          ),
        ],
      ),
    ),
  );
}
