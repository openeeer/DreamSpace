import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../core/internal_page.dart';
import '../../data/providers.dart';
import '../profile/profile_hero.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final pages = PageController();
  int page = 0;
  bool saving = false;
  String? error;

  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  Future<void> finish() async {
    if (saving) return;
    dreamSelection(ref);
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await ref.read(settingsProvider.notifier).set('onboarded', 'true');
      if (mounted) context.go('/home');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        saving = false;
        error = tr(
          ref.read(englishProvider),
          'Не удалось сохранить. Попробуй ещё раз.',
          'Could not save. Please try again.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final en = ref.watch(englishProvider);
    final light = Theme.of(context).brightness == Brightness.light;
    final reduced =
        MediaQuery.disableAnimationsOf(context) ||
        ref.watch(settingsProvider)['animations'] == 'reduced';
    final muted = InternalStyle.muted(context);
    final titles = en
        ? [
            'A little closer\nto your dreams',
            'Some dreams\nleave a trace',
            'Your own\nuniverse of dreams',
          ]
        : [
            'Твои сны\nближе, чем кажется',
            'У снов есть\nсвои подсказки',
            'Целая вселенная.\nИ она — твоя.',
          ];
    final descriptions = en
        ? [
            'Keep a piece of the night. A few words in the morning are enough to begin.',
            'Collect places, people and feelings. Notice what returns from night to night.',
            'Dreams with shared images connect on your map. Follow the threads of your stories.',
          ]
        : [
            'Сохрани кусочек ночи. Для начала хватит нескольких слов о том, что приснилось.',
            'Собирай места, людей и ощущения. Замечай, что возвращается из ночи в ночь.',
            'Сны с общими образами соединяются на карте. Исследуй связи между своими историями.',
          ];
    final labels = en
        ? ['REMEMBER', 'NOTICE', 'EXPLORE']
        : ['ЗАПОМИНАЙ', 'ЗАМЕЧАЙ', 'ИССЛЕДУЙ'];
    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 320,
            child: ProfileLandscape(),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 16, 0),
                  child: Row(
                    children: [
                      Expanded(child: Text('DreamSpace', style: display(22))),
                      CupertinoButton(
                        onPressed: saving ? null : finish,
                        child: Text(
                          tr(en, 'Пропустить', 'Skip'),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide =
                          constraints.maxWidth >= 700 &&
                          MediaQuery.textScalerOf(context).scale(16) <= 24;
                      return PageView.builder(
                        controller: pages,
                        itemCount: 3,
                        onPageChanged: (value) => setState(() => page = value),
                        itemBuilder: (context, i) {
                          final art = _WelcomeArt(page: i, light: light);
                          final copy = Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: wide
                                  ? CrossAxisAlignment.start
                                  : CrossAxisAlignment.center,
                              children: [
                                Text(
                                  labels[i],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 3,
                                    color: InternalStyle.accent(context),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  titles[i],
                                  textAlign: wide
                                      ? TextAlign.left
                                      : TextAlign.center,
                                  style: display(
                                    constraints.maxWidth < 360 ? 32 : 38,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  descriptions[i],
                                  textAlign: wide
                                      ? TextAlign.left
                                      : TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    height: 1.6,
                                    color: muted,
                                  ),
                                ),
                              ],
                            ),
                          );
                          return SingleChildScrollView(
                            key: PageStorageKey('welcome-$i'),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: wide ? 940 : 480,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    child: wide
                                        ? Row(
                                            children: [
                                              Expanded(child: art),
                                              Expanded(child: copy),
                                            ],
                                          )
                                        : Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                height:
                                                    (constraints.maxHeight *
                                                            .48)
                                                        .clamp(180.0, 350.0),
                                                child: art,
                                              ),
                                              const SizedBox(height: 12),
                                              copy,
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          label: en
                              ? 'Page ${page + 1} of 3'
                              : 'Страница ${page + 1} из 3',
                          child: ExcludeSemantics(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                3,
                                (i) => AnimatedContainer(
                                  duration: reduced
                                      ? Duration.zero
                                      : const Duration(milliseconds: 220),
                                  width: i == page ? 26 : 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: InternalStyle.accent(
                                      context,
                                    ).withValues(alpha: i == page ? 1 : .25),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(error!, textAlign: TextAlign.center),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoButton(
                            color: light
                                ? const Color(0xff6652b8)
                                : Palette.lavender,
                            borderRadius: BorderRadius.circular(22),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 18,
                            ),
                            onPressed: saving
                                ? null
                                : () {
                                    if (page == 2) {
                                      finish();
                                      return;
                                    }
                                    dreamSelection(ref);
                                    if (reduced) {
                                      pages.jumpToPage(page + 1);
                                      return;
                                    }
                                    pages.nextPage(
                                      duration: const Duration(
                                        milliseconds: 380,
                                      ),
                                      curve: Curves.easeInOutCubic,
                                    );
                                  },
                            child: saving
                                ? const CupertinoActivityIndicator()
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          page == 2
                                              ? tr(
                                                  en,
                                                  'Открыть DreamSpace',
                                                  'Open DreamSpace',
                                                )
                                              : tr(
                                                  en,
                                                  'Продолжить',
                                                  'Continue',
                                                ),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: light
                                                ? Colors.white
                                                : Palette.night,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        CupertinoIcons.arrow_right,
                                        size: 19,
                                        color: light
                                            ? Colors.white
                                            : Palette.night,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bundled artwork keeps the introduction independent of the user's journal.
class _WelcomeArt extends StatelessWidget {
  const _WelcomeArt({required this.page, required this.light});
  final int page;
  final bool light;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Center(
      child: AspectRatio(
        aspectRatio: 1.1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth, h = constraints.maxHeight;
            Widget image(String name, double x, double y, double size) =>
                Positioned(
                  left: w * x - size / 2,
                  top: h * y - size / 2,
                  width: size,
                  height: size,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Palette.lavender.withValues(alpha: .18),
                          blurRadius: 26,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/dreams/$name.webp',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _Constellation(page, light)),
                ),
                if (page == 0)
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.all(w * .02),
                      child: Image.asset(
                        'assets/profile/dream_sphere.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                if (page == 1) ...[
                  image('moon_library', .47, .48, w * .57),
                  image('ocean_without_end', .81, .29, w * .26),
                  image('glass_staircase', .22, .79, w * .29),
                ],
                if (page == 2) ...[
                  image('moon_library', .5, .5, w * .34),
                  image('sky_islands', .19, .23, w * .23),
                  image('ocean_without_end', .82, .24, w * .22),
                  image('glass_staircase', .2, .8, w * .22),
                  image('red_forest', .81, .79, w * .24),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );
}

class _Constellation extends CustomPainter {
  const _Constellation(this.page, this.light);
  final int page;
  final bool light;
  @override
  void paint(Canvas canvas, Size size) {
    final color = light ? const Color(0xff6652b8) : Palette.lavender;
    final paint = Paint()
      ..color = color.withValues(alpha: .3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    if (page == 2) {
      for (final p in [
        const Offset(.19, .23),
        const Offset(.82, .24),
        const Offset(.2, .8),
        const Offset(.81, .79),
      ]) {
        canvas.drawLine(
          Offset(size.width / 2, size.height / 2),
          Offset(size.width * p.dx, size.height * p.dy),
          paint,
        );
      }
    } else {
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(-.35);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * .94,
          height: size.height * .71,
        ),
        paint,
      );
      canvas.restore();
    }
    for (var i = 0; i < 14; i++) {
      final angle = i * 2.39996;
      final p = Offset(
        size.width * (.5 + math.cos(angle) * .46),
        size.height * (.5 + math.sin(angle) * .46),
      );
      canvas.drawCircle(
        p,
        i % 3 == 0 ? 1.8 : .9,
        Paint()..color = color.withValues(alpha: .65),
      );
    }
  }

  @override
  bool shouldRepaint(_Constellation oldDelegate) =>
      oldDelegate.page != page || oldDelegate.light != light;
}
