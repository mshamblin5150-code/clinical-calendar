import 'package:flutter/material.dart';

import 'accessibility_tokens.dart';
import 'additive_semantic_colors.dart';
import 'variant_f_theme.dart';

abstract final class CoastalLightColors {
  static const canvas = Color(0xFFEEF5F4);
  static const surface = Color(0xFFFFFCF6);
  static const surfaceRaised = Color(0xFFF4EBDD);
  static const insetBorder = Color(0xFF687E80);
  static const primaryText = Color(0xFF18343C);
  static const secondaryText = Color(0xFF4C6268);
  static const accentPrimary = Color(0xFF1F6F68);
  static const onAccent = Color(0xFFFFFFFF);
  static const control = Color(0xFFE6F1F2);
  static const controlActive = Color(0xFFDDEEEA);
  static const navigationSelected = Color(0xFFA9CDCB);
  static const clinical = Color(0xFF1F6F68);
  static const clinicalFill = Color(0xFFDDEEEA);
  static const work = Color(0xFFDFEBF2);
  static const workMachinery = Color(0xFF2F6584);
  static const protectedDay = Color(0xFFF0E7D5);
  static const protectedDayAccent = Color(0xFF7A653F);
  static const completed = Color(0xFF1F6F68);
  static const scheduled = Color(0xFF805515);
  static const unscheduled = Color(0xFFA13E32);
  static const overTarget = Color(0xFF5A597B);
  static const today = Color(0xFF2F6584);
  static const urgent = Color(0xFFA13E32);
  static const warning = Color(0xFF805515);
  static const focus = Color(0xFFA13E32);
  static const disabled = Color(0xFF6B7777);
}

const coastalLightSemanticColors = ClinicalCalendarColors(
  canvas: CoastalLightColors.canvas,
  structure: CoastalLightColors.surface,
  structureRaised: CoastalLightColors.surfaceRaised,
  insetBorder: CoastalLightColors.insetBorder,
  primaryText: CoastalLightColors.primaryText,
  secondaryText: CoastalLightColors.secondaryText,
  clinical: CoastalLightColors.clinical,
  work: CoastalLightColors.work,
  workMachinery: CoastalLightColors.workMachinery,
  protectedDay: CoastalLightColors.protectedDay,
  protectedDayAccent: CoastalLightColors.protectedDayAccent,
  scheduled: CoastalLightColors.scheduled,
  urgent: CoastalLightColors.urgent,
);

const coastalLightAdditiveColors = ClinicalCalendarAdditiveColors(
  completed: CoastalLightColors.completed,
  unscheduled: CoastalLightColors.unscheduled,
  overTarget: CoastalLightColors.overTarget,
  today: CoastalLightColors.today,
);

const coastalLightEnhancedAdditiveColors = ClinicalCalendarAdditiveColors(
  completed: Color(0xFF185D57),
  unscheduled: Color(0xFF7E281F),
  overTarget: Color(0xFF444362),
  today: Color(0xFF214F6A),
);

const coastalLightEntryVisuals = ClinicalCalendarPresentationPolicy(
  clinicalFill: CoastalLightColors.clinicalFill,
  leadingRailWidth: 4,
  segmentWorkRail: true,
  protectedDotGridCorner: true,
);

const coastalLightStandardAccessibilityTokens =
    ClinicalCalendarAccessibilityTokens(
      enhanced: false,
      focusOuterColor: CoastalLightColors.focus,
      focusInnerColor: CoastalLightColors.surface,
      focusWidth: 3,
      selectionWidth: 2,
      persistentExpandedLegend: false,
      decorationOpacity: 1,
    );

