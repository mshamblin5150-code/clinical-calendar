import 'dart:ui' as ui;

import 'package:flutter/material.dart';

const _assetRoot = 'assets/variant_f_raster';
const _nineSlicePanelAsset = '$_assetRoot/panel-nine-slice-v2.png';

enum VariantFRasterHardware {
  cornerClamp,
  ventBank,
  recessedLatch,
  railCoupler,
  conduitElbow,
  bridgeBracket,
  ribbedHousing,
  mechanicalJoint,
}

enum VariantFRasterRail {
  horizontal,
  vertical,
  upperLeft,
  upperRight,
  lowerLeft,
  lowerRight,
  junction,
  separator,
}

enum VariantFRasterPanel { calendar, placements, planning, status }

/// Normalized visible bounds within the complete `panel-atlas.png` image.
///
/// The generated panel rasters cross the nominal 2x2 cell boundaries. Grid
/// slicing therefore cuts the wide frames and includes adjacent-frame pixels
/// in the narrow frames. These are the measured connected-alpha bounds for
/// each complete panel.
Rect variantFRasterPanelCrop(VariantFRasterPanel panel) => switch (panel) {
  VariantFRasterPanel.calendar => const Rect.fromLTRB(
    28 / 1254,
    62 / 1254,
    763 / 1254,
    590 / 1254,
  ),
  VariantFRasterPanel.placements => const Rect.fromLTRB(
    807 / 1254,
    32 / 1254,
    1204 / 1254,
    603 / 1254,
  ),
  VariantFRasterPanel.planning => const Rect.fromLTRB(
    39 / 1254,
    809 / 1254,
    754 / 1254,
    1166 / 1254,
  ),
  VariantFRasterPanel.status => const Rect.fromLTRB(
    792 / 1254,
    636 / 1254,
    1215 / 1254,
    1221 / 1254,
  ),
};

/// Marks content mounted inside a rendered housing so it does not repaint a
/// second opaque/vector panel over the raster chrome.
final class VariantFRasterPanelInterior extends InheritedWidget {
  const VariantFRasterPanelInterior({required super.child, super.key});

