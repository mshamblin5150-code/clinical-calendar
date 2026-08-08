import 'package:flutter/material.dart';

import 'additive_theme_shell.dart';
import 'calendar/calendar_period_view.dart';
import 'coastal_light_frame.dart';
import 'responsive_shell.dart';
import 'variant_f_theme.dart';

const coastalLightCompactDestinationInsets = EdgeInsets.fromLTRB(
  18,
  20,
  18,
  22,
);

Widget _buildCoastalLightFrame(
  Widget child,
  EdgeInsets chromeInsets,
  EdgeInsets contentPadding,
) => CoastalLightNineSliceFrame(
  chromeInsets: chromeInsets,
  contentPadding: contentPadding,
  child: child,
);

final class CoastalLightDestinationSurface extends StatelessWidget {
  const CoastalLightDestinationSurface({
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
    frameBuilder: _buildCoastalLightFrame,
    statusSafeInsets: coastalLightStatusSafeInsets,
    compactDestinationInsets: coastalLightCompactDestinationInsets,
    child: child,
  );
}

final class CoastalLightApplicationShell extends StatelessWidget {
  const CoastalLightApplicationShell({
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
    key: const Key('coastal-calm-landscape-shell'),
    backgroundColor: const Color(0xFFEEF5F4),
    body: CoastalLightLandscapeChassis(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return Stack(
            children: [
              Positioned(
                left: width * .018,
                top: height * .012,
                width: width * .964,
                height: height * .064,
                child: _CoastalLightCommandCrown(
                  environmentName: environmentName,
                  onOpenMenu: onOpenMenu,
                  onAddSchedule: onAddSchedule,
                  onOpenDestination: onOpenDestination,
                  profileAvatar: slots.profileAvatar,
                  integrated: true,
                ),
              ),
              Positioned(
                left: width * .033,
                top: height * .104,
                width: width * .18,
                height: height * .755,
                child: _CoastalLightConsoleBay(
                  key: const Key('coastal-calm-placement-bay'),
                  accent: _CoastalLightBayAccent.clearBlue,
                  shape: _CoastalLightBayShape.placement,
                  integrated: true,
                  child: slots.placementDock,
                ),
              ),
              Positioned(
                left: width * .244,
                top: height * .104,
                width: width * .493,
                height: height * .49,
                child: _CoastalLightConsoleBay(
                  key: const Key('coastal-calm-calendar-bay'),
                  accent: _CoastalLightBayAccent.seaGlass,
                  shape: _CoastalLightBayShape.calendar,
                  integrated: true,
                  child: _CoastalLightCalendarViewport(
                    child: slots.centralContent,
                  ),
                ),
              ),
              Positioned(
                left: width * .244,
                top: height * .635,
                width: width * .493,
                height: height * .215,
                child: _CoastalLightConsoleBay(
                  key: const Key('coastal-calm-planning-bay'),
                  accent: _CoastalLightBayAccent.seaGlass,
                  shape: _CoastalLightBayShape.planning,
                  integrated: true,
                  child: VariantFPlanningBayMode(
                    expandedByDefault: true,
                    child: slots.planningRegion,
                  ),
                ),
              ),
              Positioned(
                left: width * .771,
                top: height * .104,
                width: width * .192,
                height: height * .755,
                child: _CoastalLightConsoleBay(
                  key: const Key('coastal-calm-insight-bay'),
                  accent: _CoastalLightBayAccent.clearBlue,
                  shape: _CoastalLightBayShape.insight,
                  integrated: true,
                  child: slots.insightRail,
                ),
              ),
              Positioned(
                left: width * .02,
                top: height * .906,
                width: width * .96,
                height: height * .064,
                child: _CoastalLightNavigationDeck(
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
    key: const Key('coastal-calm-portrait-shell'),
    backgroundColor: const Color(0xFFEEF5F4),
    body: SafeArea(
      child: CoastalLightNineSliceFrame(
        chromeInsets: const EdgeInsets.fromLTRB(24, 28, 24, 30),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
          child: Column(
            children: [
              _CoastalLightCommandCrown(
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
                      key: const Key('coastal-calm-portrait-scroll'),
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
                              child: _CoastalLightConsoleBay(
                                key: const Key('coastal-calm-calendar-bay'),
                                accent: _CoastalLightBayAccent.seaGlass,
                                shape: _CoastalLightBayShape.calendar,
                                child: _CoastalLightCalendarViewport(
                                  child: slots.centralContent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              flex: 3,
                              child: _CoastalLightConsoleBay(
                                key: const Key('coastal-calm-planning-bay'),
                                accent: _CoastalLightBayAccent.seaGlass,
                                shape: _CoastalLightBayShape.planning,
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
                                    child: _CoastalLightConsoleBay(
                                      key: const Key(
                                        'coastal-calm-placement-bay',
                                      ),
                                      accent: _CoastalLightBayAccent.clearBlue,
                                      shape: _CoastalLightBayShape.placement,
                                      child: slots.mobilePlacementSummary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _CoastalLightConsoleBay(
                                      key: const Key(
                                        'coastal-calm-insight-bay',
                                      ),
                                      accent: _CoastalLightBayAccent.clearBlue,
                                      shape: _CoastalLightBayShape.insight,
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
              _CoastalLightNavigationDeck(
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
    key: const Key('coastal-calm-compact-shell'),
    slots: slots,
    environmentName: environmentName,
    onOpenMenu: onOpenMenu,
    onOpenDestination: onOpenDestination,
    onOpenAttention: onOpenAttention,
    onAddSchedule: onAddSchedule,
    mobileIndex: mobileIndex,
    frameBuilder: _buildCoastalLightFrame,
    calendarSafeInsets: coastalLightCalendarSafeInsets,
    placementsSafeInsets: coastalLightPlacementsSafeInsets,
    planningSafeInsets: coastalLightPlanningSafeInsets,
    statusSafeInsets: coastalLightStatusSafeInsets,
  );
}

enum _CoastalLightBayAccent { seaGlass, clearBlue }

enum _CoastalLightBayShape { placement, calendar, planning, insight }

final class _CoastalLightCalendarViewport extends StatelessWidget {
  const _CoastalLightCalendarViewport({required this.child});

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
        key: const Key('coastal-calm-calendar-horizontal-scroll'),
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

final class _CoastalLightConsoleBay extends StatelessWidget {
  const _CoastalLightConsoleBay({
    required this.accent,
    required this.shape,
    required this.child,
    this.integrated = false,
    super.key,
  });

  final _CoastalLightBayAccent accent;
  final _CoastalLightBayShape shape;
  final Widget child;
  final bool integrated;

  @override
  Widget build(BuildContext context) {
    final colors = context.clinicalColors;
    final accentColor = switch (accent) {
      _CoastalLightBayAccent.seaGlass => colors.clinical,
      _CoastalLightBayAccent.clearBlue => colors.workMachinery,
    };
    final content = ClipPath(
      clipper: integrated ? null : _CoastalLightBayClipper(shape),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          shape == _CoastalLightBayShape.placement ? 14 : 12,
          integrated ? 10 : 20,
          shape == _CoastalLightBayShape.insight ? 14 : 12,
          integrated ? 10 : 18,
        ),
        child: child,
      ),
    );
    if (integrated) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.structure,
          borderRadius: BorderRadius.circular(18),
        ),
        child: content,
      );
    }
    if (context.accessibilityTokens.decorationOpacity == 0) {
      return DecoratedBox(
        key: const Key('coastal-light-enhanced-flat-bay'),
        decoration: BoxDecoration(
          color: colors.structure,
          border: Border.all(color: colors.insetBorder, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: content,
      );
    }
    return CustomPaint(
      painter: _CoastalLightConsoleBayPainter(
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

final class _CoastalLightConsoleBayPainter extends CustomPainter {
  const _CoastalLightConsoleBayPainter({
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
  final _CoastalLightBayShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final outer = _coastalLightBayPath(size, shape);
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
    final inner = _coastalLightBayPath(size, shape, inset: 10);
    canvas.drawPath(inner, Paint()..color = surface);
    canvas.drawPath(
      inner,
      Paint()
        ..color = const Color(0xFFAABDBD).withValues(alpha: .48)
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
  bool shouldRepaint(covariant _CoastalLightConsoleBayPainter oldDelegate) =>
      oldDelegate.surface != surface ||
      oldDelegate.raised != raised ||
      oldDelegate.border != border ||
      oldDelegate.accent != accent ||
      oldDelegate.shape != shape;
}

Path _coastalLightBayPath(
  Size size,
  _CoastalLightBayShape shape, {
  double inset = 0,
}) {
  final left = inset;
  final top = inset;
  final right = size.width - inset;
  final bottom = size.height - inset;
  final radius = switch (shape) {
    _CoastalLightBayShape.placement => 28.0,
    _CoastalLightBayShape.calendar => 34.0,
    _CoastalLightBayShape.planning => 24.0,
    _CoastalLightBayShape.insight => 28.0,
  };
  return Path()..addRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTRB(left, top, right, bottom),
      Radius.circular(radius),
    ),
  );
}

final class _CoastalLightBayClipper extends CustomClipper<Path> {
  const _CoastalLightBayClipper(this.shape);

  final _CoastalLightBayShape shape;

  @override
  Path getClip(Size size) => _coastalLightBayPath(size, shape, inset: 10);

  @override
  bool shouldReclip(covariant _CoastalLightBayClipper oldClipper) =>
      oldClipper.shape != shape;
}

final class _CoastalLightCommandCrown extends StatelessWidget {
  const _CoastalLightCommandCrown({
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
      key: const Key('coastal-calm-command-crown'),
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
                              'CLINICAL CALENDAR',
                              style:
                                  (compact
                                          ? Theme.of(
                                              context,
                                            ).textTheme.labelLarge
                                          : Theme.of(
                                              context,
                                            ).textTheme.titleLarge)
                                      ?.copyWith(
                                        letterSpacing: compact ? 1.2 : 1.6,
                                        color: context.clinicalColors.clinical,
                                        fontWeight: FontWeight.w700,
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
    if (context.accessibilityTokens.decorationOpacity == 0) {
      return DecoratedBox(
        key: const Key('coastal-light-enhanced-flat-crown'),
        decoration: BoxDecoration(
          color: context.clinicalColors.structureRaised,
          border: Border.all(
            color: context.clinicalColors.insetBorder,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: content,
      );
    }
    return CustomPaint(
      painter: _CoastalLightCrownPainter(
        structure: context.clinicalColors.structureRaised,
        border: context.clinicalColors.insetBorder,
        clearBlue: context.clinicalColors.workMachinery,
        seaGlass: context.clinicalColors.clinical,
      ),
      child: content,
    );
  }
}

final class _CoastalLightCrownPainter extends CustomPainter {
  const _CoastalLightCrownPainter({
    required this.structure,
    required this.border,
    required this.clearBlue,
    required this.seaGlass,
  });

  final Color structure;
  final Color border;
  final Color clearBlue;
  final Color seaGlass;

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
    final clearBluePaint = Paint()
      ..color = clearBlue
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final seaGlassPaint = Paint()
      ..color = seaGlass
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .08, 7),
      Offset(size.width * .32, 7),
      seaGlassPaint,
    );
    canvas.drawLine(
      Offset(size.width * .68, 7),
      Offset(size.width * .92, 7),
      clearBluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CoastalLightCrownPainter oldDelegate) =>
      oldDelegate.structure != structure ||
      oldDelegate.border != border ||
      oldDelegate.clearBlue != clearBlue ||
      oldDelegate.seaGlass != seaGlass;
}

final class _CoastalLightNavigationDeck extends StatelessWidget {
  const _CoastalLightNavigationDeck({
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
    const destinations = ClinicalCalendarPrimaryNavigation.values;
    final iconsOnly =
        compact || MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Container(
      key: const Key('coastal-calm-bottom-navigation'),
      height: compact ? 68 : 82,
      decoration: BoxDecoration(
        color: integrated
            ? Colors.transparent
            : context.clinicalColors.structureRaised,
        border: integrated
            ? null
            : Border.all(color: context.clinicalColors.insetBorder),
        borderRadius: BorderRadius.circular(38),
        boxShadow:
            integrated || context.accessibilityTokens.decorationOpacity == 0
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
                label: destinations[index].label,
                child: InkWell(
                  key: Key('coastal-calm-navigation-$index'),
                  onTap: () => destinations[index].activate(
                    onOpenDestination: onOpenDestination,
                    onOpenAttention: onOpenAttention,
                  ),
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
                              destinations[index].icon,
                              color: index == selectedIndex
                                  ? context.clinicalColors.workMachinery
                                  : null,
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  destinations[index].icon,
                                  color: index == selectedIndex
                                      ? context.clinicalColors.workMachinery
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Text(destinations[index].label),
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
