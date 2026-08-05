import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/src/calendar/calendar_data_source.dart';
import 'package:clinical_calendar_presentation/src/calendar/calendar_models.dart';
import 'package:clinical_calendar_presentation/src/calendar/calendar_period_view.dart';
import 'package:clinical_calendar_presentation/src/variant_f_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _studentId = '00000000-0000-4000-8000-000000000001';
final _today = LocalDate(2026, 8, 3);

void main() {
  testWidgets('Month, Week, and Agenda navigate their correct periods', (
    tester,
  ) async {
    final source = _MemoryCalendarDataSource(_snapshot());
    await _pumpCalendar(tester, source: source);

    expect(find.text('August 2026'), findsOneWidget);
    await tester.tap(find.byKey(const Key('calendar-next')));
    await tester.pumpAndSettle();
    expect(find.text('September 2026'), findsOneWidget);

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(_visiblePeriodTitle(tester), 'Aug 30 – Sep 5, 2026');
    await tester.tap(find.byKey(const Key('calendar-next')));
    await tester.pumpAndSettle();
    expect(find.text('Sep 6–12, 2026'), findsOneWidget);

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();
    expect(find.text('September 2026'), findsOneWidget);
    await tester.tap(find.byKey(const Key('calendar-previous')));
    await tester.pumpAndSettle();
    expect(find.text('August 2026'), findsOneWidget);
    expect(
      source.requests.map((request) => request.studentId),
      everyElement(_studentId),
    );
  });

  testWidgets(
    'week-start preference changes layout but not Protected Day date',
    (tester) async {
      final source = _MemoryCalendarDataSource(_snapshot());
      await _pumpCalendar(tester, source: source);
      expect(find.byKey(const Key('calendar-day-2026-07-26')), findsOneWidget);
      expect(find.byKey(const Key('calendar-day-2026-08-02')), findsOneWidget);

      await _pumpCalendar(
        tester,
        source: source,
        weekStartsOn: DateTime.monday,
        initialAnchor: LocalDate(2026, 8, 2),
      );
      expect(find.byKey(const Key('calendar-day-2026-07-26')), findsNothing);
      expect(find.byKey(const Key('calendar-day-2026-07-27')), findsOneWidget);
      expect(find.byKey(const Key('calendar-day-2026-08-02')), findsOneWidget);

      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(_visiblePeriodTitle(tester), 'Jul 27 – Aug 2, 2026');
      expect(find.text('Protected Day'), findsWidgets);
    },
  );

  testWidgets(
    'semantics identify Today, assignment, status, and selection action',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpCalendar(
        tester,
        source: _MemoryCalendarDataSource(_snapshot()),
        selectedDates: {_today},
      );

      expect(
        find.bySemanticsLabel(
          RegExp(
            r'Monday, August 3, 2026, Today, Work Shift, 07:00–15:00, '
            r'Scheduled, Selected; tap to deselect',
          ),
        ),
        findsOneWidget,
      );
      semantics.dispose();
      expect(
        find.bySemanticsLabel(
          RegExp(
            r'Clinical Session, Family Medicine · Jordan Lee, 09:00–17:00, '
            r'Awaiting Confirmation, Tap to open Clinical Session',
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'selected occupied date deselects before opening its Work Shift',
    (tester) async {
      final selections = <Set<LocalDate>>[];
      final opened = <CalendarItemReference>[];
      await _pumpCalendar(
        tester,
        source: _MemoryCalendarDataSource(_snapshot()),
        selectedDates: {_today},
        onSelectionChanged: selections.add,
        onOpenItem: opened.add,
      );

      await tester.tap(find.byKey(const Key('calendar-day-2026-08-03')));
      await tester.pump();
      expect(selections.single, isEmpty);
      expect(opened, isEmpty);

      await tester.tap(find.byKey(const Key('calendar-day-2026-08-03')));
      await tester.pump();
      expect(opened.single.kind, CalendarEntryKind.workShift);
      expect(opened.single.id, 'work-03');
    },
  );

  testWidgets(
    'Agenda retains labeled Work Shift and Protected Day treatments',
    (tester) async {
      await _pumpCalendar(
        tester,
        source: _MemoryCalendarDataSource(_snapshot()),
        initialPeriod: CalendarPeriod.agenda,
      );

      final work = tester.widget<Container>(
        find.byKey(const Key('agenda-row-workShift-work-03-2026-08-03')),
      );
      final protected = tester.widget<Container>(
        find.byKey(
          const Key('agenda-row-protectedDay-protected-02-2026-08-02'),
        ),
      );
      final workBorder = (work.decoration! as BoxDecoration).border! as Border;
      final protectedBorder =
          (protected.decoration! as BoxDecoration).border! as Border;
      expect(workBorder.left.color, VariantFColors.workMachinery);
      expect(protectedBorder.left.color, VariantFColors.protectedDayAccent);
      expect(workBorder.left.color, isNot(protectedBorder.left.color));
      expect(find.text('Work Shift'), findsWidgets);
      expect(find.text('Protected Day'), findsWidgets);
    },
  );

  testWidgets('cross-month Week and overnight continuation remain visible', (
    tester,
  ) async {
    await _pumpCalendar(
      tester,
      source: _MemoryCalendarDataSource(_snapshot()),
      initialAnchor: LocalDate(2026, 8, 31),
      initialPeriod: CalendarPeriod.week,
    );

    expect(_visiblePeriodTitle(tester), 'Aug 30 – Sep 5, 2026');
    expect(find.text('22:00–02:00 next day'), findsOneWidget);
    expect(find.text('Continues from 08-31-2026'), findsOneWidget);
    expect(find.byKey(const Key('week-day-2026-09-01')), findsOneWidget);
  });

  testWidgets('dense Month days show bounded cards and an overflow count', (
    tester,
  ) async {
    await _pumpCalendar(
      tester,
      source: _MemoryCalendarDataSource(_snapshot()),
      surfaceSize: const Size(1024, 768),
    );

    expect(find.text('+4 more'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('required responsive matrix renders without overflow', (
    tester,
  ) async {
    const viewports = [
      Size(320, 568),
      Size(390, 844),
      Size(844, 390),
      Size(768, 1024),
      Size(932, 430),
      Size(1024, 768),
      Size(1440, 900),
    ];
    for (final viewport in viewports) {
      await _pumpCalendar(
        tester,
        source: _MemoryCalendarDataSource(_snapshot()),
        surfaceSize: viewport,
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'Calendar overflowed at ${viewport.width}x${viewport.height}',
      );
      expect(find.byKey(const Key('month-view')), findsOneWidget);
    }
  });

  testWidgets('query bounds include six-week Month and cross-month Week', (
    tester,
  ) async {
    final source = _MemoryCalendarDataSource(_snapshot());
    await _pumpCalendar(tester, source: source);
    expect(source.requests.single.firstDate, LocalDate(2026, 7, 26));
    expect(source.requests.single.lastDate, LocalDate(2026, 9, 5));

    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    expect(source.requests.last.firstDate, LocalDate(2026, 8, 2));
    expect(source.requests.last.lastDate, LocalDate(2026, 8, 8));
  });
}

String _visiblePeriodTitle(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('calendar-period-title'))).data!;

Future<void> _pumpCalendar(
  WidgetTester tester, {
  required _MemoryCalendarDataSource source,
  Size surfaceSize = const Size(1024, 768),
  int weekStartsOn = DateTime.sunday,
  CalendarPeriod initialPeriod = CalendarPeriod.month,
  LocalDate? initialAnchor,
  Set<LocalDate> selectedDates = const {},
  ValueChanged<Set<LocalDate>>? onSelectionChanged,
  ValueChanged<CalendarItemReference>? onOpenItem,
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: buildVariantFTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: CalendarPeriodView(
            key: ValueKey('$weekStartsOn-$initialAnchor-$initialPeriod'),
            dataSource: source,
            studentId: _studentId,
            today: _today,
            initialAnchor: initialAnchor ?? LocalDate(2026, 8, 3),
            initialPeriod: initialPeriod,
            weekStartsOn: weekStartsOn,
            initialSelectedDates: selectedDates,
            onSelectionChanged: onSelectionChanged,
            onOpenItem: onOpenItem,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

CalendarSnapshot _snapshot() => CalendarSnapshot([
  CalendarEntry(
    id: 'protected-02',
    kind: CalendarEntryKind.protectedDay,
    startDate: LocalDate(2026, 8, 2),
    endDate: LocalDate(2026, 8, 2),
    title: 'Protected Day',
    statusLabel: 'Protected',
  ),
  CalendarEntry(
    id: 'work-03',
    kind: CalendarEntryKind.workShift,
    startDate: LocalDate(2026, 8, 3),
    endDate: LocalDate(2026, 8, 3),
    startTime: LocalTime(7, 0),
    endTime: LocalTime(15, 0),
    title: 'Work Shift',
    statusLabel: 'Scheduled',
  ),
  CalendarEntry(
    id: 'clinical-06',
    kind: CalendarEntryKind.clinicalSession,
    startDate: LocalDate(2026, 8, 6),
    endDate: LocalDate(2026, 8, 6),
    startTime: LocalTime(9, 0),
    endTime: LocalTime(17, 0),
    title: 'Clinical Session',
    assignment: 'Family Medicine · Jordan Lee',
    statusLabel: 'Awaiting Confirmation',
  ),
  for (var index = 0; index < 5; index++)
    CalendarEntry(
      id: 'dense-$index',
      kind: CalendarEntryKind.clinicalSession,
      startDate: LocalDate(2026, 8, 15),
      endDate: LocalDate(2026, 8, 15),
      startTime: LocalTime(8 + index, 0),
      endTime: LocalTime(9 + index, 0),
      title: 'Clinical Session',
      assignment: 'Family Medicine · Preceptor $index',
      statusLabel: 'Scheduled',
    ),
  CalendarEntry(
    id: 'completed-22',
    kind: CalendarEntryKind.clinicalSession,
    startDate: LocalDate(2026, 8, 22),
    endDate: LocalDate(2026, 8, 22),
    startTime: LocalTime(8, 17),
    endTime: LocalTime(15, 53),
    title: 'Clinical Session',
    assignment: 'Family Medicine · Avery Chen',
    statusLabel: 'Completed',
  ),
  CalendarEntry(
    id: 'overnight-31',
    kind: CalendarEntryKind.workShift,
    startDate: LocalDate(2026, 8, 31),
    endDate: LocalDate(2026, 9, 1),
    startTime: LocalTime(22, 0),
    endTime: LocalTime(2, 0),
    title: 'Work Shift',
    statusLabel: 'Scheduled',
  ),
]);

final class _CalendarLoadRequest {
  const _CalendarLoadRequest({
    required this.studentId,
    required this.firstDate,
    required this.lastDate,
  });

  final String studentId;
  final LocalDate firstDate;
  final LocalDate lastDate;
}

final class _MemoryCalendarDataSource implements CalendarDataSource {
  _MemoryCalendarDataSource(this.snapshot);

  final CalendarSnapshot snapshot;
  final List<_CalendarLoadRequest> requests = [];

  @override
  Future<CalendarSnapshot> load({
    required String studentId,
    required LocalDate firstDate,
    required LocalDate lastDate,
  }) async {
    requests.add(
      _CalendarLoadRequest(
        studentId: studentId,
        firstDate: firstDate,
        lastDate: lastDate,
      ),
    );
    return CalendarSnapshot(
      snapshot.entries.where(
        (entry) =>
            !entry.endDate.isBefore(firstDate) &&
            !entry.startDate.isAfter(lastDate),
      ),
    );
  }
}
