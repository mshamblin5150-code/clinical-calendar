import 'package:flutter/material.dart';

import 'accessibility_tokens.dart';
import 'additive_semantic_colors.dart';
import 'variant_f_theme.dart';

abstract final class BotanicalStudyColors {
  static const canvas = Color(0xFFF4EFE6);
  static const housing = Color(0xFFD8DED2);
  static const surfaceSunken = Color(0xFFF8F3EA);
  static const surface = Color(0xFFFFFDF8);
  static const surfaceLow = Color(0xFFF8F3EA);
  static const surfaceRaised = Color(0xFFF1E9E4);
  static const surfaceHigh = Color(0xFFE9D8E3);
  static const text = Color(0xFF33212F);
  static const textSecondary = Color(0xFF655665);
  static const muted = Color(0xFF786F74);
  static const outline = Color(0xFF8A7D72);
  static const outlineVariant = Color(0xFFB5AAA0);
  static const primary = Color(0xFF496B55);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFE1EBDD);
  static const clinical = Color(0xFF496B55);
  static const clinicalFill = Color(0xFFE1EBDD);
  static const work = Color(0xFFF1DFE7);
  static const workAccent = Color(0xFF815165);
  static const protectedDay = Color(0xFFECE8F0);
  static const protectedDayAccent = Color(0xFF655A73);
  static const completed = Color(0xFF496B55);
  static const scheduled = Color(0xFF805B16);
  static const unscheduled = Color(0xFFA63D4E);
  static const overTarget = Color(0xFF5E4776);
  static const today = Color(0xFFA63D4E);
  static const urgent = Color(0xFFA63D4E);
  static const warning = Color(0xFF805B16);
  static const focus = Color(0xFF6B3D67);
  static const selectedSurface = Color(0xFFE9D8E3);
  static const selectedFill = Color(0xFF482944);
}

const botanicalStudySemanticColors = ClinicalCalendarColors(
  canvas: BotanicalStudyColors.canvas,
  structure: BotanicalStudyColors.housing,
  structureRaised: BotanicalStudyColors.surface,
  insetBorder: BotanicalStudyColors.outline,
  primaryText: BotanicalStudyColors.text,
  secondaryText: BotanicalStudyColors.textSecondary,
  clinical: BotanicalStudyColors.clinical,
  work: BotanicalStudyColors.work,
  workMachinery: BotanicalStudyColors.workAccent,
  protectedDay: BotanicalStudyColors.protectedDay,
  protectedDayAccent: BotanicalStudyColors.protectedDayAccent,
  scheduled: BotanicalStudyColors.scheduled,
  urgent: BotanicalStudyColors.urgent,
);

const botanicalStudyAdditiveColors = ClinicalCalendarAdditiveColors(
  completed: BotanicalStudyColors.completed,
  unscheduled: BotanicalStudyColors.unscheduled,
  overTarget: BotanicalStudyColors.overTarget,
  today: BotanicalStudyColors.today,
);

const botanicalStudyEnhancedAdditiveColors = ClinicalCalendarAdditiveColors(
  completed: BotanicalStudyColors.completed,
  unscheduled: BotanicalStudyColors.unscheduled,
  overTarget: BotanicalStudyColors.overTarget,
  today: BotanicalStudyColors.today,
);

const botanicalStudyEntryVisuals = ClinicalCalendarPresentationPolicy(
  clinicalFill: BotanicalStudyColors.clinicalFill,
  leadingRailWidth: 3,
  segmentWorkRail: false,
  protectedDotGridCorner: false,
  denseMarkerStyle: CalendarDenseMarkerStyle.chip,
  toolbarStyle: CalendarToolbarStyle.conceptTitle,
  neutralMonthDayBackgrounds: true,
  showMonthLegend: true,
  colorWeekdayHeader: true,
  monthColumnFlex: CalendarMonthColumnFlex(113, 110, 110, 110, 110, 110, 79),
  selectedDaySurface: BotanicalStudyColors.selectedSurface,
  selectedDayBorder: BotanicalStudyColors.focus,
);

