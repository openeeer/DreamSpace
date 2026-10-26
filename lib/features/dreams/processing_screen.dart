import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../core/internal_page.dart';
import '../../data/providers.dart';
import '../../data/processing.dart';
import '../../models/character.dart';
import '../../models/dream.dart';

/// Live view of one dream going through the server pipeline. The dream is
/// already saved as text; this screen shows what the assistant is doing and
/// lets the dreamer set lucidity mid-flight — their pick outranks the AI's.
class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key, required this.dreamId});
  final String dreamId;
  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  StreamSubscription<ProcessingJob>? sub;
  ProcessingJob? job;
  int? userLucidity;
  bool saving = false;
  bool navigated = false;

  @override
  void initState() {
    super.initState();
    final dream = ref.read(dreamsProvider).value?.where(
          (d) => d.id == widget.dreamId,
        ).firstOrNull;
    if (dream != null) {
      sub = ref.read(processingServiceProvider).process(dream).listen((next) {
        if (mounted) setState(() => job = next);
      });
    }
    // Resume jobs that were queued offline when connectivity/settings allow.
    _retryQueued();
  }

  /// Auto-advance to the finished dream once, then let the person browse.
  void _maybeAutoAdvance(Dream dream) {
    if (navigated || dream.pendingProcessing) return;
    navigated = true;
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (mounted && context.mounted) {
        context.go('/dream/${dream.id}');
      }
    });
  }

  Future<void> _retryQueued() async {
    final service = ref.read(processingServiceProvider);
    if (!service.enabled) return;
    final dreams = await ref.read(repositoryProvider).all();
    for (final dream
        in dreams.where((d) => d.status == ProcessingStatus.queued)) {
      service.process(dream);
    }
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  Future<void> _setLucidity(int value) async {
    final dream = ref.read(dreamsProvider).value?.where(
          (d) => d.id == widget.dreamId,
        ).firstOrNull;
    if (dream == null) return;
    if (ref.read(settingsProvider)['haptics'] != 'false') {
      HapticFeedback.selectionClick();
    }
    setState(() => userLucidity = value);
    await ref
        .read(repositoryProvider)
        .save(dream.copyWith(lucidity: value, aiSuggested: false));
  }

  @override
  Widget build(BuildContext context) {
    final en = ref.watch(englishProvider);
    final dreams = ref.watch(dreamsProvider).value ?? const <Dream>[];
    final dream = dreams.where((d) => d.id == widget.dreamId).firstOrNull;
    if (dream == null) {
      return DreamInternalPage(
        title: tr(en, 'Сон не найден', 'Dream not found'),
        children: [EmptyDreams(en: en, notFound: true)],
      );
    }
    final finished = !dream.pendingProcessing;
    final matches = ref.watch(characterMatchesProvider(dream.id)).value ?? [];
    // Wait for pending match confirmations before auto-advancing: the cards
    // are the whole point of this screen, leaving early would hide them.
    final unresolved = matches.where((m) => m.resolved == null).length;
    if (finished && unresolved == 0 && job?.failure == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeAutoAdvance(dream);
      });
    }
    return DreamInternalPage(
      title: tr(en, 'Сон обрабатывается', 'Processing dream'),
      compact: true,
      children: [
        _StagesCard(job: job, finished: finished, en: en),
        const SizedBox(height: Rhythm.section),
        if (!finished) ...[
          _LucidityNow(
            value: userLucidity ?? dream.lucidity,
            onChanged: _setLucidity,
            en: en,
          ),
          const SizedBox(height: Rhythm.section),
        ],
        DreamGlassSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr(en, 'Что уже видно', 'What is ready so far'), style: display(20)),
              const SizedBox(height: Rhythm.m),
              _FieldRow(
                label: tr(en, 'Настроение', 'Mood'),
                value: dream.mood?.label(en),
              ),
              _FieldRow(
                label: tr(en, 'Тема', 'Theme'),
                value: dream.theme?.label(en),
              ),
              _FieldRow(
                label: tr(en, 'Осознанность', 'Lucidity'),
                value: (userLucidity ?? dream.lucidity)?.toString(),
                userSet: userLucidity != null,
              ),
              _FieldRow(
                label: tr(en, 'Яркость', 'Vividness'),
                value: dream.vividness?.toString(),
              ),
            ],
          ),
        ),
        if (matches.isNotEmpty) ...[
          const SizedBox(height: Rhythm.section),
          Text(tr(en, 'Кто тебе снился?', 'Who appeared?'), style: display(20)),
          const SizedBox(height: Rhythm.m),
          for (final match in matches.where((m) => m.resolved == null))
            _MatchCard(
              match: match,
              onResolve: (accepted) async {
                if (ref.read(settingsProvider)['haptics'] != 'false') {
                  HapticFeedback.selectionClick();
                }
                final created = await ref.read(repositoryProvider).resolveMatch(
                  match,
                  accepted,
                );
                if (!context.mounted) return;
                if (created != null) {
                  // Rejected match: the new profile opens for the dreamer
                  // to say who this person actually is.
                  context.push('/characters/${created.id}');
                }
              },
            ),
        ],
        const SizedBox(height: Rhythm.section),
        DreamButton(
          label: finished
              ? tr(en, 'Открыть сон', 'Open dream')
              : tr(en, 'Пока идёт обработка — к дневнику', 'To journal while it works'),
          onPressed: finished
              ? () => context.go('/dream/${dream.id}')
              : () => context.go('/journal'),
        ),
      ],
    );
  }
}

