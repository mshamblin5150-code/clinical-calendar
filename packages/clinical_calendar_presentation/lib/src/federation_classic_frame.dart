import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'graphite_frame.dart';

const federationClassicFrameAsset =
    'assets/federation_classic_raster/panel-nine-slice-v1.png';
const federationClassicCalendarSafeInsets = EdgeInsets.fromLTRB(38, 46, 38, 46);
const federationClassicPlacementsSafeInsets = EdgeInsets.fromLTRB(
  30,
  44,
  30,
  44,
);
const federationClassicPlanningSafeInsets = EdgeInsets.fromLTRB(34, 46, 34, 42);
const federationClassicStatusSafeInsets = EdgeInsets.fromLTRB(30, 44, 34, 44);

/// Original Federation Classic housing. Only center and edge seams stretch.
final class FederationClassicNineSliceFrame extends StatefulWidget {
  const FederationClassicNineSliceFrame({
    required this.child,
    this.chromeInsets = const EdgeInsets.all(18),
    this.contentPadding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final EdgeInsets chromeInsets;
  final EdgeInsets contentPadding;

  @override
  State<FederationClassicNineSliceFrame> createState() =>
      _FederationClassicNineSliceFrameState();
}

final class _FederationClassicNineSliceFrameState
    extends State<FederationClassicNineSliceFrame> {
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
        themeId: 'federation-classic',
        isGraphite: false,
      );
    },
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = const AssetImage(
      federationClassicFrameAsset,
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
        : _FederationClassicNineSlicePainter(
            image: _image!.image,
            destinationInsets: widget.chromeInsets,
          ),
    child: Padding(
      padding: widget.chromeInsets.add(widget.contentPadding),
      child: ClipRect(clipBehavior: Clip.hardEdge, child: widget.child),
    ),
  );
}

final class _FederationClassicNineSlicePainter extends CustomPainter {
  const _FederationClassicNineSlicePainter({
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
  bool shouldRepaint(
    covariant _FederationClassicNineSlicePainter oldDelegate,
  ) =>
      oldDelegate.image != image ||
      oldDelegate.destinationInsets != destinationInsets;
}
