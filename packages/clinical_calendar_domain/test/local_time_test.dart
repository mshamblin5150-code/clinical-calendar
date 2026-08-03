import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

void main() {
  group('LocalTime', () {
    test('normalizes supported military input to stored 24-hour time', () {
      expect(LocalTime.parseMilitary('0735').military, '07:35');
      expect(LocalTime.parseMilitary('23:59').military, '23:59');
    });

    test('formats 12-hour display without changing the stored value', () {
      final time = LocalTime.parseMilitary('1305');

      expect(time.twelveHour, '1:05 PM');
      expect(time.military, '13:05');
      expect(time.minutesSinceMidnight, 13 * 60 + 5);
    });

    test('rejects malformed or out-of-range input', () {
      for (final value in ['735', '24:00', '12:60', '09:30 PM', '']) {
        expect(
          () => LocalTime.parseMilitary(value),
          throwsA(isA<DomainValidationException>()),
          reason: value,
        );
      }
    });
  });
}
