import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const canonicalDeltaMarkAsset = 'assets/shared_brand/axion-delta-mark.png';

/// The single raster source for the Axion delta used by concept themes.
///
/// Theme shells own this widget's size, placement, semantics, and optional
/// color treatment. Containment Drone 47-Alpha does not use this mark.
final class CanonicalDeltaMark extends StatelessWidget {
  const CanonicalDeltaMark({
    this.size,
    this.color,
    this.colorBlendMode = BlendMode.srcIn,
    this.semanticLabel,
    this.imageKey,
    this.errorBuilder,
    this.resizeForRuntime = !kDebugMode,
    super.key,
  });

  final double? size;
  final Color? color;
  final BlendMode colorBlendMode;
  final String? semanticLabel;
  final Key? imageKey;
  final ImageErrorWidgetBuilder? errorBuilder;
  @visibleForTesting
  final bool resizeForRuntime;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final logicalWidth =
          size ?? (constraints.hasBoundedWidth ? constraints.maxWidth : null);
      final cacheWidth =
          resizeForRuntime &&
              logicalWidth != null &&
              logicalWidth.isFinite &&
              logicalWidth > 0
          ? (logicalWidth * MediaQuery.devicePixelRatioOf(context)).ceil()
          : null;
      return Image.asset(
        canonicalDeltaMarkAsset,
        key: imageKey,
        package: 'clinical_calendar_presentation',
        width: size,
        height: size,
        cacheWidth: cacheWidth,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        color: color,
        colorBlendMode: colorBlendMode,
        semanticLabel: semanticLabel,
        errorBuilder: errorBuilder,
      );
    },
  );
}
