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

/// A Schedule Conflict revealed by an Imported Work Shift.
final class ScheduleConflict {
  const ScheduleConflict({
    required this.violation,
    required this.importedWorkShiftId,
    required this.workScheduleFeed,
    required this.conflictDate,
    this.conflictingCommitmentId,
    this.protectedDayId,
  });

  final ScheduleInvariantViolation violation;
  final String importedWorkShiftId;
  final WorkScheduleFeedReference workScheduleFeed;
  String get workScheduleFeedId => workScheduleFeed.id;
  String get workScheduleFeedName => workScheduleFeed.name;
  final LocalDate conflictDate;
  final String? conflictingCommitmentId;
  final String? protectedDayId;
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
  BatchValidationResult._({
    required Iterable<SchedulingError> errors,
    required Iterable<ScheduleConflict> flaggedConflicts,
  }) : errors = List.unmodifiable(errors),
       flaggedConflicts = List.unmodifiable(flaggedConflicts);

  final List<SchedulingError> errors;
  final List<ScheduleConflict> flaggedConflicts;

  bool get canCommit => errors.isEmpty;
}

/// Enforces all cross-record scheduling invariants in one pure domain service.
final class SchedulingInvariantEngine {
  SchedulingInvariantEngine({CalendarWeekConfiguration? weekConfiguration})
    : weekConfiguration = weekConfiguration ?? CalendarWeekConfiguration();

  final CalendarWeekConfiguration weekConfiguration;

