import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

class DreamRows extends Table {
  TextColumn get id => text()();
  TextColumn get payload => text()();
  TextColumn get date => text()();
  DateTimeColumn get created => dateTime()();
  @override
  Set<Column> get primaryKey => {id};
}

class ElementRows extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get normalized => text()();
  TextColumn get kind => text()();
  @override
  Set<Column> get primaryKey => {id};
  @override
  List<Set<Column>> get uniqueKeys => [
    {normalized, kind},
  ];
}

class DreamLinks extends Table {
  TextColumn get dreamId =>
      text().references(DreamRows, #id, onDelete: KeyAction.cascade)();
  TextColumn get elementId =>
      text().references(ElementRows, #id, onDelete: KeyAction.cascade)();
  @override
  Set<Column> get primaryKey => {dreamId, elementId};
}

class Preferences extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [DreamRows, ElementRows, DreamLinks, Preferences])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'dreamspace'));
  AppDatabase.forTesting(super.executor);
  @override
  int get schemaVersion => 1;
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (_) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
