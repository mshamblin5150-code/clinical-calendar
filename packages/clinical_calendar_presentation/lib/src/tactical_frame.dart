import 'package:flutter/material.dart';

import 'variant_f_theme.dart';

/// The structural frame language adapted from the Variant F tactical console.
///
/// This deliberately owns geometry only. Workflow surfaces keep their existing
/// semantics and behavior while gaining a clipped silhouette, recessed fill,
/// inset rail, corner hardware, and high-contrast operational edge.
final class VariantFTacticalFrame extends StatelessWidget {
  const VariantFTacticalFrame({
    required this.child,
    this.accent,
    this.padding = const EdgeInsets.all(12),
    this.chamfer = 12,
    this.recessed = true,
    this.statusLight = false,
    super.key,
  });

  final Widget child;
  final Color? accent;
  final EdgeInsetsGeometry padding;
  final double chamfer;
  final bool recessed;
  final bool statusLight;

  @override
  Widget build(BuildContext context) {
    final edge = accent ?? context.clinicalColors.insetBorder;
    return CustomPaint(
      foregroundPainter: _VariantFTacticalFramePainter(
        edge: edge,
        rail: context.clinicalColors.insetBorder,
        chamfer: chamfer,
        statusLight: statusLight,
      ),
      child: ClipPath(
        clipper: VariantFChamferClipper(chamfer: chamfer),
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
            boxShadow: const [
              BoxShadow(
                color: VariantFColors.shadow,
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
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

final class _VariantFTacticalFramePainter extends CustomPainter {
  const _VariantFTacticalFramePainter({
    required this.edge,
    required this.rail,
    required this.chamfer,
    required this.statusLight,
  });

  final Color edge;
  final Color rail;
  final double chamfer;
  final bool statusLight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 24 || size.height < 24) return;
    final outer = variantFChamferPath(size, chamfer);
    canvas.drawPath(
      outer,
      Paint()
        ..color = edge.withValues(alpha: .95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    const inset = 5.0;
    final innerSize = Size(size.width - inset * 2, size.height - inset * 2);
    if (innerSize.width > 16 && innerSize.height > 16) {
      final inner = variantFChamferPath(
        innerSize,
        (chamfer - inset).clamp(3, chamfer),
      ).shift(const Offset(inset, inset));
      canvas.drawPath(
        inner,
        Paint()
          ..color = rail.withValues(alpha: .62)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
    }

    final hardware = Paint()
      ..color = edge.withValues(alpha: .82)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final run = (chamfer + 12).clamp(18, 34).toDouble();
    canvas
      ..drawLine(Offset(chamfer + 3, 3), Offset(run, 3), hardware)
      ..drawLine(
        Offset(size.width - run, 3),
        Offset(size.width - chamfer - 3, 3),
        hardware,
      )
      ..drawLine(
        Offset(chamfer + 3, size.height - 3),
        Offset(run, size.height - 3),
        hardware,
      )
      ..drawLine(
        Offset(size.width - run, size.height - 3),
        Offset(size.width - chamfer - 3, size.height - 3),
        hardware,
      );

    final fastener = Paint()..color = rail.withValues(alpha: .9);
    for (final point in [
      Offset(chamfer + 2, 7),
      Offset(7, chamfer + 2),
      Offset(size.width - chamfer - 2, size.height - 7),
      Offset(size.width - 7, size.height - chamfer - 2),
    ]) {
      canvas.drawRect(
        Rect.fromCenter(center: point, width: 3, height: 3),
        fastener,
      );
    }

    if (statusLight) {
      canvas.drawCircle(
        Offset(size.width - chamfer - 12, 14),
        4,
        Paint()
          ..color = VariantFColors.primary
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(size.width - chamfer - 12, 14),
        7,
        Paint()
          ..color = VariantFColors.primary.withValues(alpha: .3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VariantFTacticalFramePainter oldDelegate) =>
      oldDelegate.edge != edge ||
      oldDelegate.rail != rail ||
      oldDelegate.chamfer != chamfer ||
      oldDelegate.statusLight != statusLight;
}
