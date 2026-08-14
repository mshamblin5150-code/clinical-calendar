import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

void main() {
  test('draft derives exact overnight intervals for every selected date', () {
    final draft = BatchSchedulingDraft(
      studentId: 'student-1',
      type: BatchCommitmentType.workShift,
      dates: [_date(3), _date(7)],
      startTime: LocalTime(22, 30),
      endTime: LocalTime(6, 15),
    );

    expect(draft.intervals, hasLength(2));
    expect(draft.intervals.map((value) => value.elapsedMinutes), [465, 465]);
    expect(draft.intervals.every((value) => value.isOvernight), isTrue);
  });

  test('schedule date resolves each DST boundary after times are entered', () {
    final date = ZonedScheduleDate.resolvingOffsets(
      date: LocalDate(2026, 11, 1),
      timeZone: TimeZoneId('America/New_York'),
      offsetAt: (date, time) =>
          time.hour < 2 ? UtcOffset.inMinutes(-240) : UtcOffset.inMinutes(-300),
    );

    final interval = date.interval(
      startTime: LocalTime(1, 30),
      endTime: LocalTime(3, 30),
    );

    expect(interval.startOffset, UtcOffset.inMinutes(-240));
    expect(interval.endOffset, UtcOffset.inMinutes(-300));
    expect(interval.elapsedMinutes, 180);
  });

  test('review blocks the whole batch when any selected date conflicts', () {
    final conflict = SchedulingError(
      violation: ScheduleInvariantViolation.commitmentOverlap,
      proposedId: 'preview-1',
      proposedDate: LocalDate(2026, 8, 7),
      conflictingId: 'existing-1',
      conflictDate: LocalDate(2026, 8, 7),
    );
    final review = BatchSchedulingReview(
      items: [
        BatchSchedulingReviewItem(
          date: LocalDate(2026, 8, 3),
          durationMinutes: 465,
          conflicts: const [],
        ),
        BatchSchedulingReviewItem(
          date: LocalDate(2026, 8, 7),
          durationMinutes: 465,
          conflicts: [conflict],
        ),
      ],
    );

    expect(review.canApply, isFalse);
    expect(review.conflicts, [conflict]);
  });

  test('timed draft rejects an incomplete time range', () {
    final draft = BatchSchedulingDraft(
      studentId: 'student-1',
      type: BatchCommitmentType.clinicalSession,
      dates: [_date(3)],
      clinicalPlacementId: 'placement-1',
      preceptorId: 'preceptor-1',
    );

    expect(
      () => draft.intervals,
      throwsA(
        isA<SchedulingUseCaseException>().having(
          (error) => error.kind,
          'kind',
          SchedulingUseCaseFailureKind.incompleteTimeRange,
        ),
      ),
    );
  });

  test('draft resolves per-date Preceptors without replacing its default', () {
    final firstDate = LocalDate(2026, 8, 3);
    final secondDate = LocalDate(2026, 8, 7);
    final draft = BatchSchedulingDraft(
      studentId: 'student-1',
      type: BatchCommitmentType.clinicalSession,
      dates: [_date(3), _date(7), _date(9)],
      startTime: LocalTime(8, 0),
      endTime: LocalTime(16, 0),
      clinicalPlacementId: 'placement-1',
      preceptorId: 'preceptor-primary',
      preceptorOverrides: {firstDate: 'preceptor-a', secondDate: 'preceptor-b'},
    );

    expect(draft.preceptorIdFor(firstDate), 'preceptor-a');
    expect(draft.preceptorIdFor(secondDate), 'preceptor-b');
    expect(draft.preceptorIdFor(LocalDate(2026, 8, 9)), 'preceptor-primary');
    expect(draft.preceptorId, 'preceptor-primary');
  });
}

ZonedScheduleDate _date(int day) => ZonedScheduleDate(
  date: LocalDate(2026, 8, day),
  timeZone: TimeZoneId('America/New_York'),
  startOffset: UtcOffset.inMinutes(-240),
  endOffset: UtcOffset.inMinutes(-240),
);
