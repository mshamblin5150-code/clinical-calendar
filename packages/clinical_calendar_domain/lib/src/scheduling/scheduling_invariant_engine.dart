import '../commitments/clinical_session.dart';
import '../commitments/protected_day.dart';
import '../commitments/work_shift.dart';
import '../time/local_date.dart';
import '../time/local_time.dart';
import '../time/zoned_interval.dart';
import 'calendar_week.dart';

enum ScheduleInvariantViolation {
  commitmentOverlap,
  commitmentTouchesProtectedDay,
  multipleProtectedDaysInWeek,
}

/// One deterministic explanation for why a proposed batch item is invalid.
final class SchedulingError {
  const SchedulingError({
    required this.violation,
    required this.proposedId,
    required this.proposedDate,
    required this.conflictingId,
    required this.conflictDate,
  });

  final ScheduleInvariantViolation violation;
  final String proposedId;

  /// The date selected for the proposed item.
  final LocalDate proposedDate;

  /// The date on which the invariant is violated.
  final LocalDate conflictDate;
  final String conflictingId;
}

/// A read-only schedule snapshot accepted or returned by the invariant engine.
final class SchedulingState {
  SchedulingState({
    Iterable<WorkShift> workShifts = const <WorkShift>[],
    Iterable<ClinicalSession> clinicalSessions = const <ClinicalSession>[],
    Iterable<ProtectedDay> protectedDays = const <ProtectedDay>[],
  }) : workShifts = List.unmodifiable(workShifts),
       clinicalSessions = List.unmodifiable(clinicalSessions),
       protectedDays = List.unmodifiable(protectedDays);

  final List<WorkShift> workShifts;
  final List<ClinicalSession> clinicalSessions;
  final List<ProtectedDay> protectedDays;
}

/// Proposed additions that remain detached from persisted state until valid.
final class SchedulingBatch {
  SchedulingBatch({
    Iterable<WorkShift> workShifts = const <WorkShift>[],
    Iterable<ClinicalSession> clinicalSessions = const <ClinicalSession>[],
    Iterable<ProtectedDay> protectedDays = const <ProtectedDay>[],
  }) : workShifts = List.unmodifiable(workShifts),
       clinicalSessions = List.unmodifiable(clinicalSessions),
       protectedDays = List.unmodifiable(protectedDays);

  final List<WorkShift> workShifts;
  final List<ClinicalSession> clinicalSessions;
  final List<ProtectedDay> protectedDays;
}

/// The complete result of validating a batch without mutating either input.
final class BatchValidationResult {
  BatchValidationResult._({required Iterable<SchedulingError> errors})
    : errors = List.unmodifiable(errors);

  final List<SchedulingError> errors;

  bool get canCommit => errors.isEmpty;
}

/// Enforces all cross-record scheduling invariants in one pure domain service.
final class SchedulingInvariantEngine {
  SchedulingInvariantEngine({CalendarWeekConfiguration? weekConfiguration})
    : weekConfiguration = weekConfiguration ?? CalendarWeekConfiguration();

  final CalendarWeekConfiguration weekConfiguration;

  bool intervalsOverlap(ZonedInterval left, ZonedInterval right) =>
      left.startInstantUtc.isBefore(right.endInstantUtc) &&
      right.startInstantUtc.isBefore(left.endInstantUtc);

  bool commitmentTouchesProtectedDay(
    ZonedInterval interval,
    LocalDate protectedDate,
  ) {
    final localStart = _localInstant(interval.startDate, interval.startTime);
    final localEnd = _localInstant(interval.endDate, interval.endTime);
    final protectedStart = protectedDate.asUtcCalendarDate;
    final protectedEnd = protectedStart.add(const Duration(days: 1));
    return localStart.isBefore(protectedEnd) &&
        protectedStart.isBefore(localEnd);
  }

  CalendarWeek weekContaining(LocalDate date) =>
      weekConfiguration.weekContaining(date);

  /// Returns every week intersecting [year]/[month] that lacks a Protected Day.
  List<CalendarWeek> missingProtectedDayWeeksForMonth({
    required int year,
    required int month,
    required Iterable<ProtectedDay> protectedDays,
  }) {
    final first = LocalDate(year, month, 1);
    final lastCalendarDate = DateTime.utc(year, month + 1, 0);
    final last = LocalDate(
      lastCalendarDate.year,
      lastCalendarDate.month,
      lastCalendarDate.day,
    );
    final occupied = <CalendarWeek>{
      for (final protectedDay in protectedDays)
        weekContaining(protectedDay.date),
    };
    final missing = <CalendarWeek>[];
    var week = weekContaining(first);
    while (!week.start.isAfter(last)) {
      if (!occupied.contains(week)) {
        missing.add(week);
      }
      week = week.next;
    }
    return List.unmodifiable(missing);
  }

