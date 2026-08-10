import 'dart:math' as math;

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../additive_semantic_colors.dart';
import '../federation_classic_panel_scope.dart';
import '../graphite_instrument_scope.dart';
import '../insight_rail_presentation_policy.dart';
import '../tactical_frame.dart';
import '../variant_f_theme.dart';
import '../variant_f_raster_assets.dart';
import 'placement_progress_controller.dart';
import 'placement_specialty_icon.dart';

final class PlacementDock extends StatelessWidget {
  const PlacementDock({
    required this.controller,
    required this.studentId,
    this.onManage,
    super.key,
  });

  final PlacementProgressController controller;
  final String studentId;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    if (GraphiteInstrumentScope.isActive(context)) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) =>
            _GraphitePlacementDock(controller: controller, onManage: onManage),
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => _TacticalPanel(
        key: const Key('placement-dock-surface'),
        label: 'My placements',
        stackedHeader: true,
        expandChild: true,
        trailing: IconButton(
          key: const Key('manage-placements-action'),
          tooltip: 'Manage Clinical Placements',
          onPressed: onManage,
          icon: const Icon(Icons.settings_outlined, size: 19),
        ),
        child: controller.placements.isEmpty
            ? const _EmptyPlacementState()
            : Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      key: const Key('placement-dock-list'),
                      itemCount: controller.placements.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final snapshot = controller.placements[index];
                        return _PlacementDockRow(
                          snapshot: snapshot,
                          selected:
                              snapshot.placement.id ==
                              controller.activePlacementId,
                          onPressed: controller.isBusy
                              ? null
                              : () => controller.selectPlacement(
                                  snapshot.placement.id,
                                ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TotalProgressSegments(
                    progress: controller.totalProgress,
                    compact: true,
                  ),
                ],
              ),
      ),
    );
  }
}

final class PlacementProgressWheel extends StatelessWidget {
  const PlacementProgressWheel({
    required this.snapshot,
    required this.onCycle,
    this.touch = false,
    this.diameter = 142,
    super.key,
  });

