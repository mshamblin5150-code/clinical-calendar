import 'package:flutter/material.dart';

import 'additive_theme_shell.dart';
import 'calendar/calendar_period_view.dart';
import 'heritage_field_notes_frame.dart';
import 'heritage_field_notes_theme.dart';
import 'responsive_shell.dart';
import 'variant_f_theme.dart';

const heritageFieldNotesCompactDestinationInsets = EdgeInsets.fromLTRB(
  18,
  20,
  18,
  22,
);

Widget _buildHeritageFieldNotesFrame(
  Widget child,
  EdgeInsets chromeInsets,
  EdgeInsets contentPadding,
) => HeritageFieldNotesNineSliceFrame(
  chromeInsets: chromeInsets,
  contentPadding: contentPadding,
  child: child,
);

final class HeritageFieldNotesDestinationSurface extends StatelessWidget {
  const HeritageFieldNotesDestinationSurface({
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
    frameBuilder: _buildHeritageFieldNotesFrame,
    statusSafeInsets: heritageFieldNotesStatusSafeInsets,
    compactDestinationInsets: heritageFieldNotesCompactDestinationInsets,
    child: child,
  );
}

final class HeritageFieldNotesApplicationShell extends StatelessWidget {
  const HeritageFieldNotesApplicationShell({
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
    key: const Key('heritage-field-notes-landscape-shell'),
    backgroundColor: HeritageFieldNotesColors.canvas,
    body: Stack(
      fit: StackFit.expand,
      children: [
        HeritageFieldNotesNineSliceFrame(
          chromeInsets: const EdgeInsets.fromLTRB(60, 28, 60, 46),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              return Stack(
                children: [
                  Positioned(
                    left: width * .005,
                    top: height * .006,
                    width: width * .99,
                    height: height * .082,
                    child: _HeritageFieldNotesCommandCrown(
                      environmentName: environmentName,
                      onOpenMenu: onOpenMenu,
                      onAddSchedule: onAddSchedule,
                      onOpenDestination: onOpenDestination,
                      profileAvatar: slots.profileAvatar,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: height * .06,
                    width: width * .19,
                    height: height * .84,
                    child: _HeritageFieldNotesConsoleBay(
                      key: const Key('heritage-field-notes-placement-bay'),
                      accent: _HeritageFieldNotesBayAccent.brass,
                      shape: _HeritageFieldNotesBayShape.placement,
                      child: slots.placementDock,
                    ),
                  ),
                  Positioned(
                    left: width * .21,
                    top: height * .06,
                    width: width * .555,
                    height: height * .585,
                    child: _HeritageFieldNotesConsoleBay(
                      key: const Key('heritage-field-notes-calendar-bay'),
                      accent: _HeritageFieldNotesBayAccent.forest,
                      shape: _HeritageFieldNotesBayShape.calendar,
                      child: _HeritageFieldNotesCalendarViewport(
                        child: slots.centralContent,
                      ),
                    ),
                  ),
                  Positioned(
                    left: width * .21,
                    top: height * .655,
                    width: width * .555,
                    height: height * .245,
                    child: _HeritageFieldNotesConsoleBay(
                      key: const Key('heritage-field-notes-planning-bay'),
                      accent: _HeritageFieldNotesBayAccent.forest,
                      shape: _HeritageFieldNotesBayShape.planning,
                      child: VariantFPlanningBayMode(
                        expandedByDefault: true,
                        child: slots.planningRegion,
                      ),
                    ),
                  ),
                  Positioned(
                    left: width * .775,
                    top: height * .06,
                    width: width * .225,
                    height: height * .84,
                    child: _HeritageFieldNotesConsoleBay(
                      key: const Key('heritage-field-notes-insight-bay'),
                      accent: _HeritageFieldNotesBayAccent.brass,
                      shape: _HeritageFieldNotesBayShape.insight,
                      child: slots.insightRail,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: height * .904,
                    width: width,
                    height: height * .084,
                    child: _HeritageFieldNotesNavigationDeck(
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
        const Positioned(
          right: 5,
          top: 126,
          bottom: 126,
          width: 30,
          child: _HeritageFieldNotesIndexTabs(),
        ),
      ],
    ),
  );

  Widget _portrait() => Scaffold(
    key: const Key('heritage-field-notes-portrait-shell'),
    backgroundColor: HeritageFieldNotesColors.canvas,
    body: SafeArea(
      child: HeritageFieldNotesNineSliceFrame(
        chromeInsets: const EdgeInsets.fromLTRB(24, 28, 24, 30),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
          child: Column(
            children: [
              _HeritageFieldNotesCommandCrown(
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
                      key: const Key('heritage-field-notes-portrait-scroll'),
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
                              child: _HeritageFieldNotesConsoleBay(
                                key: const Key(
                                  'heritage-field-notes-calendar-bay',
                                ),
                                accent: _HeritageFieldNotesBayAccent.forest,
                                shape: _HeritageFieldNotesBayShape.calendar,
                                child: _HeritageFieldNotesCalendarViewport(
                                  child: slots.centralContent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              flex: 3,
                              child: _HeritageFieldNotesConsoleBay(
                                key: const Key(
                                  'heritage-field-notes-planning-bay',
                                ),
                                accent: _HeritageFieldNotesBayAccent.forest,
                                shape: _HeritageFieldNotesBayShape.planning,
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
                                    child: _HeritageFieldNotesConsoleBay(
                                      key: const Key(
                                        'heritage-field-notes-placement-bay',
                                      ),
                                      accent:
                                          _HeritageFieldNotesBayAccent.brass,
                                      shape:
                                          _HeritageFieldNotesBayShape.placement,
                                      child: slots.mobilePlacementSummary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _HeritageFieldNotesConsoleBay(
                                      key: const Key(
                                        'heritage-field-notes-insight-bay',
                                      ),
                                      accent:
                                          _HeritageFieldNotesBayAccent.brass,
                                      shape:
                                          _HeritageFieldNotesBayShape.insight,
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
              _HeritageFieldNotesNavigationDeck(
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
    key: const Key('heritage-field-notes-compact-shell'),
    slots: slots,
    environmentName: environmentName,
    onOpenMenu: onOpenMenu,
    onOpenDestination: onOpenDestination,
    onOpenAttention: onOpenAttention,
    onAddSchedule: onAddSchedule,
    mobileIndex: mobileIndex,
    frameBuilder: _buildHeritageFieldNotesFrame,
    calendarSafeInsets: heritageFieldNotesCalendarSafeInsets,
    placementsSafeInsets: heritageFieldNotesPlacementsSafeInsets,
    planningSafeInsets: heritageFieldNotesPlanningSafeInsets,
    statusSafeInsets: heritageFieldNotesStatusSafeInsets,
  );
}

enum _HeritageFieldNotesBayAccent { forest, brass }

enum _HeritageFieldNotesBayShape { placement, calendar, planning, insight }

final class _HeritageFieldNotesCalendarViewport extends StatelessWidget {
  const _HeritageFieldNotesCalendarViewport({required this.child});

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
        key: const Key('heritage-field-notes-calendar-horizontal-scroll'),
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

final class _HeritageFieldNotesConsoleBay extends StatelessWidget {
  const _HeritageFieldNotesConsoleBay({
    required this.accent,
    required this.shape,
    required this.child,
    super.key,
  });

  final _HeritageFieldNotesBayAccent accent;
  final _HeritageFieldNotesBayShape shape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.clinicalColors;
    final accentColor = switch (accent) {
      _HeritageFieldNotesBayAccent.forest => colors.clinical,
      _HeritageFieldNotesBayAccent.brass => colors.protectedDayAccent,
    };
    final content = ClipPath(
      clipper: _HeritageFieldNotesBayClipper(shape),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          shape == _HeritageFieldNotesBayShape.placement ? 14 : 12,
          20,
          shape == _HeritageFieldNotesBayShape.insight ? 14 : 12,
          18,
        ),
        child: child,
      ),
    );
    return CustomPaint(
      painter: _HeritageFieldNotesConsoleBayPainter(
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

final class _HeritageFieldNotesConsoleBayPainter extends CustomPainter {
  const _HeritageFieldNotesConsoleBayPainter({
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
  final _HeritageFieldNotesBayShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final outer = _heritageFieldNotesBayPath(size, shape);
    canvas.drawPath(outer, Paint()..color = raised);
    canvas.drawPath(
      outer,
      Paint()
        ..color = border.withValues(alpha: .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final inner = _heritageFieldNotesBayPath(size, shape, inset: 7);
    canvas.drawPath(inner, Paint()..color = surface);
    canvas.drawPath(
      inner,
      Paint()
        ..color = border.withValues(alpha: .32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawRect(
      Rect.fromLTWH(7, 18, 6, size.height - 36),
      Paint()..color = accent,
    );
    canvas.drawLine(
      const Offset(22, 11),
      Offset(size.width - 18, 11),
      Paint()
        ..color = border.withValues(alpha: .55)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(
    covariant _HeritageFieldNotesConsoleBayPainter oldDelegate,
  ) =>
      oldDelegate.surface != surface ||
      oldDelegate.raised != raised ||
      oldDelegate.border != border ||
      oldDelegate.accent != accent ||
      oldDelegate.shape != shape;
}

Path _heritageFieldNotesBayPath(
  Size size,
  _HeritageFieldNotesBayShape shape, {
  double inset = 0,
}) {
  final left = inset;
  final top = inset;
  final right = size.width - inset;
  final bottom = size.height - inset;
  return Path()..addRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, bottom),
      const Radius.circular(6),
    ),
  );
}

final class _HeritageFieldNotesBayClipper extends CustomClipper<Path> {
  const _HeritageFieldNotesBayClipper(this.shape);

  final _HeritageFieldNotesBayShape shape;

  @override
  Path getClip(Size size) => _heritageFieldNotesBayPath(size, shape, inset: 10);

  @override
  bool shouldReclip(covariant _HeritageFieldNotesBayClipper oldClipper) =>
      oldClipper.shape != shape;
}

final class _HeritageFieldNotesCommandCrown extends StatelessWidget {
  const _HeritageFieldNotesCommandCrown({
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
    final content = SizedBox(
      key: const Key('heritage-field-notes-command-crown'),
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
                                  : 'CLINICAL CALENDAR  ·  FIELD ARCHIVE',
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
    return CustomPaint(
      painter: _HeritageFieldNotesCrownPainter(
        structure: context.clinicalColors.structureRaised,
        border: context.clinicalColors.insetBorder,
        brass: context.clinicalColors.workMachinery,
        forest: context.clinicalColors.clinical,
      ),
      child: content,
    );
  }
}

final class _HeritageFieldNotesCrownPainter extends CustomPainter {
  const _HeritageFieldNotesCrownPainter({
    required this.structure,
    required this.border,
    required this.brass,
    required this.forest,
  });

  final Color structure;
  final Color border;
  final Color brass;
  final Color forest;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)),
      );
    canvas.drawPath(path, Paint()..color = structure);
    canvas.drawPath(
      path,
      Paint()
        ..color = border.withValues(alpha: .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final brassPaint = Paint()
      ..color = brass
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final forestPaint = Paint()
      ..color = forest
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(14, 7),
      Offset(size.width * .62, 7),
      forestPaint,
    );
    canvas.drawLine(
      Offset(size.width * .82, 7),
      Offset(size.width - 14, 7),
      brassPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HeritageFieldNotesCrownPainter oldDelegate) =>
      oldDelegate.structure != structure ||
      oldDelegate.border != border ||
      oldDelegate.brass != brass ||
      oldDelegate.forest != forest;
}

final class _HeritageFieldNotesNavigationDeck extends StatelessWidget {
  const _HeritageFieldNotesNavigationDeck({
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
      key: const Key('heritage-field-notes-bottom-navigation'),
      height: compact ? 68 : 82,
      decoration: BoxDecoration(
        color: context.clinicalColors.structureRaised,
        border: Border.all(color: context.clinicalColors.insetBorder),
        borderRadius: BorderRadius.circular(4),
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
                  key: Key('heritage-field-notes-navigation-$index'),
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
                                  ? context.clinicalColors.clinical
                                  : null,
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  destinations[index].$1,
                                  color: index == selectedIndex
                                      ? context.clinicalColors.clinical
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

final class _HeritageFieldNotesIndexTabs extends StatelessWidget {
  const _HeritageFieldNotesIndexTabs();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < 7; index++)
            Container(
              width: index.isEven ? 30 : 24,
              height: index == 3 ? 92 : 68,
              decoration: BoxDecoration(
                color: index.isEven
                    ? HeritageFieldNotesColors.protectedDayAccent
                    : const Color(0xFF5A3A28),
                border: Border.all(color: const Color(0xFFD2A74B), width: 1.5),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(6),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
