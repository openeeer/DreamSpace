import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../models/character.dart';
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

  // --- Characters -----------------------------------------------------------

  Stream<List<DreamCharacter>> watchCharacters() => db
      .customSelect(
        'SELECT id FROM character_rows',
        readsFrom: {db.characterRows},
      )
      .watch()
      .asyncMap((_) => characters());

  Future<List<DreamCharacter>> characters() async =>
      (await (db.select(db.characterRows)..orderBy([
            (t) => OrderingTerm.asc(t.created),
          ])).get())
          .map(
            (r) => DreamCharacter.fromJson(jsonDecode(r.payload) as Map<String, dynamic>),
          )
          .toList();

  Future<DreamCharacter?> character(String id) async {
    final row = await (db.select(
      db.characterRows,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null
        ? null
        : DreamCharacter.fromJson(jsonDecode(row.payload) as Map<String, dynamic>);
  }

  Future<DreamCharacter> saveCharacter(DreamCharacter character) async {
    await db
        .into(db.characterRows)
        .insertOnConflictUpdate(
          CharacterRowsCompanion.insert(
            id: character.id,
            payload: jsonEncode(character.toJson()),
            created: character.createdAt,
          ),
        );
    return character;
  }

  Future<DreamCharacter> newCharacter(String name, {String? relation}) =>
      saveCharacter(
        DreamCharacter(
          id: const Uuid().v4(),
          name: name.trim(),
          relation: relation?.trim(),
          createdAt: DateTime.now().toUtc(),
        ),
      );

  Future<void> deleteCharacter(String id) => (db.delete(
    db.characterRows,
  )..where((t) => t.id.equals(id))).go();

  // --- Character matches ----------------------------------------------------

  Stream<List<CharacterMatch>> watchMatches() => db
      .customSelect(
        'SELECT dream_id, candidate_id FROM match_rows',
        readsFrom: {db.matchRows},
      )
      .watch()
      .asyncMap((_) => matches());

  Future<List<CharacterMatch>> matches() async =>
      (await db.select(db.matchRows).get())
          .map(
            (r) => CharacterMatch.fromJson(jsonDecode(r.payload) as Map<String, dynamic>),
          )
          .toList();

  Future<List<CharacterMatch>> pendingMatches() async =>
      (await matches()).where((m) => m.resolved == null).toList();

  Future<void> saveMatch(CharacterMatch match) => db
      .into(db.matchRows)
      .insertOnConflictUpdate(
        MatchRowsCompanion.insert(
          dreamId: match.dreamId,
          candidateId: match.candidateId,
          payload: jsonEncode(match.toJson()),
        ),
      );

  /// A retry of the same dream must not resurrect matches the dreamer already
  /// resolved: the saved verdict wins over a fresh unresolved suggestion.
  Future<void> saveMatchPreservingVerdict(CharacterMatch match) async {
    final row = await (db.select(
      db.matchRows,
    )..where(
        (t) =>
            t.dreamId.equals(match.dreamId) &
            t.candidateId.equals(match.candidateId),
      )).getSingleOrNull();
    if (row == null) {
      await saveMatch(match);
      return;
    }
    final saved = CharacterMatch.fromJson(
      jsonDecode(row.payload) as Map<String, dynamic>,
    );
    await saveMatch(match.copyWith(resolved: saved.resolved));
  }

  /// Resolving a match is the only way an assistant suggestion becomes a
  /// real link. Accept: the character joins the dream's elements (if not
  /// already there). Reject: a new profile is born instead, ready for the
  /// dreamer to fill in their own time.
  Future<DreamCharacter?> resolveMatch(
    CharacterMatch match,
    bool accepted,
  ) async {
    await saveMatch(match.copyWith(resolved: accepted));
    if (accepted) {
      final dreams = await all();
      final dream = dreams.where((d) => d.id == match.dreamId).firstOrNull;
      if (dream != null) {
        final profile = await character(match.candidateId);
        final alreadyThere = dream.ofKind(ElementKind.character).any(
          (e) => e.id == match.candidateId || normalize(e.name) == normalize(match.candidateName),
        );
        if (!alreadyThere && profile != null) {
          await save(
            dream.copyWith(
              elements: [
                ...dream.elements,
                DreamElement(
                  id: profile.id,
                  name: profile.name,
                  kind: ElementKind.character,
                ),
              ],
            ),
          );
        }
      }
      return null;
    }
    // Rejected: spawn a fresh profile from the recognized name so the
    // dreamer can describe who this actually was.
    return newCharacter(match.candidateName);
  }

  /// Server processing results land here: fields the dreamer already set are
  /// never overwritten, and matches stay unresolved for one-tap review.
  Future<void> applyProcessing(
    Dream base,
    ProcessingResult result,
  ) => db.transaction(() async {
    final merged = base.copyWith(
      mood: result.mood,
      clearMood: result.mood == null,
      type: result.type,
      theme: result.theme,
      clearTheme: result.theme == null,
      lucidity: result.lucidity,
      vividness: result.vividness,
      artwork: result.artwork,
      // Every present field is AI-suggested until the dreamer edits it.
      aiSuggested: true,
    );
    await save(merged);
    final existingElements = {for (final e in base.elements) e.id};
    final fresh = [
      for (final element in result.elements)
        if (!existingElements.contains(element.id)) element,
    ];
    if (fresh.isNotEmpty) {
      await save(merged.copyWith(elements: [...base.elements, ...fresh]));
    }
    for (final match in result.matches) {
      await saveMatchPreservingVerdict(match);
    }
  });

  Future<void> setDreamStatus(String dreamId, ProcessingStatus status) async {
    final dreams = await all();
    final dream = dreams.where((d) => d.id == dreamId).firstOrNull;
    if (dream == null) return;
    await save(dream.copyWith(status: status));
  }
}

/// What the server will eventually return for one processed dream. The mock
/// pipeline produces this; the real one will shape it from an API response.
class ProcessingResult {
  const ProcessingResult({
    required this.elements,
    this.mood,
    this.type,
    this.theme,
    this.lucidity,
    this.vividness,
    this.artwork,
    this.matches = const [],
  });
  final Mood? mood;
  final DreamType? type;
  final DreamTheme? theme;
  final int? lucidity, vividness;
  final String? artwork;
  final List<DreamElement> elements;
  final List<CharacterMatch> matches;
}
