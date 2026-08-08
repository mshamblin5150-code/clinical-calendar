import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  Rect? _contentClipRect;
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
      final focusContext = FocusManager.instance.primaryFocus?.context;
      final target = focusContext?.findRenderObject();
      Rect? nextRect;
      Rect? nextContentClipRect;
      if (stack is RenderBox && target is RenderBox && target.attached) {
        try {
          nextRect =
              target.localToGlobal(Offset.zero, ancestor: stack) & target.size;
          nextContentClipRect = _nearestClipRect(target, stack, nextRect);
        } on Object {
          nextRect = null;
          nextContentClipRect = null;
        }
      }
      if (_focusRect != nextRect || _contentClipRect != nextContentClipRect) {
        setState(() {
          _focusRect = nextRect;
          _contentClipRect = nextContentClipRect;
        });
      }
    });
  }

  Rect? _nearestClipRect(RenderBox target, RenderBox stack, Rect targetRect) {
    Rect? result;
    RenderObject? ancestor = target.parent;
    while (ancestor != null && ancestor != stack) {
      if (ancestor is RenderClipRect && ancestor.attached) {
        final rect =
            ancestor.localToGlobal(Offset.zero, ancestor: stack) &
            ancestor.size;
        if (rect.overlaps(targetRect) &&
            (result == null ||
                rect.width * rect.height < result.width * result.height)) {
          result = rect;
        }
      }
      ancestor = ancestor.parent;
    }
    return result;
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
              rect: _focusRect!
                  .inflate(tokens!.focusWidth)
                  .intersect(
                    _contentClipRect ??
                        (Offset.zero &
                            (_stackKey.currentContext!.findRenderObject()!
                                    as RenderBox)
                                .size),
                  ),
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
