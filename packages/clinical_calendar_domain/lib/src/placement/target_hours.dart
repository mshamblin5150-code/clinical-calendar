import '../domain_validation.dart';

/// A Clinical Placement target stored as exact minutes.
final class TargetHours {
  factory TargetHours.fromMinutes(int minutes) {
    if (minutes <= 0) {
      throw const DomainValidationException(
        'Target Hours must be greater than zero.',
      );
    }
    return TargetHours._(minutes);
  }

  factory TargetHours.fromWholeHours(int hours) {
    if (hours <= 0) {
      throw const DomainValidationException(
        'Target Hours must be greater than zero.',
      );
    }
    return TargetHours._(hours * 60);
  }

  const TargetHours._(this.minutes);

  final int minutes;

  double get displayHours => minutes / 60;

  @override
  bool operator ==(Object other) =>
      other is TargetHours && minutes == other.minutes;

  @override
  int get hashCode => minutes.hashCode;

  @override
  String toString() => '$displayHours hours';
}
