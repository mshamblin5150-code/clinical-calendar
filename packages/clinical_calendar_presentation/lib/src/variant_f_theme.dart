import 'package:flutter/material.dart';

/// Stable semantic colors consumed by presentation widgets.
///
/// Workflow widgets should depend on these meanings rather than on Variant F's
/// concrete palette so another visual theme can be supplied without changing
/// scheduling behavior.
@immutable
final class ClinicalCalendarColors
    extends ThemeExtension<ClinicalCalendarColors> {
  const ClinicalCalendarColors({
    required this.canvas,
    required this.structure,
    required this.structureRaised,
    required this.insetBorder,
    required this.primaryText,
    required this.secondaryText,
    required this.clinical,
    required this.work,
    required this.workMachinery,
    required this.protectedDay,
    required this.protectedDayAccent,
    required this.scheduled,
    required this.urgent,
  });

  final Color canvas;
  final Color structure;
  final Color structureRaised;
  final Color insetBorder;
  final Color primaryText;
  final Color secondaryText;
  final Color clinical;
  final Color work;
  final Color workMachinery;
  final Color protectedDay;
  final Color protectedDayAccent;
  final Color scheduled;
  final Color urgent;

  @override
  ClinicalCalendarColors copyWith({
    Color? canvas,
    Color? structure,
    Color? structureRaised,
    Color? insetBorder,
    Color? primaryText,
    Color? secondaryText,
    Color? clinical,
    Color? work,
    Color? workMachinery,
    Color? protectedDay,
    Color? protectedDayAccent,
    Color? scheduled,
    Color? urgent,
  }) => ClinicalCalendarColors(
    canvas: canvas ?? this.canvas,
    structure: structure ?? this.structure,
    structureRaised: structureRaised ?? this.structureRaised,
    insetBorder: insetBorder ?? this.insetBorder,
    primaryText: primaryText ?? this.primaryText,
    secondaryText: secondaryText ?? this.secondaryText,
    clinical: clinical ?? this.clinical,
    work: work ?? this.work,
    workMachinery: workMachinery ?? this.workMachinery,
    protectedDay: protectedDay ?? this.protectedDay,
    protectedDayAccent: protectedDayAccent ?? this.protectedDayAccent,
    scheduled: scheduled ?? this.scheduled,
    urgent: urgent ?? this.urgent,
  );

  @override
  ClinicalCalendarColors lerp(
    covariant ClinicalCalendarColors? other,
    double t,
  ) {
    if (other == null) return this;
    return ClinicalCalendarColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      structure: Color.lerp(structure, other.structure, t)!,
      structureRaised: Color.lerp(structureRaised, other.structureRaised, t)!,
      insetBorder: Color.lerp(insetBorder, other.insetBorder, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      clinical: Color.lerp(clinical, other.clinical, t)!,
      work: Color.lerp(work, other.work, t)!,
      workMachinery: Color.lerp(workMachinery, other.workMachinery, t)!,
      protectedDay: Color.lerp(protectedDay, other.protectedDay, t)!,
      protectedDayAccent: Color.lerp(
        protectedDayAccent,
        other.protectedDayAccent,
        t,
      )!,
      scheduled: Color.lerp(scheduled, other.scheduled, t)!,
      urgent: Color.lerp(urgent, other.urgent, t)!,
    );
  }
}

