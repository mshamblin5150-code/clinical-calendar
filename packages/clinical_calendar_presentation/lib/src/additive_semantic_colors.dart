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

/// Optional theme-owned Calendar presentation policy. Its absence preserves
/// the accepted Variant F rendering exactly.
enum CalendarDenseMarkerStyle { rail, chip }

enum CalendarToolbarStyle { standard, conceptTitle }

@immutable
final class CalendarMonthCellMetrics {
  const CalendarMonthCellMetrics({
    this.weekdayHeaderHeight = 32,
    this.weekdayLabelFontSize,
    this.weekdayLabelFontWeight,
    this.cellPadding = const EdgeInsets.all(5),
    this.markerHeight = 28,
    this.markerHorizontalPadding = 7,
    this.markerIconSize = 16,
    this.markerGap = 7,
    this.markerFontSize = 11,
    this.dayNumberFontSize,
    this.showTodayLabel = false,
    this.gridStrokeWidth = 1,
    this.gridOpacity = 1,
    this.roundedSelection = false,
  });

  final double weekdayHeaderHeight;
  final double? weekdayLabelFontSize;
  final FontWeight? weekdayLabelFontWeight;
  final EdgeInsets cellPadding;
  final double markerHeight;
  final double markerHorizontalPadding;
  final double markerIconSize;
  final double markerGap;
  final double markerFontSize;
  final double? dayNumberFontSize;
  final bool showTodayLabel;
  final double gridStrokeWidth;
  final double gridOpacity;
  final bool roundedSelection;
}

@immutable
final class CalendarMonthColumnFlex {
  const CalendarMonthColumnFlex(
    this.sunday,
    this.monday,
    this.tuesday,
    this.wednesday,
    this.thursday,
    this.friday,
    this.saturday,
  ) : assert(sunday > 0),
      assert(monday > 0),
      assert(tuesday > 0),
      assert(wednesday > 0),
      assert(thursday > 0),
      assert(friday > 0),
      assert(saturday > 0);

  final int sunday;
  final int monday;
  final int tuesday;
  final int wednesday;
  final int thursday;
  final int friday;
  final int saturday;

  List<int> get values => [
    sunday,
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday,
  ];

  int forDisplayColumn({
    required int displayColumn,
    required int weekStartsOn,
  }) {
    RangeError.checkValueInInterval(displayColumn, 0, 6, 'displayColumn');
    RangeError.checkValueInInterval(
      weekStartsOn,
      DateTime.monday,
      DateTime.sunday,
      'weekStartsOn',
    );
    final weekday = (weekStartsOn - 1 + displayColumn) % 7 + 1;
    return switch (weekday) {
      DateTime.monday => monday,
      DateTime.tuesday => tuesday,
      DateTime.wednesday => wednesday,
      DateTime.thursday => thursday,
      DateTime.friday => friday,
      DateTime.saturday => saturday,
      DateTime.sunday => sunday,
      _ => throw StateError('Unreachable weekday: $weekday'),
    };
  }
}

