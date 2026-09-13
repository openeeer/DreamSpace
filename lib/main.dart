import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/design.dart';
import 'core/native_tab_bar.dart';
import 'core/route_surface.dart';
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
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
      pageBuilder: (context, state) =>
          dreamRoute(context, state, const OnboardingScreen()),
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
      pageBuilder: (context, state, shell) =>
          dreamRoute(context, state, DreamShell(shell: shell)),
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
      pageBuilder: (context, state) => dreamRoute(
        context,
        state,
        EditorScreen(
          id: state.uri.queryParameters['id'],
          date: state.uri.queryParameters['date'],
        ),
      ),
    ),
    GoRoute(
      path: '/dream/:id',
      pageBuilder: (context, state) => dreamRoute(
        context,
        state,
        DetailScreen(id: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/elements',
      pageBuilder: (context, state) =>
          dreamRoute(context, state, const ElementsScreen()),
    ),
    GoRoute(
      path: '/elements/:id',
      pageBuilder: (context, state) => dreamRoute(
        context,
        state,
        ElementDetailScreen(id: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/insights',
      pageBuilder: (context, state) =>
          dreamRoute(context, state, const InsightsScreen()),
    ),
    GoRoute(
      path: '/calendar',
      pageBuilder: (context, state) =>
          dreamRoute(context, state, const CalendarScreen()),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) =>
          dreamRoute(context, state, const SettingsScreen()),
    ),
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
        child: ColoredBox(
          color: Theme.of(context).brightness == Brightness.dark
              ? Palette.night
              : const Color(0xfff3f1fa),
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
    return Scaffold(
      body: Stack(
        children: [
          shell,
          Positioned(
            left: 22,
            right: 22,
            bottom: MediaQuery.viewPaddingOf(context).bottom + 10,
            child: DreamTabBar(
              index: shell.currentIndex,
              labels: labels,
              opaque: ref.watch(settingsProvider)['opaque'] == 'true',
              onSelected: (i) {
                if (ref.read(settingsProvider)['haptics'] != 'false') {
                  HapticFeedback.selectionClick();
                }
                shell.goBranch(i, initialLocation: i == shell.currentIndex);
              },
            ),
          ),
        ],
      ),
    );
  }
}
