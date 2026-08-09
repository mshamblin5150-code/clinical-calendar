import 'package:flutter/material.dart';

import 'accessibility_tokens.dart';
import 'additive_semantic_colors.dart';
import 'variant_f_theme.dart';

abstract final class HeritageFieldNotesColors {
  static const canvas = Color(0xFF2A2118);
  static const surface = Color(0xFFF8F1E4);
  static const surfaceRaised = Color(0xFFFFFAF0);
  static const insetBorder = Color(0xFF8A6A35);
  static const primaryText = Color(0xFF1F231D);
  static const secondaryText = Color(0xFF554C3D);
  static const accentPrimary = Color(0xFF0B5C34);
  static const onAccent = Color(0xFFFFFFFF);
  static const control = Color(0xFFF0E5D2);
  static const controlActive = Color(0xFFDCE9DD);
  static const clinical = Color(0xFF0B5C34);
  static const clinicalFill = Color(0xFFDCE9DD);
  static const work = Color(0xFFF3DDE0);
  static const workMachinery = Color(0xFF8B2431);
  static const protectedDay = Color(0xFFF4E6B8);
  static const protectedDayAccent = Color(0xFF9A6B00);
  static const completed = Color(0xFF266440);
  static const scheduled = Color(0xFF315D7A);
  static const unscheduled = Color(0xFF9A6B00);
  static const overTarget = Color(0xFF7B2B22);
  static const today = Color(0xFF006A64);
  static const urgent = Color(0xFFB10F24);
  static const warning = Color(0xFF8A5D00);
  static const focus = Color(0xFF005EA8);
  static const disabled = Color(0xFF766F64);
}

const heritageFieldNotesSemanticColors = ClinicalCalendarColors(
  canvas: HeritageFieldNotesColors.canvas,
  structure: HeritageFieldNotesColors.surface,
  structureRaised: HeritageFieldNotesColors.surfaceRaised,
  insetBorder: HeritageFieldNotesColors.insetBorder,
  primaryText: HeritageFieldNotesColors.primaryText,
  secondaryText: HeritageFieldNotesColors.secondaryText,
  clinical: HeritageFieldNotesColors.clinical,
  work: HeritageFieldNotesColors.work,
  workMachinery: HeritageFieldNotesColors.workMachinery,
  protectedDay: HeritageFieldNotesColors.protectedDay,
  protectedDayAccent: HeritageFieldNotesColors.protectedDayAccent,
  scheduled: HeritageFieldNotesColors.scheduled,
  urgent: HeritageFieldNotesColors.urgent,
);

const heritageFieldNotesAdditiveColors = ClinicalCalendarAdditiveColors(
  completed: HeritageFieldNotesColors.completed,
  unscheduled: HeritageFieldNotesColors.unscheduled,
  overTarget: HeritageFieldNotesColors.overTarget,
  today: HeritageFieldNotesColors.today,
);

const heritageFieldNotesEnhancedAdditiveColors = ClinicalCalendarAdditiveColors(
  completed: Color(0xFF154B2C),
  unscheduled: Color(0xFF704C00),
  overTarget: Color(0xFF641B15),
  today: Color(0xFF004F4B),
);

const heritageFieldNotesEntryVisuals = ClinicalCalendarEntryVisuals(
  clinicalFill: HeritageFieldNotesColors.clinicalFill,
  leadingRailWidth: 4,
  segmentWorkRail: true,
  protectedDotGridCorner: true,
  denseMonthChip: true,
);

const heritageFieldNotesStandardAccessibilityTokens =
    ClinicalCalendarAccessibilityTokens(
      enhanced: false,
      focusOuterColor: HeritageFieldNotesColors.focus,
      focusInnerColor: Colors.black,
      focusWidth: 3,
      selectionWidth: 2,
      persistentExpandedLegend: false,
      decorationOpacity: 1,
    );

