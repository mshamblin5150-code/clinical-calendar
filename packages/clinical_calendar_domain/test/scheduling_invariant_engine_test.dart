import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

void main() {
  final engine = SchedulingInvariantEngine(
    weekConfiguration: CalendarWeekConfiguration(weekStartsOn: DateTime.sunday),
  );

  group('active commitment overlap', () {
    test('rejects overlap but permits exact adjacency', () {
      final existing = SchedulingState(
        workShifts: [_work('existing', '2026-08-03', '0800', '1200')],
      );
      final batch = SchedulingBatch(
        workShifts: [
          _work('overlap', '2026-08-03', '1159', '1400'),
          _work('adjacent', '2026-08-03', '1200', '1600'),
        ],
      );

      final result = engine.validateBatch(existing: existing, batch: batch);

      expect(
        result.errors
            .where(
              (error) =>
                  error.violation ==
                      ScheduleInvariantViolation.commitmentOverlap &&
                  error.conflictingId == 'existing',
            )
            .map((error) => error.proposedId),
        ['overlap'],
      );
      expect(result.canCommit, isFalse);
    });

    test('Scheduled, Awaiting, and Completed Sessions block time', () {
      for (final state in [
        ClinicalSessionState.scheduled,
        ClinicalSessionState.awaitingConfirmation,
        ClinicalSessionState.completed,
      ]) {
        final existing = SchedulingState(
          clinicalSessions: [_session('session-${state.name}', state)],
        );
        final result = engine.validateBatch(
          existing: existing,
          batch: SchedulingBatch(
            workShifts: [_work('candidate', '2026-08-03', '1000', '1030')],
          ),
        );
        expect(result.canCommit, isFalse, reason: state.name);
      }
    });

    test('Cancelled and Missed Sessions do not block time', () {
      final existing = SchedulingState(
        clinicalSessions: [
          _session('cancelled', ClinicalSessionState.cancelled),
          _session('missed', ClinicalSessionState.missed),
        ],
      );

      final result = engine.validateBatch(
        existing: existing,
        batch: SchedulingBatch(
          workShifts: [_work('candidate', '2026-08-03', '1000', '1030')],
        ),
      );

      expect(result.canCommit, isTrue);
    });

    test('overlap is symmetric across deterministic interval samples', () {
      final intervals = <ZonedInterval>[];
      for (var hour = 0; hour < 20; hour += 2) {
        intervals.add(
          _interval(
            LocalDate(2026, 8, 3),
            '${hour.toString().padLeft(2, '0')}00',
            '${(hour + 3).toString().padLeft(2, '0')}00',
          ),
        );
      }

      for (final left in intervals) {
        for (final right in intervals) {
          expect(
            engine.intervalsOverlap(left, right),
            engine.intervalsOverlap(right, left),
          );
        }
      }
    });

    test('reports each proposed conflict in its own stored local date', () {
      final newYork = ZonedInterval(
        startDate: LocalDate(2026, 8, 3),
        startTime: LocalTime.parseMilitary('2300'),
        endTime: LocalTime.parseMilitary('0100'),
        timeZone: TimeZoneId('America/New_York'),
        startOffset: UtcOffset.inMinutes(-240),
        endOffset: UtcOffset.inMinutes(-240),
      );
      final losAngeles = ZonedInterval(
        startDate: LocalDate(2026, 8, 3),
        startTime: LocalTime.parseMilitary('2130'),
        endTime: LocalTime.parseMilitary('2330'),
        timeZone: TimeZoneId('America/Los_Angeles'),
        startOffset: UtcOffset.inMinutes(-420),
        endOffset: UtcOffset.inMinutes(-420),
      );

      final result = engine.validateBatch(
        existing: SchedulingState(),
        batch: SchedulingBatch(
          workShifts: [
            WorkShift(id: 'new-york', plannedInterval: newYork),
            WorkShift(id: 'los-angeles', plannedInterval: losAngeles),
          ],
        ),
      );

      expect(
        result.errors
            .singleWhere((error) => error.proposedId == 'new-york')
            .conflictDate,
        LocalDate(2026, 8, 4),
      );
      expect(
        result.errors
            .singleWhere((error) => error.proposedId == 'los-angeles')
            .conflictDate,
        LocalDate(2026, 8, 3),
      );
    });
  });

  group('Protected Day invariants', () {
    test('overnight activity touching the next date is rejected', () {
      final result = engine.validateBatch(
        existing: SchedulingState(
          protectedDays: [
            ProtectedDay(id: 'rest', date: LocalDate(2026, 8, 4)),
          ],
        ),
        batch: SchedulingBatch(
          workShifts: [_work('overnight', '2026-08-03', '2200', '0600')],
        ),
      );

      expect(
        result.errors.single.violation,
        ScheduleInvariantViolation.commitmentTouchesProtectedDay,
      );
      expect(result.errors.single.conflictDate, LocalDate(2026, 8, 4));
    });

    test('ending exactly at Protected Day midnight is adjacent and valid', () {
      final result = engine.validateBatch(
        existing: SchedulingState(
          protectedDays: [
            ProtectedDay(id: 'rest', date: LocalDate(2026, 8, 4)),
          ],
        ),
        batch: SchedulingBatch(
          workShifts: [_work('until-midnight', '2026-08-03', '1600', '0000')],
        ),
      );

      expect(result.canCommit, isTrue);
    });

    test('rejects each proposed Protected Day sharing a calendar week', () {
      final result = engine.validateBatch(
        existing: SchedulingState(),
        batch: SchedulingBatch(
          protectedDays: [
            ProtectedDay(id: 'sunday', date: LocalDate(2026, 8, 2)),
            ProtectedDay(id: 'saturday', date: LocalDate(2026, 8, 8)),
          ],
        ),
      );

      expect(result.errors.map((error) => error.proposedId).toSet(), {
        'sunday',
        'saturday',
      });
      expect(
        result.errors.every(
          (error) =>
              error.violation ==
              ScheduleInvariantViolation.multipleProtectedDaysInWeek,
        ),
        isTrue,
      );
    });
  });

  test('batch validation is all-errors, nonmutating, and all-or-nothing', () {
    final originalShift = _work('original', '2026-08-03', '0800', '1200');
    final existingDays = <ProtectedDay>[
      ProtectedDay(id: 'rest', date: LocalDate(2026, 8, 5)),
    ];
    final existing = SchedulingState(
      workShifts: [originalShift],
      protectedDays: existingDays,
    );
    final batch = SchedulingBatch(
      workShifts: [
        _work('overlap', '2026-08-03', '0900', '1000'),
        _work('protected', '2026-08-05', '1300', '1400'),
      ],
      protectedDays: [
        ProtectedDay(id: 'duplicate-week', date: LocalDate(2026, 8, 7)),
      ],
    );

    final result = engine.validateBatch(existing: existing, batch: batch);
    final committed = engine.commitBatchIfValid(
      existing: existing,
      batch: batch,
    );

    expect(result.errors.map((error) => error.proposedDate).toSet(), {
      LocalDate(2026, 8, 3),
      LocalDate(2026, 8, 5),
      LocalDate(2026, 8, 7),
    });
    expect(committed, isNull);
    expect(existing.workShifts, same(existing.workShifts));
    expect(existing.workShifts, [originalShift]);
    expect(existing.protectedDays, [existingDays.single]);

    final validBatch = SchedulingBatch(
      workShifts: [_work('valid', '2026-08-04', '1200', '1300')],
    );
    final next = engine.commitBatchIfValid(
      existing: existing,
      batch: validBatch,
    );
    expect(next, isNotNull);
    expect(next!.workShifts.map((shift) => shift.id), ['original', 'valid']);
    expect(existing.workShifts.map((shift) => shift.id), ['original']);
  });
}

WorkShift _work(String id, String date, String start, String end) =>
    WorkShift(id: id, plannedInterval: _interval(_date(date), start, end));

LocalDate _date(String value) {
  final parts = value.split('-').map(int.parse).toList();
  return LocalDate(parts[0], parts[1], parts[2]);
}

ClinicalSession _session(String id, ClinicalSessionState state) {
  final planned = _interval(LocalDate(2026, 8, 3), '0900', '1100');
  final actual = _interval(LocalDate(2026, 8, 3), '0930', '1130');
  return ClinicalSession.restore(
    id: id,
    clinicalPlacementId: 'placement',
    preceptorId: 'preceptor',
    plannedInterval: planned,
    state: state,
    actualInterval: state == ClinicalSessionState.completed ? actual : null,
  );
}

ZonedInterval _interval(LocalDate date, String start, String end) =>
    ZonedInterval(
      startDate: date,
      startTime: LocalTime.parseMilitary(start),
      endTime: LocalTime.parseMilitary(end),
      timeZone: TimeZoneId('America/New_York'),
      startOffset: UtcOffset.inMinutes(-240),
      endOffset: UtcOffset.inMinutes(-240),
    );
