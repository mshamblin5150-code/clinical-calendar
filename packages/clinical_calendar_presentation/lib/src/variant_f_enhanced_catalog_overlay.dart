import 'package:flutter/material.dart';

import 'variant_f_theme.dart';

/// Catalog-only accessibility strengthening layered over the frozen Variant F
/// renderer. Standard presentation and the protected theme module remain
/// unchanged.
ThemeData applyVariantFEnhancedCatalogOverlay(ThemeData theme) {
  final enhancedColors = theme.extension<ClinicalCalendarColors>()!;
  return theme.copyWith(
    colorScheme: theme.colorScheme.copyWith(
      errorContainer: const Color(0xFF5A1815),
      onErrorContainer: Colors.white,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: theme.segmentedButtonTheme.style?.copyWith(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Color(0xFF28401F)
              : VariantFColors.control,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : enhancedColors.primaryText,
        ),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (!states.contains(WidgetState.focused) &&
              !states.contains(WidgetState.pressed)) {
            return Colors.transparent;
          }
          return states.contains(WidgetState.selected)
              ? Colors.black.withValues(alpha: .12)
              : Colors.white.withValues(alpha: .12);
        }),
      ),
    ),
  );
}
