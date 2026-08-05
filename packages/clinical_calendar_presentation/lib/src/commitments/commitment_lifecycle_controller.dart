import 'dart:async';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:flutter/foundation.dart';

import '../date_input.dart';

typedef CommitmentLifecycleChanged = FutureOr<void> Function();

final class CommitmentLifecycleController extends ChangeNotifier {
  CommitmentLifecycleController({
    required this.service,
    required this.studentId,
    this.onChanged,
  });

  final SchedulingApplicationService service;
  final String studentId;
  final CommitmentLifecycleChanged? onChanged;

  CommitmentLifecycleSnapshot? _snapshot;
  CommitmentLifecycleSnapshot? get snapshot => _snapshot;

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  Object? _error;
  Object? get error => _error;

  List<SchedulingError> _conflicts = const [];
  List<SchedulingError> get conflicts => _conflicts;

  int? _missingProtectedDayWeeks;
  int? get missingProtectedDayWeeks => _missingProtectedDayWeeks;
  bool get planningIncomplete => (_missingProtectedDayWeeks ?? 0) > 0;

  Future<void> open({
    required CommitmentLifecycleKind kind,
    required String id,
  }) => _perform(() async {
    _snapshot = await service.readCommitmentLifecycle(
      studentId: studentId,
      kind: kind,
      id: id,
    );
    await _refreshPlanningStatus();
  });

  Future<void> reload() async {
    final current = _snapshot;
    if (current == null) return;
    await open(kind: current.kind, id: current.id);
  }

  ZonedInterval draftInterval({
    required LocalDate date,
    required LocalTime startTime,
    required LocalTime endTime,
  }) {
    final current = _timedInterval;
    return ZonedInterval(
      startDate: date,
      startTime: startTime,
      endTime: endTime,
      timeZone: current.timeZone,
      startOffset: current.startOffset,
      endOffset: current.endOffset,
    );
  }

  int draftDurationMinutes({
    required LocalDate date,
    required LocalTime startTime,
    required LocalTime endTime,
  }) => draftInterval(
    date: date,
    startTime: startTime,
    endTime: endTime,
  ).elapsedMinutes;

  Future<void> moveOrCorrect({
    required LocalDate date,
    required LocalTime startTime,
    required LocalTime endTime,
  }) => _mutate(() async {
    final current = _requireSnapshot();
    final interval = draftInterval(
      date: date,
      startTime: startTime,
      endTime: endTime,
    );
    final result = switch (current) {
      WorkShiftLifecycleSnapshot() => await service.moveWorkShift(
        studentId: studentId,
        id: current.id,
        plannedInterval: interval,
      ),
      ClinicalSessionLifecycleSnapshot() => await service.moveClinicalSession(
        studentId: studentId,
        id: current.id,
        plannedInterval: interval,
      ),
      ProtectedDayLifecycleSnapshot() => throw const DomainValidationException(
        'A Protected Day does not have start and end times.',
      ),
    };
    _requireCommitted(result.committed, result.conflicts);
  });

  Future<void> confirmClinicalSession({
    required LocalTime actualStartTime,
    required LocalTime actualEndTime,
    required String preceptorId,
  }) => _mutate(() async {
    final current = _requireClinicalSession();
    final planned = current.record.value.plannedInterval;
    final actual = draftInterval(
      date: planned.startDate,
      startTime: actualStartTime,
      endTime: actualEndTime,
    );
    final result = await service.confirmClinicalSession(
      studentId: studentId,
      id: current.id,
      actualInterval: actual,
      preceptorId: preceptorId,
    );
    _requireCommitted(result.committed, result.conflicts);
  });

  Future<void> cancelClinicalSession() => _mutate(() async {
    final current = _requireClinicalSession();
    await service.cancelClinicalSession(studentId: studentId, id: current.id);
  });

  Future<void> markClinicalSessionMissed() => _mutate(() async {
    final current = _requireClinicalSession();
    await service.markClinicalSessionMissed(
      studentId: studentId,
      id: current.id,
    );
  });

  Future<void> deleteErroneousEntry(ErroneousDeletionReason reason) =>
      _perform(() async {
        final current = _requireSnapshot();
        final request = ErroneousDeletionRequest(
          studentId: studentId,
          id: current.id,
          reason: reason,
          confirmed: true,
        );
        switch (current) {
          case WorkShiftLifecycleSnapshot():
            await service.deleteWorkShift(request);
          case ClinicalSessionLifecycleSnapshot():
            await service.deleteClinicalSession(request);
          case ProtectedDayLifecycleSnapshot():
            throw const DomainValidationException(
              'Use Remove Protected Day instead of erroneous-entry deletion.',
            );
        }
        _snapshot = null;
        await _notifyChanged();
      });

