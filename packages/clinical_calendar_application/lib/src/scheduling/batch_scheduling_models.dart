import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

import 'scheduling_application_service.dart';
import 'scheduling_requests.dart';

enum BatchCommitmentType { workShift, clinicalSession, protectedDay }

enum BatchSchedulingReset { addSchedule, planningIncomplete }

final class BatchClinicalPlacementOption {
  BatchClinicalPlacementOption({
    required this.id,
    required this.name,
    required this.primaryPreceptorId,
    required Iterable<BatchPreceptorOption> preceptors,
  }) : preceptors = List.unmodifiable(preceptors);

  final String id;
  final String name;
  final String primaryPreceptorId;
  final List<BatchPreceptorOption> preceptors;
}

final class BatchPreceptorOption {
  const BatchPreceptorOption({required this.id, required this.name});

  final String id;
  final String name;
}

final class BatchSchedulingDraft {
  BatchSchedulingDraft({
    required this.studentId,
    required this.type,
    required Iterable<ZonedScheduleDate> dates,
    this.startTime,
    this.endTime,
    this.clinicalPlacementId,
    this.preceptorId,
  }) : dates = List.unmodifiable(dates);

  final String studentId;
  final BatchCommitmentType type;
  final List<ZonedScheduleDate> dates;
  final LocalTime? startTime;
  final LocalTime? endTime;
  final String? clinicalPlacementId;
  final String? preceptorId;

  List<ZonedInterval> get intervals {
    if (type == BatchCommitmentType.protectedDay) return const [];
    final start = startTime;
    final end = endTime;
    if (start == null || end == null) {
      throw const SchedulingUseCaseException(
        SchedulingUseCaseFailureKind.incompleteTimeRange,
        'A timed scheduling batch requires start and end times.',
      );
    }
    return List.unmodifiable([
      for (final date in dates) date.interval(startTime: start, endTime: end),
    ]);
  }
}

final class BatchSchedulingReviewItem {
  BatchSchedulingReviewItem({
    required this.date,
    required this.durationMinutes,
    required Iterable<SchedulingError> conflicts,
  }) : conflicts = List.unmodifiable(conflicts);

  final LocalDate date;
  final int? durationMinutes;
  final List<SchedulingError> conflicts;

  bool get valid => conflicts.isEmpty;
}

final class BatchSchedulingReview {
  BatchSchedulingReview({required Iterable<BatchSchedulingReviewItem> items})
    : items = List.unmodifiable(items);

  final List<BatchSchedulingReviewItem> items;

  bool get canApply => items.isNotEmpty && items.every((item) => item.valid);
  List<SchedulingError> get conflicts =>
      List.unmodifiable([for (final item in items) ...item.conflicts]);
}

final class BatchSchedulingApplyResult {
  BatchSchedulingApplyResult({
    required this.persistedCount,
    required Iterable<SchedulingError> conflicts,
  }) : conflicts = List.unmodifiable(conflicts);

  final int persistedCount;
  final List<SchedulingError> conflicts;

  bool get applied => conflicts.isEmpty && persistedCount > 0;
}

abstract interface class BatchSchedulingOperations {
  Future<BatchSchedulingReview> review(BatchSchedulingDraft draft);

  Future<BatchSchedulingApplyResult> apply(BatchSchedulingDraft draft);
}

/// Adapts the staged UI draft to the existing single-transaction scheduling
/// use cases. Preview and apply use the same domain invariant engine.
final class SchedulingBatchCoordinator implements BatchSchedulingOperations {
  const SchedulingBatchCoordinator(this._scheduling);

  final SchedulingApplicationService _scheduling;

  @override
  Future<BatchSchedulingReview> review(BatchSchedulingDraft draft) async {
    final validation = switch (draft.type) {
      BatchCommitmentType.workShift => await _scheduling.previewWorkShiftBatch(
        WorkShiftBatchRequest(
          studentId: draft.studentId,
          intervals: draft.intervals,
        ),
      ),
      BatchCommitmentType.clinicalSession =>
        await _scheduling.previewClinicalSessionBatch(
          ClinicalSessionBatchRequest(
            studentId: draft.studentId,
            clinicalPlacementId: _requiredAssignment(
              draft.clinicalPlacementId,
              'Clinical Placement',
            ),
            preceptorId: _requiredAssignment(draft.preceptorId, 'Preceptor'),
            intervals: draft.intervals,
          ),
        ),
      BatchCommitmentType.protectedDay =>
        await _scheduling.previewProtectedDayBatch(
          ProtectedDayBatchRequest(
            studentId: draft.studentId,
            dates: draft.dates.map((date) => date.date),
          ),
        ),
    };
    return BatchSchedulingReview(
      items: [
        for (var index = 0; index < draft.dates.length; index++)
          BatchSchedulingReviewItem(
            date: draft.dates[index].date,
            durationMinutes: draft.type == BatchCommitmentType.protectedDay
                ? null
                : draft.intervals[index].elapsedMinutes,
            conflicts: validation.errors.where(
              (error) => error.proposedDate == draft.dates[index].date,
            ),
          ),
      ],
    );
  }

  @override
  Future<BatchSchedulingApplyResult> apply(BatchSchedulingDraft draft) async {
    final result = switch (draft.type) {
      BatchCommitmentType.workShift => await _scheduling.createWorkShiftBatch(
        WorkShiftBatchRequest(
          studentId: draft.studentId,
          intervals: draft.intervals,
        ),
      ),
      BatchCommitmentType.clinicalSession =>
        await _scheduling.createClinicalSessionBatch(
          ClinicalSessionBatchRequest(
            studentId: draft.studentId,
            clinicalPlacementId: _requiredAssignment(
              draft.clinicalPlacementId,
              'Clinical Placement',
            ),
            preceptorId: _requiredAssignment(draft.preceptorId, 'Preceptor'),
            intervals: draft.intervals,
          ),
        ),
      BatchCommitmentType.protectedDay =>
        await _scheduling.createProtectedDayBatch(
          ProtectedDayBatchRequest(
            studentId: draft.studentId,
            dates: draft.dates.map((date) => date.date),
          ),
        ),
    };
    return BatchSchedulingApplyResult(
      persistedCount: result.records.length,
      conflicts: result.conflicts,
    );
  }
}

String _requiredAssignment(String? value, String label) {
  if (value == null || value.trim().isEmpty) {
    throw SchedulingUseCaseException(
      SchedulingUseCaseFailureKind.incompleteClinicalAssignment,
      'A Clinical Session batch requires a $label.',
    );
  }
  return value;
}
