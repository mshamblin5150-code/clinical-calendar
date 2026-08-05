import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Variant F frame clips square corners into a tactical silhouette', () {
    final path = variantFChamferPath(const Size(120, 80), 12);

    expect(path.contains(const Offset(1, 1)), isFalse);
    expect(path.contains(const Offset(60, 40)), isTrue);
    expect(path.contains(const Offset(118, 78)), isFalse);
  });

  testWidgets('Variant F frame renders a raster-backed clipped panel', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVariantFTheme(),
        home: const Scaffold(
          body: VariantFTacticalFrame(
            statusLight: true,
            child: Text('TACTICAL PANEL'),
          ),
        ),
      ),
    );

    expect(find.byType(VariantFNineSliceFrame), findsOneWidget);
    expect(find.byType(ClipRect), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('TACTICAL PANEL'), findsOneWidget);
    expect(buildVariantFTheme().cardTheme.shape, isA<BeveledRectangleBorder>());
  });

  testWidgets('mechanical chassis reserves space for mounted console rails', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVariantFTheme(),
        home: const VariantFMechanicalChassis(
          child: SizedBox(width: 200, height: 300, child: Text('MODULE')),
        ),
      ),
    );

    final chassis = tester.getRect(find.byType(VariantFMechanicalChassis));
    final module = tester.getRect(find.text('MODULE'));
    expect(module.left, greaterThan(chassis.left));
    expect(module.right, lessThan(chassis.right));
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('Variant F mechanical tile atlas renders every reusable part', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVariantFTheme(),
        home: Scaffold(
          body: Wrap(
            children: [
              for (final tile in VariantFMechanicalTile.values)
                SizedBox.square(
                  dimension: 48,
                  child: VariantFMechanicalTileWidget(tile: tile),
                ),
            ],
          ),
        ),
      ),
    );

    expect(
      find.byType(VariantFMechanicalTileWidget),
      findsNWidgets(VariantFMechanicalTile.values.length),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('rendered Variant F raster families decode every atlas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVariantFTheme(),
        home: Scaffold(
          body: Row(
            children: [
              for (final part in VariantFRasterHardware.values)
                SizedBox.square(
                  dimension: 40,
                  child: VariantFRasterHardwareSprite(part: part),
                ),
              for (final part in VariantFRasterRail.values)
                SizedBox.square(
                  dimension: 40,
                  child: VariantFRasterRailSprite(part: part),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byType(VariantFRasterHardwareSprite),
      findsNWidgets(VariantFRasterHardware.values.length),
    );
    expect(
      find.byType(VariantFRasterRailSprite),
      findsNWidgets(VariantFRasterRail.values.length),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('raster panel clips oversized content inside its armor band', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVariantFTheme(),
        home: const Center(
          child: SizedBox.square(
            dimension: 200,
            child: VariantFRasterPanelFrame(
              panel: VariantFRasterPanel.calendar,
              padding: EdgeInsets.all(32),
              child: OverflowBox(
                maxWidth: 400,
                maxHeight: 400,
                child: SizedBox.square(
                  dimension: 400,
                  child: ColoredBox(color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(VariantFRasterPanelInterior),
        matching: find.byType(ClipRect),
      ),
      findsOneWidget,
      reason: 'Raster-panel content has no interior paint boundary.',
    );
  });

  test('raster panels trim transparent atlas margins before scaling', () {
    for (final panel in VariantFRasterPanel.values) {
      final crop = variantFRasterPanelCrop(panel);
      expect(crop, isNot(const Rect.fromLTWH(0, 0, 1, 1)));
      expect(crop.left, inInclusiveRange(0, 1));
      expect(crop.top, inInclusiveRange(0, 1));
      expect(crop.right, inInclusiveRange(0, 1));
      expect(crop.bottom, inInclusiveRange(0, 1));
    }

    expect(
      variantFRasterPanelCrop(VariantFRasterPanel.calendar).right,
      greaterThan(.5),
      reason: 'The calendar sprite crosses the nominal left atlas cell.',
    );
    expect(
      variantFRasterPanelCrop(VariantFRasterPanel.placements).left,
      greaterThan(.6),
      reason: 'The placement crop must exclude the adjacent calendar sprite.',
    );
    expect(
      variantFRasterPanelCrop(VariantFRasterPanel.planning).right,
      greaterThan(.5),
      reason: 'The planning sprite crosses the nominal left atlas cell.',
    );
    expect(
      variantFRasterPanelCrop(VariantFRasterPanel.status).left,
      greaterThan(.6),
      reason: 'The status crop must exclude the adjacent planning sprite.',
    );
  });
}
