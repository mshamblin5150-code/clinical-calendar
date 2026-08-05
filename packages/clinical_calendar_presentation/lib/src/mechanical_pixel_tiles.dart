import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'variant_f_theme.dart';

/// Small, pixel-snapped mechanical parts adapted from the Variant F reference.
///
/// Every part is authored on a 16x16 logical grid, so the same deterministic
/// tile can be repeated at several device densities without becoming a blurry
/// stretched ornament.
enum VariantFMechanicalTile {
  cornerClamp,
  railCoupler,
  recessedLatch,
  ventBank,
  conduitElbow,
  bridgeBracket,
}

@immutable
final class VariantFMechanicalPalette {
  const VariantFMechanicalPalette({
    required this.edge,
    required this.highlight,
    required this.metal,
    required this.shadow,
    required this.accent,
  });

  final Color edge;
  final Color highlight;
  final Color metal;
  final Color shadow;
  final Color accent;

  factory VariantFMechanicalPalette.fromContext(
    BuildContext context, {
    Color? accent,
  }) => VariantFMechanicalPalette(
    edge: context.clinicalColors.insetBorder,
    highlight: VariantFColors.muted.withValues(alpha: .72),
    metal: context.clinicalColors.structureRaised,
    shadow: VariantFColors.background,
    accent: accent ?? context.clinicalColors.clinical,
  );
}

/// A previewable tile widget used by component tests and future panel layouts.
final class VariantFMechanicalTileWidget extends StatelessWidget {
  const VariantFMechanicalTileWidget({
    required this.tile,
    this.turns = 0,
    this.accent,
    super.key,
  });

  final VariantFMechanicalTile tile;
  final int turns;
  final Color? accent;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _TileWidgetPainter(
      tile: tile,
      turns: turns,
      palette: VariantFMechanicalPalette.fromContext(context, accent: accent),
    ),
  );
}

final class _TileWidgetPainter extends CustomPainter {
  const _TileWidgetPainter({
    required this.tile,
    required this.turns,
    required this.palette,
  });

  final VariantFMechanicalTile tile;
  final int turns;
  final VariantFMechanicalPalette palette;

  @override
  void paint(Canvas canvas, Size size) => paintVariantFMechanicalTile(
    canvas,
    Offset.zero & size,
    tile,
    palette,
    turns: turns,
  );

  @override
  bool shouldRepaint(covariant _TileWidgetPainter oldDelegate) =>
      oldDelegate.tile != tile ||
      oldDelegate.turns != turns ||
      oldDelegate.palette != palette;
}

void paintVariantFMechanicalTile(
  Canvas canvas,
  Rect destination,
  VariantFMechanicalTile tile,
  VariantFMechanicalPalette palette, {
  int turns = 0,
}) {
  if (destination.width <= 0 || destination.height <= 0) return;
  canvas.save();
  canvas.translate(destination.center.dx, destination.center.dy);
  canvas.rotate((turns % 4) * math.pi / 2);
  final rotated = turns.isOdd
      ? Size(destination.height, destination.width)
      : destination.size;
  canvas.scale(rotated.width / 16, rotated.height / 16);
  canvas.translate(-8, -8);

  switch (tile) {
    case VariantFMechanicalTile.cornerClamp:
      _paintCornerClamp(canvas, palette);
    case VariantFMechanicalTile.railCoupler:
      _paintRailCoupler(canvas, palette);
    case VariantFMechanicalTile.recessedLatch:
      _paintRecessedLatch(canvas, palette);
    case VariantFMechanicalTile.ventBank:
      _paintVentBank(canvas, palette);
    case VariantFMechanicalTile.conduitElbow:
      _paintConduitElbow(canvas, palette);
    case VariantFMechanicalTile.bridgeBracket:
      _paintBridgeBracket(canvas, palette);
  }
  canvas.restore();
}

void _paintCornerClamp(Canvas canvas, VariantFMechanicalPalette palette) {
  final body = Path()
    ..moveTo(0, 5)
    ..lineTo(5, 0)
    ..lineTo(16, 0)
    ..lineTo(16, 5)
    ..lineTo(8, 5)
    ..lineTo(5, 8)
    ..lineTo(5, 16)
    ..lineTo(0, 16)
    ..close();
  _fillAndEdge(canvas, body, palette.metal, palette.edge, 1);
  canvas.drawPath(
    Path()
      ..moveTo(2, 6)
      ..lineTo(6, 2)
      ..lineTo(14, 2),
    Paint()
      ..color = palette.highlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = .75,
  );
  _slottedBolt(canvas, const Offset(5, 5), palette);
  canvas.drawRect(
    const Rect.fromLTWH(1, 10, 3, 4),
    Paint()..color = palette.shadow,
  );
}

