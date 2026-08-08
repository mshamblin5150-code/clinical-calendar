import 'package:flutter/material.dart';

import 'variant_f_theme.dart';

/// Adds the Enhanced dual-tone focus perimeter without changing child layout.
final class EnhancedFocusPerimeter extends StatefulWidget {
  const EnhancedFocusPerimeter({required this.child, super.key});

  final Widget child;

  @override
  State<EnhancedFocusPerimeter> createState() => _EnhancedFocusPerimeterState();
}

final class _EnhancedFocusPerimeterState extends State<EnhancedFocusPerimeter> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.accessibilityTokens;
    if (!tokens.enhanced) return widget.child;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) {
        if (_focused != focused) setState(() => _focused = focused);
      },
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          if (_focused)
            Positioned.fill(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    key: const Key('enhanced-dual-tone-focus-perimeter'),
                    foregroundPainter: _DualToneFocusPainter(tokens),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _DualToneFocusPainter extends CustomPainter {
  const _DualToneFocusPainter(this.tokens);

  final ClinicalCalendarAccessibilityTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect.deflate(tokens.focusWidth / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = tokens.focusWidth
        ..color = tokens.focusOuterColor,
    );
    canvas.drawRect(
      rect.deflate(tokens.focusWidth + .5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = tokens.focusInnerColor,
    );
  }

  @override
  bool shouldRepaint(_DualToneFocusPainter oldDelegate) =>
      oldDelegate.tokens != tokens;
}
