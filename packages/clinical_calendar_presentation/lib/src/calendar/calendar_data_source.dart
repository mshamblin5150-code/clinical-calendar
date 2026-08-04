import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import 'calendar_models.dart';

abstract interface class CalendarDataSource {
  Future<CalendarSnapshot> load({
    required String studentId,
    required LocalDate firstDate,
    required LocalDate lastDate,
  });
}

/// Presentation adapter over the application-owned calendar query.
final class SchedulingCalendarDataSource implements CalendarDataSource {
  const SchedulingCalendarDataSource(this.scheduling);

  final SchedulingApplicationService scheduling;

  @override
  Future<CalendarSnapshot> load({
    required String studentId,
    required LocalDate firstDate,
    required LocalDate lastDate,
  }) async {
    final snapshot = await scheduling.readCalendarPeriod(
      studentId: studentId,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    final entries = <CalendarEntry>[
      for (final record in snapshot.workShifts) _workShiftEntry(record.value),
      for (final record in snapshot.clinicalSessions)
        if (record.value.state != ClinicalSessionState.cancelled &&
            record.value.state != ClinicalSessionState.missed)
          _clinicalSessionEntry(
            record.value,
            snapshot.clinicalAssignmentsBySessionId[record.value.id]!,
          ),
      for (final record in snapshot.protectedDays)
        CalendarEntry(
          id: record.value.id,
          kind: CalendarEntryKind.protectedDay,
          startDate: record.value.date,
          endDate: record.value.date,
          title: 'Protected Day',
          statusLabel: 'Protected',
        ),
    ]..sort(_compareEntries);
    return CalendarSnapshot(entries);
  }
}

CalendarEntry _workShiftEntry(WorkShift shift) => CalendarEntry(
  id: shift.id,
  kind: CalendarEntryKind.workShift,
  startDate: shift.plannedInterval.startDate,
  endDate: shift.plannedInterval.endDate,
  startTime: shift.plannedInterval.startTime,
  endTime: shift.plannedInterval.endTime,
  title: 'Work Shift',
  statusLabel: 'Scheduled',
);

CalendarEntry _clinicalSessionEntry(
  ClinicalSession session,
  CalendarClinicalAssignment assignment,
) {
  final interval = session.state == ClinicalSessionState.completed
      ? session.actualInterval!
      : session.plannedInterval;
  return CalendarEntry(
    id: session.id,
    kind: CalendarEntryKind.clinicalSession,
    startDate: interval.startDate,
    endDate: interval.endDate,
    startTime: interval.startTime,
    endTime: interval.endTime,
    title: 'Clinical Session',
    assignment:
        '${assignment.clinicalPlacementName} · ${assignment.preceptorName}',
    statusLabel: _statusLabel(session.state),
  );
}

String _statusLabel(ClinicalSessionState state) => switch (state) {
  ClinicalSessionState.scheduled => 'Scheduled',
  ClinicalSessionState.awaitingConfirmation => 'Awaiting Confirmation',
  ClinicalSessionState.completed => 'Completed',
  ClinicalSessionState.cancelled => 'Cancelled',
  ClinicalSessionState.missed => 'Missed',
};

int _compareEntries(CalendarEntry left, CalendarEntry right) {
  final date = left.startDate.compareTo(right.startDate);
  if (date != 0) return date;
  final time = (left.startTime?.minutesSinceMidnight ?? -1).compareTo(
    right.startTime?.minutesSinceMidnight ?? -1,
  );
  return time != 0 ? time : left.id.compareTo(right.id);
}
