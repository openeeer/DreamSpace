import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'native_presentations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/providers.dart';
import '../models/dream.dart';
import 'native_glass.dart';

abstract final class Palette {
  /// Deep Tide: night water. Depth is a petrol ladder — each layer colder
  /// and darker. The only warm tone is moonlit jade, and it marks
  /// interaction alone.
  static const night = Color(0xff04121f),
      surface = Color(0xff0a1e30),
      raised = Color(0xff12314a),
      text = Color(0xffede9dc),
      secondary = Color(0xff8fa6b5),
      lavender = Color(0xff9fe8c8),
      moonlight = Color(0xfff5e7c4),
      blue = Color(0xff7ec8e0),
      gold = Color(0xffe0a377),
      mint = Color(0xff9fe8c8);

  /// Hairline neutral stroke for panels: the moon-white at low alpha.
  static Color hairline([bool light = false]) => light
      ? const Color(0xff152a38).withValues(alpha: .08)
      : const Color(0xffede9dc).withValues(alpha: .07);
}

/// Vertical rhythm on a 4/8 base grid. Sections of a screen separate by
/// [section]; sibling elements inside one section by [m]. Larger jumps
/// ([xl]) are reserved for the first screen of a flow. Anything outside
/// this scale is a layout defect, not a style choice.
abstract final class Rhythm {
  static const xs = 4.0, s = 8.0, m = 12.0, l = 16.0, section = 24.0, xl = 32.0;
  /// Shared horizontal content gutter for every top-level screen.
  static const gutter = 20.0;
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

/// Dream titles and signature moments: the diary's own hand. Inter never
/// italicizes; Lora italic belongs to dreams, not to chrome.
TextStyle diary(double size) => TextStyle(
  fontFamily: 'Lora',
  fontSize: size,
  height: 1.18,
  fontStyle: FontStyle.italic,
  fontWeight: FontWeight.w400,
  letterSpacing: -.3,
);
Color moodColor(Mood? mood) => switch (mood) {
  Mood.happy => Palette.gold,
  Mood.peaceful => Palette.mint,
  Mood.calm => Palette.blue,
  Mood.romantic => const Color(0xfff2c4c9),
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
    seedColor: const Color(0xff3f8f77),
    brightness: light ? Brightness.light : Brightness.dark,
    surface: light ? const Color(0xffeff2ef) : Palette.surface,
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
          bodyColor: light ? const Color(0xff152a38) : Palette.text,
          displayColor: light ? const Color(0xff152a38) : Palette.text,
        ),
    cupertinoOverrideTheme: CupertinoThemeData(
      brightness: light ? Brightness.light : Brightness.dark,
      primaryColor: light ? const Color(0xff2e7d64) : Palette.lavender,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: light
          ? Colors.white.withValues(alpha: .8)
          : Palette.raised.withValues(alpha: .45),
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
        borderSide: BorderSide(color: Palette.hairline(light), width: .7),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Palette.lavender, width: 1),
      ),
    ),
    dividerColor: Palette.hairline(light),
  );
}

