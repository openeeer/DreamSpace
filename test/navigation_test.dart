import 'package:drift/native.dart';
import 'package:dreamspace/core/design.dart';
import 'package:dreamspace/data/database.dart';
import 'package:dreamspace/data/providers.dart';
import 'package:dreamspace/data/repository.dart';
import 'package:dreamspace/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets('Animated navigation: card taps, all tabs, back, draft close', (
    tester,
  ) async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() => initializeDateFormatting('ru'));
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DreamRepository(db);
    await tester.runAsync(repo.initialize);
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    container.read(settingsProvider.notifier).load({'onboarded': 'true'});
    final router = createRouter(true);
    Future<void> frame() async {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: DreamSpaceApp(router: router),
      ),
    );
    await frame();
    await tester.tap(find.byType(DreamCard).first);
    await frame();
    expect(find.byTooltip('Редактировать'), findsOneWidget);
    await tester.tap(find.byIcon(CupertinoIcons.back));
    await frame();
    expect(find.text('DreamSpace'), findsOneWidget);
    await tester.longPress(find.byType(DreamCard).first);
    await frame();
    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    await tester.tap(find.text('Убрать из избранного'));
    await frame();
    expect((await tester.runAsync(repo.all))!.first.favorite, isFalse);
    for (final (label, heading) in [
      ('Дневник', 'Поиск снов, мест, символов'),
      ('Карта', 'Вселенная снов'),
      ('Профиль', 'Мой мир'),
      ('Главная', 'DreamSpace'),
      ('Дневник', 'Поиск снов, мест, символов'),
    ]) {
      await tester.tap(find.text(label).last);
      await frame();
      expect(find.text(heading), findsOneWidget);
    }
    await tester.enterText(find.byType(TextField), 'несуществующий сон');
    await frame();
    await tester.tap(find.byTooltip('Очистить поиск'));
    await frame();
    expect(find.byType(DreamCard), findsWidgets);
    await tester.tap(find.byTooltip('Записать сон'));
    await frame();
    await tester.tap(find.byTooltip('Закрыть, сохранив черновик'));
    await frame();
    expect(find.text('Поиск снов, мест, символов'), findsOneWidget);
    await tester.tap(find.byTooltip('Записать сон'));
    await frame();
    await tester.enterText(
      find.byType(TextField).first,
      'Черновик после закрытия',
    );
    await tester.tap(find.byTooltip('Закрыть, сохранив черновик'));
    await frame();
    await frame();
    expect(find.text('Поиск снов, мест, символов'), findsOneWidget);
    expect(
      (await tester.runAsync(repo.draft))?.description,
      'Черновик после закрытия',
    );
    await tester.tap(find.byTooltip('Записать сон'));
    await frame();
    expect(find.text('Черновик восстановлен'), findsOneWidget);
    await tester.tap(find.byTooltip('Удалить черновик'));
    await frame();
    await tester.tap(find.text('Удалить'));
    await frame();
    await frame();
    expect(find.text('Поиск снов, мест, символов'), findsOneWidget);
    expect(await tester.runAsync(repo.draft), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    await tester.runAsync(() async {
      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump(const Duration(milliseconds: 50));
  });
}
