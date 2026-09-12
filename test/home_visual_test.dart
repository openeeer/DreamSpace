import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:dreamspace/main.dart';
import 'package:dreamspace/data/database.dart';
import 'package:dreamspace/data/repository.dart';
import 'package:dreamspace/data/providers.dart';
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
    const output = String.fromEnvironment('HOME_CAPTURE');
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
    container.read(settingsProvider.notifier).load({
      'animations': 'reduced',
      'theme': 'light',
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    router.dispose();
    await tester.runAsync(() async {
      container.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
  });
}