  Future<void> moveProtectedDay(LocalDate destination) => _mutate(() async {
    final current = _requireProtectedDay();
    final result = await service.moveProtectedDay(
      studentId: studentId,
      id: current.id,
      destination: destination,
    );
    _requireCommitted(result.committed, result.conflicts);
  });

  Future<void> removeProtectedDay() => _perform(() async {
    final current = _requireProtectedDay();
    final date = current.record.value.date;
    await service.removeProtectedDay(studentId: studentId, id: current.id);
    _snapshot = null;
    await _refreshPlanningStatusFor(date);
    await _notifyChanged();
  });

  String get conflictMessage {
    if (_conflicts.isEmpty) return '';
    final conflict = _conflicts.first;
    return switch (conflict.violation) {
      ScheduleInvariantViolation.commitmentOverlap =>
        'Schedule Conflict on ${formatUsDate(conflict.conflictDate)}. '
            'The original entry was not changed.',
      ScheduleInvariantViolation.commitmentTouchesProtectedDay =>
        'Protected Day on ${formatUsDate(conflict.conflictDate)} blocks this change. '
            'The original entry was not changed.',
      ScheduleInvariantViolation.multipleProtectedDaysInWeek =>
        'That calendar week already has a Protected Day. '
            'The original entry was not changed.',
    };
  }

  ZonedInterval get _timedInterval => switch (_requireSnapshot()) {
    WorkShiftLifecycleSnapshot(:final record) => record.value.plannedInterval,
    ClinicalSessionLifecycleSnapshot(:final record) =>
      record.value.plannedInterval,
    ProtectedDayLifecycleSnapshot() => throw const DomainValidationException(
      'A Protected Day does not have a timed interval.',
    ),
  };

  CommitmentLifecycleSnapshot _requireSnapshot() {
    final current = _snapshot;
    if (current == null) {
      throw StateError('No commitment is open.');
    }
    return current;
  }

  ClinicalSessionLifecycleSnapshot _requireClinicalSession() {
    final current = _requireSnapshot();
    if (current is! ClinicalSessionLifecycleSnapshot) {
      throw StateError('The open item is not a Clinical Session.');
    }
    return current;
  }

  ProtectedDayLifecycleSnapshot _requireProtectedDay() {
    final current = _requireSnapshot();
    if (current is! ProtectedDayLifecycleSnapshot) {
      throw StateError('The open item is not a Protected Day.');
    }
    return current;
  }

  void _requireCommitted(bool committed, List<SchedulingError> conflicts) {
    if (committed) return;
    _conflicts = List.unmodifiable(conflicts);
    throw const _SchedulingConflictException();
  }

  Future<void> _mutate(Future<void> Function() mutation) => _perform(() async {
    final current = _requireSnapshot();
    await mutation();
    await _notifyChanged();
    _snapshot = await service.readCommitmentLifecycle(
      studentId: studentId,
      kind: current.kind,
      id: current.id,
    );
    await _refreshPlanningStatus();
  });

  Future<void> _refreshPlanningStatus() async {
    final current = _snapshot;
    if (current is ProtectedDayLifecycleSnapshot) {
      await _refreshPlanningStatusFor(current.record.value.date);
    }
  }

  Future<void> _refreshPlanningStatusFor(LocalDate date) async {
    _missingProtectedDayWeeks = (await service.missingProtectedDayWeeks(
      studentId: studentId,
      year: date.year,
      month: date.month,
    )).length;
  }

  Future<void> _notifyChanged() async => await onChanged?.call();

  Future<void> _perform(Future<void> Function() action) async {
    if (_isBusy) return;
    _isBusy = true;
    _error = null;
    _conflicts = const [];
    notifyListeners();
    try {
      await action();
    } on _SchedulingConflictException {
      _error = conflictMessage;
    } on Object catch (error) {
      _error = error;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}

final class _SchedulingConflictException implements Exception {
  const _SchedulingConflictException();
}

LocalDate parseCommitmentDate(String input) {
  try {
    return parseUsDate(input);
  } on Object {
    throw const FormatException('Date must use MM-DD-YYYY.');
  }
}

LocalTime parseFlexibleCommitmentTime(String input) {
  final normalized = input.trim().toUpperCase();
  final twelveHour = RegExp(
    r'^(\d{1,2})(?::?(\d{2}))\s*(AM|PM)$',
  ).firstMatch(normalized);
  if (twelveHour == null) return LocalTime.parseMilitary(normalized);
  var hour = int.parse(twelveHour.group(1)!);
  final minute = int.parse(twelveHour.group(2)!);
  if (hour < 1 || hour > 12) {
    throw const FormatException(
      'Twelve-hour time must use hours 1 through 12.',
    );
  }
  if (twelveHour.group(3) == 'AM') {
    if (hour == 12) hour = 0;
  } else if (hour != 12) {
    hour += 12;
  }
  return LocalTime(hour, minute);
}