  /// Reports all conflicts. A caller may append [batch] only when [canCommit].
  BatchValidationResult validateBatch({
    required SchedulingState existing,
    required SchedulingBatch batch,
  }) {
    final errors = <SchedulingError>[];
    final existingCommitments = _activeCommitments(existing);
    final proposedCommitments = _activeCommitments(batch);

    for (final proposed in proposedCommitments) {
      for (final current in existingCommitments) {
        if (intervalsOverlap(proposed.interval, current.interval)) {
          errors.add(
            _commitmentError(
              ScheduleInvariantViolation.commitmentOverlap,
              proposed,
              current.id,
              _overlapDate(proposed.interval, current.interval),
            ),
          );
        }
      }
    }

    for (
      var leftIndex = 0;
      leftIndex < proposedCommitments.length;
      leftIndex++
    ) {
      for (
        var rightIndex = leftIndex + 1;
        rightIndex < proposedCommitments.length;
        rightIndex++
      ) {
        final left = proposedCommitments[leftIndex];
        final right = proposedCommitments[rightIndex];
        if (intervalsOverlap(left.interval, right.interval)) {
          final date = _overlapDate(left.interval, right.interval);
          errors
            ..add(
              _commitmentError(
                ScheduleInvariantViolation.commitmentOverlap,
                left,
                right.id,
                date,
              ),
            )
            ..add(
              _commitmentError(
                ScheduleInvariantViolation.commitmentOverlap,
                right,
                left.id,
                _overlapDate(right.interval, left.interval),
              ),
            );
        }
      }
    }

    final allProtectedDays = <ProtectedDay>[
      ...existing.protectedDays,
      ...batch.protectedDays,
    ];
    for (final proposed in proposedCommitments) {
      for (final protectedDay in allProtectedDays) {
        if (commitmentTouchesProtectedDay(
          proposed.interval,
          protectedDay.date,
        )) {
          errors.add(
            _commitmentError(
              ScheduleInvariantViolation.commitmentTouchesProtectedDay,
              proposed,
              protectedDay.id,
              protectedDay.date,
            ),
          );
        }
      }
    }

    final allCommitments = <_ActiveCommitment>[
      ...existingCommitments,
      ...proposedCommitments,
    ];
    for (
      var proposedIndex = 0;
      proposedIndex < batch.protectedDays.length;
      proposedIndex++
    ) {
      final proposedDay = batch.protectedDays[proposedIndex];
      for (final commitment in allCommitments) {
        if (commitmentTouchesProtectedDay(
          commitment.interval,
          proposedDay.date,
        )) {
          errors.add(
            SchedulingError(
              violation:
                  ScheduleInvariantViolation.commitmentTouchesProtectedDay,
              proposedId: proposedDay.id,
              proposedDate: proposedDay.date,
              conflictingId: commitment.id,
              conflictDate: proposedDay.date,
            ),
          );
        }
      }

      for (
        var otherIndex = 0;
        otherIndex < allProtectedDays.length;
        otherIndex++
      ) {
        if (otherIndex == existing.protectedDays.length + proposedIndex) {
          continue;
        }
        final otherDay = allProtectedDays[otherIndex];
        if (weekContaining(proposedDay.date) == weekContaining(otherDay.date)) {
          errors.add(
            SchedulingError(
              violation: ScheduleInvariantViolation.multipleProtectedDaysInWeek,
              proposedId: proposedDay.id,
              proposedDate: proposedDay.date,
              conflictingId: otherDay.id,
              conflictDate: otherDay.date,
            ),
          );
        }
      }
    }

    return BatchValidationResult._(errors: errors);
  }

  /// Produces a new snapshot only when the whole batch is valid.
  SchedulingState? commitBatchIfValid({
    required SchedulingState existing,
    required SchedulingBatch batch,
  }) {
    final result = validateBatch(existing: existing, batch: batch);
    if (!result.canCommit) {
      return null;
    }
    return SchedulingState(
      workShifts: <WorkShift>[...existing.workShifts, ...batch.workShifts],
      clinicalSessions: <ClinicalSession>[
        ...existing.clinicalSessions,
        ...batch.clinicalSessions,
      ],
      protectedDays: <ProtectedDay>[
        ...existing.protectedDays,
        ...batch.protectedDays,
      ],
    );
  }
}

final class _ActiveCommitment {
  const _ActiveCommitment({required this.id, required this.interval});

  final String id;
  final ZonedInterval interval;
}

List<_ActiveCommitment> _activeCommitments(Object source) {
  final (workShifts, clinicalSessions) = switch (source) {
    SchedulingState value => (value.workShifts, value.clinicalSessions),
    SchedulingBatch value => (value.workShifts, value.clinicalSessions),
    _ => throw ArgumentError.value(source, 'source'),
  };
  return <_ActiveCommitment>[
    for (final shift in workShifts)
      _ActiveCommitment(id: shift.id, interval: shift.plannedInterval),
    for (final session in clinicalSessions)
      if (session.state != ClinicalSessionState.cancelled &&
          session.state != ClinicalSessionState.missed)
        _ActiveCommitment(
          id: session.id,
          interval: session.state == ClinicalSessionState.completed
              ? session.actualInterval!
              : session.plannedInterval,
        ),
  ];
}

SchedulingError _commitmentError(
  ScheduleInvariantViolation violation,
  _ActiveCommitment proposed,
  String conflictingId,
  LocalDate conflictDate,
) => SchedulingError(
  violation: violation,
  proposedId: proposed.id,
  proposedDate: proposed.interval.startDate,
  conflictingId: conflictingId,
  conflictDate: conflictDate,
);

DateTime _localInstant(LocalDate date, LocalTime time) =>
    DateTime.utc(date.year, date.month, date.day, time.hour, time.minute);

LocalDate _overlapDate(ZonedInterval left, ZonedInterval right) {
  final instant = left.startInstantUtc.isAfter(right.startInstantUtc)
      ? left.startInstantUtc
      : right.startInstantUtc;
  final local = instant.add(left.startOffset.duration);
  return LocalDate(local.year, local.month, local.day);
}
