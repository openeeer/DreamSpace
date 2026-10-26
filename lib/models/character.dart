/// Who the dreamer meets in their dreams. `DreamElement` of kind `character`
/// stays the link key; this profile carries the human-added depth the server
/// never fills on its own.
class DreamCharacter {
  const DreamCharacter({
    required this.id,
    required this.name,
    this.relation,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });
  final String id, name;

  /// Free-form, dreamer's own words: "мама", "одноклассник", "сущность из
  /// повторяющегося сна". Not an enum on purpose — people name relationships
  /// in their own language.
  final String? relation;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DreamCharacter copyWith({String? name, String? relation, String? notes}) =>
      DreamCharacter(
        id: id,
        name: name ?? this.name,
        relation: relation ?? this.relation,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: DateTime.now().toUtc(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'relation': relation,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
  factory DreamCharacter.fromJson(Map<String, dynamic> j) => DreamCharacter(
    id: j['id'] as String,
    name: j['name'] as String,
    relation: j['relation'] as String?,
    notes: j['notes'] as String?,
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: j['updatedAt'] == null
        ? null
        : DateTime.parse(j['updatedAt'] as String),
  );
}

/// A suggested match between a character the assistant detected in a new
/// dream and an existing profile. The dreamer confirms or rejects in one tap;
/// rejected matches never auto-apply.
class CharacterMatch {
  const CharacterMatch({
    required this.dreamId,
    required this.candidateId,
    required this.candidateName,
    this.confidence = 1,
    this.resolved,
  });
  final String dreamId, candidateId, candidateName;
  final double confidence;
  final bool? resolved;
  CharacterMatch copyWith({bool? resolved}) => CharacterMatch(
    dreamId: dreamId,
    candidateId: candidateId,
    candidateName: candidateName,
    confidence: confidence,
    resolved: resolved ?? this.resolved,
  );
  Map<String, dynamic> toJson() => {
    'dreamId': dreamId,
    'candidateId': candidateId,
    'candidateName': candidateName,
    'confidence': confidence,
    'resolved': resolved,
  };
  factory CharacterMatch.fromJson(Map<String, dynamic> j) => CharacterMatch(
    dreamId: j['dreamId'] as String,
    candidateId: j['candidateId'] as String,
    candidateName: j['candidateName'] as String,
    confidence: (j['confidence'] as num?)?.toDouble() ?? 1,
    resolved: j['resolved'] as bool?,
  );
}

/// Frequency and timeline of one character across the journal, derived from
/// dream links — no separate storage, computed on demand.
class CharacterStats {
  const CharacterStats({
    required this.appearances,
    required this.firstSeen,
    required this.lastSeen,
    required this.togetherWith,
  });
  final int appearances;
  final DateTime firstSeen, lastSeen;

  /// Characters that share dreams with this one, most frequent first.
  final List<(DreamCharacter, int)> togetherWith;
}
