import 'package:flutter/material.dart';

import 'additive_theme_shell.dart';
import 'calendar/calendar_period_view.dart';
import 'canonical_delta_mark.dart';
import 'federation_classic_frame.dart';
import 'federation_classic_theme.dart';
import 'insight_rail_presentation_policy.dart';
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
    backgroundColor: const Color(0xFF02040D),
    body: FederationClassicLandscapeChassis(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final size = Size(width, height);
          Rect rect(Rect conceptRect) =>
              FederationClassicLandscapeGeometry.scale(conceptRect, size);
          return Stack(
            children: [
              Positioned.fromRect(
                rect: rect(FederationClassicLandscapeGeometry.crown),
                child: _FederationClassicCommandCrown(
                  onOpenMenu: onOpenMenu,
                  onAddSchedule: onAddSchedule,
                  onOpenDestination: onOpenDestination,
                  profileAvatar: slots.profileAvatar,
                  integrated: true,
                ),
              ),
              Positioned.fromRect(
                rect: rect(FederationClassicLandscapeGeometry.placements),
                child: _FederationClassicConsoleBay(
                  key: const Key('federation-classic-placement-bay'),
                  accent: _FederationClassicBayAccent.lilac,
                  shape: _FederationClassicBayShape.placement,
                  integrated: true,
                  child: slots.placementDock,
                ),
              ),
              Positioned.fromRect(
                rect: rect(FederationClassicLandscapeGeometry.calendar),
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
              Positioned.fromRect(
                rect: rect(FederationClassicLandscapeGeometry.planning),
                child: _FederationClassicConsoleBay(
                  key: const Key('federation-classic-planning-bay'),
                  accent: _FederationClassicBayAccent.salmon,
                  shape: _FederationClassicBayShape.planning,
                  integrated: true,
                  child: VariantFPlanningBayMode(
                    expandedByDefault: false,
                    child: slots.planningRegion,
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: rect(FederationClassicLandscapeGeometry.insight),
                child: _FederationClassicConsoleBay(
                  key: const Key('federation-classic-insight-bay'),
                  accent: _FederationClassicBayAccent.lilac,
                  shape: _FederationClassicBayShape.insight,
                  integrated: true,
                  child: InsightRailPresentationPolicy(
                    placementProgressLayout:
                        PlacementProgressRailLayout.sideBySide,
                    expandedAttentionRows: true,
                    outlinedAttentionRows: true,
                    child: slots.insightRail,
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: rect(FederationClassicLandscapeGeometry.navigation),
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
        chromeInsets: const EdgeInsets.fromLTRB(30, 24, 30, 34),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Column(
            children: [
              _FederationClassicCommandCrown(
                onOpenMenu: onOpenMenu,
                onAddSchedule: onAddSchedule,
                onOpenDestination: onOpenDestination,
                profileAvatar: slots.profileAvatar,
                compact: true,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 112,
                      child: _FederationClassicNavigationDeck(
                        selectedIndex: mobileIndex,
                        onOpenDestination: onOpenDestination,
                        onOpenAttention: onOpenAttention,
                        compact: true,
                        vertical: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final enlargedText =
                              MediaQuery.textScalerOf(context).scale(1) > 1.3;
                          return SingleChildScrollView(
                            key: const Key(
                              'federation-classic-portrait-scroll',
                            ),
                            primary: true,
                            child: SizedBox(
                              height:
                                  constraints.maxHeight *
                                  (enlargedText ? 2.2 : 1.6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 8,
                                    child: _FederationClassicConsoleBay(
                                      key: const Key(
                                        'federation-classic-calendar-bay',
                                      ),
                                      accent:
                                          _FederationClassicBayAccent.salmon,
                                      shape:
                                          _FederationClassicBayShape.calendar,
                                      child: _FederationClassicCalendarViewport(
                                        scrollAtEnlargedText: true,
                                        child: slots.centralContent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    flex: 4,
                                    child: _FederationClassicConsoleBay(
                                      key: const Key(
                                        'federation-classic-planning-bay',
                                      ),
                                      accent:
                                          _FederationClassicBayAccent.salmon,
                                      shape:
                                          _FederationClassicBayShape.planning,
                                      child: VariantFPlanningBayMode(
                                        expandedByDefault: false,
                                        child: slots.planningRegion,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    flex: 4,
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
                                  const SizedBox(height: 10),
                                  Expanded(
                                    flex: 5,
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
                          );
                        },
                      ),
                    ),
                  ],
                ),
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
  const _FederationClassicCalendarViewport({
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
        toolbarLayout: CalendarPeriodToolbarLayout.stackedCentered,
        compactWeekdayLabels: true,
        uppercasePeriodTitle: true,
        monthWeekRows: 7,
        todayAccentOverride: FederationClassicColors.scheduled,
        todayBackgroundOverride: FederationClassicColors.canvas,
        child: child,
      );
      return buildEnlargedTextCalendarScrollViewport(
        context: context,
        constraints: constraints,
        enabled: scrollAtEnlargedText,
        scrollKey: const Key('federation-classic-calendar-horizontal-scroll'),
        child: calendar,
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
        // The landscape positions are the concept's rail-safe interior bays;
        // these offsets align live content within those already-safe bounds.
        padding: integrated
            ? switch (shape) {
                _FederationClassicBayShape.placement =>
                  const EdgeInsets.fromLTRB(20, 14, 5, 10),
                _FederationClassicBayShape.calendar => EdgeInsets.zero,
                _FederationClassicBayShape.planning =>
                  const EdgeInsets.fromLTRB(12, 10, 12, 10),
                _FederationClassicBayShape.insight => const EdgeInsets.fromLTRB(
                  2,
                  8,
                  14,
                  10,
                ),
              }
            : EdgeInsets.fromLTRB(
                shape == _FederationClassicBayShape.placement ? 14 : 12,
                20,
                shape == _FederationClassicBayShape.insight ? 14 : 12,
                18,
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
    required this.onOpenMenu,
    required this.onAddSchedule,
    required this.onOpenDestination,
    required this.profileAvatar,
    this.compact = false,
    this.integrated = false,
  });

  final VoidCallback onOpenMenu;
  final VoidCallback onAddSchedule;
  final ValueChanged<ClinicalCalendarDestination> onOpenDestination;
  final Widget profileAvatar;
  final bool compact;
  final bool integrated;

  @override
  Widget build(BuildContext context) {
    if (integrated) {
      return SizedBox(
        key: const Key('federation-classic-command-crown'),
        child: Row(
          children: [
            SizedBox(
              width: 280,
              child: Tooltip(
                message: 'Open menu',
                child: InkWell(
                  key: const Key('application-menu-action'),
                  onTap: onOpenMenu,
                  borderRadius: BorderRadius.circular(8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const _FederationClassicAxionDeltaMark(size: 44),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: const _FederationClassicProductTitle(
                              fontSize: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 170,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: SizedBox(
                  width: 139,
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 139,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF02040D),
                          border: Border.all(
                            color: context.clinicalColors.scheduled,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(23),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        width: 48,
                        height: 44,
                        child: IconButton(
                          tooltip: 'Add schedule',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 48,
                            height: 44,
                          ),
                          onPressed: onAddSchedule,
                          icon: const Icon(Icons.add, size: 30),
                        ),
                      ),
                      Positioned(
                        left: 81,
                        width: 44,
                        height: 44,
                        child: PopupMenuButton<ClinicalCalendarDestination>(
                          key: const Key('federation-classic-help-menu'),
                          tooltip: 'Profile and Help',
                          onSelected: onOpenDestination,
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: ClinicalCalendarDestination.help,
                              child: Text('Help'),
                            ),
                            PopupMenuItem(
                              value: ClinicalCalendarDestination.studentProfile,
                              child: Text('Student Profile'),
                            ),
                          ],
                          child: Center(
                            child: SizedBox.square(
                              dimension: 36,
                              child: IgnorePointer(child: profileAvatar),
                            ),
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
    final content = SizedBox(
      key: const Key('federation-classic-command-crown'),
      height: compact ? 72 : 92,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            Tooltip(
              message: 'Open menu',
              child: InkWell(
                key: const Key('application-menu-action'),
                onTap: onOpenMenu,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: _FederationClassicAxionDeltaMark(size: 48),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _FederationClassicProductTitle(
                  fontSize: compact ? 24 : 30,
                ),
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

final class _FederationClassicAxionDeltaMark extends StatelessWidget {
  const _FederationClassicAxionDeltaMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CanonicalDeltaMark(
      key: const Key('federation-classic-axion-delta'),
      size: size,
    ),
  );
}

final class _FederationClassicProductTitle extends StatelessWidget {
  const _FederationClassicProductTitle({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) => Text(
    'CLINICAL CALENDAR',
    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
      color: const Color(0xFFFFE4BE),
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: .1,
    ),
  );
}

enum _FederationClassicNavigationItem {
  today(Icons.today_outlined, 'TODAY'),
  calendar(Icons.calendar_month_outlined, 'CALENDAR'),
  placements(Icons.groups_outlined, 'PLACEMENTS'),
  attention(Icons.notifications_outlined, 'ATTENTION'),
  settings(Icons.settings_outlined, 'SETTINGS');

  const _FederationClassicNavigationItem(this.icon, this.label);

  final IconData icon;
  final String label;

  void activate(
    ValueChanged<ClinicalCalendarDestination> onOpenDestination,
    VoidCallback onOpenAttention,
  ) {
    switch (this) {
      case today:
      case calendar:
        onOpenDestination(ClinicalCalendarDestination.calendar);
      case placements:
        onOpenDestination(ClinicalCalendarDestination.clinicalPlacements);
      case attention:
        onOpenAttention();
      case settings:
        onOpenDestination(ClinicalCalendarDestination.settings);
    }
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
    this.vertical = false,
  });

  final int selectedIndex;
  final ValueChanged<ClinicalCalendarDestination> onOpenDestination;
  final VoidCallback onOpenAttention;
  final bool compact;
  final bool integrated;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    const destinations = _FederationClassicNavigationItem.values;
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconsOnly =
            vertical ||
            compact ||
            (!integrated && constraints.maxWidth < 900) ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3;
        if (integrated) {
          const buttonRects = [
            Rect.fromLTWH(144, 11, 146, 75),
            Rect.fromLTWH(355, 11, 289, 75),
            Rect.fromLTWH(680, 11, 200, 75),
            Rect.fromLTWH(950, 11, 215, 75),
            Rect.fromLTWH(1223, 11, 161, 75),
          ];
          final scaleX = constraints.maxWidth / 1566;
          final scaleY = constraints.maxHeight / 97;
          return SizedBox(
            key: const Key('federation-classic-bottom-navigation'),
            child: Stack(
              children: [
                for (var index = 0; index < destinations.length; index++)
                  Positioned.fromRect(
                    rect: Rect.fromLTWH(
                      buttonRects[index].left * scaleX,
                      buttonRects[index].top * scaleY,
                      buttonRects[index].width * scaleX,
                      buttonRects[index].height * scaleY,
                    ),
                    child: _FederationClassicNavigationButton(
                      item: destinations[index],
                      index: index,
                      selected: index == selectedIndex,
                      iconsOnly: iconsOnly,
                      onOpenDestination: onOpenDestination,
                      onOpenAttention: onOpenAttention,
                    ),
                  ),
              ],
            ),
          );
        }
        return Container(
          key: const Key('federation-classic-bottom-navigation'),
          height: vertical ? constraints.maxHeight : (compact ? 68 : 92),
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
          child: Padding(
            padding: integrated
                ? const EdgeInsets.only(left: 153, right: 181)
                : EdgeInsets.zero,
            child: Flex(
              direction: vertical ? Axis.vertical : Axis.horizontal,
              children: [
                for (var index = 0; index < destinations.length; index++)
                  Expanded(
                    flex: integrated ? const [4, 6, 5, 5, 5][index] : 1,
                    child: Semantics(
                      button: true,
                      selected: index == selectedIndex,
                      label: destinations[index].label,
                      child: InkWell(
                        key: Key('federation-classic-navigation-$index'),
                        onTap: () => destinations[index].activate(
                          onOpenDestination,
                          onOpenAttention,
                        ),
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
                                    destinations[index].icon,
                                    color: index == selectedIndex
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimary
                                        : null,
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        destinations[index].icon,
                                        color: index == selectedIndex
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onPrimary
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        destinations[index].label,
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
          ),
        );
      },
    );
  }
}

final class _FederationClassicNavigationButton extends StatelessWidget {
  const _FederationClassicNavigationButton({
    required this.item,
    required this.index,
    required this.selected,
    required this.iconsOnly,
    required this.onOpenDestination,
    required this.onOpenAttention,
  });

  final _FederationClassicNavigationItem item;
  final int index;
  final bool selected;
  final bool iconsOnly;
  final ValueChanged<ClinicalCalendarDestination> onOpenDestination;
  final VoidCallback onOpenAttention;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: item.label,
    child: InkWell(
      key: Key('federation-classic-navigation-$index'),
      onTap: () => item.activate(onOpenDestination, onOpenAttention),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(34),
        ),
        child: Center(
          child: iconsOnly
              ? Icon(
                  item.icon,
                  color: selected
                      ? Theme.of(context).colorScheme.onPrimary
                      : context.clinicalColors.workMachinery,
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: 7,
                      child: Icon(
                        item.icon,
                        size: 30,
                        color: selected
                            ? Theme.of(context).colorScheme.onPrimary
                            : context.clinicalColors.workMachinery,
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: selected
                              ? Theme.of(context).colorScheme.onPrimary
                              : context.clinicalColors.workMachinery,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 16,
                          letterSpacing: .6,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );
}
