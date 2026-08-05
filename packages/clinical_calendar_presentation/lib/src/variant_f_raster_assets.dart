import 'dart:ui' as ui;

import 'package:flutter/material.dart';

const _assetRoot = 'assets/variant_f_raster';

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
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Positioned.fill(
        child: IgnorePointer(
          child: _AtlasSprite(
            asset: '$_assetRoot/panel-atlas.png',
            columns: 2,
            rows: 2,
            index: panel.index,
          ),
        ),
      ),
      Padding(
        padding: padding,
        child: VariantFRasterPanelInterior(child: child),
      ),
    ],
  );
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
    final column = index % columns;
    final row = index ~/ columns;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(
        column * cellWidth,
        row * cellHeight,
        cellWidth,
        cellHeight,
      ),
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