  static bool isActive(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<VariantFRasterPanelInterior>() !=
      null;

  @override
  bool updateShouldNotify(covariant VariantFRasterPanelInterior oldWidget) =>
      false;
}

/// High-resolution raster housing that preserves its corners and rails while
/// stretching only the dark interior seams.
final class VariantFNineSliceFrame extends StatefulWidget {
  const VariantFNineSliceFrame({
    required this.child,
    this.chromeInsets = const EdgeInsets.all(14),
    this.contentPadding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final EdgeInsets chromeInsets;
  final EdgeInsets contentPadding;

  @override
  State<VariantFNineSliceFrame> createState() => _VariantFNineSliceFrameState();
}

final class _VariantFNineSliceFrameState extends State<VariantFNineSliceFrame> {
  ImageStream? _stream;
  ImageInfo? _image;
  late final ImageStreamListener _listener = ImageStreamListener((image, _) {
    if (!mounted) return;
    setState(() => _image = image);
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = AssetImage(
      _nineSlicePanelAsset,
      package: 'clinical_calendar_presentation',
    ).resolve(createLocalImageConfiguration(context));
    if (next.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _image?.dispose();
    _image = null;
    _stream = next..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _image == null
        ? null
        : _NineSlicePanelPainter(
            image: _image!.image,
            destinationInsets: widget.chromeInsets,
          ),
    child: Padding(
      padding: widget.chromeInsets.add(widget.contentPadding),
      child: ClipRect(clipBehavior: Clip.hardEdge, child: widget.child),
    ),
  );
}

final class VariantFRasterHardwareSprite extends StatelessWidget {
  const VariantFRasterHardwareSprite({required this.part, super.key});

  final VariantFRasterHardware part;

  @override
  Widget build(BuildContext context) => _AtlasSprite(
    asset: '$_assetRoot/hardware-atlas.png',
    columns: 4,
    rows: 2,
    index: part.index,
  );
}

final class VariantFRasterRailSprite extends StatelessWidget {
  const VariantFRasterRailSprite({required this.part, super.key});

  final VariantFRasterRail part;

  @override
  Widget build(BuildContext context) => _AtlasSprite(
    asset: '$_assetRoot/rail-atlas.png',
    columns: 4,
    rows: 2,
    index: part.index,
  );
}

/// A rendered mechanical housing whose center remains available to live UI.
final class VariantFRasterPanelFrame extends StatelessWidget {
  const VariantFRasterPanelFrame({
    required this.panel,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    super.key,
  });

  final VariantFRasterPanel panel;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final minimum = switch (panel) {
      VariantFRasterPanel.calendar => const EdgeInsets.fromLTRB(38, 46, 38, 46),
      VariantFRasterPanel.placements => const EdgeInsets.fromLTRB(
        30,
        44,
        30,
        44,
      ),
      VariantFRasterPanel.planning => const EdgeInsets.fromLTRB(34, 46, 34, 42),
      VariantFRasterPanel.status => const EdgeInsets.fromLTRB(30, 44, 34, 44),
    };
    final safeInsets = EdgeInsets.fromLTRB(
      padding.left > minimum.left ? padding.left : minimum.left,
      padding.top > minimum.top ? padding.top : minimum.top,
      padding.right > minimum.right ? padding.right : minimum.right,
      padding.bottom > minimum.bottom ? padding.bottom : minimum.bottom,
    );
    return VariantFNineSliceFrame(
      chromeInsets: safeInsets,
      child: VariantFRasterPanelInterior(
        child: ClipRect(clipBehavior: Clip.hardEdge, child: child),
      ),
    );
  }
}

final class _NineSlicePanelPainter extends CustomPainter {
  const _NineSlicePanelPainter({
    required this.image,
    required this.destinationInsets,
  });

  final ui.Image image;
  final EdgeInsets destinationInsets;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    const sourceInsets = EdgeInsets.fromLTRB(120, 145, 120, 170);
    final horizontalScale =
        (size.width / (destinationInsets.left + destinationInsets.right)).clamp(
          0.0,
          1.0,
        );
    final verticalScale =
        (size.height / (destinationInsets.top + destinationInsets.bottom))
            .clamp(0.0, 1.0);
    final destination = EdgeInsets.fromLTRB(
      destinationInsets.left * horizontalScale,
      destinationInsets.top * verticalScale,
      destinationInsets.right * horizontalScale,
      destinationInsets.bottom * verticalScale,
    );
    final sourceX = <double>[
      0,
      sourceInsets.left,
      image.width - sourceInsets.right,
      image.width.toDouble(),
    ];
    final sourceY = <double>[
      0,
      sourceInsets.top,
      image.height - sourceInsets.bottom,
      image.height.toDouble(),
    ];
    final destinationX = <double>[
      0,
      destination.left,
      size.width - destination.right,
      size.width,
    ];
    final destinationY = <double>[
      0,
      destination.top,
      size.height - destination.bottom,
      size.height,
    ];
    final paint = Paint()..filterQuality = FilterQuality.high;
    for (var row = 0; row < 3; row++) {
      for (var column = 0; column < 3; column++) {
        canvas.drawImageRect(
          image,
          Rect.fromLTRB(
            sourceX[column],
            sourceY[row],
            sourceX[column + 1],
            sourceY[row + 1],
          ),
          Rect.fromLTRB(
            destinationX[column],
            destinationY[row],
            destinationX[column + 1],
            destinationY[row + 1],
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NineSlicePanelPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.destinationInsets != destinationInsets;
}

final class _AtlasSprite extends StatefulWidget {
  const _AtlasSprite({
    required this.asset,
    required this.columns,
    required this.rows,
    required this.index,
  });

  final String asset;
  final int columns;
  final int rows;
  final int index;

  @override
  State<_AtlasSprite> createState() => _AtlasSpriteState();
}

final class _AtlasSpriteState extends State<_AtlasSprite> {
  ImageStream? _stream;
  ImageInfo? _image;
  late final ImageStreamListener _listener = ImageStreamListener((image, _) {
    if (!mounted) return;
    setState(() => _image = image);
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _AtlasSprite oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset != widget.asset) _resolve();
  }

  void _resolve() {
    final next = AssetImage(
      widget.asset,
      package: 'clinical_calendar_presentation',
    ).resolve(createLocalImageConfiguration(context));
    if (next.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _image?.dispose();
    _image = null;
    _stream = next..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _image == null
        ? null
        : _AtlasSpritePainter(
            image: _image!.image,
            columns: widget.columns,
            rows: widget.rows,
            index: widget.index,
          ),
  );
}

final class _AtlasSpritePainter extends CustomPainter {
  const _AtlasSpritePainter({
    required this.image,
    required this.columns,
    required this.rows,
    required this.index,
  });

  final ui.Image image;
  final int columns;
  final int rows;
  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = image.width / columns;
    final cellHeight = image.height / rows;
    final source = Rect.fromLTWH(
      (index % columns) * cellWidth,
      (index ~/ columns) * cellHeight,
      cellWidth,
      cellHeight,
    );
    canvas.drawImageRect(
      image,
      source,
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(covariant _AtlasSpritePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.columns != columns ||
      oldDelegate.rows != rows ||
      oldDelegate.index != index;
}
