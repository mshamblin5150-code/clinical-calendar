import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import '../repositories.dart';

/// A selected calendar date together with the zone offsets needed to create a
/// deterministic [ZonedInterval].
final class ZonedScheduleDate {
  const ZonedScheduleDate({
    required this.date,
    required this.timeZone,
    required this.startOffset,
    required this.endOffset,
  });

  final LocalDate date;
  final TimeZoneId timeZone;
  final UtcOffset startOffset;
  final UtcOffset endOffset;

  ZonedInterval interval({
    required LocalTime startTime,
    required LocalTime endTime,
  }) => ZonedInterval(
    startDate: date,
    startTime: startTime,
    endTime: endTime,
    timeZone: timeZone,
    startOffset: startOffset,
    endOffset: endOffset,
  );
}

final class WorkShiftBatchRequest {
  WorkShiftBatchRequest({
    required this.studentId,
    required Iterable<ZonedInterval> intervals,
  }) : intervals = List.unmodifiable(intervals);

  final String studentId;
  final List<ZonedInterval> intervals;
}

final class ClinicalSessionBatchRequest {
  ClinicalSessionBatchRequest({
    required this.studentId,
    required this.clinicalPlacementId,
    required this.preceptorId,
    required Iterable<ZonedInterval> intervals,
  }) : intervals = List.unmodifiable(intervals);

  final String studentId;
  final String clinicalPlacementId;
  final String preceptorId;
  final List<ZonedInterval> intervals;
}

final class ProtectedDayBatchRequest {
  ProtectedDayBatchRequest({
    required this.studentId,
    required Iterable<LocalDate> dates,
  }) : dates = List.unmodifiable(dates);

  final String studentId;
  final List<LocalDate> dates;
}

final class TemplateBatchRequest {
  TemplateBatchRequest({
    required this.studentId,
    required this.templateId,
    required Iterable<ZonedScheduleDate> dates,
    this.clinicalPlacementId,
    this.preceptorId,
  }) : dates = List.unmodifiable(dates);

  final String studentId;
  final String templateId;
  final List<ZonedScheduleDate> dates;

  /// Optional batch overrides. They must be supplied together.
  final String? clinicalPlacementId;
  final String? preceptorId;
}

enum ErroneousDeletionReason { erroneous, duplicate }

/// Permanent deletion is deliberately separate from cancellation and requires
/// an explicit, eligible reason plus confirmation from the calling workflow.
final class ErroneousDeletionRequest {
  const ErroneousDeletionRequest({
    required this.studentId,
    required this.id,
    required this.reason,
    required this.confirmed,
  });

  final String studentId;
  final String id;
  final ErroneousDeletionReason reason;
  final bool confirmed;
}

final class SchedulingMutationResult<T> {
  SchedulingMutationResult.committed(Iterable<StoredDomainRecord<T>> records)
    : records = List.unmodifiable(records),
      conflicts = const <SchedulingError>[];

  SchedulingMutationResult.conflicted(Iterable<SchedulingError> conflicts)
    : records = List<StoredDomainRecord<T>>.empty(growable: false),
      conflicts = List.unmodifiable(conflicts);

  final List<StoredDomainRecord<T>> records;
  final List<SchedulingError> conflicts;

  bool get committed => conflicts.isEmpty;
}

enum SchedulingUseCaseFailureKind {
  notFound,
  emptyBatch,
  duplicateDate,
  completedPlacement,
  templateTypeMismatch,
  incompleteClinicalAssignment,
  deletionNotConfirmed,
  protectedDayMoveChangesWeek,
}

final class SchedulingUseCaseException implements Exception {
  const SchedulingUseCaseException(this.kind, this.message);

  final SchedulingUseCaseFailureKind kind;
  final String message;

  @override
  String toString() => 'SchedulingUseCaseException(${kind.name}): $message';
}
