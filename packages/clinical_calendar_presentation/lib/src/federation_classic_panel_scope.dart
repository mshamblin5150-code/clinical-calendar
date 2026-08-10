import 'package:flutter/material.dart';

import 'variant_f_theme.dart';

/// Selects Federation Classic presentation for shared landing workflows.
///
/// The workflow widgets remain shared; only [ShellPanel]'s housing changes
/// while it is mounted inside this scope.
final class FederationClassicPanelScope extends InheritedWidget {
  const FederationClassicPanelScope({required super.child, super.key});

  static bool isActive(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<FederationClassicPanelScope>() !=
      null;

  @override
  bool updateShouldNotify(FederationClassicPanelScope oldWidget) => false;
}

final class FederationClassicPanelHousing extends StatelessWidget {
  const FederationClassicPanelHousing({
    required this.label,
    required this.child,
    this.accent,
    this.showHeader = true,
    super.key,
  });

  final String label;
  final Widget child;
  final Color? accent;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final signal = accent ?? context.clinicalColors.workMachinery;
    return CustomPaint(
      key: Key('federation-classic-${_panelId(label)}-housing'),
      painter: _FederationClassicPanelPainter(
        surface: context.clinicalColors.structure,
        signal: signal,
        secondary: context.clinicalColors.scheduled,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 12, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showHeader) ...[
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 8,
                        decoration: BoxDecoration(
                          color: signal,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: .8,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                if (constraints.hasBoundedHeight)
                  Expanded(child: child)
                else
                  child,
              ],
            );
            return content;
          },
        ),
      ),
    );
  }
}

String _panelId(String label) {
  final normalized = label.toLowerCase();
  if (normalized.startsWith('my placements')) return 'placements';
  if (normalized.startsWith('planning')) return 'planning';
  if (normalized.startsWith('clinical placement')) {
    return 'clinical-placement';
  }
  if (normalized.startsWith('needs attention')) return 'needs-attention';
  return 'workflow';
}

final class _FederationClassicPanelPainter extends CustomPainter {
  const _FederationClassicPanelPainter({
    required this.surface,
    required this.signal,
    required this.secondary,
  });

  final Color surface;
  final Color signal;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final body = RRect.fromRectAndCorners(
      Offset.zero & size,
      topLeft: const Radius.circular(24),
      topRight: const Radius.circular(7),
      bottomRight: const Radius.circular(24),
      bottomLeft: const Radius.circular(7),
    );
    canvas.drawRRect(body, Paint()..color = surface);
    canvas.drawRRect(
      body,
      Paint()
        ..color = signal.withValues(alpha: .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, 12, size.height),
        topLeft: const Radius.circular(24),
        bottomRight: const Radius.circular(12),
      ),
      Paint()..color = signal,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(size.width * .68, size.height - 7, size.width * .32, 7),
        topLeft: const Radius.circular(7),
        bottomRight: const Radius.circular(24),
      ),
      Paint()..color = secondary,
    );
  }

  @override
  bool shouldRepaint(_FederationClassicPanelPainter oldDelegate) =>
      oldDelegate.surface != surface ||
      oldDelegate.signal != signal ||
      oldDelegate.secondary != secondary;
}
