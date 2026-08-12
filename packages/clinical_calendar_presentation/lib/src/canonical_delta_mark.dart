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
    super.key,
  });

  final double? size;
  final Color? color;
  final BlendMode colorBlendMode;
  final String? semanticLabel;
  final Key? imageKey;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) => Image.asset(
    canonicalDeltaMarkAsset,
    key: imageKey,
    package: 'clinical_calendar_presentation',
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
    color: color,
    colorBlendMode: colorBlendMode,
    semanticLabel: semanticLabel,
    errorBuilder: errorBuilder,
  );
}
