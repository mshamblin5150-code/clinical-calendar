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
}
