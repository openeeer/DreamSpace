import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/design.dart';
import '../../core/internal_page.dart';
import '../../models/dream.dart';
import 'analytics.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});
  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int period = 30;
  @override
  Widget build(BuildContext context) => DreamsBuilder(
    builder: (all, en) {
      final now = DateTime.now(),
          start = DateTime.now().subtract(Duration(days: period));
      final dreams = period == 0
          ? all
          : all
                .where(
                  (d) => !d.date.isBefore(
                    DateTime(start.year, start.month, start.day),
                  ),
                )
                .toList();
      final stats = DreamStats(dreams), totalStats = DreamStats(all);
      final moods = stats.moods.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return DreamInternalPage(
        title: tr(en, 'Наблюдения', 'Insights'),
        subtitle: tr(
          en,
          'Узоры, которые оставляет ночь',
          'Patterns left behind by the night',
        ),
        children: [
          DreamSegmentedControl(
            value: period,
            options: {
              30: tr(en, '30 дней', '30 days'),
              90: tr(en, '90 дней', '90 days'),
              0: tr(en, 'Всё время', 'All time'),
            },
            onChanged: (v) => setState(() => period = v),
          ),
          const SizedBox(height: 24),
          DreamGlassSurface(
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.moon_stars,
                  color: Palette.lavender,
                  size: 44,
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${dreams.length}', style: display(54)),
                      Text(
                        tr(en, 'снов за этот период', 'dreams in this period'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (stats.elements(ElementKind.symbol).isNotEmpty) ...[
            DreamSettingsSection(
              children: [
                DreamSettingsRow(
                  icon: CupertinoIcons.sparkles,
                  title: stats.elements(ElementKind.symbol).first.key.name,
                  subtitle: tr(
                    en,
                    'Самый частый образ за выбранный период',
                    'Most frequent symbol in this period',
                  ),
                ),
                if (moods.isNotEmpty)
                  DreamSettingsRow(
                    icon: moodIcon(moods.first.key),
                    title: moods.first.key.label(en),
                    subtitle: tr(
                      en,
                      'Преобладающее настроение',
                      'Most frequent mood',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _tile(tr(en, 'Осознанных', 'Lucid dreams'), '${stats.lucid}'),
              _tile(
                tr(en, 'Серия сейчас', 'Current streak'),
                '${totalStats.streak}',
              ),
              _tile(
                tr(en, 'Лучшая серия', 'Longest streak'),
                '${totalStats.longest}',
              ),
              _tile(
                tr(en, 'Повторных символов', 'Recurring symbols'),
                '${stats.recurringSymbols}',
              ),
            ],
          ),
          const SizedBox(height: 28),
          SectionTitle(
            tr(en, 'Активность за 14 дней', 'Activity · last 14 days'),
          ),
          DreamGlassSurface(
            child: SizedBox(
              height: 130 + MediaQuery.textScalerOf(context).scale(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 13; i >= 0; i--)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final day = DateTime(
                                now.year,
                                now.month,
                                now.day - i,
                              ),
                              n = all
                                  .where(
                                    (d) =>
                                        dateKey(d.date) ==
                                        dateKey(
                                          DateTime(
                                            now.year,
                                            now.month,
                                            now.day - i,
                                          ),
                                        ),
                                  )
                                  .length;
                          return Semantics(
                            label: '${formatDate(day, en)}: $n',
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (n > 0)
                                    Text(
                                      '$n',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  const SizedBox(height: 5),
                                  Container(
                                    height: math.min(80, 8 + n * 22).toDouble(),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: Palette.lavender.withValues(
                                        alpha: n == 0 ? .12 : .75,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${day.day}',
                                    style: const TextStyle(fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          SectionTitle(tr(en, 'Палитра настроений', 'Mood distribution')),
          DreamGlassSurface(
            child: Column(
              children: [
                if (moods.isEmpty)
                  Text(
                    tr(
                      en,
                      'Укажи настроение в своём первом сне',
                      'Add a mood to your first dream',
                    ),
                  ),
                for (final entry in moods)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              moodIcon(entry.key),
                              size: 19,
                              color: moodColor(entry.key),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(entry.key.label(en))),
                            Text(
                              '${entry.value} · ${(entry.value / dreams.length * 100).round()}%',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.value / dreams.length,
                            color: moodColor(entry.key),
                            backgroundColor: Palette.raised,
                            minHeight: 5,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (dreams.any((d) => d.mood == null))
                  Text(
                    '${tr(en, 'Без настроения', 'Not specified')}: ${dreams.where((d) => d.mood == null).length}',
                  ),
              ],
            ),
          ),
          for (final kind in [ElementKind.symbol, ElementKind.place]) ...[
            const SizedBox(height: 28),
            SectionTitle(
              kind == ElementKind.symbol
                  ? tr(en, 'Повторяющиеся образы', 'Recurring symbols')
                  : tr(en, 'Знакомые места', 'Familiar places'),
            ),
            DreamGlassSurface(
              child: Column(
                children: [
                  if (stats.elements(kind).isEmpty)
                    Text(tr(en, 'Пока нет данных', 'No data yet')),
                  for (final item in stats.elements(kind).take(5))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.key.name)),
                          Text('${item.value}'),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          SectionTitle(tr(en, 'Темы снов', 'Dream themes')),
          DreamGlassSurface(
            child: Column(
              children: [
                for (final entry in stats.themes.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.key.label(en))),
                        Text(
                          '${(entry.value / stats.themes.values.fold<int>(0, (a, b) => a + b) * 100).round()}%',
                        ),
                      ],
                    ),
                  ),
                Text(
                  tr(
                    en,
                    'Доля среди снов с указанной темой',
                    'Share of dreams with a theme',
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Palette.secondary,
                  ),
                ),
              ],
            ),
          ),
          if (all.any((d) => d.demo))
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                tr(
                  en,
                  'Статистика включает демонстрационные записи.',
                  'Statistics include sample dreams.',
                ),
                style: const TextStyle(fontSize: 12, color: Palette.secondary),
              ),
            ),
        ],
      );
    },
  );
  Widget _tile(String title, String value) => SizedBox(
    width: 150,
    child: DreamGlassSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: display(32)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    ),
  );
}
