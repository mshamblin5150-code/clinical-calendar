import 'package:flutter/material.dart';

import 'additive_theme_shell.dart';
import 'calendar/calendar_period_view.dart';
import 'canonical_delta_mark.dart';
import 'heritage_field_notes_frame.dart';
import 'heritage_field_notes_panel_scope.dart';
import 'heritage_field_notes_theme.dart';
import 'placements/placement_progress_widgets.dart';
import 'responsive_shell.dart';
import 'variant_f_theme.dart';

const heritageFieldNotesCompactDestinationInsets = EdgeInsets.fromLTRB(
  18,
  20,
  18,
  22,
);

const _heritageFieldNotesCrownRegion = Rect.fromLTWH(.045, .012, .925, .075);
const _heritageFieldNotesPlacementsRegion = Rect.fromLTWH(
  .045,
  .095,
  .178,
  .798,
);
const _heritageFieldNotesCalendarRegion = Rect.fromLTWH(.229, .095, .519, .566);
const _heritageFieldNotesPlanningRegion = Rect.fromLTWH(.229, .663, .519, .230);
const _heritageFieldNotesInsightRegion = Rect.fromLTWH(.753, .095, .217, .798);
const _heritageFieldNotesNavigationRegion = Rect.fromLTWH(
  .036,
  .903,
  .935,
  .079,
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
  Widget build(BuildContext context) {
    final enlargedText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Scaffold(
      key: const Key('heritage-field-notes-destination-shell'),
      backgroundColor: HeritageFieldNotesColors.canvas,
      body: SafeArea(
        child: HeritageFieldNotesNineSliceFrame(
          chromeInsets: const EdgeInsets.fromLTRB(24, 22, 24, 24),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeritageFieldNotesDestinationCrown(
                  destination: destination,
                  entry: entry,
                  onExit: onExit,
                  enlargedText: enlargedText,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _HeritageFieldNotesConsoleBay(
                    key: const Key('heritage-field-notes-destination-housing'),
                    accent: _HeritageFieldNotesBayAccent.brass,
                    shape: _HeritageFieldNotesBayShape.insight,
                    child: HeritageFieldNotesPanelScope(
                      child: _HeritageFieldNotesDestinationContentTheme(
                        child: AdditiveThemePanelInterior(child: child),
                      ),
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
}

final class _HeritageFieldNotesDestinationContentTheme extends StatelessWidget {
  const _HeritageFieldNotesDestinationContentTheme({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.clinicalColors;
    return Theme(
      data: theme.copyWith(
        canvasColor: colors.structure,
        scaffoldBackgroundColor: colors.structure,
        extensions: [
          for (final extension in theme.extensions.values)
            if (extension is! ClinicalCalendarColors) extension,
          colors.copyWith(canvas: colors.structure),
        ],
      ),
      child: child,
    );
  }
}

final class _HeritageFieldNotesDestinationCrown extends StatelessWidget {
  const _HeritageFieldNotesDestinationCrown({
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
    return CustomPaint(
      key: const Key('heritage-field-notes-destination-crown'),
      painter: _HeritageFieldNotesCrownPainter(
        structure: context.clinicalColors.structureRaised,
        border: context.clinicalColors.insetBorder,
        brass: context.clinicalColors.protectedDayAccent,
        forest: context.clinicalColors.clinical,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: enlargedText ? 108 : 82),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              TextButton.icon(
                key: Key(enteredFromMenu ? 'back-action' : 'close-action'),
                onPressed: onExit,
                icon: Icon(enteredFromMenu ? Icons.arrow_back : Icons.close),
                label: Text(enteredFromMenu ? 'Back' : 'Close'),
              ),
              const SizedBox(width: 12),
              const CanonicalDeltaMark(size: 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.label.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: context.clinicalColors.primaryText,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                    ),
                    if (!enlargedText)
                      Text(
                        'CLINICAL CALENDAR  /  FIELD ARCHIVE',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.clinicalColors.secondaryText,
                          letterSpacing: 1.1,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
          chromeInsets: const EdgeInsets.fromLTRB(54, 10, 46, 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Concept #118 is 1536 by 1024. Resolve every dominant region
              // from those normalized outer-viewport coordinates so the
              // runtime retains the approved book-board composition at other
              // landscape tablet sizes without uniformly scaling its text.
              final outerWidth = constraints.maxWidth + 100;
              final outerHeight = constraints.maxHeight + 26;
              double x(double fraction) => outerWidth * fraction - 54;
              double y(double fraction) => outerHeight * fraction - 10;
              double w(double fraction) => outerWidth * fraction;
              double h(double fraction) => outerHeight * fraction;
              Rect resolveRegion(Rect normalized) => Rect.fromLTWH(
                x(normalized.left),
                y(normalized.top),
                w(normalized.width),
                h(normalized.height),
              );
              return Stack(
                children: [
                  const Positioned.fill(
                    child: ColoredBox(color: HeritageFieldNotesColors.surface),
                  ),
                  Positioned.fromRect(
                    rect: resolveRegion(_heritageFieldNotesCrownRegion),
                    child: _HeritageFieldNotesCommandCrown(
                      environmentName: environmentName,
                      onOpenMenu: onOpenMenu,
                      onAddSchedule: onAddSchedule,
                      onOpenDestination: onOpenDestination,
                      profileAvatar: slots.profileAvatar,
                    ),
                  ),
                  Positioned.fromRect(
                    rect: resolveRegion(_heritageFieldNotesPlacementsRegion),
                    child: _HeritageFieldNotesConsoleBay(
                      key: const Key('heritage-field-notes-placement-bay'),
                      accent: _HeritageFieldNotesBayAccent.brass,
                      shape: _HeritageFieldNotesBayShape.placement,
                      child: HeritageFieldNotesPanelScope(
                        child: slots.placementDock,
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: resolveRegion(_heritageFieldNotesCalendarRegion),
                    child: _HeritageFieldNotesConsoleBay(
                      key: const Key('heritage-field-notes-calendar-bay'),
                      accent: _HeritageFieldNotesBayAccent.forest,
                      shape: _HeritageFieldNotesBayShape.calendar,
                      child: _HeritageFieldNotesCalendarViewport(
                        showArchiveMonthLegend: true,
                        child: slots.centralContent,
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: resolveRegion(_heritageFieldNotesPlanningRegion),
                    child: _HeritageFieldNotesConsoleBay(
                      key: const Key('heritage-field-notes-planning-bay'),
                      accent: _HeritageFieldNotesBayAccent.forest,
                      shape: _HeritageFieldNotesBayShape.planning,
                      child: HeritageFieldNotesPanelScope(
                        child: VariantFPlanningBayMode(
                          expandedByDefault: true,
                          child: slots.planningRegion,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: resolveRegion(_heritageFieldNotesInsightRegion),
                    child: _HeritageFieldNotesConsoleBay(
                      key: const Key('heritage-field-notes-insight-bay'),
                      accent: _HeritageFieldNotesBayAccent.forest,
                      shape: _HeritageFieldNotesBayShape.insight,
                      child: HeritageFieldNotesPanelScope(
                        child: slots.insightRail,
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: resolveRegion(_heritageFieldNotesNavigationRegion),
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
        Positioned.fill(
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: Image(
                image: AssetImage(
                  heritageFieldNotesMaterialChassisAsset,
                  package: 'clinical_calendar_presentation',
                ),
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => const CustomPaint(
                  painter: _HeritageFieldNotesArchiveChassisPainter(),
                ),
              ),
            ),
          ),
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
                                  scrollAtEnlargedText: true,
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
                                child: HeritageFieldNotesPanelScope(
                                  child: VariantFPlanningBayMode(
                                    expandedByDefault: false,
                                    child: slots.planningRegion,
                                  ),
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
                                      child: SingleChildScrollView(
                                        key: const Key(
                                          'heritage-field-notes-mobile-placements-scroll',
                                        ),
                                        primary: false,
                                        child: EmbeddedPlacementPanelInterior(
                                          outerScrollOwnsVerticalOverflow: true,
                                          child: HeritageFieldNotesPanelScope(
                                            child: slots.mobilePlacementSummary,
                                          ),
                                        ),
                                      ),
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
                                      child: HeritageFieldNotesPanelScope(
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
    slots: ResponsiveShellSlots(
      placementDock: HeritageFieldNotesPanelScope(child: slots.placementDock),
      centralContent: slots.centralContent,
      insightRail: HeritageFieldNotesPanelScope(child: slots.insightRail),
      mobilePlacementSummary: HeritageFieldNotesPanelScope(
        child: slots.mobilePlacementSummary,
      ),
      mobileAttention: HeritageFieldNotesPanelScope(
        child: slots.mobileAttention,
      ),
      planningRegion: HeritageFieldNotesPanelScope(child: slots.planningRegion),
      profileAvatar: slots.profileAvatar,
    ),
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

final class _HeritageFieldNotesArchiveChassisPainter extends CustomPainter {
  const _HeritageFieldNotesArchiveChassisPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    const darkestLeather = Color(0xFF170C09);
    const archivalLeather = Color(0xFF402219);
    const leatherHighlight = Color(0xFF694433);
    const agedBrass = Color(0xFFB88A31);
    const brassHighlight = Color(0xFFE0BD68);

    final outer = Offset.zero & size;
    final pageWindow = Rect.fromLTRB(54, 10, size.width - 46, size.height - 16);
    final board = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(outer)
      ..addRect(pageWindow);
    canvas.drawPath(
      board,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            leatherHighlight,
            archivalLeather,
            darkestLeather,
            archivalLeather,
          ],
          stops: [0, .32, .72, 1],
        ).createShader(outer),
    );
    _paintLeatherTexture(canvas, Rect.fromLTWH(0, 0, size.width, 10), seed: 3);
    _paintLeatherTexture(
      canvas,
      Rect.fromLTWH(0, size.height - 16, size.width, 16),
      seed: 7,
    );
    _paintLeatherTexture(
      canvas,
      Rect.fromLTWH(0, 10, 54, size.height - 26),
      seed: 11,
    );
    _paintLeatherTexture(
      canvas,
      Rect.fromLTWH(size.width - 46, 10, 46, size.height - 26),
      seed: 17,
    );
    final embossedDark = Paint()
      ..color = darkestLeather.withValues(alpha: .72)
      ..strokeWidth = 1.5;
    final embossedLight = Paint()
      ..color = leatherHighlight.withValues(alpha: .55)
      ..strokeWidth = 1;
    canvas.drawLine(
      const Offset(8, 12),
      Offset(8, size.height - 12),
      embossedDark,
    );
    canvas.drawLine(
      const Offset(10, 12),
      Offset(10, size.height - 12),
      embossedLight,
    );
    canvas.drawLine(
      const Offset(47, 12),
      Offset(47, size.height - 12),
      embossedDark,
    );
    canvas.drawLine(
      const Offset(49, 12),
      Offset(49, size.height - 12),
      embossedLight,
    );

    final pageWindowRRect = RRect.fromRectAndRadius(
      pageWindow,
      const Radius.circular(9),
    );
    canvas.drawRRect(
      pageWindowRRect,
      Paint()
        ..color = darkestLeather
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pageWindow.deflate(3), const Radius.circular(7)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6C430C),
            Color(0xFFC9A04B),
            agedBrass,
            Color(0xFFD6B66A),
            Color(0xFF765015),
          ],
          stops: [0, .22, .52, .76, 1],
        ).createShader(pageWindow)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pageWindow.deflate(7), const Radius.circular(5)),
      Paint()
        ..color = brassHighlight.withValues(alpha: .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    for (final corner in [
      const Alignment(-1, -1),
      const Alignment(1, -1),
      const Alignment(-1, 1),
      const Alignment(1, 1),
    ]) {
      final center = Offset(
        corner.x < 0 ? 30 : size.width - 30,
        corner.y < 0 ? 24 : size.height - 24,
      );
      final plate = Rect.fromCenter(center: center, width: 34, height: 34);
      canvas.drawRRect(
        RRect.fromRectAndRadius(plate, const Radius.circular(5)),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF704A13),
              Color(0xFFD2AF5D),
              agedBrass,
              Color(0xFF6C430C),
            ],
            stops: [0, .32, .68, 1],
          ).createShader(plate),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(plate.deflate(3), const Radius.circular(3)),
        Paint()
          ..color = brassHighlight
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(center, 4.5, Paint()..color = darkestLeather);
      canvas.drawCircle(
        center.translate(-1, -1),
        1.5,
        Paint()..color = brassHighlight,
      );
    }
  }

  void _paintLeatherTexture(Canvas canvas, Rect region, {required int seed}) {
    if (region.isEmpty) return;
    final shadow = Paint()..color = const Color(0x30100604);
    final highlight = Paint()..color = const Color(0x28FFFFFF);
    var row = 0;
    for (double y = region.top + 2; y < region.bottom; y += 5.5, row++) {
      var column = 0;
      for (
        double x = region.left + 2 + (row % 3) * 1.4;
        x < region.right;
        column++
      ) {
        final hash = (row * 17 + column * 31 + seed) % 13;
        final center = Offset(x + (hash % 3) - 1, y + ((hash ~/ 3) % 3) - 1);
        final pebble = Rect.fromCenter(
          center: center,
          width: 2.8 + (hash % 4) * .42,
          height: 1.7 + (hash % 3) * .3,
        );
        canvas.drawOval(pebble, shadow);
        canvas.drawCircle(center.translate(-.6, -.5), .52, highlight);
        x += 5.4 + (hash % 5) * .85;
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _HeritageFieldNotesArchiveChassisPainter oldDelegate,
  ) => false;
}

enum _HeritageFieldNotesBayAccent { forest, brass }

enum _HeritageFieldNotesBayShape { placement, calendar, planning, insight }

final class _HeritageFieldNotesCalendarViewport extends StatelessWidget {
  const _HeritageFieldNotesCalendarViewport({
    required this.child,
    this.showArchiveMonthLegend = false,
    this.scrollAtEnlargedText = false,
  });

  final Widget child;
  final bool showArchiveMonthLegend;
  final bool scrollAtEnlargedText;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final calendar = CalendarPeriodViewportPolicy(
        useBoundedMonthGrid: true,
        scaleDayNumberWithText: true,
        useEnlargedTextLandscapeReflow: !scrollAtEnlargedText,
        useArchiveEntryVisuals: true,
        showArchiveMonthLegend: showArchiveMonthLegend,
        child: child,
      );
      return buildEnlargedTextCalendarScrollViewport(
        context: context,
        constraints: constraints,
        enabled: scrollAtEnlargedText,
        scrollKey: const Key('heritage-field-notes-calendar-horizontal-scroll'),
        child: calendar,
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
          switch (shape) {
            _HeritageFieldNotesBayShape.placement => 14,
            _HeritageFieldNotesBayShape.insight => 34,
            _ => 12,
          },
          switch (shape) {
            _HeritageFieldNotesBayShape.calendar => 10,
            _HeritageFieldNotesBayShape.planning => 12,
            _ => 20,
          },
          shape == _HeritageFieldNotesBayShape.insight ? 14 : 12,
          switch (shape) {
            _HeritageFieldNotesBayShape.calendar => 8,
            _HeritageFieldNotesBayShape.planning => 13,
            _ => 18,
          },
        ),
        child: child,
      ),
    );
    return CustomPaint(
      painter: _HeritageFieldNotesConsoleBayPainter(
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
    required this.raised,
    required this.border,
    required this.accent,
    required this.shape,
  });

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
        ..color = border.withValues(alpha: .78)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    if (shape == _HeritageFieldNotesBayShape.insight) {
      canvas.drawRect(
        const Rect.fromLTWH(17, 18, 6, 34),
        Paint()..color = accent,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _HeritageFieldNotesConsoleBayPainter oldDelegate,
  ) =>
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
  Path getClip(Size size) => _heritageFieldNotesBayPath(size, shape, inset: 1);

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
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
        child: Row(
          children: [
            Container(
              width: compact ? 44 : 52,
              height: compact ? 44 : 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.clinicalColors.structure,
                border: Border.all(
                  color: context.clinicalColors.clinical,
                  width: 2,
                ),
              ),
              child: IconButton(
                key: const Key('application-menu-action'),
                tooltip: 'Open menu',
                onPressed: onOpenMenu,
                padding: EdgeInsets.all(compact ? 4 : 2),
                icon: CanonicalDeltaMark(size: compact ? 36 : 46),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: enlargedText
                  ? const SizedBox.shrink()
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'CLINICAL CALENDAR',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    letterSpacing: compact ? 1.2 : 2.3,
                                    color: context.clinicalColors.primaryText,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
                        if (!compact && environmentName.trim().isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Text(
                            'FIELD ARCHIVE',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: context.clinicalColors.primaryText,
                                  letterSpacing: 1.4,
                                  fontWeight: FontWeight.w700,
                                ),
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
            if (compact)
              IconButton(
                key: const Key('heritage-field-notes-add-placement-action'),
                tooltip: 'Add Placement',
                onPressed: () => onOpenDestination(
                  ClinicalCalendarDestination.clinicalPlacements,
                ),
                icon: const Icon(Icons.add_circle_outline),
              )
            else
              TextButton.icon(
                key: const Key('heritage-field-notes-add-placement-action'),
                onPressed: () => onOpenDestination(
                  ClinicalCalendarDestination.clinicalPlacements,
                ),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Placement'),
              ),
            IconButton(
              key: const Key('heritage-field-notes-help-action'),
              tooltip: 'Help',
              onPressed: () =>
                  onOpenDestination(ClinicalCalendarDestination.help),
              icon: const Icon(Icons.help_outline),
            ),
            KeyedSubtree(
              key: const Key('heritage-field-notes-profile-action'),
              child: profileAvatar,
            ),
            if (!compact && !enlargedText && environmentName.trim().isNotEmpty)
              Container(
                width: 116,
                height: double.infinity,
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: context.clinicalColors.insetBorder),
                  ),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  'ARCHIVE NO.\n$environmentName',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: .8,
                    height: 1.35,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return CustomPaint(
      painter: _HeritageFieldNotesCrownPainter(
        structure: context.clinicalColors.structureRaised,
        border: context.clinicalColors.insetBorder,
        brass: context.clinicalColors.protectedDayAccent,
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
        ..color = border.withValues(alpha: .82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final brassPaint = Paint()
      ..color = brass
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final forestPaint = Paint()
      ..color = border.withValues(alpha: .72)
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
      (Icons.business_center_outlined, 'PLACEMENTS'),
      (Icons.report_gmailerrorred_outlined, 'ATTENTION'),
      (Icons.settings_outlined, 'SETTINGS'),
    ];
    final iconsOnly =
        compact || MediaQuery.textScalerOf(context).scale(1) > 1.3;
    Color destinationColor(BuildContext context, int index) => switch (index) {
      1 => context.clinicalColors.clinical,
      3 => context.clinicalColors.urgent,
      _ => const Color(0xFF6B4B22),
    };
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
                        bottom: BorderSide(color: Colors.transparent, width: 1),
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
                              size: compact ? 24 : 32,
                              color: destinationColor(context, index),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  destinations[index].$1,
                                  size: 32,
                                  color: destinationColor(context, index),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  destinations[index].$2,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        letterSpacing: .7,
                                        color: destinationColor(context, index),
                                      ),
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
  }
}