@immutable
final class ClinicalCalendarPresentationPolicy
    extends ThemeExtension<ClinicalCalendarPresentationPolicy> {
  const ClinicalCalendarPresentationPolicy({
    required this.clinicalFill,
    required this.leadingRailWidth,
    required this.segmentWorkRail,
    required this.protectedDotGridCorner,
    this.denseMarkerStyle = CalendarDenseMarkerStyle.rail,
    this.toolbarStyle = CalendarToolbarStyle.standard,
    this.neutralMonthDayBackgrounds = false,
    this.showMonthLegend = false,
    this.colorWeekdayHeader = false,
    this.monthColumnFlex,
    this.selectedDaySurface,
    this.selectedDayBorder,
    this.monthCellMetrics = const CalendarMonthCellMetrics(),
  });

  final Color clinicalFill;
  final double leadingRailWidth;
  final bool segmentWorkRail;
  final bool protectedDotGridCorner;
  final CalendarDenseMarkerStyle denseMarkerStyle;
  final CalendarToolbarStyle toolbarStyle;
  final bool neutralMonthDayBackgrounds;
  final bool showMonthLegend;
  final bool colorWeekdayHeader;
  final CalendarMonthColumnFlex? monthColumnFlex;
  final Color? selectedDaySurface;
  final Color? selectedDayBorder;
  final CalendarMonthCellMetrics monthCellMetrics;

  @override
  ClinicalCalendarPresentationPolicy copyWith({
    Color? clinicalFill,
    double? leadingRailWidth,
    bool? segmentWorkRail,
    bool? protectedDotGridCorner,
    CalendarDenseMarkerStyle? denseMarkerStyle,
    CalendarToolbarStyle? toolbarStyle,
    bool? neutralMonthDayBackgrounds,
    bool? showMonthLegend,
    bool? colorWeekdayHeader,
    CalendarMonthColumnFlex? monthColumnFlex,
    Color? selectedDaySurface,
    Color? selectedDayBorder,
    CalendarMonthCellMetrics? monthCellMetrics,
  }) => ClinicalCalendarPresentationPolicy(
    clinicalFill: clinicalFill ?? this.clinicalFill,
    leadingRailWidth: leadingRailWidth ?? this.leadingRailWidth,
    segmentWorkRail: segmentWorkRail ?? this.segmentWorkRail,
    protectedDotGridCorner:
        protectedDotGridCorner ?? this.protectedDotGridCorner,
    denseMarkerStyle: denseMarkerStyle ?? this.denseMarkerStyle,
    toolbarStyle: toolbarStyle ?? this.toolbarStyle,
    neutralMonthDayBackgrounds:
        neutralMonthDayBackgrounds ?? this.neutralMonthDayBackgrounds,
    showMonthLegend: showMonthLegend ?? this.showMonthLegend,
    colorWeekdayHeader: colorWeekdayHeader ?? this.colorWeekdayHeader,
    monthColumnFlex: monthColumnFlex ?? this.monthColumnFlex,
    selectedDaySurface: selectedDaySurface ?? this.selectedDaySurface,
    selectedDayBorder: selectedDayBorder ?? this.selectedDayBorder,
    monthCellMetrics: monthCellMetrics ?? this.monthCellMetrics,
  );

  @override
  ClinicalCalendarPresentationPolicy lerp(
    covariant ClinicalCalendarPresentationPolicy? other,
    double t,
  ) {
    if (other == null) return this;
    return ClinicalCalendarPresentationPolicy(
      clinicalFill: Color.lerp(clinicalFill, other.clinicalFill, t)!,
      leadingRailWidth:
          leadingRailWidth + (other.leadingRailWidth - leadingRailWidth) * t,
      segmentWorkRail: t < .5 ? segmentWorkRail : other.segmentWorkRail,
      protectedDotGridCorner: t < .5
          ? protectedDotGridCorner
          : other.protectedDotGridCorner,
      denseMarkerStyle: t < .5 ? denseMarkerStyle : other.denseMarkerStyle,
      toolbarStyle: t < .5 ? toolbarStyle : other.toolbarStyle,
      neutralMonthDayBackgrounds: t < .5
          ? neutralMonthDayBackgrounds
          : other.neutralMonthDayBackgrounds,
      showMonthLegend: t < .5 ? showMonthLegend : other.showMonthLegend,
      colorWeekdayHeader: t < .5
          ? colorWeekdayHeader
          : other.colorWeekdayHeader,
      monthColumnFlex: t < .5 ? monthColumnFlex : other.monthColumnFlex,
      selectedDaySurface: Color.lerp(
        selectedDaySurface,
        other.selectedDaySurface,
        t,
      ),
      selectedDayBorder: Color.lerp(
        selectedDayBorder,
        other.selectedDayBorder,
        t,
      ),
      monthCellMetrics: t < .5 ? monthCellMetrics : other.monthCellMetrics,
    );
  }
}