  final PlacementSnapshot snapshot;
  final VoidCallback? onCycle;
  final bool touch;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final progress = snapshot.progress;
    final fractions = _progressWheelFractions(progress);
    final instrument = GraphiteInstrumentScope.isActive(context);
    final touchWording = _usesTouchWording(touch);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final effectiveDiameter = diameter * textScale.clamp(1.0, 1.7);
    final semantics =
        '${snapshot.placement.name}, ${_minutes(progress.completedMinutes)} '
        'Completed Hours of ${_minutes(progress.targetMinutes)} Target Hours, '
        '${_minutes(progress.scheduledMinutes)} Scheduled Hours, '
        '${_minutes(progress.unscheduledMinutes)} Unscheduled Hours, '
        '${_minutes(progress.overTargetMinutes)} Over-Target Hours. '
        '${touchWording ? 'Tap' : 'Click'} to show the next Clinical Placement.';
    return Semantics(
      button: true,
      label: semantics,
      child: InkWell(
        key: const Key('placement-progress-wheel'),
        onTap: onCycle,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: effectiveDiameter,
          child: PlacementProgressWheelGraphic(
            key: instrument ? const Key('graphite-live-detailed-wheel') : null,
            completedFraction: fractions.completed,
            scheduledFraction: fractions.scheduled,
            unscheduledFraction: fractions.unscheduled,
            overTargetFraction: fractions.overTarget,
            instrument: instrument,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _minutes(progress.completedMinutes),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    'completed',
                    style: Theme.of(context).textTheme.bodySmall,
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

/// Shared production wheel graphic used by the live progress surface and
/// deterministic concept evidence. Fractions are normalized to the target.
final class PlacementProgressWheelGraphic extends StatelessWidget {
  const PlacementProgressWheelGraphic({
    required this.completedFraction,
    required this.scheduledFraction,
    required this.unscheduledFraction,
    this.overTargetFraction = 0,
    this.instrument = false,
    required this.child,
    super.key,
  });

  final double completedFraction;
  final double scheduledFraction;
  final double unscheduledFraction;
  final double overTargetFraction;
  final bool instrument;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _ProgressWheelPainter(
      completedFraction: completedFraction,
      scheduledFraction: scheduledFraction,
      unscheduledFraction: unscheduledFraction,
      overTargetFraction: overTargetFraction,
      colors: context.clinicalColors,
      additiveColors: Theme.of(
        context,
      ).extension<ClinicalCalendarAdditiveColors>(),
      instrument: instrument,
    ),
    child: child,
  );
}

/// Opt-in layout policy for a theme-owned progress bay.
final class PlacementProgressPanelPolicy extends InheritedWidget {
  const PlacementProgressPanelPolicy({
    required this.wheelAlignment,
    required this.wheelPadding,
    required this.compactLedger,
    this.conceptActionRail = false,
    this.emphasizeProjection = false,
    required super.child,
    super.key,
  });

  final AlignmentGeometry wheelAlignment;
  final EdgeInsetsGeometry wheelPadding;
  final bool compactLedger;
  final bool conceptActionRail;
  final bool emphasizeProjection;

  static PlacementProgressPanelPolicy? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PlacementProgressPanelPolicy>();

  @override
  bool updateShouldNotify(PlacementProgressPanelPolicy oldWidget) =>
      wheelAlignment != oldWidget.wheelAlignment ||
      wheelPadding != oldWidget.wheelPadding ||
      compactLedger != oldWidget.compactLedger ||
      conceptActionRail != oldWidget.conceptActionRail ||
      emphasizeProjection != oldWidget.emphasizeProjection;
}

/// Marks a placement panel embedded inside theme-owned housing so shared
/// content does not paint a second tactical frame.
final class EmbeddedPlacementPanelInterior extends InheritedWidget {
  const EmbeddedPlacementPanelInterior({required super.child, super.key});

  static bool isActive(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<
            EmbeddedPlacementPanelInterior
          >() !=
      null;

  @override
  bool updateShouldNotify(EmbeddedPlacementPanelInterior oldWidget) => false;
}

final class PlacementProgressRail extends StatefulWidget {
  const PlacementProgressRail({
    required this.controller,
    required this.studentId,
    this.touch = false,
    super.key,
  });

  final PlacementProgressController controller;
  final String studentId;
  final bool touch;

  @override
  State<PlacementProgressRail> createState() => _PlacementProgressRailState();
}

final class _PlacementProgressRailState extends State<PlacementProgressRail> {
  bool _showPreceptors = false;

  @override
  Widget build(BuildContext context) {
    if (GraphiteInstrumentScope.isActive(context)) {
      return AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => _GraphitePlacementProgressRail(
          snapshot: widget.controller.activePlacement,
          touch: widget.touch,
          onCycle: widget.controller.isBusy
              ? null
              : widget.controller.cyclePlacement,
          showPreceptors: _showPreceptors,
          onTogglePreceptors: () =>
              setState(() => _showPreceptors = !_showPreceptors),
        ),
      );
    }
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => PlacementProgressPanel(
        key: const Key('placement-progress-rail'),
        snapshot: widget.controller.activePlacement,
        touch: widget.touch,
        onCycle: widget.controller.isBusy
            ? null
            : widget.controller.cyclePlacement,
      ),
    );
  }
}

/// Production progress panel shared by the live controller rail and
/// deterministic visual proofs.
final class PlacementProgressPanel extends StatefulWidget {
  const PlacementProgressPanel({
    required this.snapshot,
    required this.onCycle,
    this.touch = false,
    super.key,
  });

  final PlacementSnapshot? snapshot;
  final VoidCallback? onCycle;
  final bool touch;

  @override
  State<PlacementProgressPanel> createState() => _PlacementProgressPanelState();
}

final class _PlacementProgressPanelState extends State<PlacementProgressPanel> {
  bool _showPreceptors = false;

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final policy = PlacementProgressPanelPolicy.maybeOf(context);
    final compact = policy?.compactLedger ?? false;
    final conceptActionRail = policy?.conceptActionRail ?? false;
    final sideBySide =
        InsightRailPresentationPolicy.maybeOf(
          context,
        )?.placementProgressLayout ==
        PlacementProgressRailLayout.sideBySide;
    final actionStyle = conceptActionRail
        ? TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.only(left: 34),
          )
        : null;
    return _TacticalPanel(
      label: snapshot?.placement.name ?? 'Clinical Placement',
      statusColor: context.clinicalColors.clinical,
      child: snapshot == null
          ? const _EmptyPlacementState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (sideBySide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PlacementProgressWheel(
                        snapshot: snapshot,
                        touch: widget.touch,
                        onCycle: widget.onCycle,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PlacementMetricLedger(snapshot: snapshot),
                      ),
                    ],
                  )
                else ...[
                  Padding(
                    padding: policy?.wheelPadding ?? EdgeInsets.zero,
                    child: Align(
                      alignment: policy?.wheelAlignment ?? Alignment.center,
                      child: PlacementProgressWheel(
                        snapshot: snapshot,
                        touch: widget.touch,
                        onCycle: widget.onCycle,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 12),
                  PlacementMetricLedger(snapshot: snapshot),
                ],
                SizedBox(height: compact ? 4 : 8),
                TextButton(
                  key: const Key('cycle-placement-action'),
                  onPressed: widget.onCycle,
                  style: actionStyle,
                  child: Transform.translate(
                    offset: conceptActionRail
                        ? const Offset(0, 12)
                        : Offset.zero,
                    child: Text(
                      '${_usesTouchWording(widget.touch) ? 'TAP' : 'CLICK'} '
                      'WHEEL TO VIEW NEXT PLACEMENT',
                      key: const Key('cycle-placement-label'),
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('toggle-preceptor-breakdown'),
                  onPressed: () =>
                      setState(() => _showPreceptors = !_showPreceptors),
                  style: actionStyle,
                  child: Transform.translate(
                    offset: conceptActionRail
                        ? const Offset(0, -6)
                        : Offset.zero,
                    child: Text(
                      '${_showPreceptors ? 'HIDE' : 'SHOW'} '
                      'PRECEPTOR BREAKDOWN',
                      key: const Key('preceptor-breakdown-label'),
                    ),
                  ),
                ),
                if (_showPreceptors) ...[
                  const SizedBox(height: 6),
                  PreceptorProgressBreakdown(snapshot: snapshot),
                ],
              ],
            ),
    );
  }
}

bool _usesTouchWording(bool explicitTouch) =>
    explicitTouch ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

final class PlacementMobileSummary extends StatelessWidget {
  const PlacementMobileSummary({
    required this.controller,
    required this.studentId,
    super.key,
  });

