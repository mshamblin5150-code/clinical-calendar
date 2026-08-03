import 'package:clinical_calendar_vertical_slice/domain/scheduling.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validator = ScheduleValidator();

  test('rejects an overlapping Clinical Session', () {
    final existing = ScheduleCommitment(
      id: 'existing',
      date: DateTime(2026, 8, 4),
      startMinutes: 7 * 60,
      endMinutes: 19 * 60,
      timeZone: 'America/New_York',
    );
    final candidate = ScheduleCommitment(
      id: 'candidate',
      date: DateTime(2026, 8, 4),
      startMinutes: 18 * 60,
      endMinutes: 20 * 60,
      timeZone: 'America/New_York',
    );

    final result = validator.validate(
      candidate: candidate,
      existing: [existing],
      protectedDays: {},
    );

    expect(result.isValid, isFalse);
    expect(result.rejections, contains(ScheduleRejection.overlap));
  });

  test('allows adjacent commitments', () {
    final existing = ScheduleCommitment(
      id: 'existing',
      date: DateTime(2026, 8, 4),
      startMinutes: 7 * 60,
      endMinutes: 12 * 60,
      timeZone: 'America/New_York',
    );
    final candidate = ScheduleCommitment(
      id: 'candidate',
      date: DateTime(2026, 8, 4),
      startMinutes: 12 * 60,
      endMinutes: 19 * 60,
      timeZone: 'America/New_York',
    );

    final result = validator.validate(
      candidate: candidate,
      existing: [existing],
      protectedDays: {},
    );

    expect(result.isValid, isTrue);
  });

  test('rejects an overnight commitment touching a Protected Day', () {
    final candidate = ScheduleCommitment(
      id: 'overnight',
      date: DateTime(2026, 8, 5),
      startMinutes: 23 * 60,
      endMinutes: 7 * 60,
      timeZone: 'America/New_York',
    );

    final result = validator.validate(
      candidate: candidate,
      existing: [],
      protectedDays: {DateTime(2026, 8, 6)},
    );

    expect(candidate.durationMinutes, 8 * 60);
    expect(result.isValid, isFalse);
    expect(result.rejections, contains(ScheduleRejection.protectedDay));
  });
}
