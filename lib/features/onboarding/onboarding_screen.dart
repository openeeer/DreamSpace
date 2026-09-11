import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../data/providers.dart';
import '../dream_map/map_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final pages = PageController();
  int page = 0;
  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  Future<void> finish() async {
    await ref.read(settingsProvider.notifier).set('onboarded', 'true');
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final en = ref.watch(englishProvider);
    final titles = en
        ? [
            'Remember\nyour dreams',
            'Discover\nthe patterns',
            'Explore your\ndream universe',
          ]
        : [
            'Помни\nсвои сны',
            'Замечай\nповторения',
            'Открой свою\nвселенную снов',
          ];
    final subtitles = en
        ? [
            'Save a little piece of the night before it fades.',
            'Places, people and symbols weave a story only you can tell.',
            'Every dream becomes a star. Together, they become your world.',
          ]
        : [
            'Сохрани маленький фрагмент ночи, пока он не растворился.',
            'Места, люди и символы складываются в историю, которая принадлежит только тебе.',
            'Каждый сон становится звездой. Вместе они создают твой мир.',
          ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Text('DreamSpace', style: display(23)),
                  const Spacer(),
                  TextButton(
                    onPressed: finish,
                    child: Text(tr(en, 'Пропустить', 'Skip')),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: pages,
                itemCount: 3,
                onPageChanged: (i) => setState(() => page = i),
                itemBuilder: (context, i) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 18, 28, 16),
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * .34,
                        child: i == 2
                            ? DreamsBuilder(
                                builder: (dreams, en) =>
                                    Center(child: MapPreview(dreams)),
                              )
                            : DreamArtwork(
                                i == 0 ? 'moon_library' : 'glass_staircase',
                                radius: 160,
                              ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        titles[i],
                        textAlign: TextAlign.center,
                        style: display(39),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        subtitles[i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Palette.secondary,
                          fontSize: 16,
                          height: 1.65,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: page == i ? 24 : 6,
                    height: 6,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: page == i ? Palette.lavender : Palette.raised,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: DreamButton(
                label: page == 2
                    ? tr(en, 'Войти в DreamSpace', 'Enter DreamSpace')
                    : tr(en, 'Продолжить', 'Continue'),
                icon: CupertinoIcons.arrow_right,
                onPressed: page == 2
                    ? finish
                    : () => pages.nextPage(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
