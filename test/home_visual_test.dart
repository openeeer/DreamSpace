import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:dreamspace/main.dart';
import 'package:dreamspace/data/database.dart';
import 'package:dreamspace/data/repository.dart';
import 'package:dreamspace/data/providers.dart';
import 'package:dreamspace/features/dreams/journal_components.dart';
import 'package:dreamspace/features/dreams/journal_screen.dart';
import 'package:dreamspace/core/native_tab_bar.dart';
import 'package:dreamspace/features/dream_map/universe_screen.dart';
import 'package:dreamspace/features/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets('Home reference rendering and responsive layout', (tester) async {
    await tester.runAsync(() => initializeDateFormatting('ru'));
    for (final font in ['Lora', 'Inter']) {
      final loader = FontLoader(font)
        ..addFont(rootBundle.load('assets/fonts/$font.ttf'));
      await tester.runAsync(loader.load);
    }
    final icons = FontLoader('packages/cupertino_icons/CupertinoIcons')
      ..addFont(
        rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
      );
    await tester.runAsync(icons.load);
    final system = FontLoader('.SF Pro Text')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await tester.runAsync(system.load);
    final display = FontLoader('.SF Pro Display')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await tester.runAsync(display.load);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DreamRepository(db);
    await tester.runAsync(repo.initialize);
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    container.read(settingsProvider.notifier).load({'animations': 'reduced'});
    final router = createRouter(true);
    final boundary = GlobalKey();
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: boundary,
          child: DreamSpaceApp(router: router),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(Scaffold).first);
      for (final asset in [
        'assets/dreams/moon_library.webp',
        'assets/backgrounds/nebula_foreground.webp',
      ]) {
        await precacheImage(AssetImage(asset), context);
        await precacheImage(
          ResizeImage(AssetImage(asset), width: 1000),
          context,
        );
        await precacheImage(
          ResizeImage(AssetImage(asset), width: 800),
          context,
        );
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    const journalCapture = String.fromEnvironment('JOURNAL_CAPTURE');
    if (journalCapture.isNotEmpty) {
      router.go('/journal');
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final ctx = tester.element(find.byType(Scaffold).first);
        for (final id in [
          'moon_library',
          'ocean_without_end',
          'red_forest',
          'empty_city',
        ]) {
          await precacheImage(AssetImage('assets/dreams/$id.webp'), ctx);
        }
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(journalCapture).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    const output = String.fromEnvironment('HOME_CAPTURE');
    const profileCapture = String.fromEnvironment('PROFILE_CAPTURE');
    if (profileCapture.isNotEmpty) {
      router.go('/profile');
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 400)),
        );
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(profileCapture).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    const mapCapture = String.fromEnvironment('MAP_CAPTURE');
    if (mapCapture.isNotEmpty) {
      router.go('/map');
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final ctx = tester.element(find.byType(Scaffold).first);
        for (final d in await repo.all()) {
          if (ctx.mounted) {
            await precacheImage(
              AssetImage('assets/dreams/${d.artwork}.webp'),
              ctx,
            );
          }
        }
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(mapCapture).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    if (output.isNotEmpty) {
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(output).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    for (final size in [const Size(320, 740), const Size(844, 390)]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    tester.view.physicalSize = const Size(390, 844);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    router.go('/journal');
    await tester.pumpAndSettle();
    expect(find.text('Сентябрь 2026'), findsOneWidget);
    await tester.tap(find.text('Сентябрь 2026'));
    await tester.pumpAndSettle();
    expect(find.byType(DreamJournalCard), findsNothing);
    await tester.tap(find.text('Сентябрь 2026'));
    await tester.pumpAndSettle();
    expect(find.byType(DreamJournalCard), findsWidgets);
    await tester.tap(find.byTooltip('Параметры дневника'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сначала старые'));
    await tester.tap(find.text('Применить'));
    await tester.pumpAndSettle();
    final cards = tester
        .widgetList<DreamJournalCard>(find.byType(DreamJournalCard))
        .toList();
    expect(cards.first.dream.date.isBefore(cards.last.dream.date), isTrue);
    final firstCard = find.byType(DreamJournalCard).first;
    final firstDream = tester.widget<DreamJournalCard>(firstCard).dream;
    await tester.tap(
      find.descendant(
        of: firstCard,
        matching: find.byTooltip(
          firstDream.favorite ? 'Убрать из избранного' : 'В избранное',
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(
      (await tester.runAsync(
        repo.all,
      ))!.firstWhere((d) => d.id == firstDream.id).favorite,
      !firstDream.favorite,
    );
    expect(find.byType(JournalScreen), findsOneWidget);
    final journalScroll = tester.widget<CustomScrollView>(
      find.byKey(const PageStorageKey('journal-scroll')),
    );
    final scrollable = find
        .descendant(
          of: find.byKey(journalScroll.key!),
          matching: find.byType(Scrollable),
        )
        .first;
    final state = tester.state<ScrollableState>(scrollable);
    state.position.jumpTo(state.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.byType(DreamJournalCard).last).dy,
      lessThan(tester.getTopLeft(find.byType(DreamTabBar)).dy),
    );
    state.position.jumpTo(0);
    await tester.pumpAndSettle();
    for (final size in [const Size(320, 740), const Size(844, 390)]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    tester.view.physicalSize = const Size(390, 844);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    expect(journalCount(21, false), '21 запись');
    expect(journalCount(12, false), '12 записей');
    router.go('/map');
    await tester.pumpAndSettle();
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    final beforeSearch = viewer.transformationController!.value.clone();
    await tester.enterText(find.byType(TextField), 'дверь');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(viewer.transformationController!.value, isNot(beforeSearch));
    expect(
      matchesUniverse(
        (await tester.runAsync(
          repo.all,
        ))!.firstWhere((d) => d.artwork == 'moon_library'),
        'луна',
        false,
      ),
      isTrue,
    );
    await tester.tap(find.byTooltip('Очистить поиск'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Меню карты'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Только сильные связи'));
    await tester.pumpAndSettle();
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<UniverseConnections>()
        .single;
    expect(painter.edges.every((e) => e.reasons.length >= 2), isTrue);
    for (final size in [const Size(320, 740), const Size(844, 390)]) {
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    container.read(settingsProvider.notifier).load({
      'animations': 'reduced',
      'theme': 'light',
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    router.go('/profile');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DreamStatsPanel), findsOneWidget);
    tester.view.physicalSize = const Size(320, 740);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.view.physicalSize = const Size(430, 932);
    await tester.pumpAndSettle();
    for (final label in [
      'Коллекция образов',
      'Наблюдения',
      'Календарь снов',
      'Настройки',
    ]) {
      final row = find.widgetWithText(DreamProfileMenuItem, label);
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(router.canPop(), isTrue);
      router.pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    final profileScrollable = find
        .descendant(
          of: find.byKey(const PageStorageKey('profile-scroll')),
          matching: find.byType(Scrollable),
        )
        .first;
    final profileState = tester.state<ScrollableState>(profileScrollable);
    profileState.position.jumpTo(profileState.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.byType(DreamPrivacyQuote)).dy,
      lessThan(tester.getTopLeft(find.byType(DreamTabBar)).dy),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    await tester.runAsync(() async {
      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
  });
}
