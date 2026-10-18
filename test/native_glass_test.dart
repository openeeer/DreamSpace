import 'package:dreamspace/core/internal_page.dart';
import 'package:dreamspace/core/native_glass.dart';
import 'package:dreamspace/core/native_tab_bar.dart';
import 'package:dreamspace/core/native_presentations.dart';
import 'package:dreamspace/core/design.dart';
import 'package:dreamspace/data/providers.dart';
import 'package:dreamspace/data/database.dart';
import 'package:dreamspace/data/repository.dart';
import 'package:dreamspace/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

// These tests exercise the Flutter/UIKit protocol. Actual UIKit rendering is
// deliberately not mocked as evidence of Liquid Glass quality.
void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final views = <int, Map<Object?, Object?>>{};
  final types = <int, String>{};
  final channels = <MethodChannel>[];

  setUp(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      (call) async {
        if (call.method == 'create') {
          final args = call.arguments as Map;
          final id = args['id'] as int;
          types[id] = args['viewType'] as String;
          views[id] = Map<Object?, Object?>.from(
            const StandardMessageCodec().decodeMessage(
                  ByteData.sublistView(args['params'] as Uint8List),
                )
                as Map,
          );
          final name = types[id] == 'dreamspace/native-tabs'
              ? 'native-tabs'
              : 'native-glass';
          final channel = MethodChannel('dreamspace/$name/$id');
          channels.add(channel);
          binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
            call,
          ) async {
            if (call.method == 'update') {
              views[id] = Map<Object?, Object?>.from(call.arguments as Map);
            }
            return null;
          });
        }
        return null;
      },
    );
  });
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform_views,
      null,
    );
    for (final channel in channels) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    }
    views.clear();
    types.clear();
    channels.clear();
  });

  Future<void> nativeEvent(int id, String method, Object value) async {
    final name = types[id] == 'dreamspace/native-tabs'
        ? 'native-tabs'
        : 'native-glass';
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      'dreamspace/$name/$id',
      const StandardMethodCodec().encodeMethodCall(MethodCall(method, value)),
      (_) {},
    );
  }

  testWidgets(
    'iOS menus, confirmation and dates use native presentation with typed results',
    (tester) async {
      final calls = <MethodCall>[];
      final initial = DateTime(2026, 10, 18, 8, 30);
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        nativePresentations,
        (call) async {
          calls.add(call);
          return switch (call.method) {
            'actions' => 'share',
            'confirm' => false,
            'date' => initial.millisecondsSinceEpoch,
            _ => null,
          };
        },
      );
      addTearDown(
        () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
          nativePresentations,
          null,
        ),
      );
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox();
            },
          ),
        ),
      );
      final action = await dreamActionSheet(
        context,
        title: 'Dream',
        actions: const [('share', 'Share'), ('delete', 'Delete')],
        cancelLabel: 'Cancel',
        destructive: const {'delete'},
      );
      expect(action, 'share');
      final menu = calls.single.arguments as Map;
      expect(menu['dark'], true);
      expect((menu['actions'] as List).last['destructive'], true);
      expect(
        await confirm(context, true, 'Delete?', 'Delete this dream'),
        false,
      );
      if (!context.mounted) return;
      final picked = await dreamDatePicker(context, initial: initial, en: true);
      expect(picked?.millisecondsSinceEpoch, initial.millisecondsSinceEpoch);
      expect((calls.last.arguments as Map)['mode'], 'dateAndTime');
      if (!context.mounted) return;
      await dreamNotice(context, 'Saved', 'Dream saved');
      expect(calls.last.method, 'alert');
      expect(tester.takeException(), isNull);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'iPhone screens lay out with native controls at 200 percent text',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.runAsync(() => initializeDateFormatting('ru'));
      for (final font in ['Lora', 'Inter']) {
        final loader = FontLoader(font)
          ..addFont(rootBundle.load('assets/fonts/$font.ttf'));
        await tester.runAsync(loader.load);
      }
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DreamRepository(db);
      await tester.runAsync(repo.initialize);
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.read(settingsProvider.notifier).load({'animations': 'reduced'});
      final router = createRouter(true);
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: DreamSpaceApp(router: router),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      for (final size in [
        const Size(430, 932),
        const Size(320, 740),
        const Size(844, 390),
      ]) {
        router.go('/home');
        await tester.pumpAndSettle();
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = size.width == 430
            ? 1
            : 2;
        for (final route in [
          '/home',
          '/journal',
          '/map',
          '/profile',
          '/settings',
          '/record',
          '/dream/demo-0',
          '/insights',
          '/elements',
          '/calendar',
        ]) {
          router.go(route);
          await tester.pumpAndSettle();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 80)),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$route at $size');
        }
      }
      await tester.pumpWidget(const SizedBox());
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Native button keeps identity and updates state, theme and accessibility',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      var taps = 0;
      Future<void> show({required bool enabled, required bool light}) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: ThemeData(
                brightness: light ? Brightness.light : Brightness.dark,
              ),
              home: Scaffold(
                body: Center(
                  child: NativeGlassButton(
                    label: enabled ? 'Готово' : 'Done',
                    prominent: true,
                    onPressed: enabled ? () => taps++ : null,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show(enabled: true, light: false);
      final id = views.keys.single;
      expect(views[id]!['enabled'], true);
      expect(views[id]!['dark'], true);
      await nativeEvent(id, 'change', true);
      expect(taps, 1);
      container.read(settingsProvider.notifier).load({
        'opaque': 'true',
        'animations': 'reduced',
      });
      await show(enabled: false, light: true);
      expect(views.keys.single, id);
      expect(views[id]!['label'], 'Done');
      expect(views[id]!['enabled'], false);
      expect(views[id]!['dark'], false);
      expect(views[id]!['opaque'], true);
      expect(views[id]!['reducedMotion'], true);
      await nativeEvent(id, 'change', true);
      expect(taps, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Native choices adapt to large text and switch events reach Flutter',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      bool? toggled;
      String? selected;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DreamGlassSwitch(
                        value: false,
                        label: 'Напоминания',
                        onChanged: (value) => toggled = value,
                      ),
                      DreamSegmentedControl<String>(
                        value: 'dark',
                        options: const {
                          'dark': 'Night',
                          'light': 'Mist',
                          'system': 'System',
                        },
                        onChanged: (value) => selected = value,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final switchId = views.entries
          .singleWhere((e) => e.value['kind'] == 'switch')
          .key;
      await nativeEvent(switchId, 'change', true);
      expect(toggled, true);
      final segmentsId = views.entries
          .singleWhere((e) => e.value['kind'] == 'segments')
          .key;
      await nativeEvent(segmentsId, 'change', 2);
      expect(selected, 'system');
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pump();
      await tester.pump();
      expect(find.byType(NativeGlassButton), findsNWidgets(3));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'Native tabs use system height and report selection',
    (tester) async {
      int? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: DreamTabBar(
                index: 1,
                labels: const ['Главная', 'Дневник', 'Карта', 'Профиль'],
                opaque: false,
                onSelected: (value) => selected = value,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final id = views.keys.single;
      expect(types[id], 'dreamspace/native-tabs');
      expect(views[id]!['index'], 1);
      await nativeEvent(id, 'height', 83.0);
      await tester.pump();
      expect(tester.getSize(find.byType(UiKitView)).height, 83);
      await nativeEvent(id, 'height', -1.0);
      await tester.pump();
      expect(tester.getSize(find.byType(UiKitView)).height, 83);
      await nativeEvent(id, 'select', 3);
      expect(selected, 3);
      await tester.pumpWidget(const SizedBox());
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