void _paintRailCoupler(Canvas canvas, VariantFMechanicalPalette palette) {
  final body = Path()
    ..moveTo(3, 0)
    ..lineTo(13, 0)
    ..lineTo(16, 3)
    ..lineTo(16, 13)
    ..lineTo(13, 16)
    ..lineTo(3, 16)
    ..lineTo(0, 13)
    ..lineTo(0, 3)
    ..close();
  _fillAndEdge(canvas, body, palette.metal, palette.edge, .8);
  canvas.drawRect(
    const Rect.fromLTWH(4, 2, 8, 12),
    Paint()..color = palette.shadow,
  );
  for (final y in [4.0, 7.0, 10.0]) {
    canvas.drawRect(
      Rect.fromLTWH(5, y, 6, 1),
      Paint()..color = palette.highlight,
    );
  }
  _slottedBolt(canvas, const Offset(2.5, 8), palette);
  _slottedBolt(canvas, const Offset(13.5, 8), palette);
}

void _paintRecessedLatch(Canvas canvas, VariantFMechanicalPalette palette) {
  final surround = Path()
    ..moveTo(1, 3)
    ..lineTo(15, 3)
    ..lineTo(13, 13)
    ..lineTo(3, 13)
    ..close();
  _fillAndEdge(canvas, surround, palette.metal, palette.edge, .8);
  final recess = Path()
    ..moveTo(4, 5)
    ..lineTo(12, 5)
    ..lineTo(10, 10)
    ..lineTo(6, 10)
    ..close();
  canvas.drawPath(recess, Paint()..color = palette.shadow);
  canvas.drawRect(
    const Rect.fromLTWH(6, 6, 4, 1),
    Paint()..color = palette.highlight,
  );
  _slottedBolt(canvas, const Offset(2.5, 7), palette);
  _slottedBolt(canvas, const Offset(13.5, 7), palette);
}

void _paintVentBank(Canvas canvas, VariantFMechanicalPalette palette) {
  _fillAndEdge(
    canvas,
    Path()..addRect(const Rect.fromLTWH(0, 2, 16, 12)),
    palette.metal,
    palette.edge,
    .8,
  );
  for (var x = 2.0; x <= 12; x += 2.5) {
    canvas.drawRect(Rect.fromLTWH(x, 4, 1, 8), Paint()..color = palette.shadow);
    canvas.drawRect(
      Rect.fromLTWH(x + 1, 4, .5, 8),
      Paint()..color = palette.highlight.withValues(alpha: .7),
    );
  }
}

void _paintConduitElbow(Canvas canvas, VariantFMechanicalPalette palette) {
  final pipe = Paint()
    ..color = palette.metal
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.square;
  final edge = Paint()
    ..color = palette.edge
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6.5
    ..strokeCap = StrokeCap.square;
  final path = Path()
    ..moveTo(2, 16)
    ..lineTo(2, 7)
    ..quadraticBezierTo(2, 2, 7, 2)
    ..lineTo(16, 2);
  canvas
    ..drawPath(path, edge)
    ..drawPath(path, pipe)
    ..drawPath(
      path,
      Paint()
        ..color = palette.highlight.withValues(alpha: .7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  for (final point in [const Offset(2, 12), const Offset(12, 2)]) {
    canvas.drawRect(
      Rect.fromCenter(center: point, width: 7, height: 3),
      Paint()..color = palette.shadow,
    );
    canvas.drawRect(
      Rect.fromCenter(center: point, width: 7, height: 3),
      Paint()
        ..color = palette.edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7,
    );
  }
}

void _paintBridgeBracket(Canvas canvas, VariantFMechanicalPalette palette) {
  final body = Path()
    ..moveTo(0, 3)
    ..lineTo(4, 0)
    ..lineTo(12, 0)
    ..lineTo(16, 3)
    ..lineTo(14, 16)
    ..lineTo(10, 16)
    ..lineTo(10, 7)
    ..lineTo(6, 7)
    ..lineTo(6, 16)
    ..lineTo(2, 16)
    ..close();
  _fillAndEdge(canvas, body, palette.metal, palette.edge, 1);
  canvas.drawRect(
    const Rect.fromLTWH(4, 2, 8, 2),
    Paint()..color = palette.shadow,
  );
  _slottedBolt(canvas, const Offset(3.5, 5), palette);
  _slottedBolt(canvas, const Offset(12.5, 5), palette);
}

void _fillAndEdge(
  Canvas canvas,
  Path path,
  Color fill,
  Color edge,
  double width,
) {
  canvas
    ..drawPath(path, Paint()..color = fill)
    ..drawPath(
      path,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
}

void _slottedBolt(
  Canvas canvas,
  Offset center,
  VariantFMechanicalPalette palette,
) {
  canvas
    ..drawCircle(center, 1.6, Paint()..color = palette.shadow)
    ..drawCircle(
      center,
      1.6,
      Paint()
        ..color = palette.highlight
        ..style = PaintingStyle.stroke
        ..strokeWidth = .6,
    )
    ..drawLine(
      center.translate(-.8, 0),
      center.translate(.8, 0),
      Paint()
        ..color = palette.highlight
        ..strokeWidth = .5,
    );
}
