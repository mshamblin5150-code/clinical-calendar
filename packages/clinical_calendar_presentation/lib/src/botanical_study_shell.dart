import 'package:flutter/material.dart';

import 'additive_theme_shell.dart';
import 'calendar/calendar_period_view.dart';
import 'botanical_study_frame.dart';
import 'botanical_study_theme.dart';
import 'graphite_frame.dart';
import 'responsive_shell.dart';
import 'variant_f_theme.dart';

const botanicalStudyAxionLogoAsset =
    'assets/botanical_study_raster/axion-delta-mark-v2.png';

const botanicalStudyCompactDestinationInsets = EdgeInsets.fromLTRB(
  18,
  20,
  18,
  22,
);

Widget _buildBotanicalStudyFrame(
  Widget child,
  EdgeInsets chromeInsets,
  EdgeInsets contentPadding,
) => BotanicalStudyNineSliceFrame(
  chromeInsets: chromeInsets,
  contentPadding: contentPadding,
  child: child,
);

final class BotanicalStudyDestinationSurface extends StatelessWidget {
  const BotanicalStudyDestinationSurface({
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
    frameBuilder: _buildBotanicalStudyFrame,
    statusSafeInsets: botanicalStudyStatusSafeInsets,
    compactDestinationInsets: botanicalStudyCompactDestinationInsets,
    child: child,
  );
}

final class BotanicalStudyApplicationShell extends StatelessWidget {
  const BotanicalStudyApplicationShell({
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
    key: const Key('botanical-study-landscape-shell'),
    backgroundColor: BotanicalStudyColors.canvas,
    body: BotanicalStudyLandscapeChassis(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          double x(double pixels) => width * pixels / 1586;
          double y(double pixels) => height * pixels / 992;
          return Stack(
            children: [
              Positioned(
                left: x(61),
                top: 0,
                width: x(1494),
                height: y(65),
                child: _BotanicalStudyCommandCrown(
                  environmentName: environmentName,
                  onOpenMenu: onOpenMenu,
                  onAddSchedule: onAddSchedule,
                  onOpenDestination: onOpenDestination,
                  profileAvatar: slots.profileAvatar,
                  integrated: true,
                ),
              ),
              Positioned(
                left: x(61),
                top: y(66),
                width: x(307),
                height: y(834),
                child: _BotanicalStudyConsoleBay(
                  key: const Key('botanical-study-placement-bay'),
                  accent: _BotanicalStudyBayAccent.dustyRose,
                  shape: _BotanicalStudyBayShape.placement,
                  integrated: true,
                  child: slots.placementDock,
                ),
              ),
              Positioned(
                left: x(378),
                top: y(66),
                width: x(767),
                height: y(561),
                child: _BotanicalStudyConsoleBay(
                  key: const Key('botanical-study-calendar-bay'),
                  accent: _BotanicalStudyBayAccent.eucalyptus,
                  shape: _BotanicalStudyBayShape.calendar,
                  integrated: true,
                  child: _BotanicalStudyCalendarViewport(
                    child: slots.centralContent,
                  ),
                ),
              ),
              Positioned(
                left: x(378),
                top: y(638),
                width: x(767),
                height: y(262),
                child: _BotanicalStudyConsoleBay(
                  key: const Key('botanical-study-planning-bay'),
                  accent: _BotanicalStudyBayAccent.eucalyptus,
                  shape: _BotanicalStudyBayShape.planning,
                  integrated: true,
                  child:
                      slots.planningRegion.key ==
                          const Key('live-planning-region')
                      ? SingleChildScrollView(
                          key: const Key('botanical-study-planning-scroll'),
                          primary: false,
                          child: VariantFPlanningBayMode(
                            expandedByDefault: false,
                            child: slots.planningRegion,
                          ),
                        )
                      : VariantFPlanningBayMode(
                          expandedByDefault: false,
                          child: slots.planningRegion,
                        ),
                ),
              ),
              Positioned(
                left: x(1154),
                top: y(66),
                width: x(401),
                height: y(834),
                child: _BotanicalStudyConsoleBay(
                  key: const Key('botanical-study-insight-bay'),
                  accent: _BotanicalStudyBayAccent.dustyRose,
                  shape: _BotanicalStudyBayShape.insight,
                  integrated: true,
                  child: slots.insightRail,
                ),
              ),
              Positioned(
                left: 0,
                top: y(912),
                width: width,
                height: y(80),
                child: _BotanicalStudyNavigationDeck(
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
    key: const Key('botanical-study-portrait-shell'),
    backgroundColor: BotanicalStudyColors.canvas,
    body: SafeArea(
      child: BotanicalStudyNineSliceFrame(
        chromeInsets: const EdgeInsets.fromLTRB(24, 28, 24, 30),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
          child: Column(
            children: [
              _BotanicalStudyCommandCrown(
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
                      key: const Key('botanical-study-portrait-scroll'),
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
                              child: _BotanicalStudyConsoleBay(
                                key: const Key('botanical-study-calendar-bay'),
                                accent: _BotanicalStudyBayAccent.eucalyptus,
                                shape: _BotanicalStudyBayShape.calendar,
                                child: _BotanicalStudyCalendarViewport(
                                  scrollAtEnlargedText: true,
                                  child: slots.centralContent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              flex: 3,
                              child: _BotanicalStudyConsoleBay(
                                key: const Key('botanical-study-planning-bay'),
                                accent: _BotanicalStudyBayAccent.eucalyptus,
                                shape: _BotanicalStudyBayShape.planning,
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
                                    child: _BotanicalStudyConsoleBay(
                                      key: const Key(
                                        'botanical-study-placement-bay',
                                      ),
                                      accent:
                                          _BotanicalStudyBayAccent.dustyRose,
                                      shape: _BotanicalStudyBayShape.placement,
                                      child: slots.mobilePlacementSummary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _BotanicalStudyConsoleBay(
                                      key: const Key(
                                        'botanical-study-insight-bay',
                                      ),
                                      accent:
                                          _BotanicalStudyBayAccent.dustyRose,
                                      shape: _BotanicalStudyBayShape.insight,
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
              _BotanicalStudyNavigationDeck(
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
    key: const Key('botanical-study-compact-shell'),
    slots: slots,
    environmentName: environmentName,
    onOpenMenu: onOpenMenu,
    onOpenDestination: onOpenDestination,
    onOpenAttention: onOpenAttention,
    onAddSchedule: onAddSchedule,
    mobileIndex: mobileIndex,
    frameBuilder: _buildBotanicalStudyFrame,
    calendarSafeInsets: botanicalStudyCalendarSafeInsets,
    placementsSafeInsets: botanicalStudyPlacementsSafeInsets,
    planningSafeInsets: botanicalStudyPlanningSafeInsets,
    statusSafeInsets: botanicalStudyStatusSafeInsets,
  );
}

enum _BotanicalStudyBayAccent { eucalyptus, dustyRose }

enum _BotanicalStudyBayShape { placement, calendar, planning, insight }

final class _BotanicalStudyCalendarViewport extends StatelessWidget {
  const _BotanicalStudyCalendarViewport({
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
        child: child,
      );
      if (MediaQuery.textScalerOf(context).scale(1) <= 1.3 ||
          !scrollAtEnlargedText) {
        return calendar;
      }
      return SingleChildScrollView(
        key: const Key('botanical-study-calendar-horizontal-scroll'),
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

final class _BotanicalStudyConsoleBay extends StatelessWidget {
  const _BotanicalStudyConsoleBay({
    required this.accent,
    required this.shape,
    required this.child,
    this.integrated = false,
    super.key,
  });

  final _BotanicalStudyBayAccent accent;
  final _BotanicalStudyBayShape shape;
  final Widget child;
  final bool integrated;

  @override
  Widget build(BuildContext context) {
    final colors = context.clinicalColors;
    final accentColor = switch (accent) {
      _BotanicalStudyBayAccent.eucalyptus => colors.clinical,
      _BotanicalStudyBayAccent.dustyRose => colors.workMachinery,
    };
    if (integrated) {
      final padding = switch (shape) {
        _BotanicalStudyBayShape.placement => const EdgeInsets.fromLTRB(
          18,
          22,
          14,
          18,
        ),
        _BotanicalStudyBayShape.calendar => const EdgeInsets.fromLTRB(
          12,
          14,
          12,
          4,
        ),
        _BotanicalStudyBayShape.planning => const EdgeInsets.fromLTRB(
          12,
          11,
          12,
          10,
        ),
        _BotanicalStudyBayShape.insight => const EdgeInsets.fromLTRB(
          9,
          18,
          12,
          18,
        ),
      };
      return ClipRect(
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: padding,
          child: AdditiveThemePanelInterior(child: child),
        ),
      );
    }
    final content = ClipPath(
      clipper: _BotanicalStudyBayClipper(shape),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          shape == _BotanicalStudyBayShape.placement ? 14 : 12,
          shape == _BotanicalStudyBayShape.calendar ? 10 : 20,
          shape == _BotanicalStudyBayShape.insight ? 14 : 12,
          shape == _BotanicalStudyBayShape.calendar ? 10 : 18,
        ),
        child: AdditiveThemePanelInterior(child: child),
      ),
    );
    return CustomPaint(
      painter: _BotanicalStudyConsoleBayPainter(
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

final class _BotanicalStudyConsoleBayPainter extends CustomPainter {
  const _BotanicalStudyConsoleBayPainter({
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
  final _BotanicalStudyBayShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final outer = _botanicalStudyBayPath(size, shape);
    canvas.drawPath(
      outer,
      Paint()
        ..color = Color.lerp(raised, accent, .04)!
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      outer,
      Paint()
        ..color = accent.withValues(alpha: .22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    canvas.drawPath(
      outer,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final inner = _botanicalStudyBayPath(size, shape, inset: 10);
    canvas.drawPath(inner, Paint()..color = BotanicalStudyColors.surface);
    canvas.drawPath(
      inner,
      Paint()
        ..color = BotanicalStudyColors.outlineVariant
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final rail = Paint()
      ..color = accent
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(18, 7), Offset(size.width * .42, 7), rail);
    canvas.drawLine(
      Offset(size.width * .58, size.height - 7),
      Offset(size.width - 18, size.height - 7),
      rail,
    );
  }

  @override
  bool shouldRepaint(covariant _BotanicalStudyConsoleBayPainter oldDelegate) =>
      oldDelegate.surface != surface ||
      oldDelegate.raised != raised ||
      oldDelegate.border != border ||
      oldDelegate.accent != accent ||
      oldDelegate.shape != shape;
}

Path _botanicalStudyBayPath(
  Size size,
  _BotanicalStudyBayShape shape, {
  double inset = 0,
}) {
  final left = inset;
  final top = inset;
  final right = size.width - inset;
  final bottom = size.height - inset;
  final notch = switch (shape) {
    _BotanicalStudyBayShape.placement => 16.0,
    _BotanicalStudyBayShape.calendar => 22.0,
    _BotanicalStudyBayShape.planning => 18.0,
    _BotanicalStudyBayShape.insight => 14.0,
  };
  return Path()
    ..moveTo(left + 8, top)
    ..lineTo(right - notch, top)
    ..lineTo(right, top + notch)
    ..lineTo(right, bottom - 8)
    ..quadraticBezierTo(right, bottom, right - 8, bottom)
    ..lineTo(left + notch, bottom)
    ..lineTo(left, bottom - notch)
    ..lineTo(left, top + 8)
    ..quadraticBezierTo(left, top, left + 8, top)
    ..close();
}

final class _BotanicalStudyBayClipper extends CustomClipper<Path> {
  const _BotanicalStudyBayClipper(this.shape);

  final _BotanicalStudyBayShape shape;

  @override
  Path getClip(Size size) => _botanicalStudyBayPath(size, shape, inset: 10);

  @override
  bool shouldReclip(covariant _BotanicalStudyBayClipper oldClipper) =>
      oldClipper.shape != shape;
}

final class _BotanicalStudyCommandCrown extends StatelessWidget {
  const _BotanicalStudyCommandCrown({
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
    if (integrated) {
      return SizedBox(
        key: const Key('botanical-study-command-crown'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(29, 8, 10, 7),
          child: Row(
            children: [
              Tooltip(
                message: 'Open menu',
                child: Transform.translate(
                  offset: const Offset(0, 5),
                  child: TextButton(
                    key: const Key('application-menu-action'),
                    onPressed: onOpenMenu,
                    style: TextButton.styleFrom(
                      foregroundColor: BotanicalStudyColors.focus,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(44, 44),
                    ),
                    child: const Text(
                      'CLINICAL CALENDAR',
                      style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const _BotanicalStudyAxionDeltaMark(size: 42),
              const Spacer(),
              if (!enlargedText)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      environmentName.trim().isEmpty
                          ? 'BOTANICAL STUDY'
                          : environmentName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .8,
                      ),
                    ),
                    const Text(
                      'CLINICAL PLANNING COLLECTION · 2026',
                      style: TextStyle(fontSize: 9, letterSpacing: .35),
                    ),
                  ],
                ),
              if (!enlargedText) ...[
                const SizedBox(width: 22),
                Transform.translate(
                  offset: const Offset(0, 5),
                  child: const SizedBox(
                    width: 254,
                    height: 38,
                    child: _BotanicalStudyScale(),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                tooltip: 'Add schedule',
                onPressed: onAddSchedule,
                icon: const Icon(Icons.add_box_outlined, size: 20),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: 'Help',
                onPressed: () =>
                    onOpenDestination(ClinicalCalendarDestination.help),
                icon: const Icon(Icons.help_outline, size: 20),
                visualDensity: VisualDensity.compact,
              ),
              profileAvatar,
            ],
          ),
        ),
      );
    }
    final content = SizedBox(
      key: const Key('botanical-study-command-crown'),
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
            const SizedBox(width: 6),
            _BotanicalStudyAxionDeltaMark(size: compact ? 36 : 42),
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
    return CustomPaint(
      painter: _BotanicalStudyCrownPainter(
        structure: context.clinicalColors.structureRaised,
        border: context.clinicalColors.insetBorder,
        rose: context.clinicalColors.workMachinery,
        sage: context.clinicalColors.clinical,
      ),
      child: content,
    );
  }
}

final class _BotanicalStudyAxionDeltaMark extends StatelessWidget {
  const _BotanicalStudyAxionDeltaMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      key: const Key('botanical-study-axion-delta'),
      dimension: size,
      child: Image.asset(
        botanicalStudyAxionLogoAsset,
        key: const Key('botanical-study-axion-delta-image'),
        package: 'clinical_calendar_presentation',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          GraphitePresentationFailureBoundary.report(
            context,
            error,
            themeId: 'botanical-study',
            isGraphite: false,
          );
          return const ColoredBox(color: BotanicalStudyColors.canvas);
        },
      ),
    ),
  );
}

final class _BotanicalStudyScale extends StatelessWidget {
  const _BotanicalStudyScale();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: BotanicalStudyColors.canvas,
    child: CustomPaint(
      painter: _BotanicalStudyScalePainter(
        color: BotanicalStudyColors.textSecondary,
        textStyle: DefaultTextStyle.of(context).style,
      ),
    ),
  );
}

final class _BotanicalStudyScalePainter extends CustomPainter {
  const _BotanicalStudyScalePainter({
    required this.color,
    required this.textStyle,
  });

  final Color color;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const labels = ['cm', '0', '1', '2', '3', '4', '5'];
    final style = textStyle.copyWith(fontSize: 9, color: color);
    final lineY = size.height * .72;
    canvas.drawLine(Offset(32, lineY), Offset(size.width - 4, lineY), paint);
    for (var index = 0; index < labels.length; index++) {
      final x = index == 0 ? 0.0 : 34 + (size.width - 42) * (index - 1) / 5;
      if (index > 0) {
        canvas.drawLine(Offset(x, lineY - 7), Offset(x, lineY + 7), paint);
      }
      final painter = TextPainter(
        text: TextSpan(text: labels[index], style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(x - (index == 0 ? 0 : painter.width / 2), 7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BotanicalStudyScalePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.textStyle != textStyle;
}

final class _BotanicalStudyCrownPainter extends CustomPainter {
  const _BotanicalStudyCrownPainter({
    required this.structure,
    required this.border,
    required this.rose,
    required this.sage,
  });

  final Color structure;
  final Color border;
  final Color rose;
  final Color sage;

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
    final rosePaint = Paint()
      ..color = rose
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final sagePaint = Paint()
      ..color = sage
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .08, 7),
      Offset(size.width * .32, 7),
      sagePaint,
    );
    canvas.drawLine(
      Offset(size.width * .68, 7),
      Offset(size.width * .92, 7),
      rosePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BotanicalStudyCrownPainter oldDelegate) =>
      oldDelegate.structure != structure ||
      oldDelegate.border != border ||
      oldDelegate.rose != rose ||
      oldDelegate.sage != sage;
}

final class _BotanicalStudyNavigationDeck extends StatelessWidget {
  const _BotanicalStudyNavigationDeck({
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
    const items = [
      _BotanicalNavigationItem(
        icon: Icons.calendar_today_outlined,
        label: 'TODAY',
        action: _BotanicalNavigationAction.calendar,
        integratedFlex: 328,
        integratedOffset: 25,
      ),
      _BotanicalNavigationItem(
        icon: Icons.calendar_month_outlined,
        label: 'CALENDAR',
        action: _BotanicalNavigationAction.calendar,
        integratedFlex: 313,
        integratedOffset: 6,
      ),
      _BotanicalNavigationItem(
        icon: Icons.work_outline,
        label: 'PLACEMENTS',
        action: _BotanicalNavigationAction.placements,
        integratedFlex: 298,
        integratedOffset: 2,
      ),
      _BotanicalNavigationItem(
        icon: Icons.warning_amber_outlined,
        label: 'ATTENTION',
        action: _BotanicalNavigationAction.attention,
        integratedFlex: 265,
        integratedOffset: 13,
      ),
      _BotanicalNavigationItem(
        icon: Icons.settings_outlined,
        label: 'SETTINGS',
        action: _BotanicalNavigationAction.settings,
        integratedFlex: 382,
        integratedOffset: -55,
      ),
    ];
    final iconsOnly =
        compact || MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Container(
      key: const Key('botanical-study-bottom-navigation'),
      height: compact ? 68 : 82,
      decoration: BoxDecoration(
        color: integrated
            ? Colors.transparent
            : context.clinicalColors.structureRaised,
        border: integrated
            ? null
            : Border.all(color: context.clinicalColors.insetBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++)
            Expanded(
              flex: integrated ? items[index].integratedFlex : 1,
              child: Semantics(
                button: true,
                selected: index == selectedIndex,
                label: items[index].label,
                child: InkWell(
                  key: Key('botanical-study-navigation-$index'),
                  onTap: () {
                    switch (items[index].action) {
                      case _BotanicalNavigationAction.calendar:
                        onOpenDestination(ClinicalCalendarDestination.calendar);
                      case _BotanicalNavigationAction.placements:
                        onOpenDestination(
                          ClinicalCalendarDestination.clinicalPlacements,
                        );
                      case _BotanicalNavigationAction.attention:
                        onOpenAttention();
                      case _BotanicalNavigationAction.settings:
                        onOpenDestination(ClinicalCalendarDestination.settings);
                    }
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: integrated && index == selectedIndex
                          ? BotanicalStudyColors.selectedFill
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: index == selectedIndex
                              ? integrated
                                    ? BotanicalStudyColors.selectedFill
                                    : context.clinicalColors.clinical
                              : Colors.transparent,
                          width: 4,
                        ),
                        right: index < items.length - 1
                            ? BorderSide(
                                color: context.clinicalColors.insetBorder
                                    .withValues(alpha: .5),
                              )
                            : BorderSide.none,
                      ),
                    ),
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(
                          integrated ? items[index].integratedOffset : 0,
                          0,
                        ),
                        child: iconsOnly
                            ? Icon(
                                items[index].icon,
                                size: integrated ? 30 : null,
                                color: integrated && index == selectedIndex
                                    ? BotanicalStudyColors.canvas
                                    : index == selectedIndex
                                    ? context.clinicalColors.workMachinery
                                    : integrated
                                    ? context.clinicalColors.clinical
                                    : null,
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    items[index].icon,
                                    size: integrated ? 30 : null,
                                    color: integrated && index == selectedIndex
                                        ? BotanicalStudyColors.canvas
                                        : index == selectedIndex
                                        ? context.clinicalColors.workMachinery
                                        : integrated
                                        ? context.clinicalColors.clinical
                                        : null,
                                  ),
                                  SizedBox(width: integrated ? 12 : 8),
                                  Text(
                                    items[index].label,
                                    style: TextStyle(
                                      fontSize: integrated ? 16 : null,
                                      color:
                                          integrated && index == selectedIndex
                                          ? BotanicalStudyColors.canvas
                                          : integrated
                                          ? context.clinicalColors.clinical
                                          : null,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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

enum _BotanicalNavigationAction { calendar, placements, attention, settings }

@immutable
final class _BotanicalNavigationItem {
  const _BotanicalNavigationItem({
    required this.icon,
    required this.label,
    required this.action,
    required this.integratedFlex,
    required this.integratedOffset,
  });

  final IconData icon;
  final String label;
  final _BotanicalNavigationAction action;
  final int integratedFlex;
  final double integratedOffset;
}
