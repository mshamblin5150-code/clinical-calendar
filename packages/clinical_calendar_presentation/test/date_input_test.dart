import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:clinical_calendar_presentation/src/date_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats and parses U.S. calendar dates without changing LocalDate', () {
    final date = LocalDate(2026, 8, 4);

    expect(formatUsDate(date), '08-04-2026');
    expect(parseUsDate('08-04-2026'), date);
  });

  test('rejects the former ISO presentation format', () {
    expect(() => parseUsDate('2026-08-04'), throwsFormatException);
  });
}
