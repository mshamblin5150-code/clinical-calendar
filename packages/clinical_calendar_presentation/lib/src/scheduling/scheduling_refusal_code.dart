import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

String schedulingRefusalCode(SchedulingError error) =>
    switch (error.violation) {
      ScheduleInvariantViolation.commitmentOverlap => 'schedule_conflict',
      ScheduleInvariantViolation.commitmentTouchesProtectedDay =>
        'protected_day_violation',
      ScheduleInvariantViolation.multipleProtectedDaysInWeek =>
        'protected_day_already_selected',
    };

String schedulingUseCaseRefusalCode(Object error) => switch (error) {
  SchedulingUseCaseException(kind: final kind) => switch (kind) {
    SchedulingUseCaseFailureKind.notFound => 'schedule_not_found',
    SchedulingUseCaseFailureKind.emptyBatch => 'empty_schedule_batch',
    SchedulingUseCaseFailureKind.duplicateDate => 'duplicate_schedule_date',
    SchedulingUseCaseFailureKind.completedPlacement =>
      'completed_placement_refusal',
    SchedulingUseCaseFailureKind.templateTypeMismatch =>
      'schedule_template_type_mismatch',
    SchedulingUseCaseFailureKind.incompleteClinicalAssignment =>
      'incomplete_clinical_assignment',
    SchedulingUseCaseFailureKind.incompleteTimeRange => 'incomplete_time_range',
    SchedulingUseCaseFailureKind.deletionNotConfirmed =>
      'deletion_not_confirmed',
    SchedulingUseCaseFailureKind.importedWorkShiftReadOnly =>
      'imported_work_shift_read_only',
    SchedulingUseCaseFailureKind.protectedDayMoveChangesWeek =>
      'protected_day_move_changes_week',
  },
  _ => 'commitment_change_refused',
};