class _StagesCard extends StatelessWidget {
  const _StagesCard({required this.job, required this.finished, required this.en});
  final ProcessingJob? job;
  final bool finished, en;
  @override
  Widget build(BuildContext context) {
    final stages = ProcessingStage.values;
    final activeIndex = job == null ? -1 : stages.indexOf(job!.stage);
    final failed = job?.failure == 'offline';
    return DreamGlassSurface(
      child: Column(
        children: [
          for (var i = 0; i < stages.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == stages.length - 1 ? 0 : Rhythm.m),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: finished || (job != null && i < activeIndex)
                        ? Icon(
                            CupertinoIcons.check_mark,
                            size: 20,
                            color: Palette.mint,
                            semanticLabel: tr(en, 'Готово', 'Done'),
                          )
                        : job != null && i == activeIndex
                        ? failed
                            ? Icon(
                                CupertinoIcons.wifi_exclamationmark,
                                size: 20,
                                color: Palette.gold,
                                semanticLabel: tr(en, 'Нет сети', 'Offline'),
                              )
                            : const CupertinoActivityIndicator()
                        : Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Palette.lavender.withValues(alpha: .3),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: Rhythm.m),
                  Expanded(
                    child: Text(
                      stages[i].label(en),
                      style: TextStyle(
                        fontSize: 15,
                        color: finished || (job != null && i <= activeIndex)
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (job != null && i == activeIndex && !failed)
                    Text('${(job!.progress * 100).round()}%'),
                ],
              ),
            ),
          if (failed)
            Padding(
              padding: const EdgeInsets.only(top: Rhythm.s),
              child: Text(
                tr(
                  en,
                  'Сон сохранён. Обработка продолжится, когда появится сеть.',
                  'Dream saved. Processing resumes when you are back online.',
                ),
                style: TextStyle(fontSize: 12, color: InternalStyle.muted(context)),
              ),
            ),
        ],
      ),
    );
  }
}

class _LucidityNow extends StatelessWidget {
  const _LucidityNow({required this.value, required this.onChanged, required this.en});
  final int? value;
  final ValueChanged<int> onChanged;
  final bool en;
  @override
  Widget build(BuildContext context) => DreamGlassSurface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(en, 'Осознанность', 'Lucidity'), style: display(20)),
        const SizedBox(height: Rhythm.s),
        Text(
          tr(
            en,
            'Твой выбор главнее — установи, пока идёт обработка',
            'Your pick wins — set it while processing runs',
          ),
          style: TextStyle(
            fontSize: 13,
            color: InternalStyle.muted(context),
          ),
        ),
        const SizedBox(height: Rhythm.m),
        Row(
          children: [
            for (var i = 0; i <= 4; i++)
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onPressed: () => onChanged(i * 25),
                  child: _LucidityTick(
                    active: (value ?? -1) >= i * 25,
                    label: '${i * 25}',
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _LucidityTick extends StatelessWidget {
  const _LucidityTick({required this.active, required this.label});
  final bool active;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        height: 6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: active ? Palette.lavender : Palette.raised,
        ),
      ),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.value, this.userSet = false});
  final String label;
  final String? value;
  final bool userSet;
  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Rhythm.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
          if (value == null)
            SizedBox(
              width: 70,
              height: 14,
              child: DreamGlassSurface(
                padding: EdgeInsets.zero,
                radius: 7,
                child: const SizedBox.expand(),
              ),
            )
          else ...[
            Text(value!, style: display(16)),
            const SizedBox(width: Rhythm.s),
            Icon(
              userSet
                  ? CupertinoIcons.person_fill
                  : CupertinoIcons.sparkles,
              size: 13,
              color: userSet ? Palette.gold : Palette.lavender,
              semanticLabel: userSet
                  ? tr(en, 'Выбрано тобой', 'Set by you')
                  : tr(en, 'Предложено ассистентом', 'Suggested by assistant'),
            ),
          ],
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.onResolve});
  final CharacterMatch match;
  final ValueChanged<bool> onResolve;
  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    return Padding(
      padding: const EdgeInsets.only(bottom: Rhythm.m),
      child: DreamGlassSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const DreamIconBubble(CupertinoIcons.person_crop_circle),
                const SizedBox(width: Rhythm.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(en, 'Снова ${match.candidateName}?', '${match.candidateName} again?'),
                        style: display(17),
                      ),
                      Text(
                        tr(
                          en,
                          'Ассистент узнал этого персонажа',
                          'The assistant recognized this character',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: InternalStyle.muted(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Rhythm.m),
            Row(
              children: [
                Expanded(
                  child: DreamGlassAction(
                    label: tr(en, 'Новый персонаж', 'New character'),
                    onPressed: () => onResolve(false),
                  ),
                ),
                const SizedBox(width: Rhythm.m),
                Expanded(
                  child: DreamGlassAction(
                    label: tr(en, 'Да, это он', 'Yes, it is them'),
                    prominent: true,
                    onPressed: () => onResolve(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}