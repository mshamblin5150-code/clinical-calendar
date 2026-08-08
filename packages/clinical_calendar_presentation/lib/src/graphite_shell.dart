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
      chromeInsets: const EdgeInsets.all(6),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xFF090B0D),
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.35,
            colors: [Color(0xFF20262B), Color(0xFF090B0D)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            return Stack(
              children: [
                Positioned(
                  left: width * .004,
                  top: height * .005,
                  width: width * .992,
                  height: height * .078,
                  child: _GraphiteCommandCrown(
                    environmentName: environmentName,
                    onOpenMenu: onOpenMenu,
                    onAddSchedule: onAddSchedule,
                    onOpenDestination: onOpenDestination,
                    profileAvatar: slots.profileAvatar,
                  ),
                ),
                Positioned(
                  left: width * .004,
                  top: height * .088,
                  width: width * .19,
                  height: height * .795,
                  child: _GraphiteInstrumentBay(
                    key: const Key('graphite-placement-bay'),
                    safeInsets: graphitePlacementsSafeInsets,
                    accent: _GraphiteAccent.emerald,
                    integrated: true,
                    child: slots.placementDock,
                  ),
                ),
                Positioned(
                  left: width * .2,
                  top: height * .088,
                  width: width * .55,
                  height: height * .545,
                  child: _GraphiteInstrumentBay(
                    key: const Key('graphite-calendar-bay'),
                    safeInsets: graphiteCalendarSafeInsets,
                    accent: _GraphiteAccent.silver,
                    integrated: true,
                    child: _GraphiteCalendarViewport(
                      child: slots.centralContent,
                    ),
                  ),
                ),
                Positioned(
                  left: width * .2,
                  top: height * .638,
                  width: width * .55,
                  height: height * .245,
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
                  left: width * .756,
                  top: height * .088,
                  width: width * .24,
                  height: height * .795,
                  child: _GraphiteInstrumentBay(
                    key: const Key('graphite-insight-bay'),
                    safeInsets: graphiteStatusSafeInsets,
                    accent: _GraphiteAccent.coral,
                    integrated: true,
                    child: slots.insightRail,
                  ),
                ),
                Positioned(
                  left: width * .004,
                  top: height * .89,
                  width: width * .992,
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

final class _GraphiteCalendarViewport extends StatelessWidget {
  const _GraphiteCalendarViewport({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final calendar = CalendarPeriodViewportPolicy(
        useBoundedMonthGrid: true,
        scaleDayNumberWithText: true,
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
    super.key,
  });

  final EdgeInsets safeInsets;
  final _GraphiteAccent accent;
  final Widget child;
  final bool integrated;

  @override
  Widget build(BuildContext context) {
    final colors = context.clinicalColors;
    final accentColor = switch (accent) {
      _GraphiteAccent.silver => colors.insetBorder,
      _GraphiteAccent.emerald => colors.clinical,
      _GraphiteAccent.coral => colors.urgent,
    };
    final content = ColoredBox(
      color: colors.canvas.withValues(alpha: .96),
      child: Padding(
        padding: integrated
            ? const EdgeInsets.fromLTRB(16, 14, 16, 14)
            : EdgeInsets.zero,
        child: ClipRect(clipBehavior: Clip.hardEdge, child: child),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.structure.withValues(alpha: .74),
        border: Border.all(color: accentColor.withValues(alpha: .34)),
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
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
    return Container(
      key: const Key('graphite-command-crown'),
      height: compact ? 72 : null,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.clinicalColors.structureRaised,
        border: Border.all(color: context.clinicalColors.insetBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('application-menu-action'),
            tooltip: 'Open menu',
            onPressed: onOpenMenu,
            icon: const Icon(Icons.grid_view_outlined),
          ),
          if (!enlargedText) ...[
            const SizedBox(width: 8),
            const Icon(Icons.calendar_month_outlined),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: enlargedText
                ? const SizedBox.shrink()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CLINICAL CALENDAR',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      if (!compact)
                        Text(
                          environmentName.trim().isEmpty
                              ? 'GRAPHITE'
                              : 'GRAPHITE  •  $environmentName',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: context.clinicalColors.secondaryText,
                                letterSpacing: 1.3,
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
          profileAvatar,
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
        color: context.clinicalColors.structureRaised,
        border: Border.all(color: context.clinicalColors.insetBorder),
        borderRadius: BorderRadius.circular(12),
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
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: index == selectedIndex
                              ? context.clinicalColors.clinical
                              : Colors.transparent,
                          width: 4,
                        ),
                        right: index < destinations.length - 1
                            ? BorderSide(
                                color: context.clinicalColors.insetBorder
                                    .withValues(alpha: .45),
                              )
                            : BorderSide.none,
                      ),
                    ),
                    child: Center(
                      child: iconsOnly
                          ? Icon(destinations[index].$1)
                          : FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(destinations[index].$1),
                                  const SizedBox(width: 8),
                                  Text(destinations[index].$2),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
