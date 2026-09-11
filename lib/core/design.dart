import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/providers.dart';
import '../models/dream.dart';

abstract final class Palette {
  static const night = Color(0xff070b1e),
      surface = Color(0xff12152f),
      raised = Color(0xff1c2147),
      text = Color(0xfff4f1ff),
      secondary = Color(0xffbfc3e6),
      lavender = Color(0xffc0acff),
      blue = Color(0xff8fbeff),
      gold = Color(0xffe6bf88),
      mint = Color(0xff9ad8cc);
}

String tr(bool en, String ru, String english) => en ? english : ru;
String formatDate(DateTime date, bool en) =>
    DateFormat('d MMM y', en ? 'en' : 'ru').format(date);
String dreamTitle(Dream dream, bool en) {
  final legacy = RegExp(r'^(Сон|Dream) — \d{1,2} .+ \d{4}$');
  return dream.title.trim().isEmpty || legacy.hasMatch(dream.title)
      ? tr(en, 'Без названия', 'Untitled dream')
      : dream.title;
}

TextStyle display(double size) => TextStyle(
  fontFamily: 'Lora',
  fontSize: size,
  height: 1.13,
  fontWeight: FontWeight.w400,
  letterSpacing: -.5,
);
Color moodColor(Mood? mood) => switch (mood) {
  Mood.happy => Palette.gold,
  Mood.peaceful => Palette.mint,
  Mood.calm => Palette.blue,
  Mood.romantic => const Color(0xffe6abc9),
  Mood.scary || Mood.anxious => const Color(0xffed9aaa),
  _ => Palette.lavender,
};
IconData moodIcon(Mood? mood) => switch (mood) {
  Mood.calm => CupertinoIcons.wind,
  Mood.happy => CupertinoIcons.sun_max,
  Mood.sad => CupertinoIcons.cloud_rain,
  Mood.scary => CupertinoIcons.moon_zzz,
  Mood.strange => CupertinoIcons.sparkles,
  Mood.romantic => CupertinoIcons.heart,
  Mood.mysterious => CupertinoIcons.hurricane,
  Mood.anxious => CupertinoIcons.cloud_bolt,
  Mood.peaceful => CupertinoIcons.leaf_arrow_circlepath,
  _ => CupertinoIcons.moon,
};

ThemeData dreamTheme({bool light = false}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.lavender,
    brightness: light ? Brightness.light : Brightness.dark,
    surface: light ? const Color(0xfff3f1fa) : Palette.surface,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    fontFamily: 'Inter',
    splashFactory: NoSplash.splashFactory,
    iconTheme: const IconThemeData(size: 21),
    textTheme: ThemeData(brightness: light ? Brightness.light : Brightness.dark)
        .textTheme
        .apply(
          fontFamily: 'Inter',
          bodyColor: light ? const Color(0xff24233f) : Palette.text,
          displayColor: light ? const Color(0xff24233f) : Palette.text,
        ),
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: light ? Brightness.light : Brightness.dark,
      primaryColor: light ? const Color(0xff6652b8) : Palette.lavender,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: light
          ? Colors.white.withValues(alpha: .7)
          : Palette.night.withValues(alpha: .5),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: const TextStyle(fontSize: 14),
      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Palette.lavender.withValues(alpha: .18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Palette.lavender),
      ),
    ),
    dividerColor: Palette.lavender.withValues(alpha: .14),
  );
}

class CosmicBackground extends ConsumerStatefulWidget {
  const CosmicBackground({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends ConsumerState<CosmicBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 55),
  );
  bool foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (!foreground) {
      motion.stop();
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final reduced =
        settings['animations'] == 'reduced' ||
        MediaQuery.disableAnimationsOf(context);
    final light = Theme.of(context).brightness == Brightness.light;
    if (!reduced && foreground && !motion.isAnimating) motion.repeat();
    if ((reduced || !foreground) && motion.isAnimating) motion.stop();
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: light ? const Color(0xfff3f1fa) : Palette.night),
        if (!light)
          Opacity(
            opacity: .6,
            child: Image.asset(
              'assets/backgrounds/cosmic_background.webp',
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) => const SizedBox.shrink(),
            ),
          ),
        RepaintBoundary(
          child: CustomPaint(painter: _CosmosPainter(motion, light)),
        ),
        if (!light)
          Positioned(
            left: -24,
            right: -24,
            bottom: -30,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: motion,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(
                      0,
                      reduced ? 0 : math.sin(motion.value * math.pi * 2) * 10,
                    ),
                    child: child,
                  ),
                  child: RepaintBoundary(
                    child: Opacity(
                      opacity: .23,
                      child: Image.asset(
                        'assets/backgrounds/nebula_foreground.webp',
                        fit: BoxFit.fitWidth,
                        cacheWidth: 1200,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        widget.child,
      ],
    );
  }
}

