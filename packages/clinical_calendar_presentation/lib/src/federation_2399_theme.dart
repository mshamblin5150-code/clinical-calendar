import 'package:flutter/material.dart';

import 'accessibility_tokens.dart';
import 'additive_semantic_colors.dart';
import 'variant_f_theme.dart';

abstract final class Federation2399Colors {
  static const canvas = Color(0xFF07080D);
  static const surface = Color(0xFF11131A);
  static const surfaceRaised = Color(0xFF1A1D26);
  static const insetBorder = Color(0xFF9B7A92);
  static const primaryText = Color(0xFFF4F1EB);
  static const secondaryText = Color(0xFFC8C0CC);
  static const accentPrimary = Color(0xFFC893B8);
  static const onAccent = Color(0xFF150F16);
  static const control = Color(0xFF1B1F2A);
  static const controlActive = Color(0xFF332735);
  static const clinical = Color(0xFFC893B8);
  static const clinicalFill = Color(0xFF3A2635);
  static const work = Color(0xFF273443);
  static const workMachinery = Color(0xFFA9C8D8);
  static const protectedDay = Color(0xFF383341);
  static const protectedDayAccent = Color(0xFFD6C9D9);
  static const completed = Color(0xFF95BD99);
  static const scheduled = Color(0xFFD8A65E);
  static const unscheduled = Color(0xFFA9A3AE);
  static const overTarget = Color(0xFFD98298);
  static const today = Color(0xFF89BFD2);
  static const urgent = Color(0xFFEF7D82);
  static const warning = Color(0xFFE4B85E);
  static const focus = Color(0xFFF5D27A);
  static const disabled = Color(0xFF6F6F79);
}

const federation2399SemanticColors = ClinicalCalendarColors(
  canvas: Federation2399Colors.canvas,
  structure: Federation2399Colors.surface,
  structureRaised: Federation2399Colors.surfaceRaised,
  insetBorder: Federation2399Colors.insetBorder,
  primaryText: Federation2399Colors.primaryText,
  secondaryText: Federation2399Colors.secondaryText,
  clinical: Federation2399Colors.clinical,
  work: Federation2399Colors.work,
  workMachinery: Federation2399Colors.workMachinery,
  protectedDay: Federation2399Colors.protectedDay,
  protectedDayAccent: Federation2399Colors.protectedDayAccent,
  scheduled: Federation2399Colors.scheduled,
  urgent: Federation2399Colors.urgent,
);

const federation2399AdditiveColors = ClinicalCalendarAdditiveColors(
  completed: Federation2399Colors.completed,
  unscheduled: Federation2399Colors.unscheduled,
  overTarget: Federation2399Colors.overTarget,
  today: Federation2399Colors.today,
);

const federation2399EnhancedAdditiveColors = ClinicalCalendarAdditiveColors(
  completed: Color(0xFFB1D5B3),
  unscheduled: Color(0xFFD0C9D3),
  overTarget: Color(0xFFF39CB2),
  today: Color(0xFFA8D5E5),
);

const federation2399EntryVisuals = ClinicalCalendarEntryVisuals(
  clinicalFill: Federation2399Colors.clinicalFill,
  leadingRailWidth: 4,
  segmentWorkRail: true,
  protectedDotGridCorner: true,
);

const federation2399StandardAccessibilityTokens =
    ClinicalCalendarAccessibilityTokens(
      enhanced: false,
      focusOuterColor: Federation2399Colors.focus,
      focusInnerColor: Colors.black,
      focusWidth: 3,
      selectionWidth: 2,
      persistentExpandedLegend: false,
      decorationOpacity: 1,
    );

