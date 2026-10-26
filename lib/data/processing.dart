import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/character.dart';
import '../models/dream.dart';
import 'providers.dart';
import 'repository.dart';

/// Stages the server pipeline will report. The mock advances through them
/// on a timer; the real service will push the same states from the network.
enum ProcessingStage {
  transcribe('Расшифровка', 'Transcribing'),
  analyze('Разбор смысла', 'Analyzing'),
  characters('Персонажи', 'Characters'),
  artwork('Обложка', 'Cover');

  const ProcessingStage(this.ru, this.en);
  final String ru, en;
  String label(bool english) => english ? en : ru;
}

/// A single processing job exposed to the UI as a stream of stage updates.
class ProcessingJob {
  const ProcessingJob({
    required this.dreamId,
    required this.stage,
    required this.progress,
    this.failure,
  });
  final String dreamId;
  final ProcessingStage stage;
  /// 0..1 within the current stage.
  final double progress;
  final String? failure;
}

/// Local stand-in for the future server endpoint. Simulates transcription →
/// analysis → character matching → cover generation, then applies the result
/// with the dreamer-first merge policy. The network layer replaces this class
/// alone; everything downstream stays untouched.
class MockProcessingService {
  MockProcessingService(this._ref);
  final Ref _ref;
  final _jobs = <String, StreamController<ProcessingJob>>{};

  bool get enabled {
    // Privacy switch: off by default. When off, dictated dreams are simply
    // saved as text and never "leave the device".
    return _ref.read(settingsProvider)['serverProcessing'] == 'true';
  }

  Stream<ProcessingJob> process(Dream dream) {
    final existing = _jobs[dream.id];
    if (existing != null) return existing.stream;
    final controller = StreamController<ProcessingJob>.broadcast();
    _jobs[dream.id] = controller;
    _run(dream, controller);
    return controller.stream;
  }

  Future<void> _run(Dream dream, StreamController<ProcessingJob> controller) async {
    const durations = [2200, 2600, 2000, 1600]; // per stage, ms
    try {
      final offline = _ref.read(settingsProvider)['serverProcessing'] != 'true';
      for (var i = 0; i < ProcessingStage.values.length; i++) {
        final stage = ProcessingStage.values[i];
        if (offline && i > 0) {
          // First stage (transcription) is already on-device mock; the rest
          // would need the network. Fail into queued state instead.
          controller.add(
            ProcessingJob(
              dreamId: dream.id,
              stage: ProcessingStage.transcribe,
              progress: 1,
              failure: 'offline',
            ),
          );
          await _ref.read(repositoryProvider).setDreamStatus(
            dream.id,
            ProcessingStatus.queued,
          );
          return;
        }
        final duration = durations[i];
        const steps = 8;
        for (var s = 0; s <= steps; s++) {
          await Future<void>.delayed(Duration(milliseconds: duration ~/ steps));
          controller.add(
            ProcessingJob(
              dreamId: dream.id,
              stage: stage,
              progress: s / steps,
            ),
          );
        }
        // The dreamer may edit during processing: re-read before each apply.
        if (i == 0) {
          final repo = _ref.read(repositoryProvider);
          final fresh = (await repo.all())
              .where((d) => d.id == dream.id)
              .firstOrNull;
          if (fresh != null && fresh.description != dream.description) {
            dream = fresh;
          }
        }
      }
      // Compose the mock result.
      final repo = _ref.read(repositoryProvider);
      final result = await _compose(dream);
      await repo.applyProcessing(dream, result);
      await repo.setDreamStatus(dream.id, ProcessingStatus.done);
      controller.add(
        ProcessingJob(
          dreamId: dream.id,
          stage: ProcessingStage.artwork,
          progress: 1,
        ),
      );
    } catch (e) {
      await _ref
          .read(repositoryProvider)
          .setDreamStatus(dream.id, ProcessingStatus.failed);
      controller.add(
        ProcessingJob(
          dreamId: dream.id,
          stage: ProcessingStage.transcribe,
          progress: 0,
          failure: '$e',
        ),
      );
    } finally {
      await controller.close();
      _jobs.remove(dream.id);
    }
  }

