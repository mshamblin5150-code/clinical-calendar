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
                    child: SingleChildScrollView(
                      child: Column(
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
                          Text(
                            'PRECEPTORS',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
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
                          for (final session
                              in snapshot.scheduledFutureSessions)
                            _ContainmentUpcomingSessionRow(
                              session: session,
                              preceptorName: snapshot.attachedPreceptors
                                  .where(
                                    (attached) =>
                                        attached.preceptor.id ==
                                        session.preceptorId,
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
                            Text(
                              _containmentEvaluationLabel(
                                item.requirement.identity,
                              ),
                            ),
                        ],
                      ),
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
                height: 70,
                child: ContainmentDroneFrame(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compactHeader = constraints.maxWidth < 430;
                      final exitAction = KeyedSubtree(
                        key: Key(
                          entry == DestinationEntry.applicationMenu
                              ? 'back-action'
                              : 'close-action',
                        ),
                        child: TextButton(
                          key: entry == DestinationEntry.applicationMenu
                              ? const Key('application-menu-action')
                              : const Key('destination-exit-action'),
                          onPressed: onExit,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (entry == DestinationEntry.applicationMenu)
                                const CanonicalDeltaMark(size: 34)
                              else
                                const Icon(Icons.arrow_back),
                              const SizedBox(width: 8),
                              Text(
                                entry == DestinationEntry.applicationMenu
                                    ? 'APPLICATION MENU'
                                    : 'Close',
                              ),
                            ],
                          ),
                        ),
                      );
                      return Row(
                        children: [
                          if (compactHeader)
                            Expanded(
                              flex: 3,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: exitAction,
                              ),
                            )
                          else
                            exitAction,
                          const SizedBox(width: 8),
                          if (!compactHeader) ...[
                            Icon(
                              destination.icon,
                              color: VariantFColors.primary,
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            flex: compactHeader ? 2 : 1,
                            child: Text(
                              destination.label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (constraints.maxWidth >= 600 &&
                              MediaQuery.textScalerOf(context).scale(1) <= 1.3)
                            const Text('CONTAINMENT DRONE 47-ALPHA'),
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
          Expanded(
            child: KeyedSubtree(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
            ),
          ),
        if (!menuOnly && !compact && environmentName.trim().isNotEmpty) ...[
          const SizedBox(width: 10),
          Text(environmentName, style: Theme.of(context).textTheme.labelSmall),
        ],
        if (!menuOnly) const SizedBox(width: 8),
        if (!menuOnly)
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _crownAction(
                    key: const Key('desktop-add-schedule-action'),
                    tooltip: 'Open Add Schedule',
                    icon: Icons.add_box_outlined,
                    label: 'ADD SCHEDULE',
                    onPressed: onAddSchedule,
                  ),
                  _crownAction(
                    key: const Key('desktop-help-action'),
                    tooltip: 'Open Help',
                    icon: Icons.help_outline,
                    label: 'HELP',
                    onPressed: () =>
                        onOpenDestination(ClinicalCalendarDestination.help),
                  ),
                  _crownAction(
                    key: const Key('desktop-notifications-action'),
                    tooltip: 'Open Notifications',
                    icon: Icons.notifications_outlined,
                    label: 'NOTIFICATIONS',
                    onPressed: () => onOpenDestination(
                      ClinicalCalendarDestination.notifications,
                    ),
                  ),
                  _crownAction(
                    key: const Key('desktop-synchronization-action'),
                    tooltip: 'Open Synchronization',
                    icon: Icons.sync_outlined,
                    label: 'SYNCHRONIZATION',
                    onPressed: () => onOpenDestination(
                      ClinicalCalendarDestination.synchronization,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!menuOnly) const SizedBox(width: 8),
        if (!menuOnly)
          SizedBox.square(dimension: phone ? 44 : 46, child: profileAvatar),
      ],
    ),
  );

  Widget _crownAction({
    required Key key,
    required String tooltip,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) => Padding(
    key: key,
    padding: const EdgeInsets.only(left: 4),
    child: Tooltip(
      message: tooltip,
      child: phone
          ? Semantics(
              button: true,
              label: tooltip,
              child: InkWell(
                onTap: onPressed,
                child: SizedBox(
                  width: 34,
                  height: 44,
                  child: Center(child: Icon(icon, size: 19)),
                ),
              ),
            )
          : TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: Size(compact ? 42 : 74, 44),
                padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 12),
              ),
              onPressed: onPressed,
              icon: Icon(icon, size: 19),
              label: compact ? const SizedBox.shrink() : Text(label),
            ),
    ),
  );
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
          )
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

  @override
  Widget build(BuildContext context) => Tooltip(
    message: switch (navigation) {
      ClinicalCalendarPrimaryNavigation.today => 'Open Today',
      ClinicalCalendarPrimaryNavigation.calendar => 'Open Calendar',
      ClinicalCalendarPrimaryNavigation.placements =>
        'Open Clinical Placements',
      ClinicalCalendarPrimaryNavigation.attention => 'Open Attention',
      ClinicalCalendarPrimaryNavigation.settings => 'Open Settings',
    },
    child: Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: compact ? 58 : 68,
          decoration: BoxDecoration(
            color: selected
                ? VariantFColors.primary.withValues(alpha: .13)
                : VariantFColors.surface.withValues(alpha: .72),
            border: Border.all(
              color: selected
                  ? VariantFColors.primary
                  : VariantFColors.controlBorder,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                navigation.icon,
                color: selected ? VariantFColors.primary : VariantFColors.muted,
              ),
              if (!compact || MediaQuery.sizeOf(context).width >= 360)
                Text(
                  navigation.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: selected
                        ? VariantFColors.primary
                        : VariantFColors.muted,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
