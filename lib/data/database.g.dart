// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DreamRowsTable extends DreamRows
    with TableInfo<$DreamRowsTable, DreamRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DreamRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, payload, date, created];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dream_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<DreamRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DreamRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DreamRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created'],
      )!,
    );
  }

  @override
  $DreamRowsTable createAlias(String alias) {
    return $DreamRowsTable(attachedDatabase, alias);
  }
}

class DreamRow extends DataClass implements Insertable<DreamRow> {
  final String id;
  final String payload;
  final String date;
  final DateTime created;
  const DreamRow({
    required this.id,
    required this.payload,
    required this.date,
    required this.created,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    map['date'] = Variable<String>(date);
    map['created'] = Variable<DateTime>(created);
    return map;
  }

  DreamRowsCompanion toCompanion(bool nullToAbsent) {
    return DreamRowsCompanion(
      id: Value(id),
      payload: Value(payload),
      date: Value(date),
      created: Value(created),
    );
  }

  factory DreamRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DreamRow(
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
      date: serializer.fromJson<String>(json['date']),
      created: serializer.fromJson<DateTime>(json['created']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
      'date': serializer.toJson<String>(date),
      'created': serializer.toJson<DateTime>(created),
    };
  }

  DreamRow copyWith({
    String? id,
    String? payload,
    String? date,
    DateTime? created,
  }) => DreamRow(
    id: id ?? this.id,
    payload: payload ?? this.payload,
    date: date ?? this.date,
    created: created ?? this.created,
  );
  DreamRow copyWithCompanion(DreamRowsCompanion data) {
    return DreamRow(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
      date: data.date.present ? data.date.value : this.date,
      created: data.created.present ? data.created.value : this.created,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DreamRow(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('date: $date, ')
          ..write('created: $created')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload, date, created);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DreamRow &&
          other.id == this.id &&
          other.payload == this.payload &&
          other.date == this.date &&
          other.created == this.created);
}

class DreamRowsCompanion extends UpdateCompanion<DreamRow> {
  final Value<String> id;
  final Value<String> payload;
  final Value<String> date;
  final Value<DateTime> created;
  final Value<int> rowid;
  const DreamRowsCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.date = const Value.absent(),
    this.created = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DreamRowsCompanion.insert({
    required String id,
    required String payload,
    required String date,
    required DateTime created,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload),
       date = Value(date),
       created = Value(created);
  static Insertable<DreamRow> custom({
    Expression<String>? id,
    Expression<String>? payload,
    Expression<String>? date,
    Expression<DateTime>? created,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (date != null) 'date': date,
      if (created != null) 'created': created,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DreamRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? payload,
    Value<String>? date,
    Value<DateTime>? created,
    Value<int>? rowid,
  }) {
    return DreamRowsCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      date: date ?? this.date,
      created: created ?? this.created,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DreamRowsCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('date: $date, ')
          ..write('created: $created, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ElementRowsTable extends ElementRows
    with TableInfo<$ElementRowsTable, ElementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ElementRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedMeta = const VerificationMeta(
    'normalized',
  );
  @override
  late final GeneratedColumn<String> normalized = GeneratedColumn<String>(
    'normalized',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, normalized, kind];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'element_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ElementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized')) {
      context.handle(
        _normalizedMeta,
        normalized.isAcceptableOrUnknown(data['normalized']!, _normalizedMeta),
      );
    } else if (isInserting) {
      context.missing(_normalizedMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {normalized, kind},
  ];
  @override
  ElementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ElementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalized: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
    );
  }

  @override
  $ElementRowsTable createAlias(String alias) {
    return $ElementRowsTable(attachedDatabase, alias);
  }
}

class ElementRow extends DataClass implements Insertable<ElementRow> {
  final String id;
  final String name;
  final String normalized;
  final String kind;
  const ElementRow({
    required this.id,
    required this.name,
    required this.normalized,
    required this.kind,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['normalized'] = Variable<String>(normalized);
    map['kind'] = Variable<String>(kind);
    return map;
  }

  ElementRowsCompanion toCompanion(bool nullToAbsent) {
    return ElementRowsCompanion(
      id: Value(id),
      name: Value(name),
      normalized: Value(normalized),
      kind: Value(kind),
    );
  }

  factory ElementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ElementRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      normalized: serializer.fromJson<String>(json['normalized']),
      kind: serializer.fromJson<String>(json['kind']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'normalized': serializer.toJson<String>(normalized),
      'kind': serializer.toJson<String>(kind),
    };
  }

  ElementRow copyWith({
    String? id,
    String? name,
    String? normalized,
    String? kind,
  }) => ElementRow(
    id: id ?? this.id,
    name: name ?? this.name,
    normalized: normalized ?? this.normalized,
    kind: kind ?? this.kind,
  );
  ElementRow copyWithCompanion(ElementRowsCompanion data) {
    return ElementRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      normalized: data.normalized.present
          ? data.normalized.value
          : this.normalized,
      kind: data.kind.present ? data.kind.value : this.kind,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ElementRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalized: $normalized, ')
          ..write('kind: $kind')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, normalized, kind);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ElementRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.normalized == this.normalized &&
          other.kind == this.kind);
}

class ElementRowsCompanion extends UpdateCompanion<ElementRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> normalized;
  final Value<String> kind;
  final Value<int> rowid;
  const ElementRowsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.normalized = const Value.absent(),
    this.kind = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ElementRowsCompanion.insert({
    required String id,
    required String name,
    required String normalized,
    required String kind,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       normalized = Value(normalized),
       kind = Value(kind);
  static Insertable<ElementRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? normalized,
    Expression<String>? kind,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (normalized != null) 'normalized': normalized,
      if (kind != null) 'kind': kind,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ElementRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? normalized,
    Value<String>? kind,
    Value<int>? rowid,
  }) {
    return ElementRowsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      normalized: normalized ?? this.normalized,
      kind: kind ?? this.kind,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalized.present) {
      map['normalized'] = Variable<String>(normalized.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ElementRowsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('normalized: $normalized, ')
          ..write('kind: $kind, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DreamLinksTable extends DreamLinks
    with TableInfo<$DreamLinksTable, DreamLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DreamLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dreamIdMeta = const VerificationMeta(
    'dreamId',
  );
  @override
  late final GeneratedColumn<String> dreamId = GeneratedColumn<String>(
    'dream_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dream_rows (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _elementIdMeta = const VerificationMeta(
    'elementId',
  );
  @override
  late final GeneratedColumn<String> elementId = GeneratedColumn<String>(
    'element_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES element_rows (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [dreamId, elementId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dream_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<DreamLink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dream_id')) {
      context.handle(
        _dreamIdMeta,
        dreamId.isAcceptableOrUnknown(data['dream_id']!, _dreamIdMeta),
      );
    } else if (isInserting) {
      context.missing(_dreamIdMeta);
    }
    if (data.containsKey('element_id')) {
      context.handle(
        _elementIdMeta,
        elementId.isAcceptableOrUnknown(data['element_id']!, _elementIdMeta),
      );
    } else if (isInserting) {
      context.missing(_elementIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dreamId, elementId};
  @override
  DreamLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DreamLink(
      dreamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dream_id'],
      )!,
      elementId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}element_id'],
      )!,
    );
  }

  @override
  $DreamLinksTable createAlias(String alias) {
    return $DreamLinksTable(attachedDatabase, alias);
  }
}

