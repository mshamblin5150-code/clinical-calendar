import 'package:flutter/material.dart';

import 'accessibility_tokens.dart';

/// Paints the Enhanced focus perimeter around whichever control owns primary
/// focus, including controls in routes, dialogs, and menus.
final class EnhancedGlobalFocusOverlay extends StatefulWidget {
  const EnhancedGlobalFocusOverlay({required this.child, super.key});

  final Widget child;

  @override
  State<EnhancedGlobalFocusOverlay> createState() =>
      _EnhancedGlobalFocusOverlayState();
}

final class _EnhancedGlobalFocusOverlayState
    extends State<EnhancedGlobalFocusOverlay>
    with WidgetsBindingObserver {
  final _stackKey = GlobalKey();
  Rect? _focusRect;
  bool _updateScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_scheduleUpdate);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_scheduleUpdate);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => _scheduleUpdate();

  void _scheduleUpdate() {
    if (_updateScheduled) return;
    _updateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScheduled = false;
      if (!mounted) return;
      final stack = _stackKey.currentContext?.findRenderObject();
      final target = FocusManager.instance.primaryFocus?.context
          ?.findRenderObject();
      Rect? nextRect;
      if (stack is RenderBox && target is RenderBox && target.attached) {
        try {
          nextRect =
              target.localToGlobal(Offset.zero, ancestor: stack) & target.size;
        } on Object {
          nextRect = null;
        }
      }
      if (_focusRect != nextRect) setState(() => _focusRect = nextRect);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(
      context,
    ).extension<ClinicalCalendarAccessibilityTokens>();
    _scheduleUpdate();
    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        _scheduleUpdate();
        return false;
      },
      child: Stack(
        key: _stackKey,
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          widget.child,
          if (tokens?.enhanced == true && _focusRect != null)
            Positioned.fromRect(
              rect: _focusRect!.inflate(tokens!.focusWidth),
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: CustomPaint(
                    key: const Key('enhanced-global-focus-perimeter'),
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
    final tokens = Theme.of(
      context,
    ).extension<ClinicalCalendarAccessibilityTokens>();
    if (tokens?.enhanced != true) return widget.child;
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
                    foregroundPainter: _DualToneFocusPainter(tokens!),
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
