import 'package:clinical_calendar_platform/clinical_calendar_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('system clock produces UTC values', () {
    expect(const SystemClock().nowUtc().isUtc, isTrue);
  });

  test('process identifiers remain distinct', () {
    final identifiers = ProcessIdentifierGenerator();
    final first = identifiers.nextIdentifier();
    final second = identifiers.nextIdentifier();
    expect(first, isNot(second));
    expect(
      first,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('unconfigured secure storage fails closed', () {
    expect(
      () => const DeferredSecureStorage().read('key'),
      throwsA(isA<StateError>()),
    );
  });
}
