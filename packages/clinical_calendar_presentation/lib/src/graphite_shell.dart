import 'package:flutter/material.dart';

import 'additive_theme_shell.dart';
import 'calendar/calendar_period_view.dart';
import 'graphite_frame.dart';
import 'responsive_shell.dart';
import 'variant_f_theme.dart';

const graphiteCompactDestinationInsets = EdgeInsets.fromLTRB(18, 20, 18, 22);

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
  Widget build(BuildContext context) => AdditiveThemeDestinationSurface(
    destination: destination,
    entry: entry,
    onExit: onExit,
    frameBuilder: _buildGraphiteFrame,
    statusSafeInsets: graphiteStatusSafeInsets,
    compactDestinationInsets: graphiteCompactDestinationInsets,
    child: child,
  );
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
                  child: _GraphiteInstrumentBay(
                    key: const Key('graphite-placement-bay'),
                    safeInsets: graphitePlacementsSafeInsets,
                    accent: _GraphiteAccent.emerald,
                    integrated: true,
                    child: slots.placementDock,
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
                    child: slots.insightRail,
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
                                  child: _GraphiteInstrumentBay(
                                    key: const Key('graphite-placement-bay'),
                                    safeInsets: graphitePlacementsSafeInsets,
                                    accent: _GraphiteAccent.emerald,
                                    child: slots.mobilePlacementSummary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _GraphiteInstrumentBay(
                                    key: const Key('graphite-insight-bay'),
                                    safeInsets: graphiteStatusSafeInsets,
                                    accent: _GraphiteAccent.coral,
                                    child: slots.mobileAttention,
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

abstract final class _GraphiteChrome {
  static const contentSurface = Color(0xFF13171A);
  static const raisedSurface = Color(0xFF171B1E);
  static const decorativeBoundary = Color(0xFF5C646A);
}

final class _GraphiteGridIcon extends StatelessWidget {
  const _GraphiteGridIcon();

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

final class _GraphiteLogoPainter extends CustomPainter {
  const _GraphiteLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: .75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final silver = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF2F3F3), Color(0xFF7B8287)],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final silhouette = Path()
      ..moveTo(size.width * .12, size.height * .88)
      ..lineTo(size.width * .48, size.height * .08)
      ..lineTo(size.width * .87, size.height * .88);
    final crossbar = Path()
      ..moveTo(size.width * .23, size.height * .64)
      ..lineTo(size.width * .72, size.height * .49);
    canvas.drawPath(silhouette, shadow);
    canvas.drawPath(crossbar, shadow);
    canvas.drawPath(silhouette, silver);
    canvas.drawPath(crossbar, silver);
    canvas.drawLine(
      Offset(size.width * .34, size.height * .76),
      Offset(size.width * .68, size.height * .67),
      silver..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_GraphiteLogoPainter oldDelegate) => false;
}

final class _GraphiteCalendarViewport extends StatelessWidget {
  const _GraphiteCalendarViewport({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final calendar = CalendarPeriodViewportPolicy(
        useBoundedMonthGrid: true,
        scaleDayNumberWithText: true,
        useInstrumentChrome: true,
        child: child,
      );
      if (MediaQuery.textScalerOf(context).scale(1) <= 1.3) return calendar;
      return SingleChildScrollView(
        key: const Key('graphite-calendar-horizontal-scroll'),
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: constraints.maxWidth * 3.5,
          height: constraints.maxHeight,
          child: calendar,
        ),
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
            child: const CustomPaint(painter: _GraphiteLogoPainter()),
          ),
          SizedBox(width: compact ? 8 : 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
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
                ),
                if (!compact)
                  Text(
                    environmentName.trim().isEmpty ||
                            environmentName.trim().toUpperCase() == 'GRAPHITE'
                        ? 'GRAPHITE'
                        : 'GRAPHITE  •  $environmentName',
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.clinicalColors.secondaryText,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
              ],
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
