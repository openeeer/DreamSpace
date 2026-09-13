import 'dart:io';
import 'dart:ui' as ui;
import 'package:drift/native.dart';
import 'package:dreamspace/core/internal_page.dart';
import 'package:dreamspace/data/database.dart';
import 'package:dreamspace/data/providers.dart';
import 'package:dreamspace/data/repository.dart';
import 'package:dreamspace/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets(
    'Internal pages: settings persistence, pickers, responsive layouts and editor pop',
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
      for (final name in [
        '.SF Pro Text',
        '.SF Pro Display',
        'CupertinoSystemText',
        'CupertinoSystemDisplay',
      ]) {
        await tester.runAsync(
          (FontLoader(
            name,
          )..addFont(rootBundle.load('assets/fonts/Inter.ttf'))).load,
        );
      }
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final repo = DreamRepository(db);
      await tester.runAsync(repo.initialize);
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repo)],
      );
      container.read(settingsProvider.notifier).load({'animations': 'reduced'});
      final router = createRouter(true), boundary = GlobalKey();
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
      router.push('/settings');
      await settle();
      await tester.tap(find.text('English'));
      await settle();
      expect(container.read(settingsProvider)['language'], 'en');
      await tester.tap(find.text('Русский'));
      await settle();
      final time = find.widgetWithText(DreamSettingsRow, 'Время');
      await tester.scrollUntilVisible(
        time,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(time);
      await settle();
      expect(find.byType(CupertinoDatePicker), findsOneWidget);
      await tester.tap(find.text('Готово'));
      await settle();
      expect(container.read(settingsProvider)['hour'], '8');
      final opaque = find.byWidgetPredicate(
        (w) => w is DreamGlassSwitch && w.label == 'Плотные поверхности',
      );
      await tester.scrollUntilVisible(
        opaque,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(opaque);
      await settle();
      expect(container.read(settingsProvider)['opaque'], 'true');
      await tester.tap(opaque);
      await settle();
      router.pop();
      await settle();
      final dreams = (await tester.runAsync(repo.all))!;
      for (final (name, path) in [
        ('settings', '/settings'),
        ('elements', '/elements'),
        ('insights', '/insights'),
        ('calendar', '/calendar'),
        ('detail', '/dream/${dreams.first.id}'),
        ('editor', '/record'),
      ]) {
        router.push(path);
        await settle();
        await tester.runAsync(() async {
          final ctx = tester.element(find.byType(DreamInternalPage));
          for (final asset in [
            'assets/profile/dream_sphere.png',
            'assets/profile/profile_landscape.png',
            'assets/dreams/${dreams.first.artwork}.webp',
          ]) {
            if (ctx.mounted) await precacheImage(AssetImage(asset), ctx);
          }
        });
        await settle();
        const capture = String.fromEnvironment('INTERNAL_CAPTURE');
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
              '$capture/$name.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        for (final size in [const Size(320, 740), const Size(844, 390)]) {
          debugPrint('Checking $name at $size');
          tester.view.physicalSize = size;
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          await settle();
          final scroll = find
              .descendant(
                of: find.byType(DreamInternalPage),
                matching: find.byType(Scrollable),
              )
              .first;
          final state = tester.state<ScrollableState>(scroll);
          for (
            var i = 0;
            i < 8 && state.position.pixels < state.position.maxScrollExtent;
            i++
          ) {
            state.position.jumpTo(
              (state.position.pixels + 350).clamp(
                0,
                state.position.maxScrollExtent,
              ),
            );
            await settle();
          }
        }
        tester.platformDispatcher.clearTextScaleFactorTestValue();
        tester.view.physicalSize = const Size(430, 932);
        await settle();
        router.pop();
        await settle();
      }
      router.push('/record');
      await settle();
      await tester.enterText(
        find.byType(TextField).first,
        'Запись перед системным возвратом',
      );
      await tester.runAsync(() async {
        router.pop();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await settle();
      expect(
        (await tester.runAsync(repo.draft))?.description,
        'Запись перед системным возвратом',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      router.dispose();
      container.dispose();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(db.close);
    },
  );
}
