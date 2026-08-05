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

  testWidgets('Variant F frame renders layered clipped panel geometry', (
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

    expect(find.byType(ClipPath), findsOneWidget);
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
}