@immutable
final class ClinicalCalendarMetrics
    extends ThemeExtension<ClinicalCalendarMetrics> {
  const ClinicalCalendarMetrics({
    this.cornerRadius = 3,
    this.borderWidth = 1,
    this.compactSpacing = 8,
    this.standardSpacing = 16,
    this.minimumTouchTarget = 44,
  });

  final double cornerRadius;
  final double borderWidth;
  final double compactSpacing;
  final double standardSpacing;
  final double minimumTouchTarget;

  @override
  ClinicalCalendarMetrics copyWith({
    double? cornerRadius,
    double? borderWidth,
    double? compactSpacing,
    double? standardSpacing,
    double? minimumTouchTarget,
  }) => ClinicalCalendarMetrics(
    cornerRadius: cornerRadius ?? this.cornerRadius,
    borderWidth: borderWidth ?? this.borderWidth,
    compactSpacing: compactSpacing ?? this.compactSpacing,
    standardSpacing: standardSpacing ?? this.standardSpacing,
    minimumTouchTarget: minimumTouchTarget ?? this.minimumTouchTarget,
  );

  @override
  ClinicalCalendarMetrics lerp(
    covariant ClinicalCalendarMetrics? other,
    double t,
  ) {
    if (other == null) return this;
    return ClinicalCalendarMetrics(
      cornerRadius: lerpDouble(cornerRadius, other.cornerRadius, t),
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t),
      compactSpacing: lerpDouble(compactSpacing, other.compactSpacing, t),
      standardSpacing: lerpDouble(standardSpacing, other.standardSpacing, t),
      minimumTouchTarget: lerpDouble(
        minimumTouchTarget,
        other.minimumTouchTarget,
        t,
      ),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

abstract final class VariantFColors {
  static const background = Color(0xFF050B08);
  static const surface = Color(0xFF0B130F);
  static const raisedSurface = Color(0xFF111D16);
  static const border = Color(0xFF405346);
  static const primary = Color(0xFF91C46C);
  static const text = Color(0xFFE8E4D7);
  static const muted = Color(0xFFA7B0A9);
  static const work = Color(0xFF283B3D);
  static const workMachinery = Color(0xFF668A7B);
  static const protectedDay = Color(0xFF252927);
  static const protectedDayAccent = Color(0xFFB7BCB7);
  static const scheduled = Color(0xFFC49B45);
  static const urgent = Color(0xFFD55A52);
  static const control = Color(0xFF121914);
  static const controlActive = Color(0xFF293A20);
  static const controlBorder = Color(0xFF596354);
  static const shadow = Color(0xE6000000);
}

const variantFSemanticColors = ClinicalCalendarColors(
  canvas: VariantFColors.background,
  structure: VariantFColors.surface,
  structureRaised: VariantFColors.raisedSurface,
  insetBorder: VariantFColors.border,
  primaryText: VariantFColors.text,
  secondaryText: VariantFColors.muted,
  clinical: VariantFColors.primary,
  work: VariantFColors.work,
  workMachinery: VariantFColors.workMachinery,
  protectedDay: VariantFColors.protectedDay,
  protectedDayAccent: VariantFColors.protectedDayAccent,
  scheduled: VariantFColors.scheduled,
  urgent: VariantFColors.urgent,
);

ThemeData buildVariantFTheme() {
  const metrics = ClinicalCalendarMetrics();
  const textTheme = TextTheme(
    headlineSmall: TextStyle(
      color: VariantFColors.text,
      fontSize: 21,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    ),
    titleLarge: TextStyle(
      color: VariantFColors.text,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: .7,
    ),
    titleMedium: TextStyle(
      color: VariantFColors.primary,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
    ),
    bodyLarge: TextStyle(color: VariantFColors.text, fontSize: 16, height: 1.4),
    bodyMedium: TextStyle(
      color: VariantFColors.muted,
      fontSize: 14,
      height: 1.4,
    ),
    bodySmall: TextStyle(
      color: VariantFColors.muted,
      fontSize: 12,
      height: 1.35,
    ),
    labelLarge: TextStyle(
      color: VariantFColors.text,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: .5,
    ),
    labelMedium: TextStyle(
      color: VariantFColors.muted,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: .7,
    ),
  );

  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: VariantFColors.background,
    colorScheme: const ColorScheme.dark(
      primary: VariantFColors.primary,
      secondary: VariantFColors.scheduled,
      error: VariantFColors.urgent,
      surface: VariantFColors.surface,
      onPrimary: VariantFColors.background,
      onSurface: VariantFColors.text,
    ),
    textTheme: textTheme,
    dividerColor: VariantFColors.border,
    disabledColor: VariantFColors.muted.withValues(alpha: .45),
    splashFactory: NoSplash.splashFactory,
    extensions: const [variantFSemanticColors, metrics],
    visualDensity: VisualDensity.standard,
    cardTheme: CardThemeData(
      color: VariantFColors.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: VariantFColors.shadow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: VariantFColors.border),
        borderRadius: BorderRadius.circular(metrics.cornerRadius),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: VariantFColors.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: VariantFColors.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: VariantFColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: .9,
      ),
      shape: Border(bottom: BorderSide(color: VariantFColors.border)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: VariantFColors.raisedSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      shadowColor: VariantFColors.shadow,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: VariantFColors.controlBorder),
        borderRadius: BorderRadius.circular(metrics.cornerRadius),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: VariantFColors.surface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: VariantFColors.surface,
      modalBarrierColor: Color(0xB3000000),
      shape: Border(top: BorderSide(color: VariantFColors.controlBorder)),
      showDragHandle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VariantFColors.control,
      labelStyle: const TextStyle(
        color: VariantFColors.muted,
        letterSpacing: .4,
      ),
      helperStyle: const TextStyle(color: VariantFColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(metrics.cornerRadius),
        borderSide: const BorderSide(color: VariantFColors.controlBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(metrics.cornerRadius),
        borderSide: const BorderSide(color: VariantFColors.controlBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(metrics.cornerRadius),
        borderSide: const BorderSide(color: VariantFColors.primary, width: 1.5),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: VariantFColors.muted,
      textColor: VariantFColors.text,
      selectedColor: VariantFColors.primary,
    ),
    iconButtonTheme: const IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(VariantFColors.text),
        minimumSize: WidgetStatePropertyAll(Size.square(44)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: VariantFColors.controlActive,
        foregroundColor: VariantFColors.text,
        disabledBackgroundColor: VariantFColors.control,
        disabledForegroundColor: VariantFColors.muted,
        minimumSize: const Size(44, 44),
        side: const BorderSide(color: VariantFColors.primary),
        elevation: 0,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: .7,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(metrics.cornerRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: VariantFColors.control,
        foregroundColor: VariantFColors.text,
        minimumSize: const Size(44, 44),
        side: const BorderSide(color: VariantFColors.controlBorder),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: .7,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(metrics.cornerRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: VariantFColors.primary,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: .7,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(metrics.cornerRadius),
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? VariantFColors.controlActive
              : VariantFColors.control,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? VariantFColors.primary
              : VariantFColors.text,
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: VariantFColors.controlBorder),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(metrics.cornerRadius),
          ),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700, letterSpacing: .6),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: VariantFColors.control,
      selectedColor: VariantFColors.controlActive,
      disabledColor: VariantFColors.control,
      side: const BorderSide(color: VariantFColors.controlBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(metrics.cornerRadius),
      ),
      labelStyle: const TextStyle(color: VariantFColors.text),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      height: 64,
      backgroundColor: VariantFColors.surface,
      indicatorColor: VariantFColors.controlActive,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          color: VariantFColors.muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: .7,
        ),
      ),
    ),
  );
}

extension ClinicalCalendarThemeContext on BuildContext {
  ClinicalCalendarColors get clinicalColors =>
      Theme.of(this).extension<ClinicalCalendarColors>() ??
      variantFSemanticColors;

  ClinicalCalendarMetrics get clinicalMetrics =>
      Theme.of(this).extension<ClinicalCalendarMetrics>() ??
      const ClinicalCalendarMetrics();
}
