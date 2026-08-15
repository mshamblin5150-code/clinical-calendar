import 'dart:ui' as ui;

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/material.dart';

import 'additive_theme_shell.dart';
import 'additive_semantic_colors.dart';
import 'calendar/calendar_period_view.dart';
import 'canonical_delta_mark.dart';
import 'date_input.dart';
import 'insight_rail_presentation_policy.dart';
import 'placements/placement_management_surface.dart';
import 'placements/placement_progress_widgets.dart';
import 'responsive_shell.dart';
import 'variant_f_theme.dart';

const containmentDroneRendererId = 'containment-drone-concept-renderer-v2';
const containmentDroneChassisBridgeAsset =
    'assets/containment_drone_v2/chassis-conduit-bridge.png';
const containmentDronePanelAsset =
    'assets/containment_drone_v2/panel-nine-slice-v2.png';
const containmentDroneLandscapeChassisAsset =
    'assets/containment_drone_v2/chassis-landscape-v3.png';
const containmentDronePortraitChassisAsset =
    'assets/containment_drone_v2/chassis-portrait-v3.png';

/// Concept-owned Containment housing layered around the required Variant F
/// nine-slice. The raster owns clipping and the Containment painter adds the
/// approved asymmetric chassis silhouette.
final class ContainmentDroneFrame extends StatelessWidget {
  const ContainmentDroneFrame({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.conceptAperture = false,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool conceptAperture;

  @override
  Widget build(BuildContext context) {
    final interior = AdditiveThemePanelInterior(child: child);
    if (conceptAperture) {
      return ClipRect(
        child: Padding(padding: padding, child: interior),
      );
    }
    return _ContainmentDroneV2PanelFrame(padding: padding, child: interior);
  }
}

final class _ContainmentDroneV2PanelFrame extends StatefulWidget {
  const _ContainmentDroneV2PanelFrame({
    required this.child,
    required this.padding,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  State<_ContainmentDroneV2PanelFrame> createState() =>
      _ContainmentDroneV2PanelFrameState();
}

final class _ContainmentDroneV2PanelFrameState
    extends State<_ContainmentDroneV2PanelFrame> {
  ImageStream? _stream;
  ImageInfo? _image;
  late final ImageStreamListener _listener = ImageStreamListener((image, _) {
    if (!mounted) return;
    setState(() => _image = image);
  });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = const AssetImage(
      containmentDronePanelAsset,
      package: 'clinical_calendar_presentation',
    ).resolve(createLocalImageConfiguration(context));
    if (next.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _image?.dispose();
    _image = null;
    _stream = next..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: CustomPaint(
      painter: _image == null
          ? null
          : _ContainmentDronePanelPainter(
              image: _image!.image,
              destinationInsets: widget.padding,
            ),
      child: Padding(
        padding: widget.padding,
        child: ClipRect(child: widget.child),
      ),
    ),
  );
}

final class _ContainmentDronePanelPainter extends CustomPainter {
  const _ContainmentDronePanelPainter({
    required this.image,
    required this.destinationInsets,
  });

  final ui.Image image;
  final EdgeInsets destinationInsets;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    const sourceInsets = EdgeInsets.fromLTRB(256, 128, 256, 128);
    final horizontalScale =
        (size.width / (destinationInsets.left + destinationInsets.right)).clamp(
          0.0,
          1.0,
        );
    final verticalScale =
        (size.height / (destinationInsets.top + destinationInsets.bottom))
            .clamp(0.0, 1.0);
    final destination = EdgeInsets.fromLTRB(
      destinationInsets.left * horizontalScale,
      destinationInsets.top * verticalScale,
      destinationInsets.right * horizontalScale,
      destinationInsets.bottom * verticalScale,
    );
    final sourceX = <double>[
      0,
      sourceInsets.left,
      image.width - sourceInsets.right,
      image.width.toDouble(),
    ];
    final sourceY = <double>[
      0,
      sourceInsets.top,
      image.height - sourceInsets.bottom,
      image.height.toDouble(),
    ];
    final destinationX = <double>[
      0,
      destination.left,
      size.width - destination.right,
      size.width,
    ];
    final destinationY = <double>[
      0,
      destination.top,
      size.height - destination.bottom,
      size.height,
    ];
    final paint = Paint()..filterQuality = FilterQuality.high;
    for (var row = 0; row < 3; row++) {
      for (var column = 0; column < 3; column++) {
        canvas.drawImageRect(
          image,
          Rect.fromLTRB(
            sourceX[column],
            sourceY[row],
            sourceX[column + 1],
            sourceY[row + 1],
          ),
          Rect.fromLTRB(
            destinationX[column],
            destinationY[row],
            destinationX[column + 1],
            destinationY[row + 1],
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ContainmentDronePanelPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.destinationInsets != destinationInsets;
}

/// Full-screen asymmetrical cybernetic chassis for the replacement renderer.
final class ContainmentDroneChassis extends StatelessWidget {
  const ContainmentDroneChassis({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final systemPadding = MediaQuery.paddingOf(context);
    return Padding(
      padding: systemPadding,
      child: MediaQuery.removePadding(
        context: context,
        removeLeft: true,
        removeTop: true,
        removeRight: true,
        removeBottom: true,
        child: ColoredBox(
          key: const Key('containment-drone-safe-paint-area'),
          color: VariantFColors.background,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              fit: StackFit.expand,
              children: [
                ExcludeSemantics(
                  child: IgnorePointer(
                    child: Image.asset(
                      constraints.maxWidth > constraints.maxHeight
                          ? containmentDroneLandscapeChassisAsset
                          : containmentDronePortraitChassisAsset,
                      package: 'clinical_calendar_presentation',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class ContainmentDroneApplicationShell extends StatelessWidget {
  const ContainmentDroneApplicationShell({
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
      final enlargedText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final landscape =
          constraints.maxWidth >= 1280 &&
          constraints.maxHeight >= 800 &&
          constraints.maxWidth > constraints.maxHeight;
      final portrait =
          constraints.maxWidth >= 840 &&
          constraints.maxHeight >= constraints.maxWidth;
      if (enlargedText) return _compact(context);
      if (landscape) return _landscape();
      if (portrait) return _portrait(context);
      return _compact(context);
    },
  );

  Widget _landscape() => Scaffold(
    key: const Key('containment-drone-landscape-shell'),
    backgroundColor: VariantFColors.background,
    body: ContainmentDroneChassis(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            return Stack(
              children: [
                Positioned(
                  left: width * .025,
                  top: height * .018,
                  width: width * .185,
                  height: height * .105,
                  child: _ContainmentDroneCrown(
                    frameKey: const Key(
                      'containment-drone-application-menu-crown',
                    ),
                    environmentName: environmentName,
                    onOpenMenu: onOpenMenu,
                    onOpenDestination: onOpenDestination,
                    onAddSchedule: onAddSchedule,
                    profileAvatar: slots.profileAvatar,
                    compact: true,
                    menuOnly: true,
                    conceptAperture: true,
                  ),
                ),
                Positioned(
                  left: width * .222,
                  top: height * .018,
                  width: width * .535,
                  height: height * .105,
                  child: _ContainmentDroneCrown(
                    frameKey: const Key(
                      'containment-drone-command-actions-crown',
                    ),
                    environmentName: environmentName,
                    onOpenMenu: onOpenMenu,
                    onOpenDestination: onOpenDestination,
                    onAddSchedule: onAddSchedule,
                    profileAvatar: slots.profileAvatar,
                    compact: width < 1450,
                    actionsOnly: true,
                    conceptAperture: true,
                  ),
                ),
                Positioned(
                  left: width * .025,
                  top: height * .135,
                  width: width * .185,
                  height: height * .735,
                  child: ContainmentDroneFrame(
                    key: const Key('containment-drone-placement-bay'),
                    conceptAperture: true,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    child: KeyedSubtree(
                      key: const Key('placement-dock'),
                      child: slots.placementDock,
                    ),
                  ),
                ),
                Positioned(
                  left: width * .222,
                  top: height * .135,
                  width: width * .535,
                  height: height * .55,
                  child: ContainmentDroneFrame(
                    key: const Key('containment-drone-calendar-bay'),
                    conceptAperture: true,
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    child: KeyedSubtree(
                      key: const Key('central-content'),
                      child: _ContainmentDroneCalendarViewport(
                        child: slots.centralContent,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: width * .222,
                  top: height * .662,
                  width: width * .535,
                  height: height * .208,
                  child: ContainmentDroneFrame(
                    key: const Key('containment-drone-planning-bay'),
                    conceptAperture: true,
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                    child: KeyedSubtree(
                      key: const Key('planning-region'),
                      child: SingleChildScrollView(
                        child: VariantFPlanningBayMode(
                          expandedByDefault: true,
                          child: slots.planningRegion,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: width * .769,
                  top: height * .018,
                  width: width * .206,
                  height: height * .664,
                  child: ContainmentDroneFrame(
                    key: const Key('containment-drone-insight-bay'),
                    conceptAperture: true,
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                    child: KeyedSubtree(
                      key: const Key('insight-rail'),
                      child: _progressDetailsScope(
                        slots.insightRail,
                        wheelDiameter: 250,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: width * .769,
                  top: height * .684,
                  width: width * .206,
                  height: height * .186,
                  child: ContainmentDroneFrame(
                    key: const Key('containment-drone-attention-bay'),
                    conceptAperture: true,
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                    child: SingleChildScrollView(child: slots.mobileAttention),
                  ),
                ),
                Positioned(
                  left: width * .025,
                  top: height * .888,
                  width: width * .95,
                  height: height * .092,
                  child: _ContainmentDroneNavigation(
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

  Widget _portrait(BuildContext context) {
    return Scaffold(
      key: const Key('containment-drone-portrait-shell'),
      backgroundColor: VariantFColors.background,
      body: ContainmentDroneChassis(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            return KeyedSubtree(
              key: const Key('variant-f-tablet-console'),
              child: Stack(
                children: [
                  Positioned(
                    left: width * .04,
                    top: height * .018,
                    width: width * .92,
                    height: height * .075,
                    child: _ContainmentDroneCrown(
                      environmentName: environmentName,
                      onOpenMenu: onOpenMenu,
                      onOpenDestination: onOpenDestination,
                      onAddSchedule: onAddSchedule,
                      profileAvatar: slots.profileAvatar,
                      compact: true,
                      conceptAperture: true,
                    ),
                  ),
                  Positioned(
                    key: const Key('containment-drone-portrait-scroll'),
                    left: width * .04,
                    top: height * .105,
                    width: width * .92,
                    height: height * .355,
                    child: ContainmentDroneFrame(
                      key: const Key('containment-drone-calendar-bay'),
                      conceptAperture: true,
                      padding: const EdgeInsets.all(8),
                      child: KeyedSubtree(
                        key: const Key('central-content'),
                        child: _ContainmentDroneCalendarViewport(
                          child: slots.centralContent,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: width * .04,
                    top: height * .455,
                    width: width * .27,
                    height: height * .31,
                    child: ContainmentDroneFrame(
                      key: const Key('containment-drone-placement-bay'),
                      conceptAperture: true,
                      padding: const EdgeInsets.all(8),
                      child: KeyedSubtree(
                        key: const Key('placement-dock'),
                        child: EmbeddedPlacementPanelInterior(
                          child: slots.placementDock,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: width * .34,
                    top: height * .455,
                    width: width * .62,
                    height: height * .205,
                    child: ContainmentDroneFrame(
                      key: const Key('containment-drone-insight-bay'),
                      conceptAperture: true,
                      padding: const EdgeInsets.all(8),
                      child: KeyedSubtree(
                        key: const Key('insight-rail'),
                        child: SingleChildScrollView(
                          child: _progressDetailsScope(
                            slots.insightRail,
                            wheelDiameter: 190,
                            sideBySide: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: width * .34,
                    top: height * .68,
                    width: width * .62,
                    height: height * .10,
                    child: ContainmentDroneFrame(
                      key: const Key('containment-drone-planning-bay'),
                      conceptAperture: true,
                      padding: const EdgeInsets.all(6),
                      child: KeyedSubtree(
                        key: const Key('planning-region'),
                        child: SingleChildScrollView(
                          child: VariantFPlanningBayMode(
                            expandedByDefault: false,
                            child: slots.planningRegion,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: width * .04,
                    top: height * .80,
                    width: width * .92,
                    height: height * .105,
                    child: ContainmentDroneFrame(
                      key: const Key('containment-drone-attention-bay'),
                      conceptAperture: true,
                      padding: const EdgeInsets.all(6),
                      child: SingleChildScrollView(
                        child: slots.mobileAttention,
                      ),
                    ),
                  ),
                  Positioned(
                    left: width * .04,
                    top: height * .925,
                    width: width * .92,
                    height: height * .06,
                    child: _ContainmentDroneNavigation(
                      selectedIndex: mobileIndex,
                      onOpenDestination: onOpenDestination,
                      onOpenAttention: onOpenAttention,
                      compact: true,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _compact(BuildContext context) => Scaffold(
    key: const Key('containment-drone-compact-shell'),
    backgroundColor: VariantFColors.background,
    body: ContainmentDroneChassis(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 76,
              child: _ContainmentDroneCrown(
                environmentName: environmentName,
                onOpenMenu: onOpenMenu,
                onOpenDestination: onOpenDestination,
                onAddSchedule: onAddSchedule,
                profileAvatar: slots.profileAvatar,
                compact: true,
                phone: true,
                conceptAperture: true,
              ),
            ),
            Expanded(
              child: KeyedSubtree(
                key: const Key('mobile-content-scroll'),
                child: SingleChildScrollView(
                  key: const Key('containment-drone-compact-scroll'),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _compactPanel(
                        key: const Key('containment-drone-calendar-bay'),
                        legacyKey: const Key('central-content'),
                        child: _ContainmentDroneCalendarViewport(
                          bounded: false,
                          child: slots.centralContent,
                        ),
                      ),
                      _compactPanel(
                        key: const Key('containment-drone-placement-bay'),
                        legacyKey: const Key('placement-dock'),
                        child: SizedBox(
                          height:
                              320 *
                              MediaQuery.textScalerOf(
                                context,
                              ).scale(1).clamp(1, 2),
                          child: EmbeddedPlacementPanelInterior(
                            outerScrollOwnsVerticalOverflow: true,
                            child: slots.placementDock,
                          ),
                        ),
                      ),
                      _compactPanel(
                        key: const Key('containment-drone-insight-bay'),
                        legacyKey: const Key('insight-rail'),
                        child: _progressDetailsScope(slots.insightRail),
                      ),
                      _compactPanel(
                        key: const Key('containment-drone-planning-bay'),
                        legacyKey: const Key('planning-region'),
                        child: slots.planningRegion,
                      ),
                      _compactPanel(
                        key: const Key('containment-drone-attention-bay'),
                        child: slots.mobileAttention,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: _ContainmentDroneNavigation(
      selectedIndex: mobileIndex,
      onOpenDestination: onOpenDestination,
      onOpenAttention: onOpenAttention,
      compact: true,
    ),
  );

  Widget _compactPanel({
    required Key key,
    Key? legacyKey,
    required Widget child,
  }) => KeyedSubtree(
    key: legacyKey,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ContainmentDroneFrame(
        key: key,
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: child,
      ),
    ),
  );

  Widget _progressDetailsScope(
    Widget child, {
    double? wheelDiameter,
    bool sideBySide = false,
  }) => Builder(
    builder: (context) => InsightRailPresentationPolicy(
      placementProgressLayout: sideBySide
          ? PlacementProgressRailLayout.sideBySide
          : PlacementProgressRailLayout.vertical,
      child: PlacementProgressPanelPolicy(
        wheelAlignment: Alignment.center,
        wheelPadding: EdgeInsets.zero,
        compactLedger: true,
        segmentedWheel: true,
        wheelDiameter: wheelDiameter,
        child: PlacementProgressDetailsScope(
          onOpenDetails: (snapshot) => showDialog<void>(
            context: context,
            builder: (dialogContext) => Dialog.fullscreen(
              child: ContainmentDronePlacementDetailsSurface(
                snapshot: snapshot,
                onClose: () => Navigator.pop(dialogContext),
                onManage: () {
                  Navigator.pop(dialogContext);
                  onOpenDestination(
                    ClinicalCalendarDestination.clinicalPlacements,
                  );
                },
              ),
            ),
          ),
          child: child,
        ),
      ),
    ),
  );
}

/// Read-only, live detail view for the active placement selected by the shared
/// progress controller. Management remains in the canonical destination.
final class ContainmentDronePlacementDetailsSurface extends StatelessWidget {
  const ContainmentDronePlacementDetailsSurface({
    required this.snapshot,
    required this.onClose,
    required this.onManage,
    super.key,
  });

  final PlacementSnapshot snapshot;
  final VoidCallback onClose;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final progress = snapshot.progress;
    final metrics = <(String, int)>[
      ('Completed Hours', progress.completedMinutes),
      ('Scheduled Hours', progress.scheduledMinutes),
      ('Remaining Hours', progress.remainingMinutes),
      ('Unscheduled Hours', progress.unscheduledMinutes),
      ('Over-Target Hours', progress.overTargetMinutes),
    ];
    final detailLedger = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: 180,
                child: _ContainmentDetailMetric(
                  label: metric.$1,
                  value: _detailHours(metric.$2),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text('PRECEPTORS', style: Theme.of(context).textTheme.titleMedium),
        for (final attached in snapshot.attachedPreceptors)
          Text(
            '${attached.isPrimary ? 'Primary · ' : 'Attached · '}'
            '${attached.preceptor.name}',
          ),
        const SizedBox(height: 18),
        Text(
          'UPCOMING CLINICAL SESSIONS',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (snapshot.scheduledFutureSessions.isEmpty)
          const Text(
            'No upcoming Clinical Sessions.',
            key: Key('placement-upcoming-sessions-empty'),
          ),
        for (final session in snapshot.scheduledFutureSessions)
          _ContainmentUpcomingSessionRow(
            session: session,
            preceptorName: snapshot.attachedPreceptors
                .where(
                  (attached) => attached.preceptor.id == session.preceptorId,
                )
                .map((attached) => attached.preceptor.name)
                .firstOrNull,
          ),
        const SizedBox(height: 18),
        Text(
          'EVALUATION PLAN REQUIREMENTS',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (snapshot.evaluation.requirements.isEmpty)
          const Text('No requirements configured.'),
        for (final item in snapshot.evaluation.requirements)
          Text(_containmentEvaluationLabel(item.requirement.identity)),
      ],
    );
    return Material(
      key: const Key('containment-placement-details'),
      color: VariantFColors.background,
      child: ContainmentDroneChassis(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ContainmentDroneFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          snapshot.placement.name.toUpperCase(),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        key: const Key('close-placement-details'),
                        tooltip: 'Close placement details',
                        onPressed: onClose,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Text(
                    'TARGET ${_detailHours(progress.targetMinutes)} · '
                    'DEADLINE ${formatUsDate(snapshot.placement.completionDeadline)}',
                  ),
                  const Divider(),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final instrument = _ContainmentPlacementInstrument(
                          snapshot: snapshot,
                          diameter: constraints.maxWidth >= 760 ? 300 : 220,
                        );
                        if (constraints.maxWidth >= 760) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              instrument,
                              const SizedBox(width: 20),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: detailLedger,
                                ),
                              ),
                            ],
                          );
                        }
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              instrument,
                              const SizedBox(height: 16),
                              detailLedger,
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  FilledButton.icon(
                    key: const Key('manage-placement-from-details'),
                    onPressed: onManage,
                    icon: const Icon(Icons.settings_outlined),
                    label: const Text('Manage Clinical Placement'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ContainmentPlacementInstrument extends StatelessWidget {
  const _ContainmentPlacementInstrument({
    required this.snapshot,
    required this.diameter,
  });

  final PlacementSnapshot snapshot;
  final double diameter;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '${snapshot.placement.name} progress instrument',
    child: SizedBox.square(
      key: const Key('containment-placement-details-instrument'),
      dimension: diameter,
      child: PlacementProgressWheelGraphic.forProgress(
        progress: snapshot.progress,
        segmented: true,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _detailHours(snapshot.progress.completedMinutes),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text('COMPLETED', style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    ),
  );
}

final class _ContainmentUpcomingSessionRow extends StatelessWidget {
  const _ContainmentUpcomingSessionRow({
    required this.session,
    required this.preceptorName,
  });

  final ClinicalSession session;
  final String? preceptorName;

  @override
  Widget build(BuildContext context) {
    final interval = session.plannedInterval;
    return ListTile(
      key: Key('placement-upcoming-session-${session.id}'),
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: const Icon(Icons.medical_services_outlined),
      title: Text(
        '${formatUsDate(interval.startDate)} · '
        '${interval.startTime.twelveHour}–${interval.endTime.twelveHour}',
      ),
      subtitle: Text(
        '${preceptorName ?? 'Attached Preceptor'} · '
        '${interval.timeZone.value}',
      ),
    );
  }
}

final class _ContainmentDetailMetric extends StatelessWidget {
  const _ContainmentDetailMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: VariantFColors.surface.withValues(alpha: .82),
      border: Border.all(color: VariantFColors.controlBorder),
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    ),
  );
}

String _detailHours(int minutes) => minutes % 60 == 0
    ? '${minutes ~/ 60} hr'
    : '${(minutes / 60).toStringAsFixed(1)} hr';

String _containmentEvaluationLabel(EvaluationRequirementIdentity identity) {
  final threshold = identity.thresholdMinutes;
  final atHours = threshold == null ? '' : ' at ${_detailHours(threshold)}';
  return switch (identity.kind) {
    EvaluationRequirementKind.initialSelfAssessment =>
      'Initial Self-Assessment',
    EvaluationRequirementKind.interimStudentReviewsPrimaryPreceptor =>
      'Student Reviews Primary Preceptor$atHours',
    EvaluationRequirementKind.interimPrimaryPreceptorReviewsStudent =>
      'Primary Preceptor Reviews Student$atHours',
    EvaluationRequirementKind.finalSelfAssessment => 'Final Self-Assessment',
    EvaluationRequirementKind.finalPlacementReview => 'Final Placement Review',
  };
}

final class ContainmentDroneDestinationSurface extends StatelessWidget {
  const ContainmentDroneDestinationSurface({
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
  Widget build(BuildContext context) => Scaffold(
    key: const Key('containment-drone-destination-shell'),
    backgroundColor: VariantFColors.background,
    body: ContainmentDroneChassis(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 82,
                child: ContainmentDroneFrame(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compactHeader = constraints.maxWidth < 430;
                      final exitAction = _ContainmentDestinationExitControl(
                        entry: entry,
                        compact: compactHeader,
                        onExit: onExit,
                      );
                      final title = CustomPaint(
                        painter: const _ContainmentCommandCellPainter(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Icon(
                                destination.icon,
                                color: VariantFColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  destination.label.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      return Row(
                        children: [
                          SizedBox(
                            width: compactHeader ? 72 : 210,
                            child: exitAction,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: title),
                          const SizedBox(width: 8),
                          _ContainmentDestinationIdentityDial(
                            destination: destination,
                            compact: compactHeader,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ContainmentDroneFrame(
                  padding: EdgeInsets.all(
                    MediaQuery.sizeOf(context).width < 600 ? 12 : 20,
                  ),
                  child:
                      destination ==
                          ClinicalCalendarDestination.clinicalPlacements
                      ? PlacementManagementPresentation(
                          promoteDeletionToHeader: true,
                          adaptEnlargedText: true,
                          child: child,
                        )
                      : child,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final class _ContainmentDestinationExitControl extends StatelessWidget {
  const _ContainmentDestinationExitControl({
    required this.entry,
    required this.compact,
    required this.onExit,
  });

  final DestinationEntry entry;
  final bool compact;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final fromMenu = entry == DestinationEntry.applicationMenu;
    return KeyedSubtree(
      key: Key(fromMenu ? 'back-action' : 'close-action'),
      child: Tooltip(
        message: fromMenu ? 'Return to Application Menu' : 'Close destination',
        child: Semantics(
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: fromMenu
                  ? const Key('application-menu-action')
                  : const Key('destination-exit-action'),
              onTap: onExit,
              child: CustomPaint(
                key: const Key('containment-destination-live-exit-control'),
                painter: const _ContainmentNavigationKeyPainter(selected: true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (fromMenu)
                        CanonicalDeltaMark(size: compact ? 30 : 36)
                      else
                        const Icon(Icons.arrow_back),
                      if (!compact) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              fromMenu ? 'APPLICATION MENU' : 'CLOSE',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ContainmentDestinationIdentityDial extends StatelessWidget {
  const _ContainmentDestinationIdentityDial({
    required this.destination,
    required this.compact,
  });

  final ClinicalCalendarDestination destination;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('containment-destination-identity-dial'),
    width: compact ? 52 : 62,
    height: compact ? 52 : 62,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        colors: [Color(0xFF233329), Color(0xFF07100B), Color(0xFF1A231D)],
        stops: [0, .64, 1],
      ),
      border: Border.all(color: const Color(0xFF79C44D), width: 2),
      boxShadow: const [
        BoxShadow(color: Color(0xAA000000), blurRadius: 5),
        BoxShadow(color: Color(0x333FCB45), blurRadius: 8),
      ],
    ),
    child: Icon(
      destination.icon,
      color: VariantFColors.primary,
      size: compact ? 22 : 28,
    ),
  );
}

final class _ContainmentDroneCrown extends StatelessWidget {
  const _ContainmentDroneCrown({
    required this.environmentName,
    required this.onOpenMenu,
    required this.onOpenDestination,
    required this.onAddSchedule,
    required this.profileAvatar,
    this.frameKey = const Key('containment-drone-command-crown'),
    this.compact = false,
    this.phone = false,
    this.menuOnly = false,
    this.actionsOnly = false,
    this.conceptAperture = false,
  });

  final String environmentName;
  final VoidCallback onOpenMenu;
  final ValueChanged<ClinicalCalendarDestination> onOpenDestination;
  final VoidCallback onAddSchedule;
  final Widget profileAvatar;
  final Key frameKey;
  final bool compact;
  final bool phone;
  final bool menuOnly;
  final bool actionsOnly;
  final bool conceptAperture;

  @override
  Widget build(BuildContext context) => ContainmentDroneFrame(
    key: frameKey,
    conceptAperture: conceptAperture,
    padding: EdgeInsets.symmetric(horizontal: phone ? 6 : 12, vertical: 6),
    child: Row(
      children: [
        if (!actionsOnly)
          if (menuOnly)
            Expanded(child: _menuAction(context))
          else
            SizedBox(
              width: phone ? 54 : (compact ? 108 : 150),
              child: _menuAction(context),
            ),
        if (!menuOnly && !compact && environmentName.trim().isNotEmpty) ...[
          const SizedBox(width: 10),
          Text(environmentName, style: Theme.of(context).textTheme.labelSmall),
        ],
        if (!menuOnly) const SizedBox(width: 8),
        if (!menuOnly)
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 11,
                  child: _crownAction(
                    context: context,
                    key: const Key('containment-command-add-schedule'),
                    tooltip: 'Open Add Schedule',
                    icon: Icons.add_box_outlined,
                    label: 'ADD SCHEDULE',
                    onPressed: onAddSchedule,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 9,
                  child: _crownAction(
                    context: context,
                    key: const Key('containment-command-help'),
                    tooltip: 'Open Help',
                    icon: Icons.help_outline,
                    label: 'HELP',
                    onPressed: () =>
                        onOpenDestination(ClinicalCalendarDestination.help),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 12,
                  child: _crownAction(
                    context: context,
                    key: const Key('containment-command-notifications'),
                    tooltip: 'Open Notifications',
                    icon: Icons.notifications_outlined,
                    label: 'NOTIFICATIONS',
                    onPressed: () => onOpenDestination(
                      ClinicalCalendarDestination.notifications,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 14,
                  child: _crownAction(
                    context: context,
                    key: const Key('containment-command-synchronization'),
                    tooltip: 'Open Synchronization',
                    icon: Icons.sync_outlined,
                    label: 'SYNCHRONIZATION',
                    onPressed: () => onOpenDestination(
                      ClinicalCalendarDestination.synchronization,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (!menuOnly) const SizedBox(width: 8),
        if (!menuOnly)
          Container(
            key: const Key('containment-command-student-control'),
            width: phone ? 48 : 58,
            height: phone ? 48 : 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF07100B),
              border: Border.all(color: const Color(0xFF526052), width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0xAA000000), blurRadius: 6),
                BoxShadow(color: Color(0x443FCB45), blurRadius: 8),
              ],
            ),
            alignment: Alignment.center,
            child: SizedBox.square(dimension: 44, child: profileAvatar),
          ),
      ],
    ),
  );

  Widget _menuAction(BuildContext context) => KeyedSubtree(
    key: const Key('mobile-menu-action'),
    child: Semantics(
      key: const Key('desktop-menu-action'),
      button: true,
      label: 'Open menu',
      child: InkWell(
        key: const Key('application-menu-action'),
        onTap: onOpenMenu,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CanonicalDeltaMark(
                imageKey: const Key('containment-drone-axion-delta'),
                size: phone ? 30 : (compact ? 38 : 52),
                errorBuilder: (_, _, _) => const Icon(Icons.apps),
              ),
              if (!phone)
                Text(
                  'APPLICATION MENU',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _crownAction({
    required BuildContext context,
    required Key key,
    required String tooltip,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) => SizedBox(
    key: key,
    height: phone ? 44 : 56,
    child: Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key(switch (tooltip) {
              'Open Add Schedule' => 'desktop-add-schedule-action',
              'Open Help' => 'desktop-help-action',
              'Open Notifications' => 'desktop-notifications-action',
              _ => 'desktop-synchronization-action',
            }),
            onTap: onPressed,
            customBorder: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(3)),
            ),
            child: CustomPaint(
              painter: const _ContainmentCommandCellPainter(),
              child: KeyedSubtree(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: phone ? 4 : (compact ? 7 : 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: phone ? 18 : 20),
                      if (!phone) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

final class _ContainmentCommandCellPainter extends CustomPainter {
  const _ContainmentCommandCellPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final outer = Path()
      ..moveTo(5, 0)
      ..lineTo(size.width - 3, 0)
      ..lineTo(size.width, 5)
      ..lineTo(size.width, size.height - 7)
      ..lineTo(size.width - 7, size.height)
      ..lineTo(3, size.height)
      ..lineTo(0, size.height - 4)
      ..lineTo(0, 6)
      ..close();
    canvas.drawPath(
      outer,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF263029), Color(0xFF07120D), Color(0xFF121B16)],
          stops: [0, .46, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF090C0A),
    );
    final inset = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    canvas.drawRect(
      inset,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF526052),
    );
    canvas.drawLine(
      Offset(8, 6),
      Offset(size.width - 8, 6),
      Paint()
        ..strokeWidth = 1
        ..color = const Color(0xFF89968A).withValues(alpha: .42),
    );
    for (final x in [10.0, size.width - 10]) {
      canvas.drawCircle(
        Offset(x, size.height - 8),
        1.4,
        Paint()..color = const Color(0xFF72C760).withValues(alpha: .65),
      );
    }
  }

  @override
  bool shouldRepaint(_ContainmentCommandCellPainter oldDelegate) => false;
}

final class _ContainmentDroneCalendarViewport extends StatelessWidget {
  const _ContainmentDroneCalendarViewport({
    required this.child,
    this.bounded = true,
  });

  final Widget child;
  final bool bounded;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final calendar = CalendarPeriodViewportPolicy(
        useBoundedMonthGrid: bounded,
        scaleDayNumberWithText: true,
        useEnlargedTextLandscapeReflow: true,
        centerPeriodHeader: true,
        useConceptMonthMarks: constraints.maxWidth >= 800,
        clipDayDecoration: true,
        allowLowHeightMonthScroll: true,
        child: _ContainmentCalendarTheme(
          compactCells: constraints.maxWidth < 800,
          child: child,
        ),
      );
      return calendar;
    },
  );
}

final class _ContainmentCalendarTheme extends StatelessWidget {
  const _ContainmentCalendarTheme({
    required this.child,
    this.compactCells = false,
  });
  final Widget child;
  final bool compactCells;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final policy = theme.extension<ClinicalCalendarPresentationPolicy>();
    if (policy == null) {
      return child;
    }
    final metrics = policy.monthCellMetrics;
    final conceptMetrics = CalendarMonthCellMetrics(
      weekdayHeaderHeight: metrics.weekdayHeaderHeight,
      weekdayLabelFontSize: metrics.weekdayLabelFontSize,
      weekdayLabelFontWeight: metrics.weekdayLabelFontWeight,
      cellPadding: compactCells ? const EdgeInsets.all(1) : metrics.cellPadding,
      markerHeight: compactCells ? 12 : metrics.markerHeight,
      markerHorizontalPadding: metrics.markerHorizontalPadding,
      markerIconSize: compactCells ? 8 : metrics.markerIconSize,
      markerGap: compactCells ? 1 : metrics.markerGap,
      markerFontSize: compactCells ? 8 : metrics.markerFontSize,
      dayNumberFontSize: compactCells ? 10 : metrics.dayNumberFontSize,
      gridStrokeWidth: metrics.gridStrokeWidth,
      gridOpacity: metrics.gridOpacity,
      roundedSelection: metrics.roundedSelection,
    );
    return Theme(
      data: theme.copyWith(
        extensions: [
          for (final extension in theme.extensions.values)
            if (extension is! ClinicalCalendarPresentationPolicy) extension,
          policy.copyWith(monthCellMetrics: conceptMetrics),
        ],
      ),
      child: child,
    );
  }
}

final class _ContainmentDroneNavigation extends StatelessWidget {
  const _ContainmentDroneNavigation({
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
  Widget build(BuildContext context) => KeyedSubtree(
    key: const Key('bottom-navigation'),
    child: ContainmentDroneFrame(
      key: const Key('containment-drone-bottom-navigation'),
      conceptAperture: true,
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 12, vertical: 4),
      child: Row(
        children: [
          for (
            var index = 0;
            index < ClinicalCalendarPrimaryNavigation.values.length;
            index++
          ) ...[
            if (index > 0) SizedBox(width: compact ? 4 : 8),
            Expanded(
              child: _ContainmentDroneNavigationAction(
                navigation: ClinicalCalendarPrimaryNavigation.values[index],
                selected: index == selectedIndex,
                compact: compact,
                onPressed: () =>
                    ClinicalCalendarPrimaryNavigation.values[index].activate(
                      onOpenDestination: onOpenDestination,
                      onOpenAttention: onOpenAttention,
                    ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

final class _ContainmentDroneNavigationAction extends StatelessWidget {
  const _ContainmentDroneNavigationAction({
    required this.navigation,
    required this.selected,
    required this.compact,
    required this.onPressed,
  });

  final ClinicalCalendarPrimaryNavigation navigation;
  final bool selected;
  final bool compact;
  final VoidCallback onPressed;

  ({String segment, String tooltip}) get _identity => switch (navigation) {
    ClinicalCalendarPrimaryNavigation.today => (
      segment: 'today',
      tooltip: 'Open Today',
    ),
    ClinicalCalendarPrimaryNavigation.calendar => (
      segment: 'calendar',
      tooltip: 'Open Calendar',
    ),
    ClinicalCalendarPrimaryNavigation.placements => (
      segment: 'placements',
      tooltip: 'Open Clinical Placements',
    ),
    ClinicalCalendarPrimaryNavigation.attention => (
      segment: 'attention',
      tooltip: 'Open Attention',
    ),
    ClinicalCalendarPrimaryNavigation.settings => (
      segment: 'settings',
      tooltip: 'Open Settings',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final identity = _identity;
    return KeyedSubtree(
      key: Key('containment-navigation-${identity.segment}'),
      child: Tooltip(
        message: identity.tooltip,
        child: Semantics(
          selected: selected,
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              customBorder: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              child: CustomPaint(
                painter: _ContainmentNavigationKeyPainter(selected: selected),
                child: KeyedSubtree(
                  key:
                      selected &&
                          navigation ==
                              ClinicalCalendarPrimaryNavigation.calendar
                      ? const Key('containment-navigation-calendar-active')
                      : null,
                  child: SizedBox(
                    height: compact ? 58 : 68,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          navigation.icon,
                          size: compact ? 20 : 26,
                          color: selected
                              ? VariantFColors.primary
                              : VariantFColors.muted,
                        ),
                        if (!compact ||
                            MediaQuery.sizeOf(context).width >= 360) ...[
                          SizedBox(width: compact ? 4 : 12),
                          Flexible(
                            child: Text(
                              navigation.label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    letterSpacing: compact ? .5 : 1.4,
                                    color: selected
                                        ? VariantFColors.primary
                                        : VariantFColors.muted,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ContainmentNavigationKeyPainter extends CustomPainter {
  const _ContainmentNavigationKeyPainter({required this.selected});

  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final housing = Path()
      ..moveTo(14, 0)
      ..lineTo(size.width - 12, 0)
      ..lineTo(size.width, 12)
      ..lineTo(size.width - 5, size.height - 8)
      ..lineTo(size.width - 15, size.height)
      ..lineTo(12, size.height)
      ..lineTo(0, size.height - 12)
      ..lineTo(5, 9)
      ..close();
    canvas.drawPath(
      housing,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: selected
              ? const [Color(0xFF19251A), Color(0xFF071108), Color(0xFF20331B)]
              : const [Color(0xFF29312D), Color(0xFF0A100D), Color(0xFF161E19)],
          stops: const [0, .52, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      housing,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.2 : 1.6
        ..color = selected ? const Color(0xFF79C44D) : const Color(0xFF4E5B52),
    );
    final recess = Rect.fromLTRB(10, 8, size.width - 10, size.height - 9);
    canvas.drawRect(
      recess,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = selected ? const Color(0xFF315D29) : const Color(0xFF202A24),
    );
    if (selected) {
      canvas.drawLine(
        Offset(18, size.height - 7),
        Offset(size.width - 18, size.height - 7),
        Paint()
          ..strokeWidth = 3
          ..color = const Color(0xFF72C742),
      );
    }
  }

  @override
  bool shouldRepaint(_ContainmentNavigationKeyPainter oldDelegate) =>
      oldDelegate.selected != selected;
}
