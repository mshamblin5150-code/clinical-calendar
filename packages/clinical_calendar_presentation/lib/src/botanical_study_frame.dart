import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'graphite_frame.dart';
import 'variant_f_theme.dart';

const botanicalStudyFrameAsset =
    'assets/botanical_study_raster/panel-nine-slice-v1.png';
const botanicalStudyLandscapeChassisAsset =
    'assets/botanical_study_raster/dashboard-chassis-landscape-v2.png';
const botanicalStudyCalendarSafeInsets = EdgeInsets.fromLTRB(38, 46, 38, 46);
const botanicalStudyPlacementsSafeInsets = EdgeInsets.fromLTRB(30, 44, 30, 44);
const botanicalStudyPlanningSafeInsets = EdgeInsets.fromLTRB(34, 46, 34, 42);
const botanicalStudyStatusSafeInsets = EdgeInsets.fromLTRB(30, 44, 34, 44);

/// Original Botanical Study housing. Only center and edge seams stretch.
final class BotanicalStudyNineSliceFrame extends StatefulWidget {
  const BotanicalStudyNineSliceFrame({
    required this.child,
    this.chromeInsets = const EdgeInsets.all(18),
    this.contentPadding = EdgeInsets.zero,
    super.key,
  });

  final Widget child;
  final EdgeInsets chromeInsets;
  final EdgeInsets contentPadding;

  @override
  State<BotanicalStudyNineSliceFrame> createState() =>
      _BotanicalStudyNineSliceFrameState();
}

/// Fixed 1586 x 992 chassis derived from the approved issue #115 concept.
/// The raster contains decoration only; [child] owns live content and meaning.
final class BotanicalStudyLandscapeChassis extends StatelessWidget {
  const BotanicalStudyLandscapeChassis({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (context.accessibilityTokens.decorationOpacity == 0) {
      return ColoredBox(
        key: const Key('botanical-study-enhanced-flat-chassis'),
        color: context.clinicalColors.canvas,
        child: child,
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          child: Image.asset(
            botanicalStudyLandscapeChassisAsset,
            package: 'clinical_calendar_presentation',
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              GraphitePresentationFailureBoundary.report(
                context,
                error,
                themeId: 'botanical-study',
                isGraphite: false,
              );
              return const ColoredBox(color: Color(0xFFFFFDF8));
            },
          ),
        ),
        child,
      ],
    );
  }
}

final class _BotanicalStudyNineSliceFrameState
    extends State<BotanicalStudyNineSliceFrame> {
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
        themeId: 'botanical-study',
        isGraphite: false,
      );
    },
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = const AssetImage(
      botanicalStudyFrameAsset,
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
        : _BotanicalStudyNineSlicePainter(
            image: _image!.image,
            destinationInsets: widget.chromeInsets,
            opacity: context.accessibilityTokens.decorationOpacity,
          ),
    child: Padding(
      padding: widget.chromeInsets.add(widget.contentPadding),
      child: ClipRect(clipBehavior: Clip.hardEdge, child: widget.child),
    ),
  );
}

final class _BotanicalStudyNineSlicePainter extends CustomPainter {
  const _BotanicalStudyNineSlicePainter({
    required this.image,
    required this.destinationInsets,
    required this.opacity,
  });

  final ui.Image image;
  final EdgeInsets destinationInsets;
  final double opacity;

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
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..color = Colors.white.withValues(alpha: opacity);
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
  bool shouldRepaint(covariant _BotanicalStudyNineSlicePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.destinationInsets != destinationInsets ||
      oldDelegate.opacity != opacity;
}
