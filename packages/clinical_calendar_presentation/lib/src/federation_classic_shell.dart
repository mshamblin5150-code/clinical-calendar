import 'package:flutter/material.dart';

import 'additive_theme_shell.dart';
import 'calendar/calendar_period_view.dart';
import 'federation_classic_frame.dart';
import 'responsive_shell.dart';
import 'variant_f_theme.dart';

const federationClassicCompactDestinationInsets = EdgeInsets.fromLTRB(
  18,
  20,
  18,
  22,
);

Widget _buildFederationClassicFrame(
  Widget child,
  EdgeInsets chromeInsets,
  EdgeInsets contentPadding,
) => FederationClassicNineSliceFrame(
  chromeInsets: chromeInsets,
  contentPadding: contentPadding,
  child: child,
);

final class FederationClassicDestinationSurface extends StatelessWidget {
  const FederationClassicDestinationSurface({
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
    frameBuilder: _buildFederationClassicFrame,
    statusSafeInsets: federationClassicStatusSafeInsets,
    compactDestinationInsets: federationClassicCompactDestinationInsets,
    child: child,
  );
}

final class FederationClassicApplicationShell extends StatelessWidget {
  const FederationClassicApplicationShell({
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
    key: const Key('federation-classic-landscape-shell'),
    backgroundColor: const Color(0xFF09070C),
    body: FederationClassicLandscapeChassis(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return Stack(
            children: [
              Positioned(
                left: width * .105,
                top: height * .025,
                width: width * .88,
                height: height * .065,
                child: _FederationClassicCommandCrown(
                  environmentName: environmentName,
                  onOpenMenu: onOpenMenu,
                  onAddSchedule: onAddSchedule,
                  onOpenDestination: onOpenDestination,
                  profileAvatar: slots.profileAvatar,
                  integrated: true,
                ),
              ),
              Positioned(
                left: width * .065,
                top: height * .098,
                width: width * .19,
                height: height * .67,
                child: _FederationClassicConsoleBay(
                  key: const Key('federation-classic-placement-bay'),
                  accent: _FederationClassicBayAccent.lilac,
                  shape: _FederationClassicBayShape.placement,
                  integrated: true,
                  child: slots.placementDock,
                ),
              ),
              Positioned(
                left: width * .258,
                top: height * .098,
                width: width * .47,
                height: height * .462,
                child: _FederationClassicConsoleBay(
                  key: const Key('federation-classic-calendar-bay'),
                  accent: _FederationClassicBayAccent.salmon,
                  shape: _FederationClassicBayShape.calendar,
                  integrated: true,
                  child: _FederationClassicCalendarViewport(
                    child: slots.centralContent,
                  ),
                ),
              ),
              Positioned(
                left: width * .258,
                top: height * .575,
                width: width * .47,
                height: height * .273,
                child: _FederationClassicConsoleBay(
                  key: const Key('federation-classic-planning-bay'),
                  accent: _FederationClassicBayAccent.salmon,
                  shape: _FederationClassicBayShape.planning,
                  integrated: true,
                  child: VariantFPlanningBayMode(
                    expandedByDefault: true,
                    child: slots.planningRegion,
                  ),
                ),
              ),
              Positioned(
                left: width * .75,
                top: height * .098,
                width: width * .225,
                height: height * .75,
                child: _FederationClassicConsoleBay(
                  key: const Key('federation-classic-insight-bay'),
                  accent: _FederationClassicBayAccent.lilac,
                  shape: _FederationClassicBayShape.insight,
                  integrated: true,
                  child: slots.insightRail,
                ),
              ),
              Positioned(
                left: width * .11,
                top: height * .89,
                width: width * .76,
                height: height * .085,
                child: _FederationClassicNavigationDeck(
                  selectedIndex: mobileIndex,
                  onOpenDestination: onOpenDestination,
                  onOpenAttention: onOpenAttention,
                  integrated: true,
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _portrait() => Scaffold(
    key: const Key('federation-classic-portrait-shell'),
    backgroundColor: const Color(0xFF09070C),
    body: SafeArea(
      child: FederationClassicNineSliceFrame(
        chromeInsets: const EdgeInsets.fromLTRB(24, 28, 24, 30),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
          child: Column(
            children: [
              _FederationClassicCommandCrown(
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
                      key: const Key('federation-classic-portrait-scroll'),
                      primary: true,
                      child: SizedBox(
                        height: enlargedText
                            ? constraints.maxHeight * 1.38
                            : constraints.maxHeight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 6,
                              child: _FederationClassicConsoleBay(
                                key: const Key(
                                  'federation-classic-calendar-bay',
                                ),
                                accent: _FederationClassicBayAccent.salmon,
                                shape: _FederationClassicBayShape.calendar,
                                child: _FederationClassicCalendarViewport(
                                  child: slots.centralContent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              flex: 3,
                              child: _FederationClassicConsoleBay(
                                key: const Key(
                                  'federation-classic-planning-bay',
                                ),
                                accent: _FederationClassicBayAccent.salmon,
                                shape: _FederationClassicBayShape.planning,
                                child: VariantFPlanningBayMode(
                                  expandedByDefault: false,
                                  child: slots.planningRegion,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              flex: 3,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _FederationClassicConsoleBay(
                                      key: const Key(
                                        'federation-classic-placement-bay',
                                      ),
                                      accent: _FederationClassicBayAccent.lilac,
                                      shape:
                                          _FederationClassicBayShape.placement,
                                      child: slots.mobilePlacementSummary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _FederationClassicConsoleBay(
                                      key: const Key(
                                        'federation-classic-insight-bay',
                                      ),
                                      accent: _FederationClassicBayAccent.lilac,
                                      shape: _FederationClassicBayShape.insight,
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
              _FederationClassicNavigationDeck(
                selectedIndex: mobileIndex,
                onOpenDestination: onOpenDestination,
                onOpenAttention: onOpenAttention,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _compact() => AdditiveThemeApplicationShell(
    key: const Key('federation-classic-compact-shell'),
    slots: slots,
    environmentName: environmentName,
    onOpenMenu: onOpenMenu,
    onOpenDestination: onOpenDestination,
    onOpenAttention: onOpenAttention,
    onAddSchedule: onAddSchedule,
    mobileIndex: mobileIndex,
    frameBuilder: _buildFederationClassicFrame,
    calendarSafeInsets: federationClassicCalendarSafeInsets,
    placementsSafeInsets: federationClassicPlacementsSafeInsets,
    planningSafeInsets: federationClassicPlanningSafeInsets,
    statusSafeInsets: federationClassicStatusSafeInsets,
  );
}

enum _FederationClassicBayAccent { salmon, lilac }

enum _FederationClassicBayShape { placement, calendar, planning, insight }

final class _FederationClassicCalendarViewport extends StatelessWidget {
  const _FederationClassicCalendarViewport({required this.child});

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
        key: const Key('federation-classic-calendar-horizontal-scroll'),
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

final class _FederationClassicConsoleBay extends StatelessWidget {
  const _FederationClassicConsoleBay({
    required this.accent,
    required this.shape,
    required this.child,
    this.integrated = false,
    super.key,
  });

  final _FederationClassicBayAccent accent;
  final _FederationClassicBayShape shape;
  final Widget child;
  final bool integrated;

  @override
  Widget build(BuildContext context) {
    final colors = context.clinicalColors;
    final accentColor = switch (accent) {
      _FederationClassicBayAccent.salmon => colors.clinical,
      _FederationClassicBayAccent.lilac => colors.workMachinery,
    };
    final content = ClipRRect(
      borderRadius: integrated ? BorderRadius.zero : BorderRadius.circular(24),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          shape == _FederationClassicBayShape.placement ? 14 : 12,
          integrated ? 10 : 20,
          shape == _FederationClassicBayShape.insight ? 14 : 12,
          integrated ? 10 : 18,
        ),
        child: child,
      ),
    );
    if (integrated) return content;
    return CustomPaint(
      painter: _FederationClassicConsoleBayPainter(
        surface: colors.structure,
        raised: colors.structureRaised,
        border: colors.insetBorder,
        accent: accentColor,
        shape: shape,
      ),
      child: content,
    );
  }
}

final class _FederationClassicConsoleBayPainter extends CustomPainter {
  const _FederationClassicConsoleBayPainter({
    required this.surface,
    required this.raised,
    required this.border,
    required this.accent,
    required this.shape,
  });

  final Color surface;
  final Color raised;
  final Color border;
  final Color accent;
  final _FederationClassicBayShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(26),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..color = Color.lerp(raised, accent, .10)!
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..color = accent.withValues(alpha: .82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
      const Radius.circular(18),
    );
    canvas.drawRRect(inner, Paint()..color = surface);
    canvas.drawRRect(
      inner,
      Paint()
        ..color = border.withValues(alpha: .44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final rail = Paint()
      ..color = accent
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(30, 6), Offset(size.width * .36, 6), rail);
    canvas.drawLine(
      Offset(size.width * .70, size.height - 6),
      Offset(size.width - 30, size.height - 6),
      rail,
    );
  }

  @override
  bool shouldRepaint(
    covariant _FederationClassicConsoleBayPainter oldDelegate,
  ) =>
      oldDelegate.surface != surface ||
      oldDelegate.raised != raised ||
      oldDelegate.border != border ||
      oldDelegate.accent != accent ||
      oldDelegate.shape != shape;
}

final class _FederationClassicCommandCrown extends StatelessWidget {
  const _FederationClassicCommandCrown({
    required this.environmentName,
    required this.onOpenMenu,
    required this.onAddSchedule,
    required this.onOpenDestination,
    required this.profileAvatar,
    this.compact = false,
    this.integrated = false,
  });

  final String environmentName;
  final VoidCallback onOpenMenu;
  final VoidCallback onAddSchedule;
  final ValueChanged<ClinicalCalendarDestination> onOpenDestination;
  final Widget profileAvatar;
  final bool compact;
  final bool integrated;

  @override
  Widget build(BuildContext context) {
    final enlargedText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final content = SizedBox(
      key: const Key('federation-classic-command-crown'),
      height: compact ? 72 : 92,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
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
                  : Row(
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              compact
                                  ? 'CLINICAL CALENDAR'
                                  : 'C L I N I C A L   C A L E N D A R',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    letterSpacing: compact ? 1.2 : 2.1,
                                    color: context.clinicalColors.clinical,
                                  ),
                            ),
                          ),
                        ),
                        if (!compact && environmentName.trim().isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Text(
                            environmentName,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
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
      ),
    );
    if (integrated) return content;
    return CustomPaint(
      painter: _FederationClassicCrownPainter(
        structure: context.clinicalColors.structureRaised,
        border: context.clinicalColors.insetBorder,
        cyan: context.clinicalColors.workMachinery,
        plum: context.clinicalColors.clinical,
      ),
      child: content,
    );
  }
}

final class _FederationClassicCrownPainter extends CustomPainter {
  const _FederationClassicCrownPainter({
    required this.structure,
    required this.border,
    required this.cyan,
    required this.plum,
  });

  final Color structure;
  final Color border;
  final Color cyan;
  final Color plum;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(26, 0)
      ..lineTo(size.width - 42, 0)
      ..quadraticBezierTo(size.width, 0, size.width, 34)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, 26)
      ..quadraticBezierTo(0, 0, 26, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = structure);
    canvas.drawPath(
      path,
      Paint()
        ..color = border.withValues(alpha: .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final cyanPaint = Paint()
      ..color = cyan
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final plumPaint = Paint()
      ..color = plum
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .06, 5),
      Offset(size.width * .38, 5),
      plumPaint,
    );
    canvas.drawLine(
      Offset(size.width * .62, 5),
      Offset(size.width * .94, 5),
      cyanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FederationClassicCrownPainter oldDelegate) =>
      oldDelegate.structure != structure ||
      oldDelegate.border != border ||
      oldDelegate.cyan != cyan ||
      oldDelegate.plum != plum;
}

final class _FederationClassicNavigationDeck extends StatelessWidget {
  const _FederationClassicNavigationDeck({
    required this.selectedIndex,
    required this.onOpenDestination,
    required this.onOpenAttention,
    this.compact = false,
    this.integrated = false,
  });

  final int selectedIndex;
  final ValueChanged<ClinicalCalendarDestination> onOpenDestination;
  final VoidCallback onOpenAttention;
  final bool compact;
  final bool integrated;

  @override
  Widget build(BuildContext context) {
    const destinations = [
      (Icons.today_outlined, 'TODAY'),
      (Icons.calendar_month_outlined, 'CALENDAR'),
      (Icons.track_changes_outlined, 'PLACEMENTS'),
      (Icons.notifications_outlined, 'ATTENTION'),
      (Icons.settings_outlined, 'SETTINGS'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconsOnly =
            compact ||
            constraints.maxWidth < 900 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        return Container(
          key: const Key('federation-classic-bottom-navigation'),
          height: compact ? 68 : 92,
          decoration: BoxDecoration(
            color: integrated
                ? Colors.transparent
                : context.clinicalColors.structureRaised,
            border: integrated
                ? null
                : Border.all(color: context.clinicalColors.insetBorder),
            borderRadius: BorderRadius.circular(46),
            boxShadow: integrated
                ? null
                : [
                    BoxShadow(
                      color: context.clinicalColors.workMachinery.withValues(
                        alpha: .14,
                      ),
                      blurRadius: 10,
                    ),
                  ],
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
                      key: Key('federation-classic-navigation-$index'),
                      onTap: () {
                        switch (index) {
                          case 0:
                          case 1:
                            onOpenDestination(
                              ClinicalCalendarDestination.calendar,
                            );
                          case 2:
                            onOpenDestination(
                              ClinicalCalendarDestination.clinicalPlacements,
                            );
                          case 3:
                            onOpenAttention();
                          case 4:
                            onOpenDestination(
                              ClinicalCalendarDestination.settings,
                            );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: index == selectedIndex
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(34),
                        ),
                        child: Center(
                          child: iconsOnly
                              ? Icon(
                                  destinations[index].$1,
                                  color: index == selectedIndex
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : null,
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      destinations[index].$1,
                                      color: index == selectedIndex
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onPrimary
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      destinations[index].$2,
                                      style: index == selectedIndex
                                          ? TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                              fontWeight: FontWeight.w700,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
