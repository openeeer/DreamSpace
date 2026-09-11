import '../../models/dream.dart';

class Connection {
  const Connection(this.a, this.b, this.reasons, this.weight);
  final String a, b;
  final List<String> reasons;
  final double weight;
}

List<Connection> connections(
  List<Dream> dreams, {
  Set<ElementKind>? kinds,
  bool mood = true,
}) {
  final result = <Connection>[];
  for (var i = 0; i < dreams.length; i++) {
    for (var j = i + 1; j < dreams.length; j++) {
      final a = dreams[i], b = dreams[j];
      final common = a.elements
          .where(
            (e) =>
                (kinds == null || kinds.contains(e.kind)) &&
                b.elements.any((other) => other.id == e.id),
          )
          .toList();
      final sameMood = mood && a.mood != null && a.mood == b.mood;
      if (common.isEmpty && !sameMood) continue;
      result.add(
        Connection(
          a.id,
          b.id,
          [...common.map((e) => e.name), if (sameMood) 'mood:${a.mood!.name}'],
          common.fold<double>(
                0,
                (w, e) => w + (e.kind == ElementKind.symbol ? 3 : 2),
              ) +
              (sameMood ? .5 : 0),
        ),
      );
    }
  }
  result.sort((a, b) => b.weight.compareTo(a.weight));
  return result;
}

class DreamStats {
  DreamStats(this.dreams, {DateTime? now}) : now = now ?? DateTime.now();
  final List<Dream> dreams;
  final DateTime now;
  int get lucid => dreams.where((d) => d.type == DreamType.lucid).length;
  int get month => dreams
      .where((d) => d.date.year == now.year && d.date.month == now.month)
      .length;
  Map<Mood, int> get moods {
    final result = <Mood, int>{};
    for (final d in dreams) {
      if (d.mood != null) {
        result.update(d.mood!, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    return result;
  }

  Map<DreamTheme, int> get themes {
    final result = <DreamTheme, int>{};
    for (final d in dreams) {
      if (d.theme != null) {
        result.update(d.theme!, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    return result;
  }

  List<MapEntry<DreamElement, int>> elements(ElementKind kind) {
    final counts = <String, int>{};
    final values = <String, DreamElement>{};
    for (final d in dreams) {
      for (final e in d.ofKind(kind)) {
        values[e.id] = e;
        counts.update(e.id, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    return counts.entries.map((e) => MapEntry(values[e.key]!, e.value)).toList()
      ..sort((a, b) {
        final order = b.value.compareTo(a.value);
        return order != 0 ? order : a.key.name.compareTo(b.key.name);
      });
  }

  int get recurringSymbols =>
      elements(ElementKind.symbol).where((e) => e.value >= 2).length;
  List<DateTime> get _days =>
      dreams
          .map((d) => DateTime.utc(d.date.year, d.date.month, d.date.day))
          .toSet()
          .toList()
        ..sort();
  int get longest {
    final days = _days;
    var longest = 0, current = 0;
    for (var i = 0; i < days.length; i++) {
      current = i > 0 && days[i].difference(days[i - 1]).inDays == 1
          ? current + 1
          : 1;
      if (current > longest) longest = current;
    }
    return longest;
  }

  int get streak {
    final days = _days;
    if (days.isEmpty) return 0;
    final today = DateTime.utc(now.year, now.month, now.day);
    final valid = days.where((d) => !d.isAfter(today)).toList();
    if (valid.isEmpty || today.difference(valid.last).inDays > 1) return 0;
    var result = 1;
    for (
      var i = valid.length - 1;
      i > 0 && valid[i].difference(valid[i - 1]).inDays == 1;
      i--
    ) {
      result++;
    }
    return result;
  }
}
