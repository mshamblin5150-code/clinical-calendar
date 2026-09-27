import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

void main() {
  group('continuous configurable calendar weeks', () {
    test(
      'a Monday-start week remains one identity across a month boundary',
      () {
        final configuration = CalendarWeekConfiguration(
          weekStartsOn: DateTime.monday,
        );

        final april = configuration.weekContaining(LocalDate(2026, 4, 30));
        final may = configuration.weekContaining(LocalDate(2026, 5, 1));

        expect(april, may);
        expect(april.start, LocalDate(2026, 4, 27));
        expect(april.end, LocalDate(2026, 5, 3));
        expect(april.next.start, LocalDate(2026, 5, 4));
      },
    );

    test('every configured weekday creates adjacent seven-day partitions', () {
      final dates = List.generate(
        80,
        (index) => LocalDate(2026, 1, 1).addDays(index),
      );

      for (
        var weekStart = DateTime.monday;
        weekStart <= DateTime.sunday;
        weekStart++
      ) {
        final configuration = CalendarWeekConfiguration(
          weekStartsOn: weekStart,
        );
        for (final date in dates) {
          final week = configuration.weekContaining(date);
          expect(week.contains(date), isTrue);
          expect(week.end, week.start.addDays(6));
          expect(week.next.start, week.start.addDays(7));
        }
      }
    });

    test('rejects values outside the Dart weekday range', () {
      expect(
        () => CalendarWeekConfiguration(weekStartsOn: 0),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        () => CalendarWeekConfiguration(weekStartsOn: 8),
        throwsA(isA<DomainValidationException>()),
      );
    });
  });

  group('monthly Protected Day completeness', () {
    final engine = SchedulingInvariantEngine(
      weekConfiguration: CalendarWeekConfiguration(
        weekStartsOn: DateTime.monday,
      ),
    );

    test('reports every intersecting week lacking a Protected Day', () {
      final protectedDays = [
        ProtectedDay(id: 'previous-month', date: LocalDate(2026, 4, 27)),
        ProtectedDay(id: 'middle', date: LocalDate(2026, 5, 13)),
        ProtectedDay(id: 'next-month', date: LocalDate(2026, 6, 1)),
      ];

      final missing = engine.missingProtectedDayWeeksForMonth(
        year: 2026,
        month: 5,
        protectedDays: protectedDays,
      );

      expect(missing.map((week) => week.start), [
        LocalDate(2026, 5, 4),
        LocalDate(2026, 5, 18),
        LocalDate(2026, 5, 25),
      ]);
    });

    test('one cross-month Protected Day completes the week in both months', () {
      final days = [
        ProtectedDay(id: 'cross-month', date: LocalDate(2026, 5, 1)),
      ];

      final april = engine.missingProtectedDayWeeksForMonth(
        year: 2026,
        month: 4,
        protectedDays: days,
      );
      final may = engine.missingProtectedDayWeeksForMonth(
        year: 2026,
        month: 5,
        protectedDays: days,
      );

      expect(
        april.map((week) => week.start),
        isNot(contains(LocalDate(2026, 4, 27))),
      );
      expect(
        may.map((week) => week.start),
        isNot(contains(LocalDate(2026, 4, 27))),
      );
    });

    test('a flagged Protected Day leaves its week incomplete', () {
      final missing = engine.missingProtectedDayWeeksForMonth(
        year: 2026,
        month: 5,
        protectedDays: [
          ProtectedDay(id: 'protected-1', date: LocalDate(2026, 5, 13)),
        ],
        workShifts: [
          WorkShift.imported(
            id: 'imported-1',
            plannedInterval: ZonedInterval(
              startDate: LocalDate(2026, 5, 13),
              startTime: LocalTime(8, 0),
              endTime: LocalTime(12, 0),
              timeZone: TimeZoneId('America/New_York'),
              startOffset: UtcOffset.inMinutes(-240),
              endOffset: UtcOffset.inMinutes(-240),
            ),
            workScheduleFeedId: 'feed-1',
            workScheduleFeedName: 'ER Schedule',
          ),
        ],
      );

      expect(
        missing.map((week) => week.start),
        contains(LocalDate(2026, 5, 11)),
      );
    });
  });
}
