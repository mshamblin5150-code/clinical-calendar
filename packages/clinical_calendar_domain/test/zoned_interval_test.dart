import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

void main() {
  final newYork = TimeZoneId('America/New_York');

  test('derives exact minutes without rounding or break deduction', () {
    final interval = ZonedInterval(
      startDate: LocalDate(2026, 8, 3),
      startTime: LocalTime.parseMilitary('0817'),
      endTime: LocalTime.parseMilitary('1644'),
      timeZone: newYork,
      startOffset: UtcOffset.inMinutes(-240),
      endOffset: UtcOffset.inMinutes(-240),
    );

    expect(interval.elapsedMinutes, 507);
  });

  test('an overnight interval retains its zone and covers both dates', () {
    final interval = ZonedInterval(
      startDate: LocalDate(2026, 8, 3),
      startTime: LocalTime.parseMilitary('2200'),
      endTime: LocalTime.parseMilitary('0615'),
      timeZone: newYork,
      startOffset: UtcOffset.inMinutes(-240),
      endOffset: UtcOffset.inMinutes(-240),
    );

    expect(interval.isOvernight, isTrue);
    expect(interval.endDate, LocalDate(2026, 8, 4));
    expect(interval.coveredDates, [
      LocalDate(2026, 8, 3),
      LocalDate(2026, 8, 4),
    ]);
    expect(interval.timeZone, newYork);
    expect(interval.elapsedMinutes, 495);
  });

  test('spring DST boundary uses boundary offsets for exact elapsed time', () {
    final interval = ZonedInterval(
      startDate: LocalDate(2026, 3, 8),
      startTime: LocalTime.parseMilitary('0130'),
      endTime: LocalTime.parseMilitary('0330'),
      timeZone: newYork,
      startOffset: UtcOffset.inMinutes(-300),
      endOffset: UtcOffset.inMinutes(-240),
    );

    expect(interval.elapsedMinutes, 60);
  });

  test('fall DST boundary retains the repeated elapsed hour', () {
    final interval = ZonedInterval(
      startDate: LocalDate(2026, 11, 1),
      startTime: LocalTime.parseMilitary('0030'),
      endTime: LocalTime.parseMilitary('0230'),
      timeZone: newYork,
      startOffset: UtcOffset.inMinutes(-240),
      endOffset: UtcOffset.inMinutes(-300),
    );

    expect(interval.elapsedMinutes, 180);
  });

  test('rejects zero or nonpositive elapsed intervals', () {
    expect(
      () => ZonedInterval(
        startDate: LocalDate(2026, 8, 3),
        startTime: LocalTime.parseMilitary('0900'),
        endTime: LocalTime.parseMilitary('0900'),
        timeZone: newYork,
        startOffset: UtcOffset.utc,
        endOffset: UtcOffset.utc,
      ),
      throwsA(isA<DomainValidationException>()),
    );
  });
}
