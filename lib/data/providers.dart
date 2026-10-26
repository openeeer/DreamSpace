import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../models/dream.dart';
import 'repository.dart';

final repositoryProvider = Provider<DreamRepository>(
  (ref) => throw UnimplementedError('Override at bootstrap'),
);
final dreamsProvider = StreamProvider<List<Dream>>(
  (ref) => ref.watch(repositoryProvider).watchDreams(),
);
final settingsProvider =
    NotifierProvider<SettingsController, Map<String, String>>(
      SettingsController.new,
    );

class SettingsController extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => {};
  void load(Map<String, String> values) => state = values;
  Future<void> set(String key, String value) async {
    await ref.read(repositoryProvider).setSetting(key, value);
    state = {...state, key: value};
  }
}

final englishProvider = Provider<bool>(
  (ref) => ref.watch(settingsProvider)['language'] == 'en',
);

/// Character profiles the dreamer has filled in. Watched by the screens that
/// list, edit, and match characters.
final charactersProvider = StreamProvider<List<DreamCharacter>>(
  (ref) => ref.watch(repositoryProvider).watchCharacters(),
);

/// Unresolved match suggestions for one dream, smallest friction first.
final characterMatchesProvider = StreamProvider.family
    .autoDispose<List<CharacterMatch>, String>((ref, dreamId) {
  final repo = ref.watch(repositoryProvider);
  return repo
      .watchMatches()
      .map((all) => all.where((m) => m.dreamId == dreamId).toList());
});