const botanicalStudyEnhancedEntryVisuals = ClinicalCalendarPresentationPolicy(
  clinicalFill: BotanicalStudyColors.clinicalFill,
  leadingRailWidth: 3,
  segmentWorkRail: false,
  protectedDotGridCorner: false,
  denseMarkerStyle: CalendarDenseMarkerStyle.chip,
  toolbarStyle: CalendarToolbarStyle.conceptTitle,
  neutralMonthDayBackgrounds: true,
  showMonthLegend: true,
  colorWeekdayHeader: true,
  monthColumnFlex: CalendarMonthColumnFlex(113, 110, 110, 110, 110, 110, 79),
  selectedDaySurface: BotanicalStudyColors.selectedSurface,
  selectedDayBorder: Color(0xFF4D1F55),
);

const botanicalStudyStandardAccessibilityTokens =
    ClinicalCalendarAccessibilityTokens(
      enhanced: false,
      focusOuterColor: BotanicalStudyColors.focus,
      focusInnerColor: Colors.black,
      focusWidth: 3,
      selectionWidth: 2,
      persistentExpandedLegend: false,
      decorationOpacity: 1,
    );

const botanicalStudyEnhancedAccessibilityTokens =
    ClinicalCalendarAccessibilityTokens(
      enhanced: true,
      focusOuterColor: Color(0xFF4D1F55),
      focusInnerColor: Colors.white,
      focusWidth: 3,
      selectionWidth: 3,
      persistentExpandedLegend: true,
      decorationOpacity: .55,
    );

ThemeData buildBotanicalStudyTheme({bool enhancedAccessibility = false}) {
  const metrics = ClinicalCalendarMetrics(
    cornerRadius: 8,
    compactSpacing: 8,
    standardSpacing: 16,
  );
  const scheme = ColorScheme.light(
    primary: BotanicalStudyColors.primary,
    onPrimary: BotanicalStudyColors.onPrimary,
    primaryContainer: BotanicalStudyColors.primaryContainer,
    onPrimaryContainer: Color(0xFF263529),
    secondary: BotanicalStudyColors.workAccent,
    onSecondary: Colors.white,
    secondaryContainer: BotanicalStudyColors.work,
    onSecondaryContainer: BotanicalStudyColors.text,
    tertiary: BotanicalStudyColors.protectedDayAccent,
    onTertiary: Colors.white,
    tertiaryContainer: BotanicalStudyColors.protectedDay,
    onTertiaryContainer: BotanicalStudyColors.text,
    error: BotanicalStudyColors.urgent,
    onError: Colors.white,
    errorContainer: Color(0xFFF7DDE1),
    onErrorContainer: BotanicalStudyColors.text,
    surface: BotanicalStudyColors.surface,
    onSurface: BotanicalStudyColors.text,
    onSurfaceVariant: BotanicalStudyColors.textSecondary,
    outline: BotanicalStudyColors.outline,
    outlineVariant: BotanicalStudyColors.outlineVariant,
    inverseSurface: BotanicalStudyColors.text,
    onInverseSurface: BotanicalStudyColors.canvas,
    inversePrimary: BotanicalStudyColors.primaryContainer,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: BotanicalStudyColors.primary,
  );
  final base = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: BotanicalStudyColors.canvas,
    canvasColor: BotanicalStudyColors.canvas,
    dividerColor: BotanicalStudyColors.outlineVariant,
    disabledColor: BotanicalStudyColors.muted,
    extensions: const [
      botanicalStudySemanticColors,
      botanicalStudyAdditiveColors,
      botanicalStudyEntryVisuals,
      metrics,
      botanicalStudyStandardAccessibilityTokens,
    ],
    visualDensity: VisualDensity.standard,
  );
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: const BorderSide(color: BotanicalStudyColors.outline),
  );
  final standard = base.copyWith(
    textTheme: base.textTheme
        .apply(
          bodyColor: BotanicalStudyColors.text,
          displayColor: BotanicalStudyColors.text,
        )
        .copyWith(
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            color: BotanicalStudyColors.focus,
            fontSize: 36,
            fontWeight: FontWeight.w500,
          ),
        ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BotanicalStudyColors.selectedFill
              : BotanicalStudyColors.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BotanicalStudyColors.canvas
              : BotanicalStudyColors.text,
        ),
        minimumSize: const WidgetStatePropertyAll(Size(92, 38)),
      ),
    ),
    cardTheme: CardThemeData(
      color: BotanicalStudyColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: rounded,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: BotanicalStudyColors.surface,
      foregroundColor: BotanicalStudyColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: Border(
        bottom: BorderSide(color: BotanicalStudyColors.outlineVariant),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: BotanicalStudyColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      shape: rounded,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: BotanicalStudyColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: BotanicalStudyColors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: BotanicalStudyColors.focus,
          width: 3,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            backgroundColor: BotanicalStudyColors.primary,
            foregroundColor: BotanicalStudyColors.onPrimary,
            minimumSize: const Size(44, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ).copyWith(
            foregroundColor: _botanicalStudyForeground(
              BotanicalStudyColors.onPrimary,
            ),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? BotanicalStudyColors.surfaceRaised
                  : BotanicalStudyColors.primary,
            ),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style:
          OutlinedButton.styleFrom(
            foregroundColor: BotanicalStudyColors.text,
            minimumSize: const Size(44, 44),
            side: const BorderSide(color: BotanicalStudyColors.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ).copyWith(
            foregroundColor: _botanicalStudyForeground(
              BotanicalStudyColors.text,
            ),
          ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: BotanicalStudyColors.primary)
          .copyWith(
            foregroundColor: _botanicalStudyForeground(
              BotanicalStudyColors.primary,
            ),
          ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: _botanicalStudyForeground(BotanicalStudyColors.text),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      height: 64,
      backgroundColor: BotanicalStudyColors.surface,
      indicatorColor: BotanicalStudyColors.primaryContainer,
      elevation: 0,
    ),
  );
  if (!enhancedAccessibility) return standard;
  return _applyBotanicalStudyEnhancedAccessibility(standard);
}

WidgetStateProperty<Color?> _botanicalStudyForeground(Color enabled) =>
    WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled)
          ? BotanicalStudyColors.text
          : enabled,
    );

