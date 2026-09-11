import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dreamspace/data/database.dart';
import 'package:dreamspace/data/repository.dart';
import 'package:dreamspace/data/demo.dart';
import 'package:dreamspace/models/dream.dart';
import 'package:dreamspace/features/insights/analytics.dart';
import 'package:dreamspace/features/dream_map/map_screen.dart';

void main() {
  late AppDatabase db;
  late DreamRepository repo;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DreamRepository(db);
  });
  tearDown(() async => db.close());
  test('Demo seed is idempotent and deletion never reseeds', () async {
    await repo.initialize();
    await repo.initialize();
    expect(await repo.all(), hasLength(8));
    await repo.clear();
    await repo.initialize();
    expect(await repo.all(), isEmpty);
  });
  test(
    'Shared element rename updates every dream, deletion preserves others',
    () async {
      await repo.initialize();
      final dreams = await repo.all();
      final moon = dreams.first.elements.firstWhere((e) => e.name == 'Луна');
      await repo.renameElement(moon, 'Полная Луна');
      final renamed = await repo.all();
      expect(
        renamed
            .expand((d) => d.elements)
            .where((e) => e.id == moon.id)
            .every((e) => e.name == 'Полная Луна'),
        isTrue,
      );
      await repo.delete(dreams.first.id);
      expect(await repo.all(), hasLength(7));
      expect(
        (await repo.all())
            .expand((d) => d.elements)
            .any((e) => e.id == moon.id),
        isTrue,
      );
    },
  );
  test(
    'Duplicate normalized elements merge and draft survives repository recreation',
    () async {
      final now = DateTime(2026, 9, 11);
      final d = Dream(
        id: 'test',
        title: 'Test',
        description: 'Water',
        date: now,
        createdAt: now,
        updatedAt: now,
        elements: [
          DreamElement(id: 'a', name: ' Water ', kind: ElementKind.symbol),
          DreamElement(id: 'b', name: 'water', kind: ElementKind.symbol),
        ],
      );
      await repo.save(d);
      expect((await repo.all()).single.elements, hasLength(1));
      await repo.saveDraft(d);
      expect((await DreamRepository(db).draft())!.description, 'Water');
    },
  );
  test('Graph uses real shared elements without duplicate pairs', () {
    final data = demoDreams(DateTime(2026, 9, 11));
    final graph = connections(data, mood: false);
    expect(
      graph.any(
        (e) => e.a == 'demo-0' && e.b == 'demo-1' && e.reasons.contains('Луна'),
      ),
      isTrue,
    );
    expect(graph.map((e) => '${e.a}:${e.b}').toSet().length, graph.length);
    expect(connections(data, kinds: {}, mood: false), isEmpty);
  });
  test('Streak counts dates once across a year boundary', () {
    final now = DateTime(2027, 1, 2);
    Dream d(String id, DateTime date) => Dream(
      id: id,
      title: id,
      description: id,
      date: date,
      createdAt: date,
      updatedAt: date,
    );
    final data = [
      d('a', DateTime(2026, 12, 30)),
      d('b', DateTime(2026, 12, 31)),
      d('c', DateTime(2027, 1, 1)),
      d('d', DateTime(2027, 1, 1)),
    ];
    expect(DreamStats(data, now: now).streak, 3);
    expect(DreamStats(data, now: now).longest, 3);
    expect(DreamStats(data, now: DateTime(2027, 1, 3)).streak, 0);
  });
  test('Map separates 100 colliding nodes including newly inserted dreams', () {
    final date = DateTime(2026, 9, 12);
    final dreams = List.generate(
      100,
      (i) => Dream(
        id: '$i',
        title: 'Dream $i',
        description: '',
        date: date,
        createdAt: date,
        updatedAt: date,
      ),
    );
    final positions = layoutGraph(
      dreams,
      connections(dreams),
      previous: {for (final d in dreams.take(99)) d.id: const Offset(650, 650)},
    );
    final points = positions.values.toList();
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        expect((points[i] - points[j]).distance, greaterThanOrEqualTo(159.99));
      }
    }
    expect(
      layoutGraph(dreams, connections(dreams), previous: positions),
      positions,
    );
  });
}