const heritageFieldNotesEnhancedAccessibilityTokens =
    ClinicalCalendarAccessibilityTokens(
      enhanced: true,
      focusOuterColor: Color(0xFF064727),
      focusInnerColor: Colors.white,
      focusWidth: 3,
      selectionWidth: 3,
      persistentExpandedLegend: true,
      decorationOpacity: .55,
    );

ThemeData buildHeritageFieldNotesTheme({bool enhancedAccessibility = false}) {
  const metrics = ClinicalCalendarMetrics(
    cornerRadius: 10,
    compactSpacing: 8,
    standardSpacing: 16,
  );
  const scheme = ColorScheme.light(
    primary: HeritageFieldNotesColors.accentPrimary,
    onPrimary: HeritageFieldNotesColors.onAccent,
    primaryContainer: HeritageFieldNotesColors.controlActive,
    onPrimaryContainer: HeritageFieldNotesColors.primaryText,
    secondary: HeritageFieldNotesColors.scheduled,
    onSecondary: HeritageFieldNotesColors.onAccent,
    secondaryContainer: HeritageFieldNotesColors.clinicalFill,
    onSecondaryContainer: HeritageFieldNotesColors.primaryText,
    tertiary: HeritageFieldNotesColors.workMachinery,
    onTertiary: HeritageFieldNotesColors.onAccent,
    tertiaryContainer: HeritageFieldNotesColors.work,
    onTertiaryContainer: HeritageFieldNotesColors.primaryText,
    error: HeritageFieldNotesColors.urgent,
    onError: HeritageFieldNotesColors.onAccent,
    errorContainer: HeritageFieldNotesColors.clinicalFill,
    onErrorContainer: HeritageFieldNotesColors.primaryText,
    surface: HeritageFieldNotesColors.surface,
    onSurface: HeritageFieldNotesColors.primaryText,
    onSurfaceVariant: HeritageFieldNotesColors.secondaryText,
    outline: HeritageFieldNotesColors.insetBorder,
    outlineVariant: HeritageFieldNotesColors.controlActive,
    inverseSurface: HeritageFieldNotesColors.primaryText,
    onInverseSurface: HeritageFieldNotesColors.surfaceRaised,
    inversePrimary: HeritageFieldNotesColors.controlActive,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: HeritageFieldNotesColors.accentPrimary,
  );
  final base = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: HeritageFieldNotesColors.canvas,
    canvasColor: HeritageFieldNotesColors.canvas,
    dividerColor: HeritageFieldNotesColors.insetBorder,
    disabledColor: HeritageFieldNotesColors.disabled,
    extensions: const [
      heritageFieldNotesSemanticColors,
      heritageFieldNotesAdditiveColors,
      heritageFieldNotesEntryVisuals,
      metrics,
      heritageFieldNotesStandardAccessibilityTokens,
    ],
  );
  final segmentedShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
    side: const BorderSide(color: HeritageFieldNotesColors.insetBorder),
  );
  final fieldArchiveTextTheme = base.textTheme
      .copyWith(
        bodySmall: base.textTheme.bodySmall?.copyWith(fontSize: 13),
        labelSmall: base.textTheme.labelSmall?.copyWith(fontSize: 12),
        labelMedium: base.textTheme.labelMedium?.copyWith(fontSize: 14),
        titleSmall: base.textTheme.titleSmall?.copyWith(fontSize: 17),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontSize: 19),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontSize: 24),
      )
      .apply(
        bodyColor: HeritageFieldNotesColors.primaryText,
        displayColor: HeritageFieldNotesColors.primaryText,
      );
  final standard = base.copyWith(
    textTheme: fieldArchiveTextTheme,
    cardTheme: CardThemeData(
      color: HeritageFieldNotesColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: segmentedShape,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: HeritageFieldNotesColors.surface,
      foregroundColor: HeritageFieldNotesColors.primaryText,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: Border(
        bottom: BorderSide(color: HeritageFieldNotesColors.insetBorder),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: HeritageFieldNotesColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: segmentedShape,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HeritageFieldNotesColors.control,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: HeritageFieldNotesColors.insetBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: HeritageFieldNotesColors.focus,
          width: 3,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            backgroundColor: HeritageFieldNotesColors.accentPrimary,
            foregroundColor: HeritageFieldNotesColors.onAccent,
            disabledBackgroundColor: HeritageFieldNotesColors.surfaceRaised,
            disabledForegroundColor: HeritageFieldNotesColors.primaryText,
            minimumSize: const Size(44, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ).copyWith(
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: HeritageFieldNotesColors.primaryText,
        disabledForegroundColor: HeritageFieldNotesColors.primaryText,
        minimumSize: const Size(44, 44),
        side: const BorderSide(color: HeritageFieldNotesColors.insetBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style:
          TextButton.styleFrom(
            foregroundColor: HeritageFieldNotesColors.accentPrimary,
            disabledForegroundColor: HeritageFieldNotesColors.primaryText,
          ).copyWith(
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(
          HeritageFieldNotesColors.primaryText,
        ),
      ),
    ),
    segmentedButtonTheme: const SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(
          HeritageFieldNotesColors.primaryText,
        ),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      height: 64,
      backgroundColor: HeritageFieldNotesColors.surface,
      indicatorColor: HeritageFieldNotesColors.controlActive,
      elevation: 0,
    ),
  );
  if (!enhancedAccessibility) return standard;
  return _applyHeritageFieldNotesEnhancedAccessibility(standard);
}

ThemeData _applyHeritageFieldNotesEnhancedAccessibility(ThemeData standard) {
  const boundary = Color(0xFF005EA8);
  const enhancedColors = ClinicalCalendarColors(
    canvas: HeritageFieldNotesColors.canvas,
    structure: HeritageFieldNotesColors.surface,
    structureRaised: HeritageFieldNotesColors.surfaceRaised,
    insetBorder: Color(0xFF624400),
    primaryText: Color(0xFF11140F),
    secondaryText: Color(0xFF342D23),
    clinical: Color(0xFF064727),
    work: HeritageFieldNotesColors.work,
    workMachinery: Color(0xFF741826),
    protectedDay: HeritageFieldNotesColors.protectedDay,
    protectedDayAccent: Color(0xFF704C00),
    scheduled: Color(0xFF214A65),
    urgent: Color(0xFF8E0016),
  );
  return standard.copyWith(
    colorScheme: standard.colorScheme.copyWith(
      primary: const Color(0xFF064727),
      onPrimary: Colors.white,
      secondary: enhancedColors.scheduled,
      error: enhancedColors.urgent,
      onSurface: enhancedColors.primaryText,
      onSurfaceVariant: enhancedColors.secondaryText,
      outline: enhancedColors.insetBorder,
    ),
    focusColor: boundary,
    dividerColor: enhancedColors.insetBorder,
    textTheme: standard.textTheme.apply(
      bodyColor: enhancedColors.primaryText,
      displayColor: enhancedColors.primaryText,
    ),
    inputDecorationTheme: standard.inputDecorationTheme.copyWith(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: enhancedColors.insetBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: enhancedColors.insetBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: boundary, width: 3),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: standard.filledButtonTheme.style?.copyWith(
        side: WidgetStatePropertyAll(
          BorderSide(color: enhancedColors.insetBorder, width: 1.5),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: standard.outlinedButtonTheme.style?.copyWith(
        side: WidgetStatePropertyAll(
          BorderSide(color: enhancedColors.insetBorder, width: 1.5),
        ),
      ),
    ),
    extensions: const [
      enhancedColors,
      heritageFieldNotesEnhancedAdditiveColors,
      heritageFieldNotesEntryVisuals,
      ClinicalCalendarMetrics(
        cornerRadius: 10,
        compactSpacing: 8,
        standardSpacing: 16,
      ),
      heritageFieldNotesEnhancedAccessibilityTokens,
    ],
  );
}
