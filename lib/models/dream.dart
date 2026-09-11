enum Mood {
  calm('Спокойствие', 'Calm'),
  happy('Радость', 'Joyful'),
  sad('Грусть', 'Sad'),
  scary('Страх', 'Scary'),
  strange('Странность', 'Strange'),
  romantic('Нежность', 'Romantic'),
  mysterious('Тайна', 'Mystery'),
  anxious('Тревога', 'Anxious'),
  peaceful('Гармония', 'Peaceful');

  const Mood(this.ru, this.en);
  final String ru, en;
  String label(bool english) => english ? en : ru;
}

enum DreamType {
  normal('Обычный', 'Normal'),
  nightmare('Кошмар', 'Nightmare'),
  lucid('Осознанный', 'Lucid'),
  falseAwakening('Ложное пробуждение', 'False awakening');

  const DreamType(this.ru, this.en);
  final String ru, en;
  String label(bool english) => english ? en : ru;
}

enum DreamTheme {
  fantasy('Фэнтези', 'Fantasy'),
  nature('Природа', 'Nature'),
  adventure('Приключения', 'Adventure'),
  everyday('Повседневность', 'Everyday'),
  relationships('Отношения', 'Relationships'),
  surreal('Сюрреализм', 'Surreal');

  const DreamTheme(this.ru, this.en);
  final String ru, en;
  String label(bool english) => english ? en : ru;
}

enum ElementKind { symbol, character, place }

class DreamElement {
  const DreamElement({
    required this.id,
    required this.name,
    required this.kind,
  });
  final String id, name;
  final ElementKind kind;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'kind': kind.name};
}

class Dream {
  const Dream({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.mood,
    this.type = DreamType.normal,
    this.recurring = false,
    this.lucidity,
    this.vividness,
    this.theme,
    this.elements = const [],
    this.favorite = false,
    this.artwork = 'moon_library',
    this.demo = false,
  });
  final String id, title, description, artwork;
  final DateTime date, createdAt, updatedAt;
  final Mood? mood;
  final DreamType type;
  final bool recurring, favorite, demo;
  final int? lucidity, vividness;
  final DreamTheme? theme;
  final List<DreamElement> elements;
  List<DreamElement> ofKind(ElementKind kind) =>
      elements.where((e) => e.kind == kind).toList();
  Dream copyWith({bool? favorite, List<DreamElement>? elements}) => Dream(
    id: id,
    title: title,
    description: description,
    date: date,
    createdAt: createdAt,
    updatedAt: DateTime.now().toUtc(),
    mood: mood,
    type: type,
    recurring: recurring,
    lucidity: lucidity,
    vividness: vividness,
    theme: theme,
    elements: elements ?? this.elements,
    favorite: favorite ?? this.favorite,
    artwork: artwork,
    demo: demo,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'date': dateKey(date),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'mood': mood?.name,
    'type': type.name,
    'recurring': recurring,
    'lucidity': lucidity,
    'vividness': vividness,
    'theme': theme?.name,
    'elements': elements.map((e) => e.toJson()).toList(),
    'favorite': favorite,
    'artwork': artwork,
    'demo': demo,
  };
  factory Dream.fromJson(Map<String, dynamic> j) => Dream(
    id: j['id'] as String,
    title: j['title'] as String,
    description: j['description'] as String,
    date: DateTime.parse(j['date'] as String),
    createdAt: DateTime.parse(j['createdAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
    mood: j['mood'] == null ? null : Mood.values.byName(j['mood'] as String),
    type: DreamType.values.byName(j['type'] as String),
    recurring: j['recurring'] as bool? ?? false,
    lucidity: j['lucidity'] as int?,
    vividness: j['vividness'] as int?,
    theme: j['theme'] == null
        ? null
        : DreamTheme.values.byName(j['theme'] as String),
    favorite: j['favorite'] as bool? ?? false,
    artwork: j['artwork'] as String,
    demo: j['demo'] as bool? ?? false,
    elements: (j['elements'] as List)
        .map(
          (e) => DreamElement(
            id: e['id'] as String,
            name: e['name'] as String,
            kind: ElementKind.values.byName(e['kind'] as String),
          ),
        )
        .toList(),
  );
}

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
String normalize(String text) =>
    text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
const artworkIds = [
  'moon_library',
  'ocean_without_end',
  'red_forest',
  'empty_city',
  'glass_staircase',
  'last_train',
  'sky_islands',
  'door_under_water',
];