class CosmicBackground extends ConsumerStatefulWidget {
  const CosmicBackground({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<CosmicBackground> createState() => _CosmicBackgroundState();
}

/// Deep Tide background: light falls from the surface of the water downward.
/// A vertical moon-shaft drifts slowly (the "tide"), mist sprites rise like
/// bubbles, stars hang far above. Content never moves.
class _CosmicBackgroundState extends ConsumerState<CosmicBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 44),
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
    final active = foreground && TickerMode.valuesOf(context).enabled;
    if (!reduced && active && !motion.isAnimating) motion.repeat();
    if ((reduced || !active) && motion.isAnimating) motion.stop();
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: light ? const Color(0xffeff2ef) : Palette.night),
        if (!light)
          Opacity(
            opacity: .5,
            child: Image.asset(
              'assets/backgrounds/cosmic_background.webp',
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) => const SizedBox.shrink(),
            ),
          ),
        IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(painter: _TidePainter(motion, light)),
          ),
        ),
        if (!light)
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: motion,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(
                      0,
                      reduced
                          ? 0
                          : -14 + math.sin(motion.value * math.pi * 2) * 14,
                    ),
                    child: child,
                  ),
                  child: RepaintBoundary(
                    child: const Opacity(
                      opacity: .3,
                      child: _TideMist(),
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

class _TideMist extends StatelessWidget {
  const _TideMist();
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/backgrounds/nebula_foreground_alpha.png',
    fit: BoxFit.cover,
    errorBuilder: (_, error, stack) => const SizedBox.shrink(),
  );
}

class _TidePainter extends CustomPainter {
  _TidePainter(this.animation, this.light) : super(repaint: animation);
  final Animation<double> animation;
  final bool light;
  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    // Moonlight shafts drift down slowly — the tide breathing.
    final drift = math.sin(t * math.pi * 2) * size.height * .04;
    for (final (frac, color, width) in [
      (.18, const Color(0xff9fe8c8), .55),
      (.62, const Color(0xff7ec8e0), .4),
      (.88, const Color(0xff2e6f8e), .7),
    ]) {
      final x = size.width * frac + drift * .3;
      canvas.drawRect(
        Rect.fromLTWH(x - size.width * width / 2, -40, size.width * width,
            size.height + 80),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: light ? .05 : .10),
              color.withValues(alpha: 0),
            ],
            stops: const [.0, .85],
          ).createShader(
            Rect.fromLTWH(x - size.width * width / 2, 0,
                size.width * width, size.height),
          ),
      );
    }
    if (light) return;
    // Bubbles rising slowly through the water column.
    final random = math.Random(27);
    for (var i = 0; i < 40; i++) {
      final bx = random.nextDouble() * size.width;
      final phase = random.nextDouble();
      final by = (size.height * 1.1 -
              ((t + phase) % 1) * size.height * 1.2 -
              drift * .2)
          .clamp(0.0, size.height);
      final r = 1 + random.nextDouble() * 2.2;
      canvas.drawCircle(
        Offset(bx, by),
        r,
        Paint()
          ..color = const Color(0xffede9dc).withValues(
            alpha: .05 + random.nextDouble() * .12,
          ),
      );
    }
    // Faint far stars only in the top band, above the "surface".
    final stars = math.Random(81);
    for (var i = 0; i < 60; i++) {
      canvas.drawCircle(
        Offset(
          stars.nextDouble() * size.width,
          stars.nextDouble() * size.height * .25,
        ),
        .3 + stars.nextDouble() * .7,
        Paint()
          ..color = Palette.secondary.withValues(
            alpha: .12 + stars.nextDouble() * .3,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TidePainter old) => old.light != light;
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
    // Night Atlas: a flat tonal plate — the surface tone itself carries the
    // elevation. Neutral hairline, one quiet shadow, no gradient fill.
    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: light
            ? Colors.white.withValues(alpha: opaque ? 1 : .96)
            : Palette.surface.withValues(alpha: opaque ? 1 : .93),
        border: Border.all(color: Palette.hairline(light), width: .7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: light ? .03 : .22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
    // Blur stays on the floating chrome layer only (tab bar, pop-overs).
    // Content panels are tonal, never frosted.
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
  Widget build(BuildContext context, WidgetRef ref) {
    if (usesNativeGlass) {
      return NativeGlassButton(
        label: label,
        icon: icon,
        showIconLabel: true,
        prominent: true,
        busy: busy,
        onPressed: busy || onPressed == null
            ? null
            : () {
                if (ref.read(settingsProvider)['haptics'] != 'false') {
                  HapticFeedback.lightImpact();
                }
                onPressed!();
              },
      );
    }
    return DecoratedBox(
      // Deep Tide button: a moonlit plate — jade ink in dark petrol water.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff155f4c), Color(0xff0d3a30)],
        ),
        border: Border.all(color: Palette.lavender.withValues(alpha: .45), width: .8),
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
              Icon(icon, color: Palette.mint, size: 21),
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
                  : const Color(0xffeff2ef),
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
        // Tidal pill: soft fill, no border. Jade only when interactive.
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (color ?? Palette.lavender).withValues(
            alpha: selected ? .2 : .07,
          ),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.15,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: onTap == null
                ? (color ?? Theme.of(context).colorScheme.onSurface)
                : (color ?? Palette.lavender),
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
              // A bioluminescent mote: light from within the water.
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-.35, -.4),
                    colors: [
                      color.withValues(alpha: .5),
                      color.withValues(alpha: .12),
                      Palette.night,
                    ],
                    stops: const [0, .55, 1],
                  ),
                  border: Border.all(
                    color: color.withValues(alpha: selected ? 1 : .5),
                    width: selected ? 1.6 : .7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: selected ? .3 : .1),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Icon(moodIcon(mood), color: color, size: size * .42),
              ),
              const SizedBox(height: 8),
              Text(
                mood.label(en),
                style: TextStyle(fontSize: 12, color: Palette.secondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The museum frame: the dream art is a painting, not a poster. A thin
/// neutral stroke, inner margin, and the caption lives *under* the painting
/// on the page surface — never as a scrim over the art.
class DreamArtwork extends StatelessWidget {
  const DreamArtwork(this.id,
      {super.key, this.child, this.radius = 18, this.frame = true});
  final String id;
  final Widget? child;
  final double radius;
  final bool frame;
  @override
  Widget build(BuildContext context) {
    Widget art = Stack(
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
        ?child,
      ],
    );
    if (!frame) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: art,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Palette.hairline(), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x3304121f), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 2),
          child: art,
        ),
      ),
    );
  }
}

