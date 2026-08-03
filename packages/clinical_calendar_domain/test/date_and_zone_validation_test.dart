import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

void main() {
  test(
    'LocalDate validates calendar boundaries and supports date arithmetic',
    () {
      expect(LocalDate(2024, 2, 29).addDays(1), LocalDate(2024, 3, 1));
      expect(
        () => LocalDate(2026, 2, 29),
        throwsA(isA<DomainValidationException>()),
      );
      expect(
        () => LocalDate(2026, 13, 1),
        throwsA(isA<DomainValidationException>()),
      );
    },
  );

  test('time-zone identifiers and offsets have validated constructors', () {
    expect(TimeZoneId('America/New_York').value, 'America/New_York');
    expect(UtcOffset.inMinutes(-300).toString(), '-05:00');
    expect(() => TimeZoneId(' '), throwsA(isA<DomainValidationException>()));
    expect(
      () => UtcOffset.inMinutes(14 * 60 + 1),
      throwsA(isA<DomainValidationException>()),
    );
  });
}
