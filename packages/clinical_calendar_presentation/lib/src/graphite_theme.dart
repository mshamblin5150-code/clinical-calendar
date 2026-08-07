import 'package:flutter/material.dart';

import 'variant_f_theme.dart';

abstract final class GraphiteColors {
  static const canvas = Color(0xFF0D1013);
  static const surfaceSunken = Color(0xFF090B0D);
  static const surface = Color(0xFF151A1F);
  static const surfaceLow = Color(0xFF12171B);
  static const surfaceRaised = Color(0xFF1C2329);
  static const surfaceHigh = Color(0xFF222A31);
  static const text = Color(0xFFF4F6F7);
  static const textSecondary = Color(0xFFC2CBD1);
  static const muted = Color(0xFF98A4AD);
  static const outline = Color(0xFF6F7C86);
  static const outlineVariant = Color(0xFF3E4851);
  static const primary = Color(0xFF37D6B4);
  static const onPrimary = Color(0xFF06251E);
  static const primaryContainer = Color(0xFF12483D);
  static const clinical = Color(0xFF70BFFF);
  static const work = Color(0xFF492A61);
  static const workAccent = Color(0xFFCF9DFF);
  static const protectedDay = Color(0xFF4B3B16);
  static const protectedDayAccent = Color(0xFFF2C96D);
  static const scheduled = Color(0xFF72B7FF);
  static const urgent = Color(0xFFFF8D86);
  static const focus = Color(0xFFFFD166);
}

const graphiteSemanticColors = ClinicalCalendarColors(
  canvas: GraphiteColors.canvas,
  structure: GraphiteColors.surface,
  structureRaised: GraphiteColors.surfaceRaised,
  insetBorder: GraphiteColors.outline,
  primaryText: GraphiteColors.text,
  secondaryText: GraphiteColors.textSecondary,
  clinical: GraphiteColors.clinical,
  work: GraphiteColors.work,
  workMachinery: GraphiteColors.workAccent,
  protectedDay: GraphiteColors.protectedDay,
  protectedDayAccent: GraphiteColors.protectedDayAccent,
  scheduled: GraphiteColors.scheduled,
  urgent: GraphiteColors.urgent,
);

ThemeData buildGraphiteTheme() {
  const metrics = ClinicalCalendarMetrics(
    cornerRadius: 8,
    compactSpacing: 8,
    standardSpacing: 16,
  );
  const scheme = ColorScheme.dark(
    primary: GraphiteColors.primary,
    onPrimary: GraphiteColors.onPrimary,
    primaryContainer: GraphiteColors.primaryContainer,
    onPrimaryContainer: Color(0xFFC8FFF2),
    secondary: GraphiteColors.scheduled,
    onSecondary: Color(0xFF08243E),
    secondaryContainer: Color(0xFF173C5D),
    onSecondaryContainer: Color(0xFFDAEBFF),
    tertiary: GraphiteColors.workAccent,
    onTertiary: Color(0xFF27123D),
    tertiaryContainer: Color(0xFF43265D),
    onTertiaryContainer: Color(0xFFF1E3FF),
    error: GraphiteColors.urgent,
    onError: Color(0xFF3B0908),
    errorContainer: Color(0xFF5A2428),
    onErrorContainer: GraphiteColors.text,
    surface: GraphiteColors.surface,
    onSurface: GraphiteColors.text,
    onSurfaceVariant: GraphiteColors.textSecondary,
    outline: GraphiteColors.outline,
    outlineVariant: GraphiteColors.outlineVariant,
    inverseSurface: Color(0xFFE3E8EB),
    onInverseSurface: Color(0xFF172027),
    inversePrimary: Color(0xFF006B57),
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: GraphiteColors.primary,
  );
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: GraphiteColors.canvas,
    canvasColor: GraphiteColors.canvas,
    dividerColor: GraphiteColors.outlineVariant,
    disabledColor: GraphiteColors.muted,
    extensions: const [graphiteSemanticColors, metrics],
    visualDensity: VisualDensity.standard,
  );
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: const BorderSide(color: GraphiteColors.outline),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: GraphiteColors.text,
      displayColor: GraphiteColors.text,
    ),
    cardTheme: CardThemeData(
      color: GraphiteColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: rounded,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: GraphiteColors.surface,
      foregroundColor: GraphiteColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: Border(bottom: BorderSide(color: GraphiteColors.outlineVariant)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: GraphiteColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: rounded,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GraphiteColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: GraphiteColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: GraphiteColors.focus, width: 3),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: GraphiteColors.primary,
        foregroundColor: GraphiteColors.onPrimary,
        minimumSize: const Size(44, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: GraphiteColors.text,
        minimumSize: const Size(44, 44),
        side: const BorderSide(color: GraphiteColors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: GraphiteColors.primary),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      height: 64,
      backgroundColor: GraphiteColors.surface,
      indicatorColor: GraphiteColors.primaryContainer,
      elevation: 0,
    ),
  );
}
