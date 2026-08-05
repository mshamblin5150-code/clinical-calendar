import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('clock fields open a dial time picker', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicalTimePickerField(
            label: 'Quiet hours start',
            value: LocalTime(21, 30),
            twelveHour: true,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('9:30 PM'));
    await tester.pumpAndSettle();

    final dialog = tester.widget<TimePickerDialog>(
      find.byType(TimePickerDialog),
    );
    expect(dialog.initialEntryMode, TimePickerEntryMode.dialOnly);
    expect(find.text('Cancel'), findsOneWidget);
  });
}
