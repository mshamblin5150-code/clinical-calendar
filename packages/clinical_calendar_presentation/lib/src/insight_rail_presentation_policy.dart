import 'package:flutter/widgets.dart';

enum PlacementProgressRailLayout { vertical, sideBySide }

/// Theme-hosted presentation choices for the shared progress and attention
/// widgets. Defaults preserve the established application layout.
final class InsightRailPresentationPolicy extends InheritedWidget {
  const InsightRailPresentationPolicy({
    this.placementProgressLayout = PlacementProgressRailLayout.vertical,
    this.expandedAttentionRows = false,
    this.outlinedAttentionRows = false,
    required super.child,
    super.key,
  });

  final PlacementProgressRailLayout placementProgressLayout;
  final bool expandedAttentionRows;
  final bool outlinedAttentionRows;

  static InsightRailPresentationPolicy? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<InsightRailPresentationPolicy>();

  @override
  bool updateShouldNotify(InsightRailPresentationPolicy oldWidget) =>
      placementProgressLayout != oldWidget.placementProgressLayout ||
      expandedAttentionRows != oldWidget.expandedAttentionRows ||
      outlinedAttentionRows != oldWidget.outlinedAttentionRows;
}
