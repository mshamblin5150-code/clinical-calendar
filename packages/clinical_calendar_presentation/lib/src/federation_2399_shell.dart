import 'package:flutter/material.dart';

import 'additive_theme_shell.dart';
import 'calendar/calendar_period_view.dart';
import 'federation_2399_frame.dart';
import 'responsive_shell.dart';
import 'variant_f_theme.dart';

const federation2399CompactDestinationInsets = EdgeInsets.fromLTRB(
  18,
  20,
  18,
  22,
);

Widget _buildFederation2399Frame(
  Widget child,
  EdgeInsets chromeInsets,
  EdgeInsets contentPadding,
) => Federation2399NineSliceFrame(
  chromeInsets: chromeInsets,
  contentPadding: contentPadding,
  child: child,
);

final class Federation2399DestinationSurface extends StatelessWidget {
  const Federation2399DestinationSurface({
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
    frameBuilder: _buildFederation2399Frame,
    statusSafeInsets: federation2399StatusSafeInsets,
    compactDestinationInsets: federation2399CompactDestinationInsets,
    child: child,
  );
}

final class Federation2399ApplicationShell extends StatelessWidget {
  const Federation2399ApplicationShell({
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
    key: const Key('federation-2399-landscape-shell'),
    body: SafeArea(
      child: Federation2399NineSliceFrame(
        chromeInsets: const EdgeInsets.fromLTRB(28, 30, 28, 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
          child: Column(
            children: [
              _Federation2399CommandCrown(
                environmentName: environmentName,
                onOpenMenu: onOpenMenu,
                onAddSchedule: onAddSchedule,
                onOpenDestination: onOpenDestination,
                profileAvatar: slots.profileAvatar,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 276,
                      child: _Federation2399ConsoleBay(
                        key: const Key('federation-2399-placement-bay'),
                        accent: _Federation2399BayAccent.cyan,
                        child: slots.placementDock,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 7,
                            child: _Federation2399ConsoleBay(
                              key: const Key('federation-2399-calendar-bay'),
                              accent: _Federation2399BayAccent.plum,
                              child: CalendarPeriodViewportPolicy(
                                useBoundedMonthGrid: true,
                                child: slots.centralContent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            flex: 4,
                            child: _Federation2399ConsoleBay(
                              key: const Key('federation-2399-planning-bay'),
                              accent: _Federation2399BayAccent.plum,
                              child: VariantFPlanningBayMode(
                                expandedByDefault: true,
                                child: slots.planningRegion,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 304,
                      child: _Federation2399ConsoleBay(
                        key: const Key('federation-2399-insight-bay'),
                        accent: _Federation2399BayAccent.cyan,
                        child: slots.insightRail,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _Federation2399NavigationDeck(
                selectedIndex: mobileIndex,
                onOpenDestination: onOpenDestination,
                onOpenAttention: onOpenAttention,
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _portrait() => Scaffold(
    key: const Key('federation-2399-portrait-shell'),
    body: SafeArea(
      child: Federation2399NineSliceFrame(
        chromeInsets: const EdgeInsets.fromLTRB(24, 28, 24, 30),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
          child: Column(
            children: [
              _Federation2399CommandCrown(
                environmentName: environmentName,
                onOpenMenu: onOpenMenu,
                onAddSchedule: onAddSchedule,
                onOpenDestination: onOpenDestination,
                profileAvatar: slots.profileAvatar,
                compact: true,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _Federation2399ConsoleBay(
                        key: const Key('federation-2399-calendar-bay'),
                        accent: _Federation2399BayAccent.plum,
                        child: CalendarPeriodViewportPolicy(
                          useBoundedMonthGrid: true,
                          child: slots.centralContent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      flex: 3,
                      child: _Federation2399ConsoleBay(
                        key: const Key('federation-2399-planning-bay'),
                        accent: _Federation2399BayAccent.plum,
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
                            child: _Federation2399ConsoleBay(
                              key: const Key('federation-2399-placement-bay'),
                              accent: _Federation2399BayAccent.cyan,
                              child: slots.mobilePlacementSummary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _Federation2399ConsoleBay(
                              key: const Key('federation-2399-insight-bay'),
                              accent: _Federation2399BayAccent.cyan,
                              child: slots.mobileAttention,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _Federation2399NavigationDeck(
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
    key: const Key('federation-2399-compact-shell'),
    slots: slots,
    environmentName: environmentName,
    onOpenMenu: onOpenMenu,
    onOpenDestination: onOpenDestination,
    onOpenAttention: onOpenAttention,
    onAddSchedule: onAddSchedule,
    mobileIndex: mobileIndex,
    frameBuilder: _buildFederation2399Frame,
    calendarSafeInsets: federation2399CalendarSafeInsets,
    placementsSafeInsets: federation2399PlacementsSafeInsets,
    planningSafeInsets: federation2399PlanningSafeInsets,
    statusSafeInsets: federation2399StatusSafeInsets,
  );
}

enum _Federation2399BayAccent { plum, cyan }

final class _Federation2399ConsoleBay extends StatelessWidget {
  const _Federation2399ConsoleBay({
    required this.accent,
    required this.child,
    super.key,
  });

  final _Federation2399BayAccent accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.clinicalColors;
    final accentColor = switch (accent) {
      _Federation2399BayAccent.plum => colors.clinical,
      _Federation2399BayAccent.cyan => colors.workMachinery,
    };
    return CustomPaint(
      painter: _Federation2399ConsoleBayPainter(
        surface: colors.structure,
        raised: colors.structureRaised,
        border: colors.insetBorder,
        accent: accentColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Padding(padding: const EdgeInsets.all(18), child: child),
      ),
    );
  }
}

final class _Federation2399ConsoleBayPainter extends CustomPainter {
  const _Federation2399ConsoleBayPainter({
    required this.surface,
    required this.raised,
    required this.border,
    required this.accent,
  });

  final Color surface;
  final Color raised;
  final Color border;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(28),
    );
    final middle = outer.deflate(3);
    final inner = outer.deflate(8);
    canvas.drawRRect(outer, Paint()..color = raised);
    canvas.drawRRect(
      middle,
      Paint()
        ..color = border.withValues(alpha: .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(inner, Paint()..color = surface);
    canvas.drawRRect(
      inner,
      Paint()
        ..color = accent.withValues(alpha: .58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final rail = Paint()
      ..color = accent
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(28, 7), Offset(size.width * .34, 7), rail);
    canvas.drawLine(
      Offset(size.width * .66, size.height - 7),
      Offset(size.width - 28, size.height - 7),
      rail,
    );
  }

  @override
  bool shouldRepaint(covariant _Federation2399ConsoleBayPainter oldDelegate) =>
      oldDelegate.surface != surface ||
      oldDelegate.raised != raised ||
      oldDelegate.border != border ||
      oldDelegate.accent != accent;
}

final class _Federation2399CommandCrown extends StatelessWidget {
  const _Federation2399CommandCrown({
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
  Widget build(BuildContext context) => CustomPaint(
    painter: _Federation2399CrownPainter(
      structure: context.clinicalColors.structureRaised,
      border: context.clinicalColors.insetBorder,
      cyan: context.clinicalColors.workMachinery,
      plum: context.clinicalColors.clinical,
    ),
    child: SizedBox(
      height: compact ? 58 : 66,
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
            const SizedBox(width: 8),
            const Icon(Icons.calendar_month_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        compact
                            ? 'CLINICAL CALENDAR'
                            : 'C L I N I C A L   C A L E N D A R',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
    ),
  );
}

final class _Federation2399CrownPainter extends CustomPainter {
  const _Federation2399CrownPainter({
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
      ..moveTo(0, 10)
      ..quadraticBezierTo(size.width * .18, 2, size.width * .35, 9)
      ..quadraticBezierTo(size.width * .5, 22, size.width * .65, 9)
      ..quadraticBezierTo(size.width * .82, 2, size.width, 10)
      ..lineTo(size.width, size.height - 8)
      ..quadraticBezierTo(size.width * .5, size.height, 0, size.height - 8)
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
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final plumPaint = Paint()
      ..color = plum
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .08, 7),
      Offset(size.width * .32, 7),
      plumPaint,
    );
    canvas.drawLine(
      Offset(size.width * .68, 7),
      Offset(size.width * .92, 7),
      cyanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _Federation2399CrownPainter oldDelegate) =>
      oldDelegate.structure != structure ||
      oldDelegate.border != border ||
      oldDelegate.cyan != cyan ||
      oldDelegate.plum != plum;
}

final class _Federation2399NavigationDeck extends StatelessWidget {
  const _Federation2399NavigationDeck({
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
      (Icons.track_changes_outlined, 'PLACEMENTS'),
      (Icons.notifications_outlined, 'ATTENTION'),
      (Icons.settings_outlined, 'SETTINGS'),
    ];
    final iconsOnly =
        compact || MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Container(
      key: const Key('federation-2399-bottom-navigation'),
      height: compact ? 64 : 72,
      decoration: BoxDecoration(
        color: context.clinicalColors.structureRaised,
        border: Border.all(color: context.clinicalColors.insetBorder),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: context.clinicalColors.workMachinery.withValues(alpha: .14),
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
                  key: Key('federation-2399-navigation-$index'),
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
                        bottom: BorderSide(
                          color: index == selectedIndex
                              ? context.clinicalColors.clinical
                              : Colors.transparent,
                          width: 4,
                        ),
                        right: index < destinations.length - 1
                            ? BorderSide(
                                color: context.clinicalColors.insetBorder
                                    .withValues(alpha: .5),
                              )
                            : BorderSide.none,
                      ),
                    ),
                    child: Center(
                      child: iconsOnly
                          ? Icon(
                              destinations[index].$1,
                              color: index == selectedIndex
                                  ? context.clinicalColors.workMachinery
                                  : null,
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  destinations[index].$1,
                                  color: index == selectedIndex
                                      ? context.clinicalColors.workMachinery
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(destinations[index].$2),
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
  }
}
