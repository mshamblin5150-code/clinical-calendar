import 'package:flutter/material.dart';

import 'accessibility_tokens.dart';
import 'additive_semantic_colors.dart';
import 'variant_f_theme.dart';

abstract final class FederationClassicColors {
  static const canvas = Color(0xFF09070C);
  static const surfaceSunken = Color(0xFF09070C);
  static const surface = Color(0xFF15101C);
  static const surfaceLow = Color(0xFF120D18);
  static const surfaceRaised = Color(0xFF21172B);
  static const surfaceHigh = Color(0xFF2A1D36);
  static const text = Color(0xFFFFF4D6);
  static const textSecondary = Color(0xFFE6C9FF);
  static const muted = Color(0xFF756B7A);
  static const outline = Color(0xFFB88AE8);
  static const outlineVariant = Color(0xFF3B2750);
  static const primary = Color(0xFFF6B44B);
  static const onPrimary = Color(0xFF1A0E06);
  static const primaryContainer = Color(0xFF160F1D);
  static const clinical = Color(0xFFF29A72);
  static const clinicalFill = Color(0xFF44251F);
  static const work = Color(0xFF3B2A4D);
  static const workAccent = Color(0xFFB8A3E0);
  static const protectedDay = Color(0xFF332D38);
  static const protectedDayAccent = Color(0xFFFFE09A);
  static const completed = Color(0xFFA9D47A);
  static const scheduled = Color(0xFFF6B44B);
  // The Classic concept uses the dominant LCARS salmon for work that still
  // needs scheduling and reserves lavender for time beyond the target.
  static const unscheduled = clinical;
  static const overTarget = Color(0xFFB6A8BE);
  static const today = Color(0xFF8DCAE8);
  static const urgent = Color(0xFFFF7777);
  static const warning = Color(0xFFFFD166);
  static const focus = Color(0xFFFFF06A);
}

const federationClassicSemanticColors = ClinicalCalendarColors(
  canvas: FederationClassicColors.canvas,
  structure: FederationClassicColors.surface,
  structureRaised: FederationClassicColors.surfaceRaised,
  insetBorder: FederationClassicColors.outlineVariant,
  primaryText: FederationClassicColors.text,
  secondaryText: FederationClassicColors.textSecondary,
  clinical: FederationClassicColors.clinical,
  work: FederationClassicColors.surface,
  workMachinery: FederationClassicColors.workAccent,
  protectedDay: FederationClassicColors.surface,
  protectedDayAccent: FederationClassicColors.protectedDayAccent,
  scheduled: FederationClassicColors.scheduled,
  urgent: FederationClassicColors.urgent,
);

const federationClassicAdditiveColors = ClinicalCalendarAdditiveColors(
  completed: FederationClassicColors.completed,
  unscheduled: FederationClassicColors.unscheduled,
  overTarget: FederationClassicColors.overTarget,
  today: FederationClassicColors.today,
);

const federationClassicEnhancedAdditiveColors = ClinicalCalendarAdditiveColors(
  completed: Color(0xFFC1E797),
  unscheduled: Color(0xFFFFA07A),
  overTarget: Color(0xFFD4C9DB),
  today: Color(0xFFA9DCF3),
);

const federationClassicStandardAccessibilityTokens =
    ClinicalCalendarAccessibilityTokens(
      enhanced: false,
      focusOuterColor: FederationClassicColors.focus,
      focusInnerColor: Colors.black,
      focusWidth: 3,
      selectionWidth: 1,
      persistentExpandedLegend: false,
      decorationOpacity: 0,
    );

