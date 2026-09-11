import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../models/dream.dart';
import 'database.dart';
import 'demo.dart';

class DreamRepository {
  DreamRepository(this.db);
  final AppDatabase db;
  Future<void> initialize() async {
    if (await setting('initialized') != null) return;
    await db.transaction(() async {
      for (final dream in demoDreams(DateTime.now())) {
        await save(dream);
      }
      await setSetting('initialized', 'true');
      await setSetting('joined', DateTime.now().toIso8601String());
    });
  }

  Stream<List<Dream>> watchDreams() => db
      .customSelect(
        'SELECT id FROM dream_rows',
        readsFrom: {db.dreamRows, db.elementRows, db.dreamLinks},
      )
      .watch()
      .asyncMap((_) => all());
  Future<List<Dream>> all() async {
    final rows = await (db.select(
      db.dreamRows,
    )..orderBy([(t) => OrderingTerm.desc(t.created)])).get();
    final elements = {
      for (final e in await db.select(db.elementRows).get())
        e.id: DreamElement(
          id: e.id,
          name: e.name,
          kind: ElementKind.values.byName(e.kind),
        ),
    };
    final links = await db.select(db.dreamLinks).get();
    return rows.map((r) {
      final json = jsonDecode(r.payload) as Map<String, dynamic>;
      json['elements'] = links
          .where((l) => l.dreamId == r.id)
          .map((l) => elements[l.elementId]!.toJson())
          .toList();
      return Dream.fromJson(json);
    }).toList();
  }

  Future<void> save(Dream dream) => db.transaction(() async {
    await db
        .into(db.dreamRows)
        .insertOnConflictUpdate(
          DreamRowsCompanion.insert(
            id: dream.id,
            payload: jsonEncode({...dream.toJson(), 'elements': []}),
            date: dateKey(dream.date),
            created: dream.createdAt,
          ),
        );
    await (db.delete(
      db.dreamLinks,
    )..where((t) => t.dreamId.equals(dream.id))).go();
    for (final element in dream.elements) {
      final normalized = normalize(element.name);
      if (normalized.isEmpty) continue;
      final existing =
          await (db.select(db.elementRows)..where(
                (t) =>
                    t.normalized.equals(normalized) &
                    t.kind.equals(element.kind.name),
              ))
              .getSingleOrNull();
      final id = existing?.id ?? element.id;
      if (existing == null) {
        await db
            .into(db.elementRows)
            .insert(
              ElementRowsCompanion.insert(
                id: id,
                name: element.name.trim(),
                normalized: normalized,
                kind: element.kind.name,
              ),
            );
      }
      await db
          .into(db.dreamLinks)
          .insert(
            DreamLinksCompanion.insert(dreamId: dream.id, elementId: id),
            mode: InsertMode.insertOrIgnore,
          );
    }
  });
  Future<void> delete(String id) async {
    await (db.delete(db.dreamRows)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clear({bool demoOnly = false}) => db.transaction(() async {
    for (final dream in await all()) {
      if (!demoOnly || dream.demo) await delete(dream.id);
    }
    await db.customStatement(
      'DELETE FROM element_rows WHERE id NOT IN (SELECT element_id FROM dream_links)',
    );
    await clearDraft();
  });
  Future<List<DreamElement>> elements() async =>
      (await db.select(db.elementRows).get())
          .map(
            (e) => DreamElement(
              id: e.id,
              name: e.name,
              kind: ElementKind.values.byName(e.kind),
            ),
          )
          .toList();
  Future<void> renameElement(DreamElement element, String name) async {
    final clean = name.trim();
    if (clean.isEmpty) throw ArgumentError('Empty name');
    await (db.update(
      db.elementRows,
    )..where((t) => t.id.equals(element.id))).write(
      ElementRowsCompanion(
        name: Value(clean),
        normalized: Value(normalize(clean)),
      ),
    );
  }

  Future<String?> setting(String key) async => (await (db.select(
    db.preferences,
  )..where((t) => t.key.equals(key))).getSingleOrNull())?.value;
  Future<void> setSetting(String key, String value) async => db
      .into(db.preferences)
      .insertOnConflictUpdate(
        PreferencesCompanion.insert(key: key, value: value),
      );
  Future<void> clearDraft() async =>
      (db.delete(db.preferences)..where((t) => t.key.equals('draft'))).go();
  Future<void> saveDraft(Dream dream) =>
      setSetting('draft', jsonEncode(dream.toJson()));
  Future<Dream?> draft() async {
    final value = await setting('draft');
    return value == null
        ? null
        : Dream.fromJson(jsonDecode(value) as Map<String, dynamic>);
  }

  DreamElement newElement(String name, ElementKind kind) =>
      DreamElement(id: const Uuid().v4(), name: name.trim(), kind: kind);
}