class _PlaceholderArt extends CustomPainter {
  const _PlaceholderArt(this.index);
  final int index;
  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      Palette.lavender,
      Palette.blue,
      const Color(0xff7ec8e0),
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
            const Color(0xff0d2b42),
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
          colors: [const Color(0xfff5e7c4), c, const Color(0xff1a4258)],
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

/// Museum-plate card: framed painting + caption row beneath it on the page.
class DreamCard extends ConsumerWidget {
  const DreamCard(
    this.dream, {
    super.key,
    required this.en,
    this.large = false,
  });
  final Dream dream;
  final bool en, large;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: Rhythm.section),
    child: Semantics(
      button: true,
      label: dreamTitle(dream, en),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _actions(context, ref),
        onTap: () => context.push('/dream/${dream.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height:
                  (large ? 210 : 150) *
                  math.max(1, MediaQuery.textScalerOf(context).scale(14) / 14),
              child: HeroMode(
                enabled: false,
                child: Material(
                  color: Colors.transparent,
                  child: DreamArtwork(dream.artwork),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 10, 2, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatDate(dream.date, en),
                    style: const TextStyle(
                      color: Palette.secondary,
                      fontSize: 11,
                      letterSpacing: .3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dreamTitle(dream, en),
                    style: diary(large ? 24 : 19).copyWith(color: Palette.text),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Rhythm.s),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (dream.mood != null)
                              Text(
                                dream.mood!.label(en),
                                style: TextStyle(
                                  color: moodColor(dream.mood),
                                  fontSize: 12,
                                ),
                              ),
                            if (dream.mood != null)
                              const SizedBox(width: 6),
                            Text(
                              dream.type.label(en),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Palette.secondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (dream.favorite)
                        const Icon(
                          CupertinoIcons.heart_fill,
                          size: 15,
                          color: Palette.gold,
                        ),
                      const SizedBox(width: 8),
                      const Icon(
                        CupertinoIcons.chevron_right,
                        size: 15,
                        color: Palette.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _actions(BuildContext context, WidgetRef ref) async {
    if (ref.read(settingsProvider)['haptics'] != 'false') {
      HapticFeedback.selectionClick();
    }
    final action = await dreamActionSheet(
      context,
      title: dreamTitle(dream, en),
      actions: [
        ('open', tr(en, 'Открыть сон', 'Open dream')),
        (
          'favorite',
          dream.favorite
              ? tr(en, 'Убрать из избранного', 'Remove from favorites')
              : tr(en, 'В избранное', 'Add to favorites'),
        ),
        ('edit', tr(en, 'Редактировать', 'Edit')),
        ('map', tr(en, 'Показать на карте', 'Show on map')),
      ],
      cancelLabel: tr(en, 'Отмена', 'Cancel'),
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case 'open':
        context.push('/dream/${dream.id}');
      case 'edit':
        context.push('/record?id=${dream.id}');
      case 'map':
        context.go('/map?focus=${dream.id}');
      case 'favorite':
        await ref
            .read(repositoryProvider)
            .save(dream.copyWith(favorite: !dream.favorite));
    }
  }
}

class EmptyDreams extends StatelessWidget {
  const EmptyDreams({
    super.key,
    required this.en,
    this.search = false,
    this.notFound = false,
  });
  final bool en, search;

  /// "Not found" contexts (deep link, deleted dream): the honest next step
  /// is going back to the journal, not recording a brand-new dream.
  final bool notFound;
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
          notFound
              ? tr(en, 'Этот сон исчез', 'This dream is gone')
              : search
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
          notFound
              ? tr(
                  en,
                  'Возможно, он был удалён. Остальные — в дневнике.',
                  'It may have been deleted. The rest are in your journal.',
                )
              : search
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
              label: notFound
                  ? tr(en, 'Вернуться в дневник', 'Back to journal')
                  : tr(en, 'Записать сон', 'Record Dream'),
              onPressed: () => notFound
                  ? context.go('/journal')
                  : context.push('/record'),
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
) async {
  if (usesNativeGlass) {
    return await nativePresentations.invokeMethod<bool>('confirm', {
          ...presentationStyle(context),
          'title': title,
          'message': message,
          'cancel': tr(en, 'Отмена', 'Cancel'),
          'accept': tr(en, 'Удалить', 'Delete'),
        }) ??
        false;
  }
  return await showCupertinoDialog<bool>(
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
}
