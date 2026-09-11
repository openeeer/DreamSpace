import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dreamspace/main.dart';
import 'package:dreamspace/data/database.dart';
import 'package:dreamspace/data/repository.dart';
import 'package:dreamspace/data/providers.dart';

void main() {
  testWidgets('Russian home renders, tabs navigate, English settings apply', (
    tester,
  ) async {
    await tester.runAsync(() => initializeDateFormatting('ru'));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(() => db.close());
    final repo = DreamRepository(db);
    await tester.runAsync(() => repo.initialize());
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    container.read(settingsProvider.notifier).load({
      'animations': 'reduced',
      'onboarded': 'true',
    });
    final router = createRouter(true);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: DreamSpaceApp(router: router),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );
    expect(find.text('DreamSpace'), findsOneWidget);
    expect(find.text('Лунная библиотека'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Дневник'));
    await tester.pumpAndSettle();
    expect(find.text('Поиск снов, мест, символов'), findsOneWidget);
    await tester.tap(find.text('Карта'));
    await tester.pumpAndSettle();
    expect(find.text('Вселенная снов'), findsOneWidget);
    expect(tester.takeException(), isNull);
    router.push('/record');
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'Тестовый сон: я видел лунное море.',
    );
    await tester.runAsync(() => tester.tap(find.text('Сохранить сон')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1200)),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(seconds: 2));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }
    final saved = await tester.runAsync(() => repo.all());
    expect(saved!.any((d) => d.description.contains('Тестовый сон')), isTrue);
    expect(find.text('Что тебе приснилось?'), findsNothing);
    router.push('/settings');
    await tester.pumpAndSettle();
    await tester.runAsync(() => tester.tap(find.text('English')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    await tester.runAsync(() async {
      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(milliseconds: 50));
  });
}
