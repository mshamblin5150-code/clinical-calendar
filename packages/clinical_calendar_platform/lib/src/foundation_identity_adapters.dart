import 'dart:math';

import 'package:clinical_calendar_application/clinical_calendar_identity.dart';

final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

final class ProcessIdentifierGenerator implements IdentifierGenerator {
  ProcessIdentifierGenerator({Random? random})
    : _random = random ?? Random.secure();

  final Random _random;

  @override
  String nextIdentifier() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
