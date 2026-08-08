import 'package:flutter/material.dart';

/// Presentation-only accessibility treatment layered over a complete theme.
///
/// This extension intentionally carries no theme identity or layout values.
/// Platform accessibility values remain owned by [MediaQuery].
@immutable
final class ClinicalCalendarAccessibilityTokens
    extends ThemeExtension<ClinicalCalendarAccessibilityTokens> {
  const ClinicalCalendarAccessibilityTokens({
    required this.enhanced,
    required this.focusOuterColor,
    required this.focusInnerColor,
    required this.focusWidth,
    required this.selectionWidth,
    required this.persistentExpandedLegend,
    required this.decorationOpacity,
  });

  final bool enhanced;
  final Color focusOuterColor;
  final Color focusInnerColor;
  final double focusWidth;
  final double selectionWidth;
  final bool persistentExpandedLegend;
  final double decorationOpacity;

  @override
  ClinicalCalendarAccessibilityTokens copyWith({
    bool? enhanced,
    Color? focusOuterColor,
    Color? focusInnerColor,
    double? focusWidth,
    double? selectionWidth,
    bool? persistentExpandedLegend,
    double? decorationOpacity,
  }) => ClinicalCalendarAccessibilityTokens(
    enhanced: enhanced ?? this.enhanced,
    focusOuterColor: focusOuterColor ?? this.focusOuterColor,
    focusInnerColor: focusInnerColor ?? this.focusInnerColor,
    focusWidth: focusWidth ?? this.focusWidth,
    selectionWidth: selectionWidth ?? this.selectionWidth,
    persistentExpandedLegend:
        persistentExpandedLegend ?? this.persistentExpandedLegend,
    decorationOpacity: decorationOpacity ?? this.decorationOpacity,
  );

  @override
  ClinicalCalendarAccessibilityTokens lerp(
    covariant ClinicalCalendarAccessibilityTokens? other,
    double t,
  ) {
    if (other == null) return this;
    return ClinicalCalendarAccessibilityTokens(
      enhanced: t < .5 ? enhanced : other.enhanced,
      focusOuterColor: Color.lerp(focusOuterColor, other.focusOuterColor, t)!,
      focusInnerColor: Color.lerp(focusInnerColor, other.focusInnerColor, t)!,
      focusWidth: _lerpDouble(focusWidth, other.focusWidth, t),
      selectionWidth: _lerpDouble(selectionWidth, other.selectionWidth, t),
      persistentExpandedLegend: t < .5
          ? persistentExpandedLegend
          : other.persistentExpandedLegend,
      decorationOpacity: _lerpDouble(
        decorationOpacity,
        other.decorationOpacity,
        t,
      ),
    );
  }
}

const enhancedAccessibilityTokens = ClinicalCalendarAccessibilityTokens(
  enhanced: true,
  focusOuterColor: Color(0xFFFFFF8A),
  focusInnerColor: Colors.black,
  focusWidth: 3,
  selectionWidth: 3,
  persistentExpandedLegend: true,
  decorationOpacity: .55,
);

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
