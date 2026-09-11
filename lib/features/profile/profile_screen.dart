import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../data/providers.dart';
import '../insights/analytics.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => DreamsBuilder(
    builder: (dreams, en) {
      final stats = DreamStats(dreams), settings = ref.watch(settingsProvider);
      final joined = DateTime.tryParse(settings['joined'] ?? '');
      return DreamPage(
        title: tr(en, 'Мой мир', 'My Universe'),
        actions: [
          IconButton(
            tooltip: tr(en, 'Настройки', 'Settings'),
            onPressed: () => context.push('/settings'),
            icon: const Icon(CupertinoIcons.gear),
          ),
        ],
        children: [
          Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-.4, -.5),
                  colors: [Color(0xff615997), Palette.surface],
                ),
                border: Border.all(
                  color: Palette.lavender.withValues(alpha: .5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Palette.lavender.withValues(alpha: .15),
                    blurRadius: 35,
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.moon_fill,
                color: Palette.lavender,
                size: 53,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Text(
              tr(en, 'Исследователь снов', 'Dream Explorer'),
              style: display(28),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              joined == null
                  ? 'DreamSpace'
                  : '${tr(en, 'В DreamSpace с', 'Dreamer since')} ${formatDate(joined, en)}',
              style: const TextStyle(fontSize: 13, color: Palette.secondary),
            ),
          ),
          const SizedBox(height: 30),
          DreamSurface(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('${dreams.length}', tr(en, 'снов', 'dreams')),
                _stat('${stats.streak}', tr(en, 'дней подряд', 'day streak')),
                _stat('${stats.lucid}', tr(en, 'осознанных', 'lucid')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DreamSurface(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                _link(
                  context,
                  CupertinoIcons.sparkles,
                  tr(en, 'Коллекция образов', 'Dream Elements'),
                  '/elements',
                ),
                _link(
                  context,
                  CupertinoIcons.chart_bar,
                  tr(en, 'Наблюдения', 'Insights'),
                  '/insights',
                ),
                _link(
                  context,
                  CupertinoIcons.calendar,
                  tr(en, 'Календарь снов', 'Dream Calendar'),
                  '/calendar',
                ),
                _link(
                  context,
                  CupertinoIcons.gear,
                  tr(en, 'Настройки', 'Settings'),
                  '/settings',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            tr(
              en,
              'Твои сны хранятся на этом устройстве.\nТолько ты решаешь, с кем ими поделиться.',
              'Your dreams live on this device.\nYou decide who to share them with.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Palette.secondary,
              fontSize: 13,
              height: 1.7,
            ),
          ),
        ],
      );
    },
  );
  Widget _stat(String value, String label) => Flexible(
    child: Column(
      children: [
        Text(value, style: display(32)),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    ),
  );
  Widget _link(
    BuildContext context,
    IconData icon,
    String title,
    String path,
  ) => ListTile(
    leading: Icon(icon, color: Palette.lavender),
    title: Text(title),
    trailing: const Icon(CupertinoIcons.chevron_right, size: 15),
    onTap: () => context.push(path),
  );
}
