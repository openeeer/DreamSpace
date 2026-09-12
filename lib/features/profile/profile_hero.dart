import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/design.dart';
import '../../data/providers.dart';

/// Art is optional until the reference assets arrive. Never fabricate a sphere
/// from a placeholder avatar; retain only the existing atmospheric clouds.
final profileAssetsProvider = FutureProvider<Set<String>>((ref) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  return manifest.listAssets().toSet();
});

class DreamProfileHero extends ConsumerStatefulWidget {
  const DreamProfileHero({super.key});
  @override
  ConsumerState<DreamProfileHero> createState() => _DreamProfileHeroState();
}

class _DreamProfileHeroState extends ConsumerState<DreamProfileHero>
    with SingleTickerProviderStateMixin {
  late final motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 32),
  );
  @override
  void dispose() {
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assets = ref.watch(profileAssetsProvider).asData?.value ?? {};
    final ready = assets.contains('assets/profile/dream_sphere.png');
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        ref.watch(settingsProvider)['animations'] == 'reduced' ||
        !TickerMode.valuesOf(context).enabled;
    if (ready && !reduced && !motion.isAnimating) motion.repeat();
    if ((!ready || reduced) && motion.isAnimating) motion.stop();
    final size = (MediaQuery.sizeOf(context).width * .58).clamp(180.0, 250.0);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Center(
          child: SizedBox(
            width: size,
            height: size,
            child: !ready
                ? Opacity(
                    opacity: .55,
                    child: Image.asset(
                      'assets/backgrounds/nebula_foreground.webp',
                      fit: BoxFit.contain,
                    ),
                  )
                : RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: motion,
                      child: Image.asset(
                        'assets/profile/dream_sphere.png',
                        fit: BoxFit.contain,
                        cacheWidth: 800,
                      ),
                      builder: (context, child) => Transform.translate(
                        offset: Offset(
                          0,
                          reduced
                              ? 0
                              : math.sin(motion.value * math.pi * 10) * 2,
                        ),
                        child: CustomPaint(
                          foregroundPainter: _Orbits(
                            reduced ? 0 : motion.value,
                          ),
                          child: child,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Orbits extends CustomPainter {
  const _Orbits(this.phase);
  final double phase;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-.4);
    final r = size.width * .46;
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: r * 2.1, height: r * 1.6),
      Paint()
        ..color = Palette.lavender.withValues(alpha: .22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .6,
    );
    for (var i = 0; i < 4; i++) {
      final a = phase * math.pi * 2 + i * math.pi / 2;
      final p = Offset(math.cos(a) * r * 1.05, math.sin(a) * r * .8);
      final paint = Paint()..color = Palette.lavender.withValues(alpha: .7);
      canvas.drawLine(p - const Offset(3, 0), p + const Offset(3, 0), paint);
      canvas.drawLine(p - const Offset(0, 3), p + const Offset(0, 3), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Orbits old) => old.phase != phase;
}

class ProfileHandwritten extends ConsumerWidget {
  const ProfileHandwritten({super.key, required this.en});
  final bool en;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = 'assets/profile/more_than_dreams_${en ? 'en' : 'ru'}.png';
    if (!(ref.watch(profileAssetsProvider).asData?.value.contains(path) ??
        false)) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Opacity(
          opacity: .65,
          child: Image.asset(path, width: 100, height: 66, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class ProfileLandscape extends ConsumerWidget {
  const ProfileLandscape({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready =
        ref
            .watch(profileAssetsProvider)
            .asData
            ?.value
            .contains('assets/profile/profile_landscape.png') ??
        false;
    return IgnorePointer(
      child: ExcludeSemantics(
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.white],
            stops: [0, .7],
          ).createShader(r),
          child: Opacity(
            opacity: Theme.of(context).brightness == Brightness.light
                ? .15
                : .55,
            child: Image.asset(
              ready
                  ? 'assets/profile/profile_landscape.png'
                  : 'assets/backgrounds/nebula_foreground.webp',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              cacheWidth: 1000,
            ),
          ),
        ),
      ),
    );
  }
}
