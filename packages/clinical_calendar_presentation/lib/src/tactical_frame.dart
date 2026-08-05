import 'package:flutter/material.dart';

import 'variant_f_theme.dart';

/// A substantial mechanical panel adapted from the Variant F console chassis.
///
/// Unlike a decorative outline, this reserves real layout space for its metal
/// bezel. Workflow content sits inside that chassis, behind armored corners,
/// connector blocks, latches, rails, and slotted fasteners.
final class VariantFTacticalFrame extends StatelessWidget {
  const VariantFTacticalFrame({
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(12),
    this.chamfer = 12,
    this.recessed = true,
    this.statusLight = false,
    this.mechanicalBezel = 9,
    super.key,
  });

  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final double chamfer;
  final bool recessed;
  final bool statusLight;
  final double mechanicalBezel;

  @override
  Widget build(BuildContext context) {
    final edge = accent ?? context.clinicalColors.insetBorder;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bezel = constraints.maxWidth < 500 ? 0.0 : mechanicalBezel;
        return CustomPaint(
          painter: _MechanicalPanelPainter(
            edge: edge,
            rail: context.clinicalColors.insetBorder,
            metal: context.clinicalColors.structureRaised,
            chamfer: chamfer,
            bezel: bezel,
          ),
          foregroundPainter: _MechanicalPanelHardwarePainter(
            edge: edge,
            rail: context.clinicalColors.insetBorder,
            chamfer: chamfer,
            bezel: bezel,
            statusLight: statusLight,
          ),
          child: Padding(
            padding: EdgeInsets.all(bezel),
            child: ClipPath(
              clipper: VariantFChamferClipper(
                chamfer: (chamfer - bezel / 2).clamp(4, chamfer),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: recessed
                        ? [
                            context.clinicalColors.structureRaised,
                            context.clinicalColors.structure,
                            context.clinicalColors.canvas,
                          ]
                        : [
                            context.clinicalColors.structure,
                            context.clinicalColors.structureRaised,
                          ],
                    stops: recessed ? const [0, .45, 1] : const [0, 1],
                  ),
                ),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The application-level machinery rail that makes the individual consoles
/// read as modules mounted into one chassis.
final class VariantFMechanicalChassis extends StatelessWidget {
  const VariantFMechanicalChassis({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 500;
      final rail = compact ? 0.0 : 11.0;
      return CustomPaint(
        foregroundPainter: _MechanicalChassisPainter(
          edge: context.clinicalColors.insetBorder,
          metal: context.clinicalColors.structureRaised,
          railWidth: compact ? 6 : rail,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: rail, vertical: 5),
          child: child,
        ),
      );
    },
  );
}

final class VariantFChamferClipper extends CustomClipper<Path> {
  const VariantFChamferClipper({this.chamfer = 12});

  final double chamfer;

  @override
  Path getClip(Size size) => variantFChamferPath(size, chamfer);

  @override
  bool shouldReclip(covariant VariantFChamferClipper oldClipper) =>
      oldClipper.chamfer != chamfer;
}

Path variantFChamferPath(Size size, double requestedChamfer) {
  final maximumCut = (size.shortestSide / 3)
      .clamp(0.0, requestedChamfer)
      .toDouble();
  final cut = requestedChamfer.clamp(0.0, maximumCut).toDouble();
  return Path()
    ..moveTo(cut, 0)
    ..lineTo(size.width - cut, 0)
    ..lineTo(size.width, cut)
    ..lineTo(size.width, size.height - cut)
    ..lineTo(size.width - cut, size.height)
    ..lineTo(cut, size.height)
    ..lineTo(0, size.height - cut)
    ..lineTo(0, cut)
    ..close();
}

final class _MechanicalPanelPainter extends CustomPainter {
  const _MechanicalPanelPainter({
    required this.edge,
    required this.rail,
    required this.metal,
    required this.chamfer,
    required this.bezel,
  });

  final Color edge;
  final Color rail;
  final Color metal;
  final double chamfer;
  final double bezel;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 24 || size.height < 24) return;
    final outer = variantFChamferPath(size, chamfer);
    canvas.drawShadow(outer, VariantFColors.shadow, 8, false);
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            metal.withValues(alpha: .98),
            VariantFColors.controlBorder,
            VariantFColors.control,
            metal,
          ],
          stops: const [0, .22, .55, 1],
        ).createShader(Offset.zero & size),
    );

    final plateFill = Paint()..color = VariantFColors.control;
    final plateEdge = Paint()
      ..color = edge.withValues(alpha: .9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final plate in _cornerPlates(size, chamfer)) {
      canvas
        ..drawPath(plate, plateFill)
        ..drawPath(plate, plateEdge);
    }

    final connectorFill = Paint()..color = metal;
    final connectorEdge = Paint()
      ..color = rail
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final connector in _sideConnectors(size, bezel)) {
      canvas
        ..drawPath(connector, connectorFill)
        ..drawPath(connector, connectorEdge);
    }
  }

  @override
  bool shouldRepaint(covariant _MechanicalPanelPainter oldDelegate) =>
      oldDelegate.edge != edge ||
      oldDelegate.rail != rail ||
      oldDelegate.metal != metal ||
      oldDelegate.chamfer != chamfer ||
      oldDelegate.bezel != bezel;
}

