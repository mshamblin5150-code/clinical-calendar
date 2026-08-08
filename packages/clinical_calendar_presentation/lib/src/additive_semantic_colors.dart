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