class _CosmosPainter extends CustomPainter {
  _CosmosPainter(this.animation, this.light) : super(repaint: animation);
  final Animation<double> animation;
  final bool light;
  @override
  void paint(Canvas canvas, Size size) {
    final drift = math.sin(animation.value * math.pi * 2) * 18;
    for (final (center, color, radius) in [
      (
        Offset(size.width * .95, size.height * .14 + drift),
        const Color(0xff6050c4),
        size.width * .9,
      ),
      (
        Offset(-size.width * .12, size.height * .78 - drift),
        const Color(0xff4430a0),
        size.width * .85,
      ),
      (
        Offset(size.width * .75, size.height),
        const Color(0xff214e91),
        size.width * .7,
      ),
    ]) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: light ? .08 : .24),
              color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }
    if (light) return;
    final random = math.Random(81);
    for (var i = 0; i < 95; i++) {
      final p = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final r = .35 + random.nextDouble() * .85;
      final alpha = .16 + random.nextDouble() * .45;
      canvas.drawCircle(
        p,
        r,
        Paint()..color = Palette.secondary.withValues(alpha: alpha),
      );
      if (i % 23 == 0) {
        final paint = Paint()
          ..color = Palette.lavender.withValues(alpha: .4)
          ..strokeWidth = .6;
        canvas.drawLine(p - const Offset(0, 4), p + const Offset(0, 4), paint);
        canvas.drawLine(p - const Offset(4, 0), p + const Offset(4, 0), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CosmosPainter old) => old.light != light;
}

class DreamSurface extends ConsumerWidget {
  const DreamSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.glass = false,
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool glass;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final light = Theme.of(context).brightness == Brightness.light;
    final opaque =
        ref.watch(settingsProvider)['opaque'] == 'true' ||
        MediaQuery.highContrastOf(context);
    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: light
              ? [
                  Colors.white.withValues(alpha: .92),
                  const Color(0xffe9e6f5).withValues(alpha: .94),
                ]
              : [
                  Palette.raised.withValues(alpha: opaque ? 1 : .82),
                  Palette.surface.withValues(alpha: opaque ? 1 : .88),
                ],
        ),
        border: Border.all(
          color: Palette.lavender.withValues(alpha: light ? .3 : .28),
          width: .7,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: light ? .025 : .15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (glass && !opaque) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: content,
        ),
      );
    }
    if (onTap != null) {
      content = Semantics(
        button: true,
        child: GestureDetector(onTap: onTap, child: content),
      );
    }
    return content;
  }
}