  /// Builds a deterministic, plausible result from the dream text: mood and
  /// theme from keyword heuristics, characters matched against existing
  /// profiles, a cover picked by stable hash.
  Future<ProcessingResult> _compose(Dream dream) async {
    final en = _ref.read(englishProvider);
    final repo = _ref.read(repositoryProvider);
    final text = normalize('${dream.title} ${dream.description}');
    final characters = (await repo.characters())
        .where((c) => text.contains(normalize(c.name)))
        .toList();
    final existingElements = await repo.elements();
    final knownCharacterNames = {
      for (final e in existingElements.where((e) => e.kind == ElementKind.character))
        normalize(e.name),
    };

    // A "new" character: a capitalized word not yet known to the journal.
    final newNames = RegExp(r'\b[А-ЯЁA-Z][а-яёa-zё]{2,}\b')
        .allMatches(dream.description)
        .map((m) => m.group(0)!)
        .map(normalize)
        .where(
          (n) => !knownCharacterNames.contains(n) &&
              text.contains(n) &&
              n.length > 3,
        )
        .take(2)
        .toList();

    final matches = [
      for (final c in characters)
        CharacterMatch(
          dreamId: dream.id,
          candidateId: c.id,
          candidateName: c.name,
          confidence: .9,
        ),
    ];

    final mood = _guessMood(text);
    final theme = _guessTheme(text);
    final hash = dream.id.hashCode;
    final artwork = artworkIds[hash.abs() % artworkIds.length];

    return ProcessingResult(
      mood: mood,
      // Dream type is a judgment call the dreamer makes; the assistant
      // suggesting "nightmare" would quietly re-label their experience.
      type: null,
      theme: theme,
      lucidity: null, // dreamer-first: never AI-assigned
      vividness: 40 + (hash.abs() % 60),
      artwork: artwork,
      elements: [
        for (final n in newNames)
          DreamElement(
            id: 'ai-${dream.id}-${n.hashCode.abs()}',
            name: n[0].toUpperCase() + n.substring(1),
            kind: ElementKind.character,
          ),
        DreamElement(
          id: 'ai-${dream.id}-star',
          name: en ? 'Stars' : 'Звёзды',
          kind: ElementKind.symbol,
        ),
      ],
      matches: matches,
    );
  }

  Mood? _guessMood(String text) {
    const keywords = <Mood, List<String>>{
      Mood.anxious: ['бег', 'погон', 'опозда', 'тревог', 'chase', 'anxious'],
      Mood.scary: ['страх', 'кошмар', 'темнот', 'scary', 'dark'],
      Mood.peaceful: ['тих', 'спокой', 'мир', 'peace', 'calm'],
      Mood.happy: ['радост', 'счаст', 'лет', 'happy', 'joy'],
      Mood.strange: ['странн', 'необычн', 'surreal', 'strange'],
      Mood.mysterious: ['тайн', 'секрет', 'mystery', 'secret'],
    };
    for (final entry in keywords.entries) {
      for (final k in entry.value) {
        if (text.contains(k)) return entry.key;
      }
    }
    return null;
  }

  DreamTheme? _guessTheme(String text) {
    const keywords = <DreamTheme, List<String>>{
      DreamTheme.nature: ['лес', 'море', 'океан', 'дерев', 'forest', 'ocean'],
      DreamTheme.adventure: ['пут', 'дорог', 'поезд', 'journey', 'train'],
      DreamTheme.everyday: ['дом', 'работ', 'школ', 'home', 'work'],
      DreamTheme.surreal: ['летал', 'парил', 'flying', 'floating'],
      DreamTheme.relationships: ['мам', 'друг', 'сестр', 'муж', 'friend'],
    };
    for (final entry in keywords.entries) {
      for (final k in entry.value) {
        if (text.contains(k)) return entry.key;
      }
    }
    return null;
  }
}

final processingServiceProvider = Provider<MockProcessingService>((ref) {
  final service = MockProcessingService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

extension on MockProcessingService {
  void dispose() {}
}

/// Character co-appearance: which characters share dreams, how often.
/// Computed from links — no extra storage, grows with the journal.
Map<(String, String), int> characterCoAppearance(List<Dream> dreams) {
  final counts = <(String, String), int>{};
  for (final dream in dreams) {
    final names = [
      for (final e in dream.ofKind(ElementKind.character)) e.id,
    ]..sort();
    for (var i = 0; i < names.length; i++) {
      for (var j = i + 1; j < names.length; j++) {
        final key = (names[i], names[j]);
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }
  }
  return counts;
}