  bool intervalsOverlap(ZonedInterval left, ZonedInterval right) =>
      _intervalsOverlap(left, right);

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
    Iterable<WorkShift> workShifts = const <WorkShift>[],
  }) {
    final first = LocalDate(year, month, 1);
    final lastCalendarDate = DateTime.utc(year, month + 1, 0);
    final last = LocalDate(
      lastCalendarDate.year,
      lastCalendarDate.month,
      lastCalendarDate.day,
    );
    final days = List<ProtectedDay>.unmodifiable(protectedDays);
    final conflictedProtectedDayIds =
        flaggedConflictsFor(
              SchedulingState(workShifts: workShifts, protectedDays: days),
            )
            .where((conflict) => conflict.protectedDayId != null)
            .map((conflict) => conflict.protectedDayId);
    final occupied = <CalendarWeek>{
      for (final protectedDay in days)
        if (!conflictedProtectedDayIds.contains(protectedDay.id))
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
        if (!proposed.isImported &&
            intervalsOverlap(proposed.interval, current.interval)) {
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

    for (final pair in _overlappingPairs(proposedCommitments)) {
      final date = _overlapDate(pair.left.interval, pair.right.interval);
      if (!pair.left.isImported) {
        errors.add(
          _commitmentError(
            ScheduleInvariantViolation.commitmentOverlap,
            pair.left,
            pair.right.id,
            date,
          ),
        );
      }
      if (!pair.right.isImported) {
        errors.add(
          _commitmentError(
            ScheduleInvariantViolation.commitmentOverlap,
            pair.right,
            pair.left.id,
            _overlapDate(pair.right.interval, pair.left.interval),
          ),
        );
      }
    }
    final allProtectedDays = <ProtectedDay>[
      ...existing.protectedDays,
      ...batch.protectedDays,
    ];
    for (final proposed in proposedCommitments) {
      for (final protectedDay in allProtectedDays) {
        if (!proposed.isImported &&
            commitmentTouchesProtectedDay(
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

    return BatchValidationResult._(
      errors: errors,
      flaggedConflicts: flaggedConflictsFor(
        SchedulingState(
          workShifts: <WorkShift>[...existing.workShifts, ...batch.workShifts],
          clinicalSessions: <ClinicalSession>[
            ...existing.clinicalSessions,
            ...batch.clinicalSessions,
          ],
          protectedDays: <ProtectedDay>[
            ...existing.protectedDays,
            ...batch.protectedDays,
          ],
        ),
      ),
    );
  }

  /// Derives current flags from schedule facts, so resolving a conflict clears it.
  List<ScheduleConflict> flaggedConflictsFor(SchedulingState state) {
    final commitments = _activeCommitments(state);
    final conflicts = <ScheduleConflict>[];
    for (final pair in _overlappingPairs(commitments)) {
      final imported = pair.left.isImported
          ? pair.left
          : (pair.right.isImported ? pair.right : null);
      if (imported == null) continue;
      final other = identical(imported, pair.left) ? pair.right : pair.left;
      conflicts.add(
        _scheduleConflict(
          violation: ScheduleInvariantViolation.commitmentOverlap,
          imported: imported,
          conflictDate: _overlapDate(imported.interval, other.interval),
          conflictingCommitmentId: other.id,
        ),
      );
    }
    for (final commitment in commitments.where((value) => value.isImported)) {
      for (final protectedDay in state.protectedDays) {
        if (!commitmentTouchesProtectedDay(
          commitment.interval,
          protectedDay.date,
        )) {
          continue;
        }
        conflicts.add(
          _scheduleConflict(
            violation: ScheduleInvariantViolation.commitmentTouchesProtectedDay,
            imported: commitment,
            conflictDate: protectedDay.date,
            protectedDayId: protectedDay.id,
          ),
        );
      }
    }
    return List.unmodifiable(conflicts);
  }

  /// Commits the whole valid batch, or only its Imported Work Shifts when a
  /// hand-entered item is invalid. Imported Work Shifts are never refused.
  SchedulingState? commitBatchIfValid({
    required SchedulingState existing,
    required SchedulingBatch batch,
  }) {
    final result = validateBatch(existing: existing, batch: batch);
    final importedWorkShifts = batch.workShifts
        .where((shift) => shift.isImported)
        .toList(growable: false);
    if (!result.canCommit && importedWorkShifts.isEmpty) {
      return null;
    }
    return SchedulingState(
      workShifts: <WorkShift>[
        ...existing.workShifts,
        ...(result.canCommit ? batch.workShifts : importedWorkShifts),
      ],
      clinicalSessions: <ClinicalSession>[
        ...existing.clinicalSessions,
        if (result.canCommit) ...batch.clinicalSessions,
      ],
      protectedDays: <ProtectedDay>[
        ...existing.protectedDays,
        if (result.canCommit) ...batch.protectedDays,
      ],
    );
  }
}

final class _ActiveCommitment {
  const _ActiveCommitment({
    required this.id,
    required this.interval,
    this.workScheduleFeed,
  });

  final String id;
  final ZonedInterval interval;
  final WorkScheduleFeedReference? workScheduleFeed;

  bool get isImported => workScheduleFeed != null;
}

List<_ActiveCommitment> _activeCommitments(Object source) {
  final (workShifts, clinicalSessions) = switch (source) {
    SchedulingState value => (value.workShifts, value.clinicalSessions),
    SchedulingBatch value => (value.workShifts, value.clinicalSessions),
    _ => throw ArgumentError.value(source, 'source'),
  };
  return <_ActiveCommitment>[
    for (final shift in workShifts)
      _ActiveCommitment(
        id: shift.id,
        interval: shift.plannedInterval,
        workScheduleFeed: shift.workScheduleFeed,
      ),
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

ScheduleConflict _scheduleConflict({
  required ScheduleInvariantViolation violation,
  required _ActiveCommitment imported,
  required LocalDate conflictDate,
  String? conflictingCommitmentId,
  String? protectedDayId,
}) => ScheduleConflict(
  violation: violation,
  importedWorkShiftId: imported.id,
  workScheduleFeed: imported.workScheduleFeed!,
  conflictDate: conflictDate,
  conflictingCommitmentId: conflictingCommitmentId,
  protectedDayId: protectedDayId,
);

Iterable<({_ActiveCommitment left, _ActiveCommitment right})> _overlappingPairs(
  List<_ActiveCommitment> commitments,
) sync* {
  for (var leftIndex = 0; leftIndex < commitments.length; leftIndex++) {
    for (
      var rightIndex = leftIndex + 1;
      rightIndex < commitments.length;
      rightIndex++
    ) {
      final left = commitments[leftIndex];
      final right = commitments[rightIndex];
      if (_intervalsOverlap(left.interval, right.interval)) {
        yield (left: left, right: right);
      }
    }
  }
}

bool _intervalsOverlap(ZonedInterval left, ZonedInterval right) =>
    left.startInstantUtc.isBefore(right.endInstantUtc) &&
    right.startInstantUtc.isBefore(left.endInstantUtc);

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
