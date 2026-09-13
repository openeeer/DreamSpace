import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:dreamspace/data/database.dart';
import 'package:dreamspace/data/providers.dart';
import 'package:dreamspace/data/repository.dart';
import 'package:dreamspace/features/onboarding/onboarding_screen.dart';
import 'package:dreamspace/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets(
    'First launch: pages, accessibility sizes, finish and skip persistence',
    (tester) async {
      await tester.runAsync(() => initializeDateFormatting('ru'));
      for (final font in ['Lora', 'Inter']) {
        await tester.runAsync(
          (FontLoader(
            font,
          )..addFont(rootBundle.load('assets/fonts/$font.ttf'))).load,
        );
      }
      await tester.runAsync(
        (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
              rootBundle.load(
                'packages/cupertino_icons/assets/CupertinoIcons.ttf',
              ),
            ))
            .load,
      );
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = DreamRepository(db);
      await tester.runAsync(repo.initialize);
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repo)],
      );
      container.read(settingsProvider.notifier).load({'animations': 'reduced'});
      final router = createRouter(false), boundary = GlobalKey();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(430, 932);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: boundary,
            child: DreamSpaceApp(router: router),
          ),
        ),
      );
      Future<void> settle() async {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await settle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(OnboardingScreen));
        for (final asset in [
          'assets/profile/dream_sphere.png',
          'assets/profile/profile_landscape.png',
          for (final name in [
            'moon_library',
            'ocean_without_end',
            'glass_staircase',
            'sky_islands',
            'red_forest',
          ])
            'assets/dreams/$name.webp',
        ]) {
          if (context.mounted) await precacheImage(AssetImage(asset), context);
        }
      });
      await settle();
      for (var page = 0; page < 3; page++) {
        const capture = String.fromEnvironment('ONBOARDING_CAPTURE');
        if (capture.isNotEmpty) {
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '$capture/onboarding-$page.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        for (final size in [const Size(320, 568), const Size(844, 390)]) {
          tester.view.physicalSize = size;
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          await settle();
        }
        tester.view.physicalSize = const Size(430, 932);
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        await settle();
        await tester.tap(
          find.text(page == 2 ? 'Открыть DreamSpace' : 'Продолжить'),
        );
        await settle();
      }
      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(container.read(settingsProvider)['onboarded'], 'true');
      expect(
        (await tester.runAsync(
          () => db.select(db.preferences).get(),
        ))!.any((row) => row.key == 'onboarded' && row.value == 'true'),
        isTrue,
      );
      await tester.runAsync(
        () =>
            container.read(settingsProvider.notifier).set('onboarded', 'false'),
      );
      await tester.runAsync(
        () => container.read(settingsProvider.notifier).set('language', 'en'),
      );
      await tester.runAsync(
        () => container.read(settingsProvider.notifier).set('theme', 'light'),
      );
      router.go('/onboarding');
      await settle();
      tester.view.physicalSize = const Size(844, 390);
      await settle();
      await tester.tap(find.text('Skip'));
      await settle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(container.read(settingsProvider)['onboarded'], 'true');
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      container.dispose();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(db.close);
    },
  );
}
