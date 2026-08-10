import 'package:flutter/material.dart';

import 'additive_theme_shell.dart';
import 'calendar/calendar_period_view.dart';
import 'canonical_delta_mark.dart';
import 'graphite_frame.dart';
import 'graphite_instrument_scope.dart';
import 'responsive_shell.dart';
import 'variant_f_theme.dart';

Widget _buildGraphiteFrame(
  Widget child,
  EdgeInsets chromeInsets,
  EdgeInsets contentPadding,
) => GraphiteNineSliceFrame(
  chromeInsets: chromeInsets,
  contentPadding: contentPadding,
  child: child,
);

final class GraphiteDestinationSurface extends StatelessWidget {
  const GraphiteDestinationSurface({
    required this.destination,
    required this.entry,
    required this.onExit,
    required this.child,
    super.key,
  });

  final ClinicalCalendarDestination destination;
  final DestinationEntry entry;
  final VoidCallback onExit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final enlargedText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Scaffold(
      key: const Key('graphite-destination-shell'),
      backgroundColor: const Color(0xFF090B0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _GraphiteDestinationCrown(
                destination: destination,
                entry: entry,
                onExit: onExit,
                enlargedText: enlargedText,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _GraphiteDestinationBay(
                  destination: destination,
                  enlargedText: enlargedText,
                  child: KeyedSubtree(
                    key: const Key('graphite-destination-scroll'),
                    child: AdditiveThemePanelInterior(child: child),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _GraphiteDestinationCrown extends StatelessWidget {
  const _GraphiteDestinationCrown({
    required this.destination,
    required this.entry,
    required this.onExit,
    required this.enlargedText,
  });

  final ClinicalCalendarDestination destination;
  final DestinationEntry entry;
  final VoidCallback onExit;
  final bool enlargedText;

  @override
  Widget build(BuildContext context) {
    final enteredFromMenu = entry == DestinationEntry.applicationMenu;
    return Container(
      key: const Key('graphite-destination-crown'),
      constraints: BoxConstraints(minHeight: enlargedText ? 106 : 76),
      padding: EdgeInsets.symmetric(
        horizontal: enlargedText ? 12 : 18,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _GraphiteChrome.raisedSurface,
        border: Border.all(color: _GraphiteChrome.decorativeBoundary),
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          TextButton.icon(
            key: Key(enteredFromMenu ? 'back-action' : 'close-action'),
            onPressed: onExit,
            icon: Icon(enteredFromMenu ? Icons.arrow_back : Icons.close),
            label: Text(enteredFromMenu ? 'Back' : 'Close'),
          ),
          SizedBox(width: enlargedText ? 8 : 18),
          Container(
            width: 3,
            height: enlargedText ? 54 : 38,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.label,
                  maxLines: 2,
                  overflow: TextOverflow.clip,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!enlargedText)
                  Text(
                    'GRAPHITE  /  ${destination.name.toUpperCase()}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.clinicalColors.secondaryText,
                      letterSpacing: 1.4,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox.square(
            dimension: enlargedText ? 42 : 48,
            child: Semantics(
              label: 'Graphite calendar mark',
              image: true,
              child: const ExcludeSemantics(child: CanonicalDeltaMark()),
            ),
          ),
          const SizedBox(width: 10),
          const _GraphiteGridIcon(key: Key('graphite-destination-grid')),
        ],
      ),
    );
  }
}

final class _GraphiteDestinationBay extends StatelessWidget {
  const _GraphiteDestinationBay({
    required this.destination,
    required this.enlargedText,
    required this.child,
  });

  final ClinicalCalendarDestination destination;
  final bool enlargedText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final accent = switch (destination) {
      ClinicalCalendarDestination.notifications =>
        context.clinicalColors.urgent,
      ClinicalCalendarDestination.clinicalPlacements =>
        context.clinicalColors.clinical,
      ClinicalCalendarDestination.synchronization => Theme.of(
        context,
      ).colorScheme.primary,
      _ => context.clinicalColors.insetBorder,
    };
    return CustomPaint(
      key: const Key('graphite-destination-bay'),
      painter: _GraphiteDestinationMachineryPainter(accent: accent),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          enlargedText ? 14 : 24,
          enlargedText ? 18 : 26,
          enlargedText ? 14 : 24,
          enlargedText ? 14 : 22,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _GraphiteChrome.contentSurface,
            border: Border(
              left: BorderSide(color: accent, width: 3),
              top: BorderSide(color: _GraphiteChrome.decorativeBoundary),
              right: BorderSide(color: _GraphiteChrome.decorativeBoundary),
              bottom: BorderSide(color: _GraphiteChrome.decorativeBoundary),
            ),
          ),
          child: ClipRect(child: child),
        ),
      ),
    );
  }
}

final class _GraphiteDestinationMachineryPainter extends CustomPainter {
  const _GraphiteDestinationMachineryPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFF0D1114);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)),
      background,
    );

    final grid = Paint()
      ..color = const Color(0xFF69737A).withValues(alpha: .12)
      ..strokeWidth = 1;
    const spacing = 22.0;
    for (double x = 12; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, 18), grid);
      canvas.drawLine(
        Offset(x, size.height - 14),
        Offset(x, size.height),
        grid,
      );
    }

    final rail = Paint()
      ..color = const Color(0xFF7A858C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final railRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(.5, .5, size.width - 1, size.height - 1),
      const Radius.circular(10),
    );
    canvas.drawRRect(railRect, rail);

    final signal = Paint()
      ..color = accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(32, 2), const Offset(92, 2), signal);
    canvas.drawLine(
      Offset(size.width - 92, size.height - 2),
      Offset(size.width - 32, size.height - 2),
      signal,
    );
  }

  @override
  bool shouldRepaint(_GraphiteDestinationMachineryPainter oldDelegate) =>
      accent != oldDelegate.accent;
}

