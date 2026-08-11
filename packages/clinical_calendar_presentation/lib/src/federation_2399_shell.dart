import 'package:flutter/material.dart';

import 'additive_theme_shell.dart';
import 'calendar/calendar_period_view.dart';
import 'canonical_delta_mark.dart';
import 'federation_2399_console_scope.dart';
import 'federation_2399_frame.dart';
import 'placements/placement_progress_widgets.dart';
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
    backgroundColor: const Color(0xFF07080D),
    body: Federation2399LandscapeChassis(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return Stack(
            children: [
              Positioned(
                left: width * .026,
                top: height * .044,
                width: width * .68,
                height: height * .074,
                child: _Federation2399CommandCrown(
                  environmentName: environmentName,
                  onOpenMenu: onOpenMenu,
                  onOpenDestination: onOpenDestination,
                  profileAvatar: slots.profileAvatar,
                  integrated: true,
                ),
              ),
              Positioned(
                left: width * .035,
                top: height * .128,
                width: width * .17,
                height: height * .73,
                child: _Federation2399ConsoleBay(
                  key: const Key('federation-2399-placement-bay'),
                  accent: _Federation2399BayAccent.cyan,
                  shape: _Federation2399BayShape.placement,
                  integrated: true,
                  child: slots.placementDock,
                ),
              ),
              Positioned(
                left: width * .235,
                top: height * .13,
                width: width * .478,
                height: height * .447,
                child: _Federation2399ConsoleBay(
                  key: const Key('federation-2399-calendar-bay'),
                  accent: _Federation2399BayAccent.plum,
                  shape: _Federation2399BayShape.calendar,
                  integrated: true,
                  child: _Federation2399CalendarViewport(
                    child: slots.centralContent,
                  ),
                ),
              ),
              Positioned(
                left: width * .235,
                top: height * .61,
                width: width * .478,
                height: height * .245,
                child: _Federation2399ConsoleBay(
                  key: const Key('federation-2399-planning-bay'),
                  accent: _Federation2399BayAccent.plum,
                  shape: _Federation2399BayShape.planning,
                  integrated: true,
                  child: VariantFPlanningBayMode(
                    expandedByDefault: true,
                    child: slots.planningRegion,
                  ),
                ),
              ),
              Positioned(
                left: width * .754,
                top: height * .083,
                width: width * .225,
                height: height * .772,
                child: _Federation2399ConsoleBay(
                  key: const Key('federation-2399-insight-bay'),
                  accent: _Federation2399BayAccent.cyan,
                  shape: _Federation2399BayShape.insight,
                  integrated: true,
                  child: slots.insightRail,
                ),
              ),
              Positioned(
                left: width * .056,
                top: height * .895,
                width: width * .888,
                height: height * .068,
                child: _Federation2399NavigationDeck(
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
    key: const Key('federation-2399-portrait-shell'),
    backgroundColor: const Color(0xFF07080D),
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
                      key: const Key('federation-2399-portrait-scroll'),
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
                              child: _Federation2399ConsoleBay(
                                key: const Key('federation-2399-calendar-bay'),
                                accent: _Federation2399BayAccent.plum,
                                shape: _Federation2399BayShape.calendar,
                                child: _Federation2399CalendarViewport(
                                  scrollAtEnlargedText: true,
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
                                shape: _Federation2399BayShape.planning,
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
                                      key: const Key(
                                        'federation-2399-placement-bay',
                                      ),
                                      accent: _Federation2399BayAccent.cyan,
                                      shape: _Federation2399BayShape.placement,
                                      child: slots.mobilePlacementSummary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _Federation2399ConsoleBay(
                                      key: const Key(
                                        'federation-2399-insight-bay',
                                      ),
                                      accent: _Federation2399BayAccent.cyan,
                                      shape: _Federation2399BayShape.insight,
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

enum _Federation2399BayShape { placement, calendar, planning, insight }

final class _Federation2399CalendarViewport extends StatelessWidget {
  const _Federation2399CalendarViewport({
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
        centerPeriodHeader: true,
        useConceptMonthMarks: true,
        suppressProtectedHatch: true,
        clipDayDecoration: true,
        child: Federation2399ConsoleScope(child: child),
      );
      return buildEnlargedTextCalendarScrollViewport(
        context: context,
        constraints: constraints,
        enabled: scrollAtEnlargedText,
        scrollKey: const Key('federation-2399-calendar-horizontal-scroll'),
        child: calendar,
      );
    },
  );
}

final class _Federation2399ConsoleBay extends StatelessWidget {
  const _Federation2399ConsoleBay({
    required this.accent,
    required this.shape,
    required this.child,
    this.integrated = false,
    super.key,
  });

  final _Federation2399BayAccent accent;
  final _Federation2399BayShape shape;
  final Widget child;
  final bool integrated;

  @override
  Widget build(BuildContext context) {
    final colors = context.clinicalColors;
    final accentColor = switch (accent) {
      _Federation2399BayAccent.plum => colors.clinical,
      _Federation2399BayAccent.cyan => colors.workMachinery,
    };
    final content = ClipPath(
      clipper: integrated ? null : _Federation2399BayClipper(shape),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          shape == _Federation2399BayShape.placement ? 14 : 12,
          integrated && shape == _Federation2399BayShape.placement
              ? 32
              : integrated
              ? 10
              : 20,
          shape == _Federation2399BayShape.insight ? 14 : 12,
          integrated ? 10 : 18,
        ),
        child: Federation2399ConsoleScope(child: child),
      ),
    );
    if (integrated) {
      final integratedContent = shape == _Federation2399BayShape.insight
          ? PlacementProgressPanelPolicy(
              wheelAlignment: Alignment.centerLeft,
              wheelPadding: const EdgeInsets.only(left: 30),
              compactLedger: true,
              conceptActionRail: true,
              emphasizeProjection: true,
              child: content,
            )
          : content;
      return EmbeddedPlacementPanelInterior(child: integratedContent);
    }
    return CustomPaint(
      painter: _Federation2399ConsoleBayPainter(
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

final class _Federation2399ConsoleBayPainter extends CustomPainter {
  const _Federation2399ConsoleBayPainter({
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
  final _Federation2399BayShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final outer = _federation2399BayPath(size, shape);
    canvas.drawPath(
      outer,
      Paint()
        ..color = Color.lerp(raised, accent, .10)!
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      outer,
      Paint()
        ..color = accent.withValues(alpha: .30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9,
    );
    canvas.drawPath(
      outer,
      Paint()
        ..color = border.withValues(alpha: .54)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final inner = _federation2399BayPath(size, shape, inset: 10);
    canvas.drawPath(inner, Paint()..color = surface);
    canvas.drawPath(
      inner,
      Paint()
        ..color = const Color(0xFFC9CCD3).withValues(alpha: .28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
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
      oldDelegate.accent != accent ||
      oldDelegate.shape != shape;
}

Path _federation2399BayPath(
  Size size,
  _Federation2399BayShape shape, {
  double inset = 0,
}) {
  final left = inset;
  final top = inset;
  final right = size.width - inset;
  final bottom = size.height - inset;
  final shoulder = switch (shape) {
    _Federation2399BayShape.placement => 32.0,
    _Federation2399BayShape.calendar => 44.0,
    _Federation2399BayShape.planning => 38.0,
    _Federation2399BayShape.insight => 30.0,
  };
  final path = Path()
    ..moveTo(left + shoulder, top)
    ..lineTo(right - shoulder * .7, top)
    ..quadraticBezierTo(right, top, right, top + shoulder)
    ..lineTo(right, bottom - shoulder);
  if (shape == _Federation2399BayShape.insight) {
    path
      ..quadraticBezierTo(right - 5, bottom - 5, right - shoulder, bottom)
      ..lineTo(left + shoulder * .6, bottom);
  } else {
    path
      ..quadraticBezierTo(right, bottom, right - shoulder, bottom)
      ..lineTo(left + shoulder, bottom);
  }
  path
    ..quadraticBezierTo(left, bottom, left, bottom - shoulder)
    ..lineTo(left, top + shoulder)
    ..quadraticBezierTo(left, top, left + shoulder, top)
    ..close();
  return path;
}

final class _Federation2399BayClipper extends CustomClipper<Path> {
  const _Federation2399BayClipper(this.shape);

  final _Federation2399BayShape shape;

  @override
  Path getClip(Size size) => _federation2399BayPath(size, shape, inset: 10);

  @override
  bool shouldReclip(covariant _Federation2399BayClipper oldClipper) =>
      oldClipper.shape != shape;
}

final class _Federation2399CommandCrown extends StatelessWidget {
  const _Federation2399CommandCrown({
    required this.environmentName,
    required this.onOpenMenu,
    required this.onOpenDestination,
    required this.profileAvatar,
    this.compact = false,
    this.integrated = false,
  });

  final String environmentName;
  final VoidCallback onOpenMenu;
  final ValueChanged<ClinicalCalendarDestination> onOpenDestination;
  final Widget profileAvatar;
  final bool compact;
  final bool integrated;

  @override
  Widget build(BuildContext context) {
    final enlargedText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final content = SizedBox(
      key: const Key('federation-2399-command-crown'),
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
              SizedBox.square(
                dimension: compact ? 34 : 42,
                child: const CanonicalDeltaMark(semanticLabel: 'Axion delta'),
              ),
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
            Container(
              key: const Key('federation-2399-crown-controls'),
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: context.clinicalColors.canvas.withValues(alpha: .82),
                border: Border.all(
                  color: context.clinicalColors.workMachinery.withValues(
                    alpha: .68,
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Help',
                    onPressed: () =>
                        onOpenDestination(ClinicalCalendarDestination.help),
                    icon: const Icon(Icons.help_outline),
                  ),
                  const SizedBox(width: 2),
                  Tooltip(
                    message: 'Add Placement',
                    child: TextButton.icon(
                      key: const Key('federation-2399-add-placement'),
                      onPressed: () => onOpenDestination(
                        ClinicalCalendarDestination.clinicalPlacements,
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: Text(compact ? 'PLACEMENT' : 'ADD PLACEMENT'),
                    ),
                  ),
                  Container(
                    key: const Key('federation-2399-profile-control-housing'),
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.clinicalColors.clinical.withValues(
                        alpha: .12,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                    child: profileAvatar,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (integrated) return content;
    return CustomPaint(
      painter: _Federation2399CrownPainter(
        structure: context.clinicalColors.structureRaised,
        border: context.clinicalColors.insetBorder,
        cyan: context.clinicalColors.workMachinery,
        plum: context.clinicalColors.clinical,
      ),
      child: content,
    );
  }
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
    final iconsOnly =
        compact || MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Container(
      key: const Key('federation-2399-bottom-navigation'),
      height: compact ? 68 : 82,
      decoration: BoxDecoration(
        color: integrated
            ? Colors.transparent
            : context.clinicalColors.structureRaised,
        border: integrated
            ? null
            : Border.all(color: context.clinicalColors.insetBorder),
        borderRadius: BorderRadius.circular(38),
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