final class _MechanicalPanelHardwarePainter extends CustomPainter {
  const _MechanicalPanelHardwarePainter({
    required this.edge,
    required this.rail,
    required this.chamfer,
    required this.bezel,
    required this.statusLight,
  });

  final Color edge;
  final Color rail;
  final double chamfer;
  final double bezel;
  final bool statusLight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 24 || size.height < 24) return;
    final outer = variantFChamferPath(size, chamfer);
    canvas.drawPath(
      outer,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    final innerInset = bezel + 2;
    final innerSize = Size(
      size.width - innerInset * 2,
      size.height - innerInset * 2,
    );
    if (innerSize.width > 12 && innerSize.height > 12) {
      canvas.drawPath(
        variantFChamferPath(
          innerSize,
          (chamfer - bezel / 2).clamp(4, chamfer),
        ).shift(Offset(innerInset, innerInset)),
        Paint()
          ..color = rail.withValues(alpha: .95)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    _drawLatch(canvas, size, edge, rail);
    for (final point in _fastenerPoints(size, chamfer, bezel)) {
      _drawSlottedFastener(canvas, point, rail);
    }

    if (statusLight) {
      final point = Offset(size.width - chamfer - 12, bezel + 5);
      canvas
        ..drawCircle(point, 6, Paint()..color = VariantFColors.background)
        ..drawCircle(point, 4, Paint()..color = VariantFColors.primary)
        ..drawCircle(
          point,
          7,
          Paint()
            ..color = VariantFColors.primary.withValues(alpha: .55)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _MechanicalPanelHardwarePainter oldDelegate) =>
      oldDelegate.edge != edge ||
      oldDelegate.rail != rail ||
      oldDelegate.chamfer != chamfer ||
      oldDelegate.bezel != bezel ||
      oldDelegate.statusLight != statusLight;
}

final class _MechanicalChassisPainter extends CustomPainter {
  const _MechanicalChassisPainter({
    required this.edge,
    required this.metal,
    required this.railWidth,
  });

  final Color edge;
  final Color metal;
  final double railWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 32 || size.height < 60) return;
    final railFill = Paint()..color = metal;
    final railEdge = Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final left = Path()
      ..moveTo(0, 12)
      ..lineTo(railWidth - 3, 4)
      ..lineTo(railWidth, 4)
      ..lineTo(railWidth, size.height - 4)
      ..lineTo(railWidth - 3, size.height - 4)
      ..lineTo(0, size.height - 12)
      ..close();
    final right = Path()
      ..moveTo(size.width, 12)
      ..lineTo(size.width - railWidth + 3, 4)
      ..lineTo(size.width - railWidth, 4)
      ..lineTo(size.width - railWidth, size.height - 4)
      ..lineTo(size.width - railWidth + 3, size.height - 4)
      ..lineTo(size.width, size.height - 12)
      ..close();
    canvas
      ..drawPath(left, railFill)
      ..drawPath(left, railEdge)
      ..drawPath(right, railFill)
      ..drawPath(right, railEdge);

    for (var y = 42.0; y < size.height - 32; y += 92) {
      _drawRailModule(canvas, Offset(1, y), false, edge);
      _drawRailModule(canvas, Offset(size.width - 1, y), true, edge);
    }
  }

  @override
  bool shouldRepaint(covariant _MechanicalChassisPainter oldDelegate) =>
      oldDelegate.edge != edge ||
      oldDelegate.metal != metal ||
      oldDelegate.railWidth != railWidth;
}

List<Path> _cornerPlates(Size size, double cut) {
  final depth = (cut + 13).clamp(20, 34).toDouble();
  return [
    Path()
      ..moveTo(0, cut)
      ..lineTo(cut, 0)
      ..lineTo(depth, 0)
      ..lineTo(depth - 7, 9)
      ..lineTo(10, 9)
      ..lineTo(10, depth - 7)
      ..close(),
    Path()
      ..moveTo(size.width - depth, 0)
      ..lineTo(size.width - cut, 0)
      ..lineTo(size.width, cut)
      ..lineTo(size.width, depth)
      ..lineTo(size.width - 10, depth - 7)
      ..lineTo(size.width - 10, 9)
      ..lineTo(size.width - depth + 7, 9)
      ..close(),
    Path()
      ..moveTo(0, size.height - cut)
      ..lineTo(cut, size.height)
      ..lineTo(depth, size.height)
      ..lineTo(depth - 7, size.height - 9)
      ..lineTo(10, size.height - 9)
      ..lineTo(10, size.height - depth + 7)
      ..close(),
    Path()
      ..moveTo(size.width - depth, size.height)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width, size.height - depth)
      ..lineTo(size.width - 10, size.height - depth + 7)
      ..lineTo(size.width - 10, size.height - 9)
      ..lineTo(size.width - depth + 7, size.height - 9)
      ..close(),
  ];
}

