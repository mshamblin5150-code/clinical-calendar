// ignore: implementation_imports
import 'package:clinical_calendar_application/src/reminders/reminder_policy.dart';
import 'package:clinical_calendar_platform/src/notifications/flutter_local_notification_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UTC schedule boundaries use the package UTC location', () {
    final resolver = TimeZonePackageReminderResolver();
    final wallClock = DateTime.utc(2026, 8, 5, 8);

    expect(resolver.fromLocal(wallClock, 'UTC').toUtc(), wallClock);
    expect(resolver.toLocal(wallClock, 'UTC'), wallClock);
  });

  test('named-zone wall clock follows daylight-saving transitions', () {
    final resolver = TimeZonePackageReminderResolver();
    final winter = resolver.fromLocal(
      DateTime.utc(2026, 1, 15, 7),
      'America/New_York',
    );
    final summer = resolver.fromLocal(
      DateTime.utc(2026, 7, 15, 7),
      'America/New_York',
    );
    expect(winter.toUtc(), DateTime.utc(2026, 1, 15, 12));
    expect(summer.toUtc(), DateTime.utc(2026, 7, 15, 11));
    expect(
      resolver.offsetAtLocal(DateTime.utc(2026, 1, 15, 7), 'America/New_York'),
      const Duration(hours: -5),
    );
    expect(
      resolver.offsetAtLocal(DateTime.utc(2026, 7, 15, 7), 'America/New_York'),
      const Duration(hours: -4),
    );
  });

  test('24-hour commitment lead preserves intended local wall clock', () {
    final resolver = TimeZonePackageReminderResolver();
    final schedules = DefaultReminderSchedules(resolver);
    final startsAtUtc = DateTime.utc(2026, 3, 8, 7); // 03:00 EDT.
    final reminder = schedules
        .upcoming(
          kind: ReminderKind.upcomingClinicalSession,
          subjectId: 'session',
          startsAtUtc: startsAtUtc,
          commitmentTimeZoneId: 'America/New_York',
          route: '/session',
        )
        .first;
    expect(reminder.anchorUtc, DateTime.utc(2026, 3, 7, 8)); // 03:00 EST.
    expect(reminder.intendedTimeZoneId, 'America/New_York');
  });
}
