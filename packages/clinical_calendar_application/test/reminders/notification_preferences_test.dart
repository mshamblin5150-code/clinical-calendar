import 'package:clinical_calendar_application/src/support/support_models.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Work Shift and Clinical Session reminder defaults configure separately',
    () {
      const preferences = NotificationPreferences(
        upcomingWorkShiftsEnabled: false,
        upcomingClinicalSessionsEnabled: true,
        workShiftFirstLeadMinutes: 720,
        workShiftSecondLeadMinutes: 60,
        clinicalSessionFirstLeadMinutes: 2880,
        clinicalSessionSecondLeadMinutes: 180,
        confirmationFirstDelayMinutes: 45,
        confirmationRepeatDays: 2,
        evaluationApproachingHours: 12,
        evaluationRepeatDays: 4,
        protectedDayFirstLeadDays: 4,
        protectedDaySecondLeadDays: 2,
        weeklySummaryWeekday: DateTime.monday,
        weeklySummaryHour: 17,
        noBackupReminderDays: 10,
        staleBackupReminderDays: 45,
      );
      final restored = NotificationPreferences.fromJson(preferences.toJson());
      expect(restored.upcomingWorkShiftsEnabled, isFalse);
      expect(restored.upcomingClinicalSessionsEnabled, isTrue);
      expect(restored.workShiftFirstLeadMinutes, 720);
      expect(restored.clinicalSessionFirstLeadMinutes, 2880);
      expect(restored.confirmationFirstDelayMinutes, 45);
      expect(restored.evaluationApproachingHours, 12);
      expect(restored.protectedDayFirstLeadDays, 4);
      expect(restored.weeklySummaryWeekday, DateTime.monday);
      expect(restored.noBackupReminderDays, 10);
      expect(restored.staleBackupReminderDays, 45);
    },
  );

  test('only upcoming, weekly summary, and backup have disable controls', () {
    final keys = const NotificationPreferences(
      upcomingWorkShiftsEnabled: false,
      upcomingClinicalSessionsEnabled: false,
      weeklySummaryEnabled: false,
      backupRemindersEnabled: false,
    ).toJson().keys;
    expect(keys.where((key) => key.endsWith('Enabled')).toSet(), {
      'upcomingCommitmentsEnabled',
      'upcomingWorkShiftsEnabled',
      'upcomingClinicalSessionsEnabled',
      'weeklySummaryEnabled',
      'backupRemindersEnabled',
    });
  });
}
