import 'package:clinical_calendar_vertical_slice/data/session_repository.dart';
import 'package:clinical_calendar_vertical_slice/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the responsive week and enforces conflicts', (
    tester,
  ) async {
    final repository = MemorySessionRepository();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(ClinicalCalendarSlice(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('WEEK OF AUGUST 3, 2026'), findsOneWidget);
    expect(find.text('PROTECTED DAY · REST AND PREPARATION'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final saveButton = find.text('SAVE TUE 07:00–19:00');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(find.textContaining('Saved locally'), findsOneWidget);

    final conflictButton = find.text('TRY SAME-TIME CONFLICT');
    await tester.ensureVisible(conflictButton);
    await tester.pumpAndSettle();
    await tester.tap(conflictButton);
    await tester.pumpAndSettle();
    expect(find.textContaining('Rejected: Schedule Conflict'), findsOneWidget);
    expect(await repository.loadAll(), hasLength(1));
  });

  testWidgets('uses the desktop composition without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ClinicalCalendarSlice(repository: MemorySessionRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Row), findsWidgets);
    expect(find.text('VERTICAL-SLICE EVIDENCE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
