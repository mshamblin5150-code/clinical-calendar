import 'package:flutter/material.dart';

import 'variant_f_theme.dart';

/// Opts shared live workflow widgets into Coastal Light-owned presentation.
///
/// Controllers, callbacks, validation, and persistence stay in the shared
/// widgets; this scope changes only their housing.
final class CoastalLightPanelScope extends InheritedWidget {
  const CoastalLightPanelScope({required super.child, super.key});

  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CoastalLightPanelScope>() !=
      null;

  @override
  bool updateShouldNotify(CoastalLightPanelScope oldWidget) => false;
}

enum CoastalLightPanelRole {
  placements('placements', false),
  planning('planning', true),
  clinicalPlacement('clinical-placement', true),
  needsAttention('needs-attention', true),
  supporting('supporting', false);

  const CoastalLightPanelRole(this.id, this.ownsVerticalScroll);

  final String id;
  final bool ownsVerticalScroll;
}

final class CoastalLightWorkflowHousing extends StatelessWidget {
  const CoastalLightWorkflowHousing({
    required this.role,
    required this.label,
    required this.child,
    this.accent,
    this.showHeader = true,
    super.key,
  });

  final CoastalLightPanelRole role;
  final String label;
  final Widget child;
  final Color? accent;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final colors = context.clinicalColors;
    final signal = accent ?? colors.clinical;
    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedHeight = constraints.hasBoundedHeight;
        final body = ClipRect(
          child: boundedHeight && role.ownsVerticalScroll
              ? SingleChildScrollView(
                  key: Key('coastal-light-${role.id}-scroll'),
                  child: child,
                )
              : child,
        );
        return CustomPaint(
          key: role == CoastalLightPanelRole.supporting
              ? null
              : Key('coastal-light-${role.id}-housing'),
          painter: _CoastalLightWorkflowHousingPainter(
            surface: colors.structure,
            raised: colors.structureRaised,
            border: colors.insetBorder,
            signal: signal,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              mainAxisSize: boundedHeight ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showHeader) ...[
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 5,
                        decoration: BoxDecoration(
                          color: signal,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          label.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: colors.primaryText,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .9,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                if (boundedHeight) Expanded(child: body) else body,
              ],
            ),
          ),
        );
      },
    );
  }
}

final class _CoastalLightWorkflowHousingPainter extends CustomPainter {
  const _CoastalLightWorkflowHousingPainter({
    required this.surface,
    required this.raised,
    required this.border,
    required this.signal,
  });

  final Color surface;
  final Color raised;
  final Color border;
  final Color signal;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final outer = RRect.fromRectAndCorners(
      Offset.zero & size,
      topLeft: const Radius.circular(24),
      topRight: const Radius.circular(10),
      bottomLeft: const Radius.circular(10),
      bottomRight: const Radius.circular(24),
    );
    canvas.drawRRect(outer, Paint()..color = Color.lerp(raised, signal, .08)!);
    canvas.drawRRect(
      outer,
      Paint()
        ..color = signal.withValues(alpha: .55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final inner = RRect.fromRectAndCorners(
      Rect.fromLTWH(7, 7, size.width - 14, size.height - 14),
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(7),
      bottomLeft: const Radius.circular(7),
      bottomRight: const Radius.circular(18),
    );
    canvas.drawRRect(inner, Paint()..color = surface);
    canvas.drawRRect(
      inner,
      Paint()
        ..color = border.withValues(alpha: .58)
        ..style = PaintingStyle.stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * .18, 5, size.height * .64),
        const Radius.circular(5),
      ),
      Paint()..color = signal,
    );
  }

  @override
  bool shouldRepaint(_CoastalLightWorkflowHousingPainter oldDelegate) =>
      oldDelegate.surface != surface ||
      oldDelegate.raised != raised ||
      oldDelegate.border != border ||
      oldDelegate.signal != signal;
}
