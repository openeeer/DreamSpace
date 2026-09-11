import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/design.dart';
import '../../data/providers.dart';
import '../../models/dream.dart';

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, this.id, this.date});
  final String? id, date;
  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen>
    with WidgetsBindingObserver {
  final title = TextEditingController(), body = TextEditingController();
  final entityControllers = {
    for (final k in ElementKind.values) k: TextEditingController(),
  };
  Dream? original;
  late String id;
  DateTime date = DateTime.now();
  Mood? mood;
  DreamType type = DreamType.normal;
  DreamTheme? theme;
  bool recurring = false,
      busy = false,
      loading = true,
      details = false,
      saved = false,
      restored = false;
  int? lucidity, vividness;
  String artwork = artworkIds.first;
  List<DreamElement> elements = [], suggestions = [];
  String? error;
  Timer? debounce;
  Future<void> pending = Future.value();
  @override
  void initState() {
    super.initState();
    id = const Uuid().v4();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(repositoryProvider);
      final all = await repo.all();
      final draft = await repo.draft();
      if (widget.id != null) {
        original = all.where((d) => d.id == widget.id).firstOrNull;
      }
      final value = widget.id == null
          ? draft
          : (draft?.id == widget.id ? draft : original);
      suggestions = await repo.elements();
      if (!mounted) return;
      if (value != null) {
        id = value.id;
        title.text = value.title;
        body.text = value.description;
        date = value.date;
        mood = value.mood;
        type = value.type;
        theme = value.theme;
        recurring = value.recurring;
        lucidity = value.lucidity;
        vividness = value.vividness;
        artwork = value.artwork;
        elements = [...value.elements];
        restored = value == draft;
      } else if (widget.date != null) {
        date = DateTime.parse(widget.date!);
      }
      title.addListener(_changed);
      body.addListener(_changed);
      setState(() => loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'load';
        });
      }
    }
  }

  Dream _value({bool finalSave = false}) {
    final en = ref.read(englishProvider), now = DateTime.now().toUtc();
    return Dream(
      id: id,
      title: title.text.trim().isEmpty && finalSave
          ? tr(
              en,
              'Сон — ${formatDate(date, en)}',
              'Dream — ${formatDate(date, en)}',
            )
          : title.text.trim(),
      description: body.text.trim(),
      date: date,
      createdAt: original?.createdAt ?? now,
      updatedAt: now,
      mood: mood,
      type: type,
      theme: theme,
      recurring: recurring,
      lucidity: lucidity,
      vividness: vividness,
      elements: [...elements],
      artwork: artwork,
      favorite: original?.favorite ?? false,
      demo: original?.demo ?? false,
    );
  }

  void _changed() {
    if (loading || saved) return;
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 450), _persistDraft);
  }

  Future<void> _persistDraft() {
    if (saved || loading || body.text.trim().isEmpty) return pending;
    final value = _value(), repo = ref.read(repositoryProvider);
    pending = pending.then((_) => repo.saveDraft(value)).catchError((Object e) {
      if (mounted) setState(() => error = 'draft');
    });
    return pending;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _persistDraft();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    debounce?.cancel();
    title.dispose();
    body.dispose();
    for (final c in entityControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void change(VoidCallback callback) {
    setState(callback);
    _changed();
  }

  Future<void> _save() async {
    if (body.text.trim().isEmpty) {
      setState(() => error = 'empty');
      return;
    }
    FocusScope.of(context).unfocus();
    debounce?.cancel();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await pending;
      await ref.read(repositoryProvider).save(_value(finalSave: true));
      if (mounted) setState(() => saved = true);
      await ref.read(repositoryProvider).clearDraft();
      if (!mounted) return;
      if (ref.read(settingsProvider)['haptics'] != 'false') {
        HapticFeedback.mediumImpact();
      }
      final en = ref.read(englishProvider);
      final completion = Completer<void>();
      final overlay = OverlayEntry(
        builder: (context) => _SavedMoment(
          en: en,
          artwork: artwork,
          onComplete: () {
            if (!completion.isCompleted) completion.complete();
          },
        ),
      );
      Overlay.of(context, rootOverlay: true).insert(overlay);
      await completion.future;
      overlay.remove();
      overlay.dispose();
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'save';
        });
      }
    }
  }

  Future<void> close() async {
    debounce?.cancel();
    await _persistDraft();
    if (mounted) {
      setState(() => saved = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final en = ref.watch(englishProvider);
    if (loading) {
      return const Scaffold(body: Center(child: CupertinoActivityIndicator()));
    }
    return PopScope(
      canPop: saved,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !busy) close();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: tr(
                        en,
                        'Закрыть, сохранив черновик',
                        'Close and keep draft',
                      ),
                      onPressed: busy ? null : close,
                      icon: const Icon(CupertinoIcons.xmark),
                    ),
                    Expanded(
                      child: Text(
                        widget.id == null
                            ? tr(en, 'Новый сон', 'New Dream')
                            : tr(en, 'Редактировать', 'Edit Dream'),
                        textAlign: TextAlign.center,
                        style: display(24),
                      ),
                    ),
                    IconButton(
                      tooltip: tr(en, 'Удалить черновик', 'Discard draft'),
                      icon: const Icon(CupertinoIcons.trash, size: 20),
                      onPressed: busy
                          ? null
                          : () async {
                              if (!await confirm(
                                context,
                                en,
                                tr(en, 'Удалить черновик?', 'Discard draft?'),
                                tr(
                                  en,
                                  'Несохранённый текст будет удалён.',
                                  'Unsaved text will be removed.',
                                ),
                              )) {
                                return;
                              }
                              debounce?.cancel();
                              await pending;
                              saved = true;
                              await ref.read(repositoryProvider).clearDraft();
                              if (context.mounted) context.pop();
                            },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                  children: [
                    if (restored)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Text(
                          tr(en, 'Черновик восстановлен', 'Draft restored'),
                          style: const TextStyle(
                            color: Palette.mint,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    Text(
                      tr(
                        en,
                        'Что тебе приснилось?',
                        'What did you dream about?',
                      ),
                      style: display(32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tr(
                        en,
                        'Начни с любого образа. Остальное вспомнится.',
                        'Start with a single image. The rest will follow.',
                      ),
                      style: const TextStyle(
                        color: Palette.secondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: body,
                      minLines: 7,
                      maxLines: null,
                      autofocus: widget.id == null && !restored,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 17, height: 1.65),
                      decoration: InputDecoration(
                        hintText: tr(en, 'Я помню…', 'I remember…'),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () async {
                        final selected = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (selected != null) change(() => date = selected);
                      },
                      icon: const Icon(CupertinoIcons.calendar, size: 18),
                      label: Text(formatDate(date, en)),
                    ),
                    const SizedBox(height: 16),
                    SectionTitle(
                      tr(en, 'Как ты себя чувствовал?', 'How did it feel?'),
                    ),
                    SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final m in Mood.values)
                            MoodOrb(
                              m,
                              en: en,
                              selected: mood == m,
                              onTap: () {
                                if (ref.read(settingsProvider)['haptics'] !=
                                    'false') {
                                  HapticFeedback.selectionClick();
                                }
                                change(() => mood = mood == m ? null : m);
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    DreamSurface(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(
                          tr(en, 'Детали сновидения', 'Dream details'),
                        ),
                        subtitle: Text(
                          tr(
                            en,
                            'Символы, места, яркость и обложка',
                            'Symbols, places, vividness and cover',
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Icon(
                          details
                              ? CupertinoIcons.chevron_up
                              : CupertinoIcons.chevron_down,
                        ),
                        onTap: () => setState(() => details = !details),
                      ),
                    ),
                    if (details) ...[
                      const SizedBox(height: 22),
                      TextField(
                        controller: title,
                        decoration: InputDecoration(
                          labelText: tr(
                            en,
                            'Название (необязательно)',
                            'Title (optional)',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SectionTitle(tr(en, 'Тип сна', 'Dream type')),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in DreamType.values)
                            DreamChip(
                              t.label(en),
                              selected: type == t,
                              onTap: () => change(() => type = t),
                            ),
                        ],
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          tr(en, 'Повторяющийся сон', 'Recurring dream'),
                        ),
                        value: recurring,
                        onChanged: (v) => change(() => recurring = v),
                      ),
                      _intensity(
                        tr(en, 'Осознанность', 'Lucidity'),
                        lucidity,
                        (v) => change(() => lucidity = v),
                        en,
                      ),
                      _intensity(
                        tr(en, 'Яркость', 'Vividness'),
                        vividness,
                        (v) => change(() => vividness = v),
                        en,
                      ),
                      const SizedBox(height: 20),
                      SectionTitle(tr(en, 'Тема', 'Theme')),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in DreamTheme.values)
                            DreamChip(
                              t.label(en),
                              selected: theme == t,
                              onTap: () =>
                                  change(() => theme = theme == t ? null : t),
                            ),
                        ],
                      ),
                      for (final kind in ElementKind.values) ...[
                        const SizedBox(height: 26),
                        SectionTitle(switch (kind) {
                          ElementKind.symbol => tr(en, 'Символы', 'Symbols'),
                          ElementKind.character => tr(
                            en,
                            'Персонажи',
                            'Characters',
                          ),
                          ElementKind.place => tr(en, 'Места', 'Places'),
                        }),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final e in elements.where(
                              (e) => e.kind == kind,
                            ))
                              DreamChip(
                                '${e.name} ×',
                                selected: true,
                                onTap: () => change(() => elements.remove(e)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: entityControllers[kind],
                                onSubmitted: (value) => addElement(value, kind),
                                decoration: InputDecoration(
                                  hintText: tr(
                                    en,
                                    'Добавить свой вариант',
                                    'Add your own',
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => addElement(
                                entityControllers[kind]!.text,
                                kind,
                              ),
                              icon: const Icon(CupertinoIcons.add_circled),
                              tooltip: tr(en, 'Добавить', 'Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final e
                                in suggestions
                                    .where(
                                      (e) =>
                                          e.kind == kind &&
                                          !elements.any((a) => a.id == e.id),
                                    )
                                    .take(8))
                              DreamChip(
                                e.name,
                                onTap: () => change(() => elements.add(e)),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 28),
                      SectionTitle(tr(en, 'Обложка сна', 'Dream cover')),
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final a in artworkIds)
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Semantics(
                                  button: true,
                                  selected: artwork == a,
                                  label: a.replaceAll('_', ' '),
                                  child: GestureDetector(
                                    onTap: () => change(() => artwork = a),
                                    child: Container(
                                      width: 100,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: artwork == a
                                              ? Palette.lavender
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: DreamArtwork(a, radius: 18),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Text(
                          error == 'empty'
                              ? tr(
                                  en,
                                  'Добавь хотя бы несколько слов о сне.',
                                  'Write a few words about your dream.',
                                )
                              : tr(
                                  en,
                                  'Не удалось сохранить. Текст остался здесь — попробуй ещё раз.',
                                  'Could not save. Your text is still here — please retry.',
                                ),
                          style: const TextStyle(color: Color(0xfff29ba9)),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: DreamButton(
                  label: tr(en, 'Сохранить сон', 'Save Dream'),
                  icon: CupertinoIcons.sparkles,
                  busy: busy,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void addElement(String text, ElementKind kind) {
    if (normalize(text).isEmpty) return;
    if (!elements.any(
      (e) => e.kind == kind && normalize(e.name) == normalize(text),
    )) {
      final existing = suggestions
          .where((e) => e.kind == kind && normalize(e.name) == normalize(text))
          .firstOrNull;
      change(
        () => elements.add(
          existing ?? ref.read(repositoryProvider).newElement(text, kind),
        ),
      );
    }
    entityControllers[kind]!.clear();
  }

  Widget _intensity(
    String label,
    int? value,
    ValueChanged<int?> onChanged,
    bool en,
  ) => Column(
    children: [
      Row(
        children: [
          Expanded(child: Text(label)),
          Text(value == null ? tr(en, 'Не указано', 'Not set') : '$value%'),
          if (value != null)
            IconButton(
              onPressed: () => onChanged(null),
              icon: const Icon(CupertinoIcons.xmark, size: 14),
              tooltip: tr(en, 'Сбросить', 'Reset'),
            ),
        ],
      ),
      Slider(
        value: (value ?? 0).toDouble(),
        max: 100,
        divisions: 20,
        label: '${value ?? 0}%',
        onChanged: (v) => onChanged(v.round()),
      ),
    ],
  );
}

class _SavedMoment extends StatefulWidget {
  const _SavedMoment({
    required this.en,
    required this.artwork,
    required this.onComplete,
  });
  final VoidCallback onComplete;
  final bool en;
  final String artwork;
  @override
  State<_SavedMoment> createState() => _SavedMomentState();
}

class _SavedMomentState extends State<_SavedMoment> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
    timer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Palette.night.withValues(alpha: .92),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(
              begin: MediaQuery.disableAnimationsOf(context) ? 1 : .75,
              end: 1,
            ),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Palette.lavender.withValues(alpha: .5),
                    blurRadius: 60,
                  ),
                ],
              ),
              child: ClipOval(child: DreamArtwork(widget.artwork)),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            tr(
              widget.en,
              'Ещё одна звезда в твоей вселенной',
              'A new star in your universe',
            ),
            textAlign: TextAlign.center,
            style: display(26).copyWith(color: Palette.text),
          ),
        ],
      ),
    ),
  );
}
