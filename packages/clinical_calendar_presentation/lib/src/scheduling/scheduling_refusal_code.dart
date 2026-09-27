import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';

String schedulingRefusalCode(SchedulingError error) =>
    switch (error.violation) {
      ScheduleInvariantViolation.commitmentOverlap => 'schedule_conflict',
      ScheduleInvariantViolation.commitmentTouchesProtectedDay =>
        'protected_day_violation',
      ScheduleInvariantViolation.multipleProtectedDaysInWeek =>
        'protected_day_already_selected',
    };
