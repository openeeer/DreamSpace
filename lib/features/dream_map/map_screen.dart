import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/design.dart';
import '../../models/dream.dart';
import '../insights/analytics.dart';
export 'universe_screen.dart' show MapScreen;

/// Deterministic concentric constellation, with existing coordinates reserved
/// first. IDs, not artwork or titles, identify dreams.
Map<String, Offset> layoutGraph(
  List<Dream> dreams,
  List<Connection> edges, {
  Map<String, Offset> previous = const {},
  double nodeSpacing = 160,
}) {
  final unique = {for (final d in dreams) d.id: d}.values.toList();
  final degree = {for (final d in unique) d.id: 0.0};
  for (final e in edges) {
    if (!degree.containsKey(e.a) || !degree.containsKey(e.b)) continue;
    degree[e.a] = degree[e.a]! + e.weight;
    degree[e.b] = degree[e.b]! + e.weight;
  }
  unique.sort((a, b) {
    final order = degree[b.id]!.compareTo(degree[a.id]!);
    return order == 0 ? a.id.compareTo(b.id) : order;
  });
  final seeds = <String, Offset>{};
  for (var i = 0; i < unique.length; i++) {
    final ring = ((i - 1) ~/ 7) + 1;
    final angle =
        -math.pi / 2 + ((i - 1) % 7) * math.pi * 2 / 7 + (i.isEven ? .13 : -.1);
    seeds[unique[i].id] =
        previous[unique[i].id] ??
        (i == 0
            ? const Offset(650, 700)
            : Offset(
                650 + math.cos(angle) * nodeSpacing * 1.6 * ring,
                650 + math.sin(angle) * nodeSpacing * 2.05 * ring,
              ));
  }
  final ordered = [...unique]
    ..sort(
      (a, b) => (previous.containsKey(b.id) ? 1 : 0).compareTo(
        previous.containsKey(a.id) ? 1 : 0,
      ),
    );
  final placed = <String, Offset>{};
  for (final d in ordered) {
    final origin = seeds[d.id]!;
    var candidate = origin;
    var attempt = 0;
    while (placed.values.any((p) => (p - candidate).distance < nodeSpacing)) {
      attempt++;
      final angle = attempt * 2.399963;
      candidate =
          origin +
          Offset(math.cos(angle), math.sin(angle)) *
              nodeSpacing *
              .55 *
              math.sqrt(attempt);
    }
    // Grow toward positive canvas coordinates, keeping existing nodes stable.
    if (candidate.dx < 100 || candidate.dy < 100) {
      candidate = Offset(
        math.max(100, candidate.dx),
        math.max(100, candidate.dy),
      );
      while (placed.values.any((p) => (p - candidate).distance < nodeSpacing)) {
        candidate += Offset(nodeSpacing, nodeSpacing * .5);
      }
    }
    placed[d.id] = candidate;
  }
  return placed;
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
          ..color = Palette.lavender.withValues(alpha: .3)
          ..strokeWidth = .8,
      );
      canvas.drawCircle(
        Offset.lerp(a, b, .5)!,
        1.5,
        Paint()..color = Palette.lavender.withValues(alpha: .55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant ConnectionsPainter old) =>
      old.positions != positions || old.edges != edges;
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
