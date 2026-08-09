import 'package:flutter/material.dart';

/// Semantic roles required by additive themes beyond the frozen Variant F
/// color extension. Absence preserves the accepted legacy rendering exactly.
@immutable
final class ClinicalCalendarAdditiveColors
    extends ThemeExtension<ClinicalCalendarAdditiveColors> {
  const ClinicalCalendarAdditiveColors({
    required this.completed,
    required this.unscheduled,
    required this.overTarget,
    required this.today,
  });

  final Color completed;
  final Color unscheduled;
  final Color overTarget;
  final Color today;

  @override
  ClinicalCalendarAdditiveColors copyWith({
    Color? completed,
    Color? unscheduled,
    Color? overTarget,
    Color? today,
  }) => ClinicalCalendarAdditiveColors(
    completed: completed ?? this.completed,
    unscheduled: unscheduled ?? this.unscheduled,
    overTarget: overTarget ?? this.overTarget,
    today: today ?? this.today,
  );

  @override
  ClinicalCalendarAdditiveColors lerp(
    covariant ClinicalCalendarAdditiveColors? other,
    double t,
  ) {
    if (other == null) return this;
    return ClinicalCalendarAdditiveColors(
      completed: Color.lerp(completed, other.completed, t)!,
      unscheduled: Color.lerp(unscheduled, other.unscheduled, t)!,
      overTarget: Color.lerp(overTarget, other.overTarget, t)!,
      today: Color.lerp(today, other.today, t)!,
    );
  }
}

/// Optional theme-owned Calendar entry treatment. Its absence preserves the
/// accepted Variant F rendering exactly.
@immutable
final class ClinicalCalendarEntryVisuals
    extends ThemeExtension<ClinicalCalendarEntryVisuals> {
  const ClinicalCalendarEntryVisuals({
    required this.clinicalFill,
    required this.leadingRailWidth,
    required this.segmentWorkRail,
    required this.protectedDotGridCorner,
    this.denseMonthChip = false,
  });

  final Color clinicalFill;
  final double leadingRailWidth;
  final bool segmentWorkRail;
  final bool protectedDotGridCorner;
  final bool denseMonthChip;

  @override
  ClinicalCalendarEntryVisuals copyWith({
    Color? clinicalFill,
    double? leadingRailWidth,
    bool? segmentWorkRail,
    bool? protectedDotGridCorner,
    bool? denseMonthChip,
  }) => ClinicalCalendarEntryVisuals(
    clinicalFill: clinicalFill ?? this.clinicalFill,
    leadingRailWidth: leadingRailWidth ?? this.leadingRailWidth,
    segmentWorkRail: segmentWorkRail ?? this.segmentWorkRail,
    protectedDotGridCorner:
        protectedDotGridCorner ?? this.protectedDotGridCorner,
    denseMonthChip: denseMonthChip ?? this.denseMonthChip,
  );

  @override
  ClinicalCalendarEntryVisuals lerp(
    covariant ClinicalCalendarEntryVisuals? other,
    double t,
  ) {
    if (other == null) return this;
    return ClinicalCalendarEntryVisuals(
      clinicalFill: Color.lerp(clinicalFill, other.clinicalFill, t)!,
      leadingRailWidth:
          leadingRailWidth + (other.leadingRailWidth - leadingRailWidth) * t,
      segmentWorkRail: t < .5 ? segmentWorkRail : other.segmentWorkRail,
      protectedDotGridCorner: t < .5
          ? protectedDotGridCorner
          : other.protectedDotGridCorner,
      denseMonthChip: t < .5 ? denseMonthChip : other.denseMonthChip,
    );
  }
}
