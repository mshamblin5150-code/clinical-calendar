import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/clinical_calendar_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('projects Imported Work Shift flags for a session and week', () {
    final notices = projectScheduleConflictNotices(
      conflicts: [
        ScheduleConflict(
          violation: ScheduleInvariantViolation.commitmentOverlap,
          importedWorkShiftId: 'imported-1',
          workScheduleFeedId: 'feed-1',
          workScheduleFeedName: 'ER Schedule',
          conflictDate: LocalDate(2026, 8, 12),
          conflictingCommitmentId: 'clinical-1',
        ),
        ScheduleConflict(
          violation: ScheduleInvariantViolation.commitmentTouchesProtectedDay,
          importedWorkShiftId: 'imported-2',
          workScheduleFeedId: 'feed-1',
          workScheduleFeedName: 'ER Schedule',
          conflictDate: LocalDate(2026, 8, 13),
          protectedDayId: 'protected-1',
        ),
      ],
      clinicalSessionIds: const {'clinical-1'},
    );

    expect(
      notices.singleWhere((notice) => notice.entryId == 'clinical-1').message,
      'Conflicts with your ER Schedule shift',
    );
    expect(
      notices.singleWhere((notice) => notice.protectedDayId == 'protected-1'),
      isA<CalendarScheduleConflictNotice>()
          .having(
            (notice) => notice.message,
            'message',
            'Protected Day now has a work shift – pick another',
          )
          .having((notice) => notice.date, 'date', LocalDate(2026, 8, 13)),
    );
  });
}
