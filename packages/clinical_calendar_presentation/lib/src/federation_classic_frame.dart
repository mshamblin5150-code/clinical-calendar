import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'graphite_frame.dart';

const federationClassicFrameAsset =
    'assets/federation_classic_raster/panel-nine-slice-v1.png';
const federationClassicRailNineSliceAsset =
    'assets/federation_classic_raster/lcars-rail-nine-slice-v1.png';
const federationClassicCalendarSafeInsets = EdgeInsets.fromLTRB(38, 46, 38, 46);
const federationClassicPlacementsSafeInsets = EdgeInsets.fromLTRB(
  30,
  44,
  30,
  44,
);
const federationClassicPlanningSafeInsets = EdgeInsets.fromLTRB(34, 46, 34, 42);
const federationClassicStatusSafeInsets = EdgeInsets.fromLTRB(30, 44, 34, 44);

/// Piecewise golden-exemplar chassis measured from the approved issue #113
/// composition. It renders the major rails as independent nine-slice raster
/// pieces instead of stretching a complete dashboard bitmap.
final class FederationClassicLandscapeChassis extends StatelessWidget {
  const FederationClassicLandscapeChassis({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const CustomPaint(painter: _FederationClassicLandscapePainter()),
      const FederationClassicRasterRails(),
      const CustomPaint(painter: _FederationClassicLandscapeCutoutPainter()),
      child,
    ],
  );
}

final class FederationClassicLandscapeGeometry {
  const FederationClassicLandscapeGeometry._();

  static const exemplar = Size(1586, 992);
  static const crown = Rect.fromLTWH(194, 39, 1374, 57);
  static const placements = Rect.fromLTWH(90, 112, 306, 702);
  static const calendar = Rect.fromLTWH(406, 112, 736, 473);
  static const planning = Rect.fromLTWH(406, 591, 736, 276);
  static const insight = Rect.fromLTWH(1162, 112, 367, 702);
  static const navigation = Rect.fromLTWH(10, 887, 1566, 97);

  static Rect scale(Rect rect, Size size) => Rect.fromLTWH(
    rect.left * size.width / exemplar.width,
    rect.top * size.height / exemplar.height,
    rect.width * size.width / exemplar.width,
    rect.height * size.height / exemplar.height,
  );
}

/// Loads one neutral rail material and renders each chassis rail separately
/// with [Canvas.drawImageNine]. Only the center and edge seams stretch.
final class FederationClassicRasterRails extends StatefulWidget {
  const FederationClassicRasterRails({super.key});

  static const centerSlice = Rect.fromLTRB(64, 64, 448, 448);

  @override
  State<FederationClassicRasterRails> createState() =>
      _FederationClassicRasterRailsState();
}

final class _FederationClassicRasterRailsState
    extends State<FederationClassicRasterRails> {
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
      federationClassicRailNineSliceAsset,
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
        : _FederationClassicRasterRailsPainter(_image!.image),
  );
}

final class _FederationClassicRasterRailsPainter extends CustomPainter {
  const _FederationClassicRasterRailsPainter(this.image);

  final ui.Image image;

