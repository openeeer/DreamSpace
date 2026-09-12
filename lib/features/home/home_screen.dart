import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../data/providers.dart';
import '../../models/dream.dart';
import '../dream_map/map_screen.dart';

abstract final class HomeStyle {
  static const ink = Color(0xff080e29);
  static const glass = Color(0x70121838);
  static const border = Color(0x55b6a5ff);
  static const text = Color(0xfff5f1ff);
  static const muted = Color(0xffbebbd4);
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final scroll = ScrollController();
  final pages = PageController();
  int page = 0;
  @override
  void dispose() {
    scroll.dispose();
    pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DreamsBuilder(
    builder: (dreams, en) {
      final reduced =
          MediaQuery.disableAnimationsOf(context) ||
          ref.watch(settingsProvider)['animations'] == 'reduced';
      final light = Theme.of(context).brightness == Brightness.light;
      final recent = [...dreams]..sort((a, b) => b.date.compareTo(a.date));
      final featured = recent.take(5).toList();
      return Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final gutter = width < 370 ? 18.0 : 22.0;
            final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
            final cardHeight =
                math.max(204.0, (width - gutter * 2) / 2.05) *
                math.max(1, scale);
            return Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: scroll,
                      builder: (context, _) => Stack(
                        children: [
                          Positioned(
                            top:
                                MediaQuery.paddingOf(context).top -
                                28 -
                                (reduced || !scroll.hasClients
                                    ? 0
                                    : scroll.offset * .2),
                            right: -width * .03,
                            width: width * .94,
                            height: width * .78,
                            child: Opacity(
                              opacity: light ? .28 : .95,
                              child: const _FadedLibrary(),
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.transparent,
                                    (light ? Colors.white : HomeStyle.ink)
                                        .withValues(alpha: .35),
                                  ],
                                  stops: const [0, .5, 1],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                CustomScrollView(
                  key: const PageStorageKey('home-scroll'),
                  controller: scroll,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        gutter,
                        MediaQuery.paddingOf(context).top + 30,
                        gutter,
                        MediaQuery.viewPaddingOf(context).bottom + 122,
                      ),
                      sliver: SliverList.list(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'DreamSpace',
                                        style: display(
                                          width < 370 ? 34 : 40,
                                        ).copyWith(letterSpacing: -1.5),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _Glass(
                                      padding: EdgeInsets.zero,
                                      radius: 30,
                                      child: CupertinoButton(
                                        padding: const EdgeInsets.all(12),
                                        onPressed: () {
                                          if (ref.read(
                                                settingsProvider,
                                              )['haptics'] !=
                                              'false') {
                                            HapticFeedback.selectionClick();
                                          }
                                          context.go('/profile');
                                        },
                                        child: Icon(
                                          CupertinoIcons.moon_fill,
                                          size: 26,
                                          color: light
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Palette.lavender,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr(
                                    en,
                                    'Твой дневник сновидений',
                                    'Your dream journal',
                                  ),
                                  style: TextStyle(
                                    fontSize: width < 370 ? 15 : 17,
                                    color: light
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onSurface
                                        : HomeStyle.muted,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  tr(
                                    en,
                                    'БЛИЖЕ\nК СВОЕМУ МИРУ',
                                    'CLOSER\nTO YOUR INNER WORLD',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 4,
                                    height: 1.9,
                                    color: Palette.secondary,
                                  ),
                                ),
                                SizedBox(height: width * .13),
                              ],
                            ),
                          ),
                          if (featured.isEmpty)
                            EmptyDreams(en: en)
                          else ...[
                            SizedBox(
                              height: cardHeight,
                              child: PageView.builder(
                                controller: pages,
                                itemCount: featured.length,
                                onPageChanged: (value) =>
                                    setState(() => page = value),
                                itemBuilder: (context, i) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  child: _HeroDream(featured[i], en: en),
                                ),
                              ),
                            ),
                            if (featured.length > 1)
                              SizedBox(
                                height: 30,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (var i = 0; i < featured.length; i++)
                                      Semantics(
                                        label: tr(
                                          en,
                                          'Сон ${i + 1}',
                                          'Dream ${i + 1}',
                                        ),
                                        selected: page == i,
                                        button: true,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => reduced
                                              ? pages.jumpToPage(i)
                                              : pages.animateToPage(
                                                  i,
                                                  duration: const Duration(
                                                    milliseconds: 280,
                                                  ),
                                                  curve: Curves.easeOutCubic,
                                                ),
                                          child: SizedBox(
                                            width: 22,
                                            height: 30,
                                            child: Center(
                                              child: AnimatedContainer(
                                                duration: reduced
                                                    ? Duration.zero
                                                    : const Duration(
                                                        milliseconds: 180,
                                                      ),
                                                width: page == i ? 10 : 5,
                                                height: 5,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  color: Palette.lavender
                                                      .withValues(
                                                        alpha: page == i
                                                            ? 1
                                                            : .28,
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            _RecordButton(en: en),
                            const SizedBox(height: 10),
                            Text(
                              tr(
                                en,
                                'Каждый сон имеет значение',
                                'Every dream matters',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Palette.secondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          _Glass(
                            child: Column(
                              children: [
                                _Heading(
                                  tr(en, 'Настроение снов', 'Dream moods'),
                                  en: en,
                                  onTap: () => context.push('/insights'),
                                ),
                                const SizedBox(height: 12),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      for (final mood in [
                                        Mood.calm,
                                        Mood.strange,
                                        Mood.happy,
                                        Mood.peaceful,
                                        Mood.anxious,
                                      ])
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                          ),
                                          child: Column(
                                            children: [
                                              MoodOrb(
                                                mood,
                                                en: en,
                                                size: width > 600 ? 68 : 48,
                                                onTap: () => context.go(
                                                  '/journal?mood=${mood.name}',
                                                ),
                                              ),
                                              Text(
                                                '${dreams.where((d) => d.mood == mood).length}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Palette.secondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _Glass(
                            padding: EdgeInsets.zero,
                            child: Stack(
                              children: [
                                const Positioned(
                                  right: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: 130,
                                  child: IgnorePointer(
                                    child: Opacity(
                                      opacity: .55,
                                      child: _QuoteMoon(),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '“',
                                        style: TextStyle(
                                          fontFamily: 'Lora',
                                          fontSize: 36,
                                          color: Palette.lavender,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          tr(
                                            en,
                                            'Сны — это письма,\nкоторые мы пишем себе из будущего.',
                                            'Dreams are letters\nwe write to ourselves from the future.',
                                          ),
                                          style: display(15).copyWith(
                                            fontStyle: FontStyle.italic,
                                            height: 1.6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _Heading(
                            tr(en, 'Последние записи', 'Recent dreams'),
                            en: en,
                            onTap: () => context.go('/journal'),
                          ),
                          const SizedBox(height: 12),
                          if (recent.isNotEmpty)
                            _Glass(
                              padding: const EdgeInsets.all(6),
                              child: Column(
                                children: [
                                  for (
                                    var i = 0;
                                    i < math.min(3, recent.length);
                                    i++
                                  ) ...[
                                    if (i > 0)
                                      const Divider(
                                        height: 1,
                                        indent: 86,
                                        color: HomeStyle.border,
                                      ),
                                    _RecentDream(recent[i], en: en),
                                  ],
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),
                          _Glass(
                            child: Column(
                              children: [
                                _Heading(
                                  tr(en, 'Карта снов', 'Dream map'),
                                  en: en,
                                  onTap: () => context.go('/map'),
                                ),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => context.go('/map'),
                                  child: MapPreview(dreams),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!light)
                  Positioned(
                    left: -width * .1,
                    right: -width * .1,
                    bottom: -24,
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: Opacity(
                          opacity: .52,
                          child: Image.asset(
                            'assets/backgrounds/nebula_foreground.webp',
                            height: 115,
                            fit: BoxFit.cover,
                            cacheWidth: 1000,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    },
  );
}

class _FadedLibrary extends StatelessWidget {
  const _FadedLibrary();
  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (rect) => const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.transparent,
        Colors.white,
        Colors.white,
        Colors.transparent,
      ],
      stops: [0, .12, .65, 1],
    ).createShader(rect),
    child: ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        colors: [Colors.transparent, Colors.white, Colors.white],
        stops: [0, .3, 1],
      ).createShader(rect),
      child: Image.asset(
        'assets/dreams/moon_library.webp',
        fit: BoxFit.cover,
        alignment: const Alignment(.65, 0),
        cacheWidth: 1000,
      ),
    ),
  );
}

class _QuoteMoon extends StatelessWidget {
  const _QuoteMoon();
  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      const Icon(CupertinoIcons.moon, size: 40, color: Palette.gold),
      Positioned.fill(
        child: Image.asset(
          'assets/backgrounds/nebula_foreground.webp',
          fit: BoxFit.cover,
          cacheWidth: 400,
        ),
      ),
    ],
  );
}

class _Glass extends ConsumerWidget {
  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opaque =
        ref.watch(settingsProvider)['opaque'] == 'true' ||
        MediaQuery.highContrastOf(context);
    final light = Theme.of(context).brightness == Brightness.light;
    final surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: opaque
            ? (light ? Colors.white : Palette.surface)
            : light
            ? const Color(0xcceeeaf8)
            : HomeStyle.glass,
        border: Border.all(color: HomeStyle.border, width: .7),
      ),
      child: child,
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: opaque
          ? surface
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: surface,
            ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, {required this.en, required this.onTap});
  final String title;
  final bool en;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(title, style: display(23))),
      CupertinoButton(
        padding: const EdgeInsets.only(left: 10),
        minimumSize: const Size(44, 32),
        onPressed: onTap,
        child: Row(
          children: [
            Text(
              tr(en, 'Все', 'All'),
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
            ),
            const SizedBox(width: 6),
            const Icon(CupertinoIcons.chevron_right, size: 13),
          ],
        ),
      ),
    ],
  );
}

class _HeroDream extends StatelessWidget {
  const _HeroDream(this.dream, {required this.en});
  final Dream dream;
  final bool en;
  @override
  Widget build(BuildContext context) => _Pressable(
    onPressed: () => context.push('/dream/${dream.id}'),
    label: dreamTitle(dream, en),
    child: _Glass(
      padding: EdgeInsets.zero,
      radius: 24,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: DreamArtwork(dream.artwork, radius: 24)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xf0080e29),
                  Color(0xd0080e29),
                  Color(0x10080e29),
                ],
                stops: [0, .42, 1],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDate(dream.date, en),
                  style: const TextStyle(fontSize: 12, color: HomeStyle.muted),
                ),
                const SizedBox(height: 10),
                Text(
                  dreamTitle(dream, en),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: display(
                    24,
                  ).copyWith(color: HomeStyle.text, height: 1.1),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: FractionallySizedBox(
                    widthFactor: .67,
                    alignment: Alignment.topLeft,
                    child: LayoutBuilder(
                      builder: (context, c) => Text(
                        dream.description,
                        maxLines:
                            (c.maxHeight /
                                    MediaQuery.textScalerOf(
                                      context,
                                    ).scale(18.2))
                                .floor()
                                .clamp(1, 3),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: HomeStyle.muted,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 5,
                        children: [
                          if (dream.mood != null)
                            _Pill(dream.mood!.label(en), moodColor(dream.mood)),
                          _Pill(dream.type.label(en), Palette.lavender),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Palette.lavender.withValues(alpha: .16),
                        border: Border.all(color: HomeStyle.border),
                      ),
                      child: const Icon(
                        CupertinoIcons.chevron_right,
                        color: HomeStyle.text,
                        size: 22,
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
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: HomeStyle.border),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withValues(alpha: .4), width: .7),
    ),
    child: Text(label, style: TextStyle(fontSize: 11, color: color)),
  );
}

class _RecordButton extends ConsumerWidget {
  const _RecordButton({required this.en});
  final bool en;
  @override
  Widget build(BuildContext context, WidgetRef ref) => _Pressable(
    label: tr(en, 'Записать сон', 'Record Dream'),
    onPressed: () {
      if (ref.read(settingsProvider)['haptics'] != 'false') {
        HapticFeedback.lightImpact();
      }
      context.push('/record');
    },
    child: ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: const LinearGradient(
            colors: [Color(0xbb9c63df), Color(0xc5374bb8), Color(0xbb668edb)],
          ),
          border: Border.all(color: const Color(0x99ded5ff), width: .8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: .28,
                  child: Image.asset(
                    'assets/backgrounds/nebula_foreground.webp',
                    fit: BoxFit.cover,
                    cacheWidth: 800,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.plus,
                    size: 25,
                    color: HomeStyle.text,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      tr(en, 'Записать сон', 'Record Dream'),
                      style: const TextStyle(
                        fontSize: 17,
                        color: HomeStyle.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                  const Icon(
                    CupertinoIcons.sparkles,
                    size: 22,
                    color: HomeStyle.text,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Pressable extends ConsumerStatefulWidget {
  const _Pressable({
    required this.child,
    required this.onPressed,
    required this.label,
  });
  final Widget child;
  final VoidCallback onPressed;
  final String label;
  @override
  ConsumerState<_Pressable> createState() => _PressableState();
}

class _PressableState extends ConsumerState<_Pressable> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) {
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        ref.watch(settingsProvider)['animations'] == 'reduced';
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => pressed = true),
        onTapCancel: () => setState(() => pressed = false),
        onTapUp: (_) => setState(() => pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: pressed && !reduced ? .985 : 1,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }
}

class _RecentDream extends StatelessWidget {
  const _RecentDream(this.dream, {required this.en});
  final Dream dream;
  final bool en;
  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: const EdgeInsets.all(6),
    onPressed: () => context.push('/dream/${dream.id}'),
    child: Row(
      children: [
        SizedBox(
          width: 66,
          height: 72,
          child: DreamArtwork(dream.artwork, radius: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dreamTitle(dream, en),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: display(
                  17,
                ).copyWith(color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 5),
              Text(
                dream.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: Palette.secondary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                formatDate(dream.date, en),
                style: const TextStyle(fontSize: 10, color: Palette.secondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(CupertinoIcons.chevron_right, size: 15),
      ],
    ),
  );
}