class DreamButton extends ConsumerWidget {
  const DreamButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = CupertinoIcons.add,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool busy;
  @override
  Widget build(BuildContext context, WidgetRef ref) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: const LinearGradient(
        colors: [Color(0xff6652b8), Color(0xff4356aa)],
      ),
      border: Border.all(
        color: Palette.lavender.withValues(alpha: .65),
        width: .8,
      ),
      boxShadow: [
        BoxShadow(
          color: Palette.lavender.withValues(alpha: .17),
          blurRadius: 23,
          spreadRadius: 1,
        ),
      ],
    ),
    child: CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      onPressed: busy
          ? null
          : onPressed == null
          ? null
          : () {
              if (ref.read(settingsProvider)['haptics'] != 'false') {
                HapticFeedback.lightImpact();
              }
              onPressed!();
            },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy)
            const CupertinoActivityIndicator(color: Colors.white)
          else
            Icon(icon, color: Palette.text, size: 21),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Palette.text,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class DreamPage extends StatelessWidget {
  const DreamPage({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actions = const [],
    this.back = false,
  });
  final String title;
  final String? subtitle;
  final List<Widget> children, actions;
  final bool back;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          if (back)
            SliverAppBar(
              pinned: true,
              primary: false,
              toolbarHeight: 52,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Palette.night
                  : const Color(0xfff3f1fa),
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(CupertinoIcons.back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              ),
              title: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: actions,
            ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20,
              back ? 12 : 10,
              20,
              back ? MediaQuery.paddingOf(context).bottom + 24 : 112,
            ),
            sliver: SliverList.list(
              children: [
                if (!back)
                  Row(
                    children: [
                      Expanded(child: Text(title, style: display(27))),
                      ...actions,
                    ],
                  ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Palette.secondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                if (!back || subtitle != null) const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Expanded(child: Text(title, style: display(21))),
        if (action != null)
          TextButton(
            onPressed: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(action!),
                const SizedBox(width: 4),
                const Icon(CupertinoIcons.chevron_right, size: 14),
              ],
            ),
          ),
      ],
    ),
  );
}

class DreamChip extends StatelessWidget {
  const DreamChip(
    this.label, {
    super.key,
    this.selected = false,
    this.onTap,
    this.color,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: onTap != null,
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size(0, onTap == null ? 30 : 44),
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (color ?? Palette.lavender).withValues(
            alpha: selected ? .18 : .04,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (color ?? Palette.lavender).withValues(
              alpha: selected ? .5 : .14,
            ),
            width: .7,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.15,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    ),
  );
}

class MoodOrb extends StatelessWidget {
  const MoodOrb(
    this.mood, {
    super.key,
    required this.en,
    this.selected = false,
    this.onTap,
    this.size = 48,
  });
  final Mood mood;
  final bool en, selected;
  final VoidCallback? onTap;
  final double size;
  @override
  Widget build(BuildContext context) {
    final color = moodColor(mood);
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: mood.label(en),
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-.4, -.5),
                    colors: [color.withValues(alpha: .42), Palette.surface],
                  ),
                  border: Border.all(
                    color: color.withValues(alpha: selected ? 1 : .65),
                    width: selected ? 1.7 : .8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: selected ? .32 : .14),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Icon(moodIcon(mood), color: color, size: size * .45),
              ),
              const SizedBox(height: 9),
              Text(mood.label(en), style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class DreamArtwork extends StatelessWidget {
  const DreamArtwork(this.id, {super.key, this.child, this.radius = 26});
  final String id;
  final Widget? child;
  final double radius;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _PlaceholderArt(artworkIds.indexOf(id).clamp(0, 7)),
        ),
        Image.asset(
          'assets/dreams/$id.webp',
          fit: BoxFit.cover,
          alignment: const Alignment(.35, 0),
          errorBuilder: (_, error, stack) => const SizedBox.shrink(),
        ),
        if (child != null)
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xef080d25),
                  Color(0x90080d25),
                  Color(0x10080d25),
                ],
              ),
            ),
            child: child,
          ),
      ],
    ),
  );
}

