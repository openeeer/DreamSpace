import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../data/providers.dart';
import '../../models/dream.dart';
import '../dreams/journal_components.dart';
import '../insights/analytics.dart';
import 'map_screen.dart' show layoutGraph;

bool matchesUniverse(Dream dream, String query, bool en) => normalize(
  '${dreamTitle(dream, en)} ${dream.description} ${dream.elements.map((e) => e.name).join(' ')}',
).contains(normalize(query));

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.focus});
  final String? focus;
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  final camera = TransformationController();
  final search = TextEditingController();
  late final AnimationController flight;
  Animation<Matrix4>? path;
  Timer? searchTimer, saveTimer;
  Map<String, Offset> positions = {};
  Matrix4? restoredCamera;
  Size viewport = Size.zero, savedViewport = Size.zero;
  Matrix4 home = Matrix4.identity();
  String query = '';
  String? selected;
  bool fitted = false, strong = false, showReset = false;
  bool restorePending = true;
  bool emotions = true;
  Set<ElementKind> kinds = ElementKind.values.toSet();
  double normalScale = 1, textScale = 1;
  bool get reduced =>
      MediaQuery.disableAnimationsOf(context) ||
      ref.read(settingsProvider)['animations'] == 'reduced';

  @override
  void initState() {
    super.initState();
    selected = widget.focus;
    flight =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 480),
        )..addListener(() {
          if (path != null) camera.value = path!.value;
        });
    camera.addListener(cameraChanged);
    final raw = ref.read(settingsProvider)['universe.v1'];
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        positions = (data['positions'] as Map<String, dynamic>).map(
          (id, p) => MapEntry(
            id,
            Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()),
          ),
        );
        positions.removeWhere((_, p) => !p.dx.isFinite || !p.dy.isFinite);
        final values = (data['camera'] as List)
            .map((v) => (v as num).toDouble())
            .toList();
        if (values.length == 16 && values.every((v) => v.isFinite)) {
          restoredCamera = Matrix4.fromList(values);
        }
        savedViewport = Size(
          (data['width'] as num).toDouble(),
          (data['height'] as num).toDouble(),
        );
      } catch (_) {
        positions = {};
        restoredCamera = null;
      }
    }
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focus != widget.focus) {
      selected = widget.focus;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && selected != null) focusNode(selected!);
      });
    }
  }

  @override
  void dispose() {
    searchTimer?.cancel();
    saveTimer?.cancel();
    flight.dispose();
    camera.dispose();
    search.dispose();
    super.dispose();
  }

  void haptic() {
    if (ref.read(settingsProvider)['haptics'] != 'false') {
      HapticFeedback.selectionClick();
    }
  }

  void cameraChanged() {
    final changed =
        (camera.value.getMaxScaleOnAxis() / normalScale - 1).abs() > .025;
    if (mounted && changed != showReset) setState(() => showReset = changed);
    saveTimer?.cancel();
    saveTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || viewport.isEmpty) return;
      final value = jsonEncode({
        'positions': positions.map((id, p) => MapEntry(id, [p.dx, p.dy])),
        'camera': camera.value.storage.toList(),
        'width': viewport.width,
        'height': viewport.height,
      });
      unawaited(
        ref
            .read(settingsProvider.notifier)
            .set('universe.v1', value)
            .catchError((Object error) {
              debugPrint('Map state persistence: $error');
            }),
      );
    });
  }

  Matrix4 transform(Offset point, double scale, {double y = .48}) =>
      Matrix4.identity()
        ..translateByDouble(
          viewport.width / 2 - point.dx * scale,
          viewport.height * y - point.dy * scale,
          0,
          1,
        )
        ..scaleByDouble(scale, scale, scale, 1);

  void fly(Matrix4 target, {bool immediate = false}) {
    flight.stop();
    if (immediate || reduced) {
      camera.value = target;
      return;
    }
    path = Matrix4Tween(
      begin: camera.value.clone(),
      end: target,
    ).animate(CurvedAnimation(parent: flight, curve: Curves.easeOutCubic));
    flight.forward(from: 0);
  }

  void fit({bool initial = false}) {
    if (positions.isEmpty || viewport.isEmpty) return;
    final xs = positions.values.map((p) => p.dx),
        ys = positions.values.map((p) => p.dy);
    final bounds = Rect.fromLTRB(
      xs.reduce(math.min) - 80,
      ys.reduce(math.min) - 60,
      xs.reduce(math.max) + 80,
      ys.reduce(math.max) + 110 * textScale,
    );
    normalScale = math
        .min(viewport.width / bounds.width, viewport.height / bounds.height)
        .clamp(.08, 1.1);
    home = transform(bounds.center, normalScale, y: .5);
    Matrix4 target = home;
    if (initial &&
        restoredCamera != null &&
        (savedViewport.width - viewport.width).abs() < 2 &&
        (savedViewport.height - viewport.height).abs() < 2 &&
        restoredCamera!.getMaxScaleOnAxis() >= normalScale * .75 &&
        restoredCamera!.getMaxScaleOnAxis() <= 2.8) {
      target = restoredCamera!;
    }
    restoredCamera = null;
    fly(target, immediate: initial);
    if (mounted) setState(() {});
    if (initial && selected != null && restorePending) focusNode(selected!);
    restorePending = false;
  }

  void focusNode(String id) {
    final p = positions[id];
    if (p == null || viewport.isEmpty) return;
    fly(transform(p, math.max(normalScale, .8).clamp(.1, 1.3), y: .35));
  }

  void select(String id) {
    haptic();
    FocusScope.of(context).unfocus();
    setState(() => selected = id);
    focusNode(id);
  }

  Future<void> menu(bool en) async {
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(tr(en, 'Вселенная снов', 'Dream universe')),
        actions: [
          for (final (id, label) in [
            ('all', tr(en, 'Показать все связи', 'Show all connections')),
            (
              'strong',
              tr(en, 'Только сильные связи', 'Strong connections only'),
            ),
            (
              'position',
              tr(en, 'Сбросить положение карты', 'Reset map position'),
            ),
            ('zoom', tr(en, 'Сбросить масштаб', 'Reset zoom')),
            ('help', tr(en, 'Объяснение карты', 'About the map')),
          ])
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx, id),
              child: Text(label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(tr(en, 'Отмена', 'Cancel')),
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'all':
        setState(() {
          strong = false;
          emotions = true;
          kinds = ElementKind.values.toSet();
        });
      case 'strong':
        setState(() => strong = true);
      case 'position':
        haptic();
        fly(home.clone());
      case 'zoom':
        haptic();
        fly(
          transform(
            camera.toScene(Offset(viewport.width / 2, viewport.height / 2)),
            normalScale,
            y: .5,
          ),
        );
      case 'help':
        await showCupertinoDialog<void>(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Text(tr(en, 'Твоё созвездие', 'Your constellation')),
            content: Text(
              tr(
                en,
                'Каждый круг — один сон. Линии соединяют общие символы, людей, места и эмоции. Сильная связь — минимум два совпадения. Ищи по названию или образам, двигай карту одним пальцем и меняй масштаб двумя. Двойное нажатие на фон возвращает всю карту.',
                'Each circle is a dream. Lines connect shared symbols, people, places and moods. Strong connections share at least two matches. Search titles or elements, drag to pan and pinch to zoom. Double-tap the background to fit the map.',
              ),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr(en, 'Понятно', 'Got it')),
              ),
            ],
          ),
        );
    }
  }

  Future<void> nodeMenu(Dream dream, bool en) async {
    haptic();
    final action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(dreamTitle(dream, en)),
        actions: [
          for (final (id, label) in [
            ('open', tr(en, 'Открыть сон', 'Open dream')),
            (
              'favorite',
              dream.favorite
                  ? tr(en, 'Убрать из избранного', 'Remove from favorites')
                  : tr(en, 'В избранное', 'Add to favorites'),
            ),
            ('connections', tr(en, 'Показать связи', 'Show connections')),
          ])
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(ctx, id),
              child: Text(label),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(tr(en, 'Отмена', 'Cancel')),
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'open':
        context.push('/dream/${dream.id}');
      case 'connections':
        select(dream.id);
      case 'favorite':
        await ref
            .read(repositoryProvider)
            .save(dream.copyWith(favorite: !dream.favorite));
    }
  }

  @override
  Widget build(BuildContext context) => DreamsBuilder(
    builder: (all, en) {
      final unique = {for (final d in all) d.id: d};
      final dreams = unique.values.take(100).toList();
      final focus = unique[widget.focus];
      if (focus != null && !dreams.any((d) => d.id == focus.id)) {
        if (dreams.length == 100) dreams.removeLast();
        dreams.add(focus);
      }
      final allEdges = connections(dreams);
      final edges = connections(
        dreams,
        kinds: kinds,
        mood: emotions,
      ).where((e) => !strong || e.reasons.length >= 2).toList();
      final newTextScale = MediaQuery.textScalerOf(context).scale(12) / 12;
      if (positions.length != dreams.length ||
          dreams.any((d) => !positions.containsKey(d.id)) ||
          newTextScale != textScale) {
        positions = layoutGraph(
          dreams,
          allEdges,
          previous: newTextScale == textScale ? positions : {},
          nodeSpacing: 145 + math.max(0, newTextScale - 1) * 75,
        );
        textScale = newTextScale;
        fitted = false;
      }
      final matches = dreams
          .where((d) => matchesUniverse(d, query, en))
          .toList();
      final matched = matches.map((d) => d.id).toSet();
      final related = edges
          .where((e) => e.a == selected || e.b == selected)
          .toList();
      final highlighted = {
        selected,
        ...related.expand((e) => [e.a, e.b]),
      };
      final current = unique[selected];
      final degree = {for (final d in dreams) d.id: 0.0};
      for (final e in allEdges) {
        degree[e.a] = degree[e.a]! + e.weight;
        degree[e.b] = degree[e.b]! + e.weight;
      }
      final central = dreams.isEmpty
          ? null
          : (dreams.toList()
                  ..sort((a, b) => degree[b.id]!.compareTo(degree[a.id]!)))
                .first
                .id;
      final bottom = MediaQuery.viewPaddingOf(context).bottom + 114;
      return Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    22,
                    MediaQuery.paddingOf(context).top + 18,
                    14,
                    8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr(en, 'Вселенная снов', 'Dream Universe'),
                          style: display(30),
                        ),
                      ),
                      JournalIconButton(
                        label: tr(en, 'Меню карты', 'Map menu'),
                        icon: CupertinoIcons.line_horizontal_3,
                        onPressed: () => menu(en),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: JournalGlass(
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Icon(
                            CupertinoIcons.search,
                            size: 20,
                            color: Palette.secondary,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: search,
                            style: const TextStyle(fontSize: 14),
                            keyboardAppearance: Theme.of(context).brightness,
                            textInputAction: TextInputAction.search,
                            onTapOutside: (_) =>
                                FocusScope.of(context).unfocus(),
                            onSubmitted: (_) {
                              FocusScope.of(context).unfocus();
                              if (matches.isNotEmpty) select(matches.first.id);
                            },
                            onChanged: (value) {
                              setState(() {
                                query = value;
                                selected = null;
                              });
                              searchTimer?.cancel();
                              searchTimer = Timer(
                                const Duration(milliseconds: 280),
                                () {
                                  if (!mounted) return;
                                  final found = dreams.where(
                                    (d) => matchesUniverse(d, value, en),
                                  );
                                  if (value.trim().isEmpty) {
                                    fit();
                                  } else if (found.isNotEmpty) {
                                    focusNode(found.first.id);
                                  }
                                },
                              );
                            },
                            decoration: InputDecoration(
                              hintText: tr(
                                en,
                                'Найти сон во вселенной',
                                'Find a dream',
                              ),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        if (query.isNotEmpty)
                          JournalIconButton(
                            label: tr(en, 'Очистить поиск', 'Clear search'),
                            icon: CupertinoIcons.xmark_circle_fill,
                            onPressed: () {
                              searchTimer?.cancel();
                              search.clear();
                              setState(() {
                                query = '';
                                selected = null;
                              });
                              fit();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: math.max(
                    44,
                    MediaQuery.textScalerOf(context).scale(14) + 22,
                  ),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      for (final kind in ElementKind.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: JournalFilter(
                            label: switch (kind) {
                              ElementKind.symbol => tr(
                                en,
                                'Символы',
                                'Symbols',
                              ),
                              ElementKind.character => tr(en, 'Люди', 'People'),
                              ElementKind.place => tr(en, 'Места', 'Places'),
                            },
                            selected: kinds.contains(kind),
                            onTap: () => setState(
                              () => kinds.contains(kind)
                                  ? kinds.remove(kind)
                                  : kinds.add(kind),
                            ),
                          ),
                        ),
                      JournalFilter(
                        label: tr(en, 'Эмоции', 'Mood'),
                        selected: emotions,
                        onTap: () => setState(() => emotions = !emotions),
                      ),
                    ],
                  ),
                ),
                if (query.isNotEmpty)
                  SizedBox(
                    height: 40,
                    child: matches.isEmpty
                        ? Center(
                            child: Text(
                              tr(en, 'Совпадений нет', 'No matches'),
                              style: const TextStyle(fontSize: 12),
                            ),
                          )
                        : ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            children: [
                              for (final d in matches.take(3))
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  onPressed: () => select(d.id),
                                  child: Text(
                                    dreamTitle(d, en),
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                if (all.length > 100)
                  Text(
                    tr(en, 'Последние 100 снов', 'Latest 100 dreams'),
                    style: const TextStyle(fontSize: 11),
                  ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final reserve = math.min(bottom + 24, c.maxHeight * .3);
                      final next = Size(
                        c.maxWidth,
                        math.max(1, c.maxHeight - reserve),
                      );
                      if (next != viewport) {
                        viewport = next;
                        fitted = false;
                      }
                      if (!fitted && dreams.isNotEmpty) {
                        fitted = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) fit(initial: true);
                        });
                      }
                      return Stack(
                        children: [
                          if (dreams.isEmpty)
                            SingleChildScrollView(child: EmptyDreams(en: en))
                          else
                            Positioned.fill(
                              bottom: reserve,
                              child: InteractiveViewer(
                                transformationController: camera,
                                constrained: false,
                                minScale: math.max(.04, normalScale * .75),
                                maxScale: 2.8,
                                boundaryMargin: const EdgeInsets.all(4000),
                                onInteractionStart: (_) => flight.stop(),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => setState(() => selected = null),
                                  onDoubleTap: () {
                                    haptic();
                                    setState(() => selected = null);
                                    fit();
                                  },
                                  child: RepaintBoundary(
                                    child: SizedBox(
                                      width: math.max(
                                        1400,
                                        positions.values
                                                .map((p) => p.dx)
                                                .reduce(math.max) +
                                            160,
                                      ),
                                      height: math.max(
                                        1500,
                                        positions.values
                                                .map((p) => p.dy)
                                                .reduce(math.max) +
                                            180,
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: UniverseConnections(
                                                positions,
                                                edges,
                                                selected: selected,
                                                matched: query.isEmpty
                                                    ? null
                                                    : matched,
                                                central: central,
                                                textScale: textScale,
                                              ),
                                            ),
                                          ),
                                          for (final d in dreams)
                                            Positioned(
                                              left: positions[d.id]!.dx - 64,
                                              top: positions[d.id]!.dy - 36,
                                              child: Semantics(
                                                button: true,
                                                selected: selected == d.id,
                                                label:
                                                    '${dreamTitle(d, en)}, ${formatDate(d.date, en)}',
                                                child: GestureDetector(
                                                  onTap: () => select(d.id),
                                                  onLongPress: () =>
                                                      nodeMenu(d, en),
                                                  child: AnimatedOpacity(
                                                    duration: reduced
                                                        ? Duration.zero
                                                        : const Duration(
                                                            milliseconds: 180,
                                                          ),
                                                    opacity: query.isNotEmpty
                                                        ? (matched.contains(
                                                                d.id,
                                                              )
                                                              ? 1
                                                              : .23)
                                                        : selected == null ||
                                                              highlighted
                                                                  .contains(
                                                                    d.id,
                                                                  )
                                                        ? 1
                                                        : .3,
                                                    child: AnimatedScale(
                                                      scale: selected == d.id
                                                          ? 1.08
                                                          : 1,
                                                      duration: reduced
                                                          ? Duration.zero
                                                          : const Duration(
                                                              milliseconds: 180,
                                                            ),
                                                      child: SizedBox(
                                                        width: 128,
                                                        child: Column(
                                                          children: [
                                                            Container(
                                                              width:
                                                                  d.id ==
                                                                      central
                                                                  ? 78
                                                                  : 72,
                                                              height:
                                                                  d.id ==
                                                                      central
                                                                  ? 78
                                                                  : 72,
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                  color: Palette
                                                                      .lavender
                                                                      .withValues(
                                                                        alpha:
                                                                            selected ==
                                                                                d.id
                                                                            ? 1
                                                                            : .65,
                                                                      ),
                                                                ),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Palette
                                                                        .lavender
                                                                        .withValues(
                                                                          alpha:
                                                                              selected ==
                                                                                  d.id
                                                                              ? .3
                                                                              : .14,
                                                                        ),
                                                                    blurRadius:
                                                                        12,
                                                                  ),
                                                                ],
                                                              ),
                                                              child: ClipOval(
                                                                child:
                                                                    DreamArtwork(
                                                                      d.artwork,
                                                                      radius: 0,
                                                                    ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 7,
                                                            ),
                                                            Text(
                                                              dreamTitle(d, en),
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: const TextStyle(
                                                                fontSize: 13,
                                                                height: 1.15,
                                                                shadows: [
                                                                  Shadow(
                                                                    color: Color(
                                                                      0xff080c24,
                                                                    ),
                                                                    blurRadius:
                                                                        4,
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (showReset)
                            Positioned(
                              right: 20,
                              top: 8,
                              child: JournalGlass(
                                radius: 24,
                                child: JournalIconButton(
                                  key: const ValueKey('map-reset'),
                                  label: tr(en, 'Вся карта', 'Fit all'),
                                  icon: CupertinoIcons
                                      .arrow_up_left_arrow_down_right,
                                  onPressed: () {
                                    haptic();
                                    fit();
                                  },
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            Positioned(
              left: -30,
              right: -30,
              bottom: -30,
              height: 115,
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: .4,
                    child: Image.asset(
                      'assets/backgrounds/nebula_foreground.webp',
                      fit: BoxFit.cover,
                      cacheWidth: 1000,
                    ),
                  ),
                ),
              ),
            ),
            if (MediaQuery.viewInsetsOf(context).bottom == 0)
              Positioned(
                left: 22,
                right: 22,
                bottom: bottom,
                child: current == null
                    ? IgnorePointer(
                        child: Text(
                          tr(
                            en,
                            'Каждый сон — часть чего-то большего',
                            'Every dream is part of something bigger',
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Palette.secondary,
                          ),
                        ),
                      )
                    : JournalGlass(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      dreamTitle(current, en),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: display(20),
                                    ),
                                  ),
                                  JournalIconButton(
                                    label: tr(en, 'Закрыть', 'Close'),
                                    icon: CupertinoIcons.xmark,
                                    onPressed: () =>
                                        setState(() => selected = null),
                                  ),
                                ],
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${formatDate(current.date, en)} · ${current.type.label(en)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Palette.secondary,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      tr(
                                        en,
                                        'Связей: ${related.length}',
                                        'Connections: ${related.length}',
                                      ),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  CupertinoButton(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    onPressed: () =>
                                        context.push('/dream/${current.id}'),
                                    child: Text(
                                      tr(en, 'Открыть сон', 'Open dream'),
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
          ],
        ),
      );
    },
  );
}

class UniverseConnections extends CustomPainter {
  UniverseConnections(
    this.positions,
    this.edges, {
    this.selected,
    this.matched,
    this.central,
    this.textScale = 1,
  });
  final Map<String, Offset> positions;
  final List<Connection> edges;
  final String? selected, central;
  final Set<String>? matched;
  final double textScale;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    var visible = Path()..addRect(Offset.zero & size);
    // Keep every curve away from artwork and the full caption footprint.
    for (final entry in positions.entries) {
      final exclusions = Path()
        ..addOval(
          Rect.fromCircle(
            center: entry.value,
            radius: entry.key == central ? 43 : 39,
          ),
        )
        ..addRect(
          Rect.fromLTWH(
            entry.value.dx - 65,
            entry.value.dy + 38,
            130,
            12 + 32 * textScale,
          ),
        );
      visible = Path.combine(PathOperation.difference, visible, exclusions);
    }
    canvas.clipPath(visible);
    var stars = 0;
    for (final e in edges.take(150)) {
      final a = positions[e.a], b = positions[e.b];
      if (a == null || b == null || a == b) continue;
      final delta = b - a, unit = delta / delta.distance;
      final start = a + unit * (e.a == central ? 42 : 38);
      final end = b - unit * (e.b == central ? 42 : 38);
      final mid = (start + end) / 2 + Offset(-unit.dy, unit.dx) * 10;
      final active = selected != null
          ? e.a == selected || e.b == selected
          : matched != null
          ? matched!.contains(e.a) || matched!.contains(e.b)
          : true;
      final alpha = !active
          ? .06
          : selected != null || matched != null
          ? .58
          : (.17 + e.reasons.length * .065).clamp(.2, .42);
      final curve = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy);
      canvas.drawPath(
        curve,
        Paint()
          ..color = Palette.lavender.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      if (active && stars++ < 8) {
        final p = (start + mid * 2 + end) / 4;
        canvas.drawCircle(
          p,
          2,
          Paint()..color = Palette.lavender.withValues(alpha: .65),
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant UniverseConnections old) =>
      old.positions != positions ||
      old.edges != edges ||
      old.selected != selected ||
      old.matched != matched ||
      old.textScale != textScale;
}
