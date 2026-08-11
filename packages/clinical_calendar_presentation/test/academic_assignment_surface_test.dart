import 'dart:ui' as ui;

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/keyboard_focus.dart';

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
        expect(
          find.byKey(const Key('manage-class-catalog')),
          findsOneWidget,
          reason: themeId,
        );
        expect(tester.takeException(), isNull, reason: themeId);
        expect(
          find.byKey(const Key('graphite-assignment-control-housing')),
          themeId == graphiteThemeId ? findsOneWidget : findsNothing,
          reason: themeId,
        );
        expect(
          find.byKey(
            const Key('federation-classic-assignment-control-housing'),
          ),
          themeId == federationClassicThemeId ? findsOneWidget : findsNothing,
          reason: themeId,
        );
        expect(
          find.byKey(const Key('federation-2399-assignment-control-housing')),
          themeId == federation2399ThemeId ? findsOneWidget : findsNothing,
          reason: themeId,
        );
        expect(
          find.byKey(const Key('coastal-light-assignment-control-housing')),
          themeId == coastalCalmThemeId ? findsOneWidget : findsNothing,
          reason: themeId,
        );
        expect(
          find.byKey(const Key('botanical-study-assignment-control-housing')),
          themeId == botanicalStudyThemeId ? findsOneWidget : findsNothing,
          reason: themeId,
        );
        if (themeId == graphiteThemeId) {
          expect(find.byTooltip('Add Academic Assignment'), findsOneWidget);
        }
      }

      await tester.pumpWidget(_workspace(variantFThemeId));
      expect(find.byKey(const Key('add-academic-assignment')), findsNothing);
      expect(find.byKey(const Key('manage-class-catalog')), findsNothing);

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
      if (themeId == federation2399ThemeId) {
        expect(
          find.byKey(const Key('federation-2399-assignment-control-housing')),
          findsOneWidget,
        );
        expect(find.byTooltip('Add Academic Assignment'), findsOneWidget);
      }
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
            catalogEntries: [_catalogRecord('course-1', 'NURS 702')],
            onClose: () {},
            onSave:
                ({
                  required title,
                  required course,
                  required courseId,
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
    await focusWithKeyboard(
      tester,
      find.byKey(const Key('academic-assignment-course')),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.enterText(
      find.byKey(const Key('academic-assignment-due-date')),
      '09-14-2026',
    );
    await focusWithKeyboard(
      tester,
      find.byKey(const Key('save-academic-assignment')),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(saved?.title, 'Evidence review');
    expect(saved?.course, 'NURS 702');
    expect(saved?.dueDate, LocalDate(2026, 9, 14));
    expect(find.bySemanticsLabel(RegExp('Assignment title')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Class or course')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Due date')), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('class catalog surface adds, renames, archives, and restores', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(900, 1440);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var entries = [_catalogRecord('course-1', 'NURS 702')];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGraphiteTheme(enhancedAccessibility: true),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: ClassCatalogManager(
            initialEntries: entries,
            onAdd: (name) async {
              entries = [...entries, _catalogRecord('course-2', name)];
              return entries;
            },
            onRename: (record, name) async {
              entries = [
                for (final entry in entries)
                  if (entry.value.id == record.value.id)
                    _catalogRecord(entry.value.id, name)
                  else
                    entry,
              ];
              return entries;
            },
            onSetArchived: (record, archived) async {
              entries = [
                for (final entry in entries)
                  if (entry.value.id == record.value.id)
                    _catalogRecord(
                      entry.value.id,
                      entry.value.name,
                      archived: archived,
                    )
                  else
                    entry,
              ];
              return entries;
            },
            onClose: () {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('new-class-name')), 'NURS 703');
    final addNode = tester.getSemantics(find.byKey(const Key('add-class')));
    final addData = addNode.getSemanticsData();
    expect(addData.hasAction(ui.SemanticsAction.tap), isTrue);
    expect(addData.flagsCollection.isButton, isTrue);
    tester.platformDispatcher.onSemanticsActionEvent!(
      ui.SemanticsActionEvent(
        type: ui.SemanticsAction.tap,
        viewId: tester.view.viewId,
        nodeId: addNode.id,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('NURS 703'), findsOneWidget);

    await focusWithKeyboard(
      tester,
      find.byKey(const Key('edit-class-course-1')),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('edit-class-name')),
      'NURS 701',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('NURS 701'), findsOneWidget);

    await focusWithKeyboard(
      tester,
      find.byKey(const Key('archive-class-course-1')),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Archived'), findsOneWidget);
    await focusWithKeyboard(
      tester,
      find.byKey(const Key('restore-class-course-1')),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Archived'), findsNothing);
    semantics.dispose();
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
                  required courseId,
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

  testWidgets('missing catalog row keeps a legacy course readable', (
    tester,
  ) async {
    final record = StoredDomainRecord(
      value: AcademicAssignment(
        id: 'assignment-legacy',
        title: 'Evidence review',
        course: 'NURS 702',
        courseId: 'course-not-yet-synchronized',
        dueDate: LocalDate(2026, 9, 14),
      ),
      studentId: 'student-1',
      revision: 1,
      createdAtUtc: DateTime.utc(2026, 8, 11),
      updatedAtUtc: DateTime.utc(2026, 8, 11),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AcademicAssignmentEditor(
            record: record,
            onClose: () {},
            onSave:
                ({
                  required title,
                  required course,
                  required courseId,
                  required dueDate,
                  required status,
                }) async {},
          ),
        ),
      ),
    );

    expect(find.text('NURS 702 (legacy)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

StoredDomainRecord<ClassCatalogEntry> _catalogRecord(
  String id,
  String name, {
  bool archived = false,
}) => StoredDomainRecord(
  value: ClassCatalogEntry(id: id, name: name, isArchived: archived),
  studentId: 'student-1',
  revision: 1,
  createdAtUtc: DateTime.utc(2026, 8, 11),
  updatedAtUtc: DateTime.utc(2026, 8, 11),
);

Widget _workspace(String themeId) => MaterialApp(
  home: Scaffold(
    body: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: AcademicAssignmentCalendarWorkspace(
        themeId: themeId,
        onAddAssignment: () {},
        onManageClasses: () {},
        calendar: const ColoredBox(color: Colors.black),
      ),
    ),
  ),
);
