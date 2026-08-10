import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'six additive themes expose Add Assignment but Variant F does not',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const additiveThemeIds = [
        graphiteThemeId,
        federationClassicThemeId,
        federation2399ThemeId,
        coastalCalmThemeId,
        botanicalStudyThemeId,
        heritageFieldNotesThemeId,
      ];

      for (final themeId in additiveThemeIds) {
        await tester.pumpWidget(_workspace(themeId));
        expect(
          find.byKey(const Key('add-academic-assignment')),
          findsOneWidget,
          reason: themeId,
        );
        expect(tester.takeException(), isNull, reason: themeId);
      }

      await tester.pumpWidget(_workspace(variantFThemeId));
      expect(find.byKey(const Key('add-academic-assignment')), findsNothing);
    },
  );

  testWidgets('editor validates required fields and saves fictional data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ({String title, String course, LocalDate dueDate})? saved;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: AcademicAssignmentEditor(
            onClose: () {},
            onSave:
                ({
                  required title,
                  required course,
                  required dueDate,
                  required status,
                }) async {
                  saved = (title: title, course: course, dueDate: dueDate);
                },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('save-academic-assignment')));
    await tester.pump();
    expect(find.byKey(const Key('academic-assignment-error')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('academic-assignment-title')),
      'Evidence review',
    );
    await tester.enterText(
      find.byKey(const Key('academic-assignment-course')),
      'NURS 702',
    );
    await tester.enterText(
      find.byKey(const Key('academic-assignment-due-date')),
      '09-14-2026',
    );
    await tester.tap(find.byKey(const Key('save-academic-assignment')));
    await tester.pumpAndSettle();

    expect(saved?.title, 'Evidence review');
    expect(saved?.course, 'NURS 702');
    expect(saved?.dueDate, LocalDate(2026, 9, 14));
    expect(tester.takeException(), isNull);
  });
}

Widget _workspace(String themeId) => MaterialApp(
  home: Scaffold(
    body: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: AcademicAssignmentCalendarWorkspace(
        themeId: themeId,
        onAddAssignment: () {},
        calendar: const ColoredBox(color: Colors.black),
      ),
    ),
  ),
);
