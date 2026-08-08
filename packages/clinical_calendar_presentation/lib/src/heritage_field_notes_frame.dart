import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'graphite_frame.dart';

const heritageFieldNotesFrameAsset =
    'assets/heritage_field_notes_raster/panel-nine-slice-v1.png';
const heritageFieldNotesCalendarSafeInsets = EdgeInsets.fromLTRB(
  38,
  46,
  38,
  46,
);
const heritageFieldNotesPlacementsSafeInsets = EdgeInsets.fromLTRB(
  30,
  44,
  30,
  44,
);
const heritageFieldNotesPlanningSafeInsets = EdgeInsets.fromLTRB(
  34,
  46,
  34,
  42,
);
const heritageFieldNotesStatusSafeInsets = EdgeInsets.fromLTRB(30, 44, 34, 44);

/// Original Field Archive housing. Only the center and edge seams stretch.
final class HeritageFieldNotesNineSliceFrame extends StatefulWidget {
  const HeritageFieldNotesNineSliceFrame({
    required this.child,
    this.chromeInsets = const EdgeInsets.all(18),
    this.contentPadding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final EdgeInsets chromeInsets;
  final EdgeInsets contentPadding;

  @override
  State<HeritageFieldNotesNineSliceFrame> createState() =>
      _HeritageFieldNotesNineSliceFrameState();
}

final class _HeritageFieldNotesNineSliceFrameState
    extends State<HeritageFieldNotesNineSliceFrame> {
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
        themeId: 'heritage-field-notes',
        isGraphite: false,
      );
    },
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = const AssetImage(
      heritageFieldNotesFrameAsset,
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
        : _HeritageFieldNotesNineSlicePainter(
            image: _image!.image,
            destinationInsets: widget.chromeInsets,
          ),
    child: Padding(
      padding: widget.chromeInsets.add(widget.contentPadding),
      child: ClipRect(clipBehavior: Clip.hardEdge, child: widget.child),
    ),
  );
}

final class _HeritageFieldNotesNineSlicePainter extends CustomPainter {
  const _HeritageFieldNotesNineSlicePainter({
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
    covariant _HeritageFieldNotesNineSlicePainter oldDelegate,
  ) =>
      oldDelegate.image != image ||
      oldDelegate.destinationInsets != destinationInsets;
}