ThemeData buildFederationClassicTheme({bool enhancedAccessibility = false}) {
  const metrics = ClinicalCalendarMetrics(
    cornerRadius: 8,
    compactSpacing: 8,
    standardSpacing: 16,
  );
  const scheme = ColorScheme.dark(
    primary: FederationClassicColors.primary,
    onPrimary: FederationClassicColors.onPrimary,
    primaryContainer: FederationClassicColors.primaryContainer,
    onPrimaryContainer: FederationClassicColors.text,
    secondary: FederationClassicColors.scheduled,
    onSecondary: FederationClassicColors.onPrimary,
    secondaryContainer: FederationClassicColors.clinicalFill,
    onSecondaryContainer: FederationClassicColors.text,
    tertiary: FederationClassicColors.workAccent,
    onTertiary: FederationClassicColors.onPrimary,
    tertiaryContainer: FederationClassicColors.work,
    onTertiaryContainer: FederationClassicColors.text,
    error: FederationClassicColors.urgent,
    onError: FederationClassicColors.onPrimary,
    errorContainer: FederationClassicColors.clinicalFill,
    onErrorContainer: FederationClassicColors.text,
    surface: FederationClassicColors.surface,
    onSurface: FederationClassicColors.text,
    onSurfaceVariant: FederationClassicColors.textSecondary,
    outline: FederationClassicColors.outline,
    outlineVariant: FederationClassicColors.outlineVariant,
    inverseSurface: FederationClassicColors.text,
    onInverseSurface: FederationClassicColors.canvas,
    inversePrimary: FederationClassicColors.primaryContainer,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: FederationClassicColors.primary,
  );
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: FederationClassicColors.canvas,
    canvasColor: FederationClassicColors.canvas,
    dividerColor: FederationClassicColors.outlineVariant,
    disabledColor: FederationClassicColors.muted,
    extensions: const [
      federationClassicSemanticColors,
      federationClassicAdditiveColors,
      metrics,
      federationClassicStandardAccessibilityTokens,
    ],
    visualDensity: VisualDensity.standard,
  );
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: const BorderSide(color: FederationClassicColors.outline),
  );
  final classicTextTheme = base.textTheme
      .copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontSize: 25,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 23,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      )
      .apply(
        bodyColor: FederationClassicColors.text,
        displayColor: FederationClassicColors.text,
      );
  final standard = base.copyWith(
    textTheme: classicTextTheme,
    cardTheme: CardThemeData(
      color: FederationClassicColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: rounded,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: FederationClassicColors.surface,
      foregroundColor: FederationClassicColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: Border(
        bottom: BorderSide(color: FederationClassicColors.outlineVariant),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: FederationClassicColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: rounded,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FederationClassicColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: FederationClassicColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: FederationClassicColors.focus,
          width: 3,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            backgroundColor: FederationClassicColors.primary,
            foregroundColor: FederationClassicColors.onPrimary,
            minimumSize: const Size(44, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ).copyWith(
            foregroundColor: _federationClassicForeground(
              FederationClassicColors.onPrimary,
            ),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? FederationClassicColors.surfaceRaised
                  : FederationClassicColors.primary,
            ),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            foregroundColor: FederationClassicColors.text,
            minimumSize: const Size(44, 44),
            side: const BorderSide(color: FederationClassicColors.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ).copyWith(
            foregroundColor: _federationClassicForeground(
              FederationClassicColors.text,
            ),
          ),
    ),
    textButtonTheme: TextButtonThemeData(
      style:
          TextButton.styleFrom(
            foregroundColor: FederationClassicColors.primary,
          ).copyWith(
            foregroundColor: _federationClassicForeground(
              FederationClassicColors.primary,
            ),
          ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: _federationClassicForeground(
          FederationClassicColors.text,
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? FederationClassicColors.onPrimary
              : FederationClassicColors.textSecondary,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? FederationClassicColors.primary
              : FederationClassicColors.canvas,
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: FederationClassicColors.outline),
        ),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      height: 64,
      backgroundColor: FederationClassicColors.surface,
      indicatorColor: FederationClassicColors.primaryContainer,
      elevation: 0,
    ),
  );
  if (!enhancedAccessibility) return standard;
  return _applyFederationClassicEnhancedAccessibility(standard);
}

WidgetStateProperty<Color?> _federationClassicForeground(Color enabled) =>
    WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? FederationClassicColors.text
          : enabled,
    );

ThemeData _applyFederationClassicEnhancedAccessibility(ThemeData standard) {
  const enhancedBoundary = Color(0xFFFFF27A);
  const enhancedColors = ClinicalCalendarColors(
    canvas: FederationClassicColors.canvas,
    structure: FederationClassicColors.surface,
    structureRaised: FederationClassicColors.surfaceRaised,
    insetBorder: Color(0xFFD9B8FF),
    primaryText: Color(0xFFFFFDF5),
    secondaryText: Color(0xFFF3E8FF),
    clinical: Color(0xFFFFB08D),
    work: FederationClassicColors.work,
    workMachinery: Color(0xFFD4C5FF),
    protectedDay: FederationClassicColors.protectedDay,
    protectedDayAccent: Color(0xFFFFE7AE),
    scheduled: Color(0xFFFFC45F),
    urgent: Color(0xFFFF9292),
  );
  return standard.copyWith(
    colorScheme: standard.colorScheme.copyWith(
      primary: const Color(0xFFFFC45F),
      secondary: enhancedColors.scheduled,
      error: enhancedColors.urgent,
      onSurface: enhancedColors.primaryText,
      onSurfaceVariant: enhancedColors.secondaryText,
      outline: enhancedColors.insetBorder,
    ),
    focusColor: enhancedAccessibilityTokens.focusOuterColor,
    dividerColor: enhancedColors.insetBorder,
    textTheme: standard.textTheme.apply(
      bodyColor: enhancedColors.primaryText,
      displayColor: enhancedColors.primaryText,
    ),
    cardTheme: standard.cardTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: enhancedBoundary, width: 1.5),
      ),
    ),
    appBarTheme: standard.appBarTheme.copyWith(
      shape: const Border(
        bottom: BorderSide(color: enhancedBoundary, width: 1.5),
      ),
    ),
    dialogTheme: standard.dialogTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: enhancedBoundary, width: 1.5),
      ),
    ),
    inputDecorationTheme: standard.inputDecorationTheme.copyWith(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: enhancedBoundary, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: enhancedBoundary, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: enhancedBoundary, width: 3),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: standard.filledButtonTheme.style?.copyWith(
        side: const WidgetStatePropertyAll(
          BorderSide(color: enhancedBoundary, width: 1.5),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: standard.outlinedButtonTheme.style?.copyWith(
        side: const WidgetStatePropertyAll(
          BorderSide(color: enhancedBoundary, width: 1.5),
        ),
      ),
    ),
    extensions: const [
      enhancedColors,
      federationClassicEnhancedAdditiveColors,
      ClinicalCalendarMetrics(
        cornerRadius: 8,
        compactSpacing: 8,
        standardSpacing: 16,
      ),
      enhancedAccessibilityTokens,
    ],
  );
}