class _PlaceholderArt extends CustomPainter {
  const _PlaceholderArt(this.index);
  final int index;
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      Palette.lavender,
      Palette.blue,
      const Color(0xffb779a1),
      Palette.blue,
      Palette.lavender,
      Palette.gold,
      Palette.mint,
      Palette.blue,
    ];
    final c = colors[index];
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Palette.night,
            const Color(0xff182451),
            c.withValues(alpha: .6),
          ],
        ).createShader(rect),
    );
    final center = Offset(size.width * .72, size.height * .38),
        radius = math.min(size.width, size.height) * .24;
    canvas.drawCircle(
      center,
      radius * 1.7,
      Paint()
        ..shader = RadialGradient(
          colors: [c.withValues(alpha: .4), c.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 1.7)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.5, -.5),
          colors: [const Color(0xffffe9ce), c, const Color(0xff464d91)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    final random = math.Random(index + 37);
    for (var i = 0; i < 80; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        random.nextDouble() + .3,
        Paint()
          ..color = Colors.white.withValues(
            alpha: .15 + random.nextDouble() * .45,
          ),
      );
    }
    for (var i = 0; i < 4; i++) {
      final path = Path()..moveTo(0, size.height * (.7 + i * .08));
      for (var x = 0.0; x <= size.width + 10; x += 10) {
        path.lineTo(
          x,
          size.height * (.7 + i * .08) +
              math.sin(x / size.width * 5 + i + index) * size.height * .09,
        );
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = Color.lerp(
            c,
            Palette.night,
            .65 + i * .08,
          )!.withValues(alpha: .7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlaceholderArt old) => old.index != index;
}

class DreamCard extends StatelessWidget {
  const DreamCard(
    this.dream, {
    super.key,
    required this.en,
    this.large = false,
  });
  final Dream dream;
  final bool en, large;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Semantics(
      button: true,
      label: dreamTitle(dream, en),
      child: GestureDetector(
        onTap: () => context.push('/dream/${dream.id}'),
        child: SizedBox(
          height:
              (large ? 224 : 164) *
              math.max(1, MediaQuery.textScalerOf(context).scale(14) / 14),
          child: HeroMode(
            enabled: false,
            child: Material(
              color: Colors.transparent,
              child: DreamArtwork(
                dream.artwork,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatDate(dream.date, en),
                        style: const TextStyle(
                          color: Palette.secondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        dreamTitle(dream, en),
                        style: display(
                          large ? 26 : 22,
                        ).copyWith(color: Palette.text),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      if (large)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14, right: 60),
                          child: Text(
                            dream.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Palette.secondary,
                              height: 1.5,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          if (dream.mood != null)
                            Text(
                              dream.mood!.label(en),
                              style: TextStyle(
                                color: moodColor(dream.mood),
                                fontSize: 13,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              dream.type.label(en),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Palette.secondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (dream.favorite)
                            const Icon(
                              CupertinoIcons.heart_fill,
                              size: 16,
                              color: Palette.lavender,
                            ),
                          const SizedBox(width: 8),
                          const Icon(
                            CupertinoIcons.arrow_up_right,
                            size: 19,
                            color: Palette.text,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class EmptyDreams extends StatelessWidget {
  const EmptyDreams({super.key, required this.en, this.search = false});
  final bool en, search;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 44),
    child: Column(
      children: [
        const Icon(
          CupertinoIcons.moon_stars,
          size: 56,
          color: Palette.lavender,
        ),
        const SizedBox(height: 22),
        Text(
          search
              ? tr(en, 'Ничего не найдено', 'No dreams found')
              : tr(
                  en,
                  'Здесь начинается твоя вселенная',
                  'Your universe starts here',
                ),
          textAlign: TextAlign.center,
          style: display(26),
        ),
        const SizedBox(height: 12),
        Text(
          search
              ? tr(
                  en,
                  'Измени запрос или фильтры.',
                  'Try another search or filter.',
                )
              : tr(
                  en,
                  'Сохрани хотя бы один образ из сна.',
                  'Save even a small fragment of a dream.',
                ),
          textAlign: TextAlign.center,
        ),
        if (!search)
          Padding(
            padding: const EdgeInsets.only(top: 26),
            child: DreamButton(
              label: tr(en, 'Записать сон', 'Record Dream'),
              onPressed: () => context.push('/record'),
            ),
          ),
      ],
    ),
  );
}

class DreamsBuilder extends ConsumerWidget {
  const DreamsBuilder({super.key, required this.builder});
  final Widget Function(List<Dream>, bool) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final en = ref.watch(englishProvider);
    return ref
        .watch(dreamsProvider)
        .when(
          data: (data) => builder(data, en),
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr(
                    en,
                    'Не удалось открыть дневник',
                    'Could not load your journal',
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(dreamsProvider),
                  child: Text(tr(en, 'Повторить', 'Retry')),
                ),
              ],
            ),
          ),
        );
  }
}

Future<bool> confirm(
  BuildContext context,
  bool en,
  String title,
  String message,
) async =>
    await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(en, 'Отмена', 'Cancel')),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(en, 'Удалить', 'Delete')),
          ),
        ],
      ),
    ) ??
    false;