ThemeData buildFederation2399Theme({bool enhancedAccessibility = false}) {
  const metrics = ClinicalCalendarMetrics(
    cornerRadius: 10,
    compactSpacing: 8,
    standardSpacing: 16,
  );
  const scheme = ColorScheme.dark(
    primary: Federation2399Colors.accentPrimary,
    onPrimary: Federation2399Colors.onAccent,
    primaryContainer: Federation2399Colors.controlActive,
    onPrimaryContainer: Federation2399Colors.primaryText,
    secondary: Federation2399Colors.scheduled,
    onSecondary: Federation2399Colors.onAccent,
    secondaryContainer: Federation2399Colors.clinicalFill,
    onSecondaryContainer: Federation2399Colors.primaryText,
    tertiary: Federation2399Colors.workMachinery,
    onTertiary: Federation2399Colors.onAccent,
    tertiaryContainer: Federation2399Colors.work,
    onTertiaryContainer: Federation2399Colors.primaryText,
    error: Federation2399Colors.urgent,
    onError: Federation2399Colors.onAccent,
    errorContainer: Federation2399Colors.clinicalFill,
    onErrorContainer: Federation2399Colors.primaryText,
    surface: Federation2399Colors.surface,
    onSurface: Federation2399Colors.primaryText,
    onSurfaceVariant: Federation2399Colors.secondaryText,
    outline: Federation2399Colors.insetBorder,
    outlineVariant: Federation2399Colors.controlActive,
    inverseSurface: Federation2399Colors.primaryText,
    onInverseSurface: Federation2399Colors.canvas,
    inversePrimary: Federation2399Colors.controlActive,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: Federation2399Colors.accentPrimary,
  );
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Federation2399Colors.canvas,
    canvasColor: Federation2399Colors.canvas,
    dividerColor: Federation2399Colors.insetBorder,
    disabledColor: Federation2399Colors.disabled,
    extensions: const [
      federation2399SemanticColors,
      federation2399AdditiveColors,
      federation2399EntryVisuals,
      metrics,
      federation2399StandardAccessibilityTokens,
    ],
  );
  final segmentedShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
    side: const BorderSide(color: Federation2399Colors.insetBorder),
  );
  final standard = base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: Federation2399Colors.primaryText,
      displayColor: Federation2399Colors.primaryText,
    ),
    cardTheme: CardThemeData(
      color: Federation2399Colors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: segmentedShape,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Federation2399Colors.surface,
      foregroundColor: Federation2399Colors.primaryText,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: Border(
        bottom: BorderSide(color: Federation2399Colors.insetBorder),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Federation2399Colors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: segmentedShape,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Federation2399Colors.control,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Federation2399Colors.insetBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Federation2399Colors.focus,
          width: 3,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            backgroundColor: Federation2399Colors.accentPrimary,
            foregroundColor: Federation2399Colors.onAccent,
            disabledBackgroundColor: Federation2399Colors.surfaceRaised,
            disabledForegroundColor: Federation2399Colors.primaryText,
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
        foregroundColor: Federation2399Colors.primaryText,
        disabledForegroundColor: Federation2399Colors.primaryText,
        minimumSize: const Size(44, 44),
        side: const BorderSide(color: Federation2399Colors.insetBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style:
          TextButton.styleFrom(
            foregroundColor: Federation2399Colors.accentPrimary,
            disabledForegroundColor: Federation2399Colors.primaryText,
          ).copyWith(
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(
          Federation2399Colors.primaryText,
        ),
      ),
    ),
    segmentedButtonTheme: const SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(
          Federation2399Colors.primaryText,
        ),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      height: 64,
      backgroundColor: Federation2399Colors.surface,
      indicatorColor: Federation2399Colors.controlActive,
      elevation: 0,
    ),
  );
  if (!enhancedAccessibility) return standard;
  return _applyFederation2399EnhancedAccessibility(standard);
}

ThemeData _applyFederation2399EnhancedAccessibility(ThemeData standard) {
  const boundary = Color(0xFFFFE28E);
  const enhancedColors = ClinicalCalendarColors(
    canvas: Federation2399Colors.canvas,
    structure: Federation2399Colors.surface,
    structureRaised: Federation2399Colors.surfaceRaised,
    insetBorder: Color(0xFFD6C5D1),
    primaryText: Colors.white,
    secondaryText: Color(0xFFEEE9F0),
    clinical: Color(0xFFE7B3D5),
    work: Federation2399Colors.work,
    workMachinery: Color(0xFFC8E5F0),
    protectedDay: Federation2399Colors.protectedDay,
    protectedDayAccent: Color(0xFFEFE4F2),
    scheduled: Color(0xFFF0BE72),
    urgent: Color(0xFFFF979B),
  );
  return standard.copyWith(
    colorScheme: standard.colorScheme.copyWith(
      primary: const Color(0xFFE7B3D5),
      onPrimary: const Color(0xFF120C12),
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
      federation2399EnhancedAdditiveColors,
      federation2399EntryVisuals,
      ClinicalCalendarMetrics(
        cornerRadius: 10,
        compactSpacing: 8,
        standardSpacing: 16,
      ),
      enhancedAccessibilityTokens,
    ],
  );
}
