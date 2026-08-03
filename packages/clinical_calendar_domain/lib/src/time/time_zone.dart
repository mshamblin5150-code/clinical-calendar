import '../domain_validation.dart';

/// A stable time-zone identifier, normally an IANA name such as
/// `America/New_York`.
final class TimeZoneId {
  factory TimeZoneId(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.length > 255) {
      throw const DomainValidationException(
        'Time-zone identifier must contain between 1 and 255 characters.',
      );
    }
    if (normalized.codeUnits.any((unit) => unit < 0x21 || unit == 0x7f)) {
      throw const DomainValidationException(
        'Time-zone identifier contains invalid characters.',
      );
    }
    return TimeZoneId._(normalized);
  }

  const TimeZoneId._(this.value);

  final String value;

  @override
  bool operator ==(Object other) => other is TimeZoneId && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// The observed UTC offset at one boundary of a stored local interval.
final class UtcOffset {
  factory UtcOffset.inMinutes(int minutes) {
    if (minutes < -14 * 60 || minutes > 14 * 60) {
      throw const DomainValidationException(
        'UTC offset must be between -14:00 and +14:00.',
      );
    }
    return UtcOffset._(minutes);
  }

  const UtcOffset._(this.minutes);

  static const UtcOffset utc = UtcOffset._(0);

  final int minutes;

  Duration get duration => Duration(minutes: minutes);

  @override
  bool operator ==(Object other) =>
      other is UtcOffset && minutes == other.minutes;

  @override
  int get hashCode => minutes.hashCode;

  @override
  String toString() {
    final sign = minutes < 0 ? '-' : '+';
    final absolute = minutes.abs();
    return '$sign${(absolute ~/ 60).toString().padLeft(2, '0')}:'
        '${(absolute % 60).toString().padLeft(2, '0')}';
  }
}
