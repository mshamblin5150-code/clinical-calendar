import 'package:clinical_calendar_platform/clinical_calendar_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('system clock produces UTC values', () {
    expect(const SystemClock().nowUtc().isUtc, isTrue);
  });

  test('process identifiers remain distinct', () {
    final identifiers = ProcessIdentifierGenerator();
    expect(identifiers.nextIdentifier(), isNot(identifiers.nextIdentifier()));
  });

  test('unconfigured secure storage fails closed', () {
    expect(
      () => const DeferredSecureStorage().read('key'),
      throwsA(isA<StateError>()),
    );
  });
}
