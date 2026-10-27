import 'package:dreamspace/data/demo.dart';
import 'package:dreamspace/data/providers.dart';
import 'package:dreamspace/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _TestSettings extends SettingsController {
  @override
  Map<String, String> build() => {
    'animations': 'full',
    'haptics': 'false',
    'language': 'ru',
    'theme': 'dark',
  };
}

Future<void> pumpHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith(_TestSettings.new),
        dreamsProvider.overrideWith(
          (ref) => Stream.value(demoDreams(DateTime(2026, 9, 18))),
        ),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

double sliderPage(WidgetTester tester) {
  final view = tester.widget<PageView>(find.byType(PageView));
  return view.controller?.page ?? -1;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
  });
  testWidgets('carousel keeps page after vertical scroll down and up', (
    tester,
  ) async {
    await pumpHome(tester);
    expect(find.byType(PageView), findsOneWidget);
    expect(sliderPage(tester), 0);

    // Swipe carousel to page 1 so we have a non-trivial position.
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    debugPrint('AFTER CAROUSEL SWIPE: page=${sliderPage(tester)}');
    expect(sliderPage(tester), 1);

    // Scroll the whole home page far down and back up: the carousel position
    // must survive (whether the sliver keeps it cached is an implementation
    // detail; the user-visible behavior is that page is preserved).
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2500));
    await tester.pumpAndSettle();

    // ...and back up to the top.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 2500));
    await tester.pumpAndSettle();

    debugPrint('PAGE AFTER SCROLL: ${sliderPage(tester)}');
    expect(sliderPage(tester), 1);
  });
}
