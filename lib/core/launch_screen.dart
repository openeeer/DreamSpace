import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const launchBackground = 'assets/launch/background.png';
const launchNight = Color(0xff070b1e);

class LaunchDestination {
  const LaunchDestination({
    required this.app,
    this.haptics = true,
    this.reducedMotion = false,
  });
  final Widget app;
  final bool haptics, reducedMotion;
}

abstract interface class LaunchHaptics {
  Future<bool> prepare();
  Future<void> play({required Duration duration, required bool reducedMotion});
  Future<void> stop();
}

class IPhoneLaunchHaptics implements LaunchHaptics {
  static const channel = MethodChannel('dreamspace/launch-haptics');
  bool get supportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  @override
  Future<bool> prepare() async {
    if (!supportedPlatform) return false;
    try {
      return await channel.invokeMethod<bool>('prepare') ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> play({
    required Duration duration,
    required bool reducedMotion,
  }) async {
    if (!supportedPlatform) return;
    try {
      await channel.invokeMethod<void>('play', {
        'duration': duration.inMilliseconds / 1000,
        'reducedMotion': reducedMotion,
      });
    } catch (_) {
      /* An unavailable Taptic Engine never blocks launch. */
    }
  }

  @override
  Future<void> stop() async {
    if (!supportedPlatform) return;
    try {
      await channel.invokeMethod<void>('stop');
    } catch (_) {
      /* Best effort. */
    }
  }
}

/// Owns only a cold launch. Navigation and app state live below this widget;
/// returning from the background never creates a second launch sequence.
class DreamLaunch extends StatefulWidget {
  const DreamLaunch({
    super.key,
    required this.initialize,
    this.haptics,
    this.onBackgroundReady,
  });
  final Future<LaunchDestination> Function() initialize;
  final LaunchHaptics? haptics;
  final VoidCallback? onBackgroundReady;
  @override
  State<DreamLaunch> createState() => _DreamLaunchState();
}

class _DreamLaunchState extends State<DreamLaunch>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController fill = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1650),
  );
  late final AnimationController reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final LaunchHaptics haptics = widget.haptics ?? IPhoneLaunchHaptics();
  LaunchDestination? destination;
  bool assetsReady = false,
      assetsRequested = false,
      started = false,
      preparing = false,
      finished = false,
      failed = false,
      reduced = false;
  bool get foreground =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fill.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        unawaited(haptics.stop());
        _revealWhenReady();
      }
    });
    reveal.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => finished = true);
      }
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final next = await widget.initialize();
      if (!mounted) return;
      setState(() {
        destination = next;
        failed = false;
      });
      _startWhenReady();
    } catch (error) {
      debugPrint('DreamSpace bootstrap: $error');
      if (mounted) setState(() => failed = true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!assetsRequested) {
      assetsRequested = true;
      // Keep the matching native storyboard until this exact image is decoded.
      unawaited(
        precacheImage(
          const AssetImage(launchBackground),
          context,
          onError: (error, stack) => debugPrint('Launch background: $error'),
        ).whenComplete(() {
          widget.onBackgroundReady?.call();
          if (!mounted) return;
          assetsReady = true;
          _startWhenReady();
        }),
      );
    }
  }

  Future<void> _startWhenReady() async {
    if (!mounted ||
        !assetsReady ||
        destination == null ||
        started ||
        preparing ||
        !foreground) {
      return;
    }
    preparing = true;
    reduced =
        destination!.reducedMotion || MediaQuery.disableAnimationsOf(context);
    final enabled = destination!.haptics;
    final tactile = enabled && await haptics.prepare();
    preparing = false;
    if (!mounted || !foreground) return;
    started = true;
    fill.duration = Duration(milliseconds: reduced ? 1200 : 1650);
    reveal.duration = Duration(milliseconds: reduced ? 180 : 220);
    setState(() {});
    // A single native pattern follows the same clock as the visual fill.
    // No timers or per-frame platform messages are used for haptics.
    fill.forward();
    if (tactile) {
      unawaited(haptics.play(duration: fill.duration!, reducedMotion: reduced));
    }
  }

  void _revealWhenReady() {
    if (mounted &&
        foreground &&
        destination != null &&
        fill.isCompleted &&
        !reveal.isAnimating) {
      reveal.forward();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!started) {
        _startWhenReady();
      } else if (!finished) {
        if (!fill.isCompleted) {
          fill.forward();
        } else {
          _revealWhenReady();
        }
      }
    } else {
      fill.stop(canceled: false);
      reveal.stop(canceled: false);
      unawaited(haptics.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(haptics.stop());
    fill.dispose();
    reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (destination != null)
            ExcludeSemantics(
              excluding: !finished,
              child: IgnorePointer(
                ignoring: !finished,
                child: TickerMode(enabled: finished, child: destination!.app),
              ),
            ),
          if (!finished)
            AnimatedBuilder(
              animation: reveal,
              builder: (context, child) => Opacity(
                opacity: 1 - Curves.easeOut.transform(reveal.value),
                child: child,
              ),
              child: BlockSemantics(
                child: AbsorbPointer(
                  child: AnnotatedRegion<SystemUiOverlayStyle>(
                    value: SystemUiOverlayStyle.light,
                    child: LaunchArtwork(
                      progress: fill,
                      reducedMotion: reduced,
                    ),
                  ),
                ),
              ),
            ),
          if (failed)
            MaterialApp(
              theme: ThemeData.dark(),
              home: Scaffold(
                backgroundColor: launchNight,
                body: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Не удалось открыть DreamSpace',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xfff4f1ff),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              setState(() => failed = false);
                              _load();
                            },
                            child: const Text(
                              'Попробовать снова',
                              style: TextStyle(color: Color(0xffc0acff)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LaunchArtwork extends StatelessWidget {
  const LaunchArtwork({
    super.key,
    required this.progress,
    this.reducedMotion = false,
  });
  final Animation<double> progress;
  final bool reducedMotion;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: launchNight,
    child: Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        Image.asset(
          launchBackground,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          excludeFromSemantics: true,
          errorBuilder: (_, error, stack) => const SizedBox.expand(),
        ),
        Center(
          child: Transform.translate(
            offset: const Offset(0, 40),
            child: LaunchEmblem(
              progress: progress,
              reducedMotion: reducedMotion,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Fixed brand artwork, shared with the native launch image. Its text is part of
/// the mark; app content continues to respect the user's preferred text size.
class LaunchEmblem extends StatelessWidget {
  const LaunchEmblem({
    super.key,
    required this.progress,
    this.reducedMotion = false,
  });
  final Animation<double> progress;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Dream Space',
    textDirection: TextDirection.ltr,
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox(
          width: 280,
          height: 260,
          child: Stack(
            alignment: Alignment.topLeft,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _LaunchOrbitPainter(progress, reducedMotion),
                ),
              ),
              Positioned(
                left: 102,
                top: 52,
                width: 76,
                height: 76,
                child: CustomPaint(
                  painter: CrescentFillPainter(
                    progress,
                    reducedMotion: reducedMotion,
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                top: 150,
                child: Text(
                  'Dream Space',
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1,
                    height: 1.25,
                    color: Color(0xffeee8fc),
                    decoration: TextDecoration.none,
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

class _LaunchOrbitPainter extends CustomPainter {
  _LaunchOrbitPainter(this.progress, this.reducedMotion)
    : super(repaint: progress);
  final Animation<double> progress;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    const center = Offset(140, 90);
    const lavender = Color(0xffc0acff);
    final phase = Curves.easeInOutCubic.transform(progress.value);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-.38);
    final orbit = Rect.fromCenter(center: Offset.zero, width: 182, height: 108);
    canvas.drawOval(
      orbit,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .65
        ..color = lavender.withValues(alpha: .17),
    );
    if (!reducedMotion && phase > 0) {
      final angle = -.9 + phase * 1.8;
      canvas.drawArc(
        orbit,
        angle - .45,
        .45,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..shader = ui.Gradient.sweep(
            Offset.zero,
            [lavender.withValues(alpha: 0), lavender.withValues(alpha: .6)],
            null,
            TileMode.clamp,
            angle - .45,
            angle,
          ),
      );
      final point = Offset(91 * math.cos(angle), 54 * math.sin(angle));
      canvas.drawCircle(
        point,
        5,
        Paint()
          ..color = lavender.withValues(alpha: .4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(point, 1.5, Paint()..color = const Color(0xfff5eddf));
    }
    canvas.restore();

    for (final star in const [
      (Offset(213, 44), 3.4),
      (Offset(65, 119), 2.5),
      (Offset(89, 30), 1.7),
    ]) {
      final paint = Paint()
        ..color = lavender.withValues(alpha: .45 + .15 * phase)
        ..strokeWidth = .8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        star.$1.translate(-star.$2, 0),
        star.$1.translate(star.$2, 0),
        paint,
      );
      canvas.drawLine(
        star.$1.translate(0, -star.$2),
        star.$1.translate(0, star.$2),
        paint,
      );
    }
    final ink = Paint()
      ..strokeWidth = .65
      ..color = lavender.withValues(alpha: .28);
    canvas.drawLine(const Offset(106, 210), const Offset(128, 210), ink);
    canvas.drawLine(const Offset(152, 210), const Offset(174, 210), ink);
    canvas.drawPath(
      Path()
        ..moveTo(140, 207)
        ..lineTo(143, 210)
        ..lineTo(140, 213)
        ..lineTo(137, 210)
        ..close(),
      Paint()..color = lavender.withValues(alpha: .4 + .3 * phase),
    );
  }

  @override
  bool shouldRepaint(covariant _LaunchOrbitPainter old) =>
      old.progress != progress || old.reducedMotion != reducedMotion;
}

/// Small, stable silhouette shared with the static iOS launch image.
class CrescentFillPainter extends CustomPainter {
  CrescentFillPainter(this.progress, {this.reducedMotion = false})
    : super(repaint: progress);
  final Animation<double> progress;
  final bool reducedMotion;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 76;
    canvas.save();
    canvas.translate(
      (size.width - 76 * scale) / 2,
      (size.height - 76 * scale) / 2,
    );
    canvas.scale(scale);
    final crescent = Path.combine(
      PathOperation.difference,
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(38, 38), radius: 25)),
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(49, 29), radius: 24)),
    );
    final phase = ((progress.value - .09) / .73).clamp(0.0, 1.0);
    final amount = Curves.easeInOutCubic.transform(phase);
    canvas.drawPath(
      crescent,
      Paint()..color = const Color(0xffc0acff).withValues(alpha: .055),
    );
    canvas.drawPath(
      crescent,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..color = const Color(0xffd1c5f5).withValues(alpha: .28),
    );
    if (amount > 0) {
      if (!reducedMotion) {
        canvas.drawPath(
          crescent,
          Paint()
            ..color = const Color(0xffad98e5).withValues(alpha: .2 * amount)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
      canvas.save();
      canvas.clipPath(crescent);
      final level = 66 - 56 * amount;
      final amplitude = reducedMotion ? 0.0 : math.sin(amount * math.pi) * 1.15;
      final water = Path()
        ..moveTo(0, 76)
        ..lineTo(0, level);
      for (var x = 0.0; x <= 76; x += 2) {
        water.lineTo(
          x,
          level + math.sin(x / 13 + progress.value * 7) * amplitude,
        );
      }
      water.lineTo(76, 76);
      water.close();
      canvas.drawPath(
        water,
        Paint()
          ..shader = ui.Gradient.linear(
            const Offset(20, 14),
            const Offset(53, 65),
            const [Color(0xfff6edda), Color(0xffe6dffa), Color(0xffad98e5)],
            const [0, .55, 1],
          ),
      );
      canvas.restore();
      if (!reducedMotion) {
        final gleam = math.sin(
          ((progress.value - .7) / .3).clamp(0.0, 1.0) * math.pi,
        );
        final paint = Paint()
          ..color = const Color(0xfff6edda).withValues(alpha: gleam * .8)
          ..strokeWidth = .85
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(61, 16), const Offset(61, 22), paint);
        canvas.drawLine(const Offset(58, 19), const Offset(64, 19), paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CrescentFillPainter old) =>
      old.progress != progress || old.reducedMotion != reducedMotion;
}