ThemeData _applyBotanicalStudyEnhancedAccessibility(ThemeData standard) {
  const enhancedBoundary = Color(0xFF5C5048);
  const enhancedColors = ClinicalCalendarColors(
    canvas: BotanicalStudyColors.surface,
    structure: BotanicalStudyColors.housing,
    structureRaised: BotanicalStudyColors.surface,
    insetBorder: Color(0xFF5C5048),
    primaryText: Color(0xFF21131F),
    secondaryText: Color(0xFF514452),
    clinical: BotanicalStudyColors.clinical,
    work: BotanicalStudyColors.work,
    workMachinery: BotanicalStudyColors.workAccent,
    protectedDay: BotanicalStudyColors.protectedDay,
    protectedDayAccent: BotanicalStudyColors.protectedDayAccent,
    scheduled: BotanicalStudyColors.scheduled,
    urgent: BotanicalStudyColors.urgent,
  );
  return standard.copyWith(
    colorScheme: standard.colorScheme.copyWith(
      primary: BotanicalStudyColors.primary,
      secondary: enhancedColors.scheduled,
      error: enhancedColors.urgent,
      onSurface: enhancedColors.primaryText,
      onSurfaceVariant: enhancedColors.secondaryText,
      outline: enhancedColors.insetBorder,
    ),
    focusColor: botanicalStudyEnhancedAccessibilityTokens.focusOuterColor,
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
      botanicalStudyEnhancedAdditiveColors,
      botanicalStudyEnhancedEntryVisuals,
      ClinicalCalendarMetrics(
        cornerRadius: 8,
        compactSpacing: 8,
        standardSpacing: 16,
      ),
      botanicalStudyEnhancedAccessibilityTokens,
    ],
  );
}