class DreamLink extends DataClass implements Insertable<DreamLink> {
  final String dreamId;
  final String elementId;
  const DreamLink({required this.dreamId, required this.elementId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dream_id'] = Variable<String>(dreamId);
    map['element_id'] = Variable<String>(elementId);
    return map;
  }

  DreamLinksCompanion toCompanion(bool nullToAbsent) {
    return DreamLinksCompanion(
      dreamId: Value(dreamId),
      elementId: Value(elementId),
    );
  }

  factory DreamLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DreamLink(
      dreamId: serializer.fromJson<String>(json['dreamId']),
      elementId: serializer.fromJson<String>(json['elementId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dreamId': serializer.toJson<String>(dreamId),
      'elementId': serializer.toJson<String>(elementId),
    };
  }

  DreamLink copyWith({String? dreamId, String? elementId}) => DreamLink(
    dreamId: dreamId ?? this.dreamId,
    elementId: elementId ?? this.elementId,
  );
  DreamLink copyWithCompanion(DreamLinksCompanion data) {
    return DreamLink(
      dreamId: data.dreamId.present ? data.dreamId.value : this.dreamId,
      elementId: data.elementId.present ? data.elementId.value : this.elementId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DreamLink(')
          ..write('dreamId: $dreamId, ')
          ..write('elementId: $elementId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dreamId, elementId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DreamLink &&
          other.dreamId == this.dreamId &&
          other.elementId == this.elementId);
}

class DreamLinksCompanion extends UpdateCompanion<DreamLink> {
  final Value<String> dreamId;
  final Value<String> elementId;
  final Value<int> rowid;
  const DreamLinksCompanion({
    this.dreamId = const Value.absent(),
    this.elementId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DreamLinksCompanion.insert({
    required String dreamId,
    required String elementId,
    this.rowid = const Value.absent(),
  }) : dreamId = Value(dreamId),
       elementId = Value(elementId);
  static Insertable<DreamLink> custom({
    Expression<String>? dreamId,
    Expression<String>? elementId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dreamId != null) 'dream_id': dreamId,
      if (elementId != null) 'element_id': elementId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DreamLinksCompanion copyWith({
    Value<String>? dreamId,
    Value<String>? elementId,
    Value<int>? rowid,
  }) {
    return DreamLinksCompanion(
      dreamId: dreamId ?? this.dreamId,
      elementId: elementId ?? this.elementId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dreamId.present) {
      map['dream_id'] = Variable<String>(dreamId.value);
    }
    if (elementId.present) {
      map['element_id'] = Variable<String>(elementId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DreamLinksCompanion(')
          ..write('dreamId: $dreamId, ')
          ..write('elementId: $elementId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTable extends Preferences
    with TableInfo<$PreferencesTable, Preference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Preference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Preference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Preference(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class Preference extends DataClass implements Insertable<Preference> {
  final String key;
  final String value;
  const Preference({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(key: Value(key), value: Value(value));
  }

  factory Preference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Preference(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Preference copyWith({String? key, String? value}) =>
      Preference(key: key ?? this.key, value: value ?? this.value);
  Preference copyWithCompanion(PreferencesCompanion data) {
    return Preference(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Preference(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Preference &&
          other.key == this.key &&
          other.value == this.value);
}

class PreferencesCompanion extends UpdateCompanion<Preference> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PreferencesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PreferencesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Preference> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PreferencesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PreferencesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DreamRowsTable dreamRows = $DreamRowsTable(this);
  late final $ElementRowsTable elementRows = $ElementRowsTable(this);
  late final $DreamLinksTable dreamLinks = $DreamLinksTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    dreamRows,
    elementRows,
    dreamLinks,
    preferences,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dream_rows',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('dream_links', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'element_rows',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('dream_links', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DreamRowsTableCreateCompanionBuilder =
    DreamRowsCompanion Function({
      required String id,
      required String payload,
      required String date,
      required DateTime created,
      Value<int> rowid,
    });
typedef $$DreamRowsTableUpdateCompanionBuilder =
    DreamRowsCompanion Function({
      Value<String> id,
      Value<String> payload,
      Value<String> date,
      Value<DateTime> created,
      Value<int> rowid,
    });

final class $$DreamRowsTableReferences
    extends BaseReferences<_$AppDatabase, $DreamRowsTable, DreamRow> {
  $$DreamRowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DreamLinksTable, List<DreamLink>>
  _dreamLinksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dreamLinks,
    aliasName: 'dream_rows__id__dream_links__dream_id',
  );

  $$DreamLinksTableProcessedTableManager get dreamLinksRefs {
    final manager = $$DreamLinksTableTableManager(
      $_db,
      $_db.dreamLinks,
    ).filter((f) => f.dreamId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_dreamLinksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DreamRowsTableFilterComposer
    extends Composer<_$AppDatabase, $DreamRowsTable> {
  $$DreamRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> dreamLinksRefs(
    Expression<bool> Function($$DreamLinksTableFilterComposer f) f,
  ) {
    final $$DreamLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dreamLinks,
      getReferencedColumn: (t) => t.dreamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamLinksTableFilterComposer(
            $db: $db,
            $table: $db.dreamLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DreamRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $DreamRowsTable> {
  $$DreamRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DreamRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DreamRowsTable> {
  $$DreamRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  Expression<T> dreamLinksRefs<T extends Object>(
    Expression<T> Function($$DreamLinksTableAnnotationComposer a) f,
  ) {
    final $$DreamLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dreamLinks,
      getReferencedColumn: (t) => t.dreamId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.dreamLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DreamRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DreamRowsTable,
          DreamRow,
          $$DreamRowsTableFilterComposer,
          $$DreamRowsTableOrderingComposer,
          $$DreamRowsTableAnnotationComposer,
          $$DreamRowsTableCreateCompanionBuilder,
          $$DreamRowsTableUpdateCompanionBuilder,
          (DreamRow, $$DreamRowsTableReferences),
          DreamRow,
          PrefetchHooks Function({bool dreamLinksRefs})
        > {
  $$DreamRowsTableTableManager(_$AppDatabase db, $DreamRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DreamRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DreamRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DreamRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<DateTime> created = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DreamRowsCompanion(
                id: id,
                payload: payload,
                date: date,
                created: created,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payload,
                required String date,
                required DateTime created,
                Value<int> rowid = const Value.absent(),
              }) => DreamRowsCompanion.insert(
                id: id,
                payload: payload,
                date: date,
                created: created,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DreamRowsTable, DreamRow>(table),
                  $$DreamRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dreamLinksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (dreamLinksRefs) db.dreamLinks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (dreamLinksRefs)
                    await $_getPrefetchedData<
                      DreamRow,
                      $DreamRowsTable,
                      DreamLink
                    >(
                      currentTable: table,
                      referencedTable: $$DreamRowsTableReferences
                          ._dreamLinksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DreamRowsTableReferences(
                            db,
                            table,
                            p0,
                          ).dreamLinksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.dreamId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DreamRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DreamRowsTable,
      DreamRow,
      $$DreamRowsTableFilterComposer,
      $$DreamRowsTableOrderingComposer,
      $$DreamRowsTableAnnotationComposer,
      $$DreamRowsTableCreateCompanionBuilder,
      $$DreamRowsTableUpdateCompanionBuilder,
      (DreamRow, $$DreamRowsTableReferences),
      DreamRow,
      PrefetchHooks Function({bool dreamLinksRefs})
    >;
typedef $$ElementRowsTableCreateCompanionBuilder =
    ElementRowsCompanion Function({
      required String id,
      required String name,
      required String normalized,
      required String kind,
      Value<int> rowid,
    });
typedef $$ElementRowsTableUpdateCompanionBuilder =
    ElementRowsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> normalized,
      Value<String> kind,
      Value<int> rowid,
    });

final class $$ElementRowsTableReferences
    extends BaseReferences<_$AppDatabase, $ElementRowsTable, ElementRow> {
  $$ElementRowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DreamLinksTable, List<DreamLink>>
  _dreamLinksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.dreamLinks,
    aliasName: 'element_rows__id__dream_links__element_id',
  );

  $$DreamLinksTableProcessedTableManager get dreamLinksRefs {
    final manager = $$DreamLinksTableTableManager(
      $_db,
      $_db.dreamLinks,
    ).filter((f) => f.elementId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_dreamLinksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ElementRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ElementRowsTable> {
  $$ElementRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalized => $composableBuilder(
    column: $table.normalized,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> dreamLinksRefs(
    Expression<bool> Function($$DreamLinksTableFilterComposer f) f,
  ) {
    final $$DreamLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dreamLinks,
      getReferencedColumn: (t) => t.elementId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamLinksTableFilterComposer(
            $db: $db,
            $table: $db.dreamLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ElementRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ElementRowsTable> {
  $$ElementRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalized => $composableBuilder(
    column: $table.normalized,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ElementRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ElementRowsTable> {
  $$ElementRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalized => $composableBuilder(
    column: $table.normalized,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  Expression<T> dreamLinksRefs<T extends Object>(
    Expression<T> Function($$DreamLinksTableAnnotationComposer a) f,
  ) {
    final $$DreamLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dreamLinks,
      getReferencedColumn: (t) => t.elementId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.dreamLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ElementRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ElementRowsTable,
          ElementRow,
          $$ElementRowsTableFilterComposer,
          $$ElementRowsTableOrderingComposer,
          $$ElementRowsTableAnnotationComposer,
          $$ElementRowsTableCreateCompanionBuilder,
          $$ElementRowsTableUpdateCompanionBuilder,
          (ElementRow, $$ElementRowsTableReferences),
          ElementRow,
          PrefetchHooks Function({bool dreamLinksRefs})
        > {
  $$ElementRowsTableTableManager(_$AppDatabase db, $ElementRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ElementRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ElementRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ElementRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalized = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ElementRowsCompanion(
                id: id,
                name: name,
                normalized: normalized,
                kind: kind,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String normalized,
                required String kind,
                Value<int> rowid = const Value.absent(),
              }) => ElementRowsCompanion.insert(
                id: id,
                name: name,
                normalized: normalized,
                kind: kind,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ElementRowsTable, ElementRow>(table),
                  $$ElementRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dreamLinksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (dreamLinksRefs) db.dreamLinks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (dreamLinksRefs)
                    await $_getPrefetchedData<
                      ElementRow,
                      $ElementRowsTable,
                      DreamLink
                    >(
                      currentTable: table,
                      referencedTable: $$ElementRowsTableReferences
                          ._dreamLinksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ElementRowsTableReferences(
                            db,
                            table,
                            p0,
                          ).dreamLinksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.elementId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ElementRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ElementRowsTable,
      ElementRow,
      $$ElementRowsTableFilterComposer,
      $$ElementRowsTableOrderingComposer,
      $$ElementRowsTableAnnotationComposer,
      $$ElementRowsTableCreateCompanionBuilder,
      $$ElementRowsTableUpdateCompanionBuilder,
      (ElementRow, $$ElementRowsTableReferences),
      ElementRow,
      PrefetchHooks Function({bool dreamLinksRefs})
    >;
typedef $$DreamLinksTableCreateCompanionBuilder =
    DreamLinksCompanion Function({
      required String dreamId,
      required String elementId,
      Value<int> rowid,
    });
typedef $$DreamLinksTableUpdateCompanionBuilder =
    DreamLinksCompanion Function({
      Value<String> dreamId,
      Value<String> elementId,
      Value<int> rowid,
    });

final class $$DreamLinksTableReferences
    extends BaseReferences<_$AppDatabase, $DreamLinksTable, DreamLink> {
  $$DreamLinksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DreamRowsTable _dreamIdTable(_$AppDatabase db) =>
      db.dreamRows.createAlias('dream_links__dream_id__dream_rows__id');

  $$DreamRowsTableProcessedTableManager get dreamId {
    final $_column = $_itemColumn<String>('dream_id')!;

    final manager = $$DreamRowsTableTableManager(
      $_db,
      $_db.dreamRows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dreamIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ElementRowsTable _elementIdTable(_$AppDatabase db) =>
      db.elementRows.createAlias('dream_links__element_id__element_rows__id');

  $$ElementRowsTableProcessedTableManager get elementId {
    final $_column = $_itemColumn<String>('element_id')!;

    final manager = $$ElementRowsTableTableManager(
      $_db,
      $_db.elementRows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_elementIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DreamLinksTableFilterComposer
    extends Composer<_$AppDatabase, $DreamLinksTable> {
  $$DreamLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$DreamRowsTableFilterComposer get dreamId {
    final $$DreamRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dreamId,
      referencedTable: $db.dreamRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamRowsTableFilterComposer(
            $db: $db,
            $table: $db.dreamRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ElementRowsTableFilterComposer get elementId {
    final $$ElementRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.elementId,
      referencedTable: $db.elementRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ElementRowsTableFilterComposer(
            $db: $db,
            $table: $db.elementRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DreamLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $DreamLinksTable> {
  $$DreamLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$DreamRowsTableOrderingComposer get dreamId {
    final $$DreamRowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dreamId,
      referencedTable: $db.dreamRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamRowsTableOrderingComposer(
            $db: $db,
            $table: $db.dreamRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ElementRowsTableOrderingComposer get elementId {
    final $$ElementRowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.elementId,
      referencedTable: $db.elementRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ElementRowsTableOrderingComposer(
            $db: $db,
            $table: $db.elementRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DreamLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DreamLinksTable> {
  $$DreamLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$DreamRowsTableAnnotationComposer get dreamId {
    final $$DreamRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dreamId,
      referencedTable: $db.dreamRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DreamRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.dreamRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ElementRowsTableAnnotationComposer get elementId {
    final $$ElementRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.elementId,
      referencedTable: $db.elementRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ElementRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.elementRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DreamLinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DreamLinksTable,
          DreamLink,
          $$DreamLinksTableFilterComposer,
          $$DreamLinksTableOrderingComposer,
          $$DreamLinksTableAnnotationComposer,
          $$DreamLinksTableCreateCompanionBuilder,
          $$DreamLinksTableUpdateCompanionBuilder,
          (DreamLink, $$DreamLinksTableReferences),
          DreamLink,
          PrefetchHooks Function({bool dreamId, bool elementId})
        > {
  $$DreamLinksTableTableManager(_$AppDatabase db, $DreamLinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DreamLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DreamLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DreamLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> dreamId = const Value.absent(),
                Value<String> elementId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DreamLinksCompanion(
                dreamId: dreamId,
                elementId: elementId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String dreamId,
                required String elementId,
                Value<int> rowid = const Value.absent(),
              }) => DreamLinksCompanion.insert(
                dreamId: dreamId,
                elementId: elementId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DreamLinksTable, DreamLink>(table),
                  $$DreamLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dreamId = false, elementId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (dreamId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dreamId,
                                referencedTable: $$DreamLinksTableReferences
                                    ._dreamIdTable(db),
                                referencedColumn: $$DreamLinksTableReferences
                                    ._dreamIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (elementId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.elementId,
                                referencedTable: $$DreamLinksTableReferences
                                    ._elementIdTable(db),
                                referencedColumn: $$DreamLinksTableReferences
                                    ._elementIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DreamLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DreamLinksTable,
      DreamLink,
      $$DreamLinksTableFilterComposer,
      $$DreamLinksTableOrderingComposer,
      $$DreamLinksTableAnnotationComposer,
      $$DreamLinksTableCreateCompanionBuilder,
      $$DreamLinksTableUpdateCompanionBuilder,
      (DreamLink, $$DreamLinksTableReferences),
      DreamLink,
      PrefetchHooks Function({bool dreamId, bool elementId})
    >;
typedef $$PreferencesTableCreateCompanionBuilder =
    PreferencesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$PreferencesTableUpdateCompanionBuilder =
    PreferencesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$PreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PreferencesTable,
          Preference,
          $$PreferencesTableFilterComposer,
          $$PreferencesTableOrderingComposer,
          $$PreferencesTableAnnotationComposer,
          $$PreferencesTableCreateCompanionBuilder,
          $$PreferencesTableUpdateCompanionBuilder,
          (
            Preference,
            BaseReferences<_$AppDatabase, $PreferencesTable, Preference>,
          ),
          Preference,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableManager(_$AppDatabase db, $PreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PreferencesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PreferencesTable, Preference>(table),
                  BaseReferences<_$AppDatabase, $PreferencesTable, Preference>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PreferencesTable,
      Preference,
      $$PreferencesTableFilterComposer,
      $$PreferencesTableOrderingComposer,
      $$PreferencesTableAnnotationComposer,
      $$PreferencesTableCreateCompanionBuilder,
      $$PreferencesTableUpdateCompanionBuilder,
      (
        Preference,
        BaseReferences<_$AppDatabase, $PreferencesTable, Preference>,
      ),
      Preference,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DreamRowsTableTableManager get dreamRows =>
      $$DreamRowsTableTableManager(_db, _db.dreamRows);
  $$ElementRowsTableTableManager get elementRows =>
      $$ElementRowsTableTableManager(_db, _db.elementRows);
  $$DreamLinksTableTableManager get dreamLinks =>
      $$DreamLinksTableTableManager(_db, _db.dreamLinks);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
}
