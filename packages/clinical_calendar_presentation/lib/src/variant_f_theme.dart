import 'package:flutter/material.dart';

abstract final class VariantFColors {
  static const background = Color(0xFF050B08);
  static const surface = Color(0xFF0B130F);
  static const border = Color(0xFF35483B);
  static const primary = Color(0xFF9AC56B);
  static const text = Color(0xFFE5E8E5);
  static const muted = Color(0xFF9DA59F);
}

ThemeData buildVariantFTheme() => ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: VariantFColors.background,
  colorScheme: const ColorScheme.dark(
    primary: VariantFColors.primary,
    surface: VariantFColors.surface,
    onPrimary: VariantFColors.background,
    onSurface: VariantFColors.text,
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(
      color: VariantFColors.text,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    ),
    titleMedium: TextStyle(
      color: VariantFColors.primary,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
    ),
    bodyMedium: TextStyle(color: VariantFColors.muted, height: 1.4),
  ),
);
