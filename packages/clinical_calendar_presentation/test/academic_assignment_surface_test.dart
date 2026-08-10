import 'package:clinical_calendar_application/clinical_calendar_application.dart';
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
        expect(
          find.byKey(const Key('graphite-assignment-control-housing')),
          themeId == graphiteThemeId ? findsOneWidget : findsNothing,
          reason: themeId,
        );
      }

      await tester.pumpWidget(_workspace(variantFThemeId));
      expect(find.byKey(const Key('add-academic-assignment')), findsNothing);

      await tester.pumpWidget(_workspace('unknown-theme'));
      expect(find.byKey(const Key('add-academic-assignment')), findsNothing);
    },
  );

  testWidgets('six real theme shells keep assignment entry usable at 200%', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const additiveThemeIds = [
      graphiteThemeId,
      federationClassicThemeId,
      federation2399ThemeId,
      coastalCalmThemeId,
      botanicalStudyThemeId,
      heritageFieldNotesThemeId,
    ];

    for (final themeId in additiveThemeIds) {
      final bundle = ClinicalCalendarThemeBundleRegistry.standard.resolveRoot(
        themeId,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: bundle.standardPresentation.createThemeData(),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: bundle.shellRenderer.build(
              environmentName: 'TEST',
              onOpenMenu: () {},
              onOpenDestination: (_) {},
              onOpenAttention: () {},
              onAddSchedule: () {},
              slots: ResponsiveShellSlots(
                centralContent: AcademicAssignmentCalendarWorkspace(
                  themeId: themeId,
                  onAddAssignment: () {},
                  calendar: const SizedBox(height: 480),
                ),
                planningRegion: const SizedBox.shrink(),
                placementDock: const SizedBox.shrink(),
                insightRail: const SizedBox.shrink(),
                mobilePlacementSummary: const SizedBox.shrink(),
                mobileAttention: const SizedBox.shrink(),
                profileAvatar: const Icon(Icons.person_outline),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('add-academic-assignment')),
        findsOneWidget,
        reason: themeId,
      );
      expect(tester.takeException(), isNull, reason: themeId);
    }
  });

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
    expect(find.bySemanticsLabel(RegExp('Assignment title')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Class or course')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Due date')), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing assignment exposes status and confirmed delete', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var deleted = false;
    final record = StoredDomainRecord(
      value: AcademicAssignment(
        id: 'assignment-1',
        title: 'Evidence review',
        course: 'NURS 702',
        dueDate: LocalDate(2026, 9, 14),
      ),
      studentId: 'student-1',
      revision: 1,
      createdAtUtc: DateTime.utc(2026, 8, 10),
      updatedAtUtc: DateTime.utc(2026, 8, 10),
    );
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
            record: record,
            onClose: () {},
            onSave:
                ({
                  required title,
                  required course,
                  required dueDate,
                  required status,
                }) async {},
            onDelete: () async => deleted = true,
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel(RegExp('Status')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Delete Assignment')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('delete-academic-assignment')),
    );
    await tester.tap(find.byKey(const Key('delete-academic-assignment')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
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