  final PlacementProgressController controller;
  final String studentId;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: const Key('placement-dock-surface'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlacementProgressRail(
          controller: controller,
          studentId: studentId,
          touch: true,
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) => _TacticalPanel(
            key: const Key('mobile-total-progress'),
            label: 'Total progress',
            child: TotalProgressSegments(progress: controller.totalProgress),
          ),
        ),
      ],
    ),
  );
}

final class PlacementMetricLedger extends StatelessWidget {
  const PlacementMetricLedger({required this.snapshot, super.key});

  final PlacementSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final progress = snapshot.progress;
    final policy = PlacementProgressPanelPolicy.maybeOf(context);
    final compact = policy?.compactLedger ?? false;
    final emphasizeProjection = policy?.emphasizeProjection ?? false;
    final metrics = <(String, int, Color?)>[
      ('Target', progress.targetMinutes, null),
      ('Completed', progress.completedMinutes, _completedColor(context)),
      (
        'Scheduled',
        progress.scheduledMinutes,
        context.clinicalColors.scheduled,
      ),
      ('Unscheduled', progress.unscheduledMinutes, _unscheduledColor(context)),
      ('Over-Target', progress.overTargetMinutes, _overTargetColor(context)),
    ];
    final instrument = GraphiteInstrumentScope.isActive(context);
    final icons = <IconData>[
      Icons.gps_fixed,
      Icons.check_circle_outline,
      Icons.schedule_outlined,
      Icons.radio_button_unchecked,
      Icons.keyboard_double_arrow_up,
    ];
    return Column(
      key: const Key('placement-metric-ledger'),
      children: [
        for (final (index, metric) in metrics.indexed)
          Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 0 : 3),
            child: Row(
              children: [
                if (instrument)
                  Icon(
                    icons[index],
                    size: 18,
                    color: metric.$3 ?? context.clinicalColors.secondaryText,
                  )
                else if (metric.$3 case final color?)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(width: 8, height: 8),
                const SizedBox(width: 8),
                Expanded(child: Text(metric.$1)),
                Text(
                  _minutes(metric.$2),
                  style: const TextStyle(
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        Divider(height: compact ? 12 : 18),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _projectionText(progress),
            key: const Key('placement-projection'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: emphasizeProjection
                  ? context.clinicalColors.primaryText
                  : null,
              fontSize: emphasizeProjection ? 11 : null,
              fontWeight: emphasizeProjection ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }
}

final class PreceptorProgressBreakdown extends StatelessWidget {
  const PreceptorProgressBreakdown({required this.snapshot, super.key});

  final PlacementSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      for (final attached in snapshot.attachedPreceptors)
        _PreceptorProgressRow(
          name: attached.preceptor.name,
          primary: attached.isPrimary,
          progress:
              snapshot.progress.preceptorProgress[attached.preceptor.id] ??
              const PreceptorProgress(
                completedMinutes: 0,
                scheduledMinutes: 0,
                awaitingConfirmationMinutes: 0,
                historicalMinutes: 0,
              ),
        ),
    ];
    final unattributed = snapshot.progress.unattributedProgress;
    if (unattributed.completedMinutes > 0 ||
        unattributed.scheduledMinutes > 0 ||
        unattributed.historicalMinutes > 0) {
      rows.add(
        _PreceptorProgressRow(
          name: 'Unattributed Historical Hours',
          primary: false,
          progress: unattributed,
        ),
      );
    }
    return Column(
      key: const Key('preceptor-progress-breakdown'),
      children: rows,
    );
  }
}

final class TotalProgressSegments extends StatelessWidget {
  const TotalProgressSegments({
    required this.progress,
    this.compact = false,
    super.key,
  });

  final TotalProgress progress;
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Total Progress, ${_minutes(progress.completedMinutes)} of '
        '${_minutes(progress.targetMinutes)} completed, '
        '${progress.completedPercentage} percent',
    child: Column(
      key: const Key('total-progress-segments'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!compact)
          Text(
            '${_minutes(progress.completedMinutes)} / '
            '${_minutes(progress.targetMinutes)} completed '
            '(${progress.completedPercentage}%)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        if (!compact) const SizedBox(height: 8),
        Row(
          children: [
            for (
              var index = 0;
              index < TotalProgress.segmentCount;
              index++
            ) ...[
              Expanded(
                child: _ProgressSegment(
                  key: Key('total-progress-segment-$index'),
                  fill: progress.segmentFillPercentages[index],
                ),
              ),
              if (index < TotalProgress.segmentCount - 1)
                const SizedBox(width: 3),
            ],
          ],
        ),
      ],
    ),
  );
}

final class _PlacementDockRow extends StatelessWidget {
  const _PlacementDockRow({
    required this.snapshot,
    required this.selected,
    required this.onPressed,
  });

  final PlacementSnapshot snapshot;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final progress = snapshot.progress;
    final percent = progress.targetMinutes == 0
        ? 0
        : (progress.completedMinutes * 100 / progress.targetMinutes)
              .round()
              .clamp(0, 100);
    return Semantics(
      selected: selected,
      child: Material(
        color: selected
            ? context.clinicalColors.structureRaised
            : context.clinicalColors.structure,
        child: InkWell(
          key: Key('placement-dock-${snapshot.placement.id}'),
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 92),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected
                    ? context.clinicalColors.clinical
                    : context.clinicalColors.insetBorder,
              ),
              borderRadius: BorderRadius.circular(
                context.clinicalMetrics.cornerRadius,
              ),
            ),
            padding: const EdgeInsets.all(9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlacementSpecialtyGlyph(
                  placementName: snapshot.placement.name,
                  color: selected
                      ? context.clinicalColors.clinical
                      : context.clinicalColors.secondaryText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        snapshot.placement.name,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_minutes(progress.completedMinutes)} / '
                        '${_minutes(progress.targetMinutes)} completed '
                        '($percent%)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${_minutes(progress.scheduledMinutes)} scheduled · '
                        '${_minutes(progress.unscheduledMinutes)} unscheduled',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: percent / 100,
                        minHeight: 3,
                        backgroundColor: context.clinicalColors.insetBorder,
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
  }
}

final class _GraphitePlacementDock extends StatelessWidget {
  const _GraphitePlacementDock({required this.controller, this.onManage});

  final PlacementProgressController controller;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'MY PLACEMENTS',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            key: const Key('manage-placements-action'),
            tooltip: 'Manage Clinical Placements',
            onPressed: onManage,
            icon: const Icon(Icons.settings_outlined, size: 18),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (controller.placements.isEmpty)
        const _EmptyPlacementState()
      else
        Expanded(
          child: ListView.separated(
            key: const Key('placement-dock-list'),
            itemCount: controller.placements.length,
            separatorBuilder: (_, _) => const SizedBox(height: 18),
            itemBuilder: (context, index) {
              final snapshot = controller.placements[index];
              return _GraphitePlacementCard(
                snapshot: snapshot,
                accent: index.isEven
                    ? Theme.of(context).colorScheme.primary
                    : context.clinicalColors.workMachinery,
                selected: snapshot.placement.id == controller.activePlacementId,
                onPressed: controller.isBusy
                    ? null
                    : () => controller.selectPlacement(snapshot.placement.id),
              );
            },
          ),
        ),
    ],
  );
}

