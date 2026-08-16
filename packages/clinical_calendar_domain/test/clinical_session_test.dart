import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

void main() {
  group('ClinicalSession lifecycle', () {
    test(
      'derives Scheduled and Awaiting Confirmation from the end instant',
      () {
        final interval = _interval(LocalDate(2026, 8, 3), '0800', '1200');

        final scheduled = _session(interval, DateTime.utc(2026, 8, 3, 15));
        final awaiting = _session(interval, DateTime.utc(2026, 8, 3, 17));

        expect(scheduled.state, ClinicalSessionState.scheduled);
        expect(
          scheduled.refreshStatus(DateTime.utc(2026, 8, 3, 16)).state,
          ClinicalSessionState.awaitingConfirmation,
        );
        expect(awaiting.state, ClinicalSessionState.awaitingConfirmation);
      },
    );

    test('completes only Awaiting Confirmation with exact actual minutes', () {
      final planned = _interval(LocalDate(2026, 8, 3), '0800', '1200');
      final actual = _interval(LocalDate(2026, 8, 3), '0817', '1153');
      final awaiting = _session(planned, DateTime.utc(2026, 8, 3, 17));

      final completed = awaiting.complete(actual);

      expect(completed.state, ClinicalSessionState.completed);
      expect(completed.completedMinutes, 216);
      expect(
        () => _session(planned, DateTime.utc(2026, 8, 3, 15)).complete(actual),
        throwsA(isA<DomainValidationException>()),
      );
    });

    test(
      'permits only date-appropriate cancellation and missed transitions',
      () {
        final interval = _interval(LocalDate(2026, 8, 3), '0800', '1200');
        final scheduled = _session(interval, DateTime.utc(2026, 8, 3, 15));
        final awaiting = _session(interval, DateTime.utc(2026, 8, 3, 17));

        expect(scheduled.cancel().state, ClinicalSessionState.cancelled);
        expect(awaiting.markMissed().state, ClinicalSessionState.missed);
        expect(scheduled.markMissed, throwsA(isA<DomainValidationException>()));
        expect(
          awaiting.markMissed().cancel,
          throwsA(isA<DomainValidationException>()),
        );
      },
    );

    test('moving applies the specified date-driven state rule', () {
      final original = _interval(LocalDate(2026, 8, 1), '0800', '1200');
      final actual = _interval(LocalDate(2026, 8, 1), '0810', '1210');
      final completed = _session(
        original,
        DateTime.utc(2026, 8, 1, 17),
      ).complete(actual);

      final movedToToday = completed.revisePlannedDetails(
        plannedInterval: _interval(LocalDate(2026, 8, 3), '0800', '1200'),
        preceptorId: completed.preceptorId,
        today: LocalDate(2026, 8, 3),
      );
      final movedToPast = movedToToday.revisePlannedDetails(
        plannedInterval: _interval(LocalDate(2026, 8, 2), '0800', '1200'),
        preceptorId: movedToToday.preceptorId,
        today: LocalDate(2026, 8, 3),
      );

      expect(movedToToday.state, ClinicalSessionState.scheduled);
      expect(movedToToday.actualInterval, isNull);
      expect(movedToToday.completedMinutes, 0);
      expect(movedToPast.state, ClinicalSessionState.awaitingConfirmation);
    });

    test('restoration rejects lifecycle data that cannot be valid', () {
      final interval = _interval(LocalDate(2026, 8, 3), '0800', '1200');

      expect(
        () => ClinicalSession.restore(
          id: 'session-1',
          clinicalPlacementId: 'placement-1',
          preceptorId: 'preceptor-1',
          plannedInterval: interval,
          state: ClinicalSessionState.completed,
        ),
        throwsA(isA<DomainValidationException>()),
      );
      final otherZoneActual = ZonedInterval(
        startDate: LocalDate(2026, 8, 3),
        startTime: LocalTime.parseMilitary('0800'),
        endTime: LocalTime.parseMilitary('1200'),
        timeZone: TimeZoneId('America/Chicago'),
        startOffset: UtcOffset.inMinutes(-300),
        endOffset: UtcOffset.inMinutes(-300),
      );
      expect(
        () => ClinicalSession.restore(
          id: 'session-1',
          clinicalPlacementId: 'placement-1',
          preceptorId: 'preceptor-1',
          plannedInterval: interval,
          state: ClinicalSessionState.completed,
          actualInterval: otherZoneActual,
        ),
        throwsA(isA<DomainValidationException>()),
      );
    });
  });
}

ClinicalSession _session(ZonedInterval interval, DateTime asOfUtc) =>
    ClinicalSession.schedule(
      id: 'session-1',
      clinicalPlacementId: 'placement-1',
      preceptorId: 'preceptor-1',
      plannedInterval: interval,
      asOfUtc: asOfUtc,
    );

ZonedInterval _interval(LocalDate date, String start, String end) =>
    ZonedInterval(
      startDate: date,
      startTime: LocalTime.parseMilitary(start),
      endTime: LocalTime.parseMilitary(end),
      timeZone: TimeZoneId('America/New_York'),
      startOffset: UtcOffset.inMinutes(-240),
      endOffset: UtcOffset.inMinutes(-240),
    );