  static const _rails = <(Rect, Color)>[
    (Rect.fromLTWH(10, 39, 145, 164), Color(0xFFAF8ED6)),
    (Rect.fromLTWH(474, 53, 629, 42), Color(0xFFAF8ED6)),
    (Rect.fromLTWH(1306, 53, 262, 42), Color(0xFFF5AE25)),
    (Rect.fromLTWH(10, 732, 186, 141), Color(0xFFFF8057)),
    (Rect.fromLTWH(1376, 830, 201, 40), Color(0xFFFF8057)),
    (Rect.fromLTWH(18, 895, 155, 74), Color(0xFF65448C)),
    (Rect.fromLTWH(18, 936, 45, 40), Color(0xFF65448C)),
    (Rect.fromLTWH(1385, 895, 183, 74), Color(0xFFFF8057)),
    (Rect.fromLTWH(1520, 936, 39, 40), Color(0xFFFF8057)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final (conceptRect, color) in _rails) {
      final destination = FederationClassicLandscapeGeometry.scale(
        conceptRect,
        size,
      );
      canvas.save();
      canvas.clipRRect(
        RRect.fromRectAndRadius(
          destination,
          Radius.circular(48 * size.width / 1586),
        ),
      );
      canvas.drawImageNine(
        image,
        FederationClassicRasterRails.centerSlice,
        destination,
        Paint()
          ..colorFilter = ColorFilter.mode(color, BlendMode.modulate)
          ..filterQuality = FilterQuality.high,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FederationClassicRasterRailsPainter oldDelegate) =>
      oldDelegate.image != image;
}

final class _FederationClassicLandscapePainter extends CustomPainter {
  const _FederationClassicLandscapePainter();

  static const _canvas = Color(0xFF02040D);
  static const _lilac = Color(0xFFAF8ED6);
  static const _lilacDark = Color(0xFF65448C);
  static const _salmon = Color(0xFFFF8057);
  static const _amber = Color(0xFFF5AE25);
  static const _outline = Color(0xFF3A3148);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / 1586, size.height / 992);
    final upperElbow = Path()
      ..moveTo(58, 39)
      ..lineTo(155, 39)
      ..lineTo(155, 105)
      ..lineTo(90, 105)
      ..lineTo(90, 203)
      ..lineTo(10, 203)
      ..lineTo(10, 87)
      ..cubicTo(10, 61, 31, 39, 58, 39)
      ..close();
    canvas.drawPath(upperElbow, Paint()..color = _lilac);
    canvas.drawRect(
      const Rect.fromLTWH(155, 39, 12, 66),
      Paint()..color = _lilac,
    );
    _rectSegments(canvas, const [
      (Rect.fromLTWH(10, 211, 79, 88), _lilacDark),
      (Rect.fromLTWH(10, 306, 79, 54), _salmon),
      (Rect.fromLTWH(10, 362, 79, 57), _salmon),
      (Rect.fromLTWH(10, 421, 79, 110), _salmon),
      (Rect.fromLTWH(10, 534, 79, 188), _amber),
      (Rect.fromLTWH(10, 732, 79, 120), Color(0xFFD56843)),
    ]);
    final lowerElbow = Path()
      ..moveTo(10, 732)
      ..lineTo(89, 732)
      ..lineTo(89, 785)
      ..quadraticBezierTo(89, 813, 117, 813)
      ..lineTo(150, 813)
      ..quadraticBezierTo(196, 813, 196, 859)
      ..lineTo(196, 873)
      ..lineTo(58, 873)
      ..quadraticBezierTo(10, 873, 10, 825)
      ..close();
    canvas.drawPath(lowerElbow, Paint()..color = _salmon);
    canvas.drawRect(
      const Rect.fromLTWH(137, 813, 59, 60),
      Paint()..color = _amber,
    );

    _rounded(canvas, const Rect.fromLTWH(474, 53, 629, 42), _lilac, 22);
    canvas.drawRect(
      const Rect.fromLTWH(1080, 53, 23, 42),
      Paint()..color = _lilac,
    );
    canvas.drawRect(
      const Rect.fromLTWH(1107, 53, 195, 25),
      Paint()..color = _lilacDark,
    );
    canvas.drawRect(
      const Rect.fromLTWH(1107, 82, 195, 13),
      Paint()..color = _lilacDark,
    );
    _rounded(canvas, const Rect.fromLTWH(1306, 53, 262, 42), _amber, 22);

    _panel(canvas, FederationClassicLandscapeGeometry.placements);
    _panel(canvas, FederationClassicLandscapeGeometry.calendar);
    _panel(canvas, FederationClassicLandscapeGeometry.planning);
    _panel(canvas, FederationClassicLandscapeGeometry.insight);

    _rectSegments(canvas, const [
      (Rect.fromLTWH(1545, 350, 32, 82), _salmon),
      (Rect.fromLTWH(1545, 438, 32, 315), _lilac),
      (Rect.fromLTWH(1545, 758, 32, 17), _amber),
      (Rect.fromLTWH(1545, 780, 32, 90), _salmon),
    ]);
    _rounded(canvas, const Rect.fromLTWH(1376, 830, 201, 40), _salmon, 22);
    canvas.drawRect(
      const Rect.fromLTWH(1441, 830, 5, 40),
      Paint()..color = _canvas,
    );

    final nav = RRect.fromRectAndRadius(
      const Rect.fromLTWH(10, 887, 1566, 97),
      const Radius.circular(46),
    );
    canvas.drawRRect(
      nav,
      Paint()
        ..color = _amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    _rounded(canvas, const Rect.fromLTWH(18, 895, 155, 74), _lilacDark, 37);
    _rounded(canvas, const Rect.fromLTWH(18, 936, 45, 40), _lilacDark, 20);
    _rounded(canvas, const Rect.fromLTWH(1385, 895, 183, 74), _salmon, 37);
    _rounded(canvas, const Rect.fromLTWH(1520, 936, 39, 40), _salmon, 20);
    canvas.restore();
  }

  void _panel(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()
        ..color = _outline.withValues(alpha: .78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _rectSegments(Canvas canvas, List<(Rect, Color)> segments) {
    for (final (rect, color) in segments) {
      canvas.drawRect(rect, Paint()..color = color);
    }
  }

  void _rounded(Canvas canvas, Rect rect, Color color, double radius) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

final class _FederationClassicLandscapeCutoutPainter extends CustomPainter {
  const _FederationClassicLandscapeCutoutPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / 1586, size.height / 992);
    final cutout = Paint()..color = const Color(0xFF02040D);
    canvas.drawRect(const Rect.fromLTWH(90, 105, 65, 98), cutout);
    canvas.drawRect(const Rect.fromLTWH(90, 732, 47, 81), cutout);
    canvas.drawRect(const Rect.fromLTWH(1441, 830, 5, 40), cutout);
    canvas.drawRect(const Rect.fromLTWH(63, 936, 8, 33), cutout);
    canvas.drawRect(const Rect.fromLTWH(1520, 936, 18, 33), cutout);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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
