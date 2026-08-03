import 'package:clinical_calendar_domain/clinical_calendar_domain.dart';
import 'package:test/test.dart';

void main() {
  test('domain boundary has a stable package identity', () {
    expect(DomainBoundary.packageName, 'clinical_calendar_domain');
  });
}
