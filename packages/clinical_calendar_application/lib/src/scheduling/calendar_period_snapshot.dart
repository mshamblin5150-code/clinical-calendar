import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import '../repositories.dart';

/// Placement and Preceptor display data resolved for one Clinical Session.
final class CalendarClinicalAssignment {
  const CalendarClinicalAssignment({
    required this.clinicalPlacementId,
    required this.clinicalPlacementName,
    required this.preceptorId,
    required this.preceptorName,
  });

  final String clinicalPlacementId;
  final String clinicalPlacementName;
  final String preceptorId;
  final String preceptorName;
}

/// One coherent repository snapshot bounded by inclusive local dates.
final class CalendarPeriodSnapshot {
  CalendarPeriodSnapshot({
    required this.firstDate,
    required this.lastDate,
    required Iterable<StoredDomainRecord<WorkShift>> workShifts,
    required Iterable<StoredDomainRecord<ClinicalSession>> clinicalSessions,
    required Iterable<StoredDomainRecord<ProtectedDay>> protectedDays,
    required Map<String, CalendarClinicalAssignment>
    clinicalAssignmentsBySessionId,
  }) : workShifts = List.unmodifiable(workShifts),
       clinicalSessions = List.unmodifiable(clinicalSessions),
       protectedDays = List.unmodifiable(protectedDays),
       clinicalAssignmentsBySessionId = Map.unmodifiable(
         clinicalAssignmentsBySessionId,
       ) {
    if (lastDate.isBefore(firstDate)) {
      throw const DomainValidationException(
        'Calendar period end cannot be before its start.',
      );
    }
  }

  final LocalDate firstDate;
  final LocalDate lastDate;
  final List<StoredDomainRecord<WorkShift>> workShifts;
  final List<StoredDomainRecord<ClinicalSession>> clinicalSessions;
  final List<StoredDomainRecord<ProtectedDay>> protectedDays;
  final Map<String, CalendarClinicalAssignment> clinicalAssignmentsBySessionId;
}
