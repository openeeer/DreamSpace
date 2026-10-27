import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../core/native_glass.dart';
import '../../data/providers.dart';
import '../../models/dream.dart';
import '../dream_map/map_screen.dart';
import '../dreams/journal_components.dart';

/// Deep Tide home: light falls from the top, the hero painting floats in
/// the beam, everything else arranges in quiet plates beneath it.
abstract final class HomeStyle {
  static const ink = Color(0xff04121f);
  static const text = Palette.text;
  static const muted = Palette.secondary;
}

String _greeting(bool en) {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) {
    return tr(en, 'Доброе утро', 'Good morning');
  }
  if (hour >= 12 && hour < 18) {
    return tr(en, 'Добрый день', 'Good afternoon');
  }
  if (hour >= 18 && hour < 23) {
    return tr(en, 'Добрый вечер', 'Good evening');
  }
  return tr(en, 'Тихой ночи', 'Quiet night');
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
      final width = MediaQuery.sizeOf(context).width;
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final heroHeight = math.max(360.0, width * 1.08) * math.max(1, scale);
      return Scaffold(
        body: CustomScrollView(
          key: const PageStorageKey('home-scroll'),
          controller: scroll,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                Rhythm.gutter,
                MediaQuery.paddingOf(context).top + 14,
                Rhythm.gutter,
                MediaQuery.viewPaddingOf(context).bottom + 122,
              ),
              sliver: SliverList.list(
                children: [
                  Stack(
                    children: [
                      // Moonbeam: a shaft of light behind the hero painting,
                      // fading as the page scrolls away.
                      Positioned(
                        top: -MediaQuery.paddingOf(context).top - 14,
                        left: -Rhythm.gutter,
                        right: -Rhythm.gutter,
                        bottom: -Rhythm.section,
                        child: IgnorePointer(
                          child: _Moonbeam(
                            light: light,
                            scroll: scroll,
                            reduced: reduced,
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HomeHeader(en: en, light: light),
                          if (featured.isEmpty) ...[
                            SizedBox(height: width * .12),
                            EmptyDreams(en: en),
                          ] else ...[
                            SizedBox(
                              height: heroHeight,
                              child: PageView.builder(
                                key: const PageStorageKey<String>(
                                  'home-carousel',
                                ),
                                controller: pages,
                                itemCount: featured.length,
                                onPageChanged: (value) =>
                                    setState(() => page = value),
                                itemBuilder: (context, i) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: _HeroPainting(
                                    featured[i],
                                    en: en,
                                    reduced: reduced,
                                  ),
                                ),
                              ),
                            ),
                            if (featured.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(top: Rhythm.m),
                                child: _HeroDots(
                                  count: featured.length,
                                  page: page,
                                  reduced: reduced,
                                  onSelect: (i) => reduced
                                      ? pages.jumpToPage(i)
                                      : pages.animateToPage(
                                          i,
                                          duration: const Duration(
                                            milliseconds: 280,
                                          ),
                                          curve: Curves.easeOutCubic,
                                        ),
                                ),
                              ),
                            const SizedBox(height: Rhythm.section),
                            _RecordRow(en: en),
                          ],
                          const SizedBox(height: Rhythm.section),
                          _TideMoods(
                            dreams: dreams,
                            en: en,
                            wide: width > 600,
                          ),
                          const SizedBox(height: Rhythm.section),
                          _FragmentRow(
                            title: tr(en, 'Последние записи', 'Recent dreams'),
                            action: tr(en, 'Весь дневник', 'Full journal'),
                            onTap: () => context.go('/journal'),
                            child: recent.isEmpty
                                ? _QuietNote(
                                    tr(
                                      en,
                                      'Здесь появятся твои сны',
                                      'Your dreams will gather here',
                                    ),
                                  )
                                : _Fragments(recent: recent, en: en),
                          ),
                          const SizedBox(height: Rhythm.section),
                          _FragmentRow(
                            title: tr(en, 'Карта снов', 'Dream map'),
                            action: tr(en, 'Открыть', 'Open'),
                            onTap: () => context.go('/map'),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => context.go('/map'),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: SizedBox(
                                  height: 170,
                                  child: MapPreview(recent),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _Moonbeam extends StatelessWidget {
  const _Moonbeam({required this.light, required this.scroll, required this.reduced});
  final bool light, reduced;
  final ScrollController scroll;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: scroll,
    builder: (context, _) {
      final off = reduced || !scroll.hasClients ? 0.0 : scroll.offset * .35;
      return Transform.translate(
        offset: Offset(0, -off),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (light ? const Color(0xff2e7d64) : const Color(0xff9fe8c8))
                    .withValues(alpha: .13),
                Colors.transparent,
              ],
              stops: const [0, .8],
            ),
          ),
        ),
      );
    },
  );
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader({required this.en, required this.light});
  final bool en, light;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: Rhythm.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _greeting(en),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: width < 370 ? 13 : 14,
                    letterSpacing: 1.2,
                    color: light
                        ? const Color(0xff5b6a70)
                        : Palette.secondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _MoonButton(en: en),
            ],
          ),
          const SizedBox(height: Rhythm.xs),
          Text(
            'DreamSpace',
            style: display(width < 370 ? 30 : 34).copyWith(
              letterSpacing: -1.2,
              height: 1.02,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoonButton extends ConsumerWidget {
  const _MoonButton({required this.en});
  final bool en;
  @override
  Widget build(BuildContext context, WidgetRef ref) => JournalIconButton(
    label: tr(en, 'Мой мир', 'My world'),
    icon: CupertinoIcons.moon_fill,
    onPressed: () {
      if (ref.read(settingsProvider)['haptics'] != 'false') {
        HapticFeedback.selectionClick();
      }
      context.go('/profile');
    },
  );
}

/// The hero of the home: a tall framed painting in the moonbeam, with its
/// caption set beneath the frame like a museum plate.
class _HeroPainting extends ConsumerStatefulWidget {
  const _HeroPainting(this.dream, {required this.en, required this.reduced});
  final Dream dream;
  final bool en, reduced;
  @override
  ConsumerState<_HeroPainting> createState() => _HeroPaintingState();
}

class _HeroPaintingState extends ConsumerState<_HeroPainting> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) {
    final dream = widget.dream, en = widget.en;
    // The whole cell opens the dream; the cell's open margins stay part of
    // the PageView viewport, so horizontal swipes still win the gesture
    // arena over the tap recognizer.
    openDream() {
      if (ref.read(settingsProvider)['haptics'] != 'false') {
        HapticFeedback.lightImpact();
      }
      context.push('/dream/${dream.id}');
    }

    setPressed(bool value) => setState(() => pressed = value);

    // Date and mood share the caption line; each yields so accessibility
    // text scales never overflow the hero.
    final caption = Row(
      children: [
        Expanded(
          child: Text(
            formatDate(dream.date, en),
            maxLines: 1,
            overflow: TextOverflow.fade,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: .4,
              color: Palette.secondary,
            ),
          ),
        ),
        if (dream.mood != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              dream.mood!.label(en),
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: TextStyle(
                fontSize: 11,
                color: moodColor(dream.mood),
              ),
            ),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setPressed(true),
            onTapUp: (_) => setPressed(false),
            onTapCancel: () => setPressed(false),
            onTap: openDream,
            child: Semantics(
              button: true,
              label: dreamTitle(dream, en),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: pressed && !widget.reduced ? .78 : 1,
                child: DreamArtwork(dream.artwork, radius: 22),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, Rhythm.m, 4, 0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: openDream,
            child: Semantics(
              button: true,
              label: dreamTitle(dream, en),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  caption,
                  const SizedBox(height: 4),
                  Text(
                    dreamTitle(dream, en),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: diary(
                      21,
                    ).copyWith(color: Palette.text, height: 1.1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroDots extends StatelessWidget {
  const _HeroDots({
    required this.count,
    required this.page,
    required this.reduced,
    required this.onSelect,
  });
  final int count, page;
  final bool reduced;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < count; i++)
        Semantics(
          label: 'Сон ${i + 1}',
          selected: page == i,
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelect(i),
            child: SizedBox(
              width: 44,
              height: 32,
              child: Center(
                child: AnimatedContainer(
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  width: page == i ? 18 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Palette.lavender.withValues(
                      alpha: page == i ? .9 : .3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

/// The single loud action of the screen: a moonlit jade plate that also
/// carries the dictionary gesture of "swim down to record".
class _RecordRow extends ConsumerWidget {
  const _RecordRow({required this.en});
  final bool en;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void open() {
      if (ref.read(settingsProvider)['haptics'] != 'false') {
        HapticFeedback.lightImpact();
      }
      context.push('/record');
    }

    if (usesNativeGlass) {
      return NativeGlassButton(
        label: tr(en, 'Записать сон', 'Record a dream'),
        icon: CupertinoIcons.add,
        showIconLabel: true,
        prominent: true,
        onPressed: open,
      );
    }
    return Semantics(
      button: true,
      label: tr(en, 'Записать сон', 'Record a dream'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: open,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xff17604c), Color(0xff0b382e)],
            ),
            border: Border.all(
              color: Palette.lavender.withValues(alpha: .5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff9fe8c8).withValues(alpha: .12),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.moon_fill,
                  size: 19,
                  color: Palette.mint,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr(en, 'Записать сон', 'Record a dream'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Palette.text,
                    ),
                  ),
                ),
                // The whisper line yields on narrow screens; on the widest
                // ones it fades out rather than squeezing the title.
                Flexible(
                  child: Text(
                    tr(en, 'Каждый сон имеет значение', 'Every dream matters'),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: .4,
                      color: Palette.mint.withValues(alpha: .8),
                    ),
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

/// Moods of the tide: horizontal reel of bioluminescent motes.
class _TideMoods extends StatelessWidget {
  const _TideMoods({required this.dreams, required this.en, required this.wide});
  final List<Dream> dreams;
  final bool en, wide;
  @override
  Widget build(BuildContext context) => DreamSurface(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                tr(en, 'Настроение снов', 'Dream moods'),
                style: display(20),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              onPressed: () => context.push('/insights'),
              child: const Icon(
                CupertinoIcons.chevron_right,
                size: 15,
                color: Palette.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: Rhythm.m),
        SizedBox(
          // Orb + mood label + count, sized at the live text scale so
          // accessibility sizes never clip the reel. The 16px slack keeps
          // the reel valid while the orb's 64→48 resize animation runs
          // after a wide→narrow viewport change.
          height: 16 + (wide ? 64.0 : 48.0) + MediaQuery.textScalerOf(
            context,
          ).scale(64),
          child: SingleChildScrollView(
            key: const PageStorageKey<String>('home-moods'),
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final mood in [
                  Mood.calm,
                  Mood.strange,
                  Mood.happy,
                  Mood.peaceful,
                  Mood.anxious,
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MoodOrb(
                          mood,
                          en: en,
                          size: wide ? 64 : 48,
                          onTap: () => context.go('/journal?mood=${mood.name}'),
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
        ),
      ],
    ),
  );
}

/// A titled fragment section: header row + a plate of quiet rows.
class _FragmentRow extends StatelessWidget {
  const _FragmentRow({
    required this.title,
    required this.action,
    required this.onTap,
    required this.child,
  });
  final String title, action;
  final VoidCallback onTap;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(title, style: display(20))),
          CupertinoButton(
            padding: const EdgeInsets.only(left: 10),
            minimumSize: const Size(44, 44),
            onPressed: onTap,
            child: Row(
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Palette.lavender,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 13,
                  color: Palette.lavender,
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: Rhythm.m),
      DreamSurface(
        padding: const EdgeInsets.all(6),
        child: child,
      ),
    ],
  );
}

class _QuietNote extends StatelessWidget {
  const _QuietNote(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 26),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: Palette.secondary),
      ),
    ),
  );
}

class _Fragments extends StatelessWidget {
  const _Fragments({required this.recent, required this.en});
  final List<Dream> recent;
  final bool en;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < math.min(3, recent.length); i++) ...[
        if (i > 0)
          Divider(
            height: 1,
            indent: 88,
            color: Palette.hairline(),
          ),
        _FragmentDream(recent[i], en: en),
      ],
    ],
  );
}

class _FragmentDream extends StatelessWidget {
  const _FragmentDream(this.dream, {required this.en});
  final Dream dream;
  final bool en;
  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: const EdgeInsets.all(6),
    onPressed: () => context.push('/dream/${dream.id}'),
    child: Row(
      children: [
        SizedBox(
          width: 64,
          height: 68,
          child: DreamArtwork(dream.artwork, radius: 12),
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
                style: diary(16).copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
                style: const TextStyle(
                  fontSize: 10,
                  color: Palette.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          CupertinoIcons.chevron_right,
          size: 14,
          color: Palette.secondary,
        ),
      ],
    ),
  );
}



