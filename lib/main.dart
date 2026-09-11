import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/design.dart';
import 'core/notifications.dart';
import 'data/database.dart';
import 'data/providers.dart';
import 'data/repository.dart';
import 'features/home/home_screen.dart';
import 'features/dreams/journal_screen.dart';
import 'features/dreams/editor_screen.dart';
import 'features/dreams/detail_screen.dart';
import 'features/dream_map/map_screen.dart';
import 'features/elements/elements_screen.dart';
import 'features/insights/insights_screen.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final font in ['Lora', 'Inter']) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString('assets/licenses/$font-OFL.txt'));
    }
  });
  await initializeDateFormatting('ru');
  final repo = DreamRepository(AppDatabase());
  try {
    await repo.initialize();
    final settings = {
      for (final row in await repo.db.select(repo.db.preferences).get())
        row.key: row.value,
    };
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    container.read(settingsProvider.notifier).load(settings);
    final router = createRouter(settings['onboarded'] == 'true');
    try {
      await reminders.initialize(() {
        if (router.routeInformationProvider.value.uri.path != '/record') {
          router.push('/record');
        }
      });
      if (settings['reminder'] == 'true') {
        await reminders.schedule(
          int.parse(settings['hour'] ?? '8'),
          int.parse(settings['minute'] ?? '0'),
          en: settings['language'] == 'en',
          request: false,
        );
      }
      if (reminders.openedFromNotification && settings['onboarded'] == 'true') {
        router.go('/record');
      }
    } catch (e) {
      debugPrint('Reminder initialization: $e');
    }
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: DreamSpaceApp(router: router),
      ),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Не удалось открыть DreamSpace. Перезапусти приложение.\n$e',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

GoRouter createRouter(bool onboarded) => GoRouter(
  initialLocation: onboarded ? '/home' : '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (_, state) => const OnboardingScreen(),
    ),
    StatefulShellRoute(
      navigatorContainerBuilder: (context, shell, children) => Stack(
        children: [
          for (var i = 0; i < children.length; i++)
            Offstage(
              offstage: i != shell.currentIndex,
              child: TickerMode(
                enabled: i == shell.currentIndex,
                child: HeroMode(
                  enabled: i == shell.currentIndex,
                  child: children[i],
                ),
              ),
            ),
        ],
      ),
      builder: (context, state, shell) => DreamShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/home', builder: (_, state) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/journal',
              builder: (_, state) =>
                  JournalScreen(mood: state.uri.queryParameters['mood']),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (_, state) =>
                  MapScreen(focus: state.uri.queryParameters['focus']),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (_, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/record',
      builder: (_, state) => EditorScreen(
        id: state.uri.queryParameters['id'],
        date: state.uri.queryParameters['date'],
      ),
    ),
    GoRoute(
      path: '/dream/:id',
      builder: (_, state) => DetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(path: '/elements', builder: (_, state) => const ElementsScreen()),
    GoRoute(
      path: '/elements/:id',
      builder: (_, state) =>
          ElementDetailScreen(id: state.pathParameters['id']!),
    ),
    GoRoute(path: '/insights', builder: (_, state) => const InsightsScreen()),
    GoRoute(path: '/calendar', builder: (_, state) => const CalendarScreen()),
    GoRoute(path: '/settings', builder: (_, state) => const SettingsScreen()),
  ],
);

class DreamSpaceApp extends ConsumerWidget {
  const DreamSpaceApp({super.key, required this.router});
  final GoRouter router;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider),
        en = ref.watch(englishProvider);
    return MaterialApp.router(
      title: 'DreamSpace',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: Locale(en ? 'en' : 'ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: dreamTheme(light: true),
      darkTheme: dreamTheme(),
      themeMode: switch (settings['theme']) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      },
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: CosmicBackground(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: child!,
            ),
          ),
        ),
      ),
    );
  }
}

class DreamShell extends ConsumerWidget {
  const DreamShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final en = ref.watch(englishProvider);
    final labels = en
        ? ['Home', 'Journal', 'Map', 'Profile']
        : ['Главная', 'Дневник', 'Карта', 'Профиль'];
    const icons = [
      CupertinoIcons.house,
      CupertinoIcons.book,
      CupertinoIcons.share,
      CupertinoIcons.person,
    ];
    return Scaffold(
      body: Stack(
        children: [
          shell,
          Positioned(
            left: 18,
            right: 18,
            bottom: MediaQuery.paddingOf(context).bottom + 12,
            child: DreamSurface(
              glass: true,
              radius: 38,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: Semantics(
                        selected: shell.currentIndex == i,
                        button: true,
                        label: labels[i],
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          onPressed: () {
                            if (ref.read(settingsProvider)['haptics'] !=
                                'false') {
                              HapticFeedback.selectionClick();
                            }
                            shell.goBranch(i);
                          },
                          child: AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 240),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: shell.currentIndex == i
                                  ? Palette.lavender.withValues(alpha: .14)
                                  : Colors.transparent,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  icons[i],
                                  size: 24,
                                  color: shell.currentIndex == i
                                      ? Palette.lavender
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  labels[i],
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: shell.currentIndex == i
                                        ? Palette.lavender
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
}
