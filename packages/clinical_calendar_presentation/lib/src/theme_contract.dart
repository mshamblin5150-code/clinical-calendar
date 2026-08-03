import 'package:flutter/material.dart';

import 'variant_f_theme.dart';

/// A replaceable visual theme. Workflow widgets consume semantic ThemeData and
/// never need to know the theme identifier.
abstract interface class ClinicalCalendarVisualTheme {
  String get id;

  ThemeData createThemeData();
}

final class VariantFVisualTheme implements ClinicalCalendarVisualTheme {
  const VariantFVisualTheme();

  @override
  String get id => 'variant-f';

  @override
  ThemeData createThemeData() => buildVariantFTheme();
}

/// One theme-specific calendar-state explanation used by Help.
@immutable
final class CalendarStateGuide {
  const CalendarStateGuide({
    required this.label,
    required this.description,
    required this.color,
  });

  final String label;
  final String description;
  final Color color;
}

abstract interface class ThemeHelpGuide {
  String get themeId;

  String get title;

  List<CalendarStateGuide> get calendarStates;
}

final class VariantFHelpGuide implements ThemeHelpGuide {
  const VariantFHelpGuide();

  @override
  String get themeId => 'variant-f';

  @override
  String get title => 'Variant F calendar states';

  @override
  List<CalendarStateGuide> get calendarStates => const [
    CalendarStateGuide(
      label: 'Clinical Session',
      description: 'Collective green identifies clinical activity.',
      color: VariantFColors.primary,
    ),
    CalendarStateGuide(
      label: 'Work Shift',
      description: 'Gunmetal and green-steel identify work activity.',
      color: VariantFColors.workMachinery,
    ),
    CalendarStateGuide(
      label: 'Protected Day',
      description: 'Dormant graphite and silver identify protected time.',
      color: VariantFColors.protectedDayAccent,
    ),
    CalendarStateGuide(
      label: 'Scheduled progress',
      description: 'Industrial ochre identifies hours already scheduled.',
      color: VariantFColors.scheduled,
    ),
    CalendarStateGuide(
      label: 'Today or urgent',
      description: 'Optic red is reserved for Today and urgent attention.',
      color: VariantFColors.urgent,
    ),
  ];
}

final class GenericThemeHelpGuide implements ThemeHelpGuide {
  const GenericThemeHelpGuide(this.themeId);

  @override
  final String themeId;

  @override
  String get title => 'Calendar states';

  @override
  List<CalendarStateGuide> get calendarStates => const [
    CalendarStateGuide(
      label: 'Calendar state',
      description: 'Use labels and accessible descriptions to identify items.',
      color: VariantFColors.muted,
    ),
  ];
}

/// Selects only visual-state guidance. Shared workflow Help remains independent.
final class ThemeHelpGuideRegistry {
  ThemeHelpGuideRegistry([Iterable<ThemeHelpGuide> guides = const []])
    : _guides = {for (final guide in guides) guide.themeId: guide};

  factory ThemeHelpGuideRegistry.standard() =>
      ThemeHelpGuideRegistry(const [VariantFHelpGuide()]);

  final Map<String, ThemeHelpGuide> _guides;

  ThemeHelpGuide resolve(String themeId) =>
      _guides[themeId] ?? GenericThemeHelpGuide(themeId);
}
