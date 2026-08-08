import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'graphite_frame.dart';

const federation2399FrameAsset =
    'assets/federation_2399_raster/panel-nine-slice-v1.png';
const federation2399LandscapeChassisAsset =
    'assets/federation_2399_raster/dashboard-chassis-landscape-v1.png';
const federation2399CalendarSafeInsets = EdgeInsets.fromLTRB(38, 46, 38, 46);
const federation2399PlacementsSafeInsets = EdgeInsets.fromLTRB(30, 44, 30, 44);
const federation2399PlanningSafeInsets = EdgeInsets.fromLTRB(34, 46, 34, 42);
const federation2399StatusSafeInsets = EdgeInsets.fromLTRB(30, 44, 34, 44);

/// Fixed golden-exemplar chassis derived from the approved issue #114
/// composition. The raster contains decoration only; [child] owns all live
/// content, semantics, focus, and callbacks.
final class Federation2399LandscapeChassis extends StatelessWidget {
  const Federation2399LandscapeChassis({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ExcludeSemantics(
        child: Image.asset(
          federation2399LandscapeChassisAsset,
          package: 'clinical_calendar_presentation',
          fit: BoxFit.fill,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            GraphitePresentationFailureBoundary.report(
              context,
              error,
              themeId: 'federation-2399',
              isGraphite: false,
            );
            return const ColoredBox(color: Color(0xFF07080D));
          },
        ),
      ),
      child,
    ],
  );
}

/// Original Federation 2399 housing. Only center and edge seams stretch.
final class Federation2399NineSliceFrame extends StatefulWidget {
  const Federation2399NineSliceFrame({
    required this.child,
    this.chromeInsets = const EdgeInsets.all(18),
    this.contentPadding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final EdgeInsets chromeInsets;
  final EdgeInsets contentPadding;

  @override
  State<Federation2399NineSliceFrame> createState() =>
      _Federation2399NineSliceFrameState();
}

final class _Federation2399NineSliceFrameState
    extends State<Federation2399NineSliceFrame> {
  ImageStream? _stream;
  ImageInfo? _image;
  late final ImageStreamListener _listener = ImageStreamListener(
    (image, _) {
      if (mounted) setState(() => _image = image);
    },
    onError: (Object error, StackTrace? stackTrace) {
      if (!mounted) return;
      GraphitePresentationFailureBoundary.report(
        context,
        error,
        themeId: 'federation-2399',
        isGraphite: false,
      );
    },
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = const AssetImage(
      federation2399FrameAsset,
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
        : _Federation2399NineSlicePainter(
            image: _image!.image,
            destinationInsets: widget.chromeInsets,
          ),
    child: Padding(
      padding: widget.chromeInsets.add(widget.contentPadding),
      child: ClipRect(clipBehavior: Clip.hardEdge, child: widget.child),
    ),
  );
}

final class _Federation2399NineSlicePainter extends CustomPainter {
  const _Federation2399NineSlicePainter({
    required this.image,
    required this.destinationInsets,
  });

  final ui.Image image;
  final EdgeInsets destinationInsets;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    const source = EdgeInsets.fromLTRB(120, 145, 120, 170);
    final xScale =
        (size.width / (destinationInsets.left + destinationInsets.right)).clamp(
          0.0,
          1.0,
        );
    final yScale =
        (size.height / (destinationInsets.top + destinationInsets.bottom))
            .clamp(0.0, 1.0);
    final destination = EdgeInsets.fromLTRB(
      destinationInsets.left * xScale,
      destinationInsets.top * yScale,
      destinationInsets.right * xScale,
      destinationInsets.bottom * yScale,
    );
    final sourceX = [
      0.0,
      source.left,
      image.width - source.right,
      image.width.toDouble(),
    ];
    final sourceY = [
      0.0,
      source.top,
      image.height - source.bottom,
      image.height.toDouble(),
    ];
    final destinationX = [
      0.0,
      destination.left,
      size.width - destination.right,
      size.width,
    ];
    final destinationY = [
      0.0,
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
  bool shouldRepaint(covariant _Federation2399NineSlicePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.destinationInsets != destinationInsets;
}