List<Path> _sideConnectors(Size size, double bezel) {
  final height = size.height > 110 ? 28.0 : 16.0;
  final y = size.height / 2 - height / 2;
  final width = (bezel + 6).clamp(12, 20).toDouble();
  return [
    Path()
      ..moveTo(0, y + 5)
      ..lineTo(5, y)
      ..lineTo(width, y)
      ..lineTo(width, y + height)
      ..lineTo(5, y + height)
      ..lineTo(0, y + height - 5)
      ..close(),
    Path()
      ..moveTo(size.width, y + 5)
      ..lineTo(size.width - 5, y)
      ..lineTo(size.width - width, y)
      ..lineTo(size.width - width, y + height)
      ..lineTo(size.width - 5, y + height)
      ..lineTo(size.width, y + height - 5)
      ..close(),
  ];
}

List<Offset> _fastenerPoints(Size size, double cut, double bezel) => [
  Offset(cut + 5, bezel / 2 + 1),
  Offset(bezel / 2 + 1, cut + 5),
  Offset(size.width - cut - 5, bezel / 2 + 1),
  Offset(size.width - bezel / 2 - 1, cut + 5),
  Offset(cut + 5, size.height - bezel / 2 - 1),
  Offset(bezel / 2 + 1, size.height - cut - 5),
  Offset(size.width - cut - 5, size.height - bezel / 2 - 1),
  Offset(size.width - bezel / 2 - 1, size.height - cut - 5),
];

void _drawSlottedFastener(Canvas canvas, Offset point, Color color) {
  canvas
    ..drawCircle(point, 3.2, Paint()..color = VariantFColors.background)
    ..drawCircle(
      point,
      3.2,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = .9,
    )
    ..drawLine(
      point.translate(-1.7, 0),
      point.translate(1.7, 0),
      Paint()
        ..color = color
        ..strokeWidth = .8,
    );
}

void _drawLatch(Canvas canvas, Size size, Color edge, Color rail) {
  if (size.width < 90 || size.height < 40) return;
  final latchWidth = (size.width * .12).clamp(42, 92).toDouble();
  final center = size.width / 2;
  final latch = Path()
    ..moveTo(center - latchWidth / 2, 0)
    ..lineTo(center + latchWidth / 2, 0)
    ..lineTo(center + latchWidth / 2 - 7, 7)
    ..lineTo(center - latchWidth / 2 + 7, 7)
    ..close();
  canvas
    ..drawPath(latch, Paint()..color = VariantFColors.background)
    ..drawPath(
      latch,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    )
    ..drawLine(
      Offset(center - 8, 3.5),
      Offset(center + 8, 3.5),
      Paint()
        ..color = rail
        ..strokeWidth = 1,
    );
}

void _drawRailModule(Canvas canvas, Offset center, bool right, Color edge) {
  final direction = right ? -1.0 : 1.0;
  final block = Path()
    ..moveTo(center.dx, center.dy - 18)
    ..lineTo(center.dx + direction * 8, center.dy - 12)
    ..lineTo(center.dx + direction * 8, center.dy + 12)
    ..lineTo(center.dx, center.dy + 18)
    ..close();
  canvas
    ..drawPath(block, Paint()..color = VariantFColors.control)
    ..drawPath(
      block,
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    )
    ..drawLine(
      center.translate(direction * 3, -8),
      center.translate(direction * 3, 8),
      Paint()
        ..color = edge.withValues(alpha: .7)
        ..strokeWidth = 1.4,
    );
}
