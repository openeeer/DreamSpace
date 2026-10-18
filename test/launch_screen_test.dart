import 'dart:io';
import 'dart:ui' as ui;
import 'package:dreamspace/core/launch_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

class _Haptics implements LaunchHaptics {
  int preparations = 0, plays = 0, stops = 0;
  Duration? duration;
  bool? reduced;
  @override
  Future<bool> prepare() async {
    preparations++;
    return true;
  }

  @override
  Future<void> play({
    required Duration duration,
    required bool reducedMotion,
  }) async {
    plays++;
    this.duration = duration;
    reduced = reducedMotion;
  }

  @override
  Future<void> stop() async {
    stops++;
  }
}

class _Destination extends StatefulWidget {
  const _Destination({required this.onMount});
  final VoidCallback onMount;
  @override
  State<_Destination> createState() => _DestinationState();
}

class _DestinationState extends State<_Destination> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: launchNight,
    child: Center(
      child: Text('Journal ready', textDirection: TextDirection.ltr),
    ),
  );
}

Future<void> _decode(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 150)),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'Cold launch fills once, reveals before two seconds and preserves app state',
    (tester) async {
      final haptics = _Haptics();
      var mounts = 0, loads = 0, backgroundReady = 0;
      await tester.pumpWidget(
        DreamLaunch(
          haptics: haptics,
          onBackgroundReady: () => backgroundReady++,
          initialize: () async {
            loads++;
            return LaunchDestination(
              app: _Destination(onMount: () => mounts++),
            );
          },
        ),
      );
      await _decode(tester);
      expect(backgroundReady, 1);
      expect(haptics.plays, 1);
      expect(haptics.duration, const Duration(milliseconds: 1650));
      expect(find.byType(LaunchArtwork), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1600));
      expect(find.byType(LaunchArtwork), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 230));
      expect(find.byType(LaunchArtwork), findsNothing);
      expect(mounts, 1);
      expect(find.text('Journal ready'), findsOneWidget);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(loads, 1);
      expect(haptics.plays, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Stored accessibility preferences disable haptics and shorten motion',
    (tester) async {
      final haptics = _Haptics();
      await tester.pumpWidget(
        DreamLaunch(
          haptics: haptics,
          initialize: () async => const LaunchDestination(
            app: SizedBox.expand(),
            haptics: false,
            reducedMotion: true,
          ),
        ),
      );
      await _decode(tester);
      expect(haptics.preparations, 0);
      expect(haptics.plays, 0);
      expect(
        tester.widget<LaunchArtwork>(find.byType(LaunchArtwork)).reducedMotion,
        true,
      );
      await tester.pump(const Duration(milliseconds: 1201));
      await tester.pump(const Duration(milliseconds: 181));
      expect(find.byType(LaunchArtwork), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Backgrounding cancels tactile output and resumes without replay',
    (tester) async {
      final haptics = _Haptics();
      await tester.pumpWidget(
        DreamLaunch(
          haptics: haptics,
          initialize: () async =>
              const LaunchDestination(app: SizedBox.expand()),
        ),
      );
      await _decode(tester);
      await tester.pump(const Duration(milliseconds: 450));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      final stops = haptics.stops;
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(LaunchArtwork), findsOneWidget);
      expect(stops, greaterThan(0));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1201));
      await tester.pump(const Duration(milliseconds: 230));
      expect(haptics.plays, 1);
      expect(find.byType(LaunchArtwork), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('Initialization failure offers retry and keeps launch usable', (
    tester,
  ) async {
    final haptics = _Haptics();
    var attempts = 0;
    await tester.pumpWidget(
      DreamLaunch(
        haptics: haptics,
        initialize: () async {
          if (attempts++ == 0) throw StateError('Test storage unavailable');
          return const LaunchDestination(app: SizedBox.expand());
        },
      ),
    );
    await _decode(tester);
    expect(find.text('Попробовать снова'), findsOneWidget);
    await tester.tap(find.text('Попробовать снова'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1651));
    await tester.pump(const Duration(milliseconds: 221));
    expect(attempts, 2);
    expect(find.byType(LaunchArtwork), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Launch artwork fits portrait and landscape; optional native asset and animation capture',
    (tester) async {
      final key = GlobalKey();
      Future<void> save(String path, {double ratio = 1}) => tester.runAsync(
        () async {
          final image =
              await (key.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: ratio);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(path).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        },
      );
      const moon = String.fromEnvironment('LAUNCH_MOON_CAPTURE');
      if (moon.isNotEmpty) {
        await tester.pumpWidget(
          Center(
            child: RepaintBoundary(
              key: key,
              child: CustomPaint(
                size: const Size(76, 76),
                painter: CrescentFillPainter(const AlwaysStoppedAnimation(0)),
              ),
            ),
          ),
        );
        await save(moon, ratio: 3);
        await tester.pumpWidget(const SizedBox());
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      for (final size in [
        const Size(390, 844),
        const Size(320, 568),
        const Size(844, 390),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: const LaunchArtwork(progress: AlwaysStoppedAnimation(.5)),
          ),
        );
        await _decode(tester);
        expect(tester.takeException(), isNull);
      }
      const capture = String.fromEnvironment('LAUNCH_CAPTURE');
      if (capture.isNotEmpty) {
        tester.view.physicalSize = const Size(390, 844);
        for (var i = 0; i <= 30; i++) {
          await tester.pumpWidget(
            RepaintBoundary(
              key: key,
              child: LaunchArtwork(progress: AlwaysStoppedAnimation(i / 30)),
            ),
          );
          await tester.pump();
          await save('$capture/frame_${i.toString().padLeft(3, '0')}.png');
        }
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
}