final class GraphiteApplicationShell extends StatelessWidget {
  const GraphiteApplicationShell({
    required this.slots,
    required this.environmentName,
    required this.onOpenMenu,
    required this.onOpenDestination,
    required this.onOpenAttention,
    required this.onAddSchedule,
    this.mobileIndex = 1,
    super.key,
  });

  final ResponsiveShellSlots slots;
  final String environmentName;
  final VoidCallback onOpenMenu;
  final ValueChanged<ClinicalCalendarDestination> onOpenDestination;
  final VoidCallback onOpenAttention;
  final VoidCallback onAddSchedule;
  final int mobileIndex;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final landscapeTablet =
          constraints.maxWidth >= 960 &&
          constraints.maxHeight >= 600 &&
          constraints.maxWidth > constraints.maxHeight;
      final portraitTablet =
          constraints.maxWidth >= 600 &&
          constraints.maxHeight >= 900 &&
          constraints.maxHeight >= constraints.maxWidth;
      if (landscapeTablet) return _landscape();
      if (portraitTablet) return _portrait();
      return _compact();
    },
  );

  Widget _landscape() => Scaffold(
    key: const Key('graphite-landscape-shell'),
    backgroundColor: const Color(0xFF090B0D),
    body: GraphiteNineSliceFrame(
      chromeInsets: const EdgeInsets.all(5),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFF101417),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF15191C), Color(0xFF0E1215)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  width: width,
                  height: height * .077,
                  child: _GraphiteCommandCrown(
                    environmentName: environmentName,
                    onOpenMenu: onOpenMenu,
                    onAddSchedule: onAddSchedule,
                    onOpenDestination: onOpenDestination,
                    profileAvatar: slots.profileAvatar,
                  ),
                ),
                Positioned(
                  left: 0,
                  top: height * .085,
                  width: width * .192,
                  height: height * .82,
                  child: _GraphitePlacementHousing(
                    child: GraphiteInstrumentScope(child: slots.placementDock),
                  ),
                ),
                Positioned(
                  left: width * .198,
                  top: height * .085,
                  width: width * .553,
                  height: height * .553,
                  child: _GraphiteInstrumentBay(
                    key: const Key('graphite-calendar-bay'),
                    safeInsets: graphiteCalendarSafeInsets,
                    accent: _GraphiteAccent.silver,
                    integrated: true,
                    integratedPadding: EdgeInsets.zero,
                    child: _GraphiteCalendarViewport(
                      child: slots.centralContent,
                    ),
                  ),
                ),
                Positioned(
                  left: width * .198,
                  top: height * .647,
                  width: width * .553,
                  height: height * .258,
                  child: _GraphiteInstrumentBay(
                    key: const Key('graphite-planning-bay'),
                    safeInsets: graphitePlanningSafeInsets,
                    accent: _GraphiteAccent.emerald,
                    integrated: true,
                    child: VariantFPlanningBayMode(
                      expandedByDefault: true,
                      child: slots.planningRegion,
                    ),
                  ),
                ),
                Positioned(
                  left: width * .757,
                  top: height * .085,
                  width: width * .243,
                  height: height * .82,
                  child: _GraphiteInstrumentBay(
                    key: const Key('graphite-insight-bay'),
                    safeInsets: graphiteStatusSafeInsets,
                    accent: _GraphiteAccent.coral,
                    integrated: true,
                    child: GraphiteInstrumentScope(child: slots.insightRail),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: height * .914,
                  width: width,
                  height: height * .086,
                  child: _GraphiteNavigationRail(
                    selectedIndex: mobileIndex,
                    onOpenDestination: onOpenDestination,
                    onOpenAttention: onOpenAttention,
                  ),
                ),
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      key: Key('graphite-landscape-rails'),
                      foregroundPainter: _GraphiteLandscapeRailsPainter(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _portrait() => Scaffold(
    key: const Key('graphite-portrait-shell'),
    backgroundColor: const Color(0xFF090B0D),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            _GraphiteCommandCrown(
              environmentName: environmentName,
              onOpenMenu: onOpenMenu,
              onAddSchedule: onAddSchedule,
              onOpenDestination: onOpenDestination,
              profileAvatar: slots.profileAvatar,
              compact: true,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final enlargedText =
                      MediaQuery.textScalerOf(context).scale(1) > 1.3;
                  return SingleChildScrollView(
                    key: const Key('graphite-portrait-scroll'),
                    primary: true,
                    child: SizedBox(
                      height: constraints.maxHeight * (enlargedText ? 4 : 2.5),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 8,
                            child: _GraphiteInstrumentBay(
                              key: const Key('graphite-calendar-bay'),
                              safeInsets: graphiteCalendarSafeInsets,
                              accent: _GraphiteAccent.silver,
                              child: _GraphiteCalendarViewport(
                                scrollAtEnlargedText: true,
                                child: slots.centralContent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            flex: 5,
                            child: _GraphiteInstrumentBay(
                              key: const Key('graphite-planning-bay'),
                              safeInsets: graphitePlanningSafeInsets,
                              accent: _GraphiteAccent.emerald,
                              child: VariantFPlanningBayMode(
                                expandedByDefault: false,
                                child: slots.planningRegion,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            flex: 7,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _GraphitePlacementHousing(
                                    child: GraphiteInstrumentScope(
                                      child: slots.mobilePlacementSummary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _GraphiteInstrumentBay(
                                    key: const Key('graphite-insight-bay'),
                                    safeInsets: graphiteStatusSafeInsets,
                                    accent: _GraphiteAccent.coral,
                                    child: GraphiteInstrumentScope(
                                      child: slots.mobileAttention,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            _GraphiteNavigationRail(
              selectedIndex: mobileIndex,
              onOpenDestination: onOpenDestination,
              onOpenAttention: onOpenAttention,
              compact: true,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _compact() => AdditiveThemeApplicationShell(
    key: const Key('graphite-compact-shell'),
    slots: slots,
    environmentName: environmentName,
    onOpenMenu: onOpenMenu,
    onOpenDestination: onOpenDestination,
    onOpenAttention: onOpenAttention,
    onAddSchedule: onAddSchedule,
    mobileIndex: mobileIndex,
    frameBuilder: _buildGraphiteFrame,
    calendarSafeInsets: graphiteCalendarSafeInsets,
    placementsSafeInsets: graphitePlacementsSafeInsets,
    planningSafeInsets: graphitePlanningSafeInsets,
    statusSafeInsets: graphiteStatusSafeInsets,
  );
}

enum _GraphiteAccent { silver, emerald, coral }

/// Dedicated Graphite machinery for the live placements slot.
///
/// This deliberately does not share the generic instrument-bay or nine-slice
/// frame used by the other landing regions. The placement workflow stays live
/// and shared; only its Graphite housing is owned here.
final class _GraphitePlacementHousing extends StatelessWidget {
  const _GraphitePlacementHousing({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    key: const Key('graphite-placement-housing'),
    painter: _GraphitePlacementHousingPainter(
      signal: context.clinicalColors.clinical,
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 14, 16),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: _GraphiteChrome.contentSurface),
        child: ClipRect(child: child),
      ),
    ),
  );
}

final class _GraphitePlacementHousingPainter extends CustomPainter {
  const _GraphitePlacementHousingPainter({required this.signal});

  final Color signal;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(8)),
      Paint()..color = const Color(0xFF0D1114),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds.deflate(.5), const Radius.circular(8)),
      Paint()
        ..color = _GraphiteChrome.decorativeBoundary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final rail = Paint()
      ..color = signal
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(const Offset(9, 26), Offset(9, size.height - 18), rail);
    canvas.drawLine(const Offset(9, 14), const Offset(9, 18), rail);

    final machinery = Paint()
      ..color = const Color(0xFF8C969C)
      ..strokeWidth = 1;
    canvas.drawLine(
      const Offset(20, 10),
      Offset(size.width - 52, 10),
      machinery,
    );
    for (var index = 0; index < 3; index++) {
      canvas.drawRect(
        Rect.fromLTWH(size.width - 40 + index * 9, 7, 5, 5),
        Paint()..color = index == 2 ? signal : const Color(0xFF596167),
      );
    }
  }

  @override
  bool shouldRepaint(_GraphitePlacementHousingPainter oldDelegate) =>
      signal != oldDelegate.signal;
}

final class _GraphiteLandscapeRailsPainter extends CustomPainter {
  const _GraphiteLandscapeRailsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rails = <Rect>[
      Rect.fromLTWH(0, 0, size.width, size.height * .077),
      Rect.fromLTWH(
        0,
        size.height * .085,
        size.width * .192,
        size.height * .82,
      ),
      Rect.fromLTWH(
        size.width * .198,
        size.height * .085,
        size.width * .553,
        size.height * .553,
      ),
      Rect.fromLTWH(
        size.width * .198,
        size.height * .647,
        size.width * .553,
        size.height * .258,
      ),
      Rect.fromLTWH(
        size.width * .757,
        size.height * .085,
        size.width * .243,
        size.height * .475,
      ),
      Rect.fromLTWH(
        size.width * .757,
        size.height * .569,
        size.width * .243,
        size.height * .336,
      ),
      Rect.fromLTWH(0, size.height * .914, size.width, size.height * .086),
    ];
    for (final rect in rails) {
      _paintRail(canvas, rect);
    }
  }

  void _paintRail(Canvas canvas, Rect bounds) {
    final outer = RRect.fromRectAndRadius(
      bounds.deflate(.5),
      const Radius.circular(8),
    );
    final inner = RRect.fromRectAndRadius(
      bounds.deflate(2.5),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      outer.shift(const Offset(0, 1)),
      Paint()
        ..color = const Color(0xFF020304).withValues(alpha: .92)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..color = const Color(0xFF778188)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawRRect(
      inner,
      Paint()
        ..color = const Color(0xFF252C31)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final highlight = Path()
      ..moveTo(bounds.left + 8, bounds.top + 1.5)
      ..lineTo(bounds.right - 8, bounds.top + 1.5)
      ..moveTo(bounds.left + 1.5, bounds.top + 8)
      ..lineTo(bounds.left + 1.5, bounds.bottom - 8);
    canvas.drawPath(
      highlight,
      Paint()
        ..color = const Color(0xFFC5CCD0).withValues(alpha: .22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8
        ..strokeCap = StrokeCap.round,
    );

    final shade = Path()
      ..moveTo(bounds.left + 8, bounds.bottom - 1.5)
      ..lineTo(bounds.right - 8, bounds.bottom - 1.5)
      ..moveTo(bounds.right - 1.5, bounds.top + 8)
      ..lineTo(bounds.right - 1.5, bounds.bottom - 8);
    canvas.drawPath(
      shade,
      Paint()
        ..color = Colors.black.withValues(alpha: .82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_GraphiteLandscapeRailsPainter oldDelegate) => false;
}

abstract final class _GraphiteChrome {
  static const contentSurface = Color(0xFF13171A);
  static const raisedSurface = Color(0xFF171B1E);
  static const decorativeBoundary = Color(0xFF5C646A);
}

final class _GraphiteGridIcon extends StatelessWidget {
  const _GraphiteGridIcon({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size.square(28),
    painter: _GraphiteGridPainter(
      line: context.clinicalColors.secondaryText,
      signal: context.clinicalColors.clinical,
    ),
  );
}

final class _GraphiteGridPainter extends CustomPainter {
  const _GraphiteGridPainter({required this.line, required this.signal});

  final Color line;
  final Color signal;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 5.0;
    const gap = 3.0;
    final origin = Offset(
      (size.width - (cell * 3 + gap * 2)) / 2,
      (size.height - (cell * 3 + gap * 2)) / 2,
    );
    for (var row = 0; row < 3; row++) {
      for (var column = 0; column < 3; column++) {
        final rect = Rect.fromLTWH(
          origin.dx + column * (cell + gap),
          origin.dy + row * (cell + gap),
          cell,
          cell,
        );
        final active = row == 1 && column == 2;
        canvas.drawRect(
          rect,
          Paint()
            ..color = active ? signal : line.withValues(alpha: .62)
            ..style = active ? PaintingStyle.fill : PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GraphiteGridPainter oldDelegate) =>
      line != oldDelegate.line || signal != oldDelegate.signal;
}

final class _GraphiteCalendarViewport extends StatelessWidget {
  const _GraphiteCalendarViewport({
    required this.child,
    this.scrollAtEnlargedText = false,
  });

  final Widget child;
  final bool scrollAtEnlargedText;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final calendar = CalendarPeriodViewportPolicy(
        useBoundedMonthGrid: true,
        scaleDayNumberWithText: true,
        useEnlargedTextLandscapeReflow: !scrollAtEnlargedText,
        useInstrumentChrome: true,
        child: child,
      );
      return buildEnlargedTextCalendarScrollViewport(
        context: context,
        constraints: constraints,
        enabled: scrollAtEnlargedText,
        scrollKey: const Key('graphite-calendar-horizontal-scroll'),
        child: calendar,
      );
    },
  );
}

final class _GraphiteInstrumentBay extends StatelessWidget {
  const _GraphiteInstrumentBay({
    required this.safeInsets,
    required this.accent,
    required this.child,
    this.integrated = false,
    this.integratedPadding = const EdgeInsets.fromLTRB(23, 18, 23, 18),
    super.key,
  });

  final EdgeInsets safeInsets;
  final _GraphiteAccent accent;
  final Widget child;
  final bool integrated;
  final EdgeInsets integratedPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.clinicalColors;
    final accentColor = switch (accent) {
      _GraphiteAccent.silver => colors.insetBorder,
      _GraphiteAccent.emerald => colors.clinical,
      _GraphiteAccent.coral => colors.urgent,
    };
    final content = ColoredBox(
      color: _GraphiteChrome.contentSurface.withValues(alpha: .96),
      child: Padding(
        padding: integrated ? integratedPadding : EdgeInsets.zero,
        child: ClipRect(clipBehavior: Clip.hardEdge, child: child),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.structure.withValues(alpha: .74),
        border: Border.all(
          color: integrated
              ? _GraphiteChrome.decorativeBoundary.withValues(alpha: .9)
              : accentColor.withValues(alpha: .34),
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: integrated
          ? content
          : GraphiteNineSliceFrame(chromeInsets: safeInsets, child: content),
    );
  }
}

final class _GraphiteCommandCrown extends StatelessWidget {
  const _GraphiteCommandCrown({
    required this.environmentName,
    required this.onOpenMenu,
    required this.onAddSchedule,
    required this.onOpenDestination,
    required this.profileAvatar,
    this.compact = false,
  });

  final String environmentName;
  final VoidCallback onOpenMenu;
  final VoidCallback onAddSchedule;
  final ValueChanged<ClinicalCalendarDestination> onOpenDestination;
  final Widget profileAvatar;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final enlargedText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final identity =
        environmentName.trim().isEmpty ||
            environmentName.trim().toUpperCase() == 'GRAPHITE'
        ? 'GRAPHITE'
        : 'GRAPHITE  •  $environmentName';
    final title = Text(
      'CLINICAL CALENDAR',
      maxLines: 1,
      overflow: TextOverflow.clip,
      style: TextStyle(
        color: context.clinicalColors.primaryText,
        fontSize: compact ? 18 : 25,
        height: 1,
        letterSpacing: 1.5,
        fontWeight: FontWeight.w600,
      ),
    );
    final subtitle = Text(
      identity,
      maxLines: 2,
      overflow: TextOverflow.clip,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: context.clinicalColors.secondaryText,
        fontSize: 11,
        letterSpacing: 1.5,
      ),
    );
    return Container(
      key: const Key('graphite-command-crown'),
      height: compact ? 72 : null,
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
      decoration: BoxDecoration(
        color: _GraphiteChrome.raisedSurface,
        border: Border.all(color: _GraphiteChrome.decorativeBoundary),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          SizedBox.square(
            dimension: compact ? 40 : 50,
            child: Semantics(
              label: 'Graphite calendar mark',
              image: true,
              child: const ExcludeSemantics(child: CanonicalDeltaMark()),
            ),
          ),
          SizedBox(width: compact ? 8 : 12),
          Expanded(
            child: !compact && enlargedText
                ? Row(
                    children: [
                      title,
                      const SizedBox(width: 18),
                      Flexible(child: subtitle),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, if (!compact) subtitle],
                  ),
          ),
          IconButton(
            tooltip: 'Add schedule',
            onPressed: onAddSchedule,
            icon: const Icon(Icons.add_box_outlined),
          ),
          if (!compact)
            IconButton(
              tooltip: 'Help',
              onPressed: () =>
                  onOpenDestination(ClinicalCalendarDestination.help),
              icon: const Icon(Icons.help_outline),
            ),
          SizedBox.square(
            dimension: compact ? 36 : 40,
            child: FittedBox(child: profileAvatar),
          ),
          IconButton(
            key: const Key('application-menu-action'),
            tooltip: 'Open menu',
            onPressed: onOpenMenu,
            icon: const _GraphiteGridIcon(),
          ),
        ],
      ),
    );
  }
}

final class _GraphiteNavigationRail extends StatelessWidget {
  const _GraphiteNavigationRail({
    required this.selectedIndex,
    required this.onOpenDestination,
    required this.onOpenAttention,
    this.compact = false,
  });

  final int selectedIndex;
  final ValueChanged<ClinicalCalendarDestination> onOpenDestination;
  final VoidCallback onOpenAttention;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const destinations = [
      (Icons.today_outlined, 'TODAY'),
      (Icons.calendar_month_outlined, 'CALENDAR'),
      (Icons.track_changes_outlined, 'CLINICAL PLACEMENTS'),
      (Icons.notifications_outlined, 'ATTENTION'),
      (Icons.settings_outlined, 'SETTINGS'),
    ];
    final iconsOnly =
        compact || MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Container(
      key: const Key('graphite-bottom-navigation'),
      height: compact ? 68 : null,
      decoration: BoxDecoration(
        color: _GraphiteChrome.raisedSurface,
        border: Border.all(color: _GraphiteChrome.decorativeBoundary),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (var index = 0; index < destinations.length; index++)
            Expanded(
              child: Semantics(
                button: true,
                selected: index == selectedIndex,
                label: destinations[index].$2,
                child: InkWell(
                  key: Key('graphite-navigation-$index'),
                  onTap: () {
                    switch (index) {
                      case 0:
                      case 1:
                        onOpenDestination(ClinicalCalendarDestination.calendar);
                      case 2:
                        onOpenDestination(
                          ClinicalCalendarDestination.clinicalPlacements,
                        );
                      case 3:
                        onOpenAttention();
                      case 4:
                        onOpenDestination(ClinicalCalendarDestination.settings);
                    }
                  },
                  child: Stack(
                    children: [
                      if (index == selectedIndex)
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 56,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      if (index < destinations.length - 1)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            width: 1,
                            height: 54,
                            color: context.clinicalColors.insetBorder
                                .withValues(alpha: .6),
                          ),
                        ),
                      Center(
                        child: iconsOnly
                            ? Icon(
                                destinations[index].$1,
                                color: index == selectedIndex
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              )
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      destinations[index].$1,
                                      size: 34,
                                      color: index == selectedIndex
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      destinations[index].$2,
                                      style: TextStyle(
                                        fontSize: 16,
                                        letterSpacing: .8,
                                        color: index == selectedIndex
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