final class _GraphitePlacementCard extends StatelessWidget {
  const _GraphitePlacementCard({
    required this.snapshot,
    required this.accent,
    required this.selected,
    required this.onPressed,
  });

  final PlacementSnapshot snapshot;
  final Color accent;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final progress = snapshot.progress;
    final fraction = progress.targetMinutes <= 0
        ? 0.0
        : (progress.completedMinutes / progress.targetMinutes).clamp(0.0, 1.0);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        key: const Key('graphite-live-placement-card'),
        color: context.clinicalColors.structureRaised,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: context.clinicalColors.insetBorder),
          borderRadius: BorderRadius.circular(7),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('placement-dock-${snapshot.placement.id}'),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 238),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ColoredBox(color: accent, child: const SizedBox(width: 4)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 15, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            snapshot.placement.name.toUpperCase(),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${_minutes(progress.completedMinutes)} / '
                            '${_minutes(progress.targetMinutes)} completed',
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: SizedBox.square(
                              key: const Key('graphite-live-placement-wheel'),
                              dimension: 104,
                              child: CustomPaint(
                                painter: _GraphiteDockWheelPainter(
                                  progress: fraction,
                                  accent: accent,
                                ),
                                child: Center(
                                  child: Text(
                                    '${(fraction * 100).round()}%',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Column(
                            key: const Key(
                              'graphite-live-placement-dependencies',
                            ),
                            children: [
                              _GraphiteDependencyRow(
                                icon: Icons.schedule_outlined,
                                label:
                                    '${_minutes(progress.scheduledMinutes)} scheduled',
                              ),
                              const SizedBox(height: 5),
                              _GraphiteDependencyRow(
                                label:
                                    '${_minutes(progress.unscheduledMinutes)} unscheduled',
                                accent: accent,
                                dashed: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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

final class _GraphiteDependencyRow extends StatelessWidget {
  const _GraphiteDependencyRow({
    required this.label,
    this.icon,
    this.accent,
    this.dashed = false,
  });

  final String label;
  final IconData? icon;
  final Color? accent;
  final bool dashed;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox.square(
        dimension: 20,
        child: dashed
            ? CustomPaint(
                painter: _GraphiteDashedRingPainter(
                  color: accent ?? context.clinicalColors.secondaryText,
                ),
              )
            : Icon(icon, size: 19, color: context.clinicalColors.secondaryText),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(label)),
    ],
  );
}

final class _GraphitePlacementProgressRail extends StatelessWidget {
  const _GraphitePlacementProgressRail({
    required this.snapshot,
    required this.touch,
    required this.onCycle,
    required this.showPreceptors,
    required this.onTogglePreceptors,
  });

  final PlacementSnapshot? snapshot;
  final bool touch;
  final VoidCallback? onCycle;
  final bool showPreceptors;
  final VoidCallback onTogglePreceptors;

  @override
  Widget build(BuildContext context) {
    final current = snapshot;
    if (current == null) return const _EmptyPlacementState();
    return Column(
      key: const Key('placement-progress-rail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: context.clinicalColors.workMachinery,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                current.placement.name.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          child: PlacementProgressWheel(
            snapshot: current,
            touch: touch,
            diameter: 136,
            onCycle: onCycle,
          ),
        ),
        const SizedBox(height: 10),
        PlacementMetricLedger(snapshot: current),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('cycle-placement-action'),
          onPressed: onCycle,
          child: Text(
            '${_usesTouchWording(touch) ? 'TAP' : 'CLICK'} WHEEL TO VIEW NEXT PLACEMENT',
          ),
        ),
        TextButton(
          key: const Key('toggle-preceptor-breakdown'),
          onPressed: onTogglePreceptors,
          child: Text(
            '${showPreceptors ? 'HIDE' : 'SHOW'} PRECEPTOR BREAKDOWN',
          ),
        ),
        if (showPreceptors) PreceptorProgressBreakdown(snapshot: current),
      ],
    );
  }
}

final class _PreceptorProgressRow extends StatelessWidget {
  const _PreceptorProgressRow({
    required this.name,
    required this.primary,
    required this.progress,
  });

  final String name;
  final bool primary;
  final PreceptorProgress progress;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: context.clinicalColors.canvas,
      border: Border.all(color: context.clinicalColors.insetBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            if (primary)
              Text('PRIMARY', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${_minutes(progress.completedMinutes)} completed / '
          '${_minutes(progress.scheduledMinutes)} scheduled',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (progress.awaitingConfirmationMinutes > 0)
          Text(
            '${_minutes(progress.awaitingConfirmationMinutes)} awaiting confirmation',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    ),
  );
}

final class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({required this.fill, super.key});
  final double fill;

  @override
  Widget build(BuildContext context) => Container(
    height: 6,
    decoration: BoxDecoration(
      color: context.clinicalColors.insetBorder,
      border: Border.all(color: context.clinicalColors.insetBorder),
    ),
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: (fill / 100).clamp(0, 1),
      child: ColoredBox(color: _completedColor(context)),
    ),
  );
}

final class _ProgressWheelPainter extends CustomPainter {
  const _ProgressWheelPainter({
    required this.completedFraction,
    required this.scheduledFraction,
    required this.unscheduledFraction,
    required this.overTargetFraction,
    required this.colors,
    required this.additiveColors,
    this.instrument = false,
  });
  final double completedFraction;
  final double scheduledFraction;
  final double unscheduledFraction;
  final double overTargetFraction;
  final ClinicalCalendarColors colors;
  final ClinicalCalendarAdditiveColors? additiveColors;
  final bool instrument;

  @override
  void paint(Canvas canvas, Size size) {
    if (instrument) {
      _paintInstrumentTicks(canvas, size);
    }
    final stroke = size.shortestSide * .16;
    final rect =
        Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final background = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = instrument ? 2 : stroke
      ..color = colors.insetBorder;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, background);
    var start = -math.pi / 2;
    for (final segment in [
      (
        completedFraction.clamp(0.0, 1.0),
        additiveColors?.completed ?? colors.clinical,
      ),
      (scheduledFraction.clamp(0.0, 1.0), colors.scheduled),
      (
        unscheduledFraction.clamp(0.0, 1.0),
        additiveColors?.unscheduled ?? colors.urgent,
      ),
    ]) {
      if (segment.$1 <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = instrument ? 3 : stroke
        ..strokeCap = StrokeCap.butt
        ..color = segment.$2;
      final sweep = math.pi * 2 * segment.$1;
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
    if (overTargetFraction > 0) {
      final overTargetPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(stroke * .18, 2)
        ..strokeCap = StrokeCap.round
        ..color = additiveColors?.overTarget ?? colors.primaryText;
      canvas.drawArc(
        rect.inflate(stroke * .38),
        -math.pi / 2,
        math.pi * 2 * overTargetFraction.clamp(0.0, 1.0),
        false,
        overTargetPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressWheelPainter oldDelegate) =>
      oldDelegate.completedFraction != completedFraction ||
      oldDelegate.scheduledFraction != scheduledFraction ||
      oldDelegate.unscheduledFraction != unscheduledFraction ||
      oldDelegate.overTargetFraction != overTargetFraction ||
      oldDelegate.colors != colors ||
      oldDelegate.additiveColors != additiveColors ||
      oldDelegate.instrument != instrument;

  void _paintInstrumentTicks(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 4;
    final paint = Paint()
      ..color = colors.secondaryText.withValues(alpha: .8)
      ..strokeWidth = 1;
    for (var index = 0; index < 60; index++) {
      final angle = index * math.pi / 30 - math.pi / 2;
      final outer = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final innerRadius = radius - (index % 5 == 0 ? 6 : 3);
      final inner = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      canvas.drawLine(inner, outer, paint);
    }
  }
}

({double completed, double scheduled, double unscheduled, double overTarget})
_progressWheelFractions(ClinicalPlacementProgress progress) {
  final target = progress.targetMinutes;
  if (target <= 0) {
    return (completed: 0, scheduled: 0, unscheduled: 0, overTarget: 0);
  }
  final completed = math.min(progress.completedMinutes, target) / target;
  final scheduled =
      math.min(
        progress.scheduledMinutes,
        math.max(target - progress.completedMinutes, 0),
      ) /
      target;
  final unscheduled =
      math.min(
        progress.unscheduledMinutes,
        math.max(
          target - progress.completedMinutes - progress.scheduledMinutes,
          0,
        ),
      ) /
      target;
  final overTarget = math.min(progress.overTargetMinutes / target, 1.0);
  return (
    completed: completed,
    scheduled: scheduled,
    unscheduled: unscheduled,
    overTarget: overTarget,
  );
}

final class _GraphiteDockWheelPainter extends CustomPainter {
  const _GraphiteDockWheelPainter({
    required this.progress,
    required this.accent,
  });

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 7;
    for (final ring in <(double, double, Color)>[
      (radius + 4, 1, const Color(0xFF15191C)),
      (radius, 7, const Color(0xFF4A5054)),
      (radius - 5, 1, const Color(0xFF737A7F)),
      (radius - 9, 1, const Color(0xFF252A2E)),
    ]) {
      canvas.drawCircle(
        center,
        ring.$1,
        Paint()
          ..color = ring.$3
          ..style = PaintingStyle.stroke
          ..strokeWidth = ring.$2,
      );
    }
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 1),
      math.pi * 1.05,
      math.pi * .72,
      false,
      Paint()
        ..color = const Color(0xFF8B9296).withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -math.pi * .15,
      math.pi * .7,
      false,
      Paint()
        ..color = const Color(0xFF090B0D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_GraphiteDockWheelPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}

final class _GraphiteDashedRingPainter extends CustomPainter {
  const _GraphiteDashedRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset(2, 2) & Size(size.width - 4, size.height - 4);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 10; index++) {
      canvas.drawArc(rect, index * math.pi / 5, math.pi / 10, false, paint);
    }
  }

  @override
  bool shouldRepaint(_GraphiteDashedRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

Color _completedColor(BuildContext context) =>
    Theme.of(context).extension<ClinicalCalendarAdditiveColors>()?.completed ??
    context.clinicalColors.clinical;

Color _unscheduledColor(BuildContext context) =>
    Theme.of(
      context,
    ).extension<ClinicalCalendarAdditiveColors>()?.unscheduled ??
    context.clinicalColors.urgent;

Color _overTargetColor(BuildContext context) =>
    Theme.of(context).extension<ClinicalCalendarAdditiveColors>()?.overTarget ??
    context.clinicalColors.primaryText;

final class _TacticalPanel extends StatelessWidget {
  const _TacticalPanel({
    required this.label,
    required this.child,
    this.trailing,
    this.statusColor,
    this.expandChild = false,
    this.stackedHeader = false,
    super.key,
  });

  final String label;
  final Widget child;
  final Widget? trailing;
  final Color? statusColor;
  final bool expandChild;
  final bool stackedHeader;

  @override
  Widget build(BuildContext context) {
    final enlargedText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (stackedHeader) ...[
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              softWrap: false,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (trailing != null)
            Align(alignment: Alignment.centerRight, child: trailing),
        ] else
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: enlargedText ? null : 2,
                  overflow: enlargedText ? null : TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (statusColor != null)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor!.withValues(alpha: .45),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ?trailing,
            ],
          ),
        const Divider(height: 14),
        if (expandChild) Expanded(child: child) else child,
      ],
    );
    final adaptiveContent = enlargedText
        ? SingleChildScrollView(child: content)
        : content;
    if (FederationClassicPanelScope.isActive(context)) {
      return FederationClassicPanelHousing(
        label: label,
        accent: statusColor,
        showHeader: false,
        child: adaptiveContent,
      );
    }
    if (VariantFRasterPanelInterior.isActive(context) ||
        EmbeddedPlacementPanelInterior.isActive(context)) {
      return Padding(padding: const EdgeInsets.all(8), child: adaptiveContent);
    }
    return VariantFTacticalFrame(
      accent: statusColor,
      chamfer: 13,
      statusLight: true,
      padding: const EdgeInsets.all(12),
      child: adaptiveContent,
    );
  }
}

final class _EmptyPlacementState extends StatelessWidget {
  const _EmptyPlacementState();

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      'No active Clinical Placement',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );
}

String _projectionText(ClinicalPlacementProgress progress) {
  final date = progress.projectedCompletionDate;
  if (date != null) return 'Projected Completion Date · $date';
  final pace = progress.requiredWeeklyPace;
  if (pace == null) return 'Target reached';
  if (pace.isDeadlinePassed) {
    return 'Completion Deadline passed · ${_minutes(pace.requiredMinutes)} unscheduled';
  }
  return 'Additional pace required · '
      '${_minutes(pace.averageMinutesPerWeek.round())} / week';
}

String _minutes(int minutes) {
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (remainder == 0) return '$hours hr';
  if (hours == 0) return '$remainder min';
  return '$hours hr $remainder min';
}
