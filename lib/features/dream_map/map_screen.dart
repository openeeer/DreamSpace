import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design.dart';
import '../../models/dream.dart';
import '../insights/analytics.dart';

Map<String, Offset> layoutGraph(
  List<Dream> dreams,
  List<Connection> edges, {
  Map<String, Offset> previous = const {},
}) {
  final positions = <String, Offset>{};
  for (var i = 0; i < dreams.length; i++) {
    final angle = i * 2.399963;
    final radius = 80 + math.sqrt(i) * 105;
    positions[dreams[i].id] =
        previous[dreams[i].id] ??
        Offset(650 + math.cos(angle) * radius, 650 + math.sin(angle) * radius);
  }
  if (previous.isNotEmpty) return positions;
  for (var iteration = 0; iteration < 70; iteration++) {
    final force = {for (final id in positions.keys) id: Offset.zero};
    for (var i = 0; i < dreams.length; i++) {
      for (var j = i + 1; j < dreams.length; j++) {
        final a = dreams[i].id, b = dreams[j].id;
        final delta = positions[a]! - positions[b]!;
        final distance = math.max(1.0, delta.distance);
        final push =
            delta / distance * (16000 / (distance * distance)).clamp(0, 12);
        force[a] = force[a]! + push;
        force[b] = force[b]! - push;
      }
    }
    for (final e in edges) {
      final delta = positions[e.b]! - positions[e.a]!;
      final distance = math.max(1.0, delta.distance);
      final pull = delta / distance * ((distance - 205) * .008);
      force[e.a] = force[e.a]! + pull;
      force[e.b] = force[e.b]! - pull;
    }
    for (final id in positions.keys) {
      final p = positions[id]! + force[id]!;
      positions[id] = Offset(p.dx.clamp(80, 1220), p.dy.clamp(80, 1220));
    }
  }
  return positions;
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.focus});
  final String? focus;
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final camera = TransformationController();
  Map<String, Offset> positions = {};
  String? selected;
  String query = '';
  bool mood = true, list = false, fitted = false;
  Set<ElementKind> kinds = ElementKind.values.toSet();
  Size viewport = Size.zero;
  @override
  void initState() {
    super.initState();
    selected = widget.focus;
  }

  @override
  void didUpdateWidget(covariant MapScreen old) {
    super.didUpdateWidget(old);
    if (old.focus != widget.focus) selected = widget.focus;
  }

  @override
  void dispose() {
    camera.dispose();
    super.dispose();
  }

  void fit() {
    if (positions.isEmpty || viewport.isEmpty) return;
    final xs = positions.values.map((p) => p.dx),
        ys = positions.values.map((p) => p.dy);
    final rect = Rect.fromLTRB(
      xs.reduce(math.min) - 85,
      ys.reduce(math.min) - 85,
      xs.reduce(math.max) + 85,
      ys.reduce(math.max) + 85,
    );
    final scale = math
        .min(viewport.width / rect.width, viewport.height / rect.height)
        .clamp(.25, 1.1);
    camera.value = Matrix4.identity()
      ..translateByDouble(
        viewport.width / 2 - rect.center.dx * scale,
        viewport.height / 2 - rect.center.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void zoom(double factor) {
    final old = camera.value.getMaxScaleOnAxis();
    final next = (old * factor).clamp(.2, 2.5);
    final point = camera.toScene(
      Offset(viewport.width / 2, viewport.height / 2),
    );
    camera.value = Matrix4.identity()
      ..translateByDouble(
        viewport.width / 2 - point.dx * next,
        viewport.height / 2 - point.dy * next,
        0,
        1,
      )
      ..scaleByDouble(next, next, 1, 1);
  }

  @override
  Widget build(BuildContext context) => DreamsBuilder(
    builder: (all, en) {
      final dreams = all.take(100).toList();
      if (widget.focus != null && !dreams.any((d) => d.id == widget.focus)) {
        final focused = all.where((d) => d.id == widget.focus).firstOrNull;
        if (focused != null) {
          if (dreams.length == 100) dreams.removeLast();
          dreams.add(focused);
        }
      }
      final allEdges = connections(dreams);
      positions = layoutGraph(dreams, allEdges, previous: positions);
      final edges = connections(dreams, kinds: kinds, mood: mood);
      final current = dreams.where((d) => d.id == selected).firstOrNull;
      final related = edges
          .where((e) => e.a == selected || e.b == selected)
          .toList();
      final highlighted = {
        selected,
        ...related.expand((e) => [e.a, e.b]),
      };
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tr(en, 'Вселенная снов', 'Dream Universe'),
                        style: display(30),
                      ),
                    ),
                    IconButton(
                      tooltip: tr(en, 'Список / карта', 'List / map'),
                      onPressed: () => setState(() => list = !list),
                      icon: Icon(
                        list ? CupertinoIcons.map : CupertinoIcons.list_bullet,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: TextField(
                  onChanged: (s) => setState(() => query = s),
                  decoration: InputDecoration(
                    hintText: tr(en, 'Найти сон во вселенной', 'Find a dream'),
                    prefixIcon: const Icon(CupertinoIcons.search, size: 20),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final kind in ElementKind.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: DreamChip(
                          switch (kind) {
                            ElementKind.symbol => tr(en, 'Символы', 'Symbols'),
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
                    DreamChip(
                      tr(en, 'Эмоции', 'Mood'),
                      selected: mood,
                      onTap: () => setState(() => mood = !mood),
                    ),
                  ],
                ),
              ),
              if (all.length > 100)
                Text(
                  tr(
                    en,
                    'Показаны последние 100 снов',
                    'Showing the latest 100 dreams',
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              Expanded(
                child: dreams.isEmpty
                    ? SingleChildScrollView(child: EmptyDreams(en: en))
                    : list || query.isNotEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
                        children: [
                          for (final d in all.where(
                            (d) =>
                                normalize(d.title).contains(normalize(query)),
                          ))
                            DreamCard(d, en: en),
                        ],
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          viewport = Size(
                            constraints.maxWidth,
                            constraints.maxHeight - 110,
                          );
                          if (!fitted) {
                            fitted = true;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) fit();
                            });
                          }
                          return Stack(
                            children: [
                              Positioned.fill(
                                bottom: 110,
                                child: InteractiveViewer(
                                  transformationController: camera,
                                  constrained: false,
                                  boundaryMargin: const EdgeInsets.all(1600),
                                  minScale: .2,
                                  maxScale: 2.5,
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => selected = null),
                                    child: SizedBox(
                                      width: 1300,
                                      height: 1300,
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: ConnectionsPainter(
                                                positions,
                                                selected == null
                                                    ? edges.take(150).toList()
                                                    : related,
                                                selected,
                                              ),
                                            ),
                                          ),
                                          for (final d in dreams)
                                            Positioned(
                                              left: positions[d.id]!.dx - 42,
                                              top: positions[d.id]!.dy - 42,
                                              child: Semantics(
                                                button: true,
                                                label: d.title,
                                                selected: d.id == selected,
                                                child: GestureDetector(
                                                  onTap: () => setState(
                                                    () => selected = d.id,
                                                  ),
                                                  child: AnimatedOpacity(
                                                    duration: const Duration(
                                                      milliseconds: 180,
                                                    ),
                                                    opacity:
                                                        selected == null ||
                                                            highlighted
                                                                .contains(d.id)
                                                        ? 1
                                                        : .25,
                                                    child: Column(
                                                      children: [
                                                        Container(
                                                          width: 84,
                                                          height: 84,
                                                          decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border: Border.all(
                                                              color:
                                                                  d.id ==
                                                                      selected
                                                                  ? Palette.text
                                                                  : Palette
                                                                        .lavender,
                                                              width:
                                                                  d.id ==
                                                                      selected
                                                                  ? 2
                                                                  : 1,
                                                            ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color:
                                                                    moodColor(
                                                                      d.mood,
                                                                    ).withValues(
                                                                      alpha:
                                                                          .25,
                                                                    ),
                                                                blurRadius: 22,
                                                              ),
                                                            ],
                                                          ),
                                                          child: ClipOval(
                                                            child: DreamArtwork(
                                                              d.artwork,
                                                              radius: 0,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        SizedBox(
                                                          width: 100,
                                                          child: Text(
                                                            d.title,
                                                            maxLines: 2,
                                                            textAlign: TextAlign
                                                                .center,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  height: 1.25,
                                                                ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
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
                              Positioned(
                                right: 16,
                                top: 16,
                                child: DreamSurface(
                                  padding: const EdgeInsets.all(2),
                                  glass: true,
                                  child: Column(
                                    children: [
                                      IconButton(
                                        tooltip: tr(
                                          en,
                                          'Приблизить',
                                          'Zoom in',
                                        ),
                                        onPressed: () => zoom(1.3),
                                        icon: const Icon(CupertinoIcons.plus),
                                      ),
                                      IconButton(
                                        tooltip: tr(en, 'Отдалить', 'Zoom out'),
                                        onPressed: () => zoom(.77),
                                        icon: const Icon(CupertinoIcons.minus),
                                      ),
                                      IconButton(
                                        tooltip: tr(en, 'Вся карта', 'Fit all'),
                                        onPressed: fit,
                                        icon: const Icon(
                                          CupertinoIcons
                                              .arrow_up_left_arrow_down_right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (current != null)
                                Positioned(
                                  left: 16,
                                  right: 16,
                                  bottom: 124,
                                  child: DreamSurface(
                                    glass: true,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                current.title,
                                                style: display(23),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () => setState(
                                                () => selected = null,
                                              ),
                                              icon: const Icon(
                                                CupertinoIcons.xmark,
                                              ),
                                              tooltip: tr(
                                                en,
                                                'Закрыть',
                                                'Close',
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          tr(
                                            en,
                                            'Связей: ${related.length}',
                                            'Connections: ${related.length}',
                                          ),
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          related
                                              .expand((e) => e.reasons)
                                              .toSet()
                                              .map(
                                                (r) => r.startsWith('mood:')
                                                    ? Mood.values
                                                          .byName(
                                                            r.substring(5),
                                                          )
                                                          .label(en)
                                                    : r,
                                              )
                                              .join(' · '),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        TextButton(
                                          onPressed: () => context.push(
                                            '/dream/${current.id}',
                                          ),
                                          child: Text(
                                            tr(
                                              en,
                                              'Открыть сон →',
                                              'Open Dream →',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Positioned(
                                  left: 24,
                                  right: 24,
                                  bottom: 135,
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
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class ConnectionsPainter extends CustomPainter {
  ConnectionsPainter(this.positions, this.edges, this.selected);
  final Map<String, Offset> positions;
  final List<Connection> edges;
  final String? selected;
  @override
  void paint(Canvas canvas, Size size) {
    for (final e in edges) {
      if (!positions.containsKey(e.a) || !positions.containsKey(e.b)) continue;
      final a = positions[e.a]!, b = positions[e.b]!;
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = Palette.lavender.withValues(
            alpha: selected == null ? .3 : .7,
          )
          ..strokeWidth = selected == null ? 1 : 1.5,
      );
      canvas.drawCircle(
        Offset.lerp(a, b, .5)!,
        2,
        Paint()..color = Palette.lavender.withValues(alpha: .55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ConnectionsPainter old) => true;
}

class MapPreview extends StatelessWidget {
  const MapPreview(this.dreams, {super.key});
  final List<Dream> dreams;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 156,
    child: LayoutBuilder(
      builder: (context, c) {
        final visible = dreams.take(7).toList();
        final positions = <String, Offset>{};
        for (var i = 0; i < visible.length; i++) {
          positions[visible[i].id] = i == 0
              ? Offset(c.maxWidth * .5, 78)
              : Offset(
                  c.maxWidth * (.5 + .39 * math.cos((i - 1) * math.pi / 3)),
                  78 + 49 * math.sin((i - 1) * math.pi / 3),
                );
        }
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: ConnectionsPainter(
                  positions,
                  connections(visible),
                  null,
                ),
              ),
            ),
            for (var i = 0; i < visible.length; i++)
              Positioned(
                left: positions[visible[i].id]!.dx - (i == 0 ? 31 : 21),
                top: positions[visible[i].id]!.dy - (i == 0 ? 31 : 21),
                child: Container(
                  width: i == 0 ? 62 : 42,
                  height: i == 0 ? 62 : 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Palette.lavender.withValues(alpha: .8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Palette.lavender.withValues(alpha: .22),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: DreamArtwork(visible[i].artwork, radius: 0),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