ThemeData buildCoastalLightTheme({bool enhancedAccessibility = false}) {
  const metrics = ClinicalCalendarMetrics(
    cornerRadius: 10,
    compactSpacing: 8,
    standardSpacing: 16,
  );
  const scheme = ColorScheme.light(
    primary: CoastalLightColors.accentPrimary,
    onPrimary: CoastalLightColors.onAccent,
    primaryContainer: CoastalLightColors.controlActive,
    onPrimaryContainer: CoastalLightColors.primaryText,
    secondary: CoastalLightColors.workMachinery,
    onSecondary: CoastalLightColors.onAccent,
    secondaryContainer: Color(0xFFDFEBF2),
    onSecondaryContainer: Color(0xFF1E3848),
    tertiary: CoastalLightColors.workMachinery,
    onTertiary: CoastalLightColors.onAccent,
    tertiaryContainer: CoastalLightColors.protectedDay,
    onTertiaryContainer: Color(0xFF423721),
    error: CoastalLightColors.urgent,
    onError: CoastalLightColors.onAccent,
    errorContainer: Color(0xFFF8E2DE),
    onErrorContainer: Color(0xFF5D211A),
    surface: CoastalLightColors.surface,
    onSurface: CoastalLightColors.primaryText,
    onSurfaceVariant: CoastalLightColors.secondaryText,
    outline: CoastalLightColors.insetBorder,
    outlineVariant: CoastalLightColors.controlActive,
    inverseSurface: CoastalLightColors.primaryText,
    onInverseSurface: CoastalLightColors.surface,
    inversePrimary: Color(0xFF9FD3CC),
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: CoastalLightColors.accentPrimary,
  );
  final base = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: CoastalLightColors.canvas,
    canvasColor: CoastalLightColors.canvas,
    dividerColor: CoastalLightColors.insetBorder,
    disabledColor: CoastalLightColors.disabled,
    extensions: const [
      coastalLightSemanticColors,
      coastalLightAdditiveColors,
      coastalLightEntryVisuals,
      metrics,
      coastalLightStandardAccessibilityTokens,
    ],
  );
  final segmentedShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
    side: const BorderSide(color: CoastalLightColors.insetBorder),
  );
  final standard = base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: CoastalLightColors.primaryText,
      displayColor: CoastalLightColors.primaryText,
    ),
    cardTheme: CardThemeData(
      color: CoastalLightColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: segmentedShape,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: CoastalLightColors.surface,
      foregroundColor: CoastalLightColors.primaryText,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: Border(bottom: BorderSide(color: CoastalLightColors.insetBorder)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: CoastalLightColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: segmentedShape,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CoastalLightColors.control,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: CoastalLightColors.insetBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: CoastalLightColors.focus, width: 3),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            backgroundColor: CoastalLightColors.accentPrimary,
            foregroundColor: CoastalLightColors.onAccent,
            disabledBackgroundColor: CoastalLightColors.surfaceRaised,
            disabledForegroundColor: CoastalLightColors.primaryText,
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
        foregroundColor: CoastalLightColors.primaryText,
        disabledForegroundColor: CoastalLightColors.primaryText,
        minimumSize: const Size(44, 44),
        side: const BorderSide(color: CoastalLightColors.insetBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style:
          TextButton.styleFrom(
            foregroundColor: CoastalLightColors.accentPrimary,
            disabledForegroundColor: CoastalLightColors.primaryText,
          ).copyWith(
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(CoastalLightColors.primaryText),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? CoastalLightColors.onAccent
              : CoastalLightColors.primaryText,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? CoastalLightColors.accentPrimary
              : CoastalLightColors.surface,
        ),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      height: 64,
      backgroundColor: CoastalLightColors.surface,
      indicatorColor: CoastalLightColors.controlActive,
      elevation: 0,
    ),
  );
  if (!enhancedAccessibility) return standard;
  return _applyCoastalLightEnhancedAccessibility(standard);
}

ThemeData _applyCoastalLightEnhancedAccessibility(ThemeData standard) {
  const boundary = Color(0xFF7E281F);
  const enhancedColors = ClinicalCalendarColors(
    canvas: CoastalLightColors.surface,
    structure: CoastalLightColors.surface,
    structureRaised: CoastalLightColors.surfaceRaised,
    insetBorder: Color(0xFF4F6669),
    primaryText: Color(0xFF102A31),
    secondaryText: Color(0xFF3E5359),
    clinical: Color(0xFF185D57),
    work: CoastalLightColors.work,
    workMachinery: Color(0xFF214F6A),
    protectedDay: CoastalLightColors.protectedDay,
    protectedDayAccent: Color(0xFF614E2E),
    scheduled: Color(0xFF68430C),
    urgent: Color(0xFF7E281F),
  );
  return standard.copyWith(
    colorScheme: standard.colorScheme.copyWith(
      primary: const Color(0xFF185D57),
      onPrimary: Colors.white,
      secondary: enhancedColors.workMachinery,
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
      coastalLightEnhancedAdditiveColors,
      coastalLightEntryVisuals,
      ClinicalCalendarMetrics(
        cornerRadius: 10,
        compactSpacing: 8,
        standardSpacing: 16,
      ),
      ClinicalCalendarAccessibilityTokens(
        enhanced: true,
        focusOuterColor: boundary,
        focusInnerColor: Colors.white,
        focusWidth: 3,
        selectionWidth: 3,
        persistentExpandedLegend: true,
        decorationOpacity: 0,
      ),
    ],
  );
}